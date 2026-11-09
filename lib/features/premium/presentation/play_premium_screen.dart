import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/providers/local_clock_provider.dart';
import '../providers/play_billing_providers.dart';

class PlayPremiumScreen extends ConsumerWidget {
  const PlayPremiumScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(playBillingControllerProvider);
    final membership = ref.watch(verifiedMembershipProvider);
    final now = ref.watch(localClockProvider);
    final member = membership.value;
    final active =
        !membership.hasError &&
        !membership.isLoading &&
        member?.activeAt(now) == true;
    final content = controller == null
        ? Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                !ref.watch(playBillingEnabledProvider)
                    ? 'Premium chưa mở bán. HealthMate đang hoàn tất cấu hình Google Play.'
                    : 'Thanh toán Premium hỗ trợ trên Android qua Google Play. Hãy đăng nhập và xác minh email.',
              ),
            ),
          )
        : ListenableBuilder(
            listenable: controller,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(Icons.workspace_premium_rounded, size: 64),
                const SizedBox(height: 16),
                Text(
                  active ? 'Premium đang hoạt động' : 'HealthMate Premium',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chat AI tối đa 50 lượt mỗi ngày, theo hạn mức máy chủ. Nhật ký và theo dõi cơ bản vẫn miễn phí. Quét ảnh AI đang chờ cấu hình dịch vụ.',
                ),
                const SizedBox(height: 20),
                if (controller.loading)
                  const LinearProgressIndicator()
                else if (controller.config?.enabled == false)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Premium chưa mở bán. HealthMate đang hoàn tất cấu hình Google Play.',
                      ),
                    ),
                  )
                else if (controller.product case final product?) ...[
                  Text(
                    '${product.price} / tháng',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Text(
                    'Đăng ký tự động gia hạn hàng tháng qua Google Play. Xem và xác nhận giá cuối cùng trên cửa sổ Google Play. Có thể hủy gia hạn trong Google Play; quyền dùng tiếp tục đến hết thời gian đã thanh toán.',
                  ),
                ],
                if (member != null &&
                    !membership.hasError &&
                    !membership.isLoading) ...[
                  if (member.environment == 'test')
                    const Chip(label: Text('GIAO DỊCH THỬ GOOGLE PLAY')),
                  Text(
                    '${active ? 'Có hiệu lực đến' : 'Hết quyền truy cập sau'}: ${DateFormat('dd/MM/yyyy HH:mm').format(member.expiresAt.toUtc().add(const Duration(hours: 7)))} (giờ Việt Nam)',
                  ),
                  Text(
                    member.autoRenewing
                        ? 'Đang bật tự động gia hạn.'
                        : 'Tự động gia hạn đã tắt hoặc gói không còn gia hạn.',
                  ),
                ],
                if (membership.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator(),
                  ),
                if (membership.hasError)
                  const Text(
                    'Chưa xác nhận được trạng thái gói. Kiểm tra mạng và tải lại; không cần mua lại.',
                  ),
                if (controller.message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(controller.message!),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const ValueKey('buy-play-premium'),
                  onPressed:
                      !active &&
                          !membership.isLoading &&
                          !membership.hasError &&
                          !controller.busy &&
                          !controller.loading &&
                          controller.product != null
                      ? controller.buy
                      : null,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(
                    controller.busy
                        ? 'Đang xử lý…'
                        : active
                        ? 'Gói còn hiệu lực'
                        : 'Đăng ký qua Google Play',
                  ),
                ),
                TextButton(
                  key: const ValueKey('restore-play-premium'),
                  onPressed: controller.canRestore ? controller.restore : null,
                  child: const Text('Khôi phục giao dịch'),
                ),
                TextButton(
                  onPressed: !controller.canReload
                      ? null
                      : () {
                          controller.reload();
                          ref.invalidate(verifiedMembershipProvider);
                        },
                  child: const Text('Tải lại'),
                ),
                TextButton(
                  onPressed: () async {
                    var opened = false;
                    try {
                      opened = await launchUrl(
                        Uri.https(
                          'play.google.com',
                          '/store/account/subscriptions',
                        ),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {
                      opened = false;
                    }
                    if (!opened && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Chưa mở được Google Play. Mở Play Store → Thanh toán và gói đăng ký.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Quản lý / hủy gia hạn trên Google Play'),
                ),
                const Divider(height: 32),
                const Text(
                  'Google Play xử lý thanh toán; HealthMate không thu thập thông tin thẻ. Chỉ giao dịch được máy chủ xác minh mới cấp Premium. Xóa tài khoản HealthMate không tự hủy gói đăng ký trên Google Play.',
                ),
              ],
            ),
          );
    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: SafeArea(child: content),
    );
  }
}
