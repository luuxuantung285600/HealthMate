import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';
const require=createRequire(import.meta.url);
const {prepare}=require('../tool/prepare-realtime-release.cjs');
const root=fileURLToPath(new URL('../../',import.meta.url));
const normalized=value=>value.replace(/\r\n/g,'\n').trim();

test('Spark release ships the current complete client contract even when the live baseline is legacy',()=>{
  const build=path.join(root,'build');fs.mkdirSync(build,{recursive:true});
  const fixture=fs.mkdtempSync(path.join(build,'release-contract-'));
  try {
    const baseline=path.join(fixture,'baseline');fs.mkdirSync(baseline);
    const old="rules_version = '2'; service cloud.firestore { match /databases/{db}/documents { match /{all=**} { allow read, write: if false; } } }";
    fs.writeFileSync(path.join(baseline,'firestore.rules'),old);
    fs.writeFileSync(path.join(baseline,'metadata.json'),JSON.stringify({project:'healthmate-app-20261013',rulesetName:'fixture-legacy',deployedSha256:crypto.createHash('sha256').update(normalized(old)).digest('hex')}));
    const config=path.join(fixture,'config.js');
    fs.writeFileSync(config,'window.HEALTHMATE_ADMIN_CONFIG = '+JSON.stringify({firebase:{projectId:'healthmate-app-20261013'},appCheckSiteKey:'public-fixture-key'})+';');
    const out=path.join(fixture,'release');const manifest=prepare(baseline,config,out,'spark');
    assert.equal(normalized(fs.readFileSync(path.join(out,'firestore.rules'),'utf8')),normalized(fs.readFileSync(path.join(root,'firestore.rules'),'utf8')));
    assert.equal(manifest.rulesSource,'firestore.rules');
    assert.equal(JSON.parse(fs.readFileSync(path.join(out,'firebase.review.json'),'utf8')).functions,undefined);
    assert.match(fs.readFileSync(path.join(out,'site/config.js'),'utf8'),/"statisticsMode": "firestore"/);
    for(const file of ['admin-icons.mjs','appearance.js','appearance.css','feature-identity.css','licenses/lucide.txt','food-photos.mjs','food-photos.css','bundled-food-photos.mjs','food-photos/vn-pho-bo.webp','food-photos/ATTRIBUTION.txt','exercise-media-preview.mjs','exercise-library.css']){
      assert.deepEqual(fs.readFileSync(path.join(out,'site',file)),fs.readFileSync(path.join(root,'admin-web/dist',file)),`Missing shared identity asset: ${file}`);
    }
    assert.match(JSON.parse(fs.readFileSync(path.join(out,'firebase.review.json'),'utf8')).hosting.headers[0].headers.find(h=>h.key==='Content-Security-Policy').value,/img-src 'self' https:/);
    assert.throws(()=>prepare(baseline,config,out,'spark'),/new directory/);
  } finally {
    // Resolve and bound the exact target before recursive cleanup on Windows.
    const target=path.resolve(fixture);
    assert.ok(target.startsWith(path.resolve(build)+path.sep));
    fs.rmSync(target,{recursive:true,force:true});
  }
});
