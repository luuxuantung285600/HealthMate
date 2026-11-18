# Ảnh minh họa món và ưu tiên món Việt — 10/11/2026

> Báo cáo dưới đây là đợt ảnh đầu (19 ảnh). Yêu cầu bổ sung cùng ngày đã được
> hoàn thành với 47 ảnh 512×512, thay ảnh phở gà có người và thêm 51 món/đồ gói.
> Xem [kết quả cập nhật](vietnamese-food-expansion-2026-11-10.md).

## Phạm vi

Giai đoạn 11, hoàn thiện giao diện ghi bữa ăn theo yêu cầu. Thêm ảnh bên cạnh
tên, lượng ăn, kcal và ba chất; đưa món Việt lên trước trong gợi ý. Theo yêu
cầu bổ sung của người dùng, món chưa có ảnh giữ dòng chữ cũ, không có ảnh
thay thế hoặc cột ảnh trống. Không triển khai tính năng ngoài luồng này.

## Lưu ảnh và quyền sử dụng

- **19 ảnh**, WebP **256×256**, tổng **294.392 byte**, được đóng gói trong
  `assets/food_photos/`. Hiển thị offline và không phát sinh yêu cầu tải ảnh
  khi duyệt danh sách.
- **Không lưu trên Firebase/Cloud Storage**; không tải ảnh chụp bữa của người
  dùng lên một nơi lưu trữ mới. Không thêm dịch vụ, dependency hoặc billing.
- Nguồn là Wikimedia Commons với giấy phép CC0, miền công cộng, CC BY hoặc
  CC BY-SA. Chỉ dùng bản ghi đã đối chiếu tên/mô tả và xem ảnh. Mỗi tệp có
  tác giả, trang gốc, giấy phép, mô tả cắt/thu nhỏ và SHA-256 trong
  `assets/food_photos/manifest.json` cùng `ATTRIBUTION.md`.
- Bấm ảnh trong app để xem ảnh lớn, tác giả, giấy phép và các liên kết nguồn.
  Chỉ khi người dùng bấm liên kết mới mở trình duyệt. Giấy phép gốc tiếp tục
  áp dụng cho ảnh đã cắt khung/chuyển WebP, không áp lên mã nguồn ứng dụng.
- Ảnh chỉ minh họa loại món. Công thức, cách chế biến và lượng thực tế có thể
  khác; ảnh không là nguồn tính dinh dưỡng hoặc bằng chứng về lượng đã ăn.

Các món có ảnh: phở bò/gà, cơm tấm sườn, bún bò Huế, bún chả, bún thịt nướng,
bún riêu, bánh mì thịt, bánh cuốn thịt, bánh xèo tôm thịt, gỏi cuốn tôm thịt,
chả giò, thịt kho trứng, cơm trắng, cơm gạo lứt, trứng luộc, táo, chuối,
bông cải xanh sống. Không gắn ảnh của món gần giống cho những món còn thiếu.

Ảnh được nối bằng **ID và tên món đã đối chiếu**. Khi admin đổi ID hoặc tên
thành món khác, app không gắn nhầm ảnh cũ. Món riêng có cùng tên không tự
thừa hưởng ảnh của một ID khác. Muốn bổ sung/đổi ảnh đóng gói cần cập nhật
asset, metadata và bản app; chưa có chức năng admin tải ảnh động.

## Hành vi ứng dụng

- Màn thêm bữa ăn: món có ảnh dùng thẻ gồm ảnh, tên, dinh dưỡng trên 100 g
  và nút thêm. Yêu thích, gần đây và hay dùng giữ nguyên thao tác hiện có.
- Hộp khẩu phần và phần món đã chọn cũng hiện ảnh khi có. Số liệu ở món đã
  chọn dùng đúng lượng đã nhập; không lấy lượng hoặc calo từ ảnh.
- Bấm ảnh chỉ mở nguồn minh họa, không thêm món hoặc lưu bữa. Nút thêm vẫn
  mở hộp xác nhận lượng; nút lưu vẫn qua repository và lưu snapshot như trước.
- Thiếu một giá trị macro thì hiển thị chưa biết, không thay bằng 0.
- Gợi ý sắp xếp món ăn Việt/món nhà trước, kế đến nguyên liệu Việt và các
  nguồn khác. Danh sách đầu có phở, cơm tấm, bún, bánh mì và gỏi cuốn.
  Đây là thứ tự khám phá do sản phẩm chọn, không là thống kê số người ăn
  hoặc lời khuyên dinh dưỡng.
- Khi tìm kiếm, độ khớp tên/alias được xét trước. Nếu độ khớp ngang nhau,
  món Việt được ưu tiên; tìm không dấu vẫn hoạt động. Không thay ID hoặc
  số dinh dưỡng, không sửa lịch sử, không bỏ bộ lọc chế độ ăn/thực phẩm
  cần tránh hay trạng thái ẩn từ admin.

## File chính

- `models/food_photo.dart`, `data/bundled_food_photos.dart`: mô tả ảnh và
  bảng nối ảnh đã kiểm chứng, thuộc feature nutrition.
- `presentation/food_photo_thumbnail.dart`, `food_selection_card.dart`:
  hiển thị ảnh/nguồn và thẻ món; fallback text-only cho món chưa có ảnh.
- `meal_entry_sources.dart`, `meal_form_dialog.dart`, `meal_food_sources.dart`,
  `food_portion_dialog.dart`: tích hợp vào luồng chọn và xác nhận món.
- `food_catalog_search.dart`: ưu tiên món Việt và xử lý hòa điểm tìm kiếm.
- `pubspec.yaml`: khai báo thư mục asset, không thêm package.
- `test/food_photos_test.dart`, `test/catalog_expansion_test.dart` và báo cáo.

## Kiểm thử và giới hạn

- Bộ tập trung cuối 8 file: **69/69**, exit 0, gồm 9 ca mới và hồi quy H1.
  Log `build/food-photos/focused-tests-verified.log`.
- Đã kiểm 19/19 ảnh giải mã đúng 256×256, ID/tên khớp catalog, metadata
  khớp bảng nối; kiểm SHA-256 và dung lượng bằng Python/Pillow. Kết quả
  `build/food-photos/asset-audit.json`.
- Đã xem ảnh Flutter sáng/tối ở 390px chữ 100% và 320px chữ 200%; ảnh
  `build/food-photos/meal-{light,dark}-{1,2}.png`. Đã xem bảng ảnh nguồn
  trước khi chọn; bảng WebP cuối ở `approved-photos.jpg` trong cùng thư mục.
- Format 11 file: exit 0, không còn thay đổi. `flutter analyze`: exit 0,
  **No issues found**, 38,1 giây; log `build/food-photos/analyze-complete.log`.
- Toàn bộ `flutter test --reporter expanded` cuối: **1.201/1.201**, exit 0,
  2 phút 13 giây; log `build/food-photos/full-tests-verified.log`.
- `flutter build apk --debug` với cấu hình debug riêng ngoài repo: exit 0,
  Gradle 32,2 giây; log `build/food-photos/android-debug-build-verified.log`.
  Plugin hiện hữu còn cảnh báo migration KGP, không có lỗi build. Không nâng
  package ngoài phạm vi để xử lý cảnh báo tương lai.
- Bản cài: `build/releases/healthmate-food-photos-20261110-debug.apk`,
  **238.196.862 byte**, SHA-256
  `8D52FE43D130E1A99B081BE002BB9EDACE97104C0D5EDF20D1B0E7394BA96D20`.
  Đọc ZIP của APK xác nhận **19/19** ảnh có hash đúng và có attribution/
  manifest đóng gói; kết quả `build/food-photos/apk-asset-audit.json`.
- `git diff --check`: exit 0, chỉ có cảnh báo LF/CRLF.
- Lỗi trung gian đã sửa: biến metadata ảnh đặt nhầm trong hàm đổi đơn vị;
  test mới dùng một alias vốn đã khớp chính xác như thể đó là khớp một phần;
  test bộ lọc cũ dựa vào thứ tự chưa sắp xếp khiến hàng chưa được lazy-build.
  Test bộ lọc cuối vẫn kiểm từng món được khôi phục bằng thao tác cuộn tới
  hàng đó; không bỏ assertion hoặc đổi kết quả nghiệp vụ mong đợi.
- Lượt toàn bộ trước có 1.200 test qua và 1 lỗi hồi quy H1: thứ tự hai
  kết quả cùng nhóm và độ khớp bị đổi bởi tie-break theo tên. Đã sửa code
  để giữ thứ tự trước đó trong cùng nhóm thay vì sửa test H1. Món Việt
  chỉ thắng khi độ khớp ngang nhau và nhóm khám phá khác nhau.
- Chưa nghiệm thu Android vật lý/ký phát hành. Không sửa Rules/schema/query
  Firestore, không chạy lại emulator cho thay đổi asset/UI này. Không deploy
  hoặc push GitHub trong lượt.

Không cần người dùng cấu hình thêm. Bước tiếp đề xuất: bổ sung ảnh cho các
món còn thiếu theo cùng quy trình kiểm nguồn khi có yêu cầu; chưa thực hiện.
