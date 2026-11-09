'use strict';
const {BillingError,tokenValue}=require('./billing-model.cjs');
const invalid=()=>{throw new BillingError('invalid-argument','Thông báo Google Play không hợp lệ.');};
const object=value=>value!==null&&typeof value==='object'&&!Array.isArray(value);
// This parser never grants anything. Even a recognized notification only
// selects the token/order to fetch again using the authenticated Publisher API.
function parseNotification(message,packageName){
  let data;
  try{data=message.json;}catch{invalid();}
  if(!object(data)||data.packageName!==packageName)invalid();
  const kinds=['subscriptionNotification','voidedPurchaseNotification','oneTimeProductNotification','testNotification','pendingRefundReviewNotification'].filter(key=>Object.hasOwn(data,key));
  if(kinds.length!==1||!object(data[kinds[0]]))invalid();
  const kind=kinds[0],detail=data[kind];
  if(kind==='testNotification')return {kind:'test'};
  if(kind==='oneTimeProductNotification')return {kind:'ignored'};
  // Refund review requires a human decision in Play Console. Do not silently
  // accept/reject it or treat it as a completed refund.
  if(kind==='pendingRefundReviewNotification')return {kind:'review_required'};
  if(kind==='voidedPurchaseNotification'&&detail.productType===2)return {kind:'ignored'};
  if(kind==='voidedPurchaseNotification'&&detail.productType!==1)invalid();
  if(kind==='subscriptionNotification'&&(!Number.isSafeInteger(detail.notificationType)||detail.notificationType<1))invalid();
  const token=tokenValue(detail.purchaseToken);
  if(kind==='voidedPurchaseNotification'&&(typeof detail.orderId!=='string'||!detail.orderId||detail.orderId.length>200||/[\s\x00-\x1f]/.test(detail.orderId)))invalid();
  return {kind:'reconcile',token,orderId:kind==='voidedPurchaseNotification'?detail.orderId:null};
}
async function processNotification(message,config,service,{log=()=>{}}={}){
  if(!config.enabled)return;
  let event;
  try{event=parseNotification(message,config.packageName);}
  catch(error){if(error instanceof BillingError){log('billing_notification_rejected',error.code);return;}throw new Error('billing_notification_parse_failed');}
  if(event.kind==='review_required'){log('billing_refund_review_required','review-in-play-console');return;}
  if(event.kind!=='reconcile')return;
  try{await service.reconcile(event.token,null,event.orderId);}
  catch(error){
    if(error instanceof BillingError&&['permission-denied','invalid-argument'].includes(error.code)){log('billing_notification_rejected',error.code);return;}
    // Do not log the SDK error: it may contain tokens, headers or buyer data.
    throw new Error('billing_reconciliation_retry');
  }
}
module.exports={parseNotification,processNotification};
