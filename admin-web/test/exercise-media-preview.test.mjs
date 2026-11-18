import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {parseHTML} from 'linkedom';
import {exerciseGifQueue,exerciseMediaPreview} from '../dist/exercise-media-preview.mjs';
import {ensureExerciseGifBackground,exerciseGifBackgroundId,exerciseGifBackgroundMarkup,exerciseGifBackgroundStyles} from '../dist/exercise-gif-background.mjs';
import {exerciseBackgroundProfiles} from '../dist/exercise-background-profiles.mjs';

const tick=()=>new Promise(resolve=>setImmediate(resolve));

test('reviewed backdrop profiles share coordinates and gate moving poses without changing GIF timing',()=>{
 const manifest=JSON.parse(readFileSync(new URL('../../data/workouts/exercise-background-regions.json',import.meta.url),'utf8'));
 assert.deepEqual(exerciseBackgroundProfiles,manifest.profiles);
 const {document}=parseHTML(`<svg>${exerciseGifBackgroundMarkup()}</svg>`);
 for(const [id,regions] of Object.entries(manifest.profiles)) {
   const filter=document.getElementById(`${exerciseGifBackgroundId}-${id}`);
   assert.ok(filter,id);
   assert.equal(filter.querySelectorAll('feFlood').length,regions.length);
   assert.equal(filter.querySelectorAll('feTile').length,regions.reduce((n,r)=>n+r.guards.length,0));
   assert.ok(exerciseGifBackgroundStyles().includes(`/media/${id}.gif`));
 }
 assert.doesNotMatch(exerciseGifBackgroundMarkup(),/animate|script|feImage/);
 assert.match(exerciseGifBackgroundStyles(),/:root\[data-theme="dark"\]/);
 const styles=readFileSync(new URL('../dist/exercise-background-profiles.css',import.meta.url),'utf8');
 assert.equal(styles.replace(/\/\*[\s\S]*?\*\//g,'').replace(/\s/g,''),exerciseGifBackgroundStyles().replace(/\s/g,''));
});
function setup(loadGif,{automatic=true,observerEnabled=true,row={name:'Chống đẩy',sourceId:'Ab12345'}}={}) {
  const {document,window}=parseHTML('<!doctype html><html><body></body></html>');
  const h=(tag,props={},...children)=>{
    const node=document.createElement(tag);
    for(const [key,value] of Object.entries(props)) {
      if(key.startsWith('on'))node.addEventListener(key.slice(2).toLowerCase(),value);
      else node.setAttribute(key,String(value));
    }
    node.append(...children);return node;
  };
  const button=(label,click)=>h('button',{type:'button',onClick:click},label);
  let observation;
  class Observer {
    constructor(callback){this.callback=callback;observation=this;}
    observe(target){this.target=target;}
    disconnect(){this.disconnected=true;}
    enter(visible){this.callback([{target:this.target,isIntersecting:visible}]);}
  }
  const preview=exerciseMediaPreview({h,button,row,loadGif,automatic,observer:observerEnabled?Observer:null});
  document.body.append(preview.element);
  return {preview,document,window,observation};
}

test('inline GIF waits for viewport, supports pause/retry and disposes media on exit',async()=>{
  let calls=0;
  const t=setup(async()=>{calls++;return'https://static.exercisedb.dev/media/Ab12345.gif';});
  try {
    assert.equal(calls,0);
    t.observation.enter(true);await tick();assert.equal(calls,1);
    const img=t.preview.element.querySelector('img');assert.ok(img);
    img.dispatchEvent(new t.window.Event('load'));
    assert.equal(t.preview.element.querySelector('button').textContent,'Dừng GIF');
    t.preview.element.querySelector('button').click();
    assert.equal(t.preview.element.querySelector('img'),null);
    t.observation.enter(false);t.observation.enter(true);await tick();assert.equal(calls,1,'manual pause survives visibility callbacks');
    t.preview.element.querySelector('button').click();await tick();assert.equal(calls,2);
    t.observation.enter(false);assert.equal(t.preview.element.querySelector('img'),null);
    t.observation.enter(true);await tick();assert.equal(calls,3);
    t.preview.element.querySelector('img').dispatchEvent(new t.window.Event('error'));
    assert.match(t.preview.element.textContent,/Thử lại GIF/);
    assert.equal(t.preview.element.querySelector('img'),null);
  } finally {t.preview.dispose();}
  assert.equal(t.observation.disconnected,true);
});

test('disposing a pending preview aborts its owner and ignores late completion',async()=>{
  let finish,signal;
  const t=setup((_id,options)=>{signal=options.signal;return new Promise(resolve=>finish=resolve);});
  t.observation.enter(true);assert.equal(signal.aborted,false);
  t.preview.dispose();assert.equal(signal.aborted,true);
  finish('https://static.exercisedb.dev/media/Ab12345.gif');await tick();
  assert.equal(t.preview.element.querySelector('img'),null);
});

test('hidden document drops images and a browser without an observer requires explicit play',async()=>{
  let calls=0;
  const t=setup(async()=>{calls++;return'https://static.exercisedb.dev/media/Ab12345.gif';},{observerEnabled:false});
  try {
    await tick();assert.equal(calls,0);
    t.preview.element.querySelector('button').click();await tick();assert.equal(calls,1);
    Object.defineProperty(t.document,'visibilityState',{configurable:true,value:'hidden'});
    t.document.dispatchEvent(new t.window.Event('visibilitychange'));
    assert.equal(t.preview.element.querySelector('img'),null);
    t.preview.element.querySelector('button').click();await tick();assert.equal(calls,1);
    Object.defineProperty(t.document,'visibilityState',{configurable:true,value:'visible'});
    t.preview.element.querySelector('button').click();await tick();assert.equal(calls,2);
  } finally {t.preview.dispose();}
});

test('request queue limits concurrency; cancelling one preview keeps its neighbours alive',async()=>{
  const started=[],finish=[];
  const load=exerciseGifQueue({resolveGif:(sourceId,{signal})=>new Promise(resolve=>{started.push({sourceId,signal});finish.push(()=>resolve(sourceId));})});
  const owners=Array.from({length:4},()=>new AbortController());
  const results=owners.map((owner,i)=>load(String(i),{signal:owner.signal}).catch(error=>error.name));
  await tick();assert.equal(started.length,2);
  owners[0].abort();owners[2].abort();
  assert.equal(started[1].signal.aborted,false);
  finish[0]();await tick();assert.equal(started.length,3);assert.equal(started[2].sourceId,'3');
  finish[1]();finish[2]();
  assert.deepEqual(await Promise.all(results),['AbortError','1','AbortError','3']);
});

test('ExerciseDB female preview queue keeps exact source identity, credit and pause',async()=>{
 const calls=[];
 const loadGif=exerciseGifQueue({resolveGif:async(id,options)=>{calls.push({id,sourceProvider:options.sourceProvider});return `https://static.exercisedb.dev/media/${id}.gif`;}});
 const t=setup(loadGif,{row:{name:'Kéo tạ đơn (mẫu nữ)',sourceId:'Nh3mvOO',sourceProvider:'exercisedb'}});
 try{
   t.observation.enter(true);await tick();
   assert.deepEqual(calls,[{id:'Nh3mvOO',sourceProvider:'exercisedb'}]);
   const img=t.preview.element.querySelector('img');assert.equal(img.src,'https://static.exercisedb.dev/media/Nh3mvOO.gif');
   img.dispatchEvent(new t.window.Event('load'));
   assert.match(t.preview.element.textContent,/ExerciseDB/);
   assert.match(t.preview.element.querySelector('.exercise-media-status').title,/ExerciseDB/);
   assert.equal(t.preview.element.querySelector('button').textContent,'Dừng GIF');
   t.preview.pause();assert.equal(t.preview.element.querySelector('img'),null);
 }finally{t.preview.dispose();}
});

test('male and female GIFs share one recoverable matte without changing source or playback',async()=>{
 const t=setup(async id=>`https://static.exercisedb.dev/media/${id}.gif`,{row:{name:'Kéo tạ đơn (mẫu nữ)',sourceId:'Nh3mvOO'}});
 try{
   t.document.documentElement.dataset.theme='dark';
   t.observation.enter(true);await tick();
   const female=t.preview.element.querySelector('img');
   assert.equal(female.src,'https://static.exercisedb.dev/media/Nh3mvOO.gif');
   const first=t.document.getElementById(exerciseGifBackgroundId);
   assert.ok(first,'matte is installed before the image starts');
   ensureExerciseGifBackground(t.document);
   assert.equal(t.document.getElementById(exerciseGifBackgroundId),first);
   assert.equal(t.document.querySelectorAll(`#${exerciseGifBackgroundId}`).length,1);
   t.document.documentElement.dataset.theme='light';
   assert.equal(t.preview.element.querySelector('img'),female,'theme switching keeps the running GIF');
   first.closest('svg').remove();
   t.preview.pause();
   t.preview.element.querySelector('button').click();await tick();
   assert.ok(t.document.getElementById(exerciseGifBackgroundId),'next preview recovers removed definitions');
   t.preview.element.querySelector('img').dispatchEvent(new t.window.Event('load'));
   assert.equal(t.preview.element.querySelector('button').textContent,'Dừng GIF');
   assert.equal(t.preview.element.querySelector('img').src,'https://static.exercisedb.dev/media/Nh3mvOO.gif');
 }finally{t.preview.dispose();}
 const male=setup(async id=>`https://static.exercisedb.dev/media/${id}.gif`,{row:{name:'Chống đẩy',sourceId:'I4hDWkc'}});
 try{
   male.observation.enter(true);await tick();
   assert.ok(male.document.getElementById(exerciseGifBackgroundId));
   assert.equal(male.preview.element.querySelector('img').src,'https://static.exercisedb.dev/media/I4hDWkc.gif');
 }finally{male.preview.dispose();}
});

test('black canvas and edge cleanup are scoped to ExerciseDB previews in dark mode',()=>{
 const css=readFileSync(new URL('../dist/exercise-library.css',import.meta.url),'utf8');
 assert.match(css,/:root\[data-theme="dark"\] \.exercise-media-frame\{background:#000;/);
 assert.match(css,new RegExp(`:root\\[data-theme="dark"\\] \\.exercise-media-frame img\\[src\\^="https://static\\.exercisedb\\.dev/media/"\\]\\{filter:url\\(#${exerciseGifBackgroundId}\\)`));
 assert.match(css,/\.exercise-media-frame\{[^}]*background:#fff/,'light mode retains the source backdrop');
 assert.doesNotMatch(css,/mix-blend-mode|invert\(/,'anatomical and equipment colors are preserved');
});
