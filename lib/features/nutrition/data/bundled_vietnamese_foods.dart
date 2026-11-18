import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/catalog_food_reader.dart';
import '../models/nutrition_models.dart';
import '../models/food_catalog_search.dart';

Future<List<FoodCatalogItem>> loadBundledVietnameseFoods({
  AssetBundle? bundle,
}) async {
  final assets = bundle ?? rootBundle;
  final sources = await Future.wait([
    assets.loadString('assets/nutrition/vietnamese-foods.json'),
    assets.loadString('assets/nutrition/usda-sr-legacy.json').catchError((_) {
      if (kDebugMode) debugPrint('HM_FOOD_CATALOG supplement unavailable');
      return '';
    }),
    assets.loadString('assets/nutrition/usda-current.json').catchError((_) {
      if (kDebugMode) {
        debugPrint('HM_FOOD_CATALOG current reference unavailable');
      }
      return '';
    }),
  ]);
  return compute(decodeBundledFoodCatalog, sources);
}

@visibleForTesting
List<FoodCatalogItem> decodeBundledFoodCatalog(List<String> sources) {
  final json = jsonDecode(sources[0]) as Map<String, dynamic>;
  var dietary = <String, dynamic>{};
  var ingredients = <String, dynamic>{};
  var supplement = <FoodCatalogItem>[];
  try {
    final expansion = jsonDecode(sources[1]) as Map<String, dynamic>;
    final parsed = [
      for (final raw in expansion['foods'] as List)
        readCatalogFood(
          (raw as Map)['id'] as String,
          Map<String, dynamic>.from(raw),
        ),
    ];
    dietary = Map<String, dynamic>.from(expansion['localDietaryClass'] as Map);
    ingredients = Map<String, dynamic>.from(
      expansion['localIngredients'] as Map? ?? {},
    );
    supplement = parsed;
  } catch (_) {
    dietary = {};
    ingredients = {};
    // Retain the base catalog if the optional reference asset is damaged.
    // Missing diet metadata stays unknown rather than guessing ingredients.
    if (kDebugMode) {
      debugPrint('HM_FOOD_CATALOG supplement could not be decoded');
    }
  }
  var current = <FoodCatalogItem>[];
  // Optional datasets fail independently, so one corrupt asset cannot discard
  // another valid reference set or the base Vietnamese catalog.
  if (sources.length > 2) {
    try {
      final expansion = jsonDecode(sources[2]) as Map<String, dynamic>;
      current = [
        for (final raw in expansion['foods'] as List)
          readCatalogFood(
            (raw as Map)['id'] as String,
            Map<String, dynamic>.from(raw),
          ),
      ];
    } catch (_) {
      if (kDebugMode) {
        debugPrint('HM_FOOD_CATALOG current reference could not be decoded');
      }
    }
  }
  final referenceCatalog = <String, FoodCatalogItem>{
    for (final raw in json['foods'] as List)
      raw['id'] as String: readCatalogFood(
        raw['id'] as String,
        Map<String, dynamic>.from(raw as Map),
      ),
  };
  return [
    for (final raw in json['foods'] as List)
      readCatalogFood((raw as Map)['id'] as String, {
        ...Map<String, dynamic>.from(raw),
        'dietaryClass': dietary[raw['id']] ?? raw['dietaryClass'],
        if (ingredients[raw['id']] is Map)
          ...Map<String, dynamic>.from(ingredients[raw['id']] as Map),
      }, ingredientCatalog: referenceCatalog),
    ...supplement,
    ...current,
  ]..sort(compareCatalogFoods);
}
