// Offline app asset only; no Firebase credentials or writes.
const fs = require('node:fs');
const {buildCatalog} = require('./import_food_catalog.cjs');
const recipes = JSON.parse(fs.readFileSync('data/food_catalog/recipes.json', 'utf8'));
const foods = buildCatalog();
for (const food of foods) {
  if (food.servingGrams) food.defaultServingGrams = food.servingGrams;
  if (food.servingGrams && food.sourceDetails.method === 'recipe_estimate') {
    food.servingLabel = /phở|bún|cháo|miến|hủ tiếu/i.test(food.name)
      ? 'tô tham khảo' : /bánh mì/i.test(food.name) ? 'ổ tham khảo' : 'phần tham khảo';
  }
  if (food.id === 'usda-white-rice-cooked' || /cơm trắng chín/i.test(food.name)) {
    food.servingLabel = 'chén tham khảo'; food.servingGrams = 150;
    food.defaultServingGrams = 150;
  }
}
fs.mkdirSync('assets/nutrition', {recursive: true});
fs.writeFileSync('assets/nutrition/vietnamese-foods.json', JSON.stringify({
  version: recipes.version,
  note: recipes.method + ' ' + recipes.limitation,
  foods,
}, null, 2));
console.log('Bundled ' + foods.length + ' sourced/estimated foods; no cloud changes.');
