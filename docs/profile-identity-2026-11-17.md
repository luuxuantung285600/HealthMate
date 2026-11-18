# 17/11/2026 — Tên, ảnh hồ sơ và cỡ chữ

## Phạm vi và trạng thái

Hoàn thành phần bảo trì Giai đoạn 3 theo yêu cầu: đổi tên hiển thị, ảnh đại
diện, ảnh bìa và ảnh nền trang hồ sơ. Kèm điều chỉnh typography mà người dùng
yêu cầu trong cùng lượt. Không triển khai giai đoạn sản phẩm tiếp theo.

## Hành vi

- Chạm ảnh đại diện để mở Không gian cá nhân → Tên & ảnh hồ sơ. Nhập tên,
  chọn ảnh từ thư viện, xem trước, gỡ ảnh từng vị trí rồi Lưu thay đổi.
- Bản nháp chưa ghi trước khi bấm Lưu. Chờ máy chủ xác nhận, chặn gửi lặp,
  giữ bản nháp khi lỗi để thử lại; hủy bản nháp có xác nhận bỏ thay đổi.
- Đổi tài khoản đóng form cũ, bỏ kết quả chọn ảnh của tài khoản trước.
  Màn hồ sơ và avatar không hiển thị ảnh của UID cũ khi phiên đang thay đổi.
- Tên và ảnh dùng listener hồ sơ hiện có. Avatar mới xuất hiện ở những màn
  đã dùng ProfileAvatar; ảnh bìa và ảnh nền chỉ thuộc trang hồ sơ.
- Nền có lớp phủ trung tính để giữ độ đọc ở sáng/tối. Không chọn ảnh thì
  tiếp tục dùng giao diện hiện có. Form sức khỏe vẫn chỉnh riêng như trước.
- Giảm nhẹ cỡ chữ: body chính 16→15, body thường 14→13, title 20→18,
  các heading/chỉ số lớn giảm khoảng 2–4 điểm. Giữ chữ nhỏ tối thiểu theo
  theme là 12, Public Sans, cỡ chữ hệ thống và vùng chạm hiện có.

## Dữ liệu và quyền riêng tư

Thêm map tùy chọn `users/{uid}.profileAppearance`, gồm `avatar`, `cover`,
`background`; từng giá trị là null hoặc base64 của PNG thu nhỏ. Hồ sơ cũ
không cần migration. Atomic update chỉ sửa `displayName`, `profileAppearance`,
`updatedAt`; chiều cao, cân nặng, mục tiêu và createdAt được giữ.

Ảnh được đọc bằng image_picker hiện có, cắt giữa khung, thu nhỏ và mã hóa
lại thành PNG: avatar160×160, bìa640×240, nền400×640. Mỗi ảnh tối đa64KiB;
ảnh nhiều chi tiết được giảm kích thước thêm để đạt giới hạn. Tổng ba chuỗi
tối đa262.152 ký tự, dưới giới hạn document Firestore1MiB cùng hồ sơ hiện có.
Không lưu tệp gốc, tên tệp, EXIF hay vị trí chụp. Input tối đa8MiB/40MP;
model kiểm chữ ký PNG, kích thước và giới hạn dung lượng trước khi hiển thị.
PNG lỗi trả về fallback; Security Rules giới hạn chuỗi/field/quyền sở hữu,
không phải bộ giải mã hoặc kiểm định nội dung ảnh.

Quyền đọc/sửa vẫn theo UID, email đã xác minh và kiểm soát tài khoản hiện có.
Admin thông thường không đọc được ảnh riêng tư của người dùng. Xóa hồ sơ
qua quy trình xóa tài khoản hiện có cũng xóa các ảnh trong document đó.
Không thêm collection, dependency, Cloud Storage hoặc dịch vụ trả phí.

Miễn lập chỉ mục cho map `users.profileAppearance`; ba subfield kế thừa cấu
hình này. Có cấu hình trong `firestore.indexes.json`. Triển khai thực tế dùng
REST Admin PATCH chỉ field này với updateMask=indexConfig; giữ các composite
index đang có. Không deploy toàn bộ indexes local vì có cấu hình khác ngoài
phạm vi chưa được đưa lên production.

Nguồn API được kiểm tra trong lượt này:

- https://firebase.google.com/docs/firestore/query-data/index-overview
- https://firestore.googleapis.com/$discovery/rest?version=v1

## File chính

- `lib/core/theme/app_theme.dart`, `lib/core/widgets/{metric_value,profile_avatar}.dart`;
  các số lớn ở dashboard, workout và wellness.
- `lib/features/profile/models/{profile_appearance,user_profile}.dart`.
- `lib/features/profile/data/{profile_image_picker,health_profile_repository,firebase_health_profile_repository}.dart`.
- `lib/features/profile/providers/profile_providers.dart`.
- `lib/features/profile/presentation/{profile_identity_dialog,personal_overview,profile_screen}.dart`.
- `firestore.rules`, `firestore.indexes.json`.
- `test/profile_identity_test.dart`, `test/firebase_repository_integration.dart`,
  `test/support/{test_app,fake_health_profile_repository}.dart`.
- `rules-tests/profile-appearance.rules.test.cjs` và ba tài liệu tiến độ,
  thiết kế dữ liệu, báo cáo kiểm thử.

## Kiểm thử thực tế

- `dart format --output=none --set-exit-if-changed` với21 file Dart trong
  phạm vi:0 thay đổi, exit0. Test capture sau đó đã được format lại.
- `flutter analyze --no-pub`: No issues found, exit0,40,6giây.
- `flutter test --no-pub` với12 suite: **138/138 qua**, exit0,43giây:
  `profile_identity`, `profile`, `profile_quality`, `ui_readability`,
  `navigation_features`, `ux_onboarding`, `workout_ux`, `home_reference`,
  `icon_system`, `progress_comparison_ui`, `play_premium_flow`,
  `auth_flow_capture` (hậu tố `_test.dart`).
- Chạy lại `profile_identity_test.dart` sau chỉnh vị trí cuộn ảnh kiểm thử:
  **10/10 qua**, exit0,9giây. Không cộng lặp vào138 ca ở trên.
- Firestore emulator chạy `profile-appearance.rules.test.cjs` và
  `firestore.rules.test.cjs`: **61/61 qua**, exit0,17,6giây. Có chủ sở hữu,
  UID khác/guest/email chưa xác minh/admin, field/dung lượng sai, ba ảnh
  tối đa, tài khoản bị khóa/xóa và cleanup. PERMISSION_DENIED ở các ca
  bị từ chối là kết quả được mong đợi.
- Firebase Auth/Firestore SDK thật trên Chrome + demo emulator:
  **1/1 qua**, exit0,6giây, ca
  `profile identity saves real thumbnails, preserves health fields and enforces UID privacy`.
  Kiểm snapshot listener, đọc server, timestamp, giữ field sức khỏe/createdAt,
  sửa hồ sơ sức khỏe không mất ảnh, gỡ ảnh, đăng nhập lại và chặn UID khác.
  Dùng Chrome adapter có sẵn chỉ phục vụ CanvasKit nguyên bản SDK trong
  browser kiểm thử; không mock Firebase hoặc sửa SDK/app cho lượt test.
- `flutter build web --release --no-pub --output build/profile-personalization-20261117/web`:
  qua, exit0,107,5giây. Cảnh báo Wasm dry run do mobile_scanner dùng API web
  cũ vẫn còn; bản JavaScript build thành công. Chưa kiểm build Wasm.
- Đã xem render sáng/tối của hồ sơ và form với Public Sans/Tabler thật;
  có kiểm320px/chữ hệ thống2x và390px/chữ1x, chọn/gỡ ảnh, lỗi/thử lại,
  chờ xác nhận/chặn gửi lặp và đổi UID khi đang chọn ảnh. Ảnh render dùng
  fixture kiểm thử, không phải dữ liệu tài khoản thật.
- `git diff --check` trong các file được kiểm tra: qua. Cảnh báo LF/CRLF
  chỉ phản ánh cấu hình Git Windows.

Log/ảnh/bản build nằm trong `build/profile-personalization-20261117/`:
`regression-final.log`, `identity-final.log`, `analyze-final-verified.log`,
`rules-first.log`, `sdk-emulator.log`, `build-web-final.log`,
`profile-{dark,light}.png`, `editor-{dark,light}.png`.

Các lượt đầu: một fixture đổi tài khoản vẫn trả hồ sơ UID cũ gây chờ router;
đã cung cấp hồ sơ đúng UID và giữ assertion bảo vệ phiên. Các lint import/
ngoặc khối đã sửa. Sửa clip avatar để đúng hình tròn. Test bấm lặp dùng
tọa độ nút đang bị AbsorbPointer chặn và kiểm callback đã vô hiệu hóa,
thay cho finder.tap gây cảnh báo hit-test. Không bỏ assertion để che lỗi.

## Triển khai Firebase

Project `healthmate-app-20261013`. Đã sao lưu Rules hiện hành và kiểm tra
chưa có thay đổi bên ngoài trước khi deploy. Diff chỉ thêm validation và
field tùy chọn profileAppearance, giữ quyền sở hữu và các ràng buộc cũ.

- `firebase deploy --only firestore:rules --project healthmate-app-20261013`:
  exit0. Compiler có cảnh báo hàm knownNumber chưa dùng vốn đã có.
- Đọc lại Rules sau deploy: khớp local, SHA256
  `7de62433599cde156052ff9a4314d9411299625917539710cc0b03e48ca4bc31`.
- Ruleset:
  `projects/healthmate-app-20261013/rulesets/d73c34a3-94e4-475e-ab2e-1b1900dba5c9`.
- Single-field index exemption đã áp dụng và đọc lại đủ ba subfield kế thừa;
  ba composite indexes production vẫn khớp trước/sau.
- Backup ở `production-before/`, kiểm tra lại ở `production-after/`,
  metadata field trước/sau trong `profile-index-{before,after}.json`.
  Không ghi dữ liệu kiểm thử vào users production, không push Git hoặc
  deploy app/admin/Hosting/Functions trong lượt này.

## Cần người dùng làm và giới hạn

Hot Restart hoặc dừng/chạy lại app, sau đó mở ảnh đại diện → Tên & ảnh hồ sơ.
Không cần cấu hình Firebase mới. Chọn ảnh bằng hộp thoại thư viện thật trên
Android vẫn cần người dùng nghiệm thu trên thiết bị; chưa ký/phát hành.
Ảnh hiện là bản thu nhỏ/cắt giữa, chưa có kéo chỉnh vùng cắt. Ảnh nền chỉ
áp dụng trang hồ sơ. Cập nhật nhận diện đồng thời trên nhiều thiết bị dùng
cơ chế lần lưu sau cùng của document Firestore hiện tại.

Không có lỗi chặn đã biết trong phạm vi kiểm thử. Đề xuất tiếp: Giai đoạn10
— nghiệm thu hồ sơ trên thiết bị thật; chỉ đề xuất, chưa thực hiện.
