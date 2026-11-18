# Giai đoạn 1 — Bảo trì UI system: icon, giao diện đen và vòng calo

Phạm vi yêu cầu bắt đầu 16/11, hoàn thiện 17/11/2026: đổi bộ icon app,
thống nhất màu các luồng và chia màu dưỡng chất trên vòng calo. Không thay đổi
cách tính mục tiêu, quyền truy cập hay nghiệp vụ ghi nhật ký.

## Kết quả

- Thay Phosphor bằng **Tabler Icons 3.52.0**, MIT của Paweł Kuna. Giữ đủ
  142 tên API AppIcons; tạo 116 glyph có nét trong font offline 33.432 byte.
  Icon nét ở trạng thái thường, icon đặc cho tab đang chọn. Mục tiêu dùng
  biểu tượng bia, nhiệm vụ dùng checklist để phân biệt rõ hơn.
- Nền tối đen thật, card xám trung tính, nút/chip/badge/thanh điều hướng cùng
  tông. Chế độ sáng vẫn trắng. Áp dụng từ theme và AppFeatureVisual dùng chung
  cho đăng nhập/thiết lập ban đầu, nhật ký/chọn món, tập luyện, hồ sơ, báo cáo,
  chatbot, hỗ trợ và Premium. Bỏ màu tím của biểu đồ giấc ngủ, nền vàng của
  nút nâng cấp, màu riêng trên điều khiển tính năng và phần quét mã.
- Duy trì màu dữ liệu có nghĩa: đạm san hô `#F18B88`, tinh bột xanh lam
  `#79A8F2`, chất béo vàng `#EEC45A`. Danh sách món, chi tiết món, trang chủ
  và báo cáo dùng cùng palette. Nhãn bữa ăn và trạng thái lỗi vẫn có dấu hiệu
  màu nhỏ; ảnh/GIF món ăn và bài tập giữ nguyên nội dung.
- Vòng calo lấy tổng của ngày đang chọn từ repository hiện có. Độ dài phần
  đã tô là `consumedKcal / targetKcal`, giới hạn từ 0 đến 1. Ba đoạn trong
  phần đó chia theo năng lượng quy đổi `proteinG × 4`, `carbsG × 4`,
  `fatG × 9`, chuẩn hóa theo tổng ba giá trị. Không coi tổng quy đổi luôn bằng
  kcal trên nhãn/catalog. Chú thích màu và nút giải thích nêu rõ hai ý này.
- Không thêm đường, chất xơ hay muối thành đoạn năng lượng để tránh cộng trùng.
  Thiếu bất kỳ macro nào hoặc có giá trị âm/không hữu hạn: giữ tiến độ màu
  xám, hiện thông báo chưa đủ dữ liệu. Macro bằng 0 không được tô đoạn giả.
  Chưa có mục tiêu/đang tải không bị đọc thành tiến độ 0% đã xác định.
- Giữ trạng thái vượt mục tiêu, thay đổi ngày, cập nhật/xóa bữa và nguyên tắc
  chỉ cộng vận động khi đã xác nhận. Thay ký hiệu phút không đủ glyph trong
  font bằng chữ “phút”. Public Sans vẫn là font chữ hiện tại.

## File chính

- `tool/build_app_icons.py`, font/manifest/LICENSE trong
  `assets/fonts/healthmate_icons/`, `lib/core/theme/app_icons.dart`.
- `lib/core/theme/{app_theme,app_colors,app_feature_visuals,reference_palette,design_tokens}.dart`;
  `lib/core/widgets/feature_icon_badge.dart`.
- `lib/features/dashboard/models/calorie_ring_data.dart`;
  `presentation/widgets/{calorie_macro_ring,mfp_calories_card}.dart` và
  `presentation/dashboard_screen.dart` trong cùng feature.
- `lib/features/nutrition/presentation/food_selection_card.dart`;
  `lib/features/food_scanner/presentation/{barcode_product_detail_sheet,barcode_scanner_screen,food_camera_view}.dart`;
  `lib/features/wellness/presentation/wellness_hub.dart`.
- `test/{calorie_macro_ring,home_reference,icon_system}_test.dart`.

## Nguồn và cách tạo icon

- Repository chính thức: https://github.com/tabler/tabler-icons
- Gói đã kiểm tra: https://www.npmjs.com/package/@tabler/icons-webfont/v/3.52.0
- Font đầu ra SHA-256:
  `4b951628f9c262b78dc9e8b837ee61866faa3e5601a8b3101c26f01a66884e15`.
- Generator ghim phiên bản và SHA-256 từng font/CSS/LICENSE. `--verify` chạy
  offline, kiểm glyph không rỗng, cmap liên tục, alias, trạng thái selected,
  hash và giấy phép. Không thay generator/asset icon của admin trong lượt này.
- Công cụ tạo font dùng fontTools 4.61.0 đặt tại `build/ui-tools/python`;
  đây là công cụ build local, không thêm dependency Flutter hay tải icon khi
  người dùng mở app. Khi chạy bằng Python bundled, chèn đường dẫn đó vào
  `sys.path` trước `runpy.run_path('tool/build_app_icons.py', run_name='__main__')`.
- Upstream báo `2 extra bytes in post.stringData array`; font tạo xong, kiểm
  cmap/hash/glyph qua và đã xem ảnh render thực tế của bộ icon.

## Kiểm tra thực tế

- `dart format --output=none --set-exit-if-changed` 19 file Dart trong phạm vi:
  qua, 0 file cần sửa, 0,09 giây. Generator `--verify` cuối và diff-check qua.
- `flutter analyze`: **không có issue**, exit 0, 19,2 giây.
- `flutter build web --release --no-pub --output build/neutral-ui-20261116/web`:
  **qua**, exit 0, 60 giây; font Tabler sau tree-shake 33.140 byte. Bản JS web
  build được. Dry run WebAssembly báo `mobile_scanner` còn dùng `dart:html`/
  `package:js`; chưa hỗ trợ build Wasm và không đổi package ngoài phạm vi.
- `flutter test` 14 suite dưới đây: **187/187 qua**, exit 0, 23 giây:
  `calorie_macro_ring`, `home_reference`, `icon_system`, `navigation_features`,
  `ux_onboarding`, `workout_ux`, `food_detail_ui`, `play_premium_flow`,
  `barcode_scanner`, `reference_ui`, `progress_comparison_ui`,
  `auth_flow_capture`, `support`, `chatbot` (hậu tố `_test.dart`).
- Có kiểm tra pixel của ba màu và track; tỷ lệ 4/4/9 khác kcal catalog;
  macro 0/thiếu/âm/NaN/vô hạn/tràn số; không có mục tiêu; vượt mục tiêu;
  cập nhật/xóa bữa thật qua fake repository và UI; semantic label/chú giải;
  màn 320 px, chữ 2x, sáng/tối, layout tablet theo các suite hiện có.
- Đã xem render thực tế của icon sheet, trang chủ có bữa kiểm thử và card
  sáng/tối. Ảnh tại `build/icon-system/`, `build/home-reference/` và
  `build/neutral-ui-20261116/`. Các số trong ảnh là fixture kiểm thử, không
  ghi dữ liệu mẫu lên tài khoản hay Firebase production.
- Log: `build/neutral-ui-regression.log`,
  `build/neutral-ui-analyze-final.log`, `build/neutral-ui-build-web.log`.
- Các lượt đầu: test raster bị treo do await `toImage` trong fake async;
  chuyển sang test async thường. Bốn test accessibility báo handle chưa đóng;
  sửa vòng đời bằng `try/finally`. Analyze có một lint thiếu ngoặc khối, đã
  sửa. Không bỏ assertion và không tính các lượt lỗi là lượt thành công.

## Sử dụng và giới hạn

- Dừng và chạy lại app để chắc chắn nạp font icon mới. Không cần cấu hình
  Firebase bổ sung. Bản đang được host cần build/deploy riêng để nhận code mới.
- Kiểm thử UI dùng fixture/fake repository; không thay thế nghiệm thu Android
  vật lý hay kiểm thử toàn hệ thống trên môi trường thật. Không thực hiện ký
  phát hành, push GitHub, deploy, thay rule/schema hay ghi dữ liệu production.
- Đề xuất tiếp theo: Giai đoạn 10 — nghiệm thu giao diện trên thiết bị người
  dùng; chưa thực hiện giai đoạn tiếp theo.
