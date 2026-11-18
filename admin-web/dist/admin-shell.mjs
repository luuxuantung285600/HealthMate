import {iconNodes} from './admin-icons.mjs';

export const adminPages = {
  overview:['Tổng quan','Tổng quan','Theo dõi tài khoản, Premium và hoạt động HealthMate.'],
  revenue:['Doanh thu','Doanh thu Premium','Theo dõi giao dịch và báo cáo theo nguồn dữ liệu đã chọn.'],
  user_directory:['Khách hàng','Khách hàng','Quản lý tài khoản đã đồng bộ từ ứng dụng và quyền truy cập.'],
  food_catalog:['Thực phẩm','Danh mục thực phẩm','Quản lý món ăn, nguồn và thông tin dinh dưỡng dùng chung.'],
  workouts:['Bài tập luyện','Thư viện bài tập','Quản lý động tác, hướng dẫn và minh họa đồng bộ với ứng dụng.'],
  chatbot:['AI Chatbot','AI Chatbot','Theo dõi cấu hình AI đang có trong ứng dụng.'],
  support:['Hỗ trợ khách hàng','Hỗ trợ khách hàng','Tiếp nhận, phản hồi và theo dõi yêu cầu từ khách hàng.'],
  app_config:['Cài đặt','Cài đặt ứng dụng','Điều chỉnh cấu hình áp dụng cho bản app hỗ trợ quản trị từ xa.'],
  admin_audit:['Nhật ký quản trị','Nhật ký quản trị','Lịch sử thay đổi đã được máy chủ xác nhận.'],
};

export const pageFeatures = {
  overview:'goals', revenue:'premium', user_directory:'profile',
  food_catalog:'nutrition', workouts:'workout', chatbot:'chatbot',
  support:'support', admin_audit:'report', app_config:'profile',
};
export function adminIcon(name) {
  const ns='http://www.w3.org/2000/svg',svg=document.createElementNS(ns,'svg');
  for(const [key,value] of Object.entries({viewBox:'0 0 24 24',width:'24',height:'24',fill:'none',stroke:'currentColor','stroke-width':'2','stroke-linecap':'round','stroke-linejoin':'round','aria-hidden':'true',focusable:'false','data-icon':name}))svg.setAttribute(key,value);
  for(const [tag,attributes] of iconNodes[name] ?? iconNodes.overview){
    const node=document.createElementNS(ns,tag);
    for(const [key,value] of Object.entries(attributes))node.setAttribute(key,value);
    svg.append(node);
  }
  return svg;
}

export function appearanceControl(h) {
  const control=h('select',{'data-admin-theme':'','aria-label':'Giao diện',title:'Giao diện: theo thiết bị, sáng hoặc tối',
    onChange:event=>window.HealthMateAppearance?.setPreference(event.target.value)},
    h('option',{value:'system'},'Thiết bị'),h('option',{value:'light'},'Sáng'),h('option',{value:'dark'},'Tối'));
  control.value=window.HealthMateAppearance?.getPreference()??'system';
  return h('label',{class:'appearance-control'},adminIcon('sun'),control);
}

export function adminBrand(h) {
  return h('div',{class:'brand'},h('span',{class:'brand-mark'},adminIcon('heart')),h('div',{class:'brand-name'},'HealthMate',h('small',{},'ADMIN DASHBOARD')));
}

export function renderAdminShell({root,h,currentPage,user,onNavigate,onLogout,emulator=false,environmentLabel}) {
  const name=user?.displayName||user?.email||user?.uid;
  const nav=h('nav',{class:'nav-group','aria-label':'Quản trị'});
  for(const [label,keys] of [['QUẢN LÝ',['overview','revenue','user_directory','food_catalog','workouts','chatbot']],['VẬN HÀNH',['support','admin_audit','app_config']]]){
    nav.append(h('p',{class:'nav-heading'},label));
    for(const key of keys){
      const title=adminPages[key][0];
      nav.append(h('button',{type:'button',class:`nav-button feature-${pageFeatures[key]}${currentPage===key?' active':''}`,'data-page':key,'aria-label':title,title,
        ...(currentPage===key?{'aria-current':'page'}:{}),onClick:()=>onNavigate(key)},
        h('span',{class:'nav-icon'},adminIcon(key)),h('span',{class:'nav-label'},title)));
    }
  }
  const sidebar=h('aside',{class:'sidebar',id:'admin-sidebar'},adminBrand(h),nav,
    h('div',{class:'sidebar-bottom sidebar-account'},
      name?h('span',{class:'avatar','aria-hidden':'true'},name[0].toUpperCase()):h('span',{class:'sidebar-status'}),
      h('div',{class:'sidebar-account-info nav-label'},
        h('span',{class:'sidebar-account-name',title:name||'HealthMate Admin'},name||'HealthMate Admin'),
        h('small',{class:'sidebar-account-role'},name?'Quản trị viên':'Không gian quản trị')),
      onLogout?h('button',{type:'button',class:'header-icon sidebar-logout','aria-label':'Đăng xuất',title:'Đăng xuất',onClick:onLogout},adminIcon('logout')):null));
  const main=h('main',{class:'main',id:'main-content'});
  const mobile=()=>window.matchMedia?.('(max-width: 900px)').matches??false;
  const toggle=h('button',{type:'button',class:'header-icon',id:'sidebar-toggle','aria-label':'Thu gọn hoặc mở menu','aria-controls':'admin-sidebar','aria-expanded':!mobile()},adminIcon('menu'));
  const scrim=h('button',{type:'button',class:'sidebar-scrim',tabIndex:-1,'aria-label':'Đóng menu'});
  const identity=h('div',{class:'identity'},h('span',{class:`environment${emulator?'':' cloud'}`},environmentLabel??(emulator?'LOCAL · EMULATOR':'FIREBASE')),
    h('span',{class:'locale-label'},'VI'),
    appearanceControl(h),
    h('button',{type:'button',class:'header-icon','aria-label':'Mở cài đặt',onClick:()=>onNavigate('app_config')},adminIcon('app_config')),
    name?h('span',{class:'avatar',title:name,'aria-label':name},name[0].toUpperCase()):null);
  const layout=h('div',{class:'layout'},sidebar,scrim,h('div',{class:'workspace'},h('header',{class:'topbar'},
    h('div',{class:'header-start'},toggle,h('span',{class:'breadcrumb'},'Không gian quản trị',h('span',{},'/'),h('strong',{},adminPages[currentPage][0]))),identity),main));
  function close(){layout.classList.remove('sidebar-open');toggle.setAttribute('aria-expanded',String(!mobile()&&!layout.classList.contains('sidebar-collapsed')));toggle.focus?.();}
  toggle.addEventListener('click',()=>{
    if(mobile())layout.classList.remove('sidebar-collapsed');
    const open=mobile()?layout.classList.toggle('sidebar-open'):!layout.classList.toggle('sidebar-collapsed');
    toggle.setAttribute('aria-expanded',String(open));
    if(open&&mobile()){
      // Wait for the hidden drawer to become visible before moving focus.
      // Ignore a scheduled focus if navigation has already replaced the shell.
      const focusMenu=()=>{if(layout.isConnected&&layout.classList.contains('sidebar-open'))nav.querySelector('button:not([disabled])')?.focus?.();};
      if(window.requestAnimationFrame)window.requestAnimationFrame(()=>window.requestAnimationFrame(focusMenu));
      else focusMenu();
    }
  });
  scrim.addEventListener('click',close);
  layout.addEventListener('keydown',event=>{
    if(!layout.classList.contains('sidebar-open'))return;
    if(event.key==='Escape')close();
    if(event.key==='Tab'){
      const items=[...sidebar.querySelectorAll('button:not([disabled])')];
      const first=items[0],last=items.at(-1);
      if(event.shiftKey&&document.activeElement===first){event.preventDefault();last?.focus?.();}
      else if(!event.shiftKey&&document.activeElement===last){event.preventDefault();first?.focus?.();}
    }
  });
  root.replaceChildren(layout);
  return main;
}
