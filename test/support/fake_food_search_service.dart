import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthmate/features/nutrition/data/food_local_database.dart';
import 'package:healthmate/features/nutrition/data/unified_food_search_service.dart';
import 'package:healthmate/features/nutrition/data/usda_api_service.dart';
import 'package:healthmate/features/nutrition/models/food_catalog_search.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';

/// Unit/widget tests use a deterministic catalog, never the real USDA endpoint
/// or a platform SQLite plugin. External-source integration remains unverified.
class FakeFoodSearchService extends UnifiedFoodSearchService {
  FakeFoodSearchService()
    : super(
        localDatabase: FoodLocalDatabase.instance,
        usdaService: UsdaApiService(),
      );
  @override
  Future<FoodSearchOutcome> search({
    required String query,
    required List<FoodCatalogItem> firestoreCatalog,
    int limit = 25,
    FoodSearchRequest? request,
    void Function(FoodSearchOutcome)? onProgress,
    bool Function(FoodCatalogItem)? matches,
  }) async => FoodSearchOutcome(
    searchFoodCatalog(firestoreCatalog, query)
        .where((food) => matches?.call(food) ?? true)
        .take(limit)
        .map(
          (food) =>
              FoodSearchResult(food: food, source: FoodResultSource.firestore),
        )
        .toList(),
  );
}

Widget testFoodScope(Widget child) => ProviderScope(
  overrides: [
    unifiedFoodSearchProvider.overrideWithValue(FakeFoodSearchService()),
  ],
  child: child,
);
