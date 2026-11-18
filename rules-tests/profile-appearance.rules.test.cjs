const fs = require('node:fs');
const path = require('node:path');
const {before, after, beforeEach, test} = require('node:test');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, updateDoc, deleteDoc, serverTimestamp} = require('firebase/firestore');
let env;
before(async () => { env = await initializeTestEnvironment({projectId:'demo-healthmate-profile-appearance',
  firestore:{rules:fs.readFileSync(process.env.HEALTHMATE_RULES_FILE || path.resolve(__dirname, '..', 'firestore.rules'),'utf8')}}); });
after(async () => env?.cleanup());
beforeEach(async () => env.clearFirestore());
const client = (uid, verified = true) => env.authenticatedContext(uid,{email_verified:verified,email:`${uid}@example.com`}).firestore();
const image='iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6VSEAAAAASUVORK5CYII=';
const appearance = () => ({avatar:image,cover:image,background:image});
const profile = () => ({displayName:'Người dùng kiểm thử',email:'alice@example.com',heightCm:null,birthDate:null,
  healthGoal:null,targetWeightKg:null,onboardingCompletedAt:null,createdAt:serverTimestamp(),updatedAt:serverTimestamp(),schemaVersion:2});

test('owner saves identity, reads images and removes them without changing health fields', async () => {
  const db=client('alice'),ref=doc(db,'users/alice');
  await assertSucceeds(setDoc(ref,profile()));
  await assertSucceeds(updateDoc(ref,{displayName:'Nguyễn An',profileAppearance:appearance(),updatedAt:serverTimestamp()}));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(updateDoc(ref,{profileAppearance:{avatar:null,cover:null,background:null},updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(ref,{displayName:'Đổi tên tiếp',updatedAt:serverTimestamp()}));
  await assertSucceeds(deleteDoc(ref));
});

test('other UID, guest, unverified user and admin cannot read or rewrite private photos', async () => {
  const a=client('alice');
  await assertSucceeds(setDoc(doc(a,'users/alice'),{...profile(),profileAppearance:appearance()}));
  await env.withSecurityRulesDisabled(async context => setDoc(doc(context.firestore(),'admin_roles/admin'),{enabled:true}));
  for (const db of [client('bob'),env.unauthenticatedContext().firestore(),client('alice',false),client('admin')]) {
    const ref=doc(db,'users/alice');
    await assertFails(getDoc(ref));
    await assertFails(updateDoc(ref,{profileAppearance:appearance(),updatedAt:serverTimestamp()}));
    await assertFails(deleteDoc(ref));
  }
});

test('appearance only accepts the bounded thumbnail fields, never URLs or arbitrary payloads', async () => {
  const db=client('alice'),ref=doc(db,'users/alice');
  await assertSucceeds(setDoc(ref,profile()));
  for (const invalid of [null,[],{...appearance(),uid:'bob'}, {cover:image,background:null},
      {...appearance(),avatar:'https://example.com/photo.png'}, {...appearance(),cover:'data:image/svg+xml,<svg></svg>'},
      {...appearance(),background:42}, {...appearance(),cover:'iVBORw0KGgo'+'A'.repeat(87384)}]) {
    await assertFails(updateDoc(ref,{profileAppearance:invalid,updatedAt:serverTimestamp()}));
  }
  // Three maximum-size strings still fit well below Firestore's document limit.
  const largest='iVBORw0KGgo'+'A'.repeat(87384-11);
  await assertSucceeds(updateDoc(ref,{profileAppearance:{avatar:largest,cover:largest,background:largest},updatedAt:serverTimestamp()}));
});

test('account suspension and deletion still block photo writes; deletion cleanup can remove profile', async () => {
  const db=client('alice'),ref=doc(db,'users/alice');
  await assertSucceeds(setDoc(ref,{...profile(),profileAppearance:appearance()}));
  await env.withSecurityRulesDisabled(async c => setDoc(doc(c.firestore(),'account_controls/alice'),{status:'suspended'}));
  await assertFails(updateDoc(ref,{profileAppearance:appearance(),updatedAt:serverTimestamp()}));
  await env.withSecurityRulesDisabled(async c => setDoc(doc(c.firestore(),'account_deletions/alice'),{state:'requested'}));
  await assertFails(updateDoc(ref,{displayName:'Không được ghi lại',updatedAt:serverTimestamp()}));
  await assertSucceeds(deleteDoc(ref));
});
