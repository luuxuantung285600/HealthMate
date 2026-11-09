import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../models/auth_failure.dart';

import '../models/auth_validation.dart';
import 'auth_flow_page.dart';

class ChangePasswordRequest {
  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}

Future<void> showResetPasswordDialog(
  BuildContext context, {
  required String initialEmail,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (context) => Dialog.fullscreen(
    child: _ResetPasswordDialog(initialEmail: initialEmail),
  ),
);

Future<ChangePasswordRequest?> showChangePasswordDialog(BuildContext context) =>
    showDialog<ChangePasswordRequest>(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );

Future<String?> showDeleteAccountDialog(
  BuildContext context, {
  bool requirePassword = true,
}) => showDialog<String>(
  context: context,
  barrierDismissible: false,
  builder: (context) => _DeleteAccountDialog(requirePassword: requirePassword),
);

class _ResetPasswordDialog extends ConsumerStatefulWidget {
  const _ResetPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  ConsumerState<_ResetPasswordDialog> createState() =>
      _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends ConsumerState<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  Timer? _ticker;
  bool _sent = false;
  int _displayedCooldown = 0;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail.trim());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted &&
          ref
                  .read(accountSecurityControllerProvider.notifier)
                  .resetCooldownSeconds !=
              _displayedCooldown) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(accountSecurityControllerProvider).isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final sent = await ref
        .read(accountSecurityControllerProvider.notifier)
        .sendPasswordResetEmail(_email.text.trim());
    if (mounted && sent) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountSecurityControllerProvider);
    final cooldown = ref
        .read(accountSecurityControllerProvider.notifier)
        .resetCooldownSeconds;
    _displayedCooldown = cooldown;
    return PopScope(
      canPop: !state.isLoading,
      child: AuthFlowPage(
        title: _sent ? 'Kiểm tra hộp thư' : 'Đặt lại mật khẩu',
        subtitle: _sent
            ? 'Nếu email thuộc một tài khoản HealthMate, bạn sẽ nhận được liên kết đặt lại mật khẩu.'
            : 'Nhận liên kết đặt lại mật khẩu qua email đã đăng ký.',
        showBack: true,
        onBack: state.isLoading ? null : () => Navigator.of(context).pop(),
        children: [
          Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_sent)
                  TextFormField(
                    key: const ValueKey('reset-password-email'),
                    controller: _email,
                    enabled: !state.isLoading && !_sent,
                    autofocus: widget.initialEmail.trim().isEmpty,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      label: Text('Email tài khoản'),
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    validator: AuthValidation.email,
                    onFieldSubmitted: (_) {
                      if (!state.isLoading && cooldown == 0) _submit();
                    },
                  ),
                if (_sent) ...[
                  AuthEmailAddress(email: _email.text.trim()),
                  const SizedBox(height: 24),
                  const AuthNotice(
                    message:
                        'Mở liên kết trong thư để chọn mật khẩu mới. Kiểm tra thư rác nếu chưa thấy email.',
                  ),
                ],
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: AuthNotice(
                      isError: true,
                      message: state.error is AuthFailure
                          ? (state.error as AuthFailure).message
                          : 'Chưa thể gửi email. Hãy thử lại.',
                    ),
                  ),
                const SizedBox(height: 24),
                if (_sent) ...[
                  FilledButton(
                    key: const ValueKey('reset-back-to-login'),
                    onPressed: state.isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Quay lại đăng nhập'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const ValueKey('send-reset-password'),
                    onPressed: state.isLoading || cooldown > 0 ? null : _submit,
                    child: AuthActionLabel(
                      busy: state.isLoading,
                      label: state.isLoading
                          ? 'Đang gửi…'
                          : cooldown > 0
                          ? 'Gửi lại sau ${cooldown}s'
                          : 'Gửi lại email',
                    ),
                  ),
                ] else
                  FilledButton(
                    key: const ValueKey('send-reset-password'),
                    onPressed: state.isLoading || cooldown > 0 ? null : _submit,
                    child: AuthActionLabel(
                      busy: state.isLoading,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                      label: state.isLoading
                          ? 'Đang gửi…'
                          : cooldown > 0
                          ? 'Gửi lại sau ${cooldown}s'
                          : 'Gửi liên kết',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ChangePasswordRequest(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Đổi mật khẩu'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('current-password'),
              controller: _currentPassword,
              autofocus: true,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) =>
                  AuthValidation.password(value, registering: false),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('new-password'),
              controller: _newPassword,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                helperText: 'Ít nhất 8 ký tự, không chỉ gồm khoảng trắng.',
                prefixIcon: Icon(Icons.password_rounded),
              ),
              validator: (value) {
                final validation = AuthValidation.password(
                  value,
                  registering: true,
                );
                if (validation != null) return validation;
                if (value == _currentPassword.text) {
                  return 'Mật khẩu mới cần khác mật khẩu hiện tại.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('new-password-confirmation'),
              controller: _confirmation,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Nhập lại mật khẩu mới',
                prefixIcon: const Icon(Icons.password_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) =>
                  AuthValidation.confirmation(value, _newPassword.text),
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Hủy'),
      ),
      FilledButton(
        key: const ValueKey('confirm-change-password'),
        onPressed: _submit,
        child: const Text('Đổi mật khẩu'),
      ),
    ],
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.requirePassword});
  final bool requirePassword;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _understood = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_understood || !_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Xóa vĩnh viễn tài khoản?'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tài khoản sẽ khóa ghi mới rồi xóa dữ liệu cá nhân và đăng nhập. Không thể hoàn tác. Giữ ứng dụng mở và có mạng; nếu gián đoạn, đăng nhập lại để tiếp tục.',
            ),
            const Text('UID, trạng thái xóa và nhật ký quản trị vẫn được giữ.'),
            const Text(
              'Xóa tài khoản không tự hủy gói Google Play. Hãy hủy gia hạn tại Play Store → Thanh toán và gói đăng ký.',
            ),
            const ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Chi tiết dữ liệu được giữ lại'),
              children: [
                Text(
                  'Mã tài khoản và trạng thái xóa ngăn dữ liệu cũ tạo lại. Nhật ký quản trị bất biến, quyền quản trị và nội dung danh mục chung cần quản trị viên xử lý theo chính sách lưu giữ. Biên nhận tài chính được giữ để đối soát, không chứa nhật ký sức khỏe. Tệp đã xuất hoặc ảnh trong thư viện của bạn không bị xóa. Xem thêm tại Quyền riêng tư.',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.requirePassword)
              TextFormField(
                key: const ValueKey('delete-account-password'),
                controller: _password,
                autofocus: true,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) =>
                    AuthValidation.password(value, registering: false),
              ),
            if (!widget.requirePassword)
              const Text(
                'Bạn sẽ xác nhận lại bằng đúng tài khoản Google trước khi xóa dữ liệu.',
              ),
            CheckboxListTile(
              key: const ValueKey('delete-account-understood'),
              contentPadding: EdgeInsets.zero,
              value: _understood,
              onChanged: (value) =>
                  setState(() => _understood = value ?? false),
              title: const Text('Tôi hiểu và đồng ý xóa không thể hoàn tác.'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Giữ tài khoản'),
      ),
      FilledButton(
        key: const ValueKey('confirm-delete-account'),
        onPressed: _understood ? _submit : null,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        child: const Text('Xóa tài khoản'),
      ),
    ],
  );
}
