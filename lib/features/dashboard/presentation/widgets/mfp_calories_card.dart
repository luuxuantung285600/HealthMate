import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_feature_visuals.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/information_button.dart';
import '../../../../core/theme/reference_palette.dart';
import '../../../nutrition/models/nutrition_models.dart';
import '../../models/calorie_ring_data.dart';
import 'calorie_macro_ring.dart';

/// A short reading of the selected day's recorded energy, not a health score.
class MfpCaloriesCard extends StatelessWidget {
  const MfpCaloriesCard({
    required this.consumed,
    this.target,
    this.onEditTarget,
    this.targetStatus,
    this.editKey,
    this.budgetNote,
    this.onPersonalize,
    this.macros,
    this.nutritionTotals,
    this.exerciseCalories,
    this.exerciseMinutes,
    this.onViewReport,
    this.onViewActivity,
    this.onViewMeals,
    super.key,
  });
  final double? consumed, target;
  final VoidCallback? onEditTarget, onPersonalize;
  final String? targetStatus, budgetNote;
  final Key? editKey;
  final Widget? macros;
  final NutritionTotals? nutritionTotals;
  final double? exerciseCalories;
  final int? exerciseMinutes;
  final VoidCallback? onViewReport, onViewActivity, onViewMeals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = NumberFormat('#,##0', 'vi');
    final validTarget = target != null && target!.isFinite && target! > 0;
    final remaining = validTarget && consumed != null
        ? target! - consumed!
        : null;
    final ring = CalorieRingData(
      consumed: consumed,
      target: target,
      totals: nutritionTotals,
    );
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Mục tiêu calo',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onViewReport != null)
                TextButton(
                  key: const ValueKey('home-view-report'),
                  onPressed: onViewReport,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    backgroundColor: theme.colorScheme.surface,
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Xem báo cáo'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = MediaQuery.textScalerOf(context).scale(1);
                final diameter = (180 * scale)
                    .clamp(180.0, constraints.maxWidth.clamp(180, 320))
                    .toDouble();
                final label = remaining != null
                    ? (remaining >= 0 ? 'Calo còn lại' : 'Calo vượt mục tiêu')
                    : validTarget || targetStatus != null
                    ? 'Chưa có số liệu'
                    : 'Chưa đặt mục tiêu';
                return Semantics(
                  label:
                      '${remaining == null ? label : '${number.format(remaining.abs())} $label, đơn vị kcal'}. '
                      '${ring.hasProgress ? 'Đã nạp ${number.format(ring.progress * 100)} phần trăm mục tiêu.' : 'Chưa đủ dữ liệu để tính tiến độ mục tiêu.'} '
                      '${ring.hasComposition ? 'Tỷ lệ năng lượng dưỡng chất: đạm ${number.format(ring.shares[0] * 100)} phần trăm, tinh bột ${number.format(ring.shares[1] * 100)} phần trăm, chất béo ${number.format(ring.shares[2] * 100)} phần trăm.' : 'Chưa có đủ dữ liệu để chia màu dưỡng chất.'}',
                  child: SizedBox.square(
                    dimension: diameter,
                    child: CalorieMacroRing(
                      key: const ValueKey('home-calorie-ring'),
                      data: ring,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                remaining == null
                                    ? '—'
                                    : number.format(remaining.abs()),
                                key: const ValueKey('today-remaining-energy'),
                                style: theme.textTheme.displayMedium?.copyWith(
                                  fontSize: 33,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 8,
            children: [
              for (final macro in const [
                ('Đạm', ReferencePalette.protein),
                ('Tinh bột', ReferencePalette.carb),
                ('Chất béo', ReferencePalette.fat),
              ])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: macro.$2,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(macro.$1, style: theme.textTheme.bodySmall),
                  ],
                ),
              const InformationButton(
                title: 'Cách đọc vòng calo',
                message:
                    'Độ dài phần đã tô thể hiện calo đã nạp so với mục tiêu; phần xám là phần còn lại. Ba màu chia phần đã tô theo tỷ lệ năng lượng từ đạm, tinh bột và chất béo, quy đổi lần lượt 4, 4 và 9 kcal/g. Đây là tỷ lệ quy đổi, có thể khác calo trên nhãn thực phẩm. Đường và chất xơ không được cộng thành đoạn màu riêng. Khi thiếu dữ liệu dưỡng chất, tiến độ dùng màu xám và không suy đoán tỷ lệ.',
              ),
            ],
          ),
          if (consumed != null && consumed! > 0 && !ring.hasComposition)
            Text(
              'Chưa đủ dữ liệu dưỡng chất để chia màu.',
              key: const ValueKey('home-calorie-macros-unavailable'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          if (targetStatus != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(targetStatus!, textAlign: TextAlign.center),
            ),
          if (onPersonalize != null)
            Center(
              child: TextButton(
                key: const ValueKey('open-personal-nutrition'),
                onPressed: onPersonalize,
                child: const Text('Thiết lập mục tiêu'),
              ),
            ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.4;
              final columns = [
                _EnergyStat(
                  key: editKey,
                  value: validTarget ? number.format(target) : '—',
                  label: 'Mục tiêu',
                  icon: AppIcons.goals,
                  color: AppFeatureVisual.goals.foreground(theme.brightness),
                  semanticLabel: validTarget
                      ? 'Mục tiêu ${number.format(target)} kcal'
                      : 'Mục tiêu dinh dưỡng chưa được tải hoặc thiết lập',
                  onTap: onEditTarget,
                ),
                _EnergyStat(
                  valueKey: const ValueKey('today-recorded-energy'),
                  value: consumed == null ? '—' : number.format(consumed),
                  label: 'Đã nạp',
                  icon: AppIcons.nutrition,
                  color: AppFeatureVisual.nutrition.foreground(
                    theme.brightness,
                  ),
                  semanticLabel:
                      'Đã nạp ${consumed == null ? 'chưa có số liệu' : '${number.format(consumed)} kcal'}',
                  onTap: onViewMeals,
                ),
                _EnergyStat(
                  valueKey: const ValueKey('home-exercise-energy'),
                  value: exerciseCalories != null
                      ? number.format(exerciseCalories)
                      : exerciseMinutes != null
                      ? '${number.format(exerciseMinutes)} phút'
                      : '—',
                  label: 'Tập luyện',
                  icon: AppIcons.workout,
                  color: AppFeatureVisual.workout.foreground(theme.brightness),
                  semanticLabel: exerciseCalories != null
                      ? 'Tập luyện ${number.format(exerciseCalories)} kcal vận động thêm ước tính, chỉ cộng vào mục tiêu khi đã xác nhận'
                      : exerciseMinutes != null
                      ? 'Tập luyện ${number.format(exerciseMinutes)} phút đã ghi, chưa đủ dữ liệu calo'
                      : 'Chưa tải được dữ liệu tập luyện',
                  onTap: onViewActivity,
                ),
              ];
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final column in columns)
                    SizedBox(
                      width: stacked
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 16) / 3,
                      child: column,
                    ),
                ],
              );
            },
          ),
          if (exerciseCalories != null && exerciseCalories! > 0)
            Text(
              'Calo vận động thêm là ước tính. Chỉ cộng vào calo còn lại khi bạn xác nhận ngoài mức thường ngày.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          if (budgetNote != null)
            Align(
              alignment: Alignment.center,
              child: InformationButton(
                title: 'Điều chỉnh năng lượng',
                message: budgetNote!,
              ),
            ),
          if (macros != null) ...[const Divider(height: 24), macros!],
        ],
      ),
    );
  }
}

class _EnergyStat extends StatelessWidget {
  const _EnergyStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.semanticLabel,
    this.onTap,
    this.valueKey,
    super.key,
  });
  final String value, label, semanticLabel;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    button: onTap != null,
    child: Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            children: [
              Text(
                value,
                key: valueKey,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 5,
                children: [
                  Icon(icon, size: 18, color: color),
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
