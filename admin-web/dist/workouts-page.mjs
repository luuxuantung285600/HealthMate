import {downloadReport} from './report-download.mjs';
import {normalizeSearch} from './list-model.mjs';
import {bundledExerciseLibrary} from './bundled-exercise-library.mjs';
import {exerciseId,exercisePayload,mergeExerciseLibrary,exerciseRegions,exerciseEquipment,exerciseSource,exerciseMediaCredit,freshExerciseGif} from './exercise-library-model.mjs';
import {entityVersion,text} from './validation.mjs';
import {exerciseGifQueue,exerciseMediaPreview} from './exercise-media-preview.mjs';
import {ensureExerciseGifBackground} from './exercise-gif-background.mjs';
import {exerciseDbBrowser} from './exercisedb-browser.mjs';
import {exerciseDbDraft,exerciseDbBodyLabel,exerciseDbEquipmentLabel} from './exercisedb-browser-model.mjs';
export function workoutsPage({host,api,h,button,isCurrent=()=>true,onDispose,openEditor,field,checkbox,values}){
  let rows=[],ready=false,search='',region='',equipment='',visibility='',stop,previewController,previewHost,previewObserver,sourceBrowser;
  const inlinePreviews=new Set(),loadGif=exerciseGifQueue();
  const dropInline=()=>{for(const preview of inlinePreviews)preview.dispose();inlinePreviews.clear();};
  const dropPreview=()=>{previewController?.abort();previewHost?.replaceChildren();previewObserver?.disconnect();};
  const background=()=>{if(host.ownerDocument.visibilityState==='hidden')dropPreview();};
  host.ownerDocument.addEventListener('visibilitychange',background);
  const status=h('p',{'aria-live':'polite'}),table=h('div'),toolbar=h('div',{class:'toolbar exercise-toolbar'});
  const queryInput=h('input',{type:'search',class:'search',placeholder:'Tìm bài tập…','aria-label':'Tìm bài tập',value:search,onInput:e=>{search=e.target.value;render();}});
  const mediaEnabled=api.freeExerciseMediaEnabled===true||(api.freeExerciseMediaEnabled==null&&api.emulator===true);
  const filterSelect=(label,choices,change)=>h('select',{'aria-label':label,onChange:e=>{change(e.target.value);render();}},h('option',{value:''},label),...Object.entries(choices).map(([value,label])=>h('option',{value},label)));
  const regionInput=filterSelect('Tất cả nhóm cơ',exerciseRegions,value=>region=value),equipmentInput=filterSelect('Tất cả dụng cụ',exerciseEquipment,value=>equipment=value);
  const visibilityInput=filterSelect('Tất cả trạng thái',{active:'Đang hiển thị',archived:'Đã ẩn'},value=>visibility=value);
  const current=()=>isCurrent();
  const error=e=>{ready=false;status.className='error';status.textContent=e.message;render();};
  const selector=(key,label,choices,value)=>h('label',{class:'field'},label,h('select',{name:key},...(!value?[h('option',{value:'',selected:true},'Chọn phân loại phù hợp')]:[]),...Object.entries(choices).map(([v,l])=>h('option',{value:v,selected:v===value},l))));
  function browseSource(){if(!ready||!current())return;sourceBrowser?.dispose();dropPreview();
    sourceBrowser=exerciseDbBrowser({h,button,mediaEnabled,isCurrent:current,existing:()=>rows,onSelect:source=>{
      const found=rows.find(row=>row.sourceId===source.sourceId);
      edit(found,{source:found?null:source});
    }});
    openEditor('Thêm từ ExerciseDB',[sourceBrowser.element]);sourceBrowser.start();
  }
  function edit(row,{source=null}={}){if(!ready||!current())return;const data=row??(source?exerciseDbDraft(source):{region:'chest',equipment:'bodyweight',steps:[],isActive:true});
    openEditor(row?'Chỉnh sửa bài tập':'Thêm bài tập',[
      ...(source?[
        h('section',{class:'exercise-source-reference'},h('h3',{},source.name),h('p',{},`${source.bodyParts.map(exerciseDbBodyLabel).join(', ')} · ${source.equipments.map(exerciseDbEquipmentLabel).join(', ')} · ${source.targetMuscles.join(', ')}`),h('details',{},h('summary',{},'Xem hướng dẫn gốc để biên tập tiếng Việt'),h('ol',{},...source.instructions.map(step=>h('li',{},step))))),
        h('p',{class:'notice'},'Đã chọn GIF và mã nguồn tự động. Nhập tên, cơ tác động, hướng dẫn và biến thể dễ hơn bằng tiếng Việt trước khi lưu. Các phân loại chưa khớp cần được chọn lại. Nội dung gốc không được tự động lưu vào app.'),
      ]:[]),
      field('id','Mã bài tập',data.id??'',{readonly:!!row||!!source,max:100}),field('name','Tên tiếng Việt',data.name,{max:120}),
      field('sourceId',source?'Nguồn GIF đã chọn (tự động)':'Mã ExerciseDB (7 ký tự)',data.sourceId,{max:7,readonly:!!source}),
      selector('region','Nhóm cơ',exerciseRegions,data.region),selector('equipment','Dụng cụ',exerciseEquipment,data.equipment),field('target','Cơ tác động',data.target,{max:160}),
      field('steps','Hướng dẫn: mỗi bước một dòng',(data.steps??[]).join('\n'),{type:'textarea',max:2405}),field('easier','Biến thể dễ hơn',data.easier,{type:'textarea',max:400}),checkbox('isActive','Hiển thị trong app',data.isActive!==false),
    ],async form=>{if(!ready||!current())throw Error('Chờ kết nối máy chủ rồi thử lại.');const input=values(form);
      if(source&&(input.id!==data.id||input.sourceId!==data.sourceId))throw Error('Mã nguồn đã chọn bị thay đổi. Hãy chọn lại bài từ ExerciseDB.');
      if((!row||row.sourceId!==input.sourceId)&&rows.some(existing=>existing.sourceId===input.sourceId&&existing.id!==input.id))throw Error('GIF này đã có trong HealthMate. Mở bài hiện có để chỉnh sửa hoặc khôi phục.');
      if(source&&rows.some(existing=>existing.id===input.id))throw Error('Bài vừa được thêm từ một phiên khác. Đóng form và mở bài hiện có để chỉnh sửa.');
      await api.save('exercise_library',exerciseId(input.id),exercisePayload({...input,...(source?{sourceProvider:'exercisedb'}:{})}),text(input.reason,'Lý do',200),row?.remote?entityVersion(row):null);});
  }
  function archive(row){if(!ready||!current())return;const restore=row.isActive===false;openEditor(restore?'Khôi phục bài tập?':'Xóa bài tập khỏi thư viện?',[
    h('h3',{},row.name),h('p',{class:'notice'},'Thay đổi đồng bộ vào app. Nhật ký đã ghi vẫn được giữ; bài tập bị xóa khỏi thư viện có thể khôi phục.'),
  ],async form=>{if(!ready||!current())throw Error('Chờ kết nối máy chủ rồi thử lại.');await api.save('exercise_library',row.id,{...exercisePayload(row),isActive:restore},text(values(form).reason,'Lý do',200),row.remote?entityVersion(row):null);});}
  function preview(row){if(!ready||!current())return;dropPreview();previewController=new AbortController();const signal=previewController.signal,imgHost=h('div'),message=h('p',{'aria-live':'polite'});
    previewHost=imgHost;
    openEditor('Minh họa động tác',[
      h('h3',{},row.name),h('p',{},`${exerciseRegions[row.region]} · ${exerciseEquipment[row.equipment]} · ${row.target}`),h('ol',{},...row.steps.map(step=>h('li',{},step))),h('p',{},`Dễ hơn: ${row.easier}`),
      h('p',{class:'notice'},`${exerciseMediaCredit(row)}. Chỉ dùng thử nghiệm phi thương mại. Tải theo yêu cầu, không lưu URL vào dữ liệu.`),
      h('a',{href:'https://www.exercisedb.dev/',target:'_blank',rel:'noopener noreferrer'},'Nguồn và giấy phép minh họa'),
      ...(mediaEnabled?[button('Tải GIF minh họa',async()=>{if(!mediaEnabled)return;message.textContent='Đang tải…';imgHost.replaceChildren();try{const url=await freshExerciseGif(row.sourceId,{signal,sourceProvider:exerciseSource(row)});if(!signal.aborted&&current()&&imgHost.isConnected){ensureExerciseGifBackground(imgHost.ownerDocument);imgHost.replaceChildren(h('img',{src:url,alt:`Minh họa ${row.name}`,referrerPolicy:'no-referrer',width:320,height:320,class:'exercise-detail-image',onError:()=>{imgHost.replaceChildren();message.textContent='Minh họa không tải được. Hãy tải lại.';}}));message.textContent=exerciseMediaCredit(row);}}catch(e){if(!signal.aborted&&current())message.textContent=e.message;}})]:[h('p',{class:'notice'},'Minh họa miễn phí chỉ bật trong môi trường thử nghiệm local phi thương mại. Bản triển khai này không tải GIF. Khi thử nghiệm phi thương mại trên localhost với Firebase thật, đặt enableFreeExerciseMedia: true trong config.js; không bật cho bản phát hành.')]),message,imgHost,
    ]);
    const dialog=imgHost.closest('dialog');
    if(dialog){dialog.addEventListener('close',dropPreview,{once:true});if(typeof MutationObserver!=='undefined'){previewObserver=new MutationObserver(()=>{if(!imgHost.isConnected||!dialog.hasAttribute('open'))dropPreview();});previewObserver.observe(dialog,{attributes:true,childList:true,subtree:true});}}
  }
  function exerciseName(row){
    const label=h('div',{},h('strong',{},row.name),h('small',{},row.id));
    if(!mediaEnabled)return label;
    const preview=exerciseMediaPreview({h,button,row,loadGif,automatic:true,isCurrent:current});
    inlinePreviews.add(preview);
    return h('div',{class:'exercise-name'},preview.element,label);
  }
  function render(){if(!current())return;dropInline();const selected=rows.filter(r=>(!region||r.region===region)&&(!equipment||r.equipment===equipment)&&(!visibility||(visibility==='active'?r.isActive:r.isActive===false))&&normalizeSearch(`${r.id} ${r.name} ${r.target}`).includes(normalizeSearch(search)));
    const focused=host.ownerDocument.activeElement===queryInput;
    toolbar.replaceChildren(queryInput,regionInput,equipmentInput,visibilityInput,h('button',{type:'button',class:'button',disabled:!ready,onClick:browseSource},'Thêm từ ExerciseDB'),h('button',{type:'button',class:'button secondary',disabled:!ready,onClick:()=>edit()},'Thêm bài tập'),button('Thử tải lại',load),...(ready?[button('Xuất danh mục đang lọc',()=>{downloadReport({workbook:{name:'Thư viện bài tập',headers:['Mã','Tên','Nhóm cơ','Dụng cụ','Nguồn','Mã nguồn','Trạng thái'],rows:selected.map(r=>[r.id,r.name,exerciseRegions[r.region],exerciseEquipment[r.equipment],'ExerciseDB',r.sourceId,r.isActive?'Hiển thị':'Đã ẩn']),metadata:[['Nguồn','HealthMate + AscendAPI / ExerciseDB'],['Từ khóa',search||'Tất cả'],['Nhóm cơ',exerciseRegions[region]??'Tất cả'],['Dụng cụ',exerciseEquipment[equipment]??'Tất cả'],['Trạng thái',visibility==='active'?'Đang hiển thị':visibility==='archived'?'Đã ẩn':'Tất cả'],['Lưu ý','Không lưu URL GIF; GIF chỉ dùng thử nghiệm phi thương mại.']]},filename:'HealthMate-thu-vien-bai-tap.xlsx',isCurrent:current,onResult:(message,bad)=>{status.textContent=message;status.className=bad?'error':'muted';}});})]:[]));
    if(focused)queryInput.focus();
    table.replaceChildren(...(ready?[
      h('div',{class:'exercise-overview'},h('span',{},h('strong',{},String(rows.length)),'Tổng bài tập'),h('span',{},h('strong',{},String(rows.filter(r=>r.isActive).length)),'Đang hiển thị'),h('span',{},h('strong',{},String(rows.filter(r=>!r.isActive).length)),'Đã ẩn')),
      h('p',{class:'muted'},`${selected.length}/${rows.length} bài tập · đồng bộ trực tiếp`),
      ...(selected.length?[h('div',{class:'table-wrap'},h('table',{class:'exercise-table'},h('thead',{},h('tr',{},...['BÀI TẬP','NHÓM / DỤNG CỤ','TRẠNG THÁI','THAO TÁC'].map(s=>h('th',{},s)))),h('tbody',{},...selected.map(row=>h('tr',{},h('td',{},exerciseName(row)),h('td',{},h('div',{class:'exercise-group'},h('span',{},exerciseRegions[row.region]),h('span',{class:'muted'},exerciseEquipment[row.equipment]))),h('td',{},h('span',{class:`exercise-status${row.isActive?'':' off'}`},row.isActive?'Hiển thị':'Đã ẩn')),h('td',{class:'row-actions'},button('Chi tiết / GIF',()=>preview(row)),button('Sửa',()=>edit(row)),button(row.isActive?'Xóa khỏi thư viện':'Khôi phục',()=>archive(row))))))))]:[h('p',{class:'empty'},'Không có bài tập phù hợp. Hãy đổi từ khóa hoặc bộ lọc.')]),
    ]:[]));
  }
  function load(){if(!current())return;stop?.();ready=false;status.className='loading';status.textContent='Đang xác nhận thư viện trên máy chủ…';render();try{stop=api.watchExerciseLibrary(remote=>{if(!current())return;try{rows=mergeExerciseLibrary(bundledExerciseLibrary,remote);ready=true;status.className='muted';status.textContent='Đã đồng bộ với máy chủ. Thay đổi sẽ đến app đang kết nối.';render();}catch(e){error(e);}},error,{isCurrent:current});}catch(e){error(e);}}
  host.replaceChildren(h('section',{class:'panel feature-workout'},h('p',{class:'notice exercise-source-note'},mediaEnabled?'GIF ExerciseDB tự tải khi cuộn đến bài tập. Chỉ dùng thử nghiệm phi thương mại; có thể dừng hoặc thử tải lại.': 'GIF ExerciseDB miễn phí chỉ bật ở bản kiểm thử trên máy. Bạn vẫn có thể quản lý đầy đủ bài tập và hướng dẫn tại đây.'),h('p',{class:'muted'},'Thêm và chỉnh sửa sẽ đồng bộ đến app đang kết nối. Xóa là ẩn bài tập có thể khôi phục; nhật ký cũ vẫn được giữ.'),toolbar,status,table));
  onDispose?.(()=>{stop?.();dropInline();dropPreview();sourceBrowser?.dispose();host.ownerDocument.removeEventListener('visibilitychange',background);});load();
}
