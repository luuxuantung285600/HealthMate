import 'package:flutter/material.dart';
import '../../../core/widgets/help_details.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../models/nutrition_target.dart';
import '../providers/nutrition_target_providers.dart';
import 'nutrition_target_form.dart';
import 'personal_nutrition_planner.dart';
import '../../wellness/providers/energy_providers.dart';

class NutritionTargetCard extends ConsumerWidget {
  const NutritionTargetCard({required this.day, this.meals, super.key});
  final DateTime day;
  final AsyncValue<List<MealLog>>? meals;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = localDateKey(day);
    final state = ref.watch(nutritionTargetProvider(key));
    final budgetState = ref.watch(dailyEnergyBudgetProvider(key));
    final budget = !budgetState.isLoading && !budgetState.hasError
        ? budgetState.value
        : null;
    final value = state.value;
    final today = localDateOnly(ref.watch(localClockProvider));
    final number = NumberFormat('0.#', 'vi');
    final totals =
        meals != null &&
            !meals!.isLoading &&
            !meals!.hasError &&
            meals!.value != null
        ? totalMealNutrition(meals!.value!)
        : null;
    final ready = !state.isLoading && !state.hasError;
    final theme = Theme.of(context);
    Widget line(String label, double target, double? recorded, String unit) {
      final comparison = recorded == null
          ? null
          : TargetComparison(recorded: recorded, target: target);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(
              '$label: ${recorded == null ? '—' : number.format(recorded)} / ${number.format(target)} $unit',
              style: theme.textTheme.titleSmall,
            ),
            if (comparison != null) ...[
              Text(
                comparison.excess > 0
                    ? 'Vượt ${number.format(comparison.excess)} $unit'
                    : 'Còn ${number.format(comparison.remaining)} $unit',
              ),
              if (comparison.progress != null)
                LinearProgressIndicator(value: comparison.progress),
            ],
          ],
        ),
      );
    }

    return Card(
      key: ValueKey('nutrition-target-$key'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text('Mục tiêu dinh dưỡng', style: theme.textTheme.titleLarge),
            Text('Ngày ${DateFormat('dd/MM/yyyy').format(day)}'),
            if (state.isLoading) ...[
              const LinearProgressIndicator(),
              const Text('Đang tải mục tiêu…'),
            ] else if (state.hasError) ...[
              const Text(
                'Chưa tải được mục tiêu. Không coi lỗi tải là chưa đặt mục tiêu.',
              ),
              TextButton(
                onPressed: () => ref.invalidate(nutritionTargetProvider(key)),
                child: const Text('Thử tải lại mục tiêu'),
              ),
            ] else if (value == null)
              const Text('Chưa đặt mục tiêu')
            else ...[
              if (meals == null)
                Text(
                  'Mục tiêu gốc: ${number.format(value.kcalTarget)} kcal/ngày',
                )
              else ...[
                line(
                  'Năng lượng',
                  budget?.kcalTarget ?? value.kcalTarget,
                  budget == null ? null : totals?.kcal,
                  'kcal',
                ),
                if (totals == null)
                  const Text(
                    'Nhật ký đang tải hoặc có lỗi; chưa tính còn/vượt.',
                  ),
              ],
              if (budgetState.isLoading)
                const Text('Đang kiểm tra điều chỉnh ngân sách…'),
              if (budgetState.hasError)
                TextButton(
                  onPressed: () => retryEnergyBudget(ref, key),
                  child: const Text('Chưa tải đủ ngân sách · Thử lại'),
                ),
              if (budget != null && budget.adjustmentKcal > 0)
                Text(
                  'Gốc ${number.format(value.kcalTarget)} + bước đã xác nhận ${number.format(budget.adjustmentKcal)} kcal · ước tính; macro giữ nguyên.',
                ),
              if (budget?.hasUnappliedAdjustment == true)
                Text(budget!.explanation),
              if (value.hasMacros) ...[
                if (meals == null)
                  Text(
                    'Đạm ${number.format(value.proteinGTarget)} · Carb ${number.format(value.carbsGTarget)} · Chất béo ${number.format(value.fatGTarget)} g/ngày',
                  )
                else ...[
                  line(
                    'Đạm',
                    value.proteinGTarget!,
                    totals?.proteinKnown == false ? null : totals?.proteinG,
                    'g',
                  ),
                  line(
                    'Carb',
                    value.carbsGTarget!,
                    totals?.carbsKnown == false ? null : totals?.carbsG,
                    'g',
                  ),
                  line(
                    'Chất béo',
                    value.fatGTarget!,
                    totals?.fatKnown == false ? null : totals?.fatG,
                    'g',
                  ),
                  if (totals != null && !totals.hasCompleteMacros)
                    const Text(
                      'Chưa đủ dữ liệu chất; không tính còn/vượt cho phần chưa biết.',
                    ),
                ],
              ] else
                const Text('Chưa đặt mục tiêu cho ba chất'),
              HelpDetails(
                title: 'Thông tin mục tiêu',
                children: [
                  Text(
                    'Áp dụng từ ${value.effectiveFromDateKey} · Bạn tự thiết lập',
                  ),
                  const Text(
                    'Số đã ghi chỉ tính từ nhật ký. Chưa ghi đủ không có nghĩa là chưa ăn. Mục tiêu mới không thay đổi lịch sử.',
                  ),
                ],
              ),
            ],
            if (ready)
              TextButton.icon(
                key: const ValueKey('personalize-nutrition-target'),
                onPressed: () => openPersonalNutritionPlanner(context),
                icon: const Icon(Icons.calculate_outlined),
                label: Text(
                  value == null ? 'Gợi ý mục tiêu' : 'Tính lại mục tiêu',
                ),
              ),
            if (ready)
              TextButton.icon(
                key: ValueKey('edit-nutrition-target-$key'),
                onPressed: () => openNutritionTargetForm(
                  context,
                  ref,
                  localDateKey(today) == key ? value : null,
                ),
                icon: const Icon(Icons.edit_outlined),
                label: Text(
                  localDateKey(today) == key
                      ? (value == null
                            ? 'Thiết lập mục tiêu'
                            : 'Chỉnh mục tiêu')
                      : 'Thiết lập từ hôm nay',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
