import 'food_catalog_search.dart';
import 'food_browse_index.dart';
import 'nutrition_models.dart';

/// Discovery filters only. They never change a saved meal or its nutrients.
enum FoodBrowseGroup {
  all('Tất cả'),
  vietnameseDishes('Món ăn Việt'),
  fruits('Trái cây'),
  vegetables('Rau củ'),
  meat('Thịt'),
  seafood('Cá & hải sản'),
  eggsDairy('Trứng & sữa'),
  grainsLegumesNuts('Ngũ cốc, đậu & hạt'),
  drinks('Đồ uống'),
  packaged('Đồ đóng gói');

  const FoodBrowseGroup(this.label);
  final String label;

  bool allows(FoodCatalogItem food) {
    if (this == all) return true;
    return (_browseGroups[food] ??= _classify(food)).contains(this);
  }

  int compare(FoodCatalogItem a, FoodCatalogItem b) {
    if (this == all) return compareCatalogFoods(a, b);
    int order(FoodCatalogItem food) {
      final entry = foodBrowseIndex[food.id];
      return entry?.group == name ? entry!.order : 100;
    }

    final result = order(a).compareTo(order(b));
    return result == 0 ? compareCatalogFoods(a, b) : result;
  }

  String get guidance => switch (this) {
    all => 'Ưu tiên món Việt · Chọn khẩu phần trước khi lưu',
    vietnameseDishes =>
      'Món Việt và món nhà · Dinh dưỡng tùy công thức, khẩu phần',
    fruits => 'Nhập phần ăn được, bỏ vỏ/hạt · Phân biệt quả tươi và quả khô',
    vegetables => 'Rau, củ và nấm · Chọn đúng trạng thái sống hoặc đã nấu',
    meat => 'Thịt gia súc, gia cầm và sản phẩm thịt · Không gồm cá, hải sản',
    seafood => 'Cá nước ngọt, cá biển và hải sản · Nhập phần ăn được',
    eggsDairy =>
      'Trứng, sữa động vật và chế phẩm · Sữa thực vật ở nhóm Đồ uống',
    grainsLegumesNuts =>
      'Gạo, mì, bánh mì, ngũ cốc, đậu và hạt · Chú ý khô/chín',
    drinks =>
      'Đồ uống được tính vào dinh dưỡng. Nước uống hằng ngày ghi ở mục Nước.',
    packaged =>
      'Sản phẩm đóng gói · Đối chiếu đúng nhãn, hương vị và khối lượng',
  };
}

// Catalog items are immutable. Release cached classifications when a realtime
// snapshot replaces them instead of retaining every historical catalog.
final _browseGroups = Expando<Set<FoodBrowseGroup>>();

Set<FoodBrowseGroup> _classify(FoodCatalogItem food) {
  final category = normalizeFoodSearch(food.category);
  final head = _head(food);
  final reviewed = foodBrowseIndex[food.id];
  final drink = reviewed != null ? reviewed.group == 'drinks' : _isDrink(food);
  final fruit = reviewed != null
      ? reviewed.group == 'fruits'
      : !drink && (category == 'trai cay' || _fruitHeads.contains(head));
  final vietnamese = category == 'mon an viet' || category == 'mon nha';
  // Most records have a source-derived category. Only fall back to an exact
  // identity for uncategorized references, never arbitrary ingredient matches
  // (e.g. pho bo, fish sandwich and fish sauce are not plain meat/fish).
  final generic = {'mon quoc te', 'usda', 'thuc pham', ''}.contains(category);
  final plantMilk =
      _plantMilk.hasMatch(head) ||
      _plantMilk.hasMatch(normalizeFoodSearch(food.name)) ||
      (head == 'milk' &&
          RegExp(
            r'\b(imitation|non-dairy|nondairy)\b',
          ).hasMatch(normalizeFoodSearch(food.originalName ?? food.name)));
  final eggDairy =
      !plantMilk &&
      (_dairyCategories.contains(category) ||
          (category == 'thit va trung' && _eggName.hasMatch(head)) ||
          ((generic ||
                  category == 'do uong' ||
                  category == 'san pham dong goi' ||
                  category == 'do dong goi') &&
              (_eggDairyHeads.contains(head) || _dairyName.hasMatch(head))));
  return {
    if (vietnamese) FoodBrowseGroup.vietnameseDishes,
    if (fruit) FoodBrowseGroup.fruits,
    if (!drink &&
        (_vegetableCategories.contains(category) ||
            (generic && _vegetableHeads.contains(head))))
      FoodBrowseGroup.vegetables,
    if (!drink &&
        (_meatCategories.contains(category) ||
            (category == 'thit va trung' && !eggDairy) ||
            (generic && _meatHeads.contains(head))))
      FoodBrowseGroup.meat,
    if (!drink &&
        (category == 'hai san' || (generic && _seafoodHeads.contains(head))))
      FoodBrowseGroup.seafood,
    if (eggDairy) FoodBrowseGroup.eggsDairy,
    if (!drink &&
        (_grainCategories.contains(category) ||
            ((generic || category == 'banh') && _grainHeads.contains(head))))
      FoodBrowseGroup.grainsLegumesNuts,
    if (drink) FoodBrowseGroup.drinks,
    if (category == 'san pham dong goi' ||
        category == 'do dong goi' ||
        (food.brand?.trim().isNotEmpty ?? false) ||
        (food.packageLabel?.trim().isNotEmpty ?? false))
      FoodBrowseGroup.packaged,
  };
}

final _eggName = RegExp(r'^(trung(?: |$)|eggs?(?: |$))');
final _dairyName = RegExp(
  r'^(sua (?:chua|tuoi|dac|bot)(?: |$)|pho mai(?: |$))',
);
final _plantMilk = RegExp(
  r'^(sua (?:dau nanh|hanh nhan|yen mach|gao|dua|hat)(?: |$)|'
  r'(?:soy|almond|oat|rice|coconut|cashew|hemp|pea) (?:milk|beverage)(?: |$)|'
  r'soymilk(?: |$))',
);
const _dairyCategories = {'trung', 'sua', 'sua va trung', 'sua va che pham'};
const _vegetableCategories = {'rau cu', 'cu qua'};
const _meatCategories = {
  'gia cam',
  'thit heo',
  'thit bo',
  'thit khac',
  'thit che bien',
  'thit',
};
const _grainCategories = {'ngu coc', 'ngu coc an sang', 'hat va dau'};
const _eggDairyHeads = {
  'egg',
  'eggs',
  'egg white',
  'egg yolk',
  'egg omelet or scrambled egg',
  'milk',
  'chocolate milk',
  'buttermilk',
  'cheese',
  'yogurt',
  'yoghurt',
  'cream',
  'sour cream',
  'butter',
  'ice cream',
  'kefir',
};
const _meatHeads = {
  'beef',
  'veal',
  'pork',
  'lamb',
  'mutton',
  'goat',
  'rabbit',
  'venison',
  'chicken',
  'chicken or turkey',
  'turkey',
  'duck',
  'goose',
  'quail',
  'chicken breast',
  'chicken thigh',
  'chicken drumstick',
  'chicken leg',
  'chicken wing',
  'turkey breast',
  'ham',
  'bacon',
  'sausage',
  'sausages',
  'frankfurter',
  'frankfurters',
  'salami',
  'bologna',
};
const _seafoodHeads = {
  'fish',
  'salmon',
  'tuna',
  'cod',
  'haddock',
  'halibut',
  'mackerel',
  'sardines',
  'anchovies',
  'trout',
  'tilapia',
  'catfish',
  'carp',
  'perch',
  'herring',
  'shrimp',
  'shrimps',
  'prawn',
  'prawns',
  'crab',
  'crabs',
  'lobster',
  'crayfish',
  'clam',
  'clams',
  'mussel',
  'mussels',
  'oyster',
  'oysters',
  'scallop',
  'scallops',
  'squid',
  'octopus',
  'cuttlefish',
};
const _vegetableHeads = {
  'potato',
  'potatoes',
  'sweet potato',
  'sweet potatoes',
  'taro',
  'cassava',
  'yam',
  'yams',
  'carrot',
  'carrots',
  'green beans',
  'green peas',
  'peas',
  'spinach',
  'broccoli',
  'asparagus',
  'cabbage',
  'cauliflower',
  'lettuce',
  'kale',
  'celery',
  'cucumber',
  'cucumbers',
  'tomato',
  'tomatoes',
  'eggplant',
  'mushrooms',
  'onion',
  'onions',
  'okra',
  'beets',
  'radishes',
  'turnip',
  'turnips',
  'zucchini',
  'squash',
  'pumpkin',
  'bean sprouts',
};
const _grainHeads = {
  'rice',
  'brown rice',
  'wild rice',
  'bread',
  'breads',
  'roll',
  'rolls',
  'bagel',
  'bagels',
  'pasta',
  'noodles',
  'spaghetti',
  'macaroni',
  'cereal',
  'oatmeal',
  'oats',
  'wheat',
  'barley',
  'millet',
  'quinoa',
  'corn',
  'cornmeal',
  'flour',
  'beans',
  'black beans',
  'kidney beans',
  'pinto beans',
  'chickpeas',
  'lentils',
  'soybeans',
  'tofu',
  'tempeh',
  'peanuts',
  'almonds',
  'cashews',
  'walnuts',
  'pecans',
  'pistachio nuts',
  'seeds',
};

String _head(FoodCatalogItem food) =>
    normalizeFoodSearch((food.originalName ?? food.name).split(',').first);

bool _isDrink(FoodCatalogItem food) {
  if (normalizeFoodSearch(food.category) == 'do uong') return true;
  final original = normalizeFoodSearch(food.originalName ?? food.name);
  final head = _head(food);
  // Only the food identity before the first comma: "peaches, canned in juice"
  // and "pork, cooked in ... juice" remain foods, not drinks.
  if (_drinkHeads.contains(head) ||
      RegExp(r'\b(juice|nectar|smoothie)\b').hasMatch(head)) {
    return true;
  }
  if (head == 'milk') {
    return !RegExp(r'\b(dry|powder|condensed|evaporated)\b').hasMatch(original);
  }
  // Vietnamese names are identity prefixes, never a bare "nước" substring
  // which would also match fish sauce, broth and cooked dishes.
  return RegExp(
    r'^(nuoc ep |nuoc dua(?: |$)|nuoc khoang(?: |$)|nuoc loc(?: |$)|'
    r'nuoc cam(?: |$)|nuoc quyt(?: |$)|sua dau nanh(?: |$)|'
    r'sua tuoi(?: |$)|sinh to |ca phe(?: |$)|tra xanh(?: |$)|tra den(?: |$))',
  ).hasMatch(normalizeFoodSearch(food.name));
}

const _drinkHeads = {
  'beverages',
  'beverage',
  'water',
  'coffee',
  'tea',
  'soft drink',
  'carbonated beverage',
  'lemonade',
  'limeade',
  'coconut water',
  'soy milk',
  'soymilk',
  'soy beverage',
  'almond milk',
  'oat milk',
  'rice milk',
  'milk shake',
  'milkshake',
  'milk shakes',
  'yogurt drink',
  'kefir',
  'sports drink',
  'energy drink',
  'nutrition shake',
};

const _fruitHeads = {
  'apple',
  'apples',
  'apricot',
  'apricots',
  'avocado',
  'avocados',
  'banana',
  'bananas',
  'blueberries',
  'blackberries',
  'cherries',
  'clementines',
  'dates',
  'durian',
  'figs',
  'grapefruit',
  'grapes',
  'guava',
  'guavas',
  'jackfruit',
  'jujube',
  'kiwifruit',
  'kiwifruit (kiwi)',
  'lemon',
  'lemons',
  'limes',
  'litchis',
  'longans',
  'mango',
  'mangos',
  'mangosteen',
  'melons',
  'mulberries',
  'nectarines',
  'orange',
  'oranges',
  'papaya',
  'papayas',
  'passion-fruit',
  'peach',
  'peaches',
  'pear',
  'pears',
  'persimmons',
  'pineapple',
  'plum',
  'plums',
  'pomegranates',
  'pummelo',
  'rambutan',
  'raspberries',
  'rose-apples',
  'sapodilla',
  'soursop',
  'strawberries',
  'sugar-apples',
  'tangerines',
  'watermelon',
  'carambola',
};
