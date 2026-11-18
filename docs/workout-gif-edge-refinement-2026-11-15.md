# Giai đoạn tùy chọn 11 — Giảm viền trắng của GIF, 15/11/2026

## Yêu cầu và kết quả

Người dùng phản hồi GIF còn răng cưa/viền trắng quanh nhân vật sau khi
tách nền. Các pixel này được trộn sẵn với nền trắng trong GIF 180p;
chỉ xóa pixel gần trắng nối với mép ảnh chưa loại được quầng ở đường bao.

Giữ bước xác định nền, sau đó co alpha matte khoảng một pixel nguồn
và feather Gaussian khoảng 0,4 pixel. Chỉ xử lý matte; không làm mờ
RGB bên trong cơ thể. Native tính lại RGB premultiplied khi giảm alpha
để decoder Flutter không vẽ viền sáng từ RGB cũ. Ảnh không có nền trắng
được giữ nguyên. Web dùng SVG erode/blur/clip trên alpha của ảnh HTML
ExerciseDB; chế độ sáng vẫn dùng ảnh gốc.

Đã xem so sánh trực tiếp trên GIF thật giữa cách cũ, co/feather và giảm
pixel sáng ở dải mép. Chọn co/feather vì giảm quầng trắng rõ hơn trong
mẫu. Kiểm lại màn chi tiết/danh sách Flutter thật sau khi build.

Không đổi nguồn/URL, repository, dữ liệu, quyền, luồng tập, gate debug
phi thương mại; không thêm package, proxy, dịch vụ hoặc lưu GIF vào đĩa.

## File chính

- lib/features/activity/presentation/exercise_gif_background.dart
- lib/features/activity/presentation/exercise_gif_web_background.dart
- test/exercise_gif_background_test.dart
- docs/implementation-progress.md, docs/test-report.md và báo cáo này.

## Kiểm thử thực tế

```text
dart format --output=none --set-exit-if-changed <3 file Dart đã sửa>
flutter analyze --no-pub
flutter test --no-pub test/exercise_gif_background_test.dart test/exercise_gif_preview_test.dart test/exercise_inline_library_test.dart test/exercise_library_ui_test.dart test/workout_ux_test.dart test/workout_experience_test.dart
flutter build web --debug --target build/gif-fringe-20261115/main.dart --output build/gif-fringe-20261115/web --no-pub --no-web-resources-cdn --no-wasm-dry-run
```

- Format qua, 0 thay đổi ở lượt kiểm cuối.
- Analyze sạch: **No issues found**, exit 0, 17,6 giây.
- **54/54 test qua**, exit 0. Kiểm fringe/coverage, premultiplied RGB,
  giữ màu/vùng sáng bên trong, source buffer, không làm tối ảnh vốn
  translucent khi không có backdrop; hồi quy codec/theme/pause/lifecycle,
  bố cục và luồng tập qua.
- Build web debug exit 0, 47,3 giây.
- Chrome riêng, ảnh GIF thật: chi tiết tối 1 GIF hoàn tất, danh sách tối
  4, danh sách sáng 3; mỗi màn 0 JS exception. Trong ảnh sáng có một GIF
  chưa hoàn tất tại thời điểm chụp, không tính là đã nghiệm thu đủ 50 bài.

Log và bằng chứng trong build/gif-fringe-20261115:

- tests-final.log, analyze-final.log, build.log
- detail-dark.png, library-dark.png, library-light.png
- report-detail-dark.json, report-library-dark.json, report-library-light.json
- fringe-before-after.png: ghép hai crop screenshot Flutter trước/sau;
  hai thời điểm animation độc lập, không phải benchmark frame đồng bộ.
- prototype.png: so sánh kỹ thuật trên ảnh GIF thật, không phải màn app.

Harness dùng widget/theme/service sản phẩm; override danh mục bundled và
stream vận động rỗng để review độc lập, không có AppShell. Không khởi
tạo/đọc/ghi Firebase hoặc dùng dữ liệu tài khoản thật. Không dùng fixture
thay GIF trong các ảnh review. Không tải tệp GIF tạm về đĩa trong lượt này.

Test ban đầu 53/53 qua trước khi bổ sung xử lý premultiplied RGB; đã sửa
phần chuyển alpha, thêm kiểm ảnh translucent và chạy lại 54/54 qua.
Lượt analyze cuối thực hiện sau toàn bộ sửa mã Dart.

## Cần người dùng làm và giới hạn

Không cần cấu hình Firebase hoặc chi phí mới. Hot restart app Flutter;
với Chrome, tải lại trang bằng Ctrl+F5 để nhận bộ lọc mới. Chưa deploy
web, build/cài APK mới hoặc push Git.

Đây là giảm quầng và làm mềm đường bao, không tăng độ phân giải nguồn.
GIF 180p vẫn có thể thấy điểm ảnh khi phóng lớn; nét rất mảnh ở đường
bao có thể mảnh hơn sau co matte. Chưa kiểm từng frame của toàn bộ 50 GIF,
đo FPS/CPU hoặc nghiệm thu trên Android vật lý. Bước đề xuất tiếp:
nghiệm thu Android, chưa thực hiện.
