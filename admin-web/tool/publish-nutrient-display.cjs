'use strict';
// Release only the nutrient detail row on top of the CURRENT deployed admin.
// Never deploy the unrelated working tree or modify Firestore Rules/config.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),zlib=require('node:zlib');
const {isDeepStrictEqual:equal}=require('node:util');
const project='healthmate-app-20261013',site='healthmate-admin-vn';
const version='verified-nutrients-2026-11-10-v1';
const sha=data=>crypto.createHash('sha256').update(data).digest('hex');
const packed=data=>zlib.gzipSync(data,{level:9});
const importLine="import {catalogExtras,saltFromSodium} from './nutrition-values.mjs';\n";
const sourceLine="h('p',{},row.sourceUrl)";
const wrappedSourceLine="h('p',{},...String(row.sourceUrl??'').split(/(?<=[/._-])/).flatMap(part=>[part,h('wbr')]))";
const detailLine="  h('p',{},`Đường tổng: ${catalogExtras(row).sugar==null?'Chưa có dữ liệu':`${catalogExtras(row).sugar.toLocaleString('vi-VN',{maximumFractionDigits:3})} g`} · Natri: ${catalogExtras(row).sodium==null?'Chưa có dữ liệu':`${catalogExtras(row).sodium.toLocaleString('vi-VN',{maximumFractionDigits:3})} mg`} · Muối quy đổi: ${saltFromSodium(catalogExtras(row).sodium)==null?'Chưa có dữ liệu':`${saltFromSodium(catalogExtras(row).sodium).toLocaleString('vi-VN',{maximumFractionDigits:3})} g`} / 100 g`),\n";
function patchDisplay(source) {
  const marker="  h('p',{},`Nguồn: ${row.sourceLabel}`)";
  if(source.includes('nutrition-values.mjs')||source.split(marker).length!==2||source.split(sourceLine).length!==2||source.split('function viewFood(row)').length!==2)throw Error('Deployed app differs; review the new version.');
  return importLine+source.replace(marker,detailLine+marker).replace(sourceLine,wrappedSourceLine);
}
function scopedFiles(files,changes) {
  const result=Object.fromEntries(files.map(f=>[f.path,f.hash]));
  for(const [file,bytes] of Object.entries(changes)){
    if(!['/app.mjs','/nutrition-values.mjs'].includes(file))throw Error('Unexpected release file.');
    result[file]=sha(packed(bytes));
  }
  return result;
}
async function main(args) {
  const mode=args[0],out=path.resolve(args[1]||'');
  const root=path.resolve(__dirname,'../..');
  if(!['review','apply','verify'].includes(mode)||!out.startsWith(path.join(root,'build')+path.sep))throw Error('Use review|apply|verify <new build directory>.');
  const auth=require(path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib/auth.js'));
  const account=auth.getGlobalDefaultAccount();if(!account?.tokens?.refresh_token)throw Error('CLI login required.');
  const token=await auth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform']);
  const base='https://firebasehosting.googleapis.com/v1beta1/';
  async function request(resource,{body,method}={}){
    const r=await fetch(base+resource,{method:method||(body?'POST':'GET'),headers:{Authorization:`Bearer ${token.access_token}`,'Content-Type':'application/json'},body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(30000)});
    if(!r.ok)throw Error('Hosting HTTP '+r.status+'; no response body/credential logged.');return r.json();
  }
  const channel=()=>request(`sites/${site}/channels/live`);
  async function listFiles(name){let page;const files=[];do{const q=new URLSearchParams({pageSize:'1000'});if(page)q.set('pageToken',page);const r=await request(name+'/files?'+q);files.push(...(r.files||[]));page=r.nextPageToken;}while(page);return files;}
  const save=(file,data)=>fs.writeFileSync(path.join(out,file),JSON.stringify(data,null,2),{flag:'wx'});
  if(mode==='review'){
    if(fs.existsSync(out))throw Error('Use a new review directory.');
    const live=await channel(),before=await request(live.release.version.name),files=await listFiles(before.name);
    if(before.status!=='FINALIZED'||!before.name.startsWith(`sites/${site}/versions/`))throw Error('Unexpected live Hosting version.');
    const appResponse=await fetch(`https://${site}.web.app/app.mjs`,{signal:AbortSignal.timeout(30000)});
    if(!appResponse.ok)throw Error('Public app unavailable.');
    const app=Buffer.from(await appResponse.arrayBuffer());
    if(sha(packed(app))!==files.find(f=>f.path==='/app.mjs')?.hash)throw Error('Public app/version mismatch.');
    const changes={'/app.mjs':Buffer.from(patchDisplay(app.toString('utf8'))),'/nutrition-values.mjs':fs.readFileSync(path.join(root,'admin-web/dist/nutrition-values.mjs'))};
    fs.mkdirSync(path.join(out,'site'),{recursive:true});
    fs.writeFileSync(path.join(out,'before-app.mjs'),app,{flag:'wx'});
    for(const [file,bytes] of Object.entries(changes))fs.writeFileSync(path.join(out,'site',file.slice(1)),bytes,{flag:'wx'});
    const manifest={project,site,version,reviewedAt:new Date().toISOString(),before,files,fileHashes:scopedFiles(files,changes),changes:Object.fromEntries(Object.entries(changes).map(([file,bytes])=>[file,sha(bytes)]))};
    save('manifest.json',manifest);
    console.log(JSON.stringify({mode,version,baseVersion:before.name,preservedFiles:files.length-1,updatedFiles:['/app.mjs'],addedFiles:['/nutrition-values.mjs'],configurationUnchanged:true,out}));return;
  }
  const manifest=JSON.parse(fs.readFileSync(path.join(out,'manifest.json'),'utf8'));
  if(manifest.project!==project||manifest.site!==site||manifest.version!==version)throw Error('Review project mismatch.');
  const changes=Object.fromEntries(Object.keys(manifest.changes).map(file=>[file,fs.readFileSync(path.join(out,'site',file.slice(1)))]));
  if(!equal(manifest.changes,Object.fromEntries(Object.entries(changes).map(([file,bytes])=>[file,sha(bytes)])))||!equal(scopedFiles(manifest.files,changes),manifest.fileHashes))throw Error('Review files changed.');
  if(mode==='apply'){
    if((await channel()).release.version.name!==manifest.before.name)throw Error('Live admin changed since review.');
    const created=await request(`sites/${site}/versions`,{body:{config:manifest.before.config,labels:{'healthmate-release':version}}});
    save('created.json',created);
    const population=await request(created.name+':populateFiles',{body:{files:manifest.fileHashes}});
    const compressed=new Map(Object.values(changes).map(bytes=>{const zip=packed(bytes);return[sha(zip),zip];}));
    if((population.uploadRequiredHashes||[]).some(hash=>!compressed.has(hash)))throw Error('Unexpected missing baseline blob; no live release made.');
    const upload=new URL(population.uploadUrl);
    if(upload.protocol!=='https:'||upload.hostname!=='upload-firebasehosting.googleapis.com')throw Error('Unexpected upload endpoint.');
    for(const hash of population.uploadRequiredHashes||[]){
      const r=await fetch(population.uploadUrl+'/'+hash,{method:'POST',headers:{Authorization:`Bearer ${token.access_token}`,'Content-Type':'application/octet-stream'},body:compressed.get(hash),signal:AbortSignal.timeout(30000)});
      if(!r.ok)throw Error('Hosting upload HTTP '+r.status);
    }
    const actual=Object.fromEntries((await listFiles(created.name)).map(f=>[f.path,f.hash]));
    if(!equal(actual,manifest.fileHashes))throw Error('Staged Hosting files differ; no release made.');
    const finalized=await request(created.name+'?updateMask=status',{method:'PATCH',body:{status:'FINALIZED'}});
    if(finalized.status!=='FINALIZED'||!equal(finalized.config,manifest.before.config))throw Error('Hosting configuration differs; no release made.');
    if((await channel()).release.version.name!==manifest.before.name)throw Error('Concurrent deployment; no release made.');
    const release=await request(`sites/${site}/channels/live/releases?versionName=${encodeURIComponent(created.name)}`,{body:{message:version+' · hiển thị natri/đường/muối từ catalog đã xác minh'}});
    save('release.json',release);
  }
  const live=await channel(),deployed=await request(live.release.version.name),files=await listFiles(deployed.name);
  if(!equal(deployed.config,manifest.before.config)||!equal(Object.fromEntries(files.map(f=>[f.path,f.hash])),manifest.fileHashes))throw Error('Live Hosting readback differs.');
  for(const [file,bytes] of Object.entries(changes)){
    const r=await fetch(`https://${site}.web.app${file}`,{signal:AbortSignal.timeout(30000)});
    if(!r.ok||sha(Buffer.from(await r.arrayBuffer()))!==sha(bytes))throw Error('Public readback pending/differs: '+file);
  }
  save('verification-'+Date.now()+'.json',{verifiedAt:new Date().toISOString(),version:deployed.name,files:files.length,configurationUnchanged:true,changedFiles:Object.keys(changes)});
  console.log(JSON.stringify({mode,liveVersion:deployed.name,verifiedFiles:files.length,configurationUnchanged:true,url:`https://${site}.web.app`}));
}
module.exports={patchDisplay,scopedFiles};
if(require.main===module)main(process.argv.slice(2)).catch(error=>{console.error(error.message);process.exitCode=1;});
