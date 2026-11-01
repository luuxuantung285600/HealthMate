'use strict';
const {test, before, after, beforeEach} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc} = require('firebase/firestore');

const endpoint = process.env.FIRESTORE_EMULATOR_HOST || '';
if (!/^127\.0\.0\.1:\d+$/.test(endpoint)) throw new Error('An explicit local emulator is required.');
const port = Number(endpoint.split(':')[1]);
const source = fs.readFileSync(path.join(__dirname, '../build/firebase-access-hotfix-20261101/firestore.rules'), 'utf8');
const baseline = fs.readFileSync(path.join(__dirname, '../build/firebase-access-review-20261101/firestore.rules'), 'utf8');
let environment;
const db = (uid, verified = true) => environment.authenticatedContext(uid, {email_verified: verified}).firestore();

before(async () => {
  environment = await initializeTestEnvironment({projectId: 'demo-healthmate-access', firestore: {host: '127.0.0.1', port, rules: source}});
});
beforeEach(async () => environment.clearFirestore());
after(async () => environment?.cleanup());

test('the original deployed Rules reproduce denied startup reads for a verified owner', async () => {
  const old = await initializeTestEnvironment({projectId: 'demo-healthmate-access-before', firestore: {host: '127.0.0.1', port, rules: baseline}});
  try {
    const client = old.authenticatedContext('alice', {email_verified: true}).firestore();
    await assertFails(getDoc(doc(client, 'account_deletions/alice')));
  } finally { await old.cleanup(); }
});

test('the candidate changes only one isolated read-only match in the deployed source', () => {
  const start = source.indexOf('    // Compatibility for the client startup check.');
  const end = source.indexOf('    match /account_controls/{uid} {', start);
  assert.ok(start > 0 && end > start);
  assert.equal(source.slice(0, start) + source.slice(end), baseline);
});

test('a verified owner can observe server-confirmed absence and their own existing marker', async () => {
  const alice = db('alice');
  const empty = await assertSucceeds(getDoc(doc(alice, 'account_deletions/alice')));
  assert.equal(empty.exists(), false);
  await environment.withSecurityRulesDisabled(c => setDoc(doc(c.firestore(), 'account_deletions/alice'), {uid: 'alice', state: 'requested'}));
  const marker = await assertSucceeds(getDoc(doc(alice, 'account_deletions/alice')));
  assert.equal(marker.data().state, 'requested');
});

test('another UID, an unverified account and a guest cannot read the marker', async () => {
  await environment.withSecurityRulesDisabled(c => setDoc(doc(c.firestore(), 'account_deletions/alice'), {uid: 'alice'}));
  for (const client of [db('bob'), db('alice', false), environment.unauthenticatedContext().firestore()]) {
    await assertFails(getDoc(doc(client, 'account_deletions/alice')));
  }
});

test('no client can list, create, update or delete deletion markers', async () => {
  await environment.withSecurityRulesDisabled(async c => {
    await setDoc(doc(c.firestore(), 'account_deletions/alice'), {uid: 'alice'});
    await setDoc(doc(c.firestore(), 'admin_roles/admin'), {enabled: true});
  });
  for (const client of [db('alice'), db('admin')]) {
    await assertFails(getDocs(collection(client, 'account_deletions')));
    await assertFails(setDoc(doc(client, 'account_deletions/new'), {uid: 'new'}));
    await assertFails(updateDoc(doc(client, 'account_deletions/alice'), {state: 'cleaning'}));
    await assertFails(deleteDoc(doc(client, 'account_deletions/alice')));
  }
});

test('normal account and runtime checks work while private cross-UID access stays denied', async () => {
  await environment.withSecurityRulesDisabled(async c => {
    await setDoc(doc(c.firestore(), 'users/alice'), {displayName: 'Private fixture'});
    await setDoc(doc(c.firestore(), 'app_config/runtime'), {maintenanceMode: false});
  });
  await assertSucceeds(getDoc(doc(db('alice'), 'account_controls/alice')));
  await assertSucceeds(getDoc(doc(db('alice'), 'app_config/runtime')));
  await assertSucceeds(getDoc(doc(db('alice'), 'users/alice')));
  await assertFails(getDoc(doc(db('bob'), 'users/alice')));
  await assertFails(getDoc(doc(db('bob'), 'account_controls/alice')));
});

test('suspension still blocks product and runtime data without hiding the owner status check', async () => {
  await environment.withSecurityRulesDisabled(async c => {
    await setDoc(doc(c.firestore(), 'account_controls/alice'), {status: 'suspended'});
    await setDoc(doc(c.firestore(), 'users/alice'), {displayName: 'Private fixture'});
    await setDoc(doc(c.firestore(), 'app_config/runtime'), {maintenanceMode: false});
  });
  const alice = db('alice');
  await assertSucceeds(getDoc(doc(alice, 'account_deletions/alice')));
  const control = await assertSucceeds(getDoc(doc(alice, 'account_controls/alice')));
  assert.equal(control.data().status, 'suspended');
  await assertFails(getDoc(doc(alice, 'app_config/runtime')));
  await assertFails(getDoc(doc(alice, 'users/alice')));
});
