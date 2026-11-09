# Premium Google Play — tích hợp và điều kiện mở bán, 07/11/2026

## 1. Giai đoạn và trạng thái

Giai đoạn 10 mở rộng theo yêu cầu thanh toán thật. Đã viết luồng tích hợp
Google Play Billing trên Android, xác minh máy chủ Firebase, cập nhật quyền
Premium, báo cáo admin và bộ kiểm thử local. **Chưa mở bán, chưa deploy phần
này và chưa có giao dịch Google thật/sandbox.** Chủ dự án xác nhận chưa có
Play Console; Blaze trước đó được để bật sau. Nghiệm thu Android thật và ký
release tiếp tục hoãn theo yêu cầu trước đó.

Không dùng chuyển khoản/QR để mở khóa nội dung số trong ứng dụng. Không tạo
product ID hay biên nhận giả trong luồng sản phẩm. Giá fixture 29.000 VND chỉ
nằm trong test/emulator/ảnh có nhãn kiểm thử; không seed production.

## 2. Hành vi đã triển khai

- Cá nhân → HealthMate Premium. Bản mặc định báo chưa mở bán; không kết nối
  SDK thanh toán hoặc đọc membership nếu chưa bật cờ client.
- Khi được cấu hình: tải sản phẩm/base plan từ Google, chỉ nhận gói tự gia
  hạn tháng `P1M`, một pha giá, không trial/offer/installment. Hiển thị giá
  Google trả về, điều khoản tự gia hạn và cửa sổ checkout của Google.
- Purchase stream sống theo phiên đăng nhập của app. Pending/hủy/lỗi không
  cấp quyền. Gửi token lên callable có Firebase Auth và App Check; hoàn tất
  giao dịch chỉ sau khi máy chủ xác minh. Có khôi phục khi cài lại, mất mạng
  hoặc đã trả tiền nhưng chưa xác nhận; không yêu cầu mua lại để thử lại.
- Máy chủ dùng Android Publisher `purchases.subscriptionsv2.get`, kiểm tra
  product/base plan, account ID được băm và UID sở hữu token. Client không
  cung cấp giá hay thời hạn có giá trị quyết định.
- Trạng thái active/grace/canceled còn hạn được dùng; on hold/paused/pending/
  expired không cấp quyền. Hủy gia hạn giữ thời gian đã mua. Thời hạn còn được
  kiểm tra ở gateway AI mỗi yêu cầu, không chỉ phụ thuộc listener.
- Acknowledge trên máy chủ sau khi ghi quyền bền vững. Lặp cùng order không
  nhân doanh thu. Khóa theo UID tuần tự hóa đối soát; sự kiện RTDN luôn đọc
  lại trạng thái Google, không cấp quyền theo nội dung thông báo.
- RTDN Pub/Sub nhận gia hạn/thay đổi/voided order. Job mỗi 6 giờ kiểm tra tối
  đa 100 token cũ nhất với ba worker và deadline; sửa lần đọc Orders lỗi.
  Đây là vòng bù hữu hạn, không cam kết độ trễ cho quy mô lớn.
- Giá tiền thực tế từ `orders.get`, tính bằng số nguyên nanos dưới dạng chuỗi.
  Tiền khách trả, hoàn thành công và còn sau hoàn tách theo tiền tệ; không
  đổi USD thành VND hoặc gọi số này là tiền ngân hàng nhận.
- Dashboard và trang Doanh thu mặc định là Google Play production, có chế độ
  Google Play thử nghiệm và demo riêng. Listener server cập nhật khi có thay
  đổi, phân trang 25 mục, tổng hợp tối đa 5.000 mục/kỳ, có xuất Excel.
- Orders chưa đọc được không gán giá mặc định. Đơn đã biết nhưng lần đối soát
  lỗi giữ bằng chứng cũ và đánh dấu chờ đối soát, loại khỏi tổng hiện tại.
- Gateway chatbot đọc membership đã xác minh: 50 lượt/ngày thay vì 5; test
  chỉ được tăng quota khi cấu hình máy chủ cho phép. Không hứa tăng quyền
  quét ảnh vì dịch vụ scanner hiện chưa hoàn tất.
- Đổi tài khoản bỏ kết quả UI đang chờ; biên nhận của A không cấp quyền cho B.
  Suspend/deletion bị kiểm tra trong giao dịch server và gateway. Xóa tài
  khoản có lời nhắc hủy gói Google Play; không tự hủy gia hạn với Google.

## 3. File chính

- `lib/features/premium/{data,models,providers,presentation}/play_*` và
  `firebase_play_billing` nằm trong `data/play_billing_repository.dart`.
- `lib/app.dart`, `profile_screen.dart`, `account_security_dialogs.dart`.
- `firebase-functions/src/billing-{model,service,functions}.cjs`,
  `play-publisher.cjs`, `src/index.cjs`, `.env.example`.
- `chat-api/src/ai-policy.mjs`; admin `play-revenue-page.mjs`,
  `verified-revenue.mjs`, dashboard, live queries và server paging.
- `firestore.rules`, `firestore.indexes.json`; tests Flutter, Functions,
  gateway, admin, Rules và `firebase-functions/test/billing.emulator.cjs`.

Thêm `in_app_purchase` 3.3.1, `in_app_purchase_android` 0.5.5 cho checkout và
base plan/account binding; `cloud_functions` 6.5.1 cho callable và
`url_launcher` 6.3.3 để quản lý đăng ký trên Google. Resolver cập nhật
firebase_core 4.15.0 → 4.15.2 vì cloud_functions yêu cầu >=4.15.1.
Backend thêm google-auth-library 11.3.3 cho ADC/OAuth; không có key JSON.

## 4. Kiểm thử

Kết quả cuối được ghi trong `docs/test-report.md`. Log trong `build/billing-*`.
Flutter 1030/1030; analyzer sạch; Functions 17/17, admin 90/90, gateway 49/49,
Rules 143/143, billing emulator 1/1 qua. APK debug build thành công.
Fixture Google chỉ dùng để kiểm thử ranh giới Publisher; Firestore transaction,
Rules và Web SDK listener của owner/admin được chạy thật trên emulator.
Các test này **không chứng minh** Play Console/IAM/Google sandbox đã hoạt động.

APK local: `build/releases/healthmate-play-billing-20261107-debug.apk`, SHA256
`1FB295C988293A56C5970057DC4006F26990FE59E8E885A4AF312381D0D97E50`.
Bản này có code tích hợp nhưng `HEALTHMATE_ENABLE_PLAY_BILLING=false` mặc định,
demo cũng tắt; không thể dùng để thu tiền. Rules đã kiểm thử SHA256:
`23AEB58B2F4318C344742F1E40CC1FC7C0899EB9300920FF2092A50045359494`.

## 5. Cần cấu hình trước khi thu tiền

1. Tạo Google Play Console, hoàn tất xác minh và payments profile. Chốt
   applicationId rồi tạo ứng dụng đúng package. Hiện repo vẫn dùng
   `com.example.healthmate`; không tự đổi package/Firebase registration.
2. Tạo subscription và một auto-renew base plan tháng, giá/khu vực, không
   offer/trial/installment trong lần triển khai đầu. Điền ID thật; không dùng
   ID fixture của test làm cấu hình bán.
3. Bật Blaze khi sẵn sàng triển khai Functions; Cloud Scheduler, Pub/Sub,
   Firestore/API và compute có thể phát sinh phí theo sử dụng. Code local
   không bật billing hay tạo merchant account. Đặt budget alert phù hợp.
4. Bật Google Play Android Developer API. Cấp runtime service account của
   Functions quyền cần thiết cho đúng ứng dụng trong Play Console để đọc
   subscriptions/orders và acknowledge. Dùng ADC của runtime, không tải key
   vào Flutter/Git. Kiểm tra quyền read financial/order và manage subscription
   theo giao diện Play Console tại thời điểm cấu hình.
5. Sao chép `.env.example` thành file private
   `firebase-functions/.env.<project-id>`; khai báo package/product/basePlan.
   Mặc định `BILLING_ENABLED=false`, `BILLING_ALLOW_TEST=false`. Bật test ở
   môi trường nghiệm thu; `testPurchase` do Google xác định, không lấy từ app.
6. Publish Rules và index mới; triển khai Functions có scope billing đã review
   qua `firebase.realtime.json`. Chưa chạy lệnh deploy trong lượt này.
7. Pub/Sub topic `healthmate-play-billing` cùng project với Function. Chỉ cấp
   Publisher cho `google-play-developer-notifications@system.gserviceaccount.com`
   và quản trị được ủy quyền; cấu hình RTDN trong Play Console trỏ đúng topic,
   kiểm tra test notification. Không mở HTTP webhook công khai tự cấp quyền.
8. Cấu hình App Check/Play Integrity cho Android production; bản debug chỉ
   dùng debug token được đăng ký riêng. Callables enforce App Check. Không
   tắt enforcement để vượt lỗi nghiệm thu.
9. Cập nhật/deploy gateway AI để đọc membership thật. Biến
   `AI_GATEWAY_ALLOW_TEST_PURCHASES=true` chỉ khi muốn test quota sandbox;
   mặc định không dùng test purchase để tăng quota. Không cần bật premium demo.
10. License testers + testing track trên Play Console. Bản Android kiểm thử
    dùng `HEALTHMATE_ENABLE_PLAY_BILLING=true` và demo=false, trỏ backend đã
    cấu hình. Đăng nhập Google Play bằng tester và HealthMate bằng tài khoản
    đã xác minh. Giá/test payment instrument phải hiển thị từ Google.
11. Nghiệm thu mua, pending, hủy checkout, đổi tài khoản, cài lại/restore, mất
    mạng sau trả tiền, gia hạn sandbox, cancel, grace/hold/expired, refund,
    RTDN trùng/đảo thứ tự, appcheck bị từ chối, admin test không cộng tiền thật.
    Lưu bằng chứng Google Console và timestamp server trước khi cho mở bán.
12. Ký/phát hành chính thức làm sau. Guard release hiện chặn bật Play Billing
    vì hạ tầng và sandbox chưa nghiệm thu, tương tự guard AI hiện có. Chỉ
    thay guard sau một lượt review readiness có bằng chứng, không bỏ kiểm tra.

## Cập nhật tiếp theo 08/11

Đã củng cố concurrency/restore/acknowledge, tách membership production/test,
RTDN malformed/retry và báo cáo số tiền chờ đối soát. Xem
[báo cáo 08/11](billing-reliability-2026-11-08.md) cho contract/kết quả mới;
kết quả kiểm thử và APK ngày 07/11 trong tài liệu này giữ theo lịch sử.

## 6. Giới hạn và phần chưa xác minh

- Chưa có Play Console/product thật, chưa bật Blaze/deploy/IAM/RTDN thực tế.
  Chưa có khoản tiền nào được thu trong lượt này.
- Chỉ Android Google Play; chưa làm iOS, ưu đãi/trial, nâng/hạ gói, installment
  hoặc nhiều gói. UI hiện không mở mua lại khi membership còn hiệu lực.
- RTDN là sự kiện bất đồng bộ; không hứa tức thì tuyệt đối khi mất mạng/dịch
  vụ lỗi. Job bù có giới hạn, không thay thế theo dõi lỗi/đối soát định kỳ.
- Lưu order mới nhất Google trả và các order từ voided notification. Nếu
  bỏ lỡ nhiều kỳ gia hạn trước khi hệ thống nhận thông báo, chưa tự nhập lại
  toàn bộ lịch sử cũ. Cần đối chiếu báo cáo Play Console trước chốt sổ; không
  gọi bảng này là sổ kế toán hoàn chỉnh. Chưa nghiệm thu refund của token cũ
  mà Google không còn cho đọc subscriptionsv2; cần xử lý đối soát khi xảy ra.
- Chưa tự xử lý transfer ownership của subscription hoặc gói mua bên ngoài
  thiếu obfuscated account binding; từ chối thay vì tự gắn vào UID hiện tại.
- Biên nhận tối thiểu/token phục vụ đối soát còn được giữ khi xóa account,
  riêng biệt nhật ký sức khỏe. Cần chốt chính sách lưu giữ/xóa dữ liệu tài
  chính theo vận hành/pháp lý trước production; chưa có TTL pháp lý tự đoán.
- `npm audit` Functions: 6 cảnh báo moderate trong nhánh Firebase Admin /
  google-gax → rimraf/glob/minimatch đã có, không high/critical. Không nâng
  major SDK hàng loạt để che cảnh báo; cần xử lý tương thích trước rollout.
- Local Node 24.18.0; runtime khai báo Node 22, chưa nghiệm thu runtime cloud.

## 7. Tiếp theo đề xuất

Cấu hình Play Console/Blaze và nghiệm thu Google sandbox với dữ liệu thật từ
Google. Chỉ đề xuất, chưa tự làm; không chuyển qua ký phát hành Android.

## Tài liệu chính thức đã đối chiếu

- https://developer.android.com/google/play/billing/security
- https://developer.android.com/google/play/billing/getting-ready
- https://developer.android.com/google/play/billing/test
- https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptionsv2
- https://developers.google.com/android-publisher/api-ref/rest/v3/orders
- https://developers.google.com/android-publisher/api-ref/rest/v3/orders/get
- https://pub.dev/packages/in_app_purchase
- https://firebase.google.com/docs/functions/get-started
