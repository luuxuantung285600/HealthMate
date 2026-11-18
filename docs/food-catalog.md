# Mở rộng Food Catalog — 16/10/2026
## Cập nhật 10/11/2026 — natri và đường có nguồn

Đã bổ sung từ Acecook, bảng Việt Nam 2007 và bốn mục USDA cũ: 106 mục có natri,
74 mục có đường tổng trong nhóm 213 mục Việt Nam/đồ gói. Chất xơ tổng vẫn 4 mục;
không đánh đồng Celluloza hoặc trường nguồn bỏ trống với chất xơ tổng/số 0.
Các phần mô tả thiếu vi chất bên dưới ghi nhận trạng thái lịch sử tại 16/10.
Đã phát hành version `verified-nutrients-2026-11-10-v1` lên catalog online:
110 cập nhật + 110 audit, đọc lại xác minh đủ; không đổi snapshot nhật ký cũ.
Web admin có dòng đường/natri/muối trong chi tiết món.
[Báo cáo phát hành](verified-nutrients-release-2026-11-10.md).
[Báo cáo nguồn, đơn vị và kiểm thử](vietnamese-nutrients-2026-11-10.md).


## Phạm vi và dữ liệu đã nạp

Theo yêu cầu bổ sung món Việt và món cơ bản (phạm vi Food Catalog/Giai đoạn 4),
đã thêm **148 mục** vào `food_catalog` của project `healthmate-app-20261013`.
Catalog có **158 mục** sau lần nạp: 10 mục USDA cũ được giữ nguyên toàn bộ
document, 101 mục tham chiếu mới và 47 món từ công thức ước tính.

Các nhóm gồm ngũ cốc/bún/bánh, đậu/hạt, rau/củ/nấm, trái cây, thịt/trứng,
hải sản, sữa/chế phẩm, chất béo/gia vị và món nhà. Món chế biến có phở bò/gà,
bún bò Huế, bún riêu, bún chả, bún thịt nướng, hủ tiếu, mì Quảng, miến/mì xào,
cơm tấm sườn, cơm gà, cơm chiên, bánh mì, bánh cuốn, bánh xèo, gỏi cuốn, chả giò,
cháo, xôi, canh, thịt kho, rau luộc/xào và chè. Một số món được ghi rõ bản giản lược.

Danh sách đầy đủ ở `data/food_catalog/ingredients.json` và `recipes.json`.
Không tạo nhật ký mẫu, không sửa snapshot bữa đã lưu, không thay danh mục bằng
dữ liệu trong bộ nhớ của app. Catalog tiếp tục được đọc qua repository Firestore.

## Nguồn và cách tính

101 mục tham chiếu dùng **Bảng thành phần thực phẩm Việt Nam (Viện Dinh dưỡng,
2007)**, bản gốc được FAO lưu tại
[nguồn PDF](https://www.fao.org/fileadmin/templates/food_composition/documents/pdf/VTN_FCT_2007.pdf).
Đây là nguồn năm 2007, không quảng bá là bảng mới nhất. Mỗi mục có mã thực phẩm,
số trang **PDF tính từ 1** và bốn giá trị số kcal/protein/glucid/lipid trên 100 g
phần ăn được. Tên/alias do HealthMate diễn đạt; không phân phối lại toàn bộ sách.
Đã đối chiếu bố cục/cột bằng render trang PDF và trích xuất dữ liệu gốc.

Giữ trạng thái của thực phẩm theo nguồn: thịt/cá/trứng sống bỏ phần không ăn,
gạo/bột/miến khô, rau sống, trái cây phần ăn được và những mục chín được ghi
rõ. Không dùng 100 g gạo khô như 100 g cơm chín. Các mục từ nhiều nguồn có thể
khác giống, hàm lượng nước, cách xác định carbohydrate và cách chế biến.

47 món chế biến dùng công thức **do HealthMate giả định**, không phải kết quả
phân tích món hoàn chỉnh do Viện Dinh dưỡng công bố:

```
tổng dưỡng chất = Σ(dưỡng chất nguyên liệu trên 100 g × g nguyên liệu / 100)
dưỡng chất trên 100 g thành phẩm = tổng dưỡng chất × 100 / g thành phẩm
```

Công thức lưu gram nguyên liệu theo trạng thái của mục tham chiếu, gram thành
phẩm giả định và lượng dầu/đường. Giả định giữ lại toàn bộ dưỡng chất nguyên
liệu ăn được và dầu/đường đã khai báo; chưa áp dụng hệ số thất thoát dinh dưỡng.
Khối lượng thành phẩm có thể tăng do nước hoặc giảm do chế biến. Nước dùng được
mô hình hóa bằng nước cùng dầu/gia vị liệt kê, không có nghĩa nước dùng thực tế
không chứa năng lượng. Thành phần nước mắm/gia vị khác chưa được chuẩn hóa;
không có dữ liệu natri, chất xơ hay vi chất. Thêm lượng gia vị/dầu khác nếu thực
tế khác đáng kể; món ngoài quán có thể chênh lệch nhiều so với công thức này.

Ví dụ phở bò trong công thức có 600 g thành phẩm, không coi một tô = 100 g.
Giao diện vẫn hỏi **khối lượng đã ăn (g)**. Tất cả mục mới `isEstimated: true`,
hiển thị nhãn **Ước tính**, nguồn và đơn vị. Công thức không khẳng định đây là
khẩu phần tiêu chuẩn hoặc số liệu đúng cho mọi quán/nhãn hàng.

Dấu `-` trong nguồn là thiếu dữ liệu, không phải 0. Không tự điền 0 cho số thiếu.
Riêng bún tươi có lipid thiếu trong dòng nguồn nên không nhập trực tiếp dòng
đó: dùng công thức ước tính bột gạo/khối lượng thành phẩm và ghi rõ trong tên.

## File và thay đổi giao diện

- `data/food_catalog/ingredients.json`: dữ liệu nguồn cùng mã/trang/basis.
- `data/food_catalog/recipes.json`: giả định công thức, yield, thành phần và giới hạn.
- `tool/import_food_catalog.cjs`: validate, tính công thức, dry-run và nạp quản trị.
- `tool/food_catalog.test.cjs`: 7 test dữ liệu, tính toán và giới hạn thao tác ghi.
- `lib/features/nutrition/models/food_catalog_search.dart`: chuẩn hóa tiếng Việt,
  dấu/không dấu, ký tự NFD, chữ hoa và khoảng trắng; tìm cả tên lẫn alias.
- `lib/features/nutrition/presentation/meal_form_dialog.dart`: ban đầu 12 kết quả,
  **Xem thêm món** theo từng 12 mục; tìm trên toàn catalog, reset phần hiển thị
  khi đổi từ khóa, nhãn ước tính và nhắc nhập gram thành phẩm. Không thêm số
  lượng catalog lên giao diện. Không phát sinh query tìm kiếm mới.
- `test/food_catalog_test.dart`: 4 test tìm kiếm, phân trang ở textScale 1.0/1.5
  và lưu snapshot khẩu phần ước tính.
- README, database-design và implementation-progress được cập nhật.

## Nạp dữ liệu có kiểm soát

Không cài package, không đưa key/service-account vào repo. Bộ nạp dùng Firebase
CLI đã đăng nhập và REST API quản trị; app client vẫn không có quyền ghi catalog.

```powershell
node --test tool/food_catalog.test.cjs
# Chỉ đọc/kiểm tra, chưa ghi:
node tool/import_food_catalog.cjs --project <project-id>
# Chỉ dùng khi chủ động yêu cầu nạp vào project đã kiểm tra:
node tool/import_food_catalog.cjs --project <project-id> --apply
```

Không mặc định chọn production. Kiểm tra schema, nguồn, số hữu hạn, ID/tên trùng,
trạng thái ước tính, đơn vị và tổng khối lượng macro trước khi nạp. Chỉ tạo mục
thiếu ID/tên chuẩn hóa, mỗi write có `currentDocument.exists: false`, chỉ cho
đường dẫn `food_catalog/{id}`. Một commit nguyên tử cho toàn bộ phần thêm mới;
không có delete hoặc overwrite. Nếu commit bị gián đoạn/HTTP lỗi, chạy lại
dry-run trước để đọc trạng thái server, không suy đoán có/không có ghi.

Bộ nạp chạy lại không tự nâng cấp mục đã có. Khi sửa công thức sau này cần
review dữ liệu/version và quy trình cập nhật riêng; không đổi snapshot lịch sử.
Không deploy Rules/indexes, không tắt bảo vệ, không thay Firebase project hoặc
bật billing. Metadata quản trị mới trong catalog: `sourceUrl`, `catalogVersion`,
`sourceDetails`; không thay model snapshot nhật ký hoặc schema sức khỏe dưới UID.

## Kết quả thật đã chạy

- `node --test tool/food_catalog.test.cjs`: **7/7 pass**.
- `dart format lib test tool`: 138 file; kiểm tra lại
  `dart format --output=none --set-exit-if-changed lib test tool`: **0 thay đổi**.
- `flutter analyze --no-pub`: **No issues found**, 7,1 giây.
- `flutter test --no-pub test/food_catalog_test.dart`: **4/4 pass**.
- `flutter test --no-pub`: **138/138 pass**, khoảng 12 giây.
- Dry-run production trước nạp: existing10/additions148/skipped0.
- Apply: commit thành công **148 mục mới**. Đọc lại so sánh toàn bộ fields mới
  với dữ liệu build và kiểm tra server timestamp; **148/148 khớp**.
- Đọc lại so sánh toàn bộ document cũ, gồm timestamps: **10/10 giữ nguyên**.
  Tổng **158**, không còn trang tiếp theo. Dry-run sau nạp:
  existing158/additions0/skipped148, xác nhận chạy lại không tạo trùng.
- `git -c core.safecrlf=false diff --check`: sạch. Không commit/push. Các thay
  đổi chưa commit từ các giai đoạn trước được giữ nguyên.

Không build APK mới, không chạy Rules emulator lại vì không sửa Rules hoặc
dependency trong lượt này. Không kiểm tra bằng mắt trên điện thoại; widget
tests xác minh giao diện chọn món với dữ liệu giả. Mở lại **Thêm bữa ăn** với mạng
để listener nhận catalog mới; chạy lại bản code mới để dùng tìm không dấu và
Xem thêm món. Nhập thử `pho bo`, `com tam`, `dau phu`.

Phạm vi này đã xong; không chuyển sang tính năng hoặc giai đoạn khác.

## Cập nhật 10/11/2026 — món Việt, đồ gói và ảnh

Đã thêm 29 công thức món Việt và 22 sản phẩm Acecook có nguồn riêng từng vị;
asset Việt hiện có 213 mục, tổng ba asset là 11.220. Danh mục Firebase chung
đã thêm đúng 51 mục mới và đạt 209 document; đọc lại xác nhận 158 document cũ
giữ nguyên. Có 47 ảnh 512×512 đã xem/cắt loại người và món ngoài lề.
Chi tiết nguồn, phép quy đổi nhãn gói khô, lệnh nạp có giới hạn ID, kiểm thử
và giới hạn ảnh: [báo cáo 10/11](vietnamese-food-expansion-2026-11-10.md).


## Cập nhật giao diện chọn món và ảnh nguyên liệu — 10/11/2026

Bản giao diện tiếp theo có **51 ảnh 512×512** (thêm tỏi, hành tây sống,
dưa leo sống và tôm bóc vỏ sống), chi tiết món, biểu đồ theo khẩu phần,
bảng dinh dưỡng và nguyên liệu tham khảo từ sourceDetails/công thức riêng.
Không đổi số món hoặc giá trị dinh dưỡng. Không ghi catalog Firebase trong
lượt giao diện này. Bỏ dropdown loại bữa ở màn thêm món; model và dữ liệu
lịch sử giữ tương thích. Dưỡng chất chưa có nguồn không được tự điền.
Xem [báo cáo giao diện](food-selection-detail-2026-11-10.md).
# Bổ sung 10/11/2026 — 100 mục trái cây, 100 mục đồ uống

Danh sách chuẩn hóa tại `data/food_catalog/fruit-drink-browse.json` có 100
mục mỗi nhóm, gồm các trạng thái/giống khác nhau. App có bộ lọc và ưu tiên
các mục này; các tham chiếu cũ vẫn tìm được. 27 dòng VDD mới đưa catalog
cơ sở lên 240 và toàn offline lên 11.247; không đổi dinh dưỡng USDA hiện có.
63 đồ uống có cốc quy đổi bằng gram weight nguồn; không tự coi1ml=1g.
Firebase đã thêm177 mục/audit tương ứng, giữ209 mục cũ, tổng386. Cần APK
mới để có UI nhóm. Nguồn, giới hạn, kiểm thử và quy trình phát hành:
[fruit-drink-catalog-2026-11-10.md](fruit-drink-catalog-2026-11-10.md).


## Bổ sung 10/11/2026 — danh mục chung 500 mục

Phát hành114 mục VDD2007 mới bằng tool/publish_catalog_500.cjs (create-only),
đọc lại xác minh386 document cũ nguyên vẹn và114 audit mới. Tổng food_catalog
là500; core asset354; toàn offline11.361 ID tham khảo. Có17 mục đồ hộp/mứt
mới, không gán brand/barcode/khối lượng lon khi nguồn không có. Dinh dưỡng
thiếu giữ thiếu; cellulose không được dùng làm tổng chất xơ.

Thêm35 ảnh miễn phí có giấy phép, tổng86 ảnh, đều thuộc500 mục chung.414
mục còn thiếu ảnh giữ giao diện chữ; chưa hoàn thành ảnh toàn danh mục.
Ảnh gói Hảo Hảo75g khớpbarcode8934563138165, không dùng cho vị khác.
Nguồn, giới hạn, kiểm thử, readback và APK:
[catalog-500-2026-11-10.md](catalog-500-2026-11-10.md).
