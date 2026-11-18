'use strict';
// Isolated browser QA: real UI modules, empty local adapter, no Firebase SDK.
// Never uses a personal Chrome profile, production credentials or production data.
const fs=require('node:fs'),path=require('node:path'),http=require('node:http'),{spawn}=require('node:child_process');
const root=path.resolve(__dirname,'../..'),dist=path.resolve(root,process.env.HEALTHMATE_UI_QA_DIST||'admin-web/dist');
if(!dist.startsWith(root+path.sep))throw Error('QA source must stay below the workspace');
const output=path.resolve(root,process.env.HEALTHMATE_UI_QA_OUTPUT||'build/admin-identity-20261110');
if(!output.startsWith(path.join(root,'build')+path.sep))throw Error('QA output must stay below build');
fs.mkdirSync(output,{recursive:true});
const fixture=`const qaFoods=Array.from({length:65},(_,i)=>({
  id:i===0?'vn-pho-bo':'qa-food-'+String(i).padStart(3,'0'),
  name:i===0?'Phở bò':i===64?'Cá mục cuối trang ba':i<31?'Thịt bò QA '+i:'Cá QA '+i,
  category:i===0?'Món ăn Việt':i<31?'Thịt bò':'Hải sản',
  isActive:i!==64,kcalPer100g:120,proteinGPer100g:15,carbsGPer100g:5,fatGPer100g:4,
  sourceLabel:'Fixture local QA',isEstimated:true,servingBasis:'per_100g',unit:'g',schemaVersion:1,
}));
export async function connect(){let auth;return {
  emulator:true,freeExerciseMediaEnabled:new URL(location.href).searchParams.has('exercise-media'),projectId:'demo-healthmate-ui',
  authChanges(callback){auth=callback;callback({uid:'local-renderer-qa',displayName:'Kiểm thử giao diện local',emailVerified:true});},
  role(_uid,callback){callback(true);return()=>{};},async logout(){auth(null);},
  async counts(){return[0,0,0,0];},async registeredAccounts(){return null;},
  async config(){return{chatbotEnabled:true,foodScannerEnabled:true,maintenanceMode:false};},
  async listPage(){return{rows:[],cursor:null,hasMore:false};},async exportRange(){return[];},
  watchFoodCatalog(_range,next){const timer=setTimeout(()=>next(qaFoods),0);return()=>clearTimeout(timer);},
  watchExerciseLibrary(next){const timer=setTimeout(()=>next([]),0);return()=>clearTimeout(timer);},
  async save(){throw Error('Không cho ghi dữ liệu trong QA giao diện.');}
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
  await cdp('Emulation.setEmulatedMedia',{features:[{name:'prefers-color-scheme',value:'dark'}]});
  await load();
  if(await evaluate("document.documentElement.dataset.theme!=='dark'||document.querySelector('[data-admin-theme]').value!=='system'"))throw Error('device default');
  await cdp('Emulation.setEmulatedMedia',{features:[{name:'prefers-color-scheme',value:'light'}]});
  await until("document.documentElement.dataset.theme==='light'");
  await cdp('Emulation.setEmulatedMedia',{features:[{name:'prefers-color-scheme',value:'dark'}]});
  await until("document.documentElement.dataset.theme==='dark'");
  await choose('light');await choose('dark');
  await load(true);
  if(await evaluate("document.documentElement.dataset.theme!=='dark'||document.querySelector('[data-admin-theme]').value!=='dark'"))throw Error('preference reload');
  const results=[];
  for(const mode of ['light','dark'])for(const width of process.env.HEALTHMATE_UI_QA_GIFS_ONLY==='1'?[]:[1440,1024,390,320]){
    await cdp('Emulation.setDeviceMetricsOverride',{width,height:1000,deviceScaleFactor:1,mobile:width<760});
    await load();await choose(mode);
    await evaluate(`Promise.all([400,500,600,700].map(weight=>document.fonts.load(weight+' 16px "Public Sans"')))`);
    for(const page of ['overview','revenue','user_directory','food_catalog','workouts','chatbot','support','admin_audit','app_config']){
      await navigate(page);
      const state=await evaluate(`(()=>{const surface=getComputedStyle(document.querySelector('.panel,.stat')??document.body);return {
        overflow:document.documentElement.scrollWidth>innerWidth,canvas:getComputedStyle(document.body).backgroundColor,
        font:getComputedStyle(document.body).fontFamily,fontLoaded:[400,500,600,700].every(weight=>document.fonts.check(weight+' 16px "Public Sans"')),surface:surface.backgroundColor,
        badText:[...document.querySelectorAll('.panel,.stat,.field,.search,td,th')].filter(n=>{const s=getComputedStyle(n);return s.color===s.backgroundColor;}).length,
        icons:[...document.querySelectorAll('.nav-icon svg')].length,
        actionSize:[...document.querySelectorAll('.header-icon')].map(n=>{const r=n.getBoundingClientRect();return[r.width,r.height];})};})()`);
      if(state.overflow||state.badText||state.icons!==9||(!state.font.includes('Public Sans')||!state.fontLoaded)||state.canvas!==(mode==='dark'?'rgb(0, 0, 0)':'rgb(255, 255, 255)')||state.actionSize.some(r=>r.some(n=>n<44)))throw Error(JSON.stringify({mode,width,page,...state}));
      if(page==='workouts'){
        if(!await evaluate("document.querySelectorAll('.exercise-table tbody tr').length===50&&!document.querySelector('.nav-soon')&&!document.querySelector('.exercise-media')"))throw Error('workout library or production GIF gate');
        const neutral=await evaluate("getComputedStyle(document.documentElement).getPropertyValue('--accent').trim()");
        if(neutral!==(mode==='dark'?'#f1f1f1':'#202020'))throw Error('primary is not neutral');
      }
      if((width===1440||width===390)&&['overview','food_catalog','chatbot','workouts'].includes(page))await capture(`${page}-${mode}-${width}`);
    }
    if(width<900){
      await evaluate("document.querySelector('#sidebar-toggle').click()");await until("document.activeElement?.dataset.page==='overview'");
      await until("Math.abs(document.querySelector('.sidebar').getBoundingClientRect().left)<1");
      await press('Tab','Tab',9,8);
      if(!await evaluate("document.activeElement?.classList.contains('sidebar-logout')"))throw Error('drawer reverse loop');
      await press('Tab','Tab',9);
      if(!await evaluate("document.activeElement?.dataset.page==='overview'"))throw Error('drawer forward loop');
      if(width===390)await capture(`sidebar-${mode}-${width}`);
      await press('Escape','Escape',27);
      if(!await evaluate("!document.querySelector('.sidebar-open')&&document.activeElement?.id==='sidebar-toggle'"))throw Error('drawer escape');
    }else{
      await evaluate("document.querySelector('#sidebar-toggle').click()");
      if(!await evaluate("document.querySelector('.layout').classList.contains('sidebar-collapsed')&&document.querySelector('.sidebar').getBoundingClientRect().width===80&&[...document.querySelectorAll('nav button')].every(n=>n.getAttribute('aria-label'))"))throw Error('collapsed navigation');
      await evaluate("document.querySelector('#sidebar-toggle').click()");
    }
    await navigate('food_catalog');
    await until("document.querySelectorAll('#rows-host tbody tr').length===25||document.querySelectorAll('tbody tr').length===25");
    const setFoodFilter=async(id,value)=>evaluate(`(()=>{const n=document.querySelector(${JSON.stringify('#'+id)});n.value=${JSON.stringify(value)};n.dispatchEvent(new Event('${id==='list-search'?'input':'change'}',{bubbles:true}));})()`);
    const foodState=()=>evaluate("({names:[...document.querySelectorAll('tbody tr')].map(n=>n.textContent),page:document.querySelector('.table-foot')?.textContent})");
    const groupOptions=await evaluate("[...document.querySelector('#browse-group-filter').options].map(n=>[n.value,n.textContent])");
    const expectedGroups=[['all','Tất cả'],['vietnameseDishes','Món ăn Việt'],['fruits','Trái cây'],['vegetables','Rau củ'],['meat','Thịt'],['seafood','Cá & hải sản'],['eggsDairy','Trứng & sữa'],['grainsLegumesNuts','Ngũ cốc, đậu & hạt'],['drinks','Đồ uống'],['packaged','Đồ đóng gói']];
    if(JSON.stringify(groupOptions)!==JSON.stringify(expectedGroups))throw Error('food group labels: '+JSON.stringify(groupOptions));
    for(const [group] of expectedGroups){await setFoodFilter('browse-group-filter',group);if(await evaluate("document.querySelector('#browse-group-filter').value")!==group)throw Error('unreachable food group '+group);}
    await setFoodFilter('browse-group-filter','all');
    await evaluate("[...document.querySelectorAll('.pagination button')].find(n=>n.textContent==='Sau').click()");
    if(!(await foodState()).page.includes('Trang 2/3'))throw Error('food second page');
    await setFoodFilter('browse-group-filter','meat');
    let foodCheck=await foodState();
    if(!foodCheck.page.includes('Trang 1/2')||foodCheck.names.length!==25||foodCheck.names.some(n=>!n.includes('Thịt bò QA')))throw Error('meat filter/page reset '+JSON.stringify(foodCheck));
    await setFoodFilter('browse-group-filter','seafood');
    foodCheck=await foodState();
    if(!foodCheck.page.includes('Trang 1/2')||foodCheck.names.some(n=>n.includes('Thịt bò QA')||!n.includes('Cá QA')))throw Error('seafood separation '+JSON.stringify(foodCheck));
    await setFoodFilter('status-filter','archived');
    await setFoodFilter('list-search','cuoi trang ba');
    foodCheck=await foodState();
    if(foodCheck.names.length!==1||!foodCheck.names[0].includes('Cá mục cuối trang ba')||!foodCheck.page.includes('Trang 1/1'))throw Error('global page-three combined filter '+JSON.stringify(foodCheck));
    if(width===1440||width===390)await capture(`food-filter-global-${mode}-${width}`);
    await setFoodFilter('status-filter','active');
    if((await foodState()).names.length!==0)throw Error('combined active status must exclude archived food');
    await setFoodFilter('list-search','');await setFoodFilter('status-filter','');await setFoodFilter('browse-group-filter','all');
    await evaluate("[...document.querySelectorAll('tbody tr')][0].querySelectorAll('button').forEach(n=>{if(n.textContent==='Sửa ảnh')n.click();})");
    await until("Boolean(document.querySelector('#editor[open]'))");
    if(!await evaluate("document.querySelector('#editor-title').textContent==='Chỉnh sửa ảnh món ăn'&&document.querySelector('#editor-fields h3').textContent==='Phở bò'&&!document.querySelector('#editor-fields [name=id]')&&Boolean(document.querySelector('[name=photoMode]'))"))throw Error('direct photo-only editor opens the selected food');
    await until("document.querySelector('[data-photo-preview] img')?.naturalWidth===512");
    if(width===1440||width===390)await capture(`food-direct-photo-editor-${mode}-${width}`);
    await evaluate("document.querySelector('#cancel-editor').click()");
    await evaluate("[...document.querySelectorAll('button')].find(n=>n.textContent==='Thêm món ăn').click()");await until("Boolean(document.querySelector('#editor[open]'))");
    const dialog=await evaluate("(()=>{const n=document.querySelector('#editor'),r=n.getBoundingClientRect();return{left:r.left,right:r.right,overflow:n.scrollWidth>n.clientWidth,bg:getComputedStyle(n).backgroundColor};})()");
    if(dialog.left<0||dialog.right>width||dialog.overflow||dialog.bg!==(mode==='dark'?'rgb(18, 18, 18)':'rgb(246, 246, 246)'))throw Error('dialog: '+JSON.stringify({mode,width,...dialog}));
    await evaluate(`(()=>{
      document.querySelector('[name=id]').value='vn-pho-bo';document.querySelector('[name=name]').value='Phở bò';
      [...document.querySelectorAll('button')].find(n=>n.textContent==='Xem trước ảnh').click();
    })()`);
    await until("document.querySelector('[data-photo-preview] img')?.naturalWidth===512");
    if(width===1440||width===390)await capture(`food-photo-editor-${mode}-${width}`);
    await evaluate(`(()=>{const n=document.querySelector('[name=photoMode]');n.value='hidden';n.dispatchEvent(new Event('change'));})()`);
    if(!await evaluate("!document.querySelector('[data-photo-preview] img')&&document.querySelector('[data-photo-preview]').textContent.includes('Đã gỡ ảnh')"))throw Error('remove photo preview');
    await evaluate(`(()=>{const n=document.querySelector('[name=photoMode]');n.value='custom';n.dispatchEvent(new Event('change'));
      document.querySelector('[name="photo-url"]').value='javascript:alert(1)';
      [...document.querySelectorAll('button')].find(n=>n.textContent==='Xem trước ảnh').click();
    })()`);
    if(!await evaluate("!document.querySelector('[data-photo-preview] img')&&document.querySelector('.food-photo-editor .error').textContent.includes('HTTPS')"))throw Error('unsafe image URL');
    if(await evaluate("document.querySelector('#editor').scrollWidth>document.querySelector('#editor').clientWidth"))throw Error('custom photo inputs overflow');
    await evaluate(`(()=>{const n=document.querySelector('[name=photoMode]');n.value='default';n.dispatchEvent(new Event('change'));document.querySelector('[name=id]').value='';document.querySelector('[name=name]').value='';})()`);
    await evaluate("document.querySelector('#cancel-editor').click();document.querySelector('.sidebar-logout').click()");await until("Boolean(document.querySelector('#login-email'))");
    if(await evaluate("document.documentElement.scrollWidth>innerWidth||document.querySelector('[data-admin-theme]').value!==window.HealthMateAppearance.getPreference()"))throw Error('login theme/layout');
    if(width===1440)await capture('login-'+mode);
    results.push({mode,width,pages:9,overflow:false,dialog:true,login:true,drawer:width<900?'passed':'desktop',foodGroupOptions:10,foodRows:65,globalFoodSearch:true,combinedFoodFilters:true,directPhotoEditor:true,productionWrites:0});
    await load();
  }
  if(errors.length)throw Error('browser exceptions: '+JSON.stringify(errors));
  fs.writeFileSync(path.join(output,'browser-results.json'),JSON.stringify(results,null,2));
  if(process.env.HEALTHMATE_QA_REAL_GIFS==='1'){
    await cdp('Emulation.setDeviceMetricsOverride',{width:1440,height:1000,deviceScaleFactor:1,mobile:false});
    await load(false,url+'?exercise-media=1');await choose('dark');await navigate('workouts');
    if(await evaluate("document.querySelectorAll('.exercise-media').length")!==50)throw Error('Missing inline GIF previews');
    try{
      await until("[...document.querySelectorAll('.exercise-media img')].some(n=>n.naturalWidth>0)",400);
      await until("[...document.querySelectorAll('.exercise-media')].some(n=>n.querySelector('img')?.complete&&n.querySelector('button').textContent==='Dừng GIF')",400);
    }catch(error){
      const mediaState=await evaluate("[...document.querySelectorAll('.exercise-media')].slice(0,6).map(n=>({status:n.querySelector('.exercise-media-status').textContent,control:n.querySelector('button').textContent,img:n.querySelector('img')?.src}))");
      fs.writeFileSync(path.join(output,'real-gif-failure.json'),JSON.stringify({error:error.message,mediaState},null,2));
      await capture('workouts-real-gifs-failure');throw error;
    }
    const gifState=await evaluate("({loaded:[...document.querySelectorAll('.exercise-media img')].filter(n=>n.naturalWidth>0).map(n=>({alt:n.alt,width:n.naturalWidth,height:n.naturalHeight,source:n.src})),images:document.querySelectorAll('.exercise-media img').length,overflow:document.documentElement.scrollWidth>innerWidth})");
    if(gifState.images>=10||gifState.overflow)throw Error('Inline media is not lazy: '+JSON.stringify(gifState));
    await capture('workouts-real-gifs-dark-1440');
    await evaluate("document.querySelector('.exercise-media img').closest('.exercise-media').querySelector('button').click()");
    await navigate('overview');
    if(await evaluate("document.querySelector('.exercise-media img')!==null"))throw Error('Media leaked after navigation');
    fs.writeFileSync(path.join(output,'real-gif-results.json'),JSON.stringify({...gifState,productionReads:0,productionWrites:0,fixtureAdapter:true},null,2));
  }
  console.log(JSON.stringify({cases:results.length,pages:results.length*9,preferenceReload:true,errors:0,productionWrites:0,results},null,2));
})().catch(error=>{console.error(error);process.exitCode=1;}).finally(()=>{socket?.close();chrome?.kill();server.close();});
