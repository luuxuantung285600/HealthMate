import {registerHooks,createRequire} from 'node:module';import {pathToFileURL} from 'node:url';
import test from 'node:test';import assert from 'node:assert/strict';
const require=createRequire(new URL('../../rules-tests/package.json',import.meta.url));
const hooks=registerHooks({resolve(specifier,context,next){const match=/^https:\/\/www\.gstatic\.com\/firebasejs\/13\.0\.0\/firebase-(app|auth|firestore|app-check)\.js$/.exec(specifier);return match?{url:pathToFileURL(require.resolve(`firebase/${match[1]}`)).href,shortCircuit:true}:next(specifier,context);}});
const store=new Map();globalThis.window={sessionStorage:{setItem:(k,v)=>store.set(k,v),getItem:k=>store.get(k)??null,removeItem:k=>store.delete(k)}};globalThis.location={hostname:'127.0.0.1',protocol:'http:'};
const {connect}=await import('../dist/firebase.mjs');
const api=await connect({firebase:{apiKey:'demo-key',projectId:'demo-healthmate-admin',authDomain:'demo-healthmate-admin.firebaseapp.com'},statisticsMode:'firestore',emulators:{auth:'http://127.0.0.1:9098',firestoreHost:'127.0.0.1',firestorePort:8092}});
const base='http://127.0.0.1:8092/v1/projects/demo-healthmate-admin/databases/(default)/documents';
let user,stopRole;const stopAuth=api.authChanges(value=>user=value);
const pauses=ms=>new Promise(resolve=>setTimeout(resolve,ms));
async function write(path,fields){const response=await fetch(`${base}/${path}`,{method:fields?'PATCH':'DELETE',headers:{Authorization:'Bearer owner','Content-Type':'application/json',Connection:'close'},...(fields?{body:JSON.stringify({fields})}:{})});assert.ok(response.ok,`local fixture write failed ${response.status}`);await response.arrayBuffer();}
function stream(attach){let latest,fail;const stop=attach(value=>{latest=value;},error=>{if(!/Đang kết nối lại/.test(error.message))fail=error;});return{stop,get value(){return latest;},get error(){return fail;},async until(matches){const end=Date.now()+15000;while(Date.now()<end){if(fail)throw fail;if(latest!==undefined&&matches(latest))return latest;await pauses(40);}throw Error('Live SDK timeout; last emulator snapshot: '+JSON.stringify(latest));}};}
test.before(async()=>{await api.login('admin@healthmate.local','LocalHealthMate!2026');const gate=stream((next,error)=>api.role(user.uid,next,error));await gate.until(value=>value===true);stopRole=gate.stop;});
test.after(async()=>{api.stopAll();stopRole?.();const {disableNetwork,terminate,getFirestore}=require('firebase/firestore');await disableNetwork(getFirestore());await api.logout();stopAuth();await terminate(getFirestore());hooks.deregister();const {deleteApp,getApps}=require('firebase/app');await Promise.all(getApps().map(deleteApp));});

test('Spark operational totals update without Cloud Functions, exclude orphan locks and stop after disposal',async()=>{
  const {createLiveData}=await import('../dist/live-data.mjs');
  const spark=createLiveData(require('firebase/firestore').getFirestore(),()=>()=>{}, {statisticsMode:'firestore'});
  const live=stream((next,error)=>spark.watchCounts(next,error));
  const id=`rt-spark-${Date.now()}`;
  try {
    const before=await live.until(data=>Array.isArray(data));
    await write(`food_catalog/${id}`,{name:{stringValue:'Synthetic Spark emulator fixture'}});
    await live.until(data=>data[0]===before[0]+1);
    await write(`account_controls/${id}`,{status:{stringValue:'suspended'}});
    await pauses(150);assert.equal(live.value[2],before[2],'An absent directory account is not suspended');
    await write(`user_directory/${id}`,{displayName:{stringValue:'Synthetic Spark fixture'}});
    await live.until(data=>data[1]===before[1]+1&&data[2]===before[2]+1);
    await write(`user_directory/${id}`,null);
    await live.until(data=>data[1]===before[1]&&data[2]===before[2]);
    live.stop();spark.stopAll();const last=[...live.value];
    await write(`food_catalog/${id}`,null);await pauses(150);
    assert.deepEqual(live.value,last,'Disposed views must not receive late updates');
  } finally {
    live.stop();spark.stopAll();
    for(const kind of ['food_catalog','account_controls','user_directory'])await write(`${kind}/${id}`,null);
  }
});

test('real web page listener receives create, edit, archive, restore and delete without any reload',async()=>{
  const id=`rt-web-food-${Date.now()}`,live=stream((next,error)=>api.watchPage('food_catalog',{idFrom:id,idTo:id},next,error));
  try{await live.until(page=>page.rows.length===0);
    await write(`food_catalog/${id}`,{name:{stringValue:'Before'},isActive:{booleanValue:true}});await live.until(page=>page.rows[0]?.name==='Before');
    await write(`food_catalog/${id}`,{name:{stringValue:'After'},isActive:{booleanValue:false}});await live.until(page=>page.rows[0]?.isActive===false);
    await write(`food_catalog/${id}`,{name:{stringValue:'Restored'},isActive:{booleanValue:true}});await live.until(page=>page.rows[0]?.name==='Restored');
    await write(`food_catalog/${id}`,null);await live.until(page=>page.rows.length===0);
  }finally{live.stop();await write(`food_catalog/${id}`,null);}
});

test('directory page also listens to role/control changes even when the directory document stays unchanged',async()=>{
  const id=`rt-web-member-${Date.now()}`;await write(`user_directory/${id}`,{displayName:{stringValue:'New customer'}});
  const live=stream((next,error)=>api.watchPage('user_directory',{idFrom:id,idTo:id},next,error));
  try{await live.until(page=>page.rows.length===1&&page.rows[0].control===null);
    await write(`account_controls/${id}`,{status:{stringValue:'suspended'}});await live.until(page=>page.rows[0]?.control?.status==='suspended');
    await write(`admin_roles/${id}`,{enabled:{booleanValue:true}});await live.until(page=>page.rows[0]?.adminRole?.enabled===true);
    await write(`account_controls/${id}`,{status:{stringValue:'active'}});await live.until(page=>page.rows[0]?.control?.status==='active');
  }finally{live.stop();for(const kind of ['admin_roles','account_controls','user_directory'])await write(`${kind}/${id}`,null);}
});

test('period receipt listener receives insert and deletion across the full selected range',async()=>{
  const id=`rt-web-premium-${Date.now()}`,live=stream((next,error)=>api.watchRange('demo_premium_transactions',{start:'2031-01-01',end:'2031-01-01'},next,error));
  try{await live.until(rows=>rows.length===0);
    await write(`demo_premium_transactions/${id}`,{occurredAt:{timestampValue:'2031-01-01T05:00:00Z'},amountVnd:{integerValue:'20000'}});
    await live.until(rows=>rows.some(row=>row.id===id));
    await write(`demo_premium_transactions/${id}`,null);await live.until(rows=>rows.length===0);
  }finally{live.stop();await write(`demo_premium_transactions/${id}`,null);}
});

test('Spark Auth snapshot receives trusted manual refreshes while operational counts stay live',async()=>{
  const live=stream((next,error)=>api.watchRegisteredAccounts(next,error));
  const counts=stream((next,error)=>api.watchCounts(next,error));
  try{
    // Establish the server-confirmed target before importing REST fixtures.
    // Each subsequent assertion still requires the actual SDK update.
    await live.until(()=>true);await counts.until(data=>Array.isArray(data));
    await write('admin_statistics/accounts',{schemaVersion:{integerValue:'1'},source:{stringValue:'firebase_auth'},method:{stringValue:'manual_snapshot'},totalRegisteredAccounts:{integerValue:'2'},updatedAt:{timestampValue:new Date().toISOString()}});
    await live.until(data=>data?.method==='manual_snapshot'&&data.totalRegisteredAccounts===2);
    await write('admin_statistics/accounts',{schemaVersion:{integerValue:'1'},source:{stringValue:'firebase_auth'},method:{stringValue:'manual_snapshot'},totalRegisteredAccounts:{integerValue:'3'},updatedAt:{timestampValue:new Date().toISOString()}});
    await live.until(data=>data?.totalRegisteredAccounts===3);const before=await counts.until(data=>Array.isArray(data));
    const id=`rt-web-count-${Date.now()}`;await write(`food_catalog/${id}`,{name:{stringValue:'Counter fixture'}});
    await counts.until(data=>data[0]===before[0]+1);await write(`food_catalog/${id}`,null);await counts.until(data=>data[0]===before[0]);
  }finally{live.stop();counts.stop();}
});

test('cached first snapshots are not published before server confirmation',async()=>{
  const firestore=require('firebase/firestore'),db=firestore.getFirestore();
  const {createLiveData}=await import('../dist/live-data.mjs');
  const id=`rt-cache-${Date.now()}`;
  await write(`food_catalog/${id}`,{name:{stringValue:'Synthetic offline cache fixture'}});
  await firestore.getDocFromServer(firestore.doc(db,'food_catalog',id));
  const spark=createLiveData(db,()=>()=>{}, {statisticsMode:'firestore'});
  const received=[],errors=[];
  let stop;
  try {
    stop=spark.watchPage('food_catalog',{idFrom:id,idTo:id},value=>received.push(value),error=>{
      if(/Đang kết nối lại/.test(error.message))assert.equal(received.length,0,'Initial cache must not be presented as a server ACK');
      errors.push(error);
    });
    const reconnect=Date.now()+15000;
    while(!received.length&&Date.now()<reconnect)await pauses(25);
    assert.ok(errors.some(error=>/Đang kết nối lại/.test(error.message)),'Initial cache must be labeled unconfirmed');
    assert.equal(received.at(-1)?.rows[0]?.name,'Synthetic offline cache fixture');
  } finally {
    stop?.();spark.stopAll();
    await write(`food_catalog/${id}`,null);
  }
});

test('new support enters the first live page regardless of ID; timestamp cursors survive a deleted anchor',async()=>{
  const ids=Array.from({length:27},(_,i)=>String(i).padStart(20,'z')),fresh='AAAAAAAAAAAAAAAAAAAA';
  const fields=at=>({uid:{stringValue:'rt-customer'},type:{stringValue:'bug'},title:{stringValue:'Synthetic paging fixture'},description:{stringValue:'Emulator only'},status:{stringValue:'open'},messageCount:{integerValue:'0'},lastMessageId:{stringValue:''},updatedBy:{stringValue:'rt-customer'},deleting:{booleanValue:false},createdAt:{timestampValue:at},updatedAt:{timestampValue:at}});
  let live;
  try{
    for(const id of ids)await write(`support_tickets/${id}`,fields('2024-01-01T00:00:00.123456Z'));
    live=stream((next,error)=>api.watchPage('support_tickets',{},next,error));
    await live.until(page=>page.rows.length===25);
    await write(`support_tickets/${fresh}`,fields(new Date().toISOString()));
    await live.until(page=>page.rows[0]?.id===fresh);
    const first=await api.listPage('support_tickets');assert.equal(first.rows[0].id,fresh);
    assert.equal(first.cursor.nanoseconds,123456000);
    await write(`support_tickets/${first.cursor.id}`,null);
    const second=await api.listPage('support_tickets',{cursor:first.cursor});
    assert.equal(second.rows.length,3);
    assert.equal(new Set([...first.rows,...second.rows].map(row=>row.id)).size,28);
  }finally{live?.stop();for(const id of [...ids,fresh])await write(`support_tickets/${id}`,null);}
});

test('AI and maintenance configuration changes arrive through the actual web SDK listener',async()=>{
  const response=await fetch(`${base}/app_config/runtime`,{headers:{Authorization:'Bearer owner'}});assert.ok(response.ok);const before=await response.json();
  const live=stream((next,error)=>api.watchConfig(next,error));
  try{await live.until(data=>data!==null);
    const changed={...before.fields,chatbotEnabled:{booleanValue:false},maintenanceMode:{booleanValue:true},maintenanceMessage:{stringValue:'Synthetic live maintenance'}};
    await write('app_config/runtime',changed);await live.until(data=>data.maintenanceMessage==='Synthetic live maintenance'&&data.chatbotEnabled===false);
  }finally{live.stop();await write('app_config/runtime',before.fields);}
});

test('support parent and message listeners converge to one complete thread version',async()=>{
  const id='RtThreadFixture12345',messageId='RtMessageFixture1234',at=new Date().toISOString();
  const fields={uid:{stringValue:'rt-customer'},type:{stringValue:'bug'},title:{stringValue:'Synthetic realtime support'},description:{stringValue:'Initial request'},status:{stringValue:'open'},messageCount:{integerValue:'0'},lastMessageId:{stringValue:''},updatedBy:{stringValue:'rt-customer'},deleting:{booleanValue:false},createdAt:{timestampValue:at},updatedAt:{timestampValue:at}};
  await write(`support_tickets/${id}`,fields);
  const live=stream((next,error)=>api.watchSupportThread(id,next,error));
  try{await live.until(thread=>thread.messages.length===0);
    // Deliberately send child first: the UI must wait for the matching parent.
    await write(`support_tickets/${id}/messages/${messageId}`,{authorUid:{stringValue:'rt-customer'},role:{stringValue:'customer'},text:{stringValue:'New customer reply'},sequence:{integerValue:'1'},createdAt:{timestampValue:at}});
    await write(`support_tickets/${id}`,{...fields,messageCount:{integerValue:'1'},lastMessageId:{stringValue:messageId}});
    const thread=await live.until(thread=>thread.messages.length===1);assert.equal(thread.messages[0].text,'New customer reply');
    await write(`support_tickets/${id}`,{...fields,messageCount:{integerValue:'1'},deleting:{booleanValue:true}});
    for(let i=0;i<25&&!live.error;i++)await pauses(40);
    assert.match(live.error?.message??'',/không còn khả dụng/);
    await write(`support_tickets/${id}/messages/${messageId}`,{authorUid:{stringValue:'rt-customer'},role:{stringValue:'customer'},text:{stringValue:'Must not republish deleted thread'},sequence:{integerValue:'1'},createdAt:{timestampValue:at}});
    await pauses(120);assert.equal(live.value.messages[0].text,'New customer reply');
  }finally{live.stop();await write(`support_tickets/${id}/messages/${messageId}`,null);await write(`support_tickets/${id}`,null);}
});

test('exact email and UID lookup finds customers outside the first directory page and updates live',async()=>{
  const id='lookup-customer-z',email='lookup.customer@example.com';
  const earlier=Array.from({length:28},(_,i)=>`aa-lookup-customer-${i}`);let live,byUid;
  try{
    for(const id of earlier)await write(`user_directory/${id}`,{displayName:{stringValue:'Earlier fixture'},email:{stringValue:'other@example.com'}});
    await write(`user_directory/${id}`,{displayName:{stringValue:'Lookup fixture'},email:{stringValue:email}});
    assert.equal((await api.listPage('user_directory')).rows.some(row=>row.id===id),false);
    const options={lookupField:'email',lookupValue:email};
    let page;
    await assert.doesNotReject(async()=>{page=await api.listPage('user_directory',options);},'Exact email must be readable by admin');assert.deepEqual(page.rows.map(row=>row.id),[id]);
    await assert.doesNotReject(async()=>{page=await api.listPage('user_directory',{lookupField:'id',lookupValue:id});},'Exact UID must be readable by admin');assert.equal(page.rows[0].id,id);
    live=stream((next,error)=>api.watchPage('user_directory',options,next,error));await live.until(page=>page.rows.length===1);
    byUid=stream((next,error)=>api.watchPage('user_directory',{lookupField:'id',lookupValue:id},next,error));await byUid.until(page=>page.rows.length===1);
    await write(`user_directory/${id}`,{displayName:{stringValue:'Changed remotely'},email:{stringValue:email}});
    await live.until(page=>page.rows[0]?.displayName==='Changed remotely');await byUid.until(page=>page.rows[0]?.displayName==='Changed remotely');
    await write(`user_directory/${id}`,null);await live.until(page=>page.rows.length===0);
    await byUid.until(page=>page.rows.length===0);
  }finally{live?.stop();byUid?.stop();for(const key of [...earlier,id])await write(`user_directory/${key}`,null);}
});

test('food prefix search has identical live/read ordering and survives a deleted name cursor',async()=>{
  const ids=Array.from({length:28},(_,i)=>`lookup-food-${i}`),fresh='lookup-food-fresh';let live;
  const fields=name=>({name:{stringValue:name}});
  const options={lookupField:'name',lookupValue:'Lookup needle '};
  try{
    for(const [i,id]of ids.entries())await write(`food_catalog/${id}`,fields(`Lookup needle ${i+10}`));
    live=stream((next,error)=>api.watchPage('food_catalog',options,next,error));await live.until(page=>page.rows.length===25);
    await write(`food_catalog/${fresh}`,fields('Lookup needle 00'));await live.until(page=>page.rows[0]?.id===fresh);
    const first=await api.listPage('food_catalog',options);assert.deepEqual(first.rows.map(row=>row.id),live.value.rows.map(row=>row.id));
    assert.equal(typeof first.cursor.value,'string');await write(`food_catalog/${first.cursor.id}`,null);
    const second=await api.listPage('food_catalog',{...options,cursor:first.cursor});assert.equal(second.rows.length,4);
    assert.equal(new Set([...first.rows,...second.rows].map(row=>row.id)).size,29);
    await assert.rejects(api.listPage('food_catalog',{lookupField:'name',lookupValue:'Other',cursor:first.cursor}),/phạm vi/);
  }finally{live?.stop();for(const id of [...ids,fresh])await write(`food_catalog/${id}`,null);}
});

test('audit uses newest-first nanosecond cursors and exact Vietnam date exports',async()=>{
  const ids=Array.from({length:27},(_,i)=>`lookup-audit-z-${String(i).padStart(2,'0')}`),fresh='lookup-audit-A';
  const range={start:'2034-01-02',end:'2034-01-02'};let live;
  const fields=at=>({at:{timestampValue:at},entityType:{stringValue:'food_catalog'},entityId:{stringValue:'fixture'},actorUid:{stringValue:'fixture'},reason:{stringValue:'Local test only'},changedFields:{arrayValue:{values:[{stringValue:'name'}]}}});
  try{
    for(const id of ids)await write(`admin_audit/${id}`,fields('2034-01-01T17:00:00.123456Z'));
    live=stream((next,error)=>api.watchPage('admin_audit',range,next,error));await live.until(page=>page.rows.length===25);
    await write(`admin_audit/${fresh}`,fields('2034-01-01T17:00:01.123456Z'));await live.until(page=>page.rows[0]?.id===fresh);
    const first=await api.listPage('admin_audit',range);assert.equal(first.rows[0].id,fresh);assert.equal(first.cursor.nanoseconds,123456000);
    await write(`admin_audit/${first.cursor.id}`,null);
    const next=await api.listPage('admin_audit',{...range,cursor:first.cursor});assert.equal(next.rows.length,3);
    const exported=await api.exportRange('admin_audit',range);assert.equal(exported.length,27);assert.equal(exported[0].id,fresh);
    const before=await api.exportRange('admin_audit',{start:'2034-01-01',end:'2034-01-01'});assert.equal(before.length,0);
  }finally{live?.stop();for(const id of [...ids,fresh])await write(`admin_audit/${id}`,null);}
});
