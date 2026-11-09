import {adminLists, adminPageSize, collectAdminRows} from './list-model.mjs';
import {dateBoundary} from './revenue-model.mjs';

export function pageScope(kind, {idFrom = '', idTo = '', start = '', end = '', lookupField = '', lookupValue = '',environment = ''} = {}) {
  if (!adminLists.includes(kind)) throw Error('Danh sách không được hỗ trợ.');
  for (const id of [idFrom,idTo]) if (typeof id !== 'string' || id.length > 1500 || id.includes('/')) throw Error('Khoảng mã không hợp lệ.');
  if (idFrom && idTo && idFrom > idTo) throw Error('Mã bắt đầu phải đứng trước mã kết thúc.');
  if(environment&& (kind!=='premium_transactions'||!['production','test'].includes(environment)))throw Error('Môi trường thanh toán không hợp lệ.');
  if (Boolean(start) !== Boolean(end) || ((start || end) && !['demo_premium_transactions','premium_transactions','admin_audit'].includes(kind))) throw Error('Phạm vi ngày không hợp lệ.');
  if(start&&(idFrom||idTo))throw Error('Chọn phạm vi ngày hoặc mã, không kết hợp hai loại.');
  if(kind==='support_tickets'&&(idFrom||idTo))throw Error('Hỗ trợ được phân trang theo thời điểm cập nhật.');
  if(typeof lookupValue!=='string'||typeof lookupField!=='string'||lookupValue.length>1500)throw Error('Tra cứu không hợp lệ.');
  lookupValue=lookupValue.trim();
  if(Boolean(lookupField)!==Boolean(lookupValue)||lookupField&&!(['id'].includes(lookupField)||lookupField==='email'&&kind==='user_directory'||lookupField==='name'&&kind==='food_catalog'))throw Error('Chọn mã chính xác, email khách hàng hoặc đầu tên món.');
  if(lookupField&&(idFrom||idTo||start||end||kind==='support_tickets'))throw Error('Không kết hợp tra cứu với phạm vi khác.');
  if(lookupField==='id'&&(lookupValue.includes('/')||lookupValue==='.'||lookupValue==='..'))throw Error('Mã tra cứu không hợp lệ.');
  if(lookupField==='email'&&(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(lookupValue)||lookupValue.length>254))throw Error('Nhập email đầy đủ để tra cứu.');
  if(lookupField==='name'&&(lookupValue.length>100||/[\uD800-\uDFFF]/u.test(lookupValue)))throw Error('Đầu tên món không hợp lệ.');
  const timeField=kind==='support_tickets'?'updatedAt':kind==='admin_audit'&&!idFrom&&!idTo&&!lookupField?'at':start?'occurredAt':null;
  const valueField=lookupField==='name'?'name':null;
  let lower,upper;
  if (start && end) {
    lower=dateBoundary(start);upper=dateBoundary(end)+86400000;
    if(upper<=lower||upper-lower>366*86400000)throw Error('Chọn khoảng báo cáo từ 1 đến 366 ngày.');
  }
  return {kind,idFrom,idTo,start,end,lower,upper,timeField,valueField,lookupField,lookupValue,environment,key:JSON.stringify([kind,idFrom,idTo,start,end,timeField,lookupField,lookupValue,environment])};
}

// Use the same query for live display, one-shot pages and exports.
export function pageConstraints(scope,cursor,{where,orderBy,documentId,startAfter,Timestamp}) {
  const {lookupField,lookupValue,timeField,valueField}=scope;
  if(timeField)return [...(scope.environment?[where('environment','==',scope.environment)]:[]),...(scope.start?[where(timeField,'>=',new Date(scope.lower)),where(timeField,'<',new Date(scope.upper))]:[]),orderBy(timeField,'desc'),orderBy(documentId(),'desc'),...(cursor?[startAfter(new Timestamp(cursor.seconds,cursor.nanoseconds),cursor.id)]:[])];
  if(valueField){
    const chars=Array.from(lookupValue);let upper='';
    while(chars.length){const last=chars.pop().codePointAt(0);if(last<0x10ffff){upper=chars.join('')+String.fromCodePoint(last===0xd7ff?0xe000:last+1);break;}}
    return [where(valueField,'>=',lookupValue),...(upper?[where(valueField,'<',upper)]:[]),orderBy(valueField),orderBy(documentId()),...(cursor?[startAfter(cursor.value,cursor.id)]:[])];
  }
  return [...(lookupField?[where(lookupField==='id'?documentId():lookupField,'==',lookupValue)]:[]),...(scope.idFrom?[where(documentId(),'>=',scope.idFrom)]:[]),...(scope.idTo?[where(documentId(),'<=',scope.idTo)]:[]),orderBy(documentId()),...(cursor?[startAfter(cursor.id)]:[])];
}

// All display paths read one server page. No row cache or private persistence.
// Cursor ordering is stable for an unchanged data set, not a snapshot spanning
// concurrent writes. ID cursors continue to work when the boundary row is deleted.
export function createAdminPageReader({fetchDocuments,enrichAccount}) {
  return async function readPage(kind,{cursor=null,pageSize=adminPageSize,isCurrent=()=>true,...range}={}) {
    const scope=pageScope(kind,range);
    if(!Number.isInteger(pageSize)||pageSize<1||pageSize>200)throw Error('Kích thước trang không hợp lệ.');
    if(cursor && (cursor.scope!==scope.key || typeof cursor.id!=='string' || !cursor.id || cursor.id.includes('/') ||
      (scope.timeField && (!Number.isSafeInteger(cursor.seconds)||!Number.isInteger(cursor.nanoseconds)||cursor.nanoseconds<0||cursor.nanoseconds>999999999))||
      (scope.valueField && typeof cursor.value!=='string')))throw Error('Con trỏ không thuộc phạm vi đang xem.');
    const check=()=>{if(!isCurrent())throw Error('Phiên tải đã kết thúc.');};
    check();const result=await fetchDocuments({...scope,cursor,pageSize});check();
    if(!Array.isArray(result)||result.length>pageSize)throw Error('Trang dữ liệu không hợp lệ.');
    const ids=new Set();
    for(const row of result){
      if(typeof row.id!=='string'||!row.id||ids.has(row.id))throw Error('Trang có mã trùng hoặc không hợp lệ.');
      ids.add(row.id);
    }
    const rows=kind==='user_directory'?await Promise.all(result.map(async row=>{
      check();const extra=await enrichAccount(row.id);check();return {...row,...extra};
    })):result;
    check();const last=rows.at(-1);
    const nextCursor=last?{scope:scope.key,id:last.id,...(scope.timeField?{seconds:last[scope.timeField]?.seconds,nanoseconds:last[scope.timeField]?.nanoseconds}: {}),...(scope.valueField?{value:last[scope.valueField]}:{})}:null;
    if(scope.timeField&&last&&(!Number.isSafeInteger(nextCursor.seconds)||!Number.isInteger(nextCursor.nanoseconds)||nextCursor.nanoseconds<0||nextCursor.nanoseconds>999999999))throw Error('Bản ghi chưa có thời điểm hợp lệ.');
    return {rows,cursor:nextCursor,hasMore:rows.length===pageSize};
  };
}

export async function collectRange(readPage,kind,{isCurrent=()=>true,onProgress=()=>{},...range}={}) {
  // The caller must choose an explicit range. A blank endpoint is an open side,
  // but both blank must never turn an export into an unbounded collection scan.
  if(!(range.idFrom||range.idTo||(range.start&&range.end)))throw Error('Chọn khoảng mã hoặc ngày trước khi xuất/tổng hợp.');
  return collectAdminRows(cursor=>readPage(kind,{...range,cursor,pageSize:200,isCurrent}),{isCurrent,onProgress});
}
