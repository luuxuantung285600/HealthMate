import { ApiError } from './protocol.mjs';
import { TrustedFirestore } from './trusted-firestore.mjs';

export const MAX_ACTIVE = 2;
export const LEASE_MS = 120000;
export const REQUEST_ID = /^[A-Za-z0-9_-]{16,80}$/;
export function dayKey(now) { return new Date(now + 7 * 3600000).toISOString().slice(0, 10); }
function integer(value, max) { return Number.isSafeInteger(value) && value >= 0 && value <= max; }
function validateUid(uid) {
  if (typeof uid !== 'string' || !uid || uid.length > 128 || uid.includes('/') || uid === '.' || uid === '..') throw new ApiError(401, 'unauthorized');
}
function validJob(job, uid, id, day) {
  return job?.uid === uid && job.feature === 'chat' && job.requestId === id && job.dayKey === day &&
    ['reserved', 'sent', 'completed', 'failed', 'unknown'].includes(job.state) &&
    ['pending', 'sent', 'completed', 'failed', 'unknown'].includes(job.plan) &&
    ['pending', 'sent', 'completed', 'failed', 'unknown'].includes(job.answer) &&
    integer(job.createdAt, Number.MAX_SAFE_INTEGER) && integer(job.updatedAt, Number.MAX_SAFE_INTEGER) &&
    integer(job.leaseUntil, Number.MAX_SAFE_INTEGER);
}
function checkPolicy(records, uid, now) {
  if (records.get(`account_deletions/${uid}`)) throw new ApiError(403, 'account_deleting');
  const control = records.get(`account_controls/${uid}`);
  if (control && control.status !== 'active') throw new ApiError(403, 'account_suspended');
  const config = records.get('app_config/runtime');
  if (!config || config.chatbotEnabled !== true || config.maintenanceMode !== false) throw new ApiError(403, 'feature_disabled');
  const profile = records.get(`users/${uid}`);
  // The profile is self-reported eligibility, not independently verified age.
  const birth = profile?.birthDate;
  const today = new Date(now + 7 * 3600000), born = new Date(birth);
  let age = today.getUTCFullYear() - born.getUTCFullYear();
  if (today.getUTCMonth() < born.getUTCMonth() || (today.getUTCMonth() === born.getUTCMonth() && today.getUTCDate() < born.getUTCDate())) age--;
  if (!Number.isFinite(birth) || age < 18 || age > 120 || !Number.isFinite(profile.onboardingCompletedAt)) {
    throw new ApiError(403, 'profile_ineligible');
  }
}
export class AiPolicy {
  constructor(store, { now = Date.now, premiumDemo = false, allowTestPurchases = false } = {}) { this.store = store; this.now = now; this.premiumDemo = premiumDemo; this.allowTestPurchases = allowTestPurchases; }
  paths(uid, id, day) {
    return [`account_deletions/${uid}`, `account_controls/${uid}`, 'app_config/runtime', `users/${uid}`,
      `demo_premium_accounts/${uid}`, `ai_gateway_usage/${uid}`, `ai_gateway_usage/${uid}/days/${day}`,
      `ai_gateway_reservations/${uid}/requests/${id}`, `premium_memberships/${uid}`];
  }
  async authorize(identity) { validateUid(identity.uid); await this.store.assertIdentity(identity); }
  async reserve(uid, id) {
    validateUid(uid);
    if (!REQUEST_ID.test(id ?? '')) throw new ApiError(400, 'request_id_required');
    const now = this.now(), day = dayKey(now), paths = this.paths(uid, id, day);
    return this.store.transaction(paths, records => {
      checkPolicy(records, uid, now);
      const previous = records.get(paths[7]);
      if (previous) {
        if (!validJob(previous, uid, id, previous.dayKey)) throw new ApiError(409, 'reservation_conflict');
        return { value: previous };
      }
      const membership = records.get(paths[4]);
      const verified = records.get(paths[8]);
      const paid = verified?.provider === 'google_play' && verified.verified === true && verified.active === true &&
        (verified.environment === 'production' || this.allowTestPurchases && verified.environment === 'test') &&
        ['SUBSCRIPTION_STATE_ACTIVE','SUBSCRIPTION_STATE_IN_GRACE_PERIOD','SUBSCRIPTION_STATE_CANCELED'].includes(verified.status) &&
        Number.isFinite(verified.startedAt) && verified.startedAt <= now && Number.isFinite(verified.expiresAt) && verified.expiresAt > now;
      const demo = this.premiumDemo && membership?.mode === 'demo' && membership.planId === 'premium_demo_30d' &&
        Number.isFinite(membership.startedAt) && membership.startedAt <= now && membership.expiresAt > now &&
        membership.expiresAt - membership.startedAt === 30 * 86400000;
      const limit = paid || demo ? 50 : 5;
      const usage = records.get(paths[6]);
      if (usage && (!integer(usage.chats, 50) || usage.dayKey !== day)) throw new ApiError(503, 'policy_invalid');
      const count = usage?.chats ?? 0;
      if (count >= limit) throw new ApiError(429, 'quota_exceeded');
      const parent = records.get(paths[5]);
      const leases = parent?.active ?? {};
      if (typeof leases !== 'object' || Array.isArray(leases) || Object.keys(leases).length > MAX_ACTIVE ||
        Object.entries(leases).some(([key, until]) => !REQUEST_ID.test(key) || !integer(until, Number.MAX_SAFE_INTEGER))) throw new ApiError(503, 'policy_invalid');
      const active = Object.fromEntries(Object.entries(leases).filter(([, until]) => until > now));
      if (Object.keys(active).length >= MAX_ACTIVE) throw new ApiError(429, 'concurrency_limited');
      active[id] = now + LEASE_MS;
      const job = { uid, feature: 'chat', requestId: id, dayKey: day, state: 'reserved', plan: 'pending', answer: 'pending',
        createdAt: now, updatedAt: now, leaseUntil: now + LEASE_MS };
      return { value: job, writes: [
        { path: paths[5], value: { active, updatedAt: now } },
        { path: paths[6], value: { uid, dayKey: day, chats: count + 1, updatedAt: now } },
        { path: paths[7], value: job },
      ] };
    });
  }
  async claim(uid, id, phase, day) {
    const now = this.now(), paths = this.paths(uid, id, day);
    return this.store.transaction(paths, records => {
      checkPolicy(records, uid, now);
      const job = records.get(paths[7]);
      if (!validJob(job, uid, id, day)) throw new ApiError(409, 'reservation_conflict');
      if (!['plan', 'answer'].includes(phase) || job[phase] !== 'pending' || ['failed', 'unknown', 'completed'].includes(job.state)) {
        throw new ApiError(409, 'request_already_sent');
      }
      if (phase === 'answer' && job.plan !== 'completed') throw new ApiError(409, 'plan_required');
      const active = { ...(records.get(paths[5])?.active ?? {}) };
      if (job.leaseUntil <= now || active[id] !== job.leaseUntil) throw new ApiError(409, 'request_expired');
      // Renew the same slot for a bounded phase, including startup+stream time.
      active[id] = now + LEASE_MS;
      const next = { ...job, state: 'sent', [phase]: 'sent', updatedAt: now, leaseUntil: now + LEASE_MS };
      return { value: next, writes: [{ path: paths[7], value: next }, { path: paths[5], value: { active, updatedAt: now } }] };
    });
  }
  async finish(uid, id, phase, day, outcome) {
    const now = this.now(), paths = this.paths(uid, id, day);
    return this.store.transaction(paths, records => {
      checkPolicy(records, uid, now);
      const job = records.get(paths[7]);
      if (!job || job.uid !== uid || job.requestId !== id || job.feature !== 'chat' || job.dayKey !== day || job[phase] !== 'sent') {
        throw new ApiError(409, 'reservation_conflict');
      }
      if (!['completed', 'failed', 'unknown'].includes(outcome)) throw new ApiError(503, 'policy_invalid');
      const terminal = outcome !== 'completed' || phase === 'answer';
      const next = { ...job, [phase]: outcome, state: terminal ? outcome : 'sent', updatedAt: now };
      const writes = [{ path: paths[7], value: next }];
      if (terminal) {
        const active = { ...(records.get(paths[5])?.active ?? {}) }; delete active[id];
        writes.push({ path: paths[5], value: { active, updatedAt: now } });
      }
      return { value: next, writes };
    });
  }
}
export function createTrustedPolicy(env) {
  return new AiPolicy(new TrustedFirestore(env), { premiumDemo: env.AI_GATEWAY_PREMIUM_DEMO === 'true', allowTestPurchases: env.AI_GATEWAY_ALLOW_TEST_PURCHASES === 'true' });
}
