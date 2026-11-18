import {bundledFoodPhotos,excludedFoodPhotoIds} from './bundled-food-photos.mjs';

export function photoUrl(value, max = 1000) {
  const raw = String(value ?? '').trim();
  let url;
  try { url = new URL(raw); } catch { throw Error('Ảnh: cần đường dẫn HTTPS hợp lệ.'); }
  if (raw.length > max || url.href.length > max || /\s/.test(raw) || url.protocol !== 'https:' ||
      url.username || url.password || !/^[a-zA-Z0-9][a-zA-Z0-9.-]*$/.test(url.hostname)) {
    throw Error('Ảnh: cần đường dẫn HTTPS công khai, không chứa thông tin đăng nhập.');
  }
  return url.href;
}
export function photoPayload(fields, existingPhoto = null) {
  const mode = fields.photoMode ?? 'default';
  if (!['default','custom','hidden'].includes(mode)) throw Error('Chế độ ảnh không hợp lệ.');
  if (mode !== 'custom') return {mode};
  const url=photoUrl(fields['photo-url']);
  const legacy=existingPhoto?.mode==='custom'&&existingPhoto.url===url
    ? Object.fromEntries(['title','author','sourceUrl','license','licenseUrl']
        .filter(key=>typeof existingPhoto[key]==='string'&&existingPhoto[key].trim())
        .map(key=>[key,existingPhoto[key]])) : {};
  return {mode,url,...legacy};
}
// Check browser image loading, without a CORS-dependent fetch, before saving.
export async function validateEditorPhoto(form,{timeoutMs=10000,ImageClass=form.ownerDocument.defaultView.Image}={}) {
  const read=()=>photoPayload(Object.fromEntries(['photoMode','photo-url'].map(name=>[name,form.querySelector(`[name="${name}"]`)?.value])));
  const photo=read();
  if(photo.mode!=='custom')return;
  const unchanged=()=>{
    if(JSON.stringify(read())!==JSON.stringify(photo))throw Error('Thông tin ảnh vừa thay đổi. Hãy kiểm tra và lưu lại.');
  };
  const ready=img=>img.complete&&img.naturalWidth>0&&img.naturalHeight>0;
  const preview=[...form.querySelectorAll('[data-photo-preview] img')].find(img=>img.src===photo.url&&ready(img));
  if(preview){unchanged();return;}
  if(typeof ImageClass!=='function')throw Error('Chưa thể kiểm tra ảnh. Hãy thử lại trong trình duyệt.');
  await new Promise((resolve,reject)=>{
    const img=new ImageClass();let settled=false;
    const finish=error=>{
      if(settled)return;settled=true;clearTimeout(timer);img.onload=null;img.onerror=null;
      if(error)reject(error);else resolve();
    };
    const timer=setTimeout(()=>finish(Error('Ảnh tải quá lâu. Kiểm tra đường dẫn rồi thử lưu lại.')),timeoutMs);
    img.referrerPolicy='no-referrer';
    img.onload=()=>finish(img.naturalWidth>0&&img.naturalHeight>0?null:Error('Ảnh không có kích thước hợp lệ. Hãy chọn ảnh khác.'));
    img.onerror=()=>finish(Error('Không tải được ảnh. Kiểm tra liên kết ảnh trực tiếp trước khi lưu.'));
    img.src=photo.url;
    if(ready(img))finish();
  });
  unchanged();
}
export function resolvePhoto(row) {
  if (row.photo?.mode === 'hidden') return null;
  if (row.photo != null && row.photo.mode !== 'default') {
    if (row.photo.mode !== 'custom') return null;
    try {
      const fields={photoMode:'custom',...Object.fromEntries(Object.entries(row.photo).map(([k,v])=>['photo-'+k,v]))};
      const legacy=Object.fromEntries(['title','author','sourceUrl','license','licenseUrl']
        .filter(key=>typeof row.photo[key]==='string'&&row.photo[key].trim())
        .map(key=>[key,row.photo[key]]));
      return {...legacy,...photoPayload(fields),foodName:row.name};
    } catch { return null; }
  }
  const photo=bundledFoodPhotos[row.id];
  const normalize=value=>String(value??'').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'').replace(/đ/g,'d').replace(/\s+/g,' ').trim();
  return photo && normalize(photo.foodName)===normalize(row.name) ? photo : null;
}
export function foodPhotoPreview(h,row,{compact=false}={}) {
  const photo=resolvePhoto(row);
  const host=h('div',{class:compact?'food-photo-preview compact':'food-photo-preview'});
  if (!photo) { host.append(h('small',{},row.photo?.mode==='hidden'?'Đã gỡ ảnh':'Chưa có ảnh')); return host; }
  const status=h('small',{role:'status'},'Đang tải ảnh…');
  const img=h('img',{src:photo.url,alt:`Ảnh minh họa ${row.name}`,referrerPolicy:'no-referrer',loading:'lazy',
    onLoad:()=>{const credits=[photo.title,photo.author,photo.license].filter(Boolean);status.textContent=compact?'':credits.length?`Ảnh: ${credits.join(' · ')}`:'Ảnh minh họa';},
    onError:()=>{img.hidden=true;status.textContent='Chưa tải được ảnh. Kiểm tra đường dẫn hoặc thử lại.';}});
  host.append(img,status);
  return host;
}
export function foodPhotoEditor(h,field,row) {
  const current=row.photo??{mode:'default'};
  const mode=h('select',{name:'photoMode',id:'field-photoMode'},
    ...[['default','Dùng ảnh có sẵn trong app'],['custom','Thay bằng ảnh từ đường dẫn HTTPS'],['hidden','Gỡ ảnh (chỉ hiện chữ)']].map(([value,label])=>h('option',{value,selected:current.mode===value},label)));
  const inputHost=h('div',{class:'photo-inputs'},
    field('photo-url','Đường dẫn tệp ảnh (HTTPS)',current.url,{max:1000,hint:'Dán liên kết trực tiếp đến ảnh công khai, không phải trang web chứa ảnh.'}));
  const preview=h('div',{'data-photo-preview':''});
  const error=h('p',{class:'error',role:'status'});
  const show=()=>{
    error.textContent='';
    try {
      const values=Object.fromEntries([...inputHost.querySelectorAll('input')].map(n=>[n.name,n.value]));
      const photo=photoPayload({photoMode:mode.value,...values});
      const form=mode.closest('form');
      const name=form?.querySelector('[name=name]')?.value||row.name;
      const id=form?.querySelector('[name=id]')?.value||row.id;
      preview.replaceChildren(foodPhotoPreview(h,{...row,id,name,photo}));
    } catch(e) { error.textContent=e.message; preview.replaceChildren(); }
  };
  const update=()=>{
    const custom=mode.value==='custom';inputHost.hidden=!custom;
    for(const input of inputHost.querySelectorAll('input')){input.disabled=!custom;input.required=custom;}
    show();
  };
  const refresh=h('button',{type:'button',class:'button secondary',onClick:show},'Xem trước ảnh');
  mode.addEventListener('change',update);
  const host=h('section',{class:'food-photo-editor'},h('h3',{},'Ảnh món ăn'),
    h('label',{class:'field'},'Cách hiển thị ảnh',mode),inputHost,refresh,error,preview,
    h('p',{class:'muted'},'Chỉ dùng ảnh đúng món, rõ nét, không có người hoặc món khác gây nhiễu. Bạn cần có quyền sử dụng ảnh. Ảnh minh họa không dùng để tính dinh dưỡng. Thay đổi chỉ áp dụng sau khi lưu.'));
  update();return host;
}

const excludedPhotoIds=new Set(excludedFoodPhotoIds);
export function needsPhotoBeforeActivation(row) {
  return excludedPhotoIds.has(row.id) && resolvePhoto(row)===null;
}
export function showRestorePhotoGuard(row,{openEditor,h,button,editFood}) {
  if(row.isActive!==false || !needsPhotoBeforeActivation(row))return false;
  openEditor('Thêm ảnh trước khi khôi phục',[
    h('h3',{},row.name),
    h('p',{class:'notice'},'Món này đã được ẩn vì chưa có ảnh phù hợp. Hãy dán đường dẫn ảnh HTTPS công khai; sau đó bật “Hiển thị trong danh mục app” để khôi phục.'),
    button('Thêm ảnh cho món',()=>editFood(row))
  ],null,{reason:false});
  return true;
}
