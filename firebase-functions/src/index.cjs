'use strict';
const {initializeApp}=require('firebase-admin/app');
const {getFirestore}=require('firebase-admin/firestore');
const {FieldValue}=require('firebase-admin/firestore');
const functions=require('firebase-functions/v1');
const {collections,key,reconcileAuth,reconcileOperation}=require('./sync.cjs');
initializeApp();let database;const getDb=()=>database??=getFirestore();
Object.assign(exports,require('./billing-functions.cjs'));
const runtime=functions.region('asia-southeast1').runWith({memory:'256MB',timeoutSeconds:120,maxInstances:3,failurePolicy:true});
exports.authRegistered=runtime.auth.user().onCreate((user,context)=>reconcileAuth(getDb(),{uid:user.uid,active:true,eventAt:Date.parse(context.timestamp),registeredAt:Date.parse(user.metadata.creationTime),displayName:user.displayName??'',email:user.email??''}));
exports.authDeleted=runtime.auth.user().onDelete((user,context)=>reconcileAuth(getDb(),{uid:user.uid,active:false,eventAt:Date.parse(context.timestamp)}));
for(const kind of collections)exports[`sync_${kind}`]=runtime.firestore.document(`${kind}/{id}`).onWrite(async(change,context)=>{
  await reconcileOperation(getDb(),kind,context.params.id);
  if(kind==='user_directory')await reconcileOperation(getDb(),'account_controls',context.params.id);
});
// Range reports use one lightweight revision listener instead of keeping every
// historical query open. Existing daily/private screens already use snapshots.
exports.userDataChanged=runtime.firestore.document('users/{uid}/{kind}/{id}').onWrite(async(change,context)=>{
  const {uid,kind}=context.params;
  if(!['meal_logs','water_logs','activity_logs','body_metrics','nutrition_targets','day_reviews','sleep_logs','custom_foods','recipes'].includes(kind))return;
  const db=getDb();
  await db.runTransaction(async t=>{
    const [authState,deletion]=await Promise.all([t.get(db.collection('admin_sync_state').doc(key('auth',uid))),t.get(db.collection('account_deletions').doc(uid))]);
    const target=db.collection('user_sync').doc(uid);
    if(authState.data()?.active===false||deletion.exists){t.delete(target);return;}
    t.set(target,{[kind]:FieldValue.serverTimestamp()},{merge:true});
  });
});
