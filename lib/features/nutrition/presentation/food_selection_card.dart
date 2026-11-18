import '../../../core/theme/app_icons.dart';
import '../../../core/theme/reference_palette.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/nutrition_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/food_photo_provider.dart';
import 'food_photo_thumbnail.dart';

/// The same food identity and nutrition reading across discovery and the draft.
class FoodSelectionCard extends ConsumerWidget {
  const FoodSelectionCard({
    required this.foodId,
    required this.name,
    required this.quantityLabel,
    required this.isEstimated,
    this.nutrition,
    this.status,
    this.textOnlySummary,
    this.actions = const [],
    this.onSelect,
    super.key,
  });

  final String foodId, name, quantityLabel;
  final bool isEstimated;
  final NutritionTotals? nutrition;
  final String? status, textOnlySummary;
  final List<Widget> actions;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final number = NumberFormat('0.#', 'vi');
    final value = nutrition;
    final summary = value == null
        ? status ?? 'Chưa có dữ liệu dinh dưỡng'
        : '$quantityLabel · ${NumberFormat('#,##0', 'vi').format(value.kcal)} kcal'
              '${isEstimated ? ' · Ước tính' : ''}';
    // Preserve the existing text-only rows for foods without a verified photo.
    // Never substitute an unrelated dish or reserve an empty image column.
    if (ref.watch(foodPhotoProvider((foodId, name))) == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onSelect,
        title: Text(name),
        subtitle: Text(
          textOnlySummary ??
              '$summary${value != null && status != null ? '\n$status' : ''}',
        ),
        trailing: actions.isEmpty
            ? null
            : Row(mainAxisSize: MainAxisSize.min, children: actions),
      );
    }
    final macros = value == null
        ? const <(String, double, bool, IconData, Color)>[]
        : [
            (
              'Chất đạm',
              value.proteinG,
              value.proteinKnown,
              AppIcons.protein,
              ReferencePalette.protein,
            ),
            (
              'Đường bột',
              value.carbsG,
              value.carbsKnown,
              AppIcons.carbs,
              ReferencePalette.carb,
            ),
            (
              'Chất béo',
              value.fatG,
              value.fatKnown,
              AppIcons.fat,
              ReferencePalette.fat,
            ),
          ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked =
                    constraints.maxWidth < 290 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                    (actions.length > 1 && constraints.maxWidth < 380);
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(summary, style: theme.textTheme.bodyMedium),
                    if (status != null && value != null)
                      Text(status!, style: theme.textTheme.bodySmall),
                    if (macros.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          for (final macro in macros)
                            Semantics(
                              label:
                                  '${macro.$1}: ${macro.$3 ? '${number.format(macro.$2)} g' : 'chưa có dữ liệu'}',
                              child: ExcludeSemantics(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(macro.$4, size: 16, color: macro.$5),
                                    const SizedBox(width: 3),
                                    Text(
                                      macro.$3
                                          ? '${number.format(macro.$2)}g'
                                          : '—',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FoodPhotoThumbnail(
                          foodId: foodId,
                          foodName: name,
                          size: 80,
                          onTap: onSelect,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: details),
                        if (!stacked && actions.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: actions,
                          ),
                        ],
                      ],
                    ),
                    if (stacked && actions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(spacing: 4, children: actions),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
