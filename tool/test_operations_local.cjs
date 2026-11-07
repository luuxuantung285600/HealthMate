'use strict';
// Exercises the exact release contract using fixed local demo emulators only.
const fs=require('node:fs'),path=require('node:path');
const {spawnSync}=require('node:child_process');
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8080'||process.env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9099')throw Error('Expected local Auth/Firestore demo emulators');
const root=path.resolve(__dirname,'..');
const release=process.env.HEALTHMATE_OPERATIONS_RELEASE;
const normalized=value=>value.replace(/\r\n/g,'\n').trim();
if(!release||!path.resolve(release).startsWith(path.join(root,'build')+path.sep))throw Error('Select a reviewed release under build');
if(normalized(fs.readFileSync(path.join(release,'firestore.rules'),'utf8'))!==normalized(fs.readFileSync(path.join(root,'firestore.rules'),'utf8')))throw Error('Release Rules differ from the source tested by repositories');
function run(command,args,options={}) {
  const result=spawnSync(command,args,{stdio:'inherit',cwd:root,...options});
  if(result.error||result.status!==0)process.exit(result.status||1);
}
const rules=fs.readdirSync(path.join(root,'rules-tests')).filter(name=>name.endsWith('.rules.test.cjs'));
run(process.execPath,['--test',...rules],{cwd:path.join(root,'rules-tests'),env:{...process.env,HEALTHMATE_RULES_FILE:path.resolve(release,'firestore.rules')}});
run(process.env.ComSpec||'cmd.exe',['/d','/s','/c','D:\\Flutter\\flutter\\bin\\flutter.bat test --no-pub --concurrency=1 --platform chrome --dart-define=HEALTHMATE_EMULATOR_TESTS=true test/support_repository_integration.dart test/account_deletion_repository_integration.dart']);
