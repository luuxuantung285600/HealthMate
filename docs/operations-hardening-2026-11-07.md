# Giai đoạn 10 — Sửa vận hành app và admin, 07/11/2026

Phạm vi: hoàn thiện các luồng hiện có: xóa tài khoản, hỗ trợ hai chiều, quản trị
danh mục và đồng bộ. Giữ Spark, không bật billing, không triển khai Functions
hoặc mở thêm tính năng nghiệp vụ.

## Nguyên nhân và thay đổi

Lần triển khai Spark ngày 06/11 lấy Rules production cũ làm mẫu rồi thêm quyền
thống kê. App hiện tại đã dùng deletion job, support quota và queryPartition.
Vì vậy kiểm thử source không chứng minh được tương thích của bundle đã publish.
Đọc lại ngày 07/11 xác nhận production cấm tạo account_deletions và thiếu
support_usage. Đây là lỗi tương thích, không phải yêu cầu bật Blaze.

Tool đóng gói nay sao chép nguyên Rules chuẩn của repository. Backup production
chỉ dùng đối chiếu/khôi phục có kiểm soát. Runner so sánh release với source
trước khi chạy Rules/repository tests. Test hồi quy dùng baseline cũ và kiểm
tra bundle vẫn chứa contract mới. Không deploy bằng template quyền lỗi thời.

- **Xóa tài khoản:** tạo job yêu cầu UID chính chủ, email xác minh và xác thực
  lại gần đây. Job độc lập với profile, tiến độ chỉ đi tới. Từ khi job được
  xác nhận, chặn ghi sản phẩm của UID trên các thiết bị. Owner được dọn dữ
  liệu đã kiểm kê kể cả khi suspended; không được xóa/reset job để dùng lại.
  Xóa messages trước parent, theo batch, xác minh server rồi mới xóa Auth.
  Giữ audit bất biến; có thể tiếp tục sau gián đoạn. Client không tự nhận
  rằng một worker máy chủ đã xác minh hoàn tất.
- **Hỗ trợ:** ticket và hạn mức cùng transaction. Rules bảo vệ 3 yêu cầu mới/
  ngày Việt Nam, cách nhau ít nhất 60 giây. Retry cùng ID/nội dung không tạo
  phiếu hoặc trừ hạn mức lần nữa. App xác minh đúng nội dung server trước khi
  báo thành công, phân biệt lỗi quyền với lỗi kết nối. Replies/status có
  listeners. Admin phân trang updatedAt giảm dần, ID giảm dần, giữ nanosecond;
  yêu cầu mới không bị bỏ ngoài trang đầu vì ID ngẫu nhiên.
- **Bản nháp admin:** snapshot mới không thay ô tìm kiếm đang gõ. Bản nháp
  reply được giữ khi lưu trạng thái/tải lại thread. Lần gửi chưa rõ kết quả
  giữ ID để retry. Có nút về mới nhất và thử lại khi lỗi kết nối.
- **Món ăn:** thao tác quản trị dùng transaction, kiểm tra phiên bản và audit.
  App nghe catalog Firestore; sửa/ẩn/khôi phục không sửa snapshot bữa đã lưu
  hoặc tự thêm món vào nhật ký khách. Stream danh mục dùng yield* để việc
  hủy listener hoàn tất cả khi máy chủ chưa phát snapshot tiếp theo.

## Kiểm thử và triển khai

Đã triển khai Rules và Hosting lên https://healthmate-admin-vn.web.app ngày
07/11/2026, khoảng 14:20 UTC+7. Đọc lại Rules lúc 14:20:53 xác nhận khớp
source/release; toàn bộ **27 tệp Hosting** khớp byte, có CSP và no-store.
Ruleset: `0fd10032-ee4d-4593-bdd4-21ac65c93ba5`.
SHA256 Rules chuẩn hóa:
`6504f7f66ed8054537fe74b30ebc4685ab7f63adfac6a959af42c7f2b8310c8f`.
Bundle: `build/operations-release-20261107-v2/`. Bản Rules cũ để đối chiếu/
rollback: `build/operations-final-predeploy-20261107/`; không tự rollback
về bản đã biết thiếu quyền. Billing đọc lại vẫn false; config không có Functions.

| Kiểm tra | Kết quả thật |
| --- | --- |
| Rules trên đúng contract release, hai UID và truy cập chéo | **129/129** |
| Flutter SDK hỗ trợ/xóa tài khoản, gián đoạn/offline/thiết bị cũ | **12/12** |
| Web SDK dùng module admin thật | **9/9** |
| Web SDK realtime Spark, bộ đếm/cursor/support | **8/8** |
| Flutter SDK ba client app/thiết bị thứ hai/admin | **6/6** |
| Web DOM/unit và syntax | **71/71**, syntax qua |
| Flutter unit/widget trước sửa cuối vòng đời catalog | **952/952**, 0 bỏ qua |
| Hồi quy nutrition/catalog/search/realtime sau sửa cuối | **29/29** |
| flutter analyze --no-pub sau sửa cuối | **No issues found**, 61,1 giây |
| Kiểm cấu hình admin cho APK | **7/7** |
| flutter build apk --debug --no-pub với cấu hình hiện có | Qua, Gradle 18,2 giây |
| dart format hai file Dart sửa cuối | Qua |
| Source secret audit | **651 file / 0 findings**; không phải audit APK/credential store |

Log giữ cả lần thất bại. Test ba SDK trong cùng Chrome ban đầu cạn socket
HTTP/1.1 của emulator; admin dùng host loopback riêng để mô phỏng các thiết
bị có kết nối độc lập. Fixture audit cũng được sửa để ghi đúng các field
thực thay đổi như module production, không thay/nới Rules để qua test.
Ca hủy stream có deadline 3 giây; đã qua sau sửa yield*.

Dữ liệu fixture chỉ nằm trên emulator project demo-. Không seed món, khách
hàng hoặc giao dịch giả lên production. Không xóa tài khoản khách thật để test.

Lệnh tái lập: npm test --prefix admin-web, npm run check --prefix admin-web,
flutter analyze --no-pub, flutter test --no-pub --reporter json. Hai runner
tool/test_operations_local.cjs và tool/test_operations_admin_local.cjs chạy
trong emulators:exec với firebase.emulators.json / firebase.admin-emulators.json.
Runner đầu cần HEALTHMATE_OPERATIONS_RELEASE trỏ tới bundle dưới build;
Chrome adapter cấu hình giống tool/test_emulators.ps1.

Bằng chứng: `build/operations-emulator-test.log`,
`build/operations-admin-sdk-verified.log` (hai suite Node qua, giữ cả lỗi
Flutter cũ), `build/operations-flutter-sdk-final.log` (6/6 cuối),
`build/operations-nutrition-regression-final.log`,
`build/operations-flutter-summary.json`, `build/operations-deploy.log`,
`build/operations-production-verified-20261107/metadata.json`,
`build/operations-hosting-readback.json`.

## File chính

- `firestore.rules`, `admin-web/tool/prepare-realtime-release.cjs` và
  `admin-web/test/release-contract.test.mjs`: contract triển khai chuẩn.
- `admin-web/dist/server-paging.mjs`, `firebase.mjs`, `live-data.mjs`,
  `support-page.mjs`, `support-model.mjs`: hỗ trợ/cursor/realtime/bản nháp.
- `lib/features/support/data/firebase_support_repository.dart`,
  `lib/features/support/models/support_models.dart`: xác minh ghi và lỗi.
- `lib/features/nutrition/data/firebase_nutrition_repository.dart`: hủy stream.
- `test/realtime_spark_integration.dart`, hai runner `tool/test_operations*`,
  các test admin và tài liệu tiến độ/database/test: kiểm chứng và vận hành.

## Giới hạn cần giữ rõ

Spark chưa có worker đặc quyền chạy nền. Nếu đóng app giữa lúc xóa, khách cần
mở lại và tiếp tục. Các scope đã biết được xác minh rỗng, chưa phải chứng nhận
xử lý mọi orphan legacy hoặc mọi tham chiếu danh tính của admin. Tombstone
tối thiểu được giữ để chặn token/write cũ; purge theo thời hạn cần server.

Tổng Firebase Auth vẫn là snapshot thật, có thời điểm và nhãn thủ công.
Directory realtime là danh sách hồ sơ quản trị, không thay tổng đăng ký.
Premium hiện là demo có nhãn, bị tắt trong APK hiện có; chưa có thanh toán
thật/webhook. Các trang quản trị ghi chờ triển khai chưa có nghiệp vụ tương ứng.

APK debug phục vụ kiểm thử riêng, chưa phải bản ký phát hành store. Emulator
không thay nghiệm thu Android thật, App Check và hai thiết bị trên production.
Không tạo/xóa tài khoản thật để chứng minh luồng xóa.

Bản APK cuối: `build/releases/healthmate-operations-20261107-debug.apk`,
build lúc 14:21:18 UTC+7, 237.017.697 byte, SHA256
`98D835C0AC3EFB26585EF1297A5BF4847D023409A08016A6CBB1D33050A0E211`.
Admin controls bật, server revisions tắt (Spark), dùng cấu hình App Check debug
cục bộ đã có. Cần cài bản này để nhận phần sửa client. `adb devices -l` không
có thiết bị, nên chưa cài hoặc kiểm thử trên Android thật. Không in/lưu debug
token vào báo cáo. Log build: `build/operations-apk-build-final.log`.

Build có cảnh báo tương thích KGP cho phiên bản Flutter tương lai; không
chặn build hiện tại. Firebase Rules compile có cảnh báo knownNumber chưa dùng.
Không nâng dependency hoặc thay logic chỉ để xóa các cảnh báo đó.

Tiếp theo đề xuất: nghiệm thu thiết bị thật; khi người dùng sẵn sàng bật Blaze,
triển khai worker/bộ đếm Auth đã được duyệt sau khi đánh giá lại baseline và
chi phí. Không thực hiện bước đó trong đợt này.
