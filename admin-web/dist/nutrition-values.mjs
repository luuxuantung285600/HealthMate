export const extraNutrientFields = ['sugar','saturatedFat','sodium','potassium','calcium','iron','vitaminC','cholesterol'];
export function catalogExtras(row) {
  let raw=row.extraNutrientsPer100g;
  if(typeof raw==='string') {
    try {const values=JSON.parse(raw);raw=Array.isArray(values)&&values.length===8?Object.fromEntries(extraNutrientFields.map((key,i)=>[key,values[i]])):{};}catch{raw={};}
  }
  return Object.fromEntries(extraNutrientFields.filter(key=>typeof raw?.[key]==='number'&&Number.isFinite(raw[key])&&raw[key]>=0).map(key=>[key,raw[key]]));
}
export const saltFromSodium = sodium => sodium == null ? null : sodium * 2.5 / 1000;
