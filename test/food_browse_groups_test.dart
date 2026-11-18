import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/food_library/presentation/meal_food_sources.dart';
import 'package:healthmate/features/nutrition/data/bundled_vietnamese_foods.dart';
import 'package:healthmate/features/nutrition/models/food_avoidance.dart';
import 'package:healthmate/features/nutrition/models/food_browse_group.dart';
import 'package:healthmate/features/nutrition/models/food_diet.dart';
import 'package:healthmate/features/nutrition/models/food_visibility.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/food_browse_filter.dart';
import 'package:healthmate/features/nutrition/presentation/food_selection_card.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';

import 'support/fake_nutrition_repository.dart';
import 'support/load_icon_font.dart';
import 'support/test_app.dart';

class _Catalog extends FakeNutritionRepository {
  _Catalog(this.foods, {this.visibility = const FoodVisibility()});
  final List<FoodCatalogItem> foods;
  final FoodVisibility visibility;
  @override
  Stream<List<FoodCatalogItem>> watchFoodCatalog() => Stream.value(foods);
  @override
  Stream<FoodVisibility> watchFoodVisibility() => Stream.value(visibility);
}

FoodCatalogItem _fixture(String name, String category, {String? original}) =>
    FoodCatalogItem(
      id: name,
      name: name,
      category: category,
      originalName: original,
      servingBasis: ServingBasis.per100g,
      sourceLabel: 'Test fixture',
      isEstimated: true,
    );

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      -240,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('meal-manual-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, FoodBrowseGroup group) async {
  await _tap(tester, find.byKey(const ValueKey('food-groups-menu')));
  await _tap(tester, find.byKey(ValueKey('food-group-menu-${group.name}')));
  expect(
    tester
        .widget<ChoiceChip>(find.byKey(ValueKey('food-group-${group.name}')))
        .selected,
    isTrue,
  );
  expect(
    find.byKey(ValueKey('food-group-${group.name}')).hitTestable(),
    findsOneWidget,
  );
  final chip = tester.getRect(find.byKey(ValueKey('food-group-${group.name}')));
  final viewport = tester.getRect(
    find.byKey(const ValueKey('food-groups-scroll')),
  );
  expect(chip.left, greaterThanOrEqualTo(viewport.left - 1));
  expect(chip.right, lessThanOrEqualTo(viewport.right + 1));
  final label = tester.renderObject<RenderParagraph>(
    find.descendant(
      of: find.byKey(ValueKey('food-group-${group.name}')),
      matching: find.text(group.label),
    ),
  );
  expect(label.didExceedMaxLines, isFalse);
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.ensureVisible(find.byKey(const ValueKey('food-groups-menu')));
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final picture =
        await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/food-groups-ui/$name.png');
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
    'all ten groups have bundled foods and All retains the entire catalog',
    () {
      expect(FoodBrowseGroup.values, hasLength(10));
      expect(foods.where(FoodBrowseGroup.all.allows), hasLength(11361));
      for (final group in FoodBrowseGroup.values) {
        expect(foods.where(group.allows), isNotEmpty, reason: group.label);
      }
      expect(
        foods
            .where(FoodBrowseGroup.meat.allows)
            .where(FoodBrowseGroup.seafood.allows),
        isEmpty,
      );
      // Write counts from actual data for the implementation report.
      final report = File('build/food-groups-ui/counts.txt');
      report.parent.createSync(recursive: true);
      report.writeAsStringSync(
        [
          for (final group in FoodBrowseGroup.values)
            '${group.label}: ${foods.where(group.allows).length}',
        ].join('\n'),
      );
    },
  );

  test('meat, fish, eggs, vegetables and grains use source categories', () {
    final expected = {
      FoodBrowseGroup.meat: ['vn2007-7003', 'vn2007-7013', 'vn2007-7069'],
      FoodBrowseGroup.seafood: ['vn2007-8003', 'vn2007-8040', 'vn2007-8051'],
      FoodBrowseGroup.eggsDairy: ['vn2007-9001', 'vn2007-9004', 'vn2007-9007'],
      FoodBrowseGroup.vegetables: ['vn2007-2009', 'vn2007-2013', 'vn2007-2014'],
      FoodBrowseGroup.grainsLegumesNuts: ['vn2007-1001', 'rice-cooked'],
    };
    for (final entry in expected.entries) {
      for (final id in entry.value) {
        expect(entry.key.allows(food(id)), isTrue, reason: id);
        if (entry.key != FoodBrowseGroup.meat) {
          expect(FoodBrowseGroup.meat.allows(food(id)), isFalse, reason: id);
        }
        if (entry.key != FoodBrowseGroup.seafood) {
          expect(FoodBrowseGroup.seafood.allows(food(id)), isFalse, reason: id);
        }
      }
    }
  });

  test('dairy can overlap drinks/packaged; plant milk is separate', () {
    final yogurt = food('th-yogurt-natural-100g');
    expect(FoodBrowseGroup.packaged.allows(yogurt), isTrue);
    expect(FoodBrowseGroup.eggsDairy.allows(yogurt), isTrue);
    final milk = food('usda-foundation-746782');
    expect(FoodBrowseGroup.drinks.allows(milk), isTrue);
    expect(FoodBrowseGroup.eggsDairy.allows(milk), isTrue);
    for (final item in [
      food('vn2007-3032'),
      _fixture(
        'Sữa hạnh nhân',
        'Sữa và chế phẩm',
        original: 'Almond milk, plain',
      ),
      _fixture('Sữa yến mạch', 'Món quốc tế', original: 'Oat milk, plain'),
    ]) {
      expect(FoodBrowseGroup.drinks.allows(item), isTrue, reason: item.name);
      expect(
        FoodBrowseGroup.eggsDairy.allows(item),
        isFalse,
        reason: item.name,
      );
    }
    final noodles = food('hao-hao-tom-chua-cay-75g');
    expect(FoodBrowseGroup.packaged.allows(noodles), isTrue);
    expect(FoodBrowseGroup.seafood.allows(noodles), isFalse);
  });

  test(
    'identity fallback avoids sauces, composites, eggplant and fruit names',
    () {
      for (final item in [
        food('vn-pho-bo'),
        food('vn-bun-thit-nuong'),
        food('vn-thit-kho-trung'),
        _fixture('Nước mắm', 'Gia vị', original: 'Fish sauce'),
        _fixture('Súp cá', 'Súp và nước sốt', original: 'Soup, fish'),
        _fixture('Bánh mì cá', 'Món quốc tế', original: 'Fish sandwich, plain'),
        _fixture(
          'Bánh mì gà',
          'Món quốc tế',
          original: 'Chicken fillet sandwich',
        ),
      ]) {
        expect(FoodBrowseGroup.meat.allows(item), isFalse, reason: item.name);
        expect(
          FoodBrowseGroup.seafood.allows(item),
          isFalse,
          reason: item.name,
        );
        expect(
          FoodBrowseGroup.eggsDairy.allows(item),
          isFalse,
          reason: item.name,
        );
      }
      expect(
        FoodBrowseGroup.vietnameseDishes.allows(food('vn-pho-bo')),
        isTrue,
      );
      for (final item in [
        _fixture('Cà tím', 'Món quốc tế', original: 'Eggplant, cooked'),
        _fixture('Quả trứng gà', 'Trái cây'),
      ]) {
        expect(FoodBrowseGroup.eggsDairy.allows(item), isFalse);
      }
      expect(
        FoodBrowseGroup.vegetables.allows(
          _fixture('Cà tím', 'Món quốc tế', original: 'Eggplant, cooked'),
        ),
        isTrue,
      );
      expect(
        FoodBrowseGroup.meat.allows(
          _fixture(
            'Thịt gà',
            'Món quốc tế',
            original: 'Chicken breast, roasted',
          ),
        ),
        isTrue,
      );
      expect(
        FoodBrowseGroup.seafood.allows(
          _fixture('Cá', 'Món quốc tế', original: 'Fish, steamed'),
        ),
        isTrue,
      );
      expect(
        FoodBrowseGroup.vegetables.allows(
          _fixture('Nước ép cà rốt', 'Đồ uống', original: 'Carrot juice'),
        ),
        isFalse,
      );
    },
  );

  for (final config in [
    (ThemeMode.light, 390.0, 1.0, false),
    (ThemeMode.dark, 320.0, 2.0, true),
  ]) {
    final (theme, width, scale, reusable) = config;
    testWidgets('choose meat then seafood and save both, reusable=$reusable', (
      tester,
    ) async {
      final key = GlobalKey();
      await pumpApp(
        tester,
        nutritionRepository: _Catalog(foods),
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
            sourcesBuilder: reusable
                ? (onCatalog, onRecent, onCustom, diet, avoidance) =>
                      MealFoodSources(
                        onCatalog: onCatalog,
                        onRecent: onRecent,
                        onCustom: onCustom,
                        diet: diet,
                        avoidance: avoidance,
                      )
                : null,
            onSave: (draft) async {
              saved = draft;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final chosen = <MealItemSnapshot>[];
      for (final (group, id, grams) in [
        (FoodBrowseGroup.meat, 'vn2007-7003', 120),
        // Raw carp is excluded from discovery until it has an approved photo;
        // retained raw tilapia exercises the same seafood selection and save.
        (FoodBrowseGroup.seafood, 'vn2007-8024', 150),
      ]) {
        await _choose(tester, group);
        expect(
          tester
              .widgetList<FoodSelectionCard>(find.byType(FoodSelectionCard))
              .every((card) => group.allows(food(card.foodId))),
          isTrue,
        );
        final item = food(id);
        await _reveal(tester, find.byKey(const ValueKey('food-search')));
        await tester.enterText(
          find.byKey(const ValueKey('food-search')),
          item.name,
        );
        await tester.pumpAndSettle();
        await _capture(tester, key, '${group.name}-${theme.name}-$scale');
        await _tap(tester, find.byTooltip('Thêm ${item.name}'));
        await tester.ensureVisible(find.byKey(const ValueKey('meal-grams')));
        await tester.enterText(
          find.byKey(const ValueKey('meal-grams')),
          '$grams',
        );
        await _tap(tester, find.text('Xác nhận'));
        chosen.add(MealItemSnapshot.fromCatalog(item, grams.toDouble()));
        await _reveal(tester, find.byKey(const ValueKey('food-search')));
        await _tap(tester, find.byKey(const ValueKey('clear-food-search')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<ChoiceChip>(
                find.byKey(ValueKey('food-group-${group.name}')),
              )
              .selected,
          isTrue,
        );
      }
      await _tap(tester, find.byKey(const ValueKey('save-meal')));
      expect(saved!.items.map((f) => f.foodId), chosen.map((f) => f.foodId));
      expect(
        saved!.items.map((f) => f.nutrition.kcal),
        chosen.map((f) => f.nutrition.kcal),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('every group is reachable at 320px and 200% text via the menu', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(320, 844), textScale: 2);
    var selected = FoodBrowseGroup.all;
    unawaited(
      showDialog<void>(
        context: tester.element(
          find.byKey(const ValueKey('today-date-picker')),
        ),
        builder: (_) => Dialog.fullscreen(
          child: Scaffold(
            body: StatefulBuilder(
              builder: (_, setState) => FoodBrowseFilter(
                value: selected,
                onChanged: (group) => setState(() => selected = group),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final group in FoodBrowseGroup.values.reversed) {
      await _choose(tester, group);
      expect(selected, group);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('groups compose with diet, avoidance and admin visibility', (
    tester,
  ) async {
    await pumpApp(
      tester,
      nutritionRepository: _Catalog(
        foods,
        visibility: const FoodVisibility(hiddenIds: {'vn2007-1001'}),
      ),
    );
    unawaited(
      showDialog<void>(
        context: tester.element(
          find.byKey(const ValueKey('today-date-picker')),
        ),
        builder: (_) => Dialog.fullscreen(
          child: Scaffold(
            body: SingleChildScrollView(
              child: MealFoodSources(
                onCatalog: (_) {},
                onRecent: (_) {},
                onCustom: () {},
                diet: FoodDietPreference.vegan,
                avoidance: FoodAvoidance.fromText('đậu phộng'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _choose(tester, FoodBrowseGroup.grainsLegumesNuts);
    final shown = tester
        .widgetList<FoodSelectionCard>(find.byType(FoodSelectionCard))
        .toList();
    expect(shown, isNotEmpty);
    expect(shown.any((card) => card.foodId == 'vn2007-1001'), isFalse);
    for (final card in shown) {
      final item = food(card.foodId);
      expect(FoodBrowseGroup.grainsLegumesNuts.allows(item), isTrue);
      expect(FoodDietPreference.vegan.allows(item), isTrue);
      expect(FoodAvoidance.fromText('đậu phộng').allows(item), isTrue);
    }
    await _choose(tester, FoodBrowseGroup.meat);
    expect(find.byType(FoodSelectionCard), findsNothing);
    await _choose(tester, FoodBrowseGroup.seafood);
    expect(find.byType(FoodSelectionCard), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
