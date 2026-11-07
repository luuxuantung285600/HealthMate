export const supportStatuses = {open:'Đã tiếp nhận',in_progress:'Đang xử lý',resolved:'Đã giải quyết'};
export const supportTypes = {bug:'Báo lỗi',suggestion:'Góp ý'};
export function supportText(value, max=2000) {
  const text=String(value??'').trim();
  if(!text || [...text].length>max)throw Error(`Nội dung cần từ 1 đến ${max} ký tự.`);
  return text;
}
export function supportId(id) {
  if(typeof id!=='string'||!/^[a-zA-Z0-9]{20}$/.test(id))throw Error('Mã yêu cầu không hợp lệ.');
  return id;
}
export function filterSupport(rows,{search='',type='',status=''}={}) {
  const normalize=v=>String(v??'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/đ/gi,'d').toLowerCase();
  const words=normalize(search).trim().split(/\s+/).filter(Boolean);
  return rows.filter(r=>!r.deleting && (!type||r.type===type)&&(!status||r.status===status)
    && words.every(word=>normalize(`${r.id} ${r.uid} ${r.title} ${r.description}`).includes(word)))
    .sort((a,b)=>{
      const left=a.updatedAt,right=b.updatedAt;
      const byTime=typeof left?.seconds==='number'&&typeof right?.seconds==='number'
        ? right.seconds-left.seconds||(right.nanoseconds??0)-(left.nanoseconds??0)
        : (right?.toMillis?.()??0)-(left?.toMillis?.()??0);
      return byTime||(a.id<b.id?1:a.id>b.id?-1:0);
    });
}
export function validateSupportThread(ticket,messages) {
  if(!ticket || ticket.deleting)throw Error('Yêu cầu không còn khả dụng.');
  if(!Object.hasOwn(supportStatuses,ticket.status)||!Object.hasOwn(supportTypes,ticket.type)
    ||!Number.isInteger(ticket.messageCount)||ticket.messageCount<0||ticket.messageCount>100
    ||ticket.messageCount!==messages.length)throw Error('Cuộc trao đổi vừa thay đổi hoặc tải chưa đủ. Hãy tải lại.');
  messages.forEach((m,i)=>{
    if(m.sequence!==i+1||!['admin','customer'].includes(m.role)||typeof m.text!=='string'||!m.createdAt?.toDate?.()) {
      throw Error('Tin nhắn chưa được xác nhận đầy đủ. Hãy tải lại.');
    }
  });
  return {ticket,messages};
}
