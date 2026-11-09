const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {before,beforeEach,after,test}=require('node:test');
const {initializeTestEnvironment,assertFails,assertSucceeds}=require('@firebase/rules-unit-testing');
const {doc,collection,getDoc,getDocs,setDoc,updateDoc,deleteDoc,query,where,writeBatch,runTransaction,serverTimestamp,Timestamp}=require('firebase/firestore');
let env;
const id='AbCdEfGhIjKlMnOpQrSt',m1='ZbCdEfGhIjKlMnOpQrSt',m2='XbCdEfGhIjKlMnOpQrSt';
before(async()=>{const [host,port]=(process.env.FIRESTORE_EMULATOR_HOST||'127.0.0.1:8092').split(':');env=await initializeTestEnvironment({projectId:'demo-healthmate-support-rules',firestore:{host,port:Number(port),rules:fs.readFileSync(path.join(__dirname,'..','firestore.rules'),'utf8')}});});
beforeEach(async()=>{await env.clearFirestore();await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'admin_roles/admin'),{enabled:true}));});
after(async()=>env?.cleanup());
const db=uid=>env.authenticatedContext(uid,{email_verified:true}).firestore();
const ticket=d=>doc(d,'support_tickets',id);
const message=(d,msg=m1)=>doc(ticket(d),'messages',msg);
const payload=(uid='alice')=>({uid,type:'bug',title:'Không lưu được bữa ăn',description:'Đã chọn món nhưng bấm lưu báo lỗi.',status:'open',createdAt:serverTimestamp(),updatedAt:serverTimestamp(),messageCount:0,lastMessageId:'',updatedBy:uid,deleting:false});
const dayStart=()=>{const at=new Date(Date.now()+7*3600000);return Timestamp.fromMillis(Date.UTC(at.getUTCFullYear(),at.getUTCMonth(),at.getUTCDate())-7*3600000);};
const create=(d,patch={})=>{
 const batch=writeBatch(d);batch.set(ticket(d),{...payload(),...patch});
 batch.set(doc(d,'support_usage/alice'),{schemaVersion:1,dayStart:dayStart(),count:1,lastCreatedAt:serverTimestamp(),lastTicketId:id,updatedAt:serverTimestamp()});
 return batch.commit();
};
function reply(d,{uid='admin',role='admin',msg=m1,count=1,text='Đã tiếp nhận, bạn vui lòng thử lại.',patch={},parent={}}={}){
 const batch=writeBatch(d);batch.set(message(d,msg),{authorUid:uid,role,text,sequence:count,createdAt:serverTimestamp(),...patch});
 batch.update(ticket(d),{messageCount:count,lastMessageId:msg,updatedAt:serverTimestamp(),updatedBy:uid,...(role==='customer'?{status:'open'}:{}),...parent});return batch.commit();
}
test('only verified owner creates valid support ticket; no forged status, owner, extra data or blank text',async()=>{
 const a=db('alice');await assertSucceeds(getDoc(ticket(a)));
 for(const patch of [{uid:'bob'},{status:'resolved'},{messageCount:1},{deleting:true},{title:'   \n'},{description:'\t'},{title:'a'.repeat(121)},{description:'a'.repeat(2001)},{type:'medical'},{email:'private@example.com'}])await assertFails(create(a,patch));
 await assertFails(create(env.unauthenticatedContext().firestore()));
 await assertFails(create(env.authenticatedContext('alice',{email_verified:false}).firestore()));
 await assertSucceeds(create(a));
});
test('owner query reads only own tickets; other UID cannot read thread or list, admin cannot read health data',async()=>{
 await create(db('alice'));await reply(db('admin'));
 await assertSucceeds(getDocs(query(collection(db('alice'),'support_tickets'),where('uid','==','alice'))));
 await assertFails(getDocs(collection(db('alice'),'support_tickets')));
 await assertFails(getDoc(ticket(db('bob'))));await assertFails(getDocs(collection(ticket(db('bob')),'messages')));
 await assertSucceeds(getDocs(collection(db('admin'),'support_tickets')));
 await assertSucceeds(getDocs(collection(ticket(db('alice')),'messages')));
 await assertFails(getDoc(doc(db('admin'),'users/alice')));
});

for(const topic of ['account','premium','nutrition','activity','tracking','food_scanner','chatbot','other']) {
 test(`support accepts topic ${topic} and exposes it only to owner and admin`,async()=>{
  const a=db('alice');await assertSucceeds(create(a,{topic}));
  assert.equal((await getDoc(ticket(a))).data().topic,topic);
  assert.equal((await getDoc(ticket(db('admin')))).data().topic,topic);
  await assertFails(getDoc(ticket(db('bob'))));
 });
}
test('support rejects unknown, blank and non-string topics',async()=>{
 for(const topic of ['unknown','',null,42,{code:'nutrition'},['nutrition'],'__proto__'])await assertFails(create(db('alice'),{topic}));
 await assertSucceeds(create(db('alice'),{topic:'nutrition'}));
});
test('support topics are immutable for owner and admin; legacy threads still accept replies',async()=>{
 const a=db('alice'),admin=db('admin');await create(a);
 await assertFails(updateDoc(ticket(admin),{topic:'nutrition',updatedAt:serverTimestamp(),updatedBy:'admin'}));
 await assertSucceeds(reply(admin));
 await env.withSecurityRulesDisabled(c=>updateDoc(ticket(c.firestore()),{topic:'nutrition'}));
 for(const d of [a,admin])await assertFails(updateDoc(ticket(d),{topic:'account',updatedAt:serverTimestamp(),updatedBy:d===a?'alice':'admin'}));
 await assertSucceeds(updateDoc(ticket(admin),{status:'resolved',updatedAt:serverTimestamp(),updatedBy:'admin'}));
 await assertSucceeds(reply(a,{uid:'alice',role:'customer',msg:m2,count:2}));
 assert.equal((await getDoc(ticket(a))).data().topic,'nutrition');
});
test('admin replies atomically with immutable actor, role and sequence; customer cannot impersonate admin',async()=>{
 await create(db('alice'));
 await assertFails(reply(db('alice'),{uid:'alice',role:'admin'}));
 await assertFails(reply(db('bob'),{uid:'bob',role:'customer'}));
 await assertFails(reply(db('admin'),{uid:'alice'}));
 await assertFails(reply(db('admin'),{patch:{sequence:2}}));
 await assertFails(reply(db('admin'),{text:' '.repeat(3)}));
 await assertFails(setDoc(message(db('admin')),{authorUid:'admin',role:'admin',text:'orphan',sequence:1,createdAt:serverTimestamp()}));
 await assertSucceeds(reply(db('admin')));
 await assertFails(updateDoc(message(db('admin')),{text:'replace'}));
 await assertFails(deleteDoc(message(db('alice'))));
});
test('admin status changes leave original report immutable; customer follow-up reopens resolved request',async()=>{
 const a=db('alice'),admin=db('admin');await create(a);
 await assertFails(updateDoc(ticket(a),{status:'resolved',updatedAt:serverTimestamp(),updatedBy:'alice'}));
 await assertSucceeds(updateDoc(ticket(admin),{status:'in_progress',updatedAt:serverTimestamp(),updatedBy:'admin'}));
 await assertFails(updateDoc(ticket(admin),{title:'changed',updatedAt:serverTimestamp(),updatedBy:'admin'}));
 await assertSucceeds(reply(admin));
 await assertSucceeds(updateDoc(ticket(admin),{status:'resolved',updatedAt:serverTimestamp(),updatedBy:'admin'}));
 await assertSucceeds(reply(a,{uid:'alice',role:'customer',msg:m2,count:2,text:'Mình vẫn còn gặp lỗi.'}));
 assert.equal((await getDoc(ticket(a))).data().status,'open');
 await assertFails(reply(a,{uid:'alice',role:'customer',msg:'YbCdEfGhIjKlMnOpQrSt',count:3,parent:{status:'resolved'}}));
});
test('parent counters cannot reset or jump; maximum 100 messages is enforced',async()=>{
 const a=db('alice'),admin=db('admin');await create(a);await reply(admin);
 await assertFails(updateDoc(ticket(admin),{messageCount:0,updatedAt:serverTimestamp(),updatedBy:'admin'}));
 await assertFails(reply(admin,{msg:m2,count:3}));
 await env.withSecurityRulesDisabled(c=>updateDoc(ticket(c.firestore()),{messageCount:100}));
 await assertFails(reply(admin,{msg:m2,count:101}));
});
test('account deletion freezes thread, blocks concurrent replies and allows owner cascade cleanup only',async()=>{
 const a=db('alice'),admin=db('admin');await create(a);await reply(admin);
 await assertFails(deleteDoc(ticket(a)));await assertFails(updateDoc(ticket(admin),{deleting:true,updatedAt:serverTimestamp(),updatedBy:'admin'}));
 await assertSucceeds(updateDoc(ticket(a),{deleting:true,updatedAt:serverTimestamp(),updatedBy:'alice'}));
 await assertFails(reply(admin,{msg:m2,count:2}));
 await assertFails(updateDoc(ticket(a),{deleting:false,updatedAt:serverTimestamp(),updatedBy:'alice'}));
 await assertFails(deleteDoc(message(admin)));
 await assertSucceeds(deleteDoc(message(a)));await assertSucceeds(deleteDoc(ticket(a)));
});
test('simultaneous replies serialize through parent and cannot reuse sequence or message ID',async()=>{
 await create(db('alice'));
 const send=(uid,msg,role)=>{const d=db(uid);return runTransaction(d,async t=>{
  const parent=await t.get(ticket(d)),count=parent.data().messageCount+1;
  t.set(message(d,msg),{authorUid:uid,role,text:'Concurrent reply',sequence:count,createdAt:serverTimestamp()});
  t.update(ticket(d),{messageCount:count,lastMessageId:msg,updatedBy:uid,status:'open',updatedAt:serverTimestamp()});
 });};
 const attempts=[()=>send('alice',m1,'customer'),()=>send('admin',m2,'admin')];
 const results=await Promise.allSettled(attempts.map(run=>run()));
 assert.ok(results.some(r=>r.status==='fulfilled'),'At least one atomic reply must commit');
 // Rules may reject the losing write before the SDK sees an ABORTED conflict.
 // The product keeps the draft and ID; an explicit retry reads the new count.
 for(let i=0;i<results.length;i++)if(results[i].status==='rejected')await assertSucceeds(attempts[i]());
 const messages=await getDocs(collection(ticket(db('alice')),'messages'));
 assert.deepEqual(messages.docs.map(d=>d.data().sequence).sort(),[1,2]);
 await assertFails(reply(db('admin'),{msg:m1,count:3}));
});
