const {test}=require('node:test');const assert=require('node:assert/strict');
const {authTransition,contribution}=require('../src/sync.cjs');
test('Auth delivery is idempotent, deletion wins ties and older events cannot resurrect accounts',()=>{
  assert.equal(authTransition({active:true,eventAt:2},true,2),null);
  assert.equal(authTransition({active:false,eventAt:3},true,2),null);
  assert.equal(authTransition({active:false,eventAt:3},true,3),null);
  assert.deepEqual(authTransition({active:true,eventAt:3},false,3),{active:false,eventAt:3,delta:-1});
  assert.deepEqual(authTransition({active:false,eventAt:3},true,4),{active:true,eventAt:4,delta:1});
  assert.deepEqual(authTransition(null,false,3),{active:false,eventAt:3,delta:0});
});
test('operational counts remove absent records and exclude deleted accounts from suspension total',()=>{
  assert.equal(contribution('food_catalog',null),0);assert.equal(contribution('food_catalog',{isActive:false}),1);
  assert.equal(contribution('account_controls',{status:'suspended'},true),1);
  assert.equal(contribution('account_controls',{status:'suspended'},false),0);
  assert.equal(contribution('account_controls',{status:'active'},true),0);
});
