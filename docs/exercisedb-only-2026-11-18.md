# Chỉ dùng ExerciseDB — 18/11/2026

> Cập nhật lượt rà soát mở rộng 18/11/2026: đã kiểm tra toàn bộ 1.500 ID/1.324 GIF tải được, tìm thêm 6 mẫu nữ không có nhãn giới tính. App/admin hiện **60 bài / 10 mẫu nữ**. Xem [báo cáo đầy đủ](exercisedb-full-visual-audit-2026-11-18.md). Nội dung bên dưới là lịch sử.

## Giai đoạn và kết quả

Giai đoạn 11, bảo trì minh họa tập luyện theo lựa chọn mới của người dùng:
chỉ dùng ExerciseDB, miễn phí cho bản kiểm thử, không tài khoản/API key.
Đã bỏ 30 mục RepDB khỏi danh mục đang hiển thị. App và admin dùng chung
**54 bài ExerciseDB: 50 mẫu nam cũ và 4 mẫu nữ đã xác minh**.

**Chưa đạt yêu cầu 30 GIF nữ ExerciseDB.** Bốn là số tệp nữ đã xác minh tải
được trong lượt kiểm tra này; không phải kết luận toàn bộ ExerciseDB chỉ có
bốn tệp nữ. Không thay nguồn khác, không đổi nhãn GIF nam thành nữ để đủ số.

## Nguồn và xác minh

- [Repository chính thức](https://github.com/ExerciseDB/exercisedb-api): cây
  `main` ở commit `401ef93437a160f86927fee43b8e692532d04469` hiện chỉ có
  README và LICENSE, không có thư mục media để tải thêm từ nhánh này.
- [Tài liệu V1 chính thức](https://docs.ascendapi.com/products/edb-v1/overview.md)
  hiện mô tả bản free có 1.500 bài, GIF 180p, không cần xác thực. Tổng số bài
  này không chứng minh có 30 GIF nữ.
- Tìm `name=female` qua API hiện trả danh sách rỗng; tên hiện tại đã bỏ nhãn
  giới tính ở những bài nữ cũ. Vì vậy kiểm tra từng ID trong dữ liệu đã lưu.
- Rà soát 7 ID trước đây có nhãn nữ: metadata đều HTTP 200 và ID khớp. Bốn
  tệp GIF trả 200; ba tệp `6Wr0F3W`, `ntjtCfu`, `KQfySvS` trả 404 HTML nên
  không thêm vào danh mục. Gọi tuần tự, có khoảng nghỉ, dừng nếu gặp 429.

| ID | Bài trong app | Tệp kiểm tra ngày 18/11 |
| --- | --- | --- |
| `Nh3mvOO` | Kéo tạ đơn tay ngửa (mẫu nữ) | GIF 180×180, 12 khung |
| `Pjbc0Kt` | Đẩy hông quỳ với dây kháng lực (mẫu nữ) | GIF 180×180, 12 khung |
| `yT9tk17` | Nâng chân chéo có tựa tay (mẫu nữ) | GIF 180×180, 18 khung |
| `BCs0G2F` | Ngồi nâng chân giữ tạ đòn (mẫu nữ) | GIF 180×180, 12 khung |

Đã giải mã toàn bộ khung bằng Pillow, kiểm tra pixel thay đổi và xem contact
sheet để xác nhận nhân vật, động tác, dụng cụ. Không chỉ kiểm tra URL tồn tại.
50 mục nam được giữ nguyên từ danh mục trước, chưa tải lại toàn bộ media trong
lượt này. Bằng chứng/ảnh/hash nằm trong thư mục ignored
`build/exercisedb-only-20261118/`:
`female-probe.json`, `decoded-media.json`, `female-exercisedb-verified.jpg`.

## Hành vi app và admin

- Danh mục chung sinh từ một JSON; tìm `mẫu nữ`/`mau nu` để thấy bốn bài.
  Tìm kiếm không dấu và bộ lọc nhóm cơ/dụng cụ vẫn kết hợp được.
- Admin thêm/sửa/ẩn/khôi phục bài ExerciseDB qua luồng audit đang có. Không
  còn ô chọn RepDB; mã nguồn yêu cầu đúng 7 chữ/số. Xuất danh mục ghi đúng
  ExerciseDB. Thay đổi vẫn đi qua listener Firestore.
- Model, bộ lọc, lớp tải media, admin validation và Rules chỉ chấp nhận nguồn
  ExerciseDB. Các nguồn khác bị chặn trước khi gửi request media. Override
  không hợp lệ không làm sống lại bản bundled đã bị thay thế.
- Giữ cơ chế tải theo vùng nhìn thấy, dừng/hủy khi rời màn hình và xử lý
  lỗi/thử lại. App vẫn dùng bộ xử lý nền GIF ExerciseDB hiện có.
- Firestore không lưu GIF hoặc URL. `sourceProvider` là tùy chọn, khi thiếu
  mặc định `exercisedb`; nếu có chỉ chấp nhận `exercisedb`. Không đổi dữ liệu
  nhật ký/công thức MET/calo hoặc quyền người dùng và audit.
- Xóa các allowlist, manifest, nhánh media WebP và test riêng cho tích hợp
  RepDB vừa bị người dùng từ chối; bản sao trước sửa giữ trong build ignored.

## File chính

- `data/workouts/exercise-library.json`, `tool/build_exercise_library.cjs` và
  catalog sinh ra trong Dart/admin JavaScript.
- `lib/features/activity/models/exercise_library_entry.dart`,
  `data/exercise_db_service.dart`, `presentation/exercise_gif_preview.dart`,
  `presentation/workout_ui.dart` dưới cùng feature activity.
- Admin: `exercise-library-model.mjs`, `exercise-media-preview.mjs`,
  `workouts-page.mjs`, `exercise-library.css` và các test tương ứng.
- `firestore.rules`, `rules-tests/exercise-library.rules.test.cjs`,
  `test/exercise_source_policy_test.dart`, các test catalog và giao diện nữ.
- Báo cáo này, implementation-progress, test-report, database-design và các
  ghi chú nguồn cũ được đánh dấu là lịch sử.

## Kiểm thử thực tế

- `dart format --output=none --set-exit-if-changed` trên 8 file Dart liên
  quan: 0 file thay đổi sau format.
- `node tool/build_exercise_library.cjs --check`: khớp **54 mục** ở Dart/JS.
- `flutter analyze --no-pub`: **No issues found**, 16,9 giây.
- `flutter test --no-pub` trên 12 suite tập luyện: **103 ca qua, 1 ca chụp
  opt-in cũ bỏ qua**. Bao gồm chính sách nguồn, 4 bài nữ, đồng bộ, tìm kiếm,
  chi tiết, vòng đời GIF, UI nhiều cỡ màn hình và phiên tập.
- Admin `npm run check`, `npm run check:exercises`: thành công.
  `node --test admin-web/test/*.test.mjs`: **152/152 qua**.
- Emulator Firestore: **5/5 qua**, gồm admin CRUD/audit, từ chối nguồn khác,
  người dùng chỉ đọc, chặn truy cập không hợp lệ và nhận trực tiếp chuỗi
  thêm/sửa/ẩn/khôi phục qua một listener người dùng. Emulator đã dừng.
- `flutter build web --debug --no-pub`: thành công (Built build/web, 77,6 giây). Wasm dry-run còn cảnh báo mobile_scanner/dart:html hiện có; bản JavaScript đã build thành công.
- `git diff --check` trên file tracked trong phạm vi: không lỗi whitespace.

Lần analyze đầu quét nhầm các bản sao `.dart` trong build. Đã đổi đuôi bản
sao thành `.dart.before` để giữ nguyên nội dung, chạy lại analyze sạch; không
ẩn cảnh báo hoặc sửa cấu hình analyzer. Lần admin test đầu có một assertion
nhãn nút cũ; đổi kỳ vọng sang nhãn `Dừng GIF` của ExerciseDB và chạy lại toàn
bộ 152 ca thành công. Log ban đầu lẫn kết quả cuối đều được giữ trong build.

## Cần người dùng làm và giới hạn

Hot Restart app và tải lại admin local để nhận code mới. Không cần tạo tài
khoản nguồn, thêm API key hoặc bật billing. Chưa push GitHub, deploy hosting
hoặc Rules production. Không thay đổi dữ liệu người dùng trên Firebase thật.

GIF free vẫn chỉ bật trong bản kiểm thử phi thương mại theo lựa chọn đã có;
bản phát hành Premium cần quyền sử dụng phù hợp. Media ngoài có thể bị gỡ,
giới hạn lượt gọi hoặc mất mạng. Chưa nghiệm thu Android vật lý. Mục tiêu
30 GIF nữ cùng nguồn còn thiếu 26 tệp đã xác minh.

Giai đoạn kế tiếp đề xuất: tiếp tục xác minh GIF nữ ExerciseDB khi có thêm
nguồn truy cập phù hợp; chưa tự chuyển giai đoạn hoặc mua dịch vụ.
