import {freshExerciseGif,exerciseSource,exerciseMediaCredit} from './exercise-library-model.mjs';
import {ensureExerciseGifBackground} from './exercise-gif-background.mjs';

// Metadata requests share a small queue. Each mounted preview owns its abort
// signal, so removing one row never cancels a neighbouring illustration.
export function exerciseGifQueue({resolveGif=freshExerciseGif,concurrency=2}={}) {
  let active=0;
  const pending=[];
  function drain() {
    while(active<concurrency&&pending.length) {
      const task=pending.shift();
      if(task.signal.aborted)continue;
      active++;
      Promise.resolve().then(()=>resolveGif(task.sourceId,{signal:task.signal,sourceProvider:task.sourceProvider}))
        .then(task.resolve,task.reject).finally(()=>{task.cleanup();active--;drain();});
    }
  }
  return (sourceId,{signal,sourceProvider})=>new Promise((resolve,reject)=>{
    const abort=()=>reject(new DOMException('Preview disposed','AbortError'));
    if(signal.aborted){abort();return;}
    const task={sourceId,sourceProvider,signal,resolve,reject,cleanup:()=>signal.removeEventListener('abort',abort)};
    signal.addEventListener('abort',abort,{once:true});
    pending.push(task);drain();
  });
}

export function exerciseMediaPreview({h,button,row,loadGif=freshExerciseGif,
  automatic=false,isCurrent=()=>true,observer=globalThis.IntersectionObserver,onReady=()=>{}}={}) {
  let controller,timeout,intersection,disposed=false,paused=false,phase='idle';
  const frame=h('div',{class:'exercise-media-frame'});
  const status=h('span',{class:'exercise-media-status'},'GIF · 180p');
  const control=button('Xem GIF',()=>phase==='playing'||phase==='loading'?pause():start());
  control.classList.add('exercise-media-control');
  const root=h('div',{class:`exercise-media${automatic?' compact':''}`,'aria-label':`Minh họa ${row.name}`},frame,status,control);
  function clear() {
    controller?.abort();controller=undefined;
    clearTimeout(timeout);frame.replaceChildren();
  }
  function idle(message='GIF · 180p') {
    clear();phase='idle';status.textContent=message;control.textContent='Xem GIF';
    frame.replaceChildren(h('span',{class:'exercise-media-placeholder','aria-hidden':'true'},'GIF'));
  }
  function pause() {paused=true;idle('Đã dừng');}
  function fail(message) {
    clear();phase='error';status.textContent=message;control.textContent='Thử lại GIF';
    frame.replaceChildren(h('span',{class:'exercise-media-placeholder','aria-hidden':'true'},'GIF'));
  }
  async function start() {
    if(disposed||!isCurrent()||!root.isConnected||root.ownerDocument.visibilityState==='hidden'||['loading','playing'].includes(phase))return;
    clear();paused=false;phase='loading';status.textContent='Đang tải GIF…';control.textContent='Dừng tải';
    controller=new AbortController();const request=controller;
    const valid=()=>!disposed&&!request.signal.aborted&&isCurrent()&&root.isConnected;
    timeout=setTimeout(()=>{if(valid())fail('Tải quá lâu. Hãy thử lại.');},15000);
    try {
      const url=await loadGif(row.sourceId,{signal:request.signal,sourceProvider:exerciseSource(row)});
      if(!valid())return;
      ensureExerciseGifBackground(root.ownerDocument);
      const img=h('img',{alt:`Minh họa ${row.name}`,width:180,height:180,decoding:'async',referrerPolicy:'no-referrer',
        onLoad:()=>{if(valid()){clearTimeout(timeout);phase='playing';status.textContent='ExerciseDB · 180p';status.title=exerciseMediaCredit(row);control.textContent='Dừng GIF';onReady();}},
        onError:()=>{if(valid())fail('Chưa tải được GIF. Hãy thử lại.');}});
      frame.replaceChildren(img);img.src=url;
    } catch(error) {if(valid())fail(error.message||'Chưa tải được GIF. Hãy thử lại.');}
  }
  idle();
  if(automatic&&typeof observer==='function') {
    intersection=new observer(entries=>{
      for(const entry of entries)if(entry.target===root) {
        if(entry.isIntersecting){if(!paused&&phase==='idle')void start();}
        else if(phase==='loading'||phase==='playing')idle();
      }
    },{rootMargin:'0px',threshold:0.1});
    intersection.observe(root);
  }
  const background=()=>{if(root.ownerDocument.visibilityState==='hidden')idle('Đã dừng khi chuyển tab');};
  root.ownerDocument.addEventListener('visibilitychange',background);
  return {element:root,start,pause,dispose(){disposed=true;clear();intersection?.disconnect();root.ownerDocument.removeEventListener('visibilitychange',background);}};
}
