import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/providers/local_clock_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/premium_models.dart';
import '../providers/premium_providers.dart';
import 'play_premium_screen.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});
  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _busy = false;
  String? _transactionId;
  String? _transactionUid;
  String? _error;

  Future<void> _buy() async {
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null || _busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mua gói mô phỏng?'),
        content: const Text(
          'Premium 20.000đ / 30 ngày. Đây là giao dịch demo, không thu tiền và không tự gia hạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận demo'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busy) return;
    if (ref.read(authSessionProvider).value?.uid != uid) return;
    final repository = ref.read(premiumRepositoryProvider);
    if (_transactionUid != uid) {
      _transactionId = null;
      _transactionUid = uid;
    }
    _transactionId ??= repository.newTransactionId();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.purchaseDemo(uid, _transactionId!);
      if (!mounted || ref.read(authSessionProvider).value?.uid != uid) return;
      _transactionId = null;
      ref.invalidate(premiumMembershipProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã kích hoạt Premium demo. Không có khoản tiền nào bị thu.',
          ),
        ),
      );
    } catch (error) {
      if (mounted && ref.read(authSessionProvider).value?.uid == uid) {
        setState(
          () => _error = error is PremiumFailure
              ? error.message
              : 'Chưa hoàn tất giao dịch demo. Hãy thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(premiumDemoEnabledProvider)) {
      return const PlayPremiumScreen();
    }
    final membership = ref.watch(premiumMembershipProvider);
    final usage = ref.watch(premiumUsageProvider);
    final now = ref.watch(localClockProvider);
    final active = membership.value?.activeAt(now) == true;
    final ready =
        !membership.isLoading &&
        !membership.hasError &&
        !usage.isLoading &&
        !usage.hasError;
    return Scaffold(
      appBar: AppBar(title: const Text('HealthMate Premium')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Chip(label: Text('BẢN DEMO · KHÔNG THU TIỀN')),
            Text(
              active ? 'Premium đang hoạt động' : 'Thêm lượt AI mỗi ngày',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              '20.000đ / 30 ngày',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const Text(
              'Không tự gia hạn. Nhật ký và theo dõi cơ bản vẫn miễn phí.',
            ),
            if (membership.value case final value?)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '${active ? 'Có hiệu lực đến' : 'Gói đã hết hạn'}: ${DateFormat('dd/MM/yyyy HH:mm').format(value.expiresAt.toUtc().add(const Duration(hours: 7)))} (giờ Việt Nam)',
                ),
              ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hạn mức mỗi ngày',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    const Text('Quét ảnh AI: đang chờ cấu hình dịch vụ'),
                    const SizedBox(height: 8),
                    const Text(
                      'Chat AI: dịch vụ xác nhận hạn mức. Gói demo chỉ tăng lượt khi dịch vụ đã bật hỗ trợ.',
                    ),
                    const SizedBox(height: 12),
                    if (ready) ...[
                      Text(
                        'Dịch vụ đã ghi nhận ${usage.value!.chats} lượt chat hôm nay',
                      ),
                    ] else if (membership.isLoading || usage.isLoading)
                      const LinearProgressIndicator(),
                  ],
                ),
              ),
            ),
            if (membership.hasError || usage.hasError) ...[
              const Text(
                'Chưa tải được gói và số lượt. Kiểm tra mạng hoặc cấu hình Premium demo.',
                style: TextStyle(color: Colors.red),
              ),
              TextButton(
                onPressed: () {
                  ref.invalidate(premiumMembershipProvider);
                  ref.invalidate(premiumUsageProvider);
                },
                child: const Text('Tải lại'),
              ),
            ],
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('purchase-premium-demo'),
              onPressed: ready && !active && !_busy ? _buy : null,
              child: Text(
                _busy
                    ? 'Đang xác nhận…'
                    : active
                    ? 'Gói còn hạn'
                    : 'Mua gói demo · 20.000đ',
              ),
            ),
            const SizedBox(height: 16),
            const ExpansionTile(
              title: Text('Cách tính lượt'),
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Một lượt chat dùng cùng mã yêu cầu cho bước lập kế hoạch và trả lời. Gửi lại cùng mã không trừ thêm lượt và không tự gọi AI lần nữa nếu kết quả chưa rõ. Yêu cầu đã gửi có thể vẫn tính khi lỗi hoặc bạn dừng. Đặt lại lúc 00:00 giờ Việt Nam. Quét mã vạch và tra cứu nhật ký không dùng lượt AI.',
                  ),
                ),
              ],
            ),
            const ExpansionTile(
              title: Text('Dữ liệu giao dịch demo'),
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'HealthMate lưu mã tài khoản, gói, thời hạn và số tiền mô phỏng để admin tổng hợp báo cáo. Không thu thập thẻ hay tài khoản ngân hàng. Luồng xóa tài khoản dọn giao dịch demo và hạn mức; mã tài khoản/trạng thái xóa và audit quản trị vẫn được giữ.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
