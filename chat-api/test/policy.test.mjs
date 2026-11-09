import { test } from 'node:test';
import assert from 'node:assert/strict';
import { AiPolicy, dayKey, LEASE_MS } from '../src/ai-policy.mjs';
import { ApiError } from '../src/protocol.mjs';
import { createHandler } from '../src/index.mjs';
import { fixture } from './policy-fixture.mjs';

const id = 'turn-request-0000001';
const base = { version: 1, phase: 'plan', question: 'Nước uống là gì?', history: [], today: '2026-10-31', selectedDate: '2026-10-31', timezoneOffsetMinutes: 420 };
function request({ phase = 'plan', requestId = id, signal } = {}) {
  return new Request('https://test.invalid/v1/chat', { method: 'POST', signal,
    headers: { 'content-type': 'application/json', 'x-healthmate-request-id': requestId },
    body: JSON.stringify({ ...base, phase, ...(phase === 'answer' ? { results: [] } : {}) }),
  });
}
function bindings(run = async () => ({ response: '{"requests":[]}' })) {
  return { FIREBASE_PROJECT_ID: 'demo-healthmate-rules', FIREBASE_PROJECT_NUMBER: '123', FIREBASE_ANDROID_APP_ID: 'test-app',
    AI: { run }, USER_LIMIT: { limit: async () => ({ success: true }) }, GLOBAL_LIMIT: { limit: async () => ({ success: true }) } };
}
const error = (status, code) => e => e instanceof ApiError && e.status === status && e.code === code;
const usage = (store, now) => store.data.get(`ai_gateway_usage/user-a/days/${dayKey(now)}`)?.chats ?? 0;
const job = store => store.data.get(`ai_gateway_reservations/user-a/requests/${id}`);

test('paid quota requires server verified, live and unexpired entitlement; test gated separately',async()=>{
  const now=Date.now();
  for(const [patch,allowed,allowTestPurchases] of [[{},true,false],[{verified:false},false,false],[{active:false},false,false],[{expiresAt:now},false,false],[{environment:'test'},false,false],[{environment:'test'},true,true],[{status:'SUBSCRIPTION_STATE_ON_HOLD'},false,false]]){
    const {store,policy}=fixture({now:()=>now,allowTestPurchases});
    store.data.set('premium_memberships/user-a',{provider:'google_play',verified:true,active:true,environment:'production',status:'SUBSCRIPTION_STATE_ACTIVE',startedAt:now-1000,expiresAt:now+1000,...patch});
    store.data.set(`ai_gateway_usage/user-a/days/${dayKey(now)}`,{dayKey:dayKey(now),chats:5});
    if(allowed)await policy.reserve('user-a',id);else await assert.rejects(policy.reserve('user-a',id),error(429,'quota_exceeded'));
  }
});

test('missing trusted runtime identity fails closed before any model call', async () => {
  let calls = 0;
  const handler = createHandler(async () => ({ uid: 'user-a', authTime: 1 }));
  const response = await handler(request(), bindings(async () => { calls++; }));
  assert.equal(response.status, 503); assert.equal((await response.json()).error, 'policy_not_configured'); assert.equal(calls, 0);
});
for (const [label, mutate, code] of [
  ['suspended', s => s.data.set('account_controls/user-a', { status: 'suspended' }), 'account_suspended'],
  ['deleting', s => s.data.set('account_deletions/user-a', { state: 'requested' }), 'account_deleting'],
  ['disabled feature', s => s.data.get('app_config/runtime').chatbotEnabled = false, 'feature_disabled'],
  ['maintenance', s => s.data.get('app_config/runtime').maintenanceMode = true, 'feature_disabled'],
  ['missing configuration', s => s.data.delete('app_config/runtime'), 'feature_disabled'],
  ['underage profile', s => s.data.get('users/user-a').birthDate = Date.UTC(2015, 0, 1), 'profile_ineligible'],
]) test(`direct endpoint denies ${label} without consuming quota or calling model`, async () => {
  const { store, policy } = fixture(); mutate(store); let calls = 0;
  const handler = createHandler(async () => ({ uid: 'user-a', authTime: 1 }), { policyFactory: () => policy });
  const response = await handler(request(), bindings(async () => { calls++; }));
  assert.equal(response.status, 403); assert.equal((await response.json()).error, code); assert.equal(calls, 0);
  assert.equal(usage(store, Date.now()), 0);
});
test('two concurrent requests racing for final quota reserve at most one slot', async () => {
  const now = Date.UTC(2026, 9, 31); const { store, policy } = fixture({ now: () => now });
  store.data.set(`ai_gateway_usage/user-a/days/${dayKey(now)}`, { dayKey: dayKey(now), chats: 4 });
  const results = await Promise.allSettled([policy.reserve('user-a', id), policy.reserve('user-a', 'turn-request-0000002')]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal(results.filter(r => r.status === 'rejected' && error(429, 'quota_exceeded')(r.reason)).length, 1);
  assert.equal(usage(store, now), 5);
});
test('same request ID reserves once, phase claim is single-use and answer needs completed plan', async () => {
  const { store, policy } = fixture();
  const [a, b] = await Promise.all([policy.reserve('user-a', id), policy.reserve('user-a', id)]);
  assert.equal(a.dayKey, b.dayKey); assert.equal(usage(store, Date.now()), 1);
  await assert.rejects(policy.claim('user-a', id, 'answer', a.dayKey), error(409, 'plan_required'));
  const claims = await Promise.allSettled([policy.claim('user-a', id, 'plan', a.dayKey), policy.claim('user-a', id, 'plan', a.dayKey)]);
  assert.equal(claims.filter(r => r.status === 'fulfilled').length, 1);
  await policy.finish('user-a', id, 'plan', a.dayKey, 'completed');
  await policy.claim('user-a', id, 'answer', a.dayKey);
  await policy.finish('user-a', id, 'answer', a.dayKey, 'completed');
  await assert.rejects(policy.claim('user-a', id, 'answer', a.dayKey), error(409, 'request_already_sent'));
  assert.equal(job(store).state, 'completed'); assert.equal(usage(store, Date.now()), 1);
});
test('other UID cannot reuse victim reservation; same id creates independent quota', async () => {
  const { store, policy } = fixture(); const a = await policy.reserve('user-a', id);
  await assert.rejects(policy.claim('user-b', id, 'plan', a.dayKey), error(409, 'reservation_conflict'));
  await policy.reserve('user-b', id);
  assert.equal(store.data.get(`ai_gateway_usage/user-b/days/${a.dayKey}`).chats, 1);
  assert.equal(usage(store, Date.now()), 1);
});
test('deletion between reserve and claim prevents inference and any later completion write', async () => {
  const { store, policy } = fixture(); const a = await policy.reserve('user-a', id);
  store.data.set('account_deletions/user-a', { state: 'requested' });
  await assert.rejects(policy.claim('user-a', id, 'plan', a.dayKey), error(403, 'account_deleting'));
  store.data.delete(`ai_gateway_reservations/user-a/requests/${id}`);
  await assert.rejects(policy.finish('user-a', id, 'plan', a.dayKey, 'unknown'), error(403, 'account_deleting'));
  assert.equal(job(store), undefined);
});
test('lost reserve commit ACK can retry without a second charge or invocation', async () => {
  const { store, policy } = fixture(); store.loseAckAt = 1;
  await assert.rejects(policy.reserve('user-a', id), error(503, 'policy_unavailable'));
  const a = await policy.reserve('user-a', id);
  assert.equal(a.state, 'reserved'); assert.equal(usage(store, Date.now()), 1);
  await policy.claim('user-a', id, 'plan', a.dayKey);
  await assert.rejects(policy.claim('user-a', id, 'plan', a.dayKey), error(409, 'request_already_sent'));
});
test('lost sent commit ACK cannot cause an automatic model replay', async () => {
  const { store, policy } = fixture(); const a = await policy.reserve('user-a', id);
  store.loseAckAt = 2;
  await assert.rejects(policy.claim('user-a', id, 'plan', a.dayKey), error(503, 'policy_unavailable'));
  await assert.rejects(policy.claim('user-a', id, 'plan', a.dayKey), error(409, 'request_already_sent'));
  assert.equal(usage(store, Date.now()), 1);
});
test('concurrency cap is per UID across UTC+7 day boundary, stale slots expire without refund', async () => {
  let now = Date.UTC(2026, 9, 30, 16, 59, 59); const { store, policy } = fixture({ now: () => now });
  const a = await policy.reserve('user-a', id);
  await policy.reserve('user-a', 'turn-request-0000002'); now += 2000;
  await assert.rejects(policy.reserve('user-a', 'turn-request-0000003'), error(429, 'concurrency_limited'));
  assert.notEqual(dayKey(now), a.dayKey);
  now += LEASE_MS;
  await policy.reserve('user-a', 'turn-request-0000003');
  await assert.rejects(policy.claim('user-a', id, 'plan', a.dayKey), error(409, 'request_expired'));
  assert.equal(usage(store, now), 1);
});
test('demo entitlement raises quota only with explicit trusted server flag', async () => {
  const now = Date.now(); const { store, policy } = fixture({ now: () => now });
  store.data.set('demo_premium_accounts/user-a', { mode: 'demo', planId: 'premium_demo_30d', startedAt: now - 100, expiresAt: now - 100 + 30 * 86400000 });
  store.data.set(`ai_gateway_usage/user-a/days/${dayKey(now)}`, { dayKey: dayKey(now), chats: 5 });
  await assert.rejects(policy.reserve('user-a', id), error(429, 'quota_exceeded'));
  const enabled = new AiPolicy(store, { now: () => now, premiumDemo: true });
  await enabled.reserve('user-a', id); assert.equal(usage(store, now), 6);
});
test('provider timeout retains quota, becomes unknown and retry cannot call model again', async () => {
  const { store, policy } = fixture(); let calls = 0;
  const handler = createHandler(async () => ({ uid: 'user-a', authTime: 1 }), { policyFactory: () => policy, modelTimeoutMs: 10 });
  const env = bindings(() => { calls++; return new Promise(() => {}); });
  assert.equal((await handler(request(), env)).status, 504);
  assert.equal(job(store).state, 'unknown'); assert.equal(usage(store, Date.now()), 1);
  assert.equal((await handler(request(), env)).status, 409); assert.equal(calls, 1);
});
test('provider 429 returns safe failure, retains charge and releases concurrency slot', async () => {
  const { store, policy } = fixture();
  const handler = createHandler(async () => ({ uid: 'user-a', authTime: 1 }), { policyFactory: () => policy });
  const response = await handler(request(), bindings(async () => { throw new Error('429 private provider diagnostic'); }));
  assert.equal(response.status, 429); assert.deepEqual(await response.json(), { error: 'quota_exceeded' });
  assert.equal(job(store).state, 'failed'); assert.equal(usage(store, Date.now()), 1);
  assert.deepEqual(store.data.get('ai_gateway_usage/user-a').active, {});
});
test('truncated stream and client cancellation retain quota as unknown', async () => {
  for (const cancel of [false, true]) {
    const { store, policy } = fixture();
    const handler = createHandler(async () => ({ uid: 'user-a', authTime: 1 }), { policyFactory: () => policy });
    assert.equal((await handler(request(), bindings())).status, 200);
    const response = await handler(request({ phase: 'answer' }), bindings(async () => new ReadableStream({
      start(c) { c.enqueue(new TextEncoder().encode('data: {"response":"partial"}\n\n')); if (!cancel) c.close(); },
    })));
    if (cancel) await response.body.cancel(); else await assert.rejects(response.text());
    assert.equal(job(store).state, 'unknown'); assert.equal(usage(store, Date.now()), 1);
  }
});
test('aborted request before reservation consumes nothing and never calls model', async () => {
  const { store, policy } = fixture(); const controller = new AbortController(); controller.abort(); let calls = 0;
  const handler = createHandler(async () => ({ uid: 'user-a', authTime: 1 }), { policyFactory: () => policy });
  assert.equal((await handler(request({ signal: controller.signal }), bindings(async () => { calls++; }))).status, 499);
  assert.equal(calls, 0); assert.equal(usage(store, Date.now()), 0);
});
