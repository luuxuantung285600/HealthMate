import '../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../journal/presentation/daily_log_section_card.dart';
import '../../../core/theme/app_feature_visuals.dart';
import '../models/activity_log.dart';

class ActivityLogSection extends StatelessWidget {
  const ActivityLogSection({
    required this.state,
    required this.action,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
    required this.onDismissError,
    super.key,
  });

  final AsyncValue<List<ActivityLog>> state;
  final AsyncValue<void> action;
  final VoidCallback onAdd;
  final ValueChanged<ActivityLog> onEdit;
  final ValueChanged<ActivityLog> onDelete;
  final VoidCallback onRetry;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    final logs = state.value ?? const <ActivityLog>[];
    final total = totalActivityMinutes(logs);
    final number = NumberFormat.decimalPattern('vi_VN');
    final brightness = Theme.of(context).brightness;
    final accent = AppFeatureVisual.activity.foreground(brightness);
    return DailyLogSectionCard<ActivityLog>(
      icon: AppIcons.footprints,
      accent: accent,
      title: 'Vận động',
      summary: '${number.format(total)} phút',
      description:
          'Calo vận động thêm là ước tính theo MET, cân nặng và thời gian; không phải số đo cảm biến.',
      addKey: const ValueKey('add-activity'),
      addLabel: 'Ghi hoạt động',
      state: state,
      action: action,
      onAdd: onAdd,
      onRetry: onRetry,
      onDismissError: onDismissError,
      emptyText: 'Chưa có hoạt động nào trong ngày này.',
      children: [
        for (final log in logs)
          ListTile(
            key: ValueKey('activity-log-${log.id}'),
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppFeatureVisual.activity.background(brightness),
              child: Icon(AppIcons.footprints, color: accent),
            ),
            title: Text(
              '${log.type.label} · ${number.format(log.durationMinutes)} phút',
            ),
            subtitle: Text(
              '${DateFormat('HH:mm').format(log.performedAt)}'
              '${log.energyEstimate == null ? '\nChưa có ước tính calo' : '\n≈ ${log.energyEstimate!.activeKcal.round()} kcal vận động thêm · tổng ≈ ${log.energyEstimate!.grossKcal.round()} kcal'}'
              '${log.energyEstimate?.includedInBudget == true ? '\nĐã xác nhận ngoài mức hoạt động thường ngày' : ''}'
              '${log.note.isEmpty ? '' : '\n${log.note}'}',
            ),
            trailing: DailyLogEntryMenu(
              onEdit: () => onEdit(log),
              onDelete: () => onDelete(log),
            ),
          ),
      ],
    );
  }
}
