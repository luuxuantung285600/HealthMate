import 'package:flutter/material.dart';
import '../../../core/widgets/confirmed_save.dart';

class DeleteJournalEntryDialog extends StatefulWidget {
  const DeleteJournalEntryDialog({
    required this.title,
    required this.details,
    required this.onDelete,
    super.key,
  });

  final String title;
  final String details;
  final Future<bool> Function() onDelete;

  @override
  State<DeleteJournalEntryDialog> createState() =>
      _DeleteJournalEntryDialogState();
}

class _DeleteJournalEntryDialogState extends State<DeleteJournalEntryDialog>
    with ConfirmedSave<bool, DeleteJournalEntryDialog> {
  @override
  Widget build(BuildContext context) => guardSave(
    AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.details),
            const SizedBox(height: 12),
            const Text(
              'Bản ghi này sẽ bị xóa khỏi nhật ký. Các tổng liên quan sẽ được cập nhật.',
            ),
            if (saveError == null)
              saveFeedback()
            else ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  'Chưa xác nhận xóa thành công. Hãy kiểm tra kết nối và thử lại.',
                  key: const ValueKey('journal-delete-error'),
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
          key: const ValueKey('confirm-delete-journal'),
          onPressed: saving
              ? null
              : () => saveDraft(true, (_) => widget.onDelete()),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
}
