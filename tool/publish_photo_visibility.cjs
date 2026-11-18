'use strict';
// Reversible, review-first visibility release. No user paths or deletes.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const {isDeepStrictEqual:equal}=require('node:util');
const {decode}=require('./import_food_catalog.cjs');
const {wire}=require('./publish_verified_nutrients.cjs');
const root=path.resolve(__dirname,'..'),project='healthmate-app-20261013';
const prefix=`projects/${project}/databases/(default)/documents`;
const hash=x=>crypto.createHash('sha256').update(JSON.stringify(x)).digest('hex');
const idOf=d=>d.name.split('/').at(-1);
function validCustomPhoto(p){
 if(!p||p.mode!=='custom')return false;
 const text=(k,max)=>typeof p[k]==='string'&&p[k].trim()&&p[k].length<=max;
 const url=(k,max)=>{if(!text(k,max)||/\s/.test(p[k].trim()))return false;try{const u=new URL(p[k].trim());return u.protocol==='https:'&&u.hostname&& !u.username&&!u.password&&/^[a-zA-Z0-9][a-zA-Z0-9.-]*$/.test(u.hostname);}catch{return false;}};
 return !!(url('url',1000)&&url('sourceUrl',500)&&url('licenseUrl',500)&&text('title',200)&&text('author',120)&&text('license',80));
}
function validateRelease(release,scope,photos){
 if(typeof release.version!=='string'||!/^photo-visibility-[a-zA-Z0-9-]+$/.test(release.version))throw Error('Invalid release version.');
 const ids=scope.map(x=>x.id),unique=a=>new Set(a).size===a.length;
 if(ids.some(id=>typeof id!=='string'||! /^[a-zA-Z0-9_-]+$/.test(id))||ids.length!==500||!unique(ids)||!Array.isArray(release.scopeIds)||!equal([...release.scopeIds].sort(),[...ids].sort()))throw Error('Expected exact curated 500 scope.');
 if(!Array.isArray(release.visibleIds)||!Array.isArray(release.excluded)||!unique(release.visibleIds)||!unique(release.excluded.map(x=>x.id)))throw Error('Duplicate or invalid partition.');
 const names=new Map(scope.map(x=>[x.id,x.name]));
 for(const x of release.excluded)if(names.get(x.id)!==x.name||typeof x.reason!=='string'||!x.reason.trim())throw Error('Excluded identity/reason differs.');
 const union=[...release.visibleIds,...release.excluded.map(x=>x.id)];
 if(!unique(union)||!equal(union.sort(),[...ids].sort()))throw Error('Release must partition scope.');
 if(!unique(photos.map(x=>x.foodId))||!equal(photos.map(x=>x.foodId).sort(),[...release.visibleIds].sort()))throw Error('Photo set differs from visible release.');
 for(const p of photos)if(names.get(p.foodId)!==p.foodName||!/^assets\/food_photos\/[a-zA-Z0-9_-]+\.webp$/.test(p.assetPath)||!/^[a-f0-9]{64}$/.test(p.sha256))throw Error('Invalid photo identity/hash.');
 return true;
}
function planRelease(release,documents){
 const byId=new Map(documents.map(d=>[idOf(d),d]));if(byId.size!==documents.length)throw Error('Duplicate documents.');
 const updates=[],skipped=[],conflicts=[];
 for(const x of release.excluded){
  const d=byId.get(x.id);if(!d){conflicts.push({id:x.id,reason:'missing-document'});continue;}
  if(d.name!==`${prefix}/food_catalog/${x.id}`||!d.updateTime)throw Error('Unexpected path/version.');
  const data=decode(d.fields);
  if(data.name!==x.name){conflicts.push({id:x.id,reason:'renamed-record'});continue;}
  if(data.isActive===false){skipped.push({id:x.id,reason:'already-inactive'});continue;}
  if(validCustomPhoto(data.photo)){skipped.push({id:x.id,reason:'admin-custom-photo'});continue;}
  if(data.isActive!==undefined&&data.isActive!==true){conflicts.push({id:x.id,reason:'invalid-active-state'});continue;}
  updates.push({id:x.id,name:x.name,updateTime:d.updateTime});
 }
 return {updates,skipped,conflicts};
}
function makeWrites(plan,actorUid,version){
 if(!/^firebase-cli:[a-f0-9]{24}$/.test(actorUid)||!/^photo-visibility-[a-zA-Z0-9-]+$/.test(version))throw Error('Invalid actor/version.');
 return plan.updates.flatMap(x=>{
  const operation=`${version}-${x.id}`,fields={isActive:false,updatedBy:actorUid,lastAdminOperationId:operation};
  return [{update:{name:`${prefix}/food_catalog/${x.id}`,fields:wire(fields).mapValue.fields},updateMask:{fieldPaths:Object.keys(fields)},currentDocument:{updateTime:x.updateTime},updateTransforms:[{fieldPath:'updatedAt',setToServerValue:'REQUEST_TIME'}]},
   {update:{name:`${prefix}/admin_audit/${operation}`,fields:wire({actorUid,entityType:'food_catalog',entityId:x.id,changedFields:[...Object.keys(fields),'updatedAt'],reason:`Ẩn món chưa có ảnh đã kiểm duyệt · ${version} · Firebase CLI/IAM.`}).mapValue.fields},currentDocument:{exists:false},updateTransforms:[{fieldPath:'at',setToServerValue:'REQUEST_TIME'}]}];
 });
}
function verifyRelease(plan,before,after,actorUid,version){
 const actual=new Map(after.map(d=>[idOf(d),d])),changed=new Set(plan.updates.map(x=>x.id));
 if(actual.size!==after.length||after.length!==before.length)throw Error('Catalog count changed.');
 for(const old of before){
  const d=actual.get(idOf(old));if(!d)throw Error('Missing readback.');
  if(!changed.has(idOf(old))){if(!equal(old,d))throw Error('Unrelated document changed.');continue;}
  const expected={...old.fields,isActive:{booleanValue:false},updatedBy:{stringValue:actorUid},lastAdminOperationId:{stringValue:`${version}-${idOf(old)}`},updatedAt:d.fields.updatedAt};
  if(!d.fields.updatedAt?.timestampValue||Date.parse(d.fields.updatedAt.timestampValue)<Date.parse(old.updateTime)||!equal(d.fields,expected)||d.name!==old.name||d.createTime!==old.createTime||!d.updateTime||d.updateTime===old.updateTime)throw Error(`Unexpected readback: ${idOf(old)}`);
 }
 return {hidden:changed.size,unchanged:before.length-changed.size,total:after.length};
}
function localRelease(){
 const read=p=>JSON.parse(fs.readFileSync(path.join(root,p),'utf8'));
 const release=read('data/food_catalog/photo-release.json'),scope=read('data/food_catalog/photo-coverage-500.json').foods,manifest=read('assets/food_photos/manifest.json');
 validateRelease(release,scope,manifest.photos);
 for(const p of manifest.photos)if(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,p.assetPath))).digest('hex')!==p.sha256)throw Error('Image hash mismatch.');
 return {release,sourceSha256:hash({release,scope,manifest})};
}
async function main(args){
 const [mode,target]=args,directory=path.resolve(target||'');
 if(!['review','apply','verify'].includes(mode)||!directory.startsWith(path.join(root,'build')+path.sep))throw Error('Use review|apply|verify <build/new-directory>.');
 if(JSON.parse(fs.readFileSync(path.join(root,'.firebaserc'),'utf8')).projects.default!==project)throw Error('Project mismatch.');
 const {release,sourceSha256}=localRelease();
 const auth=require(path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib/auth.js')),account=auth.getGlobalDefaultAccount();
 if(!account?.tokens?.refresh_token||!account.user?.email)throw Error('Firebase CLI login required.');
 const actorUid='firebase-cli:'+crypto.createHash('sha256').update(account.user.email.toLowerCase()).digest('hex').slice(0,24),token=await auth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform']);
 const api=`https://firestore.googleapis.com/v1/${prefix}`;
 const request=async(url,body)=>{const r=await fetch(url,{method:body?'POST':'GET',headers:{Authorization:`Bearer ${token.access_token}`,'Content-Type':'application/json'},body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(30000)});if(!r.ok)throw Error(`Firebase HTTP ${r.status}; no response body/credentials logged. Read back before retrying.`);return r.json();};
 async function readFoods(){const docs=[];let cursor;do{const q=new URLSearchParams({pageSize:'300'});if(cursor)q.set('pageToken',cursor);const r=await request(`${api}/food_catalog?${q}`);docs.push(...r.documents||[]);cursor=r.nextPageToken;}while(cursor);return docs.sort((a,b)=>a.name.localeCompare(b.name));}
 const save=(n,d)=>fs.writeFileSync(path.join(directory,n),JSON.stringify(d,null,2),{flag:'wx'}),read=n=>JSON.parse(fs.readFileSync(path.join(directory,n),'utf8'));
 if(mode==='review'){
  if(fs.existsSync(directory))throw Error('Choose a new review directory.');
  const before=await readFoods(),plan=planRelease(release,before),writes=makeWrites(plan,actorUid,release.version);
  fs.mkdirSync(directory,{recursive:true});save('before.json',before);save('manifest.json',{project,version:release.version,actorUid,sourceSha256,beforeSha256:hash(before),...plan});save('writes.json',writes);
  console.log(JSON.stringify({mode,project,updates:plan.updates.length,skipped:plan.skipped,conflicts:plan.conflicts}));return;
 }
 const manifest=read('manifest.json'),before=read('before.json'),plan=planRelease(release,before),writes=makeWrites(plan,actorUid,release.version);
 if(manifest.project!==project||manifest.version!==release.version||manifest.actorUid!==actorUid||manifest.sourceSha256!==sourceSha256||manifest.beforeSha256!==hash(before)||!equal(plan,{updates:manifest.updates,skipped:manifest.skipped,conflicts:manifest.conflicts})||!equal(writes,read('writes.json')))throw Error('Review source/artifacts changed.');
 if(mode==='apply'){
  if(!equal(await readFoods(),before))throw Error('Production changed; prepare a new review.');
  if(writes.length>450||!writes.length)throw Error('Invalid write count.');
  save('apply-started.json',{at:new Date().toISOString()});save('receipt.json',await request(api+':commit',{writes}));
 }
 const after=await readFoods(),result=verifyRelease(plan,before,after,actorUid,release.version),expectedAudits=writes.filter(w=>w.update.name.includes('/admin_audit/'));
 if(expectedAudits.length){const audits=await request(api+':batchGet',{documents:expectedAudits.map(w=>w.update.name)});if(audits.length!==expectedAudits.length)throw Error('Audit count differs.');for(const w of expectedAudits){const d=audits.find(x=>x.found?.name===w.update.name)?.found;if(!d?.fields.at?.timestampValue)throw Error('Missing audit.');const f={...d.fields};delete f.at;if(!equal(f,w.update.fields))throw Error('Audit differs.');}}
 save(`verified-${Date.now()}.json`,{...result,audits:expectedAudits.length,at:new Date().toISOString()});save(`after-${Date.now()}.json`,after);console.log(JSON.stringify({mode,project,...result,audits:expectedAudits.length}));
}
module.exports={validCustomPhoto,validateRelease,planRelease,makeWrites,verifyRelease,project,prefix};
if(require.main===module)main(process.argv.slice(2)).catch(e=>{console.error(e.message);process.exitCode=1;});
