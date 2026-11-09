# Khôi phục nháp và chỉnh sửa bữa ăn — 09/11/2026

## Phạm vi

Giai đoạn 10: cải thiện độ tin cậy của luồng bữa ăn hiện có theo yêu cầu
tiếp tục hoàn thiện app. Không thêm package, dịch vụ, query Firestore,
schema hoặc Security Rules. Giữ các thay đổi của những lượt trước.

## Vấn đề đã sửa

- Trước đây một lần sửa mới dùng lại mã `edit-{mealId}`. Chọn tạo bản
  mới có thể khiến auto-save ghi đè nháp chỉnh sửa cũ chưa xác nhận.
  Mỗi lần sửa mới giờ có mã riêng; khôi phục giữ nguyên mã của nháp đã
  chọn. Hoàn tất chỉ dọn nháp của thao tác đó, giữ các nháp khác.
- Danh sách nháp hiển thị tên món, ngày bữa ăn và ngày/giờ giữ nháp.
  Khi mở từ một bữa đã lưu, lựa chọn mới ghi “Sửa từ bữa đã lưu”.
- Khôi phục nháp sửa từ danh sách chung hiển thị “Sửa bữa ăn”, gọi
  update đúng mealId và báo “Đã cập nhật bữa ăn” khi thành công.
- Form chỉnh sửa và `MealLog.toDraft()` giữ timezone offset của bữa cũ.
  Sửa khẩu phần không tự dịch ngày bữa ăn theo múi giờ của thiết bị.
  Sao chép sang ngày mới vẫn dùng nghiệp vụ sao chép hiện có.
- Bữa schema 1 được form chuyển minimum schema thành 2, phù hợp codec
  nháp/serializer hiện có. Không tự chấp nhận phiên bản schema lạ.
- Chặn nhiều lần mở form trong cùng phiên, kể cả khi còn tải profile,
  đọc bộ nhớ hoặc chọn nháp. Hủy/lỗi mở form giải phóng quyền mở lại.
- Theo dõi đổi UID bằng `listenManual` trong thời gian mở luồng; đóng
  subscription khi luồng kết thúc hoặc widget bị dispose. Token cũ bị
  vô hiệu qua A → logout → A; cleanup cũ không giải phóng token mới.
  Khi màn hình cũ đã dispose, điểm mở mới không bị token cũ chặn.
- Kiểm tra cả Auth stream và currentUid ngay trước thao tác. Kết quả
  đọc/lưu muộn không mở form hoặc báo thành công sang phiên khác.
- Tiêu đề form xuống tối đa hai dòng, toolbar tăng theo cỡ chữ, giúp
  đọc đầy đủ “Sửa bữa ăn” ở màn 320 px/cỡ chữ 200%.

Lưu vẫn ghi nháp xuống thiết bị trước khi gửi repository; lỗi lưu giữ
form/nháp để thử lại. Chỉ sau xác nhận thành công mới dọn đúng nháp.
Các cơ chế kiểm tra dữ liệu, xác nhận món cần tránh, mã tạo bữa ổn định
và stream đồng bộ đang có tiếp tục được sử dụng.

## File chính

- `lib/features/journal/presentation/journal_meal_entry.dart`: quyền mở
  theo phiên, mã thao tác mới, kiểm tra phiên và định tuyến create/update.
- `lib/features/meal_drafts/presentation/draft_picker.dart`: nội dung chọn nháp.
- `lib/features/nutrition/presentation/meal_form_dialog.dart`: trạng thái
  sửa, timezone, schema cũ và tiêu đề khi tăng cỡ chữ.
- `lib/features/nutrition/models/nutrition_models.dart`: giữ offset khi toDraft.
- `test/meal_draft_quality_test.dart`: chín regression mới.
- Báo cáo này, `docs/implementation-progress.md`, `docs/test-report.md`.

## Kiểm thử thực tế

- Format bốn source và test mới, kiểm tra lại: **0 file thay đổi**.
- Suite h7_private_data + ux_meal_recovery + core_journal: **86/86 qua**.
- Regression mới và preview sau chỉnh sửa cuối: **11/11 qua**
  (chín regression và hai cấu hình preview).
- `flutter test --no-pub` cuối: **1.101/1.101 qua**, 2 phút 7 giây.
- `flutter analyze --no-pub` cuối: **không có vấn đề**.
- Preview Inter và MaterialIcons thật: **2/2 qua**, 390 px sáng 100%
  và 320 px tối 200%. Đã xem 12 ảnh: chọn nháp, cuối danh sách, form
  khôi phục, pending, lỗi và nút thử lại sau cuộn. Nội dung/footer có
  cuộn khi tăng cỡ chữ; nút lưu tiếp cận được, không có layout exception.
- `flutter build apk --debug --no-pub`: **thành công**, Gradle 36,4 giây.
  Giữ cảnh báo KGP hiện hữu của các plugin; không nâng dependency.
- Source secret audit: không phát hiện theo pattern. Phạm vi là source
  được Git theo dõi và file mới không bị ignore, không phải audit APK
  hoặc credential store. `git diff --check`: qua, còn cảnh báo LF/CRLF.

Ca đổi phiên ban đầu phát hiện listener đặt trong provider chỉ được
`ref.read` có thể bị pause. Đã sửa bằng subscription chủ động trong
luồng. Harness giữ profile subscription như router thật và giữ widget
mounted qua đổi phiên để không dựa vào router teardown làm test qua.
Giữ nguyên các assertion về một form, không ghi nhầm và token mới.

Log: `build/meal-draft-existing.log`, `meal-draft-focused-preview-final.log`,
`meal-draft-quality-full-final.log`, `meal-draft-analyze-final.log`,
`meal-draft-preview-final.log`, `meal-draft-apk.log`,
`meal-draft-secret-audit.log`, `meal-draft-diff-check.log`.
Preview/harness trong `build/meal-draft-quality/` dùng dữ liệu fixture
có nhãn rõ; không đưa dữ liệu kiểm thử lên Firebase production.

APK: `build/releases/healthmate-meal-drafts-20261109-debug.apk`.
Kích thước **237.540.651 byte**, SHA-256:
`55CF31870FADAA31A84D409E31FBDA52F70DF0F8A64B00E6A106D5EBCC68922B`.
Manifest JSON cùng tên ghi trạng thái build/triển khai.

## Giới hạn và bước sau

- Không cần cấu hình Firebase mới. Muốn sử dụng thay đổi cần cài bản app
  cập nhật; chưa nghiệm thu Android thật, ký release, deploy hoặc push.
- Test dùng repository và bộ nhớ giả lập; chưa xác minh mất mạng/process
  death trên Android thật. Không chạy lại Rules emulator vì không sửa Rules.
- Bảo vệ các nháp trên thiết bị; nháp không đồng bộ sang thiết bị khác.
  Giới hạn lưu hiện hữu vẫn là 20 nháp và thời hạn bảy ngày.
- Chưa phát hiện xung đột khi hai thiết bị cùng sửa một bữa: update
  phía máy chủ vẫn theo hành vi lần ghi sau cùng. Giữ nháp cũ không có
  nghĩa đã có optimistic concurrency control hoặc lịch sử phiên bản.
- Đổi phiên không hủy một lệnh máy chủ đã tiếp nhận cho tài khoản gốc;
  chỉ chặn gửi tiếp và bỏ UI/kết quả muộn của luồng cũ.
- Đề xuất tiếp theo: rà soát luồng mục tiêu dinh dưỡng và kế hoạch bữa
  ăn. Chưa triển khai nhóm tiếp theo trong lượt này.
