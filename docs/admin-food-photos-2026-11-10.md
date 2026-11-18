# Quản lý ảnh món ăn từ admin — 10/11/2026

Giai đoạn 4 mở rộng, chỉ quản lý ảnh danh mục và hiển thị tương ứng trong app.

## Hành vi đã thực hiện

- Thực phẩm → Sửa/Thêm → Ảnh món ăn: giữ ảnh bundled, đổi URL HTTPS kèm tên ảnh/tác giả/nguồn/quyền sử dụng, hoặc gỡ ảnh. Có xem trước; metadata/URL sai có thông báo; lỗi tải ảnh không làm mất thông tin món.
- Danh sách và chi tiết admin có preview. 51 ảnh preview đúng tệp/credits đã duyệt trong app, hash khớp manifest. Inter và theme đen/trắng hiện tại được giữ.
- Form vẫn sửa tên, nhóm, tên tương đương, dinh dưỡng trên 100 g, nguồn, khẩu phần và trạng thái. Lưu thực qua transaction/audit hiện có; giữ draft khi lỗi, có lý do và chống ghi đè bản mới.
- App dùng cùng stream catalog để cập nhật card, ảnh khẩu phần/nguyên liệu và modal nguồn ảnh đang mở. Gỡ ảnh không bật lại ảnh bundled. Invalid custom metadata không lấy ảnh cũ lấp vào; đổi tên không gán nhầm ảnh. Không thêm query cho mỗi ảnh.
- Snapshot bữa ăn và lượng dinh dưỡng không đổi theo ảnh. Metadata ảnh không được ghi vào meal snapshot.

## File chính

- Web: `dist/food-photos.mjs`, `food-photos.css`, `bundled-food-photos.mjs`, `food-photos/`; tích hợp `app.mjs`, `validation.mjs`, `index.html`.
- CSP/server và cả hai tool tạo release cho phép ảnh HTTPS; có no-referrer cho preview. Tool `tool/build_admin_food_photos.cjs` kiểm hash và tạo preview/credits.
- App: `food_photo.dart`, `nutrition_models.dart`, `catalog_food_reader.dart`, `food_photo_provider.dart`, `food_photo_thumbnail.dart`, `food_selection_card.dart`, `food_portion_dialog.dart`.
- `firestore.rules`: photo tùy chọn, đúng cấu trúc/giới hạn; chỉ admin đã xác thực có audit được ghi. Tài liệu schema trong `database-design.md`.
- Test Node/DOM/SDK/Rules và `test/admin_food_photo_test.dart`. Các fixture widget đơn lẻ được bọc ProviderScope/override catalog; fixture thay container unmount/pump đúng vòng đời. Không giảm assertion nghiệp vụ để bỏ lỗi.

## Kiểm thử thực tế

- Node admin: 108/108 qua; syntax check qua.
- Firestore Emulator, `node --test rules-tests/admin.rules.test.cjs`: 13/13 qua. Bao gồm legacy/default/custom/hidden, HTTPS/credentials/missing/extra fields, user thường không ghi được, audit nguyên tử.
- Auth + Firestore Emulator, seed fixture local rồi `node --test admin-web/test/realtime-sdk.integration.mjs`: 13/13 qua. SDK thật lưu custom → hidden → default, listener nhận thay đổi; audit có photo; bản cũ bị chặn.
- Chrome headless: 72 lượt trang (9 trang × 4 kích thước × 2 theme), thêm kiểm form ảnh ở cả 8 trường hợp, preview 512 px decode, hidden/unsafe URL, custom input không tràn; không ghi production.
- `flutter analyze`: sạch.
- `flutter test`: **1.220/1.220 qua**, 2 phút 18 giây. Không có test lỗi ở lượt cuối.
- `flutter build apk --debug --no-pub`: thành công, assembleDebug 40,2 giây. Gradle có cảnh báo các plugin hiện tại còn dùng KGP trước thay đổi Built-in Kotlin của Flutter tương lai; không nâng package ngoài phạm vi.
- Dart format các file sửa đã chạy. Log `build/admin-photo-*.log`; ảnh QA `build/admin-identity-20261110/food-photo-editor-{light|dark}-{1440|390}.png`.

Lượt test ban đầu phát hiện các widget fixture chưa cung cấp catalog/ProviderScope mới và một container fixture bị thay khi consumer chưa dispose. Đã bổ sung dependency fixture và flush consumer trước khi thay container; lượt kiểm tra lại lifecycle qua. Đây là thay đổi test harness, không bỏ kiểm tra lỗi.

## Cấu hình, giới hạn và bước sau

Chưa push/deploy, chưa thay catalog hoặc Rules production, chưa cài APK lên Android thật. Cần phát hành Rules/web/app mới để dùng trên môi trường thật. Không thêm dịch vụ trả phí hoặc thay cấu hình billing.

Ảnh mới dùng URL, chưa có upload tệp. Firestore giữ metadata, tệp ở hosting công khai do admin chọn; HTTPS hợp lệ không đảm bảo host luôn hoạt động hoặc giấy phép do admin nhập là đúng. Kiểm ảnh preview/quyền sử dụng trước lưu; dùng URL mới/có phiên bản khi đổi nội dung để tránh cache. Ảnh custom cần mạng, có fallback khi hỏng/offline. Món chỉ có trong bundle offline cần bản ghi catalog cùng ID trước khi admin quản trị; không tự import toàn bộ thư viện trong lượt này.

Đề xuất tiếp theo: nghiệm thu trên môi trường thật và phát hành đồng bộ Rules/web/app khi người dùng yêu cầu; chưa thực hiện.
