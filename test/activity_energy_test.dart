import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/activity/models/activity_energy.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/activity/models/guided_workout.dart';
import 'package:healthmate/features/activity/models/workout_session.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/wellness/models/energy_budget.dart';
import 'package:healthmate/features/data_export/models/journal_csv.dart';

void main() {
  final at = DateTime(2026, 11, 16, 10);
  const target = NutritionTarget(
    effectiveFromDateKey: '2026-11-01',
    kcalTarget: 1800,
  );
  ActivityEnergyEstimate estimate({
    int seconds = 1800,
    String code = '02022',
    bool include = false,
  }) => ActivityEnergyEstimate(
    metCode: code,
    weightKg: 60,
    weightMeasuredAt: at.subtract(const Duration(days: 1)),
    ageYears: 26,
    durationSeconds: seconds,
    budgetTargetFromDateKey: include ? target.effectiveFromDateKey : null,
    budgetBaseKcal: include ? target.kcalTarget : null,
  );
  ActivityLog log(ActivityEnergyEstimate? e) => ActivityLog(
    id: 'one',
    type: ActivityType.strength,
    durationMinutes: 30,
    performedAt: at,
    dateKey: '2026-11-16',
    timezoneOffsetMinutes: 420,
    note: '',
    energyEstimate: e,
  );

  test(
    'Compendium 1 kcal/kg/hour convention; separate gross from above rest',
    () {
      expect(estimate().grossKcal, closeTo(114, 1e-10));
      expect(estimate().activeKcal, closeTo(84, 1e-10));
      expect(estimate().grossKcal - estimate().activeKcal, closeTo(30, 1e-10));
      expect(estimate(code: '02020').grossKcal, 225);
      expect(estimate(code: '02020').activeKcal, 195);
      expect(log(null).caloriesBurned, isNull);
    },
  );
  test('fixed v1 catalog values match the published 2024 codes', () {
    expect(
      {for (final e in activityMetCatalog) e.code: e.met},
      {
        '17152': 2.8,
        '17190': 3.8,
        '17200': 4.8,
        '12020': 7.5,
        '12025': 4.8,
        '01010': 4.0,
        '01020': 6.8,
        '01030': 8.0,
        '02024': 2.8,
        '02056': 3.0,
        '02022': 3.8,
        '02020': 7.5,
        '02054': 3.5,
        '02050': 6.0,
        '02150': 2.3,
        '02160': 4.0,
      },
    );
  });
  test(
    'snapshot round trip retains exact time, source and historical weight',
    () {
      final e = estimate(seconds: 1817, include: true);
      final read = ActivityEnergyEstimate.fromData(e.toData());
      expect(read.toData(), e.toData());
      expect(read.activeKcal, closeTo(84.7933333333, 1e-8));
      expect(
        read.validFor(type: 'strength', minutes: 30, performedAt: at),
        isTrue,
      );
      expect(
        read.validFor(type: 'strength', minutes: 31, performedAt: at),
        isFalse,
      );
      expect(
        read.validFor(type: 'walking', minutes: 30, performedAt: at),
        isFalse,
      );
      expect(
        read.validFor(
          type: 'strength',
          minutes: 30,
          performedAt: at.subtract(const Duration(days: 2)),
        ),
        isFalse,
      );
      expect(log(e).toDraft().energyEstimate?.weightKg, 60);
      expect(
        () => ActivityEnergyEstimate.fromData({
          ...e.toData(),
          'formulaVersion': 2,
        }),
        throwsFormatException,
      );
    },
  );
  test(
    'unsupported ages, unknown codes and nonfinite weights cannot produce valid logs',
    () {
      for (final age in [18, 60]) {
        final e = ActivityEnergyEstimate(
          metCode: '02022',
          weightKg: 60,
          weightMeasuredAt: at,
          ageYears: age,
          durationSeconds: 1800,
        );
        expect(
          e.validFor(type: 'strength', minutes: 30, performedAt: at),
          isFalse,
        );
      }
      for (final kg in [double.nan, double.infinity, -60.0, 501.0]) {
        final e = ActivityEnergyEstimate(
          metCode: '02022',
          weightKg: kg,
          weightMeasuredAt: at,
          ageYears: 26,
          durationSeconds: 1800,
        );
        expect(
          e.validFor(type: 'strength', minutes: 30, performedAt: at),
          isFalse,
        );
      }
      expect(
        estimate(
          code: '99999',
        ).validFor(type: 'strength', minutes: 30, performedAt: at),
        isFalse,
      );
      expect(ageAtActivity(DateTime(2000, 11, 17), at), 25);
      expect(ageAtActivity(DateTime(2000, 11, 16), at), 26);
    },
  );
  test(
    'timer uses 64 actual work seconds; pause, rest and skipped work earn nothing',
    () {
      final s = WorkoutSession(
        workout: GuidedWorkouts.all.first,
        pace: WorkoutPace.standard,
      )..advance(const Duration(seconds: 89));
      s.paused = true;
      s.advance(const Duration(hours: 1));
      s.finishEarly();
      expect(s.workElapsed.inSeconds, 64);
      final draft = s.toDraft(
        at,
        energyEstimate: estimate(seconds: s.workElapsed.inSeconds),
      );
      expect(draft.durationMinutes, 1);
      expect(draft.caloriesBurned, closeTo(2.9866666667, 1e-9));
      expect(draft.energyEstimate!.grossKcal, closeTo(4.0533333333, 1e-9));
    },
  );
  test(
    'only explicit additional exercise confirmation credits above rest, not food',
    () {
      expect(
        resolveEnergyBudget(
          target,
          null,
          hasManualActivity: true,
          activities: [log(estimate())],
        ).remaining(1600),
        200,
      );
      final b = resolveEnergyBudget(
        target,
        null,
        hasManualActivity: true,
        activities: [log(estimate(include: true))],
      );
      expect(b.adjustmentKcal, closeTo(84, 1e-10));
      expect(b.activityAdjustmentKcal, closeTo(84, 1e-10));
      expect(b.stepAdjustmentKcal, 0);
      expect(b.remaining(1600), closeTo(284, 1e-10));
      expect(b.baseTarget, target);
      expect(
        resolveEnergyBudget(
          target,
          null,
          hasManualActivity: false,
          activities: [],
        ).remaining(1600),
        200,
      );
    },
  );
  test(
    'changed target disables old confirmation and exercise excludes step overlap',
    () {
      final e = estimate(include: true);
      final changed = resolveEnergyBudget(
        const NutritionTarget(
          effectiveFromDateKey: '2026-11-01',
          kcalTarget: 1900,
        ),
        null,
        hasManualActivity: true,
        activities: [log(e)],
      );
      expect(changed.adjustmentKcal, 0);
      expect(changed.hasUnappliedAdjustment, isTrue);
      final step = EnergyAdjustment(
        dateKey: '2026-11-16',
        timezoneOffsetMinutes: 420,
        steps: 6000,
        baselineSteps: 4000,
        stepLengthCm: 75,
        weightKg: 60,
        weightMeasuredAt: at,
        targetFromDateKey: '2026-11-01',
        baseKcalTarget: 1800,
        kcal: 40,
      );
      final b = resolveEnergyBudget(
        target,
        step,
        hasManualActivity: false,
        activities: [log(e)],
      );
      expect(b.adjustmentKcal, closeTo(84, 1e-10));
      expect(b.stepAdjustmentKcal, 0);
    },
  );
  test('CSV keeps exercise energy separate from calories consumed', () {
    final csv = buildJournalCsv(
      start: DateTime(2026, 11, 16),
      endExclusive: DateTime(2026, 11, 17),
      meals: [],
      water: [],
      activities: [log(estimate())],
      weights: [],
    );
    expect(csv, contains('activity_active_kcal'));
    expect(csv, contains('activity_energy_v1'));
    expect(csv, contains('2024 Adult Compendium'));
    expect(csv, contains('02022'));
  });
}
