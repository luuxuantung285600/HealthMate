# 10/11/2026 — Hoàn thiện luồng đăng ký Premium trong app

## Giai đoạn và trạng thái

Giai đoạn 10 mở rộng, chỉ hoàn thiện luồng đăng ký Premium qua Google Play
trong HealthMate theo xác nhận của người dùng. Không đăng ký Play Console,
không bật billing, không deploy hoặc mở bán trong lượt này. Phần GIF tập
luyện tiếp tục tạm gác. Các thay đổi font và nhật ký trước đó được giữ lại.

Đã hoàn thiện source và kiểm thử local. Việc mua qua Google Play thật hoặc
sandbox vẫn cần tài khoản Play Console, sản phẩm thật và máy chủ được cấu
hình/triển khai. Không dùng giao dịch fixture để mở Premium production.

## Luồng người dùng

1. Vào Cá nhân → HealthMate Premium. Xem quyền lợi, gói hàng tháng, điều
   khoản tự gia hạn, cách khôi phục và quyền riêng tư ngay trong app.
2. Khi cấu hình chưa sẵn sàng, trang giải thích chưa mở bán và không hiển
   thị giá tự đặt. Khi sẵn sàng, giá lấy từ Google Play cho đúng base plan.
3. Bấm Đăng ký qua Google Play để mở checkout thật của Google. App chặn
   thao tác lặp khi checkout, thanh toán pending hoặc xác minh đang chạy.
4. Callback đã mua được gửi lên máy chủ xác minh. Chỉ hoàn tất giao dịch
   khi máy chủ trả quyền completion rõ ràng. Pending/hủy/lỗi không cấp gói.
5. Nếu xác minh/hoàn tất lỗi, nút mua bị khóa và người dùng được hướng dẫn
   khôi phục giao dịch trước. Khôi phục không tìm thấy receipt không tự
   giải quyết receipt đã biết và không tạo một lần mua mới.
6. Khi máy chủ báo đã cấp quyền nhưng stream membership chưa về, app chờ
   đồng bộ và tiếp tục khóa mua. Chỉ membership đã xác nhận từ máy chủ mới
   làm trang hiện “Premium đang hoạt động”. Không tự cấp quyền từ callback.
7. Khi quay về foreground từ Google Play/ứng dụng khác, listener vòng đời
   của phiên HealthMate truy vấn lại giao dịch bằng restore của SDK. Không
   tạo listener theo mỗi lần mở màn Premium; không restore chồng khi đang
   xử lý và gỡ observer khi đăng xuất/đổi tài khoản.
8. Gói còn hạn nhưng tắt gia hạn vẫn hiển thị quyền dùng đến hết hạn.
   Grace period yêu cầu cập nhật thanh toán; on-hold/paused/pending dẫn
   người dùng quản lý gói đã có thay vì mua thêm. Gói đã hết hạn cho phép
   đăng ký mới khi không còn giao dịch chờ khôi phục.
9. Quản lý/hủy gia hạn mở trang Google Play đúng package và product đã
   cấu hình. Khi không mở được, app hướng dẫn đường đi trong Play Store.
   Màn quyền riêng tư mở rồi quay lại được mà không mất phiên thanh toán.

## Thay đổi kỹ thuật

- `play_billing_controller.dart`: guard `canBuy`, giữ receipt chưa giải
  quyết trong RAM theo phiên, trạng thái chờ membership, xử lý resume và
  restore yên lặng lúc khởi động. Token không được đưa vào log/ảnh/UI.
- `play_billing_models.dart`: đọc cờ `active` đã có trong response của
  server để khóa lần mua tiếp theo; flag này không cấp quyền. Tạo URL quản
  lý và xác định trạng thái subscription còn sở hữu cần quản lý.
- `play_billing_providers.dart`: dùng chung verifiedMembershipProvider
  cho UI/controller, một observer theo phiên; cleanup đúng vòng đời. Tách
  hàm mở Google Play để kiểm tra lỗi launcher không cần mở ứng dụng thật.
- `play_premium_screen.dart`: màn đăng ký đầy đủ kể cả khi chưa mở bán,
  phản ánh trạng thái thật, font Public Sans, nền đen/trắng theo theme.
- Không thêm package, collection, index hoặc sửa Rules/backend. Giá,
  account binding, receipt ownership, acknowledge và ledger vẫn do luồng
  máy chủ đã triển khai trong source kiểm soát.
- `test/play_premium_flow_test.dart`:21 test mới cho recovery, resume,
  stream quyền, sáu trạng thái gói, link quản lý, quyền riêng tư, lỗi đọc
  membership và320px/chữ100–200% sáng/tối. Hai test UI cũ chỉ bổ sung cuộn
  tới nút trước khi kiểm tra; giữ toàn bộ assertion nghiệp vụ.

## Kiểm thử và ảnh

Kết quả cuối của analyze/toàn bộ test/build được ghi trong
`implementation-progress.md` và `test-report.md`.

Kiểm thử tập trung39/39 qua, gồm21 test mới và18 test billing/store hiện có.
Functions syntax qua và29/29 test server hiện có qua. Fixture receipt,
giá29.000đ và membership thử chỉ nằm trong kiểm thử, không được seed lên
cloud. Ảnh `build/premium-flow/ready-light.png` và `ready-dark.png` là ảnh
kiểm thử với fixture này, không phải giao dịch/giá production.

## Các bước còn cần trước khi thu tiền

1. Tạo Play Console và app; chốt package ứng dụng, ký Android và cấu hình
   Firebase tương ứng. Repo hiện dùng `com.example.healthmate`; không tự
   đổi package hoặc tạo sản phẩm với ID giả.
2. Tạo subscription/base plan tháng tự gia hạn, chốt giá/khu vực thật.
   Cung cấp ID thật cho cấu hình máy chủ; ứng dụng lấy giá từ Google Play.
3. Khi chủ dự án sẵn sàng bật Blaze: cấu hình/deploy Firebase Functions,
   Publisher API/IAM, App Check/Play Integrity, RTDN, Rules/index và gateway
   theo [hướng dẫn billing](google-play-billing-2026-11-07.md). Không đưa
   service-account JSON vào app/repository.
4. Cài bản internal testing bằng license tester, bật cờ billing trong bản
   nghiệm thu trỏ đúng máy chủ; giữ demo tắt. Nghiệm thu mua/pending/hủy/
   mất mạng/restore/gia hạn/hoàn tiền và admin nhận ledger test riêng.
5. Chỉ bật mở bán sau khi có bằng chứng sandbox. Nghiệm thu Android thật,
   ký phát hành và deploy vẫn chưa được thực hiện trong lượt này.

## Tài liệu đã đối chiếu

- https://developer.android.com/google/play/billing/integrate
  — truy vấn lại purchases khi kết nối/foreground và không acknowledge
  giao dịch pending.
- https://developer.android.com/google/play/billing/subscriptions
  — trạng thái subscription và quyền lợi đến hạn.
- https://support.google.com/googleplay/android-developer/answer/9900533
  — thông tin đăng ký, giá và gia hạn phải rõ ràng.

## Giai đoạn kế tiếp đề xuất

Cấu hình Play Console/Blaze và nghiệm thu Google Play sandbox khi chủ dự án
sẵn sàng. Chỉ đề xuất; không tự triển khai trong lượt này.
