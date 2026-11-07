import test from 'node:test';
import assert from 'node:assert/strict';
import {dashboardPeriod,formatCount,formatMoney,registeredAccountSummary} from '../dist/dashboard-model.mjs';

test('dashboard periods use Vietnam midnight, inclusive days and calendar boundaries',() => {
  const now = new Date('2026-10-31T17:00:00Z');
  assert.deepEqual(dashboardPeriod('month',now),{start:'2026-11-01',end:'2026-11-01'});
  assert.deepEqual(dashboardPeriod('today',now),{start:'2026-11-01',end:'2026-11-01'});
  assert.deepEqual(dashboardPeriod('week',now),{start:'2026-10-26',end:'2026-11-01'});
  assert.deepEqual(dashboardPeriod('days30',now),{start:'2026-10-03',end:'2026-11-01'});
  assert.deepEqual(dashboardPeriod('month',new Date('2027-01-01T00:00:00Z')),{start:'2027-01-01',end:'2027-01-01'});
  assert.deepEqual(dashboardPeriod('week',new Date('2028-03-01T00:00:00Z')),{start:'2028-02-24',end:'2028-03-01'});
  assert.throws(() => dashboardPeriod('unknown'),/kỳ báo cáo/);
});

test('Auth summary requires trusted source, version, count and confirmed time; missing summary stays unknown',() => {
  const updatedAt = Date.now() - 10000;
  const valid = {schemaVersion:1,source:'firebase_auth',method:'manual_snapshot',totalRegisteredAccounts:0,updatedAt:{toMillis:() => updatedAt}};
  assert.deepEqual(registeredAccountSummary(valid),{count:0,updatedAt});
  assert.equal(registeredAccountSummary(null),null);
  for (const patch of [{schemaVersion:2},{source:'user_directory'},{method:'client'},{totalRegisteredAccounts:null},
    {totalRegisteredAccounts:-1},{updatedAt:null},{updatedAt:{toMillis:() => Date.now() + 600000}}])
    assert.throws(() => registeredAccountSummary({...valid,...patch}));
});

test('dashboard never formats missing, fractional, negative or unsafe counts as zero',() => {
  assert.equal(formatCount(0),'0');
  assert.equal(formatCount(12345),'12.345');
  assert.equal(formatMoney(40000),'40.000 ₫');
  for (const value of [null,undefined,NaN,-1,.5,Infinity,Number.MAX_SAFE_INTEGER + 1]) assert.throws(() => formatCount(value));
});
