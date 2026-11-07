const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { before, beforeEach, after, test } = require('node:test');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp, Timestamp } = require('firebase/firestore');
let env;
before(async () => {
  const [host,port] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8092').split(':');
  env = await initializeTestEnvironment({ projectId:'demo-healthmate-admin-rules',firestore:{host,port:Number(port),rules:fs.readFileSync(path.join(__dirname,'..','firestore.rules'),'utf8')} });
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db=context.firestore(), batch=writeBatch(db);
    batch.set(doc(db,'admin_roles/admin'),{enabled:true});
    batch.set(doc(db,'users/alice'),{displayName:'Alice',email:'alice@example.com'});
    batch.set(doc(db,'users/alice/meal_logs/private'),{totalKcal:123});
    batch.set(doc(db,'user_directory/alice'),{displayName:'Alice',email:'alice@example.com',createdAt:Timestamp.fromMillis(1),updatedAt:Timestamp.fromMillis(1)});
    await batch.commit();
  });
});
after(async()=>env.cleanup());
const db = uid => env.authenticatedContext(uid,{email:`${uid}@example.com`,email_verified:true}).firestore();
const food = () => ({name:'Cơm fixture',alternateNames:['cơm'],category:'Ngũ cốc',servingBasis:'per_100g',unit:'g',kcalPer100g:130,proteinGPer100g:2.69,carbsGPer100g:28.17,fatGPer100g:0.28,fiberGPer100g:null,sourceLabel:'USDA fixture',sourceUrl:'https://fdc.nal.usda.gov/',isEstimated:false,isActive:true,servingLabel:null,servingGrams:null});
let operation=0;
function mutation(database,kind,id,payload,{before=null,auditPatch={},targetPatch={},changes=null}={}) {
  const auditId=`op-${++operation}`,batch=writeBatch(database);
  const after={...before,...payload,updatedAt:serverTimestamp(),updatedBy:'admin',lastAdminOperationId:auditId,...targetPatch};
  const keys=changes ?? (kind==='food_catalog' && before ? Object.keys(after).filter(k=>JSON.stringify(after[k])!==JSON.stringify(before[k])) : Object.keys(after));
  batch.set(doc(database,kind,id),after);
  batch.set(doc(database,'admin_audit',auditId),{actorUid:'admin',entityType:kind,entityId:id,at:serverTimestamp(),changedFields:keys,reason:'Kiểm thử local',...auditPatch});
  return {commit:()=>batch.commit(),auditId};
}
test('admin catalog changes require atomic audit; preserves legacy data and archives without deleting',async()=>{
  const a=db('admin');
  await assertFails(setDoc(doc(a,'food_catalog/rice'),food()));
  const create=mutation(a,'food_catalog','rice',food());await assertSucceeds(create.commit());
  const original=(await getDoc(doc(a,'food_catalog/rice'))).data();
  await env.withSecurityRulesDisabled(c=>updateDoc(doc(c.firestore(),'food_catalog/rice'),{legacySource:{id:'preserve'}}));
  const before={...original,legacySource:{id:'preserve'}};
  const edit=mutation(a,'food_catalog','rice',{isActive:false},{before});await assertSucceeds(edit.commit());
  assert.deepEqual((await getDoc(doc(a,'food_catalog/rice'))).data().legacySource,{id:'preserve'});
  await assertFails(mutation(a,'food_catalog','rice',{legacySource:{id:'overwrite'}},{before:(await getDoc(doc(a,'food_catalog/rice'))).data()}).commit());
  await assertFails(deleteDoc(doc(a,'food_catalog/rice')));
  await assertFails(updateDoc(doc(a,'admin_audit',create.auditId),{reason:'rewrite'}));
  await assertFails(deleteDoc(doc(a,'admin_audit',create.auditId)));
});
test('an assigned admin role does not bypass email verification',async()=>{
  for(const claims of [{email_verified:false},{}]) {
    const unverified=env.authenticatedContext('admin',{email:'admin@example.com',...claims}).firestore();
    await assertFails(getDocs(collection(unverified,'user_directory')));
    await assertFails(getDocs(collection(unverified,'admin_audit')));
    await assertFails(mutation(unverified,'food_catalog','rice',food()).commit());
  }
});

test('only admin can inspect another directory account role; nobody can list or grant roles',async()=>{
  await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'admin_roles/protected'),{enabled:false}));
  await assertSucceeds(getDoc(doc(db('admin'),'admin_roles/protected')));
  await assertSucceeds(getDoc(doc(db('admin'),'admin_roles/alice')));
  await assertFails(getDoc(doc(db('alice'),'admin_roles/protected')));
  await assertFails(getDocs(collection(db('admin'),'admin_roles')));
  await assertFails(setDoc(doc(db('admin'),'admin_roles/alice'),{enabled:true}));
  await assertFails(deleteDoc(doc(db('admin'),'admin_roles/admin')));
});

test('roles cannot be self-granted; ordinary users and guests cannot administer or read directory/audit',async()=>{
  for(const a of [db('alice'),env.unauthenticatedContext().firestore()]) {
    await assertFails(setDoc(doc(a,'admin_roles/alice'),{enabled:true}));
    await assertFails(mutation(a,'food_catalog','rice',food()).commit());
    for(const col of ['admin_roles','user_directory','account_controls','admin_audit']) await assertFails(getDocs(collection(a,col)));
    await assertFails(getDoc(doc(a,'account_controls/bob')));
  }
  await assertSucceeds(getDoc(doc(db('alice'),'admin_roles/alice')));
  await assertSucceeds(getDoc(doc(db('alice'),'account_controls/alice')));
  await assertFails(getDoc(doc(db('admin'),'users/alice')));
  await assertFails(getDoc(doc(db('admin'),'users/alice/meal_logs/private')));
  await assertSucceeds(getDocs(collection(db('admin'),'user_directory')));
});
test('catalog validation rejects invalid and missing nutrients, aliases, source, mass and unexpected fields',async()=>{
  const a=db('admin');
  for(const patch of [{kcalPer100g:-1},{fatGPer100g:NaN},{proteinGPer100g:Infinity},{carbsGPer100g:'2'},{carbsGPer100g:100,proteinGPer100g:50},{fiberGPer100g:101},{alternateNames:['ok',7]},{alternateNames:Array(9).fill('x')},{sourceUrl:'javascript:alert(1)'},{servingLabel:'bát',servingGrams:null},{servingGrams:0},{isEstimated:'false'},{secret:'no'}]) {
    await assertFails(mutation(a,'food_catalog','invalid',{...food(),...patch}).commit());
  }
  const missing=food();delete missing.fatGPer100g;
  await assertFails(mutation(a,'food_catalog','missing',missing).commit());
  await assertFails(mutation(a,'food_catalog','Invalid_ID',food()).commit());
  await assertSucceeds(mutation(a,'food_catalog','known-zero',{...food(),fiberGPer100g:0}).commit());
});
test('audit cannot be forged, reused, orphaned or mismatched; failures leave target absent',async()=>{
  const a=db('admin');
  for(const options of [{auditPatch:{actorUid:'alice'}},{auditPatch:{entityId:'elsewhere'}},{auditPatch:{at:Timestamp.fromMillis(0)}},{auditPatch:{reason:''}},{auditPatch:{changedFields:['name']}},{targetPatch:{updatedBy:'alice'}},{targetPatch:{updatedAt:Timestamp.fromMillis(0)}}]) {
    await assertFails(mutation(a,'food_catalog','forged',food(),options).commit());
    assert.equal((await getDoc(doc(a,'food_catalog/forged'))).exists(),false);
  }
  await assertFails(setDoc(doc(a,'admin_audit/orphan'),{actorUid:'admin',entityType:'food_catalog',entityId:'missing',at:serverTimestamp(),changedFields:['name'],reason:'orphan'}));
  const create=mutation(a,'food_catalog','rice',food());await assertSucceeds(create.commit());
  await assertFails(updateDoc(doc(a,'food_catalog/rice'),{name:'No new audit',updatedAt:serverTimestamp()}));
});
test('suspension blocks owner health reads/writes and catalog but allows status; reopening restores access',async()=>{
  const a=db('admin'),user=db('alice');
  await assertSucceeds(mutation(a,'food_catalog','rice',food()).commit());
  await assertSucceeds(mutation(a,'account_controls','alice',{status:'suspended',reason:'Lý do hiển thị'}).commit());
  for(const path of ['users/alice','users/alice/meal_logs/private','food_catalog/rice','app_config/runtime']) await assertFails(getDoc(doc(user,path)));
  await assertFails(deleteDoc(doc(user,'users/alice/meal_logs/private')));
  await assertFails(updateDoc(doc(user,'account_controls/alice'),{status:'active'}));
  assert.equal((await assertSucceeds(getDoc(doc(user,'account_controls/alice')))).data().reason,'Lý do hiển thị');
  const before=(await getDoc(doc(a,'account_controls/alice'))).data();
  await assertSucceeds(mutation(a,'account_controls','alice',{status:'active',reason:'Mở lại'},{before}).commit());
  await assertSucceeds(getDoc(doc(user,'users/alice/meal_logs/private')));
  await assertSucceeds(getDoc(doc(user,'food_catalog/rice')));
});
test('account controls protect admin/self, require directory and status validation',async()=>{
  const a=db('admin');
  for(const id of ['admin','unknown']) await assertFails(mutation(a,'account_controls',id,{status:'suspended',reason:'Test'}).commit());
  await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'admin_roles/alice'),{enabled:false}));
  await assertFails(mutation(a,'account_controls','alice',{status:'suspended',reason:'Test'}).commit());
  await env.withSecurityRulesDisabled(c=>deleteDoc(doc(c.firestore(),'admin_roles/alice')));
  for(const patch of [{status:'deleted'},{reason:''},{reason:'x'.repeat(201)},{secret:true}]) await assertFails(mutation(a,'account_controls','alice',{status:'active',reason:'Test',...patch}).commit());
});
test('runtime config is validated, admin-only, audited; role revocation denies subsequent mutation',async()=>{
  const a=db('admin'),payload={chatbotEnabled:false,foodScannerEnabled:true,maintenanceMode:true,maintenanceMessage:'Đang bảo trì'};
  await assertSucceeds(mutation(a,'app_config','runtime',payload).commit());
  await assertSucceeds(getDoc(doc(db('alice'),'app_config/runtime')));
  const before=(await getDoc(doc(a,'app_config/runtime'))).data();
  for(const patch of [{maintenanceMessage:''},{chatbotEnabled:'true'},{apiKey:'forbidden'}]) await assertFails(mutation(a,'app_config','runtime',{...payload,...patch},{before}).commit());
  await assertFails(mutation(a,'app_config','other',payload).commit());
  await assertFails(mutation(db('alice'),'app_config','runtime',payload,{before}).commit());
  await env.withSecurityRulesDisabled(c=>updateDoc(doc(c.firestore(),'admin_roles/admin'),{enabled:false}));
  await assertFails(mutation(a,'app_config','runtime',{...payload,maintenanceMode:false},{before}).commit());
});
test('directory sync accepts only owner minimal metadata matching profile/token and immutable createdAt',async()=>{
  const user=db('alice'),ref=doc(user,'user_directory/alice');
  const before=(await getDoc(ref)).data();
  await assertSucceeds(setDoc(ref,{...before,updatedAt:serverTimestamp()}));
  for(const patch of [{displayName:'Forged'},{email:'someone@example.com'},{weightKg:60},{createdAt:Timestamp.fromMillis(0)}]) await assertFails(updateDoc(ref,{...patch,updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(db('admin'),'user_directory/alice'),{displayName:'Admin rewrite',updatedAt:serverTimestamp()}));
  await assertFails(getDoc(doc(db('bob'),'user_directory/alice')));
  await assertSucceeds(deleteDoc(ref));
  await assertSucceeds(setDoc(ref,{displayName:'Alice',email:'alice@example.com',createdAt:serverTimestamp(),updatedAt:serverTimestamp()}));
});

test('Auth aggregate is get-only for verified admin; other accounts, guests and every client write are denied',async()=>{
  const payload={schemaVersion:1,source:'firebase_auth',method:'manual_snapshot',totalRegisteredAccounts:42,updatedAt:Timestamp.now()};
  await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'admin_statistics/accounts'),payload));
  const a=db('admin');
  assert.equal((await assertSucceeds(getDoc(doc(a,'admin_statistics/accounts')))).data().totalRegisteredAccounts,42);
  for(const context of [db('alice'),db('bob'),env.unauthenticatedContext().firestore(),
    env.authenticatedContext('admin',{email_verified:false}).firestore()]) {
    await assertFails(getDoc(doc(context,'admin_statistics/accounts')));
    await assertFails(setDoc(doc(context,'admin_statistics/accounts'),payload));
  }
  await assertFails(getDocs(collection(a,'admin_statistics')));
  await assertFails(getDoc(doc(a,'admin_statistics/other')));
  await assertFails(setDoc(doc(a,'admin_statistics/accounts'),payload));
  await assertFails(updateDoc(doc(a,'admin_statistics/accounts'),{totalRegisteredAccounts:999}));
  await assertFails(deleteDoc(doc(a,'admin_statistics/accounts')));
  await assertFails(getDoc(doc(a,'users/alice')));
  await env.withSecurityRulesDisabled(c=>updateDoc(doc(c.firestore(),'admin_roles/admin'),{enabled:false}));
  await assertFails(getDoc(doc(a,'admin_statistics/accounts')));
});


test('realtime aggregates remain admin-only and revisions cannot be forged or read across UIDs',async()=>{
  await env.withSecurityRulesDisabled(async context=>{
    await setDoc(doc(context.firestore(),'user_sync/alice'),{meal_logs:serverTimestamp()});
    await setDoc(doc(context.firestore(),'admin_statistics/operations'),{schemaVersion:1,ready:true,foods:0,accounts:0,suspended:0,audits:0});
  });
  await assertSucceeds(getDoc(doc(db('alice'),'user_sync/alice')));
  await assertFails(getDoc(doc(db('bob'),'user_sync/alice')));
  await assertFails(getDoc(doc(db('admin'),'user_sync/alice')));
  await assertFails(setDoc(doc(db('alice'),'user_sync/alice'),{meal_logs:serverTimestamp()}));
  await assertFails(setDoc(doc(db('admin'),'user_sync/alice'),{meal_logs:serverTimestamp()}));
  await assertSucceeds(getDoc(doc(db('admin'),'admin_statistics/operations')));
  await assertFails(getDoc(doc(db('alice'),'admin_statistics/operations')));
  await assertFails(setDoc(doc(db('admin'),'admin_statistics/operations'),{foods:999}));
});
