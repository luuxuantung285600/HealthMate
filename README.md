# HealthMate

Ứng dụng Flutter theo dõi dinh dưỡng, thể trạng và thói quen, ưu tiên Android.
Dữ liệu riêng theo UID trong Cloud Firestore; Firebase Authentication quản lý
đăng nhập. Riverpod quản lý trạng thái, go_router điều hướng. Web admin và
Worker chatbot nằm cùng repository. Thông tin chỉ hỗ trợ theo dõi thói quen,
không thay thế tư vấn y tế.

App và web admin dùng **Inter** đóng gói trong dự án, đủ bốn độ đậm
400/500/600/700 và ký tự tiếng Việt; không tải font từ dịch vụ bên ngoài.
Nguồn và giấy phép: [assets/fonts/inter](assets/fonts/inter/README.md).

## Trạng thái source — 31/10/2026

Đây là candidate cải thiện trên `main`, chưa phát hành. Package demo
`com.example.healthmate`, phiên bản `1.0.0+1` được chủ dự án xác nhận giữ lại.
Kết quả cuối và giới hạn xem [tiến độ](docs/improvement-progress.md),
[báo cáo test](docs/test-report.md) và [truy vết bản kiểm tra](docs/candidate-verification.md).

- Luồng nhập món, barcode, nhật ký, cá nhân hóa, kế hoạch và báo cáo dùng
  repository thật; snapshot dinh dưỡng lịch sử được bảo toàn. Catalog offline
  có 11.169 mục; [nguồn và giới hạn dữ liệu](docs/current-food-data-2026-10-27.md).
- Gợi ý thực đơn chỉ thêm bữa còn trống, hiện tiến độ từng bữa và cho lưu
  tiếp khi lỗi. Xóa kế hoạch giữ nhật ký và từ chối snapshot đã thay đổi;
  [hành vi, kiểm thử và giới hạn](docs/meal-plan-operations-2026-11-09.md).
- Support có reply hai chiều, giới hạn tạo 3 ticket/ngày Việt Nam và cách nhau
  ít nhất 60 giây qua transaction/Rules; lịch sử 25 ticket/trang. Candidate
  Rules cần triển khai phối hợp client mới. [Chính sách](docs/package8-support-policy.md).
- Biểu mẫu bữa ăn tách controller nháp/submit, trạng thái tìm kiếm và các nguồn
  nhập; [thiết kế và test](docs/package9-meal-form-refactor.md).
- Admin candidate tải 25 mục/trang, tìm/lọc trong trang, xuất theo khoảng có
  giới hạn; [hợp đồng phân trang](docs/package7-admin-pagination.md).
- AI gateway mặc định tắt, chưa provision identity/IAM và chưa khóa được đường
  Firebase AI của client cũ ở hạ tầng. Scanner ảnh/knowledge trực tiếp bị tắt
  trong candidate; barcode và nhập tay vẫn dùng. Premium là mô phỏng, không
  phải thanh toán thật. [ADR AI](docs/ai-policy-quota-adr.md).
- Xóa tài khoản có tombstone và client cleanup; chưa có job server bền vững
  hoặc purge retention. [Giới hạn xóa dữ liệu](docs/account-deletion-adr.md).
- Query mới cần migration/index/Rules phối hợp; chưa chạy production migration.
  [Dry-run, tương thích và rollback](docs/package6-query-migration.md).

Các ghi chú deploy/APK cũ đã chuyển sang [CHANGELOG.md](CHANGELOG.md). Web online
[HealthMate Admin](https://healthmate-admin-vn.web.app/) thuộc bản đã publish
trước candidate; link hoạt động không chứng nhận source này đã được triển khai.

## Chuẩn bị từ checkout mới

Cài Git, Flutter 3.44.1/Dart 3.12.1, Android SDK/JDK 21, Node.js 24 và Chrome
cho các test web SDK. Repository có lockfiles; không cần nâng hàng loạt package.

```powershell
flutter pub get
npm ci --prefix admin-web
npm ci --prefix chat-api
npm ci --prefix rules-tests
npm install --global firebase-tools@15.22.4
```

`lib/firebase_options.dart` và cấu hình Firebase Android là client config công
khai của dự án hiện tại. Chúng không cấp quyền quản trị. Với project riêng,
chủ dự án phải chạy FlutterFire configure và cấu hình Auth, Rules/indexes,
App Check/certificate tương ứng; không dùng service-account key trong app.
Email/password, Google sign-in và provider còn phụ thuộc Firebase Console.
Không deploy Rules gốc để thử: đây là candidate có thay đổi hợp đồng dữ liệu.

Chạy Android debug bằng helper sau khi có thiết bị/emulator:

```powershell
flutter devices
powershell -NoProfile -ExecutionPolicy Bypass -File tool/run_android.ps1 -DeviceId emulator-5554
```

Helper dùng `config/admin-runtime.json`, `config/chat-api.json` và token debug
App Check cục bộ tại `%LOCALAPPDATA%\HealthMate\app-check-debug-token.txt`.
Token cần được đăng ký bởi chủ dự án ở Firebase Console; không commit/gửi token.
Thiếu file/config thì helper báo rõ và dừng. `tool/build_android.ps1` cũng là
workflow **debug**, không thay thế bản release ký thật. Các cấu hình gateway
production cũ không chứng nhận gateway candidate đã được cấp quyền.

Trong VS Code, chọn **HealthMate App (Flutter)** rồi nhấn F5. Task chuẩn bị tự
nạp cùng cấu hình/token như helper, tạo file debug riêng tại
`%LOCALAPPDATA%\HealthMate\vscode-android-debug.json` ngoài repository. Không
commit/chia sẻ file này hoặc dùng nó cho release. Thiếu token/config thì task
báo lỗi; không chọn bỏ qua lỗi để chạy bằng cấu hình cũ.

Release dùng cấu hình riêng `config/release-candidate.json` và
`tool/build_release.ps1`. Kiểm tra không build bằng:

```powershell
node tool/release_preflight.cjs
```

Thiếu keystore/config sẽ dừng an toàn. Không tự tạo khóa ký, bật billing hoặc
phát hành; [release readiness](docs/release-readiness.md) ghi phần cần chủ dự
án cấu hình và ma trận nghiệm thu điện thoại thật còn chờ.

## Web admin local

Dùng fixture emulator, không đăng nhập tài khoản production vào bản local.
Ba terminal riêng từ gốc repository:

```powershell
firebase emulators:start --config firebase.admin-emulators.json --only auth,firestore --project demo-healthmate-admin
node admin-web/seed-emulators.mjs --extended
npm run dev --prefix admin-web
```

Chờ emulator sẵn sàng trước lệnh seed; mở <http://127.0.0.1:4173/>. Tài khoản
fixture và cách cấu hình Java nằm trong [admin README](admin-web/README.md).
Chat gateway candidate cần runtime identity và quyết định rollout riêng:
[chat-api README](chat-api/README.md). Không chạy lệnh deploy để vượt blocker.

## Kiểm tra source và emulator

```powershell
node tool/check_changed_dart_format.cjs
flutter analyze --no-pub
flutter test --no-pub --concurrency=2 --reporter expanded
npm test --prefix admin-web
npm run check --prefix admin-web
npm test --prefix chat-api
npm run check --prefix chat-api
node --test tool/*.test.cjs
node tool/audit_source_secrets.cjs
git -c core.safecrlf=false diff --check
```

Format checker dùng Dart trong PATH; trên Windows có thể đặt
`HEALTHMATE_DART_COMMAND` thành đường dẫn tuyệt đối tới `dart.exe` trong SDK.
Nó chỉ kiểm tệp Dart thay đổi, không format lại toàn repository.

CI tại [.github/workflows/verify.yml](.github/workflows/verify.yml) chạy source
checks và Rules/real-SDK trên project demo cố định; không cần secret production,
không deploy hay publish artifact. CI hosted cần được chạy sau khi code lên
GitHub; kết quả local không được gọi là kết quả GitHub Actions.

Trên Linux với Flutter/Chrome/Java trong PATH:

```sh
firebase emulators:exec --config firebase.emulators.json --only auth,firestore --project demo-healthmate-rules "node tool/ci_emulator_checks.cjs"
```

Script chạy Rules trước, reset đúng database demo loopback, seed rồi chạy
Flutter web SDK, migration và gateway REST fixtures. Không chạy song song các
suite tự clear/reset cùng database. Trên Windows dùng
`tool/test_emulators.ps1` cho suite cơ bản với Chrome adapter; suite bổ sung
và lệnh thực chạy được lưu trong báo cáo. Emulator không chứng minh IAM,
provider thật, chi phí production hoặc nghiệm thu native Android.

## Tài liệu chính

[Database](docs/database-design.md) · [Tiến độ cải thiện](docs/improvement-progress.md) ·
[Test report](docs/test-report.md) · [Release](docs/release-readiness.md) ·
[Lịch sử](CHANGELOG.md)

Tích hợp Premium qua Google Play, điều kiện mở bán và giới hạn kiểm thử:
[Hướng dẫn thanh toán](docs/google-play-billing-2026-11-07.md).
Độ tin cậy restore, callback trùng, tách gói thật/thử và đối soát admin:
[Cập nhật 08/11](docs/billing-reliability-2026-11-08.md).
Chưa có Play Console/Blaze được cấu hình thì để thanh toán tắt; không dùng
dữ liệu demo như doanh thu thật.
