import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/confirmed_save.dart';
import '../models/body_metric.dart';

class DeleteBodyMetricDialog extends StatefulWidget {
  const DeleteBodyMetricDialog({
    required this.metric,
    required this.onDelete,
    super.key,
  });
  final BodyMetric metric;
  final Future<bool> Function() onDelete;

  @override
  State<DeleteBodyMetricDialog> createState() => _DeleteBodyMetricDialogState();
}

class _DeleteBodyMetricDialogState extends State<DeleteBodyMetricDialog>
    with ConfirmedSave<bool, DeleteBodyMetricDialog> {
  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    final time = widget.metric.measuredAt.toLocal();
    return guardSave(
      AlertDialog(
        title: const Text('Xóa lần đo?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.metric.weightKg} kg · ${DateFormat('dd/MM/yyyy').format(time)} · ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(time), alwaysUse24HourFormat: true)}',
              ),
              if (widget.metric.note.isNotEmpty) Text(widget.metric.note),
              const SizedBox(height: 12),
              const Text(
                'Lần đo sẽ bị xóa khỏi lịch sử. BMI và tiến độ được tính lại từ các lần đo còn lại.',
              ),
              if (saveError == null)
                saveFeedback()
              else
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'Chưa xóa được lần đo. Dữ liệu vẫn được giữ; hãy kiểm tra kết nối và thử lại.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: requestClose, child: const Text('Giữ lại')),
          FilledButton(
            key: const ValueKey('confirm-delete-metric'),
            onPressed: () => saveDraft(true, (_) => widget.onDelete()),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
