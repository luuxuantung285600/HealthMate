import test from 'node:test';
import assert from 'node:assert/strict';
import {parseHTML} from 'linkedom';
import {createExerciseDbClient,readExerciseDbEntry,exerciseDbDraft,exerciseDbSearchTerm} from '../dist/exercisedb-browser-model.mjs';
import {exerciseDbBrowser} from '../dist/exercisedb-browser.mjs';

const source=(id='Ab12345',patch={})=>({exerciseId:id,name:'barbell bench press',gifUrl:`https://static.exercisedb.dev/media/${id}.gif`,bodyParts:['chest'],equipments:['barbell'],targetMuscles:['pectorals'],instructions:['Step:1 Lie on the bench.','Step:2 Press with control.'],...patch});
const response=(data,meta={total:1,hasNextPage:false})=>({success:true,data,meta});
const ok=data=>({ok:true,json:async()=>data});
const tick=async()=>{for(let i=0;i<4;i++)await new Promise(r=>setImmediate(r));};

test('source client searches the full hosted catalog with combined filters and real cursor pagination',async()=>{
 const calls=[],client=createExerciseDbClient({fetcher:async(url,options)=>{calls.push({url:new URL(url),options});return ok(response([source('Cd23456')],{total:1500,hasNextPage:true,nextCursor:'Cd23456'}));}});
 const result=await client.page({query:'chống đẩy',bodyPart:'chest',equipment:'bodyweight',after:'Ab12345'});
 assert.equal(result.total,1500);assert.equal(result.next,'Cd23456');assert.equal(result.rows[0].sourceId,'Cd23456');assert.equal(result.rows[0].gifUrl,undefined);
 assert.deepEqual(Object.fromEntries(calls[0].url.searchParams),{limit:'25',name:'push up',bodyParts:'chest',equipments:'bodyweight',after:'Ab12345'});
 assert.equal(calls[0].url.origin,'https://oss.exercisedb.dev');assert.equal(calls[0].options.cache,'no-store');assert.equal(calls[0].options.credentials,'omit');
 assert.equal(exerciseDbSearchTerm('Squat'),'Squat');assert.throws(()=>exerciseDbSearchTerm('a'.repeat(121)));
});

test('facets expose all provider groups/equipment rather than only the bundled 60 exercises',async()=>{
 const client=createExerciseDbClient({fetcher:async url=>ok(response(String(url).endsWith('bodyparts')?[{name:'neck'},{name:'waist'}]:[{name:'towel'},{name:'barbell'}]))});
 assert.deepEqual(await client.facets(),{bodyParts:['neck','waist'],equipments:['towel','barbell']});
});

test('source rejects forged GIFs, malformed rows, oversized pages and invalid or repeating cursors',async()=>{
 for(const patch of [{exerciseId:'bad/url'},{gifUrl:'https://evil.example/a.gif'},{name:''},{instructions:['',4]},{bodyParts:'chest'}])assert.throws(()=>readExerciseDbEntry(source('Ab12345',patch)));
 for(const payload of [response(Array(26).fill(source())),response([source(),source()]),response([source()],{total:0,hasNextPage:false}),response([source()],{total:9,hasNextPage:true,nextCursor:'wrong'}),response([source()],{total:9,hasNextPage:true,nextCursor:'Cd23456'}),{success:false,data:[]}]) {
  const client=createExerciseDbClient({fetcher:async()=>ok(payload)});await assert.rejects(client.page());
 }
 const repeating=createExerciseDbClient({fetcher:async()=>ok(response([source()],{total:9,hasNextPage:true,nextCursor:'Ab12345'}))});
 await assert.rejects(repeating.page({after:'Ab12345'}));
});

test('rate limit honors retry-after and failed requests never silently show a cached catalog',async()=>{
 let time=0,calls=0;
 const client=createExerciseDbClient({now:()=>time,fetcher:async()=>{calls++;return calls===1?{ok:false,status:429,headers:{get:()=> '60'}}:ok(response([source()]));}});
 await assert.rejects(client.page(),/giới hạn/);await assert.rejects(client.page(),/giới hạn/);assert.equal(calls,1);
 time=61000;assert.equal((await client.page()).rows.length,1);assert.equal(calls,2);
 const failed=createExerciseDbClient({fetcher:async()=>{throw new TypeError('Failed to fetch');}});await assert.rejects(failed.page(),/Không kết nối/);
});

test('abort and timeout cancel requests; late responses cannot become visible results',async()=>{
 let release;
 const controller=new AbortController(),client=createExerciseDbClient({fetcher:()=>new Promise(resolve=>release=resolve)});
 const pending=client.page({signal:controller.signal});controller.abort();release(ok(response([source()])));
 await assert.rejects(pending,{name:'AbortError'});
 const timeout=createExerciseDbClient({timeoutMs:5,fetcher:(_url,{signal})=>new Promise((_resolve,reject)=>signal.addEventListener('abort',()=>reject(new DOMException('aborted','AbortError'))))});
 await assert.rejects(timeout.page(),/quá lâu/);
});

test('draft uses stable identity and known HealthMate classifications without persisting source media or instructions',()=>{
 const draft=exerciseDbDraft(readExerciseDbEntry(source()));
 assert.equal(draft.id,'edb-Ab12345');assert.equal(draft.sourceId,'Ab12345');assert.equal(draft.region,'chest');assert.equal(draft.equipment,'barbell');assert.equal(draft.target,'Cơ ngực');assert.equal(draft.name,'');assert.deepEqual(draft.steps,[]);assert.equal(draft.easier,'');assert.equal(draft.gifUrl,undefined);assert.equal(draft.instructions,undefined);
 const unknown=exerciseDbDraft(readExerciseDbEntry(source('Cd23456',{bodyParts:['neck'],equipments:['towel'],targetMuscles:['unknown muscle']})));
 assert.equal(unknown.region,'');assert.equal(unknown.equipment,'');assert.equal(unknown.target,'');
});

function setup({client,mediaEnabled=false,existing=()=>[],onSelect=()=>{}}={}) {
 const {document,window}=parseHTML('<html><body><dialog open></dialog></body></html>');
 Object.defineProperty(window.HTMLSelectElement.prototype,'value',{configurable:true,get(){return this.querySelector('option[selected]')?.value??this.querySelector('option')?.value??'';},set(value){for(const option of this.querySelectorAll('option'))option.toggleAttribute('selected',option.value===String(value));}});
 const h=(tag,props={},...children)=>{
  const node=document.createElement(tag);
  for(const [key,value] of Object.entries(props)){if(key.startsWith('on'))node.addEventListener(key.slice(2).toLowerCase(),value);else if(typeof value==='boolean'){if(value)node.setAttribute(key,'');}else node.setAttribute(key,String(value));}
  node.append(...children.filter(c=>c!=null));return node;
 };
 const button=(label,action)=>h('button',{type:'button',onClick:action},label);
 let active=true;
 const browser=exerciseDbBrowser({h,button,client,mediaEnabled,existing,onSelect,isCurrent:()=>active});document.querySelector('dialog').append(browser.element);browser.start();
 const find=label=>[...document.querySelectorAll('button')].find(b=>b.textContent===label);
 return {document,window,browser,find,leave(){active=false;browser.dispose();},change(label,value){const el=document.querySelector(`[aria-label="${label}"]`);el.value=value;el.dispatchEvent(new window.Event('change'));}};
}
const facets=async()=>({bodyParts:['chest','waist'],equipments:['barbell','bodyweight']});

test('browser refetches the selected page and resets pagination when combined filters change',async()=>{
 const calls=[],client={facets,page:async params=>{calls.push(params);return{rows:[readExerciseDbEntry(source(params.after?'Cd23456':'Ab12345'))],total:1500,next:params.after?null:'Ab12345'};}};
 const t=setup({client});
 try {
  await tick();assert.match(t.browser.element.textContent,/1.500 bài phù hợp/);t.find('Trang sau').click();await tick();assert.equal(calls[1].after,'Ab12345');
  t.change('Nhóm cơ ExerciseDB','chest');await tick();assert.equal(calls.at(-1).after,'');assert.equal(calls.at(-1).bodyPart,'chest');assert.equal(t.find('Trang trước').disabled,true);
  t.change('Dụng cụ ExerciseDB','barbell');await tick();assert.equal(calls.at(-1).bodyPart,'chest');assert.equal(calls.at(-1).equipment,'barbell');
  t.find('Trang sau').click();await tick();t.find('Trang trước').click();await tick();assert.equal(calls.at(-1).after,'');
 } finally {t.leave();}
});

test('detail shows complete original guidance, source selection and existing archived identity',async()=>{
 const picked=[],row=readExerciseDbEntry(source()),t=setup({client:{facets,page:async()=>({rows:[row],total:1,next:null})},existing:()=>[{id:'custom-old-id',sourceId:row.sourceId,name:'Tên đã biên tập',isActive:false}],onSelect:row=>picked.push(row)});
 try {
  await tick();assert.match(t.browser.element.textContent,/Đã có · đang ẩn/);t.find('Xem GIF và hướng dẫn').click();
  assert.equal(t.document.querySelectorAll('.exercise-source-detail li').length,2);assert.match(t.document.querySelector('.exercise-source-detail').textContent,/Tên đã biên tập/);
  t.find('Mở bài đã có trong HealthMate').click();assert.equal(picked.length,1);assert.equal(picked[0].sourceId,'Ab12345');assert.equal(t.browser.element.querySelector('img'),null);
 } finally {t.leave();}
});

test('a failed catalog and failed facets have independent retries; source text is rendered as text',async()=>{
 let failed=true,facetsFailed=true;
 const t=setup({client:{facets:async()=>{if(facetsFailed)throw Error('offline');return facets();},page:async()=>{if(failed)throw Error('offline');return{rows:[readExerciseDbEntry(source('Ab12345',{name:'<img src=x onerror=alert(1)>'}))],total:1,next:null};}}});
 try {
  await tick();assert.ok(t.find('Thử tải lại kho'));assert.ok(t.find('Thử tải lại bộ lọc'));
  failed=false;t.find('Thử tải lại kho').click();await tick();assert.ok(t.find('Xem GIF và hướng dẫn'));assert.equal(t.document.querySelector('.exercise-source-results img'),null);
  facetsFailed=false;t.find('Thử tải lại bộ lọc').click();await tick();assert.equal(t.find('Thử tải lại bộ lọc'),undefined);
 } finally{t.leave();}
});

test('filter changes abort stale work and closing the picker cancels all pending requests',async()=>{
 const calls=[],t=setup({client:{facets,page:params=>new Promise(resolve=>calls.push({params,resolve}))}});
 try {
  await tick();t.change('Nhóm cơ ExerciseDB','chest');await tick();assert.equal(calls[0].params.signal.aborted,true);
  calls[1].resolve({rows:[readExerciseDbEntry(source('Cd23456',{name:'current result'}))],total:1,next:null});await tick();
  calls[0].resolve({rows:[readExerciseDbEntry(source('Ab12345',{name:'stale result'}))],total:1,next:null});await tick();
  assert.match(t.browser.element.textContent,/current result/);assert.doesNotMatch(t.browser.element.textContent,/stale result/);
  t.change('Nhóm cơ ExerciseDB','waist');await tick();t.document.querySelector('dialog').dispatchEvent(new t.window.Event('close'));assert.equal(calls[2].params.signal.aborted,true);
  calls[2].resolve({rows:[readExerciseDbEntry(source())],total:1,next:null});await tick();assert.equal(t.browser.element.querySelectorAll('.exercise-source-row').length,0);
 } finally{t.leave();}
});

test('new source selection waits for a successful GIF; broken image can retry and disposal drops playback',async()=>{
 const original=globalThis.fetch;
 globalThis.fetch=async()=>ok({success:true,data:{exerciseId:'Ab12345',gifUrl:'https://static.exercisedb.dev/media/Ab12345.gif'}});
 const picked=[],t=setup({mediaEnabled:true,client:{facets,page:async()=>({rows:[readExerciseDbEntry(source())],total:1,next:null})},onSelect:row=>picked.push(row)});
 try {
  await tick();t.find('Xem GIF và hướng dẫn').click();await tick();assert.equal(t.find('Thêm vào HealthMate').disabled,true);
  t.document.querySelector('img').dispatchEvent(new t.window.Event('error'));assert.ok(t.find('Thử lại GIF'));assert.equal(t.find('Thêm vào HealthMate').disabled,true);
  t.find('Thử lại GIF').click();await tick();t.document.querySelector('img').dispatchEvent(new t.window.Event('load'));assert.equal(t.find('Thêm vào HealthMate').disabled,false);
  t.find('Thêm vào HealthMate').click();assert.equal(picked.length,1);assert.equal(t.document.querySelector('img'),null);
 } finally{t.leave();globalThis.fetch=original;}
});
