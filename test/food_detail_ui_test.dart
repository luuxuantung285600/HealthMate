import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'support/load_icon_font.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/nutrition/data/bundled_vietnamese_foods.dart';
import 'package:healthmate/features/nutrition/models/catalog_food_reader.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/food_nutrition_panel.dart';
import 'package:healthmate/features/nutrition/presentation/food_photo_thumbnail.dart';
import 'package:healthmate/features/nutrition/presentation/food_selection_card.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/food_library/presentation/food_portion_dialog.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/test_app.dart';

class _Catalog extends FakeNutritionRepository {
  _Catalog(this.foods);
  final List<FoodCatalogItem> foods;
  @override
  Stream<List<FoodCatalogItem>> watchFoodCatalog() => Stream.value(foods);
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final picture = await boundary.toImage(pixelRatio: 2);
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/food-detail/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    picture.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<FoodCatalogItem> foods;
  setUpAll(() async {
    await loadIconFont();
    foods = await loadBundledVietnameseFoods();
    final font = FontLoader('Public Sans');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(
        rootBundle.load('assets/fonts/public_sans/PublicSans-$weight.ttf'),
      );
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  test(
    'recipe details use weighed source ingredients and the finished yield',
    () {
      final pho = foods.singleWhere((f) => f.id == 'vn-pho-bo');
      expect(pho.recipeIngredients, hasLength(6));
      final noodle = pho.recipeIngredients.first;
      expect(noodle.foodId, 'vn2007-1013');
      expect(noodle.gramsPer100gYield * 6, closeTo(200, .0001));
      final raw =
          jsonDecode(
                File(
                  'assets/nutrition/vietnamese-foods.json',
                ).readAsStringSync(),
              )
              as Map;
      final row = Map<String, dynamic>.from(
        (raw['foods'] as List).singleWhere((r) => r['id'] == pho.id),
      );
      final catalog = {for (final f in foods) f.id: f};
      final server = readCatalogFood(
        pho.id,
        row,
        ingredientCatalog: catalog,
        referenceFood: pho,
      );
      expect(server.recipeIngredients, hasLength(6));
      final invalid = {
        ...row,
        'sourceDetails': {
          'method': 'recipe_estimate',
          'yieldGrams': 0,
          'ingredients': [],
        },
      };
      expect(
        readCatalogFood(
          pho.id,
          invalid,
          ingredientCatalog: catalog,
          referenceFood: pho,
        ).recipeIngredients,
        isEmpty,
      );
      row.remove('sourceDetails');
      expect(
        readCatalogFood(pho.id, row, referenceFood: pho).recipeIngredients,
        hasLength(6),
      );
      row['name'] = 'Món do admin thay đổi';
      expect(
        readCatalogFood(pho.id, row, referenceFood: pho).recipeIngredients,
        isEmpty,
      );
    },
  );

  testWidgets(
    'tapping the food row opens detail and confirms a snapshot without meal headers',
    (tester) async {
      final repo = _Catalog([foods.singleWhere((f) => f.id == 'vn-pho-bo')]);
      await pumpApp(
        tester,
        nutritionRepository: repo,
        dashboardNow: DateTime(2026, 11, 10),
      );
      await tester.tap(find.byKey(const ValueKey('quick-add-menu')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('meal-type')), findsNothing);
      expect(
        find.descendant(
          of: find.byType(MealFormDialog),
          matching: find.text('Bữa sáng'),
        ),
        findsNothing,
      );
      final card = find.byType(FoodSelectionCard).first;
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: card, matching: find.text('Phở bò')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FoodPortionDialog), findsOneWidget);
      expect(repo.addCalls, 0);
      final field = find.byKey(const ValueKey('meal-grams'));
      await tester.ensureVisible(field);
      await tester.enterText(field, '300');
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(repo.addCalls, 0);
      await tester.tap(find.byKey(const ValueKey('save-meal')));
      await tester.pumpAndSettle();
      expect(repo.meals.single.items.single.grams, 300);
      expect(
        repo.meals.single.totals.kcal,
        closeTo(repo.foods.single.forGrams(300).kcal, .001),
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final config in [
    (false, 390.0, 1.0),
    (true, 390.0, 1.0),
    (true, 320.0, 2.0),
  ]) {
    final (dark, width, scale) = config;
    testWidgets(
      'detail, ingredients and nutrition sheet ${dark ? 'dark' : 'light'} $width x$scale',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        final food = foods.singleWhere((f) => f.id == 'vn-pho-bo');
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              foodCatalogProvider.overrideWith((ref) => Stream.value(const [])),
            ],
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(key: key, child: child!),
              ),
              home: FoodPortionDialog(initial: 600, food: food),
            ),
          ),
        );
        await tester.runAsync(() async {
          final context = tester.element(find.byType(FoodPortionDialog));
          for (final image in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(image.image, context);
          }
        });
        await _capture(
          tester,
          key,
          'detail-${dark ? 'dark' : 'light'}-${scale.toInt()}',
        );
        final field = find.byKey(const ValueKey('meal-grams'));
        await tester.ensureVisible(field);
        await tester.enterText(field, '300');
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FoodNutritionPanel>(find.byType(FoodNutritionPanel))
              .value
              .kcal,
          closeTo(food.forGrams(300).kcal, .001),
        );
        await tester.ensureVisible(find.text('Nguyên liệu tham khảo'));
        await tester.pumpAndSettle();
        expect(find.text('100 g'), findsOneWidget);
        await _capture(
          tester,
          key,
          'ingredients-${dark ? 'dark' : 'light'}-${scale.toInt()}',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('show-food-nutrition')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('show-food-nutrition')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('food-nutrition-sheet')),
          findsOneWidget,
        );
        expect(find.text('238,05 kcal'), findsOneWidget);
        expect(find.text('Muối quy đổi'), findsOneWidget);
        expect(find.text('Chưa có dữ liệu'), findsNWidgets(9));
        await _capture(
          tester,
          key,
          'nutrition-${dark ? 'dark' : 'light'}-${scale.toInt()}',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'partial snapshot never invents macro percentages or ingredients',
    (tester) async {
      const snapshot = MealItemSnapshot(
        foodId: 'quick',
        name: 'Ghi nhanh',
        grams: 100,
        nutrition: NutritionTotals(
          kcal: 200,
          proteinKnown: false,
          carbsKnown: false,
          fatKnown: false,
        ),
        sourceLabel: 'Người dùng nhập',
        isEstimated: true,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            foodCatalogProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: MaterialApp(
            home: FoodPortionDialog(initial: 100, snapshot: snapshot),
          ),
        ),
      );
      expect(find.textContaining('%'), findsNothing);
      expect(find.text('Chưa đủ dữ liệu'), findsNWidgets(3));
      expect(find.text('Nguyên liệu tham khảo'), findsNothing);
      expect(find.byType(FoodPhotoThumbnail), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
