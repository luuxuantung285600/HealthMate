import {demoRevenue,revenueExport,vietnamDateKey,dateBoundary} from './revenue-model.mjs';
import {downloadReport} from './report-download.mjs';
import {liveScope,observe} from './live-scope.mjs';
const loads=new WeakMap();

export async function revenuePage({host,api,h,button,isCurrent,onDispose}) {
  const revision=(loads.get(host)??0)+1;loads.set(host,revision);
  const scope=liveScope(host,()=>isCurrent()&&loads.get(host)===revision,onDispose),current=scope.current;
  const detailHost={},reportHost={};let stopDetails,stopReport;
  const today=vietnamDateKey(new Date());
  let epoch=0,detailTurn=0,reportTurn=0,pageNumber=1,range,report;
  let cursors=[null];
  const money=n=>`${n.toLocaleString('vi-VN')}đ`;
  const start=h('input',{type:'date',value:`${today.slice(0,7)}-01`,'aria-label':'Từ ngày',onChange:invalidate});
  const end=h('input',{type:'date',value:today,'aria-label':'Đến ngày',onChange:invalidate});
  const summary=h('div',{id:'revenue-summary'}),details=h('div',{id:'revenue-results'});
  function invalidate(){stopDetails?.();stopReport?.();epoch++;report=null;summary.replaceChildren();details.replaceChildren(h('p',{class:'muted'},'Chọn Xem giao dịch để tải khoảng ngày mới.'));}
  function selectedRange(){
    const lower=dateBoundary(start.value),upper=dateBoundary(end.value)+86400000;
    if(upper<=lower||upper-lower>366*86400000)throw Error('Chọn khoảng báo cáo từ 1 đến 366 ngày.');
    return {start:start.value,end:end.value};
  }
  async function load(cursor=null,number=1,newRange=false){
    if(!current())return;
    let active=()=>false;
    try{
      if(newRange||!range){stopReport?.();range=selectedRange();epoch++;report=null;cursors=[null];summary.replaceChildren();}
      stopDetails?.();const detailsScope=liveScope(detailHost,current,scope.add);stopDetails=detailsScope.stop;
      const token=epoch,turn=++detailTurn;
      active=()=>current()&&token===epoch&&turn===detailTurn;
      details.replaceChildren(h('p',{class:'loading'},'Đang tải trang giao dịch…'));
      return await observe(detailsScope,api,'watchPage',['demo_premium_transactions',{...range,cursor,isCurrent:active}],result=>{if(!active())return;
      pageNumber=number;if(result.hasMore)cursors[number]=result.cursor;
      const page=demoRevenue(result.rows,[],range);
      const table=h('table',{},h('thead',{},h('tr',{},...['Giao dịch','UID','Thời điểm (VN)','Mô phỏng (VND)'].map(title=>h('th',{},title)))),
        h('tbody',{},...page.transactions.map(row=>h('tr',{},h('td',{},row.id),h('td',{},row.uid),
          h('td',{},new Intl.DateTimeFormat('vi-VN',{dateStyle:'short',timeStyle:'short',timeZone:'Asia/Ho_Chi_Minh'}).format(new Date(row.at))),h('td',{},money(row.amountVnd))))));
      details.replaceChildren(h('section',{class:'panel'},h('h2',{},'Giao dịch demo'),h('p',{class:'muted'},'25 mục mỗi trang, mới nhất trước. Trang này không phải tổng doanh thu của kỳ.'),
        !result.rows.length?h('p',{class:'empty'},number===1?'Chưa có giao dịch mô phỏng trong khoảng này.':'Đã hết giao dịch trong lần tải này.'):null,
        h('div',{class:'table-wrap'},table),h('div',{class:'table-foot'},h('span',{},`Trang ${pageNumber} · ${result.rows.length} giao dịch`),h('div',{class:'pagination'},
          h('button',{type:'button',class:'button secondary',disabled:number===1,onClick:()=>load(cursors[number-2],number-1)},'Trước'),
          h('button',{type:'button',class:'button secondary',disabled:!result.hasMore,onClick:()=>load(cursors[number],number+1)},'Sau')))));
      },e=>details.replaceChildren(h('p',{class:'error',role:'alert'},e.message)),()=>api.listPage('demo_premium_transactions',{...range,cursor,isCurrent:active}));
    }catch(e){if(current()&&(active()||newRange))details.replaceChildren(h('p',{class:'error',role:'alert'},e.message));}
  }
  async function summarize(){
    if(!current())return;
    let active=current;
    try{
      const selected=selectedRange();
      if(!range||JSON.stringify(range)!==JSON.stringify(selected)){await load(null,1,true);if(!current()||JSON.stringify(range)!==JSON.stringify(selected)||start.value!==selected.start||end.value!==selected.end)return;}
      stopReport?.();const reportScope=liveScope(reportHost,current,scope.add);stopReport=reportScope.stop;
      const token=epoch,turn=++reportTurn;active=()=>current()&&token===epoch&&turn===reportTurn;
      report=null;summary.replaceChildren(h('p',{class:'loading'},'Đang tải đủ giao dịch trong kỳ, tối đa 5.000 mục…'));
      return await observe(reportScope,api,'watchRange',['demo_premium_transactions',range],all=>{if(!active())return;
      report=demoRevenue(all,[],range);
      const captured=report,stats=h('div',{class:'stats'});
      for(const [label,value] of [['Doanh thu mô phỏng trong kỳ',money(report.amountVnd)],['Giao dịch demo trong kỳ',String(report.count)],['Khách mua trong kỳ',String(report.buyers)]])
        stats.append(h('section',{class:'stat'},h('div',{class:'stat-label'},label),h('div',{class:'stat-number'},value)));
      const daily=h('table',{},h('thead',{},h('tr',{},...['Ngày (VN)','Giao dịch demo','Doanh thu mô phỏng'].map(title=>h('th',{},title)))),
        h('tbody',{},...report.days.map(day=>h('tr',{},h('td',{},day.day),h('td',{},String(day.transactions)),h('td',{},money(day.amountVnd))))));
      const exportStatus=h('p',{'aria-live':'polite'});
      const exportButton=button('Xuất Excel mô phỏng',()=>{
        if(!active()||report!==captured)return;
        const workbook=revenueExport(captured);
        workbook.metadata=[['Nguồn','DEMO MÔ PHỎNG · KHÔNG THU TIỀN'],['Từ ngày (VN)',range.start],['Đến hết ngày (VN)',range.end],
          ['Tổng mô phỏng (VND)',captured.amountVnd],['Giao dịch demo',captured.count],['Khách mua demo',captured.buyers]];
        downloadReport({workbook,filename:`healthmate-doanh-thu-demo-${range.start}-${range.end}.xlsx`,isCurrent:()=>active()&&report===captured,
          onResult:(message,error)=>{exportStatus.textContent=message;exportStatus.className=error?'error':'muted';}});
      });
      summary.replaceChildren(stats,h('section',{class:'panel'},h('h2',{},'Tổng hợp đầy đủ kỳ đã chọn'),h('p',{class:'muted'},`${report.count} giao dịch đã tải đủ. Tự động cập nhật khi máy chủ xác nhận thay đổi trong kỳ.`),exportButton,exportStatus,h('div',{class:'table-wrap'},daily)));
      },e=>{report=null;summary.replaceChildren(h('p',{class:'error',role:'alert'},e.message));},()=>api.exportRange('demo_premium_transactions',{...range,isCurrent:active}));
    }catch(e){if(current()&&(active()||!range))summary.replaceChildren(h('p',{class:'error',role:'alert'},e.message));}
  }
  async function viewRange(){await load(null,1,true);if(api.watchRange&&current())await summarize();}
  host.replaceChildren(h('p',{class:'notice local'},'DEMO · KHÔNG THU TIỀN. Chỉ cộng giao dịch mô phỏng 20.000đ/30 ngày, không phải tiền thực nhận.'),
    h('section',{class:'panel'},h('div',{class:'toolbar'},h('label',{class:'field'},'Từ ngày',start),h('label',{class:'field'},'Đến ngày',end),
      button('Xem giao dịch',viewRange),button('Tổng hợp kỳ',summarize),button('Hủy tổng hợp',()=>{stopReport?.();reportTurn++;report=null;summary.replaceChildren(h('p',{class:'muted'},'Đã hủy tổng hợp.'));}),button('Tải lại',()=>revenuePage({host,api,h,button,isCurrent,onDispose}))),
      h('p',{class:'muted'},'Tổng hợp và Excel tải riêng tối đa 5.000 giao dịch của kỳ. Vượt giới hạn phải chọn khoảng ngày nhỏ hơn; không xuất thiếu âm thầm.')),
    summary,details);
  await viewRange();
}
