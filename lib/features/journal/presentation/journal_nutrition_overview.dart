import '../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/local_date_key.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../../core/theme/home_palette.dart';
import '../../../core/theme/app_feature_visuals.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../food_library/presentation/food_nutrition_text.dart';
import '../../nutrition_targets/models/nutrition_target.dart';
import '../../nutrition_targets/providers/nutrition_target_providers.dart';
import '../../nutrition_targets/presentation/nutrition_target_form.dart';
import '../../wellness/providers/energy_providers.dart';

class _DiaryProgressGrid extends StatelessWidget {
  const _DiaryProgressGrid({required this.metrics});
  final List<(String, double?, double?, IconData, Color)> metrics;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final columns = scale > 1.7
          ? 1
          : constraints.maxWidth >= 260 && scale <= 1.1
          ? 4
          : 2;
      String amount(double? value) =>
          value == null ? '—' : NumberFormat('0.#', 'vi').format(value);
      Widget metric((String, double?, double?, IconData, Color) entry) {
        final (label, value, goal, icon, color) = entry;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              '${amount(value)} / ${amount(goal)}',
              key: label == 'kcal'
                  ? const ValueKey('nutrition-daily-totals')
                  : ValueKey('journal-progress-$label'),
              semanticsLabel:
                  '${amount(value)} ${label == 'kcal' ? 'kcal' : 'g'} / ${amount(goal)} ${label == 'kcal' ? 'kcal' : 'g'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              label == 'kcal' ? 'kcal' : '$label (g)',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const Spacer(),
            const SizedBox(height: 8),
            Semantics(
              label: '$label ${amount(value)} trên mục tiêu ${amount(goal)}',
              child: LinearProgressIndicator(
                minHeight: 5,
                borderRadius: BorderRadius.circular(8),
                color: color,
                value: value == null || goal == null || goal <= 0
                    ? 0
                    : (value / goal).clamp(0, 1),
              ),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var start = 0; start < metrics.length; start += columns) ...[
            if (start > 0) const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (
                    var index = start;
                    index < start + columns && index < metrics.length;
                    index++
                  ) ...[
                    if (index > start) const SizedBox(width: 12),
                    Expanded(child: metric(metrics[index])),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}

/// The diary and its applicable target share one overview, with independent
/// loading/errors. Never turn stale AsyncValue data into a confirmed total.
class JournalNutritionOverview extends ConsumerWidget {
  const JournalNutritionOverview({
    required this.day,
    required this.meals,
    this.compact = false,
    super.key,
  });
  final DateTime day;
  final AsyncValue<List<MealLog>> meals;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = localDateKey(day);
    final targetState = ref.watch(nutritionTargetProvider(key));
    final budgetState = ref.watch(dailyEnergyBudgetProvider(key));
    final budget = !budgetState.isLoading && !budgetState.hasError
        ? budgetState.value
        : null;
    final targetReady = !targetState.isLoading && !targetState.hasError;
    final target = targetReady ? targetState.value : null;
    final totals = !meals.isLoading && !meals.hasError && meals.value != null
        ? totalMealNutrition(meals.value!)
        : null;
    final n = NumberFormat('0.#', 'vi');
    final theme = Theme.of(context);
    final today = localDateKey(ref.watch(localClockProvider));
    String amount(double? value) => value == null ? '—' : n.format(value);
    String goal(double? value) => value == null ? '—' : n.format(value);
    String comparison(double recorded, double goal, String unit) {
      final result = TargetComparison(recorded: recorded, target: goal);
      return result.excess > 0
          ? 'Vượt ${amount(result.excess)} $unit'
          : 'Còn ${amount(result.remaining)} $unit';
    }

    final macros = [
      (
        'Đạm',
        totals?.proteinKnown == false ? null : totals?.proteinG,
        target?.proteinGTarget,
      ),
      (
        'Carb',
        totals?.carbsKnown == false ? null : totals?.carbsG,
        target?.carbsGTarget,
      ),
      (
        'Chất béo',
        totals?.fatKnown == false ? null : totals?.fatG,
        target?.fatGTarget,
      ),
    ];
    if (compact) {
      return Card(
        key: const ValueKey('daily-summary'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DiaryProgressGrid(
                      metrics: [
                        (
                          'kcal',
                          totals?.kcal,
                          budget?.kcalTarget,
                          AppIcons.flame,
                          AppFeatureVisual.nutrition.foreground(
                            theme.brightness,
                          ),
                        ),
                        (
                          'Đạm',
                          totals?.proteinKnown == false
                              ? null
                              : totals?.proteinG,
                          target?.proteinGTarget,
                          AppIcons.zap,
                          HomePalette.protein,
                        ),
                        (
                          'Carb',
                          totals?.carbsKnown == false ? null : totals?.carbsG,
                          target?.carbsGTarget,
                          AppIcons.wheat,
                          HomePalette.carbs,
                        ),
                        (
                          'Chất béo',
                          totals?.fatKnown == false ? null : totals?.fatG,
                          target?.fatGTarget,
                          AppIcons.droplet,
                          HomePalette.fat,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('journal-nutrition-details'),
                    tooltip: 'Chi tiết dinh dưỡng',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => AccountBoundDialog(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 12,
                            children: [
                              JournalNutritionOverview(day: day, meals: meals),
                              if (target != null)
                                Text(
                                  'Mục tiêu áp dụng từ ${target.effectiveFromDateKey} · Bạn tự thiết lập',
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    icon: const Icon(AppIcons.ellipsis),
                  ),
                ],
              ),
              if (meals.isLoading)
                const Text('Đang tải nhật ký; chưa tính còn/vượt.'),
              if (meals.hasError)
                const Text('Chưa tải được nhật ký; chưa tính còn/vượt.'),
              if (targetState.isLoading) const Text('Đang tải mục tiêu…'),
              if (targetState.hasError)
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chưa tải được mục tiêu. Tổng đã ghi vẫn được giữ.',
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('retry-journal-target'),
                      tooltip: 'Thử tải lại mục tiêu',
                      onPressed: () =>
                          ref.invalidate(nutritionTargetProvider(key)),
                      icon: const Icon(AppIcons.refreshCw),
                    ),
                  ],
                ),
              if (budgetState.hasError && target != null)
                TextButton(
                  onPressed: () => retryEnergyBudget(ref, key),
                  child: const Text('Chưa tải đủ ngân sách · Thử lại'),
                ),
              if (budget?.hasUnappliedAdjustment == true)
                Text(budget!.explanation),
              if (budget != null && budget.adjustmentKcal > 0)
                Text(
                  'Gốc ${amount(target?.kcalTarget)} + vận động đã xác nhận ${amount(budget.adjustmentKcal)} kcal · ước tính',
                ),
              if (targetReady && target == null)
                TextButton(
                  key: ValueKey('edit-nutrition-target-$key'),
                  onPressed: () => openNutritionTargetForm(context, ref, null),
                  child: const Text('Chưa đặt mục tiêu'),
                ),
            ],
          ),
        ),
      );
    }
    return Card(
      key: const ValueKey('daily-summary'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Đã ghi / mục tiêu', style: theme.textTheme.labelMedium),
            Text(
              '${amount(totals?.kcal)} kcal / ${goal(budget?.kcalTarget)} kcal',
              key: const ValueKey('nutrition-daily-totals'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (totals != null && budget != null)
              Text(comparison(totals.kcal, budget.kcalTarget, 'kcal')),
            if (budget != null && budget.adjustmentKcal > 0)
              Text(
                'Gốc ${amount(target?.kcalTarget)} + vận động đã xác nhận ${amount(budget.adjustmentKcal)} kcal · ước tính',
              ),
            if (budget?.hasUnappliedAdjustment == true)
              Text(budget!.explanation),
            if (budgetState.hasError && target != null)
              TextButton(
                onPressed: () => retryEnergyBudget(ref, key),
                child: const Text('Chưa tải đủ ngân sách · Thử lại'),
              ),
            if (totals != null && meals.value!.isEmpty)
              const Text('Chưa ghi bữa ăn'),
            if (meals.isLoading)
              const Text('Đang tải nhật ký; chưa tính còn/vượt.'),
            if (meals.hasError)
              const Text('Chưa tải được nhật ký; chưa tính còn/vượt.'),
            if (targetState.isLoading) ...[
              const LinearProgressIndicator(),
              const Text('Đang tải mục tiêu…'),
            ] else if (targetState.hasError) ...[
              const Text('Chưa tải được mục tiêu. Tổng đã ghi vẫn được giữ.'),
              TextButton(
                key: const ValueKey('retry-journal-target'),
                onPressed: () => ref.invalidate(nutritionTargetProvider(key)),
                child: const Text('Thử tải lại mục tiêu'),
              ),
            ] else if (target == null)
              const Text('Chưa đặt mục tiêu'),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = MediaQuery.textScalerOf(context).scale(1) > 1.3
                    ? 1
                    : 3;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final macro in macros)
                      SizedBox(
                        width:
                            (constraints.maxWidth - 8 * (columns - 1)) /
                            columns,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(macro.$1, style: theme.textTheme.labelSmall),
                            Text(
                              '${amount(macro.$2)} / ${goal(macro.$3)} g',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            if (totals != null && !totals.hasCompleteMacros)
              const Text('Dấu —: chưa có số liệu, không phải 0.'),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  key: const ValueKey('journal-nutrition-details'),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (sheetContext) => AccountBoundDialog(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 12,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Chi tiết dinh dưỡng',
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(DateFormat('dd/MM/yyyy').format(day)),
                            Text(
                              'Chất xơ: ${totals == null ? '—' : macroAmount(totals.fiberG, totals.fiberKnown)}',
                            ),
                            if (totals != null)
                              Text(
                                'Đủ số liệu chất xơ ở ${meals.value!.expand((m) => m.items).where((i) => i.nutrition.fiberKnown).length}/${meals.value!.expand((m) => m.items).length} món đã ghi. Chưa biết không có nghĩa là 0.',
                              ),
                            if (target != null)
                              Text(
                                'Mục tiêu áp dụng từ ${target.effectiveFromDateKey} · Bạn tự thiết lập',
                              ),
                            for (final macro in macros) ...[
                              Text(
                                '${macro.$1}: ${amount(macro.$2)} / ${goal(macro.$3)} g',
                              ),
                              if (macro.$2 != null && macro.$3 != null)
                                Text(comparison(macro.$2!, macro.$3!, 'g')),
                            ],
                            const SizedBox(height: 12),
                            const Text(
                              'Chỉ cộng nhật ký đã ghi; chưa ghi không có nghĩa là chưa ăn. Mục tiêu mới không áp ngược ngày cũ.',
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: const Text('Đóng'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Chi tiết'),
                ),
                if (targetReady)
                  TextButton.icon(
                    key: ValueKey('edit-nutrition-target-$key'),
                    onPressed: () => openNutritionTargetForm(
                      context,
                      ref,
                      key == today ? target : null,
                    ),
                    icon: const Icon(AppIcons.squarePen, size: 18),
                    label: Text(
                      key != today
                          ? 'Thiết lập từ hôm nay'
                          : target == null
                          ? 'Thiết lập mục tiêu'
                          : 'Chỉnh mục tiêu',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
