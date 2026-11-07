import test from 'node:test';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
const {countRegisteredAccounts,syncStatistics,parseArgs} = createRequire(import.meta.url)('../tool/sync-account-statistics.cjs');

test('legacy manual writer cannot overwrite a live Auth counter or start an Auth scan',async()=>{
  let calls=0;
  await assert.rejects(syncStatistics({apply:true,request:async url=>{
    calls++;assert.match(url,/admin_statistics\/accounts$/);
    return {fields:{method:{stringValue:'realtime_auth_events'}}};
  }}),/không ghi đè/);
  assert.equal(calls,1);
});

test('Auth count traverses every page, requests identifiers only and does not write by default',async() => {
  const calls = [];
  const request = async(url,options) => {
    calls.push({url,options});const parsed = new URL(url);
    assert.equal(parsed.hostname,'identitytoolkit.googleapis.com');
    assert.equal(parsed.searchParams.get('fields'),'users(localId),nextPageToken');
    assert.equal(parsed.searchParams.get('maxResults'),'1000');
    assert.equal(options,undefined);
    return calls.length === 1 ? {users:Array.from({length:1000},(_,i) => ({localId:`user-${i}`})),nextPageToken:'page-2'} : {users:[{localId:'last'}]};
  };
  const result = await syncStatistics({request});
  assert.equal(result.totalRegisteredAccounts,1001);assert.equal(result.pages,2);assert.equal(result.applied,false);
  assert.equal(new URL(calls[1].url).searchParams.get('nextPageToken'),'page-2');
});

test('Auth count fails on duplicate IDs, repeated tokens, malformed pages or failed later page',async() => {
  for (const bad of [{users:'bad'},{users:[{}]},{users:[{localId:'same'},{localId:'same'}]},{nextPageToken:4},null])
    await assert.rejects(countRegisteredAccounts(async() => bad));
  await assert.rejects(countRegisteredAccounts(async() => ({nextPageToken:'repeat'})),/bị lặp/);
  let calls = 0, writes = 0;
  await assert.rejects(syncStatistics({apply:true,request:async(url,options) => {
    if (options?.body) {writes++;return {};}
    if (url.includes('firestore.googleapis.com')) return null;
    if (++calls === 1) return {users:[{localId:'first'}],nextPageToken:'second'};
    throw Error('Failed page');
  }}),/Failed page/);
  assert.equal(writes,0);
});

test('explicit apply publishes only the aggregate with server time and optimistic concurrency',async() => {
  for (const previous of [null,{updateTime:'2026-11-02T00:00:00Z'}]) {
    const mutations = [];
    const result = await syncStatistics({apply:true,request:async(url,options) => {
      if (options?.body) {mutations.push({url,...options});return {};}
      return url.includes('firestore.googleapis.com') ? previous : {users:[{localId:'private-user-identifier'}]};
    }});
    assert.equal(result.applied,true);assert.equal(result.totalRegisteredAccounts,1);assert.equal(mutations.length,1);
    const write = mutations[0].body.writes[0];
    assert.equal(write.update.name,'projects/healthmate-app-20261013/databases/(default)/documents/admin_statistics/accounts');
    assert.equal(write.update.fields.totalRegisteredAccounts.integerValue,'1');
    assert.deepEqual(write.currentDocument,previous ? {updateTime:previous.updateTime} : {exists:false});
    assert.deepEqual(write.updateTransforms,[{fieldPath:'updatedAt',setToServerValue:'REQUEST_TIME'}]);
    assert.doesNotMatch(JSON.stringify(mutations),/private-user-identifier/);
  }
});

test('a verified empty Auth list gives zero, not the directory size; unknown CLI flags are rejected',async() => {
  assert.equal((await syncStatistics({request:async() => ({})})).totalRegisteredAccounts,0);
  assert.deepEqual(parseArgs([]),{apply:false,cliRoot:null});
  assert.deepEqual(parseArgs(['--cli-root','C:/firebase-tools','--apply']),{apply:true,cliRoot:'C:/firebase-tools'});
  for (const args of [['--project','other'],['--cli-root'],['--cli-root','--apply'],['--force']]) assert.throws(() => parseArgs(args));
});
