import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final profile = profileState.value;
    final metrics = metricState.value ?? const <BodyMetric>[];
    final accountAnchor = GlobalKey();

    return FeaturePage(
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      titleStyle: theme.textTheme.headlineSmall?.copyWith(fontSize: 25),
      headerAction: IconButton(
        tooltip: 'Tài khoản và cài đặt',
        icon: const Icon(Icons.settings_outlined),
        onPressed: () {
          final anchor = accountAnchor.currentContext;
          if (anchor != null) {
            Scrollable.ensureVisible(
              anchor,
              duration: const Duration(milliseconds: 250),
            );
          }
        },
      ),
      title: 'Không gian cá nhân',
      subtitle: '',
      children: [
        if (ref.watch(premiumDemoEnabledProvider))
          Card(
            child: ListTile(
              key: const ValueKey('open-premium'),
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('HealthMate Premium'),
              subtitle: const Text('20.000đ / 30 ngày · Demo không thu tiền'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.premium),
            ),
          ),
        PersonalOverview(
          onEdit: profile == null
              ? null
              : () => _editProfile(context, ref, profile),
        ),
        _ProfileCard(
          state: profileState,
          profile: profile,
          onEdit: profile == null
              ? null
              : () => _editProfile(context, ref, profile),
          onRetry: () => _retryProfile(ref),
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
          key: accountAnchor,
          email: user?.email,
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
        if (profile != null && latest.value?.isNotEmpty == true)
          const SizedBox(height: AppSpacing.md),
        _MetricsCard(
          state: metricState,
          metrics: metrics,
          onAdd: profile == null ? null : () => _editMetric(context, ref),
          onEdit: (metric) => _editMetric(context, ref, metric: metric),
          onDelete: (metric) => _deleteMetric(context, ref, metric),
          onRetry: () => ref.invalidate(bodyMetricPageProvider(pageCursor)),
          pageNumber: _page + 1,
          onNewer: _page == 0 ? null : () => setState(() => _page--),
          onOlder:
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AccountBoundDialog(
        child: AlertDialog(
          title: const Text('Xóa lần đo?'),
          content: Text(
            'Lần đo ${metric.weightKg.toStringAsFixed(1)} kg sẽ bị xóa khỏi lịch sử.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Giữ lại'),
            ),
            FilledButton(
              key: const ValueKey('confirm-delete-metric'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true ||
        !context.mounted ||
        ref.read(authSessionProvider).value?.uid != uid) {
      return;
    }
    final deleted = await ref
        .read(profileControllerProvider.notifier)
        .deleteBodyMetric(metric.id);
    if (deleted && context.mounted) {
      ref.invalidate(weeklyLogsProvider);
      _showSaved(context, 'Đã xóa lần đo.');
    }
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
    required this.canChangePassword,
    required this.authAction,
    required this.accountAction,
    required this.onSignOut,
    required this.onChangePassword,
    required this.onDeleteAccount,
  });

  final String? email;
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
    final locale = MaterialLocalizations.of(context);
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
                              : 'Chiều cao: ${profile!.heightCm!.toStringAsFixed(1)} cm',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          profile!.birthDate == null
                              ? 'Chưa nhập ngày sinh'
                              : 'Ngày sinh: ${locale.formatMediumDate(profile!.birthDate!)}',
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
                            'Cân nặng mục tiêu: ${profile!.targetWeightKg!.toStringAsFixed(1)} kg',
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
    required this.state,
    required this.metrics,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
    required this.pageNumber,
    required this.onNewer,
    required this.onOlder,
  });

  final AsyncValue<List<BodyMetric>> state;
  final List<BodyMetric> metrics;
  final VoidCallback? onAdd;
  final ValueChanged<BodyMetric> onEdit;
  final ValueChanged<BodyMetric> onDelete;
  final VoidCallback onRetry;
  final int pageNumber;
  final VoidCallback? onNewer, onOlder;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lịch sử cân nặng',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  key: const ValueKey('add-metric'),
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Thêm'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Trang $pageNumber · tối đa 25 lần cân. Biểu đồ: 12 lần gần nhất trên trang, đơn vị kg.',
            ),
            state.when(
              loading: () => const _LoadingLine(),
              error: (error, _) =>
                  _LoadError(message: _messageFor(error), onRetry: onRetry),
              data: (_) => metrics.isEmpty
                  ? const Text(
                      'Chưa có lần đo nào. Thêm cân nặng để bắt đầu theo dõi lịch sử.',
                    )
                  : Column(
                      children: [
                        WeightChart(metrics: metrics),
                        const SizedBox(height: AppSpacing.md),
                        for (final metric in metrics)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              child: Icon(Icons.monitor_weight_outlined),
                            ),
                            title: Text(
                              '${metric.weightKg.toStringAsFixed(1)} kg',
                            ),
                            subtitle: Text(
                              [
                                locale.formatMediumDate(metric.measuredAt),
                                if (metric.note.isNotEmpty) metric.note,
                              ].join(' · '),
                            ),
                            trailing: Wrap(
                              spacing: AppSpacing.xs,
                              children: [
                                IconButton(
                                  key: ValueKey('edit-metric-${metric.id}'),
                                  onPressed: () => onEdit(metric),
                                  tooltip: 'Sửa lần đo',
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  key: ValueKey('delete-metric-${metric.id}'),
                                  onPressed: () => onDelete(metric),
                                  tooltip: 'Xóa lần đo',
                                  icon: const Icon(Icons.delete_outline),
                                ),
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
