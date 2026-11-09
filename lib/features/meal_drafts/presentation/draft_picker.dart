import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/meal_draft_store.dart';
import '../../../core/widgets/confirmed_save.dart';

/// Returning null means cancel; empty string explicitly starts a new draft.
Future<String?> chooseMealDraft(
  BuildContext context,
  List<SavedMealDraft> drafts, {
  bool editingMeal = false,
}) => showDialog<String>(
  context: context,
  builder: (dialogContext) => AccountBoundDialog(
    child: SimpleDialog(
      title: const Text('Bản nháp chưa xác nhận'),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'Mở lại nháp để tiếp tục. Nếu lần lưu trước bị gián đoạn, dùng cùng nháp để tránh ghi trùng.',
          ),
        ),
        for (final saved in drafts)
          SimpleDialogOption(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            key: ValueKey('restore-draft-${saved.operationId}'),
            onPressed: () => Navigator.pop(dialogContext, saved.operationId),
            child: Text(
              '${saved.draft.dateKey} · ${saved.draft.type.label}\n'
              '${saved.draft.items.map((i) => i.name).join(', ')}\n'
              '${saved.draft.items.length} món · Giữ lúc ${DateFormat('dd/MM HH:mm', 'vi').format(saved.updatedAt.toLocal())}'
              '${saved.mealId != null ? ' · Sửa bữa' : ''}',
            ),
          ),
        SimpleDialogOption(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          onPressed: () => Navigator.pop(dialogContext, ''),
          child: Text(editingMeal ? 'Sửa từ bữa đã lưu' : 'Tạo bản mới'),
        ),
        SimpleDialogOption(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Để sau'),
        ),
      ],
    ),
  ),
);
