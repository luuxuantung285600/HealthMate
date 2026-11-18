# 30 minh họa nữ RepDB — 17/11/2026

> Cập nhật lượt rà soát mở rộng 18/11/2026: đã kiểm tra toàn bộ 1.500 ID/1.324 GIF tải được, tìm thêm 6 mẫu nữ không có nhãn giới tính. App/admin hiện **60 bài / 10 mẫu nữ**. Xem [báo cáo đầy đủ](exercisedb-full-visual-audit-2026-11-18.md). Nội dung bên dưới là lịch sử.


Giai đoạn 11, theo yêu cầu thêm 30 động tác phổ biến có nhân vật nữ, không
cần tương ứng với bài nam. Danh mục chung app/admin tăng từ 54 lên **84 bài**,
gồm **34 bài có mẫu nữ** (4 ExerciseDB cũ và 30 RepDB mới).

## Nguồn và giấy phép

- [RepDB chính thức](https://repdb.co/exercise-animations/),
  [preview không cần tài khoản](https://repdb.co/download/preview?locale=en).
- Đã đọc README và LICENSE bên trong ZIP preview. Gói này có giấy phép riêng
  [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/), cho phép chia
  sẻ/chỉnh sửa/dùng phi thương mại và đánh giá trước khi mua. Credit bắt buộc:
  `Exercise data & images: RepDB (https://repdb.co)`.
  Bản sao: `docs/licenses/repdb-preview-CC-BY-NC-4.0.md`.
- Tệp là **WebP động lặp như GIF, nền trong suốt**, không phải `.gif`, MP4 hay
  người thật. Bản URL công khai 512×512, master trong ZIP 960×960. Giữ WebP
  để bảo toàn alpha/viền mượt; không áp bộ xóa nền trắng của ExerciseDB lên
  nhân vật RepDB. Không tuyên bố đây là mô hình giải phẫu 3D được thẩm định.
- Chỉ tích hợp vào bản kiểm thử phi thương mại đã được người dùng chọn.
  HealthMate có Premium nên bản phát hành có doanh thu cần giấy phép/nguồn
  phù hợp trước. Không mua dịch vụ, không bật billing. Media bị chặn trong
  release của app và admin hosted theo cổng thử nghiệm hiện có; không đóng
  gói tệp media vào assets sản phẩm.

## Danh sách mới

Tên trong app có hậu tố `(mẫu nữ)`. Tìm `mẫu nữ` hoặc `mau nu` để thấy tất cả
34 mục nữ; bộ lọc vùng cơ/dụng cụ vẫn kết hợp được.

| # | Động tác | Mã RepDB |
|---|---|---|
| 1 | Lăn bụng với con lăn | ab-wheel-rollout |
| 2 | Gập bụng trên bóng thăng bằng | balance-dome-crunch |
| 3 | Bước ngang với dây kháng lực | banded-lateral-walk |
| 4 | Chùng chân lùi với tạ đòn | barbell-reverse-lunge |
| 5 | Co gối trên ghế | bench-leg-pull-in |
| 6 | Kéo tạ đơn cúi người | bent-over-db-row |
| 7 | Cuốn tay trước với tạ đơn | bicep-curl |
| 8 | Giãn lưng mèo bò | cat-cow |
| 9 | Cuốn tạ đơn tựa đùi | concentration-curl |
| 10 | Cuốn tạ búa chéo người | cross-body-hammer-curl |
| 11 | Ép ngực tạ đơn trên ghế dốc xuống | decline-db-fly |
| 12 | Cuốn tạ EZ tựa ngực | ez-bar-spider-curl |
| 13 | Kéo tạ EZ lên trước ngực | ez-bar-upright-row |
| 14 | Squat tạ đòn trước ngực | front-squat |
| 15 | Nâng hông trên thảm | glute-bridge |
| 16 | Cuốn tay trước trên ghế nghiêng | incline-db-curl |
| 17 | Đẩy ngực tạ đơn trên ghế nghiêng | incline-db-press |
| 18 | Kéo cáp tư thế quỳ | kneeling-cable-row |
| 19 | Ép ngực với máy | machine-chest-fly |
| 20 | Leo núi tại chỗ | mountain-climbers |
| 21 | Kéo tạ chuông một tay | one-arm-kettlebell-row |
| 22 | Hít xà đơn | pull-up |
| 23 | Kéo xô tay ngửa | reverse-grip-lat-pulldown |
| 24 | Chèo thuyền với máy | rowing-machine |
| 25 | Chạy bộ | running |
| 26 | Nâng tạ vai tư thế nằm nghiêng | side-lying-lateral-raise |
| 27 | Duỗi tay sau với cáp một tay | single-arm-tricep-pushdown |
| 28 | Squat một chân chạm ghế | single-leg-box-squat |
| 29 | Squat trước với máy Smith | smith-machine-front-squat |
| 30 | Squat kết hợp đẩy tạ qua đầu | thruster |

## Tích hợp và file chính

- `data/workouts/exercise-library.json`: thêm 30 mục với hướng dẫn tiếng Việt,
  vùng cơ, dụng cụ và cách tập nhẹ hơn. 54 bản ghi cũ giữ nguyên về nội dung.
- `data/workouts/repdb-preview-manifest.json`: nguồn, giấy phép, hash ZIP,
  thông số từng master, URL và bằng chứng kiểm tra từng bản phục vụ công khai.
- `tool/build_exercise_library.cjs`: sinh cùng danh mục Dart/JS và hai allowlist
  30 mã RepDB. Không giả mã ExerciseDB 7 ký tự cho nguồn mới.
- Model thêm `sourceProvider` tùy chọn, mặc định `exercisedb`; RepDB dùng slug
  cùng ID ổn định `repdb-female-{slug}`. Dữ liệu cũ vẫn đọc được.
- `exercise_db_service.dart`: phân luồng theo nguồn, chỉ tải đúng 30 URL nữ
  được phép. RepDB không gọi API metadata ExerciseDB. Kiểm MIME/header WebP
  động, dung lượng 8 MiB, timeout và hủy request theo owner.
- `exercise_gif_preview.dart`: giải mã WebP động bằng codec có sẵn, giữ alpha
  ở cả sáng/tối, hiển thị credit/định dạng; không xóa vùng trắng trên nhân vật.
- Admin: `exercise-library-model.mjs`, `exercise-media-preview.mjs`,
  `workouts-page.mjs`, `exercise-library.css`: chọn nguồn, sửa/ẩn/khôi phục có
  audit, tải đúng clip trong hàng đợi, credit và xuất Excel có cột nguồn.
- Rules thêm trường nguồn tùy chọn, đúng 30 slug miễn phí và hai dụng cụ
  con lăn bụng/bóng thăng bằng. Giữ admin xác minh/audit/quyền đọc người dùng.
  Không thay collection, công thức calo hoặc dữ liệu sức khỏe; không dùng MET
  trong preview để sửa bảng tính năng lượng hiện hành.

## Kiểm chứng

- 30 master và 30 tệp URL công khai đã giải mã được; mỗi URL HTTP 200,
  `image/webp`, CORS `*`, có alpha, 28–150 khung, khác biệt pixel giữa các thời
  điểm. Tổng tệp công khai kiểm tra 45.156.326 byte. App chỉ tải các mục hiển
  thị/yêu cầu, không tải toàn bộ 30 tệp khi mở thư viện.
- Đã xem contact sheet toàn bộ 30 mục, chụp và xem widget thật của app ở cả
  sáng/tối với đúng tệp RepDB đã kiểm. Không dùng mockup để khẳng định UI chạy.
- `dart format` trên 9 file Dart liên quan: sạch.
- `flutter test --no-pub --dart-define=REPDB_CAPTURE=true` với 12 suite tập
  luyện: **135 ca qua, 1 ca chụp cũ opt-in bị bỏ qua**. Bao gồm 34 mapping nữ,
  giải mã animation giữ pixel trắng trên nền đen, gate release, dữ liệu sai,
  MIME/header/cap dung lượng, layout và luồng tập luyện hiện có.
- Admin `node --test test/*.test.mjs`: **152/152 ca qua**; kiểm tra sửa và ẩn
  RepDB giữ đúng provider/ID qua snapshot. `npm run check`, `check:exercises`
  đều thành công.
- Firebase Emulator, `exercise-library.rules.test.cjs`: **5/5 ca qua**, gồm
  audit, quyền admin/user/guest, RepDB sửa/ẩn/khôi phục/chuyển nguồn, dữ liệu
  không hợp lệ, và một subscription người dùng nhận create/edit/archive/
  restore/add không reload. Dùng JBR 21 của Android Studio vì Java mặc định
  của máy là bản cũ không được Firebase CLI chấp nhận.
- `flutter build web --debug --no-pub`: thành công. Wasm dry-run còn cảnh báo
  do `mobile_scanner`/`dart:html` hiện có; bản JavaScript debug build thành công.
- Generator `--check`: 84 mục hợp lệ, hai catalog và hai allowlist khớp nguồn.
- `flutter analyze --no-pub` cuối: No issues found (13,0 giây).

Log, ZIP, nguồn đã tải, GET/hash, ảnh chụp và cấu hình emulator nằm tại
ignored `build/female-30-research-20261117/`.

## Vận hành và giới hạn

Hot Restart app để nhận danh mục mới; admin local tải lại trang. Khi dùng
Firebase Emulator cần nạp Rules hiện tại. Muốn nghiệm thu chỉnh sửa RepDB
trên Firebase thật phải triển khai bản admin và Rules mới đã kiểm thử trước.
**Chưa push/deploy hosting hoặc Rules production trong lượt này**; không đưa
các thay đổi khác của working tree lên production.

Chưa nghiệm thu Android vật lý hoặc đo hiệu năng thiết bị yếu. Nguồn media
cần Internet và có thể thay đổi về sau; hướng dẫn chữ vẫn dùng được nếu tải
thất bại. Giai đoạn tiếp theo đề xuất: nghiệm thu trên thiết bị khi người dùng
yêu cầu; chưa tự thực hiện.
