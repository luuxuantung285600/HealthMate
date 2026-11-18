# Giai đoạn 11 — Xóa nền trắng khép kín của GIF nữ

Đã xử lý các khoảng nền trắng bị tay, chân, dây hoặc ghế bao quanh trong
10 GIF nữ ExerciseDB hiện có. Những khoảng đó trước đây không nối với mép
ảnh nên bộ lọc v3 bỏ sót. Chế độ tối dùng nền đen; chế độ sáng giữ ảnh gốc.

## Thay đổi

- Lưu tọa độ nhận diện nền đã rà từng khung trong
  `data/workouts/exercise-background-regions.json`; generator sinh cùng dữ
  liệu cho Dart và admin. Bảy clip cần điểm nền bổ sung; ba clip còn lại giữ
  bộ lọc mép vì các vùng trắng bên trong là chi tiết người/dụng cụ.
- Native nhận sourceId khi xử lý khung. Một số điểm nền có điều kiện màu
  ở vị trí tham chiếu để tránh xóa nhầm chi tiết cơ thể ở tư thế khác.
  Chỉ áp dụng tọa độ cho đúng nguồn và kích thước 180×180.
- Web app và admin dùng SVG v4: điểm nền và điều kiện màu được đánh giá
  trên chính SourceGraphic của từng khung, trước khi lan vùng xóa nền.
  Không dùng timer để đoán tư thế. Tạm dừng, phát, đổi theme và tải lại vẫn
  dùng cơ chế hiện có. Dùng khung ảnh vuông để tọa độ đúng cả trong thẻ nhỏ.
- Giữ làm mềm alpha và khử màu nền trắng ở đường bao. Không xóa toàn bộ
  màu trắng trong hình; cơ thể, quần áo và dụng cụ vẫn giữ chi tiết sáng.
- Không thêm dependency, đổi nguồn, lưu GIF vào assets, sửa Firestore,
  bật dịch vụ trả phí hoặc đưa code lên GitHub/web triển khai.

File chính: `exercise_gif_background.dart`, `exercise_gif_preview.dart`,
`exercise_gif_web_background.dart`, `exercise_background_profiles.dart`,
admin `exercise-gif-background.mjs`, `exercise-background-profiles.mjs`,
`exercise-library.css`; generator và các regression test liên quan.

## Kiểm thử thực tế

- Flutter: năm suite về matte, preview, danh mục nữ, chính sách nguồn và
  inline preview: **36/36 qua**. Có regression xóa nền khép kín, giữ một
  vùng trắng khác và chặn xóa chi tiết người khi điều kiện tư thế không khớp.
- `flutter analyze --no-pub`: **No issues found**, 20,8 giây ở lần cuối.
- Native review: đọc đủ **126 khung / 10 GIF thật**, kiểm mọi pixel của các
  vùng nền đã đánh dấu đều alpha 0; các chi tiết trắng được bảo vệ không
  xuất hiện lỗ alpha mới trong nội thất vốn opaque. Kiểm premultiplied RGBA
  trên toàn bộ khung và render ra PNG qua Flutter engine: qua.
- Admin: toàn bộ **155/155 test qua**; sau chỉnh khung vuông, hai suite liên
  quan DOM/media **63/63 qua**. Generator `--check` và JS syntax check qua.
- Mã Dart web biên dịch JS: năm trạng thái cài filter/gọi lặp/sáng/tối lại/
  phục hồi stylesheet qua. Đối chiếu đủ **8 filter SVG** app/admin giống nhau.
- SVG thực tế render offline bằng sharp/librsvg: chín mẫu ở kích thước
  360px đã xem; kiểm thêm đủ **24 khung** của hai clip có điều kiện tư thế,
  **3.494 pixel nội thất vùng nền** đều alpha 0.
- Format năm file Dart: 0 thay đổi ở lượt cuối. Build web debug dùng màn
  review cô lập với widget/theme sản phẩm: **qua**, exit 0, 56,1 giây ở lần
  cuối sau chỉnh khung ảnh. Log `build-web-final.log` trong thư mục bằng chứng.

Các lần sửa lựa chọn vùng trong bước nghiên cứu được giữ ở `build/`; đây
là bước rà ảnh trước khi sinh dữ liệu sản phẩm, không thay test để bỏ lỗi.

## Bằng chứng và giới hạn

`build/gif-closed-matte-20261118/` chứa các log, tọa độ vùng rà soát,
126 PNG native, chín PNG SVG, 24 PNG kiểm tư thế và `before-after.png`.
Ảnh trước/sau dùng cùng khung GIF thật qua Flutter engine, không phải ảnh
chụp màn hình trên máy người dùng. SVG được kiểm bằng rasterizer offline,
chưa nghiệm thu Chrome hoặc Android vật lý trong lượt này.

Đây là bộ lọc cho tập GIF hiện tại, không phải cam kết tự tách nền mọi GIF
mới admin thêm. Nếu nhà cung cấp thay nội dung cùng sourceId, cần rà lại
tọa độ. Độ phân giải gốc vẫn 180p; bóng tư thế có sẵn trong GIF vẫn còn.

Người dùng cần Hot Restart app và Ctrl+F5 admin local để nạp mã mới; không
cần cấu hình Firebase. Đề xuất tiếp: nghiệm thu trên thiết bị thực khi
người dùng yêu cầu; chưa thực hiện giai đoạn khác.
