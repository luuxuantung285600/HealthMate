import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_feature_visuals.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/home_palette.dart';
import '../../../core/widgets/feature_icon_badge.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../profile/presentation/account_information_screen.dart';
import '../models/play_billing_models.dart';
import '../providers/play_billing_controller.dart';
import '../providers/play_billing_providers.dart';

class PlayPremiumScreen extends ConsumerStatefulWidget {
  const PlayPremiumScreen({super.key});

  @override
  ConsumerState<PlayPremiumScreen> createState() => _PlayPremiumScreenState();
}

class _PlayPremiumScreenState extends ConsumerState<PlayPremiumScreen> {
  bool _openingManagement = false;

  Future<void> _manage(PlayBillingConfig? config) async {
    if (_openingManagement) return;
    setState(() => _openingManagement = true);
    var opened = false;
    try {
      opened = await ref.read(openPlaySubscriptionsProvider)(
        (config ?? const PlayBillingConfig(enabled: false)).managementUri,
      );
    } catch (_) {
      opened = false;
    }
    if (!mounted) return;
    setState(() => _openingManagement = false);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa mở được Google Play. Mở Play Store → Thanh toán và gói đăng ký.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(playBillingControllerProvider);
    final membership = ref.watch(verifiedMembershipProvider);
    final now = ref.watch(localClockProvider);
    return Theme(
      data: HomePalette.of(context),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Premium')),
          body: SafeArea(
            child: controller == null
                ? _content(context, null, membership, now)
                : ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) =>
                        _content(context, controller, membership, now),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    PlayBillingController? controller,
    AsyncValue<VerifiedMembership?> membership,
    DateTime now,
  ) {
    final confirmed = !membership.hasError && !membership.isLoading;
    final member = confirmed ? membership.value : null;
    final active = member?.activeAt(now) == true;
    final owned = member?.blocksNewPurchaseAt(now) == true;
    final unavailable =
        controller == null || controller.config?.enabled == false;
    final product = controller?.product;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: FeatureIconBadge(AppFeatureVisual.premium, size: 64),
        ),
        const SizedBox(height: 20),
        Text(
          active ? 'Premium đang hoạt động' : 'HealthMate Premium',
          style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        const Text(
          'Thêm không gian trò chuyện với AI để đồng hành cùng thói quen của bạn.',
        ),
        const SizedBox(height: 20),
        const _FeatureLine(
          icon: AppIcons.chatbot,
          text: 'Chat AI tối đa 50 lượt mỗi ngày, theo hạn mức máy chủ.',
        ),
        const _FeatureLine(
          icon: AppIcons.shieldCheck,
          text: 'Nhật ký và theo dõi cơ bản vẫn miễn phí.',
        ),
        const SizedBox(height: 8),
        const Text('Quét ảnh AI đang chờ cấu hình dịch vụ.'),
        const SizedBox(height: 20),
        if (controller?.loading == true)
          const LinearProgressIndicator(
            semanticsLabel: 'Đang tải gói Google Play',
          ),
        if (unavailable)
          _PremiumNotice(
            icon: AppIcons.info,
            title: 'Đang chuẩn bị mở bán',
            body: controller == null && ref.watch(playBillingEnabledProvider)
                ? 'Thanh toán Premium hỗ trợ trên Android qua Google Play. Hãy đăng nhập và xác minh email.'
                : 'Premium chưa mở bán. HealthMate đang hoàn tất cấu hình Google Play.',
          )
        else if (product != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gói hàng tháng', style: text.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '${product.price} / tháng',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Đăng ký tự động gia hạn hàng tháng qua Google Play. Xem và xác nhận giá cuối cùng trên cửa sổ Google Play. Có thể hủy gia hạn trong Google Play; quyền dùng tiếp tục đến hết thời gian đã thanh toán.',
                  ),
                ],
              ),
            ),
          ),
        if (member != null) ...[
          const SizedBox(height: 12),
          _PremiumNotice(
            key: const ValueKey('verified-premium-status'),
            icon: active ? AppIcons.circleCheck : AppIcons.clock3,
            title: _membershipTitle(member, active),
            body:
                '${active ? 'Có hiệu lực đến' : 'Thời hạn ghi nhận'}: ${DateFormat('dd/MM/yyyy HH:mm').format(member.expiresAt.toUtc().add(const Duration(hours: 7)))} (giờ Việt Nam)\n'
                '${member.autoRenewing ? 'Đang bật tự động gia hạn.' : 'Tự động gia hạn đã tắt hoặc gói không còn gia hạn.'}'
                '${member.status == 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD' || member.status == 'SUBSCRIPTION_STATE_ON_HOLD' ? '\nHãy cập nhật phương thức thanh toán trong Google Play.' : ''}',
          ),
          if (member.environment == 'test')
            const Align(
              alignment: Alignment.centerLeft,
              child: Chip(label: Text('GIAO DỊCH THỬ GOOGLE PLAY')),
            ),
        ],
        if (membership.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(
              semanticsLabel: 'Đang kiểm tra quyền Premium',
            ),
          ),
        if (membership.hasError) ...[
          const _PremiumNotice(
            icon: AppIcons.cloudAlert,
            title: 'Chưa xác nhận được trạng thái gói',
            body: 'Kiểm tra mạng và tải lại; không cần mua lại.',
          ),
          TextButton.icon(
            key: const ValueKey('retry-premium-membership'),
            onPressed: () => ref.invalidate(verifiedMembershipProvider),
            icon: const Icon(AppIcons.refreshCw),
            label: const Text('Kiểm tra lại trạng thái'),
          ),
        ],
        if (controller?.message case final message?) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: _PremiumNotice(
              key: const ValueKey('play-purchase-progress'),
              icon: controller!.needsRecovery
                  ? AppIcons.circleAlert
                  : AppIcons.info,
              title: controller.verifying
                  ? 'Đang xác minh giao dịch'
                  : controller.pending
                  ? 'Thanh toán đang chờ'
                  : controller.needsRecovery
                  ? 'Khôi phục để tiếp tục'
                  : controller.awaitingActivation
                  ? 'Đang cập nhật quyền Premium'
                  : 'Trạng thái thanh toán',
              body: message,
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const ValueKey('buy-play-premium'),
          onPressed: confirmed && !owned && controller?.canBuy == true
              ? controller!.buy
              : null,
          icon: const Icon(AppIcons.shoppingBag),
          label: Text(
            active
                ? 'Gói còn hiệu lực'
                : owned
                ? 'Quản lý gói hiện tại'
                : controller?.needsRecovery == true
                ? 'Cần khôi phục giao dịch'
                : controller?.awaitingActivation == true
                ? 'Đang cập nhật quyền…'
                : controller?.busy == true
                ? 'Đang xử lý…'
                : unavailable
                ? 'Chưa mở bán'
                : 'Đăng ký qua Google Play',
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('restore-play-premium'),
          onPressed: controller?.canRestore == true
              ? () => controller!.restore()
              : null,
          icon: const Icon(AppIcons.refreshCw),
          label: Text(
            controller?.restoring == true
                ? 'Đang khôi phục…'
                : 'Khôi phục giao dịch',
          ),
        ),
        if (controller != null)
          TextButton(
            key: const ValueKey('reload-play-products'),
            onPressed: controller.canReload
                ? () {
                    controller.reload();
                    ref.invalidate(verifiedMembershipProvider);
                  }
                : null,
            child: const Text('Tải lại'),
          ),
        const SizedBox(height: 8),
        const Text(
          'Gói đăng ký gắn với tài khoản HealthMate đang dùng. Khi cài lại app, đăng nhập đúng tài khoản và chọn Khôi phục giao dịch.',
        ),
        const Divider(height: 32),
        TextButton.icon(
          key: const ValueKey('manage-play-subscription'),
          onPressed: _openingManagement
              ? null
              : () => _manage(controller?.config),
          icon: const Icon(AppIcons.externalLink),
          label: const Text('Quản lý / hủy gia hạn trên Google Play'),
        ),
        TextButton.icon(
          key: const ValueKey('premium-privacy'),
          onPressed: () => showPrivacyInformation(context),
          icon: const Icon(AppIcons.shieldCheck),
          label: const Text('Quyền riêng tư'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Google Play xử lý thanh toán; HealthMate không thu thập thông tin thẻ. Chỉ giao dịch được máy chủ xác minh mới cấp Premium. Xóa tài khoản HealthMate không tự hủy gói đăng ký trên Google Play.',
        ),
      ],
    );
  }
}

String _membershipTitle(VerifiedMembership member, bool active) {
  if (active) {
    if (member.status == 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD') {
      return 'Cần cập nhật thanh toán gia hạn';
    }
    return member.autoRenewing
        ? 'Quyền Premium đã được xác nhận'
        : 'Đã tắt gia hạn, vẫn dùng đến hết hạn';
  }
  return switch (member.status) {
    'SUBSCRIPTION_STATE_ON_HOLD' => 'Gói tạm ngưng do thanh toán',
    'SUBSCRIPTION_STATE_PAUSED' => 'Gói đăng ký đang tạm dừng',
    'SUBSCRIPTION_STATE_PENDING' => 'Thanh toán đang chờ Google Play',
    _ => 'Gói Premium đã hết hiệu lực',
  };
}

class _PremiumNotice extends StatelessWidget {
  const _PremiumNotice({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });
  final IconData icon;
  final String title, body;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body),
        ],
      ),
    ),
  );
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
