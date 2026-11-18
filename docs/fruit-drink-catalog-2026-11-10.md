# Trái cây và đồ uống — 10/11/2026

## Phạm vi đã chốt

Giai đoạn 4 bổ sung: 100 mục trái cây và 100 mục đồ uống được chuẩn hóa
tên tiếng Việt, nguồn dinh dưỡng và thứ tự gợi ý. Đây là mục thực phẩm,
bao gồm giống, trạng thái tươi/khô/đông lạnh/đóng hộp hoặc cách pha chế;
không phải cam kết 100 loài trái cây hoặc 100 nhãn đồ uống Việt Nam.

- Danh sách 200 ID/tên/mô tả nguồn: `data/food_catalog/fruit-drink-browse.json`.
- 50 mục từ danh mục cơ sở; 150 bản ghi tham chiếu USDA đã có trong app
  được chuẩn hóa và đưa lên catalog quản trị dùng chung.
- Bổ sung mới 27 dòng VDD: 22 mục trái cây và 5 mục đồ uống. Bộ cơ sở
  tăng 213 → 240; toàn bộ catalog offline tăng 11.220 → 11.247 ID riêng biệt.
- Bộ gợi ý 100/nhóm đứng trước các bản ghi tham chiếu còn lại khi duyệt.
  Tìm kiếm vẫn ưu tiên mức khớp; bộ lọc chế độ ăn, món cần tránh và món
  admin đã ẩn vẫn có hiệu lực. Số mục nhìn thấy có thể giảm theo bộ lọc.

## Trải nghiệm

Màn thêm bữa ăn và bộ chọn thực phẩm dùng chung có `Tất cả / Trái cây /
Đồ uống`. Người dùng chọn lượng rồi xác nhận; đồ uống có năng lượng được
tính vào dinh dưỡng như một mục trong nhật ký. Việc chọn nhóm không xóa
món đã chọn, không sửa snapshot bữa ăn cũ hoặc tự cộng thêm vào nhật ký nước.

63 đồ uống dùng cốc có gram weight chính thức từ USDA; phần còn lại giữ
khối lượng/khẩu phần sẵn có. Không coi mọi chất lỏng có mật độ 1 g/ml.
Quả nhập theo phần ăn được, bỏ vỏ/hạt bỏ đi. Đồ hộp giữ rõ nước quả/siro,
để ráo hay gồm chất lỏng; đồ uống ghi rõ có đường/không đường, pha sẵn hay
nguyên chất theo mô tả nguồn. Mục chưa có ảnh giữ giao diện chữ hiện có.

Đổi nhóm hủy tìm kiếm và tải chi tiết đang chờ. Kết quả cũ không được ghi
đè nhóm mới; kết quả từ local/cache/API đều được lọc trước giới hạn hiển thị.

## Nguồn và giới hạn

- VDD 2007, bản PDF chính thức trên FAO:
  <https://www.fao.org/fileadmin/templates/food_composition/documents/pdf/VTN_FCT_2007.pdf>.
  SHA256 `6c4838ba5623df6d62b2bf4ef1a82968bbfad8a10980247c32b7e60c0c9ca281`.
  Lưu mã món, trang PDF và từng ô giá trị/tài liệu tham khảo tách biệt.
- USDA SR Legacy 2018, từng ID FoodData Central và mô tả gốc giữ nguyên.
  Đã so sánh độc lập toàn bộ dưỡng chất được nhập của 147 bản ghi SR trong
  bộ gợi ý với archive chính thức; kiểm tra 63 bản ghi khẩu phần cốc.
- Ba bản ghi Foundation (sữa nguyên kem, sữa 2% và sữa yến mạch) dùng dữ
  liệu đã có và giữ nguyên toàn bộ dinh dưỡng/nguồn. Không tuyên bố kiểm
  lại archive Foundation chưa có trong môi trường của lượt này.
- Không dùng cellulose của VDD như tổng chất xơ. Không điền ô thiếu bằng
  0. Giữ dữ liệu đường còn thiếu; loại 8 ô đường trong phần bổ sung mới
  vì lớn hơn tổng carbohydrate trong cùng bảng, lưu bằng chứng để rà soát.
- Chưa thêm VDD cóc 5043, thanh long 5044 và vú sữa 5054 vì thiếu lipid.
  Các mục này cần thêm nguồn đủ dữ liệu trước khi cho ghi nhật ký.
- Dữ liệu USDA/VDD là tham khảo theo phiên bản nguồn; nhãn đồ uống có thương
  hiệu có thể khác theo thị trường/lô, cần đối chiếu nhãn thực tế.

Tái tạo/đối chiếu (không cần API key hoặc ghi cloud):

```powershell
python tool/expand_fruit_drink_catalog.py build/nutrient-research/vdd.pdf
node tool/build_vietnamese_bundle.cjs
python tool/food_browse_metadata.py
python tool/verify_fruit_drink_sources.py build/nutrient-research/vdd.pdf build/catalog-expansion/usda-sr-legacy-2018.zip
```

## Firebase

Đã phát hành `fruit-drink-100-each-20261110-v1` vào dự án
`healthmate-app-20261013`: **177 food creates + 177 admin_audit creates** trong
một commit nguyên tử, đọc lại xác minh đầy đủ. **209 document cũ giữ nguyên**
toàn bộ fields/timestamps; catalog cloud hiện **386** document. Không sửa
dữ liệu người dùng hoặc lịch sử bữa ăn, không deploy Hosting/Rules/Functions.

Review lặp lại: creates 0, skipped 200, conflicts 0. Mỗi create có điều kiện
`exists: false`, bản sao trước khi phát hành và audit qua actor Firebase CLI
đã băm. Không lưu email/credential vào repo. Chi tiết review/receipt/readback
nằm trong `build/fruit-drink-release-20261110-v1/`.

App cũ nhận các mục cloud mới qua listener hiện có; cần cài APK mới để có
bộ lọc nhóm, thứ tự gợi ý và tên/khẩu phần offline mới. Admin dùng collection
hiện có và nhìn thấy dữ liệu mới, không cần backend hoặc billing mới.

## Kiểm thử và bản cài

- Node: 28/28 test dữ liệu, tạo bản ghi, audit, idempotence, chặn ghi đè
  và hồi quy bản phát hành dưỡng chất cũ đã qua.
- Flutter tập trung: 45/45; UI/paging cuối 12/12 qua ở sáng/tối, 390 px/chữ
  100% và 320 px/chữ 200%. Đã xem ảnh chụp và các trang nguồn PDF.
- Lần chạy toàn bộ đầu: 1.243 pass, 1 lỗi thao tác test paging ở chữ 150%
  do bấm nút mới được build nhưng chưa cuộn vào vùng bấm. Đã thêm
  `ensureVisible` trước khi bấm, giữ nguyên các assertion và kiểm thử lại qua.
- Toàn bộ Flutter cuối: **1.244/1.244 qua**, exit 0 (2 phút 57 giây).
  `flutter analyze`: **No issues found**, exit 0 (25,9 giây).
- APK debug build qua, Gradle 62,9 giây:
  `build/releases/healthmate-fruit-drinks-20261110-debug.apk`.
  238.271.433 byte; SHA256
  `a622b27d2fdec2dc701a9cfba1b3bc77b4c9a3082dee8c85cfd60ed5def9752f`.
  Đã kiểm ZIP: cả 3 asset dinh dưỡng khớp từng byte với source, đủ 11.247 ID
  riêng biệt. Manifest: `build/fruit-drink-apk-manifest.json`.
- Cảnh báo KGP từ plugin hiện hữu vẫn còn; build thành công. Không nâng
  dependency ngoài phạm vi để xử lý cảnh báo này.

Chưa nghiệm thu Android vật lý hoặc ký bản phát hành; giữ phạm vi người dùng
đã tạm hoãn. Bước đề xuất tiếp theo: nghiệm thu chọn/ghi trái cây và đồ uống
trên điện thoại khi người dùng yêu cầu.
