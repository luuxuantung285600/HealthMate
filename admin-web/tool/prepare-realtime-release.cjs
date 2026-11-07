'use strict';
// Offline packaging: the live Rules backup is rollback/provenance, not a source
// template. Ship the canonical Rules that the app integration suite tests.
// This tool never writes Firestore, deploys, grants roles or handles secrets.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
function prepare(baseline,publicConfig,output,profile='functions'){
  if(!['functions','spark'].includes(profile))throw Error('Choose functions or spark profile');
  const root=path.resolve(__dirname,'../..'),dest=path.resolve(root,output);
  if(!dest.startsWith(path.join(root,'build')+path.sep)||fs.existsSync(dest))throw Error('Choose a new directory under build.');
  const metadata=JSON.parse(fs.readFileSync(path.join(baseline,'metadata.json'),'utf8'));
  if(metadata.project!=='healthmate-app-20261013')throw Error('Unexpected Firebase project');
  const original=fs.readFileSync(path.join(baseline,'firestore.rules'),'utf8');
  const hash=text=>crypto.createHash('sha256').update(text.replace(/\r\n/g,'\n').trim()).digest('hex');
  if(hash(original)!==metadata.deployedSha256)throw Error('Baseline Rules do not match the read-only backup');
  const rules=fs.readFileSync(path.join(root,'firestore.rules'),'utf8');
  for(const scope of ['account_deletions','support_usage','support_tickets','ai_gateway_usage','ai_gateway_reservations','admin_statistics','user_sync']) {
    if(!rules.includes(`match /${scope}/`))throw Error(`Canonical Rules missing required client path: ${scope}`);
  }
  if(!rules.includes('function ownsWrite(')||!rules.includes('function cleanup('))throw Error('Canonical account lifecycle guards are missing');
  const configSource=fs.readFileSync(publicConfig,'utf8');
  const match=/^window\.HEALTHMATE_ADMIN_CONFIG\s*=\s*([\s\S]*);\s*$/.exec(configSource.trim());
  if(!match)throw Error('Public web config must be a JSON assignment');
  const config=JSON.parse(match[1]);
  if(config.firebase?.projectId!==metadata.project||config.emulators||!config.appCheckSiteKey)throw Error('Expected existing public production config');
  fs.mkdirSync(dest,{recursive:true});fs.cpSync(path.join(root,'admin-web/dist'),path.join(dest,'site'),{recursive:true});
  config.statisticsMode=profile==='spark'?'firestore':'server';
  fs.writeFileSync(path.join(dest,'site/config.js'),'window.HEALTHMATE_ADMIN_CONFIG = '+JSON.stringify(config,null,2)+';\n');fs.writeFileSync(path.join(dest,'firestore.rules'),rules);
  if(profile==='functions')for(const name of ['src','tool','package.json','package-lock.json'])fs.cpSync(path.join(root,'firebase-functions',name),path.join(dest,'functions',name),{recursive:true});
  const csp="default-src 'self'; script-src 'self' https://www.gstatic.com https://www.google.com https://www.recaptcha.net https://apis.google.com; style-src 'self'; font-src 'self'; img-src 'self' data:; connect-src 'self' https://*.googleapis.com https://*.firebaseio.com https://*.firebaseapp.com https://www.gstatic.com https://www.google.com; frame-src https://*.firebaseapp.com https://www.google.com https://www.recaptcha.net; object-src 'none'; base-uri 'self'; frame-ancestors 'none'";
  const deployment={functions:[{source:'functions',codebase:'healthmate-realtime',runtime:'nodejs22',ignore:['node_modules','tool','test']}],firestore:{rules:'firestore.rules'},hosting:{site:'healthmate-admin-vn',public:'site',ignore:['**/.*','**/node_modules/**'],headers:[{source:'**',headers:[{key:'Content-Security-Policy',value:csp},{key:'Cache-Control',value:'no-store'},{key:'X-Content-Type-Options',value:'nosniff'},{key:'Referrer-Policy',value:'no-referrer'},{key:'Permissions-Policy',value:'camera=(), microphone=(), geolocation=()'}]}]}};
  if(profile==='spark')delete deployment.functions;
  fs.writeFileSync(path.join(dest,'firebase.review.json'),JSON.stringify(deployment,null,2));
  const manifest={project:metadata.project,profile,preparedAt:new Date().toISOString(),deployed:false,baselineRuleset:metadata.rulesetName,baselineHash:metadata.deployedSha256,rulesHash:hash(rules),rulesSource:'firestore.rules',changes:['Canonical Rules matching current Flutter and admin clients','Resumable account deletion with cross-device write freeze','Atomic support creation and per-user quota','Admin-only aggregates and private server revisions',...(profile==='spark'?['Bounded direct Firestore operational counters; Auth total remains a labeled snapshot']:[])],blockers:profile==='spark'?['Test this exact Rules file with current clients and confirm live baseline before publishing','Install updated Android app']:['Enable Blaze','Recheck live Rules baseline before publishing','Deploy functions, bootstrap counters, then publish web and install updated app']};
  fs.writeFileSync(path.join(dest,'manifest.json'),JSON.stringify(manifest,null,2));return manifest;
}
if(require.main===module){try{console.log(JSON.stringify(prepare(...process.argv.slice(2))));}catch(error){console.error(error.message);process.exit(1);}}
module.exports={prepare};
