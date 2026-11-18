'use strict';
// Fixture reset only. No credentials, configurable destination or cloud fallback.
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8080'||
  process.env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9099')throw Error('Expected fixed local demo emulators.');
(async()=>{
  const response=await fetch('http://127.0.0.1:8080/emulator/v1/projects/demo-healthmate-rules/databases/(default)/documents',
    {method:'DELETE',signal:AbortSignal.timeout(20000)});
  if(!response.ok)throw Error('Demo fixture reset failed: HTTP '+response.status);
  console.log('Reset only demo-healthmate-rules documents on localhost:8080.');
})().catch(error=>{console.error(error.message);process.exitCode=1;});
