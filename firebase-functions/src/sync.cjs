'use strict';
const {createHash}=require('node:crypto');
const {FieldValue,Timestamp}=require('firebase-admin/firestore');
const collections=['food_catalog','user_directory','account_controls','admin_audit'];
const key=(kind,id)=>createHash('sha256').update(JSON.stringify([kind,id])).digest('hex');

function authTransition(previous,active,eventAt) {
  if(!Number.isFinite(eventAt)||eventAt<0)throw Error('Invalid Auth event time');
  // Deletion wins a timestamp tie. Duplicate delivery and older retries are
  // harmless, including recreation of a UID after its previous deletion.
  if(previous&&(previous.eventAt>eventAt||(previous.eventAt===eventAt&&(!previous.active||active))))return null;
  return {active,eventAt,delta:Number(active)-Number(previous?.active===true)};
}

async function reconcileAuth(db,{uid,active,eventAt,registeredAt=eventAt,displayName='',email=''}) {
  if(typeof uid!=='string'||!uid||uid.includes('/'))throw Error('Invalid UID');
  const state=db.collection('admin_sync_state').doc(key('auth',uid));
  const summary=db.doc('admin_statistics/accounts'),directory=db.doc(`user_directory/${uid}`),control=db.doc(`account_controls/${uid}`);
  await db.runTransaction(async t=>{
    const [old,stats,listed,controlled]=await Promise.all([t.get(state),t.get(summary),t.get(directory),t.get(control)]);
    const transition=authTransition(old.data(),active,eventAt);if(!transition)return;
    const count=(stats.data()?.method==='realtime_auth_events'?stats.data().totalRegisteredAccounts:0)+transition.delta;
    if(!Number.isSafeInteger(count)||count<0)throw Error('Auth aggregate requires repair');
    t.set(state,{kind:'auth',sourceId:uid,active,eventAt});
    t.set(summary,{schemaVersion:1,source:'firebase_auth',method:'realtime_auth_events',totalRegisteredAccounts:count,
      ready:stats.data()?.method==='realtime_auth_events'&&stats.data()?.ready===true,updatedAt:FieldValue.serverTimestamp()},{merge:true});
    if(active){
      if(!listed.exists)t.set(directory,{displayName:displayName.slice(0,100),email:email.slice(0,254),createdAt:Timestamp.fromMillis(Number.isFinite(registeredAt)?registeredAt:eventAt),updatedAt:FieldValue.serverTimestamp()});
      if(controlled.data()?.updatedBy==='firebase_auth')t.delete(control);
    }else{
      t.delete(directory);
      t.delete(db.doc(`user_sync/${uid}`));
      // Existing access listener stops an already signed-in app too. Client
      // Rules continue to enforce the lock even with an unexpired ID token.
      t.set(control,{status:'suspended',reason:'Tài khoản Firebase Authentication đã bị xóa.',updatedBy:'firebase_auth',updatedAt:FieldValue.serverTimestamp(),lastAdminOperationId:key('auth-delete',`${uid}:${eventAt}`)});
    }
  });
}

function contribution(kind,data,listed=true){
  if(!data)return 0;
  return kind==='account_controls'?Number(data.status==='suspended'&&listed):1;
}

async function reconcileOperation(db,kind,id){
  if(!collections.includes(kind))throw Error('Unsupported aggregate collection');
  const state=db.collection('admin_sync_state').doc(key(kind,id)),source=db.collection(kind).doc(id),summary=db.doc('admin_statistics/operations');
  const field={food_catalog:'foods',user_directory:'accounts',account_controls:'suspended',admin_audit:'audits'}[kind];
  await db.runTransaction(async t=>{
    const [row,old,stats,listed]=await Promise.all([t.get(source),t.get(state),t.get(summary),kind==='account_controls'?t.get(db.doc(`user_directory/${id}`)):Promise.resolve(null)]);
    // Read current state inside the transaction, not the event's old snapshot:
    // at-least-once and out-of-order Firestore events converge to current data.
    const value=contribution(kind,row.data(),listed?.exists??true),delta=value-(old.data()?.value??0);
    if(!delta&&old.exists)return;
    const before=stats.data()??{},count=(before[field]??0)+delta;
    if(!Number.isSafeInteger(count)||count<0)throw Error('Operation aggregate requires repair');
    t.set(state,{kind,sourceId:id,value});
    t.set(summary,{schemaVersion:1,ready:before.ready===true,foods:before.foods??0,accounts:before.accounts??0,suspended:before.suspended??0,audits:before.audits??0,[field]:count,updatedAt:FieldValue.serverTimestamp()});
  });
}

async function bootstrap(db,auth){
  // Baseline ordering must use the same server clock as Auth events, never
  // the operator laptop's wall clock.
  const run=db.collection('admin_sync_runs').doc();
  await run.set({startedAt:FieldValue.serverTimestamp()});
  const started=(await run.get()).data().startedAt.toMillis();let token,authCount=0;
  do{
    const page=await auth.listUsers(1000,token);
    for(const user of page.users){await reconcileAuth(db,{uid:user.uid,active:true,eventAt:started,registeredAt:Date.parse(user.metadata.creationTime),displayName:user.displayName??'',email:user.email??''});authCount++;}
    token=page.pageToken;
  }while(token);
  // Repair missed deletions too (Firebase Admin bulk deleteUsers does not emit
  // per-user Auth events). Do not persist credentials or export user details.
  const registry=await db.collection('admin_sync_state').where('kind','==','auth').get();
  for(const row of registry.docs){const state=row.data();if(state.active&&state.eventAt<started)await reconcileAuth(db,{uid:state.sourceId,active:false,eventAt:started});}
  for(const kind of collections){
    let cursor;
    do{
      let query=db.collection(kind).orderBy('__name__').limit(200);if(cursor)query=query.startAfter(cursor);
      const page=await query.get();
      for(const row of page.docs)await reconcileOperation(db,kind,row.id);
      cursor=page.size===200?page.docs.at(-1):null;
    }while(cursor);
    const states=await db.collection('admin_sync_state').where('kind','==',kind).get();
    for(const row of states.docs)await reconcileOperation(db,kind,row.data().sourceId);
  }
  // Initialize an empty project without replacing counters maintained by events.
  await db.runTransaction(async t=>{
    const a=db.doc('admin_statistics/accounts'),o=db.doc('admin_statistics/operations');const [accounts,operations]=await Promise.all([t.get(a),t.get(o)]);
    t.set(a,{schemaVersion:1,source:'firebase_auth',method:'realtime_auth_events',totalRegisteredAccounts:accounts.data()?.method==='realtime_auth_events'?accounts.data().totalRegisteredAccounts:0,ready:true,updatedAt:FieldValue.serverTimestamp(),bootstrappedAt:FieldValue.serverTimestamp()},{merge:true});
    t.set(o,{schemaVersion:1,foods:0,accounts:0,suspended:0,audits:0,...operations.data(),ready:true,updatedAt:FieldValue.serverTimestamp(),bootstrappedAt:FieldValue.serverTimestamp()});
  });
  await run.delete();
  return {authScanned:authCount,ready:true};
}
module.exports={collections,key,authTransition,contribution,reconcileAuth,reconcileOperation,bootstrap};
