import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import crypto from 'node:crypto';
import {photoPayload,resolvePhoto,foodPhotoEditor,foodPhotoPreview} from '../dist/food-photos.mjs';
import {bundledFoodPhotos} from '../dist/bundled-food-photos.mjs';

const custom={photoMode:'custom','photo-url':'https://example.com/pho.webp'};
test('photo changes distinguish default, removal and URL-only custom image',()=>{
  const row={id:'vn-pho-bo',name:'Phở bò'};
  assert.ok(resolvePhoto(row).url.startsWith('./food-photos/'));
  assert.equal(resolvePhoto({...row,photo:{mode:'hidden'}}),null);
  assert.equal(resolvePhoto({...row,name:'Tên món khác'}),null);
  assert.equal(resolvePhoto({...row,photo:{mode:'unknown'}}),null);
  const photo=photoPayload(custom);
  assert.deepEqual(photo,{mode:'custom',url:custom['photo-url']});
  assert.equal(resolvePhoto({...row,photo}).url,'https://example.com/pho.webp');
  assert.deepEqual(photoPayload({photoMode:'hidden',...{'photo-url':'invalid'}}),{mode:'hidden'});
  assert.deepEqual(photoPayload({}),{mode:'default'});
});
test('unsafe photo URLs cannot be saved or fall back to an unrelated image',()=>{
  for(const patch of [{'photo-url':'javascript:alert(1)'},{'photo-url':'data:image/png;base64,x'},
    {'photo-url':'http://example.com/a.png'},{'photo-url':'https://user:pass@example.com/a'},
    {'photo-url':'https://example.com/a b'},{'photo-url':'https://example.com/'+ 'x'.repeat(1000)},
    {'photo-url':''},{'photo-url':'file:///a'}, {photoMode:'invalid'}]) {
    assert.throws(()=>photoPayload({...custom,...patch}));
  }
  assert.equal(resolvePhoto({id:'vn-pho-bo',name:'Phở bò',photo:{mode:'custom',url:'invalid'}}),null);
});
test('all admin previews preserve the exact reviewed app photo and its credits',()=>{
  const {photos}=JSON.parse(fs.readFileSync(new URL('../../assets/food_photos/manifest.json',import.meta.url)));
  const scope=JSON.parse(fs.readFileSync(new URL('../../data/food_catalog/photo-coverage-500.json',import.meta.url))).foods;
  const release=JSON.parse(fs.readFileSync(new URL('../../data/food_catalog/photo-release.json',import.meta.url)));
  assert.equal(photos.length,release.visibleIds.length);
  assert.deepEqual(photos.map(p=>p.foodId).sort(),[...release.visibleIds].sort());
  assert.deepEqual([...release.visibleIds,...release.excluded.map(f=>f.id)].sort(),scope.map(f=>f.id).sort());
  assert.equal(Object.keys(bundledFoodPhotos).length,photos.length);
  for(const photo of photos){
    const web=bundledFoodPhotos[photo.foodId];
    assert.equal(crypto.createHash('sha256').update(fs.readFileSync(new URL('../dist/'+web.url,import.meta.url))).digest('hex'),photo.sha256);
    for(const key of ['title','author','sourceUrl','license','licenseUrl'])assert.equal(web[key],photo[key]);
  }
});
import {parseHTML} from 'linkedom';
import {foodPayload} from '../dist/validation.mjs';
import {needsPhotoBeforeActivation,showRestorePhotoGuard} from '../dist/food-photos.mjs';
import {excludedFoodPhotoIds} from '../dist/bundled-food-photos.mjs';

test('legacy credits remain readable and preserved only while retaining the image URL',()=>{
 const legacy={mode:'custom',url:custom['photo-url'],title:'Phở',author:'Chủ sở hữu',sourceUrl:'https://example.com/source',license:'CC0',licenseUrl:'https://example.com/license'};
 assert.equal(resolvePhoto({name:'Phở',photo:legacy}).author,legacy.author);
 assert.deepEqual(photoPayload(custom,legacy),legacy);
 assert.deepEqual(photoPayload({...custom,'photo-url':'https://example.com/new.jpg'},legacy),{mode:'custom',url:'https://example.com/new.jpg'});
});

test('custom editor contains only URL and URL-only preview never invents credits',()=>{
 const {document}=parseHTML('<form></form>');
 const h=(tag,attrs={},...children)=>{const el=document.createElement(tag);for(const [key,value] of Object.entries(attrs)){if(key==='onLoad')el.addEventListener('load',value);else if(key==='onError')el.addEventListener('error',value);else el.setAttribute(key,value);}for(const child of children)el.append(typeof child==='string'?document.createTextNode(child):child);return el;};
 const field=(name,label,value)=>h('label',{},label,h('input',{name,value:value??''}));
 const row={name:'Phở',photo:photoPayload(custom)};
 const editor=foodPhotoEditor(h,field,row);document.querySelector('form').append(editor);
 assert.deepEqual([...editor.querySelectorAll('input')].map(input=>input.name),['photo-url']);
 for(const fieldName of ['photo-title','photo-author','photo-sourceUrl','photo-license','photo-licenseUrl'])assert.equal(editor.querySelector(`[name="${fieldName}"]`),null);
 const preview=foodPhotoPreview(h,row);preview.querySelector('img').dispatchEvent(new document.defaultView.Event('load'));
 assert.equal(preview.querySelector('[role=status]').textContent,'Ảnh minh họa');assert.doesNotMatch(preview.textContent,/undefined/);
});

test('excluded no-photo restore opens add-image modal with edit action and no save action',()=>{
 const {document}=parseHTML('<main></main>');let opened,edited=null;
 const h=(tag,attrs={},...children)=>{const el=document.createElement(tag);for(const [k,v] of Object.entries(attrs))el.setAttribute(k,v);for(const c of children)el.append(typeof c==='string'?document.createTextNode(c):c);return el;};
 const row={id:excludedFoodPhotoIds[0],name:'Món chưa có ảnh',isActive:false};
 const blocked=showRestorePhotoGuard(row,{h,openEditor:(title,children,action,options)=>{opened={title,action,options};document.querySelector('main').append(...children);},button:(label,click)=>{const el=h('button',{},label);el.addEventListener('click',click);return el;},editFood:r=>edited=r});
 assert.equal(blocked,true);assert.equal(opened.action,null);assert.equal(opened.options.reason,false);assert.match(document.querySelector('main').textContent,/HTTPS công khai/);document.querySelector('button').click();assert.equal(edited,row);
 const credited={...row,photo:photoPayload(custom)};assert.equal(needsPhotoBeforeActivation(credited),false);assert.equal(showRestorePhotoGuard(credited,{openEditor:()=>assert.fail('must allow restore')}),false);
});

test('excluded image plus activation saves; missing/hidden image blocked only within release exclusions',()=>{
 const fields={id:excludedFoodPhotoIds[0],name:'Món cần ảnh',category:'Món chính',kcalPer100g:100,proteinGPer100g:5,carbsGPer100g:20,fatGPer100g:1,fiberGPer100g:'',sourceLabel:'Nguồn QA',sourceUrl:'https://example.com/source',isActive:true,isEstimated:true};
 assert.throws(()=>foodPayload(fields),/cần ảnh hợp lệ/);assert.throws(()=>foodPayload({...fields,photoMode:'hidden'}),/cần ảnh hợp lệ/);
 assert.equal(foodPayload({...fields,...custom}).isActive,true);assert.equal(foodPayload({...fields,...custom}).photo.mode,'custom');
 assert.equal(foodPayload({...fields,isActive:false}).isActive,false);assert.equal(foodPayload({...fields,id:'outside-release'}).isActive,true);
 const release=JSON.parse(fs.readFileSync(new URL('../../data/food_catalog/photo-release.json',import.meta.url)));assert.deepEqual([...excludedFoodPhotoIds].sort(),release.excluded.map(x=>x.id).sort());
});
