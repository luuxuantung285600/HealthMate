# 08/11/2026 — Giai đoạn 10: độ tin cậy thanh toán Premium

## Phạm vi và trạng thái

Tiếp tục yêu cầu “còn gì thì làm tiếp đi” trong giai đoạn 10, tập trung sửa
luồng Google Play đã thêm ngày 07/11. Đây là thay đổi source và kiểm thử local.
Chưa có Play Console; người dùng để Blaze, nghiệm thu Android thật và ký phát
hành lại sau. Không deploy hoặc mở thu tiền trong lượt này.

## Hành vi đã hoàn thiện

- Một tài khoản có cả giao dịch thật và thử vẫn giữ membership production.
  Giao dịch thử có thể được xác minh, ghi ledger riêng và acknowledge, nhưng
  không thay thế gói thật, kể cả có timestamp mới hơn hoặc gói thật đã hết hạn.
  Gói thật đã xác nhận thay thế membership thử mà không lệ thuộc timestamp thử.
- Máy chủ yêu cầu đủ thời gian bắt đầu/kết thúc hợp lệ trước khi cấp gói
  active/grace/canceled còn hạn. Giá vẫn lấy từ Google Orders; không suy giá
  từ app, gói niêm yết hoặc số tiền client gửi.
- Callable trả thêm `completionAllowed` rõ ràng. Chỉ true sau Google đã
  acknowledge hoặc acknowledge phía máy chủ thành công. App không tự hoàn
  tất giao dịch chưa được xác minh hoặc đang pending. Pending đã bị hủy không
  được acknowledge và không còn bị coi là thanh toán đang chờ vô hạn.
- Khởi tạo, tải gói, khôi phục và xác minh có chặn chạy chồng. Callback cùng
  token đang xếp hàng/xác minh chỉ được xử lý một lần; lần gia hạn/khôi phục
  về sau vẫn xác minh lại được. Pending không bị xóa chỉ vì restore chưa trả
  sự kiện; callback kết thúc có token vẫn xử lý được pending trước đó thiếu token.
- Có timeout cho callable/Google Play. Phản hồi xác minh về sau timeout hoặc
  sau đăng xuất không được dùng để complete trên app. Người dùng có đường
  khôi phục mà không phải mua lại. Giá/gói tải muộn từ tài khoản cũ không được
  gắn vào checkout của tài khoản mới; checkout gắn đúng cấu hình/tài khoản.
- RTDN kiểm tra package và đúng một loại payload. JSON hỏng, mã đơn/token
  sai hoặc thông báo bị từ chối vĩnh viễn được ghi mã lỗi đã lọc rồi kết thúc;
  lỗi dịch vụ tạm thời được retry. Mọi grant vẫn đọc lại Google Publisher.
  Không log raw token, SDK error, OAuth header hoặc dữ liệu người mua.
- Nhận diện `pendingRefundReviewNotification` để ghi tín hiệu cần xử lý trong
  Play Console. Không tự phê duyệt/từ chối hoàn tiền. Thông báo test và sản
  phẩm mua một lần không cấp Premium. Loại subscription notification mới có
  mã số nguyên dương vẫn dẫn đến đọc lại trạng thái hiện tại.
- Dashboard hiển thị “Chờ đối soát” thay số tiền cũ khi Orders đang lỗi.
  Giao dịch đó bị loại khỏi tổng và số người mua; xuất Excel cũng không đưa
  số tiền cũ ra như đã xác nhận. Order trùng ở document khác, flag pending sai
  kiểu hoặc trạng thái refund mâu thuẫn với số tiền làm báo cáo báo lỗi và
  ngừng xuất dữ liệu cũ. Callback lỗi đi qua cùng cơ chế hiển thị lỗi của trang.
- Link quản lý thuê bao xử lý được lỗi mở ứng dụng ngoài. Nút khôi phục/tải
  lại phản ánh thao tác hiện đang chạy.

## File chính

- `firebase-functions/src/billing-{model,service,functions,notifications}.cjs`,
  `firebase-functions/package.json`, tests unit/notification/emulator.
- `lib/features/premium/{models,data,providers,presentation}/`:
  models/callable/store adapter/controller và màn hình Google Play.
- `test/play_billing_test.dart`, `test/play_store_test.dart`.
- `admin-web/dist/{dashboard-page,verified-revenue,live-scope}.mjs`,
  `admin-web/test/{verified-revenue,app-dom}.test.mjs`.
- Báo cáo này, database design, implementation progress, test report và README.

Không thêm dependency, collection/index hoặc thay Security Rules trong đợt
08/11 này. Giữ nguyên thay đổi chưa commit của các đợt trước.

## Kiểm thử thực tế

| Lệnh / kiểm tra | Kết quả |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib/features/premium test/play_billing_test.dart test/play_store_test.dart` | Qua; 13 file, 0 thay đổi ở lần kiểm cuối |
| `flutter analyze --no-pub` | No issues found, 91,4 giây |
| `dart analyze lib/features/premium test/play_billing_test.dart test/play_store_test.dart` sau chỉnh cuối | No issues found |
| `flutter test --no-pub --reporter expanded` | 1.040/1.040, 0 skip, 126 giây |
| Kiểm lại hai file billing test sau chỉnh queue/pending cuối | 18/18 |
| `npm test --prefix firebase-functions` | 29/29, 0 skip |
| `npm test --prefix admin-web` | 93/93, 0 skip |
| `npm test --prefix chat-api` | 49/49, 0 skip |
| `node --test tool/release_preflight.test.cjs` | 6/6 |
| Functions/admin syntax và `check:billing` | Qua |
| Firebase Emulator Rules | 143/143 |
| Billing Firestore owner/admin SDK listeners | 2/2; sau sửa cuối chạy lại 2/2, 0 skip, 3,9 giây |
| `tool/build_android.ps1` | Runtime config 7/7; debug APK build thành công, Gradle 38,1 giây |
| `node tool/audit_source_secrets.cjs` | 690 source text files, 0 findings; không quét APK/credential store |
| `git diff --check` | Qua |

Các kiểm thử dùng receipt fixture được đánh dấu và Firebase Emulator; không
tạo khoản thu Google thật. Ở lần chạy emulator riêng sau sửa cuối, một ca
listener timeout khi Rules/emulator khởi động lạnh; đã thêm bước đọc/xác nhận
baseline trống từ máy chủ trước khi đo thay đổi, giữ nguyên deadline listener
10 giây và toàn bộ assertions nghiệp vụ. Không tăng timeout để che lỗi.
Lần chạy lại cuối qua cả 2/2. Emulator được dừng sau kiểm thử.

APK kiểm thử: `build/releases/healthmate-billing-reliability-20261108-debug.apk`
(237.503.937 byte). SHA-256:
`8171AF85C79721B3FF2AF215C93F9B879590EA84875BD93E0129C6B485622A53`.
Billing/demo mặc định tắt; APK không chứng minh mua qua Google đã hoạt động.
Build còn cảnh báo Kotlin Gradle Plugin từ các plugin hiện có; build vẫn qua.

Log local nằm trong `build/billing-reliability-*.log` (ignored). Bản toàn bộ
Flutter qua trước chỉnh queue/pending nhỏ cuối, đã kiểm lại 18 ca liên quan
sau chỉnh đó. Không gọi các kết quả local là kết quả GitHub Actions.

## Việc còn cần người dùng và giới hạn

1. Tạo Play Console/app, chốt applicationId và sản phẩm/base plan. Chuẩn bị
   quyền Google Play Developer API cho danh tính máy chủ, không đưa credential
   vào client/repository.
2. Bật Blaze khi sẵn sàng, cấu hình env, App Check/Play Integrity, IAM và RTDN;
   review rồi triển khai Functions/Rules/index/admin/gateway tương thích.
   Production chưa nhận thay đổi source local này.
3. Nghiệm thu license tester trên testing track: mua, pending, hủy, restore,
   mất mạng, đổi tài khoản, gia hạn, hết hạn, grace/hold và refund; đối chiếu
   doanh thu admin với đơn Google. Chỉ sau bằng chứng này mới xem xét mở bán.
4. Ký phát hành và Android thật vẫn theo yêu cầu để sau. APK debug không chứng
   minh thanh toán Google sandbox/live hoạt động. Billing/demo mặc định tắt.

Hệ thống RTDN bất đồng bộ và job bù có giới hạn; không hứa tức thì khi mất
mạng. Chưa tự backfill mọi kỳ gia hạn bỏ lỡ hoặc refund token quá cũ Google
không còn cho đọc; cần đối chiếu Play Console trước chốt sổ. “Còn sau hoàn”
chưa trừ phí/thuế, không phải tiền ngân hàng nhận. Refund review hiện chỉ ghi
log cần xử lý, chưa có kênh thông báo/nhắc hạn vận hành được nghiệm thu.

Các giới hạn SDK/cấu hình và cảnh báo dependency của bản 07/11 giữ nguyên;
không nâng major hàng loạt. Node local 24, Functions khai báo Node 22; runtime
cloud chưa nghiệm thu. Chính sách giữ biên nhận/token khi xóa account cần chốt
trước production. Xem hướng dẫn cấu hình và giới hạn đầy đủ trong
[bản 07/11](google-play-billing-2026-11-07.md).

## Giai đoạn kế tiếp đề xuất

Nghiệm thu Google Play sandbox sau khi có Play Console/Blaze. Chỉ đề xuất;
không tự triển khai thêm giai đoạn hoặc phát hành.

## Tài liệu đối chiếu

- https://developer.android.com/google/play/billing/rtdn-reference
- https://developer.android.com/google/play/billing/security
- https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptionsv2
- API và kiểu của các package đã khóa trong `pubspec.lock`.
