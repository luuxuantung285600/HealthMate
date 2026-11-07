import '../../../core/utils/subscription_stream.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/firebase_nutrition_repository.dart';
import '../data/food_local_database.dart';
import '../data/nutrition_repository.dart';
import '../data/unified_food_search_service.dart';
import '../data/usda_api_service.dart';
import '../data/bundled_vietnamese_foods.dart';
import '../models/nutrition_failure.dart';
import '../models/nutrition_models.dart';
import '../models/food_visibility.dart';

final nutritionRepositoryProvider = Provider<NutritionRepository>(
  (ref) => FirebaseNutritionRepository(FirebaseFirestore.instance),
);

// SQLite database singleton
final foodLocalDatabaseProvider = Provider<FoodLocalDatabase>(
  (ref) => FoodLocalDatabase.instance,
);

// USDA API service
final usdaApiServiceProvider = Provider<UsdaApiService>((ref) {
  final service = UsdaApiService();
  ref.onDispose(service.dispose);
  return service;
});

// Unified search service
final unifiedFoodSearchProvider = Provider<UnifiedFoodSearchService>(
  (ref) => UnifiedFoodSearchService(
    localDatabase: ref.watch(foodLocalDatabaseProvider),
    usdaService: ref.watch(usdaApiServiceProvider),
    isAllowed: (food) =>
        (ref.read(foodVisibilityProvider).value ?? const FoodVisibility())
            .allows(food),
  ),
);

final foodVisibilityProvider = StreamProvider<FoodVisibility>((ref) {
  final user = ref.watch(authSessionProvider).value;
  if (user?.emailVerified != true) return Stream.value(const FoodVisibility());
  return ref.watch(nutritionRepositoryProvider).watchFoodVisibility();
}, retry: (_, _) => null);

// Preload Vietnamese foods on app start
final vietnameseFoodsPreloadProvider = FutureProvider.autoDispose<void>((
  ref,
) async {
  final db = ref.watch(foodLocalDatabaseProvider);
  // Idempotent refresh replaces the old unsourced preload with the versioned
  // app asset. Never put private library foods in this shared cache.
  await db.cacheFoodsBatch(await loadBundledVietnameseFoods());
});

final foodCatalogProvider = StreamProvider.autoDispose<List<FoodCatalogItem>>((
  ref,
) {
  return subscriptionStream(
    ref.watch(nutritionRepositoryProvider).watchFoodCatalog(),
  );
});

final mealLogsProvider = StreamProvider.autoDispose
    .family<List<MealLog>, DateTime>((ref, localDate) {
      final user = ref.watch(authSessionProvider).value;
      if (user == null) {
        return Stream.value(const []);
      }
      return subscriptionStream(
        ref
            .watch(nutritionRepositoryProvider)
            .watchMealLogs(user.uid, localDate),
      );
    }, retry: (_, _) => null);

final recentMealsProvider = StreamProvider.autoDispose<RecentMealPage>((ref) {
  final user = ref.watch(authSessionProvider).value;
  if (user == null) {
    return Stream.value(const RecentMealPage(meals: []));
  }
  return subscriptionStream(
    ref.watch(nutritionRepositoryProvider).watchRecentMeals(user.uid),
  );
}, retry: (_, _) => null);

final recentMealItemsProvider =
    Provider.autoDispose<AsyncValue<List<MealItemSnapshot>>>(
      (ref) => ref
          .watch(recentMealsProvider)
          .whenData((page) => recentMealItems(page.meals)),
    );

final nutritionControllerProvider =
    NotifierProvider<NutritionController, AsyncValue<void>>(
      NutritionController.new,
    );

class NutritionController extends Notifier<AsyncValue<void>> {
  int _generation = 0;
  @override
  AsyncValue<void> build() {
    ref.watch(authSessionProvider.select((s) => s.value?.uid));
    _generation++;
    return const AsyncData(null);
  }

  void clearError() {
    if (!state.isLoading) state = const AsyncData(null);
  }

  Future<bool> addMeal(MealDraft draft, {String? operationId}) =>
      _perform((user) async {
        await ref
            .read(nutritionRepositoryProvider)
            .addMeal(uid: user.uid, draft: draft, operationId: operationId);
      });

  Future<bool> updateMeal({required String mealId, required MealDraft draft}) =>
      _perform((user) {
        return ref
            .read(nutritionRepositoryProvider)
            .updateMeal(uid: user.uid, mealId: mealId, draft: draft);
      });

  Future<bool> deleteMeal(String mealId) => _perform((user) {
    return ref
        .read(nutritionRepositoryProvider)
        .deleteMeal(uid: user.uid, mealId: mealId);
  });

  Future<bool> _perform(Future<void> Function(AuthUser user) operation) async {
    if (state.isLoading) return false;
    final user = ref.read(authSessionProvider).value;
    if (user == null) {
      state = AsyncError(
        const NutritionFailure('Phiên đăng nhập đã hết hạn.'),
        StackTrace.current,
      );
      return false;
    }
    final generation = _generation;
    bool current() =>
        ref.mounted &&
        generation == _generation &&
        ref.read(authSessionProvider).value?.uid == user.uid;
    state = const AsyncLoading();
    try {
      await operation(user);
      if (!current()) return false;
      state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (current()) {
        state = AsyncError(
          error is NutritionFailure
              ? error
              : NutritionFailure.fromCode('unknown'),
          stack,
        );
      }
      return false;
    }
  }
}
