import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../profile/presentation/account_information_screen.dart';
import '../models/account_action_failure.dart';
import '../models/auth_failure.dart';
import '../models/auth_validation.dart';
import '../providers/auth_providers.dart';
import 'account_security_dialogs.dart';
import 'auth_flow_page.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmationFocus = FocusNode();
  final _scroll = ScrollController();
  bool _registering = false;
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  bool _resetDialogOpen = false;
  bool _usingGoogle = false;
  AutovalidateMode _validation = AutovalidateMode.disabled;

  bool get _busy =>
      ref.read(authControllerProvider).isLoading ||
      ref.read(accountSecurityControllerProvider).isLoading;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmationFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _validation = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) {
      if (AuthValidation.email(_email.text) != null) {
        _emailFocus.requestFocus();
      } else if (AuthValidation.password(
            _password.text,
            registering: _registering,
          ) !=
          null) {
        _passwordFocus.requestFocus();
      } else {
        _confirmationFocus.requestFocus();
      }
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _usingGoogle = false);
    ref.read(accountSecurityControllerProvider.notifier).clearError();
    final controller = ref.read(authControllerProvider.notifier);
    if (_registering) {
      await controller.register(email: _email.text, password: _password.text);
    } else {
      await controller.signIn(email: _email.text, password: _password.text);
    }
    if (mounted && !ref.read(authControllerProvider).hasError) {
      TextInput.finishAutofillContext();
    }
  }

  void _toggleMode() {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).clearError();
    ref.read(accountSecurityControllerProvider.notifier).clearError();
    // Form.reset also resets controller-backed fields to their initial value.
    final email = _email.value;
    _formKey.currentState?.reset();
    _email.value = email;
    _password.clear();
    _confirmation.clear();
    setState(() {
      _registering = !_registering;
      _hidePassword = true;
      _hideConfirmation = true;
      _validation = AutovalidateMode.disabled;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _forgotPassword() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    ref.read(accountSecurityControllerProvider.notifier).clearError();
    setState(() => _resetDialogOpen = true);
    try {
      await showResetPasswordDialog(context, initialEmail: _email.text);
    } finally {
      if (mounted) {
        ref.read(accountSecurityControllerProvider.notifier).clearError();
        setState(() => _resetDialogOpen = false);
      }
    }
  }

  Future<void> _googleSignIn() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _usingGoogle = true);
    ref.read(accountSecurityControllerProvider.notifier).clearError();
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = ref.watch(authControllerProvider);
    final accountAction = ref.watch(accountSecurityControllerProvider);
    final busy = action.isLoading || accountAction.isLoading;
    final emailBusy = action.isLoading && !_usingGoogle;
    final googleBusy = action.isLoading && _usingGoogle;
    final error = _resetDialogOpen
        ? action.error
        : accountAction.error ?? action.error;
    return PopScope(
      canPop: !_registering && !busy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _registering && !busy) _toggleMode();
      },
      child: AuthFlowPage(
        scrollController: _scroll,
        title: _registering ? 'Tạo tài khoản' : 'Chào mừng bạn trở lại',
        subtitle: _registering
            ? 'Bắt đầu theo dõi dinh dưỡng cùng HealthMate.'
            : 'Đăng nhập để tiếp tục theo dõi dinh dưỡng.',
        children: [
          AutofillGroup(
            child: Form(
              key: _formKey,
              autovalidateMode: _validation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const ValueKey('auth-email'),
                    controller: _email,
                    focusNode: _emailFocus,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    decoration: const InputDecoration(
                      label: Text('Email'),
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: AuthValidation.email,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const ValueKey('auth-password'),
                    controller: _password,
                    focusNode: _passwordFocus,
                    enabled: !busy,
                    obscureText: _hidePassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    autofillHints: [
                      _registering
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    textInputAction: _registering
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (_registering) {
                        _confirmationFocus.requestFocus();
                      } else {
                        _submit();
                      }
                    },
                    decoration: InputDecoration(
                      label: const Text('Mật khẩu'),
                      helperText: _registering ? 'Dùng ít nhất 8 ký tự.' : null,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _hidePassword
                            ? 'Hiện mật khẩu'
                            : 'Ẩn mật khẩu',
                        onPressed: busy
                            ? null
                            : () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => AuthValidation.password(
                      value,
                      registering: _registering,
                    ),
                  ),
                  if (!_registering)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const ValueKey('forgot-password'),
                        onPressed: busy ? null : _forgotPassword,
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ),
                  if (_registering) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      key: const ValueKey('auth-confirmation'),
                      controller: _confirmation,
                      focusNode: _confirmationFocus,
                      enabled: !busy,
                      obscureText: _hideConfirmation,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        label: const Text('Nhập lại mật khẩu'),
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _hideConfirmation
                              ? 'Hiện mật khẩu nhập lại'
                              : 'Ẩn mật khẩu nhập lại',
                          onPressed: busy
                              ? null
                              : () => setState(
                                  () => _hideConfirmation = !_hideConfirmation,
                                ),
                          icon: Icon(
                            _hideConfirmation
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          AuthValidation.confirmation(value, _password.text),
                    ),
                  ],
                  if (error != null && !_resetDialogOpen) ...[
                    const SizedBox(height: AppSpacing.md),
                    AuthNotice(
                      isError: true,
                      message: switch (error) {
                        AuthFailure failure => failure.message,
                        AccountActionFailure failure => failure.message,
                        _ => 'Chưa thể hoàn tất thao tác. Vui lòng thử lại.',
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    key: const ValueKey('auth-submit'),
                    onPressed: busy ? null : _submit,
                    child: AuthActionLabel(
                      busy: emailBusy,
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      label: emailBusy
                          ? (_registering
                                ? 'Đang tạo tài khoản…'
                                : 'Đang đăng nhập…')
                          : (_registering ? 'Tạo tài khoản' : 'Đăng nhập'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'hoặc',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            key: const ValueKey('auth-google'),
            icon: googleBusy
                ? null
                : Image.asset(
                    'assets/branding/google_g.png',
                    width: 20,
                    height: 20,
                    excludeFromSemantics: true,
                  ),
            onPressed: busy ? null : _googleSignIn,
            label: AuthActionLabel(
              label: googleBusy
                  ? 'Đang kết nối Google…'
                  : 'Tiếp tục với Google',
              busy: googleBusy,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _registering ? 'Đã có tài khoản?' : 'Chưa có tài khoản?',
                style: theme.textTheme.bodyMedium,
              ),
              TextButton(
                key: const ValueKey('auth-toggle'),
                onPressed: busy ? null : _toggleMode,
                child: Text(_registering ? 'Đăng nhập' : 'Đăng ký'),
              ),
            ],
          ),
          Center(
            child: TextButton(
              key: const ValueKey('auth-privacy'),
              onPressed: busy ? null : () => showPrivacyInformation(context),
              child: const Text('Quyền riêng tư'),
            ),
          ),
        ],
      ),
    );
  }
}
