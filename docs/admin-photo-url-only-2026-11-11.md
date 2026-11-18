# Đổi ảnh món chỉ cần URL — 11/11/2026

Giai đoạn 4 bổ sung: đơn giản hóa quản trị ảnh theo yêu cầu trực tiếp của người
dùng. Đã triển khai web và Rules tại https://healthmate-admin-vn.web.app/.

## Hành vi đã hoàn thành

- Bỏ các ô tên ảnh, tác giả/chủ sở hữu, nguồn ảnh, giấy phép và URL giấy phép.
  Ảnh mới chỉ cần `photo: {mode: 'custom', url: '<HTTPS trực tiếp>'}`.
- Nút **Sửa ảnh** mở form riêng với chế độ ảnh và URL. Không phải nhập lại
  dinh dưỡng hoặc lý do; chỉ ghi field photo. Audit tự ghi lý do thực tế
  “Cập nhật ảnh món ăn”, giữ kiểm tra phiên bản để tránh ghi đè chỉnh sửa khác.
- **Sửa** món đầy đủ vẫn giữ các field và audit theo nghiệp vụ hiện có.
- Giữ chế độ ảnh mặc định/gỡ ảnh, kiểm tra HTTPS không chứa thông tin đăng nhập,
  tải ảnh trước lưu và giữ bản nháp khi lỗi/tự đổi URL trong khi kiểm tra.
- Metadata của ảnh cũ vẫn đọc được. Khi URL không đổi thì lưu lại thông tin
  đã có; khi đổi URL thì không gán thông tin tác giả/giấy phép cũ cho ảnh mới.
  Không tự tạo tác giả hoặc giấy phép để làm đủ trường.
- App chấp nhận ảnh URL-only qua stream catalog; dialog ảnh đang mở cập nhật
  theo. Không hiện dòng tác giả/giấy phép trống hoặc nút mở nguồn thiếu URL.
  Ảnh đi kèm app và ảnh cũ vẫn giữ thông tin nguồn hiện có.
- Rules chỉ thay hàm validCatalogPhoto: mode/url bắt buộc cho custom, các field
  legacy là tùy chọn và có kiểm tra nếu tồn tại. Không mở quyền sửa catalog cho
  user thường, không đổi Auth/App Check, audit, quyền dữ liệu riêng hoặc billing.

## File chính

- Admin: dist/food-photos.mjs, dist/validation.mjs, dist/app.mjs; các test ảnh,
  form DOM, load readiness và realtime-sdk.integration.mjs trong admin-web.
- App: lib/features/nutrition/models/food_photo.dart,
  lib/features/nutrition/presentation/food_photo_thumbnail.dart,
  test/admin_food_photo_test.dart.
- Rules: firestore.rules và rules-tests/admin.rules.test.cjs.

## Kiểm thử thực tế

- `npm --prefix admin-web run check`: qua.
- `npm --prefix admin-web test`: **142/142 qua**. Bao gồm form Sửa ảnh chỉ có
  URL, không có các ô metadata/lý do/dinh dưỡng; payload chỉ photo, reason tự
  ghi, lỗi tải giữ bản nháp và URL, chuyển default/hidden.
- Với đúng Rules dự kiến phát hành trên Auth/Firestore Emulator:
  Rules admin **14/14**, realtime SDK dùng đúng module gói phát hành **16/16**,
  SDK hồi quy **9/9** qua. URL-only lưu được, ảnh cũ có metadata vẫn lưu được,
  đổi ảnh không thay dinh dưỡng, stream nhận cập nhật; user thường/URL sai/
  audit thiếu hoặc sai tiếp tục bị chặn.
- Dart format 3 file: qua; targeted analyze 3 file: **No issues found**.
- `flutter test --no-pub test/admin_food_photo_test.dart
  test/food_photos_test.dart test/food_detail_ui_test.dart`: **19/19 qua**.
  URL-only không tự bịa credits, ảnh đổi trong card/dialog đang mở; regression
  ảnh đi kèm, dinh dưỡng/khẩu phần và bố cục sáng/tối qua.
- `git diff --check` phạm vi sửa và syntax module gói: qua.
- Không chạy toàn bộ Flutter suite hoặc build Android trong lượt này.

## Phát hành và việc cần thực hiện

- Backup Rules/Hosting trước deploy và tái kiểm baseline ngay trước phát hành.
  Dựng gói từ đúng site đang chạy, chỉ đổi 3 module web nêu trên; Rules chỉ thay
  validCatalogPhoto, không phát hành chênh lệch local khác đang chờ.
- Firebase deploy `--only firestore:rules,hosting`: exit0, 430 file, upload 3.
  Hosting version `sites/healthmate-admin-vn/versions/3ff1559b0dd77f75`;
  Ruleset `projects/healthmate-app-20261013/rulesets/8d0a195f-8424-4b0e-ae67-a235dc922615`.
- Đọc lại 6 URL qua HTTPS: HTTP200, bytes khớp candidate, no-store/CSP đúng.
  Rules đọc lại khớp SHA256 chuẩn hóa
  `a26a7dd0274d83eeaaf9462552f6b990556ce2fb6eff0c157712b9a850fc139d`.
- Người dùng giữ URL đang nhập, **Ctrl+F5** tab admin, chọn **Sửa ảnh**, chọn
  ảnh từ HTTPS, dán URL và lưu. App Chrome đang chạy cần **Hot Restart một lần**
  trong VS Code để nạp bộ đọc ảnh mới. Sau đó thay dữ liệu ảnh tiếp tục nhận qua
  realtime, không cần restart cho mỗi lần đổi ảnh. App Android cần build mới
  có bộ đọc ảnh này; chưa build/cài hoặc nghiệm thu thiết bị thật.
- Không ghi kiểm thử vào catalog production, không tự chỉnh món hay ảnh thật.
  Chưa thao tác lưu bằng phiên admin thật. Host ảnh ngoài có thể không tải được;
  web báo lỗi và giữ bản nháp khi gặp trường hợp đó.
- Compiler còn cảnh báo knownNumber chưa dùng từ Rules baseline; biên dịch và
  phát hành thành công. Không thay hàm đó vì ngoài phạm vi.
- Logs/candidate: build/admin-photo-url-only-20261111/; unit logs bổ sung
  build/admin-photo-only-unit.log và build/admin-url-photo-unit.log.
- Đề xuất tiếp: nghiệm thu đổi URL ảnh bằng phiên người dùng; chưa triển khai
  giai đoạn khác hoặc mở quyền quản trị rộng hơn yêu cầu.
