import '../theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/admin_runtime.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/models/account_action_failure.dart';
import '../../features/auth/models/auth_failure.dart';
import '../../features/auth/presentation/account_deletion_dialog.dart';
import '../../features/meal_drafts/data/meal_draft_store.dart';
import '../../features/wellness/providers/wellness_providers.dart';

/// A second device stops its own local writers as soon as it sees the server
/// marker. It never starts server cleanup or deletes Auth without confirmation.
final observedDeletionLocalCleanupProvider = FutureProvider.autoDispose
    .family<void, String>((ref, uid) async {
      final device = ref.read(wellnessDeviceProvider);
      final drafts = ref.read(mealDraftStoreProvider);
      // Attempt both even if one native channel fails; report failure only
      // after the other writer has had a chance to stop as well.
      await Future.wait<void>([
        if (device.supported) device.clearAccount(uid),
        if (drafts.local.supported) drafts.clearForAccountDeletion(uid),
      ]);
    }, retry: (_, _) => null);

class AdminAccessGate extends ConsumerWidget {
  const AdminAccessGate({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider).value;
    if (user?.emailVerified != true) {
      return child;
    }
    final deletion = ref.watch(accountDeletionJobProvider);
    final deleting = deletion.value != null;
    final controlsEnabled = ref.watch(adminControlsEnabledProvider);
    if (!controlsEnabled &&
        !deleting &&
        !deletion.isLoading &&
        !deletion.hasError) {
      return child;
    }
    final access = controlsEnabled ? ref.watch(appAccountAccessProvider) : null;
    final config = controlsEnabled ? ref.watch(adminAppConfigProvider) : null;
    final localCleanup = deleting
        ? ref.watch(observedDeletionLocalCleanupProvider(user!.uid))
        : null;
    final action = ref.watch(accountSecurityControllerProvider);
    final blocked = access?.value?.suspended == true;
    final failed =
        deletion.hasError ||
        (access?.hasError ?? false) ||
        (config?.hasError ?? false);
    final waiting =
        deletion.isLoading ||
        (controlsEnabled &&
            (access!.isLoading ||
                config!.isLoading ||
                access.value?.verified != true ||
                config.value?.verified != true));
    final maintenance =
        !failed && !waiting && config?.value?.maintenanceMode == true;
    if (!deleting && !blocked && !failed && !waiting && !maintenance) {
      return child;
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    deleting
                        ? AppIcons.trash2
                        : blocked
                        ? AppIcons.lockKeyhole
                        : maintenance
                        ? AppIcons.wrench
                        : AppIcons.cloudCheck,
                    size: 48,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    deleting
                        ? 'Tài khoản đang chờ xóa'
                        : blocked
                        ? 'Tạm khóa truy cập HealthMate'
                        : maintenance
                        ? 'HealthMate đang bảo trì'
                        : failed
                        ? 'Chưa xác nhận được quyền truy cập'
                        : 'Đang kiểm tra quyền truy cập',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    deleting
                        ? 'Tài khoản đã khóa ghi dữ liệu. Giữ kết nối và chọn tiếp tục để hoàn tất xóa; bạn không thể hủy để mở lại tài khoản.'
                        : blocked
                        ? access!.value!.reason
                        : maintenance
                        ? config!.value!.maintenanceMessage
                        : 'Cần kết nối máy chủ để kiểm tra trạng thái tài khoản và cấu hình ứng dụng.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if ((waiting &&
                          !blocked &&
                          !maintenance &&
                          !failed &&
                          !deleting) ||
                      action.isLoading)
                    const LinearProgressIndicator(),
                  if (localCleanup?.hasError == true) ...[
                    const Text(
                      'Chưa dừng hoặc dọn xong dữ liệu trên thiết bị này. Hãy thử lại; chưa thể xác nhận hoàn tất.',
                    ),
                    TextButton(
                      onPressed: action.isLoading
                          ? null
                          : () => ref.invalidate(
                              observedDeletionLocalCleanupProvider(user!.uid),
                            ),
                      child: const Text('Thử dọn thiết bị lại'),
                    ),
                  ],
                  if (action.hasError)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(switch (action.error) {
                        AccountActionFailure error => error.message,
                        AuthFailure error => error.message,
                        _ => 'Chưa hoàn tất yêu cầu. Hãy thử lại.',
                      }),
                    ),
                  if (blocked || deleting)
                    FilledButton(
                      key: const ValueKey('blocked-delete-account'),
                      onPressed: action.isLoading
                          ? null
                          : () => requestAccountDeletion(context, ref),
                      child: Text(
                        deleting
                            ? 'Tiếp tục xóa tài khoản'
                            : 'Xóa tài khoản và dữ liệu',
                      ),
                    ),
                  TextButton(
                    onPressed: action.isLoading
                        ? null
                        : () {
                            ref.invalidate(accountDeletionJobProvider);
                            ref.invalidate(appAccountAccessProvider);
                            ref.invalidate(adminAppConfigProvider);
                          },
                    child: const Text('Kiểm tra lại'),
                  ),
                  TextButton(
                    onPressed: action.isLoading
                        ? null
                        : () => ref
                              .read(authControllerProvider.notifier)
                              .signOut(),
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
