import {createExerciseDbClient,exerciseDbBodyLabel,exerciseDbEquipmentLabel} from './exercisedb-browser-model.mjs';
import {exerciseGifQueue,exerciseMediaPreview} from './exercise-media-preview.mjs';
import {exerciseSourceThumbnail,exerciseThumbnailQueue} from './exercise-source-thumbnail.mjs';

export function exerciseDbBrowser({h,button,onSelect,existing=()=>[],isCurrent=()=>true,mediaEnabled=false,client=createExerciseDbClient(),observer=globalThis.MutationObserver}={}) {
  let disposed=false,generation=0,controller,facetsController,timer,watcher,dialog,rows=[],next=null,page=0,total=0,loading=false;
  let cursors=[''],previews=[],thumbnails=[];
  const loadGif=exerciseGifQueue();
  const loadImage=exerciseThumbnailQueue();
  const status=h('p',{role:'status','aria-live':'polite',class:'muted'});
  const facetStatus=h('div',{'aria-live':'polite'}),results=h('div',{class:'exercise-source-results'}),detail=h('section',{class:'exercise-source-detail',hidden:true});
  const valid=()=>!disposed&&isCurrent()&&root.isConnected;
  const query=h('input',{type:'search',maxLength:120,class:'search',placeholder:'Tên bài: squat, bench press, chống đẩy…','aria-label':'Tìm trong ExerciseDB',onInput:()=>change(true),onKeydown:e=>{if(e.key==='Enter'){e.preventDefault();change(false);}}});
  const body=h('select',{'aria-label':'Nhóm cơ ExerciseDB',onChange:()=>change(false)},h('option',{value:''},'Tất cả nhóm cơ'));
  const equipment=h('select',{'aria-label':'Dụng cụ ExerciseDB',onChange:()=>change(false)},h('option',{value:''},'Tất cả dụng cụ'));
  const prev=button('Trang trước',()=>{if(!loading&&page>0){page--;void load();}}),forward=button('Trang sau',()=>{if(!loading&&next){cursors[++page]=next;void load();}});
  const pageLabel=h('span',{class:'muted'});
  const pager=h('nav',{class:'exercise-source-pager','aria-label':'Phân trang ExerciseDB'},prev,pageLabel,forward);
  const root=h('section',{class:'exercise-source-browser'},
    h('p',{class:'notice'},'Chọn bài từ kho ExerciseDB, xem minh họa rồi biên tập nội dung tiếng Việt trước khi lưu. GIF miễn phí chỉ dùng trong bản kiểm thử.'),
    h('div',{class:'toolbar exercise-source-toolbar'},query,body,equipment,button('Tìm kiếm',()=>change(false))),
    h('p',{class:'muted'},'Tên gốc từ nguồn bằng tiếng Anh. Một số từ phổ biến như “chống đẩy”, “gập bụng” cũng được hỗ trợ.'),facetStatus,status,results,pager,detail);
  function dropMedia(){for(const preview of previews)preview.dispose();previews=[];}
  function dropThumbnails(){for(const thumbnail of thumbnails)thumbnail.dispose();thumbnails=[];}
  function clearDetail(){dropMedia();detail.hidden=true;detail.replaceChildren();}
  function updatePager(){prev.disabled=loading||page===0;forward.disabled=loading||!next;pageLabel.textContent=`Trang ${page+1}${total?` · ${total.toLocaleString('vi-VN')} bài phù hợp`:''}`;}
  function change(debounce) {
    clearTimeout(timer);controller?.abort();generation++;page=0;cursors=[''];next=null;rows=[];total=0;clearDetail();dropThumbnails();results.replaceChildren();status.textContent='Đang tìm bài tập…';status.className='loading';updatePager();
    if(debounce)timer=setTimeout(()=>{if(valid())void load();},350);else void load();
  }
  async function load() {
    if(!valid())return;
    clearTimeout(timer);controller?.abort();controller=new AbortController();const signal=controller.signal,token=++generation;
    loading=true;next=null;rows=[];clearDetail();dropThumbnails();results.replaceChildren();status.className='loading';status.textContent='Đang tải trực tiếp từ ExerciseDB…';updatePager();
    try {
      const result=await client.page({query:query.value,bodyPart:body.value,equipment:equipment.value,after:cursors[page],signal});
      if(!valid()||signal.aborted||token!==generation)return;
      rows=result.rows;next=result.next;total=result.total;loading=false;status.className='muted';
      status.textContent=rows.length?`${total.toLocaleString('vi-VN')} bài phù hợp · đang hiện ${rows.length} bài. Chọn một bài để xem GIF và hướng dẫn.`:'Không có bài phù hợp. Hãy đổi từ khóa hoặc bộ lọc.';
      results.replaceChildren(...rows.map(row=>{
        const found=existing().find(e=>e.sourceId===row.sourceId);
        const thumbnail=exerciseSourceThumbnail({h,button,row,loadImage,isCurrent:valid,enabled:mediaEnabled,onOpen:()=>showDetail(row)});thumbnails.push(thumbnail);
        const action=button('Xem GIF và hướng dẫn',()=>showDetail(row));action.classList.add('exercise-source-action');
        return h('article',{class:'exercise-source-row'},thumbnail.element,h('div',{class:'exercise-source-info'},h('h3',{},row.name),h('p',{class:'muted'},`${row.bodyParts.map(exerciseDbBodyLabel).join(', ')} · ${row.equipments.map(exerciseDbEquipmentLabel).join(', ')}`),h('small',{},row.targetMuscles.join(', ')),...(found?[h('span',{class:'exercise-source-badge'},found.isActive===false?'Đã có · đang ẩn':'Đã có trong HealthMate')]:[])),action);
      }));for(const thumbnail of thumbnails)thumbnail.mount();updatePager();
    } catch(error) {
      if(!valid()||signal.aborted||token!==generation)return;
      loading=false;status.className='error';status.textContent=error.message||'Không tải được kho bài tập.';
      results.replaceChildren(button('Thử tải lại kho',()=>void load()));updatePager();
    }
  }
  function showDetail(row) {
    if(!valid()||loading||!rows.includes(row))return;
    clearDetail();detail.hidden=false;
    const found=existing().find(e=>e.sourceId===row.sourceId);
    const select=button(found?'Mở bài đã có trong HealthMate':'Thêm vào HealthMate',()=>{if(valid()&&!select.disabled){const selected={...row};dispose();onSelect(selected);}});
    // A missing CDN file must not silently become a new broken illustration.
    select.disabled=mediaEnabled&&!found;
    let media;
    if(mediaEnabled) {
      const preview=exerciseMediaPreview({h,button,row,loadGif,isCurrent:valid,onReady:()=>{select.disabled=false;}});previews.push(preview);media=preview.element;
    } else media=h('p',{class:'notice'},'GIF miễn phí chưa được bật trong môi trường này. Bạn vẫn có thể đọc hướng dẫn và chọn bài.');
    detail.replaceChildren(h('div',{class:'exercise-source-detail-head'},h('h3',{},row.name),button('Đóng chi tiết',clearDetail)),
      h('div',{class:'exercise-source-detail-body'},media,h('div',{},h('p',{},`Nhóm cơ: ${row.bodyParts.map(exerciseDbBodyLabel).join(', ')}`),h('p',{},`Dụng cụ: ${row.equipments.map(exerciseDbEquipmentLabel).join(', ')}`),h('p',{},`Cơ tác động (nguồn): ${row.targetMuscles.join(', ')}`),h('h4',{},'Hướng dẫn gốc từ ExerciseDB'),h('ol',{},...row.instructions.map(step=>h('li',{},step))),h('p',{class:'muted'},'Nội dung gốc dùng để tham khảo. Bạn sẽ nhập bản tiếng Việt trong bước tiếp theo.'))),
      ...(found?[h('p',{class:'notice'},`Bài đã có tên “${found.name}”. Mở bài hiện có để chỉnh sửa hoặc khôi phục, tránh thêm trùng.`)]:mediaEnabled?[h('p',{class:'muted'},'GIF cần tải thành công trước khi thêm. Nếu nguồn báo lỗi, chọn bài khác hoặc thử tải lại.')]:[]),select);
    detail.scrollIntoView?.({block:'nearest',behavior:'smooth'});
    if(mediaEnabled)void previews[0].start();
  }
  async function loadFacets() {
    facetsController?.abort();facetsController=new AbortController();const signal=facetsController.signal;
    facetStatus.textContent='Đang tải bộ lọc…';
    try {
      const facets=await client.facets({signal});
      if(!valid()||signal.aborted)return;
      for(const [select,choices,label,title] of [[body,facets.bodyParts,exerciseDbBodyLabel,'Tất cả nhóm cơ'],[equipment,facets.equipments,exerciseDbEquipmentLabel,'Tất cả dụng cụ']]) {
        const previous=select.value;
        select.replaceChildren(h('option',{value:''},title),...choices.map(value=>h('option',{value},label(value))));select.value=previous;
      }
      facetStatus.replaceChildren();
    } catch(error) {if(valid()&&!signal.aborted)facetStatus.replaceChildren(h('span',{class:'error'},'Chưa tải được bộ lọc. Tìm bằng tên vẫn dùng được. '),button('Thử tải lại bộ lọc',()=>void loadFacets()));}
  }
  function dispose() {
    if(disposed)return;disposed=true;generation++;controller?.abort();facetsController?.abort();clearTimeout(timer);dropMedia();dropThumbnails();rows=[];detail.replaceChildren();results.replaceChildren();watcher?.disconnect();dialog?.removeEventListener('close',dispose);dialog?.classList.remove('exercise-source-dialog');
  }
  return {element:root,dispose,start(){
    if(!valid())return;dialog=root.closest('dialog');dialog?.classList.add('exercise-source-dialog');dialog?.addEventListener('close',dispose,{once:true});
    if(dialog&&typeof observer==='function'){watcher=new observer(()=>{if(!root.isConnected||!dialog.hasAttribute('open'))dispose();});watcher.observe(dialog,{attributes:true,childList:true,subtree:true});}
    void loadFacets();void load();
  }};
}
