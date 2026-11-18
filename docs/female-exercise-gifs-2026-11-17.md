# GIF nhân vật nữ — 17/11/2026

> Cập nhật lượt rà soát mở rộng 18/11/2026: đã kiểm tra toàn bộ 1.500 ID/1.324 GIF tải được, tìm thêm 6 mẫu nữ không có nhãn giới tính. App/admin hiện **60 bài / 10 mẫu nữ**. Xem [báo cáo đầy đủ](exercisedb-full-visual-audit-2026-11-18.md). Nội dung bên dưới là lịch sử.



## Giai đoạn 11: bổ sung minh họa tập luyện

Đã bổ sung bốn bài có GIF nhân vật nữ vào danh mục chung của app và admin,
nâng số bài mặc định từ 50 lên 54. Đối chiếu với bản trước cho thấy toàn bộ
50 bản ghi cũ giữ nguyên. Đây là bổ sung danh mục, không phải bộ 50 phiên bản
nữ tương ứng với mọi bài nam và không giới hạn bài tập theo giới tính người dùng.

## Nguồn và xác minh

Đối chiếu dữ liệu của [ExerciseDB trên GitHub](https://github.com/ExerciseDB/exercisedb-api)
với API OSS hiện hành. Các tên cũ có chữ `female`, trong khi API hiện đã bỏ
chữ này; chỉ tìm từ khóa trên tên API sẽ bỏ sót các mã dưới đây.

| Mã ổn định | Tên trong HealthMate | GIF đã kiểm tra |
| --- | --- | --- |
| `Nh3mvOO` | Kéo tạ đơn tay ngửa (mẫu nữ) | 180×180, 12 khung |
| `Pjbc0Kt` | Đẩy hông quỳ với dây kháng lực (mẫu nữ) | 180×180, 12 khung |
| `yT9tk17` | Nâng chân chéo có tựa tay (mẫu nữ) | 180×180, 18 khung |
| `BCs0G2F` | Ngồi nâng chân giữ tạ đòn (mẫu nữ) | 180×180, 12 khung |

Cả bốn endpoint trả HTTP 200, ID khớp; media trả HTTP 200, MIME `image/gif`,
giải mã được nhiều khung. Đã xem các khung GIF thật để xác nhận nhân vật nữ,
động tác và dụng cụ phù hợp với hướng dẫn tiếng Việt. Không suy từ tên bài
hoặc chỉ sự tồn tại của trường `gifUrl` rằng GIF đang hoạt động.

Rà soát thêm đủ bảy tên từng có nhãn nữ trong dữ liệu GitHub. Ba mã
`6Wr0F3W`, `ntjtCfu`, `KQfySvS` vẫn có metadata API HTTP 200 nhưng tệp
`gifUrl` chính API trả về đều HTTP 404, MIME HTML; không thêm các bài thiếu
media này. Kết quả chi tiết ở `extra-candidate-check.json` và
`extra-media-probe.json` trong thư mục kiểm tra cục bộ.

Giữ cơ chế tải GIF theo yêu cầu và nguồn đúng ID; không gán GIF nữ của động
tác khác để lấp chỗ trống. Chỉ đóng gói ID và hướng dẫn tiếng Việt. Tệp kiểm
tra, log và ảnh đối chiếu nằm trong ignored `build/exercise-female-review-20261117/`,
không thêm media nhà cung cấp vào assets sản phẩm.

## App và admin

- Tìm `mẫu nữ` hoặc `mau nu` để thấy bốn bài; kết hợp bộ lọc nhóm cơ/dụng cụ
  hiện có. Mỗi bài mở chi tiết với đúng mã GIF riêng.
- Admin dùng cùng dữ liệu sinh từ JSON, có thể sửa, ẩn và khôi phục các bài
  mới qua cơ chế audit/Firestore realtime đang có. Bài đã ẩn không xuất hiện
  trở lại từ danh mục đóng gói; nhật ký cũ được giữ theo nghiệp vụ hiện hành.
- Không đổi schema, Rules, công thức calo, đăng ký dịch vụ hay thêm dependency.

File chính: `data/workouts/exercise-library.json`,
`tool/build_exercise_library.cjs`,
`lib/features/activity/data/bundled_exercise_library.dart`,
`admin-web/dist/bundled-exercise-library.mjs`,
`test/female_exercise_library_test.dart` và các test danh mục/admin liên quan.

## Kiểm tra đã chạy

- `node tool/build_exercise_library.cjs --check`: 54 ID duy nhất, Dart và web
  khớp dữ liệu nguồn.
- `dart format --output=none --set-exit-if-changed` trên sáu file Dart liên quan:
  0 thay đổi.
- `flutter analyze --no-pub`: No issues found, exit 0.
- `flutter test --no-pub` trên 11 suite exercise/workout: **99 ca qua**;
  một ca chụp tùy chọn bỏ qua. Kiểm tra tìm kiếm, mở đúng bài nữ, merge/ẩn/
  khôi phục, tải GIF lazy, cleanup, layout nhỏ/chữ lớn, timer và lưu nhật ký.
- `npm run check` trong admin: qua; `npm test`: **149/149 qua**, gồm tìm
  `mau nu` trên DOM thật của trang admin và kiểm đúng bốn ID.
- Lượt đầu có ba test layout chạm thẻ trước khi scroll được render; thêm
  `pumpAndSettle` sau `ensureVisible` và kiểm hit-test trước khi chạm, chạy
  lại qua. Hai test DOM còn kỳ vọng 50 được cập nhật thành 54 và bổ sung
  kiểm tra bốn hàng nữ; không bỏ assertion để che lỗi sản phẩm.

Log cuối: `analyze-final.log`, `flutter-tests-final.log`,
`admin-all-tests-final.log` trong thư mục build nêu trên.

## Cần người dùng làm và giới hạn

Hot Restart app đang chạy để nhận catalog mới, tải lại admin local. Chưa
deploy admin online, push Git hoặc nghiệm thu Android vật lý trong lượt này.
GIF miễn phí vẫn thuộc phạm vi kiểm thử phi thương mại đã chọn; gate bản
release hiện có giữ nguyên. Không cần cấu hình Firebase hoặc bật billing mới.

Đề xuất tiếp: nghiệm thu bốn bài trên thiết bị; chưa tự thực hiện.
