const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {before,beforeEach,after,test}=require('node:test');
const {initializeTestEnvironment,assertFails,assertSucceeds}=require('@firebase/rules-unit-testing');
const {doc,collection,getDoc,getDocs,setDoc,deleteDoc,writeBatch,serverTimestamp,onSnapshot}=require('firebase/firestore');
let env,op=0;
before(async()=>{const [host,port]=(process.env.FIRESTORE_EMULATOR_HOST||'127.0.0.1:8092').split(':');env=await initializeTestEnvironment({projectId:'demo-healthmate-exercise-rules',firestore:{host,port:Number(port),rules:fs.readFileSync(path.join(__dirname,'../firestore.rules'),'utf8')}});});
beforeEach(async()=>{await env.clearFirestore();await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'admin_roles/admin'),{enabled:true}));});
after(async()=>env?.cleanup());
const db=(uid,verified=true)=>env.authenticatedContext(uid,{email_verified:verified}).firestore();
const item=()=>({name:'Chống đẩy',sourceId:'Ab12345',region:'chest',equipment:'bodyweight',target:'Ngực',steps:['Đặt tay xuống sàn.','Hạ người.'],easier:'Chống tường.',isActive:true,schemaVersion:1});
function write(database,id,payload,before=null,patch={}){const batch=writeBatch(database),operation=`ex-${++op}`,after={...before,...payload,updatedAt:serverTimestamp(),updatedBy:'admin',lastAdminOperationId:operation};const changedFields=before?Object.keys(after).filter(k=>JSON.stringify(before[k])!==JSON.stringify(after[k])):Object.keys(after);batch.set(doc(database,'exercise_library',id),after);batch.set(doc(database,'admin_audit',operation),{actorUid:'admin',entityType:'exercise_library',entityId:id,at:serverTimestamp(),changedFields,reason:'Kiểm thử',...patch});return batch.commit();}
test('verified admin CRUD with atomic immutable audit, archive/restore preserves document',async()=>{const a=db('admin');await assertSucceeds(write(a,'push_up',item()));let original=(await getDoc(doc(a,'exercise_library/push_up'))).data();await assertSucceeds(write(a,'push_up',{name:'Tên mới',isActive:false},original));original=(await getDoc(doc(a,'exercise_library/push_up'))).data();assert.equal(original.isActive,false);await assertSucceeds(write(a,'push_up',{isActive:true},original));await assertFails(deleteDoc(doc(a,'exercise_library/push_up')));await assertSucceeds(getDocs(collection(db('alice'),'exercise_library')));await assertSucceeds(getDocs(collection(db('bob'),'exercise_library')));});

test('ExerciseDB browser draft publishes through the existing audited schema and is readable by a verified app user',async()=>{
  const {exerciseDbDraft}=await import('../admin-web/dist/exercisedb-browser-model.mjs');
  const {exercisePayload}=await import('../admin-web/dist/exercise-library-model.mjs');
  const draft=exerciseDbDraft({sourceId:'Qw12345',bodyParts:['chest'],equipments:['barbell'],targetMuscles:['pectorals']});
  const payload=exercisePayload({...draft,name:'Đẩy tạ đòn trên ghế',steps:['Đặt chân vững trên sàn.','Đẩy tạ có kiểm soát.'],easier:'Dùng mức tạ nhẹ hơn.'});
  await assertSucceeds(write(db('admin'),draft.id,payload));
  const received=(await assertSucceeds(getDoc(doc(db('alice'),'exercise_library',draft.id)))).data();
  assert.equal(received.sourceId,'Qw12345');assert.equal(received.sourceProvider,'exercisedb');assert.equal(received.name,'Đẩy tạ đòn trên ghế');assert.equal(received.gifUrl,undefined);assert.equal(received.instructions,undefined);
  assert.deepEqual(received.steps,payload.steps);
});

test('ExerciseDB-only female source supports audited CRUD and rejects other providers',async()=>{
  const a=db('admin'),id='edb-Nh3mvOO';
  await assertSucceeds(write(a,id,{...item(),sourceProvider:'exercisedb',sourceId:'Nh3mvOO'}));
  let original=(await getDoc(doc(a,'exercise_library',id))).data();
  await assertSucceeds(write(a,id,{name:'Kéo tạ đơn mẫu nữ đã sửa',isActive:false},original));
  original=(await getDoc(doc(a,'exercise_library',id))).data();
  await assertSucceeds(write(a,id,{isActive:true},original));
  await assertSucceeds(getDoc(doc(db('alice'),'exercise_library',id)));
  await assertFails(write(db('alice'),'custom',{...item(),sourceProvider:'exercisedb',sourceId:'Nh3mvOO'}));
  for(const patch of [{sourceProvider:'unknown'},{sourceProvider:'repdb',sourceId:'Nh3mvOO'},{sourceProvider:'repdb',sourceId:'glute-bridge'},{sourceProvider:4}])await assertFails(write(a,'invalid',{...item(),...patch}));
});

test('users, guests, unverified and suspended admins cannot write; active verified reads only',async()=>{for(const database of [db('alice'),db('bob'),db('admin',false),env.unauthenticatedContext().firestore()])await assertFails(write(database,'custom',item()));await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(),'exercise_library')));await assertFails(getDocs(collection(db('alice',false),'exercise_library')));await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'account_controls/admin'),{status:'suspended'}));await assertFails(write(db('admin'),'custom',item()));await assertFails(getDocs(collection(db('admin'),'exercise_library')));});
test('missing or forged audit, invalid schema and persisted GIF URLs denied',async()=>{const a=db('admin');await assertFails(setDoc(doc(a,'exercise_library/no-audit'),item()));for(const patch of [{actorUid:'alice'},{entityId:'wrong'},{entityType:'food_catalog'},{changedFields:['name']}])await assertFails(write(a,'custom',item(),null,patch));for(const patch of [{sourceId:'url'},{steps:['one']},{steps:['a',3]},{steps:Array(7).fill('a')},{region:'bad'},{equipment:'bad'},{name:'x'.repeat(121)},{gifUrl:'https://example.com/a.gif'},{schemaVersion:2},{isActive:'false'}])await assertFails(write(a,'custom',{...item(),...patch}));});

test('verified user receives live admin create/edit/archive/restore/add snapshots without reloading', {timeout:90000}, async()=>{
  const admin=db('admin');
  let latest=null, failure=null, waiting=null;
  const within=(promise,label)=>{
    let timer;
    return Promise.race([promise,new Promise((_,reject)=>{timer=setTimeout(()=>reject(Error(`Timed out: ${label}`)),12000);})]).finally(()=>clearTimeout(timer));
  };
  const waitFor=(predicate,label)=>{
    if(failure)return Promise.reject(failure);
    if(latest&&predicate(latest))return Promise.resolve(latest);
    return within(new Promise((resolve,reject)=>{waiting={predicate,resolve,reject};}),label).finally(()=>{waiting=null;});
  };
  // Keep one normal-user subscription for the entire sequence. Ignore cache-only
  // results so every assertion proves an emulator/server-delivered update.
  const unsubscribe=onSnapshot(collection(db('alice'),'exercise_library'),{includeMetadataChanges:true},snapshot=>{
    if(snapshot.metadata.fromCache||snapshot.metadata.hasPendingWrites)return;
    latest=new Map(snapshot.docs.map(entry=>[entry.id,entry.data()]));
    if(waiting&&waiting.predicate(latest))waiting.resolve(latest);
  },error=>{failure=error;waiting?.reject(error);});
  try{
    await waitFor(entries=>entries.size===0,'initial server snapshot');
    await within(write(admin,'live_push_up',item()),'admin create');
    let received=await waitFor(entries=>entries.get('live_push_up')?.name==='Chống đẩy','created exercise snapshot');
    assert.equal(received.get('live_push_up').isActive,true);
    let original=(await within(getDoc(doc(admin,'exercise_library/live_push_up')),'read created exercise')).data();
    await within(write(admin,'live_push_up',{name:'Chống đẩy đã chỉnh sửa'},original),'admin edit');
    await waitFor(entries=>entries.get('live_push_up')?.name==='Chống đẩy đã chỉnh sửa','edited name snapshot');
    original=(await within(getDoc(doc(admin,'exercise_library/live_push_up')),'read edited exercise')).data();
    await within(write(admin,'live_push_up',{isActive:false},original),'admin archive');
    received=await waitFor(entries=>entries.get('live_push_up')?.isActive===false,'archived exercise snapshot');
    assert.equal(received.get('live_push_up').name,'Chống đẩy đã chỉnh sửa');
    original=(await within(getDoc(doc(admin,'exercise_library/live_push_up')),'read archived exercise')).data();
    await within(write(admin,'live_push_up',{isActive:true},original),'admin restore');
    await waitFor(entries=>entries.get('live_push_up')?.isActive===true,'restored exercise snapshot');
    await within(write(admin,'live_second',{...item(),sourceId:'Cd67890',name:'Bài tập mới trực tiếp'}),'admin add second exercise');
    received=await waitFor(entries=>entries.size===2&&entries.get('live_second')?.name==='Bài tập mới trực tiếp','new exercise snapshot');
    assert.equal(received.get('live_second').isActive,true);
    assert.equal(received.get('live_push_up').name,'Chống đẩy đã chỉnh sửa');
    assert.equal(received.get('live_push_up').isActive,true);
  }finally{
    unsubscribe();
  }
});
