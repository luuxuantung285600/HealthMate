const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {catalog,planRelease,makeWrites,verifyRelease} = require('./publish_catalog_500.cjs');
const {decode} = require('./import_food_catalog.cjs');
const {wire} = require('./publish_verified_nutrients.cjs');
const source = require('../data/food_catalog/expanded-vietnamese-2026-11-10.json');
const actor = 'firebase-cli:' + 'a'.repeat(24);

test('114 genuinely new reference rows retain exact PDF value cells and unknown nutrients',()=>{
  const foods=catalog();assert.equal(foods.length,114);
  for(const food of foods){
    const raw=source.foods.find(row=>row.id===food.id);
    const evidence=food.sourceDetails.compositionEvidence;
    assert.equal(evidence.sourceSha256,source.sourceSha256);
    assert.equal(food.sourceDetails.pdfPage,raw.sourcePdfPage);
    for(const [metric,label] of [['kcal','Energy'],['proteinG','Protein'],['carbsG','Glucid'],['fatG','Lipid']]){
      assert.match(evidence.cells[label].valueCell,/^\d+(?:\.\d+)?$/);
      assert.equal(food[metric+'Per100g'],Number(evidence.cells[label].valueCell));
    }
    assert.equal(food.fiberGPer100g,undefined); // Cellulose is not total dietary fiber.
    for(const [key,label] of [['sodium','Sodium'],['sugar','Sugar']]){
      if(evidence.cells[label].valueCell==='-')assert.equal(food.extraNutrientsPer100g?.[key],undefined);
    }
    if(+raw.sourceFoodCode>=11001 && +raw.sourceFoodCode<=11021){
      assert.match(food.packageLabel,/nhập khối lượng/);
      assert.equal(food.servingGrams,undefined); // Never pretend all cans weigh 100 g.
      assert.equal(food.brand,undefined);
    }
  }
});

test('app offline copy matches the reviewed source and preserves 100 fruit/drink recommendations',()=>{
  const bundle=JSON.parse(fs.readFileSync('assets/nutrition/vietnamese-foods.json','utf8')).foods;
  for(const food of catalog())assert.deepEqual(bundle.find(row=>row.id===food.id),food);
  const groups=require('../data/food_catalog/fruit-drink-browse.json').groups;
  assert.equal(groups.fruits.length,100);assert.equal(groups.drinks.length,100);
});

test('catalog release preserves edited, hidden and custom-photo records and detects name conflicts',()=>{
  const foods=catalog(),first=foods[0];
  const old={name:'food_catalog/'+first.id,fields:wire({name:'Admin edited',isActive:false,photo:{mode:'hidden'},kcalPer100g:7}).mapValue.fields};
  const frozen=structuredClone(old),plan=planRelease(foods,[old]);
  assert.deepEqual(old,frozen);assert.deepEqual(plan.skipped,[first.id]);
  assert.equal(plan.creates.length,113);
  assert.equal(planRelease(foods,[{name:'food_catalog/other',fields:wire({name:first.name}).mapValue.fields}]).conflicts.length,1);
  for(const write of makeWrites(plan,actor)){
    assert.deepEqual(write.currentDocument,{exists:false});
    assert.match(write.update.name,/\/documents\/(food_catalog|admin_audit)\//);
    assert.equal(write.updateMask,undefined);
  }
});

test('publication readback detects absent foods, modified source values and any changed old record',()=>{
  const foods=catalog().slice(0,3),plan=planRelease(foods,[]);
  const after=makeWrites(plan,actor).filter(w=>w.update.name.includes('/food_catalog/')).map(w=>({name:w.update.name,fields:{...w.update.fields,updatedAt:{timestampValue:'2026-11-10T00:00:00Z'}}}));
  assert.equal(verifyRelease(plan,[],after,actor).verifiedCreates,3);
  assert.throws(()=>verifyRelease(plan,[],after.slice(1),actor));
  const changed=structuredClone(after);changed[0].fields.kcalPer100g={doubleValue:999};
  assert.throws(()=>verifyRelease(plan,[],changed,actor));
  assert.equal(decode(after[0].fields).sourceDetails.method,'reference_table');
  const old={name:'food_catalog/old',fields:wire({name:'Old',photo:{mode:'hidden'}}).mapValue.fields};
  assert.throws(()=>verifyRelease(plan,[old],[...after,{...old,fields:{}}],actor));
});
