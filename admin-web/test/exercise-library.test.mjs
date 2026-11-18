import {test} from 'node:test';
import assert from 'node:assert/strict';
import {bundledExerciseLibrary} from '../dist/bundled-exercise-library.mjs';
import {exercisePayload,exerciseId,mergeExerciseLibrary,freshExerciseGif} from '../dist/exercise-library-model.mjs';
const item={id:'push_up',name:'Chống đẩy',sourceId:'Ab12345',region:'chest',equipment:'bodyweight',target:'Ngực',steps:['Đặt tay xuống sàn.','Hạ người có kiểm soát.'],easier:'Chống đẩy trên tường.',isActive:true,schemaVersion:1};
test('admin receives the same 60-entry catalog with 10 female illustration IDs',()=>{
 assert.equal(bundledExerciseLibrary.length,60);
 const expected=["Nh3mvOO", "Pjbc0Kt", "yT9tk17", "BCs0G2F", "r5DgrW9", "daBmy1Y", "BmrwWzo", "gFyFj9z", "wSScovH", "eOG0r6v"];
 const rows=bundledExerciseLibrary.filter(row=>row.name.includes('(mẫu nữ)'));
 assert.deepEqual(rows.map(row=>row.sourceId).sort(),expected.sort());
 for(const row of rows){assert.equal(exercisePayload(row).sourceId,row.sourceId);assert.equal(row.id,`edb-${row.sourceId}`);}
});
test('female illustrations support the existing audited admin edit/archive/restore payloads',()=>{
 const row=bundledExerciseLibrary.find(row=>row.sourceId==='Nh3mvOO');
 const archived=exercisePayload({...row,isActive:false});
 const merged=mergeExerciseLibrary(bundledExerciseLibrary,[{id:row.id,...archived}]);
 assert.equal(merged.length,60);assert.equal(merged.find(r=>r.id===row.id).isActive,false);
 const edited=exercisePayload({...row,name:'Kéo tạ đơn — đã sửa',isActive:true});
 const restored=mergeExerciseLibrary(bundledExerciseLibrary,[{id:row.id,...edited}]);
 assert.equal(restored.find(r=>r.id===row.id).name,'Kéo tạ đơn — đã sửa');
 assert.equal(restored.find(r=>r.id===row.id).sourceId,'Nh3mvOO');
});

test('ExerciseDB-only policy rejects other sources before network access',async()=>{
 let calls=0;const fetcher=async()=>{calls++;throw Error('unexpected metadata API call');};
 for(const sourceProvider of ['repdb','unknown',4]){
   await assert.rejects(freshExerciseGif('Nh3mvOO',{sourceProvider,fetcher}));
   assert.throws(()=>exercisePayload({...item,sourceProvider}));
   assert.throws(()=>mergeExerciseLibrary([item],[{...item,sourceProvider}]));
 }
 assert.equal(calls,0);
 assert.ok(bundledExerciseLibrary.every(row=>(row.sourceProvider??'exercisedb')==='exercisedb'));
 assert.equal(exercisePayload({...item,sourceProvider:'exercisedb'}).sourceProvider,'exercisedb');
});

test('exercise validation enforces schema, bounds and provider identifiers',()=>{
 assert.equal(exercisePayload(item).name,'Chống đẩy');assert.equal(exerciseId(item.id),item.id);
 for(const patch of [{sourceId:'https://bad'},{name:''},{name:'a'.repeat(121)},{steps:['a']},{steps:['a',4]},{steps:Array(7).fill('a')},{easier:''},{target:'a'.repeat(161)},{region:'medical'},{equipment:'other'},{isActive:'true'}])assert.throws(()=>exercisePayload({...item,...patch}));
 for(const id of ['a/b','','a'.repeat(101)])assert.throws(()=>exerciseId(id));
});
test('remote realtime snapshots merge add/edit/archive/restore without resurrecting bundled tombstones',()=>{
 const bundled=[item],custom={...item,id:'custom'};
 assert.equal(mergeExerciseLibrary(bundled,[]).length,1);
 assert.equal(mergeExerciseLibrary(bundled,[custom]).length,2);
 assert.equal(mergeExerciseLibrary(bundled,[{...item,name:'Tên mới'}])[0].name,'Tên mới');
 assert.equal(mergeExerciseLibrary(bundled,[{...item,isActive:false}])[0].isActive,false);
 assert.equal(mergeExerciseLibrary(bundled,[{...item,isActive:true}])[0].isActive,true);
 assert.throws(()=>mergeExerciseLibrary(bundled,[{...item,steps:[]}]));
});
test('GIF loads fresh only when requested; accepts HTTPS and rejects failures',async()=>{
 const calls=[];const fetcher=async(...args)=>{calls.push(args);return {ok:true,json:async()=>({success:true,data:{exerciseId:item.sourceId,gifUrl:`https://static.exercisedb.dev/media/${item.sourceId}.gif`}})}};
 assert.equal(await freshExerciseGif(item.sourceId,{fetcher}),`https://static.exercisedb.dev/media/${item.sourceId}.gif`);
 await freshExerciseGif(item.sourceId,{fetcher});assert.equal(calls.length,2);assert.equal(calls[0][1].cache,'no-store');
 await assert.rejects(freshExerciseGif(item.sourceId,{fetcher:async()=>({ok:false})}));
 await assert.rejects(freshExerciseGif(item.sourceId,{fetcher:async()=>({ok:true,json:async()=>({data:{gifUrl:'http://bad/a'}})})}));
});

test('GIF rejects forged hosts, mismatched IDs and non-success payloads',async()=>{
 for(const data of [{success:false,data:{exerciseId:item.sourceId,gifUrl:'https://static.exercisedb.dev/media/Ab12345.gif'}},{success:true,data:{exerciseId:'wrongID',gifUrl:'https://static.exercisedb.dev/media/Ab12345.gif'}},{success:true,data:{exerciseId:item.sourceId,gifUrl:'https://evil.example/a.gif'}},{success:true,data:{exerciseId:item.sourceId,gifUrl:'https://static.exercisedb.dev:443/media/Ab12345.gif#fragment'}}])await assert.rejects(freshExerciseGif(item.sourceId,{fetcher:async()=>({ok:true,json:async()=>data})}));
});

test('429 honors local backoff and does not automatically retry the provider',async()=>{
 let calls=0;const fetcher=async()=>{calls++;return {ok:false,status:429,headers:{get:()=> '60'}};};
 await assert.rejects(freshExerciseGif(item.sourceId,{fetcher}),/giới hạn/);
 await assert.rejects(freshExerciseGif(item.sourceId,{fetcher}),/giới hạn/);assert.equal(calls,1);
});
