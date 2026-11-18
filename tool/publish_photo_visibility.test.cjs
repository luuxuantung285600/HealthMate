'use strict';
const test=require('node:test'),assert=require('node:assert/strict');
const {wire}=require('./publish_verified_nutrients.cjs');
const {validCustomPhoto,validateRelease,planRelease,makeWrites,verifyRelease,prefix}=require('./publish_photo_visibility.cjs');
const actor='firebase-cli:'+'a'.repeat(24),version='photo-visibility-test-v1';
const doc=(id,data={})=>({name:`${prefix}/food_catalog/${id}`,fields:wire({name:id,isActive:true,nutrients:{kcal:123},...data}).mapValue.fields,createTime:'2026-01-01T00:00:00Z',updateTime:'2026-11-01T00:00:00Z'});
const release={version,excluded:[{id:'a',name:'a',reason:'no photo'}]};
const custom={mode:'custom',url:'https://example.com/p.webp',sourceUrl:'https://example.com/source',licenseUrl:'https://example.com/license',title:'A',author:'B',license:'CC0'};
test('custom photo requires public HTTPS and complete bounded metadata',()=>{
 assert.equal(validCustomPhoto(custom),true);
 for(const bad of [{...custom,url:'http://example.com/x'},{...custom,url:'https://user:pass@example.com/x'},{...custom,author:''},{...custom,mode:'hidden'},{...custom,title:'x'.repeat(201)}])assert.equal(validCustomPhoto(bad),false);
});
test('plan hides only explicit missing scope, preserving inactive/custom and renamed records',()=>{
 const r={...release,excluded:['a','b','c','d','e'].map(id=>({id,name:id,reason:'missing'}))};
 const p=planRelease(r,[doc('a'),doc('b',{isActive:false}),doc('c',{photo:custom}),doc('d',{name:'admin rename'}),doc('outside')]);
 assert.deepEqual(p.updates.map(x=>x.id),['a']);assert.deepEqual(p.skipped.map(x=>x.reason),['already-inactive','admin-custom-photo']);assert.deepEqual(p.conflicts.map(x=>x.reason),['renamed-record','missing-document']);
 assert.throws(()=>planRelease(release,[doc('a'),doc('a')]));
});
test('write masks, update precondition and create-only audit are exact',()=>{
 const p=planRelease(release,[doc('a')]),writes=makeWrites(p,actor,version);
 assert.equal(writes.length,2);assert.deepEqual(writes[0].updateMask.fieldPaths,['isActive','updatedBy','lastAdminOperationId']);assert.deepEqual(writes[0].currentDocument,{updateTime:doc('a').updateTime});assert.deepEqual(writes[1].currentDocument,{exists:false});assert.equal(writes[0].updateTransforms[0].setToServerValue,'REQUEST_TIME');
 assert.ok(writes.every(w=>!w.delete&&!w.update.name.includes('/users/')));assert.throws(()=>makeWrites(p,'bad',version));
});
test('verification allows intended fields only, preserves all other fields/documents',()=>{
 const before=[doc('a'),doc('outside')],p=planRelease(release,before),after=structuredClone(before);
 after[0].fields={...after[0].fields,...makeWrites(p,actor,version)[0].update.fields,updatedAt:{timestampValue:'2026-11-11T01:00:00Z'}};after[0].updateTime='2026-11-11T01:00:00Z';
 assert.deepEqual(verifyRelease(p,before,after,actor,version),{hidden:1,unchanged:1,total:2});
 const wrong=structuredClone(after);wrong[0].fields.nutrients=wire({kcal:0});assert.throws(()=>verifyRelease(p,before,wrong,actor,version));
 const unrelated=structuredClone(after);unrelated[1].fields.isActive={booleanValue:false};assert.throws(()=>verifyRelease(p,before,unrelated,actor,version));
 const stale=structuredClone(after);stale[0].fields.updatedAt={timestampValue:'2020-01-01T00:00:00Z'};assert.throws(()=>verifyRelease(p,before,stale,actor,version));
});
test('release validates exact 500 partition, identities and image hashes',()=>{
 const scope=Array.from({length:500},(_,i)=>({id:`f${i}`,name:`Food ${i}`}));const r={version,scopeIds:scope.map(x=>x.id),visibleIds:['f0'],excluded:scope.slice(1).map(x=>({...x,reason:'missing photo'}))};const photos=[{foodId:'f0',foodName:'Food 0',assetPath:'assets/food_photos/f0.webp',sha256:'a'.repeat(64)}];
 assert.equal(validateRelease(r,scope,photos),true);
 for(const bad of [{...r,visibleIds:['f0','f0']},{...r,scopeIds:r.scopeIds.slice(1)},{...r,excluded:r.excluded.slice(1)},{...r,excluded:[{...r.excluded[0],name:'wrong'},...r.excluded.slice(1)]}])assert.throws(()=>validateRelease(bad,scope,photos));
 assert.throws(()=>validateRelease(r,scope,[{...photos[0],assetPath:'../outside.webp'}]));assert.throws(()=>validateRelease(r,scope,[{...photos[0],sha256:'bad'}]));
});
test('legacy absent active flag counts active while null/string are conflicts',()=>{
 const legacy=doc('a');delete legacy.fields.isActive;
 const p=planRelease(release,[legacy]);assert.equal(p.updates.length,1);
 for(const isActive of [null,'true',0])assert.equal(planRelease(release,[doc('a',{isActive})]).conflicts[0].reason,'invalid-active-state');
 const after=structuredClone(legacy);after.fields={...after.fields,...makeWrites(p,actor,version)[0].update.fields,updatedAt:{timestampValue:'2026-11-11T01:00:00Z'}};after.updateTime='2026-11-11T01:00:00Z';
 assert.equal(verifyRelease(p,[legacy],[after],actor,version).hidden,1);assert.deepEqual(after.fields.nutrients,legacy.fields.nutrients);
});
test('custom metadata accepts surrounding whitespace after trimming but bounds raw length',()=>{
 assert.equal(validCustomPhoto(Object.fromEntries(Object.entries(custom).map(([k,v])=>[k,k==='mode'?v:'  '+v+'  ']))),true);
 assert.equal(validCustomPhoto({...custom,url:'https://exa mple.com/x'}),false);
 assert.equal(validCustomPhoto({...custom,author:' '+ 'x'.repeat(120)}),false);
});
