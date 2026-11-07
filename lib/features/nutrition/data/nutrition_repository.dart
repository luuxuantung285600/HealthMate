import '../models/nutrition_models.dart';
import '../models/food_visibility.dart';

abstract interface class NutritionRepository {
  Stream<List<FoodCatalogItem>> watchFoodCatalog();
  Stream<FoodVisibility> watchFoodVisibility();

  Stream<List<MealLog>> watchMealLogs(String uid, DateTime localDate);

  Stream<RecentMealPage> watchRecentMeals(String uid, {int limit = 20});
  String newMealId();

  /// One-shot local-date range [start, end), including legacy meals.
  Future<List<MealLog>> loadRange(String uid, DateTime start, DateTime end);

  Future<String> addMeal({
    required String uid,
    required MealDraft draft,
    String? operationId,
  });

  Future<void> updateMeal({
    required String uid,
    required String mealId,
    required MealDraft draft,
  });

  Future<void> deleteMeal({required String uid, required String mealId});
}
