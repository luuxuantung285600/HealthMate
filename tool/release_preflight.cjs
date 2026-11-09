'use strict';
// Read-only local inputs. Never log property values, tokens or private paths.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const demoIdentity = Object.freeze({applicationId:'com.example.healthmate',versionName:'1.0.0',versionCode:1});
const defineKeys = new Set(['HEALTHMATE_ENABLE_ADMIN_CONTROLS','HEALTHMATE_ENABLE_PREMIUM_DEMO','HEALTHMATE_ENABLE_PLAY_BILLING',
  'HEALTHMATE_ENABLE_CHATBOT','HEALTHMATE_ENABLE_FOOD_SCANNER','HEALTHMATE_CHAT_API_URL',
  'HEALTHMATE_GOOGLE_SERVER_CLIENT_ID']);
function validateDefines(defines) {
  const errors=[];
  if(!defines || typeof defines!=='object' || Array.isArray(defines)) return ['invalid-defines-object'];
  for(const [key,value] of Object.entries(defines)) {
    if(!defineKeys.has(key)) {errors.push('unknown-or-development-define');continue;}
    if(key.startsWith('HEALTHMATE_ENABLE_') && typeof value!=='boolean') errors.push('boolean-define-required');
    if(key==='HEALTHMATE_ENABLE_PREMIUM_DEMO' && value!==false) errors.push('premium-demo-forbidden');
    if(key==='HEALTHMATE_ENABLE_PLAY_BILLING' && value!==false) errors.push('play-billing-infrastructure-not-verified');
    if(key.endsWith('_URL') || key==='HEALTHMATE_GOOGLE_SERVER_CLIENT_ID') {
      if(typeof value!=='string') {errors.push('string-define-required');continue;}
      if(key.endsWith('_URL') && value) {
        try {const url=new URL(value);if(url.protocol!=='https:' || url.username || url.password ||
          url.hostname==='localhost' || url.hostname.endsWith('.localhost') ||
          url.hostname.includes(':') || !url.hostname.includes('.') ||
          url.hostname.endsWith('.local') || url.hostname.endsWith('.internal') ||
          /^\d+(\.\d+){3}$/.test(url.hostname)) errors.push('public-https-url-required');}
        catch {errors.push('public-https-url-required');}
      }
    }
  }
  for(const key of ['HEALTHMATE_ENABLE_ADMIN_CONTROLS','HEALTHMATE_ENABLE_PREMIUM_DEMO',
    'HEALTHMATE_ENABLE_CHATBOT','HEALTHMATE_ENABLE_FOOD_SCANNER','HEALTHMATE_CHAT_API_URL']) {
    if(!Object.hasOwn(defines,key)) errors.push('explicit-feature-config-required');
  }
  if(defines.HEALTHMATE_ENABLE_ADMIN_CONTROLS!==true) errors.push('admin-policy-required');
  if(defines.HEALTHMATE_ENABLE_CHATBOT===true && !defines.HEALTHMATE_CHAT_API_URL) errors.push('chat-gateway-required');
  // Infrastructure verification is still absent: changing flags alone is not approval.
  if(defines.HEALTHMATE_ENABLE_CHATBOT===true) errors.push('ai-infrastructure-not-verified');
  if(defines.HEALTHMATE_ENABLE_CHATBOT===false && defines.HEALTHMATE_CHAT_API_URL) errors.push('disabled-gateway-url-must-be-empty');
  return [...new Set(errors)];
}
function properties(text) {
  const result={};
  for(const line of text.split(/\r?\n/)) {
    if(!line.trim() || /^\s*[#!]/.test(line)) continue;
    const match=/^\s*([^\s:=]+)\s*[:=]\s*(.*)$/.exec(line);
    if(match) result[match[1]]=match[2].trim().replace(/\\([\\: =])/g,'$1');
  }
  return result;
}
function inspectSigning(values,exists=file=>{try{return fs.statSync(file).isFile();}catch{return false;}}) {
  if(!values || ['storeFile','storePassword','keyAlias','keyPassword'].some(k=>typeof values[k]!=='string'||!values[k].trim())) return ['release-signing-missing'];
  const keyPath=values.storeFile;
  if(!path.isAbsolute(keyPath)) return ['absolute-keystore-required'];
  if(path.basename(keyPath).toLowerCase()==='debug.keystore' || values.keyAlias.toLowerCase()==='androiddebugkey') return ['debug-signing-forbidden'];
  return exists(keyPath)?[]:['keystore-not-found'];
}
function inspect(root,definesFile=path.join(root,'config/release-candidate.json')) {
  const blockers=[];
  let defines;
  try {defines=JSON.parse(fs.readFileSync(definesFile,'utf8').replace(/^\uFEFF/,''));blockers.push(...validateDefines(defines));}
  catch {blockers.push('release-config-unreadable');}
  const gradle=fs.readFileSync(path.join(root,'android/app/build.gradle.kts'),'utf8');
  const pubspec=fs.readFileSync(path.join(root,'pubspec.yaml'),'utf8');
  const applicationId=/applicationId\s*=\s*"([^"]+)"/.exec(gradle)?.[1];
  const version=/^version:\s*([^\s+]+)\+(\d+)\s*$/m.exec(pubspec);
  const identity={applicationId,versionName:version?.[1],versionCode:version?Number(version[2]):null};
  if(JSON.stringify(identity)!==JSON.stringify(demoIdentity)) blockers.push('demo-identity-changed');
  const signingPath=path.join(root,'android/key.properties');
  try {blockers.push(...inspectSigning(properties(fs.readFileSync(signingPath,'utf8'))));}
  catch {blockers.push('release-signing-missing');}
  const hash=file=>crypto.createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex');
  return {checkedAtUtc:new Date().toISOString(),scope:'local-source-preflight',identity,
    identityApproval:'owner accepted current identity for demo; not Play Store identity approval',
    releaseConfigSha256:fs.existsSync(definesFile)?crypto.createHash('sha256').update(fs.readFileSync(definesFile)).digest('hex'):null,
    rulesSha256:hash('firestore.rules'),indexesSha256:hash('firestore.indexes.json'),
    signingConfigured:!blockers.some(x=>x.includes('signing')||x.includes('keystore')),
    blockers:[...new Set(blockers)],buildInputsReady:blockers.length===0,
    releaseAccepted:false,apkSha256:null,nativeAcceptance:'not run; owner tests Android',
    productionAI:'blocked by real IAM/direct-route/retention verification',
    productionDeletion:'blocked by durable privileged deletion/retention job',
    loadAcceptance:'not run on signed release or production; see release-readiness.md'};
}
if(require.main===module) {
  try {
    const root=path.resolve(__dirname,'..');
    const args=process.argv.slice(2);
    if(args.length && (args.length!==2 || args[0]!=='--config')) throw Error('invalid-arguments');
    const report=inspect(root,args.length?path.resolve(args[1]):undefined);
    console.log(JSON.stringify(report,null,2));
    process.exitCode=report.buildInputsReady?0:1;
  } catch {console.error(JSON.stringify({scope:'local-source-preflight',blocked:true,code:'preflight-input-error'}));process.exitCode=1;}
}
module.exports={demoIdentity,validateDefines,properties,inspectSigning,inspect};
