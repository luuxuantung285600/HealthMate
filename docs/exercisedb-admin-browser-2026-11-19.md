# Giai đoạn 11 — Duyệt ExerciseDB và thêm bài tập từ admin

## Hoàn thành

Admin mở **Bài tập luyện → Thêm từ ExerciseDB**, tìm tên, lọc vùng cơ thể
và dụng cụ từ danh mục đầy đủ của nguồn. Mỗi trang tối đa 25 bài, có trước/
sau bằng cursor. Đây là kho nguồn trực tiếp, không phải chỉ 60 bài bundled.
Lần kiểm tra ngày 19/11/2026 trả về **1.500 bài, 10 nhóm và 30 dụng cụ**.

Chọn **Xem GIF và hướng dẫn** để tải đúng GIF, đọc đầy đủ hướng dẫn gốc.
Đã bổ sung ảnh tĩnh từ GIF trên từng thẻ kết quả; bấm ảnh cũng mở chi tiết.
Kiểm thử phần ảnh ở `docs/exercisedb-thumbnails-2026-11-19.md`.
Ở bản kiểm thử bật GIF miễn phí, nút thêm bài mới chỉ mở sau khi ảnh tải
thành công. GIF lỗi có thông báo và nút thử lại; không tự thêm ảnh hỏng.

**Thêm vào HealthMate** mở form hiện có, tự điền `edb-{sourceId}`, sourceId,
nhóm/dụng cụ đã nhận diện và nhãn cơ tiếng Việt nếu có ánh xạ rõ ràng.
Admin nhập tên, 2–6 bước hướng dẫn, biến thể dễ hơn bằng tiếng Việt và lý do
thay đổi, kiểm tra trạng thái hiển thị rồi lưu. Hướng dẫn nguồn xuất hiện
bên cạnh để đối chiếu, không tự động lưu nguyên bản vào Firestore. Phân loại
không ánh xạ được để trống và yêu cầu chọn, không đoán dụng cụ thay thế.

Bài đã có, kể cả đang ẩn hoặc dùng ID cũ khác `edb-*`, mở bản hiện có để
chỉnh sửa/khôi phục. Kiểm tra lại khi lưu nhằm chặn thêm trùng vừa xuất hiện
qua listener. Giao dịch lưu hiện có vẫn kiểm version để chặn ghi đè do hai
phiên tạo cùng document.

Lưu qua `api.save('exercise_library', ...)` và audit hiện có, không sửa
schema/Rules hoặc thêm backend. App đang kết nối cùng Firebase project nhận
bài mới qua `FirebaseExerciseLibraryRepository` đang có; không cần chạy lại
VS Code cho từng bài. Nếu mở sẵn bộ lọc, bài phải khớp bộ lọc mới xuất hiện.

## Vòng đời, lỗi và nguồn

- Request metadata trực tiếp, `cache: no-store`, không API key/RapidAPI,
  không tải repo GitHub, không tạo kho sao chép toàn bộ 1.500 bài.
- Tìm theo tên gốc tiếng Anh; có ánh xạ một số từ Việt phổ biến, không phải
  dịch AI toàn bộ. Tên/dữ liệu nguồn được hiển thị bằng text node.
- Hủy request cũ khi đổi tìm kiếm/bộ lọc; bỏ phản hồi tới muộn. Đóng picker,
  đổi trang hoặc đăng xuất hủy request, timer, observer và GIF. GIF chuyển
  động chỉ phát trong chi tiết; kết quả tải ảnh khi vào vùng nhìn thấy,
  vẽ một khung hình tĩnh rồi giải phóng nguồn GIF, tối đa hai lượt tải.
- Xử lý mất mạng, timeout, 429/backoff, response/cursor sai và retry độc lập
  cho bộ lọc hoặc kết quả. Bộ lọc lỗi không chặn tìm theo tên.
- Giữ gate GIF miễn phí cho môi trường thử nghiệm phi thương mại. Bản triển
  khai không bật gate vẫn duyệt metadata và soạn bài; báo rõ GIF chưa bật.
- Trong kiểm Chrome phát hiện style filter động bị CSP `style-src 'self'`
  chặn. Đã sinh stylesheet profile bên ngoài, link trong index; bỏ inline
  style của SVG defs, dùng width/height 0 và CSS. Kiểm computed filter chung
  và filter riêng nữ thành công dưới CSP hiện có; không nới CSP.

Tài liệu/API đối chiếu trực tiếp:

- https://docs.ascendapi.com/products/edb-v1/overview.md
- https://oss.exercisedb.dev/docs và https://oss.exercisedb.dev/swagger
- https://docs.ascendapi.com/guides/caching.md

## File chính

- `admin-web/dist/exercisedb-browser-model.mjs`: API client, parsing, mapping.
- `admin-web/dist/exercisedb-browser.mjs`: picker, tìm/lọc/phân trang/chi tiết.
- `admin-web/dist/workouts-page.mjs`: mở picker, prefill, kiểm trùng, lưu/audit.
- `admin-web/dist/exercise-media-preview.mjs`, `exercise-library.css`.
- `exercise-gif-background.mjs`, `exercise-background-profiles.css`, index,
  generator `tool/build_exercise_background_profiles.cjs` cho CSP.
- Tests model/DOM/browser và `rules-tests/exercise-library.rules.test.cjs`.

## Kiểm thử đã chạy

- Toàn bộ admin: **169/169 qua**; 11 test mới cho client/picker và 3 luồng
  app DOM mới. Kiểm kết hợp bộ lọc, reset cursor, phản hồi đảo thứ tự, abort,
  retry/rate limit, XSS, GIF lỗi/thử lại, bản nháp tiếng Việt, lưu/audit,
  bài trùng và đăng xuất giữa lúc tải.
- App Flutter: **27/27 qua** ở bốn suite exercise_library_sync,
  exercise_library_ui, exercise_source_policy, female_exercise_library.
- `flutter analyze --no-pub`: **No issues found**, 62,3 giây.
- `npm run check --prefix admin-web`, `check:exercises` và generator
  `--check`: qua. Dart format xem xét cho file generated, không đổi logic app.
- API thật: lấy facets, hai trang 25 bài không trùng, tìm `bench press` +
  chest + barbell nhận 10 bài khớp; không lưu response/media vào sản phẩm.
- Chrome headless thật: kho/API/GIF thật, adapter Firebase QA trong bộ nhớ.
  Sáu bố cục dark/light × 1440/390/320px không tràn ngang; xem GIF, kiểm CSS
  dưới CSP, chuyển bản nháp, lưu vào adapter QA thành công. **0 production
  writes, 0 runtime exception**. Ảnh trong thư mục bằng chứng là screenshot
  Chrome; dữ liệu source thật, không phải ảnh mockup.
- Firebase Emulator Firestore: **6/6 qua**, project demo riêng. Gồm payload
  được tạo bởi chính hàm draft/payload của picker, admin audit, UID người dùng
  đọc được và một listener nhận create/edit/archive/restore/add không reload.
  Các log PERMISSION_DENIED của ca từ chối truy cập là kết quả mong đợi.

Bằng chứng: `build/exercisedb-browser-20261119/` gồm admin-tests.log,
flutter-tests.log, analyze.log, rules-tests.log, live-api-smoke.json,
browser-review.json và các screenshot exercise-browser-*.png. Một lần kiểm
GIF trên Chrome hết thời gian chờ; chạy lại tải thật và hoàn thành. Emulator
ban đầu dùng Java cũ/config ngoài project: chuyển sang JBR21 đã cài cùng
Android Studio, sao chép Rules hiện tại vào config build và chạy CLI trực
tiếp bằng Node; không cài hoặc thay đổi Java hệ thống.

## Cần người dùng làm / giới hạn

Ctrl+F5 admin local để nạp mã mới. Không cần cấu hình Firebase mới, tài khoản
ExerciseDB hoặc tải GitHub. Không push/deploy trong lượt này, không ghi vào
Firebase production. Chưa nghiệm thu Android vật lý trong lượt này.

Không khẳng định mọi GIF của kho nguồn đều còn tồn tại; API/CDN có thể lỗi
hoặc giới hạn tốc độ. Giữ quyền sử dụng GIF miễn phí theo phạm vi thử nghiệm
đã thống nhất. Nội dung tiếng Việt cần admin biên tập, không tự dịch bằng AI.
GIF mới dùng matte tổng quát; các lỗ nền đặc biệt chưa được rà riêng như
10 GIF nữ. Đề xuất tiếp: nghiệm thu luồng trên môi trường người dùng khi
được yêu cầu; chưa chuyển sang tính năng/giai đoạn khác.
