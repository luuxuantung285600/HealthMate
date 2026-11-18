import '../../nutrition/models/nutrition_models.dart';

/// Length shows catalog kcal / goal. Color shares describe macro energy only;
/// 4/4/9 estimates need not equal the catalog's recorded kcal.
class CalorieRingData {
  CalorieRingData({
    required double? consumed,
    required double? target,
    required NutritionTotals? totals,
  }) {
    hasProgress =
        consumed != null &&
        consumed.isFinite &&
        consumed >= 0 &&
        target != null &&
        target.isFinite &&
        target > 0;
    progress = hasProgress ? (consumed! / target!).clamp(0.0, 1.0) : 0;
    final grams = totals == null
        ? <double>[]
        : [totals.proteinG, totals.carbsG, totals.fatG];
    final valid =
        totals?.hasCompleteMacros == true &&
        grams.every((value) => value.isFinite && value >= 0);
    final energy = valid
        ? [grams[0] * 4, grams[1] * 4, grams[2] * 9]
        : const <double>[];
    final sum = energy.fold(0.0, (total, value) => total + value);
    hasComposition = valid && sum.isFinite && sum > 0;
    shares = List.unmodifiable(
      hasComposition ? energy.map((value) => value / sum) : [0.0, 0.0, 0.0],
    );
  }

  late final double progress;
  late final bool hasProgress, hasComposition;
  // Protein, carbohydrate, fat. Sugar/fiber are not additional energy slices.
  late final List<double> shares;
}
