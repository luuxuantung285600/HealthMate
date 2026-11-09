# 08/11/2026 — Giai đoạn 10: cải thiện hồ sơ người dùng

## Phạm vi và trạng thái

Theo yêu cầu “cải thiện lại các tính năng ở hồ sơ người dùng”, hoàn thiện các
luồng hồ sơ, tài khoản và lịch sử cân nặng hiện có trong giai đoạn 10. Không
thêm dịch vụ, dependency, schema, collection, index hoặc quyền mới. Source
local; không deploy hay ghi dữ liệu production trong lượt này.

## Người dùng giờ làm được

- Dùng lối tắt Hồ sơ / Cân nặng / Tài khoản để đến đúng phần trong trang dài.
  Nút cài đặt vẫn đến phần tài khoản, giữ anchor qua các lần rebuild. Thông
  tin cá nhân được đặt trước mục Premium.
- Sửa tên, chiều cao, ngày sinh và mục tiêu với hướng dẫn đơn vị/giới hạn.
  Mở form không làm tròn chiều cao, cân nặng mục tiêu hoặc lần cân đã lưu;
  sửa một ghi chú/tên không âm thầm làm thay đổi các con số khác. Ngày sinh
  hiển thị đủ ngày/tháng/năm, thay nhãn ngày trước đây thiếu năm.
- Chọn cả ngày và giờ đo. Ngày/giờ nhập và lịch sử dùng múi giờ thiết bị;
  timestamp vẫn lưu qua repository hiện có. Sửa riêng cân nặng/ghi chú hoặc
  xác nhận lại cùng giờ/phút giữ nguyên instant cũ, kể cả giây/microsecond.
  Không cho lưu thời điểm tương lai; không tự lùi giờ mà người dùng không biết.
  Date picker mở được với lần đo cũ trước năm 2000 hoặc dữ liệu tương lai cần sửa.
- Xem đầy đủ ngày/tháng/năm và giờ trong lịch sử, xác định được nhiều lần cân
  cùng ngày. Giá trị chi tiết giữ độ chính xác đã lưu; BMI vẫn làm tròn một
  chữ số để trình bày chỉ số tham khảo. BMI ghi rõ lần cân và chiều cao dùng
  tính, lấy lần mới nhất độc lập với trang lịch sử đang mở.
- Thêm/sửa lần cân khi đang xem trang cũ sẽ trở về trang mới nhất. Trang cũ
  rỗng sau khi xóa có lời dẫn quay về “Mới hơn”, không báo sai rằng toàn bộ
  tài khoản chưa có lịch sử.
- Xem rõ lần cân, thời điểm và ghi chú trước khi xóa. Hộp xóa chờ repository
  xác nhận; chặn gửi lặp, giữ lại khi lỗi và cho thử lại. Chỉ báo thành công
  sau xác nhận. Đăng xuất trong lúc chờ đóng hộp thao tác và không hiển thị
  kết quả vào phiên khác.
- Thấy trạng thái xác minh email và cách đăng nhập thực tế. Người dùng chỉ
  đăng nhập Google được giải thích nơi quản lý mật khẩu; nút đổi mật khẩu
  chỉ xuất hiện khi tài khoản có provider mật khẩu.
- Khi dữ liệu hồ sơ đang tải lại/lỗi, không dùng bản cũ để mở form chỉnh sửa
  hoặc hiển thị mục tiêu như đang được xác nhận. Lỗi nguồn lần cân mới nhất
  có nút thử lại riêng cho BMI. Chặn thao tác lịch sử chồng khi đang ghi.
- Lịch sử dùng nút Sửa/Xóa có chữ, xuống dòng được ở màn nhỏ/chữ lớn. Tiêu đề
  và nút Thêm tách hàng khi cần. Nhãn trục biểu đồ giữ trong vùng vẽ để không
  bị cắt ở đầu trục. Giữ font Inter và theme hiện có.

## File chính

- `lib/features/profile/presentation/profile_screen.dart`
- `lib/features/profile/presentation/personal_overview.dart`
- `lib/features/profile/presentation/profile_form_dialog.dart`
- `lib/features/profile/presentation/body_metric_form_dialog.dart`
- `lib/features/profile/presentation/delete_body_metric_dialog.dart` (mới)
- `lib/features/profile/presentation/profile_number_input.dart` (mới)
- `lib/features/profile/presentation/weight_chart.dart`
- `test/profile_quality_test.dart` (mới)
- Báo cáo này, `docs/implementation-progress.md`, `docs/test-report.md`.

Giữ nguyên những thay đổi chưa commit của các lượt trước. Repository/provider
và Security Rules không cần đổi cho các hành vi trên; UI tiếp tục sử dụng
CRUD và listeners Firestore hiện có, không thêm truy vấn.

## Kiểm thử đã chạy

| Kiểm tra | Kết quả |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib/features/profile test/profile_quality_test.dart` | Qua; 23 file, 0 thay đổi cuối |
| `flutter test --no-pub --reporter expanded` | 1.052/1.052, 0 skip, 102 giây |
| Sáu file hồi quy profile/history/form/UX + preview sau chỉnh cuối | 84/84 (82 ca hồi quy và 2 harness preview), 0 skip |
| `flutter analyze --no-pub` | No issues found, 35,8 giây |
| Preview Inter thật: 390px/sáng/100%, 320px/tối/200% | 2/2 harness, đã render/xem tổng quan, lịch sử và form |
| `tool/build_android.ps1` | Runtime cấu hình 7/7; APK debug build qua, Gradle 17,6 giây |
| `node tool/audit_source_secrets.cjs` | 694 source text files, 0 findings; không quét APK/credential store |
| `git diff --check` | Qua |

12 ca mới bao phủ độ chính xác, sửa riêng tên/ghi chú, ngày tương lai/ngày cũ,
chọn giờ, xóa chờ/lỗi/thử lại, đăng xuất khi xóa, lối tắt sau rebuild, phân
trang rỗng và tài khoản Google. Bộ UX hiện có kiểm 320/390/412px, chữ
100/150/200%, sáng/tối cho chart và truy cập thao tác hồ sơ.

Sau bộ Flutter đầy đủ có chỉnh trình bày số và nhãn trục; chạy lại các ca
profile/biểu đồ và preview liên quan sau chỉnh cuối. Không sửa assertions
nghiệp vụ hoặc bỏ test để che lỗi. Fixture chỉ dùng trong test; ảnh preview
gắn nhãn kiểm thử, không ghi dữ liệu mẫu vào sản phẩm.

Log local: `build/profile-quality-*.log`; preview:
`build/profile-quality-{overview,weight,editor}-{light-390-100,dark-320-200}.png`.
Các file build/preview ignored. Không chạy lại Rules/Google Play/web admin
vì đợt này không sửa các phần đó.

APK: `build/releases/healthmate-profile-quality-20261108-debug.apk`,
237.511.636 byte, build lúc 21:36 ngày 08/11 (UTC+7).
SHA-256: `7A99FC5F6C662F2E29B7DD24D529F724869E63F7D294A2FCCE44D735A21C2724`.
Manifest cùng tên `.json` giữ hash/cấu hình build. Billing/demo vẫn mặc định
tắt. Build còn cảnh báo Kotlin Gradle Plugin từ các plugin hiện có; build
vẫn thành công, không tự nâng package ngoài phạm vi.

## Cần người dùng làm và giới hạn

- Chạy lại app hoặc cài APK debug mới để thử. Không cần cấu hình Firebase mới
  cho các thay đổi hồ sơ này. Không cập nhật bản app trên thiết bị từ xa.
- Nghiệm thu Android thật và ký phát hành vẫn để sau theo yêu cầu. Kiểm thử
  widget/build không thay thế thử bàn phím, back gesture và kết nối trên máy thật.
- Giao diện tiếp tục dùng repository Firestore hiện có; lượt này không tạo
  bằng chứng kết nối Firebase production mới hoặc đo độ trễ realtime thực tế.
  Khi offline, ghi vẫn chờ máy chủ; không tự timeout để gửi lại bản ghi đang chờ.
- Giữ điều kiện tuổi và quy tắc nghiệp vụ hiện hành. BMI chỉ tham khảo, không
  thêm phân loại/chẩn đoán sức khỏe hoặc tự thay mục tiêu dinh dưỡng đã lưu.
- Bản nháp được giữ trong form đến khi lưu/bỏ thay đổi; không thêm lưu bản
  nháp hồ sơ dài hạn qua lần đóng ứng dụng.

## Bước tiếp theo đề xuất

Nghiệm thu hồ sơ trên Android thật khi người dùng sẵn sàng. Chỉ đề xuất,
không tự chuyển sang giai đoạn phát hành hoặc mở rộng nghiệp vụ.
