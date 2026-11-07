import {dateBoundary, vietnamDateKey} from './revenue-model.mjs';

export function dashboardPeriod(preset, now = new Date()) {
  const end = vietnamDateKey(now);
  if (preset === 'month') return {start:`${end.slice(0,7)}-01`, end};
  const days = {today:1, week:7, days30:30}[preset];
  if (!days) throw Error('Chọn kỳ báo cáo hợp lệ.');
  return {start:vietnamDateKey(new Date(dateBoundary(end) - (days - 1) * 86400000)), end};
}

export function formatCount(value) {
  if (!Number.isSafeInteger(value) || value < 0) throw Error('Số liệu thống kê chưa hợp lệ.');
  return value.toLocaleString('vi-VN');
}

export function formatMoney(value) {
  return `${formatCount(value)} ₫`;
}

export function registeredAccountSummary(data) {
  if (data == null) return null;
  const updatedAt = data.updatedAt?.toMillis?.();
  if (data.schemaVersion !== 1 || data.source !== 'firebase_auth' || !['manual_snapshot','realtime_auth_events'].includes(data.method)
    || !Number.isFinite(updatedAt) || updatedAt < 0 || updatedAt > Date.now() + 120000) {
    throw Error('Thống kê tài khoản chưa được xác nhận.');
  }
  if(data.method==='realtime_auth_events' && data.ready!==true)return null;
  formatCount(data.totalRegisteredAccounts);
  return {count:data.totalRegisteredAccounts, updatedAt,...(data.method==='realtime_auth_events'?{live:true}:{})};
}
