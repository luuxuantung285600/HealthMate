import {freshExerciseGif,exerciseSource} from './exercise-library-model.mjs';
import {exerciseGifQueue} from './exercise-media-preview.mjs';
import {ensureExerciseGifBackground} from './exercise-gif-background.mjs';

const imageCleanup=new WeakMap();
function release(image) {
  imageCleanup.get(image)?.();imageCleanup.delete(image);
  image.onload=null;image.onerror=null;image.removeAttribute('src');
}

// Limit both metadata and image loading, not just the metadata request. GIFs
// are drawn once, then their image decoders are released. No readback/export,
// proxy, object URL, source file or persistent thumbnail cache is needed.
export function exerciseThumbnailQueue({resolveGif=freshExerciseGif,createImage=()=>new Image(),concurrency=2,timeoutMs=15000}={}) {
  return exerciseGifQueue({concurrency,resolveGif:async(sourceId,{signal,sourceProvider})=>{
    const url=await resolveGif(sourceId,{signal,sourceProvider});
    if(signal.aborted)throw new DOMException('Cancelled','AbortError');
    return new Promise((resolve,reject)=>{
      const image=createImage();
      const cleanup=()=>{clearTimeout(timer);signal.removeEventListener('abort',abort);};
      const fail=error=>{cleanup();release(image);reject(error);};
      const abort=()=>fail(new DOMException('Cancelled','AbortError'));
      const timer=setTimeout(()=>fail(Error('Tải ảnh quá lâu. Hãy thử lại.')),timeoutMs);
      signal.addEventListener('abort',abort,{once:true});
      imageCleanup.set(image,cleanup);
      image.onload=()=>{clearTimeout(timer);image.onload=null;image.onerror=null;resolve(image);};
      image.onerror=()=>fail(Error('Chưa tải được ảnh bài tập.'));
      image.referrerPolicy='no-referrer';image.decoding='async';
      image.src=url;
    });
  }});
}

export function exerciseSourceThumbnail({h,button,row,onOpen,loadImage,isCurrent=()=>true,observer=globalThis.IntersectionObserver,enabled=true,paint=(canvas,image)=>{
  const context=canvas.getContext('2d');
  if(!context)throw Error('Trình duyệt chưa hỗ trợ ảnh xem trước.');
  context.drawImage(image,0,0,canvas.width,canvas.height);
}}={}) {
  let controller,intersection,timeout,disposed=false,visible=false,phase='idle';
  const canvas=h('canvas',{width:180,height:180,class:'exercise-source-thumb-image','data-source-id':row.sourceId,'aria-hidden':'true'});
  const frame=button('',()=>{if(!disposed&&isCurrent())onOpen();});
  frame.classList.add('exercise-source-thumb-frame');frame.setAttribute('aria-label',`Xem GIF của ${row.name}`);
  const label=h('span',{class:'exercise-source-thumb-label'},enabled?'Ảnh xem trước':'GIF kiểm thử');
  const retry=button('Thử tải ảnh',()=>void start());retry.hidden=true;
  const root=h('div',{class:'exercise-source-thumbnail'},frame,label,retry);
  const valid=()=>!disposed&&isCurrent()&&root.isConnected;
  function idle(message='Ảnh xem trước') {
    clearTimeout(timeout);controller?.abort();controller=null;phase='idle';label.textContent=message;
    frame.replaceChildren(h('span',{'aria-hidden':'true'},'GIF'));retry.hidden=true;
  }
  async function start() {
    if(!enabled||!valid()||root.ownerDocument.visibilityState==='hidden'||phase==='loading'||phase==='ready')return;
    controller?.abort();controller=new AbortController();const request=controller;
    phase='loading';label.textContent='Đang tải ảnh…';retry.hidden=true;
    timeout=setTimeout(()=>{if(valid()&&!request.signal.aborted){request.abort();phase='error';label.textContent='Ảnh tải quá lâu';retry.hidden=false;}},20000);
    try {
      const image=await loadImage(row.sourceId,{signal:request.signal,sourceProvider:exerciseSource(row)});
      try {
        if(!valid()||request.signal.aborted)return;
        ensureExerciseGifBackground(root.ownerDocument);
        clearTimeout(timeout);paint(canvas,image);frame.replaceChildren(canvas);phase='ready';label.textContent='Xem GIF';
      } finally {release(image);}
    } catch(error) {
      if(!valid()||request.signal.aborted)return;
      clearTimeout(timeout);
      phase='error';label.textContent='Chưa có ảnh';label.title=error.message;retry.hidden=false;
    }
  }
  idle(enabled?'Ảnh xem trước':'GIF kiểm thử');
  const background=()=>{
    if(root.ownerDocument.visibilityState==='hidden'&&phase==='loading')idle();
    else if(visible&&phase==='idle')void start();
  };
  root.ownerDocument.addEventListener('visibilitychange',background);
  return {element:root,start,mount(){
    if(enabled&&typeof observer==='function') {
      intersection=new observer(entries=>{
        for(const entry of entries)if(entry.target===root){
          visible=entry.isIntersecting;
          if(visible&&phase==='idle')void start();
          else if(!visible&&phase==='loading')idle();
        }
      },{root:root.closest('.exercise-source-results'),rootMargin:'0px',threshold:.1});
      intersection.observe(root);
    }
    else if(enabled){visible=true;void start();}
  },dispose(){
    disposed=true;clearTimeout(timeout);controller?.abort();intersection?.disconnect();
    root.ownerDocument.removeEventListener('visibilitychange',background);
    // Drop the current page's transient raster surface too.
    canvas.width=0;canvas.height=0;frame.replaceChildren();
  }};
}
