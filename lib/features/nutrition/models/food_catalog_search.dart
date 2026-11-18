import 'nutrition_models.dart';

// A discovery order, not a nutrition recommendation or popularity statistic.
const _vietnameseDishOrder = [
  'vn-pho-bo',
  'vn-com-tam-suon',
  'vn-bun-bo-hue',
  'vn-bun-thit-nuong',
  'vn-bun-cha',
  'vn-pho-ga',
  'vn-banh-mi-thit',
  'vn-goi-cuon',
  'vn-banh-cuon',
  'vn-banh-xeo',
  'vn-bun-rieu',
  'vn-mi-quang',
  'vn-cha-gio',
  'vn-thit-kho-trung',
];

/// Vietnamese prepared dishes come before ingredients and overseas references.
/// Search relevance still takes precedence over this discovery order.
int _compareDiscoveryPriority(FoodCatalogItem a, FoodCatalogItem b) {
  int group(FoodCatalogItem food) {
    final id = food.id;
    if (id.startsWith('usda-foundation-')) return 3;
    if (id.startsWith('usda-fndds-')) return 4;
    if (id.startsWith('usda-sr-')) return 5;
    if (food.dataSource == FoodDataSource.usda) return 6;
    if (food.category == 'Món ăn Việt' || food.category == 'Món nhà') return 0;
    if (id.startsWith('vn-') || id.startsWith('vn2007-')) return 1;
    return 2;
  }

  final priority = group(a).compareTo(group(b));
  if (priority != 0) return priority;
  if (group(a) == 0) {
    int order(String id) {
      final index = _vietnameseDishOrder.indexOf(id);
      return index < 0 ? _vietnameseDishOrder.length : index;
    }

    final dish = order(a.id).compareTo(order(b.id));
    if (dish != 0) return dish;
  }
  return 0;
}

int compareCatalogFoods(FoodCatalogItem a, FoodCatalogItem b) {
  final priority = _compareDiscoveryPriority(a, b);
  if (priority != 0) return priority;
  final name = a.name.compareTo(b.name);
  return name != 0 ? name : a.id.compareTo(b.id);
}

// Catalog objects are immutable for the lifetime of a snapshot. A weak index
// avoids normalizing thousands of names again on each keystroke and releases
// old entries when a Firestore snapshot is replaced.
final _foodSearchIndex = Expando<List<(String, Set<String>)>>();

List<(String, Set<String>)> _searchTerms(FoodCatalogItem food) =>
    _foodSearchIndex[food] ??= [
      for (final raw in [food.name, ?food.originalName, ...food.alternateNames])
        _normalizedTerm(raw),
    ];

(String, Set<String>) _normalizedTerm(String raw) {
  final text = normalizeFoodSearch(raw);
  return (text, text.split(' ').toSet());
}

/// Search Vietnamese names with or without tone marks, including keyboard NFD.
String normalizeFoodSearch(String text) {
  var value = text.toLowerCase().trim();
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  for (final entry in groups.entries) {
    value = value.replaceAll(RegExp('[${entry.value}]'), entry.key);
  }
  return value
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}

List<FoodCatalogItem> searchFoodCatalog(
  List<FoodCatalogItem> catalog,
  String query,
) {
  final normalized = normalizeFoodSearch(query);
  if (normalized.isEmpty) return catalog;
  final words = normalized.split(' ');
  int score(FoodCatalogItem food) {
    var best = 99;
    for (final (name, tokens) in _searchTerms(food)) {
      final rank = name == normalized
          ? 0
          : name.startsWith('$normalized ')
          ? 1
          : words.every(tokens.contains)
          ? 2
          : name.contains(normalized)
          ? 3
          : 99;
      if (rank < best) best = rank;
    }
    return best;
  }

  final ranked =
      [for (final pair in catalog.indexed) (pair.$1, pair.$2, score(pair.$2))]
        ..removeWhere((r) => r.$3 == 99)
        ..sort((a, b) {
          final rank = a.$3.compareTo(b.$3);
          if (rank != 0) return rank;
          final discovery = _compareDiscoveryPriority(a.$2, b.$2);
          // Keep the upstream relevance order within the same discovery group.
          return discovery != 0 ? discovery : a.$1.compareTo(b.$1);
        });
  return [for (final result in ranked) result.$2];
}
