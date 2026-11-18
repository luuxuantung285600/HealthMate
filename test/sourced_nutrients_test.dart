import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/nutrition/data/bundled_vietnamese_foods.dart';
import 'package:healthmate/features/nutrition/models/catalog_food_reader.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<FoodCatalogItem> foods;
  late List<dynamic> raw;
  FoodCatalogItem food(String id) => foods.singleWhere((f) => f.id == id);
  setUpAll(() async {
    foods = await loadBundledVietnameseFoods();
    raw =
        (jsonDecode(
                  File(
                    'assets/nutrition/vietnamese-foods.json',
                  ).readAsStringSync(),
                )
                as Map)['foods']
            as List;
  });
  test(
    'verified Hảo Hảo packet and ingredient sources reach portion snapshots',
    () {
      final packet = food('hao-hao-tom-chua-cay-75g');
      final totals = packet.forGrams(75);
      expect(totals.totalSugarG, closeTo(4, .000001));
      expect(totals.extraNutrients['sodium'], closeTo(1778, .000001));
      expect(totals.saltEquivalentG, closeTo(4.445, .000001));
      expect(totals.fiberKnown, isFalse);
      final snapshot = MealItemSnapshot.fromCatalog(packet, 75);
      final restored = MealItemSnapshot.fromData(snapshot.toData());
      expect(restored.nutrition.totalSugarG, closeTo(4, .000001));
      expect(restored.nutrition.saltEquivalentG, closeTo(4.445, .000001));
      expect(food('vn2007-4007').nutritionPer100g.extraNutrients['sodium'], 52);
      expect(food('vn2007-4007').nutritionPer100g.totalSugarG, 4.54);
      expect(food('vn2007-4007').nutritionPer100g.fiberKnown, isFalse);
      expect(food('vn2007-7003').nutritionPer100g.totalSugarG, 0);
      expect(food('vn2007-1001').nutritionPer100g.totalSugarG, isNull);
      expect(
        food('mien-phu-huong-ga-53g').nutritionPer100g.totalSugarG,
        isNull,
      );
      expect(food('vn-pho-bo').nutritionPer100g.saltEquivalentG, isNull);
      final rice = food('rice-cooked').forGrams(150);
      expect(rice.fiberG, closeTo(.6, .000001));
      expect(rice.totalSugarG, closeTo(.075, .000001));
      expect(rice.extraNutrients['sodium'], 1.5);
    },
  );
  test(
    'only unchanged legacy catalog documents inherit reviewed extras; explicit admin values win',
    () {
      const id = 'hao-hao-tom-chua-cay-75g';
      final reference = food(id);
      final legacy = Map<String, dynamic>.from(
        raw.singleWhere((r) => r['id'] == id) as Map,
      )..remove('extraNutrientsPer100g');
      FoodCatalogItem read(Map<String, dynamic> data) =>
          readCatalogFood(id, data, referenceFood: reference);
      expect(read(legacy).forGrams(75).totalSugarG, closeTo(4, .000001));
      for (final patch in [
        {'extraNutrientsPer100g': <String, double>{}},
        {'extraNutrientsPer100g': null},
        {'name': 'Tên khác'},
        {'sourceLabel': 'Nguồn khác'},
        {'kcalPer100g': 400},
        {'unit': 'ml'},
        {'servingBasis': 'explicit_serving'},
      ]) {
        expect(
          read({...legacy, ...patch}).nutritionPer100g.totalSugarG,
          isNull,
        );
      }
      expect(
        read({
          ...legacy,
          'extraNutrientsPer100g': {'sodium': 0, 'sugar': 0},
        }).nutritionPer100g.totalSugarG,
        0,
      );
      // Previously saved diaries carry their own missing data, with no lookup.
      final old = MealItemSnapshot.fromCatalog(readCatalogFood(id, legacy), 75);
      expect(
        MealItemSnapshot.fromData(old.toData()).nutrition.totalSugarG,
        isNull,
      );
    },
  );
}
