const fs = require('node:fs');
const path = require('node:path');
const { before, after, beforeEach, test } = require('node:test');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, getDoc, deleteDoc, serverTimestamp, Timestamp } = require('firebase/firestore');
let env;
before(async () => { env = await initializeTestEnvironment({ projectId: 'demo-healthmate-activity-energy',
  firestore: { rules: fs.readFileSync(process.env.HEALTHMATE_RULES_FILE || path.resolve(__dirname, '..', 'firestore.rules'), 'utf8') } }); });
after(async () => env?.cleanup());
beforeEach(async () => env.clearFirestore());
const db = uid => env.authenticatedContext(uid, { email_verified: true }).firestore();
const at = new Date('2026-11-15T03:00:00Z');
const estimate = () => ({ formulaVersion: 1, metCode: '02022', weightKg: 60,
  weightMeasuredAtMillis: at.getTime() - 86400000, ageYears: 26, durationSeconds: 1817,
  budgetTargetFromDateKey: null, budgetBaseKcal: null });
const data = () => ({ activityType: 'strength', durationMinutes: 30, performedAt: Timestamp.fromDate(at),
  dateKey: '2026-11-15', timezoneOffsetMinutes: 420, note: '',
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), energyEstimate: estimate() });

test('owner CRUD energy snapshot and explicit budget; cross UID is rejected', async () => {
  const a = db('alice'), b = db('bob'), ref = doc(a, 'users/alice/activity_logs/energy');
  await assertSucceeds(setDoc(ref, data()));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(updateDoc(ref, { energyEstimate: { ...estimate(), budgetTargetFromDateKey: '2026-11-01', budgetBaseKcal: 1800 }, updatedAt: serverTimestamp() }));
  await assertFails(getDoc(doc(b, ref.path)));
  await assertFails(setDoc(doc(b, ref.path), data()));
  await assertFails(deleteDoc(doc(b, ref.path)));
  await assertSucceeds(updateDoc(ref, { energyEstimate: null, updatedAt: serverTimestamp() }));
  await assertSucceeds(deleteDoc(ref));
});
test('legacy minutes-only logs remain editable', async () => {
  const ref = doc(db('alice'), 'users/alice/activity_logs/legacy');
  const d = data(); delete d.energyEstimate;
  await assertSucceeds(setDoc(ref, d));
  await assertSucceeds(updateDoc(ref, { note: 'updated', updatedAt: serverTimestamp() }));
});
test('reject forged totals, sources, effort, age, future weights and duration mismatches', async () => {
  const a = db('alice');
  for (const patch of [{formulaVersion:2}, {metCode:'99999'}, {metCode:'17190'}, {met:99},
    {activeKcal:9999}, {weightKg:-1}, {weightKg:NaN}, {weightKg:501}, {ageYears:18}, {ageYears:60},
    {weightMeasuredAtMillis:at.getTime()+1}, {durationSeconds:1799}, {durationSeconds:1860},
    {budgetTargetFromDateKey:'2026-11-01'}, {budgetBaseKcal:1800},
    {budgetTargetFromDateKey:'2026-11-16',budgetBaseKcal:1800},
    {budgetTargetFromDateKey:'2026-02-30',budgetBaseKcal:1800}]) {
    await assertFails(setDoc(doc(a, 'users/alice/activity_logs/bad'), {...data(),energyEstimate:{...estimate(),...patch}}));
  }
  await assertFails(setDoc(doc(a, 'users/alice/activity_logs/bad'), {...data(), caloriesBurned:9999}));
  const unverified = env.authenticatedContext('alice', {email_verified:false}).firestore();
  await assertFails(setDoc(doc(unverified, 'users/alice/activity_logs/bad'), data()));
});
