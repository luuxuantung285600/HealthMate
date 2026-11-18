import test from 'node:test';
import assert from 'node:assert/strict';
import {parseHTML} from 'linkedom';
import {exerciseSourceThumbnail,exerciseThumbnailQueue} from '../dist/exercise-source-thumbnail.mjs';

const tick=async()=>{for(let i=0;i<4;i++)await new Promise(resolve=>setImmediate(resolve));};
const image=()=>({onload:null,onerror:null,src:'source.gif',removeAttribute(key){delete this[key];}});
function setup(loadImage,{enabled=true,paint=()=>{},observerEnabled=true}={}) {
 const {document,window}=parseHTML('<html><body><div class="exercise-source-results"></div></body></html>');
 const h=(tag,props={},...children)=>{const node=document.createElement(tag);for(const [key,value] of Object.entries(props)){if(key.startsWith('on'))node.addEventListener(key.slice(2).toLowerCase(),value);else node.setAttribute(key,String(value));}node.append(...children);return node;};
 const button=(label,action)=>h('button',{type:'button',onClick:action},label);
 let observation,opened=0;
 class Observer {
  constructor(callback,options){this.callback=callback;this.options=options;observation=this;}
  observe(target){assert.equal(target.isConnected,true);this.target=target;}
  disconnect(){this.disconnected=true;}
  enter(visible){this.callback([{target:this.target,isIntersecting:visible}]);}
 }
 const thumbnail=exerciseSourceThumbnail({h,button,row:{name:'Push up',sourceId:'Ab12345'},loadImage,enabled,paint,observer:observerEnabled?Observer:null,onOpen:()=>opened++});
 document.querySelector('.exercise-source-results').append(thumbnail.element);thumbnail.mount();
 return {thumbnail,document,window,get observation(){return observation;},get opened(){return opened;},visibility(value){Object.defineProperty(document,'visibilityState',{configurable:true,value});document.dispatchEvent(new window.Event('visibilitychange'));}};
}

test('visible cards draw once, release the GIF source and open playback only on click',async()=>{
 let calls=0,painted=0;const img=image();
 const t=setup(async()=>{calls++;return img;},{paint:(canvas,source)=>{painted++;assert.equal(source,img);assert.equal(canvas.getAttribute('width'),'180');}});
 try {
  assert.equal(calls,0);assert.equal(t.observation.options.root,t.document.querySelector('.exercise-source-results'));
  t.observation.enter(true);await tick();assert.equal(calls,1);assert.equal(painted,1);
  assert.equal(img.src,undefined);assert.equal(img.onload,null);assert.equal(img.onerror,null);
  assert.equal(t.thumbnail.element.querySelectorAll('canvas').length,1);assert.equal(t.thumbnail.element.querySelector('img'),null);
  t.observation.enter(false);t.observation.enter(true);await tick();assert.equal(painted,1);assert.equal(calls,1);
  assert.equal(t.opened,0);t.thumbnail.element.querySelector('.exercise-source-thumb-frame').click();assert.equal(t.opened,1);
 }finally{t.thumbnail.dispose();}
 assert.equal(t.observation.disconnected,true);assert.equal(t.thumbnail.element.querySelector('canvas'),null);
});

test('free media gate disables thumbnail requests and observers',async()=>{
 let calls=0;const t=setup(async()=>{calls++;return image();},{enabled:false});
 try{await t.thumbnail.start();await tick();assert.equal(calls,0);assert.equal(t.observation,undefined);assert.match(t.thumbnail.element.textContent,/GIF kiểm thử/);}finally{t.thumbnail.dispose();}
});

test('scrolling out and closing cancel pending work; late results cannot paint or retain source',async()=>{
 const requests=[];let painted=0;const t=setup((_id,{signal})=>new Promise(resolve=>requests.push({signal,resolve})),{paint:()=>painted++});
 t.observation.enter(true);t.observation.enter(false);assert.equal(requests[0].signal.aborted,true);
 const late=image();requests[0].resolve(late);await tick();assert.equal(painted,0);assert.equal(late.src,undefined);
 t.observation.enter(true);assert.equal(requests.length,2);t.thumbnail.dispose();assert.equal(requests[1].signal.aborted,true);
 const closed=image();requests[1].resolve(closed);await tick();assert.equal(painted,0);assert.equal(closed.src,undefined);
});

test('failed thumbnail offers retry independently from detail playback',async()=>{
 let calls=0;const t=setup(async()=>{if(++calls===1)throw Error('offline');return image();});
 try {
  t.observation.enter(true);await tick();assert.match(t.thumbnail.element.textContent,/Chưa có ảnh/);
  const retry=[...t.thumbnail.element.querySelectorAll('button')].find(n=>n.textContent==='Thử tải ảnh');assert.equal(retry.hidden,false);
  retry.click();await tick();assert.equal(calls,2);assert.equal(retry.hidden,true);assert.ok(t.thumbnail.element.querySelector('canvas'));
 }finally{t.thumbnail.dispose();}
});

test('hidden tabs cancel decoding and resume visible cards, including observer fallback',async()=>{
 const requests=[];const t=setup((_id,{signal})=>new Promise(resolve=>requests.push({signal,resolve})),{observerEnabled:false});
 try {
  assert.equal(requests.length,1);t.visibility('hidden');assert.equal(requests[0].signal.aborted,true);
  t.visibility('visible');assert.equal(requests.length,2);requests[0].resolve(image());requests[1].resolve(image());await tick();
  assert.ok(t.thumbnail.element.querySelector('canvas'));t.visibility('hidden');t.visibility('visible');await tick();assert.equal(requests.length,2,'finished rasters survive tab changes');
 }finally{t.thumbnail.dispose();}
});

test('image queue bounds decoding as well as metadata; cancelled queued cards do not fetch',async()=>{
 const started=[],images=[];
 const load=exerciseThumbnailQueue({resolveGif:async(id)=>{started.push(id);return `https://static.exercisedb.dev/media/${id}.gif`;},createImage:()=>{const img=image();images.push(img);return img;}});
 const owners=Array.from({length:4},()=>new AbortController());
 const results=owners.map((owner,i)=>load(String(i),{signal:owner.signal}).catch(error=>error.name));
 await tick();assert.deepEqual(started,['0','1']);assert.equal(images.length,2);
 owners[2].abort();images[0].onload();await tick();assert.deepEqual(started,['0','1','3']);
 images[1].onload();images[2].onload();const values=await Promise.all(results);assert.equal(values[2],'AbortError');
 // A caller aborting after resolution also releases the source decoder.
 owners[0].abort();assert.equal(images[0].src,undefined);assert.equal(images[1].src.endsWith('/1.gif'),true);
 owners[1].abort();owners[3].abort();assert.equal(images[1].src,undefined);assert.equal(images[2].src,undefined);
});

test('image errors and timeout release sources and allow the queue to continue',async()=>{
 const images=[];const load=exerciseThumbnailQueue({concurrency:1,timeoutMs:15,resolveGif:async id=>'https://static.exercisedb.dev/media/'+id+'.gif',createImage:()=>{const img=image();images.push(img);return img;}});
 const first=load('Ab12345',{signal:new AbortController().signal}).catch(error=>error.message);
 const second=load('Cd23456',{signal:new AbortController().signal}).catch(error=>error.message);
 await tick();images[0].onerror();assert.match(await first,/Chưa tải/);assert.equal(images[0].src,undefined);
 assert.match(await second,/quá lâu/);assert.equal(images[1].src,undefined);
});
