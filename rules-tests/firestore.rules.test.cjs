const fs = require('node:fs');
const path = require('node:path');
const { after, before, beforeEach, test } = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  collection,
  collectionGroup,
  writeBatch,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  where,
  orderBy,
  limit,
  runTransaction,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} = require('firebase/firestore');

let environment;
// Existing business-rule cases represent users whose email is verified.
const verifiedContext = (uid, claims={}) => environment.authenticatedContext(uid,{email_verified:true,...claims});

test('unverified and missing email claims cannot read/write private data or catalog; verified owner can',async()=>{
  await environment.withSecurityRulesDisabled(async c=>{
    const d=c.firestore();await setDoc(doc(d,'users/alice'),{displayName:'Private profile'});
    await setDoc(doc(d,'users/alice/meal_logs/private'),{totalKcal:100});
    await setDoc(doc(d,'food_catalog/rice'),{name:'Rice'});
  });
  for(const claims of [{email_verified:false},{}]) {
    const a=environment.authenticatedContext('alice',claims).firestore();
    for(const p of ['users/alice','users/alice/meal_logs/private','food_catalog/rice','app_config/runtime']) await assertFails(getDoc(doc(a,p)));
    await assertFails(setDoc(doc(a,'users/alice'),profileData()));
    await assertFails(deleteDoc(doc(a,'users/alice/meal_logs/private')));
  }
  await assertSucceeds(getDoc(doc(verifiedContext('alice').firestore(),'users/alice/meal_logs/private')));
  await assertFails(getDoc(doc(verifiedContext('bob').firestore(),'users/alice/meal_logs/private')));
});

test('H6 optional fiber keeps known zero, partial subtotals, five/six rows and rejects downgrade',async()=>{
  const a=verifiedContext('alice').firestore(),b=verifiedContext('bob').firestore();
  const full={...mealItem(),fiberG:2.4},partial={...mealItem(),fiberG:1.2,fiberIncomplete:true};
  const m=doc(a,'users/alice/meal_logs/h6'),data={...mealData(Array(5).fill(full)),schemaVersion:4};
  await assertSucceeds(setDoc(m,data));console.log('H6 full five created');await assertSucceeds(updateDoc(m,{items:[partial,full,full,full,full],updatedAt:serverTimestamp()}));
  console.log('H6 mixed five updated');
  await assertFails(updateDoc(m,{schemaVersion:2,updatedAt:serverTimestamp()}));
  const nonG={...full,grams:null,quantity:250,quantityUnit:'ml'};
  await assertSucceeds(setDoc(doc(a,'users/alice/meal_logs/h6-volume'),{...data,items:Array(5).fill(nonG)}));
  for(const bad of [{fiberG:-1},{fiberG:1001},{fiberG:NaN},{fiberG:'0'},{fiberG:2,knownFiberG:1}])await assertFails(setDoc(doc(a,'users/alice/meal_logs/h6-bad'),{...data,items:[{...full,...bad}]}));
  console.log('H6 full volume five created');
  const compact=i=>({...Object.fromEntries(Object.entries(i).filter(([k,v])=>!['fiberG','knownFiberG','fiberIncomplete','grams'].includes(k) && !(v==null&&['proteinG','carbsG','fatG'].includes(k)))),quantity:i.grams??i.quantity,quantityUnit:i.grams==null?i.quantityUnit:'g'});
  const t=doc(a,'users/alice/meal_templates/h6');
  await assertSucceeds(setDoc(t,{name:'H6 template',items:Array(5).fill(compact(nonG)),schemaVersion:3,fiberValues:Array(5).fill(2.4),createdAt:serverTimestamp(),updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(t,{fiberValues:[1.2,2.4,1.2,2.4,1.2],fiberPartialMask:21,items:[partial,full,partial,full,partial].map(compact),updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(t,{items:[compact(nonG),compact({...nonG,proteinG:null,carbsG:null,fatG:null}),compact(full),compact(partial),compact(full)],fiberValues:[2.4,null,0,1.2,2.4],fiberPartialMask:8,updatedAt:serverTimestamp()}));
  for(const patch of [{fiberValues:[1]},{fiberValues:[-1,0,0,0,0]},{fiberValues:[NaN,0,0,0,0]},{fiberPartialMask:32},{fiberPartialMask:-1},{fiberPartialMask:'1'},{extra:true}])await assertFails(updateDoc(t,{...patch,updatedAt:serverTimestamp()}));
  const attack={...data,items:[{...full,unexpected:'x'}]};delete attack.items[0].proteinG;
  await assertFails(setDoc(doc(a,'users/alice/meal_logs/h6-key-substitution'),attack));
  for(const key of ['totalKcal','consumedAt','source']){const missing={...data,unexpected:1};delete missing[key];await assertFails(setDoc(doc(a,'users/alice/meal_logs/h6-key-substitution'),missing));}
  await assertSucceeds(setDoc(doc(a,'users/alice/meal_logs/h6-five-partial'),{...data,items:Array(5).fill(partial)}));
  await assertFails(updateDoc(t,{schemaVersion:1,updatedAt:serverTimestamp()}));
  const r=doc(a,'users/alice/recipes/h6');
  await assertSucceeds(setDoc(r,recipeData({ingredients:Array(6).fill(full),schemaVersion:2})));
  await assertSucceeds(updateDoc(r,{ingredients:[full,partial,full,partial,full,partial],updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(r,{schemaVersion:1,updatedAt:serverTimestamp()}));
  const p=doc(a,'users/alice/custom_foods/h6');
  await assertSucceeds(setDoc(p,personalFoodData({fiberGPer100g:0,schemaVersion:2})));
  await assertFails(updateDoc(p,{fiberGPer100g:101,updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(p,{schemaVersion:1,updatedAt:serverTimestamp()}));
  for(const path of [m.path,t.path,r.path,p.path]){await assertFails(getDoc(doc(b,path)));await assertFails(updateDoc(doc(b,path),{updatedAt:serverTimestamp()}));}
});

test('H5 day reviews are owner-only, validated, immutable-createdAt and bounded by local date',async()=>{
  const a=verifiedContext('alice').firestore(),b=verifiedContext('bob').firestore(),g=environment.unauthenticatedContext().firestore();
  const key='2026-01-01',ref=doc(a,`users/alice/day_reviews/${key}`);
  const d={dateKey:key,mealsComplete:true,mealCount:0,latestMealUpdate:null,timezoneOffsetMinutes:420,createdAt:serverTimestamp(),updatedAt:serverTimestamp(),schemaVersion:1};
  await assertSucceeds(setDoc(ref,d));await assertSucceeds(getDocs(query(collection(a,'users/alice/day_reviews'),orderBy('dateKey'),limit(91))));
  await assertSucceeds(updateDoc(ref,{mealsComplete:false,updatedAt:serverTimestamp()}));
  for(const db of [b,g]){await assertFails(getDoc(doc(db,ref.path)));await assertFails(getDocs(collection(db,'users/alice/day_reviews')));await assertFails(setDoc(doc(db,ref.path),d));await assertFails(deleteDoc(doc(db,ref.path)));}
  const patches=[{extra:1},{dateKey:'2026-02-30'},{dateKey:'2999-01-01'},{mealCount:2001},{mealCount:1},{mealsComplete:'true'},{timezoneOffsetMinutes:841},{schemaVersion:2}];
  for(let i=0;i<patches.length;i++){const patch=patches[i],dayKey=patch.dateKey??`2026-01-${String(i+2).padStart(2,'0')}`;await assertFails(setDoc(doc(a,`users/alice/day_reviews/${dayKey}`),{...d,dateKey:dayKey,...patch}));}
  await assertFails(updateDoc(ref,{createdAt:Timestamp.fromMillis(0),updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(ref,{mealCount:2,latestMealUpdate:Timestamp.fromDate(new Date('2026-01-01T00:00:00Z')),updatedAt:serverTimestamp()}));
});

test('H3 calorie-only and non-mass meals keep null macros; five snapshots and templates remain bounded', async()=>{
  const alice=verifiedContext('alice').firestore(),bob=verifiedContext('bob').firestore();
  const quick={...mealItem(),grams:null,quantityUnit:'entry',quantity:1,kcal:250,proteinG:null,carbsG:null,fatG:null};
  const data={...mealData([quick]),totalProteinG:null,totalCarbsG:null,totalFatG:null,schemaVersion:3};
  await assertSucceeds(setDoc(doc(alice,'users/alice/meal_logs/h3'),data));
  await assertSucceeds(setDoc(doc(alice,'users/alice/meal_logs/h3-legacy-source'),{...data,items:[{...quick,sourceLabel:''}]}));
  await assertSucceeds(setDoc(doc(alice,'users/alice/meal_logs/h3-five'),{...data,items:Array(5).fill(quick),totalKcal:1250}));
  await assertFails(getDoc(doc(bob,'users/alice/meal_logs/h3')));
  for(const item of [{...quick,grams:100},{...quick,quantity:0},{...quick,quantityUnit:'litre'},{...quick,proteinG:-1},{...quick,proteinG:1001},{...quick,proteinG:'0'},{...quick,kcal:NaN}]) {
    await assertFails(setDoc(doc(alice,'users/alice/meal_logs/bad'),{...data,items:[item]}));
  }
  await assertFails(setDoc(doc(alice,'users/alice/meal_logs/legacy-null'),{...data,schemaVersion:2}));
  const template={name:'H3 template',items:Array(5).fill(quick),schemaVersion:2,createdAt:serverTimestamp(),updatedAt:serverTimestamp()};
  console.log('H3 rule five unknown template');
  await assertSucceeds(setDoc(doc(alice,'users/alice/meal_templates/h3'),template));
  const complete={...quick,quantityUnit:'ml',quantity:100,proteinG:1,carbsG:1,fatG:1};
  console.log('H3 rule five known template');
  await assertSucceeds(setDoc(doc(alice,'users/alice/meal_logs/h3-five-known'),{...data,items:Array(5).fill(complete),totalKcal:1250,totalProteinG:5,totalCarbsG:5,totalFatG:5}));
  await assertSucceeds(updateDoc(doc(alice,'users/alice/meal_logs/h3-five-known'),{mealType:'snack',updatedAt:serverTimestamp()}));
  await assertSucceeds(setDoc(doc(alice,'users/alice/meal_templates/h3-known'),{...template,items:Array(5).fill(complete)}));
  await assertSucceeds(updateDoc(doc(alice,'users/alice/meal_templates/h3-known'),{name:'H3 edited',updatedAt:serverTimestamp()}));
  console.log('H3 rule mixed template');
  await assertSucceeds(setDoc(doc(alice,'users/alice/meal_templates/h3-mixed'),{...template,items:[quick,complete,quick,complete,complete]}));
  await assertFails(setDoc(doc(alice,'users/alice/meal_templates/h3-overflow'),{...template,items:Array(5).fill({...complete,proteinG:500})}));
  await assertFails(setDoc(doc(bob,'users/alice/meal_templates/h3'),template));
});

test('H2 templates enforce owner CRUD, immutable timestamps, five bounded snapshots and no source dependency', async () => {
  const alice=verifiedContext('alice').firestore();
  const bob=verifiedContext('bob').firestore();
  const guest=environment.unauthenticatedContext().firestore();
  const path='users/alice/meal_templates/h2';
  const template=(items=[mealItem()])=>({name:'Bữa mẫu QA H2',items,schemaVersion:1,createdAt:serverTimestamp(),updatedAt:serverTimestamp()});
  await assertSucceeds(setDoc(doc(alice,path),template()));
  await assertSucceeds(getDoc(doc(alice,path)));
  await assertSucceeds(getDocs(query(collection(alice,'users/alice/meal_templates'),orderBy('updatedAt','desc'),limit(40))));
  await assertSucceeds(updateDoc(doc(alice,path),{name:'QA đã sửa',updatedAt:serverTimestamp()}));
  for(const db of [bob,guest]) {
    await assertFails(getDoc(doc(db,path)));
    await assertFails(getDocs(collection(db,'users/alice/meal_templates')));
    await assertFails(setDoc(doc(db,'users/alice/meal_templates/other'),template()));
    await assertFails(updateDoc(doc(db,path),{name:'QA denied',updatedAt:serverTimestamp()}));
    await assertFails(deleteDoc(doc(db,path)));
  }
  await assertFails(updateDoc(doc(alice,path),{createdAt:Timestamp.fromMillis(0),updatedAt:serverTimestamp()}));
  for(const d of [template([]),template(Array(6).fill(mealItem())),{...template(),extra:true},
      {...template(),name:''},template([mealItem({grams:-1})]),template([mealItem({kcal:null})]),
      template(Array(5).fill(mealItem({proteinG:500})))]) {
    await assertFails(setDoc(doc(alice,'users/alice/meal_templates/invalid'),d));
  }
  await assertSucceeds(setDoc(doc(alice,'users/alice/meal_templates/five'),template(Array(5).fill(mealItem()))));
  await assertSucceeds(deleteDoc(doc(alice,path)));
});

const profileData = (email = 'alice@example.com') => ({
  displayName: 'Alice',
  email,
  heightCm: 168,
  birthDate: null,
  healthGoal: null,
  targetWeightKg: null,
  onboardingCompletedAt: null,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  schemaVersion: 2,
});

// Stage 9: exact client transaction shape; both messages and parent are atomic.
async function saveChatTurn(db, uid, sessionId, turnId, overrides = {}, assistantOverrides = {}) {
  const parent = doc(db, `users/${uid}/chat_sessions/${sessionId}`);
  const user = doc(db, `users/${uid}/chat_sessions/${sessionId}/messages/${turnId}_u`);
  const assistant = doc(db, `users/${uid}/chat_sessions/${sessionId}/messages/${turnId}_a`);
  return runTransaction(db, async (transaction) => {
    const existing = await transaction.get(user);
    if (existing.exists()) return;
    const snapshot = await transaction.get(parent);
    const count = snapshot.data()?.messageCount ?? 0;
    const fields = { messageCount: count + 2, lastTurnId: turnId, updatedAt: serverTimestamp() };
    if (snapshot.exists()) transaction.update(parent, fields);
    else transaction.set(parent, {
      ...fields, title: 'Trò chuyện HealthMate', createdAt: serverTimestamp(), schemaVersion: 1,
    });
    const message = (role, sequence) => ({
      role, sequence, turnId, text: role === 'user' ? 'Hôm nay tôi ăn bao nhiêu kcal?' : 'Chưa có bản ghi.',
      source: 'journal', createdAt: serverTimestamp(), schemaVersion: 1, ...overrides,
      ...(role === 'assistant' ? assistantOverrides : {}),
    });
    transaction.set(user, message('user', count));
    transaction.set(assistant, message('assistant', count + 1));
  });
}

test('chat owner can atomically save, read ordered history, retry idempotently and delete children', async () => {
  const alice = verifiedContext('alice').firestore();
  const turn = 'a'.repeat(20);
  await assertSucceeds(saveChatTurn(alice, 'alice', 'session1', turn));
  await assertSucceeds(saveChatTurn(alice, 'alice', 'session1', turn));
  const sessions = await assertSucceeds(getDocs(query(collection(alice, 'users/alice/chat_sessions'),
    orderBy('updatedAt', 'desc'), limit(20))));
  if (sessions.size !== 1 || sessions.docs[0].data().messageCount !== 2) throw new Error('Retry duplicated turn');
  const messages = await assertSucceeds(getDocs(query(collection(alice, 'users/alice/chat_sessions/session1/messages'),
    orderBy('sequence'), limit(40))));
  if (messages.size !== 2 || messages.docs[0].data().role !== 'user' || messages.docs[1].data().role !== 'assistant') {
    throw new Error('History order or atomic pairing failed');
  }
  await assertFails(updateDoc(messages.docs[0].ref, { text: 'overwrite' }));
  for (const message of messages.docs) await assertSucceeds(deleteDoc(message.ref));
  await assertSucceeds(deleteDoc(sessions.docs[0].ref));
});

test('chat denies cross-UID and unauthenticated session/message reads, writes and deletes', async () => {
  const alice = verifiedContext('alice').firestore();
  const bob = verifiedContext('bob').firestore();
  const guest = environment.unauthenticatedContext().firestore();
  const turn = 'a'.repeat(20);
  await assertSucceeds(saveChatTurn(alice, 'alice', 'session1', turn));
  for (const db of [bob, guest]) {
    for (const path of ['users/alice/chat_sessions/session1', `users/alice/chat_sessions/session1/messages/${turn}_u`]) {
      await assertFails(getDoc(doc(db, path)));
      await assertFails(updateDoc(doc(db, path), { text: 'hijack' }));
      await assertFails(deleteDoc(doc(db, path)));
    }
    await assertFails(getDocs(collection(db, 'users/alice/chat_sessions')));
    await assertFails(getDocs(collection(db, 'users/alice/chat_sessions/session1/messages')));
    await assertFails(saveChatTurn(db, 'alice', 'session2', turn));
  }
  await assertSucceeds(saveChatTurn(bob, 'bob', 'session1', turn));
});

test('chat rejects unpaired, oversized, unknown-role/source/schema messages and invalid counters', async () => {
  const alice = verifiedContext('alice').firestore();
  const turn = 'a'.repeat(20);
  const parent = doc(alice, 'users/alice/chat_sessions/session1');
  await assertFails(setDoc(parent, { title: 'orphan', messageCount: 2,
    lastTurnId: turn, createdAt: serverTimestamp(), updatedAt: serverTimestamp(), schemaVersion: 1 }));
  for (const invalid of [{ text: 'x'.repeat(1001) }, { role: 'system' }, { source: 'admin' }, { extra: 'secret' },
    { sequence: -1 }, { schemaVersion: 2 }, { createdAt: Timestamp.fromMillis(0) }]) {
    await assertFails(saveChatTurn(alice, 'alice', 'session1', turn, invalid));
  }
  await assertSucceeds(saveChatTurn(alice, 'alice', 'session1', turn));
  await assertFails(updateDoc(parent, { messageCount: 4, updatedAt: serverTimestamp() }));
  await assertFails(saveChatTurn(alice, 'alice', 'session1', 'c'.repeat(20), {}, { text: 'x'.repeat(6001) }));
  const batch = writeBatch(alice);
  batch.set(doc(alice, `users/alice/chat_sessions/session1/messages/${'b'.repeat(20)}_a`), {
    role: 'assistant', sequence: 3, turnId: 'b'.repeat(20), text: 'x'.repeat(6001), source: 'ai',
    createdAt: serverTimestamp(), schemaVersion: 1,
  });
  await assertFails(batch.commit());
});

test('chat allows 50 turns including old sessions and rejects turn 51 for a direct client', async () => {
  const alice = verifiedContext('alice').firestore();
  for (let index = 0; index < 50; index++) {
    await assertSucceeds(saveChatTurn(alice, 'alice', 'session1', String(index).padStart(20, '0')));
  }
  await assertFails(saveChatTurn(alice, 'alice', 'session1', 'z'.repeat(20)));
  const data = await getDoc(doc(alice, 'users/alice/chat_sessions/session1'));
  if (data.data().messageCount !== 100) throw new Error('Invalid session size');
});

const metricData = () => ({
  weightKg: 62.5,
  measuredAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00Z')),
  note: 'Buổi sáng',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
});

const mealItem = (overrides = {}) => ({
  foodId: 'rice-cooked',
  name: 'Cơm trắng chín',
  grams: 150,
  kcal: 195,
  proteinG: 4.04,
  carbsG: 42.26,
  fatG: 0.42,
  sourceLabel: 'USDA FoodData Central — tham khảo/100 g',
  isEstimated: true,
  ...overrides,
});

const mealData = (items = [mealItem()]) => ({
  mealType: 'lunch',
  consumedAt: Timestamp.fromDate(new Date('2026-01-01T05:00:00Z')),
  dateKey: '2026-01-01',
  timezoneOffsetMinutes: 420,
  items,
  totalKcal: items.reduce((sum, item) => sum + item.kcal, 0),
  totalProteinG: items.reduce((sum, item) => sum + item.proteinG, 0),
  totalCarbsG: items.reduce((sum, item) => sum + item.carbsG, 0),
  totalFatG: items.reduce((sum, item) => sum + item.fatG, 0),
  source: 'manual',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  schemaVersion: 2,
});

const waterData = () => ({
  amountMl: 250,
  consumedAt: Timestamp.fromDate(new Date('2026-01-01T05:00:00Z')),
  dateKey: '2026-01-01',
  timezoneOffsetMinutes: 420,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
});

const activityData = () => ({
  activityType: 'walking',
  durationMinutes: 30,
  performedAt: Timestamp.fromDate(new Date('2026-01-01T05:00:00Z')),
  dateKey: '2026-01-01',
  timezoneOffsetMinutes: 420,
  note: 'Đi bộ trong công viên',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
});

test('audit: date keys must match the timestamp in the recorded timezone, including midnight and leap day', async () => {
  const db = verifiedContext('alice').firestore();
  const fixtures = [
    ['meal_logs', mealData(), 'consumedAt'],
    ['water_logs', waterData(), 'consumedAt'],
    ['activity_logs', activityData(), 'performedAt'],
  ];
  for (const [name, original, timeField] of fixtures) {
    const boundary = { ...original, [timeField]: Timestamp.fromDate(new Date('2026-10-15T17:00:00Z')),
      dateKey: '2026-10-16', timezoneOffsetMinutes: 420 };
    await assertSucceeds(setDoc(doc(db, `users/alice/${name}/boundary`), boundary));
    await assertFails(setDoc(doc(db, `users/alice/${name}/mismatch`), { ...boundary, dateKey: '2026-10-15' }));
    await assertFails(setDoc(doc(db, `users/alice/${name}/impossible`), { ...boundary, dateKey: '2026-02-30' }));
    await assertSucceeds(setDoc(doc(db, `users/alice/${name}/leap`), {
      ...original, [timeField]: Timestamp.fromDate(new Date('2024-02-29T00:00:00Z')),
      dateKey: '2024-02-29', timezoneOffsetMinutes: 0,
    }));
    for (const offset of [-721, 841, '420', null]) {
      await assertFails(setDoc(doc(db, `users/alice/${name}/invalid-offset`), { ...boundary, timezoneOffsetMinutes: offset }));
    }
  }
});

test('audit: unknown paths, collection-group access and privilege injection cannot bypass ownership', async () => {
  const db = verifiedContext('alice', { email: 'alice@example.com' }).firestore();
  const guest = environment.unauthenticatedContext().firestore();
  for (const path of ['admin/config', 'secrets/keys', 'users/bob/future/data']) {
    await assertFails(getDoc(doc(db, path)));
    await assertFails(setDoc(doc(db, path), { value: true }));
    await assertFails(deleteDoc(doc(db, path)));
    await assertFails(getDoc(doc(guest, path)));
  }
  await assertFails(setDoc(doc(db, 'users/alice/future/data'), { value: 'unrecognized schema' }));
  await assertSucceeds(setDoc(doc(db, 'users/alice'), profileData()));
  await assertFails(updateDoc(doc(db, 'users/alice'), { role: 'admin', updatedAt: serverTimestamp() }));
  await assertFails(getDocs(collectionGroup(db, 'water_logs')));
});

before(async () => {
  const [emulatorHost, emulatorPort] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
  const projectId=process.env.HEALTHMATE_RULES_TEST_PROJECT||'demo-healthmate-rules';
  if(!/^demo-[a-z0-9-]+$/.test(projectId))throw Error('Rules tests require an isolated demo project.');
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: emulatorHost,
      port: Number(emulatorPort),
      rules: fs.readFileSync(
        process.env.HEALTHMATE_RULES_FILE || path.join(__dirname, '..', 'firestore.rules'),
        'utf8',
      ),
    },
  });
});

beforeEach(async () => environment.clearFirestore());
after(async () => environment.cleanup());

test('owner can create, read, update and delete their profile', async () => {
  const alice = verifiedContext('alice', {
    email: 'alice@example.com',
  });
  const reference = doc(alice.firestore(), 'users/alice');

  await assertSucceeds(setDoc(reference, profileData()));
  await assertSucceeds(getDoc(reference));
  await assertSucceeds(
    updateDoc(reference, {
      displayName: 'Alice Nguyen',
      heightCm: 170.5,
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(updateDoc(reference, { schemaVersion: 3 }));
  await assertFails(updateDoc(reference, { createdAt: serverTimestamp() }));
  await assertSucceeds(deleteDoc(reference));
});

test('owner can complete onboarding only with valid required data', async () => {
  const alice = verifiedContext('alice', {
    email: 'alice@example.com',
  });
  const reference = doc(alice.firestore(), 'users/alice');
  await assertSucceeds(setDoc(reference, profileData()));

  await assertFails(
    updateDoc(reference, {
      displayName: 'Alice Nguyen',
      birthDate: Timestamp.fromDate(new Date('2000-01-15T00:00:00Z')),
      healthGoal: 'lose_weight',
      targetWeightKg: null,
      onboardingCompletedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(
    updateDoc(reference, {
      displayName: 'Alice Nguyen',
      birthDate: Timestamp.fromDate(new Date('2000-01-15T00:00:00Z')),
      healthGoal: 'unsupported_goal',
      onboardingCompletedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(
    updateDoc(reference, {
      displayName: 'Alice Nguyen',
      birthDate: Timestamp.fromDate(new Date('2000-01-15T00:00:00Z')),
      healthGoal: 'lose_weight',
      targetWeightKg: 58,
      onboardingCompletedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
  await assertFails(
    updateDoc(reference, {
      // A fresh serverTimestamp can equal the original in a fast emulator run.
      // Use a guaranteed different value to test marker immutability.
      onboardingCompletedAt: Timestamp.fromMillis(1),
      updatedAt: serverTimestamp(),
    }),
  );
});

test('other users and anonymous clients cannot access a profile', async () => {
  const alice = verifiedContext('alice', {
    email: 'alice@example.com',
  });
  const bob = verifiedContext('bob', {
    email: 'bob@example.com',
  });
  const anonymous = environment.unauthenticatedContext();

  await assertSucceeds(
    setDoc(doc(alice.firestore(), 'users/alice'), profileData()),
  );
  await assertFails(getDoc(doc(bob.firestore(), 'users/alice')));
  await assertFails(
    setDoc(doc(bob.firestore(), 'users/alice'), profileData('bob@example.com')),
  );
  await assertFails(getDoc(doc(anonymous.firestore(), 'users/alice')));
  await assertFails(deleteDoc(doc(bob.firestore(), 'users/alice')));
});

test('only the owner can delete nested private account data', async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), 'users/alice/goals/goal-1'),
      { status: 'active' },
    );
    await setDoc(
      doc(
        context.firestore(),
        'users/alice/chat_sessions/session-1/messages/message-1',
      ),
      { text: 'private' },
    );
  });
  const alice = verifiedContext('alice');
  const bob = verifiedContext('bob');
  const goalPath = 'users/alice/goals/goal-1';
  const messagePath =
    'users/alice/chat_sessions/session-1/messages/message-1';

  await assertFails(deleteDoc(doc(bob.firestore(), goalPath)));
  await assertFails(deleteDoc(doc(bob.firestore(), messagePath)));
  await assertFails(getDoc(doc(bob.firestore(), goalPath)));
  await assertSucceeds(getDoc(doc(alice.firestore(), goalPath)));
  await assertSucceeds(deleteDoc(doc(alice.firestore(), goalPath)));
  await assertSucceeds(deleteDoc(doc(alice.firestore(), messagePath)));
});

test('profile schema rejects extra fields, bad email and invalid height', async () => {
  const alice = verifiedContext('alice', {
    email: 'alice@example.com',
  });
  const db = alice.firestore();

  await assertFails(
    setDoc(doc(db, 'users/extra'), { ...profileData(), role: 'admin' }),
  );
  await assertFails(
    setDoc(doc(db, 'users/alice'), profileData('other@example.com')),
  );
  await assertFails(
    setDoc(doc(db, 'users/alice'), { ...profileData(), heightCm: 20 }),
  );
});

test('owner can create, list, update and delete valid body metrics', async () => {
  const alice = verifiedContext('alice', {
    email: 'alice@example.com',
  });
  const db = alice.firestore();
  const reference = doc(db, 'users/alice/body_metrics/metric-1');

  await assertSucceeds(setDoc(reference, metricData()));
  await assertSucceeds(
    getDocs(collection(db, 'users/alice/body_metrics')),
  );
  await assertSucceeds(
    updateDoc(reference, {
      weightKg: 63.1,
      note: '',
      updatedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(deleteDoc(reference));
});

test('body metric rules block cross-UID and invalid writes', async () => {
  const alice = verifiedContext('alice', {
    email: 'alice@example.com',
  });
  const bob = verifiedContext('bob', {
    email: 'bob@example.com',
  });
  const aliceReference = doc(
    alice.firestore(),
    'users/alice/body_metrics/metric-1',
  );

  await assertSucceeds(setDoc(aliceReference, metricData()));
  await assertFails(
    getDoc(doc(bob.firestore(), 'users/alice/body_metrics/metric-1')),
  );
  await assertFails(
    setDoc(doc(bob.firestore(), 'users/alice/body_metrics/metric-2'), metricData()),
  );
  await assertFails(
    setDoc(doc(alice.firestore(), 'users/alice/body_metrics/bad'), {
      ...metricData(),
      weightKg: 10,
    }),
  );
  await assertFails(
    updateDoc(aliceReference, { createdAt: serverTimestamp() }),
  );
});

test('signed-in users can read catalog but clients cannot write it', async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'food_catalog/rice-cooked'), {
      name: 'Cơm trắng chín',
    });
  });
  const alice = verifiedContext('alice');
  const anonymous = environment.unauthenticatedContext();
  await assertSucceeds(getDoc(doc(alice.firestore(), 'food_catalog/rice-cooked')));
  await assertFails(getDoc(doc(anonymous.firestore(), 'food_catalog/rice-cooked')));
  await assertFails(
    setDoc(doc(alice.firestore(), 'food_catalog/hacked'), { name: 'Hacked' }),
  );
});

test('owner can create, list, update and delete a valid meal log', async () => {
  const alice = verifiedContext('alice');
  const db = alice.firestore();
  const reference = doc(db, 'users/alice/meal_logs/meal-1');
  await assertSucceeds(setDoc(reference, mealData()));
  await assertSucceeds(getDocs(collection(db, 'users/alice/meal_logs')));
  await assertSucceeds(
    updateDoc(reference, {
      mealType: 'dinner',
      source: 'ai_assisted',
      updatedAt: serverTimestamp(),
    }),
  );
  await assertSucceeds(deleteDoc(reference));
});

test('meal rules accept exactly one and five valid items', async () => {
  const alice = verifiedContext('alice');
  const db = alice.firestore();
  await assertSucceeds(
    setDoc(doc(db, 'users/alice/meal_logs/one-item'), mealData()),
  );
  await assertSucceeds(
    setDoc(
      doc(db, 'users/alice/meal_logs/five-items'),
      mealData(Array.from({ length: 5 }, () => mealItem())),
    ),
  );
});

test('meal rules reject empty and oversized item lists', async () => {
  const alice = verifiedContext('alice');
  const db = alice.firestore();
  await assertFails(
    setDoc(doc(db, 'users/alice/meal_logs/empty'), mealData([])),
  );
  await assertFails(
    setDoc(
      doc(db, 'users/alice/meal_logs/too-many'),
      mealData(Array.from({ length: 6 }, () => mealItem())),
    ),
  );
});

test('meal rules reject wrong item types and extra fields', async () => {
  const alice = verifiedContext('alice');
  const db = alice.firestore();
  await assertFails(
    setDoc(
      doc(db, 'users/alice/meal_logs/wrong-item-type'),
      mealData([mealItem({ grams: '150' })]),
    ),
  );
  await assertFails(
    setDoc(
      doc(db, 'users/alice/meal_logs/extra-item-field'),
      mealData([mealItem({ secret: true })]),
    ),
  );
});

for (let invalidIndex = 0; invalidIndex < 5; invalidIndex += 1) {
  test(`meal rules reject an invalid item at position ${invalidIndex}`, async () => {
    const alice = verifiedContext('alice');
    const items = Array.from({ length: 5 }, () => mealItem());
    items[invalidIndex] = mealItem({ grams: 0 });
    await assertFails(
      setDoc(
        doc(
          alice.firestore(),
          `users/alice/meal_logs/invalid-item-${invalidIndex}`,
        ),
        mealData(items),
      ),
    );
  });
}

test('meal rules block cross-UID, invalid fields and createdAt changes', async () => {
  const alice = verifiedContext('alice');
  const bob = verifiedContext('bob');
  const reference = doc(alice.firestore(), 'users/alice/meal_logs/meal-1');
  await assertSucceeds(setDoc(reference, mealData()));
  await assertFails(getDoc(doc(bob.firestore(), 'users/alice/meal_logs/meal-1')));
  await assertFails(
    setDoc(doc(bob.firestore(), 'users/alice/meal_logs/meal-2'), mealData()),
  );
  await assertFails(
    setDoc(doc(alice.firestore(), 'users/alice/meal_logs/bad-type'), {
      ...mealData(),
      mealType: 'midnight',
    }),
  );
  await assertFails(updateDoc(reference, { createdAt: serverTimestamp() }));
});

test('meal date metadata is required and legacy meals can be upgraded on edit', async () => {
  const alice = verifiedContext('alice');
  const db = alice.firestore();
  const missingDateKey = mealData();
  delete missingDateKey.dateKey;
  await assertFails(
    setDoc(doc(db, 'users/alice/meal_logs/missing-date'), missingDateKey),
  );
  await assertFails(
    setDoc(doc(db, 'users/alice/meal_logs/bad-offset'), {
      ...mealData(),
      timezoneOffsetMinutes: 841,
    }),
  );

  const legacyPath = 'users/alice/meal_logs/legacy';
  await environment.withSecurityRulesDisabled(async (context) => {
    const legacy = mealData();
    delete legacy.dateKey;
    delete legacy.timezoneOffsetMinutes;
    legacy.schemaVersion = 1;
    await setDoc(doc(context.firestore(), legacyPath), legacy);
  });
  const legacyReference = doc(db, legacyPath);
  await assertSucceeds(getDoc(legacyReference));
  await assertSucceeds(
    updateDoc(legacyReference, {
      dateKey: '2026-01-01',
      timezoneOffsetMinutes: 420,
      schemaVersion: 2,
      updatedAt: serverTimestamp(),
    }),
  );
});

test('owner can CRUD water logs while invalid and cross-UID access is blocked', async () => {
  const alice = verifiedContext('alice');
  const bob = verifiedContext('bob');
  const reference = doc(alice.firestore(), 'users/alice/water_logs/water-1');

  await assertSucceeds(setDoc(reference, waterData()));
  await assertSucceeds(getDocs(collection(alice.firestore(), 'users/alice/water_logs')));
  await assertSucceeds(updateDoc(reference, { amountMl: 350, updatedAt: serverTimestamp() }));
  await assertFails(getDoc(doc(bob.firestore(), 'users/alice/water_logs/water-1')));
  await assertFails(setDoc(doc(bob.firestore(), 'users/alice/water_logs/water-2'), waterData()));
  await assertFails(setDoc(doc(alice.firestore(), 'users/alice/water_logs/bad'), {
    ...waterData(),
    amountMl: 20,
  }));
  await assertFails(setDoc(doc(alice.firestore(), 'users/alice/water_logs/bad-date'), {
    ...waterData(),
    dateKey: '2026-13-01',
  }));
  await assertFails(setDoc(doc(alice.firestore(), 'users/alice/water_logs/bad-offset'), {
    ...waterData(),
    timezoneOffsetMinutes: 841,
  }));
  await assertFails(updateDoc(reference, { createdAt: serverTimestamp() }));
  await assertSucceeds(deleteDoc(reference));
});

test('owner can CRUD activity logs while invalid and cross-UID access is blocked', async () => {
  const alice = verifiedContext('alice');
  const bob = verifiedContext('bob');
  const reference = doc(alice.firestore(), 'users/alice/activity_logs/activity-1');

  await assertSucceeds(setDoc(reference, activityData()));
  await assertSucceeds(getDocs(collection(alice.firestore(), 'users/alice/activity_logs')));
  await assertSucceeds(updateDoc(reference, {
    durationMinutes: 45,
    note: '',
    updatedAt: serverTimestamp(),
  }));
  await assertFails(getDoc(doc(bob.firestore(), 'users/alice/activity_logs/activity-1')));
  await assertFails(setDoc(doc(bob.firestore(), 'users/alice/activity_logs/activity-2'), activityData()));
  await assertFails(setDoc(doc(alice.firestore(), 'users/alice/activity_logs/bad'), {
    ...activityData(),
    activityType: 'swimming',
  }));
  await assertFails(setDoc(doc(alice.firestore(), 'users/alice/activity_logs/bad-date'), {
    ...activityData(),
    dateKey: '2026-01-32',
  }));
  await assertFails(updateDoc(reference, { createdAt: serverTimestamp() }));
  await assertSucceeds(deleteDoc(reference));
});

const goalData = (overrides = {}) => ({
  goalType: 'water', targetValue: 1500, unit: 'ml',
  startDateKey: '2026-10-16', endDateKey: '2026-11-16',
  status: 'active', baselineWeightKg: null,
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), schemaVersion: 1,
  ...overrides,
});
const questData = (dateKey = '2026-10-16') => ({
  dateKey, questType: 'water', title: 'Ghi lại nước đã uống',
  description: 'Chỉ ghi lượng thực tế.', reason: 'Bạn chọn theo dõi nước.',
  targetValue: 250, unit: 'ml', status: 'available', completedAt: null,
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ruleVersion: 1,
});

test('goals CRUD preserves schema, unit, baseline, timestamps and ownership', async () => {
  const alice = verifiedContext('alice').firestore();
  const bob = verifiedContext('bob').firestore();
  const guest = environment.unauthenticatedContext().firestore();
  const path = 'users/alice/goals/water';
  const ref = doc(alice, path);
  await assertSucceeds(setDoc(ref, goalData()));
  await assertSucceeds(getDocs(collection(alice, 'users/alice/goals')));
  await assertSucceeds(updateDoc(ref, { targetValue: 1000, status: 'paused', updatedAt: serverTimestamp() }));
  for (const db of [bob, guest]) {
    await assertFails(getDoc(doc(db, path)));
    await assertFails(getDocs(collection(db, 'users/alice/goals')));
    await assertFails(setDoc(doc(db, 'users/alice/goals/other'), goalData()));
    await assertFails(updateDoc(doc(db, path), { status: 'completed', updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(db, path)));
  }
  for (const bad of [
    { targetValue: -1 }, { targetValue: 5001 }, { targetValue: 123.5 },
    { unit: 'litres' }, { status: 'unknown' }, { extra: true },
    { endDateKey: '2026-10-01' }, { startDateKey: '2026-13-01' },
    { startDateKey: '2026-02-30' },
    { baselineWeightKg: 70 },
  ]) {
    await assertFails(setDoc(doc(alice, 'users/alice/goals/invalid'), goalData(bad)));
  }
  await assertFails(updateDoc(ref, { createdAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { goalType: 'activity', unit: 'phút', targetValue: 20, updatedAt: serverTimestamp() }));
  await assertSucceeds(setDoc(doc(alice, 'users/alice/goals/weight'), goalData({
    goalType: 'weight', targetValue: 65, unit: 'kg', baselineWeightKg: 70,
  })));
  await assertFails(updateDoc(doc(alice, 'users/alice/goals/weight'), {
    baselineWeightKg: 80, updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(deleteDoc(ref));
});

test('quests reject cross-UID access and illegal content or status transitions', async () => {
  const alice = verifiedContext('alice').firestore();
  const bob = verifiedContext('bob').firestore();
  const guest = environment.unauthenticatedContext().firestore();
  const path = 'users/alice/daily_quests/2026-10-16';
  const ref = doc(alice, path);
  await assertSucceeds(setDoc(ref, questData()));
  await assertSucceeds(getDoc(ref));
  for (const db of [bob, guest]) {
    await assertFails(getDoc(doc(db, path)));
    await assertFails(getDocs(collection(db, 'users/alice/daily_quests')));
    await assertFails(setDoc(doc(db, 'users/alice/daily_quests/2026-10-17'), questData('2026-10-17')));
    await assertFails(updateDoc(doc(db, path), { status: 'skipped', updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(db, path)));
  }
  await assertFails(setDoc(doc(alice, 'users/alice/daily_quests/random-id'), questData()));
  await assertFails(setDoc(doc(alice, 'users/alice/daily_quests/2026-02-30'), questData('2026-02-30')));
  await assertFails(updateDoc(ref, { title: 'Changed', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { status: 'completed', updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(ref, {
    status: 'completed', completedAt: serverTimestamp(), updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(ref, { status: 'available', completedAt: null, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { status: 'skipped', completedAt: null, updatedAt: serverTimestamp() }));
  const skipped = doc(alice, 'users/alice/daily_quests/2026-10-17');
  await assertSucceeds(setDoc(skipped, questData('2026-10-17')));
  await assertSucceeds(updateDoc(skipped, { status: 'skipped', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(skipped, { status: 'completed', completedAt: serverTimestamp(), updatedAt: serverTimestamp() }));
});

test('create-if-absent transactions do not duplicate or overwrite a finished daily quest', async () => {
  const alice = verifiedContext('alice').firestore();
  const ref = doc(alice, 'users/alice/daily_quests/2026-10-16');
  const ensure = () => runTransaction(alice, async (tx) => {
    const snapshot = await tx.get(ref);
    if (!snapshot.exists()) tx.set(ref, questData());
  });
  await Promise.all([ensure(), ensure()]);
  await assertSucceeds(updateDoc(ref, { status: 'skipped', updatedAt: serverTimestamp() }));
  await ensure();
  const documents = await getDocs(collection(alice, 'users/alice/daily_quests'));
  if (documents.size !== 1 || documents.docs[0].data().status !== 'skipped') {
    throw new Error('Daily quest must keep one document and its terminal status');
  }
});

test('weekly range queries keep local date boundaries, legacy meals and UID isolation', async () => {
  const start = Timestamp.fromDate(new Date('2026-10-11T17:00:00Z'));
  const end = Timestamp.fromDate(new Date('2026-10-18T17:00:00Z'));
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const current = { ...mealData(), dateKey: '2026-10-12', consumedAt: start };
    const legacy = (time) => {
      const data = { ...mealData(), consumedAt: time, schemaVersion: 1 };
      delete data.dateKey;
      delete data.timezoneOffsetMinutes;
      return data;
    };
    await setDoc(doc(db, 'users/alice/meal_logs/current'), current);
    await setDoc(doc(db, 'users/alice/meal_logs/start'), legacy(start));
    await setDoc(doc(db, 'users/alice/meal_logs/last'), legacy(Timestamp.fromMillis(end.toMillis() - 1)));
    await setDoc(doc(db, 'users/alice/meal_logs/end'), legacy(end));
    await setDoc(doc(db, 'users/alice/meal_logs/before'), legacy(Timestamp.fromMillis(start.toMillis() - 1)));
    await setDoc(doc(db, 'users/alice/meal_logs/key-wins'), {
      ...current, consumedAt: Timestamp.fromMillis(start.toMillis() - 1),
    });
    for (const [name, data] of [['water_logs', waterData()], ['activity_logs', activityData()]]) {
      await setDoc(doc(db, `users/alice/${name}/start`), { ...data, dateKey: '2026-10-12' });
      await setDoc(doc(db, `users/alice/${name}/end`), { ...data, dateKey: '2026-10-19' });
    }
    for (const [id, measuredAt] of [['start', start], ['last', Timestamp.fromMillis(end.toMillis() - 1)], ['end', end]]) {
      await setDoc(doc(db, `users/alice/body_metrics/${id}`), { ...metricData(), measuredAt });
    }
  });
  const alice = verifiedContext('alice').firestore();
  const mealCollection = collection(alice, 'users/alice/meal_logs');
  const modern = await assertSucceeds(getDocs(query(mealCollection,
    where('dateKey', '>=', '2026-10-12'), where('dateKey', '<', '2026-10-19'))));
  const legacy = await assertSucceeds(getDocs(query(mealCollection,
    where('consumedAt', '>=', start), where('consumedAt', '<', end))));
  const byId = new Map(modern.docs.map((d) => [d.id, d.data()]));
  for (const d of legacy.docs) {
    if (typeof d.data().dateKey !== 'string') byId.set(d.id, d.data());
  }
  const ids = [...byId.keys()].sort().join(',');
  if (ids !== 'current,key-wins,last,start') throw new Error(`Unexpected weekly meal IDs: ${ids}`);
  for (const name of ['water_logs', 'activity_logs']) {
    const q = query(collection(alice, `users/alice/${name}`),
      where('dateKey', '>=', '2026-10-12'), where('dateKey', '<', '2026-10-19'));
    const snapshot = await assertSucceeds(getDocs(q));
    if (snapshot.size !== 1 || snapshot.docs[0].id !== 'start') throw new Error('Range boundary failed');
  }
  const bob = verifiedContext('bob').firestore();
  const metrics = collection(alice, 'users/alice/body_metrics');
  const metricRange = await assertSucceeds(getDocs(query(metrics,
    where('measuredAt', '>=', start), where('measuredAt', '<', end))));
  if (metricRange.size !== 2) throw new Error('Weight range must exclude next week');
  const latest = await assertSucceeds(getDocs(query(metrics,
    where('measuredAt', '<', end), orderBy('measuredAt', 'desc'), limit(1))));
  if (latest.size !== 1 || latest.docs[0].id !== 'last') throw new Error('Latest weight must be limited to one record');
  await assertFails(getDocs(query(collection(bob, 'users/alice/body_metrics'),
    where('measuredAt', '>=', start), where('measuredAt', '<', end))));
  for (const name of ['meal_logs', 'water_logs', 'activity_logs']) {
    await assertFails(getDocs(query(collection(bob, `users/alice/${name}`),
      where('dateKey', '>=', '2026-10-12'), where('dateKey', '<', '2026-10-19'))));
  }
});

const targetData = (key = '2026-10-17') => ({
  effectiveFromDateKey: key, kcalTarget: 1800, proteinGTarget: null,
  carbsGTarget: null, fatGTarget: null, source: 'user_manual', schemaVersion: 1,
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
});
test('optional salt, total sugar and fiber targets are owner-only, bounded and nullable',async()=>{
  const a=verifiedContext('alice').firestore();
  const ref=doc(a,'users/alice/nutrition_targets/2026-10-17');
  await assertSucceeds(setDoc(ref,{...targetData(),saltGLimit:5,sugarGLimit:50,fiberGTarget:30}));
  await assertSucceeds(updateDoc(ref,{saltGLimit:0,sugarGLimit:null,fiberGTarget:null,updatedAt:serverTimestamp()}));
  for(const patch of [{saltGLimit:-1},{saltGLimit:51},{sugarGLimit:501},{fiberGTarget:201},{sugarGLimit:'50'},{fiberGTarget:NaN}]) {
    await assertFails(updateDoc(ref,{...patch,updatedAt:serverTimestamp()}));
  }
  const b=verifiedContext('bob').firestore();
  await assertFails(getDoc(doc(b,'users/alice/nutrition_targets/2026-10-17')));
  await assertFails(updateDoc(doc(b,'users/alice/nutrition_targets/2026-10-17'),{saltGLimit:4,updatedAt:serverTimestamp()}));
});

test('nutrition targets owner create/update/read/query use stable date ID and immutable createdAt', async () => {
  const db = verifiedContext('alice').firestore();
  const ref = doc(db, 'users/alice/nutrition_targets/2026-10-17');
  await assertSucceeds(setDoc(ref, targetData()));
  const createdAt = (await getDoc(ref)).data().createdAt;
  await assertSucceeds(updateDoc(ref, { kcalTarget: 1900, proteinGTarget: 0, carbsGTarget: 0, fatGTarget: 0, updatedAt: serverTimestamp() }));
  const found = await assertSucceeds(getDocs(query(collection(db, 'users/alice/nutrition_targets'),
    where('effectiveFromDateKey', '<=', '2026-10-18'), orderBy('effectiveFromDateKey','desc'), limit(1))));
  if (found.size !== 1 || found.docs[0].data().kcalTarget !== 1900 || !createdAt.isEqual(found.docs[0].data().createdAt)) throw new Error('Target update/readback mismatch');
  await assertFails(updateDoc(ref, { createdAt: Timestamp.fromMillis(1), updatedAt: serverTimestamp() }));
  await assertSucceeds(deleteDoc(ref));
});

test('nutrition targets reject guests and another UID on document and collection paths', async () => {
  const alice = verifiedContext('alice').firestore();
  await setDoc(doc(alice,'users/alice/nutrition_targets/2026-10-17'),targetData());
  for (const db of [verifiedContext('bob').firestore(), environment.unauthenticatedContext().firestore()]) {
    const ref = doc(db,'users/alice/nutrition_targets/2026-10-17');
    await assertFails(getDoc(ref));
    await assertFails(getDocs(collection(db,'users/alice/nutrition_targets')));
    await assertFails(getDocs(query(collection(db,'users/alice/nutrition_targets'),where('effectiveFromDateKey','<=','2026-10-18'),orderBy('effectiveFromDateKey','desc'),limit(1))));
    await assertFails(setDoc(ref,targetData()));
    await assertFails(updateDoc(ref,{kcalTarget:1900,updatedAt:serverTimestamp()}));
    await assertFails(deleteDoc(ref));
  }
});

test('nutrition targets reject bad schema, dates, ranges, partial macros and non-finite numbers', async () => {
  const db = verifiedContext('alice').firestore();
  const ref = doc(db,'users/alice/nutrition_targets/2026-10-17');
  for (const patch of [
    {kcalTarget:0}, {kcalTarget:-1}, {kcalTarget:20001}, {kcalTarget:NaN}, {kcalTarget:Infinity}, {kcalTarget:'1800'},
    {proteinGTarget:1}, {proteinGTarget:0,carbsGTarget:0,fatGTarget:-1},
    {proteinGTarget:5001,carbsGTarget:0,fatGTarget:0}, {proteinGTarget:NaN,carbsGTarget:0,fatGTarget:0},
    {proteinGTarget:0,carbsGTarget:Infinity,fatGTarget:0}, {proteinGTarget:0,carbsGTarget:0,fatGTarget:'0'},
    {effectiveFromDateKey:'2026-10-18'}, {source:'ai'}, {schemaVersion:2}, {secretExtra:'bad'},
    {createdAt:Timestamp.fromMillis(1)}, {updatedAt:Timestamp.fromMillis(1)},
  ]) await assertFails(setDoc(ref,{...targetData(),...patch}));
  for (const key of ['2026-02-30','2026-13-01','bad-date']) await assertFails(setDoc(doc(db,`users/alice/nutrition_targets/${key}`),targetData(key)));
  const missing = targetData(); delete missing.fatGTarget;
  await assertFails(setDoc(ref,missing));
});

test('nutrition target updates cannot smuggle invalid fields and upper technical bounds are accepted', async () => {
  const db = verifiedContext('alice').firestore();
  const ref = doc(db,'users/alice/nutrition_targets/2026-10-17');
  await assertSucceeds(setDoc(ref,{...targetData(),kcalTarget:20000,proteinGTarget:5000,carbsGTarget:5000,fatGTarget:5000}));
  for (const patch of [{kcalTarget:Infinity}, {effectiveFromDateKey:'2026-10-18'}, {fatGTarget:null}, {injected:true}]) {
    await assertFails(updateDoc(ref,{...patch,updatedAt:serverTimestamp()}));
  }
});

async function seedFavoriteCatalog() {
  await environment.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(),'food_catalog/c3-rice'),{name:'Cơm fixture'});
  });
}
const favoriteData = () => ({sourceKind:'catalog',sourceId:'c3-rice',createdAt:serverTimestamp(),updatedAt:serverTimestamp(),schemaVersion:1});

test('favorite catalog references support owner CRUD and stable ID with immutable timestamps',async()=>{
  await seedFavoriteCatalog();
  const db=verifiedContext('alice').firestore();
  const ref=doc(db,'users/alice/favorite_foods/catalog_c3-rice');
  await assertSucceeds(setDoc(ref,favoriteData()));
  const before=(await getDoc(ref)).data();
  await assertSucceeds(updateDoc(ref,{updatedAt:serverTimestamp()}));
  const page=await assertSucceeds(getDocs(query(collection(db,'users/alice/favorite_foods'),orderBy('createdAt','desc'),limit(40))));
  if(page.size!==1 || !page.docs[0].data().createdAt.isEqual(before.createdAt)) throw new Error('Favorite identity/timestamp changed');
  await assertFails(updateDoc(ref,{createdAt:Timestamp.fromMillis(1),updatedAt:serverTimestamp()}));
  await assertSucceeds(deleteDoc(ref));
});

test('favorites block unauthenticated and cross UID document/collection/query/write/delete access',async()=>{
  await seedFavoriteCatalog();
  const alice=verifiedContext('alice').firestore();
  await setDoc(doc(alice,'users/alice/favorite_foods/catalog_c3-rice'),favoriteData());
  for(const db of [verifiedContext('bob').firestore(),environment.unauthenticatedContext().firestore()]){
    const ref=doc(db,'users/alice/favorite_foods/catalog_c3-rice');
    await assertFails(getDoc(ref)); await assertFails(getDocs(collection(db,'users/alice/favorite_foods')));
    await assertFails(getDocs(query(collection(db,'users/alice/favorite_foods'),orderBy('createdAt','desc'),limit(40))));
    await assertFails(setDoc(ref,favoriteData())); await assertFails(updateDoc(ref,{updatedAt:serverTimestamp()})); await assertFails(deleteDoc(ref));
  }
});

test('favorites reject missing catalog, mismatched source identity and bad schema',async()=>{
  await seedFavoriteCatalog();
  const db=verifiedContext('alice').firestore();
  const ref=doc(db,'users/alice/favorite_foods/catalog_c3-rice');
  for(const patch of [{sourceKind:'custom'},{sourceKind:'recipe'},{sourceId:'bad/food'},{sourceId:''},{sourceId:'x'.repeat(101)},
    {schemaVersion:2},{createdAt:Timestamp.fromMillis(1)},{updatedAt:Timestamp.fromMillis(1)},{kcal:0}]){
    await assertFails(setDoc(ref,{...favoriteData(),...patch}));
  }
  const missing=favoriteData();delete missing.sourceId;await assertFails(setDoc(ref,missing));
  await assertFails(setDoc(doc(db,'users/alice/favorite_foods/wrong-id'),favoriteData()));
  await assertFails(setDoc(doc(db,'users/alice/favorite_foods/catalog_unknown'),{...favoriteData(),sourceId:'unknown'}));
});

test('favorites remain removable after catalog deletion without granting catalog writes',async()=>{
  await seedFavoriteCatalog();
  const db=verifiedContext('alice').firestore();
  const ref=doc(db,'users/alice/favorite_foods/catalog_c3-rice');
  await setDoc(ref,favoriteData());
  await assertFails(deleteDoc(doc(db,'food_catalog/c3-rice')));
  await environment.withSecurityRulesDisabled(context=>deleteDoc(doc(context.firestore(),'food_catalog/c3-rice')));
  await assertSucceeds(getDoc(ref));await assertSucceeds(deleteDoc(ref));
});

const personalFoodData = (patch={})=>({name:'Món cá nhân fixture',alternateNames:['món riêng','fixture','một','hai','ba'],servingBasis:'per_100g',kcalPer100g:130,proteinGPer100g:2.69,carbsGPer100g:28.17,fatGPer100g:.28,defaultServingGrams:150,servingLabel:'bát',servingGrams:150,sourceLabel:'Emulator fixture',isEstimated:true,schemaVersion:1,createdAt:serverTimestamp(),updatedAt:serverTimestamp(),...patch});
const recipeData = (patch={})=>({name:'Công thức fixture',ingredients:Array.from({length:6},()=>mealItem()),yieldGrams:600,servingsCount:2.5,sourceLabel:'Emulator fixture',isEstimated:true,schemaVersion:1,createdAt:serverTimestamp(),updatedAt:serverTimestamp(),...patch});
for(const [name,fixture] of [['custom_foods',personalFoodData],['recipes',recipeData]]) {
  test(`C4 ${name} owner CRUD maximum payload and immutable createdAt`,async()=>{
    const db=verifiedContext('alice').firestore(); const ref=doc(db,`users/alice/${name}/c4-test`);
    await assertSucceeds(setDoc(ref,fixture()));
    const first=await assertSucceeds(getDoc(ref));
    await assertSucceeds(getDocs(query(collection(db,`users/alice/${name}`),orderBy('createdAt','desc'),limit(40))));
    await assertSucceeds(updateDoc(ref,{name:'Đổi tên',updatedAt:serverTimestamp()}));
    if(!(await getDoc(ref)).data().createdAt.isEqual(first.data().createdAt)) throw Error('createdAt changed');
    await assertFails(updateDoc(ref,{createdAt:Timestamp.fromMillis(0),updatedAt:serverTimestamp()}));
    await assertFails(updateDoc(ref,{secret:true,updatedAt:serverTimestamp()}));
    await assertSucceeds(deleteDoc(ref));
  });
  test(`C4 ${name} blocks guests and UID B on document collection query and writes`,async()=>{
    const alice=verifiedContext('alice').firestore();await setDoc(doc(alice,`users/alice/${name}/c4-test`),fixture());
    for(const db of [environment.unauthenticatedContext().firestore(),verifiedContext('bob').firestore()]) {
      const ref=doc(db,`users/alice/${name}/c4-test`);
      await assertFails(getDoc(ref)); await assertFails(getDocs(collection(db,`users/alice/${name}`)));
      await assertFails(getDocs(query(collection(db,`users/alice/${name}`),orderBy('createdAt','desc'),limit(40))));
      await assertFails(setDoc(ref,fixture())); await assertFails(updateDoc(ref,{name:'B',updatedAt:serverTimestamp()}));await assertFails(deleteDoc(ref));
    }
  });
}
test('C4 personal food rejects missing nutrients malformed servings alias middle/end and non finite fields',async()=>{
  const db=verifiedContext('alice').firestore();const ref=doc(db,'users/alice/custom_foods/invalid');
  for(const patch of [{kcalPer100g:-1},{kcalPer100g:Infinity},{fatGPer100g:NaN},{carbsGPer100g:'0'},{proteinGPer100g:1001},{defaultServingGrams:0},{defaultServingGrams:2001},{servingGrams:null},{servingLabel:null},{servingGrams:-1},{servingLabel:'x'.repeat(41)},{alternateNames:['ok',5]},{alternateNames:['ok','ok','ok','ok',false]},{alternateNames:Array(6).fill('a')},{name:'x'},{schemaVersion:4}]) await assertFails(setDoc(ref,personalFoodData(patch)));
  const missing=personalFoodData();delete missing.fatGPer100g;await assertFails(setDoc(ref,missing));
  await assertSucceeds(setDoc(ref,personalFoodData({servingLabel:null,servingGrams:null,proteinGPer100g:0,carbsGPer100g:0,fatGPer100g:0})));
});
test('C4 recipes validate all six rows including middle and last without rule budget overflow',async()=>{
  const db=verifiedContext('alice').firestore();const ref=doc(db,'users/alice/recipes/maximum');
  await assertSucceeds(setDoc(ref,recipeData()));
  for(const index of [0,2,5]) {
    for(const patch of [{grams:0},{kcal:-1},{fatG:NaN},{carbsG:'1'},{foodId:'recipe:nested'},{name:5},{secret:'no'}]) {
      const items=Array.from({length:6},()=>mealItem());items[index]=mealItem(patch);await assertFails(setDoc(ref,recipeData({ingredients:items})));
    }
    const items=Array.from({length:6},()=>mealItem());delete items[index].proteinG;await assertFails(setDoc(ref,recipeData({ingredients:items})));
  }
});
test('C4 recipe bounds empty overflow zero yield missing count and invalid numeric inputs',async()=>{
  const db=verifiedContext('alice').firestore();const ref=doc(db,'users/alice/recipes/invalid');
  for(const patch of [{ingredients:[]},{ingredients:Array.from({length:7},()=>mealItem())},{yieldGrams:0},{yieldGrams:-1},{yieldGrams:Infinity},{yieldGrams:20001},{servingsCount:0},{servingsCount:NaN},{servingsCount:1001},{isEstimated:false},{schemaVersion:'1'},{name:''}]) await assertFails(setDoc(ref,recipeData(patch)));
  const missing=recipeData();delete missing.servingsCount;await assertFails(setDoc(ref,missing));
  await assertSucceeds(setDoc(ref,recipeData({servingsCount:null,yieldGrams:20000})));
});
test('C4 favorite custom and recipe require own source, stable namespace and remain removable after source deletion',async()=>{
  const alice=verifiedContext('alice').firestore();const bob=verifiedContext('bob').firestore();
  for(const [kind,col,fixture] of [['custom','custom_foods',personalFoodData],['recipe','recipes',recipeData]]) {
    const source=doc(alice,`users/alice/${col}/c4-source`);await setDoc(source,fixture());
    const data={sourceKind:kind,sourceId:'c4-source',createdAt:serverTimestamp(),updatedAt:serverTimestamp(),schemaVersion:1};
    const favorite=doc(alice,`users/alice/favorite_foods/${kind}_c4-source`);
    await assertSucceeds(setDoc(favorite,data));
    await assertFails(setDoc(doc(bob,`users/bob/favorite_foods/${kind}_c4-source`),data));
    await assertFails(setDoc(doc(alice,`users/alice/favorite_foods/catalog_c4-source`),data));
    await deleteDoc(source);await assertSucceeds(getDoc(favorite));await assertSucceeds(deleteDoc(favorite));
    await assertFails(setDoc(favorite,data));
  }
});

// Versioned twenty-question profile survey: private, bounded and backwards compatible.
const surveyData = () => ({version:1, formulaSex:null, pace:null, guidance:null,
  activity:null, exerciseDays:null, exerciseMinutes:null, exerciseType:null,
  diet:null, avoidFoods:null, produce:null, sweetDrinks:null, sleepHours:null,
  sleepSchedule:null, barrier:null, priority:null});

test('personalization round trip is owner-only, old profile updates preserve it, admin cannot read it', async () => {
  const db = verifiedContext('alice',{email:'alice@example.com'}).firestore();
  const ref = doc(db,'users/alice');
  await assertSucceeds(setDoc(ref,{...profileData(),personalization:{...surveyData(),
    formulaSex:'female',guidance:'preferNotSay',exerciseDays:0,avoidFoods:'Đậu phộng',sleepHours:7.5,priority:'sleep'}}));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(updateDoc(ref,{displayName:'Alice edited',updatedAt:serverTimestamp()}));
  const saved = await getDoc(ref);
  require('node:assert/strict').equal(saved.data().personalization.avoidFoods,'Đậu phộng');
  await assertFails(getDoc(doc(verifiedContext('bob',{email:'bob@example.com'}).firestore(),'users/alice')));
  await assertFails(updateDoc(doc(verifiedContext('bob').firestore(),'users/alice'),{personalization:surveyData()}));
  await assertFails(getDoc(doc(environment.unauthenticatedContext().firestore(),'users/alice')));
  await environment.withSecurityRulesDisabled(async c => setDoc(doc(c.firestore(),'admin_roles/admin'),{enabled:true}));
  await assertFails(getDoc(doc(verifiedContext('admin').firestore(),'users/alice')));
  await assertSucceeds(deleteDoc(ref));
});

test('existing profile can save and edit validated diet and avoidance answers', async () => {
  const db = verifiedContext('alice',{email:'alice@example.com'}).firestore();
  const ref = doc(db,'users/alice');
  await assertSucceeds(setDoc(ref,profileData()));
  await assertSucceeds(updateDoc(ref,{personalization:{...surveyData(),diet:'vegan',avoidFoods:'sữa; trứng'},updatedAt:serverTimestamp()}));
  await assertSucceeds(updateDoc(ref,{personalization:{...surveyData(),diet:'vegetarian',avoidFoods:'Đậu phộng'},updatedAt:serverTimestamp()}));
  require('node:assert/strict').equal((await getDoc(ref)).data().personalization.avoidFoods,'Đậu phộng');
  await assertFails(updateDoc(ref,{personalization:{...surveyData(),diet:'invalid'},updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(verifiedContext('bob',{email:'bob@example.com'}).firestore(),'users/alice'),{personalization:surveyData(),updatedAt:serverTimestamp()}));
});

test('survey rejects malformed, oversized, unknown and contradictory fields', async () => {
  const db = verifiedContext('alice',{email:'alice@example.com'}).firestore();
  const ref = doc(db,'users/alice');
  await assertSucceeds(setDoc(ref,profileData()));
  for (const change of [{version:2},{admin:true},{exerciseDays:8},{exerciseDays:'3'},
    {exerciseMinutes:-30},{formulaSex:'made-up'},{sleepHours:25},{sleepHours:-1},
    {sleepHours:NaN},{avoidFoods:'x'.repeat(201)},{guidance:true},
    {exerciseDays:0,exerciseMinutes:30},{diet:['vegan']}]) {
    await assertFails(updateDoc(ref,{personalization:{...surveyData(),...change},updatedAt:serverTimestamp()}));
  }
  await assertFails(updateDoc(ref,{personalization:{version:1},updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(ref,{personalization:null,updatedAt:serverTimestamp()}));
});

test('new muscle goal and legacy gain goal remain valid without rewriting existing records', async () => {
  const db = verifiedContext('alice',{email:'alice@example.com'}).firestore();
  const ref = doc(db,'users/alice');
  await assertSucceeds(setDoc(ref,{...profileData(),healthGoal:'gain_muscle',personalization:surveyData()}));
  await assertSucceeds(updateDoc(ref,{healthGoal:'gain_weight_or_muscle',targetWeightKg:75,updatedAt:serverTimestamp()}));
});
