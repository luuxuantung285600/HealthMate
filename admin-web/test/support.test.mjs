import test from 'node:test';
import assert from 'node:assert/strict';
import {filterSupport,supportText,supportId,validateSupportThread} from '../dist/support-model.mjs';
test('support filters Vietnamese text, status/type, excludes deleting and sorts latest first',()=>{
 const rows=[{id:'a',uid:'alice',title:'Góp ý nhật ký',type:'suggestion',status:'open',updatedAt:{toMillis:()=>2}},
 {id:'b',uid:'bob',title:'Báo lỗi',type:'bug',status:'resolved',updatedAt:{toMillis:()=>3}},
 {id:'c',uid:'alice',title:'Góp ý',deleting:true,updatedAt:{toMillis:()=>4}}];
 assert.deepEqual(filterSupport(rows).map(r=>r.id),['b','a']);
 assert.deepEqual(filterSupport(rows,{search:'gop y alice',status:'open',type:'suggestion'}).map(r=>r.id),['a']);
});
test('support validation rejects blank/oversized text, invalid paths, incomplete and misordered conversations',()=>{
 assert.equal(supportText('  phản hồi  '),'phản hồi');
 for(const text of ['  ','a'.repeat(2001)])assert.throws(()=>supportText(text));
 for(const id of ['a/b','short'])assert.throws(()=>supportId(id));
 assert.equal(supportId('AbCdEfGhIjKlMnOpQrSt'),'AbCdEfGhIjKlMnOpQrSt');
 const ticket={status:'open',type:'bug',messageCount:1},msg={sequence:1,role:'admin',text:'OK',createdAt:{toDate:()=>new Date()}};
 assert.equal(validateSupportThread(ticket,[msg]).messages.length,1);
 assert.throws(()=>validateSupportThread(ticket,[]));
 assert.throws(()=>validateSupportThread(ticket,[{...msg,sequence:2}]));
 assert.throws(()=>validateSupportThread({...ticket,deleting:true},[msg]));
});

test('support timestamp ties use nanoseconds and the same descending ID order as Firestore',()=>{
 const stamp=(nanoseconds)=>({seconds:1,nanoseconds,toMillis:()=>1000});
 const rows=[{id:'A',updatedAt:stamp(1)},{id:'a',updatedAt:stamp(1)},{id:'B',updatedAt:stamp(2)}];
 assert.deepEqual(filterSupport(rows).map(row=>row.id),['B','a','A']);
});
