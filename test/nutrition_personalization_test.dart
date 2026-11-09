import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/food_library/presentation/food_portion_dialog.dart';
import 'package:healthmate/features/nutrition/data/bundled_vietnamese_foods.dart';
import 'package:healthmate/features/nutrition/models/food_avoidance.dart';
import 'package:healthmate/features/nutrition/models/food_catalog_search.dart';
import 'package:healthmate/features/nutrition/models/food_diet.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/wellness/models/meal_plan_suggestion.dart';
import 'package:healthmate/features/wellness/models/wellness_models.dart';
import 'package:healthmate/features/wellness/presentation/wellness_screen.dart';

FoodCatalogItem food(
  String id,
  String name, {
  List<String> ingredients = const [],
  bool known = true,
  String? original,
  String category = 'Test',
  double kcal = 200,
}) => FoodCatalogItem(
  id: id,
  name: name,
  originalName: original,
  ingredientNames: ingredients,
  ingredientsKnown: known,
  category: category,
  servingBasis: ServingBasis.per100g,
  sourceLabel: 'Fixture',
  isEstimated: true,
  servingLabel: 'phần',
  servingGrams: 200,
  dietaryClass: FoodDietClass.vegan,
  per100g: NutritionTotals(kcal: kcal, proteinG: 10, carbsG: 30, fatG: 5),
);

final start = DateTime(2026, 10, 27);
const target = NutritionTarget(
  effectiveFromDateKey: '2026-10-27',
  kcalTarget: 2200,
);
final foods = [
  food('vn-com', 'Cơm đậu', ingredients: ['gạo', 'đậu phụ']),
  food('vn-bun', 'Bún rau', ingredients: ['bún gạo', 'rau']),
  food(
    'usda-fruit',
    'Chuối',
    original: 'Bananas, raw',
    category: 'Trái cây',
    kcal: 89,
  ),
];

Widget host(Widget child, {Stream<AuthUser?>? session}) => ProviderScope(
  overrides: [
    // MealFormDialog owns a session-bound draft; widget fixtures must provide
    // that dependency rather than constructing FirebaseAuth without Firebase.
    authSessionProvider.overrideWith(
      (ref) =>
          session ??
          Stream.value(
            const AuthUser(
              uid: 'personalization-fixture',
              email: 'fixture@example.com',
              emailVerified: true,
            ),
          ),
    ),
  ],
  child: MaterialApp(
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: child,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'avoidance supports accented aliases, multiple lines, custom foods and absent answers',
    () {
      final filter = FoodAvoidance.fromText(
        'Dị ứng với sữa; trứng\nđậu phộng và tôm',
      );
      for (final name in [
        'milk',
        'whey',
        'cheese',
        'Egg, boiled',
        'Peanut butter',
        'Tôm hấp',
        'Prawns',
      ]) {
        // Prawns uses a plural custom case below; ingredient unknown must still hide.
        expect(filter.allows(food('x', name, known: false)), isFalse);
      }
      expect(filter.matchesText('milk'), isTrue);
      expect(filter.matchesText('milkshake'), isFalse);
      expect(filter.matchesText('Chicken with butter'), isTrue);
      expect(filter.matchesText('Sữa đậu nành không đường'), isFalse);
      expect(
        FoodAvoidance.fromText('đậu nành').matchesText('Soy milk'),
        isTrue,
      );
      expect(
        FoodAvoidance.fromText(
          'cá',
        ).matchesText('Cà chua, cà tím, cà rốt, cà phê'),
        isFalse,
      );
      expect(
        FoodAvoidance.fromText('trứng').matchesText('Eggplant, raw'),
        isFalse,
      );
      expect(
        FoodAvoidance.fromText('gluten').matchesText('Barley, raw'),
        isTrue,
      );
      expect(FoodAvoidance.fromText('nấm').matchesText('Canh nấm'), isTrue);
      for (final value in [
        null,
        '',
        'Không',
        'không có',
        'Không dị ứng',
        'none',
      ]) {
        expect(FoodAvoidance.fromText(value).isActive, isFalse);
      }
    },
  );

  test(
    'unknown descriptions never count as absence, ingredient lists detect hidden matches',
    () {
      final filter = FoodAvoidance.fromText('sữa');
      expect(
        filter.assess(food('a', 'Bánh', ingredients: ['bột', 'whey'])),
        FoodAvoidanceStatus.containsAvoided,
      );
      expect(
        filter.assess(food('a', 'Bánh', known: false)),
        FoodAvoidanceStatus.unknown,
      );
      expect(filter.assess(food('a', 'Táo')), FoodAvoidanceStatus.noKnownMatch);
      expect(
        filter.flaggedSnapshots([
          MealItemSnapshot.fromCatalog(foods.first, 200),
        ], foods),
        isEmpty,
      );
      expect(
        filter.flaggedSnapshots([
          MealItemSnapshot.fromCatalog(food('private', 'Món riêng'), 100),
        ], foods),
        hasLength(1),
      );
    },
  );

  test(
    'real catalog screens recipe ingredients and serves fresh fruit snacks',
    () async {
      final catalog = await loadBundledVietnameseFoods();
      final soy = FoodAvoidance.fromText('đậu nành');
      expect(
        soy.allows(catalog.singleWhere((f) => f.id == 'vn-com-dau-rau')),
        isFalse,
      );
      expect(
        FoodAvoidance.fromText(
          'tôm',
        ).allows(catalog.singleWhere((f) => f.id == 'vn-hu-tieu')),
        isFalse,
      );
      expect(
        FoodAvoidance.fromText(
          'sữa',
        ).allows(catalog.singleWhere((f) => f.id == 'banana-raw')),
        isTrue,
      );
      final plan = suggestMealPlan(
        start: start,
        catalog: catalog,
        existing: [],
        targets: [target],
        diet: FoodDietPreference.vegan,
        avoidance: FoodAvoidance.fromText('sữa; trứng'),
      );
      expect(plan.drafts, hasLength(28));
      expect(plan.summaries.every((s) => !s.outsideTarget), isTrue);
      for (final draft in plan.drafts.where((d) => d.type == MealType.snack)) {
        expect(draft.items.first.foodId, startsWith('usda-'));
        expect(
          catalog.singleWhere((f) => f.id == draft.items.first.foodId).category,
          'Trái cây',
        );
      }
    },
  );

  test(
    'calorie fitting uses each day target and preserves existing snacks',
    () {
      final fixed = PlannedMeal(
        id: 'fixed',
        date: start,
        type: MealType.snack,
        items: [MealItemSnapshot.fromCatalog(foods.last, 100)],
      );
      final plan = suggestMealPlan(
        start: start,
        catalog: foods,
        existing: [fixed],
        targets: [
          target,
          const NutritionTarget(
            effectiveFromDateKey: '2026-10-30',
            kcalTarget: 2500,
          ),
        ],
      );
      expect(plan.drafts, hasLength(27));
      expect(
        plan.drafts.where(
          (d) => d.consumedAt.day == 27 && d.type == MealType.snack,
        ),
        isEmpty,
      );
      expect(fixed.items.single.grams, 100);
      expect(plan.summaries.first.targetKcal, 2200);
      expect(plan.summaries.last.targetKcal, 2500);
      expect(plan.summaries.every((s) => !s.outsideTarget), isTrue);
      expect(
        plan.drafts.every(
          (d) => d.items.every((i) => i.grams >= 100 && i.grams <= 400),
        ),
        isTrue,
      );
      expect(
        plan.drafts.map((d) => d.items.first.foodId).toSet().length,
        greaterThan(1),
      );
    },
  );

  test(
    'missing and unattainable targets are explicit; existing full day stays untouched',
    () {
      final noTarget = suggestMealPlan(
        start: start,
        catalog: foods,
        existing: [],
        targets: [],
      );
      expect(noTarget.summaries.every((s) => s.targetKcal == null), isTrue);
      expect(
        noTarget.drafts.every((d) => d.items.every((i) => i.grams == 200)),
        isTrue,
      );
      final high = suggestMealPlan(
        start: start,
        catalog: foods,
        existing: [],
        targets: [
          const NutritionTarget(
            effectiveFromDateKey: '2026-10-27',
            kcalTarget: 20000,
          ),
        ],
      );
      expect(high.summaries.every((s) => s.outsideTarget), isTrue);
      final full = PlannedMeal(
        id: 'a',
        date: start,
        type: MealType.lunch,
        items: [MealItemSnapshot.fromCatalog(foods.first, 1200)],
      );
      final plan = suggestMealPlan(
        start: start,
        catalog: foods,
        existing: [full],
        targets: [target],
      );
      expect(plan.drafts.where((d) => d.consumedAt.day == 27), isEmpty);
      expect(plan.summaries.first.plannedKcal, 2400);
      expect(
        () => suggestMealPlan(
          start: start,
          catalog: foods,
          existing: [],
          targets: [],
          avoidance: FoodAvoidance.fromText('gạo; bún'),
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'translated catalog retains original English search and snapshots',
    () async {
      final catalog = await loadBundledVietnameseFoods();
      final original = catalog
          .where((f) => f.originalName?.startsWith('Bananas,') == true)
          .first;
      expect(original.name, contains('Chuối'));
      expect(
        searchFoodCatalog(catalog, original.originalName!).map((f) => f.id),
        contains(original.id),
      );
      final snapshot = MealItemSnapshot.fromCatalog(original, 120);
      expect(
        MealItemSnapshot.fromData(snapshot.toData()).nutrition.kcal,
        snapshot.nutrition.kcal,
      );
      expect(snapshot.name, original.name);
    },
  );

  testWidgets('original USDA description can be read before confirming grams', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(FoodPortionDialog(initial: 200, food: foods.last)),
    );
    await tester.tap(find.text('Tên gốc và nguồn USDA'));
    await tester.pumpAndSettle();
    expect(find.text('Bananas, raw'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'plan editor blocks saving an avoided previous snapshot and permits removal',
    (tester) async {
      await tester.pumpWidget(
        host(
          PlanMealDialog(
            date: start,
            type: MealType.lunch,
            catalog: foods,
            items: [
              MealItemSnapshot.fromCatalog(foods.first, 200),
              MealItemSnapshot.fromCatalog(foods[1], 200),
            ],
            avoidance: FoodAvoidance.fromText('đậu nành'),
          ),
        ),
      );
      final save = find.byKey(const ValueKey('save-meal-plan'));
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await tester.tap(find.byTooltip('Bỏ món').first);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('logging a historical unknown meal requires acknowledgement', (
    tester,
  ) async {
    var saved = 0;
    await tester.pumpWidget(
      host(
        MealFormDialog(
          catalog: foods,
          initialItems: [
            MealItemSnapshot.fromCatalog(food('private', 'Món chưa rõ'), 100),
          ],
          avoidance: FoodAvoidance.fromText('sữa'),
          sourcesBuilder: (a, b, c, d, e) => const SizedBox.shrink(),
          onSave: (_) async {
            saved++;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('save-meal'));
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Kiểm tra thực phẩm cần tránh'), findsOneWidget);
    expect(saved, 0);
    await tester.tap(find.text('Quay lại kiểm tra'));
    await tester.pumpAndSettle();
    expect(saved, 0);
    await tester.tap(save);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vẫn ghi nhật ký'));
    await tester.pumpAndSettle();
    expect(saved, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unresolved authentication error cannot submit a meal draft', (
    tester,
  ) async {
    var saved = 0;
    await tester.pumpWidget(
      host(
        MealFormDialog(
          catalog: foods,
          initialItems: [MealItemSnapshot.fromCatalog(foods.first, 100)],
          sourcesBuilder: (a, b, c, d, e) => const SizedBox.shrink(),
          onSave: (_) async {
            saved++;
            return true;
          },
        ),
        session: Stream<AuthUser?>.error(StateError('Auth unavailable')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-meal')));
    await tester.pumpAndSettle();
    expect(saved, 0);
    expect(
      find.textContaining('Thông tin vẫn được giữ trong form'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
