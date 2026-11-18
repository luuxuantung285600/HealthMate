import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/models/extra_nutrients.dart';

enum FoodSourceKind { catalog, custom, recipe }

class FoodLibraryFailure implements Exception {
  const FoodLibraryFailure([
    this.message =
        'Chưa thể tải hoặc lưu thư viện món. Kiểm tra kết nối/quyền truy cập và thử lại.',
  ]);
  final String message;
}

abstract class LibraryEntry {
  String get id;
  String get name;
  FoodSourceKind get kind;
  void validate();
  Map<String, Object?> toData();
  FoodCatalogItem asFood();
}

abstract final class LibraryValidation {
  static const maxIngredients = 6;
  static void text(String value, int max, {int min = 1}) {
    if (value.trim().length < min || value.length > max) {
      throw const FormatException('Thông tin chữ chưa hợp lệ.');
    }
  }

  static void id(String value) {
    text(value, 80);
    if (value.contains('/')) {
      throw const FormatException('Mã món không hợp lệ.');
    }
  }

  static void number(double value, double max, {bool positive = false}) {
    if (!value.isFinite || (positive ? value <= 0 : value < 0) || value > max) {
      throw const FormatException(
        'Giá trị dinh dưỡng hoặc khẩu phần chưa hợp lệ.',
      );
    }
  }

  static void nutrition(NutritionTotals n) {
    number(n.kcal, 10000);
    number(n.proteinG, 1000);
    number(n.carbsG, 1000);
    number(n.fatG, 1000);
    number(n.fiberG, 1000);
    for (final e in n.extraNutrients.entries) {
      final nutrient = ExtraNutrient.values
          .where((n) => n.name == e.key)
          .firstOrNull;
      if (nutrient == null) {
        throw const FormatException('Dưỡng chất chưa hỗ trợ.');
      }
      number(e.value, nutrient.maximum);
    }
  }

  static double readNumber(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! num || !value.isFinite) {
      throw const FormatException('Thiếu số liệu dinh dưỡng.');
    }
    return value.toDouble();
  }

  static Map<String, Object?> snapshot(MealItemSnapshot item) => item.toData();
  static MealItemSnapshot readSnapshot(Map<String, dynamic> d) =>
      MealItemSnapshot.fromData(d, allowPartial: true);
}

class PersonalFood extends LibraryEntry {
  PersonalFood({
    required this.id,
    required this.name,
    required this.per100g,
    List<String> alternateNames = const [],
    this.defaultServingGrams = 100,
    this.servingLabel,
    this.servingGrams,
    this.sourceLabel = 'Người dùng nhập · Ước tính',
    this.isEstimated = true,
    this.minimumSchemaVersion = 1,
  }) : alternateNames = List.unmodifiable(alternateNames);
  @override
  final String id;
  @override
  final String name;
  final List<String> alternateNames;
  final NutritionTotals per100g;
  final double defaultServingGrams;
  final String? servingLabel;
  final double? servingGrams;
  final String sourceLabel;
  final bool isEstimated;
  final int minimumSchemaVersion;
  @override
  FoodSourceKind get kind => FoodSourceKind.custom;
  @override
  void validate() {
    LibraryValidation.id(id);
    LibraryValidation.text(name, 100, min: 2);
    LibraryValidation.text(sourceLabel, 160);
    LibraryValidation.nutrition(per100g);
    LibraryValidation.number(per100g.fiberG, 100);
    if (!per100g.fiberKnown && per100g.fiberG > 0) {
      throw const FormatException(
        'Chất xơ mới biết một phần; hãy giữ dưới dạng công thức hoặc bữa mẫu.',
      );
    }
    if (!per100g.hasCompleteMacros) {
      throw const FormatException(
        'Món trong thư viện cần đủ ba chất. Dùng ghi nhanh hoặc bữa mẫu nếu chưa biết.',
      );
    }
    LibraryValidation.number(defaultServingGrams, 2000, positive: true);
    if (alternateNames.length > 5) {
      throw const FormatException('Tối đa 5 tên khác.');
    }
    for (final alias in alternateNames) {
      LibraryValidation.text(alias, 60);
    }
    if ((servingLabel == null) != (servingGrams == null)) {
      throw const FormatException(
        'Tên khẩu phần và gram phải được nhập cùng nhau.',
      );
    }
    if (servingLabel != null) {
      LibraryValidation.text(servingLabel!, 40);
      LibraryValidation.number(servingGrams!, 2000, positive: true);
    }
  }

  @override
  Map<String, Object?> toData() {
    validate();
    return {
      'name': name,
      'alternateNames': alternateNames,
      'servingBasis': 'per_100g',
      'kcalPer100g': per100g.kcal,
      'proteinGPer100g': per100g.proteinG,
      'carbsGPer100g': per100g.carbsG,
      'fatGPer100g': per100g.fatG,
      if (per100g.fiberKnown) 'fiberGPer100g': per100g.fiberG,
      if (per100g.extraNutrients.isNotEmpty)
        'extraNutrientsPer100g': per100g.extraNutrients,
      'defaultServingGrams': defaultServingGrams,
      'servingLabel': servingLabel,
      'servingGrams': servingGrams,
      'sourceLabel': sourceLabel,
      'isEstimated': isEstimated,
      'schemaVersion':
          minimumSchemaVersion >= 3 || per100g.extraNutrients.isNotEmpty
          ? 3
          : per100g.fiberKnown
          ? 2
          : 1,
    };
  }

  factory PersonalFood.fromData(String id, Map<String, dynamic> d) {
    if (![1, 2, 3].contains(d['schemaVersion']) ||
        d['servingBasis'] != 'per_100g') {
      throw const FormatException();
    }
    final food = PersonalFood(
      id: id,
      minimumSchemaVersion: d['schemaVersion'] as int,
      name: d['name'] as String,
      alternateNames: List<String>.from(d['alternateNames'] as List),
      per100g: NutritionTotals(
        extraNutrients: readExtraNutrients(d['extraNutrientsPer100g']),
        kcal: LibraryValidation.readNumber(d, 'kcalPer100g'),
        proteinG: LibraryValidation.readNumber(d, 'proteinGPer100g'),
        carbsG: LibraryValidation.readNumber(d, 'carbsGPer100g'),
        fatG: LibraryValidation.readNumber(d, 'fatGPer100g'),
        fiberG: d['fiberGPer100g'] == null
            ? 0
            : LibraryValidation.readNumber(d, 'fiberGPer100g'),
        fiberKnown: d['fiberGPer100g'] != null,
      ),
      defaultServingGrams: LibraryValidation.readNumber(
        d,
        'defaultServingGrams',
      ),
      servingLabel: d['servingLabel'] as String?,
      servingGrams: d['servingGrams'] == null
          ? null
          : LibraryValidation.readNumber(d, 'servingGrams'),
      sourceLabel: d['sourceLabel'] as String,
      isEstimated: d['isEstimated'] as bool,
    );
    food.validate();
    return food;
  }
  @override
  FoodCatalogItem asFood() {
    validate();
    return FoodCatalogItem(
      id: 'custom:$id',
      name: name,
      alternateNames: alternateNames,
      category: 'Món của tôi',
      servingBasis: ServingBasis.per100g,
      unit: 'g',
      per100g: per100g,
      sourceLabel: sourceLabel,
      isEstimated: isEstimated,
      defaultServingGrams: defaultServingGrams,
      servingLabel: servingLabel,
      servingGrams: servingGrams,
    );
  }
}

class FoodRecipe extends LibraryEntry {
  FoodRecipe({
    required this.id,
    required this.name,
    required List<MealItemSnapshot> ingredients,
    required this.yieldGrams,
    this.servingsCount,
    this.sourceLabel = 'Công thức người dùng · Ước tính',
    this.minimumSchemaVersion = 1,
  }) : ingredients = List.unmodifiable(ingredients);
  @override
  final String id;
  @override
  final String name;
  final List<MealItemSnapshot> ingredients;
  final double yieldGrams;
  final double? servingsCount;
  final String sourceLabel;
  final int minimumSchemaVersion;
  @override
  FoodSourceKind get kind => FoodSourceKind.recipe;
  NutritionTotals get totals =>
      sumNutritionTotals(ingredients.map((i) => i.nutrition));
  NutritionTotals get per100g {
    validate();
    return totals.scale(100 / yieldGrams);
  }

  double? get portionGrams =>
      servingsCount == null ? null : yieldGrams / servingsCount!;
  @override
  void validate() {
    LibraryValidation.id(id);
    LibraryValidation.text(name, 100, min: 2);
    LibraryValidation.text(sourceLabel, 160);
    LibraryValidation.number(yieldGrams, 20000, positive: true);
    if (servingsCount != null) {
      LibraryValidation.number(servingsCount!, 1000, positive: true);
    }
    if (ingredients.isEmpty ||
        ingredients.length > LibraryValidation.maxIngredients) {
      throw const FormatException('Công thức cần từ 1 đến 6 nguyên liệu.');
    }
    for (final item in ingredients) {
      LibraryValidation.text(item.foodId, 100);
      LibraryValidation.text(item.name, 100);
      LibraryValidation.text(item.sourceLabel, 160);
      if (item.foodId.startsWith('recipe:') ||
          !item.hasNutritionData ||
          item.quantityUnit != 'g' ||
          !item.nutrition.hasCompleteMacros) {
        throw const FormatException(
          'Chỉ chọn nguyên liệu từ catalog hoặc Món của tôi.',
        );
      }
      LibraryValidation.number(item.grams, 2000, positive: true);
      LibraryValidation.nutrition(item.nutrition);
    }
    // Keep recipe /100g compatible with the same bounds as personal food.
    LibraryValidation.nutrition(totals.scale(100 / yieldGrams));
    if (portionGrams != null) {
      LibraryValidation.number(portionGrams!, 20000, positive: true);
    }
  }

  @override
  Map<String, Object?> toData() {
    validate();
    final enriched =
        minimumSchemaVersion >= 3 ||
        ingredients.any((i) => i.nutrition.extraNutrients.isNotEmpty);
    return {
      'name': name,
      'ingredients': [
        for (final item in ingredients)
          {
            for (final e in item.toData().entries)
              if (e.key != 'nutrientVectorV1') e.key: e.value,
          },
      ],
      if (enriched)
        'nutrientVectorsV1': ingredients
            .map((i) => encodeExtraNutrients(i.nutrition.extraNutrients))
            .join('|'),
      'yieldGrams': yieldGrams,
      'servingsCount': servingsCount,
      'sourceLabel': sourceLabel,
      'isEstimated': true,
      'schemaVersion': enriched
          ? 3
          : ingredients.any((i) => i.hasFiberData)
          ? 2
          : 1,
    };
  }

  factory FoodRecipe.fromData(String id, Map<String, dynamic> d) {
    if (![1, 2, 3].contains(d['schemaVersion']) || d['isEstimated'] != true) {
      throw const FormatException();
    }
    final rawItems = d['ingredients'] as List;
    final vectors = d['schemaVersion'] == 3
        ? (d['nutrientVectorsV1'] as String).split('|')
        : null;
    if (vectors != null && vectors.length != rawItems.length) {
      throw const FormatException();
    }
    final recipe = FoodRecipe(
      id: id,
      minimumSchemaVersion: d['schemaVersion'] as int,
      name: d['name'] as String,
      ingredients: rawItems.indexed
          .map(
            (entry) => LibraryValidation.readSnapshot({
              ...Map<String, dynamic>.from(entry.$2 as Map),
              if (vectors != null) 'nutrientVectorV1': vectors[entry.$1],
            }),
          )
          .toList(),
      yieldGrams: LibraryValidation.readNumber(d, 'yieldGrams'),
      servingsCount: d['servingsCount'] == null
          ? null
          : LibraryValidation.readNumber(d, 'servingsCount'),
      sourceLabel: d['sourceLabel'] as String,
    );
    recipe.validate();
    return recipe;
  }
  @override
  FoodCatalogItem asFood() => FoodCatalogItem(
    id: 'recipe:$id',
    name: name,
    alternateNames: const [],
    category: 'Công thức',
    servingBasis: ServingBasis.per100g,
    unit: 'g',
    per100g: per100g,
    sourceLabel: sourceLabel,
    isEstimated: true,
    defaultServingGrams: portionGrams != null && portionGrams! <= 2000
        ? portionGrams!
        : 100,
    servingLabel: portionGrams == null ? null : 'phần',
    servingGrams: portionGrams,
    recipeIngredients: [
      for (final item in ingredients)
        FoodRecipeIngredient(
          foodId: item.foodId,
          name: item.name,
          gramsPer100gYield: item.grams * 100 / yieldGrams,
        ),
    ],
  );
}

class LibraryPage {
  const LibraryPage({required this.items, this.fromCache = false});
  final List<LibraryEntry> items;
  final bool fromCache;
}
