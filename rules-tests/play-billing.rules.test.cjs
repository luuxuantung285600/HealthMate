const fs=require('node:fs');const path=require('node:path');const {test,before,beforeEach,after}=require('node:test');
const {initializeTestEnvironment,assertFails,assertSucceeds}=require('@firebase/rules-unit-testing');
const {doc,collection,setDoc,getDoc,getDocs,deleteDoc}=require('firebase/firestore');
let env;const db=uid=>env.authenticatedContext(uid,{email_verified:true}).firestore();
before(async()=>{const [host,port]=(process.env.FIRESTORE_EMULATOR_HOST||'127.0.0.1:8092').split(':');env=await initializeTestEnvironment({projectId:'demo-healthmate-play-rules',firestore:{host,port:Number(port),rules:fs.readFileSync(path.join(__dirname,'../firestore.rules'),'utf8')}});});
beforeEach(async()=>{await env.clearFirestore();await env.withSecurityRulesDisabled(async context=>{
  for(const [key,value] of Object.entries({'admin_roles/admin':{enabled:true},'premium_memberships/alice':{active:true,verified:true},'premium_transactions/order':{uid:'alice',netNanos:'29000000000000'},'billing_tokens/token':{uid:'alice',token:'private-receipt'},'billing_accounts/id':{uid:'alice'},'billing_locks/alice':{lease:'private'}}))await setDoc(doc(context.firestore(),key),value);
});});after(async()=>env?.cleanup());
test('only owner/admin can get verified membership; no membership listing or cross-user access',async()=>{
  await assertSucceeds(getDoc(doc(db('alice'),'premium_memberships/alice')));
  await assertSucceeds(getDoc(doc(db('admin'),'premium_memberships/alice')));
  await assertFails(getDoc(doc(db('bob'),'premium_memberships/alice')));
  await assertFails(getDocs(collection(db('alice'),'premium_memberships')));
  await assertFails(getDocs(collection(db('admin'),'premium_memberships')));
});
test('ledger admin-only; client and admin cannot forge, edit or remove money/entitlements',async()=>{
  await assertSucceeds(getDocs(collection(db('admin'),'premium_transactions')));
  await assertFails(getDoc(doc(db('alice'),'premium_transactions/order')));
  for(const uid of ['alice','admin'])for(const target of ['premium_memberships/alice','premium_transactions/order']){
    await assertFails(setDoc(doc(db(uid),target),{active:true,verified:true,netNanos:'999999999999999999999'}));
    await assertFails(deleteDoc(doc(db(uid),target)));
  }
});
test('tokens, account bindings and reconciliation leases never readable or writable by any client',async()=>{
  for(const uid of ['alice','bob','admin'])for(const target of ['billing_tokens/token','billing_accounts/id','billing_locks/alice','billing_requests/alice']){
    await assertFails(getDoc(doc(db(uid),target)));await assertFails(setDoc(doc(db(uid),target),{uid}));
  }
});
test('suspended, deleting, unauthenticated and unverified sessions denied',async()=>{
  await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'account_controls/alice'),{status:'suspended'}));
  await assertFails(getDoc(doc(db('alice'),'premium_memberships/alice')));
  await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'account_deletions/admin'),{state:'requested'}));
  await assertFails(getDocs(collection(db('admin'),'premium_transactions')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'premium_memberships/alice')));
  await assertFails(getDoc(doc(env.authenticatedContext('alice',{email_verified:false}).firestore(),'premium_memberships/alice')));
});
