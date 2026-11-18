# Tiến độ: so sánh tuần và xuất đúng khoảng ngày — 16/11/2026

## Giai đoạn và trạng thái

Giai đoạn 8 bảo trì, hoàn thành mã nguồn và kiểm thử local. Theo yêu cầu làm
phần khác, bổ sung khả năng đối chiếu tiến độ với tuần trước và sửa sự lệch
khoảng ngày giữa màn hình báo cáo và hộp thoại xuất. Chưa mở giai đoạn tiếp theo.

## Hành vi người dùng

- Vào **Tiến độ → Tuần → Tổng quan → So sánh với tuần trước** để xem năng
  lượng đã ghi, cân nặng, nước và phút vận động. Mục so sánh mặc định thu gọn.
- Tuần hiện tại chỉ đối chiếu từ thứ Hai đến hôm nay với cùng các thứ của
  tuần trước. Tuần lịch sử dùng đủ bảy ngày; ngày tương lai không tham gia.
- Mỗi chỉ số ghi riêng số ngày có dữ liệu ở hai tuần. Trung bình chỉ tính
  những cặp cùng thứ có dữ liệu ở cả hai phía. Ngày chưa ghi không được đổi
  thành 0; giá trị 0 có nhật ký vẫn là một quan sát hợp lệ.
- Nếu không có cặp ngày, hiện chưa đủ dữ liệu và không tạo số chênh lệch.
  Cân nhiều lần trong một ngày được lấy trung bình ngày trước khi so sánh.
- Có nhắc hôm nay/tuần đang diễn ra, nhật ký ăn có thể chưa đủ cả ngày và
  chênh lệch không phải kết luận tốt hơn/xấu hơn hoặc kết luận sức khỏe.
- Nút xuất điền đúng tuần/khoảng 30 hoặc 90 ngày/năm/khoảng tùy chọn đang
  xem. Tuần hiện tại xuất đến hôm nay, không lấy các ngày tương lai.
- Đổi tuần trong chi tiết rồi trở về biểu đồ giữ cùng tuần. Rời tab Tiến độ
  rồi quay lại giữ khoảng 30/90 ngày; ngày xuất và nội dung tiếp tục khớp.

## Dữ liệu và vòng đời

Chỉ tổng hợp từ các repository hiện có. `weeklyLogsProvider` được chia sẻ
giữa tổng quan và so sánh cho tuần hiện tại. Chỉ mở thêm dữ liệu tuần trước
khi mục so sánh được mở, không truy vấn riêng từng ngày. Dùng cơ chế cập nhật
dữ liệu theo UID và phạm vi hiện có; hủy consumer khi thu gọn/rời màn hình.
Không thêm collection, field Firestore, rules, dependency hoặc dịch vụ mới.

Lỗi tải không trở thành số 0. Thử lại chỉ làm mới tuần đang lỗi, giữ kết quả
tuần tải thành công. Chuyển tuần khi request cũ chưa hoàn tất không đưa kết
quả cũ vào tuần mới. Đăng xuất không tiếp tục hiện dữ liệu so sánh của UID cũ.

## File chính

- `lib/features/progress/models/week_comparison.dart`: ghép ngày, độ phủ,
  trung bình theo cặp và cân nặng trung bình ngày.
- `lib/features/progress/presentation/week_comparison_card.dart`: thu gọn,
  tải/lỗi/thử lại, dữ liệu thiếu, số liệu và giải thích tiếng Việt.
- `lib/features/progress/presentation/progress_screen.dart`: đặt thẻ so sánh,
  chọn khoảng xuất và giữ trạng thái khoảng ngày.
- `lib/features/weekly_reflection/presentation/weekly_reflection_card.dart`:
  đồng bộ điều hướng tuần với màn cha.
- `lib/features/reports/presentation/period_report_panel.dart`: khôi phục
  offset ban đầu và thông báo khi chuyển khoảng cho màn cha.
- `test/week_comparison_test.dart`, `test/progress_comparison_ui_test.dart`:
  kiểm thử tính toán, truy vấn, điều hướng, xuất và bố cục.

## Kiểm thử thực tế

Lượt cuối trên mã nguồn đã hoàn thiện:

```text
dart format --output=none --set-exit-if-changed <7 file Dart thay đổi>
Formatted 7 files (0 changed).

flutter analyze --no-pub
No issues found! (20,2 giây, exit 0)

flutter test --no-pub test/week_comparison_test.dart test/progress_comparison_ui_test.dart test/progress_test.dart test/weekly_reflection_test.dart test/year_reports_test.dart test/h5_period_report_test.dart test/report_export_quality_test.dart
88/88 tests passed (23 giây, exit 0)

git diff --check -- <vùng mã nguồn thay đổi>
exit 0
```

Các ca mới gồm tuần vắt năm, tuần chưa kết thúc, số 0 đã ghi, ngày thiếu,
không có cặp ngày, cân nhiều lần/ngày, ID trùng, dateKey, ngày tương lai,
chia sẻ request hiện tại, chỉ đọc tuần trước khi mở, lỗi và thử lại, chuyển
tuần nhanh, đăng xuất khi đang tải, xuất tuần cũ/chi tiết, khoảng 30/90 ngày,
giữ khoảng khi đổi tab, năm cũ và giao diện sáng/tối ở 320px với chữ 2x.
Các suite có sẵn kiểm thêm báo cáo năm/nhuận, tùy chọn, export, quyền theo UID
ở tầng provider/repository giả lập và layout Progress tới 412px/chữ 2x.

Đã xem ảnh render sáng/tối ở 390px, không thấy tràn chữ. Ảnh dùng fixture kiểm
thử, không phải số liệu người dùng hoặc bản chụp từ app đang chạy production.

Log cuối: `build/progress-comparison-analyze-final.log`,
`build/progress-comparison-final-tests.log`. Ảnh tại
`build/progress-comparison-20261116/{light,dark}-comparison.png`.

Lượt đầu analyze phát hiện các dấu `!` dư và thiếu ngoặc khối, đã sửa và chạy
lại sạch. Ca bổ sung rời tab phát hiện panel trở về khoảng hiện tại trong khi
header còn giữ khoảng cũ; đã bổ sung khôi phục offset và chạy lại qua. Không
sửa assertion để bỏ kiểm tra hành vi này. Một lần harness dùng nhầm key
`nav-home` đã được sửa sang key thực `nav-dashboard` trước khi tái hiện lỗi.

## Cần người dùng làm và giới hạn

- Hot Restart app đang chạy để nhận mã mới; không cần cấu hình Firebase mới.
- Mở Tiến độ, chọn Tuần/Tổng quan rồi mở mục so sánh. Cần nhật ký ở cùng thứ
  của cả hai tuần để thấy chênh lệch cho từng chỉ số.
- Chưa nghiệm thu Android vật lý hoặc phiên Firebase production trong lượt
  này; kiểm thử dùng repository giả lập. Không build/ký bản phát hành.
- Chưa push Git/deploy Hosting/Functions/Rules và không ghi dữ liệu kiểm thử
  lên production trong phạm vi này.
- Chỉ so sánh dữ liệu người dùng đã ghi; không suy ra lượng ăn/nước/vận động
  thực tế trong những thời điểm chưa có nhật ký. Không có blocker đã biết cho
  phạm vi mã nguồn đã kiểm thử.

Giai đoạn kế tiếp đề xuất: Giai đoạn 10 — nghiệm thu luồng Tiến độ và xuất
báo cáo trên môi trường người dùng. Chỉ đề xuất, chưa thực hiện.
