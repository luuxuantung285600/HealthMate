'use strict';
const functions=require('firebase-functions/v1');
const {getFirestore}=require('firebase-admin/firestore');
const {getAuth}=require('firebase-admin/auth');
const {configuration,validateIdentity,BillingError}=require('./billing-model.cjs');
const {PlayPublisher}=require('./play-publisher.cjs');
const {BillingService}=require('./billing-service.cjs');
const {processNotification}=require('./billing-notifications.cjs');
const runtime=(options={})=>functions.region('asia-southeast1').runWith({memory:'256MB',timeoutSeconds:120,maxInstances:3,...options});
function service(){const config=configuration();return new BillingService(getFirestore(),new PlayPublisher(config.packageName),config);}
async function identity(context){
  if(!context.auth||context.auth.token.email_verified!==true)throw new functions.https.HttpsError('unauthenticated','Hãy đăng nhập và xác minh email.');
  return validateIdentity(await getAuth().getUser(context.auth.uid),context.auth);
}
async function rateLimit(uid){
  const db=getFirestore(),ref=db.doc(`billing_requests/${uid}`),minute=Math.floor(Date.now()/60000);
  await db.runTransaction(async t=>{const old=(await t.get(ref)).data(),count=old?.minute===minute?old.count:0;if(count>=10)throw new BillingError('resource-exhausted','Bạn đã thử nhiều lần. Hãy chờ một phút.');t.set(ref,{minute,count:count+1});});
}
function safe(error){
  if(error instanceof functions.https.HttpsError)return error;
  if(error instanceof BillingError)return new functions.https.HttpsError(error.code,error.message);
  // SDK errors may contain raw purchase tokens, OAuth headers or buyer data.
  return new functions.https.HttpsError('unavailable','Chưa xác minh được với Google Play. Khôi phục giao dịch để thử lại; không cần mua lần nữa.');
}
exports.preparePlayBilling=runtime({enforceAppCheck:true}).https.onCall(async(data,context)=>{try{const uid=await identity(context);await rateLimit(uid);return await service().prepare(uid);}catch(error){throw safe(error);}});
exports.verifyPlayPurchase=runtime({enforceAppCheck:true}).https.onCall(async(data,context)=>{try{const uid=await identity(context);await rateLimit(uid);return await service().reconcile(data?.purchaseToken,uid);}catch(error){throw safe(error);}});
exports.playBillingNotification=runtime({failurePolicy:true}).pubsub.topic('healthmate-play-billing').onPublish(async message=>{
  const config=configuration();
  await processNotification(message,config,service(),{log:(event,code)=>console.error(event,code)});
});
// Bounded sweeps repair missed notifications and unresolved Orders fetches.
// Oldest first makes progress across all tokens; expiry is also checked by AI.
exports.reconcilePlayBilling=runtime({timeoutSeconds:540,maxInstances:1}).pubsub.schedule('every 6 hours').timeZone('Asia/Ho_Chi_Minh').onRun(async()=>{
  if(!configuration().enabled)return;
  const rows=await getFirestore().collection('billing_tokens').orderBy('checkedAt').limit(100).get(),deadline=Date.now()+420000;
  const queue=[...rows.docs];
  await Promise.all(Array.from({length:3},async()=>{while(queue.length&&Date.now()<deadline){const row=queue.shift();try{await service().reconcile(row.data().token,row.data().uid);}catch(error){
      await row.ref.update({checkedAt:require('firebase-admin/firestore').FieldValue.serverTimestamp()});
      console.error('billing_sweep_failed',error instanceof BillingError?error.code:'unavailable');
  }}}));
});
