'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const {configuration,validateIdentity,accountId,hash,subscription,replaceMembership,order}=require('../src/billing-model.cjs');
const {BillingService}=require('../src/billing-service.cjs');
const now=Date.parse('2026-11-07T04:00:00Z');
const config={enabled:true,packageName:'com.example.healthmate',productId:'premium',basePlanId:'monthly',allowTest:true};
const token='test-purchase-token-fixture-only';
function sub(patch={}){return {externalAccountIdentifiers:{obfuscatedExternalAccountId:accountId('alice')},startTime:new Date(now-86400000).toISOString(),subscriptionState:'SUBSCRIPTION_STATE_ACTIVE',acknowledgementState:'ACKNOWLEDGEMENT_STATE_PENDING',lineItems:[{productId:'premium',offerDetails:{basePlanId:'monthly'},autoRenewingPlan:{autoRenewEnabled:true},expiryTime:new Date(now+86400000).toISOString(),latestSuccessfulOrderId:'order-1'}],...patch};}
function receipt(patch={}){return {orderId:'order-1',purchaseToken:token,lineItems:[{productId:'premium'}],state:'PROCESSED',total:{currencyCode:'VND',units:'29000'},createTime:new Date(now).toISOString(),lastEventTime:new Date(now).toISOString(),...patch};}
function normalizeOrder(data){return order(data,{uid:'alice',token,productId:'premium',environment:'production',orderId:'order-1'});}
class Database {
  constructor(){this.rows=new Map();this.queue=Promise.resolve();}
  doc(path){return {path,get:async()=>this.snap(path),set:async data=>this.rows.set(path,data)};}
  snap(path){return {exists:this.rows.has(path),data:()=>this.rows.get(path)};}
  async getAll(...refs){return refs.map(ref=>this.snap(ref.path));}
  async runTransaction(fn){const previous=this.queue;let release;this.queue=new Promise(r=>release=r);await previous;
    try{const writes=[];const result=await fn({get:async ref=>this.snap(ref.path),getAll:async(...refs)=>this.getAll(...refs),set:(ref,data)=>writes.push(()=>this.rows.set(ref.path,data)),delete:ref=>writes.push(()=>this.rows.delete(ref.path))});writes.forEach(fn=>fn());return result;}finally{release();}}
}
function fixture(){const db=new Database();let state=sub(),orderData=receipt(),acks=0,failOrder=false;
  const publisher={getSubscription:async()=>state,getOrder:async()=>{if(failOrder)throw Error('Provider temporarily unavailable');return orderData;},acknowledge:async()=>{acks++;state={...state,acknowledgementState:'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED'};}};
  const service=new BillingService(db,publisher,config,{now:()=>now});return {db,service,publisher,setState:value=>state=value,setOrder:value=>orderData=value,setFailOrder:value=>failOrder=value,get acks(){return acks;}};
}
test('billing disabled by default; enabling without Play configuration fails closed',()=>{
  assert.equal(configuration({}).enabled,false);assert.throws(()=>configuration({BILLING_ENABLED:'true'}));
  assert.equal(accountId('alice').length,64);assert.notEqual(accountId('alice'),accountId('bob'));
});
test('billing callables reject revoked, disabled, unverified and mismatched identity',()=>{
  const auth={uid:'alice',token:{email_verified:true,auth_time:now/1000}};
  const user={uid:'alice',disabled:false,emailVerified:true,tokensValidAfterTime:new Date(now-1000).toISOString()};
  assert.equal(validateIdentity(user,auth),'alice');
  for(const patch of [{disabled:true},{emailVerified:false},{uid:'bob'},{tokensValidAfterTime:null},{tokensValidAfterTime:new Date(now+1000).toISOString()}])assert.throws(()=>validateIdentity({...user,...patch},auth));
  assert.throws(()=>validateIdentity(user,{...auth,token:{email_verified:true}}));
});
test('only bound correct product/base plan grants; arbitrary client claims do not',()=>{
  assert.equal(subscription(sub(),config,'alice',now).active,true);
  assert.throws(()=>subscription(sub(),config,'bob',now));
  const data=sub();data.lineItems[0].offerDetails.basePlanId='other';assert.throws(()=>subscription(data,config,'alice',now));
  assert.throws(()=>subscription(sub({testPurchase:{}}),{...config,allowTest:false},'alice',now));
  assert.equal(subscription(sub({testPurchase:{}}),config,'alice',now).environment,'test');
});
for(const state of ['PAUSED','ON_HOLD','EXPIRED','PENDING','PENDING_PURCHASE_CANCELED'])test(`no grant for ${state}`,()=>{
  assert.equal(subscription(sub({subscriptionState:`SUBSCRIPTION_STATE_${state}`}),config,'alice',now).active,false);
});
test('canceled renewal retains paid access; expiry checked independently of active state',()=>{
  assert.equal(subscription(sub({subscriptionState:'SUBSCRIPTION_STATE_CANCELED'}),config,'alice',now).active,true);
  assert.equal(subscription(sub(),config,'alice',now+2*86400000).active,false);
});
test('money is authoritative and exact, supports currencies, fractions and refunds',()=>{
  assert.equal(normalizeOrder(receipt()).netNanos,'29000000000000');
  const refund={state:'PROCESSED_SUCCESSFULLY',refundDetails:{total:{currencyCode:'VND',units:'4000'}}};
  const row=normalizeOrder(receipt({state:'PARTIALLY_REFUNDED',orderHistory:{partialRefundEvents:[refund]}}));
  assert.equal(row.netNanos,'25000000000000');
  assert.equal(normalizeOrder(receipt({total:{currencyCode:'USD',units:'1',nanos:123456789}})).netNanos,'1123456789');
  assert.throws(()=>normalizeOrder(receipt({purchaseToken:'someone-else'})));
  assert.throws(()=>normalizeOrder(receipt({state:'REFUNDED'})));
  assert.throws(()=>normalizeOrder(receipt({total:{currencyCode:'VND',units:'-1'}})));
});
test('verification persists before acknowledgement; retry is idempotent and token never enters public records',async()=>{
  const f=fixture();const result=await f.service.reconcile(token,'alice');
  assert.equal(result.active,true);assert.equal(result.completionAllowed,true);assert.equal(f.acks,1);
  await f.service.reconcile(token,'alice');assert.equal(f.acks,1);
  const ledger=[...f.db.rows].filter(([path])=>path.startsWith('premium_transactions/'));
  assert.equal(ledger.length,1);assert.equal(ledger[0][1].netNanos,'29000000000000');
  assert.ok(!JSON.stringify(ledger).includes(token));assert.ok(!JSON.stringify(f.db.rows.get('premium_memberships/alice')).includes(token));
  await assert.rejects(f.service.reconcile(token,'bob'));assert.ok(!f.db.rows.has('premium_memberships/bob'));
});
test('Orders outage never guesses price or denies purchased entitlement; retry repairs ledger',async()=>{
  const f=fixture();f.setFailOrder(true);await f.service.reconcile(token,'alice');
  const ref=`premium_transactions/${hash('order-1')}`;
  assert.equal(f.db.rows.get(ref).status,'awaiting_order');assert.equal(f.db.rows.get(ref).totalNanos,null);
  assert.equal(f.db.rows.get('premium_memberships/alice').active,true);
  f.setFailOrder(false);await f.service.reconcile(token,'alice');assert.equal(f.db.rows.get(ref).status,'paid');
  f.setFailOrder(true);await f.service.reconcile(token,'alice');assert.equal(f.db.rows.get(ref).status,'paid');
});
test('RTDN resolves UID from prepared account then fetches Play state; suspension/deletion denies grant',async()=>{
  const f=fixture();await f.service.prepare('alice');await f.service.reconcile(token);
  f.db.rows.set('account_deletions/alice',{state:'requested'});await f.service.reconcile(token);
  assert.equal(f.db.rows.get('premium_memberships/alice').active,false);
  await assert.rejects(f.service.prepare('alice'));
});
test('concurrent verification cannot issue two API reconciliations under one user lease',async()=>{
  const f=fixture();const results=await Promise.allSettled([f.service.reconcile(token,'alice'),f.service.reconcile(token,'alice')]);
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);assert.equal(results.filter(r=>r.status==='rejected'&&r.reason.code==='aborted').length,1);
});
test('older replacement token cannot overwrite newer entitlement; refund updates one original order',async()=>{
  const f=fixture();await f.service.reconcile(token,'alice');
  const member=f.db.rows.get('premium_memberships/alice');f.db.rows.set('premium_memberships/alice',{...member,tokenHash:'new-token',startedAt:{toMillis:()=>now},active:false});
  f.setOrder(receipt({state:'REFUNDED',orderHistory:{refundEvent:{refundDetails:{total:{currencyCode:'VND',units:'29000'}}}}}));
  await f.service.reconcile(token,'alice');
  assert.equal(f.db.rows.get('premium_memberships/alice').active,false);
  assert.equal(f.db.rows.get(`premium_transactions/${hash('order-1')}`).netNanos,'0');
});

test('active subscriptions require a complete, ordered validity interval from Google',()=>{
  for(const startTime of [undefined,'invalid'])assert.throws(()=>subscription(sub({startTime}),config,'alice',now));
  for(const expiryTime of [undefined,'invalid',new Date(now-86400000).toISOString()]){
    const data=sub();data.lineItems[0].expiryTime=expiryTime;
    assert.throws(()=>subscription(data,config,'alice',now));
  }
});

test('sandbox cannot overwrite production; production wins even against a newer sandbox timestamp',async()=>{
  const f=fixture();await f.service.reconcile(token,'alice');
  const production=f.db.rows.get('premium_memberships/alice');
  const testToken='sandbox-token-fixture-only';
  f.setState(sub({testPurchase:{},startTime:new Date(now-1000).toISOString()}));
  f.setOrder(receipt({orderId:'order-sandbox',purchaseToken:testToken}));
  const data=sub({testPurchase:{},startTime:new Date(now-1000).toISOString()});data.lineItems[0].latestSuccessfulOrderId='order-sandbox';f.setState(data);
  const result=await f.service.reconcile(testToken,'alice');
  assert.equal(result.active,false);assert.equal(result.completionAllowed,true);
  assert.deepEqual(f.db.rows.get('premium_memberships/alice'),production);
  assert.equal(f.db.rows.get(`premium_transactions/${hash('order-sandbox')}`).environment,'test');
  f.db.rows.set('premium_memberships/alice',{...production,environment:'test',tokenHash:hash(testToken),startedAt:{toMillis:()=>now}});
  f.setState(sub());f.setOrder(receipt());await f.service.reconcile(token,'alice');
  assert.equal(f.db.rows.get('premium_memberships/alice').environment,'production');
  for(const active of [true,false]){
    assert.equal(replaceMembership({...production,active},{...subscription(sub({testPurchase:{}}),config,'alice',now),startedAt:now+1},hash(testToken)),false);
  }
});

test('pending real purchase does not erase a working sandbox membership',()=>{
  const pending=subscription(sub({subscriptionState:'SUBSCRIPTION_STATE_PENDING'}),config,'alice',now);
  assert.equal(replaceMembership({environment:'test',tokenHash:'other'},pending,hash(token)),false);
});

test('expired, pending and canceled pending orders are never acknowledged by the client',async()=>{
  for(const state of ['EXPIRED','PENDING','PENDING_PURCHASE_CANCELED']){
    const f=fixture();f.setState(sub({subscriptionState:`SUBSCRIPTION_STATE_${state}`}));
    const result=await f.service.reconcile(token,'alice');
    assert.equal(result.active,false);assert.equal(result.completionAllowed,false);assert.equal(f.acks,0);
    assert.equal(result.pending,state==='PENDING');
  }
  const f=fixture();f.setState(sub({subscriptionState:'SUBSCRIPTION_STATE_EXPIRED',acknowledgementState:'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED'}));
  assert.equal((await f.service.reconcile(token,'alice')).completionAllowed,true);assert.equal(f.acks,0);
});

test('acknowledgement outage preserves paid grant and releases lock for restore retry',async()=>{
  const f=fixture(),acknowledge=f.publisher.acknowledge;
  f.publisher.acknowledge=async()=>{throw Error('Provider unavailable');};
  await assert.rejects(f.service.reconcile(token,'alice'));
  assert.equal(f.db.rows.get('premium_memberships/alice').active,true);assert.equal(f.db.rows.has('billing_locks/alice'),false);
  f.publisher.acknowledge=acknowledge;
  assert.equal((await f.service.reconcile(token,'alice')).completionAllowed,true);assert.equal(f.acks,1);
});

test('fresh revoked subscription is not acknowledged from an earlier active snapshot',async()=>{
  const f=fixture();let reads=0;
  f.publisher.getSubscription=async()=>sub({subscriptionState:++reads===1?'SUBSCRIPTION_STATE_ACTIVE':'SUBSCRIPTION_STATE_EXPIRED'});
  assert.equal((await f.service.reconcile(token,'alice')).completionAllowed,false);assert.equal(f.acks,0);
  assert.equal(f.db.rows.get('premium_memberships/alice').active,false);
  assert.equal(f.db.rows.get('premium_memberships/alice').status,'SUBSCRIPTION_STATE_EXPIRED');
});
