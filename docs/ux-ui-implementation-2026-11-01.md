# Cải thiện UX/UI HealthMate — 01/11/2026

Phạm vi: toàn bộ `HealthMate-UX-UI-implementation-prompt.md`, theo yêu cầu
triển khai trong một lượt. Baseline là `main@46dccf642f4dff8b51b31cc044f1a1b46cf9a1c2`.
Báo cáo re-audit tùy chọn không có tại đường dẫn Downloads đã cung cấp.

## Định hướng và hành vi đã sửa

- Nền trung tính, surface rõ, xanh lá cho hành động chính; bỏ gradient nhiều
  màu trên canvas. Giữ font Be Vietnam Pro có hỗ trợ tiếng Việt, dùng token
  hiện có. Carb/Đạm/Chất béo thống nhất tên và màu, vẫn có giá trị/nhãn chữ.
- Hôm nay: tóm tắt năng lượng gọn, nút **Thêm bữa ăn** cùng ngày đích ở đầu.
  Nhật ký: bữa trống có nút thêm đúng loại bữa; xác nhận đủ bữa là hành động
  phụ. Ngày đang xem được giữ qua Ghi nhanh, form và thao tác lưu.
- Người mới có thể chọn **Cá nhân hóa sau** ngay màn đầu để ghi nhật ký,
  không tạo mục tiêu kcal hoặc điền dữ liệu cơ thể thay người dùng. Tám phần
  cá nhân hóa đầy đủ vẫn là lựa chọn bổ sung; không đổi quy tắc hoàn thành
  hồ sơ hợp lệ ở Firestore. Lựa chọn bỏ qua được giữ theo UID trong phiên;
  đăng xuất/đổi tài khoản đặt lại lựa chọn này.
- Nháp thiết lập lưu nội dung và bước trong envelope mã hóa riêng theo UID,
  dùng cùng hàng đợi với nháp bữa ăn. Hai loại nháp không ghi đè nhau.
  Ngày sinh hiển thị dd/MM/yyyy. Calculator dẫn tới phần thiếu rồi trở lại.
  Quyền riêng tư đọc được trước đăng nhập và quay lại giữ nội dung form.
- Phân tích ảnh và mã vạch tách riêng. Backend ảnh hiện chưa sẵn sàng:
  thông báo trước khi khởi tạo camera, mở picker hoặc xin consent; có đường
  chuyển sang mã vạch/tìm món/nhập thủ công. Không bật lại AI trực tiếp hay
  thay hạn mức. Các kiểm thử camera khả dụng dùng service giả lập riêng.
- Form bữa ăn: giữ món/khẩu phần khi đổi nguồn nhập; nút **Lưu bữa ăn** rõ
  ở cuối màn; mã vạch dễ tìm, bộ lọc mở khi cần. Đóng khi có private storage
  chờ giữ nháp thành công; nếu giữ thất bại, form và lỗi được giữ kể cả tab
  Ảnh. Nền tảng chưa hỗ trợ nháp chỉ hỏi bỏ thay đổi khi form đã thay đổi.
  Back và nút đóng dùng cùng quy trình phục hồi.
- Tiến độ còn ba tác vụ Tổng quan/Dưỡng chất/Thói quen. Biểu đồ có đơn vị,
  mốc trục Y, ngày, tooltip và số ngày có dữ liệu; ngày thiếu để khoảng trống,
  số 0 đã ghi vẫn là dữ liệu. Giữ kỳ báo cáo, chi tiết và xuất dữ liệu.
- Cá nhân ưu tiên hồ sơ, mục tiêu, tài khoản, quyền riêng tư và hỗ trợ;
  bỏ các tóm tắt hằng ngày trùng Dashboard. Báo cáo tải khi mở; kiểm thử giữ
  việc hủy/khôi phục listener khi chuyển màn.

## File chính

| Nhóm | File/thư mục |
| --- | --- |
| Theme/điều hướng | `lib/core/theme/`, `core/widgets/app_shell.dart`, `core/router/` |
| Hôm nay/Nhật ký | `features/dashboard/presentation/`, `features/journal/presentation/` |
| Thiết lập | `profile/presentation/onboarding_screen.dart`, `models/onboarding_progress.dart`, `providers/onboarding_deferred_provider.dart` |
| Quyền riêng tư | `auth/presentation/auth_screen.dart`, `profile/presentation/account_information_screen.dart` |
| Nháp/form | `meal_drafts/data/meal_draft_store.dart`, `nutrition/presentation/meal_form_dialog.dart`, `meal_form_controller.dart` |
| Phân tích ảnh | `food_scanner/data/food_scanner_service.dart`, `providers/food_scanner_providers.dart`, `presentation/food_scanner_dialog.dart` |
| Tiến độ/Cá nhân | `progress/presentation/`, `profile/presentation/profile_screen.dart`, `personal_overview.dart`, `weight_chart.dart` |
| Báo cáo | `reports/presentation/period_report_panel.dart`, `weekly_reflection/presentation/weekly_reflection_card.dart` |

Đường dẫn nhóm feature trong bảng thuộc `lib/features/`.
Không thêm package, database, dịch vụ hoặc assets từ repository tham khảo.

## Bằng chứng hình ảnh

[Mở đủ 5 cặp ảnh trước/sau](ux/2026-11-01/index.html).
Ảnh gốc: [trước](ux/2026-11-01/before/) và [sau](ux/2026-11-01/after/).

| Màn hình | Ảnh ghép trước/sau |
| --- | --- |
| Home | [Hôm nay](ux/2026-11-01/home-comparison.png) |
| Diary | [Nhật ký](ux/2026-11-01/diary-comparison.png) |
| Onboarding | [Thiết lập](ux/2026-11-01/onboarding-comparison.png) |
| Meal form | [Form bữa ăn](ux/2026-11-01/meal-form-comparison.png) |
| Progress | [Tiến độ](ux/2026-11-01/progress-comparison.png) |

Các màn: Home, Diary, Onboarding, Meal form, Progress. Cùng viewport
390×844, text scale 1, theme sáng; font thật từ assets. Cùng fixture
28/10/2026, bữa cơm 150 g, mục tiêu 2.000 kcal, hai lần cân và dữ liệu ngày
trước. Nhãn nguồn và cờ ước tính trong fixture được giữ nguyên.

Baseline được giải nén từ Git archive, chỉ thêm cùng harness
`test/ux_capture_test.dart`; chạy riêng khỏi source đang chỉnh. Đây là ảnh
widget với repository giả lập, **không phải bằng chứng Android native hoặc
Firebase production**. Các PNG nguyên bản không chỉnh sửa nội dung;
ảnh ghép chỉ thêm nhãn trước/sau. Hash/metadata có trong
[manifest.json](ux/2026-11-01/manifest.json).

## Kiểm tra

Kết quả tổng hợp cuối ghi ở [test-report.md](test-report.md). Các test mới:

- `ux_home_diary_test.dart`: CTA, ngày đích, lưu thật qua fake repository,
  trạng thái lỗi không biến thành 0; 18 cấu hình màn hình/chữ/theme.
- `ux_onboarding_test.dart`: bỏ cả nhóm tùy chọn, nháp/UID/xóa dữ liệu,
  khôi phục bước, quyền riêng tư trước Auth, calculator, Back; 18 cấu hình.
- `ux_meal_recovery_test.dart`: ảnh unavailable không mở camera/consent,
  giữ món, Back/close, lỗi giữ nháp rồi thử lại, trả kết quả khi không có
  callback lưu; 18 cấu hình có bàn phím và đổi nguồn nhập.
- `ux_progress_profile_test.dart`: khoảng trống khác số 0, trục/đơn vị,
  lịch sử và thao tác Profile; 18 cấu hình cho mỗi nhóm.
- `ux_capture_test.dart`: cùng fixture xuất 5 ảnh, phát hiện lỗi render.

Ma trận: rộng 320/390/412 px × text scale 1/1,5/2 × sáng/tối. Khi nội dung
vượt viewport do chữ lớn, cho cuộn để tiếp cận thay vì thu nhỏ chữ.
Các assertion nghiệp vụ về lưu ACK, chống ghi trùng, nguồn/khẩu phần,
dị ứng, UID và vòng đời listener vẫn được giữ. Một số selector kiểm thử
cũ được đổi theo nhãn nút mới, bộ lọc mở rộng và ngày Ghi nhanh nhất quán.

## Giới hạn và thao tác còn lại

- Chưa chạy nghiệm thu Android, TalkBack, bàn phím hệ thống hay build APK
  trong lượt này; người dùng đã chọn tự test thiết bị. Kiểm tra bàn phím
  ở đây dùng widget test với viewInsets mô phỏng.
- Private storage mã hóa chỉ có trên nền tảng được triển khai sẵn (Android).
  Nền tảng khác hiển thị giới hạn và xác nhận khi bỏ form đã thay đổi.
- Tám phần cá nhân hóa đầy đủ còn được giữ để tương thích nghiệp vụ; luồng
  tối thiểu đến Nhật ký chỉ cần một màn và nút bỏ qua toàn nhóm.
- Backend ảnh, signed release và các blocker production trước đó không
  nằm trong việc sửa UX này. Chưa thay Rules, deploy, migration, production
  data, commit/push hoặc lên lịch tắt laptop.
- Bước tiếp theo đề xuất: chủ dự án nghiệm thu Android bằng dữ liệu thử,
  kiểm tra thao tác chạm/Back/TalkBack và cấu hình bàn phím thực tế.
