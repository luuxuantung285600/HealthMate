export const adminPageSize = 25;
export const maxAdminRows = 5000;
export const adminLists = ['food_catalog', 'user_directory', 'admin_audit', 'demo_premium_transactions', 'demo_premium_accounts', 'premium_transactions', 'support_tickets'];

export function normalizeSearch(value) {
  return String(value ?? '').normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd').replace(/Đ/g, 'D').toLocaleLowerCase('vi').replace(/\s+/g, ' ').trim();
}
export function filterRows(rows, kind, {search = '', category = '', status = '', role = ''} = {}) {
  if (!adminLists.includes(kind)) throw Error('Danh sách không được hỗ trợ.');
  const words = normalizeSearch(search).split(' ').filter(Boolean);
  return rows.filter(row => {
    const haystack = normalizeSearch([row.id, row.name, ...(row.alternateNames ?? []), row.category,
      row.email, row.displayName, row.entityType, row.entityId, row.actorUid, row.reason].join(' '));
    if (words.some(word => !haystack.includes(word))) return false;
    if (kind === 'food_catalog') {
      if (category && row.category !== category) return false;
      if (status && (row.isActive === false ? 'archived' : 'active') !== status) return false;
    }
    if (kind === 'user_directory') {
      if (status && (row.control?.status === 'suspended' ? 'suspended' : 'active') !== status) return false;
      if (role && (row.adminRole?.enabled === true ? 'admin' : 'user') !== role) return false;
    }
    if (kind === 'admin_audit' && category && row.entityType !== category) return false;
    return true;
  });
}
export function paginateRows(rows, requestedPage, pageSize = adminPageSize) {
  if (!Number.isInteger(pageSize) || pageSize < 1 || pageSize > 100) throw Error('Kích thước trang không hợp lệ.');
  const pages = Math.max(1, Math.ceil(rows.length / pageSize));
  const page = Math.min(pages, Math.max(1, Number.isInteger(requestedPage) ? requestedPage : 1));
  const offset = (page - 1) * pageSize;
  return {page, pages, offset, total: rows.length, rows: rows.slice(offset, offset + pageSize)};
}
export function canControlAccount(row, actorUid) {
  return row.id !== actorUid && row.adminRole == null;
}

/// Cursor paging reads the complete bounded set, or throws instead of silently
/// presenting a subset as a global search/export. No persistence of private rows.
export async function collectAdminRows(fetchPage, {isCurrent = () => true, onProgress = () => {}, maxRows = maxAdminRows} = {}) {
  const byId = new Map();
  let cursor = null;
  const cursors = new Set();
  do {
    if (!isCurrent()) throw Error('Phiên tải đã kết thúc.');
    const page = await fetchPage(cursor);
    if (!isCurrent()) throw Error('Phiên tải đã kết thúc.');
    for (const row of page.rows) {
      if (typeof row.id !== 'string' || !row.id) throw Error('Bản ghi không có mã hợp lệ.');
      byId.set(row.id, row);
    }
    if (byId.size > maxRows) throw Error(`Danh sách vượt ${maxRows.toLocaleString('vi-VN')} mục. Chưa tải đầy đủ; không thể tìm kiếm hoặc xuất toàn bộ. Cần chia phạm vi dữ liệu trước khi vận hành ở quy mô này.`);
    onProgress(byId.size);
    if (!page.hasMore) return [...byId.values()];
    if (!page.cursor || cursors.has(page.cursor.id)) throw Error('Con trỏ phân trang không hợp lệ; chưa tải đủ danh sách.');
    cursors.add(page.cursor.id);
    cursor = page.cursor;
  } while (true);
}

export function exportRows(kind, rows) {
  if (kind === 'food_catalog') return {
    name: 'Danh mục món ăn',
    headers: ['STT','Mã món','Tên món','Tên tương đương','Nhóm','Trạng thái','kcal/100g','Đạm g/100g','Carb g/100g','Béo g/100g','Xơ g/100g','Nguồn','URL nguồn','Ước tính','Khẩu phần','Gram/khẩu phần'],
    rows: rows.map((r,i) => [i+1,r.id,r.name,(r.alternateNames ?? []).join('; '),r.category,r.isActive === false ? 'Đã xóa khỏi danh mục' : 'Đang hiển thị',r.kcalPer100g,r.proteinGPer100g,r.carbsGPer100g,r.fatGPer100g,r.fiberGPer100g,r.sourceLabel,r.sourceUrl,r.isEstimated ? 'Có' : 'Không',r.servingLabel,r.servingGrams]),
  };
  if (kind === 'user_directory') return {
    name: 'Tài khoản', headers: ['STT','UID','Tên','Email','Vai trò','Trạng thái truy cập','Lý do'],
    rows: rows.map((r,i) => [i+1,r.id,r.displayName,r.email,r.adminRole?.enabled ? 'Admin' : 'Người dùng',r.control?.status === 'suspended' ? 'Tạm khóa' : 'Hoạt động',r.control?.reason]),
  };
  if (kind === 'admin_audit') return {
    name: 'Nhật ký quản trị', headers: ['STT','Mã thao tác','Thời điểm UTC','Loại đối tượng','Mã đối tượng','UID thực hiện','Trường thay đổi','Lý do'],
    rows: rows.map((r,i) => [i+1,r.id,r.at?.toDate?.().toISOString() ?? '',r.entityType,r.entityId,r.actorUid,(r.changedFields ?? []).join('; '),r.reason]),
  };
  throw Error('Danh sách không hỗ trợ xuất.');
}
