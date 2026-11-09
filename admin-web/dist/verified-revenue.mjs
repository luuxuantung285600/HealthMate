import {dateBoundary} from './revenue-model.mjs';
const paidStates=['paid','partially_refunded','refunded','pending_refund'];
const integer=value=>typeof value==='string'&&/^\d{1,28}$/.test(value);
export function formatNanos(value,currency){
  if(!integer(value)||!/^[A-Z]{3}$/.test(currency))throw Error('Số tiền chưa hợp lệ.');
  const amount=BigInt(value),fraction=String(amount%1000000000n).padStart(9,'0').replace(/0+$/,'');
  return `${(amount/1000000000n).toLocaleString('vi-VN')}${fraction?','+fraction:''} ${currency}`;
}
export function verifiedRevenue(rows,{start,end,environment='production'}={}){
  const lower=dateBoundary(start),upper=dateBoundary(end)+86400000;
  if(!['production','test'].includes(environment)||upper<=lower||upper-lower>366*86400000)throw Error('Phạm vi doanh thu không hợp lệ.');
  const seen=new Set(),orders=new Set(),transactions=[],groups=new Map();let unresolved=0;
  for(const row of rows){
    if(typeof row.id!=='string'||!row.id||seen.has(row.id)||row.provider!=='google_play'||row.verified!==true||!['production','test'].includes(row.environment)||typeof row.uid!=='string'||!row.uid||typeof row.orderId!=='string'||!row.orderId||orders.has(row.orderId)||row.reconciliationPending!==undefined&&typeof row.reconciliationPending!=='boolean')throw Error('Giao dịch chưa được xác minh hợp lệ.');
    seen.add(row.id);orders.add(row.orderId);
    const at=row.occurredAt?.toMillis?.();
    if(!Number.isFinite(at))throw Error('Giao dịch chưa có thời điểm xác nhận.');
    if(row.environment!==environment||at<lower||at>=upper)continue;
    if(![...paidStates,'pending','cancelled','awaiting_order'].includes(row.status))throw Error('Trạng thái giao dịch không hợp lệ.');
    if(row.status==='awaiting_order'||row.reconciliationPending===true){unresolved++;transactions.push({...row,at});continue;}
    if(!/^[A-Z]{3}$/.test(row.currency)||![row.totalNanos,row.refundedNanos,row.netNanos].every(integer)||BigInt(row.refundedNanos)>BigInt(row.totalNanos)||BigInt(row.netNanos)!==BigInt(row.totalNanos)-BigInt(row.refundedNanos))throw Error('Cần đối soát số tiền; chưa tổng hợp doanh thu.');
    if(row.status==='refunded'&&BigInt(row.refundedNanos)!==BigInt(row.totalNanos)||row.status==='partially_refunded'&&BigInt(row.refundedNanos)===0n)throw Error('Trạng thái hoàn tiền chưa khớp số tiền; cần đối soát với Google.');
    transactions.push({...row,at});
    if(!paidStates.includes(row.status))continue;
    const group=groups.get(row.currency)??{currency:row.currency,total:0n,refunded:0n,net:0n,count:0};
    group.total+=BigInt(row.totalNanos);group.refunded+=BigInt(row.refundedNanos);group.net+=BigInt(row.netNanos);group.count++;
    groups.set(row.currency,group);
  }
  transactions.sort((a,b)=>b.at-a.at||a.id.localeCompare(b.id));
  return {transactions,unresolved,count:transactions.filter(r=>paidStates.includes(r.status)&&!r.reconciliationPending).length,buyers:new Set(transactions.filter(r=>paidStates.includes(r.status)&&!r.reconciliationPending).map(r=>r.uid)).size,
    currencies:[...groups.values()].map(g=>({...g,total:String(g.total),refunded:String(g.refunded),net:String(g.net)})).sort((a,b)=>a.currency.localeCompare(b.currency))};
}
export function verifiedRevenueExport(report,environment){
  return {name:environment==='test'?'Google Play thử nghiệm':'Google Play đã xác minh',headers:['Đơn Google Play','UID','Thời điểm (VN)','Môi trường','Trạng thái','Tiền khách trả','Đã hoàn','Còn sau hoàn (chưa trừ phí/thuế)'],
    rows:report.transactions.map(r=>[r.orderId,r.uid,new Intl.DateTimeFormat('vi-VN',{dateStyle:'short',timeStyle:'short',timeZone:'Asia/Ho_Chi_Minh'}).format(new Date(r.at)),environment,r.reconciliationPending?'Chờ đối soát':r.status,...['totalNanos','refundedNanos','netNanos'].map(k=>r[k]==null||r.reconciliationPending?'Chờ đối soát':formatNanos(r[k],r.currency))])};
}
