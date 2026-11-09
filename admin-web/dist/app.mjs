import { foodPayload, configPayload, text, validFoodId, entityVersion } from './validation.mjs';
import { filterRows, canControlAccount, exportRows } from './list-model.mjs';
import { downloadReport } from './report-download.mjs';
import { revenuePage } from './play-revenue-page.mjs';
import { supportPage } from './support-page.mjs';
import { dashboardPage } from './dashboard-page.mjs';
import {liveScope,observe} from './live-scope.mjs';
import {pageScope} from './server-paging.mjs';
import {vietnamDateKey} from './revenue-model.mjs';
import {createDraftGuard,routePage} from './draft-guard.mjs';
import {workoutsPage} from './workouts-page.mjs';
const pageCleanups = new Set();
function registerCleanup(stop){pageCleanups.add(stop);}
function disposePage(){for(const stop of pageCleanups)stop();pageCleanups.clear();}
import {adminPages as pages, adminBrand, adminIcon, renderAdminShell} from './admin-shell.mjs';

const root = document.querySelector('#app'), dialog = document.querySelector('#editor');
const editorForm = document.querySelector('#editor-form'), fieldsHost = document.querySelector('#editor-fields');
let api, user, allowed = false, stopRole, generation = 0, pageGeneration = 0;
let currentPage = 'overview', rows = [], pageNumber = 1, filter = '', rowsReady = false;
let pageCursors=[null],nextCursor=null,hasMore=false;
let categoryFilter = '', statusFilter = '', roleFilter = '';
let serverRange={};
let editorAction, editorCancel, editorBusy = false, currentConfig = null;
function h(tag, props = {}, ...children) {
  const el = document.createElement(tag);
  for (const [key,value] of Object.entries(props)) {
    if (key.startsWith('on')) el.addEventListener(key.slice(2).toLowerCase(),value);
    else if (key === 'class') el.className = value;
    else if (key in el) el[key] = value;
    else el.setAttribute(key,value);
  }
  el.append(...children.filter(c => c !== null && c !== undefined).map(c => typeof c === 'string' ? document.createTextNode(c) : c));
  return el;
}
function brand() { return adminBrand(h); }
function errorMessage(error) {
  const code = error?.code ?? '';
  if (code === 'auth/popup-closed-by-user' || code === 'auth/cancelled-popup-request') return 'Bạn đã hủy đăng nhập Google. Có thể thử lại khi sẵn sàng.';
  if (code === 'auth/popup-blocked') return 'Trình duyệt đang chặn cửa sổ đăng nhập. Hãy cho phép cửa sổ bật lên cho HealthMate rồi thử lại.';
  if (code.includes('permission-denied')) return 'Không có quyền thực hiện. Kiểm tra vai trò admin, tài khoản được bảo vệ và Rules đã cấu hình.';
  if (code.startsWith('auth/')) return 'Không đăng nhập được. Kiểm tra email, mật khẩu và kết nối Firebase.';
  if (/unavailable|deadline|network/.test(code)) return 'Chưa kết nối được máy chủ. Dữ liệu chưa được xác nhận; hãy thử lại.';
  return error?.message ?? 'Thao tác chưa hoàn tất. Hãy thử lại.';
}
function notify(message, bad = false) {
  const el = document.querySelector('#notification');
  el.textContent = message; el.className = `notification${bad?' bad':''}`; el.hidden = false;
  clearTimeout(notify.timer); notify.timer = setTimeout(() => { el.hidden = true; },7000);
}
function date(value) { const d = value?.toDate?.(); return d ? new Intl.DateTimeFormat('vi-VN',{dateStyle:'short',timeStyle:'short',timeZone:'Asia/Ho_Chi_Minh'}).format(d) : '—'; }
function version(data) { return entityVersion(data); }
function pill(label, style = '') { return h('span',{class:`pill ${style}`},label); }
function button(label, click, style = 'secondary') { return h('button',{type:'button',class:`button ${style}`,onClick:click},label); }
const drafts=createDraftGuard({window,document,h,button});
function safeCurrent(g) { return allowed && user && generation === g; }
function clearEditor(){dialog.close();fieldsHost.replaceChildren();editorAction=null;drafts.clear('editor');document.querySelector('#editor-error').textContent='';}

function showAuth(message = '') {
  document.title='HealthMate · Quản trị';
  disposePage();
  root.replaceChildren(h('main',{class:'auth-shell'},
    h('aside',{class:'auth-story'},brand(),h('div',{},h('p',{class:'eyebrow'},'HEALTHMATE CONTROL CENTER'),h('h1',{},'Một nơi quản lý.\nNhiều thói quen tốt.'),h('p',{},'Chăm sóc dữ liệu thực phẩm, vận hành tài khoản và giữ trải nghiệm HealthMate nhất quán.'),h('div',{class:'auth-lines'},h('span'),h('span'),h('span'))),h('p',{},'Quyền quản trị được kiểm tra bằng Firebase Security Rules.')),
    h('div',{class:'auth-form'},h('section',{},h('p',{class:'page-kicker'},'CHÀO MỪNG TRỞ LẠI'),h('h2',{},user ? 'Quyền quản trị chưa sẵn sàng' : 'Đăng nhập quản trị'),h('p',{class:'muted'},message || 'Sử dụng tài khoản đã được cấp quyền HealthMate Admin.'),
      api?.emulator ? h('p',{class:'notice local'},'Môi trường kiểm thử local · Firebase Emulator. Dữ liệu tại đây không phải dữ liệu production.') : null,
      user ? button('Đăng xuất',logout) : loginForm(),
      h('p',{class:'auth-note'},'Không tự đăng ký hoặc cấp quyền admin tại đây. Chủ dự án cấp quyền qua bước thiết lập Firebase riêng.')))));
}
function loginForm() {
  const email = h('input',{id:'login-email',type:'email',autocomplete:'username',required:true,maxLength:254});
  const password = h('input',{id:'login-password',type:'password',autocomplete:'current-password',required:true,maxLength:128});
  const message = h('p',{class:'error',role:'alert'}), submit = h('button',{class:'button',type:'submit'},'Đăng nhập');
  const form = h('form',{onSubmit: async event => {
    event.preventDefault(); submit.disabled = true; message.textContent = ''; submit.textContent = 'Đang xác nhận…';
    try { await api.login(email.value.trim(),password.value); password.value = ''; }
    catch(error) { message.textContent = errorMessage(error); submit.disabled = false; submit.textContent = 'Đăng nhập'; }
  }},h('label',{class:'field'},'Email quản trị',email),h('label',{class:'field'},'Mật khẩu',password),message,submit);
  form.append(h('button',{type:'button',id:'google-login',class:'button secondary',onClick:async event=>{
    const google=event.currentTarget;
    google.disabled=true;submit.disabled=true;message.textContent='';google.textContent='Đang mở Google…';
    try { await api.loginGoogle(); }
    catch(error) { message.textContent=errorMessage(error); }
    finally { google.disabled=false;submit.disabled=false;google.textContent='Tiếp tục với Google'; }
  }},'Tiếp tục với Google'));
  let resetAt = 0;
  form.append(button('Quên mật khẩu',async () => {
    if(!email.checkValidity()||!email.value.trim()){email.reportValidity();return;}
    if(Date.now()<resetAt){message.textContent='Vui lòng chờ trước khi gửi lại email.';return;}
    resetAt=Date.now()+60000;
    try{await api.resetPassword(email.value.trim());message.textContent='Đã gửi yêu cầu đặt lại mật khẩu. Nếu email đủ điều kiện, hãy kiểm tra hộp thư và thư rác.';}
    catch(error){message.textContent=errorMessage(error);}
  }));
  return form;
}
function shell() {
  return renderAdminShell({root,h,currentPage,user,onNavigate:openPage,onLogout:logout,emulator:api.emulator});
}
async function logout(){if(editorBusy){notify('Hãy chờ máy chủ xác nhận thao tác đang lưu.',true);return;}try{if(await drafts.allow())await api.logout();}catch(error){notify(errorMessage(error),true);}}
async function openPage(key,{force=false,history='push'}={}) {
  if (!allowed) return;
  if(!Object.hasOwn(pages,key))key='overview';
  const g=generation;
  if(!force&&(editorBusy||!await drafts.allow()))return false;
  if(!safeCurrent(g))return false;
  drafts.reset();clearEditor();
  disposePage();
  pageGeneration++;
  currentPage = key; rows = []; rowsReady = false; pageNumber = 1; filter = '';
  pageCursors=[null];nextCursor=null;hasMore=false;
  categoryFilter = '';statusFilter = '';roleFilter = '';
  serverRange={};
  const main = shell(), info = pages[key];
  document.title=`${info[0]} · HealthMate Admin`;
  if(history!=='none'&&window.history&&window.location?.hash!==`#/${key}`)window.history[history==='replace'?'replaceState':'pushState'](null,'',`#/${key}`);
  main.append(h('div',{class:'page-head'},h('div',{},h('p',{class:'page-kicker'},`QUẢN TRỊ / ${info[0].toUpperCase()}`),h('h1',{},info[1]),h('p',{class:'muted'},info[2])),key === 'food_catalog' ? button('+ Thêm món ăn',() => editFood(), '') : null));
  if (api.emulator) main.append(h('p',{class:'notice local'},'Bạn đang thao tác trên dữ liệu kiểm thử local. Các thay đổi không tác động ứng dụng production.'));
  const content = h('div',{id:'page-content'}); main.append(content);
  if (key === 'overview') return overview(content);
  if (key === 'workouts') {
    const g=generation,p=pageGeneration;
    return workoutsPage({host:content,h,button,isCurrent:()=>safeCurrent(g)&&pageGeneration===p});
  }
  if (key === 'chatbot') return chatbotPage(content);
  if (key === 'app_config') return configPage(content);
  if (key === 'support') {
    const g = generation, p = pageGeneration;
    return supportPage({host:content,api,h,button,drafts,onDispose:registerCleanup,isCurrent:() => safeCurrent(g) && pageGeneration === p});
  }
  if (key === 'revenue') {
    const g = generation, p = pageGeneration;
    return revenuePage({host:content,api,h,button,onDispose:registerCleanup,isCurrent:() => safeCurrent(g) && pageGeneration === p});
  }
  const toolbar = h('div',{class:'toolbar'},h('input',{class:'search',type:'search',id:'list-search',placeholder:'Tìm trong trang đang xem…','aria-label':'Tìm trong trang đang xem',maxLength:200,onInput:event => { filter=event.target.value;renderRows(); }}));
  function select(id,label,values,change) {
    return h('label',{class:'filter-field'},label,h('select',{id,'aria-label':label,onChange:event=>{change(event.target.value);renderRows();}},...values.map(([value,title])=>h('option',{value},title))));
  }
  if(key==='food_catalog') {
    toolbar.append(select('category-filter','Nhóm món',[['','Tất cả nhóm']],v=>categoryFilter=v),
      select('status-filter','Trạng thái',[['','Tất cả trạng thái'],['active','Đang hiển thị'],['archived','Đã xóa khỏi danh mục']],v=>statusFilter=v));
  } else if(key==='user_directory') {
    toolbar.append(select('status-filter','Trạng thái',[['','Tất cả trạng thái'],['active','Hoạt động'],['suspended','Tạm khóa']],v=>statusFilter=v),
      select('role-filter','Vai trò',[['','Tất cả vai trò'],['admin','Admin'],['user','Người dùng']],v=>roleFilter=v));
  } else toolbar.append(select('category-filter','Đối tượng',[['','Tất cả đối tượng'],['food_catalog','Danh mục món ăn'],['account_controls','Tài khoản'],['app_config','Cấu hình']],v=>categoryFilter=v));
  toolbar.append(button('Tải lại',() => loadPage({reset:true})),h('button',{type:'button',class:'button secondary',id:'export-list',disabled:true,onClick:exportList},key==='admin_audit'?'Xuất Excel theo ngày':'Xuất Excel theo khoảng mã'));
  const lookupMode=h('select',{id:'lookup-field','aria-label':'Tra cứu trên toàn danh sách'},h('option',{value:'id'},'Mã chính xác'),...(key==='user_directory'?[h('option',{value:'email'},'Email chính xác')]:key==='food_catalog'?[h('option',{value:'name'},'Đầu tên món')]:[]));
  const lookupValue=h('input',{id:'lookup-value',class:'search',maxLength:1500,'aria-label':'Giá trị tra cứu',placeholder:key==='user_directory'?'Nhập UID hoặc email đầy đủ…':'Nhập mã hoặc đầu tên món…'});
  const rangeStatus=h('p',{class:'muted',id:'range-status','aria-live':'polite'},key==='admin_audit'?'Mới nhất lên đầu. Thời gian hiển thị theo Việt Nam.':'Tra cứu máy chủ trên toàn danh sách. Đầu tên món phân biệt chữ hoa và dấu.');
  const apply=range=>{try{pageScope(key,range);serverRange=range;filter='';categoryFilter='';statusFilter='';roleFilter='';document.querySelector('#list-search').value='';for(const id of ['category-filter','status-filter','role-filter']){const select=document.querySelector('#'+id);if(select)select.value='';}loadPage({reset:true});}catch(e){notify(errorMessage(e),true);}};
  const lookup=h('form',{class:'toolbar server-lookup',onSubmit:e=>{e.preventDefault();apply({lookupField:lookupMode.value,lookupValue:lookupValue.value});}},h('label',{class:'filter-field'},'Tra cứu máy chủ',lookupMode),lookupValue,h('button',{type:'submit',class:'button secondary'},'Tra cứu'),button('Xóa tra cứu',()=>{lookupValue.value='';apply({});}));
  if(key==='admin_audit'){
    const today=vietnamDateKey(new Date()),start=h('input',{id:'audit-start',type:'date',value:today,'aria-label':'Từ ngày (VN)'}),end=h('input',{id:'audit-end',type:'date',value:today,'aria-label':'Đến ngày (VN)'});
    lookup.append(h('label',{class:'filter-field'},'Từ ngày (VN)',start),h('label',{class:'filter-field'},'Đến ngày (VN)',end),button('Lọc theo ngày',()=>apply({start:start.value,end:end.value})));
  }
  content.append(h('section',{class:'panel'},lookup,rangeStatus,toolbar,h('p',{class:'muted',id:'list-status','aria-live':'polite'},'Chưa tải dữ liệu.')),h('div',{id:'data-content'}));
  await loadPage();
}
async function overview(content) {
  const g = generation, p = ++pageGeneration;
  return dashboardPage({host:content,api,h,button,openPage,errorMessage,
    onDispose:registerCleanup,isCurrent:() => safeCurrent(g) && p === pageGeneration});
}
async function chatbotPage(content) {
  const g=generation,p=pageGeneration,current=()=>safeCurrent(g)&&p===pageGeneration;
  const scope=liveScope(content,current,registerCleanup);
  content.replaceChildren(h('p',{class:'loading'},'Đang tải cấu hình AI…'));
  try {
    return await observe(scope,api,'watchConfig',[],config=>{if(!current())return;
    const cards=h('div',{class:'ai-settings-grid'});
    for(const [key,label,description] of [['chatbotEnabled','AI Chatbot','Hỗ trợ người dùng tra cứu và theo dõi thói quen.'],['foodScannerEnabled','AI Food Scanner','Hỗ trợ gợi ý món ăn từ ảnh trước khi người dùng xác nhận.']]){
      const known=typeof config?.[key]==='boolean',enabled=config?.[key]===true;
      cards.append(h('section',{class:'panel ai-setting-card'},h('div',{class:'panel-title'},h('span',{class:'feature-illustration small'},adminIcon(key==='chatbotEnabled'?'chatbot':'food_catalog')),
        pill(known?(enabled?'Đang bật':'Đang tắt'):'Chưa có cấu hình',known&&enabled?'':'off')),h('h2',{},label),h('p',{class:'muted'},description),
        button('Điều chỉnh cấu hình',()=>openPage('app_config'))));
    }
    content.replaceChildren(cards,h('p',{class:'notice'},'Đây là trạng thái cấu hình, không xác nhận API AI đang hoạt động. Hội thoại và dữ liệu sức khỏe của khách hàng vẫn riêng tư.'));
    },error=>content.replaceChildren(h('p',{class:'error'},errorMessage(error))),()=>api.config());
  } catch(error){if(current())content.replaceChildren(h('p',{class:'error',role:'alert'},errorMessage(error)),button('Thử tải lại',()=>chatbotPage(content)));}
}
async function loadPage({reset=false,page=pageNumber}={}) {
  const host = document.querySelector('#data-content'); if (!host) return;
  if(reset){page=1;pageCursors=[null];}
  const cursor=pageCursors[page-1];
  if(page<1||cursor===undefined)return;
  const g = generation, p = ++pageGeneration;
  rowsReady=false;rows=[];
  const isCurrent=()=>safeCurrent(g)&&p===pageGeneration;
  const scope=liveScope(host,isCurrent,registerCleanup);
  document.querySelector('#export-list').disabled=true;
  host.replaceChildren(h('p',{class:'loading'},'Đang tải dữ liệu…'));
  try {
    return await observe(scope,api,'watchPage',[currentPage,{...serverRange,cursor,isCurrent}],loaded=>{
    if (!isCurrent()) return;
    rows=loaded.rows;rowsReady=true;pageNumber=page;nextCursor=loaded.cursor;hasMore=loaded.hasMore;
    if(hasMore)pageCursors[pageNumber]=nextCursor;
    const categories=document.querySelector('#category-filter');
    if(currentPage==='food_catalog'&&categories){
      categories.replaceChildren(h('option',{value:''},'Tất cả nhóm'),...[...new Set(rows.map(r=>r.category).filter(Boolean))].sort((a,b)=>a.localeCompare(b,'vi')).map(value=>h('option',{value},value)));
      categories.value=categoryFilter;
      if(categories.value!==categoryFilter)categoryFilter='';
    }
    const ordering=currentPage==='admin_audit'&&!serverRange.lookupField?'mới nhất lên đầu':serverRange.lookupField==='name'?'sắp theo tên và mã':'sắp theo mã';
    document.querySelector('#range-status').textContent=serverRange.lookupField?`Tra cứu máy chủ: ${serverRange.lookupField==='email'?'email chính xác':serverRange.lookupField==='name'?'đầu tên món (phân biệt hoa và dấu)':'mã chính xác'}. Kết quả được phân trang và đồng bộ trực tiếp.`:serverRange.start?`Nhật ký từ ${serverRange.start} đến ${serverRange.end}, theo ngày Việt Nam.`:currentPage==='admin_audit'?'Mới nhất lên đầu. Thời gian theo Việt Nam.':'Đang xem toàn danh sách, phân trang từ máy chủ.';
    document.querySelector('#list-status').textContent=`Đã tải ${rows.length} mục của trang ${pageNumber}, ${ordering}. Tìm kiếm và bộ lọc chỉ áp dụng trang này. Tra cứu máy chủ ở phía trên tìm trên toàn danh sách. Đồng bộ trực tiếp.`;
    document.querySelector('#export-list').disabled=false;
    renderRows();
    },error=>{rows=[];rowsReady=false;document.querySelector('#export-list').disabled=true;document.querySelector('#list-status').textContent=errorMessage(error);host.replaceChildren(h('p',{class:'error'},errorMessage(error)),button('Thử tải lại',()=>loadPage({page})));},()=>api.listPage(currentPage,{...serverRange,cursor,isCurrent}));
  } catch(error) { if(isCurrent()) {
    document.querySelector('#list-status').textContent='Chưa tải được trang; chưa thể tìm kiếm hoặc xuất.';
    host.replaceChildren(h('section',{class:'panel'},h('p',{class:'error'},errorMessage(error)),button('Thử tải lại',() => loadPage({page}))));
  } }
}
function renderRows() {
  const host = document.querySelector('#data-content'); if (!host) return;
  if(!rowsReady)return;
  const filtered = currentRows(), page={rows:filtered,offset:(pageNumber-1)*25};
  const table = h('table'), labels = currentPage === 'food_catalog' ? ['STT','MÓN ĂN / NGUỒN','NHÓM','KCAL / 100 G','TRẠNG THÁI','THAO TÁC'] : currentPage === 'user_directory' ? ['STT','TÀI KHOẢN','VAI TRÒ','TRẠNG THÁI','CẬP NHẬT','THAO TÁC'] : ['STT','THỜI GIAN','ĐỐI TƯỢNG / THAO TÁC','NGƯỜI THỰC HIỆN','LÝ DO'];
  table.append(h('thead',{},h('tr',{},...labels.map(label => h('th',{},label)))));
  const body = h('tbody'); table.append(body);
  for (const [index,row] of page.rows.entries()) {
    const stt=h('td',{class:'number'},String(page.offset+index+1));
    if (currentPage === 'food_catalog') body.append(h('tr',{},stt,h('td',{},h('strong',{},row.name),h('small',{},row.sourceLabel),row.isEstimated?pill('Ước tính','off'):null),h('td',{},row.category),h('td',{class:'number'},String(row.kcalPer100g??'—')),h('td',{},pill(row.isActive===false?'Đã xóa khỏi danh mục':'Đang hiển thị',row.isActive===false?'off':'')),h('td',{class:'row-actions'},h('button',{class:'small-button',onClick:()=>viewFood(row)},'Chi tiết'),h('button',{class:'small-button',onClick:() => editFood(row)},'Sửa'),h('button',{class:'small-button',onClick:()=>archiveFood(row)},row.isActive===false?'Khôi phục':'Xóa khỏi danh mục'))));
    else if (currentPage === 'user_directory') body.append(h('tr',{},stt,h('td',{},h('strong',{},row.displayName||'Chưa đặt tên'),h('small',{},row.email),h('small',{},row.id)),h('td',{},pill(row.adminRole?.enabled?'Admin':'Người dùng',row.adminRole?.enabled?'':'off')),h('td',{},pill(row.control?.status === 'suspended'?'Tạm khóa':'Hoạt động',row.control?.status === 'suspended'?'suspended':'')),h('td',{},date(row.updatedAt)),h('td',{class:'row-actions'},h('button',{class:'small-button',onClick:()=>viewAccount(row)},'Chi tiết'),!canControlAccount(row,user.uid)?h('small',{},row.id===user.uid?'Tài khoản hiện tại':'Tài khoản được bảo vệ'):h('button',{class:'small-button',onClick:() => editAccount(row)},row.control?.status==='suspended'?'Mở truy cập':'Khóa truy cập'))));
    else body.append(h('tr',{},stt,h('td',{class:'number'},date(row.at)),h('td',{},h('strong',{},`${row.entityType} / ${row.entityId}`),h('small',{},(row.changedFields??[]).join(', '))),h('td',{},h('code',{},row.actorUid)),h('td',{},row.reason)));
  }
  const panel = h('section',{class:'panel'},h('div',{class:'table-wrap'},table));
  if (!filtered.length) panel.append(h('p',{class:'empty'},rows.length?'Không có kết quả trong trang này. Đổi bộ lọc hoặc chuyển trang.':pageNumber>1?'Đã hết dữ liệu trong lần tải này.':'Chưa có dữ liệu từ máy chủ.'));
  const go=n=>loadPage({page:n});
  panel.append(h('div',{class:'table-foot'},h('span',{},`Trang ${pageNumber} · ${filtered.length}/${rows.length} mục trên trang`),h('div',{class:'pagination'},h('button',{type:'button',class:'button secondary',disabled:pageNumber===1,onClick:()=>loadPage({reset:true})},'Đầu'),h('button',{type:'button',class:'button secondary',disabled:pageNumber===1,onClick:()=>go(pageNumber-1)},'Trước'),h('button',{type:'button',class:'button secondary',disabled:!hasMore,onClick:()=>go(pageNumber+1)},'Sau'))));
  host.replaceChildren(panel);
}
function currentRows(){return filterRows(rows,currentPage,{search:filter,category:categoryFilter,status:statusFilter,role:roleFilter});}
function exportList(){
  if(!rowsReady||editorBusy)return;
  const kind=currentPage,g=generation,p=pageGeneration;
  let cancelled=false,cancel;
  const audit=kind==='admin_audit',today=vietnamDateKey(new Date());
  const capturedFilters={search:filter,category:categoryFilter,status:statusFilter,role:roleFilter};
  const visibleIds=rows.map(row=>row.id).sort();
  openEditor(audit?'Xuất nhật ký theo ngày Việt Nam':'Xuất Excel theo khoảng mã',[
    h('p',{},`Xuất tối đa 5.000 mục trong khoảng ${audit?'ngày Việt Nam':'mã'}, gồm mọi trang. Nếu vượt giới hạn, chọn khoảng nhỏ hơn. Tra cứu máy chủ không giới hạn tệp này; bạn chọn áp dụng bộ lọc bên dưới.`),
    checkbox('applyFilters','Áp dụng tìm kiếm và bộ lọc hiện tại',true,'Áp dụng trên toàn bộ khoảng xuất, gồm mọi trang.'),
    h('p',{class:'muted'},`Từ khóa: ${capturedFilters.search||'Tất cả'} · Nhóm: ${capturedFilters.category||'Tất cả'} · Trạng thái: ${capturedFilters.status||'Tất cả'} · Vai trò: ${capturedFilters.role||'Tất cả'}`),
    ...(kind==='food_catalog'?[h('p',{class:'notice'},'Chỉ xuất danh mục trên Firebase, không bao gồm toàn bộ thư viện thực phẩm đi kèm app hoặc món riêng của người dùng.')]:[]),
    ...(audit?[field('start','Từ ngày (VN)',serverRange.start??today,{type:'date'}),field('end','Đến ngày (VN)',serverRange.end??today,{type:'date'})]:[
      field('idFrom','Từ mã (bao gồm)',visibleIds[0]??'',{max:1500,optional:true}),
      field('idTo','Đến mã (bao gồm)',visibleIds.at(-1)??'',{max:1500,optional:true})]),
    h('p',{class:'notice'},kind==='user_directory'?'Tệp có email và UID. Chỉ lưu vào nơi bạn quản lý; tệp tải về không tự bị xóa khi đăng xuất.':'Tệp Excel có số liệu nguồn và trạng thái hiện tại. Không gồm nhật ký sức khỏe cá nhân.'),
  ],async form=>{
    const current=()=>!cancelled&&safeCurrent(g)&&pageGeneration===p;
    const input=values(form),range=audit?{start:input.start,end:input.end}:{idFrom:input.idFrom.trim(),idTo:input.idTo.trim()};
    const selected=await Promise.race([api.exportRange(kind,{...range,isCurrent:current}),new Promise((_,reject)=>{cancel=()=>reject(Error('Đã hủy xuất.'));})]);
    if(!current())throw Error('Phiên xuất đã thay đổi.');
    const filtered=input.applyFilters?filterRows(selected,kind,capturedFilters):selected;
    if(!filtered.length)throw Error('Không có dữ liệu phù hợp trong khoảng và bộ lọc đã chọn. Chưa tạo tệp; hãy điều chỉnh rồi thử lại.');
    const workbook=exportRows(kind,filtered);
    workbook.metadata=[['Báo cáo',workbook.name],['Nguồn','Firestore · dữ liệu máy chủ tại lúc tải'],
      ['Phạm vi',audit?`${range.start} – ${range.end} (ngày Việt Nam, gồm ngày cuối)`:`Mã từ ${range.idFrom||'đầu'} đến ${range.idTo||'cuối'} (bao gồm)`],
      ['Bộ lọc',input.applyFilters?JSON.stringify(capturedFilters):'Không áp dụng'],
      ['Số bản ghi trong khoảng trước lọc',selected.length],
      ['Lưu ý',kind==='food_catalog'?'Chỉ danh mục Firebase; không bao gồm thư viện đi kèm app.':kind==='user_directory'?'Danh bạ tài khoản đã đồng bộ; không khẳng định đầy đủ Firebase Authentication. Tệp không tự xóa khi đăng xuất.':'Tệp tải về không tự cập nhật hoặc tự xóa khi đăng xuất.']];
    let resultMessage='Phiên xuất đã thay đổi.';
    const requested=downloadReport({workbook,filename:`HealthMate-${kind}-${vietnamDateKey(new Date())}.xlsx`,isCurrent:current,
      onResult:message=>{resultMessage=message;}});
    if(!requested)throw Error(resultMessage);
    editorSuccess=resultMessage;
  },{reason:false,success:'Đã tạo tệp Excel và yêu cầu trình duyệt tải xuống.',cancel:()=>{cancelled=true;cancel?.();}});
}
function field(name,label,value='',{type='text',max=100,optional=false,hint='',readonly=false}={}) {
  const input = h(type==='textarea'?'textarea':'input',{name,id:`field-${name}`,value:String(value??''),required:!optional,maxLength:max,readOnly:readonly,...(type==='textarea'?{}:{type:type==='number'?'text':type}),...(type==='number'?{inputMode:'decimal'}:{})});
  return h('label',{class:'field'},label,input,hint?h('small',{},hint):null);
}
function checkbox(name,label,checked,description='') { return h('label',{class:'check-field'},h('input',{type:'checkbox',name,checked}),h('div',{},h('strong',{},label),description?h('small',{},description):null)); }
function values(form) { const data=Object.fromEntries(new FormData(form)); for (const box of form.querySelectorAll('input[type=checkbox]')) data[box.name]=box.checked; return data; }
let editorSuccess = '';
function openEditor(title,children,action=null,{reason=true,success='Đã lưu thay đổi và nhật ký quản trị.',cancel=null}={}) {
  if (editorBusy || !allowed) return;
  fieldsHost.replaceChildren(...children,...(reason&&action?[field('reason','Lý do thay đổi','',{type:'textarea',max:200,hint:'Lưu trong nhật ký quản trị. Với khóa/mở tài khoản, lý do sẽ hiển thị cho người dùng.'})]:[]));
  editorSuccess=success;editorCancel=cancel;document.querySelector('#submit-editor').hidden=!action;
  document.querySelector('#editor-title').textContent=title; document.querySelector('#editor-error').textContent=''; editorAction=action; dialog.showModal();
  const initial=JSON.stringify(values(editorForm));
  drafts.set('editor',()=>editorBusy||Boolean(editorAction)&&dialog.hasAttribute('open')&&initial!==JSON.stringify(values(editorForm)));
}
function viewFood(row){openEditor('Chi tiết món ăn',[
  h('h3',{},row.name),h('p',{},`${row.id} · ${row.category}`),
  pill(row.isActive===false?'Đã xóa khỏi danh mục':'Đang hiển thị',row.isActive===false?'off':''),
  h('p',{},`Trên 100 g: ${row.kcalPer100g} kcal · Đạm ${row.proteinGPer100g} g · Carb ${row.carbsGPer100g} g · Béo ${row.fatGPer100g} g · Xơ ${row.fiberGPer100g??'Chưa có dữ liệu'}`),
  h('p',{},`Nguồn: ${row.sourceLabel}`),h('p',{},row.sourceUrl),h('p',{},`Tên tương đương: ${(row.alternateNames??[]).join(', ')||'—'}`),
  h('p',{},`Cập nhật: ${date(row.updatedAt)}`),
]);}
function viewAccount(row){openEditor('Chi tiết tài khoản',[
  h('h3',{},row.displayName||'Chưa đặt tên'),h('p',{},row.email),h('p',{},`UID: ${row.id}`),
  h('p',{},`Vai trò: ${row.adminRole?.enabled?'Admin':'Người dùng'}${row.adminRole?' · được bảo vệ khỏi khóa trên web':''}`),
  h('p',{},`Trạng thái truy cập: ${row.control?.status==='suspended'?'Tạm khóa':'Hoạt động'}`),
  h('p',{},`Lý do gần nhất: ${row.control?.reason||'—'}`),
  h('p',{class:'notice'},'Đây là danh bạ tài khoản đồng bộ từ HealthMate; không phải toàn bộ Firebase Authentication. Admin không được xem nhật ký sức khỏe, đổi mật khẩu hoặc xóa tài khoản Auth tại đây.'),
]);}
function archiveFood(row){const restore=row.isActive===false;openEditor(restore?'Khôi phục món ăn?':'Xóa món khỏi danh mục?',[
  h('h3',{},row.name),h('p',{class:'notice'},restore?'Món sẽ hiển thị lại trong danh mục của app sau khi đồng bộ.':'Món được ẩn khỏi danh mục đang dùng. Snapshot bữa ăn cũ và thông tin nguồn vẫn được giữ; có thể khôi phục sau.'),
],async form=>api.save('food_catalog',row.id,{isActive:restore},text(values(form).reason,'Lý do',200),version(row)));}
function editFood(row=null) {
  const data=row??{isActive:true,isEstimated:true};
  openEditor(row?'Chỉnh sửa món ăn':'Thêm món ăn',[
    field('id','Mã món',row?.id??'',{readonly:Boolean(row),hint:'Chữ thường, số và dấu gạch ngang. Mã không đổi sau khi tạo.'}),
    field('name','Tên món',data.name),
    h('div',{class:'field-row'},field('category','Nhóm món',data.category),field('alternateNames','Tên tương đương',(data.alternateNames??[]).join('\n'),{type:'textarea',max:808,optional:true,hint:'Mỗi tên một dòng, tối đa 8 tên.'})),
    h('p',{class:'notice'},'Mọi giá trị dinh dưỡng bên dưới tính trên 100 g. Để trống chất xơ khi chưa có dữ liệu; không tự thay bằng 0.'),
    h('div',{class:'field-row nutrients'},...['kcalPer100g','proteinGPer100g','carbsGPer100g','fatGPer100g','fiberGPer100g'].map((key,i)=>field(key,['Năng lượng (kcal)','Đạm (g)','Carbohydrate (g)','Chất béo (g)','Chất xơ (g)'][i],data[key],{type:'number',optional:key==='fiberGPer100g'}))),
    field('sourceLabel','Tên nguồn dinh dưỡng',data.sourceLabel,{max:160}),field('sourceUrl','Đường dẫn nguồn (HTTPS)',data.sourceUrl,{max:500}),
    h('div',{class:'field-row'},field('servingLabel','Tên khẩu phần',data.servingLabel,{max:60,optional:true}),field('servingGrams','Gram / khẩu phần',data.servingGrams,{type:'number',optional:true})),
    checkbox('isEstimated','Dữ liệu ước tính',data.isEstimated!==false),checkbox('isActive','Hiển thị trong danh mục app',data.isActive!==false,'Ẩn món không xóa hoặc thay đổi snapshot trong nhật ký đã ghi.')
  ],async form => { const input=values(form); await api.save('food_catalog',validFoodId(input.id),foodPayload(input),text(input.reason,'Lý do',200),version(row)); });
}
function editAccount(row) {
  const suspended=row.control?.status !== 'suspended';
  openEditor(suspended?'Tạm khóa truy cập':'Mở lại truy cập',[
    h('p',{},`${row.displayName||'Tài khoản'} · ${row.email}`),h('p',{class:'notice'},suspended?'Tài khoản sẽ bị chặn truy cập dữ liệu HealthMate qua Firestore Rules. Không xóa nhật ký hoặc vô hiệu hóa Firebase Auth.':'Khôi phục quyền truy cập HealthMate. Dữ liệu cá nhân được giữ nguyên.'),
    field('uid','UID',row.id,{readonly:true,max:128})
  ],async form => { const reason=text(values(form).reason,'Lý do',200); await api.save('account_controls',row.id,{status:suspended?'suspended':'active',reason},reason,version(row.control)); });
}
async function configPage(content) {
  const g=generation,p=++pageGeneration,current=()=>safeCurrent(g)&&p===pageGeneration;
  const scope=liveScope(content,current,registerCleanup);let dirty=false;
  drafts.set('page',()=>dirty);
  const syncStatus=h('p',{class:'muted','aria-live':'polite'});
  content.replaceChildren(h('p',{class:'loading'},'Đang tải cấu hình…'));
  try {
    return await observe(scope,api,'watchConfig',[],config=>{
    if(dirty){const conflict=version(config)!==version(currentConfig)||['chatbotEnabled','foodScannerEnabled','maintenanceMode','maintenanceMessage'].some(key=>config?.[key]!==currentConfig?.[key]),submit=content.querySelector('[type=submit]');if(submit)submit.disabled=conflict;syncStatus.textContent=conflict?'Cấu hình máy chủ vừa cập nhật. Bản nháp được giữ; tải cấu hình máy chủ trước khi lưu để tránh ghi đè.':'Đã kết nối lại. Bản nháp được giữ và chưa lưu.';return;}
    currentConfig=config; if(!current())return;
    const c=currentConfig??{};
    const form=h('form',{class:'config-form',onSubmit:event => {
      event.preventDefault();
      try { const payload=configPayload(values(form)); openEditor('Xác nhận thay đổi cấu hình',[h('p',{class:'notice'},'Thay đổi sẽ áp dụng cho các bản HealthMate bật quản trị từ xa. Kiểm tra các lựa chọn trước khi lưu.'),h('p',{},`Chatbot: ${payload.chatbotEnabled?'bật':'tắt'} · Quét món: ${payload.foodScannerEnabled?'bật':'tắt'} · Bảo trì: ${payload.maintenanceMode?'bật':'tắt'}`)],async review => api.save('app_config','runtime',payload,text(values(review).reason,'Lý do',200),version(currentConfig))); }
      catch(error){ notify(errorMessage(error),true); }
    }},
    checkbox('foodScannerEnabled','Quét món bằng AI',c.foodScannerEnabled!==false,'Cho phép sử dụng tính năng nhận diện ảnh. Cờ tắt trong bản build vẫn được ưu tiên.'),
    checkbox('chatbotEnabled','AI Chatbot',c.chatbotEnabled!==false,'Bật/tắt lối vào và điều kiện gọi AI trong bản app hỗ trợ.'),
    h('div',{class:'divider'}),checkbox('maintenanceMode','Chế độ bảo trì',c.maintenanceMode===true,'Hiển thị thông báo thay cho nội dung app với người dùng đang đăng nhập.'),
    field('maintenanceMessage','Thông báo bảo trì',c.maintenanceMessage,{type:'textarea',max:300,optional:true,hint:'Bắt buộc khi bật bảo trì. Tối đa 300 ký tự.'}),
    h('p',{class:'muted'},`Cập nhật gần nhất: ${date(c.updatedAt)}`),h('button',{type:'submit',class:'button'},'Kiểm tra và lưu cấu hình'));
    form.addEventListener('input',()=>{dirty=true;});
    syncStatus.textContent='Đang đồng bộ trực tiếp với máy chủ.';
    const reload=button('Tải cấu hình máy chủ',async()=>{if(await drafts.allow(['page'])){drafts.clear('page');configPage(content);}});
    content.replaceChildren(syncStatus,reload,h('section',{class:'panel config-wrap'},h('p',{class:'notice'},'Không cấu hình API key, secret hoặc tên model AI tại đây. Các giới hạn gói dịch vụ không thay đổi khi bật/tắt tính năng.'),form));
    },error=>{syncStatus.textContent=errorMessage(error);const submit=content.querySelector('[type=submit]');if(submit)submit.disabled=true;else content.replaceChildren(syncStatus,button('Thử tải lại',()=>configPage(content)));},()=>api.config());
  } catch(error){if(safeCurrent(g)&&p===pageGeneration)content.replaceChildren(h('p',{class:'error'},errorMessage(error)),button('Thử tải lại',()=>configPage(content)));}
}
async function closeEditor() { if(editorBusy&&editorCancel){editorCancel();clearEditor();}else if(!editorBusy&&await drafts.allow(['editor']))clearEditor(); }
document.querySelector('#close-editor').addEventListener('click',closeEditor);
document.querySelector('#cancel-editor').addEventListener('click',closeEditor);
dialog.addEventListener('cancel',event=>{event.preventDefault();closeEditor();});
editorForm.addEventListener('submit',async event=>{
  event.preventDefault(); if(editorBusy||!allowed||!editorAction)return;
  const g=generation,submit=document.querySelector('#submit-editor'),error=document.querySelector('#editor-error');
  editorBusy=true; submit.disabled=true; submit.textContent='Đang chờ máy chủ…'; error.textContent='';
  const controls=Array.from(editorForm.elements).map(el=>({el,disabled:el.disabled}));
  try { const operation=editorAction(editorForm); for(const {el} of controls)el.disabled=Boolean(!editorCancel||!['close-editor','cancel-editor'].includes(el.id)); await operation; if(!safeCurrent(g))return; dialog.close();drafts.clear('editor');notify(editorSuccess);if(editorSuccess==='Đã lưu thay đổi và nhật ký quản trị.')await openPage(currentPage,{force:true,history:'replace'}); }
  catch(e){if(safeCurrent(g))error.textContent=errorMessage(e);}
  finally{editorBusy=false;for(const {el,disabled} of controls)el.disabled=disabled;submit.disabled=false;submit.textContent='Xác nhận và lưu';}
});

try {
  const {connect}=await import('./firebase.mjs'); api=await connect(window.HEALTHMATE_ADMIN_CONFIG);
  api.authChanges(next=>{
    drafts.reset();disposePage();generation++;pageGeneration++;allowed=false;user=next;stopRole?.();stopRole=null;rows=[];rowsReady=false;filter='';clearEditor();
    if(!next){showAuth();return;}
    const g=generation;showAuth('Đang kiểm tra quyền quản trị với máy chủ…');
    stopRole=api.role(next.uid,enabled=>{
      if(g!==generation)return;
      if(!enabled){drafts.reset();allowed=false;pageGeneration++;rows=[];clearEditor();showAuth('Tài khoản chưa được cấp quyền admin hoặc chưa xác nhận được quyền từ máy chủ.');return;}
      if(!allowed){allowed=true;openPage(routePage(window.location?.hash,pages),{force:true,history:'replace'});}
    },()=>{if(g===generation){drafts.reset();allowed=false;pageGeneration++;rows=[];clearEditor();showAuth('Chưa xác nhận được quyền quản trị. Kiểm tra kết nối hoặc đăng nhập lại.');}});
  });
} catch(error) { root.replaceChildren(h('main',{class:'connecting'},brand(),h('h1',{},'Chưa mở được web quản trị'),h('p',{class:'error'},errorMessage(error)),h('p',{class:'muted'},'Kiểm tra kết nối, cấu hình Firebase và App Check trước khi thử lại.'),button('Tải lại',()=>location.reload()))); }

window.addEventListener('hashchange',async()=>{
  if(!allowed)return;const page=routePage(window.location?.hash,pages);
  if(page===currentPage)return;
  if(await openPage(page,{history:'none'})===false&&allowed)window.history?.replaceState(null,'',`#/${currentPage}`);
});
