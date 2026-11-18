# Giai đoạn 11 — Ảnh xem trước trên thẻ ExerciseDB

## Đã hoàn thành

Kho **Bài tập luyện → Thêm từ ExerciseDB** hiện ảnh thật lấy từ một khung
hình GIF ngay trên từng thẻ, bên cạnh tên, nhóm cơ và dụng cụ. Ảnh đứng yên;
bấm ảnh hoặc **Xem GIF và hướng dẫn** mới mở GIF chuyển động trong chi tiết.
Giữ luồng chọn bài, biên tập tiếng Việt, kiểm trùng và lưu hiện có.

Ảnh chỉ tải khi thẻ vào vùng nhìn thấy, tối đa hai lượt metadata/ảnh đang
tải đồng thời. Giữ ảnh tĩnh của trang hiện tại trong bộ nhớ; giải phóng
nguồn GIF sau khi vẽ, hủy tải khi cuộn khỏi thẻ đang tải hoặc chuyển tab.
Đổi trang, bộ lọc hoặc đóng picker giải phóng cả ảnh tĩnh, timer và observer.
Ảnh lỗi có nút thử lại riêng, không cản việc mở chi tiết.

Không sao chép thư viện nguồn, lưu thumbnail vào Firestore hay tạo cache
ứng dụng. CDN không cho CORS: dùng Image để hiển thị, vẽ một lần lên canvas;
không đọc/xuất pixel canvas, không thêm proxy/backend hay nới CSP.

Nền đen theo chế độ tối, trắng theo chế độ sáng; dùng cùng filter và profile
ExerciseDB đã có. Thẻ nhỏ nhất giữ khung 96px: thử khung 80px trên Chrome
cho thấy kernel morphology làm tròn về 0, khiến nền trắng chưa được xóa.
Đã sửa kích thước và xác minh màu nền bằng pixel screenshot ở cả sáu bố cục.

## File chính

- `admin-web/dist/exercise-source-thumbnail.mjs`: queue tải, ảnh tĩnh,
  lazy load, vòng đời, lỗi và thử lại.
- `admin-web/dist/exercisedb-browser.mjs`: tích hợp thẻ và giải phóng ảnh.
- `admin-web/dist/exercise-library.css`: bố cục có ảnh, sáng/tối, responsive.
- `admin-web/dist/exercise-gif-background.mjs`,
  `tool/build_exercise_background_profiles.cjs` và stylesheet generated:
  thêm selector filter cho canvas, giữ parity với profile hiện có.
- `admin-web/test/exercise-source-thumbnail.test.mjs`,
  `admin-web/test/exercisedb-browser.browser.cjs`, `admin-web/package.json`.

## Kiểm thử thực tế

- `npm test --prefix admin-web`: **176/176 qua**, không bỏ qua ca nào.
  Bảy ca mới kiểm ảnh chỉ vẽ một lần, giải phóng nguồn, bấm mở chi tiết,
  giới hạn hai decoder, gate media, hủy/late response, tab ẩn, lỗi/thử lại.
- `npm run check --prefix admin-web` và `check:exercises`: qua.
- `node tool/build_exercise_background_profiles.cjs --check`: qua.
- Dart format file generated profile: qua; không thay đổi logic Flutter.
  Không chạy lại Flutter analyze/test hoặc Rules Emulator cho thay đổi
  UI admin này; kết quả Flutter/Rules trước đó nằm ở báo cáo picker riêng.
- Chrome headless thật, API/GIF nguồn thật; Firebase dùng adapter QA trong
  bộ nhớ. Sáu bố cục sáng/tối × 1440/390/320px không tràn ngang.
  Ảnh thu nhỏ có nội dung thật, không có img động trong danh sách; hai
  screenshot của ảnh cách nhau 900ms giống từng byte. Xem GIF thật, áp filter
  chung/profile nữ dưới CSP, chọn và lưu bản nháp vào adapter QA đều qua.
  Đóng picker giải phóng canvas về kích thước 0; không runtime exception.
- Pillow kiểm screenshot: góc nền ảnh **RGB(0,0,0)** ở ba bố cục tối,
  **RGB(255,255,255)** ở ba bố cục sáng; đều có pixel màu của nhân vật.
- **Không ghi Firebase production, không push/deploy**.

Bằng chứng: `build/exercisedb-thumbnails-20261119/`, gồm admin-tests.log,
syntax.log, browser-review.json, thumbnail-pixel-review.json,
exercise-thumbnail-static.png và exercise-browser-*.png.

## Cần người dùng làm và giới hạn

Nhấn **Ctrl+F5** trên admin local để nạp mã mới, mở **Bài tập luyện →
Thêm từ ExerciseDB**. Không cần cấu hình Firebase hoặc tài khoản nguồn mới.
GIF vẫn thuộc luồng kiểm thử miễn phí đã được chọn; môi trường không bật
gate hiển thị thông báo thay ảnh. Phụ thuộc mạng/CDN nguồn, có thử lại khi lỗi.
Ảnh gốc 180p; không tuyên bố nâng thành ảnh độ phân giải cao.

Giai đoạn này hoàn thành. Bước tiếp theo đề xuất: nghiệm thu trên môi trường
admin người dùng khi được yêu cầu; chưa tự thực hiện tính năng/giai đoạn khác.
