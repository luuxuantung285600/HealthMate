'use strict';
// Narrow, review-first maintenance release using the existing Firebase CLI IAM
// session. Never touches users/*, creates foods, or replaces catalog documents.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {isDeepStrictEqual: equal} = require('node:util');
const {buildCatalog, decode} = require('./import_food_catalog.cjs');
const project = 'healthmate-app-20261013';
const version = 'verified-nutrients-2026-11-10-v1';
const prefix = `projects/${project}/databases/(default)/documents`;
const legacyLabel = 'USDA FoodData Central (SR Legacy) — giá trị tham khảo/100 g';
const digest = data => crypto.createHash('sha256').update(JSON.stringify(data)).digest('hex');
const own = (data, key) => Object.hasOwn(data, key);
const map = data => data !== null && typeof data === 'object' && !Array.isArray(data);
// Frozen IDs from the reviewed release: later catalog additions are separate
// releases and must never silently enter this already-published operation.
const releasedIds = new Set(require('../data/food_catalog/verified-nutrient-release-ids.json'));
const foods = () => buildCatalog().filter(f => releasedIds.has(f.id));
const canonical = data => {
  if (Array.isArray(data)) return data.map(canonical);
  if (!map(data)) return data;
  if (own(data,'integerValue')) return {doubleValue:Number(data.integerValue)};
  return Object.fromEntries(Object.entries(data).map(([key,val])=>[key,canonical(val)]));
};

function planRelease(catalog, documents) {
  const byId = new Map(documents.map(doc => [doc.name.split('/').at(-1), doc]));
  if (byId.size !== documents.length) throw Error('Duplicate production documents.');
  const updates = [], skipped = [], conflicts = [];
  for (const food of catalog) {
    const doc = byId.get(food.id);
    const reject = reason => conflicts.push({id: food.id, reason});
    if (!doc) { reject('missing-document'); continue; }
    if (doc.name !== `${prefix}/food_catalog/${food.id}` || !doc.updateTime) throw Error('Unexpected document path/version.');
    const before = decode(doc.fields);
    const legacy = food.sourceDetails.method === 'usda_sr_legacy' && before.sourceLabel === legacyLabel;
    const keys = ['name','sourceUrl','servingBasis','unit','kcalPer100g','proteinGPer100g','carbsGPer100g','fatGPer100g'];
    if (keys.some(key => before[key] !== food[key]) || (!legacy && before.sourceLabel !== food.sourceLabel)) {
      reject('identity-source-or-macros-changed'); continue;
    }
    if (before.sourceDetails != null && !map(before.sourceDetails)) { reject('invalid-source-details'); continue; }
    const details = before.sourceDetails || {};
    const sourceKeys = food.sourceDetails.method === 'manufacturer_label'
      ? ['method','basis','netWeightGrams','variantIndex','packageImageUrl']
      : food.sourceDetails.method === 'reference_table' ? ['method','foodCode','pdfPage','basis']
      : ['method','fdcId','basis','nutrientId'];
    if ((!legacy || own(before, 'sourceDetails')) && sourceKeys.some(key => !equal(details[key], food.sourceDetails[key]))) {
      reject('source-identity-changed'); continue;
    }
    if (food.sourceDetails.method === 'manufacturer_label' &&
        (before.servingGrams !== food.servingGrams || ['kcal','proteinG','carbsG','fatG'].some(key =>
          details.nutrientsPerPackage?.[key] !== food.sourceDetails.nutrientsPerPackage[key]))) {
      reject('package-identity-changed'); continue;
    }
    const extras = before.extraNutrientsPer100g;
    if (own(before,'extraNutrientsPer100g') && (!map(extras) || Object.keys(extras).length === 0)) {
      reject('explicitly-cleared-extra-nutrients'); continue;
    }
    const expected = food.extraNutrientsPer100g;
    if (Object.keys(expected).some(key => own(extras || {}, key) && extras[key] !== expected[key])) {
      reject('existing-nutrient-conflict'); continue;
    }
    const patch = {};
    for (const [key, val] of Object.entries(expected)) {
      if (!own(extras || {}, key)) patch[`extraNutrientsPer100g.${key}`] = val;
    }
    // These four USDA fiber values were verified in the same sourced dataset.
    // Explicit null/zero/other existing values are never overwritten.
    if (food.fiberGPer100g != null && !own(before,'fiberGPer100g')) {
      patch.fiberGPer100g = food.fiberGPer100g;
      if (!own(before,'fiberSourceUrl')) patch.fiberSourceUrl = food.fiberSourceUrl;
    }
    if (!Object.keys(patch).length) { skipped.push(food.id); continue; }
    const evidence = {...food.sourceDetails.additionalNutrientEvidence, releaseVersion: version};
    if (own(details,'additionalNutrientEvidence') && !equal(details.additionalNutrientEvidence,evidence)) {
      reject('existing-evidence-conflict'); continue;
    }
    if (!own(before,'sourceDetails')) {
      patch.sourceDetails = {...food.sourceDetails, additionalNutrientEvidence: evidence};
    } else {
      patch['sourceDetails.additionalNutrientEvidence'] = evidence;
      if (food.sourceDetails.method === 'manufacturer_label') {
        for (const key of ['sodiumMg','sugarG']) {
          const val = food.sourceDetails.nutrientsPerPackage[key];
          if (val === undefined) continue;
          if (own(details.nutrientsPerPackage,key) && details.nutrientsPerPackage[key] !== val) {
            reject('existing-package-nutrient-conflict');
          } else if (!own(details.nutrientsPerPackage,key)) patch[`sourceDetails.nutrientsPerPackage.${key}`] = val;
        }
        if (conflicts.at(-1)?.id === food.id) continue;
      }
    }
    updates.push({id: food.id, updateTime: doc.updateTime, patch});
  }
  return {updates, skipped, conflicts};
}

function wire(data) {
  if (data === null) return {nullValue: null};
  if (typeof data === 'string') return {stringValue: data};
  if (typeof data === 'boolean') return {booleanValue: data};
  if (typeof data === 'number' && Number.isFinite(data)) return {doubleValue: data};
  if (Array.isArray(data)) return {arrayValue: {values: data.map(wire)}};
  if (map(data)) return {mapValue: {fields: Object.fromEntries(Object.entries(data).map(([k,v]) => [k,wire(v)]))}};
  throw Error('Invalid Firestore value.');
}
function setPath(data, fieldPath, val) {
  const keys = fieldPath.split('.');
  let at = data;
  for (const key of keys.slice(0,-1)) at = at[key] ??= {};
  at[keys.at(-1)] = val;
}
function makeWrites(plan, actorUid) {
  if (!/^firebase-cli:[a-f0-9]{24}$/.test(actorUid)) throw Error('IAM maintenance actor required.');
  return plan.updates.flatMap(item => {
    const operation = `${version}-${item.id}`;
    if (operation.length > 100) throw Error('Audit operation too long.');
    const fields = {};
    for (const [key,val] of Object.entries(item.patch)) setPath(fields,key,val);
    fields.updatedBy = actorUid;
    fields.lastAdminOperationId = operation;
    const changedFields = [...new Set(Object.keys(item.patch).map(key => key.split('.')[0])), 'updatedBy','lastAdminOperationId','updatedAt'];
    return [{update: {name: `${prefix}/food_catalog/${item.id}`, fields: wire(fields).mapValue.fields},
      updateMask: {fieldPaths: [...Object.keys(item.patch),'updatedBy','lastAdminOperationId']},
      currentDocument: {updateTime: item.updateTime},
      updateTransforms: [{fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME'}]},
    {update: {name: `${prefix}/admin_audit/${operation}`, fields: wire({actorUid, entityType: 'food_catalog',
      entityId: item.id, changedFields, reason: `Phát hành ${version} · nguồn đã đối chiếu · Firebase CLI/IAM.`}).mapValue.fields},
      currentDocument: {exists: false}, updateTransforms: [{fieldPath: 'at', setToServerValue: 'REQUEST_TIME'}]}];
  });
}
function verifyRelease(plan, beforeDocs, afterDocs) {
  const before = new Map(beforeDocs.map(d => [d.name.split('/').at(-1), d]));
  const after = new Map(afterDocs.map(d => [d.name.split('/').at(-1), d]));
  if (after.size !== before.size) throw Error('Document count changed.');
  for (const [id, doc] of before) {
    const actual = after.get(id);
    if (!actual) throw Error(`Missing readback: ${id}`);
    const patch = plan.updates.find(p => p.id === id);
    const expected = structuredClone(doc.fields);
    if (patch) {
      // Operate on the Firestore wire tree, retaining timestamps and all other types.
      for (const [fieldPath,val] of Object.entries(patch.patch)) {
        const keys=fieldPath.split('.');let at=expected;
        for (const key of keys.slice(0,-1)) at=(at[key] ??= {mapValue:{fields:{}}}).mapValue.fields ??= {};
        at[keys.at(-1)] = wire(val);
      }
      for (const key of ['updatedAt','updatedBy','lastAdminOperationId']) delete expected[key];
    }
    const received = structuredClone(actual.fields);
    if (patch) for (const key of ['updatedAt','updatedBy','lastAdminOperationId']) delete received[key];
    // Firestore may canonicalize integral doubles to integerValue.
    if (!equal(canonical(expected), canonical(received))) throw Error(`Unexpected changed/missing data: ${id}`);
    if (!patch && actual.updateTime !== doc.updateTime) throw Error(`Unselected document changed: ${id}`);
  }
  return {verified: plan.updates.length, unchanged: before.size-plan.updates.length};
}

async function main(args) {
  const mode=args[0], directory=path.resolve(args[1] || '');
  if (!['review','apply','verify'].includes(mode) || !directory.startsWith(path.resolve('build')+path.sep)) throw Error('Use review|apply|verify <build/new-release-directory>.');
  if (JSON.parse(fs.readFileSync('.firebaserc','utf8')).projects.default !== project) throw Error('Project mismatch.');
  const auth=require(path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib/auth.js'));
  const account=auth.getGlobalDefaultAccount();
  if (!account?.tokens?.refresh_token || !account.user?.email) throw Error('Firebase CLI login required.');
  const actorUid='firebase-cli:'+crypto.createHash('sha256').update(account.user.email.toLowerCase()).digest('hex').slice(0,24);
  const token=await auth.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform']);
  const api=`https://firestore.googleapis.com/v1/${prefix}`;
  const request=async(url,body)=>{
    const response=await fetch(url,{method:body?'POST':'GET',headers:{Authorization:`Bearer ${token.access_token}`,'Content-Type':'application/json'},body:body?JSON.stringify(body):undefined,signal:AbortSignal.timeout(30000)});
    if (!response.ok) throw Error(`Firebase HTTP ${response.status}; re-read before retry. No response body or credential logged.`);
    return response.json();
  };
  const catalog=foods();
  async function readFoods() {
    const rows=await request(api+':batchGet',{documents:catalog.map(f=>`${prefix}/food_catalog/${f.id}`)});
    if (!Array.isArray(rows) || rows.length!==catalog.length) throw Error('Incomplete catalog read.');
    return rows.filter(r=>r.found).map(r=>r.found).sort((a,b)=>a.name.localeCompare(b.name));
  }
  const save=(file,data)=>fs.writeFileSync(path.join(directory,file),JSON.stringify(data,null,2),{flag:'wx'});
  if (mode==='review') {
    if (fs.existsSync(directory)) throw Error('Choose a new review directory.');
    const documents=await readFoods(),plan=planRelease(catalog,documents);
    fs.mkdirSync(directory,{recursive:true});
    save('before.json',documents);
    const manifest={project,version,actorUid,reviewedAt:new Date().toISOString(),catalogSha256:digest(catalog),backupSha256:digest(documents),...plan};
    save('manifest.json',manifest);save('writes.json',makeWrites(plan,actorUid));
    console.log(JSON.stringify({mode,project,version,updates:plan.updates.length,skipped:plan.skipped,conflicts:plan.conflicts,directory}));
    return;
  }
  const manifest=JSON.parse(fs.readFileSync(path.join(directory,'manifest.json'),'utf8'));
  const backup=JSON.parse(fs.readFileSync(path.join(directory,'before.json'),'utf8'));
  if (manifest.project!==project || manifest.version!==version || manifest.actorUid!==actorUid ||
      manifest.catalogSha256!==digest(catalog) || manifest.backupSha256!==digest(backup) ||
      !equal(planRelease(catalog,backup),{updates:manifest.updates,skipped:manifest.skipped,conflicts:manifest.conflicts})) throw Error('Review artifact/source changed.');
  if (mode==='apply') {
    if (manifest.conflicts.length) throw Error('Resolve conflicts before publication.');
    if (!equal(await readFoods(),backup)) throw Error('Production changed since review. Prepare a new review.');
    const writes=makeWrites(manifest,actorUid);
    if (!equal(writes,JSON.parse(fs.readFileSync(path.join(directory,'writes.json'),'utf8')))) throw Error('Reviewed writes changed.');
    if (!writes.length || writes.length>450) throw Error('Invalid atomic write count.');
    // One atomic commit; per-document updateTime prevents a concurrent admin edit
    // from being overwritten. Audit creates fail closed on an ambiguous retry.
    save('apply-started.json',{startedAt:new Date().toISOString(),version});
    const receipt=await request(api+':commit',{writes});
    save('receipt.json',receipt);
  }
  const after=await readFoods(), result=verifyRelease(manifest,backup,after);
  for (const item of manifest.updates) {
    const doc=after.find(d=>d.name.endsWith('/'+item.id));
    if (doc.fields.updatedBy?.stringValue!==actorUid || doc.fields.lastAdminOperationId?.stringValue!==`${version}-${item.id}` || !doc.fields.updatedAt?.timestampValue) throw Error('Publication metadata not confirmed.');
  }
  const audits=await request(api+':batchGet',{documents:manifest.updates.map(item=>`${prefix}/admin_audit/${version}-${item.id}`)});
  const expectedAudits=makeWrites(manifest,actorUid).filter(w=>w.update.name.includes('/admin_audit/'));
  for (const expected of expectedAudits) {
    const found=audits.find(row=>row.found?.name===expected.update.name)?.found;
    if (!found || !found.fields.at?.timestampValue) throw Error('Audit not confirmed.');
    const fields={...found.fields};delete fields.at;
    if (!equal(decode(fields),decode(expected.update.fields))) throw Error('Audit fields differ.');
  }
  save(`after-${Date.now()}.json`,after);
  save(`verified-${Date.now()}.json`,{...result,project,version,verifiedAt:new Date().toISOString(),audits:audits.length});
  console.log(JSON.stringify({mode,...result,project,version,audits:audits.length}));
}

module.exports={planRelease,makeWrites,verifyRelease,foods,project,version,wire};
if(require.main===module)main(process.argv.slice(2)).catch(error=>{console.error(error.message);process.exitCode=1;});
