'use strict';
// Isolated browser QA: real UI modules, empty local adapter, no Firebase SDK.
// Never uses a personal Chrome profile, production credentials or production data.
const fs=require('node:fs'),path=require('node:path'),http=require('node:http'),{spawn}=require('node:child_process');
const root=path.resolve(__dirname,'../..'),dist=path.resolve(root,process.env.HEALTHMATE_UI_QA_DIST||'admin-web/dist');
if(!dist.startsWith(root+path.sep))throw Error('QA source must stay below the workspace');
const output=path.resolve(root,process.env.HEALTHMATE_UI_QA_OUTPUT||'build/exercisedb-browser-20261119');
if(!output.startsWith(path.join(root,'build')+path.sep))throw Error('QA output must stay below build');
fs.mkdirSync(output,{recursive:true});
const fixture=`const qaFoods=Array.from({length:65},(_,i)=>({
  id:i===0?'vn-pho-bo':'qa-food-'+String(i).padStart(3,'0'),
  name:i===0?'Phở bò':i===64?'Cá mục cuối trang ba':i<31?'Thịt bò QA '+i:'Cá QA '+i,
  category:i===0?'Món ăn Việt':i<31?'Thịt bò':'Hải sản',
  isActive:i!==64,kcalPer100g:120,proteinGPer100g:15,carbsGPer100g:5,fatGPer100g:4,
  sourceLabel:'Fixture local QA',isEstimated:true,servingBasis:'per_100g',unit:'g',schemaVersion:1,
}));
export async function connect(){let auth,exerciseNext;const entries=[];return {
  emulator:true,freeExerciseMediaEnabled:true,projectId:'demo-healthmate-ui',
  authChanges(callback){auth=callback;callback({uid:'local-renderer-qa',displayName:'Kiểm thử giao diện local',emailVerified:true});},
  role(_uid,callback){callback(true);return()=>{};},async logout(){auth(null);},
  async counts(){return[0,0,0,0];},async registeredAccounts(){return null;},
  async config(){return{chatbotEnabled:true,foodScannerEnabled:true,maintenanceMode:false};},
  async listPage(){return{rows:[],cursor:null,hasMore:false};},async exportRange(){return[];},
  watchFoodCatalog(_range,next){const timer=setTimeout(()=>next(qaFoods),0);return()=>clearTimeout(timer);},
  watchExerciseLibrary(next){exerciseNext=next;const timer=setTimeout(()=>next(entries),0);return()=>clearTimeout(timer);},
  async save(kind,id,payload){if(kind!=='exercise_library')throw Error('QA supports only exercises');entries.push({id,...payload});window.__exerciseQaSaved={kind,id,payload};exerciseNext?.(entries);}
};}`;
const types={'.html':'text/html','.js':'text/javascript','.mjs':'text/javascript','.css':'text/css','.woff2':'font/woff2','.txt':'text/plain','.webp':'image/webp'};
const server=http.createServer(async(req,res)=>{try{
  const name=decodeURIComponent(new URL(req.url,'http://localhost').pathname);
  const file=path.resolve(dist,'.'+(name==='/'?'/index.html':name));
  if(!file.startsWith(dist+path.sep))throw Error('path');
  const body=name==='/firebase.mjs'?fixture:await fs.promises.readFile(file);
  res.writeHead(200,{'Content-Type':types[path.extname(file)]??'application/octet-stream','Cache-Control':'no-store',
    'Content-Security-Policy':"default-src 'self'; script-src 'self'; style-src 'self'; font-src 'self'; img-src 'self' https://static.exercisedb.dev; connect-src 'self' https://oss.exercisedb.dev; object-src 'none'"});res.end(body);
}catch{res.writeHead(404).end();}});
let chrome,socket;
(async()=>{
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const url='http://127.0.0.1:'+server.address().port+'/';
  const profile=fs.mkdtempSync(path.join(output,'chrome-'));
  const executable=process.env.CHROME_PATH||'C:/Program Files/Google/Chrome/Application/chrome.exe';
  chrome=spawn(executable,['--headless=new','--disable-gpu','--no-first-run','--no-default-browser-check',
    '--disable-extensions','--remote-debugging-port=0','--user-data-dir='+profile,'about:blank'],{stdio:'ignore',windowsHide:true});
  chrome.on('error',error=>{throw error;});
  const active=path.join(profile,'DevToolsActivePort');
  for(let i=0;!fs.existsSync(active)&&i<100;i++)await new Promise(resolve=>setTimeout(resolve,100));
  const port=fs.readFileSync(active,'utf8').split('\n')[0];
  const targets=await fetch('http://127.0.0.1:'+port+'/json/list').then(response=>response.json());
  socket=new WebSocket(targets.find(target=>target.type==='page').webSocketDebuggerUrl);
  await new Promise((resolve,reject)=>{socket.onopen=resolve;socket.onerror=reject;});
  let serial=0,pageLoads=0;const pending=new Map(),errors=[];
  socket.onmessage=event=>{const msg=JSON.parse(event.data);if(msg.id){const p=pending.get(msg.id);if(!p)return;pending.delete(msg.id);msg.error?p.reject(Error(JSON.stringify(msg.error))):p.resolve(msg.result);}if(msg.method==='Runtime.exceptionThrown')errors.push(msg.params.exceptionDetails);if(msg.method==='Page.loadEventFired')pageLoads++;};
  const cdp=(method,params={})=>new Promise((resolve,reject)=>{const id=++serial;pending.set(id,{resolve,reject});socket.send(JSON.stringify({id,method,params}));});
  const evaluate=async expression=>{const result=await cdp('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(result.exceptionDetails)throw Error(JSON.stringify(result.exceptionDetails));return result.result.value;};
  const until=async(expression,attempts=100)=>{for(let i=0;i<attempts;i++){if(await evaluate(expression))return;await new Promise(resolve=>setTimeout(resolve,50));}throw Error('timeout: '+expression);};
  const load=async(reload=false,href=url)=>{
    const previous=pageLoads;
    await cdp(reload?'Page.reload':'Page.navigate',reload?{}:{url:href});
    for(let i=0;pageLoads===previous&&i<100;i++)await new Promise(resolve=>setTimeout(resolve,50));
    if(pageLoads===previous)throw Error('page load timeout');
    await until("Boolean(document.querySelector('#dashboard-revenue .stat-number')&&document.querySelector('[data-admin-theme]'))");
  };
  const press=async(key,code,keyCode,modifiers=0)=>{await cdp('Input.dispatchKeyEvent',{type:'keyDown',key,code,windowsVirtualKeyCode:keyCode,modifiers});await cdp('Input.dispatchKeyEvent',{type:'keyUp',key,code,windowsVirtualKeyCode:keyCode,modifiers});};
  const choose=async mode=>{await evaluate(`(()=>{const n=document.querySelector('[data-admin-theme]');n.value='${mode}';n.dispatchEvent(new Event('change',{bubbles:true}));})()`);await until(`document.documentElement.dataset.theme==='${mode}'`);};
  const navigate=async page=>{await evaluate(`document.querySelector('nav [data-page="${page}"]').click()`);await until(`document.querySelector('nav [aria-current="page"]')?.dataset.page==='${page}'&&!document.querySelector('#page-content .loading')`);};
  const capture=async name=>{await evaluate('document.fonts.ready');const shot=await cdp('Page.captureScreenshot',{format:'png'});fs.writeFileSync(path.join(output,name+'.png'),Buffer.from(shot.data,'base64'));};
  await cdp('Page.enable');await cdp('Runtime.enable');
  await cdp('Emulation.setDeviceMetricsOverride',{width:1440,height:1100,deviceScaleFactor:1,mobile:false});
  await load();await choose('dark');await navigate('workouts');
  await evaluate("[...document.querySelectorAll('button')].find(n=>n.textContent==='Thêm từ ExerciseDB').click()");
  await until("document.querySelectorAll('.exercise-source-row').length===25",600);
  await until("document.querySelector('[aria-label=\"Nhóm cơ ExerciseDB\"]').options.length>1",200);
  await until("document.querySelectorAll('.exercise-source-results canvas').length>=4",600);
  if(await evaluate("Boolean(document.querySelector('.exercise-source-results img'))"))throw Error('Animated image in source list');
  const thumbnails=await evaluate("(()=>{const c=document.querySelector('.exercise-source-results canvas');window.__qaThumbnail=c;return{loaded:document.querySelectorAll('.exercise-source-results canvas').length,filter:getComputedStyle(c).filter,width:c.width};})()");
  if(!thumbnails.filter.includes('healthmate-admin-exercise-background-v4'))throw Error('Missing thumbnail filter under CSP');
  const thumbnailClip=await evaluate("(()=>{const r=document.querySelector('.exercise-source-results canvas').getBoundingClientRect();return{x:r.x,y:r.y,width:r.width,height:r.height,scale:1};})()");
  const crop=async()=>{const shot=await cdp('Page.captureScreenshot',{format:'png',clip:thumbnailClip});return Buffer.from(shot.data,'base64');};
  const stillA=await crop();await new Promise(resolve=>setTimeout(resolve,900));const stillB=await crop();
  if(!stillA.equals(stillB))throw Error('Thumbnail changed without user interaction');
  fs.writeFileSync(path.join(output,'exercise-thumbnail-static.png'),stillA);
  await capture('exercise-browser-dark-1440');
  const count=await evaluate("document.querySelector('.exercise-source-browser [role=status]').textContent");
  const layouts=[];
  for(const mode of ['dark','light'])for(const width of [1440,390,320]){
    await cdp('Emulation.setDeviceMetricsOverride',{width,height:1100,deviceScaleFactor:1,mobile:width<760});
    // Theme control is outside the modal; changing the saved preference is
    // equivalent to the already tested app theme selector, without focus tricks.
    await evaluate(`document.documentElement.dataset.theme='${mode}'`);
    const layout=await evaluate("(()=>{const d=document.querySelector('#editor'),r=document.querySelector('.exercise-source-results');return{dialogOverflow:d.scrollWidth>d.clientWidth,resultsOverflow:r.scrollWidth>r.clientWidth,documentOverflow:document.documentElement.scrollWidth>innerWidth};})()");
    if(Object.values(layout).some(Boolean))throw Error('Source browser overflow '+JSON.stringify({width,mode,...layout}));
    const thumbnailBounds=await evaluate("(()=>{const r=document.querySelector('.exercise-source-results canvas').getBoundingClientRect();return{x:r.x,y:r.y,width:r.width,height:r.height};})()");
    if(thumbnailBounds.width<90)throw Error('Thumbnail too small for backdrop filter');
    layouts.push({mode,width,...layout,thumbnailBounds});await capture(`exercise-browser-${mode}-${width}`);
  }
  await cdp('Emulation.setDeviceMetricsOverride',{width:1440,height:1100,deviceScaleFactor:1,mobile:false});
  await evaluate("document.documentElement.dataset.theme='dark';document.querySelector('.exercise-source-row button').click()");
  try {await until("document.querySelector('.exercise-source-detail img')?.naturalWidth>0",400);} catch(error) {
    const state=await evaluate("({detail:document.querySelector('.exercise-source-detail')?.textContent,img:document.querySelector('.exercise-source-detail img')?.outerHTML,ready:document.visibilityState})");
    fs.writeFileSync(path.join(output,'gif-load-failure.json'),JSON.stringify(state,null,2));await capture('gif-load-failure');throw error;
  }
  await until("[...document.querySelectorAll('button')].some(n=>n.textContent==='Thêm vào HealthMate'&&!n.disabled)");
  const media=await evaluate("({width:document.querySelector('.exercise-source-detail img').naturalWidth,filter:getComputedStyle(document.querySelector('.exercise-source-detail img')).filter})");
  if(!media.filter.includes('healthmate-admin-exercise-background-v4'))throw Error('Missing GIF filter under CSP');
  const enclosedFilter=await evaluate("(()=>{const img=document.createElement('img');img.className='exercise-detail-image';img.src='https://static.exercisedb.dev/media/Nh3mvOO.gif';document.body.append(img);const value=getComputedStyle(img).filter;img.remove();return value;})()");
  if(!enclosedFilter.includes('healthmate-admin-exercise-background-v4-Nh3mvOO'))throw Error('Enclosed matte CSS blocked by CSP');
  const thumbnailProfile=await evaluate("(()=>{const canvas=document.createElement('canvas');canvas.className='exercise-source-thumb-image';canvas.dataset.sourceId='Nh3mvOO';document.body.append(canvas);const value=getComputedStyle(canvas).filter;canvas.remove();return value;})()");
  if(!thumbnailProfile.includes('healthmate-admin-exercise-background-v4-Nh3mvOO'))throw Error('Thumbnail profile CSS blocked by CSP');
  await capture('exercise-browser-detail-dark-1440');
  await evaluate("[...document.querySelectorAll('button')].find(n=>n.textContent==='Thêm vào HealthMate').click()");
  await until("document.querySelector('#editor-title').textContent==='Thêm bài tập'");
  if(!await evaluate("!window.__qaThumbnail.isConnected&&window.__qaThumbnail.width===0"))throw Error('Old thumbnail raster retained after closing picker');
  if(!await evaluate("document.querySelector('[name=sourceId]').value.length===7&&document.querySelector('[name=id]').value.startsWith('edb-')&&document.querySelector('[name=name]').value===''") )throw Error('Draft identity not filled');
  await evaluate("(()=>{const fields={name:'Bài tập kiểm thử giao diện',steps:'Giữ tư thế bắt đầu vững.\\nThực hiện chậm và có kiểm soát.',easier:'Giảm biên độ nếu khó.',reason:'Kiểm thử local trong bộ nhớ'};for(const [key,value] of Object.entries(fields))document.querySelector('[name='+key+']').value=value;document.querySelector('#editor-form').requestSubmit();})()");
  await until("Boolean(window.__exerciseQaSaved)");
  if(await evaluate("Object.hasOwn(window.__exerciseQaSaved.payload,'instructions')||Object.hasOwn(window.__exerciseQaSaved.payload,'gifUrl')"))throw Error('Source content persisted');
  await until("!document.querySelector('#editor[open]')");
  if(errors.length)throw Error('Browser exceptions '+JSON.stringify(errors));
  fs.writeFileSync(path.join(output,'browser-review.json'),JSON.stringify({realBrowser:true,liveExerciseDb:true,fixtureFirebase:true,productionWrites:0,count,layouts,media,enclosedFilter,thumbnails,thumbnailProfile,staticThumbnail:true,thumbnailCleanup:true,saved:true,errors:0},null,2));
  console.log(JSON.stringify({layouts:layouts.length,liveSource:true,liveGif:true,staticThumbnail:true,thumbnailCleanup:true,editorSave:true,productionWrites:0,errors:0}));
})().catch(error=>{console.error(error);process.exitCode=1;}).finally(()=>{socket?.close();chrome?.kill();server.close();});
