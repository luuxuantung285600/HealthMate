import 'package:flutter/material.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/widgets/metric_tile.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'package:healthmate/features/water/models/water_log.dart';

import 'support/fake_activity_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/test_app.dart';

void main() {
  final now = DateTime(2026, 10, 13, 9, 30);

  testWidgets('dashboard shows a useful empty state for a day without data', (
    tester,
  ) async {
    await pumpApp(tester, dashboardNow: now);

    expect(find.text('Hôm nay'), findsNWidgets(2));
    expect(find.text('Thứ Ba, 13 tháng 10'), findsOneWidget);
    expect(find.text('Chưa ghi món'), findsNWidgets(4));
    expect(find.byKey(const ValueKey('dashboard-today-card')), findsOneWidget);
    expect(find.textContaining('kcal còn lại'), findsNothing);
    expect(find.textContaining('Gemini'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard summarizes only real repository data for today', (
    tester,
  ) async {
    final nutrition = FakeNutritionRepository(
      meals: [
        MealLog(
          id: 'meal-today',
          type: MealType.breakfast,
          consumedAt: DateTime(2026, 10, 13, 8),
          items: [
            MealItemSnapshot.fromCatalog(FakeNutritionRepository.rice, 100),
          ],
          totals: FakeNutritionRepository.rice.forGrams(100),
          source: MealSource.manual,
          dateKey: '2026-10-13',
          timezoneOffsetMinutes: now.timeZoneOffset.inMinutes,
        ),
      ],
    );
    final water = FakeWaterRepository(
      logs: [
        _water('water-1', 500, DateTime(2026, 10, 13, 8, 30)),
        _water('water-2', 250, DateTime(2026, 10, 13, 9)),
        _water('water-old', 900, DateTime(2026, 10, 12, 9)),
      ],
    );
    final activity = FakeActivityRepository(
      logs: [
        _activity('activity-1', 35, DateTime(2026, 10, 13, 7)),
        _activity('activity-old', 80, DateTime(2026, 10, 12, 7)),
      ],
    );
    final profile = FakeHealthProfileRepository(
      profile: FakeHealthProfileRepository.testProfile,
      metrics: [
        _metric('older', 73.2, DateTime(2026, 10, 1)),
        _metric('latest', 72.4, DateTime(2026, 10, 12)),
      ],
    );

    await pumpApp(
      tester,
      dashboardNow: now,
      nutritionRepository: nutrition,
      waterRepository: water,
      activityRepository: activity,
      profileRepository: profile,
    );

    expect(find.byKey(const ValueKey('dashboard-today-card')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('dashboard-today-card')),
        matching: find.text('130'),
      ),
      findsOneWidget,
    );
    await openDashboardDetails(tester);
    expect(_tile(tester, 'dashboard-water').value, '750');
    expect(_tile(tester, 'dashboard-activity').value, '35');
    expect(_tile(tester, 'dashboard-meals').value, '1');
    expect(_tile(tester, 'dashboard-weight').value, '72,4');

    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('dashboard-quick-water'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dashboard-quick-water')));
    await tester.pumpAndSettle();
    expect(water.addCalls, 1);
    expect(_tile(tester, 'dashboard-water').value, '1.000');
    expect(find.text('Đã ghi nhanh 250 ml nước.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 1.5]) {
    testWidgets(
      'opt-in scanner navigation and five quick actions fit text scale $scale',
      (tester) async {
        await pumpApp(
          tester,
          textScale: scale,
          dashboardNow: now,
          featureFlags: const AppFeatureFlags(foodScannerEnabled: true),
        );

        await tester.tap(find.byKey(const ValueKey('nav-journal')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('journal-screen')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('nav-profile')));
        await tester.pumpAndSettle();
        expect(find.text('Không gian cá nhân'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('nav-dashboard')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('quick-add-menu')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('meal-entry-manual')), findsOneWidget);
        expect(find.byKey(const ValueKey('meal-entry-photo')), findsOneWidget);
        expect(find.byKey(const ValueKey('food-search')), findsOneWidget);
        expect(find.textContaining('Gemini'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('quick action reuses the existing journal entry flow', (
    tester,
  ) async {
    await pumpApp(tester, dashboardNow: now);
    await tester.tap(find.byKey(const ValueKey('quick-add-menu')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('journal-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('save-meal')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

MetricTile _tile(WidgetTester tester, String key) =>
    tester.widget<MetricTile>(find.byKey(ValueKey(key)));

WaterLog _water(String id, int amount, DateTime consumedAt) => WaterLog(
  id: id,
  amountMl: amount,
  consumedAt: consumedAt,
  dateKey:
      '${consumedAt.year.toString().padLeft(4, '0')}-${consumedAt.month.toString().padLeft(2, '0')}-${consumedAt.day.toString().padLeft(2, '0')}',
  timezoneOffsetMinutes: consumedAt.timeZoneOffset.inMinutes,
);

ActivityLog _activity(
  String id,
  int duration,
  DateTime performedAt,
) => ActivityLog(
  id: id,
  type: ActivityType.walking,
  durationMinutes: duration,
  performedAt: performedAt,
  dateKey:
      '${performedAt.year.toString().padLeft(4, '0')}-${performedAt.month.toString().padLeft(2, '0')}-${performedAt.day.toString().padLeft(2, '0')}',
  timezoneOffsetMinutes: performedAt.timeZoneOffset.inMinutes,
  note: '',
);

BodyMetric _metric(String id, double weight, DateTime measuredAt) => BodyMetric(
  id: id,
  weightKg: weight,
  measuredAt: measuredAt,
  note: '',
  createdAt: measuredAt,
  updatedAt: measuredAt,
);
