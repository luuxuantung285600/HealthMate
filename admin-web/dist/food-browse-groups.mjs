// Port of FoodBrowseGroup classification. Changes must retain Flutter parity.
import {foodBrowseGroups, browseSets, foodBrowseIndex} from './food-browse-metadata.mjs';
export {foodBrowseGroups};
const sets = Object.fromEntries(Object.entries(browseSets).map(([key, values]) => [key, new Set(values)]));
const ids = new Set(foodBrowseGroups.map(group => group.id));
const norm = value => String(value ?? '').toLowerCase().trim().normalize('NFD')
  .replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/\s+/g, ' ');
const headOf = row => norm((row.originalName ?? row.name ?? '').split(',')[0]);
const plantMilk = /^(sua (?:dau nanh|hanh nhan|yen mach|gao|dua|hat)(?: |$)|(?:soy|almond|oat|rice|coconut|cashew|hemp|pea) (?:milk|beverage)(?: |$)|soymilk(?: |$))/;
const eggName = /^(trung(?: |$)|eggs?(?: |$))/;
const dairyName = /^(sua (?:chua|tuoi|dac|bot)(?: |$)|pho mai(?: |$))/;
function isDrink(row, category, head) {
  if (category === 'do uong') return true;
  if (sets.drinkHeads.has(head) || /\b(juice|nectar|smoothie)\b/.test(head)) return true;
  if (head === 'milk') return !/\b(dry|powder|condensed|evaporated)\b/.test(norm(row.originalName ?? row.name));
  return /^(nuoc ep |nuoc dua(?: |$)|nuoc khoang(?: |$)|nuoc loc(?: |$)|nuoc cam(?: |$)|nuoc quyt(?: |$)|sua dau nanh(?: |$)|sua tuoi(?: |$)|sinh to |ca phe(?: |$)|tra xanh(?: |$)|tra den(?: |$))/.test(norm(row.name));
}
export function classifyFoodBrowseGroups(row) {
  const category = norm(row.category), head = headOf(row);
  const reviewed = Object.hasOwn(foodBrowseIndex, row.id) ? foodBrowseIndex[row.id] : null;
  const drink = reviewed ? reviewed.group === 'drinks' : isDrink(row, category, head);
  const fruit = reviewed ? reviewed.group === 'fruits' : !drink && (category === 'trai cay' || sets.fruitHeads.has(head));
  const generic = ['mon quoc te', 'usda', 'thuc pham', ''].includes(category);
  const plant = plantMilk.test(head) || plantMilk.test(norm(row.name)) ||
    (head === 'milk' && /\b(imitation|non-dairy|nondairy)\b/.test(norm(row.originalName ?? row.name)));
  const eggDairy = !plant && (sets.dairyCategories.has(category) ||
    (category === 'thit va trung' && eggName.test(head)) ||
    ((generic || ['do uong','san pham dong goi','do dong goi'].includes(category)) && (sets.eggDairyHeads.has(head) || dairyName.test(head))));
  return [
    ...(['mon an viet', 'mon nha'].includes(category) ? ['vietnameseDishes'] : []),
    ...(fruit ? ['fruits'] : []),
    ...(!drink && (sets.vegetableCategories.has(category) || (generic && sets.vegetableHeads.has(head))) ? ['vegetables'] : []),
    ...(!drink && (sets.meatCategories.has(category) || (category === 'thit va trung' && !eggDairy) || (generic && sets.meatHeads.has(head))) ? ['meat'] : []),
    ...(!drink && (category === 'hai san' || (generic && sets.seafoodHeads.has(head))) ? ['seafood'] : []),
    ...(eggDairy ? ['eggsDairy'] : []),
    ...(!drink && (sets.grainCategories.has(category) || ((generic || category === 'banh') && sets.grainHeads.has(head))) ? ['grainsLegumesNuts'] : []),
    ...(drink ? ['drinks'] : []),
    ...(['san pham dong goi', 'do dong goi'].includes(category) || String(row.brand ?? '').trim() || String(row.packageLabel ?? '').trim() ? ['packaged'] : []),
  ];
}
export function allowsFoodBrowseGroup(row, group = 'all') {
  if (!group || group === 'all') return true;
  if (!ids.has(group)) throw Error('Nhóm món không được hỗ trợ.');
  return classifyFoodBrowseGroups(row).includes(group);
}
