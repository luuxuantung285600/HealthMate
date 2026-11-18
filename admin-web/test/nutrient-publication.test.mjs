import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {catalogExtras,saltFromSodium} from '../dist/nutrition-values.mjs';
const {patchDisplay,scopedFiles}=createRequire(import.meta.url)('../tool/publish-nutrient-display.cjs');
test('publication adds only import and nutrient detail row, and refuses ambiguous source',()=>{
  const source="function viewFood(row){openEditor('Chi tiết món ăn',[\n  h('h3',{},row.name),\n  h('p',{},`Nguồn: ${row.sourceLabel}`),h('p',{},row.sourceUrl),\n]);}\n";
  const patched=patchDisplay(source);
  assert.match(patched,/Đường tổng:/);assert.match(patched,/Muối quy đổi:/);assert.match(patched,/Chưa có dữ liệu/);
  const withoutAdditions=patched.split('\n').filter(line=>!line.includes('nutrition-values.mjs')&&!line.includes('Đường tổng:')).join('\n');
  assert.equal(withoutAdditions.replace("h('p',{},...String(row.sourceUrl??'').split(/(?<=[/._-])/).flatMap(part=>[part,h('wbr')]))","h('p',{},row.sourceUrl)"),source);
  assert.throws(()=>patchDisplay(patched));assert.throws(()=>patchDisplay('unexpected'));assert.throws(()=>patchDisplay(source+source));
});
test('release preserves unrelated Hosting file hashes',()=>{
  const files=[{path:'/app.mjs',hash:'old'},{path:'/config.js',hash:'config'},{path:'/firebase.mjs',hash:'sdk'}];
  const next=scopedFiles(files,{'/app.mjs':Buffer.from('new'),'/nutrition-values.mjs':Buffer.from('helper')});
  assert.equal(next['/config.js'],'config');assert.equal(next['/firebase.mjs'],'sdk');assert.equal(Object.keys(next).length,4);
  assert.notEqual(next['/app.mjs'],'old');assert.throws(()=>scopedFiles(files,{'/config.js':Buffer.from('bad')}));
});
test('published detail helper preserves unknown/zero and exact salt conversion',()=>{
  assert.deepEqual(catalogExtras({}),{});assert.deepEqual(catalogExtras({extraNutrientsPer100g:{sugar:0,sodium:0}}),{sugar:0,sodium:0});
  assert.equal(saltFromSodium(null),null);assert.equal(saltFromSodium(0),0);
  assert.equal(saltFromSodium(1778),4.445);assert.deepEqual(catalogExtras({extraNutrientsPer100g:{sugar:null,sodium:NaN}}),{});
});
