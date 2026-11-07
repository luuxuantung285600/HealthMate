'use strict';
// Manual aggregate refresh using the owner's EXISTING Firebase CLI session.
// Default is read-only. No user records, OAuth tokens or keys are persisted.
const path = require('node:path');
const project = 'healthmate-app-20261013';
const summaryName = `projects/${project}/databases/(default)/documents/admin_statistics/accounts`;
const summaryUrl = `https://firestore.googleapis.com/v1/${summaryName}`;

async function countRegisteredAccounts(request) {
  let pageToken = '', pages = 0;
  const ids = new Set(), tokens = new Set();
  do {
    if (++pages > 100) throw Error('Vượt 100 trang tài khoản; chưa ghi thống kê.');
    const url = new URL(`https://identitytoolkit.googleapis.com/v1/projects/${project}/accounts:batchGet`);
    url.searchParams.set('maxResults','1000');
    // Fetch only identifiers needed to deduplicate. Never request password,
    // email, provider details or any health information.
    url.searchParams.set('fields','users(localId),nextPageToken');
    if (pageToken) url.searchParams.set('nextPageToken',pageToken);
    const data = await request(url.href);
    if (!data || typeof data !== 'object' || (data.users !== undefined && !Array.isArray(data.users))) throw Error('Trang tài khoản chưa hợp lệ.');
    const users = data.users ?? [];
    if (users.length > 1000) throw Error('Trang tài khoản vượt giới hạn.');
    for (const user of users) {
      if (typeof user.localId !== 'string' || !user.localId || ids.has(user.localId)) throw Error('Tài khoản trùng hoặc thiếu mã; hãy chạy lại khi ít thay đổi.');
      ids.add(user.localId);
    }
    pageToken = data.nextPageToken ?? '';
    if (typeof pageToken !== 'string' || (pageToken && tokens.has(pageToken))) throw Error('Phân trang tài khoản bị lặp; chưa ghi thống kê.');
    if (pageToken) tokens.add(pageToken);
  } while (pageToken);
  return {totalRegisteredAccounts:ids.size,pages};
}

async function syncStatistics({request,apply = false}) {
  // Capture the existing update time BEFORE scanning to avoid an older scan
  // overwriting a newer concurrent publication.
  const previous = apply ? await request(summaryUrl,{allowMissing:true}) : null;
  if(previous?.fields?.method?.stringValue==='realtime_auth_events')throw Error('Thống kê đã chuyển sang sự kiện trực tiếp. Dùng bootstrap/reconcile của firebase-functions; không ghi đè bằng bản thủ công.');
  const scanStartedAt = new Date().toISOString();
  const result = await countRegisteredAccounts(request);
  if (apply) {
    const fields = {
      schemaVersion:{integerValue:'1'},source:{stringValue:'firebase_auth'},method:{stringValue:'manual_snapshot'},
      totalRegisteredAccounts:{integerValue:String(result.totalRegisteredAccounts)},scanStartedAt:{timestampValue:scanStartedAt},
    };
    if (previous && typeof previous.updateTime !== 'string') throw Error('Thống kê cũ thiếu phiên bản; chưa ghi thay thế.');
    await request(`https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents:commit`,{
      body:{writes:[{update:{name:summaryName,fields},
        currentDocument:previous ? {updateTime:previous.updateTime} : {exists:false},
        updateTransforms:[{fieldPath:'updatedAt',setToServerValue:'REQUEST_TIME'}]}]},
    });
  }
  return {project,...result,applied:apply,method:'manual_snapshot'};
}

function parseArgs(args) {
  const result = {apply:false,cliRoot:null};
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--apply') result.apply = true;
    else if (args[i] === '--cli-root' && args[i + 1] && !args[i + 1].startsWith('--')) result.cliRoot = args[++i];
    else throw Error('Dùng: node admin-web/tool/sync-account-statistics.cjs [--cli-root <firebase-tools>] [--apply]');
  }
  return result;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const cliRoot = options.cliRoot ?? (process.env.APPDATA ? path.join(process.env.APPDATA,'npm','node_modules','firebase-tools') : null);
  if (!cliRoot) throw Error('Chỉ định --cli-root tới firebase-tools đã cài.');
  let auth;
  try {auth = require(path.join(path.resolve(cliRoot),'lib','auth.js'));}
  catch {throw Error('Không tìm thấy Firebase CLI; chỉ định đúng --cli-root.');}
  const account = auth.getGlobalDefaultAccount();
  if (!account?.tokens?.refresh_token) throw Error('Cần đăng nhập Firebase CLI bằng tài khoản chủ dự án.');
  let token;
  try {token = await auth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform']);}
  catch {throw Error('Không lấy được phiên Firebase CLI; đăng nhập lại trước khi đồng bộ.');}
  const request = async(url,{body,allowMissing = false} = {}) => {
    let response;
    try {response = await fetch(url,{method:body ? 'POST' : 'GET',
      headers:{Authorization:`Bearer ${token.access_token}`,...(body ? {'Content-Type':'application/json'} : {})},
      ...(body ? {body:JSON.stringify(body)} : {}),signal:AbortSignal.timeout(30000)});}
    catch {throw Error('Không kết nối được Firebase; chưa xác nhận cập nhật thống kê.');}
    if (allowMissing && response.status === 404) return null;
    if (!response.ok) throw Error(`Firebase trả HTTP ${response.status}; kiểm tra quyền Auth/Firestore hoặc chạy lại nếu dữ liệu vừa thay đổi.`);
    try {return await response.json();} catch {throw Error('Firebase trả dữ liệu chưa hợp lệ.');}
  };
  console.log(JSON.stringify(await syncStatistics({request,apply:options.apply})));
}

module.exports = {countRegisteredAccounts,syncStatistics,parseArgs};
if (require.main === module) main().catch(error => {console.error(error.message);process.exitCode = 1;});
