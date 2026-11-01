import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/food_scanner/data/food_image_picker.dart';
import 'package:healthmate/features/food_scanner/data/food_scanner_service.dart';
import 'package:healthmate/features/food_scanner/models/ai_food_suggestion.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/food_library/models/food_library_models.dart';
import 'package:healthmate/features/food_library/presentation/library_forms.dart';
import 'package:healthmate/features/food_scanner/presentation/food_scanner_dialog.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_food_library_repository.dart';
import 'support/test_app.dart';

class _Picker implements FoodImagePicker {
  FoodImage? image = FoodImage(
    bytes: Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
      ),
    ),
    mimeType: 'image/png',
  );
  Object? error;
  int calls = 0;
  @override
  Future<FoodImage?> pick(ImageSource source) async {
    calls++;
    if (error != null) throw error!;
    return image;
  }
}

class _Scanner implements FoodScannerService {
  AiFoodSuggestion? result;
  Object? error;
  Completer<AiFoodSuggestion>? pending;
  int calls = 0;
  @override
  Future<AiFoodSuggestion> analyze({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    calls++;
    if (error != null) throw error!;
    if (pending != null) return pending!.future;
    return result ??
        const AiFoodSuggestion(
          dishName: 'Cơm trắng chín',
          description: 'Một phần cơm.',
          ingredients: ['gạo'],
          searchTerms: ['cơm trắng'],
        );
  }
}

class _EmptyCatalog extends FakeNutritionRepository {
  @override
  Stream<List<FoodCatalogItem>> watchFoodCatalog() => Stream.value(const []);
}

class _Catalog extends FakeNutritionRepository {
  _Catalog(this.foods);
  final List<FoodCatalogItem> foods;
  @override
  Stream<List<FoodCatalogItem>> watchFoodCatalog() => Stream.value(foods);
}

Future<void> _visibleTap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty &&
      find.byKey(const ValueKey('scanner-content')).evaluate().isNotEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('scanner-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _open(
  WidgetTester tester,
  _Picker picker,
  _Scanner scanner, {
  FakeNutritionRepository? nutrition,
  FakeAuthRepository? auth,
  FakeFoodLibraryRepository? library,
}) async {
  final container = await pumpApp(
    tester,
    featureFlags: const AppFeatureFlags(foodScannerEnabled: true),
    foodImagePicker: picker,
    foodScannerService: scanner,
    nutritionRepository: nutrition,
    repository: auth,
    libraryRepository: library,
  );
  container.read(appRouterProvider).go(AppRoutes.journal);
  await tester.pumpAndSettle();
  await _visibleTap(tester, find.byKey(const ValueKey('journal-add-meal')));
  await _visibleTap(tester, find.byKey(const ValueKey('meal-entry-photo')));
}

Future<void> _chooseAndConsent(WidgetTester tester) async {
  await _visibleTap(
    tester,
    find.byKey(const ValueKey('camera-gallery')).evaluate().isNotEmpty
        ? find.byKey(const ValueKey('camera-gallery'))
        : find.text('Chọn ảnh'),
  );
  final button = tester.widget<FilledButton>(
    find.byKey(const ValueKey('analyze-food-image')),
  );
  expect(button.onPressed, isNull);
  await _visibleTap(
    tester,
    find.byKey(const ValueKey('scanner-processing-consent')),
  );
}

Future<void> _expectSelectedMeal(
  WidgetTester tester,
  String name,
  String grams,
  String kcal,
) async {
  await openSelectedMealItems(tester);
  final row = find.byKey(const ValueKey('selected-meal-item-0'));
  await tester.scrollUntilVisible(
    row,
    160,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('meal-manual-content')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  expect(find.descendant(of: row, matching: find.text(name)), findsOneWidget);
  expect(
    find.descendant(of: row, matching: find.textContaining('$grams g')),
    findsOneWidget,
  );
  expect(
    find.descendant(of: row, matching: find.textContaining('$kcal kcal')),
    findsOneWidget,
  );
}

void main() {
  const mixedPlate = AiFoodSuggestion(
    dishName: 'Cơm tấm sườn bì chả trứng',
    description: 'Đĩa cơm với sườn, trứng và rau.',
    ingredients: ['Cơm tấm', 'Sườn heo nướng', 'Trứng ốp la', 'Rau'],
    // Broad terms may still arrive from the model or an older response.
    searchTerms: ['cơm', 'cơm trắng', 'sườn', 'trứng'],
    estimatedServingGrams: 450,
    estimatedNutritionPer100g: AiFoodNutrition(
      kcal: 185,
      proteinG: 10.5,
      carbsG: 18.2,
      fatG: 8,
      fiberG: 0.8,
    ),
  );
  testWidgets(
    'mixed plate keeps whole-dish estimate through private save and meal',
    (tester) async {
      final library = FakeFoodLibraryRepository();
      final nutrition = FakeNutritionRepository();
      await _open(
        tester,
        _Picker(),
        _Scanner()..result = mixedPlate,
        nutrition: nutrition,
        library: library,
      );
      await _chooseAndConsent(tester);
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      final target = find.textContaining('Phần 450 g: 832,5 kcal');
      await tester.scrollUntilVisible(
        target,
        150,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('scanner-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(target, findsOneWidget);
      expect(find.text('Nguồn: AI Gemini · Ước tính từ ảnh'), findsOneWidget);
      expect(find.textContaining('Phần 450 g: 47,25 g'), findsOneWidget);
      expect(find.textContaining('Phần 450 g: 36 g'), findsOneWidget);
      expect(find.textContaining('585 kcal'), findsNothing);
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('scanner-save-food')),
      );
      final form = tester.widget<PersonalFoodForm>(
        find.byType(PersonalFoodForm),
      );
      expect(form.initialFood!.name, mixedPlate.dishName);
      expect(form.initialFood!.per100g.kcal, 185);
      expect(form.initialFood!.per100g.proteinG, 10.5);
      expect(form.initialFood!.sourceLabel, contains('AI Gemini'));
      expect(library.saveCalls, 0);
      await tester.tap(find.byKey(const ValueKey('library-save')));
      await tester.pumpAndSettle();
      await _visibleTap(tester, find.text('Xác nhận món đã chọn'));
      await _expectSelectedMeal(tester, mixedPlate.dishName, '450', '833');
      expect(nutrition.addCalls, 0);
      await _visibleTap(tester, find.byKey(const ValueKey('save-meal')));
      expect(nutrition.meals.single.totals.kcal, 832.5);
      expect(nutrition.meals.single.totals.fatG, 36);
    },
  );
  testWidgets(
    'steak and fries preserve AI totals without a whole-dish catalog entry',
    (tester) async {
      await _open(
        tester,
        _Picker(),
        _Scanner()
          ..result = const AiFoodSuggestion(
            dishName: 'Bít tết kèm khoai tây chiên',
            description: 'Thịt bò và khoai chiên.',
            ingredients: ['Thịt bò', 'Khoai tây', 'Dầu ăn'],
            searchTerms: ['bít tết', 'khoai tây'],
            estimatedServingGrams: 350,
            estimatedNutritionPer100g: AiFoodNutrition(
              kcal: 220,
              proteinG: 18,
              carbsG: 15,
              fatG: 10,
              fiberG: 1.5,
            ),
          ),
      );
      await _chooseAndConsent(tester);
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      final target = find.textContaining('Phần 350 g: 770 kcal');
      await tester.scrollUntilVisible(
        target,
        150,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('scanner-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(target, findsOneWidget);
      expect(find.textContaining('Phần 350 g: 63 g'), findsOneWidget);
      expect(find.textContaining('Phần 350 g: 52,5 g'), findsOneWidget);
      expect(find.textContaining('Phần 350 g: 35 g'), findsOneWidget);
      expect(find.textContaining('Phần 350 g: 5,25 g'), findsOneWidget);
    },
  );
  testWidgets(
    'ambiguous whole-dish alias requires explicit catalog selection',
    (tester) async {
      const candidate = FoodCatalogItem(
        id: 'rice-other',
        name: 'Cơm trắng loại khác',
        alternateNames: ['Cơm trắng chín'],
        category: 'Ngũ cốc',
        servingBasis: ServingBasis.per100g,
        per100g: NutritionTotals(kcal: 160),
        sourceLabel: 'Nguồn thử',
        isEstimated: true,
      );
      await _open(
        tester,
        _Picker(),
        _Scanner()
          ..result = const AiFoodSuggestion(
            dishName: 'Cơm trắng chín',
            description: 'Cơm.',
            ingredients: ['gạo'],
            searchTerms: ['cơm'],
            estimatedServingGrams: 200,
            estimatedNutritionPer100g: AiFoodNutrition(kcal: 140),
          ),
        nutrition: _Catalog([FakeNutritionRepository.rice, candidate]),
      );
      await _chooseAndConsent(tester);
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      await _visibleTap(tester, find.text('Tiếp tục nhập thủ công'));
      final meal = tester.widget<MealFormDialog>(find.byType(MealFormDialog));
      expect(meal.suggestedFood, isNull);
    },
  );
  testWidgets(
    'editing dish name clears catalog selection and never reuses old search terms',
    (tester) async {
      await _open(tester, _Picker(), _Scanner());
      await _chooseAndConsent(tester);
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      final name = find.byKey(const ValueKey('scanner-dish-name'));
      await tester.scrollUntilVisible(
        name,
        150,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('scanner-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(name, mixedPlate.dishName);
      await tester.pumpAndSettle();
      await _visibleTap(tester, find.text('Tiếp tục nhập thủ công'));
      final meal = tester.widget<MealFormDialog>(find.byType(MealFormDialog));
      expect(meal.suggestedFood, isNull);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('food-search')))
            .controller!
            .text,
        mixedPlate.dishName,
      );
    },
  );
  const recognized = AiFoodSuggestion(
    dishName: 'Món mới từ ảnh',
    description: 'Món thử nhận diện, có rau.',
    ingredients: ['rau', 'gạo'],
    searchTerms: ['món mới'],
    estimatedServingGrams: 250,
    estimatedNutritionPer100g: AiFoodNutrition(
      kcal: 200,
      proteinG: 8,
      carbsG: 30,
      fatG: 5,
      fiberG: 2,
    ),
  );
  test('AI parsing preserves unknown nutrients and rejects invalid values', () {
    final json = <String, Object?>{
      'dishName': 'Món thử',
      'description': 'Món ăn.',
      'ingredients': ['rau'],
      'searchTerms': ['rau'],
      'isFood': true,
      'estimatedServingGrams': 200,
      'estimatedNutritionPer100g': {
        'kcal': 123,
        'proteinG': null,
        'carbsG': 0,
        'fatG': null,
        'fiberG': null,
      },
    };
    final parsed = AiFoodSuggestion.fromJsonText(jsonEncode(json));
    expect(parsed.estimatedNutritionPer100g!.proteinG, isNull);
    expect(parsed.estimatedNutritionPer100g!.carbsG, 0);
    expect(
      parsed.estimatedNutritionPer100g!.totals!.hasCompleteMacros,
      isFalse,
    );
    for (final value in [-1, 1001, '123']) {
      expect(
        () => AiFoodSuggestion.fromJsonText(
          jsonEncode({
            ...json,
            'estimatedNutritionPer100g': {'kcal': value},
          }),
        ),
        throwsFormatException,
      );
    }
    expect(
      () => AiFoodSuggestion.fromJsonText(
        jsonEncode({...json, 'estimatedServingGrams': 2001}),
      ),
      throwsFormatException,
    );
    final nonFood = AiFoodSuggestion.fromJsonText(
      jsonEncode({...json, 'isFood': false, 'searchTerms': []}),
    );
    expect(nonFood.estimatedNutritionPer100g, isNull);
    expect(nonFood.estimatedServingGrams, isNull);
  });

  testWidgets(
    'unknown scan shows nutrition, saves reviewed private food and confirms grams without logging',
    (tester) async {
      final nutrition = _EmptyCatalog();
      final library = FakeFoodLibraryRepository();
      await _open(
        tester,
        _Picker(),
        _Scanner()..result = recognized,
        nutrition: nutrition,
        library: library,
      );
      await _chooseAndConsent(tester);
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('scanner-save-food')),
      );
      expect(find.byType(PersonalFoodForm), findsOneWidget);
      expect(library.saveCalls, 0);
      expect(nutrition.addCalls, 0);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('library-kcal')))
            .controller!
            .text,
        '200.0',
      );
      await tester.enterText(
        find.byKey(const ValueKey('library-name')),
        'Món đã kiểm tra',
      );
      await tester.tap(find.byKey(const ValueKey('library-save')));
      await tester.pumpAndSettle();
      expect(library.saveCalls, 1);
      expect(library.writtenUids, [FakeAuthRepository.testUser.uid]);
      final saved =
          library.byUid[FakeAuthRepository.testUser.uid]!.values.single
              as PersonalFood;
      expect(saved.per100g.kcal, 200);
      expect(saved.per100g.fiberG, 2);
      expect(saved.isEstimated, isTrue);
      expect(saved.sourceLabel, contains('AI Gemini'));
      expect(nutrition.addCalls, 0);
      await _visibleTap(tester, find.text('Xác nhận món đã chọn'));
      expect(find.byType(MealFormDialog), findsOneWidget);
      await _expectSelectedMeal(tester, saved.name, '250', '500');
      expect(nutrition.addCalls, 0);
      expect(tester.takeException(), isNull);
      await _visibleTap(tester, find.byKey(const ValueKey('save-meal')));
      expect(nutrition.addCalls, 1);
      expect(nutrition.meals.single.items.single.grams, 250);
      expect(nutrition.meals.single.totals.kcal, 500);
      expect(nutrition.meals.single.source, MealSource.aiAssisted);
    },
  );

  testWidgets(
    'private scan save failure retains reviewed values and retries same ID',
    (tester) async {
      final library = FakeFoodLibraryRepository()..failWrite = true;
      await _open(
        tester,
        _Picker(),
        _Scanner()..result = recognized,
        nutrition: _EmptyCatalog(),
        library: library,
      );
      await _chooseAndConsent(tester);
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('scanner-save-food')),
      );
      await tester.tap(find.byKey(const ValueKey('library-save')));
      await tester.pumpAndSettle();
      expect(find.byType(PersonalFoodForm), findsOneWidget);
      expect(find.textContaining('Chưa thể lưu.'), findsOneWidget);
      library.failWrite = false;
      await tester.tap(find.byKey(const ValueKey('library-save')));
      await tester.pumpAndSettle();
      expect(library.savedIds.toSet(), hasLength(1));
      expect(library.byUid[FakeAuthRepository.testUser.uid], hasLength(1));
      expect(find.byType(PersonalFoodForm), findsNothing);
    },
  );

  testWidgets(
    'catalog nutrition takes priority over conflicting AI estimates',
    (tester) async {
      await _open(
        tester,
        _Picker(),
        _Scanner()
          ..result = const AiFoodSuggestion(
            dishName: 'Cơm trắng chín',
            description: 'Một phần cơm.',
            ingredients: ['gạo'],
            searchTerms: ['cơm'],
            estimatedNutritionPer100g: AiFoodNutrition(
              kcal: 999,
              proteinG: 90,
              carbsG: 1,
              fatG: 1,
            ),
            estimatedServingGrams: 150,
          ),
      );
      await _chooseAndConsent(tester);
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      final source = find.text(
        'Nguồn: ${FakeNutritionRepository.rice.sourceLabel}',
      );
      await tester.scrollUntilVisible(
        source,
        150,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('scanner-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        find.textContaining('Năng lượng: 130 kcal / 100 g'),
        findsOneWidget,
      );
      expect(find.textContaining('999 kcal'), findsNothing);
      await _visibleTap(tester, find.byKey(const ValueKey('scanner-use-ai')));
      expect(find.textContaining('999 kcal'), findsOneWidget);
      expect(find.text('Nguồn: AI Gemini · Ước tính từ ảnh'), findsOneWidget);
      await _visibleTap(tester, find.byType(RadioListTile<FoodCatalogItem>));
      await _visibleTap(tester, find.text('Xác nhận món đã chọn'));
      await _expectSelectedMeal(
        tester,
        FakeNutritionRepository.rice.name,
        '150',
        '195',
      );
    },
  );

  testWidgets(
    'unknown scan leaves missing fields empty in private-food review',
    (tester) async {
      final library = FakeFoodLibraryRepository();
      final partial = AiFoodSuggestion(
        dishName: recognized.dishName,
        description: recognized.description,
        ingredients: recognized.ingredients,
        searchTerms: recognized.searchTerms,
        estimatedNutritionPer100g: const AiFoodNutrition(kcal: 120, carbsG: 0),
      );
      await _open(
        tester,
        _Picker(),
        _Scanner()..result = partial,
        nutrition: _EmptyCatalog(),
        library: library,
      );
      await _chooseAndConsent(tester);
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('scanner-save-food')),
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('library-protein')),
            )
            .controller!
            .text,
        isEmpty,
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('library-carbs')))
            .controller!
            .text,
        '0.0',
      );
      await tester.tap(find.byKey(const ValueKey('library-save')));
      await tester.pumpAndSettle();
      expect(library.saveCalls, 0);
      expect(find.byType(PersonalFoodForm), findsOneWidget);
    },
  );

  testWidgets(
    'sign-out closes private scanner review and ignores pending completion',
    (tester) async {
      final library = FakeFoodLibraryRepository()..pending = Completer<void>();
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      await _open(
        tester,
        _Picker(),
        _Scanner()..result = recognized,
        nutrition: _EmptyCatalog(),
        library: library,
        auth: auth,
      );
      await _chooseAndConsent(tester);
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('scanner-save-food')),
      );
      await tester.tap(find.byKey(const ValueKey('library-save')));
      await tester.pump();
      expect(library.saveCalls, 1);
      auth.emitUser(null);
      await tester.pumpAndSettle();
      expect(find.byType(PersonalFoodForm), findsNothing);
      expect(find.byType(FoodScannerDialog), findsNothing);
      library.pending!.complete();
      await tester.pumpAndSettle();
      expect(library.writtenUids, [FakeAuthRepository.testUser.uid]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('non-food scan does not offer nutrition saving', (tester) async {
    await _open(
      tester,
      _Picker(),
      _Scanner()
        ..result = const AiFoodSuggestion(
          dishName: 'Không xác định',
          description: 'Không thấy món ăn.',
          ingredients: [],
          searchTerms: [],
          isFood: false,
        ),
    );
    await _chooseAndConsent(tester);
    await _visibleTap(tester, find.byKey(const ValueKey('analyze-food-image')));
    await _visibleTap(tester, find.text('Tiếp tục nhập thủ công'));
    expect(find.byKey(const ValueKey('scanner-save-food')), findsNothing);
    expect(find.byType(MealFormDialog), findsOneWidget);
  });
  test(
    'prepared images contain pixels rather than original file metadata',
    () async {
      final bytes = _Picker().image!.bytes;
      final prepared = await prepareFoodImage(
        Uint8List.fromList([
          ...bytes,
          ...utf8.encode('GPSLatitude=private-test'),
        ]),
      );
      expect(prepared.mimeType, 'image/png');
      expect(
        utf8.decode(prepared.bytes, allowMalformed: true),
        isNot(contains('GPSLatitude')),
      );
      expect(prepared.bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      for (final invalid in [
        Uint8List(0),
        Uint8List.fromList([1, 2, 3]),
        Uint8List(8 * 1024 * 1024 + 1),
      ]) {
        await expectLater(
          prepareFoodImage(invalid),
          throwsA(isA<FoodScannerFailure>()),
        );
      }
    },
  );
  testWidgets(
    'an empty catalog still permits scanning and manual confirmation',
    (tester) async {
      final repository = _EmptyCatalog();
      await _open(tester, _Picker(), _Scanner(), nutrition: repository);
      await _chooseAndConsent(tester);
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      await _visibleTap(tester, find.text('Tiếp tục nhập thủ công'));
      expect(find.byType(MealFormDialog), findsOneWidget);
      expect(repository.addCalls, 0);
    },
  );
  testWidgets(
    'cancelled picker and denied permission leave a working manual path',
    (tester) async {
      final picker = _Picker()..image = null;
      final scanner = _Scanner();
      await _open(tester, picker, scanner);
      await _visibleTap(tester, find.byKey(const ValueKey('camera-gallery')));
      expect(scanner.calls, 0);
      picker.error = const FoodScannerFailure(
        'Chưa mở được ảnh. Kiểm tra quyền camera.',
      );
      await _visibleTap(tester, find.byKey(const ValueKey('camera-gallery')));
      expect(find.textContaining('Kiểm tra quyền camera'), findsOneWidget);
      expect(scanner.calls, 0);
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      await _visibleTap(tester, find.byKey(const ValueKey('journal-add-meal')));
      expect(find.byType(MealFormDialog), findsOneWidget);
    },
  );

  testWidgets(
    'scanner requires disclosure, shows real result, never saves before confirmation',
    (tester) async {
      final picker = _Picker();
      final scanner = _Scanner();
      final nutrition = FakeNutritionRepository();
      await _open(tester, picker, scanner, nutrition: nutrition);
      await _chooseAndConsent(tester);
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      expect(scanner.calls, 1);
      await tester.scrollUntilVisible(
        find.text('Một phần cơm.'),
        150,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('scanner-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Một phần cơm.'), findsOneWidget);
      expect(nutrition.addCalls, 0);
      await _visibleTap(tester, find.text('Xác nhận món đã chọn'));
      expect(find.byType(MealFormDialog), findsOneWidget);
      expect(nutrition.addCalls, 0);
      expect(find.byKey(const ValueKey('save-meal')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unexpected SDK error is safe and retry succeeds without auto-saving',
    (tester) async {
      final scanner = _Scanner()..error = StateError('private SDK detail');
      await _open(tester, _Picker(), scanner);
      await _chooseAndConsent(tester);
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      expect(find.textContaining('Chưa thể phân tích ảnh'), findsOneWidget);
      expect(find.textContaining('private SDK detail'), findsNothing);
      scanner.error = null;
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      expect(scanner.calls, 2);
      await tester.scrollUntilVisible(
        find.text('Một phần cơm.'),
        150,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('scanner-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Một phần cơm.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'timeout resets scanner and closing while pending discards late response',
    (tester) async {
      final scanner = _Scanner()..pending = Completer<AiFoodSuggestion>();
      await _open(tester, _Picker(), scanner);
      await _chooseAndConsent(tester);
      final analyze = find.byKey(const ValueKey('analyze-food-image'));
      await tester.ensureVisible(analyze);
      await tester.pumpAndSettle();
      await tester.tap(analyze);
      await tester.pump();
      expect(scanner.calls, 1);
      expect(tester.widget<FilledButton>(analyze).onPressed, isNull);
      await tester.pump(const Duration(seconds: 46));
      await tester.pumpAndSettle();
      expect(find.textContaining('quá thời gian chờ'), findsOneWidget);
      await tester.tap(analyze);
      await tester.pump();
      expect(scanner.calls, 2);
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      scanner.pending!.complete(
        const AiFoodSuggestion(
          dishName: 'late',
          description: 'late',
          ingredients: [],
          searchTerms: ['late'],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('late'), findsNothing);
      expect(find.byType(MealFormDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sign-out dismisses scanner and does not retain another account image',
    (tester) async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final scanner = _Scanner()..pending = Completer<AiFoodSuggestion>();
      await _open(tester, _Picker(), scanner, auth: auth);
      await _chooseAndConsent(tester);
      final button = find.byKey(const ValueKey('analyze-food-image'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      auth.emitUser(null);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('scanner-processing-consent')),
        findsNothing,
      );
      expect(find.text('Chào mừng bạn trở lại'), findsOneWidget);
      scanner.pending!.complete(
        const AiFoodSuggestion(
          dishName: 'old account',
          description: 'late',
          ingredients: [],
          searchTerms: ['late'],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('old account'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
