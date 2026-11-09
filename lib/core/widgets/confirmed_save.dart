import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_providers.dart';

/// Keep a draft until the repository Future acknowledges the write. Never time
/// out and submit another write while the SDK may still be syncing this one.
mixin ConfirmedSave<T, W extends StatefulWidget> on State<W> {
  bool saving = false;
  String? saveError;
  bool _closing = false;
  bool _allowDiscard = false;

  /// Forms opt in by comparing their current values with the values at opening.
  bool get hasUnsavedChanges => false;

  Future<void> requestClose() async {
    if (saving || _closing || !mounted) return;
    _closing = true;
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      if (hasUnsavedChanges) {
        final discard = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Bỏ thay đổi chưa lưu?'),
            content: const Text(
              'Thông tin đang nhập chưa được lưu. Bạn có thể tiếp tục nhập hoặc bỏ thay đổi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Tiếp tục nhập'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Bỏ thay đổi'),
              ),
            ],
          ),
        );
        if (!mounted || discard != true) return;
      }
      setState(() => _allowDiscard = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      WidgetsBinding.instance.scheduleFrame();
    } finally {
      _closing = false;
    }
  }

  Future<void> saveDraft(T draft, Future<bool> Function(T)? persist) async {
    if (saving) return;
    if (persist == null) {
      Navigator.pop(context, draft);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      saving = true;
      saveError = null;
    });
    bool saved;
    try {
      saved = await persist(draft);
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, draft);
      return;
    }
    setState(() {
      saving = false;
      saveError =
          'Chưa thể lưu. Thông tin vẫn được giữ trong form; hãy thử lại.';
    });
  }

  Widget saveFeedback() => saving
      ? const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              LinearProgressIndicator(),
              SizedBox(height: 8),
              Text(
                'Đang chờ máy chủ xác nhận. Nếu mất mạng, hãy kết nối lại; không gửi lặp.',
              ),
            ],
          ),
        )
      : saveError == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            saveError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );

  Widget guardSave(Widget child) => PopScope(
    canPop: !saving && (_allowDiscard || !hasUnsavedChanges),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !saving && hasUnsavedChanges) requestClose();
    },
    child: AbsorbPointer(absorbing: saving, child: child),
  );
}

/// Pageless entry forms must not survive a change of account, including while
/// they are waiting for server confirmation. Local drafts remain isolated by UID;
/// the old account's form/chooser must never stay visible in the new session.
class AccountBoundDialog extends ConsumerWidget {
  const AccountBoundDialog({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authSessionProvider.select((s) => s.value?.uid), (
      before,
      after,
    ) {
      if (before == after) return;
      final route = ModalRoute.of(context);
      final navigator = Navigator.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || route?.isActive != true) return;
        // Dispose the draft even if its pending-write PopScope blocks user back.
        navigator.popUntil(
          (candidate) => candidate == route || candidate.isFirst,
        );
        if (route!.isCurrent) navigator.removeRoute(route);
      });
    });
    return child;
  }
}
