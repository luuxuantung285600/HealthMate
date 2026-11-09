import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/nutrition/data/bundled_vietnamese_foods.dart';
import 'package:healthmate/features/nutrition/data/unified_food_search_service.dart';
import 'package:healthmate/features/food_library/models/favorite_food.dart';
import 'package:healthmate/features/nutrition/models/catalog_food_reader.dart';
import 'package:healthmate/features/nutrition/models/food_catalog_search.dart';
import 'package:healthmate/features/nutrition/models/food_diet.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:healthmate/features/nutrition_targets/providers/nutrition_target_providers.dart';
import 'package:healthmate/features/profile/models/personalization_answers.dart';
import 'package:healthmate/features/profile/models/user_profile.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/wellness/models/wellness_models.dart';
import 'package:healthmate/features/wellness/presentation/wellness_screen.dart';
import 'package:healthmate/features/wellness/providers/wellness_providers.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_food_search_service.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_favorite_food_repository.dart';
import 'support/test_app.dart';

UserProfile veganProfile({String avoidFoods = ''}) {
  final p = FakeHealthProfileRepository.testProfile;
  return UserProfile(
    uid: p.uid,
    displayName: p.displayName,
    email: p.email,
    heightCm: p.heightCm,
    birthDate: p.birthDate,
    healthGoal: p.healthGoal,
    targetWeightKg: p.targetWeightKg,
    onboardingCompletedAt: p.onboardingCompletedAt,
    createdAt: p.createdAt,
    updatedAt: p.updatedAt,
    schemaVersion: p.schemaVersion,
    personalization: PersonalizationAnswers({
      'diet': 'vegan',
      'avoidFoods': avoidFoods,
    }),
  );
}

FoodCatalogItem item(String id, FoodDietClass kind) => FoodCatalogItem(
  id: id,
  name: 'Món $id',
  category: 'Test',
  servingBasis: ServingBasis.per100g,
  sourceLabel: 'Fixture',
  isEstimated: true,
  servingLabel: 'phần thử',
  servingGrams: 100,
  dietaryClass: kind,
  ingredientNames: [id],
  ingredientsKnown: kind != FoodDietClass.unknown,
  per100g: const NutritionTotals(kcal: 100, proteinG: 10, carbsG: 10, fatG: 2),
);

class DietCatalogRepository extends FakeNutritionRepository {
  final foods = [
    item('đậu', FoodDietClass.vegan),
    item('trứng', FoodDietClass.vegetarian),
    item('thịt', FoodDietClass.nonVegetarian),
    item('chưa rõ', FoodDietClass.unknown),
  ];
  @override
  Stream<List<FoodCatalogItem>> watchFoodCatalog() => Stream.value(foods);
}

class MissingSupplementBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => rootBundle.load(key);
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    if (key.endsWith('usda-sr-legacy.json') ||
        key.endsWith('usda-current.json')) {
      return Future.error(FlutterError('Missing optional asset'));
    }
    return rootBundle.loadString(key, cache: cache);
  }
}

class DietPendingSearch extends FakeFoodSearchService {
  final pending = <Completer<List<FoodSearchResult>>>[];
  final catalogs = <List<FoodCatalogItem>>[];
  @override
  Future<FoodSearchOutcome> search({
    required String query,
    required List<FoodCatalogItem> firestoreCatalog,
    int limit = 25,
    FoodSearchRequest? request,
    void Function(FoodSearchOutcome)? onProgress,
  }) {
    catalogs.add(firestoreCatalog);
    final gate = Completer<List<FoodSearchResult>>();
    pending.add(gate);
    return gate.future.then(FoodSearchOutcome.new);
  }
}

Future<void> openDietJournal(
  WidgetTester tester, {
  DietPendingSearch? search,
  FakeFavoriteFoodRepository? favorites,
  String avoidFoods = '',
}) async {
  final container = await pumpApp(
    tester,
    profileRepository: FakeHealthProfileRepository(
      profile: veganProfile(avoidFoods: avoidFoods),
    ),
    nutritionRepository: DietCatalogRepository(),
    foodSearchService: search,
    favoriteRepository: favorites,
  );
  container.read(appRouterProvider).go(AppRoutes.journal);
  await tester.pumpAndSettle();
  final add = find.byKey(const ValueKey('add-meal-breakfast'));
  await tester.ensureVisible(add);
  await tester.pumpAndSettle();
  await tester.tap(add);
  await tester.pumpAndSettle();
}

Future<void> selectDiet(
  WidgetTester tester,
  String label, {
  bool settle = true,
}) async {
  Future<void> pumpTransition() async {
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // The online search intentionally remains pending with an animated spinner.
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  // Leave the text field's focus/selection overlay before changing the filter;
  // keep the pending request alive to exercise the stale-response guard.
  FocusManager.instance.primaryFocus?.unfocus();
  await pumpTransition();
  final filter = find.byKey(const ValueKey('food-diet-filter'));
  final form = find.byType(MealFormDialog);
  final manual = find.byKey(const ValueKey('meal-manual-content'));
  final scrollable = form.evaluate().isNotEmpty && manual.evaluate().isNotEmpty
      ? find.descendant(of: manual, matching: find.byType(Scrollable)).first
      : form.evaluate().isNotEmpty
      ? find.descendant(of: form, matching: find.byType(Scrollable)).first
      : find.byType(Scrollable).first;
  if (form.evaluate().isNotEmpty) await openMealTools(tester);
  final options = find.byKey(const ValueKey('meal-diet-options'));
  if (form.evaluate().isNotEmpty && filter.evaluate().isEmpty) {
    await tester.scrollUntilVisible(options, -150, scrollable: scrollable);
    await Scrollable.ensureVisible(tester.element(options), alignment: .2);
    await pumpTransition();
    // A lazy ListView can dispose an offscreen filter while its tile remains
    // expanded. Recheck once visible; tapping the whole expanded tile can hit
    // its DropdownButton instead of the expansion header.
    if (filter.evaluate().isEmpty) {
      await tester.tap(find.text('Bộ lọc món'));
      await pumpTransition();
    }
  }
  await tester.scrollUntilVisible(filter, -150, scrollable: scrollable);
  await Scrollable.ensureVisible(tester.element(filter), alignment: .5);
  await pumpTransition();
  await tester.tap(filter);
  await pumpTransition();
  await tester.tap(find.text(label).last);
  await pumpTransition();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'missing or corrupted supplemental asset retains the base catalog',
    () async {
      final original = await rootBundle.loadString(
        'assets/nutrition/vietnamese-foods.json',
      );
      for (final broken in ['', '{invalid', '{"foods":[{"id":null}]}']) {
        final foods = decodeBundledFoodCatalog([original, broken]);
        expect(foods, hasLength(162));
        expect(foods.every((food) => food.hasNutritionData), isTrue);
        expect(
          foods.every((food) => food.dietaryClass == FoodDietClass.unknown),
          isTrue,
        );
      }
      expect(
        await loadBundledVietnameseFoods(bundle: MissingSupplementBundle()),
        hasLength(162),
      );
    },
  );

  test(
    'expanded asset has unique IDs, complete sourced nutrition and real portions',
    () async {
      final foods = await loadBundledVietnameseFoods();
      expect(foods, hasLength(11169));
      expect(foods.map((f) => f.id).toSet(), hasLength(foods.length));
      expect(foods.where((f) => f.hasValidServing).length, greaterThan(7100));
      expect(
        foods.every((f) => f.hasNutritionData && f.name != 'Món chưa có tên'),
        isTrue,
      );
      final banana = foods.singleWhere((f) => f.id == 'banana-raw');
      expect(banana.nutritionPer100g.kcal, 89);
      expect(FoodDietPreference.vegan.allows(banana), isTrue);
      expect(
        foods.singleWhere((f) => f.id == 'vn2007-6001').dietaryClass,
        FoodDietClass.vegetarian,
      );
      expect(searchFoodCatalog(foods, 'pho bo').first.id, 'vn-pho-bo');
      expect(
        searchFoodCatalog(
          foods,
          'thit ga uc',
        ).any((f) => f.id.startsWith('usda-sr-')),
        isTrue,
      );
      expect(
        foods.singleWhere((f) => f.id == 'vn-pho-bo').forGrams(300).kcal,
        closeTo(238.05, .02),
      );
    },
  );

  testWidgets('normal journal entry uses the saved profile diet', (
    tester,
  ) async {
    await openDietJournal(tester);
    final form = tester.widget<MealFormDialog>(find.byType(MealFormDialog));
    expect(form.initialDiet, FoodDietPreference.vegan);
    // Exercise the actual sourcesBuilder path, not just constructor metadata.
    final field = find.byKey(const ValueKey('food-search'));
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('catalog-food-đậu')), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-food-thịt')), findsNothing);
    expect(find.byKey(const ValueKey('catalog-food-trứng')), findsNothing);
    await tester.enterText(field, 'Món');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('catalog-food-đậu')), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-food-thịt')), findsNothing);
    await selectDiet(tester, 'Tất cả chế độ');
    expect(find.byKey(const ValueKey('catalog-food-thịt')), findsOneWidget);
    expect(find.byKey(const ValueKey('catalog-food-chưa rõ')), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'profile avoidance filters the actual journal sources even in all diets',
    (tester) async {
      await openDietJournal(tester, avoidFoods: 'đậu');
      await selectDiet(tester, 'Tất cả chế độ');
      expect(find.byKey(const ValueKey('catalog-food-đậu')), findsNothing);
      expect(find.byKey(const ValueKey('catalog-food-chưa rõ')), findsNothing);
      expect(find.byKey(const ValueKey('catalog-food-thịt')), findsOneWidget);
      final field = find.byKey(const ValueKey('food-search'));
      await tester.ensureVisible(field);
      await tester.enterText(field, 'Món');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('catalog-food-đậu')), findsNothing);
      expect(find.byKey(const ValueKey('catalog-food-thịt')), findsOneWidget);
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'main search filters external results and rejects an old diet response',
    (tester) async {
      final search = DietPendingSearch();
      await openDietJournal(tester, search: search);
      await selectDiet(tester, 'Tất cả chế độ');
      final field = find.byKey(const ValueKey('food-search'));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, 'Món');
      await tester.pump(const Duration(milliseconds: 350));
      expect(search.pending, hasLength(1));
      await selectDiet(tester, 'Thuần chay', settle: false);
      await tester.pump(const Duration(milliseconds: 350));
      expect(search.pending, hasLength(2));
      expect(
        search.catalogs.last.every(FoodDietPreference.vegan.allows),
        isTrue,
      );
      final foods = DietCatalogRepository().foods;
      search.pending.last.complete([
        for (final food in foods)
          FoodSearchResult(food: food, source: FoodResultSource.usdaApi),
      ]);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('catalog-food-đậu')), findsOneWidget);
      expect(find.byKey(const ValueKey('catalog-food-thịt')), findsNothing);
      expect(find.byKey(const ValueKey('catalog-food-chưa rõ')), findsNothing);
      search.pending.first.complete([
        FoodSearchResult(food: foods[2], source: FoodResultSource.cache),
      ]);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('catalog-food-đậu')), findsOneWidget);
      expect(find.byKey(const ValueKey('catalog-food-thịt')), findsNothing);
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'search failure keeps usable catalog results without exposing provider details',
    (tester) async {
      final search = DietPendingSearch();
      await openDietJournal(tester, search: search);
      final field = find.byKey(const ValueKey('food-search'));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, 'Món');
      await tester.pump(const Duration(milliseconds: 350));
      search.pending.single.completeError(
        StateError('PRIVATE_PROVIDER_DETAIL'),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('catalog-food-đậu')), findsOneWidget);
      expect(find.textContaining('Chưa tìm thêm được món'), findsOneWidget);
      expect(find.textContaining('PRIVATE_PROVIDER_DETAIL'), findsNothing);
      expect(find.text('Thử lại'), findsOneWidget);
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('catalog favorite respects diet while remaining removable', (
    tester,
  ) async {
    final favorites = FakeFavoriteFoodRepository();
    favorites.byUid['test-uid'] = {
      'catalog_thịt': const FavoriteFood(sourceId: 'thịt'),
    };
    await openDietJournal(tester, favorites: favorites);
    await tester.tap(find.byKey(const ValueKey('meal-entry-favorites')));
    await tester.pumpAndSettle();
    final addMeat = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == 'Thêm Món thịt',
    );
    var button = tester.widget<IconButton>(addMeat);
    expect(button.onPressed, isNull);
    expect(find.byKey(const ValueKey('remove-favorite-thịt')), findsOneWidget);
    await selectDiet(tester, 'Tất cả chế độ');
    button = tester.widget<IconButton>(addMeat);
    expect(button.onPressed, isNotNull);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'plan editor filters discovery without discarding existing meal items',
    (tester) async {
      final foods = DietCatalogRepository().foods;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: PlanMealDialog(
            date: DateTime(2026, 10, 27),
            type: MealType.lunch,
            catalog: foods,
            initialDiet: FoodDietPreference.vegan,
            items: [MealItemSnapshot.fromCatalog(foods[2], 120)],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Món thịt'), findsOneWidget);
      expect(find.text('Món đậu'), findsOneWidget);
      expect(find.text('Món trứng'), findsNothing);
      await selectDiet(tester, 'Tất cả chế độ');
      expect(find.text('Món thịt'), findsNWidgets(2));
      expect(find.text('Món trứng'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('planner preview excludes meat and eggs for a vegan profile', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          authSessionProvider.overrideWith(
            (ref) => Stream.value(FakeAuthRepository.testUser),
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(veganProfile()),
          ),
          foodCatalogProvider.overrideWith(
            (ref) => Stream.value([
              item('vn-đậu', FoodDietClass.vegan),
              item('vn-trứng', FoodDietClass.vegetarian),
              item('vn-thịt', FoodDietClass.nonVegetarian),
            ]),
          ),
          plansProvider.overrideWith(
            (ref, start) => Stream.value(<PlannedMeal>[]),
          ),
          weeklyNutritionTargetsProvider.overrideWith((ref, start) async => []),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Consumer(
            builder: (context, ref, child) {
              // The app shell normally keeps session and profile subscribed.
              ref.watch(authSessionProvider);
              ref.watch(userProfileProvider);
              return const Scaffold(body: MealPlannerPanel());
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('suggest-week-plan')));
    await tester.pumpAndSettle();
    expect(find.text('Xem trước gợi ý 7 ngày'), findsOneWidget);
    expect(find.text('Lựa chọn trong hồ sơ: Thuần chay.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(
        ValueKey('suggested-meal-${localDateKey(DateTime.now())}-breakfast'),
      ),
      150,
      scrollable: find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.textContaining('Món vn-đậu'), findsWidgets);
    expect(find.textContaining('Món vn-trứng'), findsNothing);
    expect(find.textContaining('Món vn-thịt'), findsNothing);
    // Cancel the preview: no repository is supplied, so an accidental write
    // would fail this test instead of silently persisting suggested meals.
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(find.text('Xem trước gợi ý 7 ngày'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test(
    'unknown food is excluded from chay; eggs and dairy are excluded from vegan',
    () {
      final foods = [
        for (final kind in FoodDietClass.values) item(kind.name, kind),
      ];
      expect(foods.where(FoodDietPreference.general.allows), hasLength(4));
      expect(
        foods.where(FoodDietPreference.vegetarian.allows).map((f) => f.id),
        ['vegan', 'vegetarian'],
      );
      expect(foods.where(FoodDietPreference.vegan.allows).map((f) => f.id), [
        'vegan',
      ]);
    },
  );

  test(
    'changed server nutrition or identity invalidates inherited dietary classification',
    () {
      final reference = item('source', FoodDietClass.vegan);
      final raw = <String, dynamic>{
        'name': reference.name,
        'sourceLabel': 'Fixture',
        'kcalPer100g': 100,
        'proteinGPer100g': 10,
        'carbsGPer100g': 10,
        'fatGPer100g': 2,
      };
      expect(
        readCatalogFood('source', raw, referenceFood: reference).dietaryClass,
        FoodDietClass.vegan,
      );
      expect(
        readCatalogFood('source', {
          ...raw,
          'name': 'Món có thịt',
        }, referenceFood: reference).dietaryClass,
        FoodDietClass.unknown,
      );
      expect(
        readCatalogFood('source', {
          ...raw,
          'kcalPer100g': 200,
        }, referenceFood: reference).dietaryClass,
        FoodDietClass.unknown,
      );
      expect(
        readCatalogFood('source', {
          ...raw,
          'dietaryClass': 'invalid',
        }).dietaryClass,
        FoodDietClass.unknown,
      );
    },
  );

  for (final scale in [1.0, 1.5]) {
    testWidgets(
      'diet filter starts from preference and restores all results, scale $scale',
      (tester) async {
        final catalog = [
          item('đậu', FoodDietClass.vegan),
          item('trứng', FoodDietClass.vegetarian),
          item('thịt', FoodDietClass.nonVegetarian),
          item('chưa rõ', FoodDietClass.unknown),
        ];
        await tester.pumpWidget(
          testFoodScope(
            MaterialApp(
              locale: const Locale('vi'),
              supportedLocales: const [Locale('vi')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: MealFormDialog(
                catalog: catalog,
                initialDiet: FoodDietPreference.vegan,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byTooltip('Thêm Món đậu'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byTooltip('Thêm Món thịt'), findsNothing);
        expect(find.byTooltip('Thêm Món trứng'), findsNothing);
        expect(find.byTooltip('Thêm Món đậu'), findsOneWidget);
        await selectDiet(tester, 'Tất cả chế độ');
        await tester.scrollUntilVisible(
          find.byTooltip('Thêm Món chưa rõ'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byTooltip('Thêm Món thịt'), findsOneWidget);
        expect(find.byTooltip('Thêm Món chưa rõ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
