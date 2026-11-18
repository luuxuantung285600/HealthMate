import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/activity/models/activity_energy.dart';
import 'package:healthmate/features/activity/presentation/activity_log_dialog.dart';
import 'package:healthmate/features/activity/providers/activity_providers.dart';
import 'package:healthmate/features/journal/models/daily_log_failure.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/wellness/providers/energy_providers.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'support/test_app.dart';
import 'support/load_icon_font.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_activity_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_target_repository.dart';

class _LostAcknowledgment extends FakeActivityRepository {
  final drafts = <ActivityLogDraft>[];
  @override
  Future<String> add({
    required String uid,
    required ActivityLogDraft draft,
    String? operationId,
  }) async {
    drafts.add(draft);
    final result = await super.add(
      uid: uid,
      draft: draft,
      operationId: operationId,
    );
    if (drafts.length == 1) throw const DailyLogFailure('Mất xác nhận');
    return result;
  }
}

void main() {
  setUpAll(loadIconFont);
  final now = DateTime.now();
  final uid = FakeAuthRepository.testUser.uid;
  BodyMetric metric(String id, double kg, DateTime at) => BodyMetric(
    id: id,
    weightKg: kg,
    measuredAt: at,
    note: '',
    createdAt: at,
    updatedAt: at,
  );
  FakeNutritionTargetRepository targets() =>
      FakeNutritionTargetRepository()
        ..byUid[uid] = {
          '2026-01-01': const NutritionTarget(
            effectiveFromDateKey: '2026-01-01',
            kcalTarget: 1800,
          ),
        };
  FakeHealthProfileRepository profile() => FakeHealthProfileRepository(
    profile: FakeHealthProfileRepository.testProfile,
    metrics: [
      metric('before', 60, now.subtract(const Duration(days: 1))),
      metric('future', 100, now.add(const Duration(days: 1))),
    ],
  );
  Future<void> choose(WidgetTester tester, String type, String text) async {
    final field = find.byKey(ValueKey('activity-met-$type'));
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(text).last);
    await tester.pumpAndSettle();
  }

  Future<ActivityLogDraft?> open(WidgetTester tester, {ActivityLog? log}) {
    final context = tester.element(find.byType(Scaffold).first);
    return showDialog<ActivityLogDraft>(
      context: context,
      builder: (_) => ActivityLogDialog(selectedDate: now, log: log),
    );
  }

  testWidgets(
    'manual entry uses prior weight; confirmed credit follows add/edit/delete in real time',
    (tester) async {
      final activities = FakeActivityRepository();
      final p = profile();
      final c = await pumpApp(
        tester,
        profileRepository: p,
        targetRepository: targets(),
        activityRepository: activities,
        dashboardNow: now,
      );
      final result = open(tester);
      await tester.pumpAndSettle();
      await choose(tester, 'walking', 'Đi bộ vừa');
      expect(find.textContaining('≈ 84 kcal vận động thêm'), findsOneWidget);
      expect(find.textContaining('60 kg'), findsOneWidget);
      final check = find.byKey(const ValueKey('activity-include-budget'));
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-activity')));
      await tester.pumpAndSettle();
      final draft = (await result)!;
      expect(draft.energyEstimate!.weightKg, 60);
      expect(draft.energyEstimate!.includedInBudget, isTrue);
      final saved = await activities.add(uid: uid, draft: draft);
      await tester.pumpAndSettle();
      final day = draft.dateKey;
      expect(
        c.read(dailyEnergyBudgetProvider(day)).value!.kcalTarget,
        closeTo(1884, 1e-8),
      );
      await p.addBodyMetric(
        uid: uid,
        draft: BodyMetricDraft(weightKg: 80, measuredAt: now, note: ''),
      );
      await tester.pumpAndSettle();
      final logs = c.read(activityLogsProvider(day)).value!;
      expect(logs.single.energyEstimate!.weightKg, 60);
      expect(logs.single.caloriesBurned, closeTo(84, 1e-8));
      final update = c
          .read(activityControllerProvider.notifier)
          .update(
            saved,
            ActivityLogDraft(
              type: draft.type,
              durationMinutes: 15,
              performedAt: draft.performedAt,
              energyEstimate: ActivityEnergyEstimate(
                metCode: '17190',
                weightKg: 60,
                weightMeasuredAt: draft.energyEstimate!.weightMeasuredAt,
                ageYears: 26,
                durationSeconds: 900,
                budgetTargetFromDateKey: '2026-01-01',
                budgetBaseKcal: 1800,
              ),
            ),
          );
      bool? updateResult;
      update.then((v) => updateResult = v);
      await tester.pumpAndSettle();
      expect(updateResult, isTrue);
      expect(
        c.read(dailyEnergyBudgetProvider(day)).value!.kcalTarget,
        closeTo(1842, 1e-8),
      );
      final deleted = c.read(activityControllerProvider.notifier).delete(saved);
      bool? deleteResult;
      deleted.then((v) => deleteResult = v);
      await tester.pumpAndSettle();
      expect(deleteResult, isTrue);
      expect(c.read(dailyEnergyBudgetProvider(day)).value!.kcalTarget, 1800);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'missing weight still saves honest minutes; legacy note edit adds no calories',
    (tester) async {
      await pumpApp(tester, targetRepository: targets());
      final result = open(tester);
      await tester.pumpAndSettle();
      await choose(tester, 'walking', 'Đi bộ vừa');
      expect(find.byKey(const ValueKey('activity-active-kcal')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('save-activity')));
      await tester.pumpAndSettle();
      expect((await result)!.energyEstimate, isNull);
      final legacy = ActivityLog(
        id: 'legacy',
        type: ActivityType.walking,
        durationMinutes: 30,
        performedAt: now,
        dateKey: localDateKey(now),
        timezoneOffsetMinutes: now.timeZoneOffset.inMinutes,
        note: 'old',
      );
      final edited = open(tester, log: legacy);
      await tester.pumpAndSettle();
      final note = find.byKey(const ValueKey('activity-note'));
      await tester.ensureVisible(note);
      await tester.enterText(note, 'new note');
      await tester.tap(find.byKey(const ValueKey('save-activity')));
      await tester.pumpAndSettle();
      expect((await edited)!.energyEstimate, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'editing an estimated log preserves history; changing duration requires a new budget confirmation',
    (tester) async {
      await pumpApp(
        tester,
        profileRepository: profile(),
        targetRepository: targets(),
        size: const Size(320, 740),
        textScale: 1.5,
      );
      final e = ActivityEnergyEstimate(
        metCode: '17190',
        weightKg: 55,
        weightMeasuredAt: now.subtract(const Duration(days: 7)),
        ageYears: 26,
        durationSeconds: 1817,
        budgetTargetFromDateKey: '2026-01-01',
        budgetBaseKcal: 1800,
      );
      final original = ActivityLog(
        id: 'snapshot',
        type: ActivityType.walking,
        durationMinutes: 30,
        performedAt: now.subtract(const Duration(hours: 1)),
        dateKey: localDateKey(now),
        timezoneOffsetMinutes: now.timeZoneOffset.inMinutes,
        note: 'old',
        energyEstimate: e,
      );
      final first = open(tester, log: original);
      await tester.pumpAndSettle();
      final note = find.byKey(const ValueKey('activity-note'));
      await tester.ensureVisible(note);
      await tester.enterText(note, 'updated note');
      await tester.tap(find.byKey(const ValueKey('save-activity')));
      await tester.pumpAndSettle();
      expect((await first)!.energyEstimate!.toData(), e.toData());
      final second = open(tester, log: original);
      await tester.pumpAndSettle();
      final budgetCheck = find.byKey(const ValueKey('activity-include-budget'));
      await tester.ensureVisible(budgetCheck);
      await tester.tap(budgetCheck);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-activity')));
      await tester.pumpAndSettle();
      final noBudget = (await second)!.energyEstimate!;
      expect(noBudget.weightKg, 55);
      expect(noBudget.durationSeconds, 1817);
      expect(noBudget.includedInBudget, isFalse);
      final third = open(tester, log: original);
      await tester.pumpAndSettle();
      final duration = find.byKey(const ValueKey('activity-duration'));
      await tester.ensureVisible(duration);
      await tester.enterText(duration, '15');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-activity')));
      await tester.pumpAndSettle();
      final changed = (await third)!.energyEstimate!;
      expect(changed.weightKg, 60);
      expect(changed.durationSeconds, 900);
      expect(changed.includedInBudget, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'timer retry freezes calorie inputs even when profile weight changes',
    (tester) async {
      final a = _LostAcknowledgment(), p = profile();
      final c = await pumpApp(
        tester,
        activityRepository: a,
        profileRepository: p,
        targetRepository: targets(),
      );
      c
          .read(appRouterProvider)
          .go('${AppRoutes.workouts}/full_body/session?pace=standard');
      await tester.pump();
      await tester.pump(const Duration(seconds: 89));
      await tester.tap(find.byKey(const ValueKey('finish-workout')));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.byKey(const ValueKey('confirm-end-workout')));
      await tester.pumpAndSettle();
      await choose(tester, 'strength', 'Thể dục vừa');
      await tester.tap(find.byKey(const ValueKey('save-workout')));
      await tester.pumpAndSettle();
      expect(a.drafts.length, 1);
      final snapshot = a.drafts.first.energyEstimate!;
      expect(snapshot.weightKg, 60);
      await p.updateBodyMetric(
        uid: uid,
        metricId: 'before',
        draft: BodyMetricDraft(
          weightKg: 90,
          measuredAt: now.subtract(const Duration(days: 1)),
          note: 'changed',
        ),
      );
      c.invalidate(userProfileProvider);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-workout')));
      await tester.pumpAndSettle();
      expect(a.drafts.length, 2);
      expect(a.drafts.last.energyEstimate!.toData(), snapshot.toData());
      expect(identical(a.drafts.first, a.drafts.last), isTrue);
      final logs = await a.loadRange(
        uid,
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day + 1),
      );
      expect(logs.length, 1);
      expect(logs.single.caloriesBurned, snapshot.activeKcal);
      expect(tester.takeException(), isNull);
    },
  );
}
