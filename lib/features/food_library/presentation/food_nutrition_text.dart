import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../nutrition/models/nutrition_models.dart';

String foodNumber(num value) => NumberFormat('0.##', 'vi_VN').format(value);
String macroAmount(double value, bool known) => known
    ? '${foodNumber(value)} g'
    : value > 0
    ? '≥${foodNumber(value)} g (chưa đủ)'
    : 'Chưa đủ dữ liệu';
String snapshotQuantityLabel(MealItemSnapshot item) =>
    '${foodNumber(item.quantity)} ${item.quantityUnitLabel}';
String nutritionLabel(NutritionTotals value) =>
    '${NumberFormat('0', 'vi_VN').format(value.kcal)} kcal · Đạm ${macroAmount(value.proteinG, value.proteinKnown)} · Carb ${macroAmount(value.carbsG, value.carbsKnown)} · Chất béo ${macroAmount(value.fatG, value.fatKnown)} · Chất xơ ${macroAmount(value.fiberG, value.fiberKnown)}';

class FoodNutritionSummary extends StatelessWidget {
  const FoodNutritionSummary({
    required this.value,
    this.showEnergy = true,
    super.key,
  });
  final NutritionTotals value;
  final bool showEnergy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: nutritionLabel(value),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          if (showEnergy)
            Text(
              '${foodNumber(value.kcal)} kcal',
              style: theme.textTheme.titleMedium,
            ),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final metric in [
                ('Đạm', value.proteinG, value.proteinKnown),
                ('Carb', value.carbsG, value.carbsKnown),
                ('Chất béo', value.fatG, value.fatKnown),
                ('Chất xơ', value.fiberG, value.fiberKnown),
              ])
                Text(
                  '${metric.$1} ${macroAmount(metric.$2, metric.$3)}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
