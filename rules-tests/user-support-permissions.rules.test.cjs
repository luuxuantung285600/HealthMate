// Current Flutter support contract: isolated emulator only, never production.
// HEALTHMATE_RULES_FILE may point at a read-only production backup to reproduce
// compatibility failures using exactly the same client permission assertions.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {before, beforeEach, after, test} = require('node:test');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, collection, getDoc, getDocs, query, where, setDoc, updateDoc, writeBatch, runTransaction, serverTimestamp, Timestamp} = require('firebase/firestore');
const root = path.join(__dirname, '..');
const rulesFile = process.env.HEALTHMATE_RULES_FILE ? path.resolve(root, process.env.HEALTHMATE_RULES_FILE) : path.join(root, 'firestore.rules');
const topics = ['account','premium','nutrition','activity','tracking','food_scanner','chatbot','other'];
const ticketId = 'AbCdEfGhIjKlMnOpQrSt';
const secondId = 'BbCdEfGhIjKlMnOpQrSt';
let env;
const client = (uid = 'alice', verified = true) => env.authenticatedContext(uid, {email_verified:verified}).firestore();
const dayStart = () => {
  const local = new Date(Date.now() + 7*3600000);
  return Timestamp.fromMillis(Date.UTC(local.getUTCFullYear(),local.getUTCMonth(),local.getUTCDate()) - 7*3600000);
};
const ticket = (uid = 'alice', patch = {}) => ({uid,type:'bug',topic:'nutrition',title:'Fixture report',description:'Synthetic compatibility fixture only.',
  status:'open',createdAt:serverTimestamp(),updatedAt:serverTimestamp(),messageCount:0,lastMessageId:'',updatedBy:uid,deleting:false,...patch});
const usage = (id = ticketId, count = 1, patch = {}) => ({schemaVersion:1,dayStart:dayStart(),count,lastCreatedAt:serverTimestamp(),lastTicketId:id,updatedAt:serverTimestamp(),...patch});
function create(db, {uid='alice',id=ticketId,count=1,ticketPatch={},usagePatch={}} = {}) {
  const batch = writeBatch(db);
  batch.set(doc(db,'support_tickets',id),ticket(uid,ticketPatch));
  batch.set(doc(db,'support_usage',uid),usage(id,count,usagePatch));
  return batch.commit();
}
async function seedUsage(patch = {}) {
  const past = Timestamp.fromMillis(Date.now()-120000);
  await env.withSecurityRulesDisabled(ctx => setDoc(doc(ctx.firestore(),'support_usage/alice'), usage(ticketId,1,{lastCreatedAt:past,updatedAt:past,...patch})));
}
function reply(db, {uid='alice',role='customer',id=ticketId,messageId='CbCdEfGhIjKlMnOpQrSt',sequence=1,parentPatch={},messagePatch={}} = {}) {
  const batch=writeBatch(db);
  batch.set(doc(db,'support_tickets',id,'messages',messageId),{authorUid:uid,role,text:'Synthetic follow-up',sequence,createdAt:serverTimestamp(),...messagePatch});
  batch.update(doc(db,'support_tickets',id),{status:'open',messageCount:sequence,lastMessageId:messageId,updatedBy:uid,updatedAt:serverTimestamp(),...parentPatch});
  return batch.commit();
}
before(async()=>{
  const [host,port]=(process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8092').split(':');
  if (!['127.0.0.1','localhost','::1'].includes(host)) throw Error('Support permissions audit requires a local emulator.');
  console.log('Support permissions rules:',path.relative(root,rulesFile));
  env=await initializeTestEnvironment({projectId:'demo-healthmate-user-support-audit',firestore:{host,port:Number(port),rules:fs.readFileSync(rulesFile,'utf8')}});
});
beforeEach(async()=>{
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(ctx=>setDoc(doc(ctx.firestore(),'admin_roles/admin'),{enabled:true}));
});
after(()=>env?.cleanup());

for (const type of ['bug','suggestion']) for (const topic of topics) {
  test(`ordinary verified free user creates ${type}/${topic} with atomic allowance`,async()=>{
    const db=client(); // No premium entitlement, role or profile is seeded.
    await assertSucceeds(create(db,{ticketPatch:{type,topic}}));
    assert.equal((await getDoc(doc(db,'support_tickets',ticketId))).data().topic,topic);
    assert.equal((await getDoc(doc(db,'support_usage/alice'))).data().count,1);
  });
}

test('topic list matches all current Flutter topic codes',()=>{
  const source=fs.readFileSync(path.join(root,'lib/features/support/models/support_models.dart'),'utf8');
  const section=source.split('enum SupportTopic {')[1].split('const SupportTopic')[0];
  assert.deepEqual([...section.matchAll(/^  \w+\('([^']+)'/gm)].map(m=>m[1]),topics);
});

test('current repository transaction may read missing own ticket and quota before create',async()=>{
  const db=client();
  await assertSucceeds(runTransaction(db,async tx=>{
    const ref=doc(db,'support_tickets',ticketId),allowance=doc(db,'support_usage/alice');
    assert.equal((await tx.get(ref)).exists(),false);
    assert.equal((await tx.get(allowance)).exists(),false);
    tx.set(allowance,usage());tx.set(ref,ticket());
  }));
});

test('ticket and quota must be atomic and bound to same owned new ticket',async()=>{
  const db=client();
  await assertFails(setDoc(doc(db,'support_tickets',ticketId),ticket()));
  await assertFails(setDoc(doc(db,'support_usage/alice'),usage()));
  await assertFails(create(db,{usagePatch:{lastTicketId:secondId}}));
  await assertSucceeds(create(db));
  await assertFails(create(db,{id:secondId,count:2})); // Server cooldown.
  assert.equal((await getDoc(doc(db,'support_usage/alice'))).data().count,1);
});

test('daily allowance permits valid increment but blocks reset overflow and forged day',async()=>{
  const db=client();await seedUsage({count:2});
  await assertSucceeds(create(db,{count:3}));
  await seedUsage({count:3});
  await assertFails(create(db,{id:secondId,count:4}));
  await assertFails(create(db,{id:secondId,count:1}));
  await assertFails(create(db,{id:secondId,count:1,usagePatch:{dayStart:Timestamp.fromMillis(dayStart().toMillis()+86400000)}}));
});

test('legacy no-topic ticket remains readable and supports owner/admin replies at exhausted quota',async()=>{
  const past=Timestamp.fromMillis(Date.now()-120000);
  await env.withSecurityRulesDisabled(async ctx=>{
    const payload=ticket('alice',{createdAt:past,updatedAt:past});delete payload.topic;
    await setDoc(doc(ctx.firestore(),'support_tickets',ticketId),payload);
  });
  await seedUsage({count:3});
  const owner=client(),admin=client('admin');
  await assertSucceeds(getDoc(doc(owner,'support_tickets',ticketId)));
  await assertSucceeds(reply(owner));
  await assertSucceeds(reply(admin,{uid:'admin',role:'admin',messageId:'DbCdEfGhIjKlMnOpQrSt',sequence:2}));
  assert.equal((await getDoc(doc(owner,'support_usage/alice'))).data().count,3);
  assert.equal('topic' in (await getDoc(doc(owner,'support_tickets',ticketId))).data(),false);
});

test('owner and admin can read while another user cannot read list or reply',async()=>{
  const owner=client(),other=client('bob'),admin=client('admin');
  await create(owner);
  for (const db of [owner,admin]) {
    await assertSucceeds(getDoc(doc(db,'support_tickets',ticketId)));
    await assertSucceeds(getDocs(query(collection(db,'support_tickets'),where('uid','==','alice'))));
  }
  await assertFails(getDoc(doc(other,'support_tickets',ticketId)));
  await assertFails(getDocs(query(collection(other,'support_tickets'),where('uid','==','alice'))));
  await assertFails(reply(other,{uid:'bob'}));
  await assertFails(reply(owner,{role:'admin'}));
  await assertFails(reply(admin,{uid:'alice',role:'admin'}));
  await assertSucceeds(reply(admin,{uid:'admin',role:'admin'}));
  await assertSucceeds(getDocs(collection(owner,'support_tickets',ticketId,'messages')));
  await assertFails(getDocs(collection(other,'support_tickets',ticketId,'messages')));
});

test('spoofed topic type UID and privilege fields cannot cross support boundary',async()=>{
  const db=client();
  for (const topic of ['invalid','__proto__',null,123,['nutrition']]) await assertFails(create(db,{ticketPatch:{topic}}));
  await assertFails(create(db,{ticketPatch:{type:'feedback'}})); // Flutter uses suggestion, not feedback.
  await assertFails(create(db,{uid:'bob'}));
  await assertFails(create(db,{ticketPatch:{uid:'bob'}}));
  await assertFails(create(db,{ticketPatch:{role:'admin'}}));
  await assertSucceeds(create(db));
  for (const actor of [db,client('admin')]) await assertFails(updateDoc(doc(actor,'support_tickets',ticketId),{topic:'account',updatedAt:serverTimestamp(),updatedBy:actor===db?'alice':'admin'}));
});

test('guest unverified suspended and deleting users cannot create support tickets',async()=>{
  await assertFails(create(env.unauthenticatedContext().firestore()));
  await assertFails(create(client('alice',false)));
  await env.withSecurityRulesDisabled(ctx=>setDoc(doc(ctx.firestore(),'account_controls/alice'),{status:'suspended'}));
  await assertFails(create(client()));
  await env.withSecurityRulesDisabled(async ctx=>{
    await setDoc(doc(ctx.firestore(),'account_controls/alice'),{status:'active'});
    await setDoc(doc(ctx.firestore(),'account_deletions/alice'),{uid:'alice'});
  });
  await assertFails(create(client()));
});
