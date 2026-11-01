import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/information_button.dart';

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
    super.key,
  });
  final double? consumed, target;
  final VoidCallback? onEditTarget, onPersonalize;
  final String? targetStatus, budgetNote;
  final Key? editKey;
  final Widget? macros;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = NumberFormat('#,##0', 'vi');
    final validTarget = target != null && target!.isFinite && target! > 0;
    final remaining = validTarget && consumed != null
        ? target! - consumed!
        : null;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Năng lượng', style: theme.textTheme.titleSmall),
              ),
              if (budgetNote != null)
                InformationButton(
                  title: 'Điều chỉnh năng lượng',
                  message: budgetNote!,
                ),
              if (onEditTarget != null)
                IconButton(
                  key: editKey,
                  tooltip: 'Mục tiêu dinh dưỡng',
                  onPressed: onEditTarget,
                  icon: const Icon(Icons.tune_rounded, size: 20),
                ),
            ],
          ),
          Text(
            remaining != null
                ? number.format(remaining.abs())
                : consumed == null
                ? '—'
                : number.format(consumed),
            key: validTarget
                ? const ValueKey('today-remaining-energy')
                : const ValueKey('today-recorded-energy'),
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            remaining != null
                ? (remaining >= 0 ? 'kcal còn lại' : 'kcal vượt mục tiêu')
                : 'kcal đã ăn',
            style: theme.textTheme.bodyMedium,
          ),
          if (validTarget) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: consumed == null ? 0 : (consumed! / target!).clamp(0, 1),
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                semanticsLabel: 'Tiến độ năng lượng đã ghi',
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (validTarget)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(
                  '${consumed == null ? '—' : number.format(consumed)} đã ăn',
                  key: const ValueKey('today-recorded-energy'),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Mục tiêu ${number.format(target)} kcal',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            )
          else
            Text(
              targetStatus ??
                  (consumed == null
                      ? 'Đang tải nhật ký…'
                      : 'Chưa đặt mục tiêu'),
              style: theme.textTheme.bodySmall,
            ),
          if (onPersonalize != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey('open-personal-nutrition'),
                onPressed: onPersonalize,
                child: const Text('Thiết lập mục tiêu'),
              ),
            ),
          if (macros != null) ...[const Divider(height: 24), macros!],
        ],
      ),
    );
  }
}
