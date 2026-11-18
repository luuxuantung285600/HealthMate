# Thư viện 50 động tác và quản trị bài tập — 11/11/2026

## Phạm vi

Giai đoạn 6 bổ sung, theo yêu cầu hiện tại: 50 động tác phổ biến, minh họa GIF
ExerciseDB cho **kiểm thử miễn phí phi thương mại**, cùng chức năng quản lý bài
tập ở web admin và đồng bộ Firestore. Không thay đổi danh mục MET/công thức calo,
ba buổi tập hẹn giờ hiện có hoặc lịch sử hoạt động. Bản gốc chỉ kiểm thử local;
cập nhật UI và Rules mới nhất xem [báo cáo hiển thị GIF](workout-gif-ui-fix-2026-11-11.md).

## Hành vi

- App: Tập luyện mở thẳng thư viện, GIF hiển thị trên thẻ khi vào viewport;
  tìm không dấu, lọc nhóm cơ/dụng cụ, xem hướng dẫn tiếng Việt, cách giảm độ khó.
  Nút Buổi tập mở các buổi tập hẹn giờ hiện có.
- Admin: Bài tập luyện → thêm, sửa tên/nhóm/dụng cụ/hướng dẫn/mã ExerciseDB,
  gỡ bài khỏi thư viện, khôi phục, lọc và xuất danh mục hiện tại.
- “Xóa” lưu `isActive:false`, có thể khôi phục và giữ lịch sử người dùng.
  Không hard-delete document vì bản đi kèm app sẽ xuất hiện lại nếu mất override.
- Hai client ghép cùng bộ 50 nội dung biên soạn với override `exercise_library`
  theo document ID; override không hoạt động được áp dụng trước khi lọc.
  Thêm bài không bị giới hạn ở 50; đây là số bài ban đầu.
- Listener app tự hủy theo vòng đời provider/phiên UID. Màn chi tiết theo dõi
  chỉnh sửa hoặc gỡ bài đang mở. Mất mạng thì chưa thể nhận thay đổi mới.
  Lần mở đầu cần snapshot xác nhận từ server; cache chưa đầy đủ không được
  dùng để hiển thị lại bài đã gỡ. Sau 12 giây chưa xác nhận thì báo lỗi/thử lại;
  listener vẫn nhận lại dữ liệu khi mạng phục hồi. Sau khi có dữ liệu server,
  cache không hoàn chỉnh không ghi đè danh sách đã xác nhận trong phiên đó.
- Admin cần snapshot được máy chủ xác nhận trước khi cho ghi. Ghi bằng
  transaction kiểm tra phiên bản, kèm audit bất biến trong cùng thao tác;
  xung đột giữ bản nháp để kiểm tra lại. Chỉ quản trị viên đủ quyền được ghi.

## Media và giấy phép

Xem [báo cáo kiểm tra nguồn](exercisedb-source-verification-2026-11-11.md).
Đã đối chiếu 50/50 ID với API chính thức; HTTP 200, ID/tên động tác khớp và có
trường GIF. Không tải hàng loạt GIF hoặc sao chép hướng dẫn của nhà cung cấp.
JSON đóng gói chỉ có ID ổn định và nội dung tiếng Việt do HealthMate biên soạn.

App chỉ cho dùng nguồn GIF miễn phí ở **debug**; release/profile không mở API
này. Admin chỉ cho xem GIF ở localhost với emulator, hoặc khi cấu hình
`enableFreeExerciseMedia:true` cho kiểm thử local dùng Firebase thật. Cấu hình
và CSP release vẫn chặn tích hợp miễn phí này. Bản thương mại cần quyền/gói
phù hợp của nhà cung cấp trước khi đổi cấu hình triển khai.

Mỗi lần mở gọi fresh detail, xác minh đúng sourceId và đúng HTTPS CDN/path.
Không ghi media URL/GIF vào Firestore, assets hoặc bộ cache tự quản. Native giữ
byte trong RAM có giới hạn 8 MiB, quản lý codec/frame và tạm dừng được. Đóng,
đổi bài, chuyển nền/ẩn tab hủy request đang chạy, bỏ media và dispose tài nguyên.
Giảm chuyển động hiển thị frame tĩnh trước, người dùng có thể chủ động phát.
Web dùng HTML image để tránh hạn chế CORS của CanvasKit; dừng bằng cách gỡ ảnh.
Browser/CDN vẫn tuân theo cache HTTP của chính nền tảng.

API không nhận UID/hồ sơ/dữ liệu sức khỏe. Có timeout, backoff khi 429,
thông báo lỗi và thử lại theo yêu cầu; không tự gọi lặp. Nhà cung cấp có thể
thay đổi API/URL hoặc hạn mức. GIF miễn phí hiện ở 180p, không phải HD.

## Cách chạy kiểm thử

```powershell
flutter run
node admin-web/server.mjs
node tool/build_exercise_library.cjs --check
flutter test --no-pub test/exercise_db_test.dart test/exercise_gif_preview_test.dart test/exercise_library_ui_test.dart test/exercise_library_sync_test.dart
npm test --prefix admin-web
npm run check --prefix admin-web
```

Khi dùng emulator admin, làm theo `admin-web/README.md`; mặc định cổng Auth9098,
Firestore8092 và project `demo-healthmate-admin`. Không dùng project thật trong
bài kiểm thử rules. App và web phải trỏ **cùng project/emulator** để nhận thay đổi.

Quyền exercise_library đã bổ sung lên Firebase thật sau kiểm thử candidate ngày
11/11/2026; xem báo cáo hiển thị GIF ở trên. App đang chạy cần Hot Restart để
nhận UI mới. Web admin online chưa được phát hành code thư viện mới trong lượt
sửa UI này. Không cần bật Blaze, Cloud Functions hay mua RapidAPI để chạy bản
kiểm thử hiện tại; gate nguồn miễn phí chỉ ở debug vẫn giữ nguyên.

## File chính

- `data/workouts/exercise-library.json`, generator và hai catalog Dart/JS.
- `lib/features/activity/{models,data,providers,presentation}/exercise_*`.
- Router và điểm vào `workouts_screen.dart`.
- `admin-web/dist/{workouts-page,exercise-library-model,firebase,live-data}.mjs`.
- `firestore.rules`, rules tests, Flutter tests và admin DOM/model tests.

## Kết quả xác minh

Kết quả cuối được cập nhật trong `docs/test-report.md` sau khi kết thúc toàn bộ
lệnh. Đã mở một harness debug dùng widget thật trên web local và thấy GIF chống
đẩy thật từ ExerciseDB hiển thị bằng HTML image. Kiểm thử codec native dùng
fixture hai frame để kiểm tra chuyển động, pause và cleanup; đây không phải nghiệm
thu Android vật lý. Không khẳng định đã xem từng frame của cả 50 GIF.

Harness/log cục bộ ở `build/exercise-library-smoke/`; không đưa harness vào app
sản phẩm. Không thêm dependency. Chưa build/ký bản Android phát hành.

Giai đoạn tiếp đề xuất: nghiệm thu trên thiết bị khi người dùng yêu cầu; chưa làm.
