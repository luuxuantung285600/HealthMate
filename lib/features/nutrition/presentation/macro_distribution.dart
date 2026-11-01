import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/reference_palette.dart';
import '../models/nutrition_models.dart';

class MacroDistribution extends StatelessWidget {
  const MacroDistribution({required this.totals, this.extra, super.key});
  final NutritionTotals? totals;
  final ({String label, String value, Color color})? extra;
  @override
  Widget build(BuildContext context) {
    final t = totals;
    final energy = t == null ? 0.0 : t.carbsG * 4 + t.proteinG * 4 + t.fatG * 9;
    final known = t?.hasCompleteMacros == true && energy > 0;
    final parts = [
      (
        label: 'Carb',
        amount: (t?.carbsG ?? 0) * 4,
        color: ReferencePalette.carb,
      ),
      (
        label: 'Đạm',
        amount: (t?.proteinG ?? 0) * 4,
        color: ReferencePalette.protein,
      ),
      (
        label: 'Chất béo',
        amount: (t?.fatG ?? 0) * 9,
        color: ReferencePalette.fat,
      ),
    ];
    Widget legend(
      String label,
      String value,
      Color color, {
      bool stacked = false,
    }) {
      if (stacked) {
        return Column(
          children: [
            Wrap(
              spacing: 6,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }
      return Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 6,
          child: Row(
            children: known
                ? [
                    for (final p in parts)
                      if (p.amount > 0) ...[
                        Expanded(
                          flex: (p.amount / energy * 10000).round().clamp(
                            1,
                            10000,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: p.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        if (p != parts.last) const SizedBox(width: 6),
                      ],
                  ]
                : [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final columns = extra == null ? 3 : 2;
            final count = MediaQuery.textScalerOf(context).scale(1) > 1.3
                ? 1
                : columns;
            return Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                for (final p in parts)
                  SizedBox(
                    width: (c.maxWidth - 16 * (count - 1)) / count,
                    child: legend(
                      p.label,
                      known
                          ? '${NumberFormat('0', 'vi').format(p.amount / energy * 100)}%'
                          : '—',
                      p.color,
                      stacked: count == 3,
                    ),
                  ),
                if (extra != null)
                  SizedBox(
                    width: (c.maxWidth - 16 * (count - 1)) / count,
                    child: legend(extra!.label, extra!.value, extra!.color),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
