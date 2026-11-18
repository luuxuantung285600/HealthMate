# HealthMate — Bàn giao cho AI tiếp theo

Cập nhật **19/11/2026**. Đọc `AGENTS.md` trước, rồi tài liệu này và các mục mới nhất
của `docs/implementation-progress.md`, `docs/test-report.md`. README và báo cáo cũ có
mốc lịch sử; ưu tiên code hiện tại và báo cáo mới, không coi source đã được deploy.

## 1. Tổng quan và môi trường

- **HealthMate** giúp người Việt, đặc biệt sinh viên/người mới, theo dõi dinh dưỡng,
  cân nặng, vận động và thói quen; không chẩn đoán hay điều trị bệnh.
- **App:** Flutter/Dart, Android ưu tiên; Chrome/Edge để chạy thử. Riverpod,
  go_router, fl_chart, image_picker, mobile_scanner, in_app_purchase,
  shared_preferences; có firebase_ai nhưng cấu hình/provider quyết định khả dụng.
- **Backend:** Firebase Auth, Cloud Firestore là database chính duy nhất,
  App Check; `firebase-functions/` chứa đồng bộ Auth và xác minh Google Play.
  `chat-api/` là gateway Cloudflare Worker đã có trong repo, mặc định tắt ở
  candidate; không tự thay kiến trúc để chạy AI.
- **Admin:** HTML/CSS/JavaScript ES modules, Firebase Web SDK; không React/bundler.
- **Máy hiện tại:** Windows/PowerShell, VS Code, Git; Flutter 3.44.1/Dart 3.12.1,
  Node 24, JDK 21. Flutter tại `D:/Flutter/flutter`, Node `D:/Database/node.exe`.
- **Git:** https://github.com/luuxuantung285600/HealthMate, nhánh `codex/nutrition`.
  Firebase project `healthmate-app-20261013`; admin local `http://127.0.0.1:4173`,
  online https://healthmate-admin-vn.web.app/ có thể khác source mới nhất.

## 2. Tiến độ — checklist

Các mục hoàn thành dưới đây là chức năng trong source và kiểm thử, không phải
chứng nhận mọi dịch vụ đã cấu hình/triển khai production.
Giai đoạn chức năng gần nhất: **11 — polish ExerciseDB**, đã xong phần được yêu cầu;
phiên này bàn giao/kiểm tra/Git, không tự mở tính năng mới.

- [x] Auth/session, onboarding nhiều câu hỏi, mục tiêu/calo cá nhân; profile sửa
  tên/ảnh, lịch sử cân nặng/BMI tham khảo.
- [x] Tìm/lọc món, khẩu phần/ảnh, nhật ký theo giờ, nước, hoạt động, quest,
  dashboard, tiến độ tuần, báo cáo/xuất dữ liệu và support theo chủ đề/hội thoại.
- [x] Admin quản lý khách hàng, món/ảnh/dinh dưỡng, bài tập, support, cấu hình,
  audit và báo cáo; listeners đồng bộ với app theo quyền và cùng Firebase project.
- [x] Bộ thực phẩm chung ban đầu 500 mục; đợt ảnh giữ **379 có ảnh, 121 ẩn** theo
  lựa chọn người dùng. USDA offline rộng hơn, không được cộng vào để nói đủ 500 ảnh.
- [x] Thư viện **60 bài ExerciseDB: 50 nam, 10 nữ**; hướng dẫn Việt, buổi tập,
  bộ đếm, ước tính kcal theo MET, nền GIF đen và xử lý viền/vùng trắng.
- [x] Mới nhất: admin **Thêm từ ExerciseDB**, tìm tên/lọc cơ/dụng cụ/phân trang
  kho nguồn (lần kiểm 19/11: 1.500 bài), ảnh tĩnh trên thẻ, bấm mới phát GIF;
  tự điền mã, admin biên tập Việt rồi lưu, app nhận qua realtime.
- [x] Source Google Play mua/khôi phục/xác minh, membership và ledger tách
  sandbox/production; không tự cấp Premium từ callback client.
- [ ] **Còn cấu hình/nghiệm thu:** Play Console, sản phẩm/base plan, signing,
  Publisher API/IAM, RTDN, App Check và deploy Functions cần Blaze. Chưa có
  bằng chứng mua thật/license testing hoàn chỉnh; người dùng đã hoãn bật billing.
- [ ] AI gateway/scanner ảnh: còn provisioning identity/IAM, quota và rollout;
  candidate đóng khi chưa sẵn sàng. Barcode/nhập tay vẫn có đường sử dụng.
- [ ] Nghiệm thu Android thật, ký phát hành; kiểm retention/purge bền vững khi
  xóa tài khoản, migration/index/Rules và rollout đồng bộ trước phát hành.
- [ ] Chưa phát hành thay đổi ExerciseDB mới nhất lên Hosting. Git push không
  đồng nghĩa deploy. Không còn hạng mục code đang sửa trong phiên bàn giao.

## 3. Cấu trúc cần nắm

```text
lib/
  main.dart, app.dart          Khởi tạo Firebase/ProviderScope và app
  core/config/                Bootstrap, cờ môi trường, App Check
  core/router/                Routes, Auth redirect, shell
  core/theme/, widgets/       Tokens, icon, theme và UI dùng chung
  features/                   Mỗi nghiệp vụ: model → repository → providers → UI
    auth/, profile/           Tài khoản, onboarding và thể trạng
    nutrition/, journal/      Danh mục, snapshot bữa ăn và nhật ký
    nutrition_targets/        Công thức và kế hoạch dinh dưỡng
    activity/                 Thư viện, GIF, buổi tập và kcal MET
    premium/, chatbot/        Billing đã xác minh và ngữ cảnh AI
    water/, goals/, daily_quest/, dashboard/, progress/, reports/, support/...
  shared/                     Provider/utility dùng chung
admin-web/dist/                Source admin đang được server phục vụ trực tiếp
admin-web/test/, server.mjs    Test admin, server local cổng 4173
firebase-functions/src/        Đồng bộ máy chủ và Play Billing
chat-api/src/                  Gateway chat, xác thực và quota
data/, assets/                 Dữ liệu biên tập, ảnh/font và registry generated
test/, integration_test/       Unit/widget và kiểm thử tích hợp Flutter
rules-tests/                   Security Rules với Firebase Emulator
tool/                         Generator, kiểm tra, seed/publish có kiểm soát
config/, deploy/, docs/        Cấu hình client, quy trình release, thiết kế/báo cáo
firestore.rules, *.indexes.json Quyền và index; không deploy tùy tiện
```

## 4. Quyết định đã chốt

- **Feature-first + Repository Pattern, Riverpod:** UI không truy vấn Firestore
  tùy tiện; dễ test và tách dữ liệu theo UID. go_router quản lý session/điều hướng.
- **Dữ liệu:** `users/{uid}/...` riêng tư; catalog chung do admin có quyền sửa.
  Nhật ký lưu snapshot dinh dưỡng, sửa catalog không được đổi lịch sử.
  Archive/restore ưu tiên hơn xóa cứng; giữ audit/version và hủy listener đúng lúc.
- **Thiết kế:** sáng trắng `#FFFFFF`, tối đen `#000000`, surface `#121212`,
  nút/icon trung tính; tránh nền tím/xanh phủ toàn app. Vòng macro: carb xanh
  `#79A8F2`, protein hồng `#F18B88`, fat vàng `#EEC45A`, luôn kèm nhãn.
- **Font hiện tại Public Sans** bundled, không phải Inter/Chirp; yêu cầu kiểu X
  đã thay lựa chọn Inter cũ. App dùng Tabler bundled qua `AppIcons`, admin Lucide;
  giữ license. Spacing 4/8/16/24/32/48, dùng `AppSpacing`, `AppShapes`, theme.
- **Tên:** class UpperCamelCase, field/hàm lowerCamelCase, file Dart snake_case;
  giao diện/giải thích tiếng Việt. Không nâng dependencies hàng loạt.
- **Media:** chỉ ExerciseDB miễn phí cho kiểm thử phi thương mại; không lấy
  RepDB, không gán GIF nam thành nữ. Không thêm RapidAPI/gói phí khi chưa được duyệt.

## 5. Vấn đề, nguyên nhân và cách đã xử lý

| Tình trạng | Nguyên nhân / cách đã thử |
| --- | --- |
| Kho chỉ hiện tên — đã sửa | Đã thêm canvas một khung GIF, lazy load và retry; bấm mở player thật. |
| Nền thumbnail mobile trắng — đã sửa | Kernel filter bị làm tròn ở khung 80px; tăng khung tối thiểu 96px, kiểm screenshot sáng/tối. |
| CSS profile bị CSP chặn — đã sửa | Bỏ style động/inline, sinh stylesheet ngoài; không nới CSP. |
| GIF nguồn có thể lỗi/chậm/429 | Timeout, hủy request, backoff và nút thử lại; nguồn gốc 180p, không hứa HD. |
| Không đủ 20–30 GIF nữ cùng nguồn | Đã rà rộng, xác minh 10 tệp khác nhau; người dùng chốt giữ 10, không tạo bản trùng cho đủ số. |
| Premium/AI chưa chạy thật đầy đủ | Thiếu cấu hình/triển khai bên ngoài như mục 2; fixture thành công không chứng minh production. |

## 6. Code cốt lõi — đọc file thay vì sao chép

- `lib/features/nutrition/data/firebase_nutrition_repository.dart`: catalog,
  visibility và nhật ký realtime; `nutrition_models.dart` giữ đơn vị/snapshot.
- `lib/features/nutrition_targets/models/personal_nutrition_plan.dart`: Mifflin–
  St Jeor và mục tiêu; không suy calo bằng AI. `activity/models/activity_energy.dart`:
  `grossKcal = MET × kg × giây / 3600`; active kcal dùng `(MET − 1)`, là ước tính.
- `activity/data/exercise_library_repository.dart`: chờ snapshot server xác nhận,
  merge bundled + override, giữ tombstone; không làm sống lại bài admin đã ẩn.
- `data/workouts/exercise-library.json` → `tool/build_exercise_library.cjs`
  → catalog Dart/admin; profile nền tương tự qua `build_exercise_background_profiles.cjs`.
  Sửa nguồn biên tập rồi sinh lại, không sửa tay file generated.
- `admin-web/dist/workouts-page.mjs`: CRUD/audit; `exercisedb-browser-model.mjs`
  đọc API/ánh xạ draft; `exercisedb-browser.mjs`, `exercise-source-thumbnail.mjs`
  và `exercise-media-preview.mjs`: picker, ảnh tĩnh, player và cleanup.
- `premium/providers/play_billing_controller.dart` và
  `firebase-functions/src/billing-*.cjs`: ownership/xác minh/ledger; tuyệt đối
  không mở entitlement hoặc ghi doanh thu thật từ client/dữ liệu mô phỏng.

## 7. Quy tắc tiếp tục và kiểm tra

- Trả lời tiếng Việt, ngắn và rõ; chỉ làm phạm vi/giai đoạn được yêu cầu, báo
  kế hoạch ngắn, kiểm thử và cập nhật progress/test-report rồi dừng.
- Giữ dữ liệu thật, nguồn/giấy phép; thiếu dinh dưỡng là thiếu, không điền 0.
  Không bịa số tài khoản/doanh thu, không đổi công thức y tế tùy ý.
- Không tự đổi Firebase project, kiến trúc/schema/Rules, package ID
  `com.example.healthmate`, giá/billing, dữ liệu production hoặc dịch vụ có phí.
  Dùng thẩm quyền đã có trong hội thoại; chưa có thì hỏi trước quyết định rủi ro.
- Không commit credential, token App Check, signing key, `.env`, build/cache.
  Client Firebase config công khai không phải khóa quản trị. Không đọc/khoe
  credential từ máy; không nới Rules hay CSP để che lỗi.
- Không suy diễn yêu cầu tắt laptop từ phiên cũ; chỉ làm nếu có yêu cầu mới.

```powershell
flutter pub get
npm ci --prefix admin-web
flutter run -d chrome --dart-define-from-file=config/chat-api.json --dart-define-from-file=config/admin-runtime.json
npm run dev --prefix admin-web
# Android: tool/run_android.ps1, cần token debug riêng ngoài repo; xem README.
flutter analyze --no-pub
flutter test --no-pub --concurrency=2 --reporter expanded
npm test --prefix admin-web
node tool/audit_source_secrets.cjs
```

**Kiểm tra bàn giao:** analyze sạch; format 260 file Dart không còn thay đổi;
admin 176/176, chat-api 49/49, Functions 29/29, tool 64/64 qua; quét source không
phát hiện secret. **Flutter toàn bộ: 1.434 qua, 1 ca chụp ảnh tùy chọn bỏ qua**
(`WORKOUT_CAPTURE` chưa bật), exit 0.
Kiểm Chrome trước bàn giao: sáu bố cục sáng/tối qua, ảnh tĩnh/GIF thật qua;
Firestore Emulator toàn bộ Rules **183/183 qua** trong lượt bàn giao.
Đã sửa fixture test thiếu repository hoạt động, chờ layout trước thao tác UI
và đường dẫn Rules phụ thuộc thư mục chạy; không bỏ assertion nghiệp vụ.
Log/ảnh tại `build/` bị gitignore, không có trong checkout GitHub; báo cáo đã
commit nằm trong `docs/`. Xem chi tiết mới nhất:
`docs/exercisedb-thumbnails-2026-11-19.md`, `docs/exercisedb-admin-browser-2026-11-19.md`.
