# Cập nhật dữ liệu thực phẩm — 27/10/2026

Phạm vi: bảo trì Food Catalog thuộc Giai đoạn 4. Bổ sung dữ liệu mới có nguồn
chính thức, không đổi kiến trúc, không ghi Firestore production, không sửa
nhật ký hoặc đổi ID đã dùng. Số đếm là mục thực phẩm/biến thể, không phải món
độc nhất hay sản phẩm Việt Nam.

## Nguồn đã đưa vào app

| Nguồn | Phiên bản chính thức | Đã thêm | Phạm vi và độ tin cậy |
| --- | --- | ---: | --- |
| USDA Foundation Foods | Bản tải 04/2026 | 308 | Thực phẩm cơ bản, metadata về phân tích/mẫu; một số dưỡng chất được tính toán |
| USDA FNDDS | Khảo sát 2021–2023, phát hành 10/2024 | 3.255 | Thực phẩm/món dùng trong nghiên cứu khẩu phần; có dữ liệu biên soạn từ nguồn tham khảo/công thức |
| Danh mục trước | Việt Nam 2007, công thức ước tính, nhãn hãng và USDA SR Legacy 2018 | Giữ 7.606 | Giữ khả năng tra cứu lại thực phẩm đã dùng |
| **Tổng đóng gói tại 27/10** | | **11.169** | Hoạt động offline, không cần API key |

**Cập nhật 10/11/2026:** đã bổ sung 51 món Việt/đồ gói, tổng hiện tại **11.220**.
Nguồn từng nhãn, khối lượng khô, kiểm thử và 47 ảnh mới được ghi tại
[báo cáo mở rộng](vietnamese-food-expansion-2026-11-10.md). Các phép đo dưới đây
ghi nhận phiên bản danh mục tại thời điểm 27/10.

Nguồn kiểm tra ngày 27/10/2026:

- [USDA — các bản tải mới nhất](https://fdc.nal.usda.gov/download-datasets/).
- [USDA — Foundation Foods và phương pháp](https://fdc.nal.usda.gov/Foundation_Foods_Documentation/).
- [USDA — tài liệu các loại dữ liệu](https://fdc.nal.usda.gov/data-documentation/).
- [USDA — quyền sử dụng CC0/public domain](https://fdc.nal.usda.gov/api-guide/).

**Ngày phát hành bộ tải khác ngày công bố bản ghi và ngày lấy mẫu/đo.**
Trong JSON Foundation tải về có 395 phần tử: 363 bản ghi và 32 giá trị null.
Các bản ghi nhập hợp lệ có ngày công bố từ 2019 đến 18/12/2025. Không có cơ sở
để gọi chúng là phép đo năm 2026. App hiển thị cả bản phát hành và ngày công
bố của từng mục Foundation. FNDDS 2021–2023 cũng không có nghĩa mọi thành phần
được phân tích trong giai đoạn đó; một phần kế thừa các bảng thành phần cũ.

## Tuyển chọn và chuyển đổi

- Foundation: bỏ 32 null, 52 mục thiếu kcal hoặc macro chính, 3 mục thuộc dinh
  dưỡng chuyên biệt; còn 308. Không điền dữ liệu thiếu bằng 0.
- FNDDS: bỏ 206 mục trẻ nhỏ/chuyên biệt/thành phần dùng trong công thức, 1 mục
  thiếu macro, 1.970 mục chưa có bản dịch đầu tên được rà soát; còn 3.255.
  Đây là tập con có chọn lọc, không phải toàn bộ FNDDS.
- Giữ tên gốc, FDC ID, URL, ngày phát hành/ngày công bố, mã dưỡng chất năng
  lượng, cơ sở 100 g. Giữ cờ giá trị tham khảo/ước tính.
- Foundation chọn năng lượng Atwater specific 2048, tiếp đến general 2047,
  cuối cùng Energy 1008; FNDDS dùng 1008. Đây là chính sách chọn của HealthMate
  dựa trên định nghĩa USDA, không phải quy tắc ưu tiên bắt buộc do USDA đặt.
  Chỉ nhận đơn vị kcal, không cộng các loại năng lượng hoặc dùng kJ thành kcal.
- Protein/carb/fat/fiber dùng g, các khoáng/vitamin được nhập dùng đúng mg
  tương ứng. Giá trị 0 có trong nguồn được giữ; thiếu vẫn là chưa biết.
- Chỉ quy đổi khẩu phần có số lượng và đơn vị rõ: thêm 34 mục Foundation,
  2.192 mục FNDDS có đơn vị gia dụng được hỗ trợ. Các mục khác nhập bằng gram.
  Không dùng mã modifier, RACC, lượng không xác định hoặc phần xương bỏ đi
  làm khẩu phần.
- Món FNDDS chưa có danh sách nguyên liệu đầy đủ được để `ingredientsKnown:
  false`, chế độ ăn `unknown`. Khi người dùng khai báo thực phẩm cần tránh,
  các món chưa rõ thành phần bị loại theo cơ chế đang có. Không chứng nhận
  món là an toàn dị ứng hoặc thuần chay từ tên món.
- Tên hiển thị Việt rút gọn có thể lược bớt chi tiết về giống/cắt thịt/nhãn;
  tên gốc vẫn mở được trước khi xác nhận. Không gán số mới vào món Việt chỉ
  vì tên gần giống.

## Các nguồn mới khác đã tìm nhưng chưa nhập

**Bảng thành phần thực phẩm Việt Nam 2017** của Bộ Y tế có trong danh mục FAO,
nhưng được mô tả là sách in. Chưa tìm được bộ số chính thức cùng quyền tái sử
dụng để đưa vào ứng dụng. Do đó chưa thay bảng Việt Nam 2007 bằng số liệu
chép từ blog hoặc bản scan không rõ quyền.
[FAO — Vietnamese Food Composition Table 2017](https://www.fao.org/food-composition/tables-and-databases/detail/(viet-nam--2017)-vietnamese-food-composition-table/en).

**Australian Food Composition Database release 3, 12/2025** của FSANZ là nguồn
đáng tham khảo tiếp theo. Chưa tích hợp hoặc tuyên bố đã dùng nguồn này;
cần rà soát điều kiện giấy phép và đối chiếu khẩu phần/món trước khi thêm.
[FSANZ — data files](https://www.foodstandards.gov.au/science-data/food-nutrient-databases/afcd/data-files),
[điều kiện sử dụng](https://www.foodstandards.gov.au/science-data/monitoringnutrients/afcd/datauserlicenceagreement).

**USDA Branded 04/2026** là nhãn sản phẩm do ngành thực phẩm cung cấp, không
tương đương mọi sản phẩm được USDA xét nghiệm. Chưa nhập toàn bộ vào asset.

## Tái tạo và file chính

Tải hai ZIP từ URL trong `data/food_catalog/usda-current-manifest.json`, đặt
chung thư mục, rồi chạy:

```powershell
python -X utf8 tool/import_usda_current.py D:/HealthMateMaintenanceQA/catalog-current
python -X utf8 -m unittest discover -s tool -p 'test_usda*.py' -v
```

Importer kiểm SHA-256 của từng ZIP trước khi đọc; chỉ ghi asset bổ sung
`assets/nutrition/usda-current.json` và manifest riêng. Không ghi đè hai asset
cũ. Manifest ghi phiên bản, nguồn, checksum, số loại trừ và ngày công bố.

Runtime: `bundled_vietnamese_foods.dart` tải asset mới độc lập; lỗi một asset
bổ sung không làm mất asset còn lại. `food_catalog_search.dart` thống nhất
thứ tự nguồn khi offline/Firestore: mục Việt biên soạn, Foundation, FNDDS,
SR Legacy; độ khớp tên chính xác vẫn được ưu tiên khi tìm. Parser giữ FDC ID
và loại nguồn để không làm mất thông tin truy vết khi cache.

Không thêm dependency hay cấu hình Firebase. Web admin hiện quản lý catalog
Firestore, không tự hiển thị mọi mục trong asset. APK cũ đã cài không tự có
danh mục mới; cần cài bản build mới.

## Kiểm tra

- Importer: **17/17** unittest qua, gồm năng lượng Atwater/kJ, dữ liệu thiếu,
  số 0 hợp lệ, checksum, null, đơn vị khẩu phần phân số và dữ liệu thành phần
  chưa rõ. Hai SHA-256 ZIP khớp bản chính thức đã tải.
- Flutter: nhóm liên quan **25/25**, toàn dự án **688/688** qua. Bổ sung kiểm
  tra snapshot món mới 200 g cà chua = 54 kcal rồi chạy lại file mới **3/3**;
  toàn bộ 7.606 mục cũ giữ nguyên nội dung snapshot trong kiểm thử đối chiếu.
- `flutter analyze --no-pub`: **No issues found**, 9,1 s ở lần cuối.
- `dart format --output=none --set-exit-if-changed` trên 7 file Dart đã sửa:
  sạch. `git diff --check` trên các file của thay đổi này qua. Toàn workspace
  vẫn có whitespace có sẵn ở `lib/main.dart:32`, không sửa phần đó.
- `tool/build_android.ps1`: **7/7** kiểm tra cấu hình runtime qua, build debug
  `lib/main.dart` thành công, Gradle 19,4 s. KGP warning của các plugin Firebase
  và mobile_scanner còn; không nâng dependency trong lượt dữ liệu này.
- SHA-256 của cả ba asset bên trong APK khớp file nguồn; APK có đủ 11.169 mục.
- Đối chiếu độc lập 3.563 mục với ZIP chính thức: tên gốc (bỏ khoảng trắng
  đầu/cuối), kcal/protein/carb/fat và đơn vị đều khớp từng bản ghi nguồn.
- Không chạy lại luồng Android theo yêu cầu người dùng tự test; chưa xác minh
  dữ liệu mới trên điện thoại thật, AI hay API tìm kiếm bên ngoài.

APK: `build/releases/healthmate-current-foods-debug.apk`, **222.932.966 byte**.
SHA-256: `FF1F1E256F1C566D42172BABA2CC34F58374460A54358F6E3A12522FD018792B`.
Manifest build: `build/releases/healthmate-current-foods-debug.json`.
Log: `build/catalog-current-20261027/`.

Giới hạn: dữ liệu tham khảo thị trường Mỹ không thay cho phân tích món ăn Việt
cụ thể; tuổi bản phát hành không đủ chứng minh một mục chính xác hơn. Ngày
đo/công bố cũ vẫn được giữ nguyên, không làm mới ngày giả. Thư viện mới vẫn
chưa có độ phủ sản phẩm/nhà hàng như MyFitnessPal. Benchmark desktop Dart JIT
11.169 mục: truy vấn đầu khoảng 731 ms, các truy vấn tiếp 35–43 ms; không phải
kết quả đo hiệu năng Android.
