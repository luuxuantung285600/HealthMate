const {test}=require('node:test');
const assert=require('node:assert/strict');
const {catalog,planRelease,makeWrites,verifyRelease}=require('./publish_fruit_drink_catalog.cjs');
const {wire}=require('./publish_verified_nutrients.cjs');
const {buildCatalog}=require('./import_food_catalog.cjs');
const browse=require('../data/food_catalog/fruit-drink-browse.json').groups;
const actor='firebase-cli:'+'a'.repeat(24);

test('200 distinct reviewed identities match app bundle and both groups have 100',()=>{
  const foods=catalog();assert.equal(foods.length,200);
  for(const group of Object.values(browse))assert.equal(group.length,100);
  assert.equal(foods.filter(f=>f.sourceDetails.method==='reference_table').length,48);
  assert.ok(foods.every(f=>f.sourceUrl&&f.sourceLabel&&f.isEstimated));
  assert.ok(foods.every(f=>f.servingBasis==='per_100g'&&f.unit==='g'));
});

test('new VDD cells keep exact units, missing fiber and inconsistent sugar withheld',()=>{
  const foods=buildCatalog();const find=id=>foods.find(f=>f.id===id);
  assert.deepEqual([find('vn2007-5003').kcalPer100g,find('vn2007-5003').fatGPer100g],[24,.3]);
  assert.equal(find('vn2007-5003').extraNutrientsPer100g.sodium,3);
  assert.equal(find('vn2007-5010').extraNutrientsPer100g.sugar,undefined);
  assert.equal(find('vn2007-14008').extraNutrientsPer100g.sugar,0);
  assert.equal(find('vn2007-14007').extraNutrientsPer100g.sodium,269);
  assert.equal(find('vn2007-5056').fiberGPer100g,undefined);
  for(const id of ['vn2007-5043','vn2007-5044','vn2007-5054'])assert.equal(find(id),undefined);
});

test('review never overwrites existing admin data and detects a conflicting name',()=>{
  const foods=catalog();const first=foods[0];
  const existing=[{name:'food_catalog/'+first.id,fields:wire({name:'Tên quản trị viên sửa'}).mapValue.fields}];
  const plan=planRelease(foods,existing);
  assert.deepEqual(plan.skipped,[first.id]);assert.equal(plan.creates.length,199);
  assert.equal(planRelease(foods,[{name:'food_catalog/another',fields:wire({name:first.name}).mapValue.fields}]).conflicts.length,1);
});

test('publication is atomic create-only with an audit for every food and no private paths',()=>{
  const plan=planRelease(catalog(),[]),writes=makeWrites(plan,actor);
  assert.equal(writes.length,400);
  for(const write of writes){assert.deepEqual(write.currentDocument,{exists:false});assert.match(write.update.name,/\/documents\/(food_catalog|admin_audit)\//);assert.equal(write.updateMask,undefined);}
  assert.throws(()=>makeWrites(plan,'untrusted'));
});

test('readback detects nutrient tampering, changes to old docs and absent creates',()=>{
  const foods=catalog().slice(0,2),plan=planRelease(foods,[]);
  const after=makeWrites(plan,actor).filter(w=>w.update.name.includes('/food_catalog/')).map(w=>({name:w.update.name,fields:{...w.update.fields,updatedAt:{timestampValue:'2026-11-10T00:00:00Z'}}}));
  assert.equal(verifyRelease(plan,[],after,actor).verifiedCreates,2);
  assert.throws(()=>verifyRelease(plan,[],after.slice(0,1),actor));
  const changed=structuredClone(after);changed[0].fields.kcalPer100g={doubleValue:999};
  assert.throws(()=>verifyRelease(plan,[],changed,actor));
  const old={name:'food_catalog/old',fields:wire({name:'Existing'}).mapValue.fields};
  assert.equal(verifyRelease(plan,[old],[...after,old],actor).unchanged,1);
  assert.throws(()=>verifyRelease(plan,[old],[...after,{...old,updateTime:'changed'}],actor));
  assert.equal(planRelease(foods,after).creates.length,0);
});
