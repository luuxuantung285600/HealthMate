'use strict';
const {test}=require('node:test');const assert=require('node:assert/strict');
const {BillingError}=require('../src/billing-model.cjs');
const {parseNotification,processNotification}=require('../src/billing-notifications.cjs');
const config={enabled:true,packageName:'com.example.healthmate'};
const token='notification-token-fixture-only';
const message=(patch={})=>({json:{packageName:config.packageName,subscriptionNotification:{notificationType:2,purchaseToken:token},...patch}});

test('notification parser rejects malformed JSON, mismatched packages and mixed payloads',()=>{
  const broken={get json(){throw Error(`JSON error ${token}`);}};
  for(const value of [broken,{json:null},{json:[]},message({packageName:'other.app'}),message({testNotification:{}}),{json:{packageName:config.packageName}}]){
    assert.throws(()=>parseNotification(value,config.packageName),error=>error.code==='invalid-argument'&&!error.message.includes(token));
  }
});

test('valid subscription and future notification types refetch by token; invalid types fail closed',()=>{
  for(const notificationType of [1,2,99])assert.deepEqual(parseNotification(message({subscriptionNotification:{notificationType,purchaseToken:token}}),config.packageName),{kind:'reconcile',token,orderId:null});
  for(const notificationType of [0,-1,'2',1.5,NaN])assert.throws(()=>parseNotification(message({subscriptionNotification:{notificationType,purchaseToken:token}}),config.packageName));
  assert.throws(()=>parseNotification(message({subscriptionNotification:{notificationType:2,purchaseToken:'bad token'}}),config.packageName));
});

test('voided subscription identifies original order; one-time, test and review events never grant',()=>{
  const envelope=detail=>({json:{packageName:config.packageName,...detail}});
  assert.deepEqual(parseNotification(envelope({voidedPurchaseNotification:{productType:1,purchaseToken:token,orderId:'order-1'}}),config.packageName),{kind:'reconcile',token,orderId:'order-1'});
  for(const orderId of ['',null,'bad order','x'.repeat(201)])assert.throws(()=>parseNotification(envelope({voidedPurchaseNotification:{productType:1,purchaseToken:token,orderId}}),config.packageName));
  for(const productType of [undefined,0,'1'])assert.throws(()=>parseNotification(envelope({voidedPurchaseNotification:{productType,purchaseToken:token,orderId:'order-1'}}),config.packageName));
  for(const [detail,kind] of [[{voidedPurchaseNotification:{productType:2}},'ignored'],[{oneTimeProductNotification:{}},'ignored'],[{testNotification:{}},'test'],[{pendingRefundReviewNotification:{}},'review_required']])assert.equal(parseNotification(envelope(detail),config.packageName).kind,kind);
});

test('malformed and permanently rejected messages are acknowledged without token leakage',async()=>{
  const logs=[],calls=[];const options={log:(...args)=>logs.push(args)};
  const service={reconcile:async(...args)=>{calls.push(args);throw new BillingError('permission-denied',`private ${token}`);}};
  await processNotification(message({packageName:'other.app'}),config,service,options);assert.equal(calls.length,0);
  await processNotification(message(),config,service,options);assert.deepEqual(calls,[[token,null,null]]);
  assert.equal(logs.length,2);assert.ok(!JSON.stringify(logs).includes(token));
});

test('transient reconciliation errors retry with sanitized errors and retain the original order',async()=>{
  const calls=[],logs=[];
  const service={reconcile:async(...args)=>{calls.push(args);throw Error(`Bearer private-token ${token}`);}};
  const input={json:{packageName:config.packageName,voidedPurchaseNotification:{productType:1,purchaseToken:token,orderId:'order-1'}}};
  await assert.rejects(processNotification(input,config,service,{log:(...args)=>logs.push(args)}),error=>error.message==='billing_reconciliation_retry'&&!String(error.stack).includes(token));
  assert.deepEqual(calls,[[token,null,'order-1']]);assert.deepEqual(logs,[]);
});

test('disabled, test and review events do not call Publisher; review requires human attention',async()=>{
  let calls=0;const logs=[],service={reconcile:async()=>calls++},options={log:(...args)=>logs.push(args)};
  await processNotification(message(),{...config,enabled:false},service,options);
  await processNotification({json:{packageName:config.packageName,testNotification:{}}},config,service,options);
  await processNotification({json:{packageName:config.packageName,pendingRefundReviewNotification:{}}},config,service,options);
  assert.equal(calls,0);assert.deepEqual(logs,[['billing_refund_review_required','review-in-play-console']]);
});
