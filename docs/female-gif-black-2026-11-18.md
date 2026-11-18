# Giai đoạn 11 — Giữ 10 GIF nữ, đồng bộ nền đen và viền

> Cập nhật 19/11: giới hạn nền trắng khép kín nêu cuối báo cáo này đã được
> xử lý cho tập10 GIF hiện tại. Xem [báo cáo mới](exercise-enclosed-background-2026-11-19.md).

## Phạm vi chốt với người dùng

Người dùng chọn: **“Giữ 10 GIF ExerciseDB, hoàn thiện nền đen và viền”**
sau khi được thông báo các tệp bổ sung tìm thấy bị trùng. Danh mục giữ
**60 bài, gồm 10 GIF nữ khác nhau**. Không còn mục tiêu thêm đủ 20 trong
lượt này; không thêm bài hoặc đổi nguồn để bù số lượng.

## Kết quả hiển thị

- App đã có bộ xử lý chung cho nam/nữ: xóa nền trắng nối với biên, co matte
  một pixel nguồn, làm mềm alpha bằng Gaussian và loại màu trắng đã trộn
  ở mép. Lượt này xác minh trên 10 GIF nữ, không sửa lại thuật toán Dart
  đang hoạt động hoặc chỉ làm tối toàn bộ ảnh. Chế độ sáng dùng ảnh gốc.
- Admin trước đây giữ nền trắng ở preview và màn chi tiết. Đã bổ sung cùng
  bộ lọc SVG v3 như app, dùng một định nghĩa chung cho mỗi document. Nền
  ngoài màu `#000` khi tối; khi sáng giữ ảnh gốc. Chỉ áp dụng cho ảnh
  ExerciseDB trong luồng tập luyện.
- Chuyển sáng/tối giữ nguyên GIF đang chạy và URL. Dừng, thử lại, rời dòng,
  đóng chi tiết và chuyển tab tiếp tục hủy/dọn media như trước. Khi định
  nghĩa SVG bị mất, lần tải tiếp theo khôi phục được.
- Giữ màu nhóm cơ, dây vàng, quần áo và dụng cụ. Không đảo màu/invert.

Không đổi catalog, schema, Rules, Firebase, quyền, dependency, MET/calo hoặc
cổng media chỉ dùng trong bản kiểm thử phi thương mại. Không đóng gói các
GIF đã tải nghiên cứu vào app/admin hoặc thêm máy chủ lưu trữ.

## Kiểm tra nguồn bổ sung và loại trùng

Đã kiểm tra 176 URL đang lỗi 404 trên host chính thức bằng bản lưu lịch sử
công khai của ExerciseDB. Cả 176 tệp tải được, đã xem khung đầu/giữa và
phóng to trường hợp chưa rõ. Năm ID có mẫu nữ là các bản trùng nội dung:

| ID trong bản lưu | GIF đã có | So sánh khung RGBA |
| --- | --- | --- |
| `6Wr0F3W` | `yT9tk17` | 18/18 giống hoàn toàn |
| `ntjtCfu` | `BCs0G2F` | 12/12 giống hoàn toàn |
| `KQfySvS` | `Nh3mvOO` | 12/12 giống hoàn toàn |
| `7858za8` | `gFyFj9z` | 12/12 giống hoàn toàn |
| `LFIOery` | `BmrwWzo` | 12/12 giống hoàn toàn |

Hash tệp khác nhau không chứng minh GIF có nội dung khác. Đã đối chiếu
từng khung giải mã và thời lượng; không đưa năm ID này vào danh mục hoặc
mở thêm host trong service. Đây là kết quả của các bộ công khai đã kiểm
tra, không khẳng định mọi gói ExerciseDB chỉ có 10 mẫu nữ.

## File chính

- `admin-web/dist/exercise-gif-background.mjs`: bộ lọc SVG và khôi phục
  định nghĩa dùng chung.
- `admin-web/dist/exercise-media-preview.mjs`, `workouts-page.mjs`: cài bộ
  lọc trước khi hiển thị GIF ở danh sách và chi tiết.
- `admin-web/dist/exercise-library.css`: nền đen/bộ lọc chỉ ở chế độ tối.
- `admin-web/test/exercise-media-preview.test.mjs`, `app-dom.test.mjs`:
  kiểm vòng đời, chuyển theme, phục hồi và preview chi tiết.
- `admin-web/package.json`: kiểm syntax cho module mới.

## Kiểm thử thực tế

- `dart format --output=none --set-exit-if-changed` trên 5 file Dart liên
  quan: **0 thay đổi**.
- `flutter analyze --no-pub`: **No issues found**, 47,7 giây.
- `flutter test --no-pub` trên 6 suite: exercise_gif_background,
  exercise_gif_preview, female_exercise_library, exercise_source_policy,
  exercise_inline_library, exercise_library_ui: **40/40 qua**.
- Harness native riêng dùng Flutter engine thực và bộ lọc Dart hiện có:
  giải mã 10 GIF, render **30 khung đầu/giữa/cuối** lên nền đen, kiểm
  premultiplied RGBA. Lượt harness + hai suite nền/preview: **18/18 qua**;
  đây là lượt riêng có các test lặp, không cộng thành 58 test khác nhau.
- `npm run check`, `npm run check:exercises`: qua.
- `node --test test/*.test.mjs` tại admin-web: **154/154 qua**.
- Render SVG lấy trực tiếp từ module admin mới bằng sharp/librsvg offline:
  **20 khung đầu/giữa của 10 GIF**, 20/20 kiểm góc nền đen qua. Đã xem ảnh
  native và SVG, màu nhóm cơ/dây/dụng cụ được giữ.

Không chạy build Flutter mới vì không đổi mã Dart/build config. Không chạy
emulator vì không đổi Rules/backend. Chưa nghiệm thu Android vật lý hoặc
giao diện trên phiên Chrome của người dùng; SVG offline không phải ảnh
chụp trình duyệt.

## Bằng chứng, giới hạn và cách xem

Trong ignored `build/female-gif-black-20261118/`: log analyze/test/check,
`native-contact.png`, `admin-offline-contact.png`, JSON theo ID và
`female-10-black-summary.png` (10 khung thật đã qua renderer Flutter).
Nghiên cứu loại trùng ở `build/exercisedb-extra10-20261118/`, gồm
`duplicate-content-comparison.json`, `research-report.md`, 6 contact sheet,
headers/hash và bản commit/giấy phép lịch sử.

GIF nguồn chỉ 180×180. Bộ lọc làm mềm đường bao; không khôi phục được chi
tiết HD. Vùng trắng khép kín giữa tay/dụng cụ có thể còn trắng; không xóa
trắng toàn ảnh vì sẽ làm mất chi tiết cơ thể/dụng cụ. Một số khung cuối có
bóng tư thế nằm sẵn trong GIF nguồn. Chưa tuyên bố xóa hết mọi răng cưa,
vùng trắng hoặc bóng động tác ở mọi khung.

Hot Restart app nếu phiên đang dùng catalog cũ, tìm `mẫu nữ`; admin local
Ctrl+F5 và chọn chế độ tối. Không cần cấu hình Firebase/tài khoản nguồn mới.
Không push/deploy trong lượt này. Bước đề xuất tiếp: nghiệm thu giao diện
trên thiết bị khi người dùng yêu cầu; không tự chuyển giai đoạn.
