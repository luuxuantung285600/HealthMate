import 'package:flutter/material.dart';
import '../../../core/theme/app_meal_visuals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_card.dart';
import '../../nutrition/models/nutrition_models.dart';

class MealSummaryGrid extends StatelessWidget {
  const MealSummaryGrid({required this.meals, required this.onOpen, super.key});
  final AsyncValue<List<MealLog>> meals;
  final ValueChanged<MealType>? onOpen;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final theme = Theme.of(context);
      final columns =
          c.maxWidth < 300 || MediaQuery.textScalerOf(context).scale(1) > 1.4
          ? 1
          : 2;
      final ready = !meals.isLoading && !meals.hasError;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final type in MealType.values)
            SizedBox(
              width: (c.maxWidth - 12 * (columns - 1)) / columns,
              child: Builder(
                builder: (context) {
                  final entries = ready
                      ? meals.value?.where((m) => m.type == type).toList() ??
                            <MealLog>[]
                      : <MealLog>[];
                  return AppCard(
                    key: ValueKey('summary-meal-${type.name}'),
                    padding: const EdgeInsets.all(12),
                    onTap: onOpen == null ? null : () => onOpen!(type),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              AppMealVisuals.icon(type),
                              color: AppMealVisuals.color(context, type),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                type.label,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppMealVisuals.color(context, type),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          !ready
                              ? (meals.hasError
                                    ? 'Chưa tải được bữa ăn'
                                    : 'Đang tải…')
                              : entries.isEmpty
                              ? 'Chưa ghi nhận'
                              : '${NumberFormat('#,##0', 'vi').format(totalMealNutrition(entries).kcal)} kcal',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (entries.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            entries
                                .expand((m) => m.items)
                                .map((i) => i.name)
                                .join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        TextButton(
                          key: ValueKey('journal-add-${type.name}'),
                          onPressed: onOpen == null
                              ? null
                              : () => onOpen!(type),
                          style: TextButton.styleFrom(
                            foregroundColor: AppMealVisuals.color(
                              context,
                              type,
                            ),
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(48, 48),
                          ),
                          child: Text('+ Thêm ${type.label.toLowerCase()}'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      );
    },
  );
}
