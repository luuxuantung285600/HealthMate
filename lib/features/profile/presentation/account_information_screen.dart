import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feature_page.dart';

enum AccountInformationPage { about, privacy, disclaimer }

/// Static policy is readable before authentication without changing the form's
/// route, controllers or authentication guards for private destinations.
Future<void> showPrivacyInformation(BuildContext context) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Quyền riêng tư'),
            leading: BackButton(onPressed: () => Navigator.of(context).pop()),
          ),
          body: const SafeArea(
            child: AccountInformationScreen(
              page: AccountInformationPage.privacy,
            ),
          ),
        ),
      ),
    );

class AccountInformationScreen extends StatelessWidget {
  const AccountInformationScreen({required this.page, super.key});

  final AccountInformationPage page;

  @override
  Widget build(BuildContext context) {
    final content = _content(page);
    return FeaturePage(
      title: content.title,
      subtitle: content.subtitle,
      children: [
        for (final section in content.sections) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(section.body),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        OutlinedButton.icon(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(AppRoutes.profile);
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Quay lại'),
        ),
      ],
    );
  }
}

({String title, String subtitle, List<_InformationSection> sections}) _content(
  AccountInformationPage page,
) => switch (page) {
  AccountInformationPage.about => (
    title: 'Giới thiệu HealthMate',
    subtitle:
        'Công cụ theo dõi thói quen sức khỏe dành cho đời sống hằng ngày.',
    sections: const [
      _InformationSection(
        'Mục đích',
        'HealthMate giúp bạn ghi nhận bữa ăn, nước uống, vận động và thay đổi thể trạng để nhìn lại thói quen của mình.',
      ),
      _InformationSection(
        'Độ tuổi sử dụng',
        'Bản MVP/demo HealthMate dành cho người từ 18 tuổi. Điều kiện AI được kiểm tra từ ngày sinh do bạn khai báo trong hồ sơ; đây không phải xác minh danh tính hoặc giấy tờ.',
      ),
      _InformationSection(
        'Cách sử dụng dữ liệu',
        'Các tổng hợp trong ứng dụng được tính từ dữ liệu bạn chủ động ghi nhận. Kết quả AI chỉ là gợi ý và luôn cần bạn kiểm tra trước khi lưu.',
      ),
    ],
  ),
  AccountInformationPage.privacy => (
    title: 'Quyền riêng tư',
    subtitle:
        'Thông tin bạn lưu được gắn với tài khoản Firebase của chính bạn.',
    sections: const [
      _InformationSection(
        'Dữ liệu tài khoản',
        'Email dùng để xác thực. Hồ sơ, thể trạng và nhật ký được lưu trong Cloud Firestore dưới UID của tài khoản; Security Rules giới hạn quyền đọc và sửa cho chủ tài khoản.',
      ),
      _InformationSection(
        'Dữ liệu trên thiết bị',
        'Lựa chọn giao diện được lưu cục bộ. Firebase SDK có thể giữ bộ nhớ đệm nhật ký để xem khi offline; đăng xuất không đồng nghĩa xóa bộ nhớ đệm này. Bản Android tắt sao lưu dữ liệu ứng dụng lên bản sao lưu hệ điều hành. Chỉ xóa dữ liệu ứng dụng trong Cài đặt Android sau khi các thay đổi cần giữ đã đồng bộ.',
      ),
      _InformationSection(
        'Tính năng AI',
        'Khi bạn xác nhận rồi bấm Phân tích, ảnh được gửi đến dịch vụ AI của Google. Dịch vụ miễn phí có thể dùng ảnh/kết quả để cải thiện sản phẩm và cho người đánh giá xem. Chỉ chọn ảnh món ăn không có thông tin cá nhân. HealthMate không tải ảnh gốc lên kho lưu trữ; camera/thư viện có thể giữ tệp tạm trên thiết bị. Chỉ kết quả bạn xác nhận mới được lưu vào nhật ký.',
      ),
      _InformationSection(
        'Hội thoại',
        'Câu hỏi và câu trả lời được lưu riêng theo tài khoản trong Cloud Firestore. Tra cứu nhật ký được tính tại ứng dụng, không gửi nhật ký, hồ sơ, nội dung tự nhập hoặc lịch sử hội thoại đến AI. Khi bạn chọn một chủ đề kiến thức chung, chỉ câu hỏi định sẵn được gửi đến dịch vụ AI của Google. Dịch vụ miễn phí có thể dùng câu hỏi/câu trả lời để cải thiện sản phẩm, có thể có người đánh giá nội dung. Mỗi chủ đề là một yêu cầu độc lập. Xóa tài khoản sẽ xóa cả hội thoại HealthMate; việc này không xóa dữ liệu đã được dịch vụ AI xử lý trước đó.',
      ),
      _InformationSection(
        'Xóa dữ liệu',
        'Bạn có thể yêu cầu xóa tại Cá nhân hoặc màn tài khoản bị khóa. Trạng thái xóa chặn ghi mới trước khi dọn hồ sơ, nhật ký, hội thoại, góp ý và dữ liệu Premium mô phỏng. Bản hiện tại cần giữ ứng dụng mở và có mạng để hoàn tất; khi gián đoạn, đăng nhập lại để tiếp tục. Nếu xóa đăng nhập thất bại, tài khoản vẫn ở trạng thái chờ xóa, không mở lại quyền sử dụng.',
      ),
      _InformationSection(
        'Dữ liệu còn giữ sau yêu cầu xóa',
        'HealthMate giữ UID, thời điểm và tiến độ xóa để ngăn token hoặc ghi offline tạo lại dữ liệu. Không tự xóa metadata này trong bản demo. Nhật ký quản trị bất biến và quyền quản trị được giữ, giới hạn truy cập quản trị; nội dung danh mục dùng chung có thể vẫn tồn tại. Cần quản trị viên xử lý phần này theo chính sách lưu giữ. Không coi giao dịch Premium mô phỏng là chứng từ tài chính bắt buộc giữ. Ảnh thư viện, tệp đã xuất, dữ liệu dịch vụ AI đã xử lý và cache của thiết bị khác không được bảo đảm xóa từ máy này.',
      ),
      _InformationSection(
        'Báo lỗi và góp ý',
        'Chỉ nội dung bạn chủ động gửi tại Báo lỗi & Góp ý, mã tài khoản và thời điểm trao đổi được cung cấp cho admin để hỗ trợ. Admin không được truy cập nhật ký sức khỏe qua tính năng này. Không gửi mật khẩu, thông tin ngân hàng hoặc hồ sơ sức khỏe nhạy cảm. Yêu cầu và phản hồi được xóa cùng dữ liệu HealthMate khi bạn xóa tài khoản trong ứng dụng.',
      ),
    ],
  ),
  AccountInformationPage.disclaimer => (
    title: 'Lưu ý sức khỏe',
    subtitle:
        'HealthMate hỗ trợ theo dõi thói quen và không cung cấp chẩn đoán y khoa.',
    sections: const [
      _InformationSection(
        'Thông tin tham khảo',
        'BMI, dinh dưỡng ước tính, gợi ý AI và các nội dung trong ứng dụng chỉ có tính tham khảo. Chúng không thay thế bác sĩ, chuyên gia dinh dưỡng hoặc nhân viên y tế.',
      ),
      _InformationSection(
        'Tình huống khẩn cấp',
        'Nếu bạn có triệu chứng nghiêm trọng hoặc cần trợ giúp khẩn cấp, hãy liên hệ cơ sở y tế hoặc dịch vụ khẩn cấp tại nơi bạn đang ở.',
      ),
      _InformationSection(
        'Quyết định sức khỏe',
        'Không tự thay đổi thuốc, điều trị hoặc chế độ ăn đặc biệt chỉ dựa trên dữ liệu hay gợi ý của HealthMate.',
      ),
    ],
  ),
};

class _InformationSection {
  const _InformationSection(this.title, this.body);

  final String title;
  final String body;
}
