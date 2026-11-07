// Executes the production admin client against local emulators. The loader maps
// official CDN imports to the SAME Firebase 13.0.0 installed for Rules tests.
import {registerHooks,createRequire} from 'node:module';
import {pathToFileURL} from 'node:url';
import test from 'node:test';
import assert from 'node:assert/strict';
import {entityVersion,foodPayload} from '../dist/validation.mjs';
const require=createRequire(new URL('../../rules-tests/package.json',import.meta.url));
const hooks=registerHooks({resolve(specifier,context,next){
  const match=/^https:\/\/www\.gstatic\.com\/firebasejs\/13\.0\.0\/firebase-(app|auth|firestore|app-check)\.js$/.exec(specifier);
  if(match)return{url:pathToFileURL(require.resolve(`firebase/${match[1]}`)).href,shortCircuit:true};
  return next(specifier,context);
}});
const sessionStore=new Map();
globalThis.window={sessionStorage:{setItem:(k,v)=>sessionStore.set(k,v),getItem:k=>sessionStore.get(k)??null,removeItem:k=>sessionStore.delete(k)}};
globalThis.location={hostname:'127.0.0.1',protocol:'http:'};
const {connect}=await import('../dist/firebase.mjs');
const api=await connect({firebase:{apiKey:'demo-key',projectId:'demo-healthmate-admin',authDomain:'demo-healthmate-admin.firebaseapp.com'},emulators:{auth:'http://127.0.0.1:9098',firestoreHost:'127.0.0.1',firestorePort:8092}});
const fixtureRows=kind=>api.exportRange(kind,{idFrom:'!',idTo:'\uf8ff'});
let currentUser;
const authStop=api.authChanges(user=>currentUser=user);
const roleStop=()=>new Promise((resolve,reject)=>{
  let stop;
  const timeout=setTimeout(()=>{stop?.();reject(Error('Role confirmation timed out'));},15000);
  stop=api.role(currentUser.uid,enabled=>{if(enabled){clearTimeout(timeout);resolve(stop);}},reject);
});
let stop;
test.before(async()=>{
  await api.login('admin@healthmate.local','LocalHealthMate!2026');
  stop=await roleStop();
});
test.after(async()=>{stop?.();await api.logout();authStop();hooks.deregister();const{deleteApp,getApps}=require('firebase/app');await Promise.all(getApps().map(deleteApp));});
test('production SDK loads one25-row cursor page, separate full fixture export and four server counts',async()=>{
  const first=await api.listPage('food_catalog');assert.equal(first.rows.length,25);assert.equal(first.hasMore,true);
  const second=await api.listPage('food_catalog',{cursor:first.cursor});assert.equal(second.rows.length,25);
  assert.equal(new Set([...first.rows,...second.rows].map(r=>r.id)).size,50);
  await assert.rejects(api.listPage('user_directory',{cursor:first.cursor}),/phạm vi/);
  const list=await fixtureRows('food_catalog');assert.ok(list.length>=65);
  assert.ok(list.some(row=>row.id==='qa-item-057'));
  const accounts=await fixtureRows('user_directory');assert.ok(accounts.some(row=>row.id===currentUser.uid&&row.adminRole?.enabled));
  assert.equal((await api.counts()).length,4);
});

test('real SDK revenue timestamp cursor retains31 same-millisecond receipts across pages',async()=>{
  const prefix=`qa-nanos-${Date.now()}`,base='http://127.0.0.1:8092/v1/projects/demo-healthmate-admin/databases/(default)/documents';
  const ids=[];
  async function request(id,method,fields){
    const response=await fetch(`${base}/demo_premium_transactions/${id}`,{method,headers:{Authorization:'Bearer owner','Content-Type':'application/json'},...(fields?{body:JSON.stringify({fields})}:{})});
    assert.ok(response.ok,`emulator fixture ${method} failed ${response.status}`);
  }
  try{
    for(let i=0;i<31;i++){
      const id=`${prefix}-${String(i).padStart(2,'0')}`;ids.push(id);
      await request(id,'PATCH',{uid:{stringValue:'fixture-member'},mode:{stringValue:'demo'},planId:{stringValue:'premium_demo_30d'},
        status:{stringValue:'simulated_paid'},source:{stringValue:'demo_checkout'},currency:{stringValue:'VND'},amountVnd:{integerValue:'20000'},
        occurredAt:{timestampValue:`2030-02-01T00:00:00.${String(i+1).padStart(9,'0')}Z`}});
    }
    const range={start:'2030-02-01',end:'2030-02-01'};
    const first=await api.listPage('demo_premium_transactions',range);assert.equal(first.rows.length,25);
    const second=await api.listPage('demo_premium_transactions',{...range,cursor:first.cursor});assert.equal(second.rows.length,6);
    const actual=[...first.rows,...second.rows].map(r=>r.id);
    assert.deepEqual(actual,[...ids].reverse());assert.equal(new Set(actual).size,31);
    const exported=await api.exportRange('demo_premium_transactions',range);assert.equal(exported.length,31);
  }finally{await Promise.all(ids.map(id=>request(id,'DELETE')));}
});

test('real SDK reads only aggregate account statistics from server and preserves zero/missing values',async()=>{
  const url='http://127.0.0.1:8092/v1/projects/demo-healthmate-admin/databases/(default)/documents/admin_statistics/accounts';
  const request=async(method,fields)=>{
    const result=await fetch(url,{method,headers:{Authorization:'Bearer owner','Content-Type':'application/json'},
      ...(fields?{body:JSON.stringify({fields})}:{})});
    assert.ok(result.ok,`aggregate fixture ${method} failed ${result.status}`);
  };
  await request('PATCH',{schemaVersion:{integerValue:'1'},source:{stringValue:'firebase_auth'},method:{stringValue:'manual_snapshot'},
    totalRegisteredAccounts:{integerValue:'0'},updatedAt:{timestampValue:new Date().toISOString()}});
  try {
    const result=await api.registeredAccounts();assert.equal(result.totalRegisteredAccounts,0);assert.ok(result.updatedAt.toMillis());
  } finally {await request('DELETE');}
  assert.equal(await api.registeredAccounts(),null);
});

test('manual Auth summary writer commits server time and concurrency precondition against real Firestore emulator',async()=>{
  const {syncStatistics}=require('../admin-web/tool/sync-account-statistics.cjs');
  const prefix='http://127.0.0.1:8092/v1/projects/demo-healthmate-admin/databases/(default)/documents';
  const request=async(url,{body,allowMissing=false}={})=>{
    if(url.startsWith('https://identitytoolkit.googleapis.com/'))return{users:[{localId:'synthetic-one'},{localId:'synthetic-two'}]};
    assert.ok(url.startsWith('https://firestore.googleapis.com/v1/projects/healthmate-app-20261013/'));
    const local=url.replace('https://firestore.googleapis.com/v1/projects/healthmate-app-20261013/databases/(default)/documents',prefix);
    const payload=body?JSON.parse(JSON.stringify(body).replaceAll('projects/healthmate-app-20261013/','projects/demo-healthmate-admin/')):null;
    const response=await fetch(local,{method:payload?'POST':'GET',headers:{Authorization:'Bearer owner','Content-Type':'application/json'},...(payload?{body:JSON.stringify(payload)}:{})});
    if(allowMissing&&response.status===404)return null;
    assert.ok(response.ok,`aggregate writer emulator failed ${response.status}`);return response.json();
  };
  try {
    for(let i=0;i<2;i++){
      assert.equal((await syncStatistics({request,apply:true})).totalRegisteredAccounts,2);
      const actual=await api.registeredAccounts();assert.equal(actual.totalRegisteredAccounts,2);assert.equal(actual.source,'firebase_auth');
      assert.ok(actual.updatedAt.toMillis());assert.ok(actual.scanStartedAt.toMillis());
    }
  } finally {await fetch(prefix+'/admin_statistics/accounts',{method:'DELETE',headers:{Authorization:'Bearer owner'}});}
});

test('real SDK opens and advances a25-row directory page with10,037 server records',async()=>{
  const prefix=`zzqa-paging-${Date.now()}-`,count=10037;
  const base='projects/demo-healthmate-admin/databases/(default)/documents';
  const endpoint=`http://127.0.0.1:8092/v1/${base}:commit`;
  const ids=Array.from({length:count},(_,i)=>`${prefix}${String(i).padStart(5,'0')}`);
  async function commit(writes){
    const response=await fetch(endpoint,{method:'POST',headers:{Authorization:'Bearer owner','Content-Type':'application/json'},body:JSON.stringify({writes})});
    assert.ok(response.ok,`large fixture failed ${response.status}`);
  }
  try{
    for(let at=0;at<ids.length;at+=400)await commit(ids.slice(at,at+400).map(id=>({update:{name:`${base}/user_directory/${id}`,fields:{displayName:{stringValue:'Synthetic cursor QA'}}}})));
    const range={idFrom:ids[0],idTo:ids.at(-1)};
    const first=await api.listPage('user_directory',range);assert.equal(first.rows.length,25);assert.equal(first.rows[0].id,ids[0]);
    const second=await api.listPage('user_directory',{...range,cursor:first.cursor});assert.equal(second.rows.length,25);assert.equal(second.rows[0].id,ids[25]);
    assert.equal(new Set([...first.rows,...second.rows].map(r=>r.id)).size,50);
    assert.equal(first.rows.every(r=>r.adminRole===null&&r.control===null),true);
    const tail=await api.listPage('user_directory',{idFrom:ids.at(-7),idTo:ids.at(-1)});assert.equal(tail.rows.length,7);assert.equal(tail.hasMore,false);
    console.info(JSON.stringify({fixture:'synthetic demo directory',records:count,firstRows:first.rows.length,secondRows:second.rows.length,tailRows:tail.rows.length,directoryGetsPerFullPage:1,roleGetsPerFullPage:25,controlGetsPerFullPage:25,productionBillingMeasured:false}));
  }finally{
    for(let at=0;at<ids.length;at+=400)await commit(ids.slice(at,at+400).map(id=>({delete:`${base}/user_directory/${id}`})));
  }
});
test('production client archive/restore is audited, confirmed and rejects stale edits',async()=>{
  const row=(await fixtureRows('food_catalog')).find(r=>r.id==='qa-item-057');
  await api.save('food_catalog',row.id,{isActive:false},'SDK QA archive',entityVersion(row));
  const archived=(await fixtureRows('food_catalog')).find(r=>r.id===row.id);
  assert.equal(archived.isActive,false);assert.ok(archived.lastAdminOperationId);
  await assert.rejects(api.save('food_catalog',row.id,{name:'Stale must not replace'},'SDK QA stale',entityVersion(row)),/thay đổi/);
  const audits=await fixtureRows('admin_audit');assert.ok(audits.some(a=>a.id===archived.lastAdminOperationId&&a.reason==='SDK QA archive'));
  await api.save('food_catalog',row.id,{isActive:true},'SDK QA restore',entityVersion(archived));
});
test('new catalog food is created, edited and archived with independent audit records',async()=>{
  const id=`qa-sdk-new-${Date.now()}`;
  const payload=foodPayload({name:'SDK món mới',category:'Món chính',kcalPer100g:150,proteinGPer100g:5,carbsGPer100g:25,fatGPer100g:3,fiberGPer100g:'',sourceLabel:'Nguồn QA',sourceUrl:'https://example.com/qa',isActive:true,isEstimated:true});
  await api.save('food_catalog',id,payload,'SDK QA create',null);
  const row=(await fixtureRows('food_catalog')).find(r=>r.id===id);assert.equal(row.fiberGPer100g,null);
  await api.save('food_catalog',id,{name:'SDK món đã sửa'},'SDK QA edit',entityVersion(row));
  const changed=(await fixtureRows('food_catalog')).find(r=>r.id===id);assert.equal(changed.name,'SDK món đã sửa');
  await api.save('food_catalog',id,{isActive:false},'SDK QA archive created',entityVersion(changed));
  const logs=(await fixtureRows('admin_audit')).filter(a=>a.entityId===id);assert.equal(logs.length,3);
});
test('server-backed account suspension and config changes keep audit and restore original values',async()=>{
  const member=(await fixtureRows('user_directory')).find(r=>r.email==='member@healthmate.local');
  await api.save('account_controls',member.id,{status:'suspended',reason:'SDK QA suspend'},'SDK QA suspend',entityVersion(member.control));
  const locked=(await fixtureRows('user_directory')).find(r=>r.id===member.id);assert.equal(locked.control.status,'suspended');
  await api.save('account_controls',member.id,{status:'active',reason:'SDK QA reopen'},'SDK QA reopen',entityVersion(locked.control));
  const config=await api.config();
  const payload={chatbotEnabled:config.chatbotEnabled,foodScannerEnabled:config.foodScannerEnabled,maintenanceMode:true,maintenanceMessage:'SDK QA maintenance'};
  await api.save('app_config','runtime',payload,'SDK QA config',entityVersion(config));
  const changed=await api.config();assert.equal(changed.maintenanceMode,true);
  await api.save('app_config','runtime',{...payload,maintenanceMode:false,maintenanceMessage:''},'SDK QA config restore',entityVersion(changed));
});

test('support SDK sends a single idempotent admin reply, changes status and reads customer follow-up',async()=>{
  const {getFirestore,collection,doc,Timestamp,serverTimestamp,runTransaction,updateDoc,deleteDoc}=require('firebase/firestore');
  const {getApp}=require('firebase/app');const db=getFirestore(getApp());
  const ref=doc(collection(db,'support_tickets')),uid=currentUser.uid;
  // Reset only this synthetic fixture's allowance on the fixed isolated admin
  // emulator so rerunning the suite does not depend on cooldown or daily quota.
  // Ticket creation itself still uses the client SDK and production Rules.
  const reset=await fetch(`http://127.0.0.1:8092/v1/projects/demo-healthmate-admin/databases/(default)/documents/support_usage/${uid}`,
    {method:'DELETE',headers:{Authorization:'Bearer owner'}});
  assert.ok(reset.ok,`support allowance fixture reset failed ${reset.status}`);
  const usage=doc(db,'support_usage',uid);
  await runTransaction(db,async t=>{
    const before=await t.get(usage);assert.equal(before.exists(),false);
    const local=new Date(Date.now()+7*3600000);
    const dayStart=Timestamp.fromMillis(Date.UTC(local.getUTCFullYear(),local.getUTCMonth(),local.getUTCDate())-7*3600000);
    t.set(usage,{schemaVersion:1,dayStart,count:1,lastTicketId:ref.id,lastCreatedAt:serverTimestamp(),updatedAt:serverTimestamp()});
    t.set(ref,{uid,type:'bug',title:'SDK lỗi lưu bữa',description:'Nội dung QA trên emulator.',status:'open',
      messageCount:0,lastMessageId:'',updatedBy:uid,deleting:false,createdAt:serverTimestamp(),updatedAt:serverTimestamp()});
  });
  try {
    const initial=await api.supportThread(ref.id);assert.equal(initial.messages.length,0);
    const messageId=api.newSupportMessageId();
    await assert.rejects(api.supportReply(ref.id,messageId,'   '),/Nội dung/);
    await api.supportReply(ref.id,messageId,'Bạn vui lòng thử lại.');
    await api.supportReply(ref.id,messageId,'Bạn vui lòng thử lại.');
    const replied=await api.supportThread(ref.id);assert.equal(replied.messages.length,1);assert.equal(replied.messages[0].role,'admin');
    await assert.rejects(api.supportStatus(ref.id,'resolved',entityVersion(initial.ticket)),/vừa thay đổi/);
    await api.supportStatus(ref.id,'resolved',entityVersion(replied.ticket));
    const followup=doc(collection(ref,'messages'));
    await runTransaction(db,async t=>{
      const parent=await t.get(ref),count=parent.data().messageCount+1;
      t.set(followup,{authorUid:uid,role:'customer',text:'Mình đã thử, cảm ơn.',sequence:count,createdAt:serverTimestamp()});
      t.update(ref,{status:'open',messageCount:count,lastMessageId:followup.id,updatedBy:uid,updatedAt:serverTimestamp()});
    });
    const result=await api.supportThread(ref.id);assert.equal(result.ticket.status,'open');assert.equal(result.messages.length,2);
    assert.equal(result.messages[1].role,'customer');
  } finally {
    const thread=await api.supportThread(ref.id);
    await updateDoc(ref,{deleting:true,updatedBy:uid,updatedAt:serverTimestamp()});
    for(const message of thread.messages)await deleteDoc(doc(ref,'messages',message.id));
    await deleteDoc(ref);
  }
});
