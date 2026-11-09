# Báo lỗi & Góp ý — 07/11/2026

## 1. Giai đoạn và phạm vi

Giai đoạn 10 — hoàn tất gói cải thiện độ tin cậy và giao diện hỗ trợ trong
phạm vi local của lượt này. Chủ dự án yêu cầu làm phần khác sau báo cáo dưỡng
chất; nghiệm thu Android thật và ký phát hành đã được để lại cho sau.

## 2. Hành vi đã hoàn thành

- Form yêu cầu mới và ô trả lời hỏi trước khi bỏ nội dung đang soạn bằng nút
  quay lại trên giao diện hoặc Back hệ thống. Tiếp tục soạn giữ nội dung; form
  trống có thể thoát ngay. Chọn bỏ nội dung không gửi yêu cầu nào.
- Trong lúc chờ kết quả gửi, khóa gửi lặp, chỉnh nội dung và Back; vẫn có thể
  cuộn lịch sử. Có tiến trình và thông báo đang chờ xác nhận.
- Lỗi gửi giữ nguyên nội dung, loại yêu cầu và mã thao tác. Thử lại dùng cùng
  mã/payload để cơ chế transaction và xác nhận server sẵn có kiểm tra bản đã
  gửi, tránh tạo bản thứ hai khi kết quả lần đầu chưa rõ. Chỉ xóa nội dung/đóng
  form khi repository xác nhận thành công trong đúng phiên tài khoản.
- Ô trả lời nằm dưới vùng lịch sử riêng, không phải cuộn qua toàn bộ hội thoại
  để nhập. Khi ít chiều cao, vùng soạn có thể cuộn tới nút gửi.
- Luồng tin nhắn và trạng thái admin tiếp tục cập nhật từ stream sẵn có; cập
  nhật khi đang gõ không thay nội dung người dùng đang soạn.
- Tới giới hạn 100 tin nhắn, bản đang soạn được giữ ở chế độ chỉ đọc để sao
  chép, không gửi mới. Một thao tác đã gửi nhưng chưa rõ kết quả vẫn có thể
  thử lại cùng mã: repository kiểm tra tin nhắn đã tồn tại trước giới hạn.
- Đăng xuất/đổi UID loại bỏ route và bản soạn của tài khoản cũ. Kết quả gửi
  đến muộn không đóng form hoặc báo thành công cho phiên mở sau đó, kể cả
  chuyển A → B → A trong cùng lượt cập nhật UI.
- Phiên Auth loading/error hoặc chưa xác minh email không bắt đầu đọc hỗ trợ
  hoặc cho gửi. Lỗi Auth tạm thời ẩn nội dung riêng tư; khi cùng UID phục hồi,
  bản soạn còn được giữ trong bộ nhớ. Stream được hủy khi không còn dùng.

## 3. File chính

- `lib/features/support/presentation/support_screen.dart`
- `lib/features/support/presentation/support_draft_guard.dart` (mới)
- `lib/features/support/providers/support_providers.dart`
- `test/support_composer_reliability_test.dart` (mới, 21 test)
- `test/support_test.dart` (pump sau cuộn trong helper tap, giữ assertion cũ)
- `docs/implementation-progress.md`, `docs/test-report.md`, báo cáo này

## 4. Kiểm thử thật đã chạy

| Kiểm tra | Kết quả |
| --- | --- |
| `flutter test --no-pub --reporter expanded` | **1018/1018 qua**, baseline trước lượt này 997 |
| `flutter test --no-pub test/support_test.dart test/support_composer_reliability_test.dart --reporter expanded` | **34/34 qua**, chạy lại sau khi tăng kiểm tra Back và gửi khi bàn phím mở |
| `flutter analyze --no-pub` | Không issues |
| `dart analyze lib/features/support test/support_test.dart test/support_composer_reliability_test.dart` | Không issues sau sửa test cuối |
| `dart format --output=none --set-exit-if-changed` trên 5 file Dart của lượt này | 0 thay đổi |
| `git diff --check` | Qua |
| Render Inter bằng theme/AppCanvas thật | **2/2 qua**, đã xem ảnh sáng/tối và bàn phím giả lập |
| Helper Android: kiểm tra admin runtime | **7/7 qua** |
| `tool/build_android.ps1` | APK debug build thành công, `assembleDebug` 18,3 giây |

Nhóm mới kiểm tra Back bỏ/giữ bản soạn, chờ ACK/gửi lặp, lỗi chưa rõ kết quả
và retry cùng ID, 80 tin nhắn cùng phản hồi admin mới, giới hạn 100, kết quả
đến muộn sau đổi tài khoản, Auth error/phục hồi và tài khoản chưa xác minh.
Ma trận bố cục 320/390 px × chữ 100%/200% × sáng/tối có inset bàn phím 260 px;
cuộn và bấm gửi ngay trong khi inset còn hiện. Đây là widget tests với
repository/stream giả lập, không phải kiểm thử giao dịch backend production
hoặc bàn phím Android thật. Dữ liệu fixture chỉ có trong test/preview.

Lỗi trung gian đã sửa: fixture thiếu `emailVerified`, `pageBack()` của Flutter
chỉ tìm tooltip tiếng Anh trong test đang dùng tiếng Việt, helper cuộn cần
pump trước tap, và hai lint thiếu braces. Đổi finder sang `BackButton`, không
bỏ assertion để làm xanh test. Không thay source sản phẩm sau full suite;
sau đó tăng assertion Back trên AppBar và gửi khi bàn phím mở, chạy lại nhóm
34 test và scoped analyzer thành công.

Log local (thư mục build không được commit):

- `build/support-quality-full-tests.log`
- `build/support-quality-focused-final.log`
- `build/support-quality-analyze-final.log`
- `build/support-quality-scoped-analyze-final.log`
- `build/support-quality-preview-final.log`
- `build/support-quality-apk.log`

Preview có nhãn “DỮ LIỆU KIỂM THỬ”, dùng Inter đã đóng gói, lưu tại
`build/support-light-390-100-{thread,keyboard}.png` và
`build/support-dark-320-200-{thread,keyboard}.png`. Inset không vẽ bàn phím OS;
vùng trống bên dưới ảnh là chỗ dành cho bàn phím giả lập.

## 5. Artifact và cấu hình

- APK: `build/releases/healthmate-support-20261107-debug.apk`
- Manifest: `build/releases/healthmate-support-20261107-debug.json`
- Dung lượng: **237065431 byte**.
- SHA-256 đã kiểm tra khớp bản sao:
  `1AFE63076450A03BAB776A0CE2657063A15D505A55BF22A32545A0454EEB3DD5`
- Thời điểm build UTC: `2026-11-07T14:00:17.3734999Z`.
- Admin runtime được bật theo cấu hình hiện có; Premium demo tắt.
- Chạy helper với `ORG_GRADLE_PROJECT_kotlin.incremental=false` trong tiến
  trình build rồi phục hồi giá trị ban đầu. Bản APK riêng của lượt trước được
  giữ nguyên. Không commit/push trong lượt này.
- Không cần cấu hình dịch vụ mới cho thay đổi này.

## 6. Giới hạn và vấn đề còn lại

Bản soạn hỗ trợ chỉ nằm trong bộ nhớ màn hình: chưa có khôi phục sau process
death hoặc sau khi người dùng xác nhận bỏ. Không tuyên bố bảo đảm hoàn tất
gửi khi mất mạng kéo dài; khi Future chưa có kết quả thì UI vẫn chờ. Kết quả
chưa rõ được thử lại cùng mã khi Future kết thúc với lỗi.

Backend, Security Rules, schema, quota và cơ chế ACK giữ nguyên; không chạy
lại Rules suite hoặc gọi đây là kiểm toán bảo mật toàn hệ thống. Không thêm
package, bật billing hay deploy production. Tổng Auth tự động, worker xóa
nền và thanh toán Premium thật tiếp tục theo blocker trong báo cáo trước.

Build có cảnh báo tương thích KGP tương lai từ `firebase_ai`,
`firebase_app_check`, `firebase_auth`, `firebase_core`, `mobile_scanner`.
Build hiện tại thành công; chưa nâng package/Gradle ngoài phạm vi.

Nghiệm thu Android thật và ký phát hành tiếp tục được hoãn theo chỉ dẫn của
chủ dự án; lượt này không thực hiện hai việc đó.

## 7. Tiếp theo đề xuất

Giai đoạn 10 — rà soát trải nghiệm khi lỗi/mất mạng của Scanner và Chatbot.
Chỉ đề xuất, chưa triển khai trong lượt này.
