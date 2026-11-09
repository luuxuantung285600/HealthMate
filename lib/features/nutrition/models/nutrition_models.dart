import '../../../core/utils/local_date_key.dart';
import 'extra_nutrients.dart';

class NutritionTotals {
  const NutritionTotals({
    this.kcal = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG = 0,
    this.fiberKnown = false,
    this.proteinKnown = true,
    this.carbsKnown = true,
    this.fatKnown = true,
    this.extraNutrients = const {},
  });

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final Map<String, double> extraNutrients;

  /// Known subtotal; fiberKnown=false preserves missing ingredients/sources.
  final double fiberG;
  final bool fiberKnown;
  static const zero = NutritionTotals(fiberKnown: true);
  // Numeric fields are known subtotals, never evidence that missing data is 0.
  final bool proteinKnown, carbsKnown, fatKnown;
  bool get hasCompleteMacros => proteinKnown && carbsKnown && fatKnown;

  NutritionTotals operator +(NutritionTotals other) => NutritionTotals(
    kcal: kcal + other.kcal,
    proteinG: proteinG + other.proteinG,
    carbsG: carbsG + other.carbsG,
    fatG: fatG + other.fatG,
    fiberG: fiberG + other.fiberG,
    fiberKnown: fiberKnown && other.fiberKnown,
    proteinKnown: proteinKnown && other.proteinKnown,
    carbsKnown: carbsKnown && other.carbsKnown,
    fatKnown: fatKnown && other.fatKnown,
    extraNutrients: sumExtras(extraNutrients, other.extraNutrients),
  );

  NutritionTotals scale(double factor) => NutritionTotals(
    kcal: kcal * factor,
    proteinG: proteinG * factor,
    carbsG: carbsG * factor,
    fatG: fatG * factor,
    fiberG: fiberG * factor,
    fiberKnown: fiberKnown,
    proteinKnown: proteinKnown,
    carbsKnown: carbsKnown,
    fatKnown: fatKnown,
    extraNutrients: scaleExtras(extraNutrients, factor),
  );
}

NutritionTotals sumNutritionTotals(Iterable<NutritionTotals> values) {
  final iterator = values.iterator;
  if (!iterator.moveNext()) return const NutritionTotals();
  var total = iterator.current;
  while (iterator.moveNext()) {
    total = total + iterator.current;
  }
  return total;
}

enum FoodDataSource {
  local,
  usda,
  user;

  String get wireValue => switch (this) {
    FoodDataSource.local => 'local',
    FoodDataSource.usda => 'usda',
    FoodDataSource.user => 'user',
  };
}

enum ServingBasis {
  per100g,
  explicitServing;

  String get wireValue => switch (this) {
    ServingBasis.per100g => 'per_100g',
    ServingBasis.explicitServing => 'explicit_serving',
  };
}

enum FoodDietClass { unknown, vegan, vegetarian, nonVegetarian }

class FoodCatalogItem {
  const FoodCatalogItem({
    required this.id,
    required this.name,
    this.alternateNames = const [],
    required this.category,
    required this.servingBasis,
    this.unit = 'g',
    this.per100g,
    required this.sourceLabel,
    required this.isEstimated,
    this.updatedAt,
    this.hasNutritionData = true,
    this.defaultServingGrams = 100,
    this.servingLabel,
    this.servingGrams,
    this.servingMetadataInvalid = false,
    this.brand,
    this.packageLabel,
    this.dataSource = FoodDataSource.local,
    this.fdcId,
    this.kcalPer100g,
    this.proteinGPer100g,
    this.carbsGPer100g,
    this.fatGPer100g,
    this.fiberGPer100g,
    this.extraNutrientsPer100g = const {},
    this.dietaryClass = FoodDietClass.unknown,
    this.originalName,
    this.ingredientNames = const [],
    this.ingredientsKnown = false,
  });

  final String id;
  final String name;
  final FoodDietClass dietaryClass;
  final String? originalName;
  final List<String> ingredientNames;
  final bool ingredientsKnown;
  final List<String> alternateNames;
  final String category;
  final ServingBasis servingBasis;
  final String unit;
  final NutritionTotals? per100g;
  final String sourceLabel;
  final bool isEstimated;
  final DateTime? updatedAt;
  final bool hasNutritionData;

  final double defaultServingGrams;
  final String? servingLabel;
  final double? servingGrams;
  final bool servingMetadataInvalid;
  final String? brand;
  final String? packageLabel;

  // USDA integration fields
  final FoodDataSource dataSource;
  final int? fdcId;

  // Simplified nutrition fields for USDA API compatibility
  final double? kcalPer100g;
  final double? proteinGPer100g;
  final double? carbsGPer100g;
  final double? fatGPer100g;
  final double? fiberGPer100g;
  final Map<String, double> extraNutrientsPer100g;

  // Get per100g from simplified fields if not set
  NutritionTotals get nutritionPer100g {
    if (per100g != null) return per100g!;

    return NutritionTotals(
      kcal: kcalPer100g ?? 0,
      proteinG: proteinGPer100g ?? 0,
      carbsG: carbsGPer100g ?? 0,
      fatG: fatGPer100g ?? 0,
      fiberG: fiberGPer100g ?? 0,
      fiberKnown: fiberGPer100g != null,
      proteinKnown: proteinGPer100g != null,
      carbsKnown: carbsGPer100g != null,
      fatKnown: fatGPer100g != null,
      extraNutrients: extraNutrientsPer100g,
    );
  }

  bool get hasValidServing =>
      servingBasis == ServingBasis.per100g &&
      unit == 'g' &&
      servingLabel != null &&
      servingLabel!.trim().isNotEmpty &&
      servingLabel!.length <= 60 &&
      servingGrams != null &&
      servingGrams!.isFinite &&
      servingGrams! > 0 &&
      servingGrams! <= 2000;

  NutritionTotals forGrams(double grams) {
    if (!hasNutritionData) {
      throw const FormatException('Món thiếu dữ liệu dinh dưỡng.');
    }
    return nutritionPer100g.scale(grams / 100);
  }
}

enum MealType {
  breakfast('Bữa sáng'),
  lunch('Bữa trưa'),
  dinner('Bữa tối'),
  snack('Bữa phụ');

  const MealType(this.label);
  final String label;
}

enum MealSource {
  manual('Nhập thủ công'),
  aiAssisted('Có hỗ trợ nhận diện');

  const MealSource(this.label);
  final String label;

  String get wireValue => switch (this) {
    MealSource.manual => 'manual',
    MealSource.aiAssisted => 'ai_assisted',
  };
}

class MealItemSnapshot {
  const MealItemSnapshot({
    required this.foodId,
    required this.name,
    required this.grams,
    required this.nutrition,
    required this.sourceLabel,
    required this.isEstimated,
    this.hasNutritionData = true,
    this.quantityUnit = 'g',
    this.quantityValue,
  });

  factory MealItemSnapshot.fromCatalog(FoodCatalogItem food, double grams) =>
      MealItemSnapshot(
        foodId: food.id,
        name: food.name,
        grams: grams,
        nutrition: food.forGrams(grams),
        sourceLabel: food.sourceLabel,
        isEstimated: food.isEstimated,
      );

  final String foodId;
  final String name;
  final double grams;
  final NutritionTotals nutrition;
  final String sourceLabel;
  final bool isEstimated;
  final bool hasNutritionData;

  /// For non-mass entries grams is an internal unused sentinel; it is serialized
  /// as null and never displayed as a measurement or used as a density.
  final String quantityUnit;
  final double? quantityValue;
  double get quantity =>
      quantityUnit == 'g' ? grams : quantityValue ?? double.nan;
  String get quantityUnitLabel => switch (quantityUnit) {
    'ml' => 'ml',
    'serving' => 'phần',
    'entry' => 'lần ghi',
    _ => 'g',
  };
  bool get needsExtendedSchema =>
      quantityUnit != 'g' || !nutrition.hasCompleteMacros;
  bool get hasFiberData => nutrition.fiberKnown || nutrition.fiberG > 0;

  Map<String, Object?> toData() => {
    'foodId': foodId,
    'name': name,
    'grams': quantityUnit == 'g' ? grams : null,
    if (quantityUnit != 'g') ...{
      'quantityUnit': quantityUnit,
      'quantity': quantityValue,
    },
    'kcal': nutrition.kcal,
    'proteinG': nutrition.proteinKnown ? nutrition.proteinG : null,
    'carbsG': nutrition.carbsKnown ? nutrition.carbsG : null,
    'fatG': nutrition.fatKnown ? nutrition.fatG : null,
    if (nutrition.fiberKnown) 'fiberG': nutrition.fiberG,
    if (!nutrition.fiberKnown && nutrition.fiberG > 0) ...{
      'fiberG': nutrition.fiberG,
      'fiberIncomplete': true,
    },
    'sourceLabel': sourceLabel,
    'isEstimated': isEstimated,
    if (nutrition.extraNutrients.isNotEmpty)
      'nutrientVectorV1': encodeExtraNutrients(nutrition.extraNutrients),
  };

  factory MealItemSnapshot.fromData(
    Map<String, dynamic> d, {
    bool allowPartial = false,
  }) {
    bool numeric(Object? n) => n is num && n.isFinite && n >= 0;
    bool fiberNumeric(Object? n) => numeric(n) && (n as num) <= 1000;
    double value(String k) => numeric(d[k]) ? (d[k] as num).toDouble() : 0;
    final unit = d['quantityUnit'] is String
        ? d['quantityUnit'] as String
        : 'g';
    final q = unit == 'g' ? d['grams'] : d['quantity'];
    final validQuantity =
        q is num &&
        q.isFinite &&
        q > 0 &&
        q <= 2000 &&
        ['g', 'ml', 'serving', 'entry'].contains(unit) &&
        (unit == 'g' || d['grams'] == null) &&
        (!d.containsKey('quantityUnit') ||
            (d['quantityUnit'] is String && unit != 'g'));
    final validMacros = ['proteinG', 'carbsG', 'fatG'].every(
      (k) =>
          d.containsKey(k) && (numeric(d[k]) || (allowPartial && d[k] == null)),
    );
    return MealItemSnapshot(
      foodId: d['foodId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      grams: unit == 'g' && q is num ? q.toDouble() : 0,
      quantityUnit: unit,
      quantityValue: unit != 'g' && q is num ? q.toDouble() : null,
      nutrition: NutritionTotals(
        kcal: value('kcal'),
        extraNutrients: readExtraNutrients(
          d['nutrientVectorV1'] ?? d['extraNutrients'],
        ),
        proteinG: value('proteinG'),
        carbsG: value('carbsG'),
        fatG: value('fatG'),
        fiberG: fiberNumeric(d['fiberG'])
            ? value('fiberG')
            : fiberNumeric(d['knownFiberG'])
            ? value('knownFiberG')
            : 0,
        fiberKnown: fiberNumeric(d['fiberG']) && d['fiberIncomplete'] != true,
        proteinKnown: numeric(d['proteinG']),
        carbsKnown: numeric(d['carbsG']),
        fatKnown: numeric(d['fatG']),
      ),
      sourceLabel: d['sourceLabel'] as String? ?? '',
      isEstimated: d['isEstimated'] as bool? ?? true,
      hasNutritionData: validQuantity && numeric(d['kcal']) && validMacros,
    );
  }
  Map<String, Object?> toCompactData() => {
    for (final e in toData().entries)
      if (e.key != 'grams') e.key: e.value,
    'quantity': quantity,
    'quantityUnit': quantityUnit,
    'nutrientVectorV1': encodeExtraNutrients(nutrition.extraNutrients),
  };

  factory MealItemSnapshot.fromCompactData(Map<String, dynamic> data) {
    final copy = Map<String, dynamic>.from(data);
    final unit = copy['quantityUnit'];
    copy['grams'] = unit == 'g' ? copy['quantity'] : null;
    if (unit == 'g') {
      copy.remove('quantity');
      copy.remove('quantityUnit');
    }
    for (final key in ['proteinG', 'carbsG', 'fatG']) {
      copy.putIfAbsent(key, () => null);
    }
    return MealItemSnapshot.fromData(copy, allowPartial: true);
  }

  MealItemSnapshot withGrams(double newGrams) {
    if (quantityUnit != 'g') {
      throw const FormatException(
        'Món này không dùng gram. Hãy sửa lượng theo đúng đơn vị.',
      );
    }
    return withQuantity(newGrams);
  }

  MealItemSnapshot withQuantity(double newGrams) {
    if (!['g', 'ml', 'serving', 'entry'].contains(quantityUnit)) {
      throw const FormatException('Đơn vị bản ghi không được hỗ trợ.');
    }
    final values = [
      quantity,
      newGrams,
      nutrition.kcal,
      nutrition.proteinG,
      nutrition.carbsG,
      nutrition.fatG,
      nutrition.fiberG,
    ];
    if (!hasNutritionData ||
        values.any((v) => !v.isFinite) ||
        quantity <= 0 ||
        newGrams <= 0 ||
        newGrams > 2000 ||
        values.skip(2).any((v) => v < 0)) {
      throw const FormatException(
        'Snapshot dinh dưỡng hoặc khối lượng không hợp lệ.',
      );
    }
    final scaled = nutrition.scale(newGrams / quantity);
    if (scaled.extraNutrients.entries.any(
      (e) =>
          !e.value.isFinite ||
          e.value < 0 ||
          e.value > ExtraNutrient.values.byName(e.key).maximum,
    )) {
      throw const FormatException(
        'Dưỡng chất theo khẩu phần vượt giới hạn lưu.',
      );
    }
    if ([
          scaled.kcal,
          scaled.proteinG,
          scaled.carbsG,
          scaled.fatG,
          scaled.fiberG,
        ].any((v) => !v.isFinite) ||
        scaled.fiberG > 1000) {
      throw const FormatException('Không thể tính khẩu phần từ snapshot này.');
    }
    return MealItemSnapshot(
      foodId: foodId,
      name: name,
      grams: quantityUnit == 'g' ? newGrams : 0,
      quantityUnit: quantityUnit,
      quantityValue: quantityUnit == 'g' ? null : newGrams,
      nutrition: scaled,
      sourceLabel: sourceLabel,
      isEstimated: isEstimated,
    );
  }
}

class MealDraft {
  const MealDraft({
    required this.type,
    required this.consumedAt,
    required this.items,
    required this.source,
    this.minimumSchemaVersion = 2,
    this.timezoneOffsetOverride,
  });

  final MealType type;
  final DateTime consumedAt;
  final List<MealItemSnapshot> items;
  final MealSource source;
  final int minimumSchemaVersion;
  final int? timezoneOffsetOverride;

  int get timezoneOffsetMinutes =>
      timezoneOffsetOverride ?? consumedAt.timeZoneOffset.inMinutes;
  String get dateKey =>
      dateKeyFromTimestampAndOffset(consumedAt, timezoneOffsetMinutes);

  NutritionTotals get totals =>
      sumNutritionTotals(items.map((item) => item.nutrition));
}

class MealLog {
  const MealLog({
    required this.id,
    required this.type,
    required this.consumedAt,
    required this.items,
    required this.totals,
    required this.source,
    this.dateKey,
    this.timezoneOffsetMinutes,
    this.createdAt,
    this.updatedAt,
    this.schemaVersion = 2,
  });

  final String id;
  final MealType type;
  final DateTime consumedAt;
  final List<MealItemSnapshot> items;
  final NutritionTotals totals;
  final MealSource source;
  final String? dateKey;
  final int? timezoneOffsetMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int schemaVersion;

  MealDraft toDraft() => MealDraft(
    type: type,
    consumedAt: consumedAt,
    items: items,
    source: source,
    minimumSchemaVersion: schemaVersion,
    timezoneOffsetOverride: timezoneOffsetMinutes,
  );

  MealDraft copyDraft({required DateTime day, DateTime? now}) {
    final clock = (now ?? DateTime.now()).toLocal();
    final date = localDateOnly(day);
    if (date.isAfter(localDateOnly(clock))) {
      throw const FormatException('Ngày sao chép không thể ở tương lai.');
    }
    final sourceTime = consumedAt.toLocal();
    final candidate = DateTime(
      date.year,
      date.month,
      date.day,
      sourceTime.hour,
      sourceTime.minute,
    );
    return MealDraft(
      type: type,
      consumedAt: candidate.isAfter(clock) ? clock : candidate,
      items: List.unmodifiable(items),
      source: source,
      minimumSchemaVersion: schemaVersion,
    );
  }
}

class RecentMealPage {
  const RecentMealPage({required this.meals, this.fromCache = false});
  final List<MealLog> meals;
  final bool fromCache;
}

List<MealItemSnapshot> recentMealItems(
  Iterable<MealLog> meals, {
  int limit = 8,
}) {
  final seen = <String>{};
  final result = <MealItemSnapshot>[];
  for (final meal in meals) {
    for (final item in meal.items) {
      final key = item.foodId.isNotEmpty
          ? item.foodId
          : item.name.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) continue;
      result.add(item);
      if (result.length == limit) return List.unmodifiable(result);
    }
  }
  return List.unmodifiable(result);
}

NutritionTotals totalMealNutrition(Iterable<MealLog> meals) =>
    sumNutritionTotals(meals.map((meal) => meal.totals));

/// Counts distinct appearances per meal inside the repository's bounded recent
/// window (currently 20 records), using the most recent snapshot/amount.
List<({MealItemSnapshot item, int count})> frequentMealItems(
  Iterable<MealLog> meals, {
  int limit = 8,
}) {
  final latest = <String, MealItemSnapshot>{}, counts = <String, int>{};
  for (final meal in meals) {
    final seen = <String>{};
    for (final item in meal.items) {
      final key = item.foodId.isEmpty
          ? item.name.trim().toLowerCase()
          : item.foodId;
      if (key.isEmpty || !seen.add(key)) continue;
      latest.putIfAbsent(key, () => item);
      counts.update(key, (v) => v + 1, ifAbsent: () => 1);
    }
  }
  final order = latest.keys.toList();
  final keys = [...order]
    ..sort((a, b) {
      final c = counts[b]!.compareTo(counts[a]!);
      return c != 0 ? c : order.indexOf(a).compareTo(order.indexOf(b));
    });
  return [
    for (final k in keys.take(limit)) (item: latest[k]!, count: counts[k]!),
  ];
}
