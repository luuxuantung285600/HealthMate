# Chủ đề yêu cầu hỗ trợ — 07/11/2026

## 1. Giai đoạn và trạng thái

Giai đoạn 10 — hoàn tất phần phân loại chủ đề trong mã nguồn app/admin,
Rules, kiểm thử local và APK debug. Chưa triển khai Rules/web production.

## 2. Hành vi mới

Form Yêu cầu mới đặt “Chủ đề cần hỗ trợ” trước “Loại yêu cầu”. Không chọn sẵn
chủ đề. Người dùng phải chọn một trong tám chủ đề trước khi gửi:

- Tài khoản & đăng nhập
- Premium & thanh toán
- Dinh dưỡng & món ăn
- Bài tập & vận động
- Hồ sơ & sức khỏe
- AI quét món ăn
- AI Chatbot
- Vấn đề khác

Loại “Báo lỗi / Góp ý” vẫn riêng biệt. Thiếu chủ đề không cấp ID, không gọi
repository và hiển thị hướng dẫn chọn. Chọn chủ đề cũng tính là bản soạn để
hỏi trước khi bỏ bằng Back. Khi đã thử gửi, chủ đề khóa cùng nội dung; retry
dùng cùng topic/ID/payload và kiểm tra ACK từ server.

App hiển thị chủ đề ở danh sách và chi tiết. Admin thêm cột chủ đề, bộ lọc
chủ đề (gồm Chưa phân loại), tìm kiếm theo nhãn tiếng Việt và hiển thị trong
chi tiết đang đồng bộ. Bộ lọc áp dụng trang đang xem như cơ chế hiện có.

Yêu cầu cũ không có topic hiển thị “Chưa phân loại”, không đoán từ nội dung và
không gán sang “Vấn đề khác”. Không sửa/migrate dữ liệu cũ. Quyền owner/admin,
quota, trạng thái, reply và giới hạn 100 tin nhắn giữ cơ chế hiện có.

## 3. File chính

- App: `support_models.dart`, `support_repository.dart`,
  `firebase_support_repository.dart`, `support_screen.dart` trong feature support.
- Admin: `admin-web/dist/support-model.mjs`, `support-page.mjs`.
- Rules: `firestore.rules`; hợp đồng dữ liệu trong `docs/database-design.md`.
- Test: hai suite hỗ trợ Flutter, `support_repository_integration.dart`,
  các fixture API create ở account deletion/realtime Spark; các test admin
  model/DOM/SDK và `rules-tests/support.rules.test.cjs`.
- Báo cáo này, `docs/implementation-progress.md`, `docs/test-report.md`.

## 4. Kiểm thử thực tế

| Kiểm tra | Kết quả |
| --- | --- |
| `flutter test --no-pub --reporter expanded` trên source cuối | **1022/1022 qua**, gồm 38 ca hỗ trợ; tăng 4 test so với 1018 |
| `flutter analyze --no-pub` | Không issues |
| `dart format --output=none --set-exit-if-changed` trên 11 file liên quan | 0 thay đổi |
| `npm test --prefix admin-web` | **86/86 qua**, gồm 3 test mới model/DOM |
| `npm run check --prefix admin-web` | Qua |
| `npm test --prefix rules-tests` trên Auth/Firestore Emulator | **139/139 qua**, thêm 10 test chủ đề |
| Flutter web SDK `support_repository_integration.dart` | **4/4 qua** trên Auth9099/Firestore8080, project demo cố định |
| Admin production SDK trên emulator | **9/9 qua**, xác nhận topic giữ nguyên qua reply/status/customer follow-up |
| Android helper | Runtime config **7/7 qua**, APK debug build thành công |
| `git diff --check` | Qua |

Test mới xác nhận đủ tiêu đề/nội dung nhưng thiếu chủ đề vẫn không ghi; chọn
chủ đề rồi mới gửi; hiển thị trong lịch sử/chi tiết; duyệt tám lựa chọn ở
320 px và chữ 200%; giữ lựa chọn khi tiếp tục bản soạn; khóa chủ đề khi retry.
SDK kiểm tra ghi `nutrition`, đọc enum tương ứng và từ chối retry cùng ID
nhưng đổi sang `premium`; lịch sử cũ không có topic vẫn phân trang bình thường.

Rules test từng mã hợp lệ, từ chối chuỗi lạ/rỗng/null/số/map/array, chặn UID
khác, chặn owner/admin sửa chủ đề, vẫn cho reply/status và lịch sử thiếu field.
Admin kiểm lọc chủ đề độc lập type/status, nhãn Việt không dấu, legacy và
phân biệt “Chưa phân loại” với `other`.

Preview dùng Inter/AppCanvas thật, nhãn “DỮ LIỆU KIỂM THỬ”, sáng390px/chữ100%
và tối320px/chữ200%. Đã xem ảnh menu và lựa chọn cuối, sửa hiện tượng chữ bị
cắt bằng chiều cao dropdown thích ứng. Ảnh tại
`build/support-topics-{light-390-100,dark-320-200}-{empty,options,selected}.png`.
Không có fixture ghi vào Firebase production.

Lỗi trung gian: các helper chỉ tìm widget đã dựng bị lỗi khi form dài hơn và
ListView bỏ widget ngoài vùng dựng. Helper nay cuộn đúng hướng để tìm trước
khi tap; popup chủ đề cũng cuộn để tới các mục chưa dựng. Sau sửa chiều cao UI,
test retry cần cùng cải thiện helper. Giữ các assertion nghiệp vụ và chạy lại
full suite trên source cuối. Không bỏ test hoặc thay assert để che lỗi.

Log chính: `build/support-topics-full-final.log`,
`build/support-topics-analyze-final.log`, `build/support-topics-admin-tests.log`,
`build/support-topics-admin-check.log`, `build/support-topics-emulators.log`,
`build/support-topics-admin-sdk.log`, `build/support-topics-preview-final.log`,
`build/support-topics-apk.log`. Emulator đã tự dừng sau mỗi lượt chạy.

## 5. Artifact và bước áp dụng

- APK: `build/releases/healthmate-support-topics-20261107-debug.apk`.
- Manifest: cùng tên, đuôi `.json`.
- SHA-256 đã đối chiếu bản sao:
  `88940133ECCD868CD477907D0BC547340C535683B8374AF930FCEB56ADB18F38`.
- Dung lượng: **237068809 byte**; build UTC `2026-11-07T14:21:15.3999773Z`.
- Bản review: `build/releases/support-topics-20261107/`, gồm Rules đã test,
  hai module admin thay đổi và manifest hash/trình tự rollout; `deployed:false`.
- Rules SHA-256:
  `EB0760E81E9C1EF775C527A3CD8B9AE85CBD7290F02594AA7689E23FD36B682F`.

Để sử dụng trên bản đang chạy: đối chiếu Rules live rồi triển khai Rules hỗ
trợ topic, publish web admin mới với cấu hình hiện có, sau đó phân phối APK.
Rules cũ có allowlist không chứa `topic`, nên app mới sẽ bị từ chối tạo yêu
cầu nếu bỏ qua bước cập nhật Rules. Không có fallback âm thầm xóa chủ đề.

Không cần dịch vụ mới, index, package hoặc Blaze cho phần này. APK dùng cấu
hình admin hiện có, Premium demo tắt. Tạm đặt Kotlin incremental=false trong
tiến trình build rồi phục hồi. Giữ các artifact và thay đổi trước lượt này.
Chưa commit/push hoặc deploy production trong lượt này.

## 6. Giới hạn

Rules tiếp tục nhận ticket không có topic để tương thích app/dữ liệu cũ; app
mới bắt buộc chọn. Topic không thay thế type và không tự phân công nhân sự
hay tạo SLA. Không kiểm thử Android thật, không ký release theo chỉ dẫn đang
áp dụng; kiểm thử SDK dùng emulator, không coi là xác nhận production.
Bản soạn hỗ trợ vẫn chỉ trong bộ nhớ. Cảnh báo plugin KGP tương lai của build
trước vẫn còn; không nâng dependencies ngoài phạm vi.

## 7. Tiếp theo đề xuất

Áp dụng Rules/web đã kiểm thử và phân phối APK mới. Chưa tự triển khai.
