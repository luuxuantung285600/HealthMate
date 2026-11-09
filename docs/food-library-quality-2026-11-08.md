# Thư viện món ăn và công thức — 08/11/2026

## Giai đoạn và phạm vi

Giai đoạn 10: củng cố độ tin cậy của tính năng hiện có. Người dùng cho phép
tự chọn một nhóm cải thiện; chọn thư viện món cá nhân/công thức sau khi rà soát.
Không thêm dependency, dịch vụ, schema, Rules hoặc ghi dữ liệu vào production.
Các thay đổi đã có trong working tree được giữ nguyên.

## Hành vi đã cải thiện

- Quay lại hoặc bấm Hủy khi đã sửa món/công thức sẽ hỏi bỏ thay đổi.
  Chọn tiếp tục giữ nguyên nội dung và nguyên liệu đang sửa; form mở rồi
  đóng khi chưa thay đổi không hỏi thừa. Bản nháp điền từ scanner cũng
  được bảo vệ trước khi lưu vào thư viện.
- Theo dõi cả tên khác, nguồn, khẩu phần, macro, chất xơ, dưỡng chất mở
  rộng và thay đổi danh sách/gram nguyên liệu. Đổi tên không làm tròn lại
  số liệu dinh dưỡng/khẩu phần đã lưu.
- Hộp xóa hiển thị đúng món, chờ repository xác nhận mới đóng và báo
  thành công. Khi đang chờ, khóa thao tác gửi lặp/đóng bằng Back. Lỗi giữ
  hộp thoại để thử lại cùng món; đổi tài khoản đóng các hộp riêng tư và
  bỏ qua kết quả muộn của phiên cũ.
- Chọn nguyên liệu kiểm tra lại trạng thái danh mục/thư viện sau bước
  nhập gram. Nguồn vừa bị ẩn/xóa, tải lỗi hoặc thiếu macro bị từ chối.
  Nếu thông tin dinh dưỡng/tên/nguồn/khẩu phần thay đổi, yêu cầu chọn lại
  để xem số liệu mới; không âm thầm thay kết quả người dùng đã xem.
- Nguồn thiếu macro vẫn có giải thích nhưng không thể thêm vào công thức.
  Revision so sánh dữ liệu liên quan, dùng vector dưỡng chất có thứ tự cố
  định để không báo thay đổi chỉ vì thứ tự key trong map khác nhau.
- Validation chất xơ trong form thống nhất với model: tối đa 100 g/100 g.
- Công thức và bữa ăn cũ tiếp tục dùng snapshot tại thời điểm xác nhận;
  sửa/xóa nguồn không viết lại lịch sử.

## File chính

- `lib/features/food_library/presentation/library_forms.dart`
- `lib/features/food_library/presentation/food_library_screen.dart`
- `lib/features/food_library/presentation/delete_library_entry_dialog.dart`
- `lib/features/food_library/models/ingredient_selection.dart`
- `test/food_library_quality_test.dart`
- `test/food_library_test.dart`
- Tài liệu tiến độ và báo cáo kiểm thử.

## Kiểm thử đã chạy

- Format feature food_library và hai file test: không còn thay đổi format.
- `flutter analyze --no-pub`: không có vấn đề.
- Suite thư viện: **52/52 qua**, gồm **14 regression mới**. Có kiểm tra
  Back/Hủy, tiếp tục nhập, sửa chỉ nguyên liệu, giữ độ chính xác, xóa chờ
  ACK/lỗi/thử lại, chống gửi lặp và logout khi đang xóa/chọn khẩu phần.
- `flutter test --no-pub`: **1.071/1.071 qua**. Chạy lại toàn bộ sau điều
  chỉnh trạng thái nút trong hộp xóa; kết quả cuối cùng nằm ở log `final`.
- Preview với font Inter và icon thật **2/2 qua**, 390 px sáng 100% và
  320 px tối 200%. Đã xem tám ảnh: xác nhận xóa, chờ máy chủ, lỗi/thử lại,
  xác nhận bỏ thay đổi ở cả hai cấu hình; không có overflow.
- `flutter build apk --debug --no-pub`: thành công, 31 giây. Cảnh báo
  plugin KGP hiện hữu vẫn còn; chưa nâng package ngoài phạm vi.
- `node tool/audit_source_secrets.cjs`: không có phát hiện theo bộ mẫu;
  không phải kiểm toán credential store hoặc APK.
- `git diff --check`: qua; Git có cảnh báo chuyển LF/CRLF ở file hiện hữu.

Hai lỗi trung gian của test mới do finder khớp cả chip ở màn hình bên dưới
và chip trong picker. Đã giới hạn finder theo IngredientPicker, giữ nguyên
assertion nghiệp vụ và chạy lại. Analyzer ban đầu có cảnh báo dấu ngoặc/
null-aware đã sửa. Không bỏ test để che lỗi.

Log trong `build/`: `library-quality-focused-final.log`,
`library-quality-all-flutter-tests-final.log`, `library-quality-analyze-final.log`,
`library-quality-preview-final.log`, `library-quality-apk.log`.
Preview/harness ở `build/library-quality/`, có nhãn dữ liệu fixture;
không dùng fixture trong luồng sản phẩm thật.

APK debug: `build/releases/healthmate-food-library-20261108-debug.apk`.
Kích thước **237.530.258 byte**. SHA-256:
`0708309EFAA0A1176AB34ABB46B05E9B7EE3FA466C1BFBEFA56307CD0352D462`.
Manifest JSON cùng tên ghi trạng thái build/triển khai.

## Giới hạn và việc tiếp theo

- Không cần cấu hình Firebase mới; cần cài APK cập nhật để dùng thay đổi.
  Chưa nghiệm thu Android thật, ký release hoặc triển khai production.
- Draft chỉ được bảo vệ trong bộ nhớ khi form còn mở. Không hứa khôi phục
  bản chưa lưu sau khi hệ điều hành tắt tiến trình hoặc app bị đóng hẳn.
- Kiểm tra nguyên liệu dùng trạng thái stream mới nhất mà app đã nhận,
  không tạo transaction nguyên tử xuyên danh mục/thư viện/form. Không thể
  biết thay đổi chưa truyền tới thiết bị. Cache thư viện vẫn giữ cảnh báo
  hiện hữu; không bổ sung một lần đọc mạng cho mỗi nguyên liệu.
- Regression dùng boundary giả lập để điều khiển lỗi/thời điểm ACK/đổi
  phiên; không coi đó là nghiệm thu mạng hoặc máy chủ trên Android thật.
- Bước tiếp theo đề xuất: nghiệm thu thao tác thư viện trên thiết bị khi
  chủ dự án sẵn sàng. Chưa tự thực hiện.
