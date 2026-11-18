# Rà soát trực quan toàn bộ ExerciseDB OSS — 18/11/2026

> Cập nhật sau cùng: người dùng đã chọn giữ **10 GIF nữ** và hoàn thiện nền
> đen/viền. Lượt kiểm tra bản lưu lịch sử loại thêm 5 ID vì trùng từng khung
> với clip đã có. Danh mục vẫn 60/10. Xem
> [kết quả nền đen và viền](female-gif-black-2026-11-18.md). Mục tiêu 20 dưới
> đây là lịch sử trước lựa chọn mới.

## 1. Giai đoạn và kết quả

Giai đoạn 11, tiếp tục hoàn thiện minh họa tập luyện theo phản hồi của người
dùng. Lần trước chủ yếu kiểm tra bảy tên từng có nhãn `female`, vì vậy đã
bỏ sót các nhân vật nữ trong bài có tên trung tính. Kết luận bốn GIF đã xác
minh trước đó không thể dùng thay cho việc rà soát toàn thư viện.

Lượt này đã đọc đủ **60 trang API / 1.500 ID**, kiểm tra **toàn bộ 1.500 URL**,
thu được **1.324 GIF nhiều khung, 176 URL HTTP 404**. Đã xem ảnh của cả 1.324
GIF trên 14 contact sheet, sau đó xem lại đủ 1.324 khung giữa trên 14 sheet
khác; phóng to ở các trường hợp cần xác định người thực hiện. Lượt xem thứ
hai không tìm thêm mẫu nữ. Xác minh được **10 GIF có mẫu nữ thực hiện động tác**, gồm
bốn mục đã có và **sáu mục mới** không có nhãn giới tính trong tên.

Đã thêm sáu mục mới vào danh mục chung app/admin: **60 bài / 10 mẫu nữ**.
Giữ nguyên toàn bộ 54 bản ghi trước đó. Người dùng đã giảm mục tiêu từ 30
xuống **20 GIF nữ**; hiện **10/20, còn thiếu 10**, chưa hoàn thành yêu cầu.

## 2. Các bài mới

| ID ExerciseDB | Tên trong HealthMate | Dụng cụ | GIF |
| --- | --- | --- | --- |
| `r5DgrW9` | Squat tạ đơn có giá đỡ chân (mẫu nữ) | Tạ đơn, giá đỡ chân | 180×180, 12 khung |
| `daBmy1Y` | Deadlift tạ đơn một chân có bục đỡ (mẫu nữ) | Tạ đơn, bục thấp | 180×180, 12 khung |
| `BmrwWzo` | Kéo tạ đơn giữa chân tư thế sumo (mẫu nữ) | Tạ đơn | 180×180, 12 khung |
| `gFyFj9z` | Chùng chân trên bục với tạ đơn (mẫu nữ) | Tạ đơn, bục | 180×180, 12 khung |
| `wSScovH` | Duỗi hông với dây kháng lực (mẫu nữ) | Dây kháng lực | 180×180, 12 khung |
| `eOG0r6v` | Cuốn tay cầm úp với cáp (mẫu nữ) | Máy cáp | 180×180, 12 khung |

Bốn ID cũ tiếp tục được xác minh: `Nh3mvOO`, `Pjbc0Kt`, `yT9tk17`, `BCs0G2F`.
Không tính `LmaFNZS`: có nhân vật nữ trong hình nhưng người nam mới là người
tập nhón gót, người nữ ngồi làm tải. Không dùng hình người thật thay cho nhân
vật minh họa. Không lấy GIF nam rồi đổi nhãn thành nữ.

Mười tệp được chọn có hash khác nhau; đã giải mã mọi khung và kiểm tra thay
đổi pixel. Hướng dẫn tiếng Việt được biên soạn riêng theo động tác/dụng cụ
thực tế, không sao chép hướng dẫn nhà cung cấp. Các biến thể dùng bục/giá đỡ
ghi rõ yêu cầu điểm tựa chắc chắn và có cách tập dễ hơn.

## 3. Nguồn, phạm vi kiểm tra và giới hạn kết luận

- [Danh mục API chính thức](https://oss.exercisedb.dev/api/v1/exercises?limit=25):
  phân trang bằng `after`, 25 mục/trang, kết thúc ở trang 60 với
  `hasNextPage=false`. Tập ID khớp hoàn toàn bản 1.500 ID đã lưu trước đây;
  không có ID thiếu hoặc lặp. Một lần tải trang bị timeout mạng; đã tiếp tục
  từ cursor đã xác nhận và kiểm tra lại tính duy nhất của toàn bộ danh sách.
- [Tài liệu ExerciseDB V1](https://docs.ascendapi.com/products/edb-v1/overview.md)
  mô tả bản OSS có 1.500 bài, GIF 180p và không cần xác thực. **Tổng bài không
  phải tổng số nhân vật nữ**, cũng không bảo đảm mọi URL GIF còn hoạt động.
- Mỗi media dùng đúng URL `https://static.exercisedb.dev/media/{ID}.gif` từ
  dữ liệu nguồn. Kiểm tra tuần tự, tối đa một lần bắt đầu yêu cầu mỗi giây;
  dừng nếu gặp 403/429. Lượt media hoàn tất không gặp hai mã này. Tổng thời
  gian phần media khoảng 1.782 giây.
- Mọi GIF truy cập được được kiểm tra MIME/header/nhiều khung, xem ảnh đầu
  và khung giữa. Trường hợp chưa rõ xem khung giữa phóng to. Mười tệp được đưa vào nhóm nữ
  được giải mã từng khung riêng và xác nhận chuyển động.
- Cả **60 bài hiện trong sản phẩm đều có GIF tải được** trong lượt này.
  176 URL 404 không được tính là GIF sử dụng được. Không suy đoán giới tính
  của media đã bị gỡ, và không kết luận các bộ dữ liệu khác chỉ có 10 mẫu nữ.
- Giữ lựa chọn miễn phí, không tài khoản/API key. Cổng thử nghiệm phi thương
  mại, ghi công ExerciseDB/AscendAPI và chính sách tải media hiện có giữ
  nguyên. Không đóng gói GIF/URL vào assets hoặc Firestore.
- Kiểm tra danh sách repository của tổ chức ExerciseDB và README/tài liệu
  V1 công khai: chưa tìm thấy bộ GIF nữ miễn phí bổ sung đáp ứng điều kiện.
  `muscle-visualizer-api` cung cấp hình nhóm cơ, không phải GIF động tác.
  Các repo `free-exercise-db-with-videos` dùng video người thật, là nguồn
  thay thế độc lập; `exercisedb-pro/exercisedb-dataset` giới thiệu Vital
  Animations, không đủ bằng chứng là nguồn ExerciseDB chính thức. Không
  thêm các nguồn này vào sản phẩm để bù số lượng.

## 4. File đã tạo/sửa

- `data/workouts/exercise-library.json`: thêm sáu bản ghi với ID ổn định,
  tên/nhóm cơ/dụng cụ/hướng dẫn tiếng Việt và cách giảm độ khó.
- Hai catalog sinh từ cùng JSON:
  `lib/features/activity/data/bundled_exercise_library.dart`,
  `admin-web/dist/bundled-exercise-library.mjs`.
- `test/female_exercise_library_test.dart`, `test/exercise_db_test.dart`,
  `admin-web/test/exercise-library.test.mjs`, `admin-web/test/app-dom.test.mjs`:
  cập nhật tập ID đã xác minh, số lượng, tìm kiếm/lọc và CRUD/binding chi tiết.
- Báo cáo này, implementation-progress, test-report và ghi chú lịch sử nguồn.

Không đổi model, schema, Rules, repository/listener, MET/calo, quyền tài khoản
hoặc dependency. Admin tiếp tục thêm/sửa/ẩn/khôi phục các bài mới qua cùng
luồng hiện có; app nhận override bằng listener đang có. Nhật ký cũ giữ nguyên.

## 5. Kiểm thử thực tế

- `node tool/build_exercise_library.cjs --check`: khớp **60 ID duy nhất**,
  catalog Dart/JavaScript đồng nhất; không có URL/media trong dữ liệu đóng gói.
- `dart format --output=none --set-exit-if-changed` trên ba file Dart liên
  quan: 0 file thay đổi sau format.
- `flutter test --no-pub` trên 12 suite tập luyện: **109 ca qua, 1 ca chụp
  opt-in cũ bỏ qua**. Cả 10 bài nữ đều được mở chi tiết và kiểm tra binding
  đúng sourceId; có tìm không dấu, bộ lọc kết hợp, đồng bộ, vòng đời media,
  phiên tập và giao diện nhiều cỡ màn hình/cỡ chữ.
- `npm run check`, `npm run check:exercises`: thành công.
  `node --test test/*.test.mjs` tại admin-web: **152/152 qua**.
- `flutter analyze --no-pub`: **No issues found**, 116,3 giây.
- `flutter build web --debug --no-pub`: **Built build/web**, 113,4 giây.
  Wasm dry-run còn cảnh báo `mobile_scanner`/`dart:html` hiện có; bản build
  JavaScript thành công. Chưa chuyển app sang Wasm.
- Đối chiếu dữ liệu: 54 bản ghi gốc không thay đổi; 60/60 media HTTP 200;
  10/10 tệp nữ giải mã mọi khung, có chuyển động và hash khác nhau.
- `git diff --check` file tracked trong phạm vi: không lỗi whitespace.

Không chạy lại emulator vì không đổi Rules/schema/backend. Không coi các ca
Rules của lượt trước là kết quả kiểm thử mới. Chưa nghiệm thu Android vật lý
hoặc thao tác trên phiên Chrome người dùng đang mở.

## 6. Bằng chứng và việc người dùng cần làm

Thư mục ignored `build/exercisedb-wide-review-20261118/` có:

- `live-index.json`, `live-index-comparison.json`: danh sách API hiện tại và
  đối chiếu đủ 1.500 ID.
- `audit.jsonl`, `progress.json`: trạng thái/định dạng/kích thước/số khung/hash
  của từng URL; `review-01.jpg` đến `review-14.jpg`: toàn bộ ảnh đã xem.
- `middle-review-01.jpg` đến `middle-review-14.jpg`: lượt kiểm tra thứ hai
  bằng khung giữa của đủ 1.324 GIF; `middle-sheets.json` ghi danh sách sheet.
- `current-org-repos.txt`, `current-official-readme.txt`, `current-v1-docs.txt`
  và các `repo-*.md`: bằng chứng đối chiếu nguồn công khai bổ sung.
- `visual-review.json`: phạm vi đã xem, sáu ID mới, trường hợp bị loại.
- `verified-female.json`, `female-10-verified.jpg`: thông số/ảnh mười tệp nữ;
  đây là ảnh đối chiếu media thật, không phải ảnh chụp giao diện app.
- `product-media-status.json`, `integration-result.json`: kiểm tra danh mục
  60 bài, không mất bản ghi cũ; `before/` giữ bản sao trước sửa.
- `flutter-tests.log`, `admin-tests.log`, `admin-check.log`,
  `flutter-analyze.log`, `flutter-build-web.log`: kết quả lệnh thực tế.

Hot Restart app và tải lại admin local, tìm `mẫu nữ` hoặc `mau nu` để xem 10
bài. Không cần cấu hình Firebase, tài khoản nguồn hoặc API key mới. Chưa push
GitHub/deploy hosting/Rules; bản web online cũ chưa nhận catalog mới.

## 7. Phần còn lại và đề xuất

Còn thiếu 10 GIF nữ để đạt mục tiêu mới 20 trong điều kiện ExerciseDB miễn phí đang truy
cập được. Những tệp 404 chưa dùng được và nguồn bên ngoài có thể thay đổi.
Không tạo đủ số bằng trùng clip hoặc thay nguồn. Đề xuất tiếp: nghiệm thu 10
minh họa này trên thiết bị khi người dùng yêu cầu; chưa tự chuyển giai đoạn.
