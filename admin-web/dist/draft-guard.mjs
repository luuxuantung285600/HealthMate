// Drafts stay in memory only. No customer content is written to browser storage.
export function createDraftGuard({window,document,h,button}) {
  const drafts=new Map();let pending;
  const dirty=keys=>[...drafts].some(([key,check])=>(!keys||keys.includes(key))&&check());
  window.addEventListener('beforeunload',event=>{if(dirty()){event.preventDefault();event.returnValue='';}});
  return {
    set(key,check){drafts.set(key,check);},clear(key){drafts.delete(key);},
    reset(){drafts.clear();pending?.finish(false);},
    allow(keys){
      if(!dirty(keys))return Promise.resolve(true);
      if(pending)return pending.promise;
      const previous=document.activeElement,modal=h('dialog',{id:'discard-dialog','aria-labelledby':'discard-title'});
      let finish;
      const promise=new Promise(resolve=>{finish=confirmed=>{modal.close();modal.remove();pending=null;if(previous?.isConnected)previous.focus();resolve(confirmed);};});
      modal.append(h('div',{class:'discard-content'},h('h2',{id:'discard-title'},'Bỏ thay đổi chưa lưu?'),h('p',{},'Nội dung chưa lưu sẽ bị mất khi bạn rời màn hình này.'),h('div',{class:'dialog-foot'},button('Ở lại',()=>finish(false)),button('Bỏ thay đổi',()=>finish(true),'danger'))));
      modal.addEventListener('cancel',event=>{event.preventDefault();finish(false);});
      pending={promise,finish};document.body.append(modal);modal.showModal();modal.querySelector('button').focus();
      return promise;
    },
  };
}

export function routePage(hash,pages){const key=String(hash??'').replace(/^#\/?/,'');return Object.hasOwn(pages,key)?key:'overview';}
