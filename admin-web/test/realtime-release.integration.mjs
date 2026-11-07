import test from 'node:test';import assert from 'node:assert/strict';import fs from 'node:fs';import {createRequire} from 'node:module';
const require=createRequire(new URL('../../rules-tests/package.json',import.meta.url));
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,getDoc,setDoc}=require('firebase/firestore');let env;
test.before(async()=>{
  env=await initializeTestEnvironment({projectId:'demo-healthmate-realtime-release',firestore:{host:'127.0.0.1',port:8092,rules:fs.readFileSync(process.env.HEALTHMATE_REALTIME_REVIEW_RULES??new URL('../../build/realtime-review-20261106-v2/firestore.rules',import.meta.url),'utf8')}});
  await env.withSecurityRulesDisabled(async context=>{const db=context.firestore();await setDoc(doc(db,'admin_roles/admin'),{enabled:true});await setDoc(doc(db,'admin_statistics/operations'),{ready:true,foods:1});await setDoc(doc(db,'user_sync/alice'),{meal_logs:1});});
});
test.after(()=>env?.cleanup());
const db=uid=>env.authenticatedContext(uid,{email_verified:true,email:`${uid}@example.test`}).firestore();
test('prepared production Rules expose aggregates to a verified active admin only',async()=>{
  await assertSucceeds(getDoc(doc(db('admin'),'admin_statistics/operations')));
  await assertFails(getDoc(doc(db('alice'),'admin_statistics/operations')));
  await assertFails(setDoc(doc(db('admin'),'admin_statistics/operations'),{foods:999}));
});
test('prepared production Rules keep revision timestamps private and server-written',async()=>{
  await assertSucceeds(getDoc(doc(db('alice'),'user_sync/alice')));
  await assertFails(getDoc(doc(db('bob'),'user_sync/alice')));
  await assertFails(getDoc(doc(db('admin'),'user_sync/alice')));
  await assertFails(setDoc(doc(db('alice'),'user_sync/alice'),{meal_logs:999}));
});
test('a deleted or suspended admin cannot retain aggregate access using an old verified ID token',async()=>{
  await env.withSecurityRulesDisabled(context=>setDoc(doc(context.firestore(),'account_controls/admin'),{status:'suspended'}));
  await assertFails(getDoc(doc(db('admin'),'admin_statistics/operations')));
});
