import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/food_scanner/data/food_camera_service.dart';
import 'package:healthmate/features/food_scanner/data/food_scanner_service.dart';
import 'package:healthmate/features/food_scanner/models/ai_food_suggestion.dart';
import 'package:healthmate/features/food_scanner/models/barcode_product_models.dart';
import 'package:healthmate/features/food_library/models/favorite_food.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'support/fake_food_camera.dart';
import 'support/fake_favorite_food_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/test_app.dart';

class _Scanner implements FoodScannerService {
  int calls = 0;
  @override
  Future<AiFoodSuggestion> analyze({
    required List<int> bytes,
    required String mimeType,
  }) async {
    calls++;
    return const AiFoodSuggestion(
      dishName: 'Cơm trắng chín',
      description: 'Một phần cơm.',
      ingredients: ['gạo'],
      searchTerms: ['cơm'],
      estimatedServingGrams: 150,
    );
  }
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      150,
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
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _addRice(WidgetTester tester) async {
  await _tap(tester, find.byTooltip('Thêm Cơm trắng chín'));
  await tester.enterText(find.byKey(const ValueKey('meal-grams')), '120');
  await _tap(tester, find.text('Xác nhận'));
}

Future<void> _capture(GlobalKey key, WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('HEALTHMATE_CAPTURE_UNIFIED_MEAL')) return;
  await tester.runAsync(() async {
    final image =
        await (key.currentContext!.findRenderObject() as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      'build/unified-meal-$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/inter/Inter-$weight.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  test(
    'camera serializes initialization, release and next owner; stale capture fails',
    () async {
      final first = FakeFoodCamera()..pendingStart = Completer<void>();
      final second = FakeFoodCamera();
      var n = 0;
      final service = FoodCameraService(
        createSession: () => n++ == 0 ? first : second,
      );
      final opening = service.open();
      await Future<void>.delayed(Duration.zero);
      final releasing = service.release();
      final reopening = service.open();
      expect(first.starts, 1);
      expect(second.starts, 0);
      first.pendingStart!.complete();
      final stale = await opening;
      await releasing;
      final current = await reopening;
      expect(first.closes, 1);
      expect(second.starts, 1);
      await expectLater(
        service.capture(stale),
        throwsA(isA<FoodScannerFailure>()),
      );
      final image = await service.capture(current);
      expect(image.mimeType, 'image/png');
      expect(second.captures, 1);
      await service.release();
      expect(second.closes, 1);
    },
  );

  testWidgets(
    'one draft retains manual item through photo capture, favorites and final save',
    (tester) async {
      final cameras = <FakeFoodCamera>[];
      final service = FoodCameraService(
        createSession: () {
          final c = FakeFoodCamera();
          cameras.add(c);
          return c;
        },
      );
      final nutrition = FakeNutritionRepository();
      final scanner = _Scanner();
      final root = GlobalKey();
      final container = await pumpApp(
        tester,
        featureFlags: const AppFeatureFlags(foodScannerEnabled: true),
        foodCameraService: service,
        nutritionRepository: nutrition,
        foodScannerService: scanner,
        captureKey: root,
        initialThemeMode: ThemeMode.dark,
      );
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('journal-add-meal')));
      await _addRice(tester);
      await _tap(tester, find.byKey(const ValueKey('meal-entry-photo')));
      expect(cameras.single.starts, 1);
      await _capture(root, tester, 'camera');
      await _tap(tester, find.byKey(const ValueKey('camera-shutter')));
      expect(cameras.single.captures, 1);
      expect(cameras.single.closes, 1);
      expect(scanner.calls, 0);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('analyze-food-image')),
            )
            .onPressed,
        isNull,
      );
      await _tap(tester, find.byKey(const ValueKey('meal-entry-favorites')));
      expect(find.textContaining('Chưa có yêu thích.'), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('meal-entry-manual')));
      expect(find.byType(MealFormDialog), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('save-meal')));
      expect(nutrition.meals.single.items.single.grams, 120);
      expect(nutrition.meals.single.totals.kcal, 156);
      expect(nutrition.meals.single.source, MealSource.manual);
      expect(scanner.calls, 0);
    },
  );

  testWidgets(
    'photo barcode handoff closes camera and adds product to same manual meal',
    (tester) async {
      final camera = FakeFoodCamera();
      final nutrition = FakeNutritionRepository();
      final service = FoodCameraService(createSession: () => camera);
      final container = await pumpApp(
        tester,
        featureFlags: const AppFeatureFlags(foodScannerEnabled: true),
        foodCameraService: service,
        nutritionRepository: nutrition,
        barcodeScanner: (_) async {
          expect(camera.closes, 1);
          return const BarcodeMealSelection(
            product: BarcodeProduct(
              barcode: 'test',
              name: 'Sản phẩm thử',
              source: 'Open Food Facts',
              nutrition: NutritionTotals(kcal: 500),
            ),
            quantity: 30,
          );
        },
        foodScannerService: _Scanner(),
      );
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('journal-add-meal')));
      await _addRice(tester);
      await _tap(tester, find.byKey(const ValueKey('meal-entry-photo')));
      await _tap(tester, find.byKey(const ValueKey('camera-barcode')));
      await _tap(tester, find.byKey(const ValueKey('save-meal')));
      expect(nutrition.meals.single.items, hasLength(2));
      expect(nutrition.meals.single.items.last.grams, 30);
      expect(nutrition.meals.single.totals.kcal, 306);
    },
  );

  testWidgets(
    'favorite tab adds existing favorite without dropping manual draft',
    (tester) async {
      final favorites = FakeFavoriteFoodRepository();
      favorites.byUid['test-uid'] = {
        'rice': const FavoriteFood(sourceId: 'rice-cooked'),
      };
      final nutrition = FakeNutritionRepository();
      final container = await pumpApp(
        tester,
        featureFlags: const AppFeatureFlags(foodScannerEnabled: true),
        favoriteRepository: favorites,
        nutritionRepository: nutrition,
      );
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('journal-add-meal')));
      await _addRice(tester);
      await _tap(tester, find.byKey(const ValueKey('meal-entry-favorites')));
      await _tap(tester, find.byTooltip('Thêm Cơm trắng chín'));
      await _tap(tester, find.text('Xác nhận'));
      await _tap(tester, find.byKey(const ValueKey('save-meal')));
      expect(nutrition.meals.single.items, hasLength(2));
      expect(nutrition.meals.single.items.first.grams, 120);
      expect(nutrition.meals.single.totals.kcal, 286);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'camera permissions, lifecycle and tabs fit 360px at text scale $scale',
      (tester) async {
        final cameras = <FakeFoodCamera>[];
        var denied = true;
        final service = FoodCameraService(
          createSession: () {
            final c = FakeFoodCamera();
            if (denied) {
              c.error = const FoodScannerFailure(
                'Chưa cấp quyền camera. Chọn ảnh hoặc nhập tay.',
              );
            }
            cameras.add(c);
            return c;
          },
        );
        final container = await pumpApp(
          tester,
          size: const Size(360, 740),
          textScale: scale,
          featureFlags: const AppFeatureFlags(foodScannerEnabled: true),
          foodCameraService: service,
          foodScannerService: _Scanner(),
        );
        container.read(appRouterProvider).go(AppRoutes.journal);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('journal-add-meal')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('meal-entry-photo')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Chưa cấp quyền camera.'), findsOneWidget);
        expect(find.byKey(const ValueKey('camera-gallery')), findsOneWidget);
        denied = false;
        await _tap(tester, find.text('Thử mở lại camera'));
        expect(cameras.last.starts, 1);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pumpAndSettle();
        expect(cameras.last.closes, 1);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(cameras, hasLength(3));
        await _tap(tester, find.byKey(const ValueKey('meal-entry-manual')));
        expect(cameras.last.closes, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
