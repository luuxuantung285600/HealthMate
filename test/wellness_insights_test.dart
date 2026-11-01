import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/journal/providers/journal_date_provider.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'package:healthmate/features/wellness/models/energy_budget.dart';
import 'package:healthmate/features/wellness/models/sleep_summary.dart';
import 'package:healthmate/features/wellness/models/wellness_models.dart';
import 'package:healthmate/features/wellness/presentation/energy_panel.dart';
import 'package:healthmate/features/wellness/presentation/weight_progress_panel.dart';
import 'package:healthmate/features/wellness/providers/energy_providers.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/chatbot/domain/personal_chat_context.dart';
import 'package:healthmate/features/chatbot/domain/chat_request.dart';
import 'support/fake_energy_repository.dart';
import 'support/fake_nutrition_target_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/fake_activity_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/test_app.dart';

EnergyAdjustment adjustment({double kcal = 50, double weight = 70}) =>
    EnergyAdjustment(
      dateKey: '2026-10-26',
      timezoneOffsetMinutes: 420,
      steps: 6000,
      baselineSteps: 4000,
      stepLengthCm: 75,
      weightKg: weight,
      weightMeasuredAt: DateTime(2026, 10, 25),
      targetFromDateKey: '2026-10-01',
      baseKcalTarget: 1800,
      kcal: kcal,
    );
const target = NutritionTarget(
  effectiveFromDateKey: '2026-10-01',
  kcalTarget: 1800,
);
SleepLog sleep(DateTime a, DateTime b) =>
    SleepLog(id: a.toIso8601String(), start: a, end: b, source: 'manual_entry');
BodyMetric metric(double kg, DateTime at) => BodyMetric(
  id: '$kg-$at',
  weightKg: kg,
  measuredAt: at,
  note: '',
  createdAt: null,
  updatedAt: null,
);

void main() {
  testWidgets(
    'dashboard diary and budget share confirmed credit; adding manual activity suspends it',
    (tester) async {
      final targets = FakeNutritionTargetRepository()
        ..byUid['test-uid'] = {'2026-10-01': target};
      final energy = FakeEnergyRepository()
        ..adjustments['test-uid/2026-10-26'] = adjustment();
      final activities = FakeActivityRepository();
      final container = await pumpApp(
        tester,
        dashboardNow: DateTime(2026, 10, 26, 12),
        targetRepository: targets,
        energyRepository: energy,
        activityRepository: activities,
      );
      expect(
        container
            .read(dailyEnergyBudgetProvider('2026-10-26'))
            .value!
            .kcalTarget,
        1850,
      );
      expect(find.text('Mục tiêu 1.850 kcal'), findsOneWidget);
      // Compare the same fixture day, independent of the machine's current date.
      container
          .read(journalDateProvider.notifier)
          .select(DateTime(2026, 10, 26));
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      expect(journalTotals('0 kcal / 1850 kcal'), findsOneWidget);
      await activities.add(
        uid: 'test-uid',
        draft: ActivityLogDraft(
          type: ActivityType.walking,
          durationMinutes: 30,
          performedAt: DateTime(2026, 10, 26, 11),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        container
            .read(dailyEnergyBudgetProvider('2026-10-26'))
            .value!
            .adjustmentKcal,
        0,
      );
      expect(journalTotals('0 kcal / 1800 kcal'), findsOneWidget);
      expect(find.textContaining('Có vận động nhập tay'), findsOneWidget);
    },
  );
  test('chat remaining uses the same confirmed budget', () async {
    final targets = FakeNutritionTargetRepository()
      ..byUid['test-uid'] = {'2026-10-01': target};
    final energy = FakeEnergyRepository()
      ..adjustments['test-uid/2026-10-26'] = adjustment();
    final context = PersonalChatContext(
      nutrition: FakeNutritionRepository(),
      water: FakeWaterRepository(),
      activity: FakeActivityRepository(),
      targets: targets,
      profile: FakeHealthProfileRepository(),
      energy: energy,
    );
    final answer = await context.answer(
      'test-uid',
      planChatRequest(
        'Hôm nay còn bao nhiêu kcal?',
        DateTime(2026, 10, 26),
        DateTime(2026, 10, 26, 12),
      ),
    );
    expect(answer, contains('1.850'));
    expect(answer, contains('50 kcal bước chân'));
    expect(answer, contains('Chưa có bữa'));
    expect(answer, isNot(contains('weightKg')));
  });
  test(
    'inconsistent wake-day totals over 24h are excluded instead of awarding a goal',
    () {
      final result = summarizeSleep(
        [
          sleep(DateTime(2026, 10, 25), DateTime(2026, 10, 26)),
          sleep(DateTime(2026, 10, 26, 1), DateTime(2026, 10, 26, 23)),
        ],
        DateTime(2026, 10, 26),
        1,
        goalMinutes: 480,
      );
      expect(result.inconsistentDays, 1);
      expect(result.averageMinutes, isNull);
      expect(result.daysAtGoal, 0);
    },
  );
  test(
    'walking estimate uses calibrated single-step distance and net above rest',
    () {
      const e = StepEnergyEstimate(6000, 75, 70, 4000);
      expect(e.distanceKm, 4.5);
      expect(e.netKcal, 157.5);
      expect(e.extraKcal, 52.5);
      expect(const StepEnergyEstimate(2000, 75, 70, 4000).extraKcal, 0);
    },
  );
  test(
    'default budget has no automatic credit and confirmed credit does not reduce food calories',
    () {
      expect(
        resolveEnergyBudget(
          target,
          null,
          hasManualActivity: false,
        ).remaining(1600),
        200,
      );
      final b = resolveEnergyBudget(
        target,
        adjustment(),
        hasManualActivity: false,
      );
      expect(b.kcalTarget, 1850);
      expect(b.remaining(1600), 250);
      expect(b.baseTarget.kcalTarget, 1800);
    },
  );
  test(
    'manual activity and changed target disable duplicate or obsolete credit',
    () {
      expect(
        resolveEnergyBudget(
          target,
          adjustment(),
          hasManualActivity: true,
        ).adjustmentKcal,
        0,
      );
      expect(
        resolveEnergyBudget(
          const NutritionTarget(
            effectiveFromDateKey: '2026-10-26',
            kcalTarget: 1800,
          ),
          adjustment(),
          hasManualActivity: false,
        ).adjustmentKcal,
        0,
      );
      expect(
        resolveEnergyBudget(
          const NutritionTarget(
            effectiveFromDateKey: '2026-10-01',
            kcalTarget: 1700,
          ),
          adjustment(),
          hasManualActivity: false,
        ).adjustmentKcal,
        0,
      );
    },
  );
  test(
    'credit rejects invented amount, nonfinite body data and excessive input',
    () {
      expect(adjustment(kcal: 53).validate(), isNotNull);
      expect(adjustment(kcal: 0).validate(), isNotNull);
      expect(adjustment(weight: double.nan).validate(), isNotNull);
      expect(adjustment(kcal: double.infinity).validate(), isNotNull);
      expect(adjustment().validate(), isNull);
      expect(const WellnessPreferences().validate(), isNull);
      expect(
        const WellnessPreferences(stepLengthCm: double.infinity).validate(),
        isNotNull,
      );
      expect(
        const WellnessPreferences(sleepGoalMinutes: 0).validate(),
        isNotNull,
      );
    },
  );
  test(
    'sleep overlap counted once by wake date and missing days excluded from averages',
    () {
      final s = summarizeSleep(
        [
          sleep(DateTime(2026, 10, 25, 23), DateTime(2026, 10, 26, 7)),
          sleep(DateTime(2026, 10, 26, 6), DateTime(2026, 10, 26, 8)),
        ],
        DateTime(2026, 10, 25),
        3,
        goalMinutes: 480,
      );
      expect(s.recorded.length, 1);
      expect(s.averageMinutes, 540);
      expect(s.daysAtGoal, 1);
      expect(s.days.first.minutes, isNull);
      expect(s.days.last.minutes, isNull);
    },
  );
  test(
    'bedtime variation respects midnight and naps do not replace main bedtime',
    () {
      final s = summarizeSleep(
        [
          sleep(DateTime(2026, 10, 24, 23, 50), DateTime(2026, 10, 25, 7)),
          sleep(DateTime(2026, 10, 26, 0, 10), DateTime(2026, 10, 26, 7)),
          sleep(DateTime(2026, 10, 26, 13), DateTime(2026, 10, 26, 14)),
        ],
        DateTime(2026, 10, 25),
        2,
      );
      expect(s.bedtimeVariationMinutes, closeTo(10, .001));
      expect(s.days.last.minutes, 470);
      expect(s.daysAtGoal, isNull);
    },
  );
  test(
    'weekly weights give each measured day equal weight and preserve missing weeks',
    () {
      final data = weeklyWeightAverages([
        metric(80, DateTime(2026, 10, 19)),
        metric(82, DateTime(2026, 10, 19, 12)),
        metric(79, DateTime(2026, 10, 20)),
        metric(78, DateTime(2026, 10, 26)),
      ]);
      expect(data, {'2026-10-19': 80.0, '2026-10-26': 78.0});
    },
  );
  testWidgets(
    'step budget requires explicit consent and preserves dialog on save failure',
    (tester) async {
      var writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('vi')],
          home: Scaffold(
            body: StepAdjustmentDialog(
              maximum: 52.5,
              create: (k) => adjustment(kcal: k),
              onSave: (a) async {
                writes++;
                return false;
              },
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('save-step-budget')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('ack-step-budget')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('step-adjustment-kcal')),
        '53',
      );
      await tester.tap(find.byKey(const ValueKey('save-step-budget')));
      await tester.pumpAndSettle();
      expect(writes, 0);
      await tester.enterText(
        find.byKey(const ValueKey('step-adjustment-kcal')),
        '50',
      );
      await tester.tap(find.byKey(const ValueKey('save-step-budget')));
      await tester.pumpAndSettle();
      expect(writes, 1);
      expect(find.byType(StepAdjustmentDialog), findsOneWidget);
    },
  );
}
