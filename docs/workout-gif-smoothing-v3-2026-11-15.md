# Giai đoạn tùy chọn 11 — GIF smoothing v3, 15/11/2026

## Yêu cầu và kết quả

Người dùng tiếp tục thấy răng cưa. Đã tăng độ mềm của alpha transition
từ Gaussian khoảng0,4 lên0,8 pixel nguồn, kết hợp inverse compositing để
loại phần màu trắng đã trộn ở đường bao. Không chỉ tăng blur trên RGB của
toàn nhân vật. Giữ resampling high cho RawImage native; light mode vẫn
dùng ảnh gốc. Phần nội thất đủ xa mép giữ màu/chi tiết, các pixel ở dải
mép có thể tối/mảnh hơn do tách màu nền trắng.

Đã xử lý thêm vòng đời bộ lọc web: revision3, SVG/style có ID ổn định,
thay node/định nghĩa cũ khi Dart state reset hoặc revision thay đổi,
khôi phục nếu stylesheet bị mất. Tránh tham chiếu lại filter ID cũ
còn tồn tại trong DOM sau hot restart. Đây là sửa từ phân tích mã và
kiểm DOM giả; chưa xác nhận đó là nguyên nhân trên Chrome của người dùng.

## File chính

- lib/features/activity/presentation/exercise_gif_background.dart
- lib/features/activity/presentation/exercise_gif_web_background.dart
- lib/features/activity/presentation/exercise_gif_preview.dart
- test/exercise_gif_background_test.dart
- docs/implementation-progress.md, docs/test-report.md và báo cáo này.

## Kiểm thử đã chạy

- dart format --output=none --set-exit-if-changed trên4 file Dart: qua,
  0 thay đổi ở lượt cuối.
- flutter test --no-pub với exercise_gif_background_test,
  exercise_gif_preview_test, exercise_inline_library_test,
  exercise_library_ui_test, workout_ux_test, workout_experience_test:
  **54/54 qua**, exit0.
- flutter analyze --no-pub: **No issues found**,126,4giây,exit0.
- dart compile js build/gif-smooth-20261115/web_background_check.dart:
  qua. Node chạy đúng mã Dart biên dịch với DOM trong bộ nhớ:
  **5/5** trạng thái tối/gọi lặp/sáng/tối lại/phục hồi stylesheet qua.
- flutter test --no-pub build/gif-smooth-20261115/native_render.dart:
  **1/1 qua**, GIF thật I4hDWkc gồm12frame; render frame0/6/11 bằng
  decoder + decodeImageFromPixels + Canvas Flutter, phóng2x với resampling
  high. Kiểm toàn bộ RGBA của3frame có premultiplied alpha hợp lệ.
- flutter build web --debug --target build/gif-smooth-20261115/main.dart
  --output build/gif-smooth-20261115/web --no-pub --no-web-resources-cdn
  --no-wasm-dry-run: exit0,59,6giây.

Ảnh review/log ở build/gif-smooth-20261115:

- tests-final.log, analyze.log, build.log, web-compile.log,
  web-dom-final.log, native-render-final.log, native-review.json.
- native-frame-0.png, native-frame-6.png, native-frame-11.png:
  frame thật qua renderer Flutter native, không phải Android vật lý.
- web-v3-offline.png: chính filter SVG lấy từ mã Dart biên dịch,
  render bằng sharp/librsvg, không phải screenshot Chrome.
- same-frame-comparison.png: cùng một frame thật, rasterizer offline,
  so sánh bộ lọc cũ và mới; không phải ảnh UI app.
- comparison.png: các phương án tham khảo trước khi chốt.

Nguồn GIF chỉ được đọc vào bộ nhớ để kiểm tra; không lưu GIF thành asset
hoặc cache trên đĩa. Các PNG là bằng chứng review, không được đóng gói
trong app. Không đọc/ghi Firebase hoặc dữ liệu tài khoản.

## Lỗi kiểm thử ban đầu và giới hạn

Test nội thất trước đó dùng hình7pixel bề ngang; mẫu màu gần mép rơi vào
vùng Gaussian rộng hơn. Đã mở rộng fixture để kiểm màu ở nội thất thực
sự, vẫn kiểm riêng dải mép và alpha. DOM harness ban đầu thiếu trường
currentScript/scripts mà Dart runtime cần; bổ sung harness rồi5/5 qua.
Render review đầu dùng testWidgets khiến Flutter thay HTTP bằng400;
chuyển harness sang test engine thuần, không bật widget binding, tải
GIF thật trong bộ nhớ rồi render thành công. Các log đầu được giữ lại.

Đã thử kiểm tra Chrome đang mở qua skill computer-use, nhưng công cụ dừng
vì không xác định được URL đủ tin cậy. Đã kết thúc phần CUA; không tiếp
tục điều khiển trình duyệt bằng công cụ khác. Kiểm mã/build và render
artifact offline vẫn thực hiện độc lập. Không khẳng định đã xác minh UI
trên trang Chrome của người dùng trong lượt này.

Đối chiếu lại tài liệu chính thức ngày15/11/2026:
https://docs.ascendapi.com/products/edb-v1/overview.md — miễn phí chỉ có
GIF180p;360p–1080p thuộc gói RapidAPI trả phí. Không đổi gói/nguồn hoặc
phát sinh chi phí. Bộ lọc làm mép mềm hơn, không thể phục hồi chi tiết
HD từ180p; khi phóng lớn vẫn có thể lộ điểm ảnh. Frame11 còn ghost pose
trong nguồn; không tuyên bố đã sửa hoặc nghiệm thu toàn bộ50GIF/frame.

## Cần người dùng làm và bước tiếp theo

Hot restart app, Chrome Ctrl+F5. Không cần cấu hình Firebase mới.
Chưa deploy web, cài APK, kiểm Android vật lý hoặc pushGit.
Bước đề xuất tiếp: đánh giá nguồn GIF độ phân giải cao nếu người dùng
muốn nâng chất lượng; chưa triển khai hoặc đăng ký dịch vụ trả phí.
