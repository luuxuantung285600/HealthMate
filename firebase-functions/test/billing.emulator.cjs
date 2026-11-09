'use strict';
// Uses real Firestore transactions and owner/admin Web SDK listeners locally.
// Only the Google Publisher boundary is a fixture; no real purchase is created.
const {test,after}=require('node:test');const assert=require('node:assert/strict');const fs=require('node:fs');const path=require('node:path');
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8080')throw Error('Requires fixed local Firestore emulator.');
const {initializeApp,deleteApp}=require('firebase-admin/app');const {getFirestore}=require('firebase-admin/firestore');
const {initializeTestEnvironment}=require('../../rules-tests/node_modules/@firebase/rules-unit-testing');
const {doc,setDoc,getDocFromServer,getDocsFromServer,collection,query,where,limit,onSnapshot}=require('../../rules-tests/node_modules/firebase/firestore');
const {BillingService}=require('../src/billing-service.cjs');const {accountId}=require('../src/billing-model.cjs');
const projectId='demo-healthmate-billing-service',app=initializeApp({projectId},'billing-integration'),db=getFirestore(app);
const {hostname:host,port}=new URL(`http://${process.env.FIRESTORE_EMULATOR_HOST}`);
let env;
after(async()=>{await env?.cleanup();await db.terminate();await deleteApp(app);});
function waitFor(target,predicate){let stop;return new Promise((resolve,reject)=>{
  const timeout=setTimeout(()=>{stop?.();reject(Error('Listener timeout'));},10000);
  stop=onSnapshot(target,snapshot=>{if(predicate(snapshot)){clearTimeout(timeout);stop();resolve(snapshot);}},error=>{clearTimeout(timeout);stop?.();reject(error);});
});}
test('verified purchase streams to owner and admin; replay, refund and suspension persist atomically',async()=>{
  env=await initializeTestEnvironment({projectId,firestore:{host,port:Number(port),rules:fs.readFileSync(path.join(__dirname,'../../firestore.rules'),'utf8')}});
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'admin_roles/admin'),{enabled:true}));
  const owner=env.authenticatedContext('alice',{email_verified:true}).firestore(),admin=env.authenticatedContext('admin',{email_verified:true}).firestore();
  const now=Date.now(),token='emulator-receipt-fixture-only';let acks=0,refund=false;
  const publisher={getSubscription:async()=>({externalAccountIdentifiers:{obfuscatedExternalAccountId:accountId('alice')},startTime:new Date(now-1000).toISOString(),subscriptionState:'SUBSCRIPTION_STATE_ACTIVE',acknowledgementState:acks?'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED':'ACKNOWLEDGEMENT_STATE_PENDING',lineItems:[{productId:'premium',offerDetails:{basePlanId:'monthly'},autoRenewingPlan:{autoRenewEnabled:true},expiryTime:new Date(now+86400000).toISOString(),latestSuccessfulOrderId:'order-emulator'}]}),
    getOrder:async()=>({orderId:'order-emulator',purchaseToken:token,lineItems:[{productId:'premium'}],state:refund?'REFUNDED':'PROCESSED',total:{currencyCode:'VND',units:'29000'},createTime:new Date(now).toISOString(),lastEventTime:new Date(now+1000).toISOString(),...(refund?{orderHistory:{refundEvent:{refundDetails:{total:{currencyCode:'VND',units:'29000'}}}}}:{})}),acknowledge:async()=>{acks++;}};
  const service=new BillingService(db,publisher,{enabled:true,packageName:'com.example.healthmate',productId:'premium',basePlanId:'monthly',allowTest:false});
  await service.prepare('alice');
  // Establish the empty server baseline (including cold emulator Rules setup)
  // before timing the change notification. Keep the 10-second update deadline.
  assert.equal((await getDocFromServer(doc(owner,'premium_memberships/alice'))).exists(),false);
  assert.equal((await getDocsFromServer(query(collection(admin,'premium_transactions'),limit(10)))).empty,true);
  const membership=waitFor(doc(owner,'premium_memberships/alice'),s=>s.data()?.active===true);
  const ledger=waitFor(query(collection(admin,'premium_transactions'),limit(10)),s=>s.docs[0]?.data().netNanos==='29000000000000');
  const verified=await service.reconcile(token,'alice');assert.equal(verified.completionAllowed,true);await Promise.all([membership,ledger]);assert.equal(acks,1);
  await service.reconcile(token,'alice');assert.equal((await db.collection('premium_transactions').get()).size,1);assert.equal(acks,1);
  refund=true;await service.reconcile(token);assert.equal((await db.collection('premium_transactions').get()).docs[0].data().netNanos,'0');
  await db.doc('account_controls/alice').set({status:'suspended'});await service.reconcile(token,'alice');assert.equal((await db.doc('premium_memberships/alice').get()).data().active,false);
});

test('newer sandbox purchase streams a separate ledger without replacing the owner production grant',async()=>{
  const owner=env.authenticatedContext('dual',{email_verified:true}).firestore(),admin=env.authenticatedContext('admin',{email_verified:true}).firestore();
  const now=Date.now(),production='production-token-fixture-only',sandbox='sandbox-token-fixture-only',acknowledged=new Set();
  const orderId=token=>token===production?'emulator-real-order':'emulator-test-order';
  const publisher={
    getSubscription:async token=>({externalAccountIdentifiers:{obfuscatedExternalAccountId:accountId('dual')},startTime:new Date(now-(token===production?10000:5000)).toISOString(),subscriptionState:'SUBSCRIPTION_STATE_ACTIVE',acknowledgementState:acknowledged.has(token)?'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED':'ACKNOWLEDGEMENT_STATE_PENDING',...(token===sandbox?{testPurchase:{}}:{}),lineItems:[{productId:'premium',offerDetails:{basePlanId:'monthly'},autoRenewingPlan:{autoRenewEnabled:true},expiryTime:new Date(now+86400000).toISOString(),latestSuccessfulOrderId:orderId(token)}]}),
    getOrder:async id=>({orderId:id,purchaseToken:id===orderId(production)?production:sandbox,lineItems:[{productId:'premium'}],state:'PROCESSED',total:{currencyCode:'VND',units:'29000'},createTime:new Date(now).toISOString(),lastEventTime:new Date(now).toISOString()}),
    acknowledge:async(_product,token)=>acknowledged.add(token),
  };
  const service=new BillingService(db,publisher,{enabled:true,packageName:'com.example.healthmate',productId:'premium',basePlanId:'monthly',allowTest:true});
  const liveMembership=waitFor(doc(owner,'premium_memberships/dual'),s=>s.data()?.environment==='production'&&s.data()?.active);
  await service.reconcile(production,'dual');await liveMembership;
  const liveTestOrder=waitFor(query(collection(admin,'premium_transactions'),where('environment','==','test'),limit(10)),s=>s.docs.some(row=>row.data().orderId===orderId(sandbox)));
  const result=await service.reconcile(sandbox,'dual');await liveTestOrder;
  assert.equal(result.active,false);assert.equal(result.environment,'test');assert.equal(result.completionAllowed,true);
  const membership=(await getDocFromServer(doc(owner,'premium_memberships/dual'))).data();
  assert.equal(membership.environment,'production');assert.equal(membership.active,true);
  await service.reconcile(sandbox,'dual');assert.equal(acknowledged.size,2);
  const invoices=await db.collection('premium_transactions').where('uid','==','dual').get();
  assert.equal(invoices.size,2);assert.deepEqual(invoices.docs.map(row=>row.data().environment).sort(),['production','test']);
});
