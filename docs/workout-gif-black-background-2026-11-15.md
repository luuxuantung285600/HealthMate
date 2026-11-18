# Giai đoạn tùy chọn 11 — Nền GIF tập luyện, 15/11/2026

## Phạm vi và hành vi

Người dùng yêu cầu đổi nền trắng xung quanh nhân vật thành đen. Nền trắng
nằm trong pixel GIF gốc nên cần xử lý ảnh, ngoài việc đổi màu khung.
Áp dụng trong chế độ tối; chế độ sáng vẫn dùng ảnh gốc/nền trắng theo
quy ước sáng/tối hiện tại của HealthMate. Renderer chung được dùng ở
thư viện, chi tiết và cover buổi tập.

Chỉ tách vùng gần trắng nối với mép ảnh, giữ vùng sáng được bao kín
bên trong cơ thể, màu cơ và dụng cụ có màu. Native xử lý từng frame
đang phát bằng flood fill, giữ frame gốc để đổi lại chế độ sáng và
dispose frame khi thay thế. Web dùng SVG mask trên ảnh HTML ExerciseDB
do CDN không cho đọc pixel cross-origin; quy tắc chỉ nhắm URL media
ExerciseDB và được gỡ khi chuyển sang sáng. Không đảo màu nhân vật.

Không đổi repository, Firestore, quyền, luồng tập, nguồn media, URL hoặc
gate giấy phép. Không thêm package, dịch vụ, proxy, chi phí hay asset GIF.
Không lưu GIF lâu dài vào đĩa; tệp source-sample.gif kiểm tra tạm đã xóa.

## File chính

- lib/features/activity/presentation/exercise_gif_preview.dart
- lib/features/activity/presentation/exercise_gif_background.dart (mới)
- lib/features/activity/presentation/exercise_gif_web_background.dart (mới)
- lib/features/activity/presentation/exercise_gif_web_background_stub.dart (mới)
- test/exercise_gif_background_test.dart (mới)
- test/exercise_gif_preview_test.dart
- docs/implementation-progress.md, docs/test-report.md và báo cáo này.

## Kiểm thử đã chạy

```text
dart format <các file Dart đã sửa>
flutter analyze --no-pub
flutter test --no-pub test/exercise_gif_background_test.dart test/exercise_gif_preview_test.dart test/exercise_inline_library_test.dart test/exercise_library_ui_test.dart test/workout_ux_test.dart test/workout_experience_test.dart
flutter build web --debug --target build/gif-black-background-20261115/main.dart --output build/gif-black-background-20261115/web --no-pub --no-web-resources-cdn --no-wasm-dry-run
```

- Format qua; analyze **No issues found**, 15,6 giây; **51/51 test qua**.
- Kiểm tách nền/chi tiết/màu/giữ buffer gốc và validation; codec thật
  đổi sáng → tối → sáng mà không tải lại. Hồi quy bố cục, phát/tạm dừng,
  lifecycle, thư viện và trải nghiệm tập qua.
- Build web debug thành công, exit 0, 53,6 giây.
- Chrome riêng tải GIF thật qua service hiện tại. Đã xem ảnh danh sách
  tối (4 GIF hoàn tất), danh sách sáng (4), chi tiết tối (1); mỗi màn
  0 JS exception. Nền tối đen, chế độ sáng trắng, nhân vật giữ màu cơ.

Harness dùng đúng widget/theme/service sản phẩm; chỉ override danh mục
bằng 50 entry bundled và vận động bằng stream rỗng để review độc lập.
Không khởi tạo/đọc/ghi Firebase; ảnh không phải dữ liệu tài khoản thật,
không chứa thanh điều hướng AppShell. Không dùng ảnh fixture thay GIF.

Log và ảnh trong build/gif-black-background-20261115:

- tests.log, analyze.log, build.log
- library-dark.png, library-light.png, detail-dark.png
- report-library-dark.json, report-library-light.json, report-detail-dark.json
- capture-actual.cjs và main.dart: harness/capture, không thuộc product assets.

Lượt đầu có hai lỗi lint dấu ngoặc và test chuyển theme trước khi animation
MaterialApp kết thúc. Đã sửa lint; test dùng themeAnimationDuration bằng 0
để kiểm đổi theme ở thời điểm xác định, chạy lại nhóm test/analyze qua.
Prototype đảo màu hoặc bỏ mọi pixel trắng làm mất chi tiết nhân vật đã
bị loại; chỉ thuật toán nối mép được dùng trong mã sản phẩm.

## Cấu hình và giới hạn

Không cần cấu hình Firebase hoặc trả phí mới. Cần hot restart app Flutter
đang chạy để nhận mã mới. Chưa deploy web, build/cài APK mới hoặc push Git.
GIF miễn phí giữ gate debug kiểm thử phi thương mại và cần Internet.

Chưa nghiệm thu Android vật lý hoặc đo hiệu năng FPS/CPU, đặc biệt khi có
nhiều GIF cùng hiển thị trên web. Nền xám/dụng cụ thật trong minh họa vẫn
được giữ. GIF 180p và các tư thế bóng mờ đã có trong nguồn không thay đổi.
Bước đề xuất tiếp: nghiệm thu trên Android; chưa thực hiện.
