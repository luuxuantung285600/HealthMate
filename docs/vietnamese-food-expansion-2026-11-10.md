# Mở rộng món Việt, đồ gói và chất lượng ảnh — 10/11/2026

## Phạm vi và kết quả

Giai đoạn 4 bổ sung theo yêu cầu: danh mục thực phẩm và cách trình bày khi ghi
bữa ăn. Thêm **51 mục**, gồm **29 món Việt** và **22 sản phẩm đóng gói**.
Asset Việt tăng từ **162 lên 213 mục**; toàn bộ ba asset có **11.220 mục**.
Các ID, tên, bốn chất dinh dưỡng và khối lượng khẩu phần của 162 mục cũ giữ
nguyên. Không sửa snapshot nhật ký hoặc dữ liệu riêng của người dùng.

29 món mới: bánh bao, bánh chưng, bánh tét, bánh giò, bánh bèo tôm, bánh đúc
nóng, bột chiên, bánh canh tôm thịt bằng bột gạo, bún măng vịt, bún sườn,
cháo cá/tôm/sườn/bí đỏ đậu xanh, xôi đậu phộng/lạp xưởng, cơm chiên hải sản,
bò kho, bò lúc lắc, cá lóc kho tiêu, đậu phụ nhồi thịt, canh khổ qua/bí đỏ/
rau đay/cà chua trứng, trứng chiên/hấp thịt, bắp cải xào và khoai lang luộc.

Đây là **công thức tham khảo/ước tính**, không là kết quả phân tích món hoàn
chỉnh của Viện Dinh dưỡng. Tính qua pipeline hiện có từ nguyên liệu VDD 2007
và khối lượng thành phẩm khai báo. Không thêm món nếu thiếu nguyên liệu có
nguồn; ví dụ bánh bột lọc chưa được thêm khi chưa có tham chiếu bột năng.
Giữ bộ lọc ăn chay/thực phẩm cần tránh theo hướng thận trọng; không tự đoán
phân loại chế độ ăn cho mục mới chưa có metadata được xác minh.

## Sản phẩm đóng gói và nguồn

Số liệu từ trang sản phẩm Acecook Việt Nam, đọc ngày 10/11/2026. Khối lượng
đối chiếu bao bì công bố; phở bò 68 g và phở gà 67 g đối chiếu trang 1 bản
tự công bố vì hình bao bì ở website không thể đọc khối lượng rõ ràng.

| Dòng | Biến thể và khối lượng khô | Nguồn bảng dinh dưỡng |
| --- | --- | --- |
| Hảo Hảo (9) | Tôm chua cay 75 g; gà vàng 74 g; sa tế hành tím 75 g; kim chi 75 g; sườn heo tỏi phi 73 g; chay rau nấm 74 g; xào tôm chua ngọt 75 g; xào hải sản 72 g; BIG tôm chua cay 100 g | [Acecook](https://acecookvietnam.vn/product/mi-hao-hao/) |
| Phở Đệ Nhất (2) | Bò 68 g; gà 67 g | [Acecook](https://acecookvietnam.vn/product/pho-de-nhat/) |
| Miến Phú Hương (4) | Thịt bằm 55 g; sườn heo 55 g; lẩu Thái tôm 60 g; gà 53 g | [Acecook](https://acecookvietnam.vn/product/mien-phu-huong/) |
| Hủ tiếu Nhịp Sống (5) | Nam Vang 70 g; sườn heo 70 g; bò kho 75 g; chay Nam Vang 70 g; khô Nam Vang 72 g | [Acecook](https://acecookvietnam.vn/product/hu-tieu-nhip-song/) |
| Phở trộn Đệ Nhất (2) | Bò 84 g; thập cẩm cay 84 g | [Acecook](https://acecookvietnam.vn/product/pho-tron-de-nhat/) |

Chi tiết mỗi vị ở `data/food_catalog/packaged.json`: bảng nhãn trên một gói,
khối lượng tịnh, chỉ số tab của biến thể, URL ảnh bao bì đối chiếu, SHA-256
của trang nguồn đã đọc, ngày truy xuất và URL bản công bố khi cần.

Chuẩn hóa: **giá trị nhãn một gói × 100 / khối lượng gói**. Ví dụ Hảo Hảo
tôm chua cay 75 g: 350 kcal, 6,9 g đạm, 51,4 g carb, 13 g béo trên một gói;
không gắn số liệu này cho mọi vị Hảo Hảo. Tên và hộp khẩu phần ghi **gói khô**,
nhắc không nhập trọng lượng nước pha; thịt/trứng/rau thêm ghi riêng. Mặc định
một gói hoạt động cả từ asset offline lẫn document Firebase thiếu field
`defaultServingGrams`. Có thể chọn Gram hoặc Khẩu phần và nhập nửa/hai gói.

Số nhãn là giá trị trung bình; app giữ nhãn tham khảo/ước tính và yêu cầu đối
chiếu bao bì đang dùng. Không suy ra món không có chất xơ hay vi chất khi
nguồn chưa cung cấp. Không tự dùng nhãn xuất khẩu hoặc sản phẩm khác cùng tên.

## Ảnh đã kiểm duyệt

- **47 ảnh WebP 512×512**, **2.025.086 byte**, tăng từ 19 ảnh. Thêm 28 ảnh
  cho món Việt, rau và trái cây/nguyên liệu dùng trong bữa ăn.
- Thay ảnh phở gà có người bằng `Homemade "Phở gà" by A.jpeg`, chụp một tô
  từ trên xuống. Thay ảnh bánh xèo/chả giò/bún chả/trứng luộc; cắt lại phở
  bò, bún riêu và các ảnh cũ để loại món khác, người, chai lọ và bàn ăn rối.
- Mỗi khung cuối được xem trực tiếp; không còn người/tay trong ảnh. Không
  phóng lớn nguồn dưới 512 px ở chiều ngắn của vùng cắt. Lưu kích thước vùng
  cắt nguồn và tọa độ trong manifest để kiểm tra lại.
- Chỉ dùng CC0, miền công cộng, CC BY hoặc CC BY-SA. Tác giả, URL nguồn,
  giấy phép, mô tả chỉnh sửa và SHA-256 được giữ trong manifest/attribution.
  Loại nguồn chỉ có GFDL. Credit bánh tét giữ đầy đủ yêu cầu Flickr của tác giả.
- Ảnh minh họa loại món, không dùng để suy ra lượng ăn/dinh dưỡng. Rau trang
  trí nằm trong món vẫn có thể xuất hiện; không gán ảnh món khác để đủ số.
- Ảnh nằm trong **assets của app**, dùng offline; không lưu Firebase Storage.
  Thay ảnh cần cập nhật bản app. Món chưa có ảnh, bao gồm sản phẩm đóng gói
  chưa có ảnh với quyền tái sử dụng được xác minh, vẫn giữ dòng chữ cũ.
  Ảnh bao bì chỉ được dùng đối chiếu khối lượng trong quá trình nghiên cứu,
  không được đưa vào asset sản phẩm khi chưa có giấy phép phù hợp.

Nguồn duy nhất cho registry là `assets/food_photos/manifest.json`.
`node tool/build_food_photo_registry.cjs` kiểm hash trước khi sinh Dart và
ATTRIBUTION.md; chạy Dart format sau khi sinh. Không tải ảnh khi app duyệt món.

## Danh mục chung app/admin

Đã thêm đúng **51 mục** vào `healthmate-app-20261013/food_catalog`, commit
nguyên tử với điều kiện mỗi document chưa tồn tại; không cập nhật/xóa mục cũ.
158 document cũ giữ nguyên toàn bộ fields và timestamps sau khi đọc lại.
51 document mới khớp toàn bộ fields nguồn và có server timestamp. Tổng catalog
trên Firebase: **209 document**; con số này khác 11.220 mục đóng gói trong app.
Admin hiện có listener cho catalog nên nhận được các mục chung mới.

Danh sách cho đợt này ở `data/food_catalog/additions-2026-11-10.json`.
`--ids-file` bắt buộc từng ID hợp lệ, không trùng/không thiếu; tránh nạp các
mục cũ khác vốn chưa được đưa lên cloud ở những lượt trước.

```powershell
node tool/import_food_catalog.cjs --project healthmate-app-20261013 --ids-file data/food_catalog/additions-2026-11-10.json
```

Đã dry-run trước: additions51, updates0, conflicts0. Apply thành công; đọc
lại: oldUnchanged158, newVerified51. Dry-run sau: additions0, skipped51,
updates0, conflicts0. Bằng chứng trong `build/food-photos/live-catalog-audit.json`.
Không deploy app/admin/rules/functions, không thay kiến trúc hoặc bật billing.

## File chính và kiểm thử

- Dữ liệu: recipes.json, packaged.json, additions-2026-11-10.json và asset
  vietnamese-foods.json sinh lại qua pipeline.
- Tooling: build_vietnamese_bundle.cjs giữ đúng nhãn gói/hộp; importer giới hạn
  nguồn nhà sản xuất và xác minh phép quy đổi; registry ảnh và hai bộ Node tests.
- Flutter: catalog_food_reader.dart giữ mặc định một gói từ server;
  food_portion_dialog.dart giải thích khối lượng khô; thumbnail cache 512 px;
  registry ảnh, test ảnh/đồ gói và số lượng bộ dữ liệu đã cập nhật.
- Kiểm thử tập trung ban đầu: **72/72**; sau bổ sung kiểm hồi quy server: **20/20**.
- Node catalog/photo: **14/14**. Kiểm manifest, hash, ảnh giải mã, ID/tên,
  phép quy đổi nhãn, chống nhập trùng, chống thay dữ liệu cũ.
- Toàn Flutter lần đầu: **1.204/1.204**, 2 phút 5 giây; analyze sạch 28,9 giây.
  Toàn Flutter sau sửa fallback server: **1.204/1.204**, exit0, 2 phút6 giây;
  log `quality-full-tests-final.log`. Analyze cuối sạch, exit0, 14 giây;
  `quality-analyze-clean.log`. Format8 file, 0 thay đổi.
- Đã xem ảnh Flutter sáng/tối, màn 390 px/chữ100% và 320 px/chữ200%, bảng
  47 ảnh cuối và ảnh nguồn. Không thay assertion nghiệp vụ để che lỗi; cập
  nhật các assertion số mục theo 51 mục mới. Lỗi kiểm thử đầu là số lượng cũ
  và URL giấy phép HTTP; đã chuyển liên kết giấy phép sang HTTPS.
- Android debug build cuối: exit0, Gradle15 giây;
  `quality-android-debug-build-final.log`. Cảnh báo migration Kotlin của plugin
  hiện hữu vẫn còn; không nâng dependencies ngoài phạm vi.
- APK: `build/releases/healthmate-vietnamese-foods-20261110-debug.apk`,
  **238.196.712 byte**, SHA-256
  `233E1473D15B26B721A851608DDBF5E834DD5C5ED04B90A886542A92120CF767`.
  Đọc ZIP xác minh47/47 ảnh đúng hash, manifest/attribution đúng file nguồn,
  ba asset dinh dưỡng khớp byte và đủ11.220 mục. Báo cáo
  `build/food-photos/quality-apk-asset-audit.json`.

Chưa nghiệm thu trên Android vật lý hoặc ký phát hành. Bước tiếp đề xuất:
nghiệm thu luồng ghi bữa ăn trên thiết bị; chỉ thực hiện khi người dùng yêu cầu.
