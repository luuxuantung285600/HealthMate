import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'support/load_icon_font.dart';
import 'package:healthmate/core/theme/app_icons.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/food_library/presentation/food_portion_dialog.dart';
import 'package:healthmate/features/nutrition/data/bundled_food_photos.dart';
import 'package:healthmate/features/nutrition/data/bundled_vietnamese_foods.dart';
import 'package:healthmate/features/nutrition/models/food_catalog_search.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/food_photo_thumbnail.dart';
import 'package:healthmate/features/nutrition/presentation/food_selection_card.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/test_app.dart';

class _PhotoCatalogRepository extends FakeNutritionRepository {
  _PhotoCatalogRepository(this.foods);
  final List<FoodCatalogItem> foods;
  @override
  Stream<List<FoodCatalogItem>> watchFoodCatalog() => Stream.value(foods);
}

Future<void> _tap(
  WidgetTester tester,
  Finder finder, {
  double delta = 260,
}) async {
  final scroll = find
      .descendant(
        of: find.byKey(const ValueKey('meal-manual-content')),
        matching: find.byType(Scrollable),
      )
      .first;
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, delta, scrollable: scroll);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final context = key.currentContext!;
    for (final provider
        in tester
            .widgetList<Image>(find.byType(Image))
            .map((widget) => widget.image)
            .toSet()) {
      await precacheImage(provider, context);
    }
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final picture = await boundary.toImage(pixelRatio: 2);
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/food-photos/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    picture.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<FoodCatalogItem> foods;
  late Set<String> visibleIds;
  late Map<String, String> scopedNames;
  setUpAll(() async {
    await loadIconFont();
    final scope =
        jsonDecode(
              File(
                'data/food_catalog/photo-coverage-500.json',
              ).readAsStringSync(),
            )
            as Map;
    final ids = (scope['foods'] as List).map((f) => f['id']).toSet();
    scopedNames = {
      for (final row in scope['foods'] as List)
        row['id'] as String: row['name'] as String,
    };
    foods = (await loadBundledVietnameseFoods())
        .where((food) => ids.contains(food.id))
        .toList();
    // These original catalog identities are provided by Firestore, not the
    // bundled reference datasets. Image validation still covers them below.
    expect(ids.difference(foods.map((f) => f.id).toSet()), {
      'chicken-breast-roasted',
      'milk-whole',
      'oatmeal-cooked',
      'salmon-cooked',
      'sweet-potato-boiled',
      'tofu-firm',
    });
    final release =
        jsonDecode(
              File('data/food_catalog/photo-release.json').readAsStringSync(),
            )
            as Map;
    visibleIds = (release['visibleIds'] as List).cast<String>().toSet();
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

  testWidgets(
    'all attributed local photos decode and match the actual food IDs and names',
    (tester) async {
      final manifest =
          jsonDecode(
                File('assets/food_photos/manifest.json').readAsStringSync(),
              )
              as Map;
      final records = manifest['photos'] as List;
      expect(records, hasLength(visibleIds.length));
      expect(records.map((r) => r['foodId']), unorderedEquals(visibleIds));
      expect(records.length, bundledFoodPhotos.length);
      expect(records.map((r) => r['foodId']).toSet().length, records.length);
      await tester.runAsync(() async {
        for (final photo in bundledFoodPhotos.values) {
          final name = scopedNames[photo.foodId]!;
          expect(findFoodPhoto(photo.foodId, name), same(photo));
          expect(
            Uri.parse(photo.sourceUrl).host,
            anyOf(
              'world.openfoodfacts.org',
              'commons.wikimedia.org',
              'www.pexels.com',
              'acecookvietnam.vn',
              'www.flickr.com',
            ),
          );
          expect(Uri.parse(photo.licenseUrl).scheme, 'https');
          expect(photo.author, isNotEmpty);
          expect(
            photo.license,
            anyOf(
              'CC0',
              'Public domain',
              startsWith('CC BY'),
              'Pexels License',
              'Bản quyền nhà sản xuất',
            ),
          );
          final record = records.singleWhere(
            (r) => r['foodId'] == photo.foodId,
          );
          expect(record['assetPath'], photo.assetPath);
          expect(record['sourceUrl'], photo.sourceUrl);
          final bytes = await rootBundle.load(photo.assetPath);
          final codec = await ui.instantiateImageCodec(
            bytes.buffer.asUint8List(),
          );
          final frame = await codec.getNextFrame();
          expect(frame.image.width, 512);
          expect(frame.image.height, 512);
          frame.image.dispose();
          codec.dispose();
        }
      });
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'a rename or a different private food ID cannot reuse an unrelated photo',
    () {
      expect(findFoodPhoto('vn-pho-bo', 'PHỞ BÒ'), isNotNull);
      expect(findFoodPhoto('vn-pho-bo', 'Phở chay'), isNull);
      expect(findFoodPhoto('my-private-food', 'Phở bò'), isNull);
      expect(findFoodPhoto('unknown', 'Không có ảnh'), isNull);
    },
  );

  test('discovery favors Vietnamese dishes while exact search still wins', () {
    final pho = foods.singleWhere((f) => f.id == 'vn-pho-bo');
    final rice = foods.singleWhere((f) => f.id == 'vn2007-1004');
    const overseas = FoodCatalogItem(
      id: 'usda-foundation-fixture',
      name: 'Phở bò',
      category: 'USDA',
      servingBasis: ServingBasis.per100g,
      sourceLabel: 'Test only',
      isEstimated: false,
      dataSource: FoodDataSource.usda,
    );
    final sorted = [rice, overseas, pho]..sort(compareCatalogFoods);
    expect(sorted.first.id, 'vn-pho-bo');
    expect(searchFoodCatalog([overseas, pho], 'pho bo').first.id, 'vn-pho-bo');
    const partial = FoodCatalogItem(
      id: 'vn-partial-search-fixture',
      name: 'Bún bò Huế',
      category: 'Món ăn Việt',
      servingBasis: ServingBasis.per100g,
      sourceLabel: 'Test only',
      isEstimated: true,
    );
    const exact = FoodCatalogItem(
      id: 'usda-sr-fixture',
      name: 'Bún bò',
      category: 'USDA',
      servingBasis: ServingBasis.per100g,
      sourceLabel: 'Test only',
      isEstimated: false,
      dataSource: FoodDataSource.usda,
    );
    expect(searchFoodCatalog([partial, exact], 'bun bo').first.id, exact.id);
    final original = [overseas, rice, pho];
    searchFoodCatalog(original, 'pho');
    expect(original.map((f) => f.id), [overseas.id, rice.id, pho.id]);
  });

  testWidgets('food without a photo keeps the original text-only row', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foodCatalogProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: FoodSelectionCard(
              foodId: 'private-no-photo',
              name: 'Món riêng',
              quantityLabel: '100 g',
              isEstimated: true,
              nutrition: const NutritionTotals(kcal: 120),
              textOnlySummary: '120 kcal / 100 g · Ước tính',
              actions: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('120 kcal / 100 g · Ước tính'), findsOneWidget);
    expect(find.byType(FoodPhotoThumbnail), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(AppIcons.cameraOff), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'photo attribution does not add food; portions still save the catalog snapshot',
    (tester) async {
      final repo = _PhotoCatalogRepository(foods.reversed.toList());
      await pumpApp(
        tester,
        nutritionRepository: repo,
        dashboardNow: DateTime(2026, 11, 10),
      );
      await tester.tap(find.byKey(const ValueKey('quick-add-menu')));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('food-photo-vn-pho-bo')));
      expect(find.byType(FoodPortionDialog), findsOneWidget);
      expect(repo.addCalls, 0);
      await tester.tap(find.byKey(const ValueKey('portion-food-photo')));
      await tester.pumpAndSettle();
      expect(find.text('Trang ảnh gốc'), findsOneWidget);
      expect(find.textContaining('Andy Li'), findsOneWidget);
      expect(find.byType(FoodPortionDialog), findsOneWidget);
      expect(repo.addCalls, 0);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      await _tap(tester, find.byTooltip('Thêm Phở bò'));
      expect(find.byKey(const ValueKey('portion-food-photo')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('meal-grams')), '200');
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      await _tap(
        tester,
        find.byKey(const ValueKey('selected-meal-items')),
        delta: -320,
      );
      final selected = tester.widget<FoodSelectionCard>(
        find.byKey(const ValueKey('selected-meal-item-0')),
      );
      final expected = foods
          .singleWhere((f) => f.id == 'vn-pho-bo')
          .forGrams(200);
      expect(selected.nutrition!.kcal, expected.kcal);
      expect(selected.quantityLabel, '200 g');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('selected-meal-item-0')),
          matching: find.byType(FoodPhotoThumbnail),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('save-meal')));
      await tester.pumpAndSettle();
      expect(repo.addCalls, 1);
      expect(repo.meals.single.items.single.grams, 200);
      expect(repo.meals.single.totals.kcal, expected.kcal);
      expect(
        repo.meals.single.items.single.toData().containsKey('imageUrl'),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'meal photo list ${mode.name} text $scale fits and captures actual catalog',
        (tester) async {
          final key = GlobalKey();
          final repo = _PhotoCatalogRepository(foods.reversed.toList());
          await pumpApp(
            tester,
            size: Size(scale == 2 ? 320 : 390, 844),
            textScale: scale,
            captureKey: key,
            nutritionRepository: repo,
            initialThemeMode: mode,
            dashboardNow: DateTime(2026, 11, 10),
          );
          await tester.tap(find.byKey(const ValueKey('quick-add-menu')));
          await tester.pumpAndSettle();
          final firstCard = tester
              .widgetList<FoodSelectionCard>(find.byType(FoodSelectionCard))
              .first;
          expect(firstCard.foodId, 'vn-pho-bo');
          await tester.ensureVisible(find.byKey(const ValueKey('food-search')));
          await _capture(tester, key, 'meal-${mode.name}-${scale.toInt()}');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
