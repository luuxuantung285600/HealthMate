# 11/11/2026 — Giai đoạn 1 bổ sung: nhóm nội dung và khung bo nhẹ

> Bản ghi lần chỉnh trước. Theo phản hồi tiếp theo của người dùng, kiểu khung
> và bộ icon được điều chỉnh tiếp; xem [phosphor-ui-2026-11-11.md](phosphor-ui-2026-11-11.md).

## Phạm vi

Hoàn thiện giao diện Flutter theo yêu cầu bọc các cụm thông tin và thao tác
trong khung rõ ràng, bo góc nhẹ. Giữ font Public Sans, thanh điều hướng hiện tại,
dữ liệu thật và các hành vi đang có. Không sửa backend, Rules hoặc danh mục.

## Thay đổi

- `AppInsetPanel`: nhóm nội dung tĩnh, góc 12 px, viền 1 px theo theme và padding
  mặc định 12 px. Không thêm thao tác hoặc gộp semantics của các nút con.
- Card dùng viền mảnh; bộ lọc dạng chip bo 12 px, có viền và nền phân biệt
  trạng thái chọn. Theme Trang chủ dùng đúng màu trung tính đen/trắng.
- Trang chủ: nhóm chọn ngày, cụm calo và các chỉ số có khung; các ô chỉ số có nền
  riêng; nút báo cáo bo 12 px và vùng chạm tối thiểu 48 px. Hai bảng dưỡng chất
  và các nút chuyển bảng nằm trong cùng một card, tránh khung lồng trùng nhau.
- Nhật ký: nhóm chuyển ngày/ngày đang chọn. Tiến độ: nhóm thời gian, điều hướng
  tuần và thông báo lỗi/thử lại; các nút phân đoạn tối thiểu 48 px và thể hiện
  trạng thái được chọn cho trình đọc màn hình.
- Tập luyện: nhóm bộ lọc, thông tin thời lượng/số động tác, nhịp tập và chuẩn bị.
  Thực phẩm: nhóm thanh bộ lọc với nút mở toàn bộ nhóm; giữ cuộn ngang và tự
  đưa nhóm đã chọn vào vùng nhìn thấy.
- Các nhóm dùng Wrap/scroll và chiều cao theo nội dung để hỗ trợ chữ lớn.

## File chính

- `lib/core/theme/{app_spacing,app_theme,home_palette}.dart`
- `lib/core/widgets/{app_card,app_inset_panel,reference_segments}.dart`
- `lib/features/dashboard/presentation/widgets/{home_day_selector,mfp_calories_card,home_macro_panel,home_nutrient_panels}.dart`
- `lib/features/journal/presentation/journal_date_selector.dart`
- `lib/features/progress/presentation/progress_screen.dart`
- `lib/features/activity/presentation/workouts_screen.dart`
- `lib/features/nutrition/presentation/food_browse_filter.dart`
- `test/home_reference_test.dart`: bổ sung ảnh chụp phần dưới trong vòng kiểm
  thử hiện có; không thay fixture hoặc giảm assertion nghiệp vụ.

## Kiểm thử

- `dart format` và kiểm tra lại `--output=none --set-exit-if-changed`: 15 file
  qua, lần kiểm tra cuối không có file cần định dạng lại.
- Nhóm kiểm thử Home, dưỡng chất, icon/navigation, Progress, bộ lọc thực phẩm,
  workout và timeline: 130/130 qua, exit 0 (22 giây). Bao gồm kích thước
  320/360/390/412 px, scale đến 2× và sáng/tối theo các suite hiện có.
- `flutter test --no-pub --reporter json`: 1.289/1.289 qua, không lỗi/skip,
  exit 0, 136.846 ms. Giữ nguyên các assertion nghiệp vụ.
- `flutter analyze --no-pub`: không có vấn đề; lần đầu 12,1 giây, lần cuối
  sau thay đổi nút phân đoạn và ảnh chụp 11,8 giây, cả hai exit 0.
- `git diff --check` trên các file trong phạm vi: qua.
- Đã xem ảnh Home sáng/tối, chữ lớn 320 px, bảng dưỡng chất thứ hai và phần
  bữa ăn/nước uống. Ảnh nằm trong `build/home-reference/`; các ảnh Progress,
  Journal, Workout và bộ lọc tiếp tục được suite hiện có tạo ra.

Log: `build/rounded-ui-focused.log`, `rounded-ui-full-test.jsonl`,
`rounded-ui-test-summary.json`, `rounded-ui-analyze.log`,
`rounded-ui-analyze-final.log`.

## Cấu hình và giới hạn

Không cần cấu hình Firebase mới. Chạy hot restart nếu đang phát triển từ source;
APK cũ cần build/cài lại để nhận giao diện. Lượt này không build APK, deploy web
hoặc nghiệm thu điện thoại Android thật. Ảnh chụp widget test chỉ xác nhận bố cục
với fixture kiểm thử, không chứng nhận dữ liệu production hoặc thiết bị thật.

Giai đoạn tiếp theo đề xuất: nghiệm thu giao diện trên thiết bị khi được yêu cầu;
không tự chuyển sang triển khai tính năng khác.
