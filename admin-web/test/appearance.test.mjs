import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import {createHash} from 'node:crypto';
import {parseHTML} from 'linkedom';
import {adminIcon} from '../dist/admin-shell.mjs';

const script=readFileSync(new URL('../dist/appearance.js',import.meta.url),'utf8');
function setup({saved=null,dark=false,blocked=false}={}) {
  const {window:domWindow,document}=parseHTML('<!doctype html><html><body><select data-admin-theme><option value="system">Thiết bị</option><option value="light">Sáng</option><option value="dark">Tối</option></select></body></html>');
  const window={};
  const values=new Map(saved?[['healthmate.admin.theme',saved]]:[]),events={};
  const media={matches:dark,addEventListener(_name,callback){this.change=callback;}};
  window.matchMedia=()=>media;
  window.addEventListener=(name,callback)=>events[name]=callback;
  window.localStorage={getItem(key){if(blocked)throw Error('Blocked');return values.get(key)??null;},setItem(key,value){if(blocked)throw Error('Blocked');values.set(key,value);}};
  // Linkedom's select.value has no setter; emulate the browser's property here.
  Object.defineProperty(domWindow.HTMLSelectElement.prototype,'value',{configurable:true,get(){return this.getAttribute('data-value');},set(value){this.setAttribute('data-value',value);}});
  vm.runInNewContext(script,{window,document});
  return{window,document,values,events,media,appearance:window.HealthMateAppearance};
}

test('system theme follows the device; an explicit choice persists and overrides device changes',()=>{
  const t=setup({dark:true});
  assert.equal(t.document.documentElement.dataset.theme,'dark');
  t.media.matches=false;t.media.change();
  assert.equal(t.document.documentElement.dataset.theme,'light');
  t.appearance.setPreference('dark');
  assert.equal(t.values.get('healthmate.admin.theme'),'dark');
  t.media.change();assert.equal(t.document.documentElement.dataset.theme,'dark');
  assert.equal(t.document.querySelector('[data-admin-theme]').value,'dark');
  t.appearance.setPreference('system');
  assert.equal(t.document.documentElement.dataset.theme,'light');
  assert.equal(setup({saved:'dark'}).document.documentElement.dataset.theme,'dark');
});

test('blocked storage and malformed preferences keep the UI usable without changing account data',()=>{
  const t=setup({saved:'unexpected',blocked:true,dark:false});
  assert.equal(t.appearance.getPreference(),'system');
  t.appearance.setPreference('dark');
  assert.equal(t.document.documentElement.dataset.theme,'dark');
  t.appearance.setPreference('<script>');
  assert.equal(t.appearance.getPreference(),'dark');
});

test('theme changes in another tab update controls; clearing storage returns to device preference',()=>{
  const t=setup({dark:true});
  t.events.storage({key:'unrelated',newValue:'light'});
  assert.equal(t.appearance.getPreference(),'system');
  t.events.storage({key:'healthmate.admin.theme',newValue:'light'});
  assert.equal(t.document.documentElement.dataset.theme,'light');
  assert.equal(t.document.querySelector('[data-admin-theme]').value,'light');
  t.events.storage({key:null,newValue:null});
  assert.equal(t.appearance.getPreference(),'system');
  assert.equal(t.document.documentElement.dataset.theme,'dark');
});

test('admin icons retain their pinned source and local license while sharing Flutter feature colors',()=>{
  const manifest=JSON.parse(readFileSync(new URL('../dist/licenses/lucide-manifest.json',import.meta.url),'utf8'));
  const app=JSON.parse(readFileSync(new URL('../../assets/fonts/healthmate_icons/manifest.json',import.meta.url),'utf8'));
  const pinned=JSON.parse(readFileSync(new URL('../dist/licenses/lucide-source.json',import.meta.url),'utf8'));
  const dart=readFileSync(new URL('../../lib/core/theme/app_feature_visuals.dart',import.meta.url),'utf8');
  assert.deepEqual(manifest.source,pinned.upstream);
  for(const [alias,key] of Object.entries(manifest.flutterAliases)){
    assert.equal(manifest.icons[alias].lucide,pinned.icons[key].lucide);
    assert.ok(Object.hasOwn(app.icons,key),`Flutter semantic alias remains available: ${key}`);
  }
  for(const match of dart.matchAll(/(\w+)\(AppIcons\.\w+, 0xFF([A-Fa-f0-9]{6}), 0xFF([A-Fa-f0-9]{6})\)/g)){
    assert.deepEqual(manifest.colors[match[1]],{light:'#'+match[2].toLowerCase(),dark:'#'+match[3].toLowerCase()});
  }
  const license=readFileSync(new URL('../dist/licenses/lucide.txt',import.meta.url));
  assert.equal(createHash('sha256').update(license).digest('hex'),pinned.licenseSha256);
  assert.match(license.toString('utf8'),/ISC License/);
  assert.match(license.toString('utf8'),/MIT License/);
  const html=readFileSync(new URL('../dist/index.html',import.meta.url),'utf8');
  assert.ok(html.indexOf('appearance.js')<html.indexOf('style.css'),'apply the preference before painting styles');
});

test('SVG icons are decorative, reusable and do not contribute text to action button names',()=>{
  const {document}=parseHTML('<!doctype html><html><body></body></html>');
  globalThis.document=document;
  for(const name of ['overview','food_catalog','workouts','chatbot','support','revenue','close','delete']){
    const first=adminIcon(name),second=adminIcon(name);
    assert.notEqual(first,second);
    assert.equal(first.getAttribute('aria-hidden'),'true');
    assert.equal(first.getAttribute('focusable'),'false');
    assert.equal(first.getAttribute('stroke-width'),'2');
    assert.equal(first.textContent,'');
    assert.ok(first.children.length>0);
    assert.equal(first.querySelector('script,image,use,foreignObject'),null);
  }
});
