'use strict';
const {spawnSync}=require('node:child_process');
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8092'||process.env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9098')throw Error('Expected fixed local demo emulators');
function run(command,args) {
  const result=spawnSync(command,args,{stdio:'inherit'});
  if(result.error||result.status!==0)process.exit(result.status||1);
}
run(process.execPath,['admin-web/seed-emulators.mjs','--extended']);
if(!process.argv.includes('--flutter-only')) {
  run(process.execPath,['--test','admin-web/test/sdk.integration.mjs']);
  run(process.execPath,['--test','admin-web/test/realtime-sdk.integration.mjs']);
}
if(process.argv.includes('--node-only'))process.exit(0);
run(process.env.ComSpec||'cmd.exe',['/d','/s','/c','D:\\Flutter\\flutter\\bin\\flutter.bat test --no-pub --platform chrome --dart-define=HEALTHMATE_EMULATOR_TESTS=true test/realtime_spark_integration.dart']);
