# HealthMate Admin

Web quản trị nằm ngay trong repository HealthMate, mở/sửa được bằng VS Code.
HTML, CSS và JavaScript thuần; Firebase Web SDK 13.0.0 tải từ CDN chính thức.
Không cần React, bundler, Admin SDK, service-account hoặc backend riêng.

## Hoàn thiện admin — 07/11/2026

Tra cứu máy chủ theo UID/email đầy đủ/mã món/đầu tên; audit mới nhất, lọc và
xuất theo ngày Việt Nam; cảnh báo bỏ bản nháp, retry lỗi và URL theo trang.
Đầu tên món phân biệt chữ hoa/dấu; tìm nhanh/bộ lọc phía dưới chỉ ở trang
đang xem. Chỉ đọc 33 bài tập lấy từ mã nguồn app, tìm/lọc/xuất được.
Để cập nhật danh mục này, chạy `dart run tool/export_admin_exercises.dart`
và `dart run tool/export_admin_exercises.dart --check` từ root trước release.
Web 83/83, SDK 20/20, browser desktop/mobile qua. Đã publish Hosting, đọc lại
30 tệp khớp release; tải lại trang để dùng. Rules và gói Spark giữ nguyên.
[Chi tiết rollout và giới hạn](../docs/admin-completion-2026-11-07.md).

Font hiện tại: **Inter v4.1**, WOFF2 đóng gói trong `dist/fonts/inter/`,
đủ 400/500/600/700 và tiếng Việt. Không phụ thuộc dịch vụ font bên ngoài;
giấy phép SIL OFL 1.1 nằm cùng thư mục font. App Flutter dùng cùng Inter.

## Giao diện hiện tại — thiết kế 06/11, publish 07/11/2026

Theo ảnh mới: nền đen, sidebar đen, panel xám đậm, viền mảnh, điểm nhấn
xanh dương. Bốn card số liệu ở đầu, biểu đồ trái và thông tin vận hành
phải; tài khoản/đăng xuất ở footer. Bảng/form/dialog/đăng nhập đồng bộ tối.
Menu và hành động dữ liệu hiện có được giữ, không thêm số/tăng trưởng giả.

Đã kiểm Node/DOM 61/61 và browser desktop/mobile. Ảnh dùng Firebase đọc
thật ngày 06/11, Premium vẫn demo. **Đã publish cùng đợt sửa vận hành
07/11**; riêng lượt đổi theme trước đó không thay Rules/ghi production.
[Chi tiết và kiểm thử](../docs/admin-dark-ui-2026-11-06.md).

## Lịch sử giao diện theo ảnh trước — candidate 03/11/2026

Sidebar trắng, nền xám nhạt, panel trắng và card gradient hồng/tím/xanh/cam.
Menu gồm **Tổng quan, Doanh thu, Khách hàng, Thực phẩm, Bài tập luyện,
AI Chatbot**, giữ Hỗ trợ khách hàng, Nhật ký quản trị và Cài đặt. Có thu
gọn sidebar desktop và drawer mobile. Trang bài tập ghi rõ chờ triển khai;
trang AI đọc cấu hình hiện có và dẫn tới form chỉnh sửa có audit.

Biểu đồ lấy giao dịch đã lưu; dữ liệu trống hiện đường 0, không tạo số
hoặc xu hướng minh họa. Premium vẫn demo. Bản xem trước dùng dữ liệu thật
đọc lúc 02:01:25 ngày 03/11/2026 UTC+7, không phải bản web đã publish.
**UI candidate chưa lên online**, không đổi backend/Rules trong lượt này.
[Thay đổi, kiểm thử và ảnh](../docs/admin-ui-reference-2026-11-03.md).

## Dashboard mới — candidate 02/11/2026

Dashboard ưu tiên tổng tài khoản đăng ký, doanh thu Premium **demo**, số
giao dịch và khách mua; chọn kỳ UTC+7, biểu đồ từng ngày, 5 giao dịch mới
nhất và lối tới báo cáo/Excel. Count/config/revenue lỗi độc lập; không hiện
doanh thu 0 khi tải lỗi hoặc dùng tổng một trang thay tổng kỳ.

Tổng đăng ký đọc `admin_statistics/accounts` do chủ dự án đồng bộ từ
Firebase Authentication, hiển thị thời điểm và nhãn cập nhật thủ công.
Không dùng số `user_directory` làm tổng Auth. Chưa có summary/Rules thì
hiện “Chưa có số liệu”, danh sách đã đồng bộ vẫn được đếm riêng.

`node admin-web/tool/sync-account-statistics.cjs` mặc định chỉ đọc, không
ghi. Chỉ khi được yêu cầu cập nhật production mới chạy thêm `--apply`.
Không cần thêm backend/service-account/billing. **Candidate chưa publish,
chưa ghi summary**; không deploy toàn bộ root candidate Rules để bật nó.
Xem [cách dùng, kiểm thử và rollout](../docs/admin-dashboard-2026-11-02.md).

## Chức năng hiện tại — 27/10/2026

Cập nhật 30/10: thêm **Hỗ trợ khách hàng**. Khách tạo báo lỗi/góp ý trong app;
admin lọc loại/trạng thái/từ khóa, mở cuộc trao đổi, Gửi phản hồi và Lưu trạng
thái xử lý. Phản hồi hiển thị trong app, không gửi email hoặc push. Khách bổ
sung tin nhắn sẽ mở lại yêu cầu. Không thể sửa nội dung gốc hoặc tin đã gửi.
Tối đa 100 tin/cuộc, 2.000 ký tự/tin; candidate Gói 7 tải từng trang 25 ticket.
Xóa tài khoản trong app xóa ticket/messages; admin không có quyền xóa thay.
Chi tiết: [Hỗ trợ khách hàng](../docs/customer-support-2026-10-30.md).

- Đăng nhập email/mật khẩu hoặc Google bằng Firebase Auth; quyền đọc/ghi kiểm tra bằng Firestore Rules.
- Thêm/sửa/ẩn/hiện món dùng chung, dinh dưỡng trên 100 g, chất xơ và nguồn.
- Danh sách tài khoản đã đồng bộ: tên/email/UID; khóa/mở quyền dữ liệu HealthMate.
- Bật/tắt quét ảnh AI, chatbot, chế độ bảo trì và thông báo.
- Nhật ký quản trị ghi nguyên tử cùng thay đổi, không sửa/xóa từ client.
- Dashboard có bốn số liệu thật: món, tài khoản đã đồng bộ, tài khoản tạm khóa và thao tác quản trị.
- Candidate Gói 7: tìm có/không dấu và lọc nhóm/trạng thái/vai trò **trong trang đang xem**; chuyển trang đọc 25 mục tiếp từ Firestore.
- Xem chi tiết, xác nhận xóa khỏi danh mục và khôi phục món. Không hard delete để giữ liên kết/lịch sử.
- Xuất Excel `.xlsx` theo **khoảng mã đã chọn**, gồm mọi trang trong phạm vi; tối đa 5.000 mục, quá giới hạn báo lỗi và yêu cầu chia nhỏ. Bộ lọc trang không áp dụng vào tệp.
- Quên mật khẩu gửi yêu cầu email Firebase; logout/thu hồi quyền loại dữ liệu đang hiển thị.

Candidate Gói 7 không tải toàn collection trước trang đầu: mỗi trang 25 document,
sắp theo mã, chỉ đọc control/role của tối đa 25 UID đang xem. Gõ tìm kiếm chỉ
lọc trang hiện tại, không đọc lại Firestore. Chưa có dịch vụ global full-text
search; UI công khai phạm vi thay vì gọi đây là tìm toàn hệ thống. Trang hỗ trợ
cũng dùng cursor. Revenue tải giao dịch theo khoảng ngày, 25 mục mới nhất mỗi
trang; nút **Tổng hợp kỳ** đọc riêng đầy đủ tối đa 5.000 giao dịch của kỳ để
tính và xuất Excel. Không cộng trang hiển thị thành tổng thiếu. Chỉ số gói còn
hạn toàn hệ thống chưa có summary tin cậy nên không hiển thị trong candidate.

Export có thể hủy, kiểm session/quyền trước và sau mỗi request. Không tự thu
hồi tệp đã tải. Dùng **Tải lại** để cập nhật người khác thay đổi; cursor không
phải snapshot nguyên tử của database đang được ghi. Record chèn trước cursor
cần tải lại từ đầu mới thấy; bản ghi đổi timestamp có thể đổi trang.
Chi tiết kiểm thử và giới hạn: [Gói 7](../docs/package7-admin-pagination.md).
Những thay đổi Gói 7 hiện chỉ là source candidate, **chưa publish**; trạng thái
production lịch sử dưới đây không xác nhận candidate này đã lên web.

Trạng thái: **đã publish https://healthmate-admin-vn.web.app**. App Check web,
role và Rules/Hosting đã cấu hình. Dùng **Tiếp tục với Google →
luuxuantung285600@gmail.com**; tài khoản này không có mật khẩu riêng.
17 kiểm tra server thật qua, người dùng chọn thử giao diện sau. Client chờ token
App Check trước mở đăng nhập; enforcement AI giữ nguyên, chưa bật enforcement
mới cho Firestore/Auth. Thanh toán vẫn tắt.
[Báo cáo production và APK nhận cấu hình](../docs/admin-production.md).

Admin không được đọc hồ sơ, bữa ăn, cân nặng hoặc hội thoại của người khác.
Không có nút tự cấp quyền, xóa tài khoản Auth hoặc đổi mật khẩu người dùng.

## Mở trong VS Code và chạy bản local

Nếu cần quản trị dữ liệu thật, chọn **HealthMate Admin (online)** trong Run and
Debug rồi F5, hoặc mở <https://healthmate-admin-vn.web.app>. Bản online không
cần server localhost hoặc emulator. Đăng nhập Google bằng tài khoản admin đã cấp.

Cấu hình **HealthMate Admin (localhost:4173)** nay tự chạy server web trước khi
mở Chrome. Nếu server đang chạy, dùng lại; không khởi tạo trùng. Có thể chạy
riêng `powershell -NoProfile -ExecutionPolicy Bypass -File tool/start_admin_local.ps1`
từ gốc repository. Cờ này chỉ áp dụng cho tiến trình chạy script, không đổi
execution policy đã lưu của Windows.
Log/PID nằm ở `build/admin-local/`. Server chạy nền sau khi đóng Chrome; muốn
dừng thì kiểm tra PID trong file đó trước khi dừng đúng tiến trình Node.

Địa chỉ localhost là **bản thử nghiệm**, dùng Firebase Emulator và tài khoản
fixture bên dưới. F5 chỉ khởi động web server; vẫn cần chạy emulator để đăng
nhập local. Không dùng tài khoản Google thật của production cho bản này.

Mở thư mục gốc **HealthMate 2** bằng File → Open Folder. Cần Node.js,
Firebase CLI và Java 21 trở lên. Web không cần `npm install`.
Thực hiện trong terminal PowerShell tại thư mục gốc, ba terminal riêng:

Terminal 1 — dịch vụ Firebase thử nghiệm:

```powershell
# Máy hiện tại có Java 21 trong Android Studio; đặt PATH để tránh Java cũ.
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = (Join-Path $env:JAVA_HOME 'bin') + ';' + $env:Path
firebase emulators:start --config firebase.admin-emulators.json --only 'auth,firestore' --project demo-healthmate-admin
```

Terminal 2 — tạo dữ liệu mẫu sau khi emulator báo sẵn sàng:

```powershell
node admin-web/seed-emulators.mjs --extended
```

Script chỉ gọi `127.0.0.1:9098/8092` và project `demo-healthmate-admin` cố định.
Chạy lại giữ cùng tài khoản nhưng có thể đặt lại các document fixture; không
dùng script cho dữ liệu cần bảo toàn. Dữ liệu emulator mất khi dừng nếu không export.

Terminal 3 — chạy web:

```powershell
npm --prefix admin-web run dev
```

Mở <http://127.0.0.1:4173/>. Đăng nhập fixture:

| Vai trò local | Email | Mật khẩu fixture |
| --- | --- | --- |
| Admin | admin@healthmate.local | LocalHealthMate!2026 |
| Người dùng thường | member@healthmate.local | LocalHealthMate!2026 |

Đây chỉ là tài khoản giả lập, không phải thông tin đăng nhập production.
Script seed xác minh email hai tài khoản qua Auth Emulator để đáp ứng Rules;
không gửi email thật. Nếu đã đăng nhập trước khi seed hoàn tất, đăng xuất rồi đăng nhập lại để nhận token mới.
Tài khoản thường đăng nhập được nhưng bị từ chối màn hình quản trị.
Web cần mạng để tải Firebase SDK từ `www.gstatic.com`; dữ liệu thử nghiệm vẫn
được gửi tới emulator trên máy. Không mở `index.html` trực tiếp bằng `file://`.
Dừng từng server bằng Ctrl+C sau khi thử.

## File để chỉnh giao diện và hành vi

| File | Vai trò |
| --- | --- |
| `dist/index.html` | Trang gốc và dialog |
| `dist/style.css` | Giao diện, responsive, khai báo font Inter |
| `dist/admin-theme.css` | Theme theo ảnh tham khảo, nạp sau style.css |
| `dist/admin-shell.mjs` | Sidebar, menu, header và drawer mobile |
| `dist/dashboard-page.mjs` | Bố cục tổng quan, biểu đồ và trạng thái dữ liệu |
| `dist/app.mjs` | Đăng nhập, danh sách, form và trạng thái UI |
| `dist/firebase.mjs` | Auth, truy vấn và transaction có audit |
| `dist/validation.mjs` | Kiểm tra dữ liệu, đơn vị, phiên bản document |
| `dist/list-model.mjs` | Tìm toàn bộ danh sách, lọc, phân trang và dữ liệu xuất |
| `dist/xlsx-export.mjs` | Tạo XLSX thật, giữ giá trị người dùng dưới dạng text, không formula |
| `dist/config.js` | Mặc định kết nối emulator, chưa trỏ Firebase thật |
| `server.mjs` | Static server chỉ lắng nghe loopback, kèm CSP |
| `tool/prepare-release.cjs` | Tạo gói review dưới build, không deploy/cấp role |

## Quy trình cấu hình Firebase thật — tham khảo cho lần triển khai sau

Rollout đầu đã hoàn thành theo yêu cầu ngày 27/10; các bước dưới là quy trình
tham khảo, không chạy lại để thử local. Không dùng fixture trong production.

1. Trong Firebase project HealthMate hiện có, đăng ký Web App, lấy **public web
   config**. Bật Email/Password nếu chưa có; chủ dự án tạo/chọn tài khoản admin
   và xác định UID chính xác trong Authentication.
2. Chọn đúng tài khoản `luuxuantung285600@gmail.com` đã xác minh trong Authentication.
   Chủ dự án dùng Firebase Console/IAM tạo `admin_roles/{UID}` với đúng field
   `enabled: true`. Không đặt role trong `users`, không cấp từ web/mobile.
   Thu hồi bằng `enabled: false`; client không thể sửa role. Một UID có document
   `admin_roles`, kể cả đã thu hồi, được bảo vệ khỏi khóa trên web; chủ dự án
   quản lý vòng đời document này qua Console.
3. Rà soát/deploy **toàn bộ** `firestore.rules` hiện tại sau kiểm thử. File đang
   chứa cả thay đổi chưa deploy từ các lượt trước; không dán riêng một đoạn admin
   đè lên Rules khác. Xác nhận `firestore.indexes.json` theo môi trường. Không
   cần Cloud Functions hoặc thêm database.
4. Đăng ký tên miền HTTPS trong Firebase Auth Authorized domains. Đăng ký Web App
   với App Check/reCAPTCHA Enterprise, key kiểu Web/score-based, không checkbox.
   Không thêm localhost vào key production. Kiểm tra request metrics cho cả
   Android/web trước khi thay enforcement, không tắt bảo vệ Android hiện có.
5. Thay cấu hình `dist/config.js` bằng public config thực, xóa `emulators`, thêm
   `appCheckSiteKey`. Ví dụ cấu trúc (điền giá trị do Console cấp):

```javascript
window.HEALTHMATE_ADMIN_CONFIG = {
  firebase: {
    apiKey: 'PUBLIC_FIREBASE_WEB_API_KEY',
    authDomain: 'PROJECT_ID.firebaseapp.com',
    projectId: 'PROJECT_ID',
    appId: 'PUBLIC_FIREBASE_WEB_APP_ID'
  },
  appCheckSiteKey: 'PUBLIC_RECAPTCHA_ENTERPRISE_SITE_KEY'
};
```

Không đưa private key, service-account, Gemini key riêng, mật khẩu hoặc token
debug vào các file này. Public config và site key không thay thế Security Rules.

6. Host bản cấu hình production riêng trên HTTPS sau khi được yêu cầu. Áp dụng các header CSP,
   nosniff/no-referrer/no-store của `server.mjs` trên hosting; không chỉ copy
   giao diện rồi bỏ các header. Không sửa config emulator của repository để thử thật.
   Dự án đã có Hosting site `healthmate-app-20261013`; publish vào đó sẽ thay nội
   dung hiện tại, nên cần kiểm tra trước. Gói đã deploy là
   `build/admin-production-20261027`; không dùng gói review cũ thiếu key.
   Khi cần tạo lại, dùng readiness mới và **thư mục mới**:

```powershell
node admin-web/tool/prepare-release.cjs build/admin-rollout-ready-with-key.json build/admin-review-next
```

   Lệnh chỉ copy nguồn và public config; không gọi Firebase, không xác nhận key
   đã hoạt động và không cấp quyền. Xem manifest; rà soát `firebase.review.json`
   trước mọi lệnh deploy. Không deploy cả root `firebase.json` để bật admin.
7. Sau khi Rules và quyền admin đã sẵn sàng, build bản mobile hỗ trợ:

```powershell
flutter build apk --debug --dart-define=HEALTHMATE_ENABLE_ADMIN_CONTROLS=true
```

Cờ mặc định **false** để bản đang dùng không gọi collection mới trước khi Rules
sẵn sàng. Bật cờ mới áp dụng cấu hình từ xa, màn hình khóa/bảo trì và đồng bộ
directory. Tài khoản cũ xuất hiện trong danh sách sau đăng nhập/tải hồ sơ ở bản
mobile có cờ này; đây không phải toàn bộ danh sách Firebase Authentication.

## Giới hạn vận hành cần hiểu

- Khóa qua Firestore chặn quyền đọc/ghi dữ liệu trên máy chủ, không vô hiệu hóa
  tài khoản Firebase Auth, không thu hồi token và không xóa dữ liệu đã cache trên
  thiết bị. Rules không khóa API Firebase AI Logic; bản mobile hỗ trợ chặn AI ở
  client. Không tuyên bố có thể ngăn client đã bị sửa hoặc app cũ gọi AI trực tiếp.
- Cấu hình bảo trì/tính năng có hiệu lực trên bản mobile bật cờ. Không thêm
  điều kiện bảo trì vào Rules của nhật ký; việc đang lưu có thể hoàn tất.
- Bản bật cờ cần xác minh trạng thái từ server. Cache, lỗi mạng hoặc cấu hình
  không hợp lệ chưa cho vào nội dung riêng tư; có kiểm tra lại/đăng xuất.
- Cập nhật danh mục không sửa snapshot của nhật ký cũ. Ẩn món áp dụng với app
  mới có bộ lọc `isActive`; app cũ có thể vẫn hiển thị.
- Transaction phát hiện document đã đổi theo timestamp tới nanosecond, yêu cầu
  tải lại thay vì ghi đè. Retry cùng thao tác giữ audit ID cho tới khi nhận ACK.
- Sử dụng hạn mức Firebase hiện có; không thêm backend trả phí, không nâng
  billing. Firestore/Auth/App Check vẫn có hạn mức; không hứa miễn phí vô hạn.
  App Check Enterprise có phần miễn phí và phí vượt quota theo cấu hình dự án.

## Kiểm thử

### Doanh thu Premium demo

Mục **Doanh thu** tải `demo_premium_transactions` và
`demo_premium_accounts`, chỉ chấp nhận gói `premium_demo_30d`, giá 20.000 VND,
`mode:demo`, `status:simulated_paid`, `source:demo_checkout`. Không cộng số
người dùng thành doanh thu, không trộn giao dịch thật hoặc dữ liệu sai.

Chọn ngày đầu/cuối theo UTC+7, tối đa 366 ngày; ngày cuối bao gồm cả ngày.
Hiển thị tổng số tiền mô phỏng, số giao dịch/khách mua trong kỳ, gói còn hạn
hiện tại, tổng theo ngày và tối đa 100 chi tiết mới nhất. Excel chứa đủ giao
dịch trong kỳ đã tải. Tải thiếu/lỗi quyền/vượt giới hạn 5.000 bản ghi của bộ
tải sẽ báo lỗi, không hiện tổng thiếu. Nhãn demo đi cùng màn hình và Excel.

Rules chỉ cấp admin đọc metadata giao dịch/gói, không cho đọc nhật ký sức
khỏe người khác hoặc sửa receipt. Bản ghi demo hiện giữ sau xóa Auth, nên số
gói còn hạn là số bản ghi, không bảo đảm tài khoản Auth vẫn tồn tại.

Đã triển khai `build/admin-premium-demo-review-20261030/` ngày 30/10/2026 lên
[admin online](https://healthmate-admin-vn.web.app). Đã backup/đối chiếu
Rules production trước triển khai và đọc lại khớp bản đã test. Quyền admin,
App Check và billing giữ nguyên; chưa đăng nhập/mua demo thay người dùng.
Chi tiết: [Premium demo](../docs/premium-demo-2026-10-30.md).

```powershell
# Cần Node.js hỗ trợ node:module registerHooks (máy kiểm thử hiện tại có sẵn).
npm --prefix admin-web ci
npm --prefix admin-web run check
npm --prefix admin-web test
# Emulator ở terminal 1 phải đang chạy:
npm --prefix rules-tests ci
npm --prefix admin-web run test:sdk
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8092'
npm --prefix rules-tests test
flutter test test/admin_runtime_test.dart
```

Chỉ các bài test dùng dependency dev `linkedom`; chạy web không cần cài package.
Test SDK dùng Firebase 13.0.0 từ rules-tests, đúng phiên bản CDN của production.
Test Rules dùng project demo riêng, không xóa dữ liệu
fixture trong project web admin. Kết quả thực tế: xem `../docs/test-report.md`.

`test/production-smoke.cjs` cần yêu cầu nghiệm thu thật và `--allow-production-qa`:
tạo/xóa danh tính/document QA tạm, giữ audit; không nằm trong `npm test`, không
thay thế test giao diện hoặc token App Check từ browser thật.

Tài liệu chính thức đã kiểm tra ngày 27/10/2026:
[Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions),
[App Check Web Enterprise và hạn mức](https://firebase.google.com/docs/app-check/web/recaptcha-enterprise-provider),
[Auth Admin user management](https://firebase.google.com/docs/auth/admin/manage-users).


## Đồng bộ thời gian thực — candidate 06/11/2026

Đã có listeners cho dashboard, kỳ doanh thu, khách hàng (kèm control/role),
thực phẩm, audit, hỗ trợ và cấu hình. Không cần tải lại để nhận các thay đổi
trong phạm vi đang xem. Hủy listeners khi chuyển trang/đăng xuất/thu hồi quyền;
không dùng dữ liệu cache làm xác nhận mới của server. Bản nháp không bị ghi đè.

Thống kê Auth/vận hành được Cloud Functions cập nhật, bootstrap đầy đủ trước khi
ready. Client không tự ghi bộ đếm. Premium vẫn demo, các chức năng web còn chờ
triển khai không được tính là đã hoàn thành. Người dùng chọn bật Blaze sau:
**candidate chưa publish**, web công khai vẫn chạy bản trước.

Source Functions và lockfile tại `firebase-functions/`; config deployment chỉ
Functions là `firebase.realtime.json`, config local là
`firebase.realtime-emulators.json`. Không deploy toàn bộ root candidate Rules.
Tool `prepare-realtime-release.cjs` hiện sao chép Rules chuẩn repository;
baseline production dùng đối chiếu/rollback. Bundle Functions lịch sử tại
`build/realtime-review-20261106-v2`, chưa triển khai.

Kết quả: admin 66/66, SDK realtime 6/6, Functions emulator 3/3; toàn bộ app và
Rules cũng đã kiểm. Xem [báo cáo, lệnh chạy và giới hạn](../docs/realtime-sync-2026-11-06.md).

## Realtime Spark đã publish — 06/11/2026

Web online đã dùng listeners và statisticsMode=firestore; không cần Functions cho các tập dữ liệu nhỏ. Auth vẫn là snapshot thật có nhãn thủ công. Đã kiểm HTTP/Rules đọc lại khớp release. App cần cài APK mới. Xem [báo cáo triển khai và kiểm thử](../docs/realtime-spark-2026-11-06.md).

## Sửa vận hành — 07/11/2026

Tool prepare-realtime-release.cjs nay đóng gói **nguyên Rules chuẩn** đang được
kiểm thử với Flutter. Backup production là bằng chứng/rollback, không dùng làm
template để bỏ sót quyền của client mới. Chạy test_operations_local.cjs trong
Auth/Firestore emulators và kiểm hash release trước publish. Không cần Blaze
để sửa quyền deletion job/support quota. Giữ nhãn snapshot thủ công cho tổng
Auth. Hỗ trợ đọc trang mới nhất theo updatedAt/ID giảm dần, cursor nanosecond,
giữ draft và ID gửi lại khi chưa rõ kết quả. [Trạng thái rollout và kiểm thử](../docs/operations-hardening-2026-11-07.md).
