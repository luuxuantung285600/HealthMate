import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/nutrition/models/catalog_food_reader.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/models/food_catalog_search.dart';
import 'package:healthmate/features/food_library/presentation/food_portion_dialog.dart';

Map<String, dynamic> data() => {
  'name': 'Phở fixture',
  'servingBasis': 'per_100g',
  'unit': 'g',
  'kcalPer100g': 100,
  'proteinGPer100g': 10,
  'carbsGPer100g': 12,
  'fatGPer100g': 2,
  'servingLabel': 'tô tham khảo',
  'servingGrams': 400,
};

void main() {
  test('old gram catalog and optional metadata are backward compatible', () {
    final old = data()
      ..remove('servingLabel')
      ..remove('servingGrams');
    final food = readCatalogFood('old', old);
    expect(food.hasNutritionData, isTrue);
    expect(food.hasValidServing, isFalse);
    expect(food.servingMetadataInvalid, isFalse);
    expect(food.forGrams(150).kcal, 150);
    final portion = readCatalogFood('new', data());
    expect(portion.hasValidServing, isTrue);
    final snapshot = MealItemSnapshot.fromCatalog(portion, 200);
    final changed = readCatalogFood(
      'new',
      data()
        ..['servingGrams'] = 600
        ..['kcalPer100g'] = 500,
    );
    expect(changed.forGrams(200).kcal, 1000);
    expect(snapshot.nutrition.kcal, 200);
    expect(snapshot.withGrams(100).nutrition.kcal, 100);
  });

  test(
    'broken portions fall back to grams without zeroing known nutrition',
    () {
      for (final patch in [
        {'servingGrams': -1},
        {'servingGrams': 0},
        {'servingGrams': double.nan},
        {'servingGrams': double.infinity},
        {'servingGrams': '400'},
        {'servingLabel': ''},
        {'servingLabel': 3},
        {'servingGrams': null},
        {'servingLabel': null},
      ]) {
        final food = readCatalogFood('bad', {...data(), ...patch});
        expect(food.hasValidServing, isFalse, reason: '$patch');
        expect(food.servingMetadataInvalid, isTrue);
        expect(food.hasNutritionData, isTrue);
        expect(food.forGrams(150).kcal, 150);
      }
      for (final patch in [
        {'unit': 'ml'},
        {'servingBasis': 'per_100ml'},
        {'kcalPer100g': null},
      ]) {
        expect(
          readCatalogFood('bad-base', {...data(), ...patch}).hasNutritionData,
          isFalse,
        );
      }
      expect(
        readCatalogFood('bad-types', {
          'name': 4,
          'alternateNames': 'bad',
        }).hasNutritionData,
        isFalse,
      );
    },
  );

  test(
    'ranking prioritizes exact alias/name then words and preserves old substring hits',
    () {
      FoodCatalogItem f(
        String id,
        String name, [
        List<String> aliases = const [],
      ]) => readCatalogFood(id, {
        ...data(),
        'name': name,
        'alternateNames': aliases,
      });
      final rice = f('brown', 'Cơm gạo lứt'), chicken = f('chicken', 'Cơm gà');
      final alias = f('alias', 'Đĩa gà cơm chín', ['cơm gà xé']);
      final foods = [rice, alias, chicken];
      expect(searchFoodCatalog(foods, 'com ga'), [chicken, alias, rice]);
      expect(searchFoodCatalog(foods, 'ga com'), [alias, chicken]);
      expect(searchFoodCatalog(foods, 'COM GA XE').first, alias);
      expect(searchFoodCatalog(foods, 'pizza'), isEmpty);
      expect(searchFoodCatalog(foods, ''), same(foods));
    },
  );

  for (final scale in [1.0, 1.5, 2.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'fractional portion, reversible units and keyboard scale=$scale dark=$dark',
        (tester) async {
          tester.view.physicalSize = const Size(360, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          double? result;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                foodCatalogProvider.overrideWith(
                  (ref) => Stream.value(const []),
                ),
              ],
              child: MaterialApp(
                theme: ThemeData(
                  brightness: dark ? Brightness.dark : Brightness.light,
                ),
                builder: (_, child) => MediaQuery(
                  data: MediaQueryData(
                    size: const Size(360, 800),
                    textScaler: TextScaler.linear(scale),
                    viewInsets: const EdgeInsets.only(bottom: 200),
                  ),
                  child: child!,
                ),
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () async {
                        result = await askFoodGrams(
                          context,
                          initial: 200,
                          food: readCatalogFood('portion', data()),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.byKey(const ValueKey('portion-unit')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('portion-unit')));
          await tester.pumpAndSettle();
          final amount = find.byKey(const ValueKey('meal-grams'));
          expect(tester.widget<TextFormField>(amount).controller!.text, '0.5');
          await tester.enterText(amount, '0,25');
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Gram'));
          await tester.tap(find.widgetWithText(ChoiceChip, 'Gram'));
          await tester.pumpAndSettle();
          expect(
            double.parse(tester.widget<TextFormField>(amount).controller!.text),
            100,
          );
          await tester.enterText(amount, '-1');
          await tester.tap(find.text('Xác nhận'));
          await tester.pumpAndSettle();
          expect(find.byType(FoodPortionDialog), findsOneWidget);
          await tester.enterText(amount, '100');
          await tester.pumpAndSettle();
          await tester.tap(find.text('Xác nhận'));
          await tester.pumpAndSettle();
          expect(result, 100);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
