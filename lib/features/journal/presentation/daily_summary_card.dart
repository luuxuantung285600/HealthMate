import '../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../activity/models/activity_log.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../water/models/water_log.dart';

class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({
    required this.date,
    required this.mealsState,
    required this.waterState,
    required this.activityState,
    super.key,
  });

  final DateTime date;
  final AsyncValue<List<MealLog>> mealsState;
  final AsyncValue<List<WaterLog>> waterState;
  final AsyncValue<List<ActivityLog>> activityState;

  @override
  Widget build(BuildContext context) {
    final meals = mealsState.value;
    final water = waterState.value;
    final activities = activityState.value;
    final nutrition = meals == null ? null : totalMealNutrition(meals);
    final number = NumberFormat.decimalPattern('vi_VN');
    final decimal = NumberFormat('0.0', 'vi_VN');
    final hasError =
        mealsState.hasError || waterState.hasError || activityState.hasError;
    final loading =
        mealsState.isLoading || waterState.isLoading || activityState.isLoading;
    final theme = Theme.of(context);

    return Card(
      key: const ValueKey('daily-summary'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tóm tắt ngày đang chọn', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(1);
                final columns = constraints.maxWidth >= 248 * scale ? 2 : 1;
                final width =
                    (constraints.maxWidth - AppSpacing.sm * (columns - 1)) /
                    columns;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _SummaryValue(
                      key: const ValueKey('summary-kcal'),
                      icon: AppIcons.flame,
                      label: 'Năng lượng',
                      value: nutrition == null
                          ? '—'
                          : '${number.format(nutrition.kcal.round())} kcal',
                    ),
                    _SummaryValue(
                      key: const ValueKey('summary-macros'),
                      icon: AppIcons.chartPie,
                      label: 'P · C · F',
                      value: nutrition == null
                          ? '—'
                          : !nutrition.hasCompleteMacros
                          ? 'Ba chất chưa đủ dữ liệu'
                          : '${decimal.format(nutrition.proteinG)} · '
                                '${decimal.format(nutrition.carbsG)} · '
                                '${decimal.format(nutrition.fatG)} g',
                    ),
                    _SummaryValue(
                      key: const ValueKey('summary-water'),
                      icon: AppIcons.water,
                      label: 'Nước',
                      value: water == null
                          ? '—'
                          : '${number.format(totalWaterMl(water))} ml',
                    ),
                    _SummaryValue(
                      key: const ValueKey('summary-activity'),
                      icon: AppIcons.footprints,
                      label: 'Vận động',
                      value: activities == null
                          ? '—'
                          : '${number.format(totalActivityMinutes(activities))} phút',
                    ),
                  ].map((child) => SizedBox(width: width, child: child)).toList(),
                );
              },
            ),
            if (loading) ...[
              const SizedBox(height: AppSpacing.md),
              const LinearProgressIndicator(),
            ],
            if (hasError) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Một phần dữ liệu chưa tải được; dấu “—” không được tính là 0.',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
