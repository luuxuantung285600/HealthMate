import 'package:flutter/material.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../models/food_library_models.dart';

class DeleteLibraryEntryDialog extends StatefulWidget {
  const DeleteLibraryEntryDialog({
    required this.entry,
    required this.onDelete,
    super.key,
  });
  final LibraryEntry entry;
  final Future<bool> Function() onDelete;
  @override
  State<DeleteLibraryEntryDialog> createState() =>
      _DeleteLibraryEntryDialogState();
}

class _DeleteLibraryEntryDialogState extends State<DeleteLibraryEntryDialog>
    with ConfirmedSave<bool, DeleteLibraryEntryDialog> {
  @override
  Widget build(BuildContext context) => guardSave(
    AlertDialog(
      title: const Text('Xóa khỏi thư viện?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.entry.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chỉ xóa nguồn trong thư viện. Thông tin nguyên liệu trong công thức và các bữa ăn đã ghi được giữ nguyên.',
            ),
            if (saveError == null)
              saveFeedback()
            else
              Semantics(
                liveRegion: true,
                child: Text(
                  'Chưa xác nhận xóa thành công. Hãy kiểm tra kết nối và thử lại.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : requestClose,
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const ValueKey('confirm-delete-library'),
          onPressed: saving
              ? null
              : () => saveDraft(true, (_) => widget.onDelete()),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
}
