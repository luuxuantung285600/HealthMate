import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_providers.dart';
import '../../journal/models/daily_log_failure.dart';
import '../models/water_log.dart';
import '../providers/water_providers.dart';

Future<void> addQuickWater(
  BuildContext context,
  WidgetRef ref,
  WaterLogDraft draft,
) async {
  final uid = ref.read(authSessionProvider).value?.uid;
  if (uid == null) return;
  final receipt = await ref
      .read(waterControllerProvider.notifier)
      .addWithReceipt(draft);
  if (!context.mounted || ref.read(authSessionProvider).value?.uid != uid) {
    return;
  }
  if (receipt == null) {
    _showForOwner(
      context,
      ref,
      uid,
      const SnackBar(content: Text('Chưa thể ghi nước. Hãy thử lại.')),
    );
    return;
  }
  _showUndo(context, ref, receipt);
}

void _showUndo(
  BuildContext context,
  WidgetRef ref,
  WaterEntryReceipt receipt, {
  DailyLogFailure? failure,
}) {
  final changed = failure?.code == 'water-entry-changed';
  _showForOwner(
    context,
    ref,
    receipt.uid,
    SnackBar(
      duration: const Duration(seconds: 8),
      content: failure == null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Đã ghi nhanh ${receipt.draft.amountMl} ml nước.'),
                Text(
                  DateFormat(
                    'dd/MM/yyyy · HH:mm',
                    'vi',
                  ).format(receipt.draft.consumedAt.toLocal()),
                ),
              ],
            )
          : Text(failure.message),
      action: changed
          ? null
          : SnackBarAction(
              label: failure == null ? 'Hoàn tác' : 'Thử lại',
              onPressed: () async {
                if (!context.mounted ||
                    ref.read(authSessionProvider).value?.uid != receipt.uid) {
                  return;
                }
                final saved = await ref
                    .read(waterControllerProvider.notifier)
                    .undoAdd(receipt);
                if (!context.mounted ||
                    ref.read(authSessionProvider).value?.uid != receipt.uid) {
                  return;
                }
                if (saved) {
                  _showForOwner(
                    context,
                    ref,
                    receipt.uid,
                    const SnackBar(content: Text('Đã hoàn tác lần ghi nước.')),
                  );
                } else {
                  final error = ref.read(waterControllerProvider).error;
                  _showUndo(
                    context,
                    ref,
                    receipt,
                    failure: error is DailyLogFailure
                        ? error
                        : const DailyLogFailure(
                            'Chưa thể hoàn tác. Hãy thử lại khi thao tác hiện tại hoàn tất.',
                          ),
                  );
                }
              },
            ),
    ),
  );
}

void _showForOwner(
  BuildContext context,
  WidgetRef ref,
  String uid,
  SnackBar snackBar,
) {
  final messenger = ScaffoldMessenger.of(context);
  // The latest quick entry owns its own undo. Do not queue stale receipts.
  messenger.clearSnackBars();
  final shown = messenger.showSnackBar(snackBar);
  final subscription = ref.listenManual(
    authSessionProvider.select((session) => session.value?.uid),
    (_, after) {
      if (after != uid) shown.close();
    },
  );
  shown.closed.then((_) => subscription.close());
}
