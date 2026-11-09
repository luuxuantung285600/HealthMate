import {revenuePage as demoRevenuePage} from './revenue-page.mjs';
import {verifiedRevenue,verifiedRevenueExport,formatNanos} from './verified-revenue.mjs';
import {vietnamDateKey,dateBoundary} from './revenue-model.mjs';
import {liveScope,observe} from './live-scope.mjs';
import {downloadReport} from './report-download.mjs';

export async function revenuePage(args){
  const {host,h,isCurrent,onDispose}=args;
  const scope=liveScope(host,isCurrent,onDispose),body=h('div',{});
  let turn=0;
  const mode=h('select',{id:'revenue-environment','aria-label':'Nguồn doanh thu',onChange:render},
    h('option',{value:'production'},'Google Play · tiền thật'),h('option',{value:'test'},'Google Play · thử nghiệm'),h('option',{value:'demo'},'Demo mô phỏng · không thu tiền'));
  mode.value='production';
  host.replaceChildren(h('label',{class:'field'},'Nguồn doanh thu',mode),body);
  async function render(){
    const captured=++turn,environment=mode.value;
    const options={...args,host:body,isCurrent:()=>scope.current()&&captured===turn,onDispose:scope.add};
    if(environment==='demo')return demoRevenuePage(options);
    return playRevenuePage({...options,environment});
  }
  await render();
}

async function playRevenuePage({host,api,h,button,isCurrent,onDispose,environment}){
  const scope=liveScope(host,isCurrent,onDispose),current=scope.current,reportHost={},detailHost={};
  let stopReport,stopDetails,epoch=0,report=null,cursors=[null],range;
  const today=vietnamDateKey(new Date());
  const start=h('input',{type:'date',value:`${today.slice(0,7)}-01`,'aria-label':'Từ ngày',onChange:invalidate});
  const end=h('input',{type:'date',value:today,'aria-label':'Đến ngày',onChange:invalidate});
  const summary=h('div',{id:'revenue-summary'}),details=h('div',{id:'revenue-results'});
  function invalidate(){epoch++;stopReport?.();stopDetails?.();report=null;summary.replaceChildren();details.replaceChildren(h('p',{},'Chọn Xem giao dịch để tải kỳ mới.'));}
  function selected(){const lower=dateBoundary(start.value),upper=dateBoundary(end.value)+86400000;if(upper<=lower||upper-lower>366*86400000)throw Error('Chọn kỳ từ 1 đến 366 ngày.');return {start:start.value,end:end.value,environment};}
  const amount=(row,key)=>row[key]==null||row.reconciliationPending?'Chờ đối soát':formatNanos(row[key],row.currency);
  function table(rows){return h('div',{class:'table-wrap'},h('table',{},h('thead',{},h('tr',{},...['Đơn Google Play','UID','Thời điểm (VN)','Khách trả','Đã hoàn','Còn sau hoàn','Trạng thái'].map(label=>h('th',{},label)))),h('tbody',{},...rows.map(row=>h('tr',{},h('td',{},row.orderId),h('td',{},row.uid),h('td',{},new Intl.DateTimeFormat('vi-VN',{dateStyle:'short',timeStyle:'short',timeZone:'Asia/Ho_Chi_Minh'}).format(new Date(row.at))),...['totalNanos','refundedNanos','netNanos'].map(key=>h('td',{},amount(row,key))),h('td',{},row.status))))));}
  async function load(cursor=null,page=1){
    if(!current())return;
    stopDetails?.();const child=liveScope(detailHost,current,scope.add);stopDetails=child.stop;
    const captured=epoch,active=()=>child.current()&&captured===epoch;
    details.replaceChildren(h('p',{class:'loading'},'Đang tải giao dịch Google Play…'));
    try{await observe(child,api,'watchPage',['premium_transactions',{...range,cursor,isCurrent:active}],result=>{
      if(!active())return;
      const data=verifiedRevenue(result.rows,range);if(result.hasMore)cursors[page]=result.cursor;
      details.replaceChildren(h('section',{class:'panel'},h('h2',{},'Giao dịch Google Play'),!data.transactions.length?h('p',{class:'empty'},'Chưa có giao dịch trong kỳ này.'):table(data.transactions),h('p',{class:'muted'},`Trang ${page} · ${result.rows.length} mục. Tổng kỳ được tính riêng.`),
        h('button',{type:'button',disabled:page===1,onClick:()=>load(cursors[page-2],page-1)},'Trước'),h('button',{type:'button',disabled:!result.hasMore,onClick:()=>load(cursors[page],page+1)},'Sau')));
    },e=>details.replaceChildren(h('p',{class:'error',role:'alert'},e.message)),()=>api.listPage('premium_transactions',{...range,cursor,isCurrent:active}));}catch(e){if(active())details.replaceChildren(h('p',{class:'error',role:'alert'},e.message));}
  }
  async function summarize(){
    if(!current())return;
    try{
      const next=selected();if(JSON.stringify(next)!==JSON.stringify(range)){invalidate();range=next;cursors=[null];await load();if(!current())return;}
      stopReport?.();const child=liveScope(reportHost,current,scope.add);stopReport=child.stop;
      const captured=epoch,active=()=>child.current()&&captured===epoch;report=null;
      summary.replaceChildren(h('p',{class:'loading'},'Đang đối soát đủ giao dịch trong kỳ…'));
      await observe(child,api,'watchRange',['premium_transactions',range],rows=>{
        if(!active())return;
        report=verifiedRevenue(rows,range);const saved=report;
        const totals=h('div',{class:'stats'},...report.currencies.map(g=>h('section',{class:'stat'},h('h3',{},g.currency),h('p',{},`Khách trả: ${formatNanos(g.total,g.currency)}`),h('p',{},`Đã hoàn: ${formatNanos(g.refunded,g.currency)}`),h('strong',{},`Còn sau hoàn: ${formatNanos(g.net,g.currency)}`))));
        const exportStatus=h('p',{'aria-live':'polite'});
        const exportButton=button('Xuất Excel đã xác minh',()=>{
          if(!active()||report!==saved)return;
          const workbook=verifiedRevenueExport(saved,environment);
          workbook.metadata=[['Nguồn',environment==='test'?'GOOGLE PLAY THỬ NGHIỆM · không phải tiền thật':'Google Play production · đã xác minh'],
            ['Từ ngày (VN)',range.start],['Đến hết ngày (VN)',range.end],['Đơn đã thanh toán',saved.count],['Khách mua',saved.buyers],['Đơn chờ đối soát',saved.unresolved],
            ...saved.currencies.flatMap(g=>[[`Khách trả (${g.currency})`,formatNanos(g.total,g.currency)],[`Đã hoàn (${g.currency})`,formatNanos(g.refunded,g.currency)],[`Còn sau hoàn (${g.currency})`,formatNanos(g.net,g.currency)]]),
            ['Lưu ý','Chỉ gồm đơn đã đồng bộ. Còn sau hoàn chưa trừ phí/thuế; cần đối soát Play Console trước chốt sổ. Số tiền giữ dạng văn bản để không mất độ chính xác.']];
          downloadReport({workbook,filename:`healthmate-google-play-${environment}-${range.start}-${range.end}.xlsx`,isCurrent:()=>active()&&report===saved,
            onResult:(message,error)=>{exportStatus.textContent=message;exportStatus.className=error?'error':'muted';}});
        });
        summary.replaceChildren(totals,h('p',{},`${report.count} đơn đã thanh toán · ${report.buyers} tài khoản · ${report.unresolved} đơn chờ đối soát, chưa cộng vào tổng.`),exportButton,exportStatus);
      },e=>{report=null;summary.replaceChildren(h('p',{class:'error',role:'alert'},e.message));},()=>api.exportRange('premium_transactions',{...range,isCurrent:active}));
    }catch(e){if(current())summary.replaceChildren(h('p',{class:'error',role:'alert'},e.message));}
  }
  async function view(){try{invalidate();range=selected();cursors=[null];await load();if(current()&&api.watchRange)await summarize();}catch(e){if(current())details.replaceChildren(h('p',{class:'error',role:'alert'},e.message));}}
  host.replaceChildren(h('p',{class:'notice local'},environment==='test'?'GOOGLE PLAY THỬ NGHIỆM · KHÔNG CỘNG VÀO DOANH THU THẬT.':'GOOGLE PLAY · GIAO DỊCH ĐÃ XÁC MINH TRÊN MÁY CHỦ.'),
    h('p',{class:'muted'},'Số tiền khách trả và hoàn tiền lấy từ Google Orders, tách theo tiền tệ. Còn sau hoàn chưa trừ phí/thuế, không phải số tiền ngân hàng nhận. Hoàn tiền điều chỉnh kỳ của đơn gốc. Chỉ gồm đơn đã đồng bộ; cần đối chiếu báo cáo Play Console trước khi chốt sổ.'),
    h('section',{class:'panel'},h('div',{class:'toolbar'},h('label',{class:'field'},'Từ ngày',start),h('label',{class:'field'},'Đến ngày',end),button('Xem giao dịch',view),button('Tổng hợp kỳ',summarize),button('Hủy tổng hợp',()=>{stopReport?.();report=null;summary.replaceChildren(h('p',{},'Đã hủy tổng hợp.'));}),button('Tải lại',view)),h('p',{class:'muted'},'Tối đa 5.000 giao dịch mỗi kỳ; vượt giới hạn cần chọn khoảng ngày nhỏ hơn.')),summary,details);
  await view();
}
