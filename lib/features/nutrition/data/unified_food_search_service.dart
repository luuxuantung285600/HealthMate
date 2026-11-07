import 'package:flutter/foundation.dart';
import '../models/nutrition_models.dart';
import '../models/food_catalog_search.dart';
import 'food_search_cache.dart';
import 'food_search_request.dart';
import 'usda_api_service.dart';
export 'food_search_request.dart';

class FoodSearchResult {
  const FoodSearchResult({
    required this.food,
    required this.source,
    this.requiresDetail = false,
  });
  final FoodCatalogItem food;
  final FoodResultSource source;
  final bool requiresDetail;
}

enum FoodResultSource {
  firestore,
  cache,
  usdaApi,
  user;

  String get displayLabel => switch (this) {
    FoodResultSource.firestore => 'Danh mục local',
    FoodResultSource.cache => 'Đã lưu',
    FoodResultSource.usdaApi => 'USDA',
    FoodResultSource.user => 'Của bạn',
  };
}

enum FoodSearchStage { cache, online, complete }

class FoodSearchOutcome {
  const FoodSearchOutcome(
    this.results, {
    this.stage = FoodSearchStage.complete,
    this.failure,
    this.cacheWarning = false,
  });
  final List<FoodSearchResult> results;
  final FoodSearchStage stage;
  final FoodSearchFailure? failure;
  final bool cacheWarning;
  bool get isLoading => stage != FoodSearchStage.complete;
  bool get isPartial => results.isNotEmpty && (failure != null || cacheWarning);
  String? get message =>
      failure?.message ??
      (cacheWarning
          ? 'Bộ nhớ món trên máy chưa khả dụng. Bạn vẫn có thể dùng kết quả hiện có.'
          : null);
}

class FoodDetailOutcome {
  const FoodDetailOutcome(this.food, {this.cacheWarning = false});
  final FoodCatalogItem food;
  final bool cacheWarning;
}

/// Public metadata is searched once; nutrition detail is fetched on selection.
class UnifiedFoodSearchService {
  UnifiedFoodSearchService({
    required this.localDatabase,
    required this.usdaService,
    this.isAllowed,
  });
  final FoodSearchCache localDatabase;
  final UsdaApiService usdaService;
  final bool Function(FoodCatalogItem)? isAllowed;
  bool _allows(FoodCatalogItem food) => isAllowed?.call(food) ?? true;
  void _checkVisible(FoodCatalogItem food) {
    if (!_allows(food)) {
      throw const FoodSearchFailure(FoodSearchFailureKind.invalidData);
    }
  }

  Future<FoodSearchOutcome> search({
    required String query,
    required List<FoodCatalogItem> firestoreCatalog,
    int limit = 25,
    FoodSearchRequest? request,
    void Function(FoodSearchOutcome)? onProgress,
  }) async {
    final work = request ?? FoodSearchRequest();
    final count = limit.clamp(1, 50);
    final results = <FoodSearchResult>[];
    final seen = <String>{};
    var cacheWarning = false;
    void add(
      FoodCatalogItem food,
      FoodResultSource source, {
      bool detail = false,
    }) {
      if (_allows(food) && seen.add(food.id) && results.length < count) {
        results.add(
          FoodSearchResult(food: food, source: source, requiresDetail: detail),
        );
      }
    }

    FoodSearchOutcome snapshot(
      FoodSearchStage stage, {
      FoodSearchFailure? failure,
    }) => FoodSearchOutcome(
      List.unmodifiable(results.where((row) => _allows(row.food))),
      stage: stage,
      failure: failure,
      cacheWarning: cacheWarning,
    );
    void publish(FoodSearchStage stage) {
      work.check();
      onProgress?.call(snapshot(stage));
    }

    try {
      work.check();
      if (query.trim().isEmpty) return snapshot(FoodSearchStage.complete);
      for (final food in searchFoodCatalog(
        firestoreCatalog,
        query,
      ).take(count)) {
        add(
          food,
          food.dataSource == FoodDataSource.user
              ? FoodResultSource.user
              : FoodResultSource.firestore,
        );
      }
      publish(FoodSearchStage.cache);
      if (results.length >= 10 || results.length >= count) {
        return snapshot(FoodSearchStage.complete);
      }
      try {
        final cached = await work.run(
          () => localDatabase.searchFoods(query, limit: count - results.length),
        );
        for (final food in cached) {
          add(food, FoodResultSource.cache);
        }
      } on FoodSearchFailure {
        rethrow;
      } catch (_) {
        cacheWarning = true;
      }
      if (results.length >= 10 || results.length >= count) {
        return snapshot(FoodSearchStage.complete);
      }
      publish(FoodSearchStage.online);
      final rows = await usdaService.searchFoods(
        query,
        pageSize: count - results.length,
        request: work,
      );
      work.check();
      for (final row in rows) {
        add(
          FoodCatalogItem(
            id: 'usda_${row.fdcId}',
            name: row.description,
            category: 'USDA',
            servingBasis: ServingBasis.per100g,
            sourceLabel: 'USDA FoodData Central',
            isEstimated: false,
            hasNutritionData: false,
            dataSource: FoodDataSource.usda,
            fdcId: row.fdcId,
            brand: row.brandOwner,
          ),
          FoodResultSource.usdaApi,
          detail: true,
        );
      }
      return snapshot(FoodSearchStage.complete);
    } on FoodSearchFailure catch (failure) {
      if (failure.kind == FoodSearchFailureKind.cancelled) rethrow;
      return snapshot(FoodSearchStage.complete, failure: failure);
    } finally {
      if (request == null) work.finish();
    }
  }

  Future<FoodDetailOutcome> resolveResult(
    FoodSearchResult result, {
    FoodSearchRequest? request,
  }) async {
    final work = request ?? FoodSearchRequest();
    try {
      work.check();
      _checkVisible(result.food);
      if (!result.requiresDetail) return FoodDetailOutcome(result.food);
      var cacheWarning = false;
      FoodCatalogItem? cached;
      try {
        cached = await work.run(
          () => localDatabase.getFoodById(result.food.id),
        );
      } on FoodSearchFailure {
        rethrow;
      } catch (_) {
        cacheWarning = true;
      }
      if (cached != null && cached.hasNutritionData) {
        _checkVisible(cached);
        return FoodDetailOutcome(cached, cacheWarning: cacheWarning);
      }
      work.check();
      final id = result.food.fdcId;
      if (id == null) {
        throw const FoodSearchFailure(FoodSearchFailureKind.invalidData);
      }
      final food = await usdaService.getFoodDetail(id, request: work);
      if (food == null || !food.hasNutritionData) {
        throw const FoodSearchFailure(FoodSearchFailureKind.invalidData);
      }
      _checkVisible(food);
      try {
        await work.run(() => localDatabase.cacheFood(food));
      } on FoodSearchFailure catch (failure) {
        if (failure.kind == FoodSearchFailureKind.cancelled) rethrow;
        // Detail is already usable. A slow cache must not turn it into no food.
        cacheWarning = true;
      } catch (_) {
        cacheWarning = true;
      }
      _checkVisible(food);
      return FoodDetailOutcome(food, cacheWarning: cacheWarning);
    } finally {
      if (request == null) work.finish();
    }
  }

  Future<FoodCatalogItem?> getFoodById(
    String id, {
    required List<FoodCatalogItem> firestoreCatalog,
  }) async {
    final local = firestoreCatalog.where((f) => f.id == id).firstOrNull;
    if (local != null) return _allows(local) ? local : null;
    final fdcId = id.startsWith('usda_') ? int.tryParse(id.substring(5)) : null;
    if (fdcId != null) {
      return (await resolveResult(
        FoodSearchResult(
          source: FoodResultSource.usdaApi,
          requiresDetail: true,
          food: FoodCatalogItem(
            id: id,
            name: id,
            category: 'USDA',
            servingBasis: ServingBasis.per100g,
            sourceLabel: 'USDA FoodData Central',
            isEstimated: false,
            hasNutritionData: false,
            fdcId: fdcId,
          ),
        ),
      )).food;
    }
    final cached = await localDatabase.getFoodById(id);
    return cached != null && _allows(cached) ? cached : null;
  }

  /// Mark food as recently used
  Future<void> markFoodUsed(String foodId) async {
    try {
      await localDatabase.markFoodUsed(foodId);
    } catch (_) {
      if (kDebugMode) debugPrint('HM_FOOD_SEARCH recent-write failed');
    }
  }

  /// Get recently used foods for quick access
  Future<List<FoodCatalogItem>> getRecentFoods({int limit = 20}) async {
    try {
      return (await localDatabase.getRecentFoods(
        limit: limit,
      )).where(_allows).toList();
    } catch (_) {
      if (kDebugMode) debugPrint('HM_FOOD_SEARCH recent-read failed');
      return [];
    }
  }

  /// Clean old cache entries
  Future<void> cleanOldCache() async {
    try {
      await localDatabase.cleanOldCache();
    } catch (_) {
      if (kDebugMode) debugPrint('HM_FOOD_SEARCH cache-clean failed');
    }
  }

  /// Get cache statistics for debugging/settings
  Future<Map<String, int>> getCacheStats() async {
    try {
      return await localDatabase.getCacheStats();
    } catch (_) {
      if (kDebugMode) debugPrint('HM_FOOD_SEARCH cache-stats failed');
      return {'total': 0, 'usda': 0, 'local': 0, 'user': 0};
    }
  }
}
