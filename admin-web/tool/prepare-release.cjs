'use strict';
// Creates a local review bundle. No network, deployment or role assignment.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '../..');
const [readinessFile, output, suppliedSiteKey] = process.argv.slice(2);
function fail(message) { console.error(message); process.exit(1); }
if (!readinessFile || !output) fail('Usage: node admin-web/tool/prepare-release.cjs <readiness.json> <new-build-directory> [public-site-key]');
const build = path.join(root, 'build') + path.sep;
const dest = path.resolve(root, output);
if (!dest.startsWith(build) || fs.existsSync(dest)) fail('Output must be a new directory below build; existing files are never overwritten.');
const report = JSON.parse(fs.readFileSync(path.resolve(root, readinessFile), 'utf8'));
const project = 'healthmate-app-20261013';
const hostingSite = 'healthmate-admin-vn';
if (report.project !== project || report.webConfigStatus !== 200 || report.webConfig?.projectId !== project ||
    !report.requestedAdmin?.emailVerified || report.requestedAdmin.disabled) fail('A successful readiness check for the verified HealthMate admin is required.');
const site = report.hostingSites?.find(s => s.name === `projects/${project}/sites/${hostingSite}`);
if (!site) fail('Expected existing Hosting site was not confirmed.');
const siteKey = suppliedSiteKey || report.appCheck?.siteKey || '';
if (siteKey && !/^[a-zA-Z0-9_-]{20,200}$/.test(siteKey)) fail('Invalid public App Check site key.');
const firebase = {};
// Explicit allowlist: never copy OAuth, account UID, response metadata or secrets.
for (const key of ['projectId','appId','apiKey','authDomain','storageBucket','messagingSenderId']) {
  if (typeof report.webConfig[key] === 'string') firebase[key] = report.webConfig[key];
}
const csp = "default-src 'self'; script-src 'self' https://www.gstatic.com https://www.google.com https://www.recaptcha.net https://apis.google.com; style-src 'self'; font-src 'self'; img-src 'self' https: data:; connect-src 'self' https://*.googleapis.com https://*.firebaseio.com https://*.firebaseapp.com https://www.gstatic.com https://www.google.com; frame-src https://*.firebaseapp.com https://www.google.com https://www.recaptcha.net; object-src 'none'; base-uri 'self'; frame-ancestors 'none'";
fs.mkdirSync(dest, {recursive:true});
fs.cpSync(path.join(root, 'admin-web/dist'), path.join(dest, 'site'), {recursive:true});
fs.writeFileSync(path.join(dest, 'site/config.js'), 'window.HEALTHMATE_ADMIN_CONFIG = ' + JSON.stringify({firebase,appCheckSiteKey:siteKey}, null, 2) + ';\n');
fs.copyFileSync(path.join(root, 'firestore.rules'), path.join(dest, 'firestore.rules'));
const config = {
  hosting: {site:hostingSite,public:'site',ignore:['**/.*','**/node_modules/**'],headers:[{source:'**',headers:[
    {key:'Content-Security-Policy',value:csp},
    {key:'Cache-Control',value:'no-store'},
    {key:'X-Content-Type-Options',value:'nosniff'},
    {key:'Referrer-Policy',value:'no-referrer'},
    {key:'Permissions-Policy',value:'camera=(), microphone=(), geolocation=()'},
  ]}]},
  firestore:{rules:'firestore.rules'},
};
// Missing-key bundles intentionally have no Firebase deployment config.
fs.writeFileSync(path.join(dest, siteKey ? 'firebase.review.json' : 'hosting.blocked.json'), JSON.stringify(config,null,2));
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(path.join(dest,file))).digest('hex');
const manifest = {
  preparedAtUtc:new Date().toISOString(),project,hostingSite,hostingUrl:site.defaultUrl,
  clientConfigured:Boolean(siteKey),deploymentApproved:false,roleGranted:false,deployed:false,
  blockers:[...(!siteKey ? ['Register the web App Check Enterprise site key and rebuild this bundle.'] : []),
    'Review use of the existing Hosting site: publishing replaces its current contents.',
    'Review and deploy admin Rules; grant the selected verified account admin_roles/{uid}.enabled through trusted project access.',
    'Perform live App Check and admin/user acceptance before enabling the mobile runtime flag.'],
  hashes:{rules:hash('firestore.rules'),config:hash('site/config.js')},
};
fs.writeFileSync(path.join(dest,'manifest.json'),JSON.stringify(manifest,null,2));
console.log(JSON.stringify({output:path.relative(root,dest),clientConfigured:manifest.clientConfigured,deployed:false,blockers:manifest.blockers}));
