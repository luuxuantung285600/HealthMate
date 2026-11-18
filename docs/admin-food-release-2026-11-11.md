# Phát hành quản trị ảnh và bộ lọc thực phẩm — 11/11/2026

Giai đoạn 4 bổ sung: quản trị danh mục thực phẩm. Đã triển khai lên
https://healthmate-admin-vn.web.app, project `healthmate-app-20261013`.

## Hành vi

- Thực phẩm → **Sửa ảnh** ở từng dòng mở đúng món và đưa vào phần ảnh.
  Giữ ảnh đi kèm app, đổi bằng URL HTTPS có nguồn/quyền sử dụng, hoặc gỡ ảnh.
  Có xem trước; ảnh custom phải tải được và có kích thước hợp lệ trước lưu.
  Lỗi ảnh/mạng giữ nguyên bản nháp. Lưu có lý do, kiểm phiên bản, transaction
  và audit nguyên tử. Không upload tệp: Firestore giữ metadata, tệp ảnh custom
  ở máy chủ HTTPS mà admin chọn.
- Món bị ẩn vì chưa có ảnh cần ảnh custom hợp lệ trước khi khôi phục.
  379 ảnh đã duyệt được phát hành cùng web; 121 món thiếu ảnh vẫn có thể quản trị.
- Đủ 10 lựa chọn như app: Tất cả, Món ăn Việt, Trái cây, Rau củ, Thịt,
  Cá & hải sản, Trứng & sữa, Ngũ cốc, đậu & hạt, Đồ uống, Đồ đóng gói.
  Port phân loại cùng dữ liệu ngoại lệ đã duyệt; sản phẩm có thể thuộc nhiều
  nhóm như app. Thịt và cá/hải sản tách riêng. Không ghi thêm field nhóm vào DB.
- Tìm không dấu, nhóm và trạng thái kết hợp trên **toàn bộ kết quả**, rồi
  phân trang 25 món. Đổi lọc trở về trang 1. Một listener catalog theo vòng đời
  màn hình; phân trang/lọc không tạo truy vấn mới. Phạm vi trên 5.000 món báo lỗi
  và yêu cầu thu hẹp tra cứu, không hiển thị tập thiếu như kết quả đầy đủ.
- Tra cứu chính xác mã/đầu tên vẫn hoạt động; xuất Excel áp dụng cùng bộ lọc
  trên khoảng mã đã chọn. Admin gồm cả món đang hiển thị và đã ẩn, trong khi
  app chỉ cho chọn món đủ điều kiện hiển thị. Không nhập thêm thư viện USDA
  hoặc món riêng của người dùng vào danh mục quản trị.

## Phát hành

- Sao lưu Rules/config công khai và phiên bản Hosting cũ trước deploy trong
  `build/admin-food-release-20261111/production-before/`.
  Hosting cũ: `sites/healthmate-admin-vn/versions/60d6d4c5fd3c672b`.
- Kiểm tra lại baseline ngay trước deploy: không đổi từ lúc review.
- Rules production chỉ bổ sung field/validation ảnh và extra nutrients cho
  catalog; form hiện tại luôn gửi extra nutrients. Tất cả đường dẫn khác giữ
  nguyên từ production. Không phát hành toàn bộ chênh lệch Rules local của các
  công việc trước. Giữ Spark, App Check và `statisticsMode=firestore`.
- Lệnh thực tế, exit 0:

  ```powershell
  firebase deploy --project healthmate-app-20261013 --config build/admin-food-release-20261111/candidate/firebase.review.json --only "firestore:rules,hosting" --non-interactive
  ```

- 430 tệp, gồm 379 ảnh. Kiểm 14 URL sau deploy: module UI/bộ lọc/listener,
  config, CSS, index và 3 ảnh; tất cả HTTP 200, hash khớp candidate, no-store.
  CSP cho ảnh HTTPS và no-referrer đã xác minh. Đọc lại Rules từ Firebase:
  SHA256 chuẩn hóa `6569cc8744a52e1c9ea0001ba3b14d9448a3c600d4260f5c2ead2f3bd7195088`,
  khớp chính xác bản đã kiểm thử. Báo cáo `hosted-verification.json`.
- Quét 430 tệp phát hành: không phát hiện private key/service account/refresh
  token/OAuth secret. Chỉ cấu hình Firebase client công khai được đóng gói.

## Kiểm thử

- `npm --prefix admin-web run check` và syntax check hai module nhóm mới: qua.
- `npm --prefix admin-web test`: **129/129** qua. Bao gồm phân loại cùng app,
  kết hợp lọc xuyên trang, realtime, lỗi ảnh chặn lưu và giữ draft.
- Phân loại toàn bộ 11.361 record tham khảo khớp Flutter theo từng nhóm.
- Firestore Emulator với **đúng Rules dự kiến phát hành**: **14/14** qua;
  admin/audit, ảnh hợp lệ/sai, user thường và dữ liệu riêng tư.
- `node --test admin-web/test/realtime-sdk.integration.mjs`: **14/14** qua
  với Auth/Firestore Emulator và đúng Rules. Có nhận 27 món vượt trang 25,
  thay ảnh/ẩn món và dừng listener; không ghi dữ liệu kiểm thử production.
- `npm --prefix admin-web run test:ui`: 72 lượt trang, 4 chiều rộng × 2 theme;
  kiểm 10 nhóm, 65 món qua nhiều trang, tìm/lọc kết hợp và mở Sửa ảnh đúng món.
  Ảnh/log tại `build/admin-identity-20261110/`; log Node/SDK/Rules/deploy tại
  `build/admin-food-release-20261111/`.
- Không sửa Dart/Android trong lượt này nên không chạy lại format/analyze/test
  Flutter hoặc build APK. Kết quả Flutter ở lượt phát hành ảnh trước không được
  tính là kiểm thử mới. Không nghiệm thu Android thật trong lượt này.

## Giới hạn và bước tiếp theo

Admin cần tải lại tab đang mở để nhận module mới. Không cần Blaze hoặc cấu hình
dịch vụ mới. Ảnh custom cần mạng và quyền sử dụng do admin xác nhận; kiểm tải ảnh
không chứng minh ảnh đúng món hoặc giấy phép đúng. Host ảnh có thể hỏng sau này.
App đã có consumer metadata ảnh trong source; thiết bị cần bản app có hỗ trợ này
để hiển thị thay đổi. Chưa thực hiện đăng nhập/lưu ảnh bằng tài khoản admin thật
trên production; quyền ghi và đồng bộ đã kiểm bằng SDK thật trong emulator,
Rules production đã đọc lại khớp. Không tạo dữ liệu giả ở production.

Firestore compiler có cảnh báo hàm `knownNumber` chưa dùng từ Rules baseline;
biên dịch và deploy thành công. Các thay đổi Rules local ngoài catalog vẫn chưa
được triển khai bởi lượt này. Đề xuất tiếp theo: nghiệm thu thao tác admin/app
trên thiết bị thực khi người dùng yêu cầu; chưa triển khai giai đoạn khác.
