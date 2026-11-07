import {demoRevenue} from './revenue-model.mjs';
import {dashboardPeriod, formatCount, formatMoney, registeredAccountSummary} from './dashboard-model.mjs';
import {adminIcon} from './admin-shell.mjs';
import {liveScope,observe} from './live-scope.mjs';

const loads = new WeakMap();
const periods = [['month','Tháng này'], ['today','Hôm nay'], ['week','7 ngày qua'], ['days30','30 ngày qua']];
const dateLabel = key => key.split('-').reverse().join('/');

export async function dashboardPage({host, api, h, button, openPage, errorMessage, isCurrent, initialPreset = 'month',onDispose}) {
  const revision = (loads.get(host) ?? 0) + 1;
  loads.set(host, revision);
  const scope = liveScope(host,() => isCurrent() && loads.get(host) === revision,onDispose), current = scope.current;
  const revenueScopeHost = {},accountsScopeHost={},configScopeHost={}; let stopRevenue,stopAccounts,stopConfig;
  let revenueTurn = 0, countsTurn = 0, configTurn = 0, preset = initialPreset, registered = null, syncedCount = null;
  const account = h('section',{class:'stat',id:'dashboard-accounts'});
  const metrics = h('div',{class:'stats dashboard-stats'});
  const revenueCards = ['dashboard-revenue','dashboard-transactions','dashboard-buyers'].map(id => h('section',{class:'stat',id}));
  metrics.append(account,...revenueCards);
  const chart = h('section',{class:'panel dashboard-chart',id:'dashboard-chart'});
  const latest = h('section',{class:'panel',id:'dashboard-latest'});
  const operations = h('section',{class:'panel',id:'dashboard-operations'});
  const features = h('section',{class:'panel',id:'dashboard-features'});
  const side = h('div',{class:'dashboard-side'},features,operations);
  const revenueStatus = h('p',{class:'muted',id:'dashboard-revenue-status','aria-live':'polite'});
  const selector = h('select',{'aria-label':'Kỳ doanh thu',id:'dashboard-period',onChange:() => {preset = selector.value;loadRevenue();}},
    ...periods.map(([value,label]) => h('option',{value},label)));
  selector.value = preset;
  const periodLabel = h('span',{class:'dashboard-period-label'});
  const message = error => errorMessage?.(error) ?? error.message;
  function stat(node, label, value, foot, {compact = false, accent = false} = {}) {
    const icon = {'dashboard-accounts':'user_directory','dashboard-revenue':'revenue','dashboard-transactions':'transactions','dashboard-buyers':'buyers'}[node.id];
    node.className = `stat${accent ? ' stat-accent' : ''}`;
    node.replaceChildren(h('div',{class:'stat-label'},label),
      h('div',{class:`stat-number${compact ? ' stat-unavailable' : ''}`},value),h('div',{class:'stat-foot'},foot),
      h('span',{class:'stat-symbol','aria-hidden':'true'},adminIcon(icon)));
  }
  function revenueState(text) {
    const labels = ['Doanh thu Premium · demo','Giao dịch Premium · demo','Khách mua Premium · demo'];
    revenueCards.forEach((node,i) => stat(node,labels[i],'—',text,{accent:i === 0}));
  }
  function renderAccounts() {
    if (registered) {
      const updated = new Intl.DateTimeFormat('vi-VN',{dateStyle:'short',timeStyle:'short',timeZone:'Asia/Ho_Chi_Minh'}).format(new Date(registered.updatedAt));
      stat(account,'Tổng tài khoản đăng ký',formatCount(registered.count),`Bản thống kê lúc ${updated} (UTC+7) · ${registered.live?'đồng bộ trực tiếp':'cập nhật thủ công'}`);
    } else stat(account,'Tổng tài khoản đăng ký','Chưa có số liệu',syncedCount === null
      ? 'Cần cập nhật thống kê đầy đủ từ Firebase Authentication.' : `${formatCount(syncedCount)} tài khoản đã đồng bộ từ app`,{compact:true});
  }
  async function loadRegistered() {
    try {
      return await observe(scope,api,'watchRegisteredAccounts',[],data=>{
        try {registered=registeredAccountSummary(data);} catch {registered=null;}
        renderAccounts();
      },()=>{registered=null;renderAccounts();},()=>api.registeredAccounts());
    } catch {
      // Old production Rules may not yet expose this aggregate. Never replace
      // it with the incomplete directory count, or hide the rest of the page.
      if (current()) {registered = null;renderAccounts();}
    }
  }
  async function loadAccounts() {
    stopAccounts?.();const accountScope=liveScope(accountsScopeHost,current,scope.add);stopAccounts=accountScope.stop;
    const turn = ++countsTurn, active = () => current() && turn === countsTurn;
    operations.replaceChildren(h('p',{class:'loading'},'Đang tải số liệu vận hành…'));
    try {
      return await observe(accountScope,api,'watchCounts',[],counts=>{
      if (!active()) return;
      if (!Array.isArray(counts) || counts.length !== 4) throw Error('Số liệu thống kê chưa hợp lệ.');
      const values = counts.map(formatCount);
      syncedCount = counts[1];renderAccounts();
      operations.replaceChildren(h('div',{class:'panel-title'},h('h2',{},'Tài khoản & vận hành'),button('Xem tài khoản',() => openPage('user_directory'))),
        h('dl',{class:'dashboard-counts'},...[[1,'Tài khoản đã đồng bộ'],[2,'Tài khoản tạm khóa'],[0,'Món trong danh mục'],[3,'Thao tác quản trị']].map(([i,label]) =>
          h('div',{},h('dt',{},label),h('dd',{},values[i])))),
        h('details',{class:'dashboard-account-help'},h('summary',{},'Cách tính tài khoản'),
          h('p',{class:'muted dashboard-source'},'Tổng đăng ký lấy từ Firebase Authentication, gồm cả admin, tài khoản chưa xác minh và đã vô hiệu hóa còn tồn tại; không phải số đang online. Thống kê trực tiếp do máy chủ cập nhật sau khi khởi tạo. Bản thủ công cũ có nhãn riêng; chưa có bản thống kê đầy đủ thì hiển thị “Chưa có số liệu”.')),
        button('Xem nhật ký quản trị',() => openPage('admin_audit')));
      },error=>{syncedCount=null;renderAccounts();operations.replaceChildren(h('p',{class:'error',role:'alert'},message(error)),button('Thử tải tài khoản',loadAccounts));},()=>api.counts());
    } catch (error) {
      if (!active()) return;
      syncedCount = null;renderAccounts();
      operations.replaceChildren(h('h2',{},'Tài khoản & vận hành'),h('p',{class:'error',role:'alert'},message(error)),button('Thử tải tài khoản',loadAccounts));
    }
  }
  async function loadConfig() {
    stopConfig?.();const configScope=liveScope(configScopeHost,current,scope.add);stopConfig=configScope.stop;
    const turn = ++configTurn, active = () => current() && turn === configTurn;
    features.replaceChildren(h('p',{class:'loading'},'Đang tải trạng thái tính năng…'));
    try {
      return await observe(configScope,api,'watchConfig',[],config=>{
      if (!active()) return;
      features.replaceChildren(h('div',{class:'panel-title'},h('h2',{},'Trạng thái tính năng'),button('Điều chỉnh',() => openPage('app_config'))));
      for (const [label,key] of [['Quét món bằng AI','foodScannerEnabled'],['AI Chatbot','chatbotEnabled'],['Chế độ bảo trì','maintenanceMode']]) {
        const value = config?.[key], known = typeof value === 'boolean';
        features.append(h('div',{class:'feature-card'},h('strong',{},label),
          h('span',{class:`pill${known && value ? '' : ' off'}`},known ? value ? 'Đang bật' : 'Đang tắt' : 'Chưa có cấu hình')));
      }
      features.append(h('p',{class:'muted dashboard-source'},'Trạng thái theo cấu hình quản trị, áp dụng cho bản app hỗ trợ. Không xác nhận dịch vụ AI đang hoạt động.'));
      },error=>features.replaceChildren(h('p',{class:'error',role:'alert'},message(error)),button('Thử tải cấu hình',loadConfig)),()=>api.config());
    } catch (error) {
      if (active()) features.replaceChildren(h('h2',{},'Trạng thái tính năng'),h('p',{class:'error',role:'alert'},message(error)),button('Thử tải cấu hình',loadConfig));
    }
  }
  async function loadRevenue() {
    stopRevenue?.();
    const revenueScope=liveScope(revenueScopeHost,current,scope.add);stopRevenue=revenueScope.stop;
    const turn = ++revenueTurn, active = () => current() && turn === revenueTurn;
    const range = dashboardPeriod(preset);
    periodLabel.textContent = `${dateLabel(range.start)} – ${dateLabel(range.end)} · giờ Việt Nam (UTC+7)`;
    revenueState('Đang tải giao dịch trong kỳ…');
    revenueStatus.textContent = 'Đang tổng hợp đầy đủ giao dịch trong kỳ…';
    chart.replaceChildren(h('p',{class:'loading'},'Đang tải biểu đồ doanh thu…'));
    latest.replaceChildren(h('p',{class:'loading'},'Đang tải giao dịch gần đây…'));
    try {
      return await observe(revenueScope,api,'watchRange',['demo_premium_transactions',range],rows=>{
      if (!active()) return;
      const report = demoRevenue(rows,[],range);
      stat(revenueCards[0],'Doanh thu Premium · demo',formatMoney(report.amountVnd),'Tổng giao dịch mô phỏng trong kỳ',{accent:true});
      stat(revenueCards[1],'Giao dịch Premium · demo',formatCount(report.count),'Giao dịch mô phỏng thành công');
      stat(revenueCards[2],'Khách mua Premium · demo',formatCount(report.buyers),'Số tài khoản mua khác nhau trong kỳ');
      const time = new Intl.DateTimeFormat('vi-VN',{hour:'2-digit',minute:'2-digit',timeZone:'Asia/Ho_Chi_Minh'}).format(new Date());
      revenueStatus.textContent = `Doanh thu cập nhật lúc ${time} · ${formatCount(report.count)} giao dịch đã tải đủ trong kỳ. Tự động nhận thay đổi từ máy chủ.`;
      chart.replaceChildren(h('div',{class:'panel-title'},h('h2',{},'Doanh thu Premium theo ngày'),h('span',{class:'pill off'},'DEMO')),
        !report.count ? h('p',{class:'chart-empty'},'Chưa có giao dịch Premium demo trong kỳ này.') : null,
        revenueChart(report.days,h,chart.clientWidth ? Math.max(260,Math.min(640,chart.clientWidth - 46)) : 640),
        h('p',{class:'muted dashboard-source'},'Chỉ cộng giao dịch mô phỏng 20.000 ₫ / 30 ngày. Ngày không có giao dịch được tính là 0.'));
      latest.replaceChildren(h('div',{class:'panel-title'},h('h2',{},'Giao dịch gần đây'),button('Xem báo cáo & xuất Excel',() => openPage('revenue'))));
      if (!report.count) latest.append(h('p',{class:'empty'},'Giao dịch mới sẽ xuất hiện tại đây sau khi người dùng mua gói demo.'));
      else {
        const table = h('table',{},h('thead',{},h('tr',{},...['Thời điểm (VN)','Tài khoản (UID)','Số tiền demo'].map(title => h('th',{},title)))),
          h('tbody',{},...report.transactions.slice(0,5).map(row => h('tr',{},
            h('td',{},new Intl.DateTimeFormat('vi-VN',{dateStyle:'short',timeStyle:'short',timeZone:'Asia/Ho_Chi_Minh'}).format(new Date(row.at))),
            h('td',{class:'dashboard-uid'},row.uid),h('td',{class:'number'},formatMoney(row.amountVnd))))));
        latest.append(h('div',{class:'table-wrap',tabIndex:0,'aria-label':'5 giao dịch Premium demo gần nhất trong kỳ'},table));
      }
      },showRevenueError,()=>api.exportRange('demo_premium_transactions',{...range,isCurrent:active}));
    } catch (error) {showRevenueError(error);}
    function showRevenueError(error) {
      if (!active()) return;
      revenueState('Chưa tổng hợp được kỳ này');
      revenueStatus.textContent = 'Chưa có tổng doanh thu được xác nhận cho kỳ này.';
      chart.replaceChildren(h('h2',{},'Doanh thu Premium'),h('p',{class:'error',role:'alert'},message(error)),button('Thử tải doanh thu',loadRevenue));
      latest.replaceChildren(h('h2',{},'Giao dịch gần đây'),h('p',{class:'muted'},'Chưa nhận đủ dữ liệu. Chờ kết nối lại hoặc chọn kỳ ngắn hơn.'));
    }
  }
  host.replaceChildren(h('div',{class:'dashboard-toolbar'},
      h('label',{class:'filter-field'},'Kỳ doanh thu',selector),periodLabel,button('Tải lại dashboard',() => dashboardPage({host,api,h,button,openPage,errorMessage,isCurrent,initialPreset:preset,onDispose}))),
    h('p',{class:'notice local dashboard-demo'},'PREMIUM DEMO · KHÔNG THU TIỀN. Doanh thu dưới đây là số tiền mô phỏng, chưa phải doanh thu thực nhận.'),
    metrics,revenueStatus,h('div',{class:'dashboard-hero-grid'},chart,side),latest);
  renderAccounts();
  if(api.watchRange){
    let midnightTimer;
    function scheduleDay(){
      const day=86400000,offset=7*3600000;
      const next=(Math.floor((Date.now()+offset)/day)+1)*day-offset;
      midnightTimer=setTimeout(()=>{if(current()){loadRevenue();scheduleDay();}},next-Date.now()+100);
      midnightTimer.unref?.();
    }
    scheduleDay();scope.add(()=>clearTimeout(midnightTimer));
  }
  await Promise.allSettled([loadRegistered(),loadAccounts(),loadConfig(),loadRevenue()]);
}

function revenueChart(days,h,width = 640) {
  // SVG geometry uses presentation attributes so the chart also works under
  // Hosting's style-src 'self' policy (no inline CSS or chart dependency).
  const svg = (tag,props = {},...children) => {
    const node = document.createElementNS('http://www.w3.org/2000/svg',tag);
    for (const [key,value] of Object.entries(props)) node.setAttribute(key,String(value));
    node.append(...children.map(child => typeof child === 'string' ? document.createTextNode(child) : child));
    return node;
  };
  const max = Math.max(...days.map(day => day.amountVnd),20000), left = 70, top = 24, height = width < 420 ? 160 : 236, plotWidth = width - left - 20;
  const step = plotWidth / Math.max(days.length - 1,1);
  const plot = svg('svg',{viewBox:`0 0 ${width} ${height + 94}`,role:'img','aria-label':'Biểu đồ đường doanh thu Premium mô phỏng theo ngày',class:'dashboard-revenue-svg'},
    svg('title',{},'Doanh thu Premium mô phỏng theo ngày. Mở bảng số liệu để xem giá trị từng ngày.'));
  plot.append(svg('defs',{},svg('linearGradient',{id:'revenue-area-fill',x1:'0',y1:'0',x2:'0',y2:'1'},
    svg('stop',{offset:'0%',class:'chart-area-stop-top'}),svg('stop',{offset:'100%',class:'chart-area-stop-bottom'}))));
  for (let i = 0; i <= 2; i++) {
    const y = top + height * i / 2;
    plot.append(svg('line',{x1:left,x2:left + plotWidth,y1:y,y2:y,class:'chart-grid'}),
      svg('text',{x:left - 10,y:y + 4,'text-anchor':'end',class:'chart-label'},Math.round(max * (1 - i / 2)).toLocaleString('vi-VN')));
  }
  const labelEvery = Math.max(1,Math.ceil((days.length - 1) / Math.max(2,Math.floor(plotWidth / 85))));
  const points = days.map((day,i) => ({x:days.length === 1 ? left + plotWidth / 2 : left + i * step,y:top + height - day.amountVnd / max * height,day}));
  const line = points.map((point,i) => `${i ? 'L' : 'M'}${point.x} ${point.y}`).join(' ');
  if (points.length) plot.append(svg('path',{d:`${line} L${points.at(-1).x} ${top + height} L${points[0].x} ${top + height} Z`,class:'chart-area'}),svg('path',{d:line,class:'chart-line'}));
  points.forEach(({x,y,day},i) => {
    plot.append(svg('circle',{cx:x,cy:y,r:days.length > 15 ? 2.5 : 4,class:'chart-dot'},
      svg('title',{},`${dateLabel(day.day)}: ${formatMoney(day.amountVnd)}, ${day.transactions} giao dịch demo`)));
    if (i % labelEvery === 0 || i === days.length - 1) plot.append(svg('text',{
      x,y:top + height + 30,'text-anchor':'middle',class:'chart-label'},day.day.slice(5).split('-').reverse().join('/')));
  });
  return h('div',{},plot,h('details',{class:'dashboard-chart-data'},h('summary',{},'Xem số liệu từng ngày'),
    h('div',{class:'table-wrap'},h('table',{},h('thead',{},h('tr',{},...['Ngày (VN)','Giao dịch demo','Doanh thu demo'].map(label => h('th',{},label)))),
      h('tbody',{},...days.map(day => h('tr',{},h('td',{},dateLabel(day.day)),h('td',{},formatCount(day.transactions)),h('td',{},formatMoney(day.amountVnd)))))))));
}
