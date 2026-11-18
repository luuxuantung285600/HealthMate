import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_feature_visuals.dart';
import '../../../core/theme/app_meal_visuals.dart';
import '../../../core/theme/home_palette.dart';
import '../../food_library/presentation/food_nutrition_text.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/presentation/food_photo_thumbnail.dart';
import '../../nutrition/providers/food_photo_provider.dart';
import '../models/meal_timeline.dart';

class HourlyMealTimeline extends StatelessWidget {
  const HourlyMealTimeline({
    required this.day,
    required this.now,
    required this.meals,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.onDuplicate,
    super.key,
  });

  final DateTime day, now;
  final List<MealLog> meals;
  final ValueChanged<DateTime>? onAdd;
  final ValueChanged<MealLog> onEdit, onDelete;
  final ValueChanged<MealLog>? onDuplicate;

  @override
  Widget build(BuildContext context) {
    final groups = groupMealsByHour(meals);
    Widget hour(MealHourGroup group) => _HourSection(
      group: group,
      addAt: mealTimeForHour(day, group.hour, now),
      onAdd: onAdd,
      onEdit: onEdit,
      onDelete: onDelete,
      onDuplicate: onDuplicate,
    );
    return Column(
      key: const ValueKey('journal-hourly-timeline'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (meals.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Chưa ghi món trong ngày. Nhấn + ở giờ bạn đã ăn.'),
          ),
        if (groups.take(7).any((g) => g.meals.isNotEmpty)) ...[
          for (final group in groups.take(7)) hour(group),
        ] else
          ExpansionTile(
            key: ValueKey((
              'journal-early-hours',
              day.year,
              day.month,
              day.day,
            )),
            tilePadding: EdgeInsets.zero,
            title: const Text('Giờ khuya và sáng sớm · 00:00–06:59'),
            children: [for (final group in groups.take(7)) hour(group)],
          ),
        for (final group in groups.skip(7)) hour(group),
      ],
    );
  }
}

class _HourSection extends StatelessWidget {
  const _HourSection({
    required this.group,
    required this.addAt,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
  });
  final MealHourGroup group;
  final DateTime? addAt;
  final ValueChanged<DateTime>? onAdd;
  final ValueChanged<MealLog> onEdit, onDelete;
  final ValueChanged<MealLog>? onDuplicate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = '${group.hour.toString().padLeft(2, '0')}:00';
    final future = addAt == null;
    return Padding(
      key: ValueKey('journal-hour-${group.hour}'),
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Text(label, style: theme.textTheme.titleSmall),
              ),
              const SizedBox(width: 14),
              const Expanded(child: Divider()),
              const SizedBox(width: 14),
              IconButton.filledTonal(
                key: ValueKey('add-meal-hour-${group.hour}'),
                tooltip: future
                    ? 'Chưa thể ghi món cho $label trong tương lai'
                    : 'Thêm món lúc $label',
                onPressed: future || onAdd == null
                    ? null
                    : () => onAdd!(addAt!),
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: theme.colorScheme.surfaceContainer,
                  foregroundColor: theme.colorScheme.onSurface,
                ),
                icon: const Icon(AppIcons.plus),
              ),
            ],
          ),
          if (group.meals.isNotEmpty) ...[
            const SizedBox(height: 12),
            TimelineNutrition(
              key: ValueKey('journal-hour-totals-${group.hour}'),
              value: group.totals,
              showEnergy: true,
            ),
            for (final meal in group.meals)
              Padding(
                key: ValueKey('meal-log-${meal.id}'),
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          AppMealVisuals.icon(meal.type),
                          color: AppMealVisuals.color(context, meal.type),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${DateFormat('HH:mm').format(journalMealTime(meal))} · ${meal.items.length} món',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppMealVisuals.color(context, meal.type),
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          key: ValueKey('meal-menu-${meal.id}'),
                          tooltip: 'Tùy chọn bữa ăn',
                          onSelected: (action) {
                            switch (action) {
                              case 'edit':
                                onEdit(meal);
                              case 'duplicate':
                                onDuplicate?.call(meal);
                              case 'delete':
                                onDelete(meal);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Sửa'),
                            ),
                            if (onDuplicate != null)
                              const PopupMenuItem(
                                value: 'duplicate',
                                child: Text('Nhân bản bữa'),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Xóa'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    for (final (index, item) in meal.items.indexed)
                      _TimelineFoodCard(
                        key: ValueKey('journal-food-${meal.id}-$index'),
                        item: item,
                        onEdit: () => onEdit(meal),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TimelineFoodCard extends ConsumerWidget {
  const _TimelineFoodCard({
    required this.item,
    required this.onEdit,
    super.key,
  });
  final MealItemSnapshot item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final photo = ref.watch(foodPhotoProvider((item.foodId, item.name)));
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${snapshotQuantityLabel(item)} · ${item.hasNutritionData ? '${foodNumber(item.nutrition.kcal)} kcal' : 'Chưa có dinh dưỡng'}${item.isEstimated ? ' · Ước tính' : ''}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (item.hasNutritionData) ...[
          const SizedBox(height: 10),
          TimelineNutrition(value: item.nutrition),
        ],
      ],
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final vertical =
                  constraints.maxWidth < 270 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.4;
              if (photo == null) return content;
              final thumbnail = FoodPhotoThumbnail(
                foodId: item.foodId,
                foodName: item.name,
                size: vertical ? 80 : 72,
              );
              return vertical
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        thumbnail,
                        const SizedBox(height: 12),
                        content,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        thumbnail,
                        const SizedBox(width: 14),
                        Expanded(child: content),
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }
}

class TimelineNutrition extends StatelessWidget {
  const TimelineNutrition({
    required this.value,
    this.showEnergy = false,
    super.key,
  });
  final NutritionTotals value;
  final bool showEnergy;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 14,
    runSpacing: 8,
    children: [
      for (final (label, icon, color, amount) in [
        if (showEnergy)
          (
            'Năng lượng',
            AppIcons.flame,
            AppFeatureVisual.nutrition.foreground(Theme.of(context).brightness),
            '${foodNumber(value.kcal)} kcal',
          ),
        (
          'Đạm',
          AppIcons.zap,
          HomePalette.protein,
          macroAmount(value.proteinG, value.proteinKnown),
        ),
        (
          'Carb',
          AppIcons.wheat,
          HomePalette.carbs,
          macroAmount(value.carbsG, value.carbsKnown),
        ),
        (
          'Chất béo',
          AppIcons.droplet,
          HomePalette.fat,
          macroAmount(value.fatG, value.fatKnown),
        ),
      ])
        Semantics(
          label: '$label $amount',
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  amount,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
