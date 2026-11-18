# Giai đoạn tùy chọn 11 — UX/UI Tập luyện, 15/11/2026

## Phạm vi và tham khảo

Người dùng yêu cầu cải thiện UX/UI phần tập luyện theo các app hướng dẫn tập.
Chỉ sửa presentation của thư viện, buổi tập và chi tiết; giữ repository,
Firestore, đồng hồ và luồng xác nhận/lưu vận động hiện có. Không thêm package,
đổi kiến trúc, phát hành, billing hoặc dữ liệu tài khoản.

Đã đọc trang và xem ảnh giao diện chính thức:

- [Nike Training Club](https://www.nike.com/ntc-app): các tab điều hướng rõ,
  thẻ xem trước có tiêu đề và thông tin buổi tập dễ quét.
- [Seven](https://seven.app/): ưu tiên động tác đang tập và nhịp thời gian.
  [Ảnh chính thức](https://cms.perigee.se/uploads/seven_screenshot_workout_e893ad4176.png).

Áp dụng cách tổ chức vào tính năng thật của HealthMate; dùng font Public Sans,
bộ icon Phosphor và GIF ExerciseDB hiện có. Không lấy hình/nhãn hiệu của hai
app tham khảo làm asset sản phẩm. Các bản HTML/ảnh tham khảo ở build/ chỉ để
review, không được khai báo trong assets.

## Hành vi sau thay đổi

- Hai tab “Thư viện động tác” và “Buổi tập” ngay dưới tiêu đề. Thư viện vẫn
  mở mặc định. Từ khóa và bộ lọc thư viện được giữ khi chuyển sang buổi tập.
- Tìm kiếm, hàng nhóm cơ vuốt ngang và nút lọc dụng cụ riêng. Bảng lọc có
  trạng thái nháp: chỉ Áp dụng mới đổi kết quả; đóng bảng không áp dụng nháp.
  Có xóa từ khóa, xóa tất cả bộ lọc và giải thích khi không có kết quả.
- Thẻ ngang có GIF cạnh tên bài, vùng cơ thể, dụng cụ và hành động xem hướng
  dẫn. Nút phát/tạm dừng trên ảnh có tooltip; không tải toàn bộ 50 GIF khi mở.
  Màn nhỏ hoặc chữ lớn chuyển thẻ sang bố cục dọc.
- Chi tiết có GIF lớn, nhãn dụng cụ/nhóm cơ, các bước đánh số, biến thể nhẹ
  hơn và lưu ý tập an toàn. Nội dung vẫn nhận sửa/ẩn từ stream thư viện.
- Buổi tập có thẻ xem trước, số động tác và thời lượng tính bằng
  WorkoutPace.totalDuration. Cover dùng đúng một động tác đã ghép GIF trong
  buổi đó, tôn trọng trạng thái ẩn từ admin; không ghép một biến thể khác.
- Màn chi tiết buổi tập có tiêu đề và nút Bắt đầu màu san hô, lựa chọn nhịp,
  khâu chuẩn bị và danh sách động tác rõ hơn. Giữ luồng hẹn giờ/tạm dừng,
  xác nhận kết thúc và chỉ lưu số phút vận động thực đã hoàn thành.
- Nền đen trong dark mode, nền trắng trong light mode; điểm nhấn san hô.
  Thông tin nguồn/GIF kiểm thử và an toàn vẫn xem được qua nút thông tin.

## File chính

- lib/features/activity/presentation/exercise_library_screen.dart
- lib/features/activity/presentation/exercise_gif_preview.dart
- lib/features/activity/presentation/workouts_screen.dart
- lib/features/activity/presentation/workout_ui.dart (mới)
- test/workout_ux_test.dart (mới), exercise_library_ui_test.dart,
  exercise_gif_preview_test.dart, workout_experience_test.dart
- docs/implementation-progress.md, docs/test-report.md và báo cáo này.

## Kiểm thử thật

- dart format trên bốn file presentation và bốn file test đã sửa: qua.
- flutter analyze --no-pub: **No issues found**, exit 0.
- flutter test --no-pub trên 9 suite: **88/88 qua**, exit 0.
  Bao gồm lọc kết hợp, hủy nháp, reset, đổi tab giữ tìm kiếm, nguồn/an toàn,
  cover đúng variant và nhận ẩn, pause thumbnail giữ frame; layout sáng/tối
  320/430/900 px ở chữ 200%. Hồi quy owner/lifecycle GIF, lazy load, đồng bộ
  thư viện, lỗi mạng và session/timer/xác nhận/lưu nhật ký cũng qua.
- Build web debug harness dùng đúng widget/theme/service sản phẩm: exit 0,
  76,8 giây; --no-wasm-dry-run, không thay scanner.

Đã chụp và xem 5 màn Flutter thật: thư viện tối/sáng, chi tiết động tác,
bảng lọc và buổi tập. Ảnh ở build/workout-ui-20261115: library-dark.png,
library-light.png, detail-dark.png, filters-dark.png, sessions-dark.png.
Các case hoàn tất ghi nhận 0 JS exception. Kiểm riêng buổi tập tải 3 GIF
hoàn tất, metadata và media HTTP 200; kiểm lại thư viện riêng cũng qua.
Chứng cứ tổng hợp: visual-review-report.json, capture-sessions-report.json,
capture-report.json, capture*.log. Không dùng ảnh test fixture làm minh họa.

Lệnh/log và harness nằm ở build/workout-ui-20261115. Harness chỉ override
thư viện bằng 50 bản ghi bundled và nhật ký vận động bằng stream rỗng phục
vụ review độc lập. Service GIF thật không bị override. Không khởi tạo
Firebase, đọc tài khoản hoặc ghi dữ liệu; đây không phải tài khoản production.
Ảnh preview là màn feature độc lập, không chứa thanh điều hướng AppShell.

Lượt đầu phát hiện import sai, tràn ngang nhãn ở chữ lớn, header bảng lọc
bị dồn cột, và assertion test còn dùng câu chữ cũ. Đã sửa code/expectation
đúng hành vi rồi chạy lại. Capture đầu của buổi tập chờ GIF bị timeout do
chọn động tác chưa có mapping; đã sửa cover chọn variant được xác minh,
bổ sung kiểm thử và build lại. Các log vòng đầu được giữ trong build/.

Lượt capture nhiều màn sau đó và một lượt lặp lại đầu thư viện vẫn có
timeout tải GIF. Khi kiểm riêng thư viện/buổi tập, nguồn lại tải thành công;
curl kiểm metadata cũng HTTP 200. Chưa xác định chính xác nguyên nhân lỗi
kết nối ngắt quãng, không khẳng định nguồn đã ổn định hoàn toàn. App vẫn có
trạng thái chưa tải được/nút thử lại và hướng dẫn chữ. Lượt có timeout không
được tính là bộ capture 6/6 thành công. Không sửa service hoặc dùng ảnh giả
để che lỗi trong lượt polish này.

## Cấu hình, giới hạn và bước tiếp theo

Không cần cấu hình Firebase hoặc trả phí mới. App đang chạy bản cũ cần hot
restart để nhận code mới. GIF ExerciseDB miễn phí vẫn chỉ bật ở bản debug
kiểm thử phi thương mại, cần Internet; bản release giữ gate hiện có.
Chưa nghiệm thu Android vật lý, build/ký APK mới hoặc deploy app/web trong
lượt này. Bước đề xuất: nghiệm thu luồng tập trên Android; chưa thực hiện.
