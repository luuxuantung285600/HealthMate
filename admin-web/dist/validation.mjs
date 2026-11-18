import {photoPayload,needsPhotoBeforeActivation} from './food-photos.mjs';
import {catalogExtras,extraNutrientFields} from './nutrition-values.mjs';
export function text(value, label, max, optional = false) {
  const result = String(value ?? '').trim();
  if ((!optional && !result) || result.length > max) throw Error(`${label}: nhập ${optional ? 'tối đa' : 'từ 1 đến'} ${max} ký tự.`);
  return result;
}
export function number(value, label, max, { optional = false, positive = false } = {}) {
  if (String(value ?? '').trim() === '' && optional) return null;
  if (String(value ?? '').trim() === '') throw Error(`${label}: cần nhập số.`);
  const result = Number(String(value).replace(',', '.'));
  if (!Number.isFinite(result) || result < 0 || (positive && result === 0) || result > max) throw Error(`${label}: nhập ${positive ? 'trên' : 'từ'} 0 đến ${max}.`);
  return result;
}
export function foodPayload(fields, existing = {}) {
  const alternateNames = String(fields.alternateNames ?? '').split('\n').map(s => s.trim()).filter(Boolean);
  if (alternateNames.length > 8 || alternateNames.some(s => s.length > 100)) throw Error('Tên tương đương: tối đa 8 dòng, mỗi dòng 100 ký tự.');
  const sourceUrl = text(fields.sourceUrl, 'URL nguồn', 500);
  const url = new URL(sourceUrl);
  if (url.protocol !== 'https:' || url.username || url.password) throw Error('Nguồn cần URL HTTPS hợp lệ.');
  const data = {
    name: text(fields.name, 'Tên món', 100), alternateNames,
    photo: photoPayload(fields, existing.photo),
    category: text(fields.category, 'Nhóm món', 100), servingBasis: 'per_100g', unit: 'g',
    kcalPer100g: number(fields.kcalPer100g, 'kcal/100 g', 1000),
    proteinGPer100g: number(fields.proteinGPer100g, 'Đạm', 100),
    carbsGPer100g: number(fields.carbsGPer100g, 'Carbohydrate', 100),
    fatGPer100g: number(fields.fatGPer100g, 'Chất béo', 100),
    fiberGPer100g: number(fields.fiberGPer100g, 'Chất xơ', 100, { optional: true }),
    sourceLabel: text(fields.sourceLabel, 'Tên nguồn', 160), sourceUrl,
    isEstimated: fields.isEstimated === true, isActive: fields.isActive === true,
    servingLabel: text(fields.servingLabel, 'Tên khẩu phần', 60, true) || null,
    servingGrams: number(fields.servingGrams, 'Gram/khẩu phần', 2000, { optional: true, positive: true })
  };
  const extras=catalogExtras(existing);
  for(const [field,key,max,label] of [['sugarGPer100g','sugar',100,'Đường tổng'],['sodiumMgPer100g','sodium',100000,'Natri']]) {
    if(Object.hasOwn(fields,field)) {
      const value=number(fields[field],label,max,{optional:true});
      if(value===null)delete extras[key];else extras[key]=value;
    }
  }
  const limits=[2000,2000,100000,100000,100000,10000,100000,100000];
  for(const [i,key] of extraNutrientFields.entries())if(extras[key]!=null)number(extras[key],key,limits[i]);
  data.extraNutrientsPer100g=extras;
  if (data.proteinGPer100g + data.carbsGPer100g + data.fatGPer100g > 101) throw Error('Tổng đạm, carb và chất béo vượt khối lượng 100 g.');
  if ((data.servingLabel === null) !== (data.servingGrams === null)) throw Error('Tên khẩu phần và gram phải được nhập cùng nhau.');
  if(data.isActive && needsPhotoBeforeActivation({...existing,...data,id:fields.id??existing.id})) throw Error('Món này cần ảnh hợp lệ trước khi hiển thị. Hãy thêm đường dẫn ảnh HTTPS công khai.');
  return data;
}
export function configPayload(fields) {
  const message = text(fields.maintenanceMessage, 'Thông báo bảo trì', 300, !fields.maintenanceMode);
  return { chatbotEnabled: fields.chatbotEnabled === true, foodScannerEnabled: fields.foodScannerEnabled === true, maintenanceMode: fields.maintenanceMode === true, maintenanceMessage: message };
}
export function validFoodId(value) {
  if (!/^[a-z0-9-]{1,100}$/.test(value)) throw Error('Mã món chỉ gồm chữ thường, số và dấu gạch ngang, tối đa 100 ký tự.');
  return value;
}
function sameFieldValue(a, b) {
  if (a === b) return true;
  if (Array.isArray(a) || Array.isArray(b)) {
    return Array.isArray(a) && Array.isArray(b) && a.length === b.length
      && a.every((value, index) => sameFieldValue(value, b[index]));
  }
  const isMap = value => value !== null && typeof value === 'object'
    && [Object.prototype, null].includes(Object.getPrototypeOf(value));
  if (isMap(a) && isMap(b)) {
    const keys = Object.keys(a);
    return keys.length === Object.keys(b).length
      && keys.every(key => Object.hasOwn(b, key) && sameFieldValue(a[key], b[key]));
  }
  // Preserve SDK value / timestamp serialization behavior; only maps need
  // unordered keys to match Firestore's affectedKeys() comparison.
  return JSON.stringify(a) === JSON.stringify(b);
}
export function changedFields(before, after, kind) {
  if (!before || kind !== 'food_catalog') return Object.keys(after);
  return Object.keys(after).filter(key => !sameFieldValue(before[key], after[key]));
}
export function entityVersion(data) {
  if (!data) return null;
  const stamp = data.updatedAt;
  return typeof stamp?.seconds === 'number' && typeof stamp?.nanoseconds === 'number'
    ? `${stamp.seconds}:${stamp.nanoseconds}` : 'legacy';
}
