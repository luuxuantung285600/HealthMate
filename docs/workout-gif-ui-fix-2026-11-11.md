# GIF trên danh sách tập luyện và bỏ xanh mint — 11/11/2026

## Phạm vi và kết quả

Bảo trì giao diện tập luyện theo yêu cầu hiện tại, bổ sung của Giai đoạn 6.
Người dùng xác nhận muốn GIF hiện ngay trong danh sách, không chỉ trong màn
chi tiết. Đã hoàn thành mã nguồn, kiểm thử local và bổ sung Rules cho thư viện.
Không thay công thức calo, danh mục MET, timer, xác nhận kết quả hoặc lịch sử.

## Nguyên nhân

- Màu primary chung vẫn xanh mint. Ảnh nút thêm món cũ còn dùng phiên app trước
  khi Hot Restart; bỏ mint khỏi primary để các màn khác cũng không nhận màu này.
- Tab Tập luyện vẫn ưu tiên ba buổi tập cũ và thumbnail video người thật. Bộ
  50 bài ExerciseDB nằm ở route thư viện riêng; danh sách thư viện chỉ có chữ.
- Rules production chưa có collection `exercise_library`. Query xác nhận
  override từ admin bị từ chối dù danh mục đi kèm app đã có 50 bài.

## Hành vi mới

- Primary trắng/xám trung tính; nút dinh dưỡng cam. Bỏ mint khỏi các màu mục
  tiêu, vận động, bước chân, bữa phụ và đạm; bữa phụ hồng, vận động vàng nhạt,
  đạm san hô. Nền tối giữ đen, nền sáng giữ trắng.
- Tab Tập luyện mở thẳng thư viện 50 bài. Nút **Buổi tập** mở các buổi tập
  hẹn giờ hiện có; trong đó vẫn có đường quay lại thư viện.
- Mỗi thẻ có khung GIF 150 px ngay trên danh sách, tự tải khi thẻ xuất hiện,
  có phát/dừng/thử lại. Danh sách dùng SliverList.builder, scrollCacheExtent 0;
  không khởi tạo 50 request khi mở màn hình. Kích thước loading/error cố định
  để không gây xây hàng loạt card trước khi ảnh tải xong. Nguồn ghi ở header.
- Chọn tên bài mở hướng dẫn và GIF trong chi tiết. Mỗi preview có request owner
  riêng: bỏ một thẻ khỏi viewport không hủy request của thẻ bên cạnh. Rời tab,
  chuyển nền hoặc dispose thì bỏ media và hủy request đúng owner. Trở lại thẻ
  inline đã ẩn thì tải một lần; rebuild bình thường không gọi thêm.
- Hai biến thể khớp chính xác trong buổi tập cũ dùng GIF từ thư viện đã ghép
  override admin: chống đẩy tường và nâng hông trên sàn. Không gán GIF gần giống
  cho các động tác khác. Thumbnail người thật bị bỏ khỏi card; video cũ chỉ
  còn dạng tùy chọn trong hướng dẫn của bài chưa có mapping chính xác.
- Admin đổi sourceId/ẩn bài vẫn được phản ánh bởi provider. Key gồm ID/sourceId
  để không giữ GIF cũ sau chỉnh sửa; lỗi quyền/mạng không bị che bằng fallback.

## Nguồn và giới hạn

Nguồn là **ExerciseDB / AscendAPI**, theo lựa chọn kiểm thử miễn phí trước đây;
không phải media GymVisual có phí. Giữ gate debug, bản miễn phí phi thương mại,
180p, cần Internet. Không tải cả bộ vào assets hoặc Firestore, không thêm gói.
Mỗi lần xem lấy fresh metadata theo ID, kiểm CDN/path, chặn request sau 429 theo
Retry-After; không tự retry vòng lặp. Hạn mức của nhà cung cấp vẫn có thể làm
một số ảnh tạm chưa tải được khi cuộn nhanh qua nhiều bài.

Kiểm tra mạng trong lượt này: `I4hDWkc` trả HTTP 200, ID đúng, tên `push-up`,
API CORS `*`; GIF trả HTTP 200, image/gif, chữ ký GIF89a, 87.535 byte. Chỉ đọc
trong RAM, không lưu GIF vào repository. Không khẳng định đã xem cả 50 GIF.

## Rules đã phát hành

- Chỉ ghép block exercise_library và thêm entityType tương ứng vào audit
  allowlist từ mã nguồn vào đúng bản Rules đang chạy. Không deploy toàn bộ
  Rules local hoặc các thay đổi nghiệp vụ khác đang có trong working tree.
- Đọc: tài khoản đã xác minh và được phép hoạt động. Ghi: admin hợp lệ, schema
  có giới hạn và audit cùng transaction. Từ chối hard delete và lưu URL GIF.
- 18 ca emulator trên candidate đã qua trước deploy, gồm truy cập bị chặn,
  audit giả, dữ liệu sai và client người dùng nhận tạo/sửa/ẩn/khôi phục realtime.
- Deploy chỉ firestore:rules exit 0; đọc lại production khớp hash candidate:
  `d9eb3358046aa11719d799abbc8ff95f5e37e795d05c5fc2a05d387695f576c3`.
- Ruleset: `projects/healthmate-app-20261013/rulesets/4182be7f-4e92-4b3d-b0c3-9944b201dbef`.
  Không ghi dữ liệu kiểm thử production, không deploy Hosting hoặc push Git.
  Artifacts/rollback baseline: `build/workout-gif-ui-20261111/`.

## File chính

- `lib/core/theme/{app_theme,reference_palette,app_feature_visuals,app_meal_visuals,design_tokens}.dart`,
  `lib/core/widgets/app_shell.dart`, `home_nutrient_panels.dart`.
- `lib/features/activity/data/exercise_db_service.dart`;
  `providers/workout_exercise_provider.dart`.
- Activity presentation: workouts_screen, exercise_library_screen,
  exercise_gif_preview, movement_media_preview, workout_tutorial_sheet,
  workout_session_screen.
- Tests: exercise_db_test, exercise_gif_preview_test, exercise_library_ui_test,
  exercise_inline_library_test, workout_experience_test, workout_tutorial_test
  và support/test_app.

## Kiểm thử cuối

- Format các file sửa qua; diff-check qua (Git có cảnh báo LF/CRLF hiện có).
- `flutter analyze --no-pub` toàn repo: **No issues found**, exit 0, 15,6 giây.
- 10 suite Flutter: **89/89 qua**, exit 0, 14 giây: exercise_db_test,
  exercise_gif_preview_test, exercise_library_ui_test, exercise_library_sync_test,
  exercise_inline_library_test, workout_experience_test, workout_tutorial_test,
  home_reference_test, journal_timeline_test, icon_system_test.
- **18/18 Rules** trên candidate với Firestore emulator: exit 0, 11,9 giây.
  Lần đầu emulator không chạy do Java hệ thống cũ; dùng JBR 21 của Android Studio
  riêng cho tiến trình, không thay cài đặt hệ thống.
- Đợt combined Flutter đầu có 15 timeout do widget test chung chưa mock nguồn
  GIF tự tải. Đã bổ sung service disabled cho các test không kiểm media; test
  media riêng dùng fixture codec. Rerun toàn bộ 10 suite đã qua. Analyze đầu
  có unused variable/deprecation/const/import, đã sửa và chạy lại sạch.
- Kiểm concurrency: hủy GIF A không hủy GIF B; kiểm inline fixed frame, pause,
  hidden/return, lazy request count nhỏ hơn 5 khi mở danh sách 50 bài, scroll,
  đổi nguồn/ẩn bài và timer/lịch sử. Không sửa production để che lỗi test.
- Logs: analyze.log, final-tests-rerun.log, rules-tests.log, rules-deploy.log
  trong `build/workout-gif-ui-20261111/`.

## Cần người dùng làm / giới hạn nghiệm thu

Đã yêu cầu Hot Restart qua VS Code trước bản inline cuối; ảnh người dùng gửi
xác nhận thư viện mới đã mở nhưng lúc đó danh sách còn chỉ chữ. Sau đó người
dùng bấm Esc dừng Computer Use: đã dừng mọi điều khiển UI, không Hot Restart
bản inline cuối. Người dùng bấm **Ctrl+Shift+F5 trong VS Code** để nhận bản mới,
rồi mở Tập luyện. Không cần sửa config Firebase.

Chrome connector không có sẵn trong lượt này. Chưa quan sát GIF thật trên
Chrome sau bản inline cuối, chưa nghiệm thu Android vật lý/build release.
Ảnh `build/exercise-inline/list-dark-test-fixture.png` dùng GIF màu 3 px để
kiểm layout/codec, không phải hình động tác thật và không dùng làm bằng chứng
đã xem media ExerciseDB trên app đang chạy.

Đề xuất tiếp: nghiệm thu bản inline trên phiên app của người dùng; không tự
mở giai đoạn khác. Web admin online chưa được cập nhật code thư viện mới trong
lượt này; việc deploy Rules không tương đương phát hành UI admin.
