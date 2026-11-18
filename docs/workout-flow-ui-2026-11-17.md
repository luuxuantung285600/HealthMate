# Luồng tập luyện — 17/11/2026

## Giai đoạn 11: hoàn thiện giao diện theo yêu cầu

Hoàn thành thiết kế lại phần trình bày của thư viện, buổi tập, chi tiết, hướng
dẫn động tác, màn đang tập và tổng kết. Mục tiêu là phân cấp rõ bằng hình ảnh,
chữ và khoảng cách, giảm các khung lồng nhau. Giữ nền đen thực ở chế độ tối,
nền trắng ở chế độ sáng, Public Sans và bộ icon hiện tại.

- Thư viện dùng lưới hai cột trên điện thoại đủ rộng, ba cột trên màn lớn;
  chuyển về danh sách khi màn nhỏ hoặc chữ lớn. GIF vẫn tải theo viewport.
  Tên dài trong lưới giới hạn ba dòng; trang chi tiết đọc được tên đầy đủ.
- Buổi tập dùng ảnh động bìa rộng, tên/nhóm/thời lượng tách rõ; nhật ký hôm
  nay vẫn lấy dữ liệu thật và có trạng thái tải/lỗi/trống.
- Chi tiết có dải thời lượng/số động tác/số vòng, chọn nhịp, phần chuẩn bị
  và danh sách theo số thứ tự. Bìa chọn đúng động tác có ánh xạ trong buổi,
  ghi rõ tên minh họa; không dùng GIF của động tác khác khi admin ẩn bài.
- Màn đang tập dùng số đếm lớn, chữ số cùng độ rộng, tiến trình buổi và GIF
  không bị bọc trong nhiều thẻ. Điều khiển tạm dừng/tiếp tục/kết thúc/bỏ qua
  nằm cố định phía dưới; hướng dẫn và đồng hồ vẫn có ngữ nghĩa trợ năng.
- Hướng dẫn từng bước, cách tập nhẹ hơn và tổng kết dùng cùng hệ chữ và
  đường phân cách. Nút bắt đầu/lưu chính có tương phản đen/trắng nhất quán.

Không đổi mô hình dữ liệu, truy vấn, công thức MET, nhịp tập, cơ chế tạm dừng
khi rời app, xác nhận lưu từ máy chủ hoặc ID dùng lại khi retry. Không thêm
dependency, thay nguồn GIF hoặc triển khai lên Firebase/GitHub.

## File chính

- `lib/features/activity/presentation/workout_ui.dart`: heading/metrics/steps,
  kiểu nút và hệ trình bày chung.
- `lib/features/activity/presentation/exercise_library_screen.dart`: lưới,
  danh sách thích nghi và chi tiết động tác.
- `lib/features/activity/presentation/workouts_screen.dart`: danh sách buổi,
  chi tiết và thứ tự động tác.
- `lib/features/activity/presentation/workout_session_screen.dart`: trình
  bày bộ đếm, điều khiển và tổng kết; giữ logic điều khiển/lưu hiện có.
- `lib/features/activity/presentation/exercise_gif_preview.dart` và
  `movement_media_preview.dart`: chế độ hiển thị GIF lớn, chiều cao theo
  ngữ cảnh; lỗi/không có GIF tự giãn theo cỡ chữ.
- `lib/features/activity/presentation/workout_tutorial_sheet.dart`.
- `test/workout_flow_design_test.dart`, `test/support/test_app.dart`:
  kiểm tra toàn danh mục ở nhiều kích thước và tùy chọn chụp bằng media thật.

## Kiểm tra thực tế

- Format chín file thay đổi: không còn khác biệt định dạng.
- `flutter analyze --no-pub`: **No issues found**.
- Mười suite: `workout_ux_test`, `workout_experience_test`,
  `workout_session_test`, `workout_tutorial_test`, `exercise_library_ui_test`,
  `exercise_inline_library_test`, `exercise_gif_preview_test`,
  `exercise_library_sync_test`, `activity_energy_ui_test`,
  `workout_flow_design_test`: **84 ca qua**, một ca chụp tùy chọn bỏ qua khi
  không bật `WORKOUT_CAPTURE`.
- Sau giới hạn tên dài, ba suite giao diện cuối: **20 ca qua**, một ca chụp
  tùy chọn bỏ qua. Kiểm tra danh mục 50 bài ở 360/390/430/900 px, cỡ chữ
  100–120%; suite có sẵn kiểm tra 320–900 px với cỡ chữ 200%, sáng/tối.
- Ca chụp bật riêng bằng `--dart-define=WORKOUT_CAPTURE=true`: đạt; xuất tám
  ảnh thư viện/buổi tập/chi tiết/player ở cả hai theme. Đây là widget thật,
  font/icon thật, GIF đúng source ID từ ExerciseDB; tài khoản và nhật ký là
  fixture kiểm thử, không đọc/ghi dữ liệu khách hàng Firebase.
- `flutter build web --no-pub --no-wasm-dry-run --output
  build/workout-flow-20261117/web`: build thành công.

Các lượt đầu phát hiện thông báo GIF tràn ở cỡ chữ 200%; đã sửa nội dung tự
giãn và chạy lại qua. Harness chụp được sửa để chờ giải mã ảnh thật thay vì
chờ mọi animation dừng; không sửa test để bỏ qua lỗi sản phẩm.

Log/ảnh ở `build/workout-flow-20261117/`. Bản ghép `workout-flow-preview.png`
chỉ ghép ba ảnh màn hình thật, không phải mockup được vẽ lại. GIF tải trong
thư mục build chỉ phục vụ kiểm thử; không đóng gói media này vào sản phẩm.

## Cần người dùng làm và giới hạn

Hot Restart phiên Flutter đang mở để xem đầy đủ thay đổi. Không có cấu hình
Firebase mới. Chưa nghiệm thu trên Android vật lý trong lượt này; PNG chỉ
thể hiện một khung hình của GIF. Giấy phép ExerciseDB miễn phí cho kiểm thử
phi thương mại và giới hạn Internet/API hiện có vẫn áp dụng; bản release
vẫn tắt nguồn media thử nghiệm theo cấu hình đã có.

Đề xuất tiếp: nghiệm thu bố cục trên thiết bị người dùng; chưa thực hiện.
