import test from 'node:test';
import assert from 'node:assert/strict';
import { foodPayload,configPayload,validFoodId,number,changedFields,entityVersion } from '../dist/validation.mjs';
const fields={name:'Cơm tấm',category:'Món chính',kcalPer100g:'200',proteinGPer100g:'12',carbsGPer100g:'23',fatGPer100g:'7',fiberGPer100g:'',sourceLabel:'Nguồn tham khảo',sourceUrl:'https://example.com/food',isEstimated:true,isActive:true};
test('conflict detection preserves timestamp nanoseconds and separates missing from legacy documents',()=>{
  assert.notEqual(entityVersion({updatedAt:{seconds:1,nanoseconds:1}}),entityVersion({updatedAt:{seconds:1,nanoseconds:2}}));
  assert.equal(entityVersion(null),null);assert.equal(entityVersion({}),'legacy');
});
test('nutrition distinguishes missing from zero and accepts Vietnamese decimal input',()=>{
  assert.equal(foodPayload(fields).fiberGPer100g,null);
  assert.equal(foodPayload({...fields,fiberGPer100g:'0'}).fiberGPer100g,0);
  assert.equal(foodPayload({...fields,proteinGPer100g:'12,5'}).proteinGPer100g,12.5);
  for(const value of ['',NaN,Infinity,-1,1001])assert.throws(()=>number(value,'kcal',1000));
});
test('catalog rejects impossible mass, unsafe URLs and incomplete portions',()=>{
  for(const patch of [{fatGPer100g:100,proteinGPer100g:100},{sourceUrl:'javascript:alert(1)'},{sourceUrl:'https://user:password@example.com'},{servingLabel:'tô'},{servingGrams:'0'},{alternateNames:Array(9).fill('tên').join('\n')}])assert.throws(()=>foodPayload({...fields,...patch}));
  const payload=foodPayload({...fields,servingLabel:'phần',servingGrams:'450'});
  assert.equal(payload.servingGrams,450);assert.equal(payload.kcalPer100g,200);
});
test('maintenance requires a message; config contains only permitted switches',()=>{
  assert.throws(()=>configPayload({maintenanceMode:true,maintenanceMessage:' '}));
  assert.deepEqual(Object.keys(configPayload({chatbotEnabled:true,maintenanceMessage:'',apiKey:'secret'})).sort(),['chatbotEnabled','foodScannerEnabled','maintenanceMode','maintenanceMessage'].sort());
});
test('IDs are bounded and audit retains only fields changed in catalog',()=>{
  for(const id of ['../x','A','a/b','', 'a'.repeat(101)])assert.throws(()=>validFoodId(id));
  assert.equal(validFoodId('vn-com-tam-1'),'vn-com-tam-1');
  assert.deepEqual(changedFields({name:'A',updatedBy:'admin'},{name:'B',updatedBy:'admin'},'food_catalog'),['name']);
});
test('sugar and sodium preserve unknown versus confirmed zero and retain other micronutrients',()=>{
  const existing={extraNutrientsPer100g:{sugar:3,sodium:400,potassium:120,calcium:50}};
  const data=foodPayload({...fields,sugarGPer100g:'0',sodiumMgPer100g:'800,5'},existing);
  assert.deepEqual(data.extraNutrientsPer100g,{sugar:0,sodium:800.5,potassium:120,calcium:50});
  assert.deepEqual(foodPayload({...fields,sugarGPer100g:'',sodiumMgPer100g:''},existing).extraNutrientsPer100g,{potassium:120,calcium:50});
  for(const patch of [{sugarGPer100g:-1},{sugarGPer100g:101},{sodiumMgPer100g:Infinity},{sodiumMgPer100g:100001}])assert.throws(()=>foodPayload({...fields,...patch}));
});

test('catalog audit ignores nutrient and photo map key order after form serialization',()=>{
  const before={
    name:'Cơm tấm',
    extraNutrientsPer100g:{calcium:50,potassium:120,sodium:400,sugar:3},
    photo:{author:'Tác giả',license:'CC0',licenseUrl:'https://example.com/license',mode:'custom',sourceUrl:'https://example.com/source',title:'Ảnh',url:'https://example.com/photo.jpg'}
  };
  const after={...before,...foodPayload({...fields,photoMode:'custom',
    'photo-url':before.photo.url,'photo-sourceUrl':before.photo.sourceUrl,
    'photo-licenseUrl':before.photo.licenseUrl,'photo-title':before.photo.title,
    'photo-author':before.photo.author,'photo-license':before.photo.license
  },before)};
  const changed=changedFields(before,after,'food_catalog');
  assert.equal(changed.includes('extraNutrientsPer100g'),false);
  assert.equal(changed.includes('photo'),false);
  assert.deepEqual(changedFields(before,{...before,photo:{...after.photo,title:'Ảnh mới'}},'food_catalog'),['photo']);
  assert.deepEqual(changedFields(before,{...before,extraNutrientsPer100g:{...after.extraNutrientsPer100g,sugar:0}},'food_catalog'),['extraNutrientsPer100g']);
});

test('catalog audit retains scalar, ordered array and timestamp changes',()=>{
  const before={name:'A',alternateNames:['a','b'],updatedAt:{seconds:1,nanoseconds:1}};
  assert.deepEqual(changedFields(before,{...before,name:'B',alternateNames:['b','a'],updatedAt:{seconds:1,nanoseconds:2}},'food_catalog'),['name','alternateNames','updatedAt']);
  assert.deepEqual(changedFields({items:[{a:1,b:2}]},{items:[{b:2,a:1}]},'food_catalog'),[]);
  assert.deepEqual(changedFields({value:null},{value:{}},'food_catalog'),['value']);
  assert.deepEqual(changedFields({}, {value:0},'food_catalog'),['value']);
});
