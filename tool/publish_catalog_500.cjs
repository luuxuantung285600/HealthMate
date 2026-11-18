'use strict';
// Create-only, reviewed publication of the 114 additional VDD entries used by the
// app. Uses existing Firebase CLI IAM; never touches users/* or updates foods.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {isDeepStrictEqual: equal} = require('node:util');
const {buildCatalog, decode} = require('./import_food_catalog.cjs');
const {wire} = require('./publish_verified_nutrients.cjs');
const root = path.resolve(__dirname, '..');
const project = 'healthmate-app-20261013';
const version = 'catalog-500-20261110-v1';
const prefix = `projects/${project}/databases/(default)/documents`;
const hash = data => crypto.createHash('sha256').update(JSON.stringify(data)).digest('hex');
const normalize = name => name.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/đ/g,'d').trim();

function catalog() {
  const definitions = require('../data/food_catalog/expanded-vietnamese-2026-11-10.json').foods;
  const byId = new Map(buildCatalog().map(food => [food.id, food]));
  const foods = definitions.map(row => byId.get(row.id));
  if (foods.length !== 114 || foods.some(food => !food || food.sourceDetails.method !== 'reference_table' ||
      food.servingBasis !== 'per_100g' || food.unit !== 'g' || !food.isEstimated)) {
    throw Error('Expected the reviewed 114 VDD additions.');
  }
  if (new Set(foods.map(food => food.id)).size !== foods.length ||
      new Set(foods.map(food => normalize(food.name))).size !== foods.length) throw Error('Duplicate release identity.');
  return foods;
}

function planRelease(foods, documents) {
  const ids = new Set(documents.map(doc=>doc.name.split('/').at(-1)));
  const names = new Map(documents.map(doc=>[normalize(decode(doc.fields).name || ''),doc.name.split('/').at(-1)]));
  const creates=[], skipped=[], conflicts=[];
  for(const food of foods) {
    if(ids.has(food.id)) { skipped.push(food.id); continue; }
    if(names.has(normalize(food.name))) {conflicts.push({id:food.id,reason:'existing-name-with-another-id'});continue;}
    creates.push(food);
  }
  return {creates,skipped,conflicts};
}

function makeWrites(plan, actorUid) {
  if (!/^firebase-cli:[a-f0-9]{24}$/.test(actorUid)) throw Error('IAM maintenance actor required.');
  return plan.creates.flatMap(food=>{
    const {id,...data}=food;
    const operation=`${version}-${id}`;
    const fields={...data,updatedBy:actorUid,lastAdminOperationId:operation};
    return [
      {update:{name:`${prefix}/food_catalog/${id}`,fields:wire(fields).mapValue.fields},currentDocument:{exists:false},updateTransforms:[{fieldPath:'updatedAt',setToServerValue:'REQUEST_TIME'}]},
      {update:{name:`${prefix}/admin_audit/${operation}`,fields:wire({actorUid,entityType:'food_catalog',entityId:id,changedFields:[...Object.keys(fields),'updatedAt'],reason:`Bổ sung danh mục ${version} · nguồn VDD 2007 · Firebase CLI/IAM.`}).mapValue.fields},currentDocument:{exists:false},updateTransforms:[{fieldPath:'at',setToServerValue:'REQUEST_TIME'}]},
    ];
  });
}

function verifyRelease(plan, before, after, actorUid) {
  const actual=new Map(after.map(doc=>[doc.name.split('/').at(-1),doc]));
  if(actual.size!==before.length+plan.creates.length)throw Error('Unexpected catalog count.');
  for(const doc of before) {
    if(!equal(actual.get(doc.name.split('/').at(-1)),doc))throw Error('An existing document changed.');
  }
  for(const food of plan.creates) {
    const doc=actual.get(food.id);
    if(!doc?.fields.updatedAt?.timestampValue)throw Error('Missing create timestamp.');
    const data=decode(doc.fields),{id,...expected}=food;
    delete data.updatedAt;delete data.updatedBy;delete data.lastAdminOperationId;
    if(!equal(data,expected)||doc.fields.updatedBy.stringValue!==actorUid||doc.fields.lastAdminOperationId.stringValue!==`${version}-${id}`)throw Error(`Readback differs: ${food.id}`);
  }
  return {verifiedCreates:plan.creates.length,unchanged:before.length,total:after.length};
}

async function main(args) {
  const [mode,target]=args,directory=path.resolve(target||'');
  if(!['review','apply','verify'].includes(mode)||!directory.startsWith(path.join(root,'build')+path.sep))throw Error('Use review|apply|verify <build/new-directory>.');
  if(JSON.parse(fs.readFileSync(path.join(root,'.firebaserc'),'utf8')).projects.default!==project)throw Error('Project mismatch.');
  const foods=catalog();
  const auth=require(path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib/auth.js'));
  const account=auth.getGlobalDefaultAccount();
  if(!account?.tokens?.refresh_token||!account.user?.email)throw Error('Firebase CLI login required.');
  const actorUid='firebase-cli:'+crypto.createHash('sha256').update(account.user.email.toLowerCase()).digest('hex').slice(0,24);
  const token=await auth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform']);
  const api=`https://firestore.googleapis.com/v1/${prefix}`;
  const request=async(url,body)=>{
    const response=await fetch(url,{method:body?'POST':'GET',headers:{Authorization:`Bearer ${token.access_token}`,'Content-Type':'application/json'},body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(30000)});
    if(!response.ok)throw Error(`Firebase HTTP ${response.status}; no response body/credentials logged. Read back before retrying.`);
    return response.json();
  };
  async function readFoods(){
    const docs=[];let cursor;
    do{const query=new URLSearchParams({pageSize:'300'});if(cursor)query.set('pageToken',cursor);
      const result=await request(`${api}/food_catalog?${query}`);docs.push(...result.documents||[]);cursor=result.nextPageToken;
    }while(cursor);
    return docs.sort((a,b)=>a.name.localeCompare(b.name));
  }
  const save=(name,data)=>fs.writeFileSync(path.join(directory,name),JSON.stringify(data,null,2),{flag:'wx'});
  if(mode==='review'){
    if(fs.existsSync(directory))throw Error('Choose a new review directory.');
    const before=await readFoods(),plan=planRelease(foods,before);
    const manifest={project,version,actorUid,catalogSha256:hash(foods),beforeSha256:hash(before),...plan};
    fs.mkdirSync(directory,{recursive:true});save('before.json',before);save('manifest.json',manifest);save('writes.json',makeWrites(plan,actorUid));
    console.log(JSON.stringify({mode,project,existing:before.length,creates:plan.creates.length,skipped:plan.skipped.length,conflicts:plan.conflicts}));return;
  }
  const manifest=JSON.parse(fs.readFileSync(path.join(directory,'manifest.json'),'utf8'));
  const before=JSON.parse(fs.readFileSync(path.join(directory,'before.json'),'utf8'));
  if(manifest.project!==project||manifest.version!==version||manifest.actorUid!==actorUid||manifest.catalogSha256!==hash(foods)||manifest.beforeSha256!==hash(before)||!equal(planRelease(foods,before),{creates:manifest.creates,skipped:manifest.skipped,conflicts:manifest.conflicts}))throw Error('Review source/artifacts changed.');
  if(mode==='apply'){
    if(manifest.conflicts.length||!equal(await readFoods(),before))throw Error('Conflict or production changed. Prepare a new review.');
    const writes=makeWrites(manifest,actorUid);
    if(!equal(writes,JSON.parse(fs.readFileSync(path.join(directory,'writes.json'),'utf8')))||writes.length>450||!writes.length)throw Error('Invalid reviewed writes.');
    save('apply-started.json',{at:new Date().toISOString()});save('receipt.json',await request(api+':commit',{writes}));
  }
  const after=await readFoods(),result=verifyRelease(manifest,before,after,actorUid);
  const expectedAudits=makeWrites(manifest,actorUid).filter(w=>w.update.name.includes('/admin_audit/'));
  const audits=await request(api+':batchGet',{documents:expectedAudits.map(w=>w.update.name)});
  for(const expected of expectedAudits){
    const found=audits.find(row=>row.found?.name===expected.update.name)?.found;
    if(!found?.fields.at?.timestampValue)throw Error('Missing audit.');
    const fields={...found.fields};delete fields.at;
    if(!equal(decode(fields),decode(expected.update.fields)))throw Error('Audit differs.');
  }
  save(`verified-${Date.now()}.json`,{...result,at:new Date().toISOString(),audits:expectedAudits.length});
  save(`after-${Date.now()}.json`,after);
  console.log(JSON.stringify({mode,project,...result,audits:expectedAudits.length}));
}

module.exports={catalog,planRelease,makeWrites,verifyRelease,project,version};
if(require.main===module)main(process.argv.slice(2)).catch(error=>{console.error(error.message);process.exitCode=1;});
