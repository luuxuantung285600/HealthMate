import '../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../journal/presentation/daily_log_section_card.dart';
import '../../../core/theme/app_feature_visuals.dart';
import '../models/water_log.dart';

class WaterLogSection extends StatelessWidget {
  const WaterLogSection({
    required this.state,
    required this.action,
    required this.onAdd,
    this.onQuickAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
    required this.onDismissError,
    super.key,
  });

  final AsyncValue<List<WaterLog>> state;
  final AsyncValue<void> action;
  final VoidCallback onAdd;
  final ValueChanged<int>? onQuickAdd;
  final ValueChanged<WaterLog> onEdit;
  final ValueChanged<WaterLog> onDelete;
  final VoidCallback onRetry;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    final logs = state.value ?? const <WaterLog>[];
    final total = totalWaterMl(logs);
    final number = NumberFormat.decimalPattern('vi_VN');
    final brightness = Theme.of(context).brightness;
    final accent = AppFeatureVisual.water.foreground(brightness);
    return DailyLogSectionCard<WaterLog>(
      icon: AppIcons.water,
      accent: accent,
      title: 'Nước uống',
      summary: state.isLoading
          ? 'Đang tải…'
          : state.hasError
          ? 'Chưa tải được lượng nước'
          : '${number.format(total)} ml',
      description: 'Tổng theo ngày đã chọn, dựa trên các lần bạn tự ghi.',
      addKey: const ValueKey('add-water'),
      addLabel: 'Ghi nước uống',
      state: state,
      action: action,
      onAdd: onAdd,
      onRetry: onRetry,
      onDismissError: onDismissError,
      emptyText: 'Chưa có lần uống nước nào trong ngày này.',
      entryActions: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final amount in const [250, 350, 500])
              ActionChip(
                key: ValueKey('quick-water-$amount'),
                avatar: const Icon(AppIcons.plus, size: 18),
                label: Text('$amount ml'),
                onPressed: action.isLoading || onQuickAdd == null
                    ? null
                    : () => onQuickAdd!(amount),
              ),
          ],
        ),
      ),
      children: [
        for (final log in logs)
          ListTile(
            key: ValueKey('water-log-${log.id}'),
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppFeatureVisual.water.background(brightness),
              child: Icon(AppIcons.water, color: accent),
            ),
            title: Text('${number.format(log.amountMl)} ml'),
            subtitle: Text(DateFormat('HH:mm').format(log.consumedAt)),
            trailing: DailyLogEntryMenu(
              onEdit: () => onEdit(log),
              onDelete: () => onDelete(log),
            ),
          ),
      ],
    );
  }
}
