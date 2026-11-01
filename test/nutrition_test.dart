import 'package:healthmate/features/journal/presentation/journal_nutrition_overview.dart';
import 'package:flutter/material.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/food_scanner/models/ai_food_suggestion.dart';
import 'package:healthmate/features/food_scanner/presentation/food_scanner_dialog.dart';
import 'package:healthmate/features/journal/providers/journal_date_provider.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/models/nutrition_validation.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/water/models/water_log.dart';

import 'support/fake_activity_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/test_app.dart';

MealLog _meal(String id, DateTime consumedAt, NutritionTotals totals) =>
    MealLog(
      id: id,
      type: MealType.lunch,
      consumedAt: consumedAt,
      items: [
        MealItemSnapshot(
          foodId: id,
          name: 'Món $id',
          grams: 100,
          nutrition: totals,
          sourceLabel: 'Dữ liệu kiểm thử',
          isEstimated: true,
        ),
      ],
      totals: totals,
      source: MealSource.manual,
    );

void main() {
  group('nutrition calculations and scanner parsing', () {
    test('scales catalog nutrients from 100 g to the confirmed portion', () {
      final result = FakeNutritionRepository.rice.forGrams(150);
      expect(result.kcal, closeTo(195, 0.001));
      expect(result.proteinG, closeTo(4.035, 0.001));
      expect(result.carbsG, closeTo(42.255, 0.001));
      expect(result.fatG, closeTo(0.42, 0.001));
    });

    test('validates portions and strict Gemini JSON', () {
      expect(NutritionValidation.grams('0'), isNotNull);
      expect(NutritionValidation.grams('150,5'), isNull);
      final suggestion = AiFoodSuggestion.fromJsonText(
        '{"dishName":"Cơm gà","description":"Cơm và thịt gà",'
        '"ingredients":["cơm","gà"],"searchTerms":["cơm","gà"]}',
      );
      expect(suggestion.dishName, 'Cơm gà');
      expect(
        () => AiFoodSuggestion.fromJsonText(
          '{"dishName":"Cơm","description":"Món ăn",'
          '"ingredients":[],"searchTerms":[]}',
        ),
        throwsFormatException,
      );
    });

    test('uses a half-open local day range at midnight boundaries', () async {
      final selectedDate = DateTime(2026, 10, 13);
      final range = localDayRange(selectedDate);
      final repository = FakeNutritionRepository(
        meals: [
          _meal(
            'previous-day',
            range.start.subtract(const Duration(microseconds: 1)),
            const NutritionTotals(kcal: 10),
          ),
          _meal('start', range.start, const NutritionTotals(kcal: 20)),
          _meal(
            'end-minus-one',
            range.end.subtract(const Duration(microseconds: 1)),
            const NutritionTotals(kcal: 30),
          ),
          _meal('next-day', range.end, const NutritionTotals(kcal: 40)),
        ],
      );
      addTearDown(repository.dispose);

      final result = await repository
          .watchMealLogs('alice', selectedDate)
          .first;

      expect(result.map((meal) => meal.id), ['end-minus-one', 'start']);
      final totals = totalMealNutrition(result);
      expect(totals.kcal, 50);
    });
  });

  testWidgets('selected date controls meal, water and activity totals', (
    tester,
  ) async {
    final today = localDateOnly(DateTime.now());
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final nutrition = FakeNutritionRepository(
      meals: [
        _meal(
          'today-a',
          DateTime(today.year, today.month, today.day, 8),
          const NutritionTotals(kcal: 100, proteinG: 10, carbsG: 15, fatG: 4),
        ),
        _meal(
          'today-b',
          DateTime(today.year, today.month, today.day, 20),
          const NutritionTotals(kcal: 200, proteinG: 20, carbsG: 25, fatG: 6),
        ),
        _meal(
          'yesterday',
          DateTime(yesterday.year, yesterday.month, yesterday.day, 12),
          const NutritionTotals(kcal: 50, proteinG: 5, carbsG: 7, fatG: 2),
        ),
      ],
    );
    final water = FakeWaterRepository(
      logs: [
        WaterLog(
          id: 'water-today',
          amountMl: 250,
          consumedAt: DateTime(today.year, today.month, today.day, 9),
          dateKey: localDateKey(today),
          timezoneOffsetMinutes: today.timeZoneOffset.inMinutes,
        ),
        WaterLog(
          id: 'water-yesterday',
          amountMl: 900,
          consumedAt: DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
            9,
          ),
          dateKey: localDateKey(yesterday),
          timezoneOffsetMinutes: yesterday.timeZoneOffset.inMinutes,
        ),
      ],
    );
    final activity = FakeActivityRepository(
      logs: [
        ActivityLog(
          id: 'activity-today',
          type: ActivityType.walking,
          durationMinutes: 30,
          performedAt: DateTime(today.year, today.month, today.day, 10),
          dateKey: localDateKey(today),
          timezoneOffsetMinutes: today.timeZoneOffset.inMinutes,
          note: '',
        ),
        ActivityLog(
          id: 'activity-yesterday',
          type: ActivityType.yoga,
          durationMinutes: 90,
          performedAt: DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
            10,
          ),
          dateKey: localDateKey(yesterday),
          timezoneOffsetMinutes: yesterday.timeZoneOffset.inMinutes,
          note: '',
        ),
      ],
    );
    final container = await pumpApp(
      tester,
      nutritionRepository: nutrition,
      waterRepository: water,
      activityRepository: activity,
    );
    container.read(appRouterProvider).go(AppRoutes.journal);
    await tester.pumpAndSettle();

    expect(journalTotals('300 kcal / — kcal'), findsOneWidget);
    await openJournalNutritionDetails(tester);
    for (final macro in ['30 / — g', '40 / — g', '10 / — g']) {
      expect(find.text(macro), findsOneWidget);
    }
    Navigator.of(
      tester.element(find.byType(JournalNutritionOverview).last),
    ).pop();
    await tester.pumpAndSettle();
    expect(find.text('250 ml'), findsWidgets);
    await openActivityDetails(tester);
    expect(find.text('30 phút'), findsWidgets);
    expect(find.textContaining('Món yesterday'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('journal-previous-day')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('journal-previous-day')));
    await tester.pumpAndSettle();

    expect(journalTotals('50 kcal / — kcal'), findsOneWidget);
    await openJournalNutritionDetails(tester);
    for (final macro in ['5 / — g', '7 / — g', '2 / — g']) {
      expect(find.text(macro), findsOneWidget);
    }
    Navigator.of(
      tester.element(find.byType(JournalNutritionOverview).last),
    ).pop();
    await tester.pumpAndSettle();
    expect(find.text('900 ml'), findsWidgets);
    expect(find.text('90 phút'), findsWidgets);
    expect(find.textContaining('Món today-a'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('journal-previous-day')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('journal-previous-day')));
    await tester.pumpAndSettle();

    expect(journalTotals('0 kcal / — kcal'), findsOneWidget);
    await openJournalNutritionDetails(tester);
    expect(find.text('0 / — g'), findsNWidgets(3));
    Navigator.of(
      tester.element(find.byType(JournalNutritionOverview).last),
    ).pop();
    await tester.pumpAndSettle();
    expect(find.text('Chưa ghi món'), findsNWidgets(4));
  });

  testWidgets('switching date while meals load cannot show the old day', (
    tester,
  ) async {
    final today = localDateOnly(DateTime.now());
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final repository = FakeNutritionRepository(
      emitImmediately: false,
      meals: [
        _meal(
          'today-only',
          DateTime(today.year, today.month, today.day, 12),
          const NutritionTotals(kcal: 100),
        ),
        _meal(
          'yesterday-only',
          DateTime(yesterday.year, yesterday.month, yesterday.day, 12),
          const NutritionTotals(kcal: 200),
        ),
      ],
    );
    final container = await pumpApp(tester, nutritionRepository: repository);
    container.read(appRouterProvider).go(AppRoutes.journal);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Đang tải danh mục và nhật ký…'), findsOneWidget);

    container.read(journalDateProvider.notifier).select(yesterday);
    await tester.pump();
    expect(find.text('Đang tải danh mục và nhật ký…'), findsOneWidget);

    repository.emitPending();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repository.watchedDateKeys, contains(localDateKey(today)));
    expect(repository.watchedDateKeys, contains(localDateKey(yesterday)));
    // The summary card and the editable journal row show the same meal.
    expect(find.textContaining('Món yesterday-only'), findsOneWidget);
    expect(find.textContaining('Món today-only'), findsNothing);
  });

  testWidgets('adds a meal manually with catalog nutrition', (tester) async {
    final repository = FakeNutritionRepository();
    final container = await pumpApp(tester, nutritionRepository: repository);
    container.read(appRouterProvider).go(AppRoutes.journal);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'journal');

    expect(find.text('Chưa ghi món'), findsNWidgets(4));
    await tester.ensureVisible(find.byKey(const ValueKey('journal-add-meal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('journal-add-meal')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'meal form');
    await tester.ensureVisible(find.byKey(const ValueKey('food-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('food-search')), 'cơm');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'search');
    await tester.ensureVisible(find.byTooltip('Thêm Cơm trắng chín'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thêm Cơm trắng chín'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'grams dialog');
    await tester.enterText(find.byKey(const ValueKey('meal-grams')), '150');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'portion added');
    await openSelectedMealItems(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('selected-meal-item-0')),
      200,
      scrollable: find
          .descendant(
            of: find.byType(MealFormDialog),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('195 kcal'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('save-meal')));
    await tester.pumpAndSettle();

    expect(repository.addCalls, 1);
    expect(find.textContaining('Cơm trắng chín · 150 g'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Food Scanner result still opens the meal confirmation form', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      featureFlags: const AppFeatureFlags(foodScannerEnabled: true),
    );
    container.read(appRouterProvider).go(AppRoutes.journal);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('journal-add-meal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('journal-add-meal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('meal-entry-photo')));
    await tester.pumpAndSettle();
    expect(find.byType(FoodScannerDialog), findsOneWidget);

    tester
        .widget<FoodScannerDialog>(find.byType(FoodScannerDialog))
        .onSelected!(
      const FoodScanChoice(query: 'cơm', food: FakeNutritionRepository.rice),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MealFormDialog), findsOneWidget);
    expect(find.textContaining('Cơm trắng chín'), findsWidgets);
    expect(find.byKey(const ValueKey('save-meal')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
