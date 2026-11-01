import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/water/models/water_log.dart';

import 'support/fake_activity_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/test_app.dart';

void main() {
  group('daily log calculations and validation', () {
    test('creates a stable local date key', () {
      expect(localDateKey(DateTime(2026, 2, 3, 23, 30)), '2026-02-03');
    });

    test('validates real calendar dates instead of only their shape', () {
      expect(isValidDateKey('2026-10-13'), isTrue);
      expect(isValidDateKey('2028-02-29'), isTrue);
      expect(isValidDateKey('2026-02-29'), isFalse);
      expect(isValidDateKey('2026-02-30'), isFalse);
      expect(isValidDateKey('2026-13-01'), isFalse);
      expect(isValidDateKey('2026-2-03'), isFalse);
    });

    test('uses the recorded offset across a local-midnight boundary', () {
      const offset = 420;
      expect(
        dateKeyFromTimestampAndOffset(
          DateTime.utc(2026, 10, 13, 16, 59),
          offset,
        ),
        '2026-10-13',
      );
      expect(
        dateKeyFromTimestampAndOffset(DateTime.utc(2026, 10, 13, 17), offset),
        '2026-10-14',
      );
    });

    test('detects mismatched timestamp, date key and timezone offset', () {
      final timestamp = DateTime.utc(2026, 10, 13, 17, 30);
      expect(
        dateKeyMatchesTimestamp(
          dateKey: '2026-10-14',
          timestamp: timestamp,
          timezoneOffsetMinutes: 420,
        ),
        isTrue,
      );
      expect(
        dateKeyMatchesTimestamp(
          dateKey: '2026-10-13',
          timestamp: timestamp,
          timezoneOffsetMinutes: 420,
        ),
        isFalse,
      );
      expect(
        dateKeyMatchesTimestamp(
          dateKey: '2026-10-14',
          timestamp: timestamp,
          timezoneOffsetMinutes: 0,
        ),
        isFalse,
      );
    });

    test('drafts recalculate dependent date fields after timestamp edits', () {
      final beforeMidnight = DateTime(2026, 10, 13, 23, 59);
      final afterMidnight = DateTime(2026, 10, 14);
      final originalWater = WaterLogDraft(
        amountMl: 250,
        consumedAt: beforeMidnight,
      );
      final editedWater = WaterLogDraft(
        amountMl: 250,
        consumedAt: afterMidnight,
      );
      final editedActivity = ActivityLogDraft(
        type: ActivityType.walking,
        durationMinutes: 30,
        performedAt: afterMidnight,
      );

      expect(originalWater.dateKey, '2026-10-13');
      expect(editedWater.dateKey, '2026-10-14');
      expect(editedActivity.dateKey, '2026-10-14');
      expect(
        editedWater.timezoneOffsetMinutes,
        afterMidnight.timeZoneOffset.inMinutes,
      );
      expect(
        editedActivity.timezoneOffsetMinutes,
        afterMidnight.timeZoneOffset.inMinutes,
      );
    });

    test('validates water amount and activity duration', () {
      expect(WaterValidation.amount('49'), isNotNull);
      expect(WaterValidation.amount('250'), isNull);
      expect(WaterValidation.amount('5001'), isNotNull);
      expect(ActivityValidation.duration('0'), isNotNull);
      expect(ActivityValidation.duration('30'), isNull);
      expect(ActivityValidation.duration('1441'), isNotNull);
      final now = DateTime(2026, 10, 13, 10);
      expect(
        WaterValidation.consumedAt(now.add(const Duration(hours: 1)), now: now),
        isNotNull,
      );
      expect(ActivityValidation.performedAt(now, now: now), isNull);
    });

    test('totals reflect the current log list', () {
      final now = DateTime(2026, 10, 13, 8);
      expect(
        totalWaterMl([
          WaterLog(
            id: '1',
            amountMl: 250,
            consumedAt: now,
            dateKey: '2026-10-13',
            timezoneOffsetMinutes: 420,
          ),
          WaterLog(
            id: '2',
            amountMl: 350,
            consumedAt: now,
            dateKey: '2026-10-13',
            timezoneOffsetMinutes: 420,
          ),
        ]),
        600,
      );
      expect(
        totalActivityMinutes([
          ActivityLog(
            id: '1',
            type: ActivityType.walking,
            durationMinutes: 20,
            performedAt: now,
            dateKey: '2026-10-13',
            timezoneOffsetMinutes: 420,
            note: '',
          ),
          ActivityLog(
            id: '2',
            type: ActivityType.yoga,
            durationMinutes: 15,
            performedAt: now,
            dateKey: '2026-10-13',
            timezoneOffsetMinutes: 420,
            note: '',
          ),
        ]),
        35,
      );
    });
  });

  testWidgets('adds water and activity entries for the selected day', (
    tester,
  ) async {
    final water = FakeWaterRepository();
    final activity = FakeActivityRepository();
    final container = await pumpApp(
      tester,
      waterRepository: water,
      activityRepository: activity,
    );
    container.read(appRouterProvider).go(AppRoutes.journal);
    await tester.pumpAndSettle();

    final addWater = find.byKey(const ValueKey('add-water'));
    tester.widget<FilledButton>(addWater).onPressed!();
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('water-amount')), '300');
    await tester.tap(find.byKey(const ValueKey('save-water')));
    await tester.pumpAndSettle();
    expect(water.addCalls, 1);
    expect(find.textContaining('300 ml'), findsWidgets);

    Finder waterMenu() => find.descendant(
      of: find.byKey(const ValueKey('water-log-water-1')),
      matching: find.byType(PopupMenuButton<String>),
    );
    tester.widget<PopupMenuButton<String>>(waterMenu()).onSelected!('edit');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('water-amount')), '450');
    await tester.tap(find.byKey(const ValueKey('save-water')));
    await tester.pumpAndSettle();
    expect(water.updateCalls, 1);
    expect(find.textContaining('450 ml'), findsWidgets);

    tester.widget<PopupMenuButton<String>>(waterMenu()).onSelected!('delete');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(water.deleteCalls, 1);
    expect(water.logs, isEmpty);

    await openActivityDetails(tester);
    final addActivity = find.byKey(const ValueKey('add-activity'));
    tester.widget<FilledButton>(addActivity).onPressed!();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('activity-duration')),
      '45',
    );
    await tester.tap(find.byKey(const ValueKey('save-activity')));
    await tester.pumpAndSettle();
    expect(activity.addCalls, 1);
    expect(find.textContaining('45 phút'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
