import 'nutrition_models.dart';
import 'extra_nutrients.dart';
import 'food_photo.dart';

/// Catalog metadata is optional. A damaged portion never corrupts the per-100g
/// values or makes unrelated catalog documents unreadable.
FoodCatalogItem readCatalogFood(
  String id,
  Map<String, dynamic> data, {
  DateTime? updatedAt,
  FoodCatalogItem? referenceFood,
  Map<String, FoodCatalogItem> ingredientCatalog = const {},
}) {
  String? text(String key, [int max = 100]) {
    final value = data[key];
    return value is String && value.trim().isNotEmpty && value.length <= max
        ? value.trim()
        : null;
  }

  double? number(String key, double max, {bool positive = false}) {
    final value = data[key];
    return value is num &&
            value.isFinite &&
            (positive ? value > 0 : value >= 0) &&
            value <= max
        ? value.toDouble()
        : null;
  }

  final kcal = number('kcalPer100g', 10000);
  final protein = number('proteinGPer100g', 1000);
  final carbs = number('carbsGPer100g', 1000);
  final fat = number('fatGPer100g', 1000);
  final fiber = number('fiberGPer100g', 100);
  final basisStr =
      text('servingBasis') ??
      (data['servingBasis'] == null ? 'per_100g' : 'unsupported');
  final basis = basisStr == 'per_100g'
      ? ServingBasis.per100g
      : basisStr == 'explicit_serving'
      ? ServingBasis.explicitServing
      : ServingBasis.per100g; // fallback
  final unit = text('unit') ?? (data['unit'] == null ? 'g' : 'unsupported');
  final label = text('servingLabel', 60);
  final grams = number('servingGrams', 2000, positive: true);
  final hasRawServing =
      data['servingLabel'] != null || data['servingGrams'] != null;
  final validServing =
      label != null && grams != null && basisStr == 'per_100g' && unit == 'g';
  final referenceMatches =
      referenceFood != null &&
      referenceFood.id == id &&
      (referenceFood.name == text('name') ||
          referenceFood.originalName == text('name')) &&
      referenceFood.sourceLabel == text('sourceLabel', 160) &&
      referenceFood.nutritionPer100g.kcal == kcal &&
      referenceFood.nutritionPer100g.proteinG == protein &&
      referenceFood.nutritionPer100g.carbsG == carbs &&
      referenceFood.nutritionPer100g.fatG == fat;
  final dietaryClass = FoodDietClass.values
      .where((kind) => kind.name == data['dietaryClass'])
      .firstOrNull;
  return FoodCatalogItem(
    id: id,
    photoMode: data['photo'] == null
        ? 'default'
        : (data['photo'] is Map && data['photo']['mode'] == 'default'
              ? 'default'
              : data['photo'] is Map && data['photo']['mode'] == 'custom'
              ? 'custom'
              : 'hidden'),
    photo: readCatalogPhoto(id, text('name') ?? '', data['photo']),
    name: text('name') ?? 'Món chưa có tên',
    originalName:
        text('originalName', 1000) ??
        (referenceMatches ? referenceFood.originalName : null),
    ingredientNames: data['ingredientNames'] is List
        ? (data['ingredientNames'] as List)
              .whereType<String>()
              .take(60)
              .toList()
        : (referenceMatches ? referenceFood.ingredientNames : const []),
    ingredientsKnown:
        data['ingredientsKnown'] == true ||
        (data['ingredientsKnown'] == null &&
            referenceMatches &&
            referenceFood.ingredientsKnown),
    recipeIngredients: data['sourceDetails'] != null
        ? _readRecipeIngredients(data['sourceDetails'], ingredientCatalog)
        : (referenceMatches ? referenceFood.recipeIngredients : const []),
    dietaryClass:
        dietaryClass ??
        (referenceMatches ? referenceFood.dietaryClass : FoodDietClass.unknown),
    alternateNames: data['alternateNames'] is List
        ? (data['alternateNames'] as List)
              .whereType<String>()
              .where((s) => s.trim().isNotEmpty)
              .toList()
        : const [],
    category: text('category') ?? '',
    servingBasis: basis,
    unit: unit,
    hasNutritionData:
        [kcal, protein, carbs, fat].every((v) => v != null) &&
        basisStr == 'per_100g' &&
        unit == 'g',
    per100g: NutritionTotals(
      extraNutrients:
          !data.containsKey('extraNutrientsPer100g') &&
              referenceMatches &&
              basisStr == 'per_100g' &&
              unit == 'g'
          ? referenceFood.nutritionPer100g.extraNutrients
          : readExtraNutrients(data['extraNutrientsPer100g']),
      kcal: kcal ?? 0,
      proteinG: protein ?? 0,
      carbsG: carbs ?? 0,
      fatG: fat ?? 0,
      fiberG: fiber ?? 0,
      fiberKnown: fiber != null,
    ),
    sourceLabel: text('sourceLabel', 160) ?? 'Không rõ nguồn',
    isEstimated: data['isEstimated'] is bool
        ? data['isEstimated'] as bool
        : true,
    updatedAt: updatedAt,
    defaultServingGrams:
        number('defaultServingGrams', 2000, positive: true) ??
        // A server catalog document may have a package portion without the
        // optional default field. Start with one declared package, as offline.
        (validServing && text('packageLabel', 60) != null ? grams : 100),
    servingLabel: validServing ? label : null,
    servingGrams: validServing ? grams : null,
    servingMetadataInvalid: hasRawServing && !validServing,
    brand: text('brand', 60),
    packageLabel: text('packageLabel', 60),
    dataSource:
        FoodDataSource.values
            .where((source) => source.wireValue == data['dataSource'])
            .firstOrNull ??
        FoodDataSource.local,
    fdcId: data['fdcId'] is int && (data['fdcId'] as int) > 0
        ? data['fdcId'] as int
        : null,
  );
}

List<FoodRecipeIngredient> _readRecipeIngredients(
  Object? details,
  Map<String, FoodCatalogItem> catalog,
) {
  if (details is! Map || details['method'] != 'recipe_estimate') {
    return const [];
  }
  final yield = details['yieldGrams'];
  final entries = details['ingredients'];
  if (yield is! num ||
      !yield.isFinite ||
      yield <= 0 ||
      yield > 20000 ||
      entries is! List ||
      entries.isEmpty ||
      entries.length > 60) {
    return const [];
  }
  final result = <FoodRecipeIngredient>[];
  for (final entry in entries) {
    if (entry is! Map || entry['reference'] is! String) return const [];
    final ingredient = catalog['vn2007-${entry['reference']}'];
    final grams = entry['grams'];
    if (ingredient == null ||
        grams is! num ||
        !grams.isFinite ||
        grams <= 0 ||
        grams > 20000) {
      return const [];
    }
    result.add(
      FoodRecipeIngredient(
        foodId: ingredient.id,
        name: ingredient.name,
        gramsPer100gYield: grams * 100 / yield,
      ),
    );
  }
  return List.unmodifiable(result);
}
