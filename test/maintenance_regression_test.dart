import 'support/fake_food_search_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/models/nutrition_failure.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/test_app.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/fake_activity_repository.dart';
import 'package:healthmate/features/water/models/water_log.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/journal/models/daily_log_failure.dart';

class _RejectedWater extends FakeWaterRepository {
  bool reject = true;
  @override
  Future<String> add({
    required String uid,
    required WaterLogDraft draft,
  }) async {
    if (reject) {
      reject = false;
      throw const DailyLogFailure('Test rejection');
    }
    return super.add(uid: uid, draft: draft);
  }
}

class _RejectedActivity extends FakeActivityRepository {
  bool reject = true;
  @override
  Future<String> add({
    required String uid,
    required ActivityLogDraft draft,
  }) async {
    if (reject) {
      reject = false;
      throw const DailyLogFailure('Test rejection');
    }
    return super.add(uid: uid, draft: draft);
  }
}

class _RejectedMeal extends FakeNutritionRepository {
  int attempts = 0;
  Completer<void>? pending;
  @override
  Future<String> addMeal({
    required String uid,
    required MealDraft draft,
    String? operationId,
  }) async {
    attempts++;
    if (pending != null) await pending!.future;
    if (attempts == 1) throw const NutritionFailure('Không có quyền ghi.');
    return super.addMeal(uid: uid, draft: draft, operationId: operationId);
  }
}

Future<void> _openMeal(
  WidgetTester tester,
  FakeNutritionRepository repository, {
  FakeAuthRepository? auth,
}) async {
  final container = await pumpApp(
    tester,
    nutritionRepository: repository,
    repository: auth,
  );
  container.read(appRouterProvider).go(AppRoutes.journal);
  await tester.pumpAndSettle();
  final add = find.byKey(const ValueKey('journal-add-meal'));
  await tester.scrollUntilVisible(
    add,
    400,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(add);
  await tester.pumpAndSettle();
  await tester.tap(add);
  await tester.pumpAndSettle();
  final rice = find.byTooltip('Thêm Cơm trắng chín');
  await tester.ensureVisible(rice);
  await tester.pumpAndSettle();
  await tester.tap(rice);
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('meal-grams')), '150');
  await tester.tap(find.text('Xác nhận'));
  await tester.pumpAndSettle();
}

void main() {
  for (final kind in ['water', 'activity']) {
    testWidgets('F01 $kind rejection preserves input and retry saves once', (
      tester,
    ) async {
      final water = _RejectedWater();
      final activity = _RejectedActivity();
      final container = await pumpApp(
        tester,
        waterRepository: water,
        activityRepository: activity,
      );
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      if (kind == 'activity') await openActivityDetails(tester);
      final add = find.byKey(ValueKey('add-$kind'));
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      final field = find.byKey(
        ValueKey(kind == 'water' ? 'water-amount' : 'activity-duration'),
      );
      await tester.enterText(field, kind == 'water' ? '350' : '42');
      await tester.tap(find.byKey(ValueKey('save-$kind')));
      await tester.pumpAndSettle();
      expect(field, findsOneWidget);
      expect(
        tester.widget<TextFormField>(field).controller!.text,
        kind == 'water' ? '350' : '42',
      );
      expect(find.textContaining('Thông tin vẫn được giữ'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('save-$kind')));
      await tester.pumpAndSettle();
      expect(kind == 'water' ? water.addCalls : activity.addCalls, 1);
    });
  }
  testWidgets(
    'F01 pending meal blocks duplicates and drops draft on sign out',
    (tester) async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final repo = _RejectedMeal()
        ..attempts = 1
        ..pending = Completer<void>();
      await _openMeal(tester, repo, auth: auth);
      await tester.tap(find.byKey(const ValueKey('save-meal')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 20));
      expect(find.byType(MealFormDialog), findsOneWidget);
      expect(repo.attempts, 2);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('save-meal')))
            .onPressed,
        isNull,
      );
      expect(
        find.descendant(
          of: find.byType(MealFormDialog),
          matching: find.textContaining('Đang chờ máy chủ xác nhận'),
        ),
        findsOneWidget,
      );
      auth.emitUser(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(MealFormDialog), findsNothing);
      repo.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Đã lưu bữa ăn.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  test('F02 corrupt snapshots cannot silently become valid nutrition', () {
    for (final item in [
      const MealItemSnapshot(
        foodId: 'bad',
        name: 'Bad',
        grams: 0,
        nutrition: NutritionTotals(kcal: 130),
        sourceLabel: 'old',
        isEstimated: true,
      ),
      const MealItemSnapshot(
        foodId: 'bad',
        name: 'Bad',
        grams: 100,
        nutrition: NutritionTotals(kcal: double.nan),
        sourceLabel: 'old',
        isEstimated: true,
      ),
      const MealItemSnapshot(
        foodId: 'bad',
        name: 'Bad',
        grams: 100,
        nutrition: NutritionTotals(),
        sourceLabel: 'old',
        isEstimated: true,
        hasNutritionData: false,
      ),
    ]) {
      expect(() => item.withGrams(150), throwsFormatException);
    }
  });

  testWidgets('F01 rejected meal keeps draft and retries once', (tester) async {
    final repo = _RejectedMeal();
    await _openMeal(tester, repo);
    final form = tester.widget<MealFormDialog>(find.byType(MealFormDialog));
    final date = form.initialConsumedAt!;
    await tester.tap(find.byKey(const ValueKey('save-meal')));
    await tester.pumpAndSettle();
    expect(find.byType(MealFormDialog), findsOneWidget);
    await openSelectedMealItems(tester);
    expect(find.textContaining('150 g'), findsWidgets);
    expect(find.textContaining('thử lại'), findsWidgets);
    expect(repo.meals, isEmpty);
    await tester.tap(find.byKey(const ValueKey('save-meal')));
    await tester.pumpAndSettle();
    expect(repo.attempts, 2);
    expect(repo.meals, hasLength(1));
    expect(repo.meals.single.consumedAt, date);
    expect(repo.meals.single.items.single.grams, 150);
    expect(repo.meals.single.totals.kcal, 195);
    expect(find.byType(MealFormDialog), findsNothing);
  });

  for (final grams in [100, 150]) {
    for (final exists in [true, false]) {
      testWidgets(
        'F02 old snapshot keeps nutrition at $grams g, catalog exists=$exists',
        (tester) async {
          final old = MealItemSnapshot.fromCatalog(
            FakeNutritionRepository.rice,
            100,
          );
          const changed = FoodCatalogItem(
            id: 'rice-cooked',
            name: 'Cơm mới',
            alternateNames: [],
            category: 'Cơm',
            servingBasis: ServingBasis.per100g,
            unit: 'g',
            per100g: NutritionTotals(
              kcal: 260,
              proteinG: 20,
              carbsG: 40,
              fatG: 8,
            ),
            sourceLabel: 'Nguồn mới',
            isEstimated: false,
          );
          MealDraft? result;
          await tester.pumpWidget(
            testFoodScope(
              MaterialApp(
                locale: const Locale('vi'),
                supportedLocales: const [Locale('vi')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () async {
                        result = await showDialog<MealDraft>(
                          context: context,
                          builder: (_) => MealFormDialog(
                            catalog: exists ? [changed] : [],
                            initialItems: [old],
                          ),
                        );
                      },
                      child: const Text('Mở'),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Mở'));
          await tester.pumpAndSettle();
          final edit = find.byTooltip('Sửa khẩu phần');
          await tester.scrollUntilVisible(
            edit,
            180,
            scrollable: find
                .byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                )
                .last,
          );
          await tester.pumpAndSettle();
          await tester.tap(edit);
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('meal-grams')),
            '$grams',
          );
          await tester.tap(find.text('Xác nhận'));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('save-meal')));
          await tester.pumpAndSettle();
          final item = result!.items.single;
          expect(item.nutrition.kcal, 130 * grams / 100);
          expect(
            item.nutrition.proteinG,
            closeTo(old.nutrition.proteinG * grams / 100, 1e-9),
          );
          expect(
            item.nutrition.carbsG,
            closeTo(old.nutrition.carbsG * grams / 100, 1e-9),
          );
          expect(
            item.nutrition.fatG,
            closeTo(old.nutrition.fatG * grams / 100, 1e-9),
          );
          expect(item.sourceLabel, old.sourceLabel);
          expect(item.isEstimated, old.isEstimated);
          expect(item.name, old.name);
        },
      );
    }
  }
}
