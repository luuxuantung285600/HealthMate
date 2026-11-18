import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/nutrition/data/bundled_vietnamese_foods.dart';
import 'package:healthmate/features/nutrition/models/food_catalog_search.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'current datasets load with traceable sources and conservative diets',
    () async {
      final foods = await loadBundledVietnameseFoods();
      final foundation = foods
          .where((f) => f.id.startsWith('usda-foundation-'))
          .toList();
      final survey = foods
          .where((f) => f.id.startsWith('usda-fndds-'))
          .toList();
      expect(foundation, hasLength(308));
      expect(survey, hasLength(3255));
      expect(foods, hasLength(11361));
      for (final food in [...foundation, ...survey]) {
        expect(food.hasNutritionData, isTrue);
        expect(food.fdcId, isNotNull);
        expect(food.dataSource, FoodDataSource.usda);
        expect(food.sourceLabel, contains('${food.fdcId}'));
        expect(food.originalName, isNotEmpty);
      }
      expect(
        foundation.every((f) => f.sourceLabel.contains('04/2026')),
        isTrue,
      );
      expect(survey.every((f) => f.sourceLabel.contains('2021–2023')), isTrue);
      expect(
        survey.every(
          (f) => !f.ingredientsKnown && f.dietaryClass == FoodDietClass.unknown,
        ),
        isTrue,
      );
      final tomato = foundation.singleWhere((f) => f.fdcId == 321360);
      expect(tomato.nutritionPer100g.kcal, 27);
      expect(tomato.sourceLabel, contains('công bố 01/04/2019'));
      final saved = MealItemSnapshot.fromData(
        MealItemSnapshot.fromCatalog(tomato, 200).toData(),
      );
      expect(saved.foodId, tomato.id);
      expect(saved.sourceLabel, tomato.sourceLabel);
      expect(saved.nutrition.kcal, 54);
      expect(
        foods.singleWhere((f) => f.id == 'banana-raw').nutritionPer100g.kcal,
        89,
      );
      expect(searchFoodCatalog(foods, 'pho bo').first.id, 'vn-pho-bo');
    },
  );

  test('each optional dataset fails independently', () async {
    final base = await rootBundle.loadString(
      'assets/nutrition/vietnamese-foods.json',
    );
    final legacy = await rootBundle.loadString(
      'assets/nutrition/usda-sr-legacy.json',
    );
    final current = await rootBundle.loadString(
      'assets/nutrition/usda-current.json',
    );
    for (final corrupt in ['', '{invalid', '{"foods":[{"id":null}]}']) {
      expect(
        decodeBundledFoodCatalog([base, legacy, corrupt]),
        hasLength(7798),
      );
      final withoutLegacy = decodeBundledFoodCatalog([base, corrupt, current]);
      expect(withoutLegacy, hasLength(3917));
      expect(
        withoutLegacy.any((f) => f.id == 'usda-foundation-321360'),
        isTrue,
      );
    }
    final historical = decodeBundledFoodCatalog([base, legacy]);
    final expanded = decodeBundledFoodCatalog([base, legacy, current]);
    final byId = {for (final food in expanded) food.id: food};
    for (final original in historical) {
      final retained = byId[original.id]!;
      expect(retained.name, original.name);
      expect(retained.sourceLabel, original.sourceLabel);
      expect(
        MealItemSnapshot.fromCatalog(retained, 123).toData(),
        MealItemSnapshot.fromCatalog(original, 123).toData(),
      );
    }
  });

  test('equally relevant USDA results prefer current references', () {
    FoodCatalogItem fixture(String id, [String name = 'Cà chua']) =>
        FoodCatalogItem(
          id: id,
          name: name,
          category: 'Rau củ',
          servingBasis: ServingBasis.per100g,
          sourceLabel: 'Fixture',
          isEstimated: true,
        );
    final foods = [
      fixture('usda-sr-1'),
      fixture('usda-fndds-2'),
      fixture('usda-foundation-3'),
    ]..sort(compareCatalogFoods);
    expect(searchFoodCatalog(foods, 'ca chua').map((f) => f.id), [
      'usda-foundation-3',
      'usda-fndds-2',
      'usda-sr-1',
    ]);
    // A precise identity match still wins over a merely partial current match.
    final exact = [
      fixture('usda-foundation-3', 'Cà chua sống'),
      fixture('usda-sr-1'),
    ]..sort(compareCatalogFoods);
    expect(searchFoodCatalog(exact, 'ca chua').first.id, 'usda-sr-1');
  });
}
