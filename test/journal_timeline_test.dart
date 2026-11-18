import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/journal/models/meal_timeline.dart';
import 'package:healthmate/features/journal/presentation/hourly_meal_timeline.dart';
import 'package:healthmate/features/journal/providers/journal_date_provider.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/nutrition/presentation/food_photo_thumbnail.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_nutrition_target_repository.dart';
import 'support/load_icon_font.dart';
import 'support/test_app.dart';

final _now = DateTime(2026, 11, 10, 14, 27);
MealLog _meal(String id, DateTime time, {int? offset, bool both = false}) {
  final items = [
    MealItemSnapshot.fromCatalog(FakeNutritionRepository.rice, 150),
    if (both) MealItemSnapshot.fromCatalog(FakeNutritionRepository.egg, 100),
  ];
  return MealLog(
    id: id,
    type: MealType.dinner,
    consumedAt: time,
    items: items,
    totals: sumNutritionTotals(items.map((i) => i.nutrition)),
    source: MealSource.manual,
    timezoneOffsetMinutes: offset,
  );
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, key.currentContext!);
    }
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final image =
        await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/journal-timeline/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await loadIconFont();
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

  test(
    '09:30 and 09:05 share 09:00, sorted precisely regardless of meal type',
    () {
      final late = _meal('late', DateTime(2026, 11, 10, 9, 30), both: true);
      final early = _meal('early', DateTime(2026, 11, 10, 9, 5));
      final next = _meal('next', DateTime(2026, 11, 10, 10));
      final groups = groupMealsByHour([late, next, early]);
      expect(groups, hasLength(24));
      expect(groups[9].meals.map((m) => m.id), ['early', 'late']);
      expect(groups[10].meals.single.id, 'next');
      expect(groups[8].meals, isEmpty);
      expect(groups[9].totals.kcal, 195 + 350);
      expect(late.consumedAt.minute, 30);
      expect(late.type, MealType.dinner);
    },
  );

  test(
    'stored timezone controls the clock, including midnight; legacy uses local',
    () {
      final meal = _meal(
        'offset',
        DateTime.utc(2026, 11, 9, 17, 30),
        offset: 420,
      );
      expect(journalMealTime(meal).day, 10);
      expect(journalMealTime(meal).hour, 0);
      expect(groupMealsByHour([meal])[0].meals.single, meal);
      final west = _meal(
        'west',
        DateTime.utc(2026, 11, 10, 1, 30),
        offset: -480,
      );
      expect(journalMealTime(west).day, 9);
      expect(journalMealTime(west).hour, 17);
      final legacy = _meal('legacy', DateTime(2026, 11, 10, 23, 59));
      expect(groupMealsByHour([legacy])[23].meals.single, legacy);
    },
  );

  test(
    'legacy and recorded-offset entries sort by displayed minutes together',
    () {
      final legacy = _meal('legacy', DateTime(2026, 11, 10, 9, 40));
      final recorded = _meal(
        'recorded',
        DateTime.utc(2026, 11, 10, 2, 30),
        offset: 420,
      );
      final groups = groupMealsByHour([legacy, recorded]);
      expect(groups[9].meals.map((m) => m.id), ['recorded', 'legacy']);
      expect(journalMealTime(legacy).hour, 9);
      expect(journalMealTime(legacy).minute, 40);
      expect(journalMealTime(legacy).isUtc, isTrue);
      expect(legacy.consumedAt, DateTime(2026, 11, 10, 9, 40));
    },
  );

  test(
    'hour add retains selected day/current minute and prevents future times',
    () {
      final clock = DateTime(2026, 11, 10, 9, 30);
      expect(mealTimeForHour(clock, 9, clock), clock);
      expect(mealTimeForHour(clock, 8, clock), DateTime(2026, 11, 10, 8));
      expect(mealTimeForHour(clock, 10, clock), isNull);
      expect(
        mealTimeForHour(DateTime(2026, 11, 9), 23, clock),
        DateTime(2026, 11, 9, 23),
      );
      expect(() => mealTimeForHour(clock, 24, clock), throwsRangeError);
    },
  );

  for (final config in [
    (ThemeMode.light, 390.0, 1.0),
    (ThemeMode.dark, 390.0, 1.0),
    (ThemeMode.dark, 320.0, 2.0),
  ]) {
    final (mode, width, scale) = config;
    testWidgets(
      'hourly journal photos, exact time and totals $mode/$width/$scale',
      (tester) async {
        final repo = FakeNutritionRepository(
          meals: [
            _meal('breakfast', DateTime(2026, 11, 10, 9, 30), both: true),
          ],
        );
        final targets = FakeNutritionTargetRepository();
        targets.byUid['test-uid'] = {
          '2026-11-10': const NutritionTarget(
            effectiveFromDateKey: '2026-11-10',
            kcalTarget: 2000,
            proteinGTarget: 100,
            carbsGTarget: 250,
            fatGTarget: 70,
          ),
        };
        final key = GlobalKey();
        final container = await pumpApp(
          tester,
          nutritionRepository: repo,
          dashboardNow: _now,
          initialThemeMode: mode,
          size: Size(width, 844),
          textScale: scale,
          captureKey: key,
          targetRepository: targets,
        );
        container.read(journalDateProvider.notifier).select(_now);
        container.read(appRouterProvider).go(AppRoutes.journal);
        await tester.pumpAndSettle();
        expect(journalTotals('350 kcal / 2000 kcal'), findsOneWidget);
        expect(find.byKey(const ValueKey('add-meal-breakfast')), findsNothing);
        expect(find.text('09:30 · 2 món'), findsOneWidget);
        final bucket = find.byKey(const ValueKey('journal-hour-9'));
        expect(
          find.descendant(
            of: bucket,
            matching: find.byKey(const ValueKey('meal-log-breakfast')),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: bucket,
            matching: find.byType(FoodPhotoThumbnail),
          ),
          findsNWidgets(2),
        );
        await _capture(tester, key, 'overview-${mode.name}-$scale');
        await tester.ensureVisible(
          find.byKey(const ValueKey('journal-hour-totals-9')),
        );
        await tester.pumpAndSettle();
        await _capture(tester, key, 'foods-${mode.name}-$scale');
        final future = tester.widget<IconButton>(
          find.byKey(const ValueKey('add-meal-hour-15')),
        );
        expect(future.onPressed, isNull);
        await _tap(tester, find.byKey(const ValueKey('add-meal-hour-8')));
        final form = tester.widget<MealFormDialog>(find.byType(MealFormDialog));
        expect(form.initialConsumedAt, DateTime(2026, 11, 10, 8));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'save at 09:30 then realtime move/delete updates the right hour',
    (tester) async {
      final clock = DateTime(2026, 11, 10, 9, 30);
      final repo = FakeNutritionRepository();
      final container = await pumpApp(
        tester,
        nutritionRepository: repo,
        dashboardNow: clock,
      );
      container.read(journalDateProvider.notifier).select(clock);
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('journal-add-meal')));
      expect(
        tester
            .widget<MealFormDialog>(find.byType(MealFormDialog))
            .initialConsumedAt,
        clock,
      );
      await _tap(tester, find.byTooltip('Thêm Cơm trắng chín'));
      await tester.enterText(find.byKey(const ValueKey('meal-grams')), '150');
      await _tap(tester, find.text('Xác nhận'));
      await _tap(tester, find.byKey(const ValueKey('save-meal')));
      expect(repo.addCalls, 1);
      final saved = repo.meals.single;
      final mealKey = find.byKey(ValueKey('meal-log-${saved.id}'));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('journal-hour-9')),
          matching: mealKey,
        ),
        findsOneWidget,
      );
      expect(saved.consumedAt, clock);
      expect(saved.items.single.grams, 150);
      expect(saved.totals.kcal, 195);
      // A repository change (e.g. another device editing the meal) must move
      // the existing ID without duplicating a card or rewriting the snapshot.
      await repo.updateMeal(
        uid: 'test-uid',
        mealId: saved.id,
        draft: MealDraft(
          type: saved.type,
          consumedAt: DateTime(2026, 11, 10, 8, 15),
          items: saved.items,
          source: saved.source,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('journal-hour-8')),
          matching: mealKey,
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('journal-hour-9')),
          matching: mealKey,
        ),
        findsNothing,
      );
      expect(journalTotals('195 kcal / — kcal'), findsOneWidget);
      // A new overnight entry arriving while early hours are collapsed must
      // become visible without the user having to expand the empty section.
      await repo.updateMeal(
        uid: 'test-uid',
        mealId: saved.id,
        draft: MealDraft(
          type: saved.type,
          consumedAt: DateTime(2026, 11, 10, 0, 15),
          items: saved.items,
          source: saved.source,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('journal-hour-0')),
          matching: mealKey,
        ),
        findsOneWidget,
      );
      expect(find.text('00:15 · 1 món'), findsOneWidget);
      await _tap(tester, find.byKey(ValueKey('meal-menu-${saved.id}')));
      await _tap(tester, find.text('Xóa'));
      await _tap(tester, find.byKey(const ValueKey('confirm-delete-journal')));
      expect(repo.deleteCalls, 1);
      expect(mealKey, findsNothing);
      expect(journalTotals('0 kcal / — kcal'), findsOneWidget);
    },
  );

  testWidgets('overnight records are visible and unknown macros stay unknown', (
    tester,
  ) async {
    final overnight = MealLog(
      id: 'night',
      type: MealType.snack,
      consumedAt: DateTime(2026, 11, 10, 0, 30),
      items: [
        const MealItemSnapshot(
          foodId: 'custom-no-image',
          name: 'Món ghi riêng',
          grams: 100,
          nutrition: NutritionTotals(kcal: 100, proteinKnown: false),
          sourceLabel: 'Fixture',
          isEstimated: true,
        ),
      ],
      totals: const NutritionTotals(kcal: 100, proteinKnown: false),
      source: MealSource.manual,
    );
    final container = await pumpApp(
      tester,
      dashboardNow: _now,
      nutritionRepository: FakeNutritionRepository(meals: [overnight]),
    );
    container.read(journalDateProvider.notifier).select(_now);
    container.read(appRouterProvider).go(AppRoutes.journal);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('meal-log-night')), findsOneWidget);
    expect(find.byType(FoodPhotoThumbnail), findsNothing);
    expect(find.text('Chưa đủ dữ liệu'), findsWidgets);
    final timeline = tester.widget<HourlyMealTimeline>(
      find.byType(HourlyMealTimeline),
    );
    expect(timeline.meals.single.items.single.nutrition.proteinKnown, isFalse);
    expect(tester.takeException(), isNull);
  });
}
