import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/progress/models/week_comparison.dart';
import 'package:healthmate/features/weekly_reflection/models/weekly_reflection.dart';
import 'weekly_reflection_test.dart' as f show meal, water, activity, weight;

void main() {
  final monday = DateTime(2026, 12, 28), today = DateTime(2027, 1, 1, 12);
  final before = DateTime(2026, 12, 21);
  WeekLogs empty() =>
      WeekLogs(meals: [], water: [], activities: [], loadedAt: today);
  WeekMetricComparison metric(WeekComparison c, ProgressMeasure m) =>
      c.metrics.singleWhere((row) => row.measure == m);

  test(
    'partial week compares only paired weekdays, keeping recorded zero and excluding future/unmatched values',
    () {
      final c = compareWeeks(
        start: monday,
        today: today,
        current: WeekLogs(
          meals: [
            f.meal('m', monday, 100),
            f.meal('t', DateTime(2026, 12, 29), 0),
            f.meal('th', DateTime(2026, 12, 31), 1000),
            f.meal('f', today, 600),
            f.meal('future', DateTime(2027, 1, 2), 9999),
          ],
          water: [],
          activities: [],
          loadedAt: today,
        ),
        previous: WeekLogs(
          meals: [
            f.meal('pm', before, 200),
            f.meal('pt', DateTime(2026, 12, 22), 0),
            f.meal('pw', DateTime(2026, 12, 23), 900),
            f.meal('pf', DateTime(2026, 12, 25), 300),
            f.meal('ps', DateTime(2026, 12, 26), 9999),
          ],
          water: [],
          activities: [],
          loadedAt: today,
        ),
      );
      expect(c.start, monday);
      expect(c.previousStart, before);
      expect(c.elapsedDays, 5);
      expect(c.lastDay, DateTime(2027, 1, 1));
      expect(c.previousLastDay, DateTime(2026, 12, 25));
      expect(c.inProgress, isTrue);
      final kcal = metric(c, ProgressMeasure.energy);
      expect(kcal.currentDays, 4);
      expect(kcal.previousDays, 4);
      expect(kcal.pairs.length, 3);
      expect(kcal.currentAverage, closeTo(700 / 3, .000001));
      expect(kcal.previousAverage, closeTo(500 / 3, .000001));
      expect(kcal.difference, closeTo(200 / 3, .000001));
      expect(kcal.pairs.map((p) => p.currentDate.weekday), [1, 2, 5]);
      expect(
        kcal.pairs.every(
          (p) => p.currentDate.weekday == p.previousDate.weekday,
        ),
        isTrue,
      );
    },
  );

  test(
    'weight comparison gives each measured day equal weight, de-duplicates IDs and excludes future dates',
    () {
      final c = compareWeeks(
        start: monday,
        today: today,
        current: WeekLogs(
          meals: [],
          water: [],
          activities: [],
          loadedAt: today,
          metrics: [
            f.weight('m1', monday, 60),
            f.weight('m2', DateTime(2026, 12, 28, 20), 64),
            f.weight('m1', monday, 60),
            f.weight('t1', DateTime(2026, 12, 29), 80),
            f.weight('future', DateTime(2027, 1, 2), 100),
          ],
        ),
        previous: WeekLogs(
          meals: [],
          water: [],
          activities: [],
          loadedAt: today,
          metrics: [
            f.weight('pm', before, 64),
            f.weight('pt', DateTime(2026, 12, 22), 82),
          ],
        ),
      );
      final weight = metric(c, ProgressMeasure.weight);
      expect(weight.currentDays, 2);
      expect(weight.previousDays, 2);
      expect(weight.currentAverage, 71);
      expect(weight.previousAverage, 73);
      expect(weight.difference, -2);
      expect(weight.pairs.first.currentValue, 62);
    },
  );

  test(
    'coverage is independent for each measure and non-overlapping weekdays are unknown',
    () {
      final c = compareWeeks(
        start: monday,
        today: today,
        current: WeekLogs(
          meals: [f.meal('m', monday, 0)],
          water: [f.water('w', DateTime(2026, 12, 29), 500)],
          activities: [f.activity('a', monday, 20)],
          loadedAt: today,
        ),
        previous: WeekLogs(
          meals: [f.meal('pm', before, 100)],
          water: [f.water('pw', before, 250)],
          activities: [f.activity('pa', before, 10)],
          loadedAt: today,
        ),
      );
      expect(metric(c, ProgressMeasure.energy).currentAverage, 0);
      expect(metric(c, ProgressMeasure.energy).difference, -100);
      final water = metric(c, ProgressMeasure.water);
      expect(water.currentDays, 1);
      expect(water.previousDays, 1);
      expect(water.currentAverage, isNull);
      expect(water.difference, isNull);
      expect(metric(c, ProgressMeasure.activity).difference, 10);
      expect(metric(c, ProgressMeasure.weight).pairs, isEmpty);
    },
  );

  test(
    'past weeks use all seven days; future and empty weeks invent no observations',
    () {
      final past = compareWeeks(
        start: before,
        today: today,
        current: empty(),
        previous: empty(),
      );
      expect(past.elapsedDays, 7);
      expect(past.inProgress, isFalse);
      expect(past.lastDay, DateTime(2026, 12, 27));
      expect(
        past.metrics.every(
          (r) =>
              r.currentAverage == null &&
              r.previousAverage == null &&
              r.difference == null,
        ),
        isTrue,
      );
      final future = compareWeeks(
        start: DateTime(2027, 1, 4),
        today: today,
        current: empty(),
        previous: empty(),
      );
      expect(future.elapsedDays, 0);
      expect(future.metrics.every((r) => r.pairs.isEmpty), isTrue);
    },
  );

  test(
    'recorded date keys and snapshots drive comparisons, duplicate logs are counted once',
    () {
      final m = f.meal(
        'one',
        DateTime(2026, 12, 27, 23),
        250,
        key: '2026-12-28',
      );
      final c = compareWeeks(
        start: monday,
        today: today,
        current: WeekLogs(
          meals: [m, m],
          water: [],
          activities: [],
          loadedAt: today,
        ),
        previous: WeekLogs(
          meals: [f.meal('p', before, 200)],
          water: [],
          activities: [],
          loadedAt: today,
        ),
      );
      expect(metric(c, ProgressMeasure.energy).currentAverage, 250);
      expect(metric(c, ProgressMeasure.energy).difference, 50);
    },
  );
}
