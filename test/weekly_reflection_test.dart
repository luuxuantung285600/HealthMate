import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/core/widgets/metric_tile.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/dashboard/providers/dashboard_providers.dart';
import 'package:healthmate/features/daily_quest/domain/quest_engine.dart';
import 'package:healthmate/features/daily_quest/models/daily_quest.dart';
import 'package:healthmate/features/goals/models/tracking_goal.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'package:healthmate/features/water/models/water_log.dart';
import 'package:healthmate/features/weekly_reflection/models/weekly_reflection.dart';
import 'package:healthmate/shared/providers/local_clock_provider.dart';

import 'support/fake_activity_repository.dart';
import 'support/fake_goals_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/test_app.dart';

final start = DateTime(2026, 10, 12);
final sunday = DateTime(2026, 10, 18, 20);
MealLog meal(String id, DateTime time, double kcal, {String? key}) => MealLog(
  id: id,
  type: MealType.lunch,
  consumedAt: time,
  items: [],
  totals: NutritionTotals(
    kcal: kcal,
    proteinG: kcal / 10,
    carbsG: kcal / 5,
    fatG: kcal / 20,
  ),
  source: MealSource.manual,
  dateKey: key,
);
WaterLog water(String id, DateTime day, int ml) => WaterLog(
  id: id,
  amountMl: ml,
  consumedAt: day,
  dateKey: localDateKey(day),
  timezoneOffsetMinutes: day.timeZoneOffset.inMinutes,
);
ActivityLog activity(String id, DateTime day, int minutes) => ActivityLog(
  id: id,
  type: ActivityType.walking,
  durationMinutes: minutes,
  performedAt: day,
  dateKey: localDateKey(day),
  timezoneOffsetMinutes: day.timeZoneOffset.inMinutes,
  note: '',
);
BodyMetric weight(String id, DateTime day, double kg) => BodyMetric(
  id: id,
  weightKg: kg,
  measuredAt: day,
  note: '',
  createdAt: day,
  updatedAt: day,
);

Future<void> openWeek(WidgetTester tester) async {
  await openDashboardDetails(tester);
  final finder = find.byKey(const ValueKey('open-weekly-reflection'));
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.2);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('week starts Monday across month/year boundary', () {
    expect(weekStart(DateTime(2027, 1, 3)), DateTime(2026, 12, 28));
    expect(weekStart(DateTime(2026, 10, 12, 23)), start);
  });

  test(
    'weekly totals match snapshots, respect date keys and deduplicate IDs',
    () {
      final mid = DateTime(2026, 10, 14, 12);
      final logs = WeekLogs(
        meals: [
          meal('start', start, 100),
          meal('mid', mid, 300),
          meal('mid', mid, 300),
          meal('last', DateTime(2026, 10, 18, 23, 59, 59, 999), 200),
          meal('next', DateTime(2026, 10, 19), 999),
          meal('old', DateTime(2026, 10, 11), 777),
        ],
        water: [
          water('w1', start, 250),
          water('w2', DateTime(2026, 10, 16), 500),
        ],
        activities: [
          activity('a1', DateTime(2026, 10, 13), 15),
          activity('a2', DateTime(2026, 10, 15), 30),
        ],
        loadedAt: sunday,
      );
      final r = summarizeWeek(
        start,
        sunday,
        logs,
        metrics: [
          weight('end', DateTime(2026, 10, 18), 69.5),
          weight('start', start, 70),
        ],
      );
      expect(r.days.length, 7);
      expect(r.nutrition.kcal, 600);
      expect(r.nutrition.proteinG, 60);
      expect(r.nutrition.carbsG, 120);
      expect(r.nutrition.fatG, 30);
      expect(r.waterMl, 750);
      expect(r.activityMinutes, 45);
      expect(r.mealDays, 3);
      expect(r.averageKcalPerRecordedDay, 200);
      expect(r.weightChange, -0.5);
    },
  );

  test(
    'no logs and one weight never imply intake averages or weight trends',
    () {
      final r = summarizeWeek(
        start,
        sunday,
        WeekLogs(meals: [], water: [], activities: [], loadedAt: sunday),
        metrics: [weight('one', start, 70)],
      );
      expect(r.hasLogs, isFalse);
      expect(r.averageKcalPerRecordedDay, isNull);
      expect(r.weightChange, isNull);
      expect(r.metrics.length, 1);
    },
  );

  test(
    'future days are excluded and recorded timezone date wins over timestamp',
    () {
      final r = summarizeWeek(
        start,
        DateTime(2026, 10, 13),
        WeekLogs(
          meals: [
            meal(
              'recorded',
              DateTime(2026, 10, 11, 23),
              100,
              key: '2026-10-12',
            ),
            meal('other-zone', start, 400, key: '2026-10-11'),
            meal('future', DateTime(2026, 10, 14), 900),
          ],
          water: [],
          activities: [],
          loadedAt: sunday,
        ),
      );
      expect(r.eligibleDays, 2);
      expect(r.nutrition.kcal, 100);
      expect(r.averageKcalPerRecordedDay, 100);
      expect(r.days.last.isFuture, isTrue);
    },
  );

  test('range repositories use half-open calendar boundaries', () async {
    final n = FakeNutritionRepository(
      meals: [
        meal('start', start, 100),
        meal('last', DateTime(2026, 10, 18, 23, 59), 200),
        meal('end', DateTime(2026, 10, 19), 300),
      ],
    );
    addTearDown(n.dispose);
    expect(
      (await n.loadRange(
        'uid',
        start,
        DateTime(2026, 10, 19),
      )).map((m) => m.id),
      ['start', 'last'],
    );
  });

  testWidgets(
    'week loads only when opened and rebuilds do not duplicate queries',
    (tester) async {
      final n = FakeNutritionRepository(meals: [meal('m', start, 130)]);
      final w = FakeWaterRepository();
      final a = FakeActivityRepository();
      final profile = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
        metrics: [
          weight('first', start, 70),
          weight('last', DateTime(2026, 10, 17), 69),
        ],
      );
      final container = await pumpApp(
        tester,
        dashboardNow: sunday,
        nutritionRepository: n,
        waterRepository: w,
        activityRepository: a,
        profileRepository: profile,
      );
      expect(n.rangeCalls, 0);
      expect(profile.metricRangeCalls, 0);
      expect(profile.fullMetricWatchCalls, 0);
      expect(profile.latestMetricListeners, 1);
      await openWeek(tester);
      expect(n.rangeCalls, 1);
      expect(w.rangeCalls, 1);
      expect(a.rangeCalls, 1);
      expect(profile.metricRangeCalls, 1);
      expect(find.byKey(const ValueKey('weekly-chart')), findsOneWidget);
      container.invalidate(dashboardClockProvider);
      await tester.pumpAndSettle();
      expect(n.rangeCalls, 1);
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const ValueKey('refresh-week'))),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('refresh-week')));
      await tester.pumpAndSettle();
      expect(n.rangeCalls, 2);
      expect(w.rangeCalls, 2);
      expect(a.rangeCalls, 2);
      expect(profile.metricRangeCalls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'week error is visible and retry recovers without fabricated totals',
    (tester) async {
      final n = FakeNutritionRepository()..rangeError = StateError('test-only');
      await pumpApp(tester, dashboardNow: sunday, nutritionRepository: n);
      await openWeek(tester);
      expect(find.textContaining('Chưa tải đủ dữ liệu tuần'), findsOneWidget);
      expect(find.textContaining('test-only'), findsNothing);
      expect(find.byKey(const ValueKey('weekly-chart')), findsNothing);
      n.rangeError = null;
      final retry = find.byKey(const ValueKey('retry-week'));
      await Scrollable.ensureVisible(tester.element(retry), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Chưa có nhật ký bữa ăn, nước hoặc vận động'),
        findsOneWidget,
      );
      expect(n.rangeCalls, 2);
    },
  );

  testWidgets('switching week while loading cannot display the earlier week', (
    tester,
  ) async {
    final gate = Completer<void>();
    final n = FakeNutritionRepository(meals: [meal('week-current', start, 130)])
      ..rangePending = gate;
    await pumpApp(tester, dashboardNow: sunday, nutritionRepository: n);
    await openDashboardDetails(tester);
    final open = find.byKey(const ValueKey('open-weekly-reflection'));
    await Scrollable.ensureVisible(tester.element(open), alignment: 0.2);
    await tester.pumpAndSettle();
    await tester.tap(open);
    await tester.pump();
    final previous = find.byKey(const ValueKey('previous-week'));
    await Scrollable.ensureVisible(tester.element(previous), alignment: 0.2);
    await tester.pump();
    await tester.tap(previous);
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('05/10/2026 – 11/10/2026'), findsOneWidget);
    expect(find.byKey(const ValueKey('weekly-chart')), findsNothing);
    expect(n.rangeCalls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Dashboard releases daily listeners on Profile; reports load only on demand',
    (tester) async {
      final n = FakeNutritionRepository();
      final w = FakeWaterRepository();
      final a = FakeActivityRepository();
      await pumpApp(
        tester,
        dashboardNow: sunday,
        nutritionRepository: n,
        waterRepository: w,
        activityRepository: a,
      );
      expect(
        n.activeDayListeners,
        2,
      ); // Selected day and previous-day meal reuse.
      expect(w.activeDayListeners, 1);
      expect(a.activeDayListeners, 1);
      await tester.tap(find.byKey(const ValueKey('nav-profile')));
      await tester.pumpAndSettle();
      // Profile manages the account and goals, without duplicate daily journals.
      expect(n.activeDayListeners, 0);
      expect(w.activeDayListeners, 0);
      expect(a.activeDayListeners, 0);
      expect(n.rangeCalls, 0);
      expect(w.rangeCalls, 0);
      expect(a.rangeCalls, 0);
      await tester.tap(find.byKey(const ValueKey('nav-progress')));
      await tester.pumpAndSettle();
      expect(n.activeDayListeners, 0);
      expect(w.activeDayListeners, 0);
      expect(a.activeDayListeners, 0);
      expect(n.rangeCalls, 1);
      expect(w.rangeCalls, 1);
      expect(a.rangeCalls, 1);
      await tester.tap(find.byKey(const ValueKey('nav-dashboard')));
      await tester.pumpAndSettle();
      expect(
        n.activeDayListeners,
        2,
      ); // Selected day and previous-day meal reuse.
      expect(w.activeDayListeners, 1);
      expect(a.activeDayListeners, 1);
      expect(n.rangeCalls, 1);
      expect(w.rangeCalls, 1);
      expect(a.rangeCalls, 1);
    },
  );

  testWidgets(
    'Dashboard shows saved goal/quest and errors use a dash rather than zero',
    (tester) async {
      final repo = FakeGoalsRepository();
      repo.goals['test-uid'] = [
        TrackingGoal(
          id: 'water',
          draft: GoalDraft(
            type: GoalType.water,
            targetValue: 1000,
            startDate: start,
            endDate: sunday,
          ),
        ),
      ];
      repo.quests['test-uid/2026-10-18'] = suggestQuest(
        day: sunday,
        goals: [],
        mealCount: 0,
        waterMl: 0,
        activityMinutes: 0,
      ).withStatus(QuestStatus.completed);
      final n = FakeNutritionRepository()..dayError = StateError('unavailable');
      await pumpApp(
        tester,
        dashboardNow: sunday,
        goalsRepository: repo,
        nutritionRepository: n,
      );
      await openDashboardDetails(tester);
      expect(find.text('Nước đã ghi: 0 / 1000 ml'), findsOneWidget);
      expect(find.textContaining('Đã hoàn thành'), findsOneWidget);
      expect(
        tester
            .widget<MetricTile>(find.byKey(const ValueKey('dashboard-meals')))
            .value,
        '—',
      );
      expect(find.text('0 kcal đã ghi'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('day rollover changes Dashboard query key', (tester) async {
    var now = DateTime(2026, 10, 18, 23, 59);
    final n = FakeNutritionRepository();
    final container = await pumpApp(
      tester,
      dashboardNowSource: () => now,
      nutritionRepository: n,
    );
    expect(n.watchedDateKeys.last, '2026-10-18');
    now = DateTime(2026, 10, 19, 0, 1);
    container.invalidate(dashboardClockProvider);
    await tester.pumpAndSettle();
    expect(n.watchedDateKeys.last, '2026-10-19');
    expect(
      n.activeDayListeners,
      2,
    ); // Selected day and previous-day meal reuse.
  });

  testWidgets('clock refreshes on resume and disposes its timer', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 18, 23, 59, 50);
    final container = ProviderContainer(
      overrides: [currentLocalTimeProvider.overrideWithValue(() => now)],
    );
    final sub = container.listen(localClockProvider, (_, _) {});
    expect(container.read(localClockProvider).day, 18);
    now = DateTime(2026, 10, 19, 0, 0);
    await tester.pump(const Duration(seconds: 10));
    expect(container.read(localClockProvider).day, 19);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime(2026, 10, 20, 9);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(container.read(localClockProvider).day, 20);
    sub.close();
    container.dispose();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 1.5]) {
    testWidgets('sparse weekly chart fits phone at text scale $scale', (
      tester,
    ) async {
      await pumpApp(
        tester,
        dashboardNow: sunday,
        textScale: scale,
        size: const Size(320, 720),
        initialThemeMode: scale > 1 ? ThemeMode.dark : ThemeMode.light,
        nutritionRepository: FakeNutritionRepository(
          meals: [meal('one', start, 130)],
        ),
      );
      await openWeek(tester);
      expect(find.byKey(const ValueKey('weekly-chart')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
