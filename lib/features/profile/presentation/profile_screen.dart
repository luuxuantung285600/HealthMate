import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/config/app_feature_flags.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../nutrition_targets/presentation/nutrition_target_card.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../../shared/providers/theme_mode_provider.dart';
import '../../auth/models/auth_failure.dart';
import '../../auth/models/account_action_failure.dart';
import '../../auth/presentation/account_security_dialogs.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/body_metric.dart';
import '../models/profile_failure.dart';
import '../models/profile_validation.dart';
import '../models/user_profile.dart';
import '../providers/profile_providers.dart';
import 'body_metric_form_dialog.dart';
import 'profile_form_dialog.dart';
import 'weight_chart.dart';
import 'personal_overview.dart';
import 'delete_body_metric_dialog.dart';
import '../../data_export/presentation/journal_export_dialog.dart';
import '../../premium/providers/premium_providers.dart';
import '../../weekly_reflection/providers/weekly_reflection_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _pageUid;
  final _cursors = <BodyMetricCursor?>[null];
  int _page = 0;
  final _profileAnchor = GlobalKey();
  final _metricsAnchor = GlobalKey();
  final _accountAnchor = GlobalKey();

  void _jumpTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 250),
      alignment: .05,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final selectedMode = ref.watch(themeModeProvider);
    final user = ref.watch(authSessionProvider).value;
    final authAction = ref.watch(authControllerProvider);
    final accountAction = ref.watch(accountSecurityControllerProvider);
    final profileAction = ref.watch(profileControllerProvider);
    final profileState = ref.watch(userProfileProvider);
    if (_pageUid != user?.uid) {
      _pageUid = user?.uid;
      _cursors.clear();
      _cursors.add(null);
      _page = 0;
    }
    final pageCursor = _cursors[_page];
    final pageState = ref.watch(bodyMetricPageProvider(pageCursor));
    final metricState = pageState.whenData((page) => page.metrics);
    final today = localDateOnly(ref.watch(localClockProvider));
    final latest = ref.watch(latestBodyMetricProvider(today));
    final profile = !profileState.isLoading && !profileState.hasError
        ? profileState.value
        : null;
    final metrics = !metricState.isLoading && !metricState.hasError
        ? metricState.value ?? const <BodyMetric>[]
        : const <BodyMetric>[];
    final canEdit = profile != null && !profileAction.isLoading;

    return FeaturePage(
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      titleStyle: theme.textTheme.headlineSmall?.copyWith(fontSize: 25),
      headerAction: IconButton(
        tooltip: 'Tài khoản và cài đặt',
        icon: const Icon(Icons.settings_outlined),
        onPressed: () => _jumpTo(_accountAnchor),
      ),
      title: 'Không gian cá nhân',
      subtitle: '',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              key: const ValueKey('jump-profile'),
              avatar: const Icon(Icons.person_outline),
              label: const Text('Hồ sơ'),
              onPressed: () => _jumpTo(_profileAnchor),
            ),
            ActionChip(
              key: const ValueKey('jump-weight'),
              avatar: const Icon(Icons.monitor_weight_outlined),
              label: const Text('Cân nặng'),
              onPressed: () => _jumpTo(_metricsAnchor),
            ),
            ActionChip(
              key: const ValueKey('jump-account'),
              avatar: const Icon(Icons.manage_accounts_outlined),
              label: const Text('Tài khoản'),
              onPressed: () => _jumpTo(_accountAnchor),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        PersonalOverview(
          onEdit: !canEdit ? null : () => _editProfile(context, ref, profile),
        ),
        _ProfileCard(
          key: _profileAnchor,
          state: profileState,
          profile: profile,
          onEdit: !canEdit ? null : () => _editProfile(context, ref, profile),
          onRetry: () => _retryProfile(ref),
        ),
        Card(
          child: ListTile(
            key: const ValueKey('open-premium'),
            leading: MediaQuery.textScalerOf(context).scale(1) > 1.5
                ? null
                : const Icon(Icons.workspace_premium_outlined),
            title: const Text('HealthMate Premium'),
            subtitle: Text(
              ref.watch(premiumDemoEnabledProvider)
                  ? 'Demo không thu tiền'
                  : 'Gói đăng ký qua Google Play',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.premium),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: ListTile(
            key: const ValueKey('open-support'),
            leading: const Icon(Icons.support_agent_outlined),
            title: const Text('Báo lỗi & Góp ý'),
            subtitle: const Text('Gửi yêu cầu và xem phản hồi từ HealthMate'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.support),
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                key: const ValueKey('open-wellness'),
                leading: const Icon(Icons.favorite_outline),
                title: const Text('Thói quen & kế hoạch'),
                subtitle: const Text(
                  'Nhắc bữa · Thực đơn · Bước chân · Giấc ngủ · Dưỡng chất',
                ),
                onTap: () => context.push(AppRoutes.wellness),
              ),
              ListTile(
                key: const ValueKey('open-goals-quests'),
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Mục tiêu và nhiệm vụ hằng ngày'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go(AppRoutes.quest),
              ),
              if (ref.watch(appFeatureFlagsProvider).chatbotEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  key: const ValueKey('open-chat'),
                  leading: const Icon(Icons.forum_outlined),
                  title: const Text('Trò chuyện cùng HealthMate'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(AppRoutes.chat),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (profileAction.isLoading) const LinearProgressIndicator(),
        if (profileAction.error case final ProfileFailure error) ...[
          _InlineError(
            message: error.message,
            onDismiss: () =>
                ref.read(profileControllerProvider.notifier).clearError(),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Card(
          child: Column(
            children: [
              ListTile(
                key: const ValueKey('open-about'),
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('Giới thiệu'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go(AppRoutes.about),
              ),
              const Divider(height: 1),
              ListTile(
                key: const ValueKey('open-privacy'),
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Quyền riêng tư'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go(AppRoutes.privacy),
              ),
              const Divider(height: 1),
              ListTile(
                key: const ValueKey('open-disclaimer'),
                leading: const Icon(Icons.health_and_safety_outlined),
                title: const Text('Lưu ý sức khỏe'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go(AppRoutes.disclaimer),
              ),
            ],
          ),
        ),
        _AccountCard(
          key: _accountAnchor,
          email: user?.email,
          emailVerified: user?.emailVerified == true,
          providerIds: user?.providerIds ?? const [],
          canChangePassword: user?.hasPassword == true,
          authAction: authAction,
          accountAction: accountAction,
          onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
          onChangePassword: () => _changePassword(context, ref),
          onDeleteAccount: () => _deleteAccount(context, ref),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: ListTile(
            key: const ValueKey('open-personalization'),
            leading: const Icon(Icons.tune_rounded),
            title: const Text('Cá nhân hóa thêm'),
            subtitle: Text(
              profile?.personalization == null
                  ? 'Bổ sung mục tiêu và thói quen khi bạn sẵn sàng'
                  : profile!.personalization!.segmentLabels.join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.personalization),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (profile != null &&
            !latest.isLoading &&
            !latest.hasError &&
            latest.value?.isNotEmpty == true)
          _BmiCard(profile: profile, latestMetric: latest.value!.first),
        if (profile != null && latest.hasError)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _LoadError(
                message: 'Chưa tải được lần cân mới nhất để tính BMI.',
                onRetry: () => ref.invalidate(latestBodyMetricProvider(today)),
              ),
            ),
          ),
        if (profile != null &&
            !latest.isLoading &&
            !latest.hasError &&
            latest.value?.isNotEmpty == true)
          const SizedBox(height: AppSpacing.md),
        _MetricsCard(
          key: _metricsAnchor,
          state: metricState,
          metrics: metrics,
          onAdd: !canEdit ? null : () => _editMetric(context, ref),
          busy: profileAction.isLoading,
          onEdit: (metric) => _editMetric(context, ref, metric: metric),
          onDelete: (metric) => _deleteMetric(context, ref, metric),
          onRetry: () => ref.invalidate(bodyMetricPageProvider(pageCursor)),
          pageNumber: _page + 1,
          onNewer: _page == 0 || profileAction.isLoading
              ? null
              : () => setState(() => _page--),
          onOlder:
              profileAction.isLoading ||
                  pageState.isLoading ||
                  pageState.hasError ||
                  pageState.value?.hasMore != true
              ? null
              : () {
                  final next = pageState.value!.nextCursor;
                  if (next == null) return;
                  setState(() {
                    if (_cursors.length > _page + 1) {
                      _cursors.removeRange(_page + 1, _cursors.length);
                    }
                    _cursors.add(next);
                    _page++;
                  });
                },
        ),
        const SizedBox(height: AppSpacing.xl),
        NutritionTargetCard(day: localDateOnly(ref.watch(localClockProvider))),
        Card(
          child: ListTile(
            key: const ValueKey('open-food-library'),
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Thư viện món của tôi'),
            subtitle: const Text('Món cá nhân, công thức và khẩu phần'),
            onTap: () => context.push(AppRoutes.foodLibrary),
          ),
        ),
        Card(
          child: ListTile(
            key: const ValueKey('open-journal-export'),
            leading: const Icon(Icons.download_outlined),
            title: const Text('Xuất nhật ký CSV'),
            subtitle: const Text('Chọn khoảng ngày và nơi lưu tệp riêng tư'),
            onTap: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) =>
                  const AccountBoundDialog(child: JournalExportDialog()),
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Giao diện', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                const Text('Lựa chọn này được giữ lại trên thiết bị.'),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final option in const [
                      (
                        mode: ThemeMode.system,
                        label: 'Thiết bị',
                        icon: Icons.phone_android,
                      ),
                      (
                        mode: ThemeMode.light,
                        label: 'Sáng',
                        icon: Icons.light_mode_outlined,
                      ),
                      (
                        mode: ThemeMode.dark,
                        label: 'Tối',
                        icon: Icons.dark_mode_outlined,
                      ),
                    ])
                      ChoiceChip(
                        avatar: Icon(option.icon, size: 18),
                        label: Text(option.label),
                        selected: selectedMode == option.mode,
                        onSelected: (_) async {
                          try {
                            await ref
                                .read(themeModeProvider.notifier)
                                .setMode(option.mode);
                          } catch (_) {
                            if (context.mounted) {
                              _showSaved(
                                context,
                                'Chưa thể lưu lựa chọn giao diện.',
                              );
                            }
                          }
                        },
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    ref.read(accountSecurityControllerProvider.notifier).clearError();
    final request = await showChangePasswordDialog(context);
    if (request == null || !context.mounted) return;
    final changed = await ref
        .read(accountSecurityControllerProvider.notifier)
        .changePassword(
          currentPassword: request.currentPassword,
          newPassword: request.newPassword,
        );
    if (changed && context.mounted) {
      _showSaved(context, 'Đã đổi mật khẩu.');
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    ref.read(accountSecurityControllerProvider.notifier).clearError();
    final password = await showDeleteAccountDialog(
      context,
      requirePassword:
          ref.read(authSessionProvider).value?.hasPassword != false,
    );
    if (password == null || !context.mounted) return;
    await ref
        .read(accountSecurityControllerProvider.notifier)
        .deleteAccount(password);
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null || uid != profile.uid) return;
    final saved = await showDialog<UserProfileDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AccountBoundDialog(
        child: ProfileFormDialog(
          profile: profile,
          onSave: (draft) async {
            if (ref.read(authSessionProvider).value?.uid != uid) return false;
            return ref
                .read(profileControllerProvider.notifier)
                .updateProfile(draft);
          },
        ),
      ),
    );
    if (saved != null &&
        context.mounted &&
        ref.read(authSessionProvider).value?.uid == uid) {
      _showSaved(context, 'Đã cập nhật hồ sơ.');
    }
  }

  Future<void> _editMetric(
    BuildContext context,
    WidgetRef ref, {
    BodyMetric? metric,
  }) async {
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) return;
    final saved = await showDialog<BodyMetricDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AccountBoundDialog(
        child: BodyMetricFormDialog(
          metric: metric,
          onSave: (draft) async {
            if (ref.read(authSessionProvider).value?.uid != uid) return false;
            final controller = ref.read(profileControllerProvider.notifier);
            return metric == null
                ? controller.addBodyMetric(draft)
                : controller.updateBodyMetric(
                    metricId: metric.id,
                    draft: draft,
                  );
          },
        ),
      ),
    );
    if (saved != null &&
        context.mounted &&
        ref.read(authSessionProvider).value?.uid == uid) {
      setState(() {
        _page = 0;
        _cursors.removeRange(1, _cursors.length);
      });
      ref.invalidate(weeklyLogsProvider);
      _showSaved(
        context,
        metric == null ? 'Đã thêm lần đo.' : 'Đã cập nhật lần đo.',
      );
    }
  }

  Future<void> _deleteMetric(
    BuildContext context,
    WidgetRef ref,
    BodyMetric metric,
  ) async {
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null || ref.read(profileControllerProvider).isLoading) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AccountBoundDialog(
        child: DeleteBodyMetricDialog(
          metric: metric,
          onDelete: () async {
            if (ref.read(authSessionProvider).value?.uid != uid) return false;
            return ref
                .read(profileControllerProvider.notifier)
                .deleteBodyMetric(metric.id);
          },
        ),
      ),
    );
    if (confirmed != true ||
        !context.mounted ||
        ref.read(authSessionProvider).value?.uid != uid) {
      return;
    }
    ref.invalidate(weeklyLogsProvider);
    _showSaved(context, 'Đã xóa lần đo.');
  }

  void _retryProfile(WidgetRef ref) {
    ref.invalidate(profileBootstrapProvider);
    ref.invalidate(userProfileProvider);
  }

  void _showSaved(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    super.key,
    required this.email,
    required this.emailVerified,
    required this.providerIds,
    required this.canChangePassword,
    required this.authAction,
    required this.accountAction,
    required this.onSignOut,
    required this.onChangePassword,
    required this.onDeleteAccount,
  });

  final String? email;
  final bool emailVerified;
  final List<String> providerIds;
  final bool canChangePassword;
  final AsyncValue<void> authAction;
  final AsyncValue<void> accountAction;
  final VoidCallback onSignOut;
  final VoidCallback onChangePassword;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = authAction.isLoading || accountAction.isLoading;
    final error = accountAction.error ?? authAction.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tài khoản của bạn', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(email ?? 'Tài khoản đã đăng nhập'),
            Text(emailVerified ? 'Email đã xác minh' : 'Email chưa xác minh'),
            if (providerIds.contains('password') ||
                providerIds.contains('google.com'))
              Text(
                'Cách đăng nhập: ${[if (providerIds.contains('password')) 'Email và mật khẩu', if (providerIds.contains('google.com')) 'Google'].join(' · ')}',
              ),
            if (!canChangePassword && providerIds.contains('google.com'))
              const Text(
                'Bạn đăng nhập bằng Google. Quản lý mật khẩu trong tài khoản Google của bạn.',
              ),
            const SizedBox(height: AppSpacing.md),
            if (canChangePassword)
              OutlinedButton.icon(
                key: const ValueKey('change-password'),
                onPressed: busy ? null : onChangePassword,
                icon: const Icon(Icons.password_rounded),
                label: const Text('Đổi mật khẩu'),
              ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              key: const ValueKey('sign-out'),
              onPressed: busy ? null : onSignOut,
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                authAction.isLoading ? 'Đang đăng xuất…' : 'Đăng xuất',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              key: const ValueKey('delete-account'),
              onPressed: busy ? null : onDeleteAccount,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(
                accountAction.isLoading
                    ? 'Đang xử lý tài khoản…'
                    : 'Xóa tài khoản và dữ liệu',
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(switch (error) {
                  AuthFailure failure => failure.message,
                  AccountActionFailure failure => failure.message,
                  _ => 'Chưa thể hoàn tất thao tác. Vui lòng thử lại.',
                }, style: TextStyle(color: theme.colorScheme.error)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    super.key,
    required this.state,
    required this.profile,
    required this.onEdit,
    required this.onRetry,
  });

  final AsyncValue<UserProfile?> state;
  final UserProfile? profile;
  final VoidCallback? onEdit;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Hồ sơ', style: theme.textTheme.titleLarge),
                ),
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Chỉnh sửa hồ sơ',
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            state.when(
              skipLoadingOnRefresh: false,
              loading: () => const _LoadingLine(),
              error: (error, _) =>
                  _LoadError(message: _messageFor(error), onRetry: onRetry),
              data: (_) => profile == null
                  ? _LoadError(
                      message: 'Chưa thể tạo hồ sơ cho tài khoản này.',
                      onRetry: onRetry,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile!.displayName.isEmpty
                              ? 'Chưa đặt tên hiển thị'
                              : profile!.displayName,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          profile!.heightCm == null
                              ? 'Chưa nhập chiều cao'
                              : 'Chiều cao: ${profile!.heightCm} cm',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          profile!.birthDate == null
                              ? 'Chưa nhập ngày sinh'
                              : 'Ngày sinh: ${DateFormat('dd/MM/yyyy').format(profile!.birthDate!)}',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          profile!.healthGoal == null
                              ? 'Chưa chọn mục tiêu sức khỏe'
                              : 'Mục tiêu: ${profile!.healthGoal!.label}',
                        ),
                        if (profile!.targetWeightKg != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Cân nặng mục tiêu: ${profile!.targetWeightKg} kg',
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.profile, required this.latestMetric});

  final UserProfile profile;
  final BodyMetric latestMetric;

  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    final measuredAt = latestMetric.measuredAt.toLocal();
    final bmi = ProfileValidation.bmi(
      heightCm: profile.heightCm,
      weightKg: latestMetric.weightKg,
    );
    if (bmi == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BMI tham khảo: ${bmi.toStringAsFixed(1)}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Lần cân mới nhất: ${latestMetric.weightKg} kg · ${DateFormat('dd/MM/yyyy').format(measuredAt)} · ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(measuredAt), alwaysUse24HourFormat: true)}',
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
            Text(
              'Chiều cao dùng tính: ${profile.heightCm} cm',
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tính từ chiều cao và lần đo cân nặng mới nhất. Chỉ số này chỉ để tham khảo, không phải chẩn đoán y khoa.',
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({
    super.key,
    required this.state,
    required this.metrics,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
    required this.pageNumber,
    required this.onNewer,
    required this.onOlder,
    required this.busy,
  });

  final AsyncValue<List<BodyMetric>> state;
  final List<BodyMetric> metrics;
  final VoidCallback? onAdd;
  final ValueChanged<BodyMetric> onEdit;
  final ValueChanged<BodyMetric> onDelete;
  final VoidCallback onRetry;
  final int pageNumber;
  final VoidCallback? onNewer, onOlder;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = MaterialLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final title = Text(
                  'Lịch sử cân nặng',
                  style: theme.textTheme.titleLarge,
                );
                final add = FilledButton.icon(
                  key: const ValueKey('add-metric'),
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Thêm'),
                );
                if (constraints.maxWidth < 360 &&
                    MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      title,
                      const SizedBox(height: AppSpacing.sm),
                      Align(alignment: Alignment.centerLeft, child: add),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: title),
                    add,
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Trang $pageNumber · tối đa 25 lần cân. Biểu đồ: 12 lần gần nhất trên trang, đơn vị kg.',
            ),
            state.when(
              skipLoadingOnRefresh: false,
              loading: () => const _LoadingLine(),
              error: (error, _) =>
                  _LoadError(message: _messageFor(error), onRetry: onRetry),
              data: (_) => metrics.isEmpty
                  ? Text(
                      pageNumber == 1
                          ? 'Chưa có lần đo nào. Thêm cân nặng để bắt đầu theo dõi lịch sử.'
                          : 'Trang này không còn lần đo nào. Chọn Mới hơn để quay lại lịch sử gần đây.',
                    )
                  : Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.textScalerOf(context).scale(12),
                        ),
                        WeightChart(metrics: metrics),
                        const SizedBox(height: AppSpacing.md),
                        for (final metric in metrics)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '${metric.weightKg} kg',
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(
                                  '${DateFormat('dd/MM/yyyy').format(metric.measuredAt.toLocal())} · ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(metric.measuredAt.toLocal()), alwaysUse24HourFormat: true)}',
                                ),
                                if (metric.note.isNotEmpty) Text(metric.note),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  children: [
                                    TextButton.icon(
                                      key: ValueKey('edit-metric-${metric.id}'),
                                      onPressed: busy
                                          ? null
                                          : () => onEdit(metric),
                                      icon: const Icon(Icons.edit_outlined),
                                      label: const Text('Sửa lần đo'),
                                    ),
                                    TextButton.icon(
                                      key: ValueKey(
                                        'delete-metric-${metric.id}',
                                      ),
                                      onPressed: busy
                                          ? null
                                          : () => onDelete(metric),
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('Xóa lần đo'),
                                    ),
                                  ],
                                ),
                                const Divider(height: 1),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  key: const ValueKey('weight-history-newer'),
                  onPressed: state.isLoading ? null : onNewer,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Mới hơn'),
                ),
                TextButton.icon(
                  key: const ValueKey('weight-history-older'),
                  onPressed: state.isLoading ? null : onOlder,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Cũ hơn'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: Text('Đang tải dữ liệu…')),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Thử lại'),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Đóng thông báo',
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

String _messageFor(Object error) => switch (error) {
  ProfileFailure failure => failure.message,
  _ => 'Chưa thể tải dữ liệu. Vui lòng thử lại.',
};
