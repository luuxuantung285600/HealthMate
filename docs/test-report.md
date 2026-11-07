# Giai đoạn 10 — Báo cáo kiểm thử và rà soát MVP

## 07/11/2026 — Bổ sung chức năng vận hành web admin

Web **83/83**, syntax qua; Web SDK thật **9/9 + 11/11** trên emulator.
Chrome 9 trang × 1440/390/320 px: theme/bố cục, drawer bàn phím, dialog giữ/
bỏ bản nháp và reload deep link qua. Script Dart xuất bài tập analyze sạch,
đối chiếu khớp 33 bài tập. Ba query production chỉ đọc HTTP200, không cần
index mới. Không chạy lại Flutter suite/build APK/Rules vì không sửa app/Rules.
Đã deploy Hosting, đọc lại 30/30 tệp khớp byte, CSP/no-store qua; Rules giữ
nguyên ruleset/hash. Source audit 656 file/0 findings; git diff --check qua.
Xem [file, bằng chứng và giới hạn](admin-completion-2026-11-07.md).

## 07/11/2026 — Sửa contract Rules và vận hành app/admin

Đã qua 129/129 Rules, 12/12 Flutter repository SDK, 17/17 SDK web và 6/6
Flutter SDK liên thông Spark. Web DOM/unit 71/71. Flutter unit/widget
952/952 trước sửa listener cuối; sau sửa chạy 29/29 hồi quy liên quan và
6/6 SDK trên, không bỏ assertions. Analyze cuối sạch. Đã publish Rules +
Hosting khoảng 14:20 UTC+7; đọc lại đúng Rules và 27 tệp Hosting.
APK debug build cuối thành công lúc 14:21:18 (Gradle 18,2 giây); cấu hình
admin qua 7/7. Chưa có thiết bị adb để cài/kiểm thử native.
[Báo cáo, file và giới hạn](operations-hardening-2026-11-07.md).

Bản kiểm chứng mới nhất là đợt vận hành 07/11 ở trên. Giai đoạn 10 chưa
nghiệm thu signed release/native; các mục dưới giữ lịch sử theo ngày.

## 06/11/2026 — Inter cho app Flutter và web admin

- `dart format lib/core/theme/design_tokens.dart test`: 104 file, 20 file
  định dạng sau đổi đường dẫn. Cập nhật 20 loader test dùng Inter thật;
  không thay assertions hoặc bỏ ca kiểm thử.
- `flutter analyze --no-pub`: **No issues found**, 91,1 giây.
- `flutter test --no-pub --reporter json`: **944/944**, 0 lỗi, 0 bỏ qua;
  kết thúc `success:true`, runner 111,865 giây.
- Web syntax qua, Node/DOM **61/61**, 0 skip. Server local HEAD đủ bốn
  WOFF2 HTTP 200, MIME `font/woff2`; tiến trình probe đã dừng.
- Format kiểm tra cuối 104 file/0 thay đổi; `git diff --check` qua.
  Secret audit 626 source text files/0 findings, không quét APK/credential store.
- Kiểm metadata TTF weights 400/500/600/700 và **187 codepoint/font** gồm
  chữ Việt/dấu ghép/số/₫, không thiếu glyph trong bộ kiểm tra. Bốn WOFF2
  tải từ local; Chrome CDP xác nhận custom font Inter SemiBold thực render.
- Browser ảnh 1440/1024/390/320 px và module app thật với adapter local
  9 trang × 1440/390/320 px: không tràn ngang/lỗi JS; drawer/dialog/login qua.
- Đã xem ảnh web và widget app đăng nhập/form 320px chữ200%. Không dùng
  widget screenshot làm bằng chứng Firebase hoặc Android thật. Ảnh web
  giữ snapshot đọc thật lúc01:50:46 ngày06/11 từ lượt theme, không đọc mới.

Log: `build/inter-font-20261106/`; [nguồn, files và giới hạn](inter-font-2026-11-06.md).
Không chạy Rules/SDK Emulator, build/cài APK hoặc deploy trong lượt font.

## 06/11/2026 — Admin phong cách tối theo ảnh mới

Phạm vi theme/shell/dashboard presentation và hồi quy đăng xuất. Không
đổi dữ liệu/Rules/backend hoặc deploy. Bảo toàn các thay đổi trước đó.

| Kiểm tra | Kết quả |
| --- | --- |
| `npm --prefix admin-web run check` | Qua |
| `npm --prefix admin-web test` | **61/61**, 0 lỗi, 0 bỏ qua |
| Chrome CSP, ảnh dữ liệu thật 1440/1024/390/320 px | Không tràn ngang hoặc JS exception; 3/0 ₫/0/0 khớp nguồn |
| Chrome app thật + adapter QA loopback, 9 trang × 1440/390/320 px | Dark surfaces, bố cục, dialog/login qua |
| Mobile drawer 390/320 px | Tab/Shift+Tab có logout, Escape trả focus qua |
| `git -c core.safecrlf=false diff --check` | Qua |
| `node tool/audit_source_secrets.cjs` | 622 source text files, 0 findings; không quét credential store/APK |

Snapshot Firebase chỉ đọc lúc **01:50:46 ngày 06/11/2026 UTC+7**: Auth 3,
counts[158,1,0,7]; kỳ 01–06/11 có 0 giao dịch Premium demo, 0 VND mô phỏng,
0 khách mua. Bản xem trước có nhãn/thời điểm, không tự ghi summary trên
server; không dùng fixture làm ảnh dữ liệu thật. Premium chưa thu tiền.

Browser QA dùng module app thật với adapter local riêng chặn ghi, danh
sách rỗng, danh tính kiểm thử rõ ràng; không SDK/mạng production. Không
chụp các màn này làm bằng chứng dữ liệu dự án. Phát hiện focus drawer lúc
vừa bỏ hidden chưa vào menu; sửa chờ frame hiển thị và guard shell cũ,
chạy lại đầy đủ qua, giữ assertions. Log trước sửa được lưu riêng.

Log/ảnh: `build/admin-dark-20261106/`. Không đổi Dart/Android/Rules nên
không chạy lại Flutter, SDK Emulator/Rules. Kết quả các lượt trước giữ
riêng dưới đây. Chi tiết: [UI tối](admin-dark-ui-2026-11-06.md).

## 03/11/2026 — UI admin theo ảnh tham khảo

Phạm vi shell/theme/dashboard presentation và hai trang menu bài tập/AI;
không đổi backend/Rules, không deploy hoặc ghi dữ liệu production.

| Lệnh/kiểm tra | Kết quả thực tế |
| --- | --- |
| `npm --prefix admin-web run check` | Qua, gồm module shell mới |
| `npm --prefix admin-web test` | **60/60 qua**, 0 lỗi, 0 bỏ qua |
| Chrome headless ở 1440/1024/390/320 px | Không tràn ngang trang hoặc JS exception; ô số liệu khớp nguồn đọc |
| Bản xem trước từ snapshot Firebase thật | **3 / 0 ₫ / 0 / 0** lúc 02:01:25 ngày 03/11 UTC+7 |
| `git -c core.safecrlf=false diff --check` | Qua |
| `node tool/audit_source_secrets.cjs` | 621 source text files, 0 findings; không quét APK/credential store |

Năm ca DOM mới kiểm tra thứ tự/active menu, toggle sidebar/drawer, trang
bài tập chờ triển khai, lối sửa cấu hình AI có audit, cấu hình chưa xác
định và response AI cũ sau đổi trang/logout. Giữ những assertions dữ liệu
và hành động của các ca trước.

Log syntax/test: `build/admin-ui-reference-20261103/{check,test}.log`.
`read-production.cjs` chỉ đọc; `preview.cjs` chạy shell/dashboard sản phẩm
với snapshot qua server loopback và Chrome rồi đóng tiến trình sau khi
chụp. Không dùng fixture để thay số trong bản bàn giao. Đã xem ảnh desktop
và mobile sau chỉnh nhãn biểu đồ responsive cuối. Premium vẫn là demo;
không coi 0 VND mô phỏng là doanh thu thanh toán thật đã được tích hợp.

Không chạy lại Flutter/Dart/Android, SDK Emulator hoặc Rules suites trong
lượt chỉ đổi UI này. Các kết quả 9/9 SDK và 128/128 Rules bên dưới là từ
lượt dashboard trước, không phải kiểm thử lại của theme mới.
Chi tiết: [UI admin](admin-ui-reference-2026-11-03.md).

## 03/11/2026 — Đính chính ảnh bàn giao dashboard

Ảnh trước dùng fixture42/240.000đ/12/4, không phải dữ liệu dự án; đã thay
bằng ảnh render từ dữ liệu máy chủ đọc thật. Không thay code sản phẩm/Rules,
không seed hoặc ghi server để có số, không deploy.

- `node build/admin-dashboard-real-20261103/read-production.cjs`: exit0,
  chỉ đọc; lúc00:58:12 UTC+7, Auth3, count[158,1,0,7]. Receipt tháng11
  đến03/11:0, tiền mô phỏng0 VND, UID mua0. Không in/lưu token credential.
- `node build/admin-dashboard-real-20261103/preview.cjs`: Chrome1440/390,
  các ô tổng3/0/0/0 khớp nguồn đọc, không tràn ngang hoặc JS exception.
- Không chạy lại tests Flutter/Rules vì không sửa mã sản phẩm/Rules.
- Chi tiết và đường dẫn ảnh đã đính chính:
  [Dashboard admin](admin-dashboard-2026-11-02.md).

## 02/11/2026 — Dashboard admin: tài khoản và Premium

Phạm vi web/Rules, chưa deploy hoặc ghi dữ liệu production.

| Lệnh/kiểm tra | Kết quả thực tế |
| --- | --- |
| `npm --prefix admin-web run check` + helper `node --check` | Qua |
| `npm --prefix admin-web test` | 55/55 qua |
| `node --test admin-web/test/sdk.integration.mjs` trên Emulator | 9/9 qua |
| `node --test *.rules.test.cjs` từ rules-tests, Emulator8092 | 128/128 qua |
| Chrome headless, CSP, widths1440/390/320 | Ready, không tràn ngang hoặc JS exception |
| `node admin-web/tool/sync-account-statistics.cjs` | Chỉ đọc production; total3, pages1, applied:false |
| `node tool/audit_source_secrets.cjs` | 0 finding |
| `git diff --check` | Qua |

Chạy Firebase CLI `emulators:exec --config firebase.admin-emulators.json
--only auth,firestore --project demo-healthmate-admin` với runner local
`build/admin-dashboard-20261102/verify.cjs`: seed fixture → SDK → toàn bộ
Rules. Auth9098/Firestore8092; đã dừng các emulator do task tạo.

Lượt Rules đầu runner dùng cwd root, suite có đường dẫn tương đối không
tìm thấy Rules; sửa cwd rules-tests và chạy lại đầy đủ128/128. Lượt DOM
đầu assertion giá quá rộng bắt giá gói trong chú thích, sửa kiểm đúng ô số
liệu và giữ UID/race checks; lượt cuối55/55. Không đổi nghiệp vụ hoặc nới
Rules để các bài test qua. Log/ảnh fixture và giới hạn:
[Dashboard admin](admin-dashboard-2026-11-02.md).

Không sửa Dart/Android nên không chạy lại Flutter/native; không kiểm thanh
toán/AI thật hoặc nghiệm thu admin production. Tổng Auth là bản cập nhật
thủ công, không được coi là số người online hay realtime. Chưa deploy
Hosting/Rules và chưa chạy helper với `--apply`.

## 02/11/2026 — Kiểm tra chuẩn bị push GitHub

- `node tool/audit_source_secrets.cjs`:613 source text files,0 findings;
  không quét credential store hoặc tuyên bố đã audit APK.
- `node --test tool/prepare_vscode_android.test.cjs`: **5/5 qua**,0 skip trên
  Windows; log `build/github-push-launcher-tests-20261102.log`.
- CI source chạy Linux không có `powershell.exe`. Bốn ca thực thi helper
  được đánh dấu đúng nền tảng và job `windows-launcher` mới chạy đủ5 ca
  trên `windows-latest`; ca wiring thuần source vẫn chạy trên cả hai hệ.
  Chưa chứng nhận hosted CI bằng kết quả local.
- `git diff --check` và kiểm tra staged diff qua. Không thay Dart từ lượt
  UI đã kiểm944/944 bên dưới nên không chạy lại toàn Flutter/Android trong
  lượt push. Không deploy Firebase hoặc phát hành ứng dụng.

## 01/11/2026 — Thu gọn giao diện dinh dưỡng

- Full `flutter test --dart-define=UX_CAPTURE_DIR=build/nutrition-ui-20261101/after
  --reporter json`: **944/944 qua**, 0 lỗi, 0 bỏ qua; 91,878 giây theo test
  runner. Log `build/nutrition-ui-tests-current.jsonl`, kết thúc `success: true`.
- `flutter analyze`: **No issues found**, 7,8 giây. Log
  `build/nutrition-ui-analyze-current.log`.
- Đã chạy `dart format lib test`, rồi kiểm định dạng103 file Dart thay đổi:
  **0 thay đổi**, log `build/nutrition-ui-format-final.log`;
  `git -c core.safecrlf=false diff --check` qua. Không giữ thay đổi format
  khoảng trắng cuối file `lib/main.dart` vì file đó ngoài phạm vi.
- Giữ các assertion nghiệp vụ khi đổi đường vào form: ngày cũ, loại bữa,
  khẩu phần/tổng kcal, lưu sửa/xóa/copy, single-flight, lỗi mạng/retry,
  nháp phục hồi, chặn UID thay đổi, camera consent và nguồn tìm kiếm.
  Lối vào thói quen qua Cá nhân có kiểm tra Back từ chi tiết về hub rồi
  về Cá nhân. Sửa cân từ Cá nhân được kiểm tra cập nhật lại Tiến độ.
- Các test bố cục hiện có kiểm tra 320/390/412 × chữ1/1,5/2 × sáng/tối,
  bàn phím mô phỏng và nút chính. Sáu capture widget với fixture cố định
  qua trong full suite; ảnh 390×844, chữ100%, sáng. Đã xem Hôm nay/Nhật ký/
  thêm món. [Gallery](ux/nutrition-simple-2026-11-01/index.html).

Các lượt đầu phát hiện test phụ thuộc menu cũ, key `nav-profile` trùng giữa
avatar/tab, nhịp pump khi mở tab camera và Back thói quen khi mở từ Cá nhân.
Đã cập nhật kiểm thử theo thao tác UI mới, tách key avatar, sửa Back nội bộ
và giữ những assertion lưu dữ liệu. Kiểm tra còn phát hiện thiếu invalidate
báo cáo tuần sau sửa/xóa cân trong Cá nhân; đã bổ sung. Lượt full trước lần
chốt nhãn ngày cũ/nguồn snapshot cũng qua944/944, nhưng bằng chứng cuối là
`nutrition-ui-tests-current.jsonl` sau các sửa cuối. Log lỗi trung gian giữ
tại `build/nutrition-ui-tests-*.jsonl`, không mô tả là các lượt qua.

Chưa chạy lại Android, cài APK hoặc thao tác dữ liệu thật theo lựa chọn
người dùng tự test thiết bị. Không build APK trong lượt UI, không deploy
hoặc push. Không dùng widget fixtures làm bằng chứng Firebase/Android thật.
Không thay Rules/backend, hạn mức hoặc xử lý các blocker production cũ.

## 01/11/2026 — Rules startup và cấu hình F5

- Đọc metadata/Rules production bằng CLI credential hiện có; không đọc dữ
  liệu sức khỏe. Xác nhận thiếu `account_deletions` trong Rules đang chạy;
  tái hiện owner-get bị từ chối với chính baseline trên emulator.
- `node --test tool/prepare_vscode_android.test.cjs`: **5/5 pass**.
- `flutter test --no-pub --dart-define-from-file=config/admin-runtime.json
  --dart-define=HEALTHMATE_VERIFY_ADMIN_BUILD=true test/admin_runtime_test.dart`:
  **7/7 pass**, bao gồm fail-closed/suspension/maintenance/listener retry;
  log `build/vscode-admin-runtime-tests.log`.
- Firestore-only emulator project **demo-healthmate-access**, port8093:
  `node --test rules-tests/access_hotfix.emulator.cjs`: **7/7 pass**;
  baseline-deny, owner-get absent/present, UID/verified/guest/list/write,
  product privacy và suspension; xác nhận candidate chỉ thêm một match.
  Log `build/firebase-access-hotfix-emulator.log`; emulator task đã dừng.
- `flutter build apk --debug --no-pub` với private defines file đúng F5:
  **thành công**, Gradle26,8 giây. Log `build/vscode-android-debug-build.log`.
- Secret source audit không có finding; diff check qua. Không thay Dart nên
  không chạy lại format/analyze/full Flutter suite trong lượt cấu hình này.

Người dùng duyệt deploy qua câu trả lời **Áp dụng bản vá lên Firebase**.
Đã đọc lại production baseline trước deploy, không thay đổi so với backup;
deploy **chỉ firestore:rules** với config candidate riêng tới project
`healthmate-app-20261013`: thành công. Tải lại toàn bộ source sau deploy,
chuẩn hóa và so sánh: khớp candidate đã kiểm thử. Hash đang chạy:
`b062a8c0620c83f40a41c33196f14b2d218fd9e134a827aeec9b4d2e697d6bfc`.
Log deploy `build/firebase-access-hotfix-deploy.log`, metadata hậu kiểm ở
`build/firebase-access-postdeploy-20261101/metadata.json`.

Chưa chạy lại luồng native theo lựa chọn người dùng tự test. Logcat thiết bị
chỉ trả buffer header nên không lấy đó làm bằng chứng lỗi/kết quả trên máy.
Không deploy root candidate Rules hoặc thay dữ liệu người dùng; chỉ vá quyền
get chính UID đã xác minh, vẫn chặn list/write/cross UID. Workflow deletion và
rollout các gói khác chưa được bật bởi bản vá này. Chi tiết:
[báo cáo sửa truy cập](firebase-access-fix-2026-11-01.md).

## 01/11/2026 — Sửa Gradle build Android

- Trước sửa: `android/gradlew.bat help --offline --console=plain` tái hiện
  `Unresolved reference 'io'` ở dòng tạo File; log
  `build/android-gradle-before.log`. Accessor `android {}` cũng báo deprecated.
- Sửa `android/app/build.gradle.kts`: import/call `File` tránh extension
  `java` che package; dùng `extensions.configure<ApplicationExtension>`.
  Đối chiếu AGP9 release notes chính thức và public interface trong SDK đã cài.
  Giữ flags tương thích Flutter/plugin, versions và toàn bộ release gates.
- Sau sửa: `gradlew.bat help --offline --console=plain` **BUILD SUCCESSFUL**,
  15 giây; log `build/android-gradle-config-fixed.log`.
- `flutter build apk --debug --no-pub`: **thành công**, Gradle48,3 giây;
  log `build/android-debug-build-fixed.log`; APK mới tại
  `build/app/outputs/flutter-apk/app-debug.apk` (237.024.298 bytes).
- `node --test tool/release_preflight.test.cjs`: **6/6 pass**.
- `gradlew.bat :app:assembleRelease --dry-run --offline --console=plain`:
  **từ chối đúng** với `HealthMate release signing is not configured`;
  log `build/android-release-guard-fixed.log`. Đây là kiểm tra gate, không phải
  release build thành công hoặc nghiệm thu khóa ký.
- `git -c core.safecrlf=false diff --check`: qua. Không thay Dart nên không
  chạy lại format/analyze/full Flutter suite trong lượt sửa Gradle này;
  kết quả943 test bên dưới thuộc lượt Auth trước đó.

Không cài APK/chạy lại luồng điện thoại theo lựa chọn người dùng tự test.
Cảnh báo KGP/built-in Kotlin từ plugins vẫn còn nhưng không chặn debug build;
không nâng cấp hàng loạt dependencies để xử lý cảnh báo ngoài phạm vi.
Không thay signing/config riêng tư, dữ liệu production, deploy hoặc push.

## 01/11/2026 — UX tài khoản: đăng nhập/đăng ký và phục hồi

- Full `flutter test --no-pub --dart-define=UX_CAPTURE_DIR=build/auth-ux-20261101/after
  --reporter=expanded`: **943/943 pass**, 1 phút34giây. Log:
  `D:\HealthMateMaintenanceQA\ux-20261101\auth-full-final.log`.
- `flutter analyze --no-pub`: **No issues found**, 16,3 giây; log
  `D:\HealthMateMaintenanceQA\ux-20261101\auth-analyze-final.log`.
- Format10 file Dart của lượt Auth: **0 thay đổi** sau định dạng;
  `git -c core.safecrlf=false diff --check` qua.
- Thêm26 ca `ux_auth_flow_test.dart`: chuyển chế độ/giữ email/xóa mật khẩu,
  Back, focus/Next/Done, lỗi mạng giữ form, reset và lỗi riêng, single-flight,
  Google cancellation/progress, guideline vùng chạm/nhãn và18 cấu hình màn
  320/390/412 × scale1/1,5/2 × sáng/tối có viewInsets bàn phím mô phỏng.
- Thêm5 capture mặc định, nằm trong943 ca. Baseline5/5; stress capture
  320×844/chữ200%/nền tối5/5. Ảnh trước/sau390×844, chữ100%, nền sáng:
  [luồng tài khoản](ux/auth-2026-11-01/index.html).15 PNG/hashes và các đường
  dẫn ảnh trong gallery đã kiểm tra. Đây là widget/fake-repository evidence.

### Lỗi trung gian và sửa thực tế

- Focused run đầu63 pass/1 fail vì sau gửi reset, nút gửi lại chuyển từ
  FilledButton sang TextButton; sửa selector, giữ assertion cooldown.
- Test mới ban đầu đọc focusNode từ TextFormField thay vì TextField con;
  sửa helper. SemanticsHandle phải giải phóng trước khi test kết thúc;
  chuyển sang try/finally. Đây là lỗi harness, không nới nghiệp vụ.
- Xem ảnh320/chữ200% phát hiện tên thương hiệu bị bẻ giữa từ và label nhập
  lại mật khẩu có ellipsis dù không overflow. Sửa layout thương hiệu bằng
  Wrap và label widget hỗ trợ nhiều dòng; đã chụp lại và xem trực quan.
- Full run đầu942 pass/1 fail do test chờ hồ sơ còn kỳ vọng câu copy cũ.
  Đổi sang câu mới, giữ timeout/AsyncError/retry/no-spinner assertions;
  chạy lại full943/943. Log đầu giữ ở `auth-full-first.log` cùng thư mục QA.

Chưa chạy lại Android/TalkBack/Google và nhận thư thật hoặc build APK, theo
lựa chọn người dùng tự test thiết bị. Không đổi repository/Rules/config/
dependencies; không deploy, production write hay tắt laptop. Chi tiết phạm vi:
[báo cáo Auth UX](auth-ux-2026-11-01.md).

## 01/11/2026 — UX/UI, kiểm chứng tích hợp

- Baseline Git: `46dccf642f4dff8b51b31cc044f1a1b46cf9a1c2`.
- `flutter test --no-pub`: **912/912 pass**, 2 phút20giây. Log:
  `D:\HealthMateMaintenanceQA\ux-20261101\flutter-full-final.log`.
- `flutter analyze --no-pub`: **No issues found**. Log cuối:
  `D:\HealthMateMaintenanceQA\ux-20261101\analyze-final-verified.log`.
- `dart format --output=none --set-exit-if-changed <58 file Dart thay đổi>`:
  **0 thay đổi**; `git -c core.safecrlf=false diff --check` qua.
- Bộ mới109 test: Home/Diary21, onboarding24, meal recovery23,
  charts/Profile36, captures5. Có ma trận320/390/412 × scale1/1,5/2 ×
  light/dark cho Home/Diary/onboarding/meal/chart/Profile. Keyboard ở đây
  mô phỏng viewInsets, không phải bàn phím hệ thống Android.
- Capture baseline riêng từ Git archive và capture source: **5/5 mỗi bên**,
  cùng font/fixture390×844. PNG gốc, ảnh ghép và manifest:
  [5 cặp trước/sau](ux/2026-11-01/index.html).
- Sau full pass, điều chỉnh tối thiểu vùng chạm macro Home thành48dp;
  kiểm lại Home/Diary, mfp UI và5 ảnh: **38/38 pass**, 15giây, ở
  `D:\HealthMateMaintenanceQA\ux-20261101\visual-final.log`.

### Lỗi trung gian và cách xử lý

Lượt full đầu **888 pass/24 fail** do selector/giả định UI cũ: Hủy đổi thành
Đóng, Save đổi từ TextButton sang FilledButton, bộ lọc được mở theo nhu cầu,
Profile bỏ daily summaries, Ghi nhanh giữ ngày đang xem, camera production
được chặn trước consent. Đã cập nhật thao tác kiểm thử tương ứng, giữ kiểm
tra CRUD/ACK/chống trùng/UID/dị ứng/stale response và listener lifecycle.
Camera lifecycle được kiểm bằng service khả dụng giả lập; có test riêng
chứng minh service production unavailable không mở camera/consent.

Widget matrix ban đầu cần cuộn trước khi tìm/chạm child lazy ListView và
nút fallback ngoài viewport chữ200%. Helper đổi bộ lọc từng mở dropdown
hai lần khi tile mở mà child đã bị hủy ngoài màn; sửa helper chạm đúng
header sau khi cuộn, giữ assertion2 requests và loại response cũ.
Một lượt compile trung gian lỗi tham số fake service lặp; đã sửa fixture.
Không nới validation hoặc Rules để cho test qua.

Đồng thời sửa lỗi sản phẩm đã phát hiện: Home320/chữ200% bị ép hàng;
giữ nháp thất bại ở tabẢnh bị ẩn lỗi; Back thiết lập chưa đánh dấu bỏ qua
nên quay lại gate; controller input chưa rebuild dirty Back trên nền tảng
không có storage. Các test phục hồi và matrix cuối đều đã qua.

### Giới hạn kiểm chứng

Chưa chạy Rules/SDK/Node suites trong lượt UX vì không sửa Rules, backend,
Android hay dependency/config tương ứng; không lấy số pass cũ làm test mới.
Chưa nghiệm thu native/TalkBack/build APK, chưa deploy/production write.
Người dùng tự test Android. Backend ảnh và blocker release trước đó vẫn
cần xử lý riêng. Chi tiết file/luồng/giới hạn:
[báo cáo UX/UI](ux-ui-implementation-2026-11-01.md).

## 27/10/2026 — Polish UI dinh dưỡng (Giai đoạn tùy chọn 11)

- Format 22 file Dart: 0 lệch; analyze **0 issues** (23,3 giây).
- Full Flutter **685/685 qua** (92 giây). Bao gồm 7 ca mới cho màn nhỏ,
  chữ 200%, bàn phím, đổi khẩu phần/lưu đúng và nền header khi cuộn.
- Lần đầu full suite 676 qua/9 lỗi do kỳ vọng UI cũ; đã cập nhật thao tác cuộn,
  kiểm tra nội dung thay kiểu ListTile, và nhãn hiển thị. Không bỏ kiểm tra dữ liệu.
- APK app thường build thành công (62,4 giây), 7/7 runtime tests qua; hash trong báo cáo UI.
- **Không chạy lại luồng Android theo yêu cầu người dùng.** Người dùng tự test.
- Chi tiết, file, ảnh và giới hạn: [báo cáo UI](ui-polish-2026-10-27.md).

## 27/10/2026 — Tích hợp admin với Android

Đã sửa quy trình run/build để dùng chung `config/admin-runtime.json`, và sửa
listener cấu hình tự kết nối lại sau khi tài khoản được mở khóa. Ca hồi quy
thay đổi cấu hình trong lúc khóa đã thất bại trước sửa, qua sau sửa. Không nới
Rules hoặc bỏ App Check để vượt kiểm thử.

- Full Flutter: **656/656**, `build/admin-flutter-tests-accepted.log`.
- Runtime theo cấu hình build thật: **7/7**, chạy trước bước build APK.
- Emulator: **77/77 Rules**, **4/4 web SDK**, **3/3 Flutter SDK**;
  `build/admin-integration-accepted.log`.
- Web DOM/validation/list/XLSX: **20/20**, `build/admin-unit-accepted.log`.
- Analyze: **No issues found**, `build/admin-analyze-accepted.log`.
- Format ba file Dart 0 lệch; PowerShell parser 4/4 qua; diff whitespace qua.
- APK debug build **exit 0**, Gradle 34,0 giây; manifest SHA256/kích thước
  đối chiếu đúng. Log `build/admin-android-build-accepted.log`.

Chỉ dùng fixture demo local. Chưa có ADB device để nghiệm thu Android thật với
admin production. [Chi tiết và lệnh chạy lại](admin-runtime-integration.md).

## 27/10/2026 — Bộ 20 câu cá nhân hóa đã hoàn tất

Phạm vi mở rộng hồ sơ/onboarding (Giai đoạn 3): đúng 20 câu, chia các phần ngắn;
nhánh không tập/không đổi cân nặng bỏ câu không liên quan. Câu bổ sung có thể để
sau, null không phải 0/không có. Câu 1–9 dùng bộ tính kcal hiện có, phải xem lại
và xác nhận trước lưu. Người cũ không bị ép làm lại; vào Thêm → Cá nhân hóa ·
20 câu hỏi. Có 5 mục tiêu, tách thêm Tăng cơ; giá trị tăng cân cũ giữ nguyên.
Lưu map version1 theo UID, không gửi AI/không cho admin đọc. Sửa câu trả lời giữ
số đo cũ; cân nặng đổi thêm số đo, không đổi không tạo log. Giữ toàn bộ source
admin/cá nhân hóa/báo cáo đang chờ commit trước đó theo yêu cầu up GitHub.

Kiểm tra thực tế: format phần thay đổi 0 lệch; analyze 0 issues (7 giây);
full Flutter **646/646** (66 giây). Sau chỉnh text phân nhóm/giới hạn subtitle,
chạy lại analyze 0 issues và **7/7** ca khảo sát (3 giây). **39/39** ca hồi quy
Auth/account/widget/khảo sát qua sau sửa vị trí entry, không sửa test Auth để
bỏ qua lỗi. Rules **77/77** (24,8 giây); web **20/20**, SDK Emulator **4/4**.
Lần thử Rules đầu thiếu Java21 ở PATH/Emulator chưa lên nên không kết nối được;
đã chạy bằng Java21 và server8092. SDK lượt đầu thiếu fixture, seed local
--extended rồi 4/4; không hạ rule. Secret scan 478 file text, 0 mẫu credential
nhạy cảm; không phải chứng nhận audit toàn bộ lịch sử Git/APK.

Rules đã deploy scoped `firestore:rules`, không đổi Hosting/indexes/billing.
Readback hash `04a81618172e2a843e71c57b21208a080aa2643c14c55efce2dd24e6ab0c0428` khớp source,
ruleset `04f3777e-84c5-42a2-b242-56c1640a0bbe`. Backup trước/sau chỉ ở build/.
Warning knownNumber unused có sẵn; build còn warning Kotlin plugin có sẵn.
APK debug build qua **30,1 giây**, giữ define admin + AI debug cục bộ:
`build/releases/healthmate-questionnaire-20-debug.apk` (236777378 byte),
SHA256 `3afab0533edc044304ec1105a5b09d02e8c1063273ec332a3d02a1b32f20e984`. Chưa cài/thử trên điện thoại, không public APK/debug token.
Ảnh font thật 360×800/chữ150% đã xem, không overflow; một số lựa chọn dài hiển
thị dấu …, có toàn bộ nội dung trong phần xem lại. Không coi đây là nghiệm thu native.

File chính: models/personalization_answers.dart, presentation/personalization_questions.dart,
onboarding_screen.dart, profile_screen.dart, repository/model hồ sơ, router,
firestore.rules, test/personalization_questionnaire_test.dart và Rules tests.
Thiết kế/nguồn/giới hạn: [personalization-questionnaire.md](personalization-questionnaire.md).
Chưa áp bộ lọc thực đơn tự động theo chế độ ăn/dị ứng, chưa tự sửa lịch nhắc ngủ.
Bước kế tiếp đề xuất: nghiệm thu luồng 20 câu trên điện thoại; không tự mở giai đoạn khác.


## 27/10/2026 — Nghiệm thu server production admin

- Syntax qua; web **20/20**, SDK Emulator **4/4**, Rules **74/74** (11,3 giây).
- Production smoke end-user ID tokens: **17/17 qua**. Hai lần đầu lỗi harness
  timestamp máy/audit field contract; sửa fixture theo server, không nới Rules.
  Lần cuối `build/admin-production-smoke-1793041420664.json` cleanup không lỗi.
- Kiểm tra lại **6 danh tính QA** từ ba lượt đã xóa, fixture đã dọn; giữ **7
  audit thành công**, không tính thao tác bị từ chối. Không đọc/sửa health data thật.
- Deploy compile qua (warning knownNumber chưa dùng có sẵn); đọc lại Rules
  khớp nguồn hash5d02e187…/rulesete4c952fa…. Indexes/AI enforcement/billing không đổi.
- HTTPS **11/11 file** byte-for-byte + CSP/no-store/nosniff/no-referrer qua;
  App Check token sai **403 App attestation failed**, role/email/Google/billing
  readback xác nhận. Chưa chứng minh browser token hợp lệ.
- Runtime **5/5** với define admin true; debug build qua **21,6 giây**, warning
  KGP cũ. APK admin-enabled 236758930byte/hashd59c2bc6… chưa cài điện thoại.
- Người dùng chọn **thử giao diện sau**. Browser vẫn chưa QA trực quan; popup
  Google và email reset inbox chưa xác nhận. Không tuyên bố toàn bộ nghiệm thu UI
  đã xong; chưa bật enforcement Firestore/Auth mới để tránh chặn app cũ.

Logs và lệnh cụ thể: [admin-production.md](admin-production.md). Không đổi Dart
source nên không lặp full639/analyze của lượt trước hoặc format ngoài phạm vi.

## 27/10/2026 — Hoàn thiện admin theo yêu cầu mới

- Syntax admin qua; `npm --prefix admin-web test`: **19/19**, 7,3 giây.
- Production adapter + Firebase SDK 13.0.0 qua Auth/Firestore Emulator:
  `npm --prefix admin-web run test:sdk`: **4/4**, 0,87 giây.
- Toàn bộ source Rules: **74/74**, 12,1 giây, cổng 8092. Sửa suite wellness dùng
  biến môi trường thay cổng cứng 8080; giữ assertion truy cập chéo/validation.
- `flutter test --no-pub test/admin_runtime_test.dart`: **5/5**. Không sửa Dart;
  full 639/639 và analyze 0 issues ở phần báo cáo năm bên dưới là lần chạy trước.
- Audit production dependencies **0**; HTTP asset/headers/traversal/method qua.
- XLSX thật được parser ZIP test và openpyxl độc lập đọc đủ 67 dòng ×16 cột;
  null/zero/text giống formula giữ đúng kiểu. Không có dữ liệu sức khỏe thật.

DOM dùng linkedom chỉ trong dev; SDK test dùng module production với cùng phiên
bản Firebase, không đổi logic để giả thành công. Browser bị tắt trong Work settings,
chưa QA hiển thị mới trực tiếp. Các test đều chạy local, không ghi production.
Email admin được chọn đã verified qua kiểm tra read-only; chưa grant role, App
Check web thiếu site key. Chưa deploy/kiểm thử production inbox, chưa bật cờ mobile.
Chi tiết log/coverage/blocker: [admin-completion.md](admin-completion.md).

## 27/10/2026 — Báo cáo năm và khoảng tùy chọn (Giai đoạn 8 mở rộng)

- `dart format --output=none --set-exit-if-changed` trên 15 file Dart liên quan:
  **0 file thay đổi**, exit 0.
- `flutter analyze --no-pub`: **0 issues**, 48,2 giây, exit 0;
  `build/year-reports-analyze-final.log`.
- `flutter test --no-pub --reporter expanded`: **639/639**, 112 giây, exit 0;
  `build/year-reports-full-final.log`. Gồm 14 ca mới, không bỏ kiểm tra quyền hoặc
  lỗi nguồn. Nhóm báo cáo/CSV trước đó qua 54/54; ca mới cuối 14/14.
- `flutter build apk --debug --no-pub --dart-define-from-file=<ignored local config>`:
  **qua**, Gradle 26,8 giây, exit 0; `build/year-reports-build.log`. Giữ warning
  KGP từ các plugin cũ về hỗ trợ Flutter tương lai; không tự nâng dependency.
- `git diff --check`: qua. Source audit **449 tệp văn bản, không phát hiện mẫu
  secret** (kiểm tra nguồn theo mẫu, không phải audit APK). Cấu hình debug và APK
  nằm dưới `build/` đã kiểm tra được Git ignore.

Bao phủ: năm nhuận 366 ngày/29-2, năm hiện tại 01/01–hôm nay, khoảng 1/123/366 ngày,
đầu cuối bao gồm, khoảng đảo/quá giới hạn, calendar picker và hủy giữ khoảng cũ;
ghép phần ≤90 ngày không mất/trùng ngày, dedup target đúng hiệu lực, thiếu nhật ký
không là 0 đã ăn, tổng/tháng/ngày và mẫu số xác nhận, phân trang; lỗi phần sau giữ
nguồn ở error thay vì tổng thiếu, retry, đổi UID bỏ dữ liệu cũ và dừng phần kế;
CSV cả năm, nguồn lỗi không mở/ghi tệp, prefill khoảng báo cáo và consent vẫn tắt.
Widget 360×800/chữ150% qua; ảnh font thật `build/year-report-ui/year.png` đã xem.

Lượt đầu phát hiện lỗi bọc exception của tác vụ CSV song song; đã giữ lại đúng lỗi
nguồn và lỗi đổi phiên để không báo nhầm. Ca CSV cũ được đổi mốc quá giới hạn từ
91 sang 367 ngày theo yêu cầu mới; vẫn kiểm tra range đảo/trống/ID trùng.
Full đầu 638/639 do test wellness cố định 26/10 nhưng Nhật ký mặc định là 27/10:
đã chọn tường minh đúng ngày fixture, giữ các assertion ngân sách 1850/1800 và
ngừng credit khi có activity. Full cuối qua. Không sửa logic wellness ngoài phạm vi.

`mfp_ui_test` tự sinh lại 12 ảnh tracked; các ảnh này sạch khi bắt đầu lượt, đã
giữ bản sinh trong `build/year-report-ui/generated-mfp/` và khôi phục đúng ảnh
gốc để không thêm diff hình ngoài phạm vi. Các source chưa commit từ lượt cá nhân
hóa dinh dưỡng vẫn được giữ nguyên.

Không sửa repository query giới hạn 90 ngày/Rules/schema, không deploy backend,
không gọi AI để lập báo cáo, không chạy lại Emulator/native acceptance hoặc cài
điện thoại. Không coi test Emulator/native trước đây là vừa chạy lại. Bản APK
thường và SHA256 ở [year-and-custom-reports.md](year-and-custom-reports.md).

## 26/10/2026 — Cá nhân hóa mục tiêu dinh dưỡng (Giai đoạn 7 bổ sung)

- `dart format` trên 10 file Dart sửa/tạo: lượt cuối **0 file thay đổi**.
- `flutter analyze --no-pub`: **0 issues**, 18,1 giây, exit 0.
  Log `build/personal-nutrition-analyze-final-2.log`.
- `flutter test --no-pub --reporter expanded`: **625/625**, 92 giây, exit 0.
  Log `build/personal-nutrition-full-final.log`. Có 17 ca mới; các fixture onboarding
  cũ được cập nhật đúng bước kế hoạch có thể bỏ qua. Không bỏ assertion để né lỗi.
- `flutter build apk --debug --no-pub --dart-define-from-file=<ignored local config>`:
  **thành công**, Gradle 72,5 giây, exit 0. Log `build/personal-nutrition-build.log`.
  Còn warning KGP từ một số plugin hiện có về hỗ trợ Flutter tương lai; không nâng
  dependency ngoài phạm vi. Không có lỗi compile.
- `git diff --check`: qua. `node tool/audit_source_secrets.cjs`: **445 tệp văn bản,
  không phát hiện mẫu secret**. Đây là kiểm tra nguồn theo mẫu, không phải audit APK.

Bao phủ mới: công thức Mifflin, hệ số/nhịp, rounding kcal/macro, giới hạn và dữ liệu
thiếu/NaN, chiều hướng cân đích, birthday, cân cũ/tương lai; xác nhận trước ghi,
giữ mục tiêu ngày cũ, phát hiện mục tiêu đổi khi đang xem, lỗi đọc/lưu và thử lại,
không gửi lặp, logout khi chờ lưu, sang ngày mới, onboarding lưu target/profile
hai bước và retry không trùng. Widget kiểm ngân sách Dashboard/Journal và context
chat cùng lấy mục tiêu đã xác nhận. Màn 360×800/chữ150% qua; đã xem ảnh font thật
`build/personal-nutrition-ui/questions.png`, `review.png` (dữ liệu fixture).

Các lượt đầu phát hiện và đã sửa: reset draft khi nguồn seed tải lại/qua nửa đêm,
cuộn làm khuất đầu kết quả với chữ lớn, frame logout có profile null. Lỗi fixture
getter TextFormField và finder Scrollable đã sửa theo widget thật, giữ kiểm tra
readonly, chống ghi lặp, lỗi lưu và tính nhất quán. Kết quả cuối ở log full nêu trên.

Không đổi Rules/schema, không deploy Firebase/Cloudflare, không gọi AI để tính,
không chạy lại Emulator Rules/SDK của đợt trước. Không nhận kết quả Emulator cũ
là vừa chạy lại. Chưa cài/kiểm tra trên điện thoại thật hoặc chạy native acceptance
cho luồng mới; user đã chọn kết nối sau. APK thường mới ở
`build/releases/healthmate-personalized-nutrition-debug.apk`; hash và giới hạn
ở [personalized-nutrition.md](personalized-nutrition.md).

## Mới nhất26/10/2026 — Mục2–3–4

Full Flutter608/608,82giây; Ruleslocal73/73 vàFirebaseSDK23/23; candidateMVP không
admin64/64; Androidacceptance cuối1scenario+teardown51giây exit0; debugbuild24giây
qua. Cả3ảnh UIcalo/ngủ/tiến độ đã xem. Testkhôngtrộncalonghỉ/bướctínhsẵn, tạm
ngừngcreditkhiđổigoal/cóactivitynhậptay, consent/retry, thốngnhấtDashboard/Journal/
chat, sleepoverlap/midnight/missing/invalidday vàtrungbìnhcânmỗingàynhưnhau.
Analyzer cuối0issues,49,2giây;format34file0thayđổi,diffcheckexit0,sourceaudit438file
khôngkhớp cácmẫu secret kiểm tra (không phải kiểm toán APK).

Native kiểm thông báo giờ ngủ thực, dữ liệu thiết lập/goal, biểu đồ30ngày,
calo fixture xác nhận→ngân sách và đổi UID dọn thông báo, không lẫn cache.
Không sensor thật trên AVD;6000bước là fixture UI/mô hình. Chưa thử/cài điện thoại.
Deploy chỉRules thành công, cảnh báo unusedknownNumbercũ, đọcserverkhớp6a1762dd…,
rulesete0057d3e-f72e-405c-b50c-cd5063e25c6c. Khôngghi/thửuserproduction.
Chi tiết nguồn/đơn vị/dữ liệu/giới hạn và log [wellness-insights.md](wellness-insights.md).

## Mới nhất26/10/2026 — Rollout mục1

Đã chạy lại **61/61 Rules tests** đúng candidate MVP, exit0,19,7giây; log
`build/wellness-rollout-candidate-tests.log`. Baseline đọc mới khớp bản đã review,
backup và diff lưu riêng. Firebase compiler/deploy qua; có1warning unused
knownNumber, không có compilation error. Đọc lại Rules trên server khớp SHA256
`2bb6a4a230da4d516cb757c564944782924e875ff9cc1f3b7397951773d59f62`;
ruleset `8add3549-ea41-4a5d-9f5c-22d1b62808cc`.

APK hash/manifest đúng bản thường đã nghiệm thu. Không sửa Flutter/native nên
không chạy lại597 tests/analyze/build; kết quả bên dưới thuộc đợt source trước.
Không test bằng cách tạo user hoặc ghi fixture trong production. ADB không có
thiết bị; user chọn kết nối sau, chưa cài APK hoặc kiểm cảm biến/lưu app qua Firebase
thật. Chi tiết và log: [wellness-rollout.md](wellness-rollout.md).

## 26/10/2026 — Nghiệm thu đợt mở rộng 6 tính năng

Kết quả ưu tiên cho source hiện tại; kết quả giai đoạn10 bên dưới là lịch sử.

| Lệnh/lượt chạy cuối | Kết quả |
| --- | --- |
| `flutter analyze --no-pub` | 0 issues, 25,7 giây |
| `flutter test --no-pub` | 597/597, 66 giây |
| `node --test tool/food_catalog.test.cjs` | 10/10 |
| `tool/test_emulators.ps1` | 70/70 Rules và22/22 Flutter SDK, exit0 |
| `node tool/test_stage10_rules_candidate.cjs --wellness` trong Firestore demo | 61/61, exit0 |
| `tool/test_android_core.ps1 -Suite wellness` trên AVD riêng | exit0, 1 end-to-end + teardown, 25 giây trong test |
| `flutter build apk --debug --no-pub` | Thành công, Gradle14,7 giây |
| `node tool/audit_source_secrets.cjs` | 424 file, 0 khớp các mẫu kiểm tra |

Đã kiểm tra thực: notification Android xuất hiện rồi được gỡ khi ghi bữa;
SQLite v3 round-trip extras/aliases/portion; ngủ start/finish/history; plan lưu
Firestore nhưng không tự cộng journal; dưỡng chất thiếu/zero; đổi UID không đọc
cache/lịch/notification cũ. SDK kiểm tra idempotent finish ngủ và chuyển plan→journal,
step sync không giảm số cũ. Rules kiểm verified/khách/chéoUID,5 hàng meal/plan/template
và6 ingredient recipe có đủ nutrients, dữ liệu sai ở giữa/cuối bị chặn.

Native lượt1 phát hiện chờ catalog autoDispose và lượt2 phát hiện UnmountedRef
khi đổi tài khoản; đã sửa và lượt3 qua. Một lượt cuối Rules vẫn dùng schema3 là
"unsupported" cho custom food trong fixture cũ; cập nhật ca phiên bản chưa hỗ trợ
thành4 theo schema mới và chạy lại toàn bộ70+SDK, không bỏ validation dữ liệu sai.

Chỉ dùng Firebase Emulator demo/AVD HealthMateMaintenanceQA; AI tắt bằng cờ rõ
ràng trong integration build, APK bàn giao dùng entry point app thật. Skia chỉ
được chọn ở runner QA vì Impeller/SwiftShader API30 vượt giới hạn uniform; không
đổi renderer của APK thường. SourceRules test bao gồm admin đang tạm gác, candidate
MVP riêng đã bỏ toàn bộ quyền quản trị và cũng qua61ca.

Chưa kiểm trên điện thoại thật/Android13+ hoặc độ chính xác step counter. AVD
không có sensor, app báo không hỗ trợ; không dùng số bước giả để nhận pass. Chưa
đo giao alarm đúng giờ sau Doze/reboot/OEM; notification tức thời đã kiểm thật.
Chưa deploy Rules hoặc cài APK điện thoại. Release signing chưa cấu hình.
Artifacts/log/hash/cấu hình còn thiếu: [wellness-expansion.md](wellness-expansion.md).

## Mới nhất 25–26/10/2026 — Giai đoạn 10 theo yêu cầu

Phần này ưu tiên hơn kết quả lịch sử bên dưới. Đã sửa parser USDA, bảo vệ cache
danh mục công khai, giữ giá trị chưa biết/zero đúng nghĩa, bỏ log tìm kiếm nhạy
cảm và bổ sung kiểm tra verified email cho admin local. Không bật lại web admin,
không đổi model/quota, không thêm package và không tác động dữ liệu production.

| Kiểm tra | Kết quả thực tế |
| --- | --- |
| `flutter analyze --no-pub` | No issues found, 51,5 giây |
| `flutter test --no-pub` | 584/584 qua, 68 giây |
| `tool/test_emulators.ps1` | 60/60 Rules (52 MVP + 8 admin lúc đó), 19/19 Flutter SDK, catalog import 155 tạo/155 bỏ qua khi retry |
| Admin Rules sau bổ sung email gate | 9/9 qua, tổng hiện tại 61 ca Rules đã kiểm tra |
| MVP candidate Rules tách admin | 52/52 qua, 19,5 giây |
| Auth Emulator email actions | 1/1 luồng verify/reset/refresh token; mã dùng một lần và mật khẩu cũ bị chặn |
| Worker tests/check/audit | 21/21 qua; syntax qua; npm audit 0 vulnerabilities |
| Android native core | SQLite cache + 10 checkpoint nghiệp vụ qua; exit0, 4phút13giây, log round7 |
| Android H7 dữ liệu riêng tư | 2pha qua (17giây/44giây); process death, draft mã hóa, offline/retry, SAF CSV/readback, đổi UID khi export và xóa dữ liệu đúng UID; exit0 |
| APK debug với URL chatbot thật | Build qua, assembleDebug 15,1 giây, 236.547.388 byte |
| Format/diff check | 11 Dart file trong phạm vi đúng format, diff-check sạch; check 271 file có 12 file ngoài phạm vi lệch format, exit1, không ghi sửa |

Android native chạy riêng bằng AVD `HealthMateMaintenanceQA` và backend Emulator
demo. Các lần đầu dừng vì bài thử cũ chưa mở disclosure Mục tiêu, đợi SnackBar,
còn đọc giao diện Tiến độ/ngày cũ hoặc runner chưa truyền AI=false rõ ràng.
Đã sửa thao tác/cấu hình fixture, giữ các assertion dữ liệu và quyền. Lượt cuối
qua toàn bộ, bao gồm UID thứ hai không đọc/thấy dữ liệu của UID trước.

APK: `build/releases/healthmate-stage10-debug.apk`, SHA-256
`7EC5FCD80B9CD67FF042F475BFAA70D9210A59E808D8E40E828A375DB5A61205`.
Chưa cài điện thoại vì người dùng chọn thử sau; chưa build signed release do
thiếu khóa riêng. Không ghi Emulator OOB là đã kiểm tra Inbox Gmail thật.

**Chưa triển khai production:** Rules thật thiếu verified email gate và schema
dinh dưỡng mới. Candidate MVP đã qua 52 tests, loại phần admin; phải duyệt trước
khi đổi điều kiện truy cập tài khoản chưa xác minh. App Check AI được xác nhận
ENFORCED; Firestore trả thiếu enforcementMode nên chưa được coi đã enforce.
Chi tiết lỗi, file, log, candidate hash và rollback tại
[báo cáo bảo mật](stage10-security-review.md). Không chuyển Giai đoạn 11.

## Bổ sung mới nhất25/10 — chatbot 50 lượt và khôi phục tab (Giai đoạn9)

Format qua; focused chat62/62,full Flutter578/578 (~67s); analyze cuối18info
có sẵn,0warning/error,exit1. Rules local lần cuối52/52,candidate production
4/4ca chat bao gồm UID/atomic pair/validation/50–51lượt. Lượt full Rules đầu
51/52 do assertion onboarding; test đó trên baseline trước thay đổi đã qua,
chạy full lại cũng qua. Ghi nhận dấu hiệu phụ thuộc thời điểm, chưa sửa ngoài scope.
APK debug có URL thật build42,2s,236.539.039bytes. Đã deploy/đọc lại đúng hash
Rules production chỉ đổi trần chat; không đẩy file local có các thay đổi khác.
Người dùng chọn cài/thử APK sau: chưa có kết quả native của bản mới. Chi tiết
và log: [chatbot-capacity-update.md](chatbot-capacity-update.md).

## Bổ sung25/10 — Giai đoạn9, kết nối API thật

Trạng thái mới nhất ở [chatbot-live-qa.md](chatbot-live-qa.md), ưu tiên hơn phần
lịch sử dưới đây. Worker đã deploy;21/21tests và syntax qua,auditproduction0;
endpoint thật thiếu/saiJWT401. Benchmark20fixture bằng model thật qua REST:
20/20đúng nguồn/ngày và hoàn tất,1,258–5,494s,median1,892s. Đây không phải test
độ chính xác dinh dưỡng hay native E2E. APK debug có URL build qua45,9s;
adb install -r trả Success, app đã mở, giữ dữ liệu. Kết quả native sau sửa nằm
ở đoạn tiếp theo. Flutter569tests là lượt full gần nhất trước thay đổi này;
không chạy lại full để ghi kết quả mới.

Native lần đầu báo "Phản hồi AI vượt giới hạn"; đã sửa SSE transport budget,
giữ text budget.55/55focusedchat tests qua8s,2regressions mới. Dart replay capture
thật45.817byte/844ký tự qua. APK sửa17,1s qua,analyze3file sạch; cài đè lần hai
Success,lastUpdateTime25/10/2026 02:59:04; người dùng xác nhận câu kiến thức chung
trả lời đầy đủ. Sau đó người dùng xác nhận mục tiêu kcal và follow-up đạm khớp
số liệu hoặc báo thiếu dữ liệu đúng. Luồng chính native đã chạy; chưa ghi các
test offline/quota/đổi UID/lịch sử mở lại là đã qua.
Full analyze cuối8,9s:18info có sẵn,0warning/error,exit1 do info; targeted3file0issues.

Ngày kiểm tra: **16/10/2026**. Phạm vi chỉ Giai đoạn 10; không triển khai Giai đoạn 11.
Người dùng đã duyệt MVP/demo **18+**, cập nhật onboarding và chặn gọi AI khi
chưa xác nhận đủ điều kiện. Giữ lựa chọn Gemini Developer API free tier:
tra cứu nhật ký tại ứng dụng, AI Chat chỉ nhận chủ đề chung định sẵn.

## Kết quả chạy thực tế cuối lượt

| Lệnh | Kết quả thực tế |
| --- | --- |
| `dart format lib test tool` | 136 file, 0 thay đổi ở lần chạy cuối |
| `flutter analyze --no-pub` | **No issues found**, 7,5 giây |
| `flutter test --no-pub` | **134/134 pass**, khoảng 14 giây, không skip |
| `tool/test_emulators.ps1` | **31/31 Rules + 4/4 Flutter SDK pass**, exit 0 |
| `flutter build apk --debug --no-pub` | **Thành công**, assembleDebug 16,2 giây |
| `flutter pub get --offline` | Thành công; dùng cache, không nâng phiên bản dependency |
| `git -c core.safecrlf=false diff --check` | Sạch; không có lỗi whitespace |
| `dart format --output=none --set-exit-if-changed lib test tool` | 136 file, 0 thay đổi, exit 0 |

APK: `build/app/outputs/flutter-apk/app-debug.apk` (artifact được Git ignore).
Build còn cảnh báo Firebase plugins `firebase_ai`, `firebase_app_check`,
`firebase_auth`, `firebase_core` dùng Kotlin Gradle Plugin; Flutter cảnh báo
khả năng không tương thích với bản Flutter tương lai. Cảnh báo không làm build
hiện tại thất bại; chưa tự nâng SDK/plugin để tránh đổi phạm vi.

Môi trường: Windows, Flutter 3.44.1/Dart 3.12.1 tại `D:\Flutter\flutter`,
Android SDK đã cài, Java 21 từ Android Studio, Node.js và Firebase CLI,
Chrome headless. `flutter devices` chỉ thấy Windows/Chrome/Edge, không có
Android kết nối trong lượt kiểm tra này.

Log phát triển ở `build/stage10-tests.log`, `build/stage10-emulators-final.log`,
`build/stage10-apk.log` chỉ nằm cục bộ, không đưa vào Git. Các dòng
`PERMISSION_DENIED` trong log Rules là kết quả mong đợi của test từ chối truy cập;
kết luận dựa trên test runner 31 pass/0 fail, không dựa trên việc log không có lỗi.

## Unit/widget tests

Bộ 134 test gồm các test đã có cho Auth, tài khoản, onboarding/profile/BMI,
công thức khẩu phần, nhật ký nhiều ngày/ranh giới ngày, Goals/Quest rules engine,
tổng hợp tuần, Dashboard, Chat và layout/navigation. Giai đoạn 10 bổ sung
**13 test** trong `test/security_regression_test.dart` (6) và
`test/food_scanner_test.dart` (7), đồng thời tái sử dụng fake repositories:

- Chính xác ngày sinh nhật 18 tuổi, giới hạn 120 tuổi; thiếu ngày sinh,
  thiếu onboarding, khác UID và tài khoản chưa đủ tuổi không được gọi AI.
- Hồ sơ cũ dưới 18 tuổi quay lại thiết lập, giữ nguyên dữ liệu và không làm
  crash date picker. Không tự thay đổi ngày sinh để cho phép gọi AI.
- `NaN`, Infinity và số overflow bị chặn ở form profile/dinh dưỡng/BMI;
  đầu ra JSON sai kiểu/quá dài/danh sách quá giới hạn bị từ chối.
- Scanner không có catalog vẫn có đường nhập thủ công; hủy picker, lỗi quyền,
  consent từng ảnh, matching và xác nhận bữa đều có test. Không tự lưu meal.
- Lỗi ngoài dự kiến, timeout, đóng khi tải, đăng xuất và kết quả về muộn không
  được gắn vào session mới. Hủy chờ chỉ bỏ kết quả, không cam kết hủy server.
- Re-encode PNG từ pixel giữ pixel thử nghiệm, bỏ metadata gốc của fixture;
  byte rỗng/quá lớn/ảnh hỏng bị chặn. Test không thay thế thử camera OEM thật.
- Ghi nước đang chờ máy chủ hiển thị trạng thái chờ và vô hiệu gửi nhanh lặp.

Widget tests dùng fake repositories/services; không chứng minh model AI thật,
camera thật hoặc App Check production hoạt động. Các bài test cũ về công thức,
parsing, engine và tổng hợp báo cáo đã chạy lại toàn bộ, không chỉ test mới.

## Rules và tích hợp Firebase SDK thật

Chạy lại trên **demo project cố định** `demo-healthmate-rules`, localhost Auth
9099/Firestore 8080 với `firebase.emulators.json`. Không dùng config Firebase
production, không import `firebase_options.dart`, không có fallback production.
Emulators tự dừng khi script kết thúc; không deploy Rules/indexes.

31 test Node trong `rules-tests/firestore.rules.test.cjs` kiểm tra quyền owner,
guest, hai UID, catalog chỉ đọc, schema/giới hạn, bất biến timestamp, meal totals,
Goals/Quest transitions/idempotence, Chat pair transaction/sequence và cleanup.
Hai test mới bao phủ dateKey/timestamp/offset và đường dẫn ngoài schema:

- Ngày trong `dateKey` phải trùng calendar day của timestamp sau khi cộng
  `timezoneOffsetMinutes`: có ca sát nửa đêm, bù giờ âm/dương, ngày nhuận,
  ngày không tồn tại và offset không hợp lệ cho meal/water/activity.
- Guest/UID khác và collection-group rộng bị từ chối; không ghi được root
  tùy ý, collection chưa định nghĩa hay field quản trị vào profile.
- Owner read/delete wildcard vẫn được giữ để dọn dữ liệu của chính tài khoản;
  wildcard này không cho create/update collection tùy ý. Các match cho phép
  có hiệu lực OR; không coi một nhánh `false` là phủ định nhánh khác.

`test/firebase_repository_integration.dart` có **4 test** dùng Flutter Firebase
Auth/Firestore SDK và các repository production thật, không dùng fake backend:

1. Đăng ký, tạo profile, hoàn tất onboarding hai lần vẫn giữ completion marker
   và một metric ban đầu; ghi/tải meal, water, activity, goal, quest và chat.
   Tạo quest/save turn lại không nhân đôi hay ghi đè trạng thái hoàn tất.
2. Đăng nhập bằng tài khoản thứ hai: không đọc hoặc ghi được dữ liệu UID thứ nhất.
3. Tắt mạng SDK, quan sát snapshot cache `hasPendingWrites`, Future ghi chưa
   hoàn tất; bật mạng lại xác nhận chỉ có một bản ghi nước mới (tổng 583 ml).
4. Xác thực lại và đổi mật khẩu; xóa tất cả collection được ứng dụng hỗ trợ,
   gồm messages lồng trong chat, kiểm tra dữ liệu không còn trong khi Auth
   vẫn tồn tại, rồi mới xóa Auth.

Mô phỏng offline này dùng SDK web trong Chrome; chưa kiểm tra cache/persistence
Android sau kill/restart, và không khẳng định mọi luồng offline đều đã được thử.
Xóa tài khoản vẫn cần kết nối mạng, không có transaction nguyên tử liên dịch vụ
Firestore/Auth. Test lỗi giữa chừng ở tầng controller tiếp tục nằm trong bộ
widget/unit có sẵn; không cố tạo lỗi production.

### Chạy lại trên máy khác và lỗi test runner đã xử lý

```powershell
flutter pub get
npm ci --prefix rules-tests
.\tool\test_emulators.ps1 -FlutterSdk 'D:\Flutter\flutter' `
  -Chrome 'C:\Program Files\Google\Chrome\Application\chrome.exe' `
  -JavaHome 'C:\Program Files\Android\Android Studio\jbr'
```

Trong lượt này không chạy `npm install/ci`; dependencies Node đã có. Bốn package
web vốn là transitive dependencies đã được khai báo thêm dưới **dev_dependencies**
để đăng ký plugin thật trong web test: `firebase_core_web`, `firebase_auth_web`,
`cloud_firestore_web`, `flutter_web_plugins`. `flutter pub get --offline` chỉ
đổi phân loại lockfile thành direct dev, giữ nguyên phiên bản/runtime dependencies.

SDK Windows hiện tại có lỗi slash trong route CanvasKit khi chạy Flutter web
test: JS/wasm 404 trước khi test khởi động, và đường dẫn test lồng thư mục cũng
gây lỗi selector. Giữ test SDK ở gốc `test/` và adapter headless riêng trong
`tool/chrome_test_adapter.*` phục vụ **file cache SDK nguyên bản** cho đúng URL
CanvasKit của test localhost. Không sửa SDK, nội dung test hay mã production
để bỏ qua lỗi. Các lần chạy trước adapter từng thất bại ở bootstrap; kết quả
31+4 cuối bảng là lần chạy script portable thành công sau khi khắc phục.
Khi SDK sửa lỗi, dùng `-WithoutChromeAdapter` để chạy Chrome trực tiếp.

Test SDK không mang hậu tố `_test.dart` nên không tự chạy trong suite mặc định.
Cần cờ `--dart-define=HEALTHMATE_EMULATOR_TESTS=true`; chạy sai cách sẽ fail
ngay thay vì im lặng skip hoặc kết nối production. Script giữ/restores biến môi
trường của terminal và chỉ khởi chạy Chrome profile test headless riêng.

## Thay đổi bảo mật/quyền riêng tư

- MVP/demo 18+ theo quyết định người dùng và
  [điều khoản tuổi Gemini](https://ai.google.dev/gemini-api/terms#age-requirements).
  Cổng AI dùng cùng UID/profile hợp lệ, không khởi tạo model khi bị chặn.
  **Ngày sinh tự khai, kiểm tra client không phải chứng thực tuổi phía server.**
- Giữ Chat free tier chỉ gửi ba chủ đề chung; không gửi text tự nhập, hồ sơ,
  nhật ký hoặc lịch sử. Scanner yêu cầu consent từng ảnh, công khai điều khoản
  xử lý miễn phí; không chấp nhận thông tin cá nhân trong ảnh. Decode/scale và
  encode PNG loại EXIF/GPS gốc, không làm ẩn nội dung cá nhân trong pixel.
- Không có Firebase Storage SDK, upload code hay collection lưu ảnh gốc.
  Storage Rules **không áp dụng** cho ứng dụng hiện tại. OS picker có thể tạo
  file tạm; không hứa mọi byte ảnh biến mất ngay sau khi đóng dialog.
- Android đặt `allowBackup=false`, `fullBackupContent=false` và XML loại dữ
  liệu khỏi cloud backup/device transfer. APK debug đã compile tài nguyên này;
  chưa kiểm thử chuyển máy OEM, không tuyên bố xóa an toàn cache đang tồn tại.
- Native Firestore cache có thể tồn tại sau đăng xuất. UI giải thích rõ; không
  tự clear cache làm mất ghi đang chờ. Khi offline không tự timeout/retry các
  ghi journal đang pending để tránh tạo bản trùng.
- Quét mẫu secret trong source nonignored và kiểm tra log/error paths: không
  phát hiện private/service-account/Gemini secret riêng; chỉ gặp public Firebase
  client config hiện có. Không in giá trị token. Đây là kiểm tra mẫu, không phải
  audit toàn bộ lịch sử Git, ignored files hoặc cam kết không có mọi loại secret.

## Giới hạn và việc cần làm trước demo/phát hành

- **Chưa chạy Android thật**, live AI/App Check/Play Integrity, quota/model,
  camera/permissions thực hoặc bài `integration_test/firebase_ai_smoke_test.dart`
  trong lượt này. Chưa kiểm tra release signing hay phát hành Play Store.
- Source Rules Giai đoạn 7/9/10 cần chủ project review và yêu cầu deploy riêng.
  Không có thay đổi Rules/index production trong nhiệm vụ này; chưa coi những
  thao tác mới đã được xác minh trên backend production.
- Android còn ID `com.example.healthmate`, icon template, release signing dùng
  debug template. Cần quyết định thương hiệu và signing/Play Integrity trước
  public release. Không tạo keystore/billing hay thay đổi project tự động.
- Rules bảo vệ UID/schema/range và các bất biến được test; không chứng thực
  độ chính xác dinh dưỡng, nguồn catalog, tuổi tự khai hoặc tính trung thực
  nhật ký do owner nhập. AI vẫn có thể sai và free tier có thể hết quota.
- Xóa account phía client biết các collection được app hỗ trợ. Khi thêm
  collection/subcollection mới phải cập nhật cleanup và test; không thể tự liệt
  kê mọi subcollection tùy ý như Admin SDK. Client không được tạo path ngoài schema.
- Test emulator không thay thế audit bảo mật độc lập. Kiểm tra bằng mắt/thực
  tế theo kịch bản Android trong README: chữ lớn/sáng tối, đổi tài khoản,
  mất mạng, pending write, Scanner, Chat, quên mật khẩu, xóa account thử nghiệm.

Không commit, stage, push, deploy Firebase, chạy migration, bật billing hoặc
tự tiến sang Giai đoạn 11. HEAD giữ nguyên
`310c8971ee2189ab4f01f2002edd4f93ff1e5535`; bảo toàn thay đổi chưa commit của
các đợt trước. Danh sách thay đổi Giai đoạn 10: [implementation-progress.md](implementation-progress.md).

## Tài liệu chính thức đã đối chiếu

- [Gemini API Terms](https://ai.google.dev/gemini-api/terms)
- [Firestore Rules conditions](https://firebase.google.com/docs/firestore/security/rules-conditions)
- [Rules structure/overlapping matches](https://firebase.google.com/docs/firestore/security/rules-structure)
- [Firestore offline](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- [App Check Flutter](https://firebase.google.com/docs/app-check/flutter/default-providers)
- [App Check debug](https://firebase.google.com/docs/app-check/flutter/debug-provider)
- [Android backup/device transfer](https://developer.android.com/identity/data/autobackup)

## Bảo trì MVP — 17/10/2026 (F01–F06, R01)

Đây là kết quả mới của đợt bảo trì, không thay thế lịch sử ở trên.
Chi tiết nguyên nhân, file, bằng chứng đỏ→xanh và giới hạn runtime:
[maintenance-2026-10-17.md](maintenance-2026-10-17.md).

- HEAD ban đầu/cuối: `3e8e9cc756c0a8caf1a882f6829088216736e56b`, checkout sạch lúc bắt đầu.
- Format `lib test integration_test`: 145 file, 0 thay đổi; analyze: No issues found (19,0s).
- Flutter: **176/176 pass**; catalog Node: **7/7 pass**.
- Firebase Rules **31/31** và SDK integration **6/6 pass**, project cố định
  `demo-healthmate-rules`, Auth/Firestore emulator, SDK qua Chrome.
- Android x64 debug build thành công (52,1s); có cảnh báo KGP từ plugin Firebase.
- Đã sửa/xác minh F01 giữ bản nháp + pending/session, F02 snapshot lịch sử,
  F05/F06 responsive/không cắt nhãn, R01 retry tạo mục tiêu theo ID ổn định.
- F03 đã sửa chẩn đoán/retry local; đọc Rules production xác nhận thiếu match ghi
  Goals/Quest/Chat. **Chưa deploy, chưa xác minh luồng Quest production đã hết lỗi.**
- F04 Android QA: một lượt Chat cloud18,151s/14chunks và Scanner service15,709s
  thành công; ba lượt khác timeout45s mỗi thao tác. **AI chưa ổn định, chưa sửa dứt điểm.**
  Không đổi model/provider/timeout, billing hoặc App Check enforcement.
- Layout: 24 tổ hợp360/390/412/900dp × scale1/1,5/2 × sáng/tối, có xem ảnh render.
  Chưa kiểm tra điện thoại thật hoặc toàn bộ scanner end-to-end.
- QA AVD mới trên D:, không dữ liệu người dùng; không uninstall/pm clear/wipe,
  tạo tài khoản production hoặc dùng dữ liệu sức khỏe thật để test.
- Không stage/commit/push/PR/deploy/migration. Chỉ thêm `http` đã có bắc cầu vào
  dev dependency cho probe, khôi phục offline, không nâng phiên bản.

## C1 — Chuyển sang phạm vi core (17/10/2026)

Báo cáo/phạm vi, mapping code, schema dự kiến và kế hoạch C2–C6:
[core-scope.md](core-scope.md). Kết quả dưới đây được chạy mới trong C1.
HEAD `86238197a9f8e24a2222da2da9e74164c35844ea`, working tree sạch trước sửa.

| Lệnh/môi trường | Kết quả thực tế |
|---|---|
| Baseline `flutter test --no-pub` | 176/176 pass,13s. |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 147file,0thay đổi. |
| `flutter analyze --no-pub` | No issues found,10,7s. |
| `flutter test --no-pub` | 201/201 pass,18s; 25test C1 mới, không skip/hạ assertion cũ. |
| `node --test tool/food_catalog.test.cjs` | 7/7 pass,0fail/skip. |
| `tool/test_emulators.ps1` | Rules31/31 + SDK6/6 pass trên Auth/Firestore demo-healthmate-rules, SDK qua Chrome. |
| `flutter build apk --debug --no-pub --target-platform android-x64` | Thành công,11,8s; cảnh báo plugin Firebase dùng KGP, không có token/cờ bật AI. |

Test C1 bao phủ flags mặc địnhfalse, không khởi tạo Chat/controller/service/picker
khi startup/tab/menu/route bị tắt; controller gọi trực tiếp không đọc/ghi lịch sử
hoặc gọi AI; scan action bị chặn; manual form vẫn mở; giữ Quest/Profile indexes;
Auth/onboarding, cold deep link, return link, Back và hai flags độc lập.
18tổ hợp360/390/412dp × scale1/1,5/2 × sáng/tối; dùng font thật và đã xem3ảnh render
menu+ trong build/c1-layout. Không gọi AI thật; test AI cũ bật flags riêng và dùng fake.

Đã GET read-only Rules production lúc11:59 UTC+07 ngày17/10/2026: release updateTime
2026-10-13T06:25:21.345792Z, vẫn khác local và thiếu match ghi goals/daily_quests/
chat_sessions. Không sửa Rules/indexes trong C1 vì source local đã có và đạt tests.
Chưa deploy hoặc chạy nghiệp vụ bằng tài khoản production, chưa xác minh indexes thật.

Không có Android kết nối (chỉ Windows/Chrome/Edge). Chỉ build x64; chưa cài/chạy E2E
Android/điện thoại vật lý, không uninstall/clear/wipe hoặc đụng session người dùng.
Không đổi schema, seed/migration, model/provider, App Check, billing hoặc dependency.
Local C1 đạt; production chưa nghiệm thu, đặc biệt mục tiêu/Quest còn chờ Rules được
review/deploy riêng. Không stage/commit/push/deploy; không làm C2–C6.

## C2 — Mục tiêu dinh dưỡng theo ngày hiệu lực (17/10/2026)

Chi tiết hành vi, schema, file, lỗi trung gian và giới hạn:
[core-scope.md — C2](core-scope.md#c2--mục-tiêu-kcalmacros-theo-ngày-hiệu-lực-17102026).
HEAD86238197a9f8e24a2222da2da9e74164c35844ea, bảo toàn C1 chưa commit.

- Baseline mới201/201 Flutter (16s). Cuối **234/234Flutter pass** (24s), không skip;
  **35/35Rules**, **7/7SDK integration** (demo-healthmate-rules, SDK qua Chrome),
  **7/7catalog Node** pass. Không dùng production cho test ghi/xóa.
- Format lib/test/integration_test155 file/0 thay đổi; analyze sạch11,6s;
  debugAPKandroid-x64 build18,0s. Cảnh báo KGP còn, chưa phải bản ARM/release.
-33 bài C2 gồm lịch sử hiệu lực/ngày trống/tương lai/cuối năm, macro/all-null/0/NaN/
  bounds, còn/vượt/zero denominator, mismatch confirmation, lỗi lưu/giữ draft/retry,
  pending 20 s/nhấn lặp, đổiUID và async muộn, đổi ngày khi tải, qua nửa đêm;
  UI18 tổ hợp360/390/412 × scale1/1,5/2 × sáng/tối + insets keyboard 260 dp.
- Đã xem3 ảnh font thật. Sửa đệm keyboard trùng sau khi xem ảnh, chạy lại toàn bộ
  kiểm tra. Chưa E2E Android/điện thoại/bàn phím thật, không cài/xóa app người dùng.
- SDK thực tế phát hiện transaction có thể ghi khi disableNetwork đã chặn server
  reads. Đã thêm server read-back trước success; lỗi ack giữ draft, retry cùng ID.
  Test mới xác minh bản ghi đã có sau reconnect và không nhân đôi khi retry;
  không giả định lỗi đồng nghĩa rollback.6SDK tests cũ giữ nguyên ý nghĩa/assertion.
- Cleanup đã kiểm tra xóa nutrition_targets. Rules mới kiểm tra owner/guest/B,
  document/collection/query, schema/bounds/date/timestamps, unknown fields và số xấu.
- GET Rules production read-only12:23 UTC+07,17/10/2026: vẫn updateTime
  2026-10-13T06:25:21.345792Z, chưa có quyền ghi nutrition_targets/Goals/Quest/Chat.
  **C2local đạt; production chưa nghiệm thu và chưa lưu được mục tiêu mới.**
- Không deploy Rules/index, commit/push, billing, migration, dependency upgrade
  hoặc gọiAI thật. ChỉC2; chưaC3. Logignored: build/c2-*.log và build/c2-layout.

## Core C3 — kiểm chứng mới ngày 17/10/2026

Checkout main, HEAD `86238197a9f8e24a2222da2da9e74164c35844ea`; bảo toàn C1/C2
chưa commit. Baseline thực tế 234/234 Flutter pass, 17s. Môi trường Windows,
Flutter 3.44.1/Dart 3.12.1, Java 21 và Chrome.

| Lệnh đã chạy | Kết quả cuối |
|---|---|
| `dart format lib test integration_test`, rồi `dart format --output=none --set-exit-if-changed lib test integration_test` | 162 file; 0 thay đổi ở kiểm tra cuối. |
| `flutter analyze --no-pub` | No issues found, 8,2s. |
| `flutter test --no-pub` | 270/270 pass, 22s, không skip. |
| `node --test tool/food_catalog.test.cjs` | 7/7 pass, 0 fail/skip. |
| `tool/test_emulators.ps1` | 39/39 Rules + 9/9 SDK pass, SDK 19s; project demo-healthmate-rules, Auth 9099/Firestore 8080. |
| `flutter build apk --debug --no-pub --target-platform android-x64` | Thành công, 11,8s; TEMP/TMP tại D:, không bật AI. |
| `git -c core.safecrlf=false diff --check` | Sạch. |
| `flutter devices` | Chỉ Windows/Chrome/Edge, không Android. |

36 test C3 trong core_journal_test.dart bao phủ ID favorite, copy qua nửa đêm/
tháng-năm/offset và chặn tương lai; nhóm bữa độc lập, tổng sau sửa/xóa, thêm đúng
ngày/loại; catalog lỗi không che logs. Recent có live/loading/error/retry/cache
và dùng lại snapshot khi catalog mất. Favorite có idempotency, pending, lỗi ghi,
retry, mất nguồn, tải hơn 40, đổi UID A→B và completion muộn. Copy có hủy không ghi,
retry cùng ID sau unknown ack, ID mới cho ý định mới, sửa ngày/giờ/loại/gram.
Catalog thiếu chất bị chặn cả khi là món gợi ý, không bị thay bằng món 0 kcal.
Giới hạn 5/6 món có test; giữ gram và snapshot dinh dưỡng.

UI có 18 tổ hợp 360/390/412dp × textScale 1/1,5/2 × sáng/tối, keyboard insets
260dp, favorite/mất nguồn và nút Save. Đã xem 3 ảnh dùng font thật trong ignored
build/c3-layout. Đây là render/widget test với insets mô phỏng, chưa phải Android
E2E hoặc bàn phím thật.

4 Rules test C3 mới kiểm tra owner CRUD/createdAt, guest/B bị chặn read/query/
write/delete; field/type/sourceKind/sourceId/docId/schema xấu, catalog không tồn
tại và nguồn mất vẫn bỏ favorite được. Client không được ghi catalog.
2 SDK test C3 mới dùng repository Firebase thật: favorite create/read/retry giữ
createdAt/remove, chặn đọc chéo; copy lưu/đọc lại và giữ 195 kcal dù catalog đổi,
đổi 100g thành 130 kcal, nguồn không đổi, dateKey/offset mới, một ID khi retry,
payload khác bị chặn, ý định copy mới dùng ID khác. Test offline kiểm tra ack lỗi
không đồng nghĩa rollback, reconnect/retry không trùng, favorite delete chờ mạng.
Cleanup xóa mọi collection A gồm favorite_foods trước Auth; favorite B vẫn còn.

Các hồi quy F01/F02/F05/F06/R01 và C1/C2 được chạy lại. Các lần đầu có lỗi test
cuộn tới vị trí cũ, assertion đếm catalog đã bỏ khỏi UI và finder Tooltip trả
RawTooltip. Đã sửa thao tác test theo key/vùng hiển thị, giữ assertion 195/130 kcal,
150/100g, số document và ý nghĩa hồi quy. Kết quả cuối ở bảng, không che fail.

GET Rules production read-only lúc 12:45:30 UTC+07 ngày 17/10/2026: release vẫn
2026-10-13T06:25:21.345792Z, normalized SHA256
`0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade`, thiếu match
favorite_foods/nutrition_targets/goals/daily_quests/chat_sessions.
**Local C3 đạt trong phạm vi test/build; production chưa đạt.** Không deploy
Rules/index, seed/migrate/delete production, commit/push, bật billing hoặc gọi AI.
Hướng dẫn deploy với project cụ thể trong core-scope chỉ là tài liệu, chưa chạy.

Giới hạn: chưa Android E2E, APK debug x64 chưa phải ARM/release; cảnh báo KGP của
plugin Firebase còn; draft chỉ giữ RAM và mất khi tắt app. Không cài/uninstall/
clear app hoặc đụng session thật. Sau khi Rules được triển khai có chủ đích, cần
xem trên Android với tài khoản QA: hai log cùng bữa → thêm qua favorite/recent →
copy/sửa ngày giờ gram → hủy/retry → kiểm tra tổng; chữ lớn/sáng tối/keyboard và
switch UID. Không dùng tài khoản sức khỏe thật thử cleanup.

Log ignored: build/c3-{baseline,tests,analyze,format,emulators,catalog,build}.log,
build/c3-production-rules.json; ảnh build/c3-layout. Chi tiết file/luồng C3 và kế
hoạch tiếp theo: docs/core-scope.md. Chỉ C3; chưa thực hiện C4.

## Core C4 — kiểm chứng mới ngày 17/10/2026

Checkout main, HEAD `86238197a9f8e24a2222da2da9e74164c35844ea`; bảo toàn thay đổi
C1–C3 chưa commit. Baseline270/270 Flutter pass19s. Windows, Flutter3.44.1/
Dart3.12.1/Java21, SDK thực qua Chrome; dữ liệu tổng hợp trên demo Emulator.

| Lệnh thực tế | Kết quả cuối C4 |
|---|---|
| `dart format lib test integration_test`, sau đó `dart format --output=none --set-exit-if-changed lib test integration_test` | 172file, không còn thay đổi ở kiểm tra cuối. |
| `flutter analyze --no-pub` | No issues found,7,4s. |
| `flutter test --no-pub` | 308/308 pass,39s,không skip;38test C4 mới. |
| `node --test tool/food_catalog.test.cjs` | 7/7 pass,0fail/skip. |
| `tool/test_emulators.ps1` | 47/47Rules +11/11SDK pass,SDK19s; project demo-healthmate-rules, Auth9099/Firestore8080. |
| `flutter build apk --debug --no-pub --target-platform android-x64` | Thành công45,5s; TEMP/TMP trên D:, không bậtAI. |
| `git -c core.safecrlf=false diff --check` | Sạch. |
| `flutter devices` | Windows/Chrome/Edge, không Android. |

38test C4 bao phủ serialization, alias/list bất biến, scale4chất, yield khác tổng
nguyên liệu, phần thập phân, bound0/âm/NaN/Infinity, thiếu macro/cặp khẩu phần,
6/vượt6dòng và lỗi dòng giữa/cuối/nested recipe. Widget test CRUD món riêng,
recipe chọn catalog và món cá nhân, thêm0,5phần đúng ngày thành snapshot, không
ngầm lưu thư viện, nguồn thư viện đã lưu nhưng bữa lỗi/retry, ack không rõ/pending
20s/double tap/cùng ID, logout và completionA đến sau khi chuyểnB, pagination41,
favorite đọc trực tiếp nguồn ngoài trang đầu và3namespace độc lập, lỗi đọc/cache/
missing/retry, route thư viện qua Auth. Kiểm tra macro0 phải nhập chủ động, không
coi trường trống là0; kiểm tra dinh dưỡng sau quy đổi không vượt MealItem bounds.

18tổ hợp360/390/412dp × textScale1/1,5/2 × sáng/tối: cả form món và recipe6dòng,
chỉnh dòng cuối, nhập một lần có checkbox thư viện, keyboardinsets260dp, Save vẫn
trong vùng bấm. Font Be Vietnam Pro/MaterialIcons nạp thật; đã xem4ảnh tại ignored
build/c4-layout. Đây là render/widget test, không E2E/keyboard Android thật.

8Rules mới kiểm tra CRUD/query owner, guest/B không đọc/ghi/xóa/query A; field lạ,
kiểu sai/missing/NaN/Infinity, cặp khẩu phần và alias mọi vị trí, createdAt bất
biến, recipe đủ6/vượt6/lỗi dòng0/2/5/nested, favorite cần nguồn đúngUID và vẫn bỏ
được khi nguồn xóa. Rule6dòng ban đầu vượt1.000expression; tối ưu binding số,
allowlist dùng chung và regex type/length; vẫn kiểm tra mọi dòng, không giảm test.
47Rules gồm các hồi quy catalog/MealLog/Profile/Goals/Quest/Chat cũ.

2SDK mới dùng FirebaseFoodLibraryRepository thật: create/read/update/delete,
watch server page, createdAt/retry/cùngID; six-row recipe, yield và phần thập phân;
MealLog và ingredient snapshots không đổi khi sửa/xóa nguồn; từ chối sửa nguồn
đã xóa; chặn B thao tác A; lỗi Source.server khi offline không biến thành missing,
write ack không rõ/reconnect/retry không trùng hoặc ghi đè payload khác, delete
pending tới reconnect. Cleanup thử A gồm custom_foods/recipes trước Auth và kiểm
tra custom food/recipe/favorite B còn nguyên. Emulator localhost/demo guard giữ
nguyên; không chạy seed hoặc cleanup trên production.

Các hồi quy F01/F02/F05/F06/R01/C1/C2/C3 giữ ý nghĩa. Điều chỉnh ensureVisible/
pump cho vị trí mới khi form có5nguồn, giữ assertion dinh dưỡng/số bản ghi cũ;
test nhập một lần điền0macro chủ động thay vì dựa vào field mặc định. Test CRUD
phát hiện confirm xóa dùng context của nested Navigator, đã sửa dialogContext
và chạy lại thành công. Một lượt compile bị ngắt; một lượt full test lỗi thật
errno112 khi copy compiler file trên C. Không hạ assertion/skip để che lỗi; chuyển
TEMP/TMP sang D và chạy đủ308test. Lệnh môi trường dùng ở lượt cuối:

```powershell
$env:TEMP = 'D:\HealthMateMaintenanceQA\tmp'
$env:TMP = $env:TEMP
```

GET Rules production read-only lúc16:11:23UTC+07 ngày17/10/2026: project
healthmate-app-20261013, releaseupdateTime2026-10-13T06:25:21.345792Z, normalized
SHA256 `0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade`.
Chưa match custom_foods/recipes/favorite_foods/nutrition_targets/goals/
daily_quests/chat_sessions. **Local C4 đạt trong phạm vi trên; production chưa đạt.**
Chưa deploy Rules/index, push/commit, billing, migration hoặc gọiAI. Không thay
package/config/schema MealLog; các field nguồn mới nằm trong namespace foodId.

Giới hạn: chưa E2E Android hoặc cài APK, APKdebugx64 chưa ARM/release; warningKGP
của plugin Firebase đã có vẫn còn. C ít chỗ trống, QA Flutter dùng thư mục tạm D.
Không clear/uninstall app, thay session hoặc xóa dữ liệu người dùng. Draft chỉ
RAM, mất khi đóng app. Sau deploy được yêu cầu riêng, cần QA Android với tài khoản
thử: CRUD nguồn → recipe yield/0,5phần → bữa → sửa/xóa nguồn → kiểm tra lịch sử →
favorite nguồn mất → offline/retry/đổiUID; xem chữ lớn/sáng tối/keyboard/nútSave/
confirmdelete. Không dùng tài khoản sức khỏe thật để thử cleanup.

Log ignored build/c4-{baseline,tests,analyze,format,emulators,catalog,build}.log;
build/c4-tests-environment.log giữ lỗi dung lượng; build/c4-production-rules.json
chỉ có metadata/hash/boolean. Ảnh build/c4-layout. Danh sách file/luồng/schema và
hướng dẫn deploy chưa chạy trong docs/core-scope.md phầnC4. Chỉ C4; chưa C5.


## Core C5 — Tiến độ, cân nặng và tổng hợp tuần (17/10/2026)

Chỉ C5 theo file Sửa; main/HEAD86238197 không đổi, working tree C1–C4 được giữ.
Không stage/commit/push/deploy/migration/billing hoặc gọi AI. Flutter3.44.1,
Dart3.12.1/Windows/Java21; TEMP/TMP D:\HealthMateMaintenanceQA\tmp. Kết quả mới:

| Lệnh | Thực tế cuối C5 |
|---|---|
| Baseline flutter test --no-pub | 308/308pass,33s |
| dart format lib test integration_test + kiểm tra --output=none --set-exit-if-changed | 174file,0đổi ở check |
| flutter analyze --no-pub | No issues found,7,1s |
| flutter test --no-pub | 337/337pass,41s,0skip |
| node --test tool/food_catalog.test.cjs | 7/7pass,0fail/skip |
| tool/test_emulators.ps1 | 47/47Rules +13/13Flutter SDK pass; SDK21s; demo-healthmate-rules |
| flutter build apk --debug --no-pub --target-platform android-x64 | Thành công,21,6s; build/app/outputs/flutter-apk/app-debug.apk |
| git -c core.safecrlf=false diff --check | Sạch |

29test C5 mới trong progress_test: tuần qua tháng/năm và Thứ Hai, ghi0 vẫn có ngày
trong mẫu số, missing không thành0, future không cộng, tổngmacro/nước/phút, cân
sort/real timestamp gaps, ít điểm, loading/error/retry/timeout, đổi tuần liên tục
và giữ tuần qua tab, đổi UID/pending, quick weight giữ draft/chặn nhấn lặp/logout,
Auth/deep link/push/back.18layout360/390/412 × scale1/1,5/2 × sáng/tối với font
Be Vietnam Pro thật, cả weekly chart và weight chart. Ảnh ignored build/c5-layout;
đã xem sáng100%/tối200%, sửa padding nhãn y và gợi ý vuốt chart chữ lớn.
Core_scope18matrix cũng đi qua Progress và xác minh AI vẫn không được khởi tạo.

Hai SDK C5 dùng Firebase repositories thật: lưu/đọc lại bữa/nước/vận động/cân nặng
một tuần qua năm mới, khớp600kcal/40gP/80gC/12gF/250ml/20phút,2ngày ghi và300kcal
trung bình, cân70→69,5 đúng ngày, không lấy lần cân ngoài tuần, B không đọc A.
Fixture chỉ emulator, không số liệu mẫu trong app. Target range kiểm tra base từ
trước tuần, đổi trong tuần, loại biên end, giữ mục tiêu cũ khi sửa bản mới, khoảng
sai, trước bản đầu, đọc server offline và B bị từ chối, dữ liệu hỏng không thành0.
47Rules kiểm tra owner/guest/B/allowlist/giới hạn; cleanup A trước Auth giữ dữ liệu B
được chạy lại. Không sửa Rules/index/schema/dependency C5 hoặc chạy migration.

Lượt full đầu334pass/1fail: Profile scrollUntilVisible tìm nhiều Scrollable sau
khi chart cuộn ngang. Đổi ensureVisible đúng nút sửa/xóa, giữ mọi assert CRUD rồi
chạy lại đủ337pass. SDK bổ sung ban đầu compile fail do tham số fixture sai;
sửa nutrition/source, chạy lại13/13pass. Info lint ban đầu đã sửa. Không skip hoặc
hạ assertion/Rules để che lỗi. Log lỗi vẫn nằm ở build/c5-tests.log và
build/c5-emulators-compile.log; các log kết quả cuối dùng hậu tố -final (riêng
catalog/format-check không hậu tố này). Không dùng số lượt cũ làm kết quả hiện tại.

GET Rules production chỉ đọc16:33:55UTC+07,17/10/2026: healthmate-app-20261013,
release2026-10-13T06:25:21.345792Z, normalized SHA256
0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade. Thiếu match
nutrition_targets/favorite_foods/custom_foods/recipes/goals/daily_quests/chat_sessions.
Metadata/hash/boolean trong ignored build/c5-production-rules.json; không chứa token
hoặc dữ liệu sức khỏe. Chưa deploy. **Local C5 đạt; production chưa nghiệm thu.**

Không Android trong flutter devices (chỉ Windows/Chrome/Edge); chưa E2E máy thật,
chưa cài/clear/uninstall/đổi session app. APK debugx64, chưa ARM/release. KGP warning
Firebase plugins cũ còn; C ít dung lượng nên Flutter QA dùng TEMP/TMP D.
Cần review và yêu cầu deploy riêng rồi QA Android: tổng tuần vs Journal, mục tiêu
lịch sử, sparse weight/ngày đo, quick+/save/retry/offline/UID,4tab ở chữ100/150/200%,
sáng/tối, vuốt chart, keyboard/safe area. Báo cáo tuần cần mạng, có refresh sau sửa
nhật ký; draft chỉ RAM. Dừng C5, chỉ đề xuất C6, chưa thực hiện nghiệm thu C6.

## Core C6 — Nghiệm thu Android và bàn giao (17/10/2026)

Chỉ C6/file Sửa. Main HEAD86238197a9f8e24a2222da2da9e74164c35844ea;
working tree C1–C5 có sẵn được giữ. Không stage/commit/push/deploy/migration/
billing, không bật hoặc gọi AI. Flutter3.44.1/Dart3.12.1/Java21 trên Windows.
TEMP/TMP D:\HealthMateMaintenanceQA\tmp; native project copy trên D do ổ C còn
khoảng157MB. Không sửa lock/dependency; pub get --offline chỉ tái tạo tooling copy.

### Lệnh và kết quả thực tế

| Lệnh/phạm vi | Kết quả C6 |
|---|---|
| Baseline flutter test --no-pub | 337/337pass34s |
| dart format lib test integration_test test_driver | 178file,0đổi ở lượt cuối |
| dart format --output=none --set-exit-if-changed lib test integration_test test_driver | Exit0,178file/0đổi,0,8s; build/c6-format-check.log |
| flutter analyze --no-pub | No issues found10,8s |
| flutter test --no-pub --reporter expanded | 349/349pass37s,0skip |
| node --test tool/food_catalog.test.cjs | 7/7pass,142,9ms,0skip |
| tool/test_emulators.ps1 | 47/47Rules pass15,7s +14/14Flutter Firebase SDK pass22s; demo-healthmate-rules |
| tool/test_android_core.ps1 -DeviceId emulator-5560 -CrossDriveBuild | Exit0,10/10checkpoints,137s; Flutter driver báo All tests passed |
| flutter build apk --debug --no-pub --target lib/main.dart --target-platform android-arm64 | Pass24,8s trên copy D; APK150691276bytes |
| gradlew :app:processReleaseMainManifest --offline (bổ sung) | Fail7s: chưa cache io.flutter armeabi_v7a_release/arm64_v8a_release/x86_64_release; không có kết quả release merged manifest |
| git -c core.safecrlf=false diff --check | Exit0,sạch; build/c6-diff-check.log; không stage |

12test mới (core_acceptance_regression_test) kiểm tra: success/error UID A trễ
không thay trạng thái B; đổi UID sau reauth không đổi mật khẩu B; cleanup A về
trễ không xóa Auth B;2form hồ sơ/cân giữ draft khi lỗi/retry; lần cân sau onboarding
hôm nay là mới nhất; sửa cân giữ nguyên giờ/microseconds;2form pending bỏ khi logout;
active stream error giữ lỗi, Future cancel lỗi không thoát sang phiên mới.
SDK mới kiểm tra expectedUid sai từ chối cả reauth/updatePassword/delete và tài
khoản vẫn đăng nhập/hoạt động bình thường sau đó. Các test F01/F02/F05/F06/R01,
ngày trống/nửa đêm/timezone/tuần qua năm mới, schema/ownership/cleanup của C1–C5
được chạy lại, không bỏ hoặc hạ assertion. Rules C6 không sửa so với C5.

### E2E Android native với dữ liệu thử tách biệt

AVD riêng HealthMateMaintenanceQA/emulator-5560, Android11/API30/x86_64,
1080x2280/density440 (~393dp), timezone Asia/Bangkok/UTC+07. AVD chạy headless
trên D, không dùng máy/AVD có phiên thật. Native Firebase SDK + repositories thật
và UI/router thật; không fake health repository. Named app healthmate-core-c6-qa,
project demo-healthmate-rules, Auth9099/Firestore8080 tại10.0.2.2; persistence false.
Tài khoản alice/bob-email QA được tạo mới trong emulator; catalog một fixture
tổng hợp có nhãn QA. Không gửi dữ liệu thử vào Firebase production.

1. Đăng ký/onboard A, đọc hồ sơ isOnboardingComplete từ repository thật.
2. Fixture mục tiêu hôm qua1800; UI hôm nay2000; đọc lại lịch sử vẫn1800.
3. Chọn catalog fixture, nhập150g →195kcal và lưu qua form/SDK.
4. Sửa200g →260kcal; copy sang hôm qua có ID khác, gram/snapshot đúng; Journal
   hôm qua hiển thị260/1800 thay vì dùng mục tiêu hôm nay.
5. Thêm350ml nước/25phút vận động/69,5kg, cân mới nhất đúng; tuần có2ngày ghi,
   520kcal,12gđạm/112gtinh bột/1,2gbéo,350ml/25phút, khớp dữ liệu thật.
6. UI tạo món200kcal/100g; recipe nguyên liệu100g/yield80g/2phần →250kcal/100g.
7. Ghi0,5phần=20g/50kcal; sửa món thành300kcal/100g, đổi yield160g rồi xóa món/
   công thức; MealLog50kcal và bữa260kcal còn nguyên.
8. DisableNetwork, lưu target2100: form giữ draft/lỗi; enableNetwork/retry chờ
   ack, document đúng2100; hôm qua1800, chỉ2phiên bản theo ngày, không trùng.
9. Chọn theme tối và native textScale200%, điều hướng Tiến độ, không exception.
10. Logout A, đăng ký/onboard B; B thấy tuần chưa ghi nhật ký và không lẫn món A;
    SDK từ B đọc targets A bị từ chối, own-target B null. AI flagsfalse và các
    controller/service Chat/Knowledge/Scanner chưa được khởi tạo.

Log **build/c6-android.log**,4PNG hợp lệ **build/c6-android/c6-01-journal-history.png,
c6-02-progress.png,c6-03-dark-large-text.png,c6-04-account-isolation.png**, được
driver ghi trong lượt pass17:26:26UTC+07. Đã mở xem bằng mắt Nhật ký ngày cũ,
Tiến độ có dữ liệu, tối/chữ200% và B trống. PNG tối chữ lớn đang ở đầu báo cáo;
không dùng ảnh đó làm bằng chứng đã xem mọi điểm biểu đồ. Native keyboard/scroll
được thao tác trong luồng, không warnIfMissed=false. Các matrix widget sáng/tối/
360–412dp/font100/150/200% và chart/công thức dài vẫn trong full349tests.
AVD và backend QA đã tắt sau khi xong; không xóa/clear/wipe app có phiên thật.

### Lỗi đã tìm thấy và các lượt chưa đạt

Baseline/new regression ban đầu tái hiện lỗi session/form. Sau sửa,20test liên
quan pass; sau thêm timestamp/cancel tests,51test nhóm liên quan pass11s rồi full
349pass. Log before/after được giữ trong build/c6-regression-*.log; không đổi
assertion để làm code lỗi thành pass.

Native build đầu lỗi Kotlin incremental different roots giữa cache C và source D.
Chỉ env override chưa đủ; runner nay tạm thêm kotlin.incremental=false vào copy
gradle.properties rồi khôi phục nguyên bytes trong finally. Các lượt flutter test
đầu thử uninstall package QA chưa tồn tại và báo DELETE_FAILED_INTERNAL_ERROR;
không có session thật bị gỡ. Runner cuối dùng flutter drive --keep-app-running.
Các lỗi harness tiếp theo: IME resize làm tap chưa vào nút, DatePicker OK khác
confirmText Chọn, convertFlutterSurfaceToImage chỉ được gọi một lần. Đã sửa helper
đúng API, không bỏ assert nghiệp vụ. Logout từ Profile giữ return destination
Profile; test nay xác nhận đã vào app shell rồi bấm Home, không giả định router
phải tự đổi về Dashboard.

Native cũng phát hiện2lỗi sản phẩm: cân mới cắt giờ về00:00 không thành latest;
Firestore async* cancel báo domain error khi logout sau consumer đã dispose.
Đã sửa timestamp và biên hủy subscription kèm test; active errors vẫn tới UI.
Cleartext emulator bị Android từ chối: debug-only config mở10.0.2.2/127.0.0.1/
localhost, base cleartextfalse; không bật cleartext toàn app hoặc đổi release.
Lượt native cuối đủ10checkpoint, không còn lỗi unhandled khi đổi UID.
Các log thất bại nằm D:\HealthMateMaintenanceQA\c6-android-{first,second,third,
drive1,drive2,drive3,drive4,drive5}.log; lượt pass drive6.log. Không lấy ảnh48byte
từ thử nghiệm cache-pull lỗi làm bằng chứng;4PNG cuối đã được driver ghi đè hợp lệ.

### Build, snapshot và quyền riêng tư

APK thường: **D:\HealthMateMaintenanceQA\HealthMate-core-debug-arm64.apk**,
150691276bytes, SHA2560a3a8ad877016891f532aeb68b6be95f7603985bb39267d56a99bf8c401ecd6e.
ZIP kiểm tra có lib/arm64-v8a/libflutter.so. Target lib/main.dart, AI mặc địnhfalse;
APK E2E không được dùng thay APK sản phẩm. Chưa cài máy thật hoặc ký release.
build/c6-snapshot-parity.json so SHA256213file nguồn/test/assets/Android/config/
Rules/scripts với copy D:0mismatch; gradle.properties đã phục hồi. Reports/README
được cập nhật sau kiểm tra, không tham gia code hash. Log build/c6-build-arm64.log.
Kiểm tra release offline bổ sung bị thiếu cache như bảng trên; log c6-release-
manifest.log, không coi lỗi môi trường này là release đã build thành công.

Scan155file lib/tool/integration_test/test_driver/android/app/src với pattern
private-key/service-account/OAuth/GitHub token:0findings; build/c6-secret-scan.json
chỉ lưu metadata. Scan có phạm vi hữu hạn; Firebase client config public không
được coi là credential Admin. Không in token CLI hoặc dùng tài khoản sức khỏe thật.

### Production, blocker và bước sau

GET Rules/index metadata chỉ đọc lúc17:04:32UTC+07,17/10/2026. Project
healthmate-app-20261013, releaseUpdatedAt2026-10-13T06:25:21.345792Z, SHA256normalized
0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade, khác source.
Thiếu nutrition_targets/favorite_foods/custom_foods/recipes/goals/daily_quests/
chat_sessions; water/dateKey+consumedAt và activity/dateKey+performedAt indexes
READY. Metadata/hash/boolean ở build/c6-production-rules.json; không token/data.
Không deploy Rules/indexes, không migration hoặc CRUD production trong C6.

**C6 local đạt. Production chưa nghiệm thu**; các phần mới có thể bị permission
denied nếu chạy backend đang triển khai. Cần review và yêu cầu deploy riêng trước
QA tài khoản thử trên điện thoại thật. Chưa kiểm chứng App Check/Play Integrity
thực, release signing, process death/draft qua đóng app. KGP warning các Firebase
plugins còn, không tự upgrade. Xem máy thật: số ngày/mục tiêu cũ, sparse chart/vuốt,
keyboard/back/safe-area,4tab, tiếng Việt, sáng/tối/font100/150/200%, offline/retry/
đổiUID. Cleanup chỉ thử tài khoản tổng hợp trên emulator. Báo cáo tuần cần mạng/
refresh sau sửa nhật ký; draft chỉ RAM. Dừng C6, chưa tự làm phần khác.

## U1 — Nhật ký/Tiến độ và Firebase review (18/10/2026)

Chỉ U1 theo file PROMPT-Agent-Cai-Thien-HealthMate-UX-Firebase.md. REPO_ROOT là
checkout HealthMate2 hiện có, main/HEADfd2f72bbc07c0afe62942e0b62d5e1bf0b71bb12,
working tree sạch lúc đầu. Không checkout/reset/clean/pull đè; U1 chưa commit/push,
U2/deploy, billing, migration/seed, App Check changes hoặc AI. Flutter3.44.1,
Dart3.12.1/Java21/Windows; TEMP/TMP D:\HealthMateMaintenanceQA\tmp.

### Kết quả thực chạy

| Lệnh | Kết quả U1 |
|---|---|
| Baseline flutter test --no-pub --reporter expanded |349/349pass36s; u1-baseline.log|
| dart format --output=none --set-exit-if-changed lib test integration_test test_driver |180file0đổi/exit0,0,63s; u1-format-check.log|
| flutter analyze --no-pub |No issues found43,8s; u1-analyze-final.log|
| flutter test --no-pub --reporter expanded |370/370pass64s,0skip; u1-tests-final.log|
| node --test tool/food_catalog.test.cjs |7/7pass273,9ms; u1-catalog.log|
| tool/test_emulators.ps1 |47/47Rules pass19,1s +14/14Firebase SDK pass24s; u1-emulators.log|
| tool/test_android_core.ps1 -DeviceId emulator-5560 -CrossDriveBuild |Exit0,10core checkpoints + viewport và Gần đây;164s; u1-android.log|
| flutter build apk --debug --no-pub --target lib/main.dart --target-platform android-arm64 |Pass39,6s trên copy D; u1-build-arm64.log|
| node --check tool/inspect_firestore_deployment.cjs |Exit0|
| tool/inspect_firestore_deployment.ps1 |GET cấu hình/backup thành công, không deploy; u1-firebase-inspection.log và u1-firebase-final.log|
| git diff --check |Kiểm tra cuối trong u1-diff-check.log|

Log trong build/ (ignored). Số test là kết quả lệnh lượt này, không cộng kết quả
2test độc lập được nhắc trong prompt hoặc dùng số C6 như kết quả U1.

21test mới u1_ux_test gồm2viewport sáng/tối (fixture đủ target3macro, không cuộn),
luồng recent ngày/loại bữa/gram/snapshot/1write;2loading/error có dữ liệu cũ bằng
FutureProvider refresh thật; target lỗi/retry giữ tổng; ngày trống/chưa đặt;
macro0/excess/UID sheet; weekly logs lỗi không thêm target query;12matrix
360×800/412×915×scale100/150/200%×sáng/tối, keyboard260dp không che nút Lưu.
Giữ assertion nghiệp vụ cũ: target lịch sử/late response, mean mẫu số, tuần ranh
giới, no extra queries/listeners, stale UID, F01/F02/F05/F06/R01, snapshot/copy,
idempotency/offline/retry, favorites/library/recipe và cleanup.

### UX và ảnh trước/sau

[Gallery kèm ảnh/JSON đã lưu trong repo](ux/u1/README.md), cùng390×844/100%, font
đóng gói thật, fake repositories/synthetic data: ngày18/10/2026,2bữa195kcal khác
ngày, target2000kcal/100gP/250gC/60gF,750ml/25phút, cân70→69,5kg. 8ảnh trước/sau,
sáng/tối, scroll offset0. Trước sửa: addBreakfast1319–1367, chart888–1128;
sau: addBreakfast497–545, chart362–602; viewport không bị bottom bar che đến748dp.
Test đo full rect và hitTestable của nút, chart/range/tổng; không ensureVisible
hoặc cuộn trước assertion viewport đầu. Chữ lớn được đọc/cuộn thay vì ép chiều
cao/font. Đã mở ảnh sáng/tối và ảnh native để xem bố cục/số/nhãn/biểu đồ.

Luồng Gần đây giữ5bấm,0search,1xác nhận khẩu phần đã có,0xác nhận mới; cuộn1→0.
Baseline flow được chạy lại trên copy UI/formfd2f72b (6blob đã so,0mismatch),
không checkout ngược source người dùng. Saved16/10/Bữa sáng/150g195kcal/1write;
khác quy tắc global+ hôm nay. Các phép đo không được suy thành benchmark người
dùng hoặc tốc độ mạng. Fixture/ảnh không phải số liệu sức khỏe production.

### Android SDK/repository thật qua backend demo

AVD riêng HealthMateMaintenanceQA/emulator-5560, Android11/API30/x86_64,
1080×2280/density440/UTC+07, named Firebase app QA, demo-healthmate-rules tại
10.0.2.2:9099/8080. Đã đọc runner và xác minh AVD/project; không dùng máy/phiên
người dùng, không clear/wipe hoặc fixture production. QA AVD đã tắt khi xong.

Kịch bản core cũ vẫn đủ10checkpoint: onboarding, target hôm qua1800/hôm nay2000,
thêm150g195kcal/sửa200g260kcal/copy giữ snapshot và ngày,350ml/25phút/69,5kg,
tuần thật520kcal từ2ngày trước bữa recipe, CRUD món/công thức/giữ MealLog50kcal,
offline target2100/retry chỉ2phiên bản/giữ hôm qua, tối chữ200%, logout/A→B và
permission denied khi B đọc A. AI flagsfalse/service không khởi tạo.

Thêm target đủ100gP/275gC/60gF cho native viewport: addBreakfast584–632dp trong
body đến685,1dp và hit-test được; chart top386dp, range và tổng hit-test được,
không cuộn trước đo. Sau core bước8, recent5bấm/khôngsearch/gram200/260kcal/
ngày hôm nay/Bữa sáng và3MealLog. Cuối tuần tổng830kcal vì đã thêm bữa recipe50
và recent260, không coi khác fixture520 ban đầu là lỗi tổng.5PNG từ driver ở
build/u1-android,2ảnh viewport copy vào gallery; không dùng last-screen teardown
trống làm bằng chứng UI. Đây là Android emulator, không điện thoại thật/cloudE2E.

### Các lượt chưa đạt và cách xử lý

Lượt full đầu337pass/14fail: title cũ, tổng cũ bị gộp, target/daily details đang
đóng và drag700 cố định làm trượt qua nút mới. Cập nhật finder về journal-screen,
kiểm tra kcal và từng macro, mở details rồi giữ các assert lịch sử/quyền/query,
ensureVisible đúng action trong test thao tác (không dùng trước viewport proof).
Luồng recent mới ban đầu thiếu thao tác xác nhận khẩu phần **đã có** nên nút Lưu
bị dialog chắn; thêm thao tác đó vào cả trước/sau, không đổi production flow.
Lượt focused ban đầu còn2fail (recent và label0macro cũ), sau sửa test pass.

Analyze đầu có unused totals và test gọi copyWithPrevious internal; bỏ biến thừa
và dùng FutureProvider refresh thật để kiểm tra stale data, không ignore lint.
Harness Android đầu thiếu import MealType; thêm import, chạy lại thành công.
Một lượt test sau thay helper thiếu import Completer, đã thêm lại dart:async;
final21UX tests rồi full370pass và analyze sạch. Không xóa test/hạ Rules/assert
để che lỗi; log first/related và D:\HealthMateMaintenanceQA\u1-android.log giữ
lỗi trước sửa, lượt pass native là u1-android-second.log (copy thành build/u1-android.log).

AVD SwiftShader có log Impeller/GLES shader active uniforms exceed GL_MAX_FRAGMENT_
UNIFORM_VECTORS; ảnh thật đã xem có đầy đủ card/chữ/biểu đồ và E2E không có test
exception. Không sửa engine hoặc bỏ bảo vệ app; chưa xác minh mọi GPU/máy thật.
KGP warning Firebase plugins còn. App Check placeholder chỉ ở named emulator app;
production App Check không bị đổi/tắt. Không có kết quả release build trong U1.

### Build, cấu hình và giới hạn

APK thường lib/main.dart debug ARM64 **D:\HealthMateMaintenanceQA\HealthMate-U1-debug-arm64.apk**,
150690083bytes, SHA256
cd9796fbc43159db9db001536752d20eb37cf9c596fa86a6c5bc8a708173b4a0.
APK này khác test target; APK C6 cũ được giữ. Copy source D khớp217file Dart/test/
asset/Android/Rules/config/script (build/u1-source-parity.json),0mismatch;
gradle.properties override Kotlin incremental khác ổ chỉ tạm trên QA copy,
finally đã khôi phục. Không nâng/cài package mới hoặc đổi pubspec/lock.

Ổ C có lúc còn100MB; giữ tmp/build native ở D và chuyển **artifact generated**
build/app cũ968MB sang D:\HealthMateMaintenanceQA\archived-project-build-app-20261018
sau xác minh absolute source/destination. Không xóa dữ liệu/cache ngoài công việc,
không thay source hoặc APK C6 đã bàn giao; C còn khoảng1GB sau chuyển.

Rules/index local không đổi từfd2f72b: SHA256LFtrimd33e017ecc4ca63ef1068ec55ab3ff732df0430492e57fcbfee6b4a89b796877.
Đã review owner/schema/bounds/timestamps và chạy lại47Rules +14SDK, gồm guest/B
read/query/write bị chặn và cleanup A giữ B. Không thêm query/listener/schema/index.
Tool inspect chỉ GET Rules release/source, database metadata và indexes; auth CLI
ở RAM, output metadata/source/config rollback không có credential hoặc dữ liệu
sức khỏe. Tool yêu cầu output build mới, không overwrite backup cũ.

Production GET cuối **19:12:59UTC+07,18/10/2026**: healthmate-app-20261013,
database(default)/asia-southeast1/FIRESTORE_NATIVE, CLI15.22.4. Release update
2026-10-13T06:25:21.345792Z, rulesetb83d6f60-1e9a-49b3-a3e7-239ccf0d3ee0,
hash0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade,
matchesLocalfalse. Vẫn thiếu create/update targets/favorites/custom/recipes/goals/
quests/chat;2water/activity composite indexes READY, không cần index mới.
Backups build/u1-firebase-review và u1-firebase-final, diff252thêm/7bỏ so với
production; không phải diff Rules mới do U1. [Playbook](firebase-deployment-plan.md)
có commit/hash/đích, exact command chỉ Rules, GET xác minh/rollback và QA sau U2.

**Local U1 đạt / Rules production chưa deploy / E2E production chưa kiểm chứng.**
Chưa tài khoản QA production được giao, chưa máy thật/Play Integrity/release
signing. Draft chỉ RAM và báo cáo cần mạng/refresh như core cũ. Giữ AI tắt,
không tự tạo tài khoản cloud/thử xóa thật. Dừng U1; U2 chỉ sau yêu cầu rõ từ chủ
sản phẩm. Bảng/lệnh deploy trong playbook là phần chuẩn bị, chưa được thực thi.

## U2 — deploy Rules và kiểm thử production thật (18/10/2026)

Đây là kết quả sau yêu cầu hoàn tất toàn bộ file UX/Firebase, thay trạng thái U2
còn chờ trong phần lịch sử U1. Người dùng cho phép tạo đúng hai tài khoản QA có
dữ liệu tổng hợp và chỉ dọn dữ liệu QA. Base main/fd2f72bbc07c0afe62942e0b62d5e1bf0b71bb12;
giữ working tree U1, chưa stage/commit/push. Không thay app code trong U2.

### Kiểm tra mới thực sự đã chạy

| Lệnh/kiểm tra U2 | Kết quả |
|---|---|
| `.\tool\test_emulators.ps1` | 47/47 Rules + 14/14 Firebase SDK, exit 0; SDK 20 giây |
| `firebase deploy --only firestore:rules --project healthmate-app-20261013` | Exit 0, release chỉ Rules thành công |
| Inspect GET trước, sau deploy và cuối production QA | Đúng project/default DB; sau deploy/final hash khớp local; hai indexes READY |
| `.\tool\test_production_qa.ps1 -AllowProductionQa -CredentialsFile <PRIVATE_FILE> -VerifiedDeploymentDirectory <VERIFIED_METADATA>` | Flutter test Chrome/backend production: **1 scenario, 10 checkpoint, 27 giây, pass cả teardown** |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 180 file, 0 thay đổi, exit 0 |
| `flutter analyze --no-pub` (cuối) | No issues found, 6,7 giây, exit 0 |

Analyze đầu báo một unnecessary import dart:async ở harness mới (57,6 giây);
đã bỏ import thừa rồi chạy analyze sạch. Không sửa/hạ test để che lỗi. Flutter
370/370, catalog 7/7, Android API30 E2E và build APK là lần chạy **U1** đã ghi ở
trên, không phải chạy lại trong U2. Không có thay đổi sản phẩm sau lần U1 đó.

### Deploy và khả năng phục hồi

Trước deploy GET lúc 19:31:42 UTC+07: Rules release cũ 13/10/2026, hash
0b7a11a28ca4768390e12fca777157acdb269c489e4a59b5c78b8b2c9f87dade.
Backup đầy đủ source/metadata/firebase.rollback.json tại
`D:\HealthMateMaintenanceQA\u2-before-20261018-193138`; đã so bản copy trước deploy.
Rules/index source không đổi so với fd2f72b; không thêm diff vô nghĩa.

Release mới 2026-10-18T12:33:45.507953Z (19:33:45 UTC+07), ruleset
423ff6c8-79b7-4158-ba4f-2de9871a715d. Hash LF-trim deployed/local cùng
d33e017ecc4ca63ef1068ec55ab3ff732df0430492e57fcbfee6b4a89b796877;
matchesLocal=true trong hai GET sau deploy và cuối QA. Hai composite water/activity
vẫn READY. Không deploy indexes hoặc chạy rollback; không đổi App Check/billing.
[Metadata và log đã lưu](firebase/u2/README.md),
[lệnh rollback chỉ Rules](firebase-deployment-plan.md).

### SDK E2E production và dữ liệu QA

Chrome headless, Firebase Web SDK thật và repository/model ứng dụng thật; named
apps A/B/guest tách khỏi default session, Auth persistence NONE, Firestore cache
không lưu đĩa. Hai QA email cố định có prefix/run; retry cùng credential, không
tạo tài khoản bổ sung. Credentials lưu ngoài repo với ACL riêng, không in log.
Harness không có hậu tố _test.dart nên full suite thông thường không gọi cloud.
Runner và Dart cùng chặn thiếu opt-in, sai prefix/project/hash hoặc credential
trong repo. Chạy từ QA copy D để artifact test riêng, không phân phối test build.

- Onboarding tổng hợp 18+, lưu/tải lại profile và cân nặng ban đầu.
- Target ngày cũ/mới, cập nhật hôm nay giữ lịch sử, query range thật.
- Món riêng, công thức và favorite retry idempotent; bữa 20g từ recipe 80g có
  50kcal. Sửa/xóa hai nguồn vẫn giữ 50kcal, scale snapshot 40g thành 100kcal;
  copy sang hôm trước vẫn 50kcal đúng ngày.
- Nước 250ml, đi bộ 20phút; query server dateKey/orderBy dùng index production.
- Goal tạo hai lần cùng ID vẫn một bản; Quest hoàn thành không reset khi ensure.
- Logout/login cùng UID, dữ liệu target/meal đọc lại đúng từ server.
- Tắt network 3 giây không xác nhận lưu; bật lại, đợi thao tác cũ kết thúc rồi
  retry cùng operation ID, đúng một bữa 50kcal. Không coi timeout là hủy write.
- **50** yêu cầu guest/B đọc/query/ghi/xóa vào A nhận permission-denied: profile
  và 11 collection core, thêm update profile/delete meal. Không chỉ nhìn Rules.
- Dọn dữ liệu Firestore A, xác minh B vẫn còn profile rồi dọn B. Đọc server xác
  nhận profile không tồn tại và cả 11 collection rỗng; teardown kiểm tra lại hai
  tài khoản. **Giữ hai Auth QA**, không thử xóa Auth production.

Không đọc/sửa/xóa hồ sơ thật, seed food_catalog, migration hoặc gọi AI.
Production SDK log + tổng hợp không credential ở docs/firebase/u2. Raw log và
credential riêng ở D:\HealthMateMaintenanceQA\u2-production-qa-20261018194000.
APK thường lib/main.dart U1 giữ nguyên, không chứa QA dart-defines; không rebuild
Android trong U2 vì source app không đổi và Rules nằm trên backend.

**Local đạt / Rules đã deploy đúng / SDK production E2E đã kiểm chứng.**
Không suy thành Android UI production, điện thoại thật, Play Integrity, release
signing hoặc mọi thiết bị/mạng đã đạt. Các giới hạn KGP/GPU/draft RAM ở U1 vẫn
còn. Hoàn tất file U1/U2 và dừng, không thêm giai đoạn hoặc push ngoài yêu cầu.

Kiểm tra bàn giao lúc 19:45 UTC+07: `git diff --check` sạch, parser PowerShell
runner không lỗi, scan chính xác QA password trên 37 file text thay đổi/bằng
chứng không có kết quả khớp (không phải chứng nhận quét mọi loại secret).
Staged 0; HEAD và origin/main đã biết vẫn fd2f72b; diff Rules/index/dependencies 0.
APK U1 thường giữ SHA256 cd9796fbc43159db9db001536752d20eb37cf9c596fa86a6c5bc8a708173b4a0.

## H0 — 19/10/2026: kiểm thử theo identity và release guard

Đã sửa fixture để recipe là breakfast và chọn bữa mới theo ID; đủ 3 ID,
breakfast đúng ngày/200g/260kcal, ít nhất 2 breakfast hợp lệ. Không thay app clock.
Format 1 file/0 đổi, analyze sạch 33,8s, Flutter 370/370 pass 56s. Android QA
emulator-5580/HealthMateMaintenanceQA/API30 với Auth+Firestore demo-healthmate-rules:
10 checkpoint + viewport/recent pass 159s, debug build 42,7s. Runner trên QA copy D,
log D:\HealthMateMaintenanceQA\h0-android.log. KGP/SwiftShader warnings còn.
Release bỏ ký debug ngầm; private key.properties được ignore. Gradle dry-run release
thiếu khóa dừng đúng thông báo; chưa build release hoặc tạo keystore/đổi package.
Chi tiết docs/release-readiness.md và docs/h-improvements.md. Theo yêu cầu trực tiếp
thực hiện tuần tự H0–H7, chuyển H1 sau mốc H0 này; không deploy/import production.

## H1 — 19/10/2026: khẩu phần catalog, tìm kiếm và dữ liệu có nguồn

Hoàn thành code/data review, chưa import production. Reader khẩu phần tương thích
cũ, fallback gram khi metadata hỏng, không dùng basis/unit không hỗ trợ. Đổi đơn vị
giữ lượng, phần phân số preview/snapshot đúng. Tìm exact/alias/token trước substring;
giữ tìm dấu/không dấu/NFD. Ba dòng TH yogurt100g có nguồn nhà sản xuất;47 công thức
đề xuất phần tham khảo theo yield, không coi tô=100g. docs/h1-catalog-review.md.
Node9/9; Flutter379/379 (42s), focused51/51, H1 cuối9/9; analyze sạch9,6s.
Rules47/47 + SDK15/15 (21s); import emulator151create, retry0create/update/conflict.
Fixture import ban đầu bỏ pagination và fail; diagnostic xác định vn2007-9007,
sửa đọc nextPageToken rồi đạt. Benchmark tool đầu5lint imports/braces đã sửa.
Android QA emulator-5580/API30/demo-healthmate-rules đủ10checkpoint pass154s;
phần0,75 ×200g lưu150g/195kcal qua repository thật. Ảnh docs/ux/h1/catalog-fractional-portion.png
đã xem; benchmark19truy vấn có nhóm held-out/brand/missing,15positive+4rỗng có chủ đích,
19đúng first/empty, giữ và báo kết quả nhiễu. Dataset branch151 khác production158.
Dry-run production: existing158/create3/skip148/proposedMetadataUpdates47/conflict0;
manifest/benchmark ở docs/ux/h1. Tool --apply chỉcreate, metadataupdates cần review/
maintenance riêng. Không đổi Rules/index/schema nhật ký hoặc deploy/AI/billing.
Chưa máy thật/release ký. Hạn mức5h còn60%; chuyển H2 theo yêu cầu chuỗi.

## H2 — 19/10/2026: ghi quen nhanh và bữa mẫu, đạt local/emulator

Recent ưu tiên khi có lịch sử, tài khoản mới về Tìm món; dùng trực tiếp lượng
hiển thị vào bản nháp, Hoàn tác/Sửa riêng, Lưu mới ghi server. Hay dùng đếm theo
20 bản ghi gần nhất/tối đa8 món, không tải toàn lịch sử. Cùng fixture/điểm bắt
đầu đo3tap/0scroll/0gõ/0xác nhận lượng thay cho5tap; đúng ngày/bữa/gram/snapshot.
Bữa mẫu thuộc UID, CRUD tên+1–5snapshot, tạo từ bữa cũ/món đang chọn, dùng bản sao
vào ngày/bữa chọn và sửa từng món. Không gộp thành recipe, nguồn mất vẫn giữ lịch
sử. Cleanup client mới thêm meal_templates; cần nâng client trước enable backend
để client cũ không bỏ sót collection mới khi xóa tài khoản.
Format20file0đổi; analyze sạch11,4s; Flutter385/385 pass52s; targeted6/6 (UID+
pending/retry/bounds/widget100/150/200%). Rules48/48 + SDK16/16 pass25s; test A/B,
guest,5món/overflow/timestamps, offline/retry snapshot và cleanup A giữ B.
Rules đầu vượt1000expressions khi5món; dùng regex/let/sum bounded giữ đủ validation
rồi focused/full pass. UI test đầu chưa prewarm Auth làm dialog đóng, sau đó
x2 chữ dài đẩy ô tên khỏi lazy viewport: sửa harness auth và đưa tên lên trước
hướng dẫn ngắn; cuối6pass. UID test cần giữ subscription Auth trước await.future;
đã sửa và full385pass. Không bỏ assertion hoặc nới Rules lấy pass.
Android final: emulator-5580/HealthMateMaintenanceQA/API30/demo-healthmate-rules,
10checkpoint +H1portion/H2recent vàtemplate UI pass176s. Tạo mẫu2món từ draft,
hủy không log; dùng/chỉnh100g +20grecipe nguồn đã xóa =180kcal đúng ngày/Bữa tối;
xóa mẫu không đổi meal; logoutBriêng tư. Ảnh/flow ở docs/ux/h2.
Lượt Android đầu cần reveal trường lazy sau bố cục mới; lượt sau dùng Rules cũ
trong QA copy nên lưu bị từ chối. Thêm tool/sync_qa_workspace.ps1 đối chiếu241
source/config/asset gồm root Rules rồi final pass. Không deploy production để
sửa lỗi QA copy. Raw logs D:\HealthMateMaintenanceQA\h2-android*.log.
Schema/Rules/rollback và client compatibility trong h2-templates-deployment.md;
local Rules mới chưa deploy, catalog H1 mới chưa import. Không commit/push/AI/billing.
H3–H7 chưa triển khai tại mốc H2; tiếp tục tuần tự theo yêu cầu, còn40% hạn mức5h
ở lần kiểm tra trước Android final.

## H3 checkpoint 19/10/2026 — code/Rules/SDK đạt, Android đang chạy

Chi tiết hành vi, file, schema/rollout, log và các vòng lỗi/sửa trong
[H3 Quick Add](h3-quick-add.md). Ghi100g/100ml/khẩu phần/tổng, kcal-only/macro
optional, unknown khác0; nhật ký/copy/template/history dùng snapshot.
Format32file; analyze sạch9.8s; fullFlutter397/397(52s),focusedcuối13/13(4s);
Rules49/49(13.2s),SDK17/17(23s), importerEmulator151/0retrychanges.
Android H3 đang chạyQA AVDemulator-5580/demo-healthmate-rules, chưa kết luận đạt.
Production chưa ghi/import/deploy, Git chưacommit/push. H4–H7 chưa triển khai.
Hạn mức5h còn7% lần kiểm tra gần nhất; sẽ theo yêu cầu dừng/lưu/tắt máy khi<5%.

### H3 cập nhật kiểm chứng cuối

FullFlutter398/398(56s), analyze sạch10.2s sau fix UI, focused13/13(3s),
Rules49/49(13.5s), SDK17/17(23s). AndroidH3đủ10checkpoint pass206s; hiện chạy
lần cuối sau cải thiện spacing/helper/snackbar từ ảnh kiểm tra. Chi tiết cả lần
lỗi và sửa trong h3-quick-add.md. Hạn mức5h đã<5%(còn4%); chốtH3/dừngH4–H7,
lưu tiến độ và tắt laptop theo yêu cầu. Không commit/push/deploy/importproduction.

### H3 đạt; tiếp tục theo yêu cầu mới sau khi hạn mức reset

Android visual-final đạt200s, đủ10checkpoint/H2templates/H3QuickAdd. Đã xem ảnh
volume-preview mới: khoảng cách/hướng dẫn rõ và không còn snackbar cũ che form.
Nguồn243fileQAđối chiếu. H3 hoàn tất local/Emulator; chưa nghiệm thu production.
Người dùng gửi “tiếp tục đi” sau khoảng nghỉ; kiểm tra mới: hạn mức5h used0%,
còn100%. Chưa có lệnh shutdown nào được thực thi/lập lịch. Tiếp tục H4–H7 theo
lệnh mới, vẫn theo dõi điều kiện<5% và tắt máy ở cuối chuỗi hoặc tại ngưỡng đó.
Các mục “Android đang chạy” ở trên là checkpoint lịch sử, đã có kết quả cuối này.

## H4 — đạt local/Android Emulator

Helper tùy chọn mức duy trì từ FAO/WHO/UNU/Schofield; đầu vào tự chọn, chưa lưu
sinh lý, phạm vi18–59 và đường quay về nhập tay. Xem cách tính, đưa kcal vàoform,
chỉnh rồi xác nhận lưu với ngày hiệu lực; giữ macro/historical target. Không tự
thâm hụt/dư năng lượng hoặc cộng kcal vận động. Quyết định/nguồn/giới hạn và file
chính trong h4-goal-guidance.md; cần chuyên gia rà soát trước phát hành rộng.
Format10file/5đổi rồi9file0; analyze sạch12.9s; focused9/9(7s); full407/407(49s).
Android h4-android-final.log:10checkpoint +H1/H2/H3/H4pass235s trênAVDQA/API30,
demo-healthmate-rules. H4 UIxemkếtquả2670kcal chưa ghi, sửa2600rồiLưu, đọcSDK
đúng2600, ngàytrước1800khôngđổi; BkhôngđọcA. Ảnhdocs/ux/h4/maintenance-estimate.png.
Lượt nativeđầu bị guardchặn vìAVDđãđóng trong khoảngnghỉ; khởi độnglạiđúngAVDQA,
khôngchuyểnsangmáythật. KGP/SwiftShaderwarningscũcòn. H4khôngđổischema/Rules,
khôngdeploy/importproduction, khôngcommit/push, AIgiữtắt. TiếptheoH5.

## H5 — đạt local/Emulator

Báo cáo30/90, giữtuầncũ; mụctiêuđúnghiệulực; trạngtháixácnhậnđủbữa theoUID+
ngày+revision, không tự coi1bữa làđủ. Ngàytrống khônglà0kcalđãăn; macrothiếu giữ
coverage. Range2001sentinel/chặn>2000doc mỗiquery,1–90ngày; lỗi nguồn riêng,
refresh rõ, không thêmrealtime. Cân hiển thịđiểmthật/khoảngcáchthời gian/sốmẫu.
File/schema/rollout và lỗi đãsửa trongh5-period-reports.md. Cleanupday_reviews,
Rulesmớiđãtestnhưngchưadeploy, khôngindexmới/migration/AI/importproduction.
Focused53/53(19s); H5+UID11/11(13s), full417/417(122s) trước thêmtestUIDcuối;
analyze sạch39s. Rules50/50 vàSDK18/18(31s), kểcả2.001waterfixturebịbáooverflow,
xáoriêngfixturetrongfinally. NativeAndroid227s/10checkpoint+H1–H5đạttrênAVDQA/
demo-healthmate-rules: UIxácnhậnngày,30/90tổngkhớpSDK,1ngàyxácnhận, khoảngcũ
trống/next/trởvềvàBriêngtư. Ảnhdocs/ux/h5/period-30.png. Khôngcommit/push/deploy.
Tiếp theoH6; H7chưatriểnkhai. Hạnmức5h lần gầnnhất còn66%, tiếptụctheodõi.


## H6 — đạt local/Emulator, chưa triển khai production

Thêm chất xơ có nguồn, phân biệt 0 thật/thiếu/tổng biết một phần; giữ coverage khi
nhân khẩu phần, recipe yield, snapshot, sửa/copy/bữa mẫu và báo cáo. Nguồn 4 ID
USDA có sẵn; branch 155 mục, production dry-run 158 đang có/3 create/51 metadata/
0 conflict/152 skip, không apply. Hợp đồng meal4, custom/recipe2, template3,
chống hạ phiên bản và rollout/rollback xem h6-fiber.md và database-design.md.
File chính: nutrition_models/catalog_food_reader, firebase_nutrition_repository,
food_library models/forms/text/repository, quick_add_dialog, meal_templates,
journal/weekly summary, firestore.rules, legacy_usda.json, importer và tests.
Format 59 file/0 đổi ở kiểm tra cuối; analyze sạch (62.1s); Flutter423/423(67s);
unit H6 mới nhất5/5 sau thêm assert round-trip. Rules51/51, importer Emulator155
create/retry0change, Firebase Flutter Web SDK19/19(43s), gồm thiếu nguồn, retry,
A/B, cleanup và H5 overflow2.001rows. Android QA API30/emulator-5580 +
demo-healthmate-rules: 10checkpoint và H1–H6 đạt239s; 250ml/100ml ->3g, nguồn
recipe đã xóa nhưng bữa cũ vẫn0.5g, B riêng tư. Lượt native đầu221s thất bại do
assert nhầm recipe một nguyên liệu biết chất xơ thành thiếu; sửa kỳ vọng và đọc
lại bản ghi thật rồi chạy lại. Các lỗi Rules/codec phát triển ghi ở h6-fiber.md.
Ảnh h6/fiber-volume.png và ảnh H5 mới đã xem: nút xác nhận rõ, preview3g,
macro thiếu không thành0, nội dung báo cáo có thể cuộn. Còn cảnh báo KGP/
SwiftShader/Impeller cũ; cần xem thêm máy thật. Không commit/push/deploy/index/
import production/AI. H6 hoàn thành; tiếp H7 theo yêu cầu, theo dõi ngưỡng5%.


## H7 — checkpoint chưa hoàn thành, dừng do hạn mức còn 4%

Đã chốt lõi CSV thuần journal_csv.dart + test/h7_csv_test.dart:4/4 qua; định dạng
UTF-8 BOM/CRLF/quote, chặn formula injection, range1–90 ngày, dateKey/UTC/offset/
schema và missing/0/partial. Chưa nối UI/controller/file picker hoặc quyền UID
cho export; chưa lưu/phục hồi draft bền vững. Không gọi đây là H7 hoàn chỉnh.
Format2file; analyze lượt đầu1lint thiếu ngoặc, đã sửa; lượt cuối xem log và
h7-checkpoint.md. Không chạy lại toàn bộ suite sau4test mới; fullH6 trước đó423/423,
Rules51/51, SDK19/19, Android239s/10checkpoint+H1–H6 đã đạt. H7 chưa testAndroid.
Không có package/collection/Rules/index/localstorage mới cho H7, không production
write/commit/push. Còn lại và hướng nối tiếp ghi rõ h7-checkpoint.md. Theo chỉ thị
người dùng, lưu checkpoint và tắt máy bình thường sau khi chốt phần CSV này.


Chốt checkpoint H7: analyze cuối sạch (11.5s), format2file; CSV4/4. Bản sao323file nguồn/tài liệu và log nằm ở D:/HealthMateMaintenanceQA/h0-h6-h7-checkpoint-20261019; patchtracked riêng h0-h6-h7-working-tree.patch. H7 còn thiếu đúng như danh sách trên, không công bố hoàn tất.

## H7 — hoàn thành local/Android Emulator sau khi tiếp tục

Tiếp tục từ checkpoint 4% sau khi cửa sổ 5 giờ reset; H0–H6 và toàn bộ thay đổi
chưa commit được giữ. H7 hoàn thành, không tự chuyển mốc khác. Hạn mức được đọc
ở các mốc; không cần dùng lý do hạn mức để bỏ phần nghiệm thu còn lại.

- Android giữ nháp mã hóa AES-256/GCM, khóa AndroidKeyStore và AtomicFile trong
  noBackupFilesDir. UID/ngày/bữa, snapshot nguồn, unit, missing/0/partial, UTC,
  offset, operationId và minimum schema giữ xuyên restart. Tối đa20nháp/512KiB,
  TTL7ngày, dọn khi mở kho; khôi phục/bỏ nháp do người dùng chọn, không tự submit.
- Mọi entry point MealFormDialog nối cùng kho. Lưu operationId+payload local
  trước gửi Firestore; chỉ dọn sau ack. Gián đoạn có thể vẫn commit; retry giữ
  ID cũ, không mặc định lỗi Future đồng nghĩa chưa có bản ghi máy chủ.
- Cá nhân có Xuất nhật ký CSV, ngày1–90, bốn nguồn nhật ký/cân nặng, query giới
  hạn H5; không export profile/chat/goals/draft và không gọi đây là toàn bộ account.
  CSV BOM/CRLF/quote/chặn công thức, schema/đơn vị/timezone/basis và nutrient status.
  Consent riêng tư, Android document picker, kiểm tra UID trực tiếp SDK và phiên
  trước ghi bytes, native đọc lại khớp mới báo thành công. Không email/upload tự động.
- Xóa tài khoản dọn nháp đúng UID sau Firestore/trước Auth; lỗi giữa chừng giữ Auth
  cho retry, chặn callback trễ ghi lại. Không xóa B hoặc CSV người dùng đã xuất.
- Sửa hai guard ref.mounted ở userProfileProvider/bodyMetricsProvider: lỗi cũ được
  native H7 phát hiện khi đổi UID lúc bootstrap, trực tiếp chặn nghiệm thu A/B.
  Không refactor toàn bộ profile; regression có completer theo sự kiện thực.

File chính: core/data/private_local_data.dart; Android PrivateLocalData.kt và
MainActivity.kt; meal_drafts/data/meal_draft_store.dart, presentation/draft_picker.dart;
MealFormDialog, JournalScreen, MealDraft; data_export/models/journal_csv.dart,
data/journal_export_service.dart, presentation/journal_export_dialog.dart;
ProfileScreen, auth repository/currentUid và controller cleanup; profile_providers;
test/h7_csv_test.dart, h7_private_data_test.dart; integration_test/h7_private_data_test.dart;
tool/test_h7_android.ps1 và verify_h7_export.ps1. Đường dẫn/contract đầy đủ:
[h7-private-data.md](h7-private-data.md), ảnh và chứng cứ [ux/h7](ux/h7/README.md).

Kiểm tra cuối (19/10/2026):
- flutter test --no-pub: **454/454 qua, 43s**, build/h7-flutter-final-6.log.
- flutter analyze --no-pub: **No issues found, 17.4s**, build/h7-analyze-final-5.log.
- Native QA: **phase1 12s + phase2 32s, exit0**; D:/HealthMateMaintenanceQA/h7-android-final.log
  và c6-workspace/build/h7-android/phase-1.log, phase-2.log. Process death/restore,
  offline/uncertain commit/retry, OS picker/file readback, UID switch và A/B cleanup đều qua.
- tool/verify_h7_export.ps1: **file Downloads1554byte khớp từng byte** với CSV từ
  repository thật; BOM và đủ bốn loại dữ liệu. build/h7-export-final.log.
- H7 không sửa Rules/indexes. Bộ Rules51/51, Web SDK19/19 và native H0–H6 trước đó
  vẫn là kết quả lịch sử đã ghi, không giả là vừa chạy lại các suite đó trong H7.

Các lượt phát triển thất bại được giữ log: lỗi dùng navigator context của màn
thay dialog; thêm nút export làm test vị trí metric cần sửa layout; lỗi provider
đã disposed (đã thêm guard); runner Windows ExitCode/file sharing và chờ frame
khi OS picker mở (sửa harness). Một kỳ vọng offline=0 sau reconnect không đúng
hợp đồng acknowledgement; giữ assert chưa tự gửi trước Lưu, sau retry đúng một
ID trên server. Bài regression đầu có chờ theo thời gian bị flaky; đổi sang
completer/sự kiện bootstrap, full suite452qua. Script đọc CSV ban đầu quote sai
đường dẫn có khoảng trắng qua exec-out; đã sửa và đối chiếu byte thật, không bỏ assert.

Không thêm package, collection, Rules/index hoặc migration H7. Không commit/push,
không deploy Firebase/import production, không bật AI/billing hoặc sửa package ID.
Production vẫn cần review/ủy quyền rollout Rules/schema H2–H6 và catalog manifest
riêng; APK E2E trỏ demo không phải APK phát hành. Web/desktop chưa có nháp bền vững
hoặc lưu CSV; local không đồng bộ nhiều thiết bị, không xóa được bản sao offline
trên thiết bị khác, file CSV do người dùng quản lý. Cần QA điện thoại thật và cấu
hình release/signing còn thiếu như release-readiness.md. Đề xuất tiếp theo: review
rollout và kiểm tra máy thật; **không triển khai** trong lượt này.

Đóng kiểm tra: dart format --output=none --set-exit-if-changed trên toàn bộ76file
Dart thay đổi: 0file cần format, exit0. git diff --check với cr-at-eol phù hợp
Windows: exit0; không thay line ending hàng loạt. HEAD vẫn
1c258b37366d47ef562eed65f326e490efabae99, không stage/commit/push. Ảnh export đã xem
và lưu docs/ux/h7/export-android.png. Chỉ định tiếp theo là review/máy thật, không
chạy thêm giai đoạn hoặc deploy. Sau khi sao lưu, tắt máy bình thường theo chỉ thị
người dùng; không dùng /f để ép mất tài liệu đang mở.

Bổ sung chốt hồi quy H7 trên bố cục cuối:
- Android core H0–H6: 221s, đủ10checkpoint và H1–H6, exit0;
  D:/HealthMateMaintenanceQA/h7-core-regression-3.log. Recent vẫn3tap; U1 kiểm tra
  vùng bấm thêm bữa trong viewport đầu thật. Hai thao tác hủy hẳn trong fixture
  dùng Bỏ bản nháp để phù hợp UX H7, không bỏ các assert dữ liệu/ngày/snapshot.
- Lượt core đầu phát hiện nút nháp riêng đẩy nút thêm bữa xuống: chuyển thành icon
  cạnh Bữa ăn. Lượt sau cho thấy nút bỏ nháp trong body khó truy cập khi cuộn:
  đưa lên AppBar, chống bấm lặp. Test360/chữ2/tối phát hiện dropdown bữa tràn1.2px;
  isExpanded xử lý đúng, không giảm cỡ chữ/ẩn lỗi. Test xóa nháp lỗi rồi retry và
  xóa account lỗi server/local giữ Auth, giữ UID B đã bổ sung; full cuối454/454.
- H7 native chạy lại trên bố cục cuối:12s/32s, exit0. Đọc lại file Downloads thật
  sau lượt cuối vẫn1554byte khớp từng byte. Không dùng ảnh cũ để kết luận UI mới;
  ảnh journal-android.png lấy từ core lượt đã qua, đã kiểm tra bằng mắt.

Bản sao cuối gồm nguồn/tài liệu chưa commit và log kiểm chứng: D:\HealthMateMaintenanceQA\h0-h7-complete-20261019-191713. Hạn mức được kiểm tra trước tắt máy; không đợi xuống dưới5% vì công việc đã hoàn tất.

## 20/10/2026 — UI/UX theo ảnh tham chiếu MyFitnessPal

Trên nền ba0557d cùng bản sửa palette cục bộ; chưa commit/push/deploy.
Báo cáo chi tiết: [mfp-ui-redesign.md](mfp-ui-redesign.md).

| Kiểm tra | Kết quả thực tế | Chứng cứ |
| --- | --- | --- |
| Format file Dart thay đổi | 25 file, 0 cần format ở lần kiểm tra cuối | Dart formatter exit 0 |
| Flutter unit/widget đầy đủ | **468/468 qua**, 52s, exit 0 | build/mfp-flutter-complete.log |
| Analyze | **0 error, 0 warning, 21 info**, exit 1 | build/mfp-analyze-complete.log |
| APK Android debug | **Build thành công**, 16.4s, exit 0 | build/mfp-build-complete.log |
| Ảnh widget QA | 24 ảnh, sáng/tối, cỡ chữ 1.0/1.5 | docs/ux/mfp/README.md |

Các info còn lại: withOpacity ở widget cũ, print của unified search và http
chưa khai báo trong dependencies chính. KGP warning xuất hiện lúc build.
Không gọi các info này là analyze thành công hoàn toàn.

14 test mới kiểm tra tương phản 4,5:1, dữ liệu thật qua fake repository, ngày
trống, phản hồi ngày cũ đến trễ, trạng thái tải/lỗi mục tiêu, mục tiêu tự đặt,
copy bữa chỉ lưu sau xác nhận, tab dùng chung range, xuất CSV mở đúng dialog,
retry báo cáo và search đảo thứ tự ở cả form standalone và thư viện món.
Các test cũ giữ xác nhận số liệu/UID/quyền thao tác/nháp/operation ID; cập nhật
cách mở báo cáo chi tiết và vùng bấm sau khi đổi UI. Hai fixture standalone
được bọc ProviderScope theo ConsumerStatefulWidget hiện tại. Không xóa test.

Các kết quả 48 hoặc 65 case lỗi trong log phát triển là các lượt trước sửa,
không phải trạng thái cuối. Toàn bộ suite trên source cuối qua 468 case.
Không chạy lại Firestore emulator/security hoặc production QA; không sửa Rules,
indexes/schema hoặc package. Chưa kiểm chứng camera/API online trên máy thật.

### 2026-10-20 — Thanh dưới 5 ô, hiện lại Scanner/Chat

- dart format 8 file Dart thuộc lượt sửa: qua, kiểm tra lại 0 thay đổi.
- flutter test --no-pub --reporter expanded: **485/485 qua**, 60 giây, exit 0.
  Log build/navigation-full-test-final.log. Thêm 16 widget test về 5 ô ở rộng
  320/390, textScale 1/1,5/2 và sáng/tối; tab chuyển đúng route, + ở giữa, vùng
  bấm >=48; mở Scanner không gọi camera/AI, Mục tiêu/Chat mở từ + và Thêm;
  barcode có mặt trong form thật dùng sourcesBuilder kể cả khi AI tắt.
  Thêm test mặc định cờ hiển thị mà không khởi tạo Firebase/AI. Các test core-only
  vẫn kiểm tra hai cờ false chặn AI và đường dẫn trực tiếp như trước.
- flutter analyze --no-pub: **21 info, 0 warning, 0 error**, exit 1. Đây là các
  info withOpacity/print/http có sẵn; không gọi analyze sạch. Lượt phát triển đầu
  có thêm 1 info thiếu ngoặc trong test mới, đã sửa.
- flutter build apk --debug --no-pub: qua, assembleDebug 26,3 giây, exit 0.
  APK build/app/outputs/flutter-apk/app-debug.apk; cảnh báo KGP còn tồn tại.
- Một lượt full trước sửa test cuộn có 484 qua/1 lỗi do locator Sửa khẩu phần
  chưa được dựng vì ngoài viewport; đã bổ sung scrollUntilVisible, giữ nguyên
  assertion ngày/loại/khẩu phần/tổng và dữ liệu gốc. 36 test nhật ký riêng qua
  sau sửa, rồi toàn suite cuối qua 485. Log lỗi giữ ở build/navigation-full-test.log.
- Đã xem ảnh widget render today-dark-1.0.png: 5 ô hiện đúng. Ảnh trong docs/ux/mfp
  tiếp tục là fixture tổng hợp, không phải dữ liệu thật hay kiểm tra điện thoại.
- Không chạy camera/AI/Open Food Facts thật, không thay/deploy Rules/indexes, không
  kiểm thử lại security emulator; các kiểm tra AI eligibility/consent hiện có vẫn qua.

### 2026-10-20 — Rút gọn UI, mở chi tiết theo nhu cầu

- Format 20 file Dart của đợt này: qua, kiểm tra lại 0 thay đổi.
- flutter test --no-pub --reporter expanded: **490/490 qua**, 65 giây, exit 0.
  Log build/compact-full-final.log. 5 test mới xác nhận nội dung phụ không dựng
  hoặc đọc Goals trước khi mở; mở/đóng vẫn giữ các chức năng; nút thông tin mở
  đúng giải thích và đóng được ở cỡ chữ 1/1,5/2; Barcode/Save còn trong form thật.
  Các test mục tiêu/weekly được cập nhật mở mục tổng kết trước khi kiểm tra;
  giữ nguyên assertions dữ liệu/UID/lưu/tổng/cạnh tranh async.
- flutter analyze --no-pub: **21 info, 0 warning/error**, exit 1, 21,7 giây.
  Không gọi analyze sạch. Log build/compact-analyze.log.
- flutter build apk --debug --no-pub: qua, assembleDebug 49,1 giây, exit 0.
  Log build/compact-build.log. APK build/app/outputs/flutter-apk/app-debug.apk.
- Các lượt phát triển đầu có lỗi finder sau đổi nhãn hoặc do nội dung mặc định
  đóng; đã cập nhật tương tác mở/đóng đúng header, scoped finder trạng thái tải.
  Lượt full trước cuối 489 qua/1 lỗi copy cảnh báo macro thiếu; sửa thành câu ngắn
  vẫn phân biệt — với 0, cập nhật assertion, toàn suite cuối qua 490. Không skip.
- Đã xem ảnh Today dark 1.0 được render lại: bỏ dòng UTC cố định và đoạn giải thích
  macro, thấy phần Bữa ăn sớm hơn; 5 ô vẫn rõ. Bộ ảnh fixture sáng/tối và chữ lớn
  tiếp tục sinh từ widget test, không phải kiểm tra trên điện thoại thật.
- Không chạy lại security emulator hay API/camera thật; không đổi nghiệp vụ,
  Firebase Rules/indexes/schema, dependency hoặc triển khai production.

## 23/10/2026 — Quét ảnh, khẩu phần mã vạch và lưu món riêng

Nền Git 63cda3f; phạm vi và cách dùng ở [scanner-update.md](scanner-update.md).

| Lệnh/kiểm tra | Kết quả thực tế | Log |
| --- | --- | --- |
| `dart format --output=none --set-exit-if-changed` trên các file Dart thay đổi | **13 file, 0 thay đổi**, exit 0 | Kết quả terminal cuối |
| `git -c core.whitespace=cr-at-eol diff --check` | **Qua**, exit 0 | Kết quả terminal cuối |
| Flutter test đầy đủ `--no-version-check test --no-pub --reporter expanded` | **501/501 qua**, 54 giây, exit 0 | build/scanner-full-test.log |
| Flutter analyze `--no-version-check analyze --no-pub` | **20 info, 0 warning/error**, 11,1 giây, exit 1 | build/scanner-analyze.log |
| Android debug `--no-version-check build apk --debug --no-pub` | **Qua**, assembleDebug 37,6 giây, exit 0; KGP warning còn | build/scanner-build.log |
| `firebase emulators:exec --config firebase.emulators.json --only firestore --project demo-healthmate-rules "npm test --prefix rules-tests"` | **51/51 qua**, 15,8 giây chạy test, exit 0 | build/scanner-rules.log |

11 test mới (4 barcode, 7 ảnh/thư viện) bổ sung trên suite 490 trước đó: quy đổi
30g từ 500kcal/100g thành 150kcal; đổi lượng, round-trip snapshot và chất xơ;
input dấu phẩy, rỗng/âm/quá giới hạn; thiếu khác 0; kJ, lỗi mạng/quota/JSON và
không tìm thấy. Scanner kiểm tra parser/null/giới hạn, catalog ưu tiên AI, form
điền đúng nhưng không tự ghi, lưu món riêng theo UID rồi lưu bữa đúng 250g/500kcal,
failed save retry cùng ID, đăng xuất khi pending và ảnh không phải món ăn.

Các lượt phát triển đầu có lỗi fixture http.Response mã hóa Latin-1 và locator
ngoài viewport; đã sửa charset UTF-8 và cuộn đúng ListView. Test còn phát hiện
SnackBar che nút xác nhận sau lưu; sản phẩm chuyển sang thông báo inline, không
che nút. Giữ nguyên assertion dinh dưỡng/lưu/UID; không bỏ hoặc skip test.

Analyze còn các info cũ withOpacity trong glass/skeleton, print trong search và
http ở dev_dependencies; không tắt lint/nâng package. Model/API theo tài liệu
Firebase hiện hành, schema nullable được xác nhận tương thích SDK firebase_ai
4.0.0 đang cài. Không đổi model/provider, package, Rules/index/schema hoặc billing.

Emulator dùng project demo cố định, không đụng dữ liệu production; các lỗi
PERMISSION_DENIED trong log thuộc assertion từ chối truy cập như dự kiến.
Chưa xác minh Rules production hỗ trợ schema/chất xơ H0–H7 đã ghi trong README.
Không camera/cloud AI thật: ADB không có thiết bị kết nối. Unit/widget dùng fake
services và dữ liệu tổng hợp; không dùng kết quả này để khẳng định chất lượng
nhận diện hoặc App Check thật. Không push/deploy, không lưu ảnh gốc.

### 2026-10-23 — Kiểm tra trước khi đồng bộ GitHub

- Theo yêu cầu người dùng, gom đầy đủ các thay đổi UI, thanh điều hướng 5 ô,
  Scanner/Chat, rút gọn nội dung, test, ảnh fixture và tài liệu bàn giao để commit/push.
- git fetch origin: main và origin/main cùng ở ba0557d trước khi tạo commit mới,
  không có commit remote cần hợp nhất.
- dart format --output=none --set-exit-if-changed trên 40 file Dart thay đổi/mới:
  0 file cần sửa, exit 0.
- flutter test --no-pub --reporter expanded: **490/490 qua**, 64 giây, exit 0;
  log build/github-push-test.log.
- flutter analyze --no-pub: **21 info, 0 warning/error**, 87,3 giây, exit 1;
  log build/github-push-analyze.log. Không gọi analyze sạch.
- Kiểm tra diff whitespace: qua. Rà soát danh sách file và mẫu private key/token
  phổ biến: không thấy mẫu khớp trong các file sẽ đưa lên; không đưa build, log,
  credential hoặc file cục bộ bị ignore vào commit. Ảnh UI dùng fixture tổng hợp.
- Không sửa mã nguồn nghiệp vụ trong lượt đồng bộ, không chạy lại build APK;
  kết quả build gần nhất của chính thay đổi này là bản debug qua ngày 20/10.
  Không deploy Firebase; kết quả push và mã commit xác nhận sau khi GitHub nhận.

## 23/10/2026 — Xác minh bản sửa độ trễ scanner trên Android

| Lệnh/kiểm tra | Kết quả thực tế | Log/nguồn |
| --- | --- | --- |
| Flutter test đầy đủ --no-version-check test --no-pub --reporter expanded | **504/504 qua**, 91 giây, exit 0 | build/scanner-latency-full-test.log |
| Flutter analyze --no-version-check analyze --no-pub | **18 info, 0 warning/error**, 7,6 giây, exit 1 | build/scanner-latency-analyze-final.log |
| Flutter debug build --no-version-check build apk --debug --no-pub | **Qua**, assembleDebug 57,1 giây, exit 0 | build/scanner-latency-build.log |
| Dart format --output=none --set-exit-if-changed trên 4 file Dart bản sửa | **0 thay đổi**, exit 0 | Terminal |
| REST probe cùng Firebase AI Logic, App Check, ảnh người dùng và schema thật | HTTP 200, JSON được parser ứng dụng chấp nhận, **16,898 giây** | build/scanner-live-result.json; test runtime |
| adb install -r -t APK debug | **Success**, cập nhật giữ dữ liệu | Terminal cài đặt |
| Người dùng chọn ảnh/phân tích trên điện thoại | App Check **44 ms**, HTTP 200 **6743 ms**, parse thành công **6767 ms** | HM_DIAG quan sát qua ADB; người dùng xác nhận đã thấy kết quả |

Ba test runtime mới kiểm tra cấu hình model/thinking/schema, phân loại lỗi và
HTTP transport/close. Lượt test đầu phát hiện chuỗi lỗi app-check có dấu gạch
nối chưa được phân loại; đã sửa mapping rồi chạy lại đầy đủ, không bỏ test.
http chuyển từ dev sang runtime dependency nên hai info cũ liên quan import
runtime được xử lý; 18 info còn lại ở glass/skeleton và print tìm kiếm có sẵn.

Model cũ gemini-3.8-flash không trả lời trong 30 giây ở hai probe nhỏ; model mới
trả HTTP 200. Lượt điện thoại cũ lỗi SDK sau 8,868 giây chưa có mã cụ thể, do đó
không khẳng định chính xác nguyên nhân lỗi gốc. Thay model riêng scanner,
minimal thinking, ảnh 1024 px và xử lý lỗi được xác minh bằng lượt thành công
thật trên điện thoại. Kết quả dinh dưỡng vẫn là ước tính, không được kiểm định
bằng phép đo thực phẩm. Không cam kết mọi lượt dưới 7 giây.

Chưa kiểm tra lại thao tác chụp camera hoặc lưu món production; không thay
Rules/schema/billing/App Check enforcement, không push/deploy. Rules emulator
không chạy lại trong lượt này vì không thay đổi; kết quả 51/51 ở mục trước.
Build/log/probe cục bộ nằm trong build bị Git ignore, không đưa credential vào
source hoặc tài liệu. Xem scanner-update.md để biết phạm vi và tài liệu model.

### 23/10/2026 — Chẩn đoán chênh lệch hai món, chưa sửa sản phẩm

- Đối chiếu sáu ảnh người dùng và chạy hai trường hợp qua FoodScannerDialog thật
  với response dựng từ ảnh; không gọi lại cloud AI và không sửa code sản phẩm.
- 2/2 probe qua: tái hiện cơm tấm bị tự ghép Cơm trắng chín cho toàn bộ 450 g
  (585 kcal, đạm 12,11 g, béo 1,26 g); bít tết quy đổi đúng 220 × 3,5 = 770 kcal.
- Lệnh: flutter --no-version-check test --no-pub
  build/scanner_comparison_probe_test.dart --plain-name "comparison probe"
  --reporter expanded. Phần thực thi 2 giây; build/scanner-comparison-probe.log.
- Probe chỉ chứng minh hành vi hiện tại và lỗi ghép món; không chứng minh độ
  chính xác dinh dưỡng. Chưa sửa nên không chạy lại full suite/analyze/build.
  Chi tiết và giới hạn đối chiếu ở scanner-update.md. Không push/deploy.

## 23/10/2026 — Kiểm thử bản sửa ghép nguồn của món nhiều thành phần

| Lệnh/kiểm tra | Kết quả thực tế | Log |
| --- | --- | --- |
| Flutter test nhóm food_scan_catalog_matcher, food_scanner, scanner_runtime --no-pub --reporter expanded | **25/25 qua**, 13 giây, exit 0 | build/scanner-whole-dish-tests.log |
| Flutter test đầy đủ --no-version-check test --no-pub --reporter expanded | **512/512 qua**, 68 giây, exit 0 | build/scanner-whole-dish-full-test.log |
| Flutter analyze --no-version-check analyze --no-pub, lần cuối | **18 info cũ, 0 warning/error**, 7,1 giây, exit 1 | build/scanner-whole-dish-analyze-final.log |
| Flutter build --no-version-check build apk --debug --no-pub | **Qua**, assembleDebug 28,4 giây, exit 0; cảnh báo KGP còn | build/scanner-whole-dish-build.log |
| Dart format --output=none --set-exit-if-changed trên 5 file Dart bản sửa | **0 thay đổi**, exit 0 | Terminal |
| git -c core.whitespace=cr-at-eol diff --check | **Qua**, exit 0 | Terminal |
| adb devices (hai lần) | Không có thiết bị kết nối; **chưa cài APK** | Terminal |

Bổ sung 8 test: 4 matcher (không khớp nguyên liệu, tên/tên tương đương đầy đủ và
Unicode tiếng Việt, nhiều kết quả bất kể thứ tự, gộp ID trùng); 4 widget (cơm tấm
không lấy số cơm trắng, giữ số AI qua form món riêng đến snapshot bữa ăn; bít tết
quy đổi đúng; trùng tên không tự chọn; sửa tên không lấy lại searchTerms cũ).
Test ưu tiên catalog có sẵn được mở rộng để kiểm tra chuyển sang AI rồi chọn
lại catalog. Giữ assertion nguồn, khẩu phần, số liệu và không ghi trước xác nhận.

Lần compile test đầu dùng nhầm tên getter suggestedQuery trong test mới; sửa
thành initialSearch đúng giao diện hiện có rồi chạy lại nhóm và toàn suite qua.
Analyze ban đầu có 4 info phát sinh từ file probe tạm của lượt chẩn đoán trước
trong build; đổi đuôi file tạm sang .dart.txt để giữ bằng chứng nhưng không đưa
vào phân tích Dart, rồi chạy lại. Không tắt lint hoặc thay analysis_options.

Kết quả dinh dưỡng trong test là fixture, không phải phép đo thực phẩm hoặc
response cloud mới. Giữ model/schema và không chạy probe AI cloud trong lượt
này. Không chạy lại rules emulator vì không thay Rules/schema. Không push/deploy;
APK build/app/outputs/flutter-apk/app-debug.apk chờ thiết bị để cài và nghiệm thu.

## 23/10/2026 — Thêm bữa ăn hợp nhất với camera xem trước

| Lệnh/kiểm tra | Kết quả thực tế | Log/ảnh |
| --- | --- | --- |
| flutter test --no-pub test/food_scanner_test.dart test/navigation_features_test.dart test/core_journal_test.dart --reporter expanded | **70/70 qua**, 13 giây, exit 0 | build/unified-meal-focused.log |
| flutter test --no-pub --dart-define=HEALTHMATE_CAPTURE_UNIFIED_MEAL=true test/unified_meal_entry_test.dart --reporter expanded | **6/6 qua**, 4 giây, exit 0 | build/unified-meal-entry-test.log; build/unified-meal-camera.png |
| flutter test --no-pub test/compact_ui_test.dart test/nutrition_test.dart test/stage_6b_test.dart --reporter expanded | **18/18 qua**, 5 giây, exit 0 | build/unified-meal-regression-test.log |
| flutter --no-version-check test --no-pub --reporter expanded | **518/518 qua**, 67 giây, exit 0 | build/unified-meal-full-final.log |
| flutter --no-version-check analyze --no-pub | **18 info cũ, 0 warning/error**, 8,7 giây, exit 1 | build/unified-meal-analyze-final.log |
| flutter --no-version-check build apk --debug --no-pub | **Qua**, assembleDebug 29,9 giây, exit 0; KGP warning còn | build/unified-meal-build-final.log |
| dart format --output=none --set-exit-if-changed trên 18 file Dart lượt UI | **0 thay đổi**, exit 0 | Terminal |
| git -c core.whitespace=cr-at-eol diff --check | **Qua**, exit 0 | Terminal |
| aapt dump permissions APK | CAMERA có; RECORD_AUDIO và WRITE_EXTERNAL_STORAGE không có; quyền đọc thư viện cũ còn | build/unified-meal-permissions.log |
| adb devices nhiều lần | Không có thiết bị, **chưa cài APK** | Terminal |

Sáu test mới: camera serialize init/dispose/đổi chủ và từ chối capture phiên cũ;
nháp nhập tay 120g giữ qua chụp ảnh và tab yêu thích đến lưu, không tự gửi AI;
barcode đóng camera trước khi mở, thêm 30g vào cùng nháp với phép tính đúng;
chọn món yêu thích vẫn giữ món nhập trước; lỗi quyền/thử lại, inactive/resumed,
đổi tab trên 360px ở text scale 1 và 2. Test scanner hiện có tiếp tục kiểm tra
consent, parsing, UID guard, AI/catalog priority, món riêng, khẩu phần và lưu.

Các lỗi trong lượt phát triển đã xử lý: lỗi chọn ảnh ban đầu không hiện ở pane
camera (đã đưa thông báo vào pane); locator ngoài viewport sau thêm thanh tab
(đổi thành cuộn đúng ListView, giữ assertion); test chuyển màn bằng Navigator.pop
cũ chuyển sang callback chọn món trong cùng nháp; host test standalone bổ sung
ProviderScope. Full suite đầu 515 qua/3 lỗi, đã sửa setup/thao tác test phù hợp
luồng mới rồi chạy lại 518/518. Không bỏ/skip test hoặc assertion dữ liệu.

Snapshot có font BeVietnamPro và MaterialIcons thật, đã mở kiểm tra bố cục.
Camera dùng fake session nên preview đen; không dùng làm bằng chứng camera thật.
Lượt export snapshot đầu bị chờ do xử lý ảnh ngoài runAsync; đã đưa toàn bộ
export vào runAsync và chạy lại qua. Bản build đầu sau thêm plugin qua 101,8
 giây; build cuối 29,9 giây. Braces lint mới đã sửa, không tắt lint.

Thêm camera 0.12.0+2 qua tooling offline; lockfile không nâng phiên bản package
có sẵn. Không thay database/Rules nên không chạy lại emulator. Không gọi AI cloud
hoặc API barcode thật trong lượt UI. APK build/app/outputs/flutter-apk/app-debug.apk
chờ thiết bị; cần kiểm tra native camera và chuyển barcode trên Android thật.
Không push/deploy, không xóa dữ liệu hoặc thay App Check/billing.
# Web quản trị — kết quả 23/10/2026

Phạm vi: catalog, Firestore account access, app config và audit; chỉ dữ liệu
demo local. Không dùng tài khoản/nhật ký thật và không gọi AI hoặc deploy.

| Kiểm tra đã chạy | Kết quả |
| --- | --- |
| `npm --prefix admin-web run check` | Syntax các module UI/Firebase/validation qua |
| `npm --prefix admin-web test` | **5/5 qua**: null/zero, số Việt/NaN, mass, URL, khẩu phần, aliases, config, ID/audit, timestamp nanosecond |
| `FIRESTORE_EMULATOR_HOST=127.0.0.1:8092 npm --prefix rules-tests test` | **59/59 qua**, 11,1 giây; project demo tách biệt web fixture |
| `flutter test test/admin_runtime_test.dart` | **5/5 qua**: parsing, rollout off, fail closed/AI flags, identity-only sync, khóa đóng dialog/bảo trì/offline |
| `flutter test` | **523/523 qua**, 78 giây; log `build/admin-flutter-tests.log` |
| `flutter analyze` | **18 info cũ, 0 warning/error**, exit 1, 35,9 giây; `build/admin-flutter-analyze.log` |
| `flutter build apk --debug` | **Qua**, assembleDebug 27,7 giây; `build/admin-android-build.log`; APK chưa cài thiết bị, cờ quản trị false mặc định |
| Dart format các file admin/runtime sửa | Qua; không format hàng loạt file ngoài phạm vi |
| `git diff --check` | Qua; Git có thông báo LF/CRLF, không lỗi whitespace |
| Browser localhost + Auth/Firestore Emulator | Admin login, đọc counts thật, tạo món có nguồn, sửa chất xơ/ẩn món, khóa rồi mở lại member, tắt rồi bật lại scanner, hiển thị audit, logout, member login bị chặn admin |

Rules mới kiểm tra role không tự cấp được; guest/user thường không quản trị;
admin không đọc `users/alice`/meal logs; catalog validation, legacy metadata
không bị ghi đè; thiếu/giả audit bị rollback target; audit append-only;
suspension chặn owner read/write/catalog, vẫn đọc được lý do, reopen phục hồi;
không khóa admin/self/UID chưa có directory; config whitelist/role revocation;
directory metadata khớp profile/token, không thêm sức khỏe/đổi createdAt.
51 test cũ giữ nguyên assertion, gồm 5 món với fiber partial và 6 nguyên liệu.

Lỗi phát hiện và xử lý khi phát triển: Rules Map.keys() là list nên phải
chuyển sang set khi đối chiếu audit; kiểm tra account control làm trường hợp
5 món sát budget 1000 expression thất bại, đã bỏ lookup quantity không dùng
trên gram rows và chạy lại cả 59 test; không nới validation hoặc bỏ test.
Unit Riverpod cần listener giữ stream hoạt động; đã sửa harness. Widget test
phát hiện trạng thái maintenance cũ che lỗi mạng; gate nay ưu tiên lỗi xác minh.
Timestamp conflict check giữ nanosecond thay vì làm tròn millisecond.

Log thêm: `build/admin-rules-all.log`, `build/admin-runtime-tests.log`.
Ảnh bằng chứng UI: `docs/ux/admin-web-overview.png` (dữ liệu emulator, không phải
production). Chưa kiểm tra layout web trên thiết bị nhỏ hoặc App Check/domain
production, chưa bật cờ quản trị trên điện thoại. Emulators/server thử nghiệm
được dừng sau QA; chạy lại theo `admin-web/README.md`.
# Auth mobile — 24/10/2026

| Kiểm tra thực tế | Kết quả |
| --- | --- |
| `flutter test --no-pub` | **534/534 qua**, 82s; `build/auth-full-tests.log` |
| `flutter test --no-pub --dart-define=HEALTHMATE_CAPTURE_AUTH=true test/auth_completion_test.dart test/auth_test.dart test/account_security_test.dart` | **35/35 qua**, 5s sau chỉnh copy/logo; `build/auth-final-focused.log` |
| `flutter analyze --no-pub` | 18 info cũ, không warning/error, exit1; `build/auth-final-analyze.log` |
| `flutter build apk --debug --no-pub` | Qua; plugin build101,4s; APK cuối10,8s, `build/auth-android-build-final.log` |
| `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm --prefix rules-tests test` | **60/60 qua**, 18s; `build/auth-rules-results.log` |
| `npm --prefix rules-tests run test:auth` | **1/1 qua**, 1,3s; `build/auth-email-e2e.log` |
| Dart format file auth/router/profile/test/helper sửa và `git diff --check` | Qua; không bỏ thay đổi cũ hoặc format toàn repo |
| Đọc Firebase config qua API đã đăng nhập sẵn | Project config200: Email/Password bật; Google IDP404; list IDP200 rỗng. Chỉ đọc, không ghi config/token vào source. |
| `adb devices` | Không có device kết nối; chưa cài APK hoặc chạy native UI |

11 test mới: min8 nhưng login mật khẩu cũ vẫn được; Google cancel/collision/
retry và chống gửi trùng; user chưa verified không bootstrap profile và không
vào route riêng tư; refresh chỉ mở sau server xác minh; resend hết cooldown0
và resume; gửi lỗi có retry; kết quả trễ của UID A không đổi trạng thái B;
reset lỗi/neutral success/cooldown; Google-only reauth trước delete; layout
verification 360/390px text scale2. Snapshot trong `docs/ux/auth/` đã mở kiểm
tra bằng mắt, dùng fake repositories và font/icon thật, không giả ảnh thiết bị.

Email E2E chạy trên Auth/Firestore Emulator loopback: tạo user giả, gửi
VERIFY_EMAIL, lấy/tiêu thụ OOB code, link dùng lại bị từ chối; token cũ vẫn bị
chặn đọc profile, token refresh được đọc. PASSWORD_RESET tạo link, kiểm tra
code, đặt mật khẩu mới; link giả/đã dùng bị từ chối; password cũ không đăng nhập
được, password mới được và giữ emailVerified. Không log code/token, không gửi
email thật, xóa đúng fixture đã tạo ở cuối test.

Rules giữ 59 case cũ, thêm verified-claim boundary cho cả false/thiếu claim và
cross UID. Verified fixture ghi rõ để giữ ý nghĩa test nghiệp vụ; không thay
assertion chặn quyền, không dùng fixture verified để thay test xác minh email.
Helper Android C6/H7 đã đổi sang tiêu thụ link email emulator thật nhưng chưa
chạy lại trên Android vì không có thiết bị. Không coi REST E2E là Google OAuth
hoặc nghiệm thu giao thư production.

Sửa trong QA: thêm required emailVerified làm rõ trạng thái identity trong
fixture; bỏ await nhầm trên lifecycle void của harness; reset dialog ban đầu
hiện lỗi hai nơi (dialog và form sau lưng), đã chỉ hiện trong dialog khi mở;
timer cập nhật cả khi cooldown về0; UID guard bỏ kết quả email của phiên cũ;
braces lint mới đã sửa, không tắt lint. Full534 qua trước vòng chỉnh copy/logo,
35 auth qua sau vòng cuối. KGP warning và 18 info cũ vẫn còn.

Blocker production: `google-services.json` chưa có OAuth client và Google chưa
bật; Rules mới chưa deploy; chưa nhận/mở thư thật hoặc chọn Google account trên
điện thoại. Xem `docs/authentication-flow.md`. Web admin tạm gác theo yêu cầu;
không cấu hình Facebook, không thay đổi provider/health data production.

### Cấu hình Google tiếp nối — 24/10/2026, trước bước lưu

- `firebase apps:android:sha:list`: ban đầu chỉ có SHA-256; thêm SHA-1 debug
  thành công rồi đọc lại đủ hai fingerprint đúng Android App ID.
- `firebase apps:sdkconfig ANDROID ... --out build/google-services-before-enable.json`:
  thành công, project/package/app ID đúng, `oauth_client` vẫn rỗng. Chưa thay
  file cấu hình trong app, chưa build/test lại vì chưa có cấu hình mới.
- Console Google chưa bấm Save: đang chờ xác nhận email hỗ trợ công khai.
  Không có ADB device. Không có bằng chứng đăng nhập Google production.

### Google đã bật sau xác nhận — 24/10/2026 (thay blocker Google phía trên)

- Console trả Success: Google enabled và bảng provider Google Enabled.
  Đọc lại Google IDP API200: enabled=true, có client ID; không log secret/token.
- SDK config CLI: đúng project/app/package; Android OAuth client_type1 khớp
  SHA-1 debug đã đăng ký, Web client_type3 có mặt. Cập nhật JSON trong Android.
- So sánh JSON trước/sau: cấu hình ngoài OAuth client giữ nguyên, không có
  client_secret. Resource Gradle `default_web_client_id` khớp Web OAuth ID.
- `flutter --no-version-check build apk --debug --no-pub`: qua11,1s,
  `build/google-enabled-android-build.log`; APK app-debug.apk, KGP warning cũ.
- Whitespace check qua. Không đổi Dart/test ở bước config nên không chạy lại
  format/analyze/unit suite; kết quả auth local ở trên vẫn là lần chạy trước.
- ADB không có thiết bị: chưa cài APK/nghiệm thu native Google OAuth hoặc thư
  inbox. Không đổi Rules/billing/health data, không tiếp tục admin.

# Chatbot theo nhật ký/mục tiêu — 25/10/2026

- Focused: `flutter test --no-pub test/chatbot_test.dart test/chatbot_personal_test.dart --dart-define=HEALTHMATE_CAPTURE_CHAT=true`
  **32/32qua**,11s, build/chatbot-personal-focused-final.log. Font/icon thật
  được nạp khi chụp; snapshot đã mở bằng view_image, có360px scale100%/200%.
- Full Flutter sau cập nhật nhãn navigation: **548/548qua**,65s,
  build/chatbot-personal-full-final.log. Vòng chốt sau sửa thêm routing mục tiêu
  khác dinh dưỡng **548/548qua**,73s, build/chatbot-personal-accepted-tests.log.
- `dart format --output=none --set-exit-if-changed`12file:0thay đổi.
- `flutter analyze --no-pub`:18info có sẵn,0warning/error,48s,exit1,
  build/chatbot-personal-accepted-analyze.log. Không gọi analyze sạch.
- `flutter build apk --debug --no-pub`:qua25,7s,
  build/chatbot-personal-build-final.log. KGP warning cũ; APK debug chưa cài.
- Whitespace check qua; không đổi package/collection/schema/Rules/index.
  Không chạy Rules emulator vì giữ nguyên payload chat/schema quyền.

14test mới kiểm tra: ngày/tuần/calendar và ngày sai/tương lai/ngoài phạm vi;
followup giữ intent/phạm vi và ngày viết rõ ưu tiên; canonical topic/medical/
write/offtopic guards; tổng tuần loại biên và mẫu số ngày có bản ghi; target
còn/vượt/partial macro; version target theo từng ngày và protein attainment;
thiếu target/nhật ký/lỗi nguồn không tạo tổng giả; nước không đọc bữa;
tóm tắt không giấu nguồn lỗi; cân nặng có ngày đo không xuất private note;
controller nhớ/xóa context; gõ kiến thức có disclosure và chỉ gửi enum;
late target response sau signout không lưu; layout360px ở2text scales.

QA phát hiện test navigation còn tìm headline cũ, đã cập nhật nhãn mới và thêm
assert composer, giữ các assert route/đăng xuất/nguồn. Không bỏ assertion nghiệp
vụ để né lỗi. Lỗi source bữa ăn giữ thông báo cụ thể. Analyze ban đầu phát hiện
unused import trong test mới; đã bỏ import rồi chạy lại, không tắt lint.

ADB không có device; chưa thử Gemini production hoặc chat UI native trong
lượt này. Test fake và snapshot không phải bằng chứng cloud/độ đúng của model.
USDA parser và Rules rollout từ audit vẫn là việc riêng chưa sửa. Không ghi dữ
liệu production, không nâng billing, không deploy hoặc tiếp tục admin.

## 25/10/2026 — Chatbot Cloudflare API, QA local (chưa live)

- Flutter full: `flutter --no-version-check test --no-pub --reporter expanded`
  **569/569**, 56s, `build/chat-api-full-tests-final.log`.
- Nhóm chat: **51/51** trước thêm 2 layout; layout/capture riêng **2/2** ở 360px,
  scale1.0/2.0, font thật; đã xem 4 ảnh trong `docs/ux/chatbot-api`. Sau bổ sung,
  full 569 bao gồm cả 2 case này. Ảnh dùng service/repositories fake.
- Format: 17 file chat/test helper được kiểm tra, 0 thay đổi; whitespace qua.
- Analyze: 18 info cũ (withOpacity/print), 0 warning/error, exit1, 6,8s;
  `build/chat-api-analyze-final.log`, không gọi analyzer sạch.
- APK debug: build 10,9s, exit0, KGP warning cũ; log
  `build/chat-api-android-build-final.log`, output app-debug.apk 236.534.148 byte.
  Không có URL API thật trong bản build; chưa cài thiết bị.
- Worker: `npm test` **18/18**, `npm run check` qua, `npm audit` 0 vulnerabilities,
  `npm run build` chỉ Wrangler dry-run bundle48,14KiB qua, không deploy;
  `build/chat-api-worker-tests.log`, `build/chat-api-worker-build.log`.

21 case Flutter mới kiểm tra schema read-only/date bounds; tối thiểu ngữ cảnh,
chặn metadata/UID/token vào body; UTF-8 chia từng byte, SSE/finish/truncation và
ẩn reasoning; HTTP lỗi không lộ body; không tải dữ liệu khi kế hoạch sai; đổi
UID trước/sau đọc chặn truyền tiếp; cancel đóng transport; catalog math/source;
consent từ chối/đồng ý, free-form history, idempotent retry, local mode không
gọi cả 2 AI, stop/signout và giao diện chữ lớn. Case Worker dùng JWT RS256 thật
với key tổng hợp để kiểm project/verified/expiry/app/tamper; xác thực trước AI,
schema/body/rate/model cố định và streaming no-store. AI output vẫn là fixture.

Trong QA đã sửa bug UI chặn nút chủ đề khi ô nhập trống; harness mới dùng UTF-8
Response.bytes, đúng asset Material Icons và completion matcher; xử lý cleanup
stream trong widget fake async để không treo. Không bỏ assertion nghiệp vụ.
Audit ban đầu phát hiện undici dev dependency; override bản vá7.30.1, audit và
tests/dry-run đã chạy lại, không hạ Wrangler hoặc dùng audit fix --force.

`wrangler whoami` chưa đăng nhập, người dùng đang tạo Free; chưa deploy/có URL,
chưa gọi Qwen live/benchmark tiếng Việt hoặc đo latency. ADB không có thiết bị.
Không chạy lại Rules emulator vì không đổi schema/Rules. Không đọc nhật ký thật,
ghi production, thay billing hoặc push/commit. Setup và giới hạn xác thực,
quota phân tán, token revocation/CPU/JSON/SSE cần live QA: `chat-api/README.md`.

## 27/10/2026 — Giai đoạn 4, catalog mở rộng và chế độ ăn

| Lệnh/kiểm tra | Kết quả thực tế |
| --- | --- |
| `dart format` 12 file Dart tạo/sửa | Định dạng xong; kiểm tra cuối `--output=none --set-exit-if-changed`: 0 thay đổi |
| `flutter analyze --no-pub` | No issues found, 7,3 giây |
| `flutter test --no-pub --reporter expanded` | **663/663 qua**, 74 giây |
| `python tool/test_usda_bundle.py` | **5/5 qua** |
| `node --test tool/food_catalog.test.cjs` | **10/10 qua** |
| `tool/build_android.ps1`: runtime config tests | **7/7 qua** với cấu hình admin thực dùng khi build |
| `flutter build apk --debug --no-pub` qua script | Thành công, Gradle 17,6 giây; còn warning KGP cũ |
| Kiểm byte asset trong ZIP APK | 2/2 trùng source, tổng đúng **7.606** mục |
| SHA256 APK và manifest | Trùng nhau |
| `git diff --check` | Qua, không lỗi whitespace |
| `adb devices` | Không có thiết bị |

Logs: `build/catalog-expansion/{analyze-final.log,full-tests.log,profile-diet-tests.log,
base-source-tests.log,android-build.log,search-final.json}`. Importer kiểm SHA của
archive USDA chính thức trước tạo asset. Các kiểm thử mới xác minh ID duy nhất,
nguồn/nutrition/gram, phân loại món mơ hồ, kế thừa metadata khi server khớp và
vô hiệu hóa khi server đổi tên/macro; bộ lọc chay 100%/150%; hồ sơ → form Nhật ký;
và hồ sơ → gợi ý thực đơn thuần chay, hủy preview không ghi kế hoạch.

Benchmark desktop JIT trên 7.606 mục: cold query 232 ms; bốn query tiếp theo
11–20 ms, trong lúc chạy full suite. Đây chỉ là phép đo cục bộ, không phải
cam kết latency Android. Chuỗi tìm kiếm có dấu/không dấu giữ xếp hạng món Việt.

APK: `build/releases/healthmate-food-catalog-debug.apk`, **236.850.186 byte**.
SHA256: `DC0B4808E0A36F5E4B72F434BA71FC222F0E25F902D98E508857D5FFA6D15330`.
Manifest: `build/releases/healthmate-food-catalog-debug.json`. APK giữ cấu hình
runtime admin, có cả hai asset; chưa cài điện thoại. Không chạy lại Rules/emulator
vì không đổi Rules/schema hoặc ghi cloud. Không coi widget fixtures, nguồn USDA
hoặc build thành công là nghiệm thu dữ liệu/cảm biến/AI production trên thiết bị.

Nguồn, so sánh đối thủ, cách tái tạo và giới hạn phân loại ở
[catalog-expansion-and-diets.md](catalog-expansion-and-diets.md).

## 27/10/2026 — Sửa luồng người dùng sau mở rộng catalog

Phát hiện thiếu sót của QA trước: test hồ sơ → form mới kiểm giá trị constructor,
chưa chứng minh nhánh `sourcesBuilder` lọc danh sách thật. Nhánh này nay đã sửa
và test được mở rộng bằng thao tác duyệt, gõ tìm và đổi dropdown trên màn chính.
Các kết quả 663/663 phía trên là lịch sử trước bản sửa này.

- `dart format --output=none --set-exit-if-changed`: **15 file, 0 thay đổi**.
- `flutter analyze --no-pub`: **No issues found**, 7,1 giây;
  `build/nutrition-polish/analyze-final.log`.
- `flutter test --no-pub --reporter expanded`: **668/668 qua**, 68 giây;
  `build/nutrition-polish/full-tests-final.log`.
- Nhóm `catalog_expansion_test.dart`: **12/12 qua**;
  `build/nutrition-polish/diet-tests-final.log`. Gồm thiếu/hỏng supplement giữ162;
  profile vegan lọc UI chính; đổi filter khi response cũ pending; kết quả ngoài
  non-vegan/unknown bị loại; lỗi tìm thêm giữ local và ẩn provider detail; favorite
  ngoài filter bị khóa thêm nhưng vẫn bỏ lưu được; plan editor lọc discovery mà
  không xóa món đã chọn. Các layout bàn phím/core journal vẫn nằm trong full suite.
- `git diff --check`: qua. `adb devices`: không có thiết bị.

Lần chạy đầu test mới có lỗi cuộn ListView lazy và chọn widget tooltip sai kiểu;
đã sửa harness cuộn về filter/đợi animation và tìm đúng IconButton. Không bỏ
assertion nghiệp vụ để qua test. Analyzer bắt một info thiếu braces trong catch
phục hồi asset; đã sửa rồi chạy lại sạch.

Không đổi Rules/schema/package/API/model/billing, không ghi production hoặc push.
Tài liệu requirements đang untracked được giữ nguyên. Tests dùng fakes để kiểm
logic/UI, không thay thế nghiệm thu điện thoại hoặc tính đầy đủ của thành phần.

APK cuối: `build/releases/healthmate-nutrition-polish-debug.apk`, **236.851.546
byte**, Gradle **16,7s**, exit0. Cấu hình runtime admin **7/7** trước build; log
`build/nutrition-polish/android-build.log`. Còn warning KGP plugin cũ. Kiểm ZIP
2 asset trùng byte source/tổng7.606 mục và SHA256 trùng manifest cạnh APK:
`E76D3B198918E4C702C4FA26C12616A0F78A0040CF0CF9F52A1CA9FBCB16F029`.
Bản này thay APK food-catalog trong báo cáo trước; chưa cài điện thoại.

## 27/10/2026 — Giai đoạn 4, sàng lọc thực phẩm cần tránh, kcal và tên Việt

Phần này cập nhật các giới hạn đã nêu trong những báo cáo lịch sử phía trên.

- Full `flutter test --no-pub`: **678/678 qua**, 74 giây;
  `build/personalized-nutrition-full-tests.log`.
- Sau chỉnh xử lý dấu phân cách và khóa đổi tuần khi đang gợi ý, chạy lại
  catalog/wellness/cá nhân hóa: **33/33 qua**;
  `build/personalized-nutrition-final-regressions.log`.
- `flutter analyze --no-pub`: **No issues found**, 7,5 giây;
  `build/personalized-nutrition-analyze-final.log`.
- Python importer: **7/7 qua**. Kiểm tra tên Việt/trạng thái chế biến, giữ tên
  gốc/thương hiệu, provenance/portion và nguồn thành phần chưa rõ.
- Đối chiếu 7.444 ID, toàn bộ nutrient vector, sourceDetails, servingLabel,
  servingGrams và portionSource với APK nutrition-polish trước: **không đổi**.
- Format 21 file Dart thuộc working tree: **0 thay đổi**. Kiểm toàn repo bằng
  `dart format .` bị path không tồn tại trong cache Chrome `.dart_tool`; kiểm
  lại `lib test integration_test tool` có 4 file cũ chưa đúng format
  (`app_spacing.dart`, `core_acceptance_regression_test.dart`,
  `food_library_test.dart`, `h2_templates_test.dart`). Dùng `--output=none`,
  không sửa các file ngoài phạm vi. Logs `personalized-nutrition-format*.log`.
- `git diff --check`: qua; ADB: không có thiết bị.

Nhóm mới kiểm sàng lọc tên/alias Việt Anh, nhiều dòng, sữa thực vật, cà chua,
eggplant không trùng nhầm; từ khóa trong thành phần công thức; unknown bị ẩn;
nhật ký chính giữ bộ lọc cần tránh khi đổi Tất cả chế độ; kế hoạch cũ cần thay
món trước lưu; lịch sử/món riêng yêu cầu xác nhận khi vẫn ghi bữa đã ăn.
Kcal: mục tiêu từng ngày, giữ bữa phụ cũ, giới hạn gram, thiếu mục tiêu,
không thể khớp mục tiêu, bữa đã chiếm đủ kcal và món chay có thực phẩm cần tránh.
UI kiểm đọc tên USDA gốc trước xác nhận gram, hủy preview không ghi kế hoạch.

Lượt đầu test preview lỗi vì 7 dòng tổng mới đẩy món xuống vùng lazy chưa build;
đã thêm key theo ngày/bữa và cuộn đúng item, giữ assertion nội dung/chay.
Không sửa nghiệp vụ hoặc bỏ assertion để che lỗi test.

Không đổi Rules/collection/SQL schema/dependency, không ghi production. Sàng lọc
thành phần tham khảo/từ khóa không chứng nhận an toàn dị ứng hay nhiễm chéo.
6.969/7.444 mục dịch được tên thực phẩm chính; còn thương hiệu/giống hiếm dùng
nhóm Việt kèm tên gốc. Chưa QA bản này trên Android thật; build còn warning KGP.

APK cuối: `build/releases/healthmate-personalized-food-debug.apk`,
**236.866.438 byte**, Gradle **14,3s**, exit0; runtime config admin **7/7**.
SHA256: `5C2FB0C58A262521BF4A4A45B1BFF86F78D2372513B3BB8484A631B1B7104726`.
Manifest JSON cùng tên cạnh APK. ZIP kiểm hai asset trùng byte source, đủ7.606
mục; đây là APK cuối sau khóa đổi tuần lúc gợi ý. Log
`build/personalized-nutrition-android-build.log`. Không cài lên thiết bị.

## 27/10/2026 — Android nutrition acceptance (Giai đoạn 10 có giới hạn)

Kết luận: **11/11 checkpoint nghiệp vụ qua trên Android Emulator; nghiệm thu
có điều kiện**, chưa xác nhận bản production hoặc điện thoại vật lý. Suite
native duy nhất chạy UI/SQLite/Firebase repositories thật, project demo riêng.

- `.\tool\test_android_core.ps1 -DeviceId emulator-5580 -CrossDriveBuild -Suite nutrition`
  (tại QA copy ổD đã hash-sync418 nguồn/config/assets): exit0, `All tests passed`,
  khoảng74s; Gradle14,8s. Android11/API30/x86_64, Skia, múi giờ Việt Nam.
- Catalog7.606; đo decode488ms; SQLite giữ metadata. Táo USDA150g=72kcal,
  sửa200g=96kcal giữID, tổng ngày96/2200 đúng. Preview/Hủy không ghi;
  xác nhận28bữa/7ngày trong±5%; sàng lọc món tránh/chưa rõ; kế hoạch chỉ vào
  nhật ký sau xác nhận; xóa nhật ký không xóa28kế hoạch; UID B bị server chặn
  đọc một document thật của A.
- `firebase emulators:exec --config firebase.emulators.json --only firestore
  --project demo-healthmate-rules "D:\Database\node.exe --test rules-tests/firestore.rules.test.cjs"`:
  **56/56 qua**,17,3s. Đã sửa Rules thiếu `personalization` trong affectedKeys
  update, thêm regression cho thêm/sửa profile answers và chặn dữ liệu sai/UIDkhác.
  Chưa deploy; các báo cáo cũ nói không đổi Rules áp dụng cho lượt trước.
- `flutter analyze --no-pub`: **No issues found**,20,3s sau helper cuối.
  `dart format --output=none --set-exit-if-changed integration_test/nutrition_acceptance_test.dart`:
 0thay đổi; `git diff --check`: qua (có thông báo LF/CRLF của Git).
  Full678test ở mục trước không được tính là chạy lại trong lượt này.

Native lần1–2 thất bại ở transaction onboarding do Rules; lần3 fixture banana
không có originalName top-level; lần4 capture thiếu pump; lần5 nhập text sau
unfocus IME không đổi query. Đã sửa harness/fixture và blocker Rules; lần6 qua
cả11checkpoint. Các lỗi deny khi sign-out/kiểm truy cập chéo được ghi đúng là
mong đợi, không coi mọi dòng PERMISSION_DENIED trong log là lỗi sản phẩm.

Kiểm ảnh ghi nhận **thực đơn vẫn lặp món/khẩu phần lớn, chưa cân bằng macro**,
header dashboard trong suốt gây chồng khi cuộn, qualifier `USDA slices` chưa dịch.
Đây là các tồn tại thật ngoài11assertion chức năng, không kết luận UX hoàn hảo.
Không kiểm điện thoại/API USDA ngoài/Gemini/production/App Check thật; không
đổi production, không build lại APK sản phẩm hoặc cài integrationAPK lên phone.

Log cuối/Rules/analyze và10ảnh tại `build/android-nutrition-20261027/`.
Checklist, file sửa, ảnh cụ thể và giới hạn:
[android-nutrition-acceptance.md](android-nutrition-acceptance.md).
# 27/10/2026 — Cập nhật nguồn Food Catalog (Giai đoạn 4)

- QA workspace đồng bộ và kiểm hash 425 file nguồn/config/asset tại
  `D:/HealthMateMaintenanceQA/c6-workspace`; không chạy lại native flow.
- Python `-m unittest discover -s tool -p 'test_usda*.py' -v`: **17/17 qua**.
- Flutter nhóm catalog/personalization: **25/25 qua**.
- `flutter test --no-pub --reporter expanded`: **688/688 qua**, khoảng81s.
- Thêm assert snapshot món Foundation rồi chạy file mới: **3/3 qua**. Lần
  compile đầu của assert mới nhầm tên field `sourceId`; sửa đúng `foodId`.
- Analyzer đầu có2 lint thiếu ngoặc khối; đã sửa. Analyzer cuối:
  **No issues found**,9,1s. Format7file sạch; diff-check phạm vi thay đổi qua.
- Build `tool/build_android.ps1`: runtime7/7, Gradle19,4s, APK debug chuẩn
  `lib/main.dart` thành công. Warning KGP plugin cũ còn.
- So SHA-256 cả3 asset từ APK với nguồn: khớp;162 +7.444 +3.563 =11.169 mục.
- Snapshot toàn bộ7.606 mục cũ không đổi; fallback từng asset hoạt động;
  ngày công bố khác ngày phát hành; kcal/kJ không lẫn; khẩu phần không lấy
  mã modifier làm số lượng. Bản ghi thiếu macro/null đã loại với số đếm trong
  `data/food_catalog/usda-current-manifest.json`.
- Chưa test trên điện thoại, production, AI hoặc API ngoài trong lượt này.
- APK: `build/releases/healthmate-current-foods-debug.apk`,222.932.966byte.
  SHA256 `FF1F1E256F1C566D42172BABA2CC34F58374460A54358F6E3A12522FD018792B`.
- Log: `build/catalog-current-20261027/`; báo cáo nguồn:
  [current-food-data-2026-10-27.md](current-food-data-2026-10-27.md).

## 30/10/2026 — Premium demo và doanh thu mô phỏng

- QA source hash-sync **433** file sang
  `D:/HealthMateMaintenanceQA/c6-workspace`; không chạy Android acceptance.
- `dart format` các file Dart sửa/tạo trong đợt: sạch. Không format diện rộng;
  whitespace cũ của `lib/main.dart` giữ nguyên.
- `flutter analyze --no-pub`: **No issues found**, **10,6s**. Lần đầu có 4
  lint thiếu braces, đã sửa rồi kiểm lại. Log `build/premium-demo-20261030/analyze.log`.
- `flutter test --no-pub --reporter expanded`: **697/697 qua**, khoảng **87s**.
  8 test Premium mới và 1 regression chat, ngoài các test sẵn có. Log
  `build/premium-demo-20261030/flutter-all.log`.
- `npm --prefix admin-web run check` và `npm --prefix admin-web test`: syntax
  qua, **25/25 test qua**; gồm UTC+7, trống = 0, không suy từ membership,
  từ chối mixed/live/giá sai/trùng ID/mất timestamp và nhãn Excel/DOM admin.
  Log `build/premium-demo-20261030/admin-tests-final.log`.
- `$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8092'; npm --prefix rules-tests test`:
  **84/84 qua**, **12,9s**; 6 test Premium kiểm nguyên tử account/receipt,
  giá/period/UID/status, immutable, owner/admin/guest/unverified, quota free,
  Premium/hết hạn và 2 thiết bị tranh lượt cuối. Log `rules-all.log` cùng thư mục.
  Các PERMISSION_DENIED trong test negative là kỳ vọng, không lỗi bị bỏ qua.
- Widget test xác nhận/Hủy/retry giữ ID/chặn mua chồng; màn 320 px scale
  1/1,5/2 không lỗi layout. Scanner kiểm ảnh trước trừ lượt và chặn API khi hết
  lượt. Chatbot lookup local không trừ; AI trừ 1; retry lưu không gọi/trừ lại.
- `tool/build_android.ps1 -PremiumDemo`: 7/7 runtime config qua; Gradle
  **55,4s**, exit0. QA-only tạm `kotlin.incremental=false`, khôi phục file khi
  kết thúc; không đổi Gradle của repo. Warning KGP dependency cũ vẫn còn.
- APK `build/releases/healthmate-premium-demo-debug.apk`: **222.955.916 byte**,
  SHA-256 **974348DCF030F070FAE1FA9760F6E3D379510C62ACA66E84236A5331FF94A449**.
  So 3 JSON catalog trong ZIP với source: khớp; Dart kernel có mặt, manifest
  bật Premium demo và admin. Log `android-build.log`.
- Đã backup và đọc Rules production ngày 30/10: ngoài Premium mới chỉ còn
  allowlist `personalization` đã kiểm thử trước. Predeploy xác minh role admin
  hiện có, public App Check key không đổi, **billingEnabled:false**; chưa có
  thay đổi role/billing/App Check. Đã deploy Hosting/Rules thành công, exit0.
- Đọc lại production: Rules khớp source đã test, ruleset
  `3867e8a2-ecd2-440a-89d0-9382bc2c3d6e`; Hosting version
  `7995564a0830c7c8`. Cả **13/13 file** HTTP200, SHA khớp bundle; nosniff
  và CSP còn. `build/premium-demo-20261030/postdeploy.json` ghi chi tiết;
  backup trước ở `build/premium-production-before-20261030/`, phiên bản
  Hosting trước `b6a2534e5fa9f9da` lưu trong predeploy.json. Không chạy rollback.
  Không tạo giao dịch doanh thu trên production, chưa login bằng browser thật.
  Compile Rules cloud có warning cũ `knownNumber` unused, không có lỗi compile.

Các kiểm thử không chứng minh thanh toán thật, quota chống client sửa, AI ngoài
hay UI trên điện thoại thật. Lượt giữ trước gọi AI nên lỗi dịch vụ vẫn tính.
Metadata demo chưa cleanup khi xóa Auth; nêu rõ tại UI và tài liệu.

## 30/10/2026 — Địa chỉ admin healthmate-admin-vn.web.app

- `firebase hosting:sites:create healthmate-admin` bị từ chối vì tên đã được
  dự án khác giữ; không tạo site đó. Validate-only ba tên thay thế thành công;
  người dùng chọn `healthmate-admin-vn` rồi create site thành công.
- `firebase hosting:clone healthmate-app-20261013:live healthmate-admin-vn:live
  --project healthmate-app-20261013 --non-interactive`: exit0, site mới phát hành
  version `74c1043d0c4d1f45`. Không xóa hoặc đổi site cũ.
- Firebase Auth authorized domains và reCAPTCHA allowedDomains đã thêm đúng
  `.web.app` / `.firebaseapp.com` của site mới, đọc lại xác nhận. Giữ domain
  cũ, web key, chế độ SCORE và hạn chế domain; không đổi Rules/admin role.
  Billing kiểm lại vẫn false. Backup/config/readback trong
  `build/admin-domain-switch-20261030/`.
- HTTPS **13/13 file HTTP200**, SHA256 khớp bundle live Premium demo, CSP và
  nosniff giữ nguyên; site cũ HTTP200. Không ghi giao dịch hay hồ sơ người dùng.
- Browser IAB truy cập link mới: lần đầu App Check chưa xác minh; sau tải lại
  trang đã mở **Đăng nhập quản trị**, email/password/Google/reset đều hiển thị.
  Link cũ cũng tới form đăng nhập. Không tắt/bypass App Check để đạt kết quả;
  không đăng nhập hoặc kiểm Google popup bằng tài khoản người dùng.
- Tool đóng gói `prepare-release.cjs` cập nhật đích Hosting mới; chạy tạo
  bundle review và kiểm đúng `hosting.site:healthmate-admin-vn` thành công.
  `npm --prefix admin-web run check`: qua. Không đổi UI/Dart/Rules/dependency,
  không chạy Flutter/native flow hoặc build lại APK trong đợt đổi domain.

## 30/10/2026 — Báo lỗi, góp ý và phản hồi từ web admin

- Đồng bộ 440 file source/config/assets sang QA workspace; không chạy lại
  luồng Android trên thiết bị theo yêu cầu người dùng.
- `dart format` các file Dart trong phạm vi thay đổi: qua.
  `flutter analyze --no-pub`: **No issues found**, **31,0s**.
  Lần đầu có 6 lint thiếu braces, đã sửa trước lần kiểm tra cuối.
- `flutter test --no-pub --reporter expanded`: **707/707 qua**, khoảng **81s**.
  Có 10 test hỗ trợ mới: validation, gửi/Hủy, giữ draft/ID khi retry, phản hồi
  admin, đổi tài khoản, ngắt listener khi tab ẩn, lỗi tải lại và layout 320px
  với cỡ chữ 1/1,5/2. Log `build/support-20261030/flutter-final.log` và
  `analyze-final.log`.
- `npm --prefix admin-web run check`: qua; admin tests **29/29 qua**, gồm
  DOM hỗ trợ, lọc/tìm kiếm, giữ draft/ID sau lỗi và chặn kết quả tải muộn sau
  logout. Log `admin-check-final.log`, `admin-tests.log` cùng thư mục.
- Firestore Rules trên Emulator: **91/91 qua**, khoảng **13,5s**; 7 test hỗ
  trợ kiểm hai UID, vai trò, nội dung bất biến, ghi nguyên tử, giới hạn tin,
  cleanup và gửi đồng thời. Log `rules-all.log`.
- Firebase Web SDK thật trên Auth/Firestore Emulator: **5/5 qua**, khoảng
  **1,7s**, gồm tạo yêu cầu, admin reply, retry cùng ID không trùng tin, chặn
  cập nhật trạng thái cũ, khách bổ sung/mở lại yêu cầu và cleanup. Lần seed
  đầu dùng sai demo project; đã khởi động lại đúng `demo-healthmate-admin`
  rồi kiểm tra thành công. Log `sdk-tests.log`.
- Khi gửi đồng thời, một request có thể bị Rules từ chối trước khi SDK retry
  conflict. Giao diện giữ draft/ID, người dùng bấm thử lại an toàn; test xác
  nhận không trùng tin sau retry. Chưa có cơ chế retry tự động cho trường hợp này.
- `tool/build_android.ps1 -PremiumDemo`: **7/7** runtime config qua; Gradle
  **21,8s**, exit0. QA-only tạm `kotlin.incremental=false` rồi khôi phục;
  warning KGP dependency hiện có vẫn còn. Log `android-build-final.log`.
- APK cuối `build/releases/healthmate-support-debug.apk`: **222.973.794 byte**,
  SHA-256 `68D2B3F50ADDC5681FE4E589CA99E77CF53763A0096DFB1DFA2473C3A1A14854`.
  Manifest bàn giao bật customer support, admin và Premium demo.
- Đã deploy Rules và Hosting tại `https://healthmate-admin-vn.web.app`.
  Đọc lại Rules khớp source đã test; ruleset
  `588a1f58-a818-47b5-88af-a38cb35cb3a0`, SHA-256 chuẩn hóa
  `0767a0a4363296b9cf268591bdb278089b21ef2835d263ce00d79860935c2824`.
  Hosting version `afa8c65b5c59dab9`; **15/15** file HTTPS khớp hash bundle,
  nosniff giữ nguyên. Index `support_tickets` UID/updatedAt **READY**, các
  index cũ giữ nguyên; billing vẫn false. Không đổi admin role/App Check.
- Backup production trước triển khai ở `build/support-production-before-20261030/`;
  bundle ở `build/admin-support-release-20261030/`; readback ở
  `build/support-production-after-20261030/`. Báo cáo máy tại
  `build/support-20261030/postdeploy.json`.

Không tạo ticket/phản hồi thật trên production, không đăng nhập thay khách
hoặc admin, không kiểm luồng Android/native hay gọi AI thật trong đợt này.
Chưa có ảnh đính kèm, email/push, chống spam riêng hoặc trang lưu trữ ngoài
50 yêu cầu gần nhất trên app. Mỗi cuộc trao đổi tối đa 100 tin sau nội dung
gốc. Xóa tài khoản trong app có cleanup; xóa Auth trực tiếp ngoài app không
tự cleanup. Chi tiết tính năng: `docs/customer-support-2026-10-30.md`.

## 30/10/2026 — Gói cải thiện 1: barcode và dữ liệu trên 100 g

- Baseline `main@0e897eca3cbdb7907012197830b9d365763e4faf`. Flutter 3.44.1,
  Dart 3.12.1, Node 24.18.0; QA hash-sync 441 source/config/assets.
- Trước sửa: barcode **5 qua / 11 thất bại**; Rules regression **1 qua /
  3 thất bại**. Lỗi gồm 500 g protein/100 g vẫn tạo snapshot và ghi Firestore,
  constructor trực tiếp không chặn và layout tràn 9 tổ hợp kích thước/cỡ chữ.
- `dart format` 7 file thay đổi: qua. `flutter analyze --no-pub`: exit 0,
  **No issues found**, **104,2s**.
- `flutter test --no-pub --reporter expanded`: exit 0, **726/726 qua**,
  khoảng **126s**; barcode có 24 test, tăng 19 test so với baseline.
- `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm --prefix rules-tests test`:
  exit 0, **95/95 qua**, **12,65s**, tăng 4 test. Emulator chỉ project demo.
- Kiểm mass/volume/serving/entry, partial/zero, invalid float, sodium/iron
  g→mg, quy đổi khẩu phần đúng một lần, snapshot cũ không bị sửa. Widget
  dùng AppTheme và font thật BeVietnamPro: 320/360/412 px, chữ 1/1,5/2;
  xác nhận g/ml và thêm từ sheet ở 320 px chữ 2 vẫn hoạt động.
- Candidate Rules chặn ghi trực tiếp ở meal schemas 2–5, custom foods,
  recipes/templates và fiber compact; test sẵn có vẫn xác nhận bữa 5 món,
  công thức 6 nguyên liệu, phân quyền UID và trạng thái unknown.
- Các vòng đầu chạm Rules expression budget; đã thay cách tổ chức biểu
  thức, giữ assertion cũ. Một lệnh focused chạy sai cwd đã được chạy lại từ
  `rules-tests`; kết quả thất bại đó không tính là kiểm thử sản phẩm. Widget
  confirm ban đầu cần `ensureVisible` + settle để test tap đúng vị trí sau
  bàn phím/scroll; không dùng `warnIfMissed:false` để bỏ qua lỗi.
- Log: `build/improvement-package1/{flutter-red,rules-red,flutter-all,analyze,
  rules-all}.log`. Hash source và Rules tại `verification.json` cùng thư mục.
- Không deploy, sửa dữ liệu production, gọi AI thật, chạy lại luồng Android
  hoặc build APK. Đây là bằng chứng local, chưa phải nghiệm thu production.

Chi tiết quyết định đơn vị OFF, tương thích và rollout:
[improvement-progress.md](improvement-progress.md).

## 31/10/2026 — Gói cải thiện 2: USDA request/deadline/lỗi

- Baseline vẫn `main@0e897eca3cbdb7907012197830b9d365763e4faf`, giữ chỉnh sửa
  Gói 1 chưa commit. Flutter 3.44.1 / Dart 3.12.1. QA sync **445** file
  source/config/assets có kiểm SHA-256 tại `D:/HealthMateMaintenanceQA/c6-workspace`.
- Test tái hiện trước sửa: **0 qua / 1 thất bại**, fixture 50 kết quả phát
  1 search + 50 detail. Sau sửa cùng bất biến: chỉ 1 search, 0 detail chưa
  chọn; chọn ID 8 thêm đúng 1 detail; chọn lại dùng cache không thêm request.
  Không suy số request fixture thành benchmark latency/quota mạng thật.
- Focused: `flutter test --no-pub test/food_search_request_test.dart
  test/usda_api_service_test.dart test/mfp_search_test.dart
  test/catalog_expansion_test.dart test/food_search_lifecycle_test.dart
  --reporter expanded`: exit 0, **49/49**, khoảng **12s**.
- Full: `flutter test --no-pub --reporter expanded`: exit 0,
  **753/753**, khoảng **116s**. Tăng **27 test** so với Gói 1: 18 service và
  9 widget. Giữ test nhãn/validator USDA, diet/avoidance, query mới nhất,
  nhật ký và các suite chức năng sẵn có.
- `flutter analyze --no-pub`: exit 0, **No issues found**, **6,6s**.
  `dart format` các Dart file thay đổi và `git diff --check`: qua.
- Fake clock chứng minh 5s cache + 3s HTTP chạm deadline chung **8s**;
  không thêm 8s cho mỗi bước. Test detail có deadline và cờ abort tại
  `http.AbortableRequest` client thực nhận. Transport giả cố tình trả muộn
  sau abort để chứng minh không publish/cache tiếp. Không gọi USDA/model thật.
- Kiểm rỗng hợp lệ khác 429/503/network/JSON/schema sai; lỗi đọc/ghi cache
  được báo mà không mất local/detail hợp lệ. Timeout ghi cache giữ detail
  với warning; cancel ghi cache chặn continuation, không tuyên bố rollback.
- Hai UI kiểm local chọn được lúc pending và sau quota lỗi; metadata không
  hiện 0 kcal, chặn favorite trước detail; bấm lặp chỉ gọi detail một lần.
  Đổi query/UID/dispose/nguồn món hủy request; dữ liệu cũ không hiện lại.
- Vòng đầu sửa lint, helper test `pumpAndSettle` khi progress cố ý pending,
  và finder tooltip Flutter mới (`RawTooltip`); giữ assertion và kiểm thao
  tác chọn món thật trong widget harness, không tắt loading để né test.
- Log `build/improvement-package2/{flutter-red,flutter-focused,flutter-all,
  analyze}.log`; `verification.json` ghi source hash, môi trường và phạm vi.
  USDA guide chính thức lưu cùng thư mục; DEMO_KEY ghi 30 request/IP/giờ,
  50 request/IP/ngày tại thời điểm đọc, không phải quota bảo đảm theo user.
- Không đổi/deploy Rules hoặc schema, không build APK, không chạy lại
  Android/native hay nghiệm thu production. Gói 2 không sửa web admin/chat
  nên không chạy lại Node/Rules suites vốn đã qua ở Gói 1. Chưa xác minh
  mạng USDA thật và hành vi abort của thiết bị thật.

## 31/10/2026 — Gói cải thiện 3: plan–meal nguyên tử và retry

Mã source/config/assets đã sync và đối chiếu SHA-256 **449 file** với bản
QA `D:/HealthMateMaintenanceQA/c6-workspace`. Flutter 3.44.1/Dart 3.12.1,
Chrome headless dùng Firebase SDK thật; Auth/Firestore Emulator chỉ loopback
9099/8080 và project demo. Không nghiệm thu Android/native theo yêu cầu.

| Lệnh / suite | Kết quả |
| --- | --- |
| SDK tái hiện trước sửa `test/plan_meal_repository_integration.dart` | Exit 1: 0 qua, 3 lỗi đúng hành vi liên kết cũ |
| SDK cùng file sau sửa (opt-in Chrome + `HEALTHMATE_EMULATOR_TESTS=true`) | Exit 0: 13/13, khoảng 4s chạy test |
| `flutter test --no-pub test/plan_meal_ui_test.dart --reporter expanded` | Exit 0: 4/4, khoảng 2s |
| Node `--test plan-meal.rules.test.cjs wellness.rules.test.cjs` | Exit 0: 17/17 |
| Node `--test` toàn bộ `*.rules.test.cjs` trong `rules-tests` | Exit 0: 100/100, khoảng 16s |
| SDK `test/firebase_repository_integration.dart` (opt-in Chrome) | Exit 0: 23/23, khoảng 29s |
| `flutter test --no-pub --reporter expanded` | Exit 0: 757/757, khoảng 93s |
| `flutter analyze --no-pub` | Exit 0: No issues found, lần cuối 7,2s |
| `dart format --output=none --set-exit-if-changed` 29 Dart đang thay đổi | Exit 0: 0 thay đổi |
| `git -c core.safecrlf=false diff --check` | Exit 0 |

SDK focused kiểm chuỗi plan → journal → xóa meal → gỡ pointer → ghi lại đúng
một meal; retry payload khác; hai Firebase app độc lập xác nhận cùng/khác
payload; phiên bản plan cũ, xóa/tạo lại plan, retry cũ sau xóa meal; legacy
dangling/unlinked; xóa meal thủ công không ảnh hưởng plan khác; cleanup tài
khoản có cặp đang liên kết. Mất ACK mô phỏng bằng bỏ giá trị trả về sau commit,
không cắt ACK transport thật. Hai app SDK không thay thế hai thiết bị thật.

Widget kiểm marker cũ vẫn bấm kiểm tra được, preflight/save chống bấm lặp,
meal đã có không mở form/ghi lại, lưu lỗi giữ nháp + thông báo xung đột để
retry, đổi UID khi đang đối soát không mở form tài khoản cũ. Rules kiểm
guard atomic, UID khác/guest/unverified, legacy và cặp đủ 5 món với fiber
và cả 8 dưỡng chất mở rộng; không giảm validator/giới hạn để tránh budget.

Vòng đầu Rules gặp trần 1.000 biểu thức; đã tối ưu cách đánh giá và giữ test
đủ 5 món. Exception trong callback web được chuyển sang kết quả enum rồi
báo lỗi nghiệp vụ sau transaction. Widget ban đầu `pumpAndSettle` timeout
vì parent busy khi dialog mở; sửa harness chờ hữu hạn, giữ loading.

SDK rộng lần đầu 22 qua/1 lỗi thiếu fixture H1; chạy lại trên database chưa
reset có 22 qua/1 lỗi C3 do catalog đã bị test trước sửa kcal. Reset riêng
`demo-healthmate-rules`, seed lại bằng helper có loopback guard: 162 creates,
retry 0 create/update/conflict; suite sau đó 23/23. Helper từng từ chối vì
thiếu biến host, không gửi request khi guard fail. Chưa thay kỳ vọng/sửa
source sản phẩm để che lỗi fixture.

Kiểm format toàn `lib test` với output=none báo 5 file cũ ngoài phạm vi:
`app_spacing.dart`, `main.dart`, `core_acceptance_regression_test.dart`,
`food_library_test.dart`, `h2_templates_test.dart`. Giữ nguyên những file này;
không tuyên bố toàn repo format sạch. Lệnh scoped 29 Dart thay đổi qua.

Logs + hash/manifest: `build/improvement-package3/verification.json` và các
log trong cùng thư mục. Source chính và giới hạn rollout được ghi tại
[improvement-progress.md](improvement-progress.md). Client cũ ghi hai bước
không tương thích Rules candidate; cần phối hợp phát hành. Chưa deploy,
build APK, push GitHub hoặc triển khai Gói 4. Chưa xác minh production.

Emulator còn cảnh báo helper Rules `knownNumber` không được sử dụng; đây là
cảnh báo, không phải lỗi test. Không loại validator để xử lý cảnh báo.
Đã dừng các emulator của lượt kiểm thử, xác nhận không còn listener 8080/9099.

## 31/10/2026 — Gói cải thiện 4: vòng đời xóa tài khoản

HEAD giữ nguyên `main@0e897eca3cbdb7907012197830b9d365763e4faf`; bảo toàn
working tree Gói 1–3. Flutter 3.44.1/Dart 3.12.1, Node 24.18.0, Java Android
Studio. Flutter/compile dùng QA `D:/HealthMateMaintenanceQA/c6-workspace`,
sync/hash 458 source/config/assets từ root, không copy dữ liệu private/secret.
SDK chạy Chrome headless thật với Auth/Firestore emulator loopback 9099/8080,
project `demo-healthmate-rules`; Rules dùng project demo riêng. Không gọi AI.

| Lệnh / suite | Kết quả cuối |
| --- | --- |
| `flutter test --no-pub --platform chrome --dart-define=HEALTHMATE_EMULATOR_TESTS=true test/account_deletion_repository_integration.dart --reporter expanded` | Exit 0, 8/8, 12s |
| SDK cùng lệnh với `test/firebase_repository_integration.dart` | Exit 0, 23/23, 29s |
| Node `--test account-deletion.rules.test.cjs` | Exit 0, 9/9 |
| Node `--test` toàn bộ `*.rules.test.cjs` | Exit 0, 109/109, 17,75s |
| Node `--test plan-meal.rules.test.cjs` hồi quy budget | Exit 0, 5/5 |
| Flutter focused controller/gate/security/private/auth/core/admin | Exit 0, 75/75 |
| Flutter `test/account_deletion_export_test.dart` | Exit 0, 4/4 |
| Flutter `test/wellness_expansion_test.dart` | Exit 0, 11/11 |
| `flutter test --no-pub --reporter expanded` cuối | Exit 0, 772/772, 89s |
| `flutter analyze --no-pub` cuối | Exit 0, No issues found, 8,6s |
| `dart format --output=none --set-exit-if-changed` 54 Dart đang thay đổi | Exit 0, 0 thay đổi |
| `git -c core.safecrlf=false diff --check` | Exit 0 |
| `tool/test_account_deletion_native.ps1` | Exit 0, 5/5 host contract |
| `:app:compileDebugKotlin --offline '-Pkotlin.incremental=false' '-Pkotlin.incremental.useClasspathSnapshot=false'` | Exit 0, BUILD SUCCESSFUL 41s, 142 tasks |

SDK kiểm hơn 100 body records qua batch100, toàn bộ inventory health/library/
wellness, messages chat/support, Premium demo transactions/membership/usage
(kể cả subcollection không parent), directory/controls; giữ tombstone/audit.
Hai app SDK cùng UID thử write hợp lệ trước marker và bị chặn sau marker,
cả trước cleanup và khi dữ liệu/parent đã mất. Ca offline chứng minh write
đang pending trước yêu cầu; sau reconnect write bị từ chối và bootstrap
không tạo lại hồ sơ. Kiểm suspended owner, UID khác, checkpoint dở và resume
bằng repository mới; finalize sớm bị từ chối, Auth chưa xóa retry an toàn;
ca cuối xóa Auth emulator thật và marker vẫn `auth_pending`.

Unit/widget kiểm thứ tự reauth → marker ACK → dừng native/drafts → cleanup →
xác minh → Auth, lỗi từng bước, không chạy Auth nếu dọn lỗi, UID đổi giữa
chừng. Gate nhận marker độc lập admin flag, fail closed khi chưa xác nhận,
cho suspended delete/resume; cleanup local quan sát thử cả hai bộ dọn dù
một bộ lỗi. Export đang đợi OS picker bị vô hiệu khi marker cùng UID xuất
hiện; lỗi/loading trạng thái xóa cũng không bắt đầu xuất. Host test dùng
source `AccountDeletionBlock.kt` thật với Context/AtomicFile adapters:
idempotence, restart, interrupted marker, UID isolation và ghi đang chạy.
Không thay thế Android Keystore/sensor/alarm/acceptance E2E.

Các lỗi trong vòng kiểm chứng và cách xử lý:

- Full Flutter ban đầu 771 qua/1 lỗi wellness do thiếu fake repository cho
  dependency mới, vô tình gọi Firebase chưa khởi tạo. Bổ sung fake, giữ guard
  và assertion; focused 11/11, full cuối 772/772. Riverpod standalone harness
  khác cần active listener để stream không bị pause, không sửa sản phẩm né test.
- SDK helper email action cần project trùng emulator đã cấu hình. Ca offline
  riêng qua nhưng tái dùng app qua nhiều UID từng chờ trong suite; đổi thành
  hai app mới mỗi test, teardown reconnect/signout/terminate/delete. Giữ đủ
  assertions pending/offline và timeout, không quy kết lỗi Firebase SDK.
- Rules marker guard ban đầu vượt budget với payload 5 món; tối ưu cấu trúc
  đánh giá, giữ đủ validator/dưỡng chất và test 5 món. Toàn Rules cuối qua.
- Compile incremental vướng đường dẫn C PubCache/D QA; quoting Gradle args
  được sửa và compile nonincremental qua. Không tuyên bố APK build thành công.
- Lệnh Dart format sandbox đầu chờ không kết quả và bị dừng; chạy lại bằng
  SDK cùng chế độ chỉ kiểm với quyền runtime phù hợp qua 54 file. Không nói
  toàn repo đã format sạch; các lệch ngoài phạm vi từng báo ở Gói 3 giữ nguyên.

Trước SDK rộng đã reset **chỉ** database `demo-healthmate-rules` tại endpoint
emulator localhost, seed 162 món H1; retry 0 create/update/conflict. Không
reset Auth/Firestore production. Log không chứa credential tài khoản thật.

Bằng chứng cuối tại `build/improvement-package4/verification.json` và các
log cùng thư mục. Candidate mới chưa deploy, không build APK/push GitHub,
không chạy lại luồng Android hoặc xóa account thật. Thiếu server deletion
job đặc quyền, tìm orphan/unknown collections và retention/purge/role revoke
nên chưa nghiệm thu job server/production. Client phải mở/có mạng để tiếp
tục; `auth_pending` không chứng nhận completed. Chi tiết giữ UID/audit/cache/
export/provider data trong [account-deletion-adr.md](account-deletion-adr.md).

Kiểm tra cuối không còn listener emulator 8080/9099. Manifest xác minh
458 hash source khớp QA và lưu 16 log/hash. Không có tiến trình kiểm thử
hoặc emulator của gói này cần người dùng tiếp tục chờ.

## 31/10/2026 — Gói cải thiện 5–7

Branch/HEAD vẫn `main@0e897eca3cbdb7907012197830b9d365763e4faf`;
working tree bao gồm Gói 1–7 chưa commit. Source Flutter chạy ở QA workspace
`D:/HealthMateMaintenanceQA/c6-workspace`, sync đối chiếu SHA256 **466**
source/config/assets. Flutter3.44.1/Dart3.12.1, Node24.18.0, Java JBR Android
Studio. Không model call, credential/IAM, billing, production deploy/migration,
APK hoặc native acceptance. Mọi dữ liệu ghi là fixture demo ở loopback.

| Lệnh / lớp | Kết quả thật | Log |
| --- | --- | --- |
| `node --test chat-api/test/*.test.mjs` | 48/48, exit0 | `build/package5-chat-tests.log` |
| `npm --prefix chat-api run check` | exit0 | `build/package5-chat-check.log` |
| Chat adapter REST opt-in emulator | 3/3, exit0, 16,03s | `build/package5-rest-sdk.log` |
| Wrangler deploy `--dry-run` | exit0; không deploy | `build/package5-worker-dryrun.log` |
| `node --test admin-web/test/*.test.mjs` | 42/42, exit0 | `build/package7-admin-tests.log` |
| `npm --prefix admin-web run check` | exit0 | `build/package7-admin-check.log` |
| `node --test admin-web/test/sdk.integration.mjs` cuối | 7/7, exit0, 8,45s | `build/package7-sdk-final.log` |
| `node --test tool/meal_query_migration.test.cjs tool/meal_query_migration.integration.cjs` | 6/6, exit0, 10,30s | `build/package6-migration-final.log` |
| `node --test rules-tests/*.rules.test.cjs` trên emulator | 119/119, exit0, 13,65s | `build/package567-rules-final.log` |
| Flutter full trước sửa race | 780/780, exit0, 95s | `D:/HealthMateMaintenanceQA/package567-flutter-all.log` |
| `flutter test --no-pub --concurrency=2 --reporter expanded` sau sửa race | 780/780, exit0, 210s | `D:/HealthMateMaintenanceQA/package567-flutter-handoff.log` |
| Flutter SDK opt-in cuối: deletion8 + broad23 + plan13 + query4 | 48/48, exit0, 61s | `D:/HealthMateMaintenanceQA/package567-sdk-handoff.log` |
| `flutter analyze --no-pub` sau sửa race | No issues found, exit0, 8,1s | `D:/HealthMateMaintenanceQA/package567-analyze-handoff.log` |
| `dart format --output=none --set-exit-if-changed` Dart thay đổi | 79 files, 0 thay đổi, exit0 | `build/package567-format.log` |
| `git -c core.safecrlf=false diff --check` | exit0 | `build/package567-diff-check.log` |

Rules cuối SHA256
`D43FC4EFDFA4A1D559433103BC288D79E3BD2339AD64E209963B820F0132ABFC`.
Admin SDK dùng bản copy Rules đúng hash này, emulators8092/9098. SDK Flutter
dùng demo-healthmate-rules8080/9099; không chạy reset/seed cùng lúc một suite
khác dùng chung project. Rules Node full hoàn tất trước SDK Flutter cuối.

### Các lớp bằng chứng

- AI mock tests kiểm signature/AppCheck/revocation/disabled/deleted,
  fail-closed config/policy/deletion, contention quota/idempotency, mất ACK,
  timeout/429, stream thiếu DONE và lỗi kết thúc. REST suite dùng adapter
  beginTransaction/batchGet/commit/rollback thực với Firestore emulator;
  OAuth/IAM/provider vẫn mock, không chứng nhận production identity.
- Query SDK đo compatibility5 downloads cho3 meals, partitioned3, complete3;
  marker đọc riêng. Kiểm timezone, 130 lịch sử cân trùng timestamp, page26
  lookahead, latest/baseline1, báo cáo60 không bị cắt bởi page và UID isolation.
  Migration thực205 records chứng minh resume/idempotency/preserve nutrition.
- Admin SDK thật chạy source sản phẩm với Firebase13.0.0 local package thay
  CDN import, fixture10.037 tài khoản: trang25/25/tail7, enrich25 role+25 control
  cho trang đầy. 31 receipts cùng millisecond khác nanos:25+6, export31.
  Giữ archive/restore/audit/stale-edit/account-control/config/support reply.
- Rules kiểm cả old13-field và current14-field meals, marker partitioned/
  complete/migrating; five distinct rows, đủ8 dưỡng chất, fiberIncomplete
  true trên cả5 và khẩu phần xác nhận khác plan. Kiểu/rỗng/field lạ, fiber
  âm/sai metadata, vector sai bị chặn. Không bớt món hoặc bỏ validator để
  vượt ngân sách 1.000 expressions; nhánh5 gọi trực tiếp đủ5 validator.
- Deletion SDK mở rộng inventory migration và hai cây gateway: nested dữ
  liệu vẫn được dọn khi parent thiếu; giữ tombstone/audit. Legacy counter
  direct write được chứng minh hợp lệ trước marker và bị Rules từ chối sau
  marker; client `consume` luôn bị từ chối theo hợp đồng quota server mới.

### Lỗi trung gian đã xử lý và giới hạn

- SDK deletion precheck cũ gọi `consume` như một thao tác hợp lệ. Đã sửa
  harness để assert client không cấp quota, đồng thời direct-write legacy
  fixture trước/sau marker để vẫn kiểm Rules thật, không bỏ assertion.
- Rules thêm migration guard từng vượt1.000 expressions ở bữa5 món. Đã
  dùng count trực tiếp, cache data/route, boolean validators và nhánh5;
  giữ phạm vi số/kiểu/nguồn/ngày và mọi item. Chứng minh bằng119 Rules tests.
- SDK contender có thể nhận permission-denied trước conflict retry. Thêm
  bounded retry1 sau khi server xác nhận cặp liên kết đã tồn tại, transaction
  mới kiểm lại payload/UID. Hai trường hợp cùng/khác portions từng thất bại,
  sau sửa suite plan riêng **13/13 qua**, exit0, khoảng5s:
  `D:/HealthMateMaintenanceQA/package567-plan-sdk-final.log`.
- Một lượt compiler Chrome không tạo được DartWorker/thread trên Windows;
  dừng tác vụ coverage diagnostic riêng rồi chạy lại thành công. Không sửa
  assertion hoặc tăng timeout để che lỗi sản phẩm. Một fixture response dùng
  Latin1 đã đổi UTF8, probe integration cũ cập nhật để không gọi direct model.
- REST migration emulator không hỗ trợ list pageToken kèm orderBy; tool dùng
  thứ tự tên mặc định của REST, planner tự sort. Ca205 records sau sửa qua.

Các log cũ có failure được giữ làm bằng chứng chẩn đoán, không trình bày là
kết quả cuối. Widget/default tests không thay Android acceptance. Không đo
hóa đơn Firestore, concurrent-user capacity, IAM thật hoặc model chất lượng.
Gói5 chưa production-ready; gateway mặc định tắt và scanner ảnh chưa có
gateway. Gói6 cần migration/Rules/index rollout; admin chưa publish. Tình
trạng server deletion job/retention từ Gói4 vẫn còn, không tự giải quyết ở gói này.

Manifest và bản sao log: `build/improvement-packages5-7/verification.json`.
Gói tiếp theo đề xuất8; chưa thực hiện. Sau khi kiểm tra, lưu báo cáo và dừng
emulator của task, laptop được hẹn tắt theo yêu cầu, không dùng forced close.

Đã dừng hai emulator của task; kiểm tra không còn listener trên
8080/9099/8092/9098. Manifest lưu466 hash khớp QA,211 hash admin/chat/docs
và21 log; các hash nguồn tài liệu được cập nhật sau khi chốt báo cáo.
Lệnh tắt dùng helper chờ60 giây rồi `shutdown.exe /s /t 0`, không `/f`;
ứng dụng chưa lưu có thể chặn tắt máy. Trạng thái thực thi được lưu riêng
ở `build/improvement-packages5-7/shutdown-status.json`.

## 31/10/2026 — Gói cải thiện 8, 9, 10: kiểm chứng candidate local

Phạm vi theo yêu cầu trực tiếp của chủ dự án: ba gói cuối trong improvement
plan, giữ toàn bộ Gói 1–7 chưa commit. Branch/HEAD bắt đầu và kết thúc vẫn
`main@0e897eca3cbdb7907012197830b9d365763e4faf`. Không build APK, nghiệm thu
native Android, commit/push/deploy, migration production, gọi AI hoặc xóa
tài khoản thật. Chủ dự án giữ package/version demo và tự test Android.

### Kết quả cuối đã chạy

| Lệnh/nhóm kiểm tra | Kết quả thực tế | Exit |
| --- | --- | --- |
| `flutter test --no-pub --concurrency=2 --reporter expanded` | **803/803 qua**, 2 phút 49 giây test | 0 |
| `flutter analyze --no-pub` | **No issues found**, 5,8 giây | 0 |
| Changed Dart format checker | **92 files, 0 changed** | 0 |
| `node --test *.rules.test.cjs` từ rules-tests, emulator 8080 | **127/127 qua**, 20,97 giây | 0 |
| Flutter web SDK support | **4/4 qua** | 0 |
| Flutter web SDK deletion (có support_usage inventory) | **8/8 qua** | 0 |
| Flutter web SDK repository rộng | **23/23 qua** | 0 |
| Flutter web SDK plan–meal | **13/13 qua** | 0 |
| Flutter web SDK query/history | **4/4 qua** | 0 |
| Admin Node/DOM tests + syntax checks | **42/42 qua**, check qua | 0 |
| Admin real SDK với Rules mới, emulator 8092/9098 | **7/7 qua**, 8,4 giây | 0 |
| Chat Node + syntax checks | **48/48 qua**, check qua | 0 |
| Gateway REST transaction emulator | **3/3 qua**, OAuth/IAM adapter mock | 0 |
| Migration REST emulator | **1/1 qua**, 205 records, resume/idempotent/snapshot | 0 |
| `node --test tool/*.test.cjs` | **28/28 qua**, gồm preflight/load/CI guard/migration/catalog | 0 |
| Load probe local | **100/100 queries**, concurrency 10, 1.000 docs, 0 lỗi | 0 |
| Workflow YAML + PowerShell release helper syntax | Parse qua; helper không execute | 0 |
| Source secret audit + diff check | Không phát hiện secret theo patterns; whitespace qua | 0 |
| `node tool/release_preflight.cjs` | Chặn đúng `release-signing-missing`; APK/hash null, accepted=false | **1, expected blocker** |

Flutter SDK tổng **52/52** trên Auth9099/Firestore8080, chạy từng process
với reset/seed demo riêng trước suite. Flag duy nhất cho SDK là
`HEALTHMATE_EMULATOR_TESTS=true`; Chrome thực qua adapter. Một số suite plan
cũ tự clear database nên không chạy song song hay gộp file mà giả định thứ tự.
Rules hoàn tất trước SDK. Admin dùng cặp emulator và project demo riêng.
QA sync cuối đối chiếu **481** source/config/assets với source thực.

Môi trường thực: Windows; Flutter 3.44.1/Dart 3.12.1; Node 24.18.0;
Firebase CLI 15.22.4; JBR OpenJDK 21.0.8; Google Chrome. Tool versions và
log cuối ở `build/improvement-packages8-10/`; manifest liệt kê hashes/file,
lệnh, exit và giới hạn tại `verification.json`. GitHub Actions hosted chưa
chạy; YAML parse và local suites không được mô tả là hosted CI pass.

### Những hành vi đã có bằng chứng

- Rules chặn ticket không counter, counter riêng/reset, multi-ticket một
  debit, quá 3/ngày, cooldown, hai request tranh lượt cuối và UID khác.
  Repository thật dùng cùng ID idempotent, payload khác bị từ chối; hai SDK
  chỉ một request thắng lượt cuối. Lịch sử 70 ticket qua 25/25/20, giữ nanos
  và đi tiếp khi anchor mất. Reply/reopen vẫn chạy khi hết quota tạo mới.
- Admin SDK giữ reply idempotent/status/audit/customer follow-up với hợp
  đồng tạo ticket mới. Fixture 10.037 directory records vẫn chỉ tải trang
  25 và enrich 25 role/control; đây là document/request fixture, không phải
  số người dùng đồng thời hay hóa đơn production.
- Controller form/search test độc lập giữ nháp revision/ACK, single-flight,
  retry, UID/dispose, query/detail cancellation, progress cũ và source guard.
  Widget tests giữ lưu bản sao/5 món, xác nhận thực phẩm cần tránh và paging
  catalog chữ lớn; Auth error không gọi persistence và giữ nháp.
- Load probe admin REST: p50 **17.604 ms**, p95 **58.452 ms**, max **66.382 ms**,
  total **296.778 ms** gồm setup/cleanup; dọn đúng 100 fixture paths. Không
  đo billing reads/quota/Auth/Rules/App Check/AI/native hoặc capacity thật.

### Lỗi trung gian và cách xử lý

- Lượt full Flutter đầu: 797 qua/4 lỗi. Capture owner khi Auth còn loading
  khiến lưu không gọi callback; bọc catalog rows trong một Column làm mất
  lazy reveal/paging. Sửa first-resolved ownership và direct ListView children,
  giữ assertions. Lượt tiếp 801 qua/1 lỗi vì personalization host thiếu Auth
  fixture khi form mới phụ thuộc Auth; inject fake đúng scope, giữ xác nhận
  món chưa rõ và thêm test Auth error fail-closed. Lượt cuối **803/803**.
- SDK support đầu 2/4 lỗi: DateTime local từ Timestamp khác biểu diễn UTC
  khi so sánh `==`, làm count cùng ngày thành 0; dùng `isAtSameMomentAs` và
  unit test local timestamp. Exception Dart trong callback web transaction
  bị NativeError bọc; callback trả business failure, throw SupportFailure
  bên ngoài, giữ typed error/race/retry assertions. Lượt cuối **4/4**.
- Admin SDK đầu 6/7: fixture tạo ticket đơn lẻ bị Rules mới chặn đúng.
  Sửa fixture client ghi ticket+counter atomic; chỉ reset metadata synthetic
  của chính fixture ở emulator admin. Không nới Rules, giữ toàn bộ assertions.
  Lượt cuối **7/7**.
- Analyzer đầu có 4 style infos thiếu braces; đã sửa, cuối sạch. Rules thử
  trước khi emulator ready bị ECONNREFUSED; sau ready suite **127/127**.
  Admin emulator config tham chiếu Rules ngoài project directory bị CLI từ
  chối; dùng bản copy trong thư mục config, kiểm SHA khớp source rồi chạy.

Các log lỗi Flutter/admin/startup còn lưu riêng để đối chiếu, không trình
bày như kết quả cuối. Support SDK log canonical là lượt cuối sau sửa; lỗi
trung gian được ghi ở phần này, không giả vờ mọi lượt đều xanh.

### Giới hạn và bước cần chủ dự án thực hiện

Gói 8/9 đã xác minh candidate local, chưa deploy/push. Rules support mới cần
client mới và rollout phối hợp; ticket cũ không có counter không bị sửa nội
dung. Gói 10 mới hoàn tất phần chuẩn bị/kiểm tra local: **chưa nghiệm thu bản
release ký thật**, chưa có APK/certificate/hash hay bằng chứng điện thoại.
Preflight fail đúng vì không có keystore; không tạo/ghi đè khóa để vượt gate.

Chủ dự án cần cung cấp khóa ký theo cơ chế private, cấu hình certificate/
App Check rồi tự nghiệm thu ma trận native; trước production còn phải giải
quyết R1 server deletion/retention và Gói 5 IAM/revoke/direct-route/scan
gateway, duyệt migration/backup/rollout và chi phí. Không tự dùng quyền
production hoặc bật billing. Không gọi client cleanup là job server bền vững.

[Truy vết hashes/config](candidate-verification.md) ·
[Trạng thái từng gói](improvement-progress.md) ·
[Ma trận release và rollback](release-readiness.md).

Đã lưu kết quả cuối và dừng đúng hai emulator do task tạo. Kiểm tra không còn
listener trên 8080/9099/8092/9098. Không hẹn tắt laptop ở lượt này vì điều kiện
“hoàn thành xong” còn chưa đạt ở nghiệm thu signed release/native Gói 10;
trạng thái được lưu tại `build/improvement-packages8-10/shutdown-status.json`.
Không ép đóng ứng dụng hoặc tạo khóa ký để vượt blocker.


## Đồng bộ thời gian thực — 06/11/2026

Bản kiểm thử hoàn tất, chưa triển khai production theo lựa chọn bật Blaze sau.

| Lệnh/nhóm | Kết quả cuối |
| --- | --- |
| dart format các file đợt này | Hoàn tất |
| flutter analyze --no-pub | Không issue |
| flutter test --no-pub --reporter json | 951/951, success=true |
| flutter build apk --debug --no-pub --dart-define-from-file=config/release-candidate.json | Thành công, chưa cài thiết bị |
| npm test / npm run check --prefix admin-web | 66/66 / qua |
| SDK cũ / SDK realtime với emulator | 9/9 / 6/6 |
| Functions unit / Auth+Firestore+Functions emulator | 2/2 / 3/3 |
| npm test --prefix rules-tests | 129/129 |
| Rules bundle dựa trên baseline production | 3/3 |
| Kiểm tra SDK bổ sung ticket đang xóa | Qua |
| git diff --check | Qua |

Test bao gồm tự cập nhật khi tạo/sửa/ẩn/khôi phục/xóa món, control/role thay đổi
mà directory không đổi, giao dịch xuất hiện/xóa trong kỳ, cấu hình, hỗ trợ,
đăng ký chưa xác minh, xóa Auth, retry cũ, bootstrap lặp, báo cáo được invalidation
đúng nguồn, tổng kết tuần, chi tiết món riêng/công thức đang mở sau sửa/xóa từ
thiết bị khác, chặn dữ liệu đến trễ và giữ bản nháp. Hai UID không đọc/ghi chéo
revision; admin không tự ghi bộ đếm và admin bị khóa không dùng token cũ đọc tổng.

Có lần discovery Functions vượt mặc định 10s; đã dùng lazy Firestore và kiểm lại
với FUNCTIONS_DISCOVERY_TIMEOUT=60. Không đổi test để che lỗi; giữ log các lần
lỗi. Emulator Node 24, deploy runtime Node 22; chưa kiểm thử production/Android
hai thiết bị. Cảnh báo KGP tương lai và 6 advisory moderate của dependency gián
tiếp Functions được ghi rõ trong [báo cáo realtime](realtime-sync-2026-11-06.md).

Bằng chứng chính: `build/realtime-flutter-summary.json`,
`build/realtime-analyze-final.log`, `build/realtime-apk-build.log`,
`build/admin-realtime-final4.log`, `build/realtime-legacy-and-rules.log`,
`build/realtime-integration-final3.log`, `build/realtime-release-final3.log`.

## 06/11/2026 — Đã triển khai realtime trên Spark

- Tiếp tục yêu cầu đồng bộ hiện có: đã publish Hosting và Rules tối thiểu lên
  healthmate-admin-vn.web.app, đọc lại file/Rules khớp. Không bật billing/Functions.
- Web nghe dữ liệu trực tiếp; app thêm listeners đúng khoảng báo cáo/tuần,
  mục tiêu, giấc ngủ và chi tiết thư viện, không chờ revision server.
- File chính: live-data.mjs, firebase.mjs, prepare-realtime-release.cjs;
  private_data_changes.dart, user_data_revision.dart và các providers liên quan.
- Đạt: Flutter952/952, analyze sạch, admin66/66, Spark SDK1/1, Flutter SDK3/3,
  Rules bundle3/3, APK debug build qua. Snapshot Auth thật3 có nhãn thủ công.
- Cần cài APK mới; chưa có thiết bị Android kết nối, chưa nghiệm thu hai thiết
  bị production. Tổng Auth tự động còn chờ Functions/Blaze; Premium vẫn demo.
- Tiếp theo đề xuất: nghiệm thu app/web thật, không tự thêm nghiệp vụ khác.
- Chi tiết và bằng chứng: [realtime-spark-2026-11-06.md](realtime-spark-2026-11-06.md).
