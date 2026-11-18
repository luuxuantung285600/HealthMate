const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const {createHash} = require('node:crypto');
const {photos} = JSON.parse(fs.readFileSync('assets/food_photos/manifest.json','utf8'));
const foods = JSON.parse(fs.readFileSync('data/food_catalog/photo-coverage-500.json','utf8')).foods;
const selection = JSON.parse(fs.readFileSync('data/food_catalog/full-photo-selection.json','utf8'));
const packages = JSON.parse(fs.readFileSync('data/food_catalog/packaged.json','utf8')).foods;
const release = JSON.parse(fs.readFileSync('data/food_catalog/photo-release.json','utf8'));
const {validateRelease} = require('./publish_photo_visibility.cjs');

test('every retained food has a reviewed image with matching identity, hash and source rights', () => {
  assert.equal(validateRelease(release,foods,photos),true);
  assert.equal(photos.length, release.visibleIds.length);
  assert.equal(new Set(photos.map(p => p.foodId)).size, photos.length);
  assert.deepEqual(photos.map(p=>p.foodId).sort(),[...release.visibleIds].sort());
  const byHash = new Map();
  for (const photo of photos) {
    const group=byHash.get(photo.sha256) || [];
    group.push(photo); byHash.set(photo.sha256,group);
    if (photo.sourcePhotoKey) {
      assert.equal(selection.assignments[photo.foodId]?.source,photo.sourcePhotoKey);
      assert.equal(selection.assignments[photo.foodId]?.reviewNote,photo.visualReview);
      assert.ok(photo.visualReview.length>=12);
    }
  }
  for (const group of byHash.values()) {
    if (group.length<2) continue;
    const original=group.find(p=>!p.sourcePhotoKey);
    if(original) {
      assert.equal(group.filter(p=>!p.sourcePhotoKey).length,1);
      for(const p of group.filter(p=>p!==original)) {
        assert.equal(p.sourcePhotoKey,'bundled:'+original.foodId,'Sharing requires the exact reviewed bundled source');
      }
    } else assert.equal(new Set(group.map(p=>p.sourcePhotoKey)).size,1,'Duplicates require an explicitly shared reviewed source');
  }
  assert.deepEqual(fs.readdirSync('assets/food_photos').filter(f => f.endsWith('.webp')).sort(),
    photos.map(p => p.foodId + '.webp').sort());
  for (const photo of photos) {
    assert.equal(photo.assetPath, `assets/food_photos/${photo.foodId}.webp`);
    assert.equal(foods.find(f => f.id === photo.foodId)?.name, photo.foodName);
    assert.equal(photo.width, 512); assert.equal(photo.height, 512);
    if (photo.renderScale != null) {
      assert.ok(photo.renderScale > 0 && photo.renderScale <= 1, 'Never enlarge source pixels');
      assert.ok(Math.max(...photo.sourceCropPixels) * photo.renderScale <= 492.01);
      assert.ok(Math.min(...photo.sourceCropPixels) >= (photo.barcode ? 300 : 200));
      assert.ok(Math.max(...photo.sourceCropPixels) >= (photo.barcode ? 400 : photo.sourcePhotoKey ? 480 : 512));
    } else assert.ok(photo.sourceCropPixels.every(n => n >= 512), 'Original reviewed photos retain their resolution');
    assert.ok(photo.cropNormalized.every(n => n >= 0 && n <= 1));
    if (photo.barcode) {
      assert.equal(photo.foodId, 'hao-hao-tom-chua-cay-75g');
      assert.equal(photo.barcode, '8934563138165');
      assert.equal(photo.sourceUrl, 'https://world.openfoodfacts.org/product/' + photo.barcode);
      assert.match(photo.originalUrl, /^https:\/\/images\.openfoodfacts\.org\//);
      assert.equal(photo.license, 'CC BY-SA 3.0');
    } else if (photo.sourceKind==='pexels') {
      assert.match(photo.sourceUrl,/^https:\/\/www\.pexels\.com\/photo\//);
      assert.match(photo.originalUrl,/^https:\/\/images\.pexels\.com\/photos\//);
      assert.equal(photo.license,'Pexels License');
      assert.equal(photo.licenseUrl,'https://www.pexels.com/license/');
    } else if (photo.sourceKind==='flickr') {
      assert.match(photo.sourceUrl,/^https:\/\/www\.flickr\.com\/photos\/[^/]+\/\d+\/$/);
      assert.match(photo.originalUrl,/^https:\/\/live\.staticflickr\.com\/\d+\/\d+_[a-z0-9_]+\.jpg$/);
      const allowed=new Map([
        ['CC BY 2.0','https://creativecommons.org/licenses/by/2.0/'],
        ['CC BY-SA 2.0','https://creativecommons.org/licenses/by-sa/2.0/'],
        ['CC BY 4.0','https://creativecommons.org/licenses/by/4.0/'],
        ['CC BY-SA 4.0','https://creativecommons.org/licenses/by-sa/4.0/'],
        ['CC0','https://creativecommons.org/publicdomain/zero/1.0/'],
        ['Public domain','https://creativecommons.org/publicdomain/mark/1.0/'],
      ]);
      assert.equal(photo.licenseUrl,allowed.get(photo.license),'Only explicitly reviewed reusable Flickr licenses');
    } else if (photo.sourceKind==='manufacturer') {
      const food=packages.find(f=>f.id===photo.foodId);
      assert.ok(food && food.brand==='Acecook');
      assert.equal(photo.originalUrl,food.sourceDetails.packageImageUrl);
      assert.equal(photo.sourcePhotoKey,'manufacturer:'+food.id,'A brand photo cannot cross flavors or pack sizes');
      assert.match(photo.sourceUrl,/^https:\/\/acecookvietnam\.vn\/product\//);
      assert.equal(photo.license,'Bản quyền nhà sản xuất');
      assert.equal(photo.licenseUrl,photo.sourceUrl,'Never invent a CC grant for manufacturer artwork');
    } else {
      assert.match(photo.sourceUrl, /^https:\/\/commons\.wikimedia\.org\/wiki\/File:/);
      assert.match(photo.originalUrl, /^https:\/\/upload\.wikimedia\.org\//);
      assert.ok(['CC0','Public domain'].includes(photo.license) || /^CC BY(?:-SA)? [1-4]\.\d(?: [a-z]{2})?$/.test(photo.license), 'No NC/ND or unknown Commons restrictions');
    }
    if(photo.author === 'Unknown') {
      assert.equal(photo.license,'CC0','An unspecified author is only accepted with the source CC0 waiver');
    } else assert.ok(photo.author.trim());
    assert.equal(createHash('sha256').update(fs.readFileSync(photo.assetPath)).digest('hex'), photo.sha256);
  }
});

test('the rejected chicken pho photo and crowded low-resolution pancake are replaced', () => {
  assert.equal(photos.find(p => p.foodId === 'vn-pho-ga').title, 'Homemade \"Phở gà\" by A.jpeg');
  assert.notEqual(photos.find(p => p.foodId === 'vn-banh-xeo').title, 'Banh Xeo with fish sauce and vegetables.jpg');
});
