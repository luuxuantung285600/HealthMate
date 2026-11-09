# Độ tin cậy khi xóa nhật ký — 08/11/2026

## Phạm vi

Giai đoạn 10: hoàn thiện luồng xóa bữa ăn, lần uống nước và hoạt động đã có.
Người dùng yêu cầu tiếp tục cải thiện app; chọn nhóm này sau khi rà soát
nhật ký. Không thêm dependency, dịch vụ, schema, Rules hoặc chi phí mới.
Giữ nguyên những thay đổi đang có của các lượt trước.

## Vấn đề và hành vi mới

Trước đây hộp xác nhận đóng ngay khi bấm Xóa rồi mới gọi repository.
Nếu máy chủ từ chối hoặc mất mạng, người dùng mất ngữ cảnh của bản ghi
đang xóa. Hộp cũng chưa ràng buộc với phiên tài khoản; callback đọc
controller của phiên hiện tại sau khi chờ xác nhận.

Hiện tại:

- Hiển thị loại bữa và tên/khẩu phần từng món, hoặc lượng nước, hoặc loại/
  thời lượng vận động, cùng ngày giờ của bản ghi để kiểm tra trước khi xóa.
- Bấm Hủy trước khi gửi không ghi dữ liệu.
- Bấm Xóa giữ hộp mở trong lúc chờ repository. Khóa gửi lặp, Back và thao
  tác đóng trong thời gian chờ; không tự timeout rồi gửi lệnh thứ hai.
- Thành công mới đóng và báo đã xóa. Lỗi giữ đúng bản ghi và cho thử lại
  cùng ID, kể cả trường hợp lần trước đã áp dụng nhưng chưa nhận ACK.
- Chỉ mở một hộp xóa trong cùng màn nhật ký. Khi đổi tài khoản, hộp riêng
  tư đóng; kết quả muộn không thông báo thành công trong phiên mới.
- Kiểm tra cả UID trong auth stream và UID hiện tại của Auth repository
  ngay trước khi gửi. Chặn cả khoảng trễ giữa đổi Auth và stream cập nhật.
- Các section nhật ký được gắn key theo UID để dispose menu state cũ.
  PopupMenuButton đọc callback của widget hiện tại khi menu hoàn tất;
  giữ state qua tài khoản có thể chuyển thao tác menu cũ sang tài khoản mới.
  Closure cũng giữ UID đã tạo thao tác để từ chối phiên không còn phù hợp.
- Luồng stream/tổng hợp có sẵn tiếp tục cập nhật tổng kcal, ml nước và
  phút vận động sau xóa. Không thêm listener hoặc lần đọc Firestore mới.

Repository và Rules không thay đổi. Xóa nước/vận động đã dùng delete theo
UID/ID; xóa bữa đã dùng transaction đọc trạng thái hiện tại, bỏ liên kết
meal plan nếu có và chỉ delete document khi tồn tại. Thử lại khi document
không còn tồn tại giữ hành vi idempotent hiện hữu.

## File chính

- `lib/features/journal/presentation/journal_screen.dart`: thống nhất luồng
  xóa, chờ ACK, kiểm tra phiên, thông báo và key section theo UID.
- `lib/features/journal/presentation/delete_journal_entry_dialog.dart`:
  dialog trạng thái chờ/lỗi/thử lại, nội dung cuộn và phản hồi accessibility.
- `lib/features/nutrition/presentation/meal_log_section.dart`: key ổn định
  cho dòng bữa ăn, phục vụ xác định chính xác bản ghi trong UI/test.
- `test/journal_deletion_quality_test.dart`: 21 regression mới.
- `docs/implementation-progress.md`, `docs/test-report.md`, báo cáo này.

## Kiểm thử và artifact

- Format ba source và test mới: sạch.
- `flutter analyze --no-pub`: không có vấn đề.
- Suite nhật ký mới + core_journal + journal_sections: **60/60 qua**.
- `flutter test --no-pub`: **1.092/1.092 qua** (1 phút 43 giây).
- Sau đó tăng độ chặt của test menu đổi phiên: giữ JournalScreen thực
  mounted qua A → B, giữ popup cũ, chọn Xóa và xác nhận không mở hộp/ghi.
  Suite mới chạy lại **21/21 qua** (8 giây), analyzer chạy lại sạch.
- Mỗi loại nhật ký đều có test Hủy, pending/double tap/Back, lỗi và thử
  lại, đổi tài khoản trước xác nhận, Auth đổi trước stream, menu phiên cũ,
  logout khi đang chờ và ACK không nhận sau khi thao tác đã áp dụng.
- Sau xóa, stream tổng hợp thực của app trả về phần còn lại trong fixture:
  155 kcal, 200 ml và 15 phút; bản ghi khác được giữ.
- Preview Inter/icon thật **6/6 qua**, ba loại nhật ký ở 390 px sáng 100%
  và 320 px tối 200%. Đã xem 18 ảnh xác nhận/pending/retry qua ba contact
  sheet; không có overflow, thông tin và nút vẫn đọc được.
- `flutter build apk --debug --no-pub`: thành công (25,6 giây). Giữ cảnh
  báo plugin KGP hiện hữu; không nâng package ngoài phạm vi.
- Source secret audit: không có phát hiện theo pattern. `git diff --check`:
  qua, chỉ có cảnh báo LF/CRLF hiện hữu.

Các lỗi fixture trung gian đã sửa: finder khớp nội dung ở cả màn bên dưới
và dialog; hồ sơ UID B chưa được cấp cho router; kiểm tra provider theo
giờ 12:30 thay vì key ngày 00:00 của UI. Đã sửa harness/fixture, không bỏ
assertion nghiệp vụ hoặc thay đổi logic sản phẩm để che lỗi test.

Log trong `build/`: `journal-delete-focused-final.log`,
`journal-delete-session-final.log`, `journal-delete-all-flutter-tests.log`,
`journal-delete-analyze-final.log`, `journal-delete-preview.log`,
`journal-delete-apk.log`. Preview và harness tại `build/journal-deletion-quality/`
được gắn nhãn fixture, không phải số liệu người dùng thật.

APK: `build/releases/healthmate-journal-deletion-20261108-debug.apk`.
Kích thước **237.534.804 byte**; SHA-256:
`0C791DBF427E686DA2792FFBE7ED56985F5A4AD6EA723152BCC218EA3B1FBCA2`.
Manifest JSON cùng tên ghi trạng thái build/triển khai.

## Giới hạn và bước sau

- Không cần cấu hình Firebase mới; cài APK cập nhật để dùng thay đổi.
- Chưa nghiệm thu Android thật, ký release, deploy hoặc push GitHub.
- Lỗi mạng/ACK và đổi phiên được điều khiển bằng repository giả lập;
  không coi đây là bằng chứng nghiệm thu máy chủ trên thiết bị thật.
- Đổi tài khoản đóng UI và bỏ kết quả muộn; không hủy được một lệnh máy
  chủ đã tiếp nhận trước đó cho tài khoản gốc. Không có cơ chế hoàn tác xóa.
- Bước sau đề xuất: rà soát khôi phục nháp và chỉnh sửa bữa ăn. Chưa tự
  triển khai sang nhóm tiếp theo.
