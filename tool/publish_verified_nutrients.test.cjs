'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {planRelease,makeWrites,verifyRelease,foods,project,version,wire}=require('./publish_verified_nutrients.cjs');
const prefix=`projects/${project}/databases/(default)/documents`;
const actor='firebase-cli:'+'a'.repeat(24);
const source=foods();
function fixture(food=source[0]) {
  const {id,...data}=structuredClone(food);
  delete data.extraNutrientsPer100g;
  delete data.sourceDetails.additionalNutrientEvidence;
  if(data.sourceDetails.nutrientsPerPackage) {
    delete data.sourceDetails.nutrientsPerPackage.sodiumMg;
    delete data.sourceDetails.nutrientsPerPackage.sugarG;
  }
  data.isActive=false;data.photo={mode:'hidden'};data.updatedAt=null;
  return {name:`${prefix}/food_catalog/${id}`,fields:wire(data).mapValue.fields,updateTime:'2026-11-10T00:00:00.000001Z'};
}
function applied(doc,plan) {
  const result=structuredClone(doc),write=makeWrites(plan,actor)[0];
  for(const fieldPath of write.updateMask.fieldPaths){
    const keys=fieldPath.split('.');let from=write.update.fields,to=result.fields;
    for(const key of keys.slice(0,-1)){from=from[key].mapValue.fields;to=(to[key]??={mapValue:{fields:{}}}).mapValue.fields;}
    to[keys.at(-1)]=structuredClone(from[keys.at(-1)]);
  }
  result.fields.updatedAt={timestampValue:'2026-11-10T01:00:00Z'};
  result.updateTime='2026-11-10T01:00:00Z';return result;
}

test('exact release contains 110 sourced foods and nested masked changes with audit',()=>{
  assert.equal(source.length,110);
  const docs=source.map(fixture),plan=planRelease(source,docs),writes=makeWrites(plan,actor);
  assert.equal(plan.updates.length,110);assert.deepEqual(plan.conflicts,[]);assert.equal(writes.length,220);
  for(let i=0;i<writes.length;i+=2){
    const write=writes[i],audit=writes[i+1];
    assert.ok(write.currentDocument.updateTime);assert.deepEqual(audit.currentDocument,{exists:false});
    assert.match(write.update.name,/\/food_catalog\//);assert.match(audit.update.name,/\/admin_audit\//);
    assert.equal(write.updateTransforms[0].fieldPath,'updatedAt');
    for(const key of ['name','isActive','photo','kcalPer100g','sourceLabel'])assert.ok(!write.updateMask.fieldPaths.includes(key));
    assert.ok(write.updateMask.fieldPaths.some(k=>k.startsWith('extraNutrientsPer100g.')));
    assert.ok(audit.update.fields.reason.stringValue.includes(version));
  }
});
test('source identity, macros, exact variant and units must match',()=>{
  const food=source.find(f=>f.brand==='Acecook');
  for(const [key,val] of [['name','other'],['sourceLabel','other'],['sourceUrl','https://other.test'],['unit','ml'],['kcalPer100g',1]]){
    const doc=fixture(food);doc.fields[key]=wire(val);assert.equal(planRelease([food],[doc]).conflicts.length,1);
  }
  const doc=fixture(food);doc.fields.sourceDetails.mapValue.fields.variantIndex=wire(99);
  assert.equal(planRelease([food],[doc]).conflicts[0].reason,'source-identity-changed');
});
test('missing, foreign paths and missing versions cannot create or overwrite data',()=>{
  assert.equal(planRelease([source[0]],[]).conflicts[0].reason,'missing-document');
  const doc=fixture();delete doc.updateTime;assert.throws(()=>planRelease([source[0]],[doc]));
  doc.updateTime='v';doc.name=doc.name.replace(project,'other-project');assert.throws(()=>planRelease([source[0]],[doc]));
});
test('explicit zero, null, cleared maps and conflicting nutrients are preserved',()=>{
  for(const val of [null,{}, {sodium:0},{sodium:null},{sodium:12345}]){
    const doc=fixture();doc.fields.extraNutrientsPer100g=wire(val);const before=structuredClone(doc);
    const plan=planRelease([source[0]],[doc]);assert.equal(plan.updates.length,0);assert.equal(plan.conflicts.length,1);assert.deepEqual(doc,before);
  }
});
test('existing unrelated micronutrients/photos/hidden state survive merge and readback',()=>{
  const food=source[0],doc=fixture();doc.fields.extraNutrientsPer100g=wire({potassium:50});
  const plan=planRelease([food],[doc]),after=applied(doc,plan);
  assert.deepEqual(verifyRelease(plan,[doc],[after]),{verified:1,unchanged:0});
  assert.equal(after.fields.extraNutrientsPer100g.mapValue.fields.potassium.doubleValue,50);
  assert.deepEqual(after.fields.photo,doc.fields.photo);assert.deepEqual(after.fields.isActive,doc.fields.isActive);
});
test('legacy USDA enrichment accepts only known old source and retains existing label/fiber',()=>{
  const food=source.find(f=>f.id==='egg-boiled'),doc=fixture(food);
  doc.fields.sourceLabel=wire('USDA FoodData Central (SR Legacy) — giá trị tham khảo/100 g');delete doc.fields.sourceDetails;
  delete doc.fields.fiberGPer100g;delete doc.fields.fiberSourceUrl;
  let plan=planRelease([food],[doc]);assert.equal(plan.updates.length,1);assert.equal(plan.updates[0].patch.fiberGPer100g,0);
  assert.equal(plan.updates[0].patch.sourceDetails.fdcId,173424);assert.ok(!('sourceLabel' in plan.updates[0].patch));
  doc.fields.fiberGPer100g=wire(null);plan=planRelease([food],[doc]);assert.ok(!('fiberGPer100g'in plan.updates[0].patch));
  doc.fields.sourceLabel=wire('Admin custom source');assert.equal(planRelease([food],[doc]).updates.length,0);
});
test('package values stay exact, unknown sugar is never filled, audit records source changes',()=>{
  const food=source.find(f=>f.id==='hao-hao-tom-chua-cay-75g'),plan=planRelease([food],[fixture(food)]),patch=plan.updates[0].patch;
  assert.ok(Math.abs(patch['extraNutrientsPer100g.sugar']*.75-4)<1e-10);
  assert.ok(Math.abs(patch['extraNutrientsPer100g.sodium']*.75-1778)<1e-10);
  assert.equal(patch['sourceDetails.nutrientsPerPackage.sodiumMg'],1778);
  const unknown=source.find(f=>f.id==='mien-phu-huong-ga-53g');
  assert.ok(!('extraNutrientsPer100g.sugar'in planRelease([unknown],[fixture(unknown)]).updates[0].patch));
});
test('existing evidence/package conflicts cannot be silently replaced',()=>{
  const food=source.find(f=>f.brand==='Acecook'),doc=fixture(food);
  doc.fields.sourceDetails.mapValue.fields.additionalNutrientEvidence=wire({reviewedOn:'other'});
  assert.equal(planRelease([food],[doc]).conflicts[0].reason,'existing-evidence-conflict');
  delete doc.fields.sourceDetails.mapValue.fields.additionalNutrientEvidence;
  doc.fields.sourceDetails.mapValue.fields.nutrientsPerPackage.mapValue.fields.sodiumMg=wire(1);
  assert.equal(planRelease([food],[doc]).conflicts[0].reason,'existing-package-nutrient-conflict');
});
test('replanning the published result is idempotent',()=>{
  const doc=fixture(),plan=planRelease([source[0]],[doc]),after=applied(doc,plan),again=planRelease([source[0]],[after]);
  assert.equal(again.updates.length,0);assert.deepEqual(again.conflicts,[]);assert.deepEqual(again.skipped,[source[0].id]);
});
test('verification detects every unrelated mutation including timestamps',()=>{
  const doc=fixture(),plan=planRelease([source[0]],[doc]);
  doc.fields.createdAt={timestampValue:'2026-01-01T00:00:00Z'};
  for(const mutate of [d=>d.fields.isActive=wire(true),d=>delete d.fields.photo,d=>d.fields.createdAt.timestampValue='2026-01-02T00:00:00Z',d=>d.fields.extraNutrientsPer100g.mapValue.fields.sodium=wire(999)]){
    const after=applied(doc,plan);mutate(after);assert.throws(()=>verifyRelease(plan,[doc],[after]));
  }
});
