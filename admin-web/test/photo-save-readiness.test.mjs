import test from 'node:test';
import assert from 'node:assert/strict';
import {parseHTML} from 'linkedom';
import {validateEditorPhoto} from '../dist/food-photos.mjs';

function fixture(){
 const {document}=parseHTML('<form></form>'),form=document.querySelector('form');
 const fields={photoMode:'custom','photo-url':'https://example.com/photo.webp'};
 for(const [name,value] of Object.entries(fields)){const input=document.createElement('input');input.name=name;input.value=value;form.append(input);}
 return form;
}
function imageClass(outcome,inspect=()=>{}){
 return class {
  set src(url){this.url=url;inspect(this);if(outcome==='pending')return;
   queueMicrotask(()=>{if(outcome==='load'){this.naturalWidth=512;this.naturalHeight=512;this.onload?.();}
    else if(outcome==='empty'){this.naturalWidth=0;this.naturalHeight=512;this.onload?.();}
    else this.onerror?.();});
  }
 };
}
test('custom save needs only URL, loads without referrer and validates URL first',async()=>{
 const form=fixture();let loads=0;
 await validateEditorPhoto(form,{ImageClass:imageClass('load',img=>{loads++;assert.equal(img.url,'https://example.com/photo.webp');assert.equal(img.referrerPolicy,'no-referrer');})});
 assert.equal(loads,1);form.querySelector('[name="photo-url"]').value='http://example.com/photo.jpg';
 await assert.rejects(validateEditorPhoto(form,{ImageClass:imageClass('load',()=>loads++)}),/HTTPS/);assert.equal(loads,1);
});
test('default and hidden modes do not load images',async()=>{
 for(const mode of ['default','hidden']){const form=fixture();form.querySelector('[name="photoMode"]').value=mode;
 await validateEditorPhoto(form,{ImageClass:imageClass('error',()=>assert.fail('must not load'))});}
});
test('load errors, empty dimensions and stalled requests reject saving',async()=>{
 for(const [outcome,message] of [['error',/Không tải được/],['empty',/kích thước/],['pending',/quá lâu/]])
  await assert.rejects(validateEditorPhoto(fixture(),{ImageClass:imageClass(outcome),timeoutMs:5}),message);
});
test('only a loaded preview matching the current URL can bypass loading',async()=>{
 const form=fixture(),host=form.ownerDocument.createElement('div'),img=form.ownerDocument.createElement('img');host.setAttribute('data-photo-preview','');host.append(img);form.append(host);
 img.src='https://example.com/old.webp';Object.defineProperties(img,{complete:{value:true},naturalWidth:{value:512},naturalHeight:{value:512}});
 let loads=0;await validateEditorPhoto(form,{ImageClass:imageClass('load',()=>loads++)});assert.equal(loads,1);
 img.src='https://example.com/photo.webp';await validateEditorPhoto(form,{ImageClass:imageClass('error',()=>assert.fail('matching preview ready'))});
});
test('editing URL or mode while image loads cannot validate a stale draft',async()=>{
 for(const [name,value] of [['photo-url','https://example.com/new.webp'],['photoMode','hidden']]){
  const form=fixture();await assert.rejects(validateEditorPhoto(form,{ImageClass:imageClass('load',()=>{form.querySelector(`[name="${name}"]`).value=value;})}),/vừa thay đổi/);
 }
});
