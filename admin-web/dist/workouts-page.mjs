import {exerciseCatalog} from './exercise-catalog.mjs';
import {normalizeSearch} from './list-model.mjs';
import {buildXlsx} from './xlsx-export.mjs';

export function workoutsPage({host,h,button}) {
  let search='',category='';
  const tableHost=h('div'),summary=h('p',{class:'muted','aria-live':'polite'});
  const input=h('input',{type:'search',class:'search','aria-label':'Tìm bài tập',placeholder:'Tìm tên, mã hoặc mô tả…',maxLength:200,onInput:e=>{search=e.target.value;render();}});
  const select=h('select',{'aria-label':'Nhóm bài tập',onChange:e=>{category=e.target.value;render();}},h('option',{value:''},'Tất cả nhóm'),...Object.entries(exerciseCatalog.categories).map(([value,label])=>h('option',{value},label)));
  const selected=()=>exerciseCatalog.items.filter(row=>(!category||row.category===category)&&normalizeSearch(`${row.id} ${row.name} ${row.description??''}`).includes(normalizeSearch(search)));
  function render(){
    const rows=selected();summary.textContent=`${rows.length}/${exerciseCatalog.items.length} bài tập trong danh mục mã nguồn app hiện tại.`;
    tableHost.replaceChildren(h('div',{class:'table-wrap'},h('table',{},h('thead',{},h('tr',{},...['BÀI TẬP / MÃ','NHÓM','MET THAM KHẢO','MÔ TẢ'].map(label=>h('th',{},label)))),h('tbody',{},...rows.map(row=>h('tr',{},h('td',{},h('strong',{},row.name),h('small',{},row.id)),h('td',{},exerciseCatalog.categories[row.category]),h('td',{class:'number'},String(row.met)),h('td',{},row.description??'—')))))),...(rows.length?[]:[h('p',{class:'empty'},'Không có bài tập phù hợp.')]));
  }
  host.replaceChildren(h('section',{class:'panel'},h('div',{class:'toolbar'},input,h('label',{class:'filter-field'},'Nhóm',select),button('Xuất danh mục đang lọc',()=>{
    const bytes=buildXlsx({name:'Danh mục bài tập',headers:['Mã','Tên bài tập','Nhóm','MET tham khảo','Mô tả'],rows:selected().map(row=>[row.id,row.name,exerciseCatalog.categories[row.category],row.met,row.description??''])});
    const url=URL.createObjectURL(new Blob([bytes],{type:'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'}));
    const link=h('a',{href:url,download:'HealthMate-bai-tap.xlsx'});document.body.append(link);link.click();link.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);
  })),summary,h('p',{class:'notice'},'Danh mục chỉ đọc, xuất từ mã nguồn HealthMate. Bản app đã cài có thể khác nếu chưa cập nhật. Chưa hỗ trợ sửa bài tập từ xa; thay đổi danh mục cần cập nhật app. MET và calo tính từ MET chỉ là ước tính, không phải số đo thiết bị.'),h('p',{class:'muted'},'Nguồn được ghi trong app: ',h('a',{href:exerciseCatalog.sourceUrl,target:'_blank',rel:'noopener noreferrer'},'Compendium of Physical Activities')),tableHost));render();
}
