import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/nutrition/data/bundled_food_photos.dart';
import 'package:healthmate/features/nutrition/data/bundled_vietnamese_foods.dart';
import 'package:healthmate/features/nutrition/models/food_catalog_search.dart';
import 'package:healthmate/features/nutrition/models/catalog_food_reader.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/food_library/presentation/food_portion_dialog.dart';
import 'package:healthmate/features/nutrition/presentation/food_nutrition_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<FoodCatalogItem> foods;
  setUpAll(() async => foods = await loadBundledVietnameseFoods());

  test(
    'all 22 manufacturer variants return label totals for one dry package',
    () {
      final data =
          jsonDecode(File('data/food_catalog/packaged.json').readAsStringSync())
              as Map;
      final packages = (data['foods'] as List).where(
        (f) => f['brand'] == 'Acecook',
      );
      expect(packages, hasLength(22));
      for (final raw in packages) {
        final food = foods.singleWhere((f) => f.id == raw['id']);
        final label = raw['sourceDetails']['nutrientsPerPackage'] as Map;
        final totals = food.forGrams(food.servingGrams!);
        expect(food.hasValidServing, isTrue);
        expect(food.defaultServingGrams, raw['servingGrams']);
        expect(food.servingLabel, startsWith('gói khô'));
        final serverData = Map<String, dynamic>.from(raw as Map)
          ..remove('defaultServingGrams');
        final serverFood = readCatalogFood(food.id, serverData);
        expect(serverFood.defaultServingGrams, raw['servingGrams']);
        expect(
          serverFood.forGrams(serverFood.defaultServingGrams).kcal,
          closeTo(label['kcal'] as num, .00001),
        );
        expect(totals.kcal, closeTo(label['kcal'] as num, .00001));
        expect(totals.proteinG, closeTo(label['proteinG'] as num, .00001));
        expect(totals.carbsG, closeTo(label['carbsG'] as num, .00001));
        expect(totals.fatG, closeTo(label['fatG'] as num, .00001));
        // Only the exact, reviewed packshot may represent a branded variant.
        final photo = findFoodPhoto(food.id, food.name);
        expect(photo, isNotNull);
        if (food.id == 'hao-hao-tom-chua-cay-75g') {
          expect(photo, isNotNull);
          expect(
            photo!.sourceUrl,
            'https://world.openfoodfacts.org/product/8934563138165',
          );
        } else {
          expect(photo!.sourceUrl, raw['sourceUrl']);
          expect(photo.license, 'Bản quyền nhà sản xuất');
          final manifest =
              jsonDecode(
                    File('assets/food_photos/manifest.json').readAsStringSync(),
                  )
                  as Map;
          final record = (manifest['photos'] as List).singleWhere(
            (p) => p['foodId'] == food.id,
          );
          expect(
            record['originalUrl'],
            raw['sourceDetails']['packageImageUrl'],
          );
          expect(record['sourcePhotoKey'], 'manufacturer:${food.id}');
        }
      }
    },
  );

  test(
    'Vietnamese aliases locate exact packaged foods and new home dishes',
    () {
      expect(
        searchFoodCatalog(foods, 'my hao hao').map((f) => f.id),
        contains('hao-hao-tom-chua-cay-75g'),
      );
      expect(
        searchFoodCatalog(foods, 'pho goi de nhat bo').first.id,
        'pho-de-nhat-bo-68g',
      );
      expect(searchFoodCatalog(foods, 'bo kho').first.id, 'vn-bo-kho');
      expect(searchFoodCatalog(foods, 'banh bao').first.id, 'vn-banh-bao');
      final rice = foods.singleWhere((f) => f.id == 'rice-cooked');
      expect(rice.forGrams(150).kcal, closeTo(195, .001));
    },
  );

  testWidgets(
    'one dry packet can be confirmed without treating water as food mass',
    (tester) async {
      final food = foods.singleWhere((f) => f.id == 'hao-hao-tom-chua-cay-75g');
      double? confirmed;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            foodCatalogProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    confirmed = await askFoodGrams(
                      context,
                      initial: food.defaultServingGrams,
                      food: food,
                    );
                  },
                  child: const Text('Chọn gói'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Chọn gói'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Không cộng trọng lượng nước pha'),
        findsOneWidget,
      );
      final field = tester.widget<TextFormField>(
        find.byKey(const ValueKey('meal-grams')),
      );
      expect(double.parse(field.controller!.text), 75);
      await tester.ensureVisible(find.byKey(const ValueKey('portion-unit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('portion-unit')));
      await tester.pumpAndSettle();
      expect(find.text('1 gói khô 75 g = 75 g'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('meal-grams')), '2');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FoodNutritionPanel>(find.byType(FoodNutritionPanel))
            .value
            .kcal,
        closeTo(700, .001),
      );
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(confirmed, 150);
      expect(tester.takeException(), isNull);
    },
  );
}
