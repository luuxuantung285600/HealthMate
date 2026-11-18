import '../../nutrition/models/nutrition_models.dart';

/// Wall-clock time in the meal's recorded timezone, matching its stored dateKey.
/// Legacy entries without an offset retain the device-local interpretation.
/// UTC carries clock components only; this value is for display/grouping, never
/// persistence or conversion back with toLocal(). Both paths use the same
/// carrier so mixed legacy/offset entries sort by their displayed clock time.
DateTime journalMealTime(MealLog meal) {
  final offset = meal.timezoneOffsetMinutes;
  if (offset != null && offset >= -720 && offset <= 840) {
    return meal.consumedAt.toUtc().add(Duration(minutes: offset));
  }
  final local = meal.consumedAt.toLocal();
  return DateTime.utc(
    local.year,
    local.month,
    local.day,
    local.hour,
    local.minute,
    local.second,
    local.millisecond,
    local.microsecond,
  );
}

class MealHourGroup {
  const MealHourGroup(this.hour, this.meals);
  final int hour;
  final List<MealLog> meals;
  NutritionTotals get totals => totalMealNutrition(meals);
}

/// Presentation groups only: never round a persisted timestamp or change type.
List<MealHourGroup> groupMealsByHour(Iterable<MealLog> meals) {
  final hours = List.generate(24, (_) => <MealLog>[]);
  for (final meal in meals) {
    hours[journalMealTime(meal).hour].add(meal);
  }
  for (final group in hours) {
    group.sort((a, b) {
      final time = journalMealTime(a).compareTo(journalMealTime(b));
      return time != 0 ? time : a.id.compareTo(b.id);
    });
  }
  return List.unmodifiable([
    for (var hour = 0; hour < 24; hour++)
      MealHourGroup(hour, List.unmodifiable(hours[hour])),
  ]);
}

/// The current hour starts at the current minute; past hours start at :00.
/// Return null for future slots, consistent with meal entry validation.
DateTime? mealTimeForHour(DateTime day, int hour, DateTime now) {
  if (hour < 0 || hour > 23) throw RangeError.range(hour, 0, 23, 'hour');
  final clock = now.toLocal();
  final date = day.toLocal();
  final candidate = DateTime(date.year, date.month, date.day, hour);
  if (candidate.isAfter(clock)) return null;
  return date.year == clock.year &&
          date.month == clock.month &&
          date.day == clock.day &&
          hour == clock.hour
      ? DateTime(date.year, date.month, date.day, hour, clock.minute)
      : candidate;
}
