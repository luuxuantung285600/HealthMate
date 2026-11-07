const {test,after}=require('node:test');const assert=require('node:assert/strict');
process.env.FIRESTORE_EMULATOR_HOST='127.0.0.1:8092';process.env.FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9098';
const {initializeApp,deleteApp}=require('firebase-admin/app');const {getFirestore}=require('firebase-admin/firestore');const {getAuth}=require('firebase-admin/auth');
const {bootstrap,reconcileAuth,reconcileOperation,key}=require('../src/sync.cjs');
const app=initializeApp({projectId:'demo-healthmate-admin'}),db=getFirestore(app),auth=getAuth(app);
async function until(check){const end=Date.now()+30000;while(Date.now()<end){const value=await check();if(value)return value;await new Promise(resolve=>setTimeout(resolve,100));}throw Error('Realtime emulator update timed out');}
after(()=>deleteApp(app));

test('bootstrap and real Auth triggers count unverified registrations, publish directory, lock deleted sessions and retry safely',async()=>{
  await bootstrap(db,auth);
  const before=(await db.doc('admin_statistics/accounts').get()).data().totalRegisteredAccounts;
  const uid=`rt-auth-${Date.now()}`;
  await auth.createUser({uid,email:`${uid}@example.test`,emailVerified:false});
  await until(async()=>((await db.doc('admin_statistics/accounts').get()).data()?.totalRegisteredAccounts===before+1));
  assert.equal((await db.doc(`user_directory/${uid}`).get()).exists,true);
  const state=(await db.doc(`admin_sync_state/${key('auth',uid)}`).get()).data();
  await reconcileAuth(db,{uid,active:true,eventAt:state.eventAt});
  assert.equal((await db.doc('admin_statistics/accounts').get()).data().totalRegisteredAccounts,before+1);
  await auth.deleteUser(uid);
  await until(async()=>((await db.doc('admin_statistics/accounts').get()).data()?.totalRegisteredAccounts===before));
  assert.equal((await db.doc(`user_directory/${uid}`).get()).exists,false);
  assert.equal((await db.doc(`account_controls/${uid}`).get()).data().status,'suspended');
  await reconcileAuth(db,{uid,active:true,eventAt:state.eventAt});
  assert.equal((await db.doc(`user_directory/${uid}`).get()).exists,false,'late create must not resurrect deleted account');
});

test('Firestore triggers maintain counts for edits, archives, creation and deletion without double increments',async()=>{
  const baseline=(await db.doc('admin_statistics/operations').get()).data().foods;
  const id=`rt-food-${Date.now()}`,food=db.doc(`food_catalog/${id}`);
  await food.set({name:'Synthetic emulator fixture',isActive:true});
  await until(async()=>((await db.doc('admin_statistics/operations').get()).data().foods===baseline+1));
  await food.update({isActive:false});await reconcileOperation(db,'food_catalog',id);await reconcileOperation(db,'food_catalog',id);
  assert.equal((await db.doc('admin_statistics/operations').get()).data().foods,baseline+1);
  await food.delete();
  await until(async()=>((await db.doc('admin_statistics/operations').get()).data().foods===baseline));
  await reconcileOperation(db,'food_catalog',id);
  assert.equal((await db.doc('admin_statistics/operations').get()).data().foods,baseline);
});

test('each report and library source emits private revisions for create, update and delete; bootstrap remains idempotent',async()=>{
  const uid='rt-private-fixture',other='rt-other-fixture';
  for(const kind of ['meal_logs','water_logs','activity_logs','body_metrics','nutrition_targets','day_reviews','sleep_logs','custom_foods','recipes']){
    const doc=db.doc(`users/${uid}/${kind}/fixture`);await doc.set({testOnly:true});
    await until(async()=>((await db.doc(`user_sync/${uid}`).get()).data()?.[kind]));
    const created=(await db.doc(`user_sync/${uid}`).get()).data()[kind];
    await doc.update({testOnly:'updated'});
    await until(async()=>((await db.doc(`user_sync/${uid}`).get()).data()?.[kind]?.toMillis()>created.toMillis()));
    const updated=(await db.doc(`user_sync/${uid}`).get()).data()[kind];
    await doc.delete();
    await until(async()=>((await db.doc(`user_sync/${uid}`).get()).data()?.[kind]?.toMillis()>updated.toMillis()));
  }
  assert.equal((await db.doc(`user_sync/${other}`).get()).exists,false);
  const before=(await db.doc('admin_statistics/accounts').get()).data().totalRegisteredAccounts;
  await bootstrap(db,auth);await bootstrap(db,auth);
  const after=(await db.doc('admin_statistics/accounts').get()).data();
  assert.equal(after.totalRegisteredAccounts,before);assert.equal(after.ready,true);
});
