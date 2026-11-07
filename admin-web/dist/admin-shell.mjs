export const adminPages = {
  overview:['Tổng quan','Tổng quan','Theo dõi tài khoản, Premium và hoạt động HealthMate.'],
  revenue:['Doanh thu','Doanh thu Premium','Theo dõi giao dịch và báo cáo. Premium hiện dùng giao dịch demo, chưa thu tiền thật.'],
  user_directory:['Khách hàng','Khách hàng','Quản lý tài khoản đã đồng bộ từ ứng dụng và quyền truy cập.'],
  food_catalog:['Thực phẩm','Danh mục thực phẩm','Quản lý món ăn, nguồn và thông tin dinh dưỡng dùng chung.'],
  workouts:['Bài tập luyện','Bài tập luyện','Tra cứu và xuất danh mục bài tập đang có trong mã nguồn HealthMate.'],
  chatbot:['AI Chatbot','AI Chatbot','Theo dõi cấu hình AI đang có trong ứng dụng.'],
  support:['Hỗ trợ khách hàng','Hỗ trợ khách hàng','Tiếp nhận, phản hồi và theo dõi yêu cầu từ khách hàng.'],
  app_config:['Cài đặt','Cài đặt ứng dụng','Điều chỉnh cấu hình áp dụng cho bản app hỗ trợ quản trị từ xa.'],
  admin_audit:['Nhật ký quản trị','Nhật ký quản trị','Lịch sử thay đổi đã được máy chủ xác nhận.'],
};

const paths = {
  overview:['M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z'],
  revenue:['M12 2v20M17 6H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6'],
  transactions:['M7 3h10v18l-2.5-1.5L12 21l-2.5-1.5L7 21zM10 8h4M10 12h4'],
  buyers:['M3 3h2l3 12h10l3-9H6M9 20h.01M18 20h.01'],
  user_directory:['M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2','M16 3a4 4 0 0 1 0 8','M22 21v-2a4 4 0 0 0-3-3.87'],
  food_catalog:['M7 3v5M4 3v5a3 3 0 0 0 6 0V3M7 11v10','M20 3c-4 0-5 5-5 9h5M20 3v18'],
  workouts:['M6 5v14M3 8v8M18 5v14M21 8v8M6 12h12'],
  chatbot:['M4 7h16v13H4zM12 3v4M9 16h6M1 11v5M23 11v5'],
  support:['M21 15a4 4 0 0 1-4 4H8l-5 3V7a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4z'],
  app_config:['M4 7h16M4 17h16M8 4v6M16 14v6'],
  admin_audit:['M3 12a9 9 0 1 0 3-6.7L3 8','M3 3v5h5M12 7v5l3 2'],
  menu:['M4 6h16M4 12h16M4 18h16'],
  logout:['M9 4H4v16h5M13 8l4 4-4 4M8 12h13'],
  heart:['M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8z'],
};
export function adminIcon(name) {
  const ns='http://www.w3.org/2000/svg',svg=document.createElementNS(ns,'svg');
  for(const [key,value] of Object.entries({viewBox:'0 0 24 24',fill:'none',stroke:'currentColor','stroke-width':'1.7','stroke-linecap':'round','stroke-linejoin':'round','aria-hidden':'true',focusable:'false'}))svg.setAttribute(key,value);
  for(const d of paths[name] ?? paths.overview){const p=document.createElementNS(ns,'path');p.setAttribute('d',d);svg.append(p);}
  if(name==='user_directory'){const circle=document.createElementNS(ns,'circle');circle.setAttribute('cx','9');circle.setAttribute('cy','7');circle.setAttribute('r','4');svg.append(circle);}
  if(name==='chatbot')for(const x of ['8','16']){const circle=document.createElementNS(ns,'circle');circle.setAttribute('cx',x);circle.setAttribute('cy','12');circle.setAttribute('r','1');svg.append(circle);}
  return svg;
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
      nav.append(h('button',{type:'button',class:`nav-button${currentPage===key?' active':''}`,'data-page':key,'aria-label':title,title,
        ...(currentPage===key?{'aria-current':'page'}:{}),onClick:()=>onNavigate(key)},
        h('span',{class:'nav-icon'},adminIcon(key)),h('span',{class:'nav-label'},title),
        key==='workouts'?h('span',{class:'nav-soon'},'Chỉ đọc'):null));
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
