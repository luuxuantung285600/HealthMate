# Phát hành dữ liệu dinh dưỡng đã xác minh — 10/11/2026

Giai đoạn 4, bảo trì Food Catalog theo yêu cầu “phát hành bộ dữ liệu đã xác
minh”. Đã phát hành thật lên Firebase project `healthmate-app-20261013` và
web admin; không phải chỉ chuẩn bị bản local.

## Dữ liệu đã phát hành

Version: `verified-nutrients-2026-11-10-v1`.
Firestore commit: `2026-11-10T03:49:20.357456Z` (10:49:20 giờ Việt Nam).

| Nguồn | Món được cập nhật | Có natri mới | Có đường tổng mới | Có chất xơ tổng mới |
| --- | ---: | ---: | ---: | ---: |
| Viện Dinh dưỡng 2007, bản FAO lưu | 84 | 80 | 49 | 0 |
| Nhãn đúng biến thể Acecook | 22 | 22 | 21 | 0 |
| USDA SR Legacy, đúng FDC ID | 4 | 4 | 4 | 4 |
| Tổng | **110** | **106** | **74** | **4** |

Chỉ bổ sung field đã có nguồn: natri mg/100 g, đường tổng g/100 g, bốn giá
trị chất xơ USDA và bằng chứng nguồn. Không tạo/xóa món hoặc sửa kcal/đạm/
carb/béo, tên, ảnh, trạng thái ẩn, aliases, khẩu phần hay nhãn nguồn hiện có.
Không ghi vào `users/*`; snapshot nhật ký đã lưu giữ nguyên.

Ví dụ Hảo Hảo tôm chua cay **gói khô 75 g**: đường **4 g**, natri
**1.778 mg**, tương đương **4,445 g muối**; chất xơ vẫn chưa có số xác minh.
Web chi tiết hiển thị trên **100 g**: đường 5,333 g, natri 2.370,667 mg,
muối quy đổi 5,927 g (làm tròn hiển thị, dữ liệu gốc giữ đủ độ chính xác).

Miến Phú Hương gà thiếu đơn vị đường trong nguồn nên vẫn chưa biết. Ba nhãn
TH chưa đọc được nguồn và 83 công thức chưa đủ dữ liệu gia vị không được
tự điền. Celluloza trong bảng 2007 không được đổi thành chất xơ tổng.
[Báo cáo đối chiếu nguồn](vietnamese-nutrients-2026-11-10.md).

## Cách ghi và kiểm chứng

- Review trước khi ghi: 110/110 document tồn tại. Tên, nguồn, bốn macro,
  đơn vị/cơ sở đo và mã/trang hoặc biến thể/khối lượng nhãn được kiểm tra.
  Bốn mục USDA chỉ chấp nhận chính xác nhãn SR Legacy cũ đã biết; giữ nguyên
  nhãn này, bổ sung FDC ID/bằng chứng chi tiết.
- Có backup Firestore wire format và manifest. Dùng update mask từng field,
  không thay cả document/map. Giá trị 0/null/rỗng hoặc xung đột hiện có được
  bảo vệ; có xung đột thì chưa apply. Review thực tế: **0 xung đột**.
- Một atomic commit gồm 110 cập nhật + 110 audit create. Mỗi cập nhật dùng
  `updateTime` đã review; admin sửa đồng thời sẽ làm commit bị từ chối.
- Bằng chứng có `releaseVersion`; timestamp do server cấp. Phiên phát hành
  là Firebase CLI/IAM của chủ dự án, không giả mạo phiên đăng nhập app.
  `actorUid`/`updatedBy` dùng `firebase-cli:<hash định danh>`, audit ghi rõ
  CLI/IAM và version; không lưu token, credential hay email vào catalog.
- Đọc lại **110/110** document và **110/110** audit. Đối chiếu toàn bộ field
  ngoài patch, kể cả timestamp; đúng giá trị và metadata phát hành. Chạy
  `verify` lần nữa vẫn qua; lập kế hoạch lại trên readback: 0 cập nhật,
  110 bỏ qua, 0 xung đột.

Backup/manifest/receipt/readback:
`build/verified-nutrients-release-20261110-v1/`. Đây là artifact local bị
Git ignore; giữ lại để đối chiếu/khôi phục có kiểm soát khi cần.

## Web admin và bản app

- [Web admin](https://healthmate-admin-vn.web.app): chi tiết món hiển thị
  đường tổng, natri, muối quy đổi; thiếu chỉ số hiện “Chưa có dữ liệu”.
- Hosting từ `ce490717ebc30850` sang **`60d6d4c5fd3c672b`**. Chỉ patch
  `app.mjs` và thêm `nutrition-values.mjs`; 31 tệp khác và toàn bộ config,
  CSP, App Check/auth adapter giữ nguyên. Sửa ngắt URL nguồn bằng `wbr` để
  hộp chi tiết không tràn ở 320 px. Không deploy toàn bộ working tree.
- Đã đọc lại đủ **33 hash tệp** trên live version, config và bytes công
  khai của hai tệp thay đổi. Không deploy Firestore Rules/Functions, không
  thay billing hoặc thêm dịch vụ. Form sửa natri/đường và các thay đổi UI
  khác đang có ở source local chưa được đưa lên trong lần phát hành dữ liệu.
- App hiện có listener catalog chung; bản hỗ trợ extras nhận số liệu server
  khi đồng bộ. Bộ offline cùng dữ liệu nằm trong APK kiểm thử:
  `build/releases/healthmate-verified-nutrients-20261110-debug.apk`.
  Đã kiểm ZIP: asset khớp byte nguồn, 213 mục nhóm Việt/đồ gói, 106 có natri,
  74 có đường; đúng số liệu Hảo Hảo75g. APK 238.245.701 byte, SHA256:
  `93d5fdd9a9f757dd72b18abe2ba3cc393df3cee8016b9e6cee7b7e8a7db30ec5`.
- APK là **debug**, tái đóng gói artifact đã build/kiểm ở lượt chuẩn bị,
  không chạy build lại khi source Flutter không đổi. Chưa ký bản phát hành,
  chưa đưa Play Store hoặc nghiệm thu trên Android vật lý.

## Kiểm thử trong lượt phát hành

- `node --test tool/publish_verified_nutrients.test.cjs tool/food_catalog.test.cjs tool/food_photos.test.cjs`: **25/25 qua**.
- `npm test` trong `admin-web`: **113/113 qua**.
- Sau sửa cách ngắt URL: `node --test test/nutrient-publication.test.mjs test/app-dom.test.mjs` trong admin-web: **50/50 qua**.
- Chrome headless: **9/9** lượt chi tiết, ba món × 320/390/1440 px, đúng
  unknown/zero/natri/đường/muối, không tràn, 0 runtime error. Dùng đúng
  source web đang chuẩn bị và adapter local chỉ đọc, không đăng nhập hoặc
  giả lập thao tác production. Đã xem ảnh 320 px sau sửa URL.
- `node --check` tooling và app module staging, `git diff --check`: qua.
- Firestore/Hosting `apply` và `verify`: exit0, kết quả đọc lại như trên.
- Flutter format/analyze/1.235 tests và debug build đã qua ở lượt chuẩn bị
  (log `build/nutrient-research/`); không chạy lại vì lượt này không sửa Dart.

Chứng cứ web: `build/verified-nutrients-admin-20261110-v2/` (manifest,
receipt, QA, screenshots và hash readback). Bản v1 của web chỉ là review
trước sửa URL, chưa phát hành.

Không cần người dùng cấu hình Firebase/billing mới. Tải lại trang admin để
xem phần chi tiết mới; cài APK kiểm thử để có dữ liệu offline mới. Giai đoạn
tiếp đề xuất: nghiệm thu trên Android vật lý khi người dùng yêu cầu.
