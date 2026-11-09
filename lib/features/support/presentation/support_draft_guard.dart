import 'package:flutter/material.dart';

/// Protect only this in-memory composer. Never start another request or leave
/// the page while the existing request is still awaiting its result.
class SupportDraftGuard extends StatefulWidget {
  const SupportDraftGuard({
    required this.hasDraft,
    required this.busy,
    required this.child,
    super.key,
  });
  final bool hasDraft, busy;
  final Widget child;

  @override
  State<SupportDraftGuard> createState() => _SupportDraftGuardState();
}

class _SupportDraftGuardState extends State<SupportDraftGuard> {
  bool _confirming = false, _allowExit = false;

  Future<void> _requestExit() async {
    if (_confirming || widget.busy || !widget.hasDraft) return;
    _confirming = true;
    FocusManager.instance.primaryFocus?.unfocus();
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bỏ nội dung đang soạn?'),
        content: const Text(
          'Nội dung đang giữ trên màn hình sẽ bị bỏ khi bạn rời đi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tiếp tục soạn'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Bỏ nội dung'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (discard != true) {
      _confirming = false;
      return;
    }
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.busy) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.busy && (_allowExit || !widget.hasDraft),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _requestExit();
    },
    child: widget.child,
  );
}
