import '../../../core/utils/local_date_key.dart';
import '../../profile/models/body_metric.dart';
import '../../weekly_reflection/models/weekly_reflection.dart';

enum ProgressMeasure { energy, weight, water, activity }

class ComparedDay {
  const ComparedDay({
    required this.currentDate,
    required this.previousDate,
    required this.currentValue,
    required this.previousValue,
  });
  final DateTime currentDate, previousDate;
  final double currentValue, previousValue;
}

/// Each metric has its own coverage. Only matching weekdays with observations
/// on BOTH sides enter the means; absent days never become zero observations.
class WeekMetricComparison {
  const WeekMetricComparison({
    required this.measure,
    required this.currentDays,
    required this.previousDays,
    required this.pairs,
  });
  final ProgressMeasure measure;
  final int currentDays, previousDays;
  final List<ComparedDay> pairs;
  double? get currentAverage => pairs.isEmpty
      ? null
      : pairs.fold(0.0, (sum, p) => sum + p.currentValue) / pairs.length;
  double? get previousAverage => pairs.isEmpty
      ? null
      : pairs.fold(0.0, (sum, p) => sum + p.previousValue) / pairs.length;
  double? get difference =>
      pairs.isEmpty ? null : currentAverage! - previousAverage!;
}

class WeekComparison {
  const WeekComparison({
    required this.start,
    required this.previousStart,
    required this.elapsedDays,
    required this.inProgress,
    required this.metrics,
  });
  final DateTime start, previousStart;
  final int elapsedDays;
  final bool inProgress;
  final List<WeekMetricComparison> metrics;
  DateTime get lastDay =>
      DateTime(start.year, start.month, start.day + elapsedDays - 1);
  DateTime get previousLastDay => DateTime(
    previousStart.year,
    previousStart.month,
    previousStart.day + elapsedDays - 1,
  );
}

WeekComparison compareWeeks({
  required DateTime start,
  required DateTime today,
  required WeekLogs current,
  required WeekLogs previous,
}) {
  final first = weekStart(start);
  final before = DateTime(first.year, first.month, first.day - 7);
  final currentWeek = summarizeWeek(first, today, current);
  final previousWeek = summarizeWeek(before, today, previous);
  final count = currentWeek.eligibleDays;
  final weights = _dailyWeights(currentWeek.metrics);
  final previousWeights = _dailyWeights(previousWeek.metrics);

  double? value(
    DayReflection day,
    ProgressMeasure measure,
    Map<String, double> weight,
  ) => switch (measure) {
    ProgressMeasure.energy => day.mealCount > 0 ? day.nutrition.kcal : null,
    ProgressMeasure.weight => weight[localDateKey(day.date)],
    ProgressMeasure.water => day.waterCount > 0 ? day.waterMl.toDouble() : null,
    ProgressMeasure.activity =>
      day.activityCount > 0 ? day.activityMinutes.toDouble() : null,
  };

  return WeekComparison(
    start: first,
    previousStart: before,
    elapsedDays: count,
    inProgress: first == weekStart(today),
    metrics: [
      for (final measure in ProgressMeasure.values)
        (() {
          final pairs = <ComparedDay>[];
          var currentDays = 0, previousDays = 0;
          for (var i = 0; i < count; i++) {
            final day = currentWeek.days[i], earlier = previousWeek.days[i];
            final currentValue = value(day, measure, weights);
            final previousValue = value(earlier, measure, previousWeights);
            if (currentValue != null) currentDays++;
            if (previousValue != null) previousDays++;
            if (currentValue != null && previousValue != null) {
              pairs.add(
                ComparedDay(
                  currentDate: day.date,
                  previousDate: earlier.date,
                  currentValue: currentValue,
                  previousValue: previousValue,
                ),
              );
            }
          }
          return WeekMetricComparison(
            measure: measure,
            currentDays: currentDays,
            previousDays: previousDays,
            pairs: List.unmodifiable(pairs),
          );
        })(),
    ],
  );
}

/// Weighing several times in one day does not give that day extra weight in
/// the comparison. De-duplicate IDs before computing the day's arithmetic mean.
Map<String, double> _dailyWeights(Iterable<BodyMetric> metrics) {
  final sums = <String, double>{}, counts = <String, int>{};
  final seen = <String>{};
  for (final metric in metrics) {
    if (!seen.add(metric.id)) continue;
    final day = localDateKey(metric.measuredAt);
    sums[day] = (sums[day] ?? 0) + metric.weightKg;
    counts[day] = (counts[day] ?? 0) + 1;
  }
  return {for (final day in sums.keys) day: sums[day]! / counts[day]!};
}
