import test from 'node:test';
import assert from 'node:assert/strict';
import {createAdminPageReader,collectRange,pageScope,pageConstraints} from '../dist/server-paging.mjs';
import {filterRows} from '../dist/list-model.mjs';

function fixture(count=10037){
  const records=Array.from({length:count},(_,i)=>({id:`user-${String(i).padStart(5,'0')}`,displayName:`Khách ${i}`}));
  const calls=[],enriched=[];
  const read=createAdminPageReader({
    async fetchDocuments(spec){calls.push(spec);return records.filter(row=>(!spec.cursor||row.id>spec.cursor.id)&&(!spec.idFrom||row.id>=spec.idFrom)&&(!spec.idTo||row.id<=spec.idTo)).slice(0,spec.pageSize);},
    async enrichAccount(id){enriched.push(id);return{adminRole:null,control:id.endsWith('2')?{status:'suspended'}:null};},
  });
  return{read,calls,enriched,records};
}

test('server lookup is scoped and validates explicit email, ID and food prefix modes',()=>{
  assert.equal(pageScope('user_directory',{lookupField:'email',lookupValue:'  Member@example.com  '}).lookupValue,'Member@example.com');
  for(const input of [{lookupField:'name',lookupValue:'x'},{lookupField:'email',lookupValue:'x'},{lookupField:'id',lookupValue:'a/b'},{lookupField:'id',lookupValue:'x',start:'2026-11-01',end:'2026-11-02'}])assert.throws(()=>pageScope('user_directory',input));
  assert.throws(()=>pageScope('food_catalog',{lookupField:'name',lookupValue:'x',idFrom:'a'}));
  assert.throws(()=>pageScope('food_catalog',{lookupField:'email',lookupValue:'a@b.com'}));
});

test('shared SDK constraints order audits by nanosecond time and food prefixes by name then ID',()=>{
  const sdk={where:(...x)=>['where',...x],orderBy:(...x)=>['order',...x],documentId:()=>'$id',startAfter:(...x)=>['after',...x],Timestamp:class{constructor(seconds,nanoseconds){Object.assign(this,{seconds,nanoseconds});}}};
  const audit=pageScope('admin_audit',{start:'2026-11-01',end:'2026-11-02'});
  const clauses=pageConstraints(audit,{seconds:5,nanoseconds:123,id:'z'},sdk);
  assert.equal(clauses[0][1],'at');assert.deepEqual(clauses.slice(2,4),[['order','at','desc'],['order','$id','desc']]);assert.equal(clauses.at(-1)[1].nanoseconds,123);
  const name=pageScope('food_catalog',{lookupField:'name',lookupValue:'Cơm'});
  assert.deepEqual(pageConstraints(name,{value:'Cơm tấm',id:'boundary'},sdk),[['where','name','>=','Cơm'],['where','name','<','Cơn'],['order','name'],['order','$id'],['after','Cơm tấm','boundary']]);
  const email=pageScope('user_directory',{lookupField:'email',lookupValue:'x@example.com'});
  assert.deepEqual(pageConstraints(email,null,sdk),[['where','email','==','x@example.com'],['order','$id']]);
});

test('name cursors keep the boundary value and cannot be reused for another search',async()=>{
  const read=createAdminPageReader({fetchDocuments:async()=>[{id:'z',name:'Cơm tấm'}],enrichAccount:async()=>({})});
  const options={lookupField:'name',lookupValue:'Cơm'},first=await read('food_catalog',options);
  assert.equal(first.cursor.value,'Cơm tấm');
  await assert.rejects(read('food_catalog',{...options,cursor:first.cursor,lookupValue:'Bún'}),/phạm vi/);
  await assert.rejects(read('food_catalog',{...options,cursor:{...first.cursor,value:undefined}}),/phạm vi/);
});

test('10,037 accounts: first page reads only25 directory+25 controls+25 roles; next page is bounded',async()=>{
  const f=fixture(),first=await f.read('user_directory');
  assert.equal(first.rows.length,25);assert.equal(f.calls.length,1);assert.equal(f.enriched.length,25);
  assert.equal(f.calls[0].pageSize,25);assert.equal(first.rows[24].id,'user-00024');
  const second=await f.read('user_directory',{cursor:first.cursor});
  assert.equal(second.rows[0].id,'user-00025');assert.equal(second.rows[24].id,'user-00049');
  assert.equal(f.enriched.length,50);assert.equal(new Set([...first.rows,...second.rows].map(r=>r.id)).size,50);
  assert.equal(filterRows(first.rows,'user_directory',{search:'Khách 10000'}).length,0,'filter never searches unseen rows');
});

test('cursor traverses >10k without loops, duplicates or dropped IDs in unchanged fixture',async()=>{
  const f=fixture(),seen=[];let cursor=null,more;
  do{const page=await f.read('food_catalog',{cursor});seen.push(...page.rows.map(r=>r.id));cursor=page.cursor;more=page.hasMore;}while(more);
  assert.deepEqual(seen,f.records.map(r=>r.id));assert.equal(new Set(seen).size,10037);
  assert.equal(f.calls.length,402);assert.equal(f.enriched.length,0);
});

test('cursor survives deleted boundary ID and rejects another kind or range',async()=>{
  const f=fixture(),page=await f.read('user_directory');
  f.records.splice(24,1);
  assert.equal((await f.read('user_directory',{cursor:page.cursor})).rows[0].id,'user-00025');
  await assert.rejects(f.read('food_catalog',{cursor:page.cursor}),/phạm vi/);
  await assert.rejects(f.read('user_directory',{cursor:page.cursor,idFrom:'user-00001'}),/phạm vi/);
});

test('exports require explicit range and return full range across pages, never display-page subset',async()=>{
  const f=fixture();
  await assert.rejects(collectRange(f.read,'user_directory'),/Chọn khoảng/);
  assert.equal(f.calls.length,0);
  const rows=await collectRange(f.read,'user_directory',{idFrom:'user-00100',idTo:'user-00350'});
  assert.equal(rows.length,251);assert.equal(rows[0].id,'user-00100');assert.equal(rows.at(-1).id,'user-00350');
  assert.equal(f.calls.length,2);assert.equal(f.enriched.length,251);
});

test('oversized export errors without delivering partial rows; limit remains5000',async()=>{
  const f=fixture();
  await assert.rejects(collectRange(f.read,'food_catalog',{idFrom:'user-00000',idTo:'user-10036'}),/vượt 5\.000/);
  assert.equal(f.calls.length,26);assert.equal(f.calls.reduce((sum,c)=>sum+c.pageSize,0),5200);
});

test('late page after logout/revoke is discarded before account enrichment',async()=>{
  let active=true,enriched=0;
  const read=createAdminPageReader({fetchDocuments:async()=>{active=false;return[{id:'private'}];},enrichAccount:async()=>{enriched++;return{};}});
  await assert.rejects(read('user_directory',{isCurrent:()=>active}),/kết thúc/);assert.equal(enriched,0);
});

test('revoke during export or account enrichment aborts, never returns sensitive results',async()=>{
  let active=true,calls=0;
  const read=createAdminPageReader({fetchDocuments:async()=>{calls++;return[{id:'private'}];},enrichAccount:async()=>{active=false;return{adminRole:{enabled:true}};}});
  await assert.rejects(collectRange(read,'user_directory',{idFrom:'a',idTo:'z',isCurrent:()=>active}),/kết thúc/);assert.equal(calls,1);
});

test('period scope uses exact Vietnam inclusive days and refuses invalid ranges',()=>{
  const scope=pageScope('demo_premium_transactions',{start:'2026-10-01',end:'2026-10-31'});
  assert.equal(new Date(scope.lower).toISOString(),'2026-09-30T17:00:00.000Z');
  assert.equal(new Date(scope.upper).toISOString(),'2026-10-31T17:00:00.000Z');
  assert.throws(()=>pageScope('user_directory',{start:'2026-10-01',end:'2026-10-31'}));
  assert.throws(()=>pageScope('demo_premium_transactions',{start:'2026-02-30',end:'2026-03-01'}));
  assert.throws(()=>pageScope('demo_premium_transactions',{start:'2025-01-01',end:'2026-10-31'}));
  assert.throws(()=>pageScope('demo_premium_transactions',{idFrom:'a',start:'2026-10-01',end:'2026-10-31'}));
});

test('revenue cursor preserves nanoseconds instead of rounding equal-millisecond receipts',async()=>{
  let received;
  const read=createAdminPageReader({fetchDocuments:async spec=>{received=spec.cursor;return spec.cursor?[]:[{id:'receipt',occurredAt:{seconds:1790816400,nanoseconds:987654321}}];}});
  const range={start:'2026-10-01',end:'2026-10-31'};
  const first=await read('demo_premium_transactions',range);
  await read('demo_premium_transactions',{...range,cursor:first.cursor});
  assert.equal(received.seconds,1790816400);assert.equal(received.nanoseconds,987654321);
});

test('support uses latest activity and exact timestamp/id cursors, including a deleted boundary',async()=>{
  const at={seconds:1790816400,nanoseconds:987654321};
  const rows=Array.from({length:51},(_,i)=>({id:String(100-i).padStart(20,'0'),updatedAt:at}));
  const read=createAdminPageReader({fetchDocuments:async spec=>{
    assert.equal(spec.timeField,'updatedAt');
    return rows.filter(row=>!spec.cursor||row.id<spec.cursor.id).slice(0,spec.pageSize);
  }});
  const first=await read('support_tickets');
  assert.equal(first.cursor.nanoseconds,987654321);
  rows.splice(24,1);
  const second=await read('support_tickets',{cursor:first.cursor});
  assert.equal(second.rows[0].id,rows[24].id);
  assert.equal(new Set([...first.rows,...second.rows].map(row=>row.id)).size,50);
  await assert.rejects(read('support_tickets',{cursor:{...first.cursor,seconds:undefined}}),/Con trỏ/);
  assert.throws(()=>pageScope('support_tickets',{idFrom:'a'}),/thời điểm/);
});
