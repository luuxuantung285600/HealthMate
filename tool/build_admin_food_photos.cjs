const fs=require('node:fs'),path=require('node:path'),{createHash}=require('node:crypto');
const {photos}=JSON.parse(fs.readFileSync('assets/food_photos/manifest.json','utf8'));
fs.mkdirSync('admin-web/dist/food-photos',{recursive:true});
const data={};for(const p of photos){
  if(createHash('sha256').update(fs.readFileSync(p.assetPath)).digest('hex')!==p.sha256)throw Error('Photo differs from reviewed source: '+p.foodId);
  const file=path.basename(p.assetPath);fs.copyFileSync(p.assetPath,'admin-web/dist/food-photos/'+file);const {title,author,sourceUrl,license,licenseUrl,foodName}=p;data[p.foodId]={foodName,url:'./food-photos/'+file,title,author,sourceUrl,license,licenseUrl};}
const excluded=JSON.parse(fs.readFileSync('data/food_catalog/photo-release.json','utf8')).excluded.map(row=>row.id);
fs.writeFileSync('admin-web/dist/bundled-food-photos.mjs','// Generated from reviewed assets/food_photos/manifest.json.\nexport const bundledFoodPhotos = '+JSON.stringify(data,null,2)+';\nexport const excludedFoodPhotoIds = '+JSON.stringify(excluded)+';\n');
fs.copyFileSync('assets/food_photos/ATTRIBUTION.md','admin-web/dist/food-photos/ATTRIBUTION.txt');
console.log('Copied '+photos.length+' reviewed previews with source credits.');
