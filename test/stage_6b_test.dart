import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/journal/presentation/daily_summary_card.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'package:healthmate/features/profile/presentation/weight_chart.dart';
import 'package:healthmate/features/water/models/water_log.dart';

import 'support/fake_nutrition_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/test_app.dart';

MealLog _meal(String id, DateTime time) => MealLog(
  id: id,
  type: MealType.lunch,
  consumedAt: time,
  items: const [
    MealItemSnapshot(
      foodId: 'rice-cooked',
      name: 'Cơm trắng chín',
      grams: 150,
      nutrition: NutritionTotals(kcal: 195, proteinG: 4, carbsG: 42, fatG: 0.4),
      sourceLabel: 'Nguồn kiểm thử',
      isEstimated: true,
    ),
  ],
  totals: const NutritionTotals(kcal: 195, proteinG: 4, carbsG: 42, fatG: 0.4),
  source: MealSource.manual,
);

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('vi'),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  test('meal drafts persist date key and timezone from the consumed time', () {
    final consumedAt = DateTime(2026, 10, 13, 23, 30);
    final draft = MealDraft(
      type: MealType.dinner,
      consumedAt: consumedAt,
      items: const [
        MealItemSnapshot(
          foodId: 'custom-test',
          name: 'Món thử',
          grams: 100,
          nutrition: NutritionTotals(kcal: 100),
          sourceLabel: 'Người dùng nhập · Ước tính',
          isEstimated: true,
        ),
      ],
      source: MealSource.manual,
    );

    expect(draft.dateKey, localDateKey(consumedAt));
    expect(draft.timezoneOffsetMinutes, consumedAt.timeZoneOffset.inMinutes);
  });

  test('recent foods keep newest unique items', () {
    final now = DateTime(2026, 10, 13, 12);
    final items = recentMealItems([
      _meal('newest', now),
      _meal('older-duplicate', now.subtract(const Duration(days: 1))),
    ]);
    expect(items, hasLength(1));
    expect(items.single.name, 'Cơm trắng chín');
  });

  testWidgets('daily summary adds only loaded records for the selected day', (
    tester,
  ) async {
    final time = DateTime(2026, 10, 13, 12);
    await tester.pumpWidget(
      _host(
        DailySummaryCard(
          date: time,
          mealsState: AsyncData([_meal('meal', time)]),
          waterState: AsyncData([
            WaterLog(
              id: 'water',
              amountMl: 500,
              consumedAt: time,
              dateKey: '2026-10-13',
              timezoneOffsetMinutes: 420,
            ),
          ]),
          activityState: AsyncData([
            ActivityLog(
              id: 'activity',
              type: ActivityType.walking,
              durationMinutes: 30,
              performedAt: time,
              dateKey: '2026-10-13',
              timezoneOffsetMinutes: 420,
              note: '',
            ),
          ]),
        ),
      ),
    );

    expect(find.text('195 kcal'), findsOneWidget);
    expect(find.text('4,0 · 42,0 · 0,4 g'), findsOneWidget);
    expect(find.text('500 ml'), findsOneWidget);
    expect(find.text('30 phút'), findsOneWidget);
  });

  testWidgets('meal form offers recent and custom estimated foods', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MealFormDialog(
            catalog: const [FakeNutritionRepository.rice],
            recentItems: _meal('recent', DateTime(2026, 10, 13)).items,
          ),
        ),
      ),
    );

    expect(find.text('Món gần đây'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-custom-food')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('custom-food-name')),
      'Bánh nhà làm',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-food-kcal')),
      '220',
    );
    for (final field in ['protein', 'carbs', 'fat']) {
      await tester.enterText(find.byKey(ValueKey('custom-food-$field')), '0');
    }
    await tester.tap(find.byKey(const ValueKey('save-custom-food')));
    await tester.pumpAndSettle();

    await openSelectedMealItems(tester);
    expect(find.text('Bánh nhà làm'), findsOneWidget);
    expect(find.textContaining('Ước tính'), findsWidgets);
  });

  testWidgets('duplicate meal and quick water write real entries', (
    tester,
  ) async {
    final today = localDateOnly(DateTime.now());
    final nutrition = FakeNutritionRepository(
      meals: [
        _meal('source', DateTime(today.year, today.month, today.day, 12)),
      ],
    );
    final water = FakeWaterRepository();
    final container = await pumpApp(
      tester,
      nutritionRepository: nutrition,
      waterRepository: water,
    );
    container.read(appRouterProvider).go(AppRoutes.journal);
    await tester.pumpAndSettle();

    final mealMenu = tester
        .widgetList<PopupMenuButton<String>>(
          find.byType(PopupMenuButton<String>),
        )
        .first;
    mealMenu.onSelected!('duplicate');
    await tester.pumpAndSettle();
    expect(find.text('Cơm trắng chín'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('save-meal')));
    await tester.pumpAndSettle();
    expect(nutrition.addCalls, 1);
    expect(nutrition.meals, hasLength(2));
    expect(nutrition.meals.last.dateKey, localDateKey(today));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('quick-water-250')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-water-250')));
    await tester.pumpAndSettle();
    expect(water.addCalls, 1);
    expect(water.logs.single.amountMl, 250);
    expect(water.logs.single.dateKey, localDateKey(today));
  });

  testWidgets('weight history renders an intl-formatted fl_chart', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        WeightChart(
          metrics: [
            BodyMetric(
              id: 'new',
              weightKg: 69.5,
              measuredAt: DateTime(2026, 10, 13),
              note: '',
              createdAt: null,
              updatedAt: null,
            ),
            BodyMetric(
              id: 'old',
              weightKg: 70,
              measuredAt: DateTime(2026, 10, 1),
              note: '',
              createdAt: null,
              updatedAt: null,
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('weight-chart')), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
