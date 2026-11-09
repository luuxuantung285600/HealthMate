# Chất lượng Android và phục hồi thao tác — 07/11/2026

Phạm vi: Giai đoạn 10, kiểm thử và sửa độ tin cậy của các luồng hiện có.
Không thay schema, Rules, dependencies, cấu hình thanh toán hoặc billing.

## Hành vi đã sửa

- Nước, vận động, cân nặng và hồ sơ hỏi trước khi Back/Hủy làm mất nội dung
  đã sửa. Chọn tiếp tục giữ nguyên giá trị; chỉ bỏ khi người dùng xác nhận.
  Nội dung các form này vẫn nằm trong bộ nhớ; đây không phải lưu nháp bền vững
  khi Android kết thúc tiến trình. Form bữa ăn giữ cơ chế nháp mã hóa sẵn có.
- Khi bắt đầu lưu, đóng bàn phím và tiếp tục chờ xác nhận của repository.
  Không thêm timeout hoặc tự gửi lặp. Lưu thất bại giữ nguyên nội dung nhập.
- Quay lại từ Settings làm mới quyền thông báo và đặt lại lịch nhắc native.
  Không dùng snapshot cũ để ghi đè lịch vừa lưu, hoặc kết quả phiên A cũ sau
  khi chuyển A → B → A. Lỗi đọc cài đặt của một lượt cũ cũng không thay thế
  trạng thái vừa lưu thành công; đọc lại trạng thái mới khi cần. Việc kiểm tra
  yêu cầu xóa tài khoản được giữ nguyên.
- Dừng polling của màn hình bước chân khi chạy nền hoặc tab bị ẩn; đọc lại
  khi trở về. Dịch vụ cảm biến native đang được người dùng bật vẫn làm việc
  theo hành vi cũ, không bị tắt vì ngừng polling UI.
- Đồng bộ bước phân biệt ngày và số bước: số bằng hôm qua vẫn được gửi cho
  ngày mới. Quay về app thử lại bản chưa đồng bộ, xóa thông báo lỗi khi máy
  chủ xác nhận thành công. Một ACK còn chờ không sinh thêm lần ghi cùng phiên.
- Realtime listeners có thể nhận cùng Firestore instance với repository.
  Named Firebase app trong kiểm thử không rơi về instance `[DEFAULT]`;
  ứng dụng thông thường vẫn sử dụng cấu hình mặc định hiện có.

## File chính

- `lib/core/widgets/confirmed_save.dart`: xác nhận bỏ thay đổi, bàn phím và ACK.
- `water_log_dialog.dart`, `activity_log_dialog.dart`,
  `body_metric_form_dialog.dart`, `profile_form_dialog.dart`: phát hiện thay đổi.
- `wellness_providers.dart`: lifecycle, permission, lịch nhắc và chặn kết quả cũ.
- `wellness_screen.dart`: vòng đời polling, đồng bộ theo ngày và phục hồi lỗi.
- `lib/core/data/user_data_revision.dart`, `private_data_changes.dart`:
  dependency injection cho Firestore realtime; cập nhật ba harness native cũ.
- `test/daily_form_recovery_test.dart`, `test/android_daily_reliability_test.dart`:
  21 regression tests mới, chỉ dùng fixture trong kiểm thử.
- `integration_test/daily_reliability_acceptance_test.dart`,
  `tool/test_android_core.ps1`: suite `daily` dùng native plugin/SDK thật,
  chỉ chạy trên AVD riêng và Auth/Firestore Emulator của demo project.

## Kiểm chứng

- 21/21 kiểm thử mới qua. Ma trận form gồm 320 px, chữ 160%, bàn phím,
  Back/Hủy, lỗi lưu, ACK chậm và thay tài khoản khi đang chờ lưu.
- 44/44 kiểm thử tập trung cuối qua, bao gồm hồi quy form bữa ăn/nháp cũ.
- `flutter analyze --no-pub`: không phát hiện vấn đề.
- `flutter test --no-pub --reporter expanded`: **973/973 qua** trên source cuối.
- Native suite `daily`: **qua**, một scenario gồm năm checkpoint dưới đây.
  Đây là plugin Android và Firebase SDK thật kết nối emulator, không phải fake
  repository. Lượt chạy cuối có cả bản sửa xử lý lỗi cài đặt cũ.
- `dart format --output=none --set-exit-if-changed`: 15 file Dart, 0 thay đổi.
- `git diff --check` và parse cú pháp PowerShell runner: qua.
- `./tool/build_android.ps1`: **7/7** kiểm tra cấu hình admin qua;
  build APK debug cuối thành công, Gradle assembleDebug 17,0 giây.

Log tập trung cuối tại `build/android-quality-focused-last-valid.log`.
Log full/analyze/native tại `build/android-quality-full-last.log`,
`build/android-quality-analyze-last.log`,
`build/android-quality-native-daily-final.log`.
Lần chạy đầu toàn suite phát hiện một
xung đột PopScope với form bữa ăn; đã giới hạn callback mới vào form có thay
đổi cần bảo vệ, giữ assertions cũ và chạy lại hồi quy. Không xóa test để che lỗi.
Regression riêng cho lỗi đọc cài đặt cũ thất bại trước khi sửa tại
`build/android-quality-stale-read-before.log`; sau khi sửa qua trong suite cuối.
Analyzer phát hiện một dòng thiếu braces trong test native mới; đã sửa,
lượt cuối sạch. Hai lệnh tập trung gõ nhầm đường dẫn test không tồn tại bị
load failure; lệnh đã sửa chạy đủ 44/44, không coi các lần đó là pass.

Các lệnh tái kiểm tra (Flutter SDK trong PATH):

```powershell
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter test --no-pub test/android_daily_reliability_test.dart test/daily_form_recovery_test.dart test/ux_meal_recovery_test.dart
./tool/test_android_core.ps1 -DeviceId emulator-5580 -Suite daily -CrossDriveBuild
./tool/build_android.ps1
```

Lệnh native cần AVD riêng đã khởi động và Firebase CLI/Java. Lượt này chạy
native trong QA workspace đã copy/kiểm hash ở `D:\HealthMateMaintenanceQA\c6-workspace`.
Tắt Kotlin incremental chỉ trong process build/QA để tránh lỗi cache giữa
ổ C và D; runner khôi phục `gradle.properties` sau khi chạy. Không thay file
cấu hình Gradle được theo dõi trong repository.

## Nghiệm thu native trong môi trường cách ly

AVD `HealthMateMaintenanceQA`, Android API 30, `emulator-5580`;
Firebase project cố định `demo-healthmate-rules`, AI tắt trong harness.
Không sử dụng điện thoại hoặc tài khoản người dùng thật.

Suite `daily` kiểm tra trực tiếp trên Android:

1. Đọc lại lịch nhắc mã hóa/quyền thông báo sau resume và đăng thông báo native.
2. Nháp bữa ăn mã hóa đọc lại được sau khi tạo lại store.
3. Ngắt mạng Firestore, lưu nước, chặn Back khi đang chờ, nối lại mạng,
   xác nhận đúng một bản ghi 350 ml phía server.
4. Lưu vận động khi ngắt mạng, nối lại mạng, đúng một bản ghi 45 phút.
5. Chuyển sang UID khác đóng form cũ; không thấy nháp UID cũ; native từ chối
   đọc cài đặt UID cũ và Firestore từ chối đọc nhật ký của tài khoản kia.

Đây là nghiệm thu có giới hạn cho gói sửa này, chưa phải toàn bộ app.
Suite native `core` cũ đi qua đăng ký/onboarding và sửa mục tiêu, rồi dừng
ở finder `find.text('0 kcal / 2000 kcal')` không còn phù hợp Text.rich hiện tại.
Chưa báo suite `core` này đạt. Không xóa hoặc nới assertion để bỏ qua bước đó.
Log các lượt cũ còn trong thư mục build của QA workspace trên ổ D.

Lượt native đầu phát hiện listener dùng default Firebase instance và bị từ
chối đọc; đã sửa injection dùng đúng named instance của harness. Không có
ghi/xóa dữ liệu production. Cảnh báo thiếu App Check provider chỉ thuộc harness
demo; lượt này không tắt App Check production. KGP còn cảnh báo deprecation
cho bản Flutter tương lai; chưa thay dependencies trong gói này.

## APK để cài thử

- Tệp: `build/releases/healthmate-android-quality-20261107-debug.apk`.
- Manifest: `build/releases/healthmate-android-quality-20261107-debug.json`.
- Build cuối: `2026-11-07T12:06:15.7877362Z` (19:06 giờ Việt Nam).
- Kích thước: 237.035.619 byte; bản debug, chưa phải signed release.
- Cấu hình: admin controls bật; Premium demo tắt.
- SHA-256:
  `BEBEF665F83C0BF9604B908921A963F52AD664D7957B5416A0175E7CB3A25513`.
- Log build: `build/android-quality-apk-last.log`; manifest bằng chứng/hash
  source: `build/android-quality-evidence-20261107.json`.

Chủ dự án cần cài APK này và nghiệm thu trên điện thoại Android thật. Lượt
này không deploy app/web/Rules/Functions hoặc bật billing. AVD do task tạo đã
được tắt, Auth/Firestore Emulator dừng sạch; không xóa các AVD khác.

## Giới hạn còn lại

- Chưa thể coi là nghiệm thu trên điện thoại thật, Play Integrity hoặc bản ký
  phát hành. Các test widget mô phỏng ACK lỗi/chậm không thay kiểm tra SDK/native.
- Native QA dùng Android API 30; chưa nghiệm thu trực tiếp quyền thông báo
  Android 13+ hoặc cảm biến bước chân trên điện thoại thật. Kiểm thử mất mạng
  dùng `FirebaseFirestore.disableNetwork()` và nối lại SDK, chưa thử chuyển
  Wi-Fi/4G/chế độ máy bay trong toàn bộ app. Nháp được kiểm tra bằng cách tạo
  lại store, chưa có bài kết thúc rồi khởi động lại tiến trình Android.
- AI ảnh, AI chatbot phát hành, thanh toán thật, bộ đếm Auth tự động và worker
  xóa nền vẫn theo blocker ở các báo cáo trước; lượt này không mở các giai đoạn đó.
- Tiếp theo đề xuất: nghiệm thu điện thoại thật và hoàn tất signing; sau đó
  mới xử lý các phần máy chủ/AI/thanh toán theo từng phạm vi được duyệt.
