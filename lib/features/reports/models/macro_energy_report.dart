import '../../../core/utils/local_date_key.dart';
import '../../nutrition/models/nutrition_models.dart';
import 'period_report.dart';

enum EnergyMacro {
  carbs('Carb', 4),
  protein('Đạm', 4),
  fat('Chất béo', 9);

  const EnergyMacro(this.label, this.kcalPerGram);
  final String label;
  final double kcalPerGram;

  double grams(NutritionTotals value) => switch (this) {
    carbs => value.carbsG,
    protein => value.proteinG,
    fat => value.fatG,
  };
}

class MacroFoodContribution {
  const MacroFoodContribution({
    required this.meal,
    required this.item,
    required this.itemIndex,
    required this.dateKey,
  });

  final MealLog meal;
  final MealItemSnapshot item;
  final int itemIndex;
  final String dateKey;

  bool get complete =>
      item.hasNutritionData &&
      item.nutrition.hasCompleteMacros &&
      EnergyMacro.values.every((macro) {
        final grams = macro.grams(item.nutrition);
        return grams.isFinite && grams >= 0 && energy(macro).isFinite;
      });

  double energy(EnergyMacro macro) =>
      macro.grams(item.nutrition) * macro.kcalPerGram;
}

/// A read-only calculation over saved item snapshots. Catalog changes, stored
/// totalKcal and goals never supply or change this chart's denominator.
class MacroEnergyReport {
  MacroEnergyReport({
    required Iterable<MealLog> meals,
    required ReportRange range,
    required DateTime today,
  }) {
    range.validate();
    final first = localDateKey(range.start);
    final last = localDateKey(range.lastDay);
    final current = localDateKey(today);
    final scoped = <String, MealLog>{};
    for (final meal in meals) {
      final key = meal.dateKey ?? localDateKey(meal.consumedAt.toLocal());
      if (key.compareTo(first) >= 0 &&
          key.compareTo(last) <= 0 &&
          key.compareTo(current) <= 0) {
        scoped[meal.id] = meal;
      }
    }
    mealCount = scoped.length;
    missingMealCount = scoped.values.where((m) => m.items.isEmpty).length;
    items = List.unmodifiable([
      for (final meal in scoped.values)
        for (final entry in meal.items.indexed)
          MacroFoodContribution(
            meal: meal,
            item: entry.$2,
            itemIndex: entry.$1,
            dateKey: meal.dateKey ?? localDateKey(meal.consumedAt.toLocal()),
          ),
    ]);
    incompleteItemCount = items.where((row) => !row.complete).length;
    estimatedItemCount = items.where((row) => row.item.isEstimated).length;
    _energy = {
      for (final macro in EnergyMacro.values)
        macro: items
            .where((row) => row.complete)
            .fold(0.0, (sum, row) => sum + row.energy(macro)),
    };
  }

  late final int mealCount, missingMealCount;
  late final int incompleteItemCount, estimatedItemCount;
  late final List<MacroFoodContribution> items;
  late final Map<EnergyMacro, double> _energy;

  bool get complete =>
      mealCount > 0 && missingMealCount == 0 && incompleteItemCount == 0;
  double energy(EnergyMacro macro) => _energy[macro]!;
  double grams(EnergyMacro macro) => energy(macro) / macro.kcalPerGram;
  double get totalEnergy => _energy.values.fold(0.0, (sum, v) => sum + v);
  bool get canChart => complete && totalEnergy.isFinite && totalEnergy > 0;
  double? percent(EnergyMacro macro) =>
      canChart ? energy(macro) / totalEnergy * 100 : null;

  List<MacroFoodContribution> contributions(EnergyMacro macro) {
    if (!canChart) return const [];
    return items.where((row) => row.energy(macro) > 0).toList()..sort((a, b) {
      final energyOrder = b.energy(macro).compareTo(a.energy(macro));
      if (energyOrder != 0) return energyOrder;
      final dateOrder = b.dateKey.compareTo(a.dateKey);
      if (dateOrder != 0) return dateOrder;
      final mealOrder = a.meal.id.compareTo(b.meal.id);
      return mealOrder != 0 ? mealOrder : a.itemIndex.compareTo(b.itemIndex);
    });
  }
}
