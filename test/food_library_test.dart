import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/router/auth_redirect.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/profile/models/user_profile.dart';
import 'package:healthmate/features/food_library/models/favorite_food.dart';
import 'package:healthmate/features/food_library/models/food_library_models.dart';
import 'package:healthmate/features/food_library/providers/food_library_providers.dart';
import 'package:healthmate/features/food_library/providers/favorite_food_providers.dart';
import 'package:healthmate/features/food_library/presentation/food_library_screen.dart';
import 'package:healthmate/features/food_library/presentation/library_forms.dart';
import 'package:healthmate/features/food_library/presentation/food_portion_dialog.dart';
import 'package:healthmate/features/journal/providers/journal_date_provider.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/models/nutrition_failure.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/nutrition/presentation/custom_food_dialog.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_food_library_repository.dart';
import 'support/fake_favorite_food_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/test_app.dart';

PersonalFood personal({
  String id = 'personal',
  String name = 'Cơm nhà nấu',
  double kcal = 130,
}) => PersonalFood(
  id: id,
  name: name,
  per100g: NutritionTotals(
    kcal: kcal,
    proteinG: 2.69,
    carbsG: 28.17,
    fatG: .28,
  ),
  defaultServingGrams: 150,
  servingLabel: 'bát',
  servingGrams: 150,
);
FoodRecipe recipe({
  String id = 'recipe',
  int rows = 2,
  double yieldGrams = 250,
  double? count = 2.5,
}) => FoodRecipe(
  id: id,
  name: 'Cơm trứng nhà làm',
  ingredients: [
    for (var i = 0; i < rows; i++)
      MealItemSnapshot.fromCatalog(
        i.isEven ? personal().asFood() : FakeNutritionRepository.egg,
        i.isEven ? 150 : 100,
      ),
  ],
  yieldGrams: yieldGrams,
  servingsCount: count,
);
FakeFoodLibraryRepository seeded() {
  final repository = FakeFoodLibraryRepository();
  repository.seed('test-uid', personal());
  repository.seed('test-uid', recipe());
  return repository;
}

Finder get vertical => find
    .byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    )
    .last;
Future<void> reveal(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(target, 220, scrollable: vertical);
  } else {
    await tester.ensureVisible(target);
  }
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder target) async {
  await reveal(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> input(WidgetTester tester, String key, String value) async {
  final finder = find.byKey(ValueKey(key));
  await reveal(tester, finder);
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

Future<void> openJournal(
  WidgetTester tester,
  ProviderContainer container,
) async {
  container.read(appRouterProvider).go(AppRoutes.journal);
  container.read(journalDateProvider.notifier).select(DateTime(2026, 10, 16));
  await tester.pumpAndSettle();
  await tap(tester, find.byKey(const ValueKey('journal-add-meal')));
}

Future<void> fillPersonal(WidgetTester tester) async {
  for (final entry in {
    'library-name': 'Món tự tạo',
    'library-kcal': '130',
    'library-protein': '2,69',
    'library-carbs': '28.17',
    'library-fat': '0,28',
    'library-default-grams': '150',
    'library-serving-label': 'bát',
    'library-serving-grams': '150',
  }.entries) {
    await input(tester, entry.key, entry.value);
  }
}

Future<void> fillOneShot(WidgetTester tester) async {
  for (final entry in {
    'custom-food-name': 'Món riêng một lần',
    'custom-food-kcal': '130',
    'custom-food-protein': '2,69',
    'custom-food-carbs': '28.17',
    'custom-food-fat': '0,28',
  }.entries) {
    await input(tester, entry.key, entry.value);
  }
}

class RejectMealOnce extends FakeNutritionRepository {
  int attempts = 0;
  @override
  Future<String> addMeal({
    required String uid,
    required MealDraft draft,
    String? operationId,
  }) async {
    attempts++;
    if (attempts == 1) throw const NutritionFailure('Bữa chưa lưu được.');
    return super.addMeal(uid: uid, draft: draft, operationId: operationId);
  }
}

class UnknownLibraryAck extends FakeFoodLibraryRepository {
  @override
  Future<void> save(
    String uid,
    LibraryEntry entry, {
    required bool create,
  }) async {
    await super.save(uid, entry, create: create);
    if (saveCalls == 1) {
      throw const FoodLibraryFailure('Chưa nhận xác nhận thư viện.');
    }
  }
}

class DelayedAliceLibrary extends FakeFoodLibraryRepository {
  final delayed = Completer<LibraryEntry?>();
  @override
  Future<LibraryEntry?> load(String uid, FoodSourceKind kind, String id) =>
      uid == 'test-uid' ? delayed.future : super.load(uid, kind, id);
}

void main() {
  setUpAll(() async {
    final fonts = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(
        rootBundle.load('assets/fonts/be_vietnam_pro/BeVietnamPro-$weight.ttf'),
      );
    }
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  test('library deep link survives auth gate as an app-owned destination', () {
    final destination = authRedirect(
      const AsyncData(null),
      Uri.parse(AppRoutes.foodLibrary),
    );
    expect(
      Uri.parse(destination!).queryParameters['from'],
      AppRoutes.foodLibrary,
    );
  });
  test(
    'personal food round trip, namespace and gram scaling do not collide with catalog or old one-shot IDs',
    () {
      final food = personal(id: 'rice-cooked');
      final loaded = PersonalFood.fromData(
        food.id,
        Map<String, dynamic>.from(food.toData()),
      );
      expect(loaded.asFood().id, 'custom:rice-cooked');
      expect(loaded.asFood().forGrams(150).kcal, 195);
      expect(loaded.asFood().servingGrams, 150);
      expect(
        favoriteFoodId(food.id, sourceKind: FoodSourceKind.custom),
        'custom_rice-cooked',
      );
      expect(favoriteFoodId(food.id), 'catalog_rice-cooked');
      expect(
        favoriteFoodId(food.id, sourceKind: FoodSourceKind.recipe),
        'recipe_rice-cooked',
      );
    },
  );
  test(
    'recipe computes all macros from snapshots with independent yield and fractional servings',
    () {
      final value = recipe();
      final loaded = FoodRecipe.fromData(
        value.id,
        Map<String, dynamic>.from(value.toData()),
      );
      expect(loaded.totals.kcal, 350);
      expect(loaded.per100g.kcal, 140);
      expect(loaded.portionGrams, 100);
      final half = MealItemSnapshot.fromCatalog(
        loaded.asFood(),
        loaded.portionGrams! * .5,
      );
      expect(half.nutrition.kcal, 70);
      expect(half.grams, 50);
      expect(half.foodId, 'recipe:recipe');
      expect(
        half.nutrition.proteinG,
        closeTo(loaded.totals.proteinG * .2, 1e-10),
      );
      expect(half.nutrition.carbsG, closeTo(loaded.totals.carbsG * .2, 1e-10));
      expect(half.nutrition.fatG, closeTo(loaded.totals.fatG * .2, 1e-10));
      expect(loaded.toData().containsKey('totalKcal'), isFalse);
    },
  );
  test(
    'library models freeze input lists and never recompute ingredient snapshots from changed source',
    () {
      final aliases = ['cơm'];
      final food = PersonalFood(
        id: 'p',
        name: 'Cơm',
        per100g: personal().per100g,
        alternateNames: aliases,
      );
      aliases.add('new');
      expect(food.alternateNames, ['cơm']);
      final ingredients = [MealItemSnapshot.fromCatalog(food.asFood(), 150)];
      final value = FoodRecipe(
        id: 'r',
        name: 'Công thức',
        ingredients: ingredients,
        yieldGrams: 100,
      );
      ingredients.clear();
      expect(value.totals.kcal, 195);
      expect(() => value.ingredients.clear(), throwsUnsupportedError);
      expect(value.ingredients.single.withGrams(100).nutrition.kcal, 130);
    },
  );
  test(
    'personal validation rejects missing fields, non finite values, bounds and incomplete portion pairs',
    () {
      for (final n in [double.nan, double.infinity, -1.0, 10001.0]) {
        expect(
          () => PersonalFood(
            id: 'p',
            name: 'Món',
            per100g: NutritionTotals(kcal: n),
          ).validate(),
          throwsFormatException,
        );
      }
      for (final data in [
        personal().toData()..remove('fatGPer100g'),
        personal().toData()..['carbsGPer100g'] = '0',
      ]) {
        expect(
          () => PersonalFood.fromData('p', Map<String, dynamic>.from(data)),
          throwsA(anyOf(isA<FormatException>(), isA<TypeError>())),
        );
      }
      expect(
        () => PersonalFood(
          id: 'p',
          name: 'Món',
          per100g: const NutritionTotals(),
          servingLabel: 'bát',
        ).validate(),
        throwsFormatException,
      );
      expect(
        () => PersonalFood(
          id: 'p',
          name: 'Món',
          per100g: const NutritionTotals(),
          servingGrams: 150,
        ).validate(),
        throwsFormatException,
      );
      expect(
        () => PersonalFood(
          id: 'p',
          name: 'Món',
          per100g: const NutritionTotals(),
          defaultServingGrams: 0,
        ).validate(),
        throwsFormatException,
      );
      PersonalFood(
        id: 'p',
        name: 'Món',
        per100g: const NutritionTotals(),
      ).validate();
    },
  );
  test(
    'recipe rejects zero/negative/nonfinite yield count, nested recipes and invalid middle/last ingredient',
    () {
      for (final n in [0.0, -1.0, double.nan, double.infinity, 20001.0]) {
        expect(() => recipe(yieldGrams: n).validate(), throwsFormatException);
      }
      for (final n in [0.0, -1.0, double.nan, double.infinity, 1001.0]) {
        expect(() => recipe(count: n).validate(), throwsFormatException);
      }
      recipe(rows: 6, yieldGrams: 500).validate();
      expect(() => recipe(rows: 7).validate(), throwsFormatException);
      for (final index in [2, 5]) {
        final ingredients = [...recipe(rows: 6).ingredients];
        ingredients[index] = MealItemSnapshot(
          foodId: 'recipe:other',
          name: 'Không lồng',
          grams: 100,
          nutrition: const NutritionTotals(kcal: 100),
          sourceLabel: 'fixture',
          isEstimated: true,
        );
        expect(
          () => FoodRecipe(
            id: 'r',
            name: 'Recipe',
            ingredients: ingredients,
            yieldGrams: 500,
          ).validate(),
          throwsFormatException,
        );
        ingredients[index] = MealItemSnapshot(
          foodId: 'p',
          name: 'NaN',
          grams: 100,
          nutrition: const NutritionTotals(kcal: double.nan),
          sourceLabel: 'fixture',
          isEstimated: true,
        );
        expect(
          () => FoodRecipe(
            id: 'r',
            name: 'Recipe',
            ingredients: ingredients,
            yieldGrams: 500,
          ).validate(),
          throwsFormatException,
        );
      }
      expect(
        () => FoodRecipe(
          id: 'r',
          name: 'Recipe',
          ingredients: [],
          yieldGrams: 100,
        ).validate(),
        throwsFormatException,
      );
    },
  );
  testWidgets(
    'profile library entry opens a real library and personal CRUD preserves retry ID',
    (tester) async {
      final library = FakeFoodLibraryRepository()..failWrite = true;
      final container = await pumpApp(tester, libraryRepository: library);
      container.read(appRouterProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('open-food-library')));
      expect(find.byType(FoodLibraryScreen), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('create-custom')));
      await fillPersonal(tester);
      await tap(tester, find.byKey(const ValueKey('library-save')));
      expect(find.byType(PersonalFoodForm), findsOneWidget);
      expect(library.savedIds, hasLength(1));
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('library-serving-grams')),
            )
            .controller!
            .text,
        '150',
      );
      library.failWrite = false;
      await tap(tester, find.byKey(const ValueKey('library-save')));
      expect(library.savedIds[0], library.savedIds[1]);
      final saved = library.byUid['test-uid']!.values.single;
      expect(saved.asFood().servingGrams, 150);
      await tap(tester, find.byKey(ValueKey('edit-custom-${saved.id}')));
      await input(tester, 'library-name', 'Món đã sửa');
      await tap(tester, find.byKey(const ValueKey('library-save')));
      expect(library.byUid['test-uid']!.values.single.name, 'Món đã sửa');
      await tap(tester, find.byKey(ValueKey('delete-custom-${saved.id}')));
      await tap(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Xóa'),
        ),
      );
      expect(library.byUid['test-uid'], isEmpty);
    },
  );
  testWidgets(
    'portion validates the scaled nutrients against the same meal-item bounds',
    (tester) async {
      final dense = PersonalFood(
        id: 'dense',
        name: 'Fixture đậm đặc',
        per100g: const NutritionTotals(kcal: 10000, proteinG: 500),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: FoodPortionDialog(initial: 150, food: dense.asFood()),
        ),
      );
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Khẩu phần vượt giới hạn lưu'),
        findsOneWidget,
      );
      expect(find.byType(FoodPortionDialog), findsOneWidget);
    },
  );
  testWidgets(
    'recipe form selects catalog and own food, scales grams and saves actual yield',
    (tester) async {
      final library = seeded();
      final container = await pumpApp(tester, libraryRepository: library);
      container.read(appRouterProvider).go(AppRoutes.foodLibrary);
      await tester.pumpAndSettle();
      await tap(tester, find.widgetWithText(ChoiceChip, 'Công thức'));
      await tap(tester, find.byKey(const ValueKey('create-recipe')));
      await input(tester, 'recipe-name', 'Công thức mới');
      await input(tester, 'recipe-yield', '300');
      await input(tester, 'recipe-servings', '1,5');
      for (final own in [false, true]) {
        await tap(tester, find.byKey(const ValueKey('add-ingredient')));
        if (own) {
          await tap(
            tester,
            find.descendant(
              of: find.byType(IngredientPicker),
              matching: find.widgetWithText(ChoiceChip, 'Món của tôi'),
            ),
          );
        }
        await tap(tester, find.text(own ? 'Cơm nhà nấu' : 'Cơm trắng chín'));
        await tester.enterText(find.byKey(const ValueKey('meal-grams')), '150');
        await tap(tester, find.text('Xác nhận'));
      }
      await tap(tester, find.byKey(const ValueKey('library-save')));
      final saved = library.byUid['test-uid']!.values
          .whereType<FoodRecipe>()
          .firstWhere((entry) => entry.id != 'recipe');
      expect(saved.ingredients, hasLength(2));
      expect(saved.totals.kcal, 390);
      expect(saved.yieldGrams, 300);
      expect(saved.portionGrams, 200);
      expect(saved.ingredients.last.foodId, 'custom:personal');
      expect(saved.per100g.kcal, 130);
    },
  );
  for (final kind in [FoodSourceKind.custom, FoodSourceKind.recipe]) {
    testWidgets(
      '$kind adds fractional portion to selected day as a frozen snapshot',
      (tester) async {
        final library = seeded();
        final nutrition = FakeNutritionRepository();
        final container = await pumpApp(
          tester,
          libraryRepository: library,
          nutritionRepository: nutrition,
        );
        await openJournal(tester, container);
        await tap(
          tester,
          find.byKey(
            ValueKey(
              'food-source-${kind == FoodSourceKind.custom ? 'custom' : 'recipes'}',
            ),
          ),
        );
        await tap(
          tester,
          find.byKey(
            ValueKey(
              'choose-${kind.name}-${kind == FoodSourceKind.custom ? 'personal' : 'recipe'}',
            ),
          ),
        );
        await tap(tester, find.byKey(const ValueKey('portion-unit')));
        await tester.enterText(find.byKey(const ValueKey('meal-grams')), '0,5');
        await tap(tester, find.text('Xác nhận'));
        await tap(tester, find.byKey(const ValueKey('save-meal')));
        final saved = nutrition.meals.single;
        expect(saved.dateKey, '2026-10-16');
        expect(saved.items.single.foodId, startsWith('${kind.name}:'));
        expect(
          saved.items.single.grams,
          kind == FoodSourceKind.custom ? 75 : 50,
        );
        expect(saved.totals.kcal, kind == FoodSourceKind.custom ? 97.5 : 70);
        expect(library.saveCalls, 0);
      },
    );
  }
  testWidgets(
    'source list read error retry and cached empty are not claimed as confirmed empty',
    (tester) async {
      final library = FakeFoodLibraryRepository()..failRead = true;
      final container = await pumpApp(tester, libraryRepository: library);
      container.read(appRouterProvider).go(AppRoutes.foodLibrary);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Không coi lỗi là chưa có món'),
        findsOneWidget,
      );
      library.failRead = false;
      library.fromCache = true;
      await tap(tester, find.text('Thử tải lại thư viện'));
      expect(
        find.text('Chưa xác nhận được món phù hợp từ máy chủ.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'favorite loads own source directly beyond first 40, missing and error remain distinguishable',
    (tester) async {
      final library = FakeFoodLibraryRepository();
      for (var i = 0; i < 41; i++) {
        library.seed('test-uid', personal(id: 'food$i', name: 'Món thứ $i'));
      }
      final favorites = FakeFavoriteFoodRepository()
        ..byUid['test-uid'] = {
          'custom_food40': const FavoriteFood(
            sourceId: 'food40',
            sourceKind: FoodSourceKind.custom,
          ),
        };
      final container = await pumpApp(
        tester,
        libraryRepository: library,
        favoriteRepository: favorites,
      );
      await openJournal(tester, container);
      await tap(tester, find.byKey(const ValueKey('food-source-favorites')));
      expect(find.text('Món thứ 40'), findsOneWidget);
      expect(library.loadCalls, 1);
      expect(library.watchCalls, 0);
      library.failRead = true;
      container.invalidate(libraryEntryProvider);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Không coi lỗi là món đã bị xóa'),
        findsOneWidget,
      );
      library.failRead = false;
      library.byUid['test-uid']!.remove('custom:food40');
      await tap(tester, find.text('Thử tải lại nguồn yêu thích'));
      expect(find.text('Món không còn khả dụng: food40'), findsOneWidget);
      await tap(
        tester,
        find.byKey(const ValueKey('remove-favorite-custom_food40')),
      );
      expect(favorites.byUid['test-uid'], isEmpty);
    },
  );
  testWidgets(
    'library list loads next 40 explicitly and filters loaded items without a second query',
    (tester) async {
      final library = FakeFoodLibraryRepository();
      for (var i = 0; i < 41; i++) {
        library.seed('test-uid', personal(id: 'food$i', name: 'Món riêng $i'));
      }
      final container = await pumpApp(tester, libraryRepository: library);
      await openJournal(tester, container);
      await tap(tester, find.byKey(const ValueKey('food-source-custom')));
      expect(find.text('Món riêng 40'), findsNothing);
      await tap(tester, find.byKey(const ValueKey('more-library')));
      expect(find.text('Món riêng 40'), findsOneWidget);
      expect(library.watchCalls, 2);
      await input(tester, 'food-search', 'mon rieng 40');
      expect(find.text('Món riêng 40'), findsOneWidget);
      expect(find.text('Món riêng 39'), findsNothing);
      expect(library.watchCalls, 2);
    },
  );
  testWidgets(
    'private source async A result cannot overwrite B after account switch',
    (tester) async {
      final library = DelayedAliceLibrary();
      library.seed('bob', personal(id: 'same', name: 'Món của B'));
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final profiles = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
      );
      final container = await pumpApp(
        tester,
        repository: auth,
        profileRepository: profiles,
        libraryRepository: library,
      );
      final key = (kind: FoodSourceKind.custom, id: 'same');
      final sub = container.listen(libraryEntryProvider(key), (_, _) {});
      addTearDown(sub.close);
      await tester.pump();
      final p = FakeHealthProfileRepository.testProfile;
      profiles.emitProfile(
        UserProfile(
          uid: 'bob',
          displayName: p.displayName,
          email: 'bob@example.test',
          heightCm: p.heightCm,
          birthDate: p.birthDate,
          healthGoal: p.healthGoal,
          targetWeightKg: p.targetWeightKg,
          onboardingCompletedAt: p.onboardingCompletedAt,
          createdAt: p.createdAt,
          updatedAt: p.updatedAt,
          schemaVersion: p.schemaVersion,
        ),
      );
      auth.emitUser(
        const AuthUser(
          emailVerified: true,
          uid: 'bob',
          email: 'bob@example.test',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(libraryEntryProvider(key)).value!.name,
        'Món của B',
      );
      library.delayed.complete(personal(id: 'same', name: 'Món bí mật của A'));
      await tester.pumpAndSettle();
      expect(
        container.read(libraryEntryProvider(key)).value!.name,
        'Món của B',
      );
      expect(find.text('Món bí mật của A'), findsNothing);
    },
  );
  testWidgets(
    'custom and recipe favorites with same source ID remain independent and idempotent',
    (tester) async {
      final favorites = FakeFavoriteFoodRepository();
      final container = await pumpApp(tester, favoriteRepository: favorites);
      final controller = container.read(
        favoriteFoodControllerProvider.notifier,
      );
      for (final kind in FoodSourceKind.values) {
        expect(
          await controller.setFavorite('same-id', true, sourceKind: kind),
          isTrue,
        );
        expect(
          await controller.setFavorite('same-id', true, sourceKind: kind),
          isTrue,
        );
      }
      expect(
        favorites.byUid['test-uid']!.keys,
        containsAll(['catalog_same-id', 'custom_same-id', 'recipe_same-id']),
      );
      await controller.setFavorite(
        'same-id',
        false,
        sourceKind: FoodSourceKind.custom,
      );
      expect(favorites.byUid['test-uid'], hasLength(2));
    },
  );
  testWidgets(
    'library unknown ack stays open, double tap pending is blocked and retry reuses ID',
    (tester) async {
      final library = UnknownLibraryAck()..pending = Completer<void>();
      final container = await pumpApp(tester, libraryRepository: library);
      container.read(appRouterProvider).go(AppRoutes.foodLibrary);
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('create-custom')));
      await fillPersonal(tester);
      await tester.tap(find.byKey(const ValueKey('library-save')));
      await tester.pump();
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('library-save'))),
      );
      await tester.pump(const Duration(seconds: 20));
      expect(library.saveCalls, 1);
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('library-save')))
            .onPressed,
        isNull,
      );
      library.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(PersonalFoodForm), findsOneWidget);
      expect(find.text('Chưa nhận xác nhận thư viện.'), findsWidgets);
      await tap(tester, find.byKey(const ValueKey('library-save')));
      expect(library.byUid['test-uid'], hasLength(1));
      expect(library.savedIds.first, library.savedIds.last);
    },
  );
  testWidgets(
    'logout discards pending private draft and ignores its late completion',
    (tester) async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final library = FakeFoodLibraryRepository()..pending = Completer<void>();
      final container = await pumpApp(
        tester,
        repository: auth,
        libraryRepository: library,
      );
      container.read(appRouterProvider).go(AppRoutes.foodLibrary);
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('create-custom')));
      await fillPersonal(tester);
      await tester.tap(find.byKey(const ValueKey('library-save')));
      await tester.pump();
      auth.emitUser(null);
      await tester.pumpAndSettle();
      expect(find.byType(PersonalFoodForm), findsNothing);
      library.pending!.complete();
      await tester.pumpAndSettle();
      expect(library.writtenUids, ['test-uid']);
      expect(
        find.text('Đã lưu vào thư viện. Các bữa ăn đã ghi giữ nguyên.'),
        findsNothing,
      );
    },
  );
  testWidgets(
    'explicit library save succeeds while failed meal keeps draft and retries only meal',
    (tester) async {
      final library = FakeFoodLibraryRepository();
      final nutrition = RejectMealOnce();
      final container = await pumpApp(
        tester,
        libraryRepository: library,
        nutritionRepository: nutrition,
      );
      await openJournal(tester, container);
      await tap(tester, find.byKey(const ValueKey('add-custom-food')));
      await fillOneShot(tester);
      await tap(tester, find.byKey(const ValueKey('save-to-library')));
      await tap(tester, find.byKey(const ValueKey('save-custom-food')));
      expect(library.saveCalls, 1);
      expect(
        find.descendant(
          of: find.byType(MealFormDialog),
          matching: find.textContaining('Bữa ăn vẫn là bản nháp'),
        ),
        findsOneWidget,
      );
      await tap(tester, find.byKey(const ValueKey('save-meal')));
      expect(find.byType(MealFormDialog), findsOneWidget);
      expect(nutrition.meals, isEmpty);
      await tap(tester, find.byKey(const ValueKey('save-meal')));
      expect(nutrition.meals, hasLength(1));
      expect(library.saveCalls, 1);
      expect(nutrition.meals.single.items.single.foodId, startsWith('custom:'));
    },
  );
  testWidgets(
    'one-shot default never saves to library and missing macros must be entered',
    (tester) async {
      final library = FakeFoodLibraryRepository();
      final container = await pumpApp(tester, libraryRepository: library);
      await openJournal(tester, container);
      await tap(tester, find.byKey(const ValueKey('add-custom-food')));
      await input(tester, 'custom-food-name', 'Món một lần');
      await input(tester, 'custom-food-kcal', '100');
      await tap(tester, find.byKey(const ValueKey('save-custom-food')));
      expect(find.byType(CustomFoodDialog), findsOneWidget);
      expect(library.saveCalls, 0);
      await fillOneShot(tester);
      await tap(tester, find.byKey(const ValueKey('save-custom-food')));
      expect(library.saveCalls, 0);
      expect(library.byUid, isEmpty);
    },
  );
  for (final width in [360.0, 390.0, 412.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets(
          'C4 library forms keyboard and six ingredients fit $width x$scale dark=$dark',
          (tester) async {
            final library = seeded();
            library.seed('test-uid', recipe(rows: 6, yieldGrams: 500));
            final capture = GlobalKey();
            final container = await pumpApp(
              tester,
              size: Size(width, 800),
              textScale: scale,
              initialThemeMode: dark ? ThemeMode.dark : ThemeMode.light,
              libraryRepository: library,
              captureKey: capture,
            );
            container.read(appRouterProvider).go(AppRoutes.foodLibrary);
            await tester.pumpAndSettle();
            await tap(
              tester,
              find.byKey(const ValueKey('edit-custom-personal')),
            );
            await input(tester, 'library-fat', '0,28');
            tester.view.viewInsets = const FakeViewPadding(bottom: 260);
            await tester.pumpAndSettle();
            expect(
              tester
                  .getBottomRight(find.byKey(const ValueKey('library-save')))
                  .dy,
              lessThanOrEqualTo(540),
            );
            expect(tester.takeException(), isNull);
            if (width == 360 && scale == 1 && !dark) {
              await captureImage(tester, capture, 'personal-light');
            }
            tester.view.resetViewInsets();
            FocusManager.instance.primaryFocus?.unfocus();
            await tester.pumpAndSettle();
            await tap(tester, find.byTooltip('Hủy'));
            await tap(tester, find.widgetWithText(ChoiceChip, 'Công thức'));
            await tap(tester, find.byKey(const ValueKey('edit-recipe-recipe')));
            await input(tester, 'recipe-yield', '500');
            tester.view.viewInsets = const FakeViewPadding(bottom: 260);
            await tester.pumpAndSettle();
            expect(
              tester
                  .getBottomRight(find.byKey(const ValueKey('library-save')))
                  .dy,
              lessThanOrEqualTo(540),
            );
            expect(tester.takeException(), isNull);
            if (width == 390 && scale == 1.5 && dark) {
              await captureImage(tester, capture, 'recipe-dark');
            }
            tester.view.resetViewInsets();
            FocusManager.instance.primaryFocus?.unfocus();
            await tester.pumpAndSettle();
            await tap(tester, find.byKey(const ValueKey('edit-ingredient-5')));
            await tester.enterText(
              find.byKey(const ValueKey('meal-grams')),
              '12,5',
            );
            await tap(tester, find.text('Xác nhận'));
            expect(tester.takeException(), isNull);
            if (width == 412 && scale == 2 && !dark) {
              await captureImage(tester, capture, 'six-ingredients-large');
            }
            await tap(tester, find.byTooltip('Hủy'));
            await openJournal(tester, container);
            await tap(tester, find.byKey(const ValueKey('add-custom-food')));
            await input(tester, 'custom-food-fat', '0');
            tester.view.viewInsets = const FakeViewPadding(bottom: 260);
            await tester.pumpAndSettle();
            expect(
              tester
                  .getBottomRight(
                    find.byKey(const ValueKey('save-custom-food')),
                  )
                  .dy,
              lessThanOrEqualTo(540),
            );
            expect(
              tester
                  .widget<CheckboxListTile>(
                    find.byKey(const ValueKey('save-to-library')),
                  )
                  .value,
              isFalse,
            );
            expect(tester.takeException(), isNull);
            if (width == 412 && scale == 2 && !dark) {
              await captureImage(tester, capture, 'one-shot-large-keyboard');
            }
            addTearDown(tester.view.resetViewInsets);
          },
        );
      }
    }
  }
}

Future<void> captureImage(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await Directory('build/c4-layout').create(recursive: true);
    await File(
      'build/c4-layout/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
  });
}
