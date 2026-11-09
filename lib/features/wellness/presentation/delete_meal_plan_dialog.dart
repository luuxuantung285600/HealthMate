import 'package:flutter/material.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../models/wellness_models.dart';

class DeleteMealPlanDialog extends StatefulWidget {
  const DeleteMealPlanDialog({
    required this.plan,
    required this.onDelete,
    super.key,
  });
  final PlannedMeal plan;
  final Future<bool> Function() onDelete;
  @override
  State<DeleteMealPlanDialog> createState() => _DeleteMealPlanDialogState();
}

class _DeleteMealPlanDialogState extends State<DeleteMealPlanDialog>
    with ConfirmedSave<bool, DeleteMealPlanDialog> {
  String? failure;
  Future<bool> remove() async {
    failure = null;
    try {
      return await widget.onDelete();
    } on FormatException catch (error) {
      failure = error.message;
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => guardSave(
    AlertDialog(
      title: const Text('Xóa kế hoạch bữa ăn?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.plan.type.label} · ${widget.plan.date.day}/${widget.plan.date.month}/${widget.plan.date.year}',
            ),
            for (final item in widget.plan.items) Text(item.name),
            const SizedBox(height: 12),
            const Text('Chỉ xóa kế hoạch này. Nhật ký đã ghi được giữ nguyên.'),
            if (saveError == null)
              saveFeedback()
            else ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  failure ??
                      'Chưa xác nhận xóa thành công. Hãy kiểm tra kết nối và thử lại.',
                  key: const ValueKey('plan-delete-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : requestClose,
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const ValueKey('confirm-delete-plan'),
          onPressed: saving ? null : () => saveDraft(true, (_) => remove()),
          child: const Text('Xóa kế hoạch'),
        ),
      ],
    ),
  );
}
