import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/food_library/presentation/meal_food_sources.dart';
import 'package:healthmate/features/nutrition/data/bundled_vietnamese_foods.dart';
import 'package:healthmate/features/nutrition/data/unified_food_search_service.dart';
import 'package:healthmate/features/nutrition/models/food_browse_group.dart';
import 'package:healthmate/features/nutrition/models/food_browse_index.dart';
import 'package:healthmate/features/nutrition/models/food_catalog_search.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/food_selection_card.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/nutrition/presentation/meal_search_controller.dart';

import 'meal_search_controller_test.dart' show PendingSearch;
import 'support/fake_nutrition_repository.dart';
import 'support/load_icon_font.dart';
import 'support/test_app.dart';

class _Catalog extends FakeNutritionRepository {
  _Catalog(this.foods);
  final List<FoodCatalogItem> foods;
  @override
  Stream<List<FoodCatalogItem>> watchFoodCatalog() => Stream.value(foods);
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      -250,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('meal-manual-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await _reveal(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  final search = find.byKey(const ValueKey('food-search'));
  await _reveal(tester, search);
  await Scrollable.ensureVisible(tester.element(search), alignment: 0);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final context = tester.element(find.byType(MealFormDialog));
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, context);
    }
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final picture =
        await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/fruit-drink-ui/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    picture.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<FoodCatalogItem> foods;
  FoodCatalogItem food(String id) => foods.singleWhere((f) => f.id == id);
  setUpAll(() async {
    foods = await loadBundledVietnameseFoods();
    await loadIconFont();
    final font = FontLoader('Public Sans');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(
        rootBundle.load('assets/fonts/public_sans/PublicSans-$weight.ttf'),
      );
    }
    await font.load();
  });

  test(
    '100 distinct reviewed fruits and 100 drinks are available, searchable and selectable',
    () {
      final source =
          jsonDecode(
                File(
                  'data/food_catalog/fruit-drink-browse.json',
                ).readAsStringSync(),
              )
              as Map;
      final groups = source['groups'] as Map;
      expect(foodBrowseIndex, hasLength(200));
      for (final group in [FoodBrowseGroup.fruits, FoodBrowseGroup.drinks]) {
        final rows = groups[group.name] as List;
        expect(rows, hasLength(100));
        final eligible = foods.where(group.allows).toList()
          ..sort(group.compare);
        expect(eligible.take(100).map((f) => f.id), rows.map((r) => r['id']));
        for (final row in rows) {
          final item = food(row['id'] as String);
          expect(item.name, row['name']);
          expect(item.hasNutritionData, isTrue, reason: item.id);
          expect(item.nutritionPer100g.hasCompleteMacros, isTrue);
          expect(
            searchFoodCatalog(eligible, item.name).any((f) => f.id == item.id),
            isTrue,
          );
          final snapshot = MealItemSnapshot.fromCatalog(item, 123);
          expect(
            MealItemSnapshot.fromData(snapshot.toData()).nutrition.kcal,
            closeTo(item.nutritionPer100g.kcal * 1.23, .000001),
          );
        }
      }
    },
  );

  test(
    'juice is separate from fruit; milk, coconut water are drinks; sauces and soups stay out',
    () {
      for (final id in [
        'vn2007-14005',
        'usda-sr-170174',
        'usda-foundation-746782',
        'usda-sr-169109',
      ]) {
        expect(FoodBrowseGroup.drinks.allows(food(id)), isTrue, reason: id);
        expect(FoodBrowseGroup.fruits.allows(food(id)), isFalse);
      }
      FoodCatalogItem fixture(
        String name,
        String category, [
        String? original,
      ]) => FoodCatalogItem(
        id: name,
        name: name,
        category: category,
        originalName: original,
        servingBasis: ServingBasis.per100g,
        sourceLabel: 'Fixture',
        isEstimated: true,
      );
      for (final item in [
        fixture('Nước mắm', 'Gia vị'),
        fixture('Phở nước', 'Món ăn Việt'),
        fixture('Soup', 'Súp và nước sốt', 'Soup, tomato, with juice'),
        fixture('Peaches', 'Trái cây', 'Peaches, canned, juice pack'),
        fixture('Milk powder', 'Sữa', 'Milk, dry, nonfat'),
        fixture('Coffee candy', 'Đồ ngọt', 'Candies, coffee'),
      ]) {
        expect(FoodBrowseGroup.drinks.allows(item), isFalse, reason: item.name);
      }
      expect(FoodBrowseGroup.fruits.allows(food('usda-sr-169090')), isTrue);
      expect(food('usda-sr-169090').name, contains('đóng hộp ngâm siro'));
    },
  );

  test(
    'source portions use their actual gram weights and unknown nutrients stay unknown',
    () {
      final coconut = food('usda-sr-170174');
      expect(coconut.servingGrams, 240);
      expect(
        coconut.forGrams(240).kcal,
        closeTo(coconut.nutritionPer100g.kcal * 2.4, .000001),
      );
      final coffee = food('usda-sr-171890');
      expect(coffee.servingLabel, contains('cốc'));
      expect(coffee.servingGrams, 237);
      expect(food('vn2007-14008').nutritionPer100g.totalSugarG, 0);
      expect(food('vn2007-5010').nutritionPer100g.totalSugarG, isNull);
      expect(food('vn2007-5056').nutritionPer100g.fiberKnown, isFalse);
      expect(food('vn2007-14007').forGrams(200).extraNutrients['sodium'], 538);
    },
  );

  test(
    'group changes cancel pending searches/details and reject late results',
    () async {
      final service = PendingSearch();
      var group = FoodBrowseGroup.all;
      final fruit = food('vn2007-5003'), drink = food('vn2007-14005');
      final controller = MealSearchController(
        service: () => service,
        catalog: () => [fruit, drink].where(group.allows).toList(),
        query: () => 'cam',
        currentUid: () => 'alice',
        isActive: () => true,
        canSearch: () => true,
        allows: (item) => group.allows(item),
        onChanged: () {},
        debounce: const Duration(days: 1),
      );
      addTearDown(controller.dispose);
      final old = controller.search();
      group = FoodBrowseGroup.fruits;
      controller.changed();
      expect(service.requests.first.isActive, isFalse);
      service.searches.first.complete(
        FoodSearchOutcome([
          FoodSearchResult(food: drink, source: FoodResultSource.usdaApi),
        ]),
      );
      await old;
      expect(
        controller.state.results.every((r) => group.allows(r.food)),
        isTrue,
      );
      final current = controller.search();
      service.searches.last.complete(
        FoodSearchOutcome([
          for (final f in [fruit, drink])
            FoodSearchResult(food: f, source: FoodResultSource.usdaApi),
        ]),
      );
      await current;
      expect(controller.state.results.single.food.id, fruit.id);
      final detail = controller.resolve(
        FoodSearchResult(
          food: fruit,
          source: FoodResultSource.usdaApi,
          requiresDetail: true,
        ),
      );
      group = FoodBrowseGroup.drinks;
      controller.changed();
      service.details.last.complete(FoodDetailOutcome(fruit));
      expect(await detail, isNull);
    },
  );

  for (final config in [
    (ThemeMode.light, 390.0, 1.0),
    (ThemeMode.dark, 390.0, 1.0),
    (ThemeMode.dark, 320.0, 2.0),
  ]) {
    final (theme, width, scale) = config;
    testWidgets(
      'browse fruit/drink and retain chosen snapshots $theme $width x$scale',
      (tester) async {
        final key = GlobalKey();
        await pumpApp(
          tester,
          size: Size(width, 844),
          textScale: scale,
          initialThemeMode: theme,
          captureKey: key,
        );
        MealDraft? saved;
        unawaited(
          showDialog<void>(
            context: tester.element(
              find.byKey(const ValueKey('today-date-picker')),
            ),
            builder: (_) => MealFormDialog(
              catalog: foods,
              onSave: (draft) async {
                saved = draft;
                return true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _tap(tester, find.byKey(const ValueKey('food-group-fruits')));
        final firstFruit = food('vn2007-5001');
        await _reveal(tester, find.byTooltip('Thêm ${firstFruit.name}'));
        await _capture(tester, key, 'fruits-${theme.name}-$scale');
        expect(
          tester
              .widgetList<FoodSelectionCard>(find.byType(FoodSelectionCard))
              .every((w) => FoodBrowseGroup.fruits.allows(food(w.foodId))),
          isTrue,
        );
        await _tap(tester, find.byTooltip('Thêm ${firstFruit.name}'));
        await tester.ensureVisible(find.byKey(const ValueKey('meal-grams')));
        await tester.enterText(find.byKey(const ValueKey('meal-grams')), '200');
        await _tap(tester, find.text('Xác nhận'));
        await _tap(tester, find.byKey(const ValueKey('food-group-drinks')));
        final firstDrink = food('vn2007-3032');
        await _reveal(tester, find.byTooltip('Thêm ${firstDrink.name}'));
        await _capture(tester, key, 'drinks-${theme.name}-$scale');
        await _tap(tester, find.byTooltip('Thêm ${firstDrink.name}'));
        await tester.ensureVisible(find.byKey(const ValueKey('meal-grams')));
        await tester.enterText(find.byKey(const ValueKey('meal-grams')), '250');
        await _tap(tester, find.text('Xác nhận'));
        await _tap(tester, find.byKey(const ValueKey('save-meal')));
        expect(saved!.items.map((i) => i.foodId), [
          firstFruit.id,
          firstDrink.id,
        ]);
        expect(saved!.items[0].nutrition.kcal, firstFruit.forGrams(200).kcal);
        expect(saved!.items[1].nutrition.kcal, firstDrink.forGrams(250).kcal);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'reusable picker filters all sources and finds a reviewed item beyond the first page',
    (tester) async {
      await pumpApp(tester, nutritionRepository: _Catalog(foods));
      FoodCatalogItem? selected;
      unawaited(
        showDialog<void>(
          context: tester.element(
            find.byKey(const ValueKey('today-date-picker')),
          ),
          builder: (_) => Dialog.fullscreen(
            child: Scaffold(
              body: SingleChildScrollView(
                child: MealFoodSources(
                  onCatalog: (f) => selected = f,
                  onRecent: (_) {},
                  onCustom: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('food-group-drinks')));
      final last = food('usda-sr-173210');
      await tester.enterText(
        find.byKey(const ValueKey('food-search')),
        'red bull',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Thêm ${last.name}'));
      expect(selected!.id, last.id);
      expect(tester.takeException(), isNull);
    },
  );
}
