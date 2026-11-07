'use strict';
// Explicit mutation command. Emulator is fixed to an isolated demo project;
// production uses Application Default Credentials, never a repository key.
const {initializeApp,applicationDefault}=require('firebase-admin/app');
const {getFirestore}=require('firebase-admin/firestore');
const {getAuth}=require('firebase-admin/auth');
const {bootstrap}=require('../src/sync.cjs');
const args=process.argv.slice(2),emulator=args.includes('--emulator'),cliAuth=args.includes('--cli-auth');
if(!args.includes('--apply'))throw Error('Review first; pass --apply to initialize/reconcile server aggregates.');
if(args.some(arg=>!['--apply','--emulator','--cli-auth'].includes(arg))||(emulator&&cliAuth))throw Error('Unsupported option');
if(emulator){process.env.FIRESTORE_EMULATOR_HOST='127.0.0.1:8092';process.env.FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9098';}
else if(process.env.FIRESTORE_EMULATOR_HOST||process.env.FIREBASE_AUTH_EMULATOR_HOST)throw Error('Use --emulator for local data');
let credential;
if(!emulator){
  credential=cliAuth?{async getAccessToken(){
    try{
      const path=require('node:path');const cli=require(path.join(process.env.APPDATA,'npm/node_modules/firebase-tools/lib/auth.js'));
      const account=cli.getGlobalDefaultAccount();if(!account)throw Error();
      const token=await cli.getAccessToken(account.tokens.refresh_token,['https://www.googleapis.com/auth/cloud-platform']);
      return {access_token:token.access_token,expires_in:3600};
    }catch{throw Error('Firebase CLI authentication unavailable. Run firebase login with the project owner.');}
  }}:applicationDefault();
}
initializeApp({projectId:emulator?'demo-healthmate-admin':'healthmate-app-20261013',...(!emulator?{credential}:{})});
bootstrap(getFirestore(),getAuth()).then(result=>{console.log(JSON.stringify({project:emulator?'demo-healthmate-admin':'healthmate-app-20261013',...result}));process.exit(0);}).catch(error=>{console.error(error.message);process.exit(1);});
