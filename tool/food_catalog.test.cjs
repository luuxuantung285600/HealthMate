const {test} = require('node:test');
const assert = require('node:assert/strict');
const {buildCatalog, selectCatalogIds, validateFood, planAdditions, createWrites, planCatalogChanges} = require('./import_food_catalog.cjs');
const catalog = buildCatalog();
const find = id => catalog.find(food => food.id === id);

test('a targeted import cannot silently include old entries, unknown IDs or duplicates', () => {
  assert.deepEqual(selectCatalogIds(catalog, ['hao-hao-tom-chua-cay-75g']).map(f => f.id), ['hao-hao-tom-chua-cay-75g']);
  for (const ids of [[], ['missing'], ['vn-pho-bo','vn-pho-bo'], null]) {
    assert.throws(() => selectCatalogIds(catalog, ids));
  }
});

test('Vietnamese expansion has complete sources, finite macros, estimates and distinct names/IDs', () => {
  assert.equal(catalog.length, 354);
  assert.equal(new Set(catalog.map(food => food.id)).size, catalog.length);
  assert.equal(new Set(catalog.map(food => food.name)).size, catalog.length);
  assert.equal(catalog.filter(food => food.sourceDetails.method === 'reference_table').length, 242);
  assert.equal(catalog.filter(food => food.sourceDetails.method === 'recipe_estimate').length, 83);
  for (const food of catalog) {
    assert.equal(validateFood(food), food);
    assert.match(food.sourceUrl, /^https:\/\/(www\.fao\.org|(?:www\.)?thmilk\.vn|acecookvietnam\.vn|fdc\.nal\.usda\.gov)\//);
    if (food.sourceDetails.method === 'reference_table') {
      assert.ok(food.sourceDetails.pdfPage >= 14 && food.sourceDetails.pdfPage <= 567);
      assert.match(food.sourceDetails.foodCode, /^\d+$/);
    } else if (food.sourceDetails.method === 'recipe_estimate') {
      assert.ok(food.sourceDetails.yieldGrams > 0);
      assert.ok(food.sourceDetails.ingredients.length > 0);
      assert.match(food.sourceDetails.note, /không phải kết quả phân tích/);
      assert.equal(food.servingGrams, food.sourceDetails.yieldGrams);
    } else if(food.sourceDetails.method==='usda_sr_legacy') {
      assert.equal(food.sourceDetails.nutrientId,1079);
      assert.ok(Number.isFinite(food.fiberGPer100g));
      assert.match(food.fiberSourceUrl,/food-details\/\d+\/nutrients$/);
    } else if (food.brand === 'TH true YOGURT') {
      assert.equal(food.sourceDetails.method, 'manufacturer_label');
      assert.equal(food.servingGrams, 100);
      assert.equal(food.brand, 'TH true YOGURT');
      assert.equal(food.sourceDetails.retrievedOn, '2026-10-19');
    } else {
      assert.equal(food.sourceDetails.method, 'manufacturer_label');
      assert.equal(food.sourceDetails.basis, 'per_package');
      assert.equal(food.brand, 'Acecook');
      assert.equal(food.sourceDetails.retrievedOn, '2026-11-10');
      assert.equal(food.servingGrams, food.sourceDetails.netWeightGrams);
    }
  }
});

test('new package variants normalize their exact net weight and preserve the one-package label', () => {
  const cases = [
    ['hao-hao-tom-chua-cay-75g', 75, 350, 6.9, 51.4, 13],
    ['hao-hao-big-tom-chua-cay-100g', 100, 434, 8.8, 61.7, 16.9],
    ['pho-de-nhat-bo-68g', 68, 251, 5, 49.4, 3.7],
    ['pho-de-nhat-ga-67g', 67, 255, 5, 51.2, 3.3],
    ['mien-phu-huong-ga-53g', 53, 189, 1.9, 40.1, 2.3],
  ];
  for (const [id, grams, ...expected] of cases) {
    const food = find(id);
    assert.equal(food.servingGrams, grams);
    for (const [i, metric] of ['kcal','proteinG','carbsG','fatG'].entries()) {
      assert.ok(Math.abs(food[metric + 'Per100g'] * grams / 100 - expected[i]) < .00001);
    }
    assert.match(food.packageLabel, /chưa pha nước/);
    assert.match(food.name, /gói khô/);
  }
  const bundle = JSON.parse(require('node:fs').readFileSync('assets/nutrition/vietnamese-foods.json','utf8'));
  for (const food of catalog.filter(f => f.brand)) {
    const bundled = bundle.foods.find(f => f.id === food.id);
    assert.equal(bundled.servingGrams, food.servingGrams);
    assert.equal(bundled.defaultServingGrams, food.servingGrams);
    assert.equal(bundled.servingLabel, food.servingLabel); // never "tô tham khảo" for a dry package
  }
});

test('reference food state is explicit and bread/pho nutrients match their cited rows', () => {
  const noodles = find('vn2007-1013');
  assert.deepEqual([noodles.kcalPer100g, noodles.proteinGPer100g, noodles.carbsGPer100g, noodles.fatGPer100g], [143, 3.2, 31.7, 0.4]);
  assert.equal(noodles.sourceDetails.pdfPage, 26);
  assert.equal(find('vn2007-1012').kcalPer100g, 249);
  assert.match(find('vn2007-7017').name, /sống/);
  assert.match(find('vn2007-8022').name, /Cá lóc/);
  assert.equal(find('vn2007-8022').sourceDetails.pdfPage, 410);
});

test('pho recipe uses all ingredient energy and finished weight, not 100g as one bowl', () => {
  const pho = find('vn-pho-bo');
  const bowlKcal = 143 * 2 + 118 * .9 + 41 * .25 + 44 * .3 + 897 * .05 + 390 * .04;
  assert.ok(Math.abs(pho.kcalPer100g * 6 - bowlKcal) < .04);
  assert.equal(pho.sourceDetails.yieldGrams, 600);
  assert.equal(pho.kcalPer100g, 79.35);
  // The NIN bun row has a missing fat value: estimate from flour/yield instead.
  assert.equal(find('vn2007-1020'), undefined);
  assert.equal(find('vn-bun-tuoi').sourceDetails.method, 'recipe_estimate');
  assert.ok(find('vn-bun-tuoi').fatGPer100g > 0);
});

test('recipes can use another recipe and normalize final cooked yield once', () => {
  const fried = find('vn-com-chien-trung');
  const energy = (344 / 270 * 280 + 166 * .6 + 39 * .35 + 41 * .2 + 897 * .12) / 4;
  assert.ok(Math.abs(fried.kcalPer100g - energy) < .01);
  assert.equal(find('vn-rice-base'), undefined); // Internal base is not a duplicate catalog rice.
});

test('import is additive/idempotent and detects matching normalized names with another id', () => {
  const existing = catalog.map(food => ({name: `projects/demo-test/databases/(default)/documents/food_catalog/${food.id}`, fields: {name: {stringValue: food.name}}}));
  assert.equal(planAdditions(catalog, existing).additions.length, 0);
  assert.equal(planAdditions(catalog, existing).skipped, catalog.length);
  const renamedId = [{name: 'food_catalog/legacy-pho', fields: {name: {stringValue: 'PHO BO'}}}];
  const plan = planAdditions(catalog, renamedId);
  assert.equal(plan.skipped, 1);
  assert.ok(!plan.additions.some(food => food.id === 'vn-pho-bo'));
});

test('manufacturer variants retain their own values and mass basis, never generic milk/ml', () => {
  const sweet = find('th-yogurt-sweetened-100g'), plain = find('th-yogurt-natural-100g');
  assert.deepEqual([sweet.kcalPer100g, sweet.proteinGPer100g, sweet.carbsGPer100g, sweet.fatGPer100g], [94.9,3.1,13.2,3.3]);
  assert.deepEqual([plain.kcalPer100g, plain.proteinGPer100g, plain.carbsGPer100g, plain.fatGPer100g], [63.2,3.3,4.4,3.6]);
  for (const servingGrams of [0, -1, NaN, Infinity, '100']) assert.throws(() => validateFood({...sweet, servingGrams}));
  assert.throws(() => validateFood({...sweet, servingLabel: ''}));
});

test('review manifest distinguishes metadata updates, conflicts and skips without overwriting', () => {
  const food = find('vn-pho-bo');
  const write = createWrites('demo-healthmate-rules', [food])[0];
  const existing = {name: write.update.name, fields: {...write.update.fields}, updateTime: '2026-10-01T00:00:00Z'};
  delete existing.fields.servingLabel; delete existing.fields.servingGrams; delete existing.fields.portionSource;
  const plan = planCatalogChanges([food], [existing]);
  assert.equal(plan.creates.length, 0); assert.equal(plan.updates.length, 1);
  assert.equal(plan.updates[0].patch.servingGrams, 600);
  assert.equal(plan.updates[0].beforeUpdateTime, existing.updateTime);
  const fresh = {name: write.update.name, fields: write.update.fields};
  assert.deepEqual(planCatalogChanges([food], [fresh]).skips, [food.id]);
  const changed = {...existing, fields: {...existing.fields, kcalPer100g: {doubleValue: 999}}};
  assert.equal(planCatalogChanges([food], [changed]).conflicts.length, 1);
});

test('every write is a catalog create with a server timestamp, never user-data mutation', () => {
  const writes = createWrites('demo-healthmate-rules', catalog);
  for (const write of writes) {
    assert.match(write.update.name, /^projects\/demo-healthmate-rules\/databases\/\(default\)\/documents\/food_catalog\/[a-z0-9-]+$/);
    assert.deepEqual(write.currentDocument, {exists: false});
    assert.deepEqual(write.updateTransforms, [{fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME'}]);
    assert.equal(write.update.fields.isEstimated.booleanValue, true);
    assert.equal(write.update.fields.servingBasis.stringValue, 'per_100g');
  }
  assert.throws(() => createWrites('bad/project', catalog));
  assert.throws(() => createWrites('demo-healthmate-rules', [{...catalog[0], id: '../users/uid'}]));
});

test('import rejects non-finite, missing, impossible or misleading nutrition metadata', () => {
  for (const replacement of [NaN, Infinity, -1, 1001]) assert.throws(() => validateFood({...catalog[0], kcalPer100g: replacement}));
  assert.throws(() => validateFood({...catalog[0], fatGPer100g: undefined}));
  assert.throws(() => validateFood({...catalog[0], proteinGPer100g: 90, fatGPer100g: 30}));
  assert.throws(() => validateFood({...catalog[0], servingBasis: 'per_bowl'}));
  assert.throws(() => validateFood({...catalog[0], isEstimated: false}));
});

test('fiber metadata is sourced, optional, zero-preserving and review-only idempotent',()=>{
  const food=find('egg-boiled'); assert.equal(food.fiberGPer100g,0);
  for(const fiberGPer100g of [-1,101,NaN,Infinity,'0'])assert.throws(()=>validateFood({...food,fiberGPer100g}));
  assert.throws(()=>validateFood({...food,fiberSourceUrl:'https://example.com/unverified'}));
  const write=createWrites('demo-healthmate-rules',[food])[0];
  const existing={name:write.update.name,fields:{...write.update.fields},updateTime:'2026-10-01T00:00:00Z'};
  delete existing.fields.fiberGPer100g; delete existing.fields.fiberSourceUrl;
  const plan=planCatalogChanges([food],[existing]);
  assert.equal(plan.creates.length,0);assert.equal(plan.updates.length,1);assert.equal(plan.updates[0].patch.fiberGPer100g,0);
  assert.deepEqual(planCatalogChanges([food],[{name:write.update.name,fields:write.update.fields}]).skips,[food.id]);
});

test('reviewed sodium/sugar retain exact package units, unknowns and source evidence',()=>{
  const hh=find('hao-hao-tom-chua-cay-75g');
  assert.ok(Math.abs(hh.extraNutrientsPer100g.sodium*.75-1778)<.00001);
  assert.ok(Math.abs(hh.extraNutrientsPer100g.sugar*.75-4)<.00001);
  assert.equal(hh.sourceDetails.additionalNutrientEvidence.rows.sodium.raw,'1.778mg');
  assert.equal(find('hu-tieu-nhip-song-nam-vang-70g').sourceDetails.nutrientsPerPackage.sodiumMg,1669);
  assert.equal(find('mien-phu-huong-ga-53g').extraNutrientsPer100g.sugar,undefined);
  assert.equal(find('vn2007-1001').extraNutrientsPer100g.sugar,undefined);
  assert.equal(find('vn2007-7003').extraNutrientsPer100g.sugar,0);
  assert.equal(find('vn2007-4007').extraNutrientsPer100g.sodium,52);
  // VDD's Celluloza is not imported as Fiber, total dietary.
  assert.equal(find('vn2007-4007').fiberGPer100g,undefined);
  assert.equal(find('vn-pho-bo').extraNutrientsPer100g,undefined);
  const rice=find('rice-cooked');
  assert.deepEqual(rice.extraNutrientsPer100g,{sodium:1,sugar:.05});
  for(const extraNutrientsPer100g of [{sugar:101},{sodium:-1},{sodium:Infinity},{sugar:'0'},{fiber:3}])
    assert.throws(()=>validateFood({...hh,extraNutrientsPer100g}));
  assert.throws(()=>validateFood({...hh,sourceDetails:{...hh.sourceDetails,additionalNutrientEvidence:null}}));
});
