# Bổ sung dưỡng chất có nguồn cho món Việt và đồ gói — 10/11/2026

**Cập nhật:** đã phát hành Firebase và phần hiển thị chi tiết trên web admin
theo yêu cầu tiếp theo. [Báo cáo phát hành, kiểm chứng và APK](verified-nutrients-release-2026-11-10.md).
Các trạng thái “chưa phát hành” bên dưới ghi nhận cuối lượt chuẩn bị dữ liệu.

Giai đoạn 4, bảo trì dữ liệu theo yêu cầu người dùng tự tìm nguồn. Đã đọc
nguồn chính thức và bổ sung các chỉ số được công bố; không suy đường từ carb,
không đổi dưỡng chất thiếu thành 0, không thay calo/ba chất hoặc ID hiện có.

## Kết quả trong nhóm 213 mục Việt Nam/đồ gói đang có

| Nguồn | Số mục | Có natri | Có đường tổng | Có chất xơ tổng |
| --- | ---: | ---: | ---: | ---: |
| Viện Dinh dưỡng 2007 | 101 | 80 | 49 | 0 |
| Công thức HealthMate ước tính | 83 | 0 | 0 | 0 |
| Nhãn hãng | 25 | 22 | 21 | 0 |
| Bốn mục USDA cũ | 4 | 4 | 4 | 4 |
| Tổng | 213 | 106 | 74 | 4 |

Trước lượt này: natri 0, đường 0, chất xơ 4. Tổng catalog vẫn 11.220 mục;
không thêm món trùng để tăng số đếm. Toàn bộ offline hiện có natri 11.025,
đường 9.024 và chất xơ 10.326 mục. Không phải mọi mục đều có đủ cả ba.

## Nguồn và kiểm tra

1. [Acecook — Hảo Hảo](https://acecookvietnam.vn/product/mi-hao-hao/),
   [Phở Đệ Nhất](https://acecookvietnam.vn/product/pho-de-nhat/),
   [Miến Phú Hương](https://acecookvietnam.vn/product/mien-phu-huong/),
   [Hủ tiếu Nhịp Sống](https://acecookvietnam.vn/product/hu-tieu-nhip-song/),
   [Phở trộn Đệ Nhất](https://acecookvietnam.vn/product/pho-tron-de-nhat/).
   Đọc đúng `data-tab` của từng biến thể, đối chiếu ảnh bao bì và cả bốn số
   kcal/đạm/carb/béo với dữ liệu gói hiện có trước khi nhập. Natri 22 mục,
   đường 21 mục, chuẩn hóa theo đúng trọng lượng gói khô, không dùng gram sau
   pha nước. Dấu chấm hoặc phẩy nhóm ba chữ số của natri mg là dấu hàng nghìn;
   dấu phẩy trong đường g là thập phân. Evidence giữ nguyên chuỗi nguồn,
   hash HTML, ngày kiểm tra và giá trị trên gói trong `sourceDetails`.
   Ví dụ Hảo Hảo tôm chua cay 75g: 1.778mg natri, 4g đường; tương đương
   4,445g muối quy đổi. Miến Phú Hương gà ghi `4,0` nhưng thiếu đơn vị đường
   trong bảng đã đọc: giữ chưa biết. Các bảng này không công bố số chất xơ.
2. [Bảng thành phần thực phẩm Việt Nam 2007, FAO lưu bản gốc](https://www.fao.org/fileadmin/templates/food_composition/documents/pdf/VTN_FCT_2007.pdf).
   SHA256 `6c4838ba5623df6d62b2bf4ef1a82968bbfad8a10980247c32b7e60c0c9ca281`.
   Đọc cột trái theo tên chỉ số tiếng Anh, đơn vị và giá trị; đối chiếu đủ
   101 mã thực phẩm với trang đã lưu. Dấu `-` giữ chưa biết, 0 nguồn công bố
   được giữ. Đã render và xem mẫu trang 14/107/450/509 để đối chiếu bố cục.
   Chỉ nhập Sodium (mg) và Sugar (g). Dòng `Celluloza (Fiber)` không tự đổi
   sang `Fiber, total dietary` của USDA; chưa điền vào field chất xơ tổng.
   Raw row, mã/trang và hash được giữ trong dữ liệu tham chiếu.
3. [USDA SR Legacy 2018](https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip).
   Đọc archive cache đã có, đối chiếu FDC ID và cả bốn macro/chất xơ trước
   khi bổ sung natri ID1093, đường ID2000. Bốn FDC: 171688, 173944, 168878,
   173424. Có ID từng dòng `food_nutrient` và hash archive trong evidence.
   Dữ liệu tham khảo lịch sử, không quảng bá là phép đo hiện tại của món.

Trang sản phẩm TH trả HTTP403 trong lần tra cứu. Chưa xác minh ba nhãn này,
không dùng tên “không đường” để gán đường tổng bằng 0. Chưa bổ sung chỉ số
cho công thức món chế biến khi chưa kiểm tra đủ gia vị/nước mắm/nước dùng.

## Cách áp dụng và giới hạn

- `ingredients.json`, `packaged.json`, `legacy_usda.json` giữ dữ liệu gốc,
  thêm extras/evidence; `build_vietnamese_bundle.cjs` sinh asset hiện có.
- Importer validate key/giới hạn/evidence; natri và đường của gói phải khớp
  phép chuẩn hóa từ số trên gói. Lệnh import `--apply` vẫn chỉ tạo mục thiếu,
  không tự ghi đè mục online hoặc thay nhật ký.
- App dùng extras đã nhập cho món/khẩu phần/snapshot mới. Document catalog
  cũ hoàn toàn chưa có field extras được đọc bổ sung từ bundle chỉ khi ID,
  tên, nhãn nguồn, bốn macro và cơ sở g/100g khớp. Nếu admin đã ghi field,
  kể cả `{}` hoặc null, app tôn trọng và không tự lấp lại; đổi nguồn/tên/
  macro/cơ sở đo không được kế thừa. Không thêm listener hoặc collection.
- Nhật ký cũ giữ snapshot thiếu dữ liệu, không bị thay đổi bởi catalog mới.
- Chưa ghi Firestore production, deploy web/Rules, push Git, cài Android thật
  hoặc ký release. Web admin online vẫn hiển thị dữ liệu Firestore hiện tại;
  cần quy trình cập nhật catalog có version/audit để đưa số liệu mới lên web.

## Kiểm tra

- Node catalog/ảnh: 15/15 qua.
- Flutter nhóm nguồn/đồ gói/Home: 17/17 qua.
- Analyze: sạch, 24,8 giây.
- Toàn Flutter: **1.235/1.235 qua**, exit 0, 2 phút 17 giây.
- Dart format hai file/0 đổi và `git diff --check` qua.
- Debug APK build thành công, exit0, assembleDebug 20,7s. Đọc lại asset trong
  APK có hash khớp source và đúng số liệu Hảo Hảo75g. Cảnh báo KGP tương lai
  từ plugin hiện có vẫn còn, không chặn build.

Log/nguồn tải/ảnh QA trong `build/nutrient-research/`; không đưa credential
hoặc PDF/snapshot HTML nguồn vào Git. Dữ liệu nguồn công bố được lưu có xuất xứ.
Đề xuất tiếp: nghiệm thu và phát hành dữ liệu có kiểm soát khi được yêu cầu.
