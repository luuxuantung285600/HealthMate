'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const os=require('node:os');
const path=require('node:path');
const {demoIdentity,validateDefines,properties,inspectSigning,inspect}=require('./release_preflight.cjs');
const config=()=>({HEALTHMATE_ENABLE_ADMIN_CONTROLS:true,HEALTHMATE_ENABLE_PREMIUM_DEMO:false,
  HEALTHMATE_ENABLE_CHATBOT:false,HEALTHMATE_ENABLE_FOOD_SCANNER:true,HEALTHMATE_CHAT_API_URL:''});
test('release config is explicit, preserves barcode entry and closes unverified AI/demo',()=>{
  assert.deepEqual(validateDefines(config()),[]);
  assert.ok(validateDefines({...config(),HEALTHMATE_ENABLE_CHATBOT:true,HEALTHMATE_CHAT_API_URL:'https://example.com/v1/chat'}).includes('ai-infrastructure-not-verified'));
  assert.ok(validateDefines({...config(),HEALTHMATE_ENABLE_PREMIUM_DEMO:true}).includes('premium-demo-forbidden'));
  assert.ok(validateDefines({...config(),HEALTHMATE_ENABLE_PLAY_BILLING:true}).includes('play-billing-infrastructure-not-verified'));
  assert.deepEqual(validateDefines({...config(),HEALTHMATE_ENABLE_PLAY_BILLING:false}),[]);
  assert.ok(validateDefines({}).includes('explicit-feature-config-required'));
});
test('debug token, emulator config, booleans encoded as strings and credentials in URLs are rejected without values',()=>{
  for(const extra of [{HEALTHMATE_APP_CHECK_DEBUG_TOKEN:'PRIVATE-FIXTURE'},
    {HEALTHMATE_EMULATOR_TESTS:true},{HEALTHMATE_ENABLE_CHATBOT:'false'},
    {HEALTHMATE_CHAT_API_URL:'http://127.0.0.1:8080'},
    {FIREBASE_APPCHECK_DEBUG_TOKEN:'PRIVATE-FIXTURE'},
    {HEALTHMATE_CHAT_API_URL:'https://[fd00::1]/chat'},
    {HEALTHMATE_CHAT_API_URL:'https://gateway.internal/chat'},
    {HEALTHMATE_CHAT_API_URL:'https://example.com/chat'},
    {HEALTHMATE_CHAT_API_URL:'https://name:PRIVATE-FIXTURE@example.com'}]) {
    const result=validateDefines({...config(),...extra});assert.ok(result.length);assert.ok(!JSON.stringify(result).includes('PRIVATE-FIXTURE'));
  }
});
test('signing requires existing absolute private non-debug key and never returns secrets',()=>{
  const values={storeFile:path.resolve(os.tmpdir(),'private-release-key.jks'),storePassword:'PRIVATE-FIXTURE',keyAlias:'release',keyPassword:'PRIVATE-FIXTURE'};
  assert.deepEqual(inspectSigning(values,()=>true),[]);
  for(const value of [{}, {...values,storeFile:'relative.jks'}, {...values,keyAlias:'androiddebugkey'},
    {...values,keyPassword:'   '},
    {...values,storeFile:path.resolve(os.tmpdir(),'debug.keystore')}]) assert.ok(inspectSigning(value,()=>true).length);
  const result=inspectSigning(values,()=>false);assert.deepEqual(result,['keystore-not-found']);assert.ok(!JSON.stringify(result).includes('PRIVATE-FIXTURE'));
});

test('direct Gradle release path contains resolved-task signing and explicit configuration guards',()=>{
  // Source contract only: no Gradle/native build or certificate acceptance is implied.
  const source=fs.readFileSync(path.join(__dirname,'../android/app/build.gradle.kts'),'utf8');
  for(const required of ['gradle.taskGraph.whenReady','allTasks.any',
    'normalizedKey.contains("DEBUG")','normalizedKey.contains("EMULATOR")',
    'key !in allowedHealthMateDefines','"HEALTHMATE_ENABLE_CHATBOT" to "false"',
    '"HEALTHMATE_ENABLE_ADMIN_CONTROLS" to "true"',
    '"HEALTHMATE_CHAT_API_URL" to ""','requiredDefines.any',
    'signingConfigs.getByName("release") else null']) assert.ok(source.includes(required),required);
  assert.ok(!source.includes('signingConfigs.getByName("debug")'));
});
test('properties parsing supports documented Windows escaping and demo identity remains unchanged',()=>{
  const input=properties('# private fixture\r\nstoreFile=C:\\\\Keys\\\\release.jks\nkeyAlias=release\nstorePassword=PRIVATE-FIXTURE\nkeyPassword=PRIVATE-FIXTURE');
  assert.equal(input.storeFile,'C:\\Keys\\release.jks');assert.equal(input.keyAlias,'release');
  assert.deepEqual(demoIdentity,{applicationId:'com.example.healthmate',versionName:'1.0.0',versionCode:1});
});
test('preflight reports missing signing and source hashes without claiming release acceptance or logging keys',()=>{
  const fixture=fs.mkdtempSync(path.join(os.tmpdir(),'healthmate-release-'));
  try {
    fs.mkdirSync(path.join(fixture,'android/app'),{recursive:true});fs.mkdirSync(path.join(fixture,'config'));
    fs.writeFileSync(path.join(fixture,'android/app/build.gradle.kts'),'applicationId = "com.example.healthmate"');
    fs.writeFileSync(path.join(fixture,'pubspec.yaml'),'version: 1.0.0+1\n');
    fs.writeFileSync(path.join(fixture,'config/release-candidate.json'),JSON.stringify(config()));
    fs.writeFileSync(path.join(fixture,'firestore.rules'),'fixture');fs.writeFileSync(path.join(fixture,'firestore.indexes.json'),'{}');
    const report=inspect(fixture);assert.deepEqual(report.blockers,['release-signing-missing']);
    assert.equal(report.releaseAccepted,false);assert.equal(report.apkSha256,null);assert.equal(report.rulesSha256.length,64);
    fs.writeFileSync(path.join(fixture,'android/key.properties'),'storePassword=PRIVATE-FIXTURE');
    assert.ok(!JSON.stringify(inspect(fixture)).includes('PRIVATE-FIXTURE'));
  } finally {
    const expectedPrefix=path.resolve(os.tmpdir())+path.sep+'healthmate-release-';
    assert.ok(path.resolve(fixture).startsWith(expectedPrefix));
    fs.rmSync(fixture,{recursive:true,force:true});
  }
});
