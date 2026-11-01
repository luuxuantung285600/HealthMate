# Thu gọn giao diện theo dõi dinh dưỡng — 01/11/2026

## Phạm vi

Giai đoạn 11: chỉnh giao diện theo phản hồi màn hình quá nhiều thông tin,
thao tác rối. Giữ code và chức năng đang có trong workspace, bao gồm những
thay đổi Auth/UX đã có trước lượt này. Không thêm package hoặc thay schema,
Security Rules, hạn mức AI, cấu hình production.

## Hành vi sau khi chỉnh

- **Hôm nay:** ưu tiên kcal còn lại, lượng đã ăn, mục tiêu và ba chất chính.
  Tiếp theo là nút thêm bữa và bốn hàng bữa ăn gọn. Không còn cụm lối tắt
  lớn hoặc hướng dẫn lặp lại phía trên nhật ký. Chi tiết mục tiêu, thể trạng
  và tổng kết chỉ tải khi mở **Xem thêm**.
- **Điều hướng:** Hôm nay, Nhật ký, **+ Thêm món**, Tiến độ, Cá nhân.
  Nút giữa mở thẳng form thêm món, giữ ngày đang chọn ở Hôm nay/Nhật ký.
  Các tiện ích thói quen vẫn mở từ Cá nhân.
- **Nhật ký:** một danh sách theo bữa, bỏ bảng tóm tắt lặp lại phía trên.
  Dòng món hiển thị tên, khẩu phần, giờ và kcal; chạm dòng để sửa. Sửa,
  sao chép và xóa vẫn có trong menu. Nháp chuyển lên tiêu đề; vận động
  mở khi cần. Nút hoàn tất nhật ký dùng được cho cả ngày cũ.
- **Thêm món:** chuyển cách nhập lên đầu, ngày và bữa trên cùng một hàng;
  tìm món nằm gần đầu màn hình. Nút lưu cố định cho biết số món và tổng kcal.
  Danh sách đã chọn có thể mở để xem/sửa khẩu phần. Mã vạch, nhập nhanh kcal
  và bộ lọc nằm trong **⋯ → Tùy chọn thêm món**. Nguồn dinh dưỡng ở chi tiết
  khẩu phần; vẫn giữ nhãn ước tính và tình trạng thiếu dưỡng chất ở danh sách.
- **Hướng dẫn:** mở theo yêu cầu; giữ thông báo lỗi, cảnh báo thực phẩm cần
  tránh, xác nhận ảnh và quy trình lưu/khôi phục nháp.
- **Quay lại và đồng bộ:** từ chi tiết thói quen quay lại danh sách thói quen,
  rồi trở về Cá nhân. Sửa/xóa cân nặng từ Cá nhân cập nhật lại Tiến độ.

## File chính

- `lib/core/widgets/app_shell.dart`, `profile_avatar.dart`.
- `lib/features/dashboard/presentation/dashboard_screen.dart`,
  `widgets/mfp_calories_card.dart`, `mfp_macros_card.dart`, `mfp_meal_card.dart`.
- `lib/features/journal/presentation/journal_screen.dart`.
- `lib/features/nutrition/presentation/meal_form_dialog.dart`,
  `meal_entry_sources.dart`, `meal_log_section.dart`.
- `lib/features/food_library/presentation/meal_food_sources.dart`,
  `food_portion_dialog.dart`.
- `lib/features/profile/presentation/profile_screen.dart`.
- `lib/features/wellness/presentation/wellness_screen.dart`, `wellness_hub.dart`.
- Các kiểm thử điều hướng/nhật ký/form được cập nhật theo vị trí nút mới,
  giữ kiểm tra ngày, khẩu phần, UID, lỗi mạng, retry và chống lưu trùng.

## Bằng chứng giao diện

[Xem ảnh trước/sau và màn hình thêm món](ux/nutrition-simple-2026-11-01/index.html).
Ảnh dựng từ widget thật với dữ liệu kiểm thử cố định ở 390×844, phông chữ
Be Vietnam Pro. Đây không phải ảnh chụp từ điện thoại hoặc dữ liệu tài khoản
thật. Kiểm thử bố cục còn kiểm tra rộng 320/390/412 và tỷ lệ chữ 1/1,5/2,
giao diện sáng/tối.

## Kiểm tra và giới hạn

Kết quả cuối được ghi tại `docs/test-report.md` và
`docs/implementation-progress.md`. Log chi tiết lưu ở `build/nutrition-ui-*`.
Các lần kiểm tra đầu phát hiện test còn dùng menu cũ và key Cá nhân trùng;
đã sửa vị trí điều hướng/test theo UI mới và tách key avatar/tab. Kiểm tra
cũng phát hiện thiếu làm mới Tiến độ sau khi sửa cân từ Cá nhân; đã sửa.

Không cài/chạy lại luồng trên Android theo lựa chọn người dùng tự test.
Không build APK trong lượt này. Để xem giao diện mới, hot restart phiên Flutter
đang chạy, hoặc chạy lại cấu hình dự án trong VS Code. Không cần cấu hình
Firebase thủ công cho thay đổi UI này.

Chưa commit/push GitHub hoặc deploy trong lượt này. Không tắt laptop.
Bước tiếp theo đề xuất: người dùng tự kiểm tra giao diện Android và phản hồi
màn hình cụ thể cần tinh chỉnh; chưa triển khai thêm giai đoạn/tính năng.
