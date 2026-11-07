import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {registerHooks} from 'node:module';
import {parseHTML} from 'linkedom';

const hooks=registerHooks({resolve(specifier,context,next){
  if(specifier==='./firebase.mjs'&&context.parentURL?.includes('/dist/app.mjs'))return{url:new URL('./support/connect-fixture.mjs',import.meta.url).href,shortCircuit:true};
  return next(specifier,context);
}});
let serial=0;
async function setup({member=false,pendingList=false,live=false,hash=''}={}) {
  const {window,document}=parseHTML(await readFile(new URL('../dist/index.html',import.meta.url),'utf8'));
  globalThis.window=window;globalThis.document=document;
  window.location={hash};window.history={pushState(_a,_b,value){window.location.hash=value;},replaceState(_a,_b,value){window.location.hash=value;}};
  window.HTMLElement.prototype.showModal=function(){this.setAttribute('open','');};window.HTMLElement.prototype.close=function(){this.removeAttribute('open');};
  const dialog=document.querySelector('#editor');dialog.showModal=()=>dialog.setAttribute('open','');dialog.close=()=>dialog.removeAttribute('open');
  Object.defineProperty(document.querySelector('#editor-form'),'elements',{configurable:true,get(){return this.querySelectorAll('input,select,textarea,button');}});
  Object.defineProperty(window.HTMLSelectElement.prototype,'value',{configurable:true,get(){return this.querySelector('option[selected]')?.value??this.querySelector('option')?.value??'';},set(value){for(const option of this.querySelectorAll('option'))option.toggleAttribute('selected',option.value===String(value));}});
  globalThis.FormData=class {constructor(form){this.values=[...form.querySelectorAll('input,textarea,select')].filter(el=>el.name&&!el.disabled&&(!(el.type==='checkbox')||el.checked)).map(el=>[el.name,el.value]);}*[Symbol.iterator](){yield* this.values;}};
  const stamp={seconds:1,nanoseconds:0,toDate:()=>new Date('2026-10-27T00:00:00Z')};
  const rows=Array.from({length:67},(_,i)=>({id:`qa-${i}`,name:i===56?'Cơm tấm sườn':'QA Món '+String(i).padStart(3,'0'),alternateNames:[],category:i%2?'Món chính':'Trái cây',isActive:true,kcalPer100g:130,proteinGPer100g:2,carbsGPer100g:28,fatGPer100g:.3,fiberGPer100g:null,sourceLabel:'Nguồn QA',sourceUrl:'https://example.com',isEstimated:true,updatedAt:stamp}));
  let release;const held=new Promise(resolve=>release=resolve);
  const api={emulator:true,projectId:'demo-healthmate-admin',rows,saves:[],listCalls:0,failSave:false,
    authChanges(callback){this.auth=callback;callback({uid:'admin',email:'admin@healthmate.local',emailVerified:true});},
    role(uid,data){this.roleData=data;data(!member);return()=>{};},
    async logout(){this.auth(null);},async counts(){return[67,3,0,0];},async config(){return{chatbotEnabled:true,foodScannerEnabled:true,maintenanceMode:false};},
    async registeredAccounts(){return this.registeredSummary ?? null;},
    async source(kind){if(pendingList)await held;if(kind==='support_tickets')return this.supportRows??[];if(kind.startsWith('demo_premium_'))return this.demoRows?.[kind] ?? [];return kind==='food_catalog'?this.rows:[{id:'member',email:'member@example.com',displayName:'Member',adminRole:null,control:null},{id:'admin',email:'admin@example.com',adminRole:{enabled:true}}];},
    async listPage(kind,{cursor=null,...range}={}){this.listCalls++;this.lastRange=range;const source=(await this.source(kind)).filter(row=>!range.lookupField||(range.lookupField==='name'?row.name.startsWith(range.lookupValue):row[range.lookupField==='id'?'id':range.lookupField]===range.lookupValue));const offset=cursor?.offset??0,rows=source.slice(offset,offset+25);return{rows,cursor:{id:rows.at(-1)?.id,offset:offset+25},hasMore:offset+25<source.length};},
    async exportRange(kind,{idFrom='',idTo='',isCurrent=()=>true}={}){const source=await this.source(kind);if(!isCurrent())throw Error('Phiên tải đã kết thúc.');return source.filter(row=>(!idFrom||row.id>=idFrom)&&(!idTo||row.id<=idTo));},
    async save(kind,id,payload,reason,version){this.saves.push({kind,id,payload,reason,version});if(this.failSave)throw Error('Lỗi nguồn QA');const row=this.rows.find(r=>r.id===id);if(row)Object.assign(row,payload);else this.rows.push({...payload,id});},
    release,
  };
  if(live){
    const listeners=new Map();api.liveListeners=listeners;
    const bind=(key,receive,error,options,initial)=>{
      const row={receive,error,active:true,options};
      if(!listeners.has(key))listeners.set(key,[]);listeners.get(key).push(row);
      Promise.resolve().then(initial).then(value=>{if(row.active&&(options?.isCurrent?.()??true))receive(value);}).catch(error);
      return()=>{row.active=false;};
    };
    api.emit=(key,value,error=false)=>{for(const row of listeners.get(key)??[])if(row.active&&(row.options?.isCurrent?.()??true))(error?row.error:row.receive)(value);};
    api.watchConfig=(next,error,opts)=>bind('config',next,error,opts,()=>api.config());
    api.watchCounts=(next,error,opts)=>bind('counts',next,error,opts,()=>api.counts());
    api.watchRegisteredAccounts=(next,error,opts)=>bind('registered',next,error,opts,()=>api.registeredAccounts());
    api.watchRange=(kind,range,next,error,opts)=>bind('range',next,error,opts,()=>api.exportRange(kind,range));
    api.watchPage=(kind,opts,next,error)=>bind('page:'+kind,next,error,opts,()=>api.listPage(kind,opts));
    api.watchSupportThread=(id,next,error,opts)=>bind('thread:'+id,next,error,opts,()=>api.supportThread(id));
  }
  globalThis.adminDomFixture=api;
  await import(`../dist/app.mjs?dom-test=${serial++}`);
  const flush=async()=>{for(let i=0;i<8;i++)await new Promise(resolve=>setImmediate(resolve));};
  const click=async el=>{assert.ok(el,'Expected control');el.dispatchEvent(new window.Event('click',{bubbles:true}));await flush();};
  const button=label=>[...document.querySelectorAll('button')].find(el=>el.textContent===label);
  const submit=async()=>{document.querySelector('#editor-form').dispatchEvent(new window.Event('submit',{cancelable:true}));await flush();};
  await flush();
  return{window,document,api,click,button,submit,flush};
}
test('dashboard distinguishes unavailable registered total from synced accounts; server paging and search stay page-local',async()=>{
  const t=await setup();
  assert.equal(t.document.querySelectorAll('.stat-number').length,4);
  assert.match(t.document.querySelector('#dashboard-accounts').textContent,/Tổng tài khoản đăng kýChưa có số liệu3 tài khoản đã đồng bộ/);
  assert.match(t.document.querySelector('#dashboard-operations').textContent,/chưa có bản thống kê đầy đủ/);
  await t.click(t.document.querySelector('[data-page="food_catalog"]'));
  assert.equal(t.document.querySelectorAll('tbody tr').length,25);
  await t.click(t.button('Sau'));
  assert.equal(t.document.querySelector('tbody td').textContent,'26');
  const search=t.document.querySelector('#list-search');search.value='com tam';search.dispatchEvent(new t.window.Event('input'));await t.flush();
  assert.equal(t.document.querySelectorAll('tbody tr').length,0,'page two must not claim a match on unseen page three');
  assert.match(t.document.querySelector('#list-status').textContent,/chỉ áp dụng trang này/);
  await t.click(t.button('Sau'));
  assert.equal(t.document.querySelectorAll('tbody tr').length,1);
  assert.match(t.document.querySelector('tbody').textContent,/Cơm tấm/);
  assert.equal(t.document.querySelector('tbody td').textContent,'51');
  assert.equal(t.api.listCalls,3,'each navigation fetches one page; filtering does not refetch');
});
test('archive requires review and reason, failure keeps draft, restore preserves row and source',async()=>{
  const t=await setup();await t.click(t.document.querySelector('[data-page="food_catalog"]'));
  await t.click(t.button('Xóa khỏi danh mục'));
  assert.equal(t.api.saves.length,0);
  assert.match(t.document.querySelector('#editor-title').textContent,/Xóa/);
  t.document.querySelector('[name="reason"]').value='QA kiểm tra';
  t.api.failSave=true;await t.submit();
  assert.match(t.document.querySelector('#editor-error').textContent,/Lỗi nguồn/);
  assert.ok(t.document.querySelector('#editor[open]'));
  t.api.failSave=false;await t.submit();
  assert.equal(t.api.rows[0].isActive,false);assert.equal(t.api.rows[0].sourceLabel,'Nguồn QA');
  await t.click(t.button('Khôi phục'));t.document.querySelector('[name="reason"]').value='QA khôi phục';await t.submit();
  assert.equal(t.api.rows[0].isActive,true);
});
test('ordinary account never renders private admin lists; revoked role clears visible data',async()=>{
  const denied=await setup({member:true});assert.equal(denied.document.querySelector('tbody'),null);assert.match(denied.document.body.textContent,/chưa được cấp quyền/);
  const t=await setup();await t.click(t.document.querySelector('[data-page="food_catalog"]'));
  t.api.roleData(false);await t.flush();assert.equal(t.document.querySelector('tbody'),null);assert.equal(t.document.querySelector('#editor[open]'),null);
});
test('account self/admin is protected; late data after logout cannot reappear',async()=>{
  const t=await setup();await t.click(t.document.querySelector('[data-page="user_directory"]'));
  assert.equal([...t.document.querySelectorAll('tbody button')].filter(b=>b.textContent==='Khóa truy cập').length,1);
  const delayed=await setup({pendingList:true});
  delayed.document.querySelector('[data-page="food_catalog"]').dispatchEvent(new delayed.window.Event('click'));
  await delayed.flush();await delayed.api.logout();delayed.api.release();await delayed.flush();
  assert.equal(delayed.document.querySelector('tbody'),null);assert.match(delayed.document.body.textContent,/Đăng nhập quản trị/);
});
test('catalog create validates nutrition before writing and detail safely shows user text',async()=>{
  const t=await setup();await t.click(t.document.querySelector('[data-page="food_catalog"]'));
  await t.click(t.button('+ Thêm món ăn'));
  const fields={id:'qa-created',name:'<script>do not run</script>',category:'Món chính',kcalPer100g:'150',proteinGPer100g:'5',carbsGPer100g:'25',fatGPer100g:'3',fiberGPer100g:'',sourceLabel:'QA',sourceUrl:'https://example.com',reason:'QA tạo'};
  for(const [key,value]of Object.entries(fields))t.document.querySelector(`[name="${key}"]`).value=value;
  t.document.querySelector('[name="isActive"]').checked=true;t.document.querySelector('[name="isEstimated"]').checked=true;
  t.document.querySelector('[name="kcalPer100g"]').value='-1';await t.submit();assert.equal(t.api.saves.length,0);assert.match(t.document.querySelector('#editor-error').textContent,/kcal/);
  t.document.querySelector('[name="kcalPer100g"]').value='150';await t.submit();assert.equal(t.api.saves.length,1);
  assert.equal(t.api.rows.at(-1).fiberGPer100g,null);assert.equal(t.document.querySelectorAll('#app script').length,0);
});
test('Google sign-in opens from login and handles popup rejection without a stuck button',async()=>{
  const t=await setup();await t.api.logout();await t.flush();
  let calls=0;
  t.api.loginGoogle=async()=>{calls++;throw{code:'auth/popup-blocked'};};
  await t.click(t.document.querySelector('#google-login'));
  assert.equal(calls,1);assert.match(t.document.querySelector('.error').textContent,/cửa sổ đăng nhập/);
  assert.equal(t.document.querySelector('#google-login').disabled,false);
  t.api.loginGoogle=async()=>{calls++;throw{code:'auth/popup-closed-by-user'};};
  await t.click(t.document.querySelector('#google-login'));
  assert.equal(calls,2);assert.match(t.document.querySelector('.error').textContent,/hủy đăng nhập/);
});

test('revenue page displays only simulated money, empty state and confirmed order totals',async()=>{
  const t=await setup();await t.click(t.document.querySelector('[data-page="revenue"]'));
  assert.match(t.document.querySelector('#page-content').textContent,/KHÔNG THU TIỀN/);
  assert.match(t.document.querySelector('#revenue-results').textContent,/Chưa có giao dịch/);
  const now=Date.now();
  t.api.demoRows={demo_premium_transactions:[{id:'demo-1',uid:'member',mode:'demo',planId:'premium_demo_30d',
    amountVnd:20000,currency:'VND',status:'simulated_paid',source:'demo_checkout',occurredAt:{toMillis:()=>now}}],
    demo_premium_accounts:[{id:'member',mode:'demo',planId:'premium_demo_30d',startedAt:{toMillis:()=>now-1000},expiresAt:{toMillis:()=>now+86400000}}]};
  await t.click(t.button('Tải lại'));
  assert.match(t.document.querySelector('#revenue-results').textContent,/20\.000đ/);
  assert.match(t.document.querySelector('#revenue-results').textContent,/demo-1/);
  assert.equal(t.document.querySelector('#revenue-summary .stats'),null,'no partial-period summary from display page');
  await t.click(t.button('Tổng hợp kỳ'));
  assert.match(t.document.querySelector('#revenue-summary').textContent,/20\.000đ/);
  assert.ok(t.button('Xuất Excel mô phỏng'));
  t.api.demoRows.demo_premium_transactions[0].mode='live';
  await t.click(t.button('Tải lại'));
  assert.match(t.document.querySelector('#revenue-results').textContent,/chưa hợp lệ/);
  assert.equal(t.document.querySelector('#revenue-summary .stats'),null);
});
test('support list filters and replies safely, retains failed draft/id and updates status',async()=>{
  const t=await setup();
  const stamp={toDate:()=>new Date(),toMillis:()=>Date.now(),seconds:1,nanoseconds:0};
  const ticket={id:'AbCdEfGhIjKlMnOpQrSt',uid:'member',title:'<script>QA</script>',description:'Không lưu được bữa sáng',type:'bug',status:'open',messageCount:0,createdAt:stamp,updatedAt:stamp};
  t.api.supportRows=[ticket];let sends=[];
  t.api.supportThread=async()=>({ticket,messages:[]});
  t.api.newSupportMessageId=()=> 'ZbCdEfGhIjKlMnOpQrSt';
  t.api.supportReply=async(id,msg,text)=>{sends.push({id,msg,text});if(t.api.failSave)throw Error('Chưa gửi được phản hồi');};
  t.api.supportStatus=async(id,status)=>{ticket.status=status;};
  await t.click(t.document.querySelector('[data-page="support"]'));
  assert.match(t.document.querySelector('tbody').textContent,/<script>QA/);
  assert.equal(t.document.querySelectorAll('#app script').length,0);
  await t.click(t.button('Xem & trả lời'));
  await t.click(t.button('Gửi phản hồi'));assert.equal(sends.length,0);
  t.api.failSave=true;
  t.document.querySelector('textarea').value='Bạn vui lòng thử cập nhật app.';
  await t.click(t.button('Gửi phản hồi'));
  assert.match(t.document.querySelector('.error').textContent,/Chưa gửi/);
  assert.equal(t.document.querySelector('textarea').value,'Bạn vui lòng thử cập nhật app.');
  t.api.failSave=false;await t.click(t.button('Gửi phản hồi'));
  assert.equal(sends.length,2);assert.equal(sends[0].msg,sends[1].msg);
  t.document.querySelector('[aria-label="Trạng thái xử lý"]').value='resolved';await t.click(t.button('Lưu trạng thái'));
  assert.equal(ticket.status,'resolved');
  await t.api.logout();await t.flush();assert.equal(t.document.querySelector('.support-thread'),null);
});

test('late support thread after logout never restores customer content',async()=>{
  const t=await setup();let release;
  t.api.supportRows=[{id:'AbCdEfGhIjKlMnOpQrSt',uid:'member',title:'QA riêng',type:'bug',status:'open'}];
  t.api.supportThread=()=>new Promise(resolve=>release=resolve);
  await t.click(t.document.querySelector('[data-page="support"]'));
  await t.click(t.button('Xem & trả lời'));await t.api.logout();
  release({ticket:{title:'Nội dung riêng tư'},messages:[]});await t.flush();
  assert.doesNotMatch(t.document.querySelector('#app').textContent,/Nội dung riêng tư/);
});

test('canceling a pending range export closes it and late rows never create a download',async()=>{
  const t=await setup();await t.click(t.document.querySelector('[data-page="food_catalog"]'));
  let release,receivedCurrent;
  t.api.exportRange=(_kind,{isCurrent})=>{receivedCurrent=isCurrent;return new Promise(resolve=>release=resolve);};
  let downloads=0;const original=URL.createObjectURL;URL.createObjectURL=()=>{downloads++;return'blob:qa';};
  try{
    await t.click(t.button('Xuất Excel theo khoảng mã'));
    t.document.querySelector('#editor-form').dispatchEvent(new t.window.Event('submit',{cancelable:true}));await t.flush();
    assert.equal(t.document.querySelector('#cancel-editor').disabled,false);
    await t.click(t.document.querySelector('#cancel-editor'));
    assert.equal(t.document.querySelector('#editor[open]'),null);assert.equal(receivedCurrent(),false);
    release(t.api.rows);await t.flush();assert.equal(downloads,0);
  }finally{URL.createObjectURL=original;}
});

test('revoked role while range export is pending discards all late private rows',async()=>{
  const t=await setup();await t.click(t.document.querySelector('[data-page="user_directory"]'));
  let release; t.api.exportRange=()=>new Promise(resolve=>release=resolve);
  let downloads=0;const original=URL.createObjectURL;URL.createObjectURL=()=>{downloads++;return'blob:qa';};
  try{
    await t.click(t.button('Xuất Excel theo khoảng mã'));
    t.document.querySelector('#editor-form').dispatchEvent(new t.window.Event('submit',{cancelable:true}));await t.flush();
    t.api.roleData(false);await t.flush();release([{id:'private',email:'private@example.com'}]);await t.flush();
    assert.equal(downloads,0);assert.doesNotMatch(t.document.body.textContent,/private@example/);
  }finally{URL.createObjectURL=original;}
});

test('canceling period summary prevents late totals and Excel from appearing',async()=>{
  const t=await setup();await t.click(t.document.querySelector('[data-page="revenue"]'));
  let release;t.api.exportRange=()=>new Promise(resolve=>release=resolve);
  await t.click(t.button('Tổng hợp kỳ'));await t.click(t.button('Hủy tổng hợp'));
  release([]);await t.flush();
  assert.match(t.document.querySelector('#revenue-summary').textContent,/Đã hủy/);
  assert.equal(t.document.querySelector('#revenue-summary .stats'),null);assert.equal(t.button('Xuất Excel mô phỏng'),undefined);
});

function dashboardReceipt(id,uid = 'member',at = Date.now()) {
  return {id,uid,mode:'demo',planId:'premium_demo_30d',amountVnd:20000,currency:'VND',
    status:'simulated_paid',source:'demo_checkout',occurredAt:{toMillis:() => at}};
}

test('dashboard aggregates the entire period beyond one page, shows five latest and accessible chart values',async() => {
  const t = await setup();
  const transactions = Array.from({length:61},(_,i) => dashboardReceipt(`demo-${i}`,`buyer-${i % 7}`));
  transactions.push(dashboardReceipt('outside-period','outside',Date.parse('2020-01-01T00:00:00Z')));
  const calls = [];
  t.api.exportRange = async(kind,options) => {calls.push({kind,options});return transactions;};
  await t.click(t.button('Tải lại dashboard'));
  assert.equal(calls.length,1);
  assert.equal(calls[0].kind,'demo_premium_transactions');
  assert.ok(calls[0].options.start && calls[0].options.end);
  assert.match(t.document.querySelector('#dashboard-revenue .stat-number').textContent,/1\.220\.000 ₫/);
  assert.equal(t.document.querySelector('#dashboard-transactions .stat-number').textContent,'61');
  assert.equal(t.document.querySelector('#dashboard-buyers .stat-number').textContent,'7');
  assert.equal(t.document.querySelectorAll('#dashboard-latest tbody tr').length,5);
  assert.ok(t.document.querySelector('#dashboard-chart svg[role="img"]'));
  assert.match(t.document.querySelector('#dashboard-chart details').textContent,/1\.220\.000 ₫/);
  assert.equal(t.document.querySelectorAll('#dashboard-chart [style]').length,0,'chart works without inline CSS under Hosting CSP');
  assert.match(t.document.querySelector('#page-content').textContent,/KHÔNG THU TIỀN/);
  await t.click(t.button('Xem tài khoản'));
  assert.equal(t.document.querySelectorAll('#dashboard-revenue').length,0);
  assert.ok(t.document.querySelector('#list-search'));
});

test('dashboard empty period is zero but failed or invalid receipts never become zero revenue',async() => {
  const t = await setup();
  assert.equal(t.document.querySelector('#dashboard-revenue .stat-number').textContent,'0 ₫');
  assert.match(t.document.querySelector('#dashboard-chart').textContent,/Chưa có giao dịch/);
  t.api.exportRange = async() => {throw Error('Vượt giới hạn 5.000 giao dịch; chọn kỳ ngắn hơn.');};
  await t.click(t.button('Tải lại dashboard'));
  assert.equal(t.document.querySelector('#dashboard-revenue .stat-number').textContent,'—');
  assert.match(t.document.querySelector('#dashboard-chart [role="alert"]').textContent,/5\.000/);
  assert.match(t.document.querySelector('#dashboard-operations').textContent,/3/);
  t.api.exportRange = async() => [{...dashboardReceipt('live'),mode:'live'}];
  await t.click(t.button('Thử tải doanh thu'));
  assert.equal(t.document.querySelector('#dashboard-revenue .stat-number').textContent,'—');
  assert.match(t.document.querySelector('#dashboard-chart [role="alert"]').textContent,/chưa hợp lệ/);
  t.api.exportRange = async() => [dashboardReceipt('valid')];
  await t.click(t.button('Thử tải doanh thu'));
  assert.equal(t.document.querySelector('#dashboard-revenue .stat-number').textContent,'20.000 ₫');
});

test('dashboard count/config failures do not hide revenue; missing config is never assumed enabled',async() => {
  const t = await setup();
  t.api.counts = async() => {throw Error('Lỗi tải tài khoản');};
  t.api.config = async() => null;
  t.api.exportRange = async() => [dashboardReceipt('valid')];
  await t.click(t.button('Tải lại dashboard'));
  assert.match(t.document.querySelector('#dashboard-accounts').textContent,/Chưa có số liệu/);
  assert.match(t.document.querySelector('#dashboard-operations [role="alert"]').textContent,/Lỗi tải tài khoản/);
  assert.equal(t.document.querySelector('#dashboard-revenue .stat-number').textContent,'20.000 ₫');
  assert.equal(t.document.querySelectorAll('#dashboard-features .feature-card').length,3);
  assert.equal(t.document.querySelectorAll('#dashboard-features .pill.off').length,3);
  assert.doesNotMatch(t.document.querySelector('#dashboard-features').textContent,/Đang bật/);
  t.api.counts = async() => [67,1000,0,0];
  await t.click(t.button('Thử tải tài khoản'));
  assert.match(t.document.querySelector('#dashboard-accounts').textContent,/1\.000 tài khoản đã đồng bộ/);
  assert.match(t.document.querySelector('#dashboard-accounts .stat-number').textContent,/Chưa có số liệu/);
});

test('dashboard uses trusted Auth aggregate independently of synced directory and never fabricates a missing total',async() => {
  const t = await setup();
  t.api.registeredSummary = {schemaVersion:1,source:'firebase_auth',method:'manual_snapshot',totalRegisteredAccounts:42,
    updatedAt:{toMillis:() => Date.now() - 10000}};
  await t.click(t.button('Tải lại dashboard'));
  assert.equal(t.document.querySelector('#dashboard-accounts .stat-number').textContent,'42');
  assert.match(t.document.querySelector('#dashboard-accounts .stat-foot').textContent,/Bản thống kê lúc/);
  assert.match(t.document.querySelector('#dashboard-operations').textContent,/Tài khoản đã đồng bộ3/);
  t.api.counts = async() => {throw Error('Failed directory count');};
  await t.click(t.button('Tải lại dashboard'));
  assert.equal(t.document.querySelector('#dashboard-accounts .stat-number').textContent,'42');
  t.api.registeredSummary.totalRegisteredAccounts = -1;
  await t.click(t.button('Tải lại dashboard'));
  assert.equal(t.document.querySelector('#dashboard-accounts .stat-number').textContent,'Chưa có số liệu');
  t.api.registeredAccounts = async() => {throw {code:'permission-denied'};};
  await t.click(t.button('Tải lại dashboard'));
  assert.equal(t.document.querySelector('#dashboard-accounts .stat-number').textContent,'Chưa có số liệu');
  assert.equal(t.document.querySelector('#dashboard-revenue .stat-number').textContent,'0 ₫');
});

test('changing dashboard periods discards late totals and refresh keeps the selected period',async() => {
  const t = await setup();
  let release;
  t.api.exportRange = () => new Promise(resolve => release = resolve);
  await t.click(t.button('Tải lại dashboard'));
  t.api.exportRange = async() => [dashboardReceipt('today')];
  const selector = t.document.querySelector('#dashboard-period');
  selector.value = 'today';selector.dispatchEvent(new t.window.Event('change'));await t.flush();
  assert.equal(t.document.querySelector('#dashboard-revenue .stat-number').textContent,'20.000 ₫');
  release([dashboardReceipt('old-1'),dashboardReceipt('old-2')]);await t.flush();
  assert.equal(t.document.querySelector('#dashboard-revenue .stat-number').textContent,'20.000 ₫');
  let selectedRange;
  t.api.exportRange = async(_kind,options) => {selectedRange = options;return [];};
  await t.click(t.button('Tải lại dashboard'));
  assert.equal(t.document.querySelector('#dashboard-period').value,'today');
  assert.equal(selectedRange.start,selectedRange.end);
});

test('dashboard pending results cannot reappear after logout, role revocation or navigation',async() => {
  for (const action of ['logout','revoke','navigate','refresh']) {
    const t = await setup();
    let release;
    t.api.exportRange = () => new Promise(resolve => release = resolve);
    await t.click(t.button('Tải lại dashboard'));
    t.api.exportRange = async() => [];
    if (action === 'logout') await t.api.logout();
    if (action === 'revoke') t.api.roleData(false);
    if (action === 'navigate') await t.click(t.document.querySelector('[data-page="food_catalog"]'));
    if (action === 'refresh') await t.click(t.button('Tải lại dashboard'));
    release([dashboardReceipt('private','PRIVATE-LATE-UID')]);await t.flush();
    assert.doesNotMatch(t.document.querySelector('#app').textContent,/PRIVATE-LATE-UID/);
    assert.notEqual(t.document.querySelector('#dashboard-revenue .stat-number')?.textContent,'20.000 ₫');
  }
});

test('dark sidebar keeps requested order, active page and existing data routes',async() => {
  const t=await setup();
  const labels=[...t.document.querySelectorAll('nav [data-page] .nav-label')].map(node=>node.textContent);
  assert.deepEqual(labels.slice(0,6),['Tổng quan','Doanh thu','Khách hàng','Thực phẩm','Bài tập luyện','AI Chatbot']);
  assert.equal(t.document.querySelector('nav [aria-current="page"]').dataset.page,'overview');
  await t.click(t.document.querySelector('[data-page="user_directory"]'));
  assert.equal(t.document.querySelector('nav [aria-current="page"]').dataset.page,'user_directory');
  assert.match(t.document.querySelector('h1').textContent,/Khách hàng/);
  assert.ok(t.document.querySelector('tbody'),'customer page retains the real directory flow');
});

test('sidebar account shows the authenticated identity and its logout clears private content',async() => {
  const t=await setup();
  assert.equal(t.document.querySelector('.sidebar-account-name').textContent,'admin@healthmate.local');
  assert.equal(t.document.querySelector('.sidebar-account-role').textContent,'Quản trị viên');
  assert.ok(t.document.querySelector('.sidebar-account [aria-label="Đăng xuất"]'));
  await t.click(t.document.querySelector('.sidebar-logout'));
  assert.ok(t.document.querySelector('#login-email'));
  assert.equal(t.document.querySelector('#dashboard-accounts'),null);
  assert.equal(t.document.querySelector('.sidebar-account-name'),null);
});

test('sidebar collapse and mobile drawer support toggle, scrim and Escape without losing current data',async() => {
  const t=await setup();
  await t.click(t.document.querySelector('#sidebar-toggle'));
  assert.ok(t.document.querySelector('.layout.sidebar-collapsed'));
  assert.equal(t.document.querySelector('#sidebar-toggle').getAttribute('aria-expanded'),'false');
  await t.click(t.document.querySelector('#sidebar-toggle'));
  assert.equal(t.document.querySelector('.layout.sidebar-collapsed'),null);
  t.window.matchMedia=()=>({matches:true});
  await t.click(t.document.querySelector('#sidebar-toggle'));
  assert.ok(t.document.querySelector('.layout.sidebar-open'));
  await t.click(t.document.querySelector('.sidebar-scrim'));
  assert.equal(t.document.querySelector('.layout.sidebar-open'),null);
  await t.click(t.document.querySelector('#sidebar-toggle'));
  const escape=new t.window.Event('keydown',{bubbles:true});escape.key='Escape';
  t.document.querySelector('#admin-sidebar').dispatchEvent(escape);await t.flush();
  assert.equal(t.document.querySelector('.layout.sidebar-open'),null);
  assert.ok(t.document.querySelector('#dashboard-accounts'));
});

test('workouts inspects the actual app catalog without backend queries or pretend write controls',async() => {
  const t=await setup(),before=t.api.listCalls;
  await t.click(t.document.querySelector('[data-page="workouts"]'));
  const content=t.document.querySelector('#page-content');
  assert.match(content.textContent,/Danh mục chỉ đọc/);
  assert.match(content.textContent,/Chưa hỗ trợ sửa bài tập từ xa/);
  assert.equal(content.querySelectorAll('tbody tr').length,33);
  assert.equal([...content.querySelectorAll('button')].some(button=>/Thêm|Sửa|Xóa/.test(button.textContent)),false);
  assert.equal(t.api.listCalls,before);
  assert.equal(t.api.saves.length,0);
});

test('AI management reads real configuration and editing still requires review and audit reason',async() => {
  const t=await setup();
  t.api.config=async()=>({chatbotEnabled:false,foodScannerEnabled:true,maintenanceMode:false,maintenanceMessage:''});
  await t.click(t.document.querySelector('[data-page="chatbot"]'));
  const cards=t.document.querySelectorAll('.ai-setting-card');
  assert.match(cards[0].textContent,/Đang tắt/);assert.match(cards[1].textContent,/Đang bật/);
  assert.equal(t.api.saves.length,0);
  await t.click(t.button('Điều chỉnh cấu hình'));
  t.document.querySelector('[name="chatbotEnabled"]').checked=true;
  t.document.querySelector('.config-form').dispatchEvent(new t.window.Event('submit',{cancelable:true}));await t.flush();
  assert.equal(t.api.saves.length,0,'review comes before any write');
  t.document.querySelector('[name="reason"]').value='Bật chatbot theo cấu hình đã duyệt';await t.submit();
  assert.equal(t.api.saves.length,1);assert.equal(t.api.saves[0].kind,'app_config');
  assert.equal(t.api.saves[0].payload.chatbotEnabled,true);
  assert.match(t.api.saves[0].reason,/đã duyệt/);
});

test('AI configuration handles missing/error states and discards late state after logout',async() => {
  const t=await setup();
  t.api.config=async()=>null;
  await t.click(t.document.querySelector('[data-page="chatbot"]'));
  assert.equal(t.document.querySelectorAll('.ai-setting-card .pill.off').length,2);
  assert.doesNotMatch(t.document.querySelector('#page-content').textContent,/Đang bật/);
  let release;t.api.config=()=>new Promise(resolve=>release=resolve);
  await t.click(t.document.querySelector('[data-page="chatbot"]'));
  await t.api.logout();release({chatbotEnabled:true,foodScannerEnabled:true});await t.flush();
  assert.equal(t.document.querySelector('.ai-settings-grid'),null);
});

test.after(()=>hooks.deregister());


test('live dashboard receives Auth, operational counts, config and receipts without a reload; old listeners stop',async()=>{
  const t=await setup({live:true});
  t.api.emit('registered',{schemaVersion:1,source:'firebase_auth',method:'realtime_auth_events',ready:true,totalRegisteredAccounts:7,updatedAt:{toMillis:()=>Date.now()}});
  t.api.emit('counts',[67,7,1,9]);
  t.api.emit('range',[dashboardReceipt('live-one'),dashboardReceipt('live-two')]);
  t.api.emit('config',{chatbotEnabled:false,foodScannerEnabled:true,maintenanceMode:true});
  t.api.emit('counts',Error('Mất kết nối thống kê'),true);await t.click(t.button('Thử tải tài khoản'));
  assert.equal(t.api.liveListeners.get('counts').filter(row=>row.active).length,1);
  assert.equal(t.document.querySelector('#dashboard-accounts .stat-number').textContent,'7');
  assert.match(t.document.querySelector('#dashboard-accounts').textContent,/đồng bộ trực tiếp/);
  assert.equal(t.document.querySelector('#dashboard-revenue .stat-number').textContent,'40.000 ₫');
  assert.match(t.document.querySelector('#dashboard-features').textContent,/Đang tắt/);
  await t.click(t.document.querySelector('[data-page="food_catalog"]'));
  assert.ok(t.api.liveListeners.get('range').every(row=>!row.active));
  t.api.emit('page:food_catalog',{rows:[{...t.api.rows[0],name:'Tên mới trực tiếp',isActive:false}],cursor:null,hasMore:false});
  assert.match(t.document.querySelector('tbody').textContent,/Tên mới trực tiếp/);
  assert.match(t.document.querySelector('tbody').textContent,/Đã xóa khỏi danh mục/);
  t.api.emit('page:food_catalog',Error('Mất kết nối máy chủ'),true);
  assert.equal(t.document.querySelector('tbody'),null);
  t.api.emit('page:food_catalog',{rows:[],cursor:null,hasMore:false});
  assert.match(t.document.querySelector('#data-content').textContent,/Chưa có dữ liệu/);
  await t.api.logout();await t.flush();
  assert.ok([...t.api.liveListeners.values()].flat().every(row=>!row.active));
});

test('live revenue updates the complete period and transaction page automatically and rejects stale snapshots',async()=>{
  const t=await setup({live:true});
  await t.click(t.document.querySelector('[data-page="revenue"]'));
  t.api.emit('range',[dashboardReceipt('arrived')]);
  t.api.emit('page:demo_premium_transactions',{rows:[dashboardReceipt('arrived')],cursor:null,hasMore:false});
  assert.match(t.document.querySelector('#revenue-summary').textContent,/20\.000đ/);
  assert.match(t.document.querySelector('#revenue-results').textContent,/arrived/);
  await t.click(t.button('Xem giao dịch'));
  assert.equal(t.api.liveListeners.get('range').filter(row=>row.active).length,1);
  await t.click(t.document.querySelector('[data-page="user_directory"]'));
  assert.ok(t.api.liveListeners.get('range').every(row=>!row.active));
  t.api.emit('page:user_directory',{rows:[{id:'new-member',displayName:'Khách vừa đăng ký',control:{status:'suspended'}}],cursor:null,hasMore:false});
  assert.match(t.document.querySelector('tbody').textContent,/Khách vừa đăng ký/);
  assert.match(t.document.querySelector('tbody').textContent,/Tạm khóa/);
  t.api.roleData(false);await t.flush();
  assert.equal(t.document.querySelector('tbody'),null);
  assert.ok([...t.api.liveListeners.values()].flat().every(row=>!row.active));
});

test('remote config updates retain a dirty form and confirmed version instead of overwriting the admin draft',async()=>{
  const t=await setup({live:true});await t.click(t.document.querySelector('[data-page="app_config"]'));
  const input=t.document.querySelector('[name="maintenanceMessage"]');input.value='Bản nháp chưa lưu';input.dispatchEvent(new t.window.Event('input',{bubbles:true}));
  t.api.emit('config',{chatbotEnabled:false,foodScannerEnabled:true,maintenanceMode:false,maintenanceMessage:'Máy khác vừa đổi'});
  assert.equal(input.value,'Bản nháp chưa lưu');
  assert.match(t.document.querySelector('#page-content').textContent,/Bản nháp được giữ/);
});

test('server lookup finds a food outside the visible page and clearing restores the normal list',async()=>{
  const t=await setup();await t.click(t.document.querySelector('[data-page="food_catalog"]'));
  t.document.querySelector('#lookup-field').value='name';t.document.querySelector('#lookup-value').value='Cơm tấm';
  t.document.querySelector('.server-lookup').dispatchEvent(new t.window.Event('submit',{cancelable:true}));await t.flush();
  assert.equal(t.document.querySelectorAll('tbody tr').length,1);assert.match(t.document.querySelector('tbody').textContent,/Cơm tấm/);
  assert.equal(t.api.lastRange.lookupValue,'Cơm tấm');assert.match(t.document.querySelector('#range-status').textContent,/phân biệt hoa và dấu/);
  await t.click(t.button('Xóa tra cứu'));assert.equal(t.document.querySelectorAll('tbody tr').length,25);
});

test('deep links survive authentication, support browser navigation and reject unknown routes',async()=>{
  const t=await setup({hash:'#/food_catalog'});assert.equal(t.document.querySelector('h1').textContent,'Danh mục thực phẩm');
  await t.click(t.document.querySelector('[data-page="user_directory"]'));assert.equal(t.window.location.hash,'#/user_directory');
  t.window.location.hash='#/food_catalog';t.window.dispatchEvent(new t.window.Event('hashchange'));await t.flush();assert.equal(t.document.querySelector('h1').textContent,'Danh mục thực phẩm');
  const unknown=await setup({hash:'#/not-a-page'});assert.equal(unknown.window.location.hash,'#/overview');
});

test('editor guards discard and beforeunload, and clears the guard after confirmed cancellation',async()=>{
  const t=await setup({hash:'#/food_catalog'});await t.click(t.button('+ Thêm món ăn'));
  t.document.querySelector('[name="name"]').value='Bản nháp';
  const unload=new t.window.Event('beforeunload',{cancelable:true});t.window.dispatchEvent(unload);assert.equal(unload.returnValue,'');
  await t.click(t.button('Hủy'));assert.ok(t.document.querySelector('#discard-dialog[open]'));
  await t.click(t.button('Ở lại'));assert.equal(t.document.querySelector('[name="name"]').value,'Bản nháp');assert.ok(t.document.querySelector('#editor[open]'));
  await t.click(t.button('Hủy'));await t.click(t.button('Bỏ thay đổi'));assert.equal(t.document.querySelector('#editor[open]'),null);
  const clean=new t.window.Event('beforeunload',{cancelable:true});t.window.dispatchEvent(clean);assert.notEqual(clean.returnValue,'');
});

test('dirty config stays on screen until discard; conflict disables save and offers confirmed reload',async()=>{
  const t=await setup({live:true,hash:'#/app_config'});
  const input=t.document.querySelector('[name="maintenanceMessage"]');input.value='Bản nháp';input.dispatchEvent(new t.window.Event('input',{bubbles:true}));
  await t.click(t.document.querySelector('[data-page="food_catalog"]'));assert.ok(t.document.querySelector('#discard-dialog[open]'));
  await t.click(t.button('Ở lại'));assert.equal(t.window.location.hash,'#/app_config');assert.equal(input.value,'Bản nháp');
  t.api.emit('config',{chatbotEnabled:false,foodScannerEnabled:true,maintenanceMode:false,maintenanceMessage:'Mới từ máy chủ'});
  assert.equal(t.document.querySelector('.config-form [type="submit"]').disabled,true);
  t.api.config=async()=>({chatbotEnabled:false,foodScannerEnabled:true,maintenanceMode:false,maintenanceMessage:'Mới từ máy chủ'});
  await t.click(t.button('Tải cấu hình máy chủ'));await t.click(t.button('Bỏ thay đổi'));
  assert.equal(t.document.querySelector('[name="maintenanceMessage"]').value,'Mới từ máy chủ');
  await t.click(t.document.querySelector('[data-page="food_catalog"]'));assert.equal(t.document.querySelector('#discard-dialog'),null);
});

test('revoking a role clears an open discard prompt and all private draft content',async()=>{
  const t=await setup({hash:'#/food_catalog'});await t.click(t.button('+ Thêm món ăn'));t.document.querySelector('[name="name"]').value='Private draft';
  await t.click(t.button('Hủy'));assert.ok(t.document.querySelector('#discard-dialog'));
  t.api.roleData(false);await t.flush();assert.equal(t.document.querySelector('#discard-dialog'),null);assert.equal(t.document.querySelector('#editor[open]'),null);
  assert.equal(t.document.querySelector('#editor-fields').childElementCount,0);
  assert.equal(t.document.querySelector('tbody'),null);assert.doesNotMatch(t.document.querySelector('#app').textContent,/Private draft/);
});

test('audit offers Vietnam day filtering and date-based export',async()=>{
  const t=await setup({hash:'#/admin_audit'});t.document.querySelector('#audit-start').value='2026-11-01';t.document.querySelector('#audit-end').value='2026-11-07';
  await t.click(t.button('Lọc theo ngày'));assert.equal(t.api.lastRange.start,'2026-11-01');assert.equal(t.api.lastRange.end,'2026-11-07');
  assert.match(t.document.querySelector('#list-status').textContent,/mới nhất lên đầu/);
  await t.click(t.button('Xuất Excel theo ngày'));assert.equal(t.document.querySelector('[name="start"]').value,'2026-11-01');assert.equal(t.document.querySelector('[name="idFrom"]'),null);
});

test('workouts show all 33 actual app exercises with accent-insensitive lookup and explicit read-only status',async()=>{
  const t=await setup({hash:'#/workouts'});assert.equal(t.document.querySelectorAll('tbody tr').length,33);
  assert.match(t.document.querySelector('#page-content').textContent,/Chưa hỗ trợ sửa bài tập từ xa/);
  const search=t.document.querySelector('[aria-label="Tìm bài tập"]');search.value='di bo';search.dispatchEvent(new t.window.Event('input'));await t.flush();
  assert.equal(t.document.querySelectorAll('tbody tr').length,3);assert.ok(t.button('Xuất danh mục đang lọc'));
});

test('support reply drafts guard navigation and thread retry stays available after a listener failure',async()=>{
  const t=await setup({live:true,hash:'#/support'}),id='DraftSupportTest1234';
  const ticket={id,uid:'member',title:'Synthetic draft test',description:'Initial request',type:'bug',status:'open',messageCount:0};
  t.api.supportRows=[ticket];t.api.supportThread=async()=>({ticket,messages:[]});
  await t.click(t.button('Tải lại'));await t.click(t.button('Xem & trả lời'));
  const input=t.document.querySelector('textarea');input.value='Phản hồi chưa gửi';input.dispatchEvent(new t.window.Event('input'));
  await t.click(t.document.querySelector('[data-page="food_catalog"]'));assert.ok(t.document.querySelector('#discard-dialog'));
  await t.click(t.button('Ở lại'));assert.equal(input.value,'Phản hồi chưa gửi');
  t.api.emit('thread:'+id,Error('Synthetic connection failure'),true);
  assert.equal(t.button('Tải lại trao đổi').disabled,false);await t.click(t.button('Tải lại trao đổi'));
  assert.equal(t.document.querySelector('textarea').value,'Phản hồi chưa gửi');
  await t.click(t.document.querySelector('[data-page="food_catalog"]'));await t.click(t.button('Bỏ thay đổi'));assert.equal(t.window.location.hash,'#/food_catalog');
});

test('logout failure is visible and does not discard the current admin session',async()=>{
  const t=await setup({hash:'#/food_catalog'});t.api.logout=async()=>{throw Error('Synthetic logout failure');};
  await t.click(t.document.querySelector('.sidebar-logout'));assert.match(t.document.querySelector('#notification').textContent,/Synthetic logout failure/);
  assert.ok(t.document.querySelector('#list-search'));
});

test('live support messages update while preserving an unsent reply and subscriptions stop on leaving the conversation',async()=>{
  const t=await setup({live:true});const id='AbCdEfGhIjKlMnOpQrSt',stamp={toDate:()=>new Date(),toMillis:()=>Date.now(),seconds:1,nanoseconds:0};
  const ticket={id,uid:'member',title:'Hỗ trợ trực tiếp',description:'Nội dung ban đầu',type:'bug',status:'open',messageCount:0,createdAt:stamp,updatedAt:stamp};
  t.api.supportRows=[ticket];t.api.supportThread=async()=>({ticket,messages:[]});
  await t.click(t.document.querySelector('[data-page="support"]'));await t.click(t.button('Xem & trả lời'));
  const input=t.document.querySelector('textarea');input.value='Tôi đang soạn phản hồi';
  t.api.emit('thread:'+id,{ticket:{...ticket,messageCount:1},messages:[{text:'Khách vừa bổ sung',role:'customer',createdAt:stamp}]});
  assert.match(t.document.querySelector('.support-thread').textContent,/Khách vừa bổ sung/);
  assert.equal(input.value,'Tôi đang soạn phản hồi');
  await t.click(t.button('← Danh sách'));assert.ok(t.api.liveListeners.get('thread:'+id).every(row=>!row.active));
});

test('support list snapshots retain the active search control and recover after a connection error',async()=>{
  const t=await setup({live:true});
  const stamp={seconds:1,nanoseconds:0,toDate:()=>new Date()};
  const ticket={id:'AbCdEfGhIjKlMnOpQrSt',uid:'member',title:'Cần hỗ trợ',type:'bug',status:'open',updatedAt:stamp};
  t.api.supportRows=[ticket];
  await t.click(t.document.querySelector('[data-page="support"]'));
  const input=t.document.querySelector('input[type="search"]');
  input.value='Cần hỗ trợ';input.dispatchEvent(new t.window.Event('input'));
  t.api.emit('page:support_tickets',{rows:[ticket,{...ticket,id:'BbCdEfGhIjKlMnOpQrSt'}],hasMore:false});
  assert.equal(t.document.querySelector('input[type="search"]'),input);
  assert.equal(input.value,'Cần hỗ trợ');
  t.api.emit('page:support_tickets',Error('Đang kết nối lại'),true);
  assert.ok(t.button('Thử lại'));
  t.api.emit('page:support_tickets',{rows:[ticket],hasMore:false});
  assert.match(t.document.querySelector('tbody').textContent,/Cần hỗ trợ/);
});

test('support keeps a draft across status updates and keeps one message ID across an uncertain send and reload',async()=>{
  const t=await setup({live:true}),id='AbCdEfGhIjKlMnOpQrSt';
  const stamp={seconds:1,nanoseconds:0,toDate:()=>new Date()};
  let ticket={id,uid:'member',title:'Hỗ trợ',description:'Nội dung',type:'bug',status:'open',messageCount:0,createdAt:stamp,updatedAt:stamp};
  t.api.supportRows=[ticket];t.api.supportThread=async()=>({ticket,messages:[]});
  t.api.supportStatus=async(_id,status)=>{ticket={...ticket,status};};
  const sent=[];let attempts=0;
  t.api.newSupportMessageId=()=>'ReplyFixture12345678';
  t.api.supportReply=async(_id,messageId,text)=>{sent.push([messageId,text]);if(++attempts===1)throw Error('Chưa xác nhận gửi');};
  await t.click(t.document.querySelector('[data-page="support"]'));await t.click(t.button('Xem & trả lời'));
  let input=t.document.querySelector('textarea');input.value='Bản nháp trả lời';input.dispatchEvent(new t.window.Event('input'));
  const select=t.document.querySelector('[aria-label="Trạng thái xử lý"]');select.value='in_progress';
  await t.click(t.button('Lưu trạng thái'));
  assert.equal(t.document.querySelector('textarea').value,'Bản nháp trả lời');
  await t.click(t.button('Gửi phản hồi'));
  assert.match(t.document.querySelector('[role="alert"]').textContent,/Chưa xác nhận gửi/);
  await t.click(t.button('Tải lại trao đổi'));
  assert.equal(t.document.querySelector('textarea').value,'Bản nháp trả lời');
  await t.click(t.button('Gửi phản hồi'));
  assert.deepEqual(sent,[[sent[0][0],'Bản nháp trả lời'],[sent[0][0],'Bản nháp trả lời']]);
  assert.equal(t.document.querySelector('textarea').value,'');
});
