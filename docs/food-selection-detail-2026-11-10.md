# Giai đoạn 4 bổ sung — Giao diện chọn và xem món ăn

Phạm vi yêu cầu ngày 10/11/2026: thêm ảnh, tham khảo ba màn Wao được cung cấp
cho danh sách/chọn món, trang chi tiết và bảng dinh dưỡng; bỏ phần chọn bữa
sáng/trưa/tối/phụ ở màn thêm món. Không triển khai giai đoạn khác.

## Hành vi đã thay đổi

- Danh sách thẻ có ảnh 80 px, gram, kcal và ba chất. Chạm tên/thẻ/ảnh hoặc
  dấu cộng mở chi tiết; món chưa có ảnh phù hợp giữ hàng chữ như trước.
- Màn chi tiết toàn màn hình có ảnh 152 px khi có nguồn, tên món, lượng,
  biểu đồ tròn năng lượng và tỷ lệ đạm/carb/béo. Nền đen hoặc trắng theo chế
  độ tối/sáng; Inter; màu nhấn tím, không dùng nền tím.
- Nút Giá trị dinh dưỡng mở bảng kéo lên, dùng số liệu của khẩu phần đang
  nhập. Có kcal, carb, xơ, béo, đạm và các dưỡng chất mở rộng mà model hiện
  hỗ trợ: đường, béo bão hòa, natri, kali, canxi, sắt, vitamin C, cholesterol.
  Không tự thêm vitamin hoặc huy hiệu chuyên gia từ ảnh tham khảo.
- Tỷ lệ biểu đồ tính từ năng lượng 4/4/9 kcal/g. Thiếu ba chất hoặc năng lượng
  macro bằng 0 thì giữ vòng trung tính, không tự tạo tỷ lệ. Dữ liệu thiếu
  được phân biệt với số 0; tổng mới biết một phần được ghi rõ.
- Công thức catalog có sourceDetails hợp lệ được giải tên nguyên liệu từ
  đúng bảng tham chiếu. Định lượng trước chế biến được quy đổi theo khối
  lượng thành phẩm đã chọn. Công thức riêng dùng các snapshot nguyên liệu
  của chính người dùng. Có ảnh nguyên liệu khi ID và tên khớp ảnh đã duyệt.
- Không suy đoán nguyên liệu/định lượng cho món thiếu nguồn. Metadata nguồn
  lỗi không làm hỏng danh mục; không tái dùng nguyên liệu của món bị đổi tên.
- Đổi gram/phần, phần lẻ, dấu phẩy thập phân, giới hạn lưu và cảnh báo gói
  khô vẫn hoạt động. Chỉnh lịch sử dùng snapshot đã lưu, không lấy giá trị
  dinh dưỡng mới của catalog để thay lịch sử.
- Bỏ dropdown loại bữa khỏi màn chọn món; vẫn chỉnh ngày/giờ. Trường loại
  bữa trong model/database được giữ tương thích và giữ loại đã lưu của bản
  ghi/nháp. Nhật ký và báo cáo hiện hữu không bị đổi schema.
- Xác nhận chỉ thêm vào nháp; Lưu mới ghi nhật ký. Sau khi đóng chi tiết,
  kiểm tra lại bộ lọc và trạng thái ẩn hiện tại trước khi thêm món.

## Ảnh

Tổng tăng từ 47 lên **51 ảnh WebP 512×512**, đóng gói offline trong app,
không lưu trên Firebase Storage. Bốn ảnh mới là tỏi, hành tây sống, dưa leo
sống và tôm biển bóc vỏ sống. Từng ảnh được xem bản nguồn/bản cuối, chọn
khung tập trung vào thực phẩm; không có người, bàn tay hoặc món không liên
quan. Dưa leo dùng ảnh một quả trên nền trắng, thay ứng viên ngoài vườn.
Không phóng lớn nguồn nhỏ. Nguồn, tác giả, giấy phép và hash nằm trong
assets/food_photos/manifest.json và ATTRIBUTION.md. Chạm ảnh ở trang chi tiết
để xem nguồn/giấy phép. Chưa có ảnh hợp lệ cho đồ gói thì vẫn hiện chữ.

Không thêm món, sửa dữ liệu dinh dưỡng, ghi Firebase, deploy, commit/push,
đổi Rules, thêm package, dịch vụ hoặc billing trong lượt này.

## File chính

- food_portion_dialog.dart, food_nutrition_panel.dart, food_selection_theme.dart.
- meal_form_dialog.dart, meal_entry_sources.dart, food_selection_card.dart,
  food_photo_thumbnail.dart và registry bundled_food_photos.dart.
- nutrition_models.dart, catalog_food_reader.dart, bundled_vietnamese_foods.dart,
  firebase_nutrition_repository.dart, food_library_models.dart.
- test/food_detail_ui_test.dart và các test hồi quy liên quan.

## Kiểm tra

- `dart format` 20 file ảnh hưởng: 0 thay đổi; `git diff --check`: sạch.
- `flutter analyze`: **No issues found**, exit0, 28,2 giây.
- `flutter test`: **1.210/1.210 qua**, exit0, 2 phút8 giây; log
  `build/food-detail/full-tests-verified.log`.
- Node catalog/photo: **14/14 qua**; hash, ID/tên, giấy phép, khung ảnh,
  kích thước nguồn và tính toàn vẹn catalog đều được kiểm.
- Luồng mới/package/journal tập trung **45/45**; visual/source **25/25**;
  appearance cuối **15/15**, maintenance regression **9/9**.
- Đã xem ảnh render Inter sáng/tối ở 390px/chữ100% và tối320px/chữ200%,
  màn chi tiết, bảng dinh dưỡng, nguyên liệu và danh sách. Kiểm bàn phím và
  phần lẻ qua các test hồi quy hiện có.
- Hai lượt toàn bộ đầu phát hiện thao tác test chưa cuộn tới disclosure
  USDA và danh sách nháp sau thay đổi bố cục. Đã sửa helper/test để cuộn
  đúng; giữ assertion về snapshot, giữ nháp, số lần ghi và thử lại.
- Android debug build cuối: thành công, Gradle34,2 giây. Có cảnh báo KGP
  migration từ plugin hiện hữu, chưa nâng dependencies ngoài phạm vi.
- APK: `build/releases/healthmate-food-detail-20261110-debug.apk`,
  **238.217.196 byte**, SHA-256
  `dd926f4ac31e3e23fab37b76c25e7ecfabd94beeead06c791eaecb639ebf5c6b`.
  Đã đọc ZIP xác minh **51/51 ảnh** đúng hash, manifest và mọi asset dinh
  dưỡng byte-identical với source. `build/food-detail/apk-audit.json`.
- Ảnh xem trước: `build/food-detail/preview-20261110.jpg`.

## Cần người dùng làm và giới hạn

Cài APK mới hoặc chạy lại app để nhận UI/ảnh đóng gói mới. Không cần cấu hình
Firebase mới. Chưa nghiệm thu trên Android vật lý và chưa ký bản phát hành.
Đề xuất giai đoạn tiếp: nghiệm thu luồng chọn/ghi món trên Android thật;
chưa tự thực hiện.
