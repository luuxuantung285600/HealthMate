import 'dart:convert';
import '../../nutrition/models/nutrition_models.dart';

bool canUseRecipeIngredient(FoodCatalogItem food) =>
    !food.id.startsWith('recipe:') &&
    food.hasNutritionData &&
    food.unit == 'g' &&
    food.servingBasis == ServingBasis.per100g &&
    food.nutritionPer100g.hasCompleteMacros;

/// Compare the data actually shown/added, not object identity or unrelated edits.
/// Extra nutrient vectors use the stable schema order from snapshot.toData().
String ingredientSelectionRevision(FoodCatalogItem food) => jsonEncode([
  food.defaultServingGrams,
  food.servingLabel,
  food.servingGrams,
  MealItemSnapshot.fromCatalog(food, 100).toData(),
]);
