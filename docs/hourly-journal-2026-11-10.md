# Nhật ký theo giờ — 10/11/2026

## Phạm vi

Giai đoạn 4 bổ sung: đổi cách trình bày nhật ký dinh dưỡng theo ảnh tham khảo
Wao. Không đổi database, Firestore Rules, dữ liệu dinh dưỡng hoặc cấu trúc
snapshot bữa ăn; không thêm package hay dịch vụ.

## Hành vi

- Món ghi lúc 09:30 tự thuộc khung **09:00–09:59**; vẫn hiển thị 09:30.
  Các bản ghi cùng giờ xếp theo thời điểm ăn, không theo nhãn sáng/trưa/tối.
- Nút + ở mỗi giờ mở bộ chọn món với ngày và giờ tương ứng. Với giờ hiện
  tại, giữ phút hiện tại; với giờ đã qua, bắt đầu ở HH:00. Không cho ghi
  thời điểm trong tương lai, theo validation sẵn có.
- Có đủ 24 giờ. Các giờ 00:00–06:59 thu gọn khi trống và tự hiện khi có món,
  kể cả món vừa đến qua stream dữ liệu. Các giờ 07:00–23:59 hiện trực tiếp.
- Mỗi món hiển thị tên, ảnh nếu có, khẩu phần, kcal và các macro đã biết.
  Món thiếu ảnh giữ nội dung chữ; macro chưa biết không bị đổi thành 0.
  Ảnh dùng registry/provider hiện có, bao gồm cập nhật ảnh/ẩn ảnh từ admin.
- Tổng theo giờ và tổng ngày tính từ snapshot nhật ký. Sửa giờ tự chuyển
  bản ghi sang khung mới, không nhân đôi món; xóa có xác nhận và cập nhật tổng.
- Giữ sửa/nhân bản/xóa cả bữa. Chạm một thẻ món mở bữa chứa món đó để sửa;
  không xóa riêng từng snapshot bằng thao tác ngầm.
- Dữ liệu cũ giữ nguyên timestamp, dateKey, loại bữa và snapshot. Phân giờ
  dùng offset múi giờ đã lưu; dữ liệu cũ thiếu offset dùng giờ địa phương.
- Tổng quan có bốn thanh kcal/đạm/carb/chất béo, giữ mục tiêu đúng ngày và
  bảng chi tiết dinh dưỡng. Có trạng thái tải/lỗi/thiếu mục tiêu độc lập.
- Chế độ tối dùng nền đen, chế độ sáng dùng nền trắng, font Inter hiện có.
  Màn hình nhỏ/chữ lớn tự xuống dòng để tránh cắt tên và số dinh dưỡng.

## File chính

- `lib/features/journal/models/meal_timeline.dart`
- `lib/features/journal/presentation/hourly_meal_timeline.dart`
- `lib/features/journal/presentation/journal_screen.dart`
- `lib/features/journal/presentation/journal_nutrition_overview.dart`
- `lib/features/journal/providers/journal_date_provider.dart`
- `lib/features/nutrition/presentation/meal_log_section.dart`
- `test/journal_timeline_test.dart` và các test nhật ký liên quan.
- Hai kịch bản integration cập nhật nút thêm theo UI mới; tiếp tục kiểm tra
  thời điểm/loại bữa suy ra từ giờ khi dùng món gần đây/công thức/bữa mẫu.

## Kiểm thử và bản chạy

- Test tập trung nhật ký/cốt lõi/dinh dưỡng: **51/51 qua**.
- Test cuối về timeline và luồng camera/chọn món: **14/14 qua**, bao gồm
  cập nhật stream đưa món vào giờ khuya khi phần giờ trống đang thu gọn.
- Lượt test toàn bộ đầu có 1 lỗi: kịch bản camera chạm nút thêm ngoài màn
  hình khi chữ 200%. Kịch bản nay cuộn tới nút bằng helper sẵn có, giữ nguyên
  các kiểm tra quyền camera/vòng đời/tab; không bỏ assertion hoặc giấu lỗi.
- Đã sửa lỗi Material ancestor khi thử nghiệm nền mới, căn thanh tiến độ
  theo hàng và sửa các kỳ vọng giao diện cũ về nhóm loại bữa/thẻ gộp.
- Bổ sung kiểm thử món cũ thiếu offset cùng món mới có offset: thứ tự theo
  phút hiển thị, tránh so sánh nhầm UTC với giờ địa phương. Tổng cộng có
  **9 test mới** cho timeline.
- `dart format --output=none --set-exit-if-changed` trên16 file Dart:
  0 thay đổi, exit0.
- `flutter analyze`: No issues found, exit0,121,1 giây.
- `flutter test --reporter expanded`: **1.261/1.261 qua**, exit0,2 phút59
  giây. Log: `build/journal-hourly-verified-final.log`.
- APK debug build qua, exit0,Gradle60,5 giây;
  `build/releases/healthmate-hourly-journal-20261110-debug.apk`,
  238.290.841 byte. SHA256:
  `27671cc07d489d2a05047a3612a5b7f02968d2cad71987bd2ff1aaad94637894`.
- Web JavaScript build qua, exit0,79,1 giây, output `build/web`;
  log `build/journal-hourly-web.log`. Cảnh báo Wasm dry run của
  mobile_scanner và KGP khi build Android là giới hạn plugin hiện hữu.
- `git diff --check`: exit0, chỉ cảnh báo LF/CRLF hiện hữu.

Kết quả kiểm tra toàn bộ cuối/build được ghi trong `test-report.md` và
`implementation-progress.md`. Ảnh kiểm tra sáng/tối, 390px/chữ100% và
320px/chữ200% nằm ở `build/journal-timeline/`; dữ liệu trong ảnh là fixture
kiểm thử, không được chèn vào sản phẩm hoặc Firebase thật.

## Cấu hình và giới hạn

Không cần bật billing hoặc cấu hình Firebase mới. Cần cập nhật/chạy lại app
để thấy giao diện mới. Trong lượt này chưa nghiệm thu trên Android vật lý,
chưa chạy integration với emulator Firebase và chưa ký bản phát hành.

Đề xuất tiếp theo: nghiệm thu nhật ký theo giờ trên thiết bị thật khi được
yêu cầu; chưa triển khai trong lượt này.
