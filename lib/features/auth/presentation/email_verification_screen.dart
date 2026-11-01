import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_flow_page.dart';
import '../models/auth_failure.dart';
import '../providers/auth_providers.dart';
import '../providers/email_verification_provider.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});
  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  int _displayedCooldown = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          ref.read(emailVerificationProvider.notifier).send(automatic: true),
        );
      }
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted &&
          ref.read(emailVerificationProvider.notifier).cooldownSeconds !=
              _displayedCooldown) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(emailVerificationProvider.notifier).refresh());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider.select((s) => s.value?.uid), (
      previous,
      next,
    ) {
      if (next != null && next != previous) {
        Future.microtask(() {
          if (mounted) {
            ref.read(emailVerificationProvider.notifier).send(automatic: true);
          }
        });
      }
    });
    final user = ref.watch(authSessionProvider).value,
        state = ref.watch(emailVerificationProvider),
        auth = ref.watch(authControllerProvider);
    final controller = ref.read(emailVerificationProvider.notifier),
        seconds = controller.cooldownSeconds;
    _displayedCooldown = seconds;
    final busy = state.busy || auth.isLoading;
    return AuthFlowPage(
      title: 'Xác minh email của bạn',
      subtitle: 'Mở liên kết trong email, rồi quay lại xác nhận để tiếp tục.',
      children: [
        AuthEmailAddress(email: user?.email ?? ''),
        const SizedBox(height: 24),
        if (state.error != null || auth.hasError) ...[
          AuthNotice(
            isError: true,
            message:
                state.error ??
                (auth.error is AuthFailure
                    ? (auth.error as AuthFailure).message
                    : 'Chưa thể đăng xuất. Hãy thử lại.'),
          ),
          const SizedBox(height: 24),
        ] else if (state.message.isNotEmpty) ...[
          AuthNotice(
            key: const ValueKey('verification-message'),
            message: state.message,
          ),
          const SizedBox(height: 24),
        ],
        FilledButton(
          key: const ValueKey('verification-check'),
          onPressed: busy ? null : controller.refresh,
          child: AuthActionLabel(
            busy: state.busy,
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            label: state.busy ? 'Đang xử lý…' : 'Tôi đã xác minh',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const ValueKey('verification-resend'),
          onPressed: busy || seconds > 0 ? null : controller.send,
          child: Text(
            seconds > 0 ? 'Gửi lại sau ${seconds}s' : 'Gửi lại email xác minh',
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          key: const ValueKey('verification-sign-out'),
          onPressed: busy
              ? null
              : () => ref.read(authControllerProvider.notifier).signOut(),
          child: AuthActionLabel(
            label: auth.isLoading ? 'Đang đăng xuất…' : 'Dùng tài khoản khác',
            busy: auth.isLoading,
          ),
        ),
      ],
    );
  }
}
