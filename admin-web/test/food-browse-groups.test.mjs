import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {foodBrowseGroups, classifyFoodBrowseGroups, allowsFoodBrowseGroup} from '../dist/food-browse-groups.mjs';
import {foodBrowseIndex, browseSets} from '../dist/food-browse-metadata.mjs';
import {filterRows} from '../dist/list-model.mjs';
const root = new URL('../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const foods = ['vietnamese-foods', 'usda-sr-legacy', 'usda-current'].flatMap(name => JSON.parse(read(`assets/nutrition/${name}.json`)).foods);
const groups = row => classifyFoodBrowseGroups(row);
const fixture = (name, category = 'Món quốc tế', extra = {}) => ({id: 'fixture', name, category, ...extra});

test('ten group IDs/labels and all generated sets follow Flutter source', () => {
  const dart = read('lib/features/nutrition/models/food_browse_group.dart');
  assert.deepEqual(foodBrowseGroups, [...dart.matchAll(/^  (\w+)\('([^']+)'\)[,;]/gm)].map(([,id,label]) => ({id,label})));
  const sets = Object.fromEntries([...dart.matchAll(/const _(\w+) = \{([\s\S]*?)\};/g)].map(([,key,body]) => [key,[...body.matchAll(/'([^']*)'/g)].map(m=>m[1])]));
  assert.deepEqual(browseSets, sets);
  const index = Object.fromEntries([...read('lib/features/nutrition/models/food_browse_index.dart').matchAll(/'([^']+)': \(group: '([^']+)', order: (\d+)\)/g)].map(([,id,group,order]) => [id,{group,order:Number(order)}]));
  assert.deepEqual(foodBrowseIndex,index);
});

test('full reference catalog group counts equal Flutter classification', () => {
  // Recorded from test/food_browse_groups_test.dart against the same full assets.
  const expected = {all:11361,vietnameseDishes:88,fruits:415,vegetables:1272,meat:2753,seafood:484,eggsDairy:595,grainsLegumesNuts:1534,drinks:774,packaged:59};
  for (const {id} of foodBrowseGroups) assert.equal(foods.filter(row => allowsFoodBrowseGroup(row,id)).length,expected[id],id);
  assert.equal(foods.some(row => allowsFoodBrowseGroup(row,'meat') && allowsFoodBrowseGroup(row,'seafood')),false);
});

test('source categories and exact identity keep meat and seafood separate', () => {
  assert.deepEqual(groups(fixture('Thịt bò','Thịt bò')),['meat']);
  assert.deepEqual(groups(fixture('Cá rô phi','Hải sản')),['seafood']);
  assert.deepEqual(groups(fixture('Chicken breast, roasted')),['meat']);
  assert.deepEqual(groups(fixture('Fish, steamed')),['seafood']);
  for (const name of ['Fish sauce','Fish sandwich, plain','Soup, fish','Chicken fillet sandwich']) {
    assert.equal(allowsFoodBrowseGroup(fixture(name),'meat'),false,name);
    assert.equal(allowsFoodBrowseGroup(fixture(name),'seafood'),false,name);
  }
  assert.deepEqual(groups(fixture('Phở bò','Món ăn Việt')),['vietnameseDishes']);
  assert.deepEqual(groups(fixture('Cá hấp','Món nhà')),['vietnameseDishes']);
});

test('packaged override overlaps dairy without reclassifying flavor as seafood', () => {
  const yogurt=fixture('Sữa chua','Sản phẩm đóng gói');
  assert.deepEqual(groups(yogurt),['eggsDairy','packaged']);
  assert.deepEqual(groups(fixture('Mì tôm chua cay','Sản phẩm đóng gói')),['packaged']);
  assert.deepEqual(groups(fixture('Beef, raw','Thịt bò',{brand:'Brand'})),['meat','packaged']);
  assert.deepEqual(groups(fixture('Rice, cooked','Ngũ cốc',{packageLabel:'500 g'})),['grainsLegumesNuts','packaged']);
});

test('plant milk, powdered milk, juice and reviewed identity follow app exceptions', () => {
  for (const name of ['Soy milk, plain','Almond milk, plain','Sữa yến mạch']) {
    assert.equal(allowsFoodBrowseGroup(fixture(name,'Đồ uống'),'drinks'),true);
    assert.equal(allowsFoodBrowseGroup(fixture(name,'Sữa và chế phẩm'),'eggsDairy'),false);
  }
  assert.deepEqual(groups(fixture('Milk, dry')),['eggsDairy']);
  assert.deepEqual(groups(fixture('Milk, whole')),['eggsDairy','drinks']);
  assert.deepEqual(groups(fixture('Peaches, canned in juice')),['fruits']);
  assert.deepEqual(groups(fixture('Carrot juice','Đồ uống')),['drinks']);
  assert.deepEqual(groups(fixture('Eggplant, cooked')),['vegetables']);
  assert.equal(allowsFoodBrowseGroup(fixture('Quả trứng gà','Trái cây'),'eggsDairy'),false);
  const fruitId = Object.keys(foodBrowseIndex).find(id=>foodBrowseIndex[id].group==='fruits');
  const drinkId = Object.keys(foodBrowseIndex).find(id=>foodBrowseIndex[id].group==='drinks');
  assert.deepEqual(groups(fixture('Coffee','Món quốc tế',{id:fruitId})),['fruits']);
  assert.deepEqual(groups(fixture('Apple','Món quốc tế',{id:drinkId})),['drinks']);
});

test('browse group composes with search, category and archived status without mutation', () => {
  const rows=[fixture('Cá rô phi','Hải sản',{id:'fish',isActive:false}),fixture('Cá thu','Hải sản',{id:'fish2'}),fixture('Thịt bò','Thịt bò',{id:'beef'})];
  const original=structuredClone(rows);
  assert.deepEqual(filterRows(rows,'food_catalog',{browseGroup:'seafood',search:'ro phi',category:'Hải sản',status:'archived'}).map(r=>r.id),['fish']);
  assert.deepEqual(filterRows(rows,'food_catalog',{browseGroup:'meat'}).map(r=>r.id),['beef']);
  assert.equal(filterRows(rows,'food_catalog',{browseGroup:'all'}).length,3);
  assert.deepEqual(rows,original);
  assert.throws(()=>allowsFoodBrowseGroup(rows[0],'unknown'),/Nhóm món/);
  assert.equal(filterRows([{id:'u'}],'user_directory',{browseGroup:'seafood'}).length,1);
});

test('realtime row category and branding edits reclassify without stale cache', () => {
  const row=fixture('Food','Thịt bò');
  assert.deepEqual(groups(row),['meat']);
  row.category='Hải sản';
  assert.deepEqual(groups(row),['seafood']);
  row.brand='Brand';
  assert.deepEqual(groups(row),['seafood','packaged']);
});
