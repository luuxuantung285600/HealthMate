# Nền đen và màu nhận diện — 11/11/2026

## Giai đoạn và kết quả

Giai đoạn 1, bảo trì UI theo yêu cầu. Hoàn thành mã nguồn và kiểm thử local.
Nền tối toàn app dùng đen #000000, thẻ xám than #121212 và các lớp nổi xám
trung tính; chế độ sáng vẫn nền trắng. Bỏ theme tím riêng của Trang chủ, dùng
chung AppTheme. Màu tím còn tiết chế ở AI/ngủ, không là màu điều khiển chính.

- Bữa sáng vàng hổ phách, trưa cam san hô, tối xanh dương, bữa phụ mint. Áp
  dụng vào icon, tên bữa, nút thêm và giờ bản ghi; nền giữ trung tính.
- Dinh dưỡng cam, nước xanh da trời, vận động mint, tập luyện san hô, cân nặng
  hồng, Tiến độ cyan, Quest/Premium vàng. Đồng bộ điểm vào, điều hướng và các
  biểu đồ liên quan. Macro dùng cùng màu giữa Trang chủ, Nhật ký và báo cáo.
- Nút thêm món/ghi nước có màu tương ứng; đường và vùng tô cân nặng cùng hồng.
  Không đổi logic phân loại bữa, ngày giờ, repository hoặc listener.

## File chính

- `lib/core/theme/`: app_theme, home_palette, reference_palette, app_colors,
  app_feature_visuals, app_meal_visuals, design_tokens.
- `lib/core/widgets/`: app_shell, tracking_page.
- Dashboard và mfp_calories_card, mfp_meal_card, dashboard_hero_section.
- Journal: hourly_meal_timeline, meal_summary_grid, journal_nutrition_overview,
  daily_log_section_card; các section nhật ký dinh dưỡng/nước/vận động.
- progress_overview, weight_chart, period_report_panel, weekly_reflection_card.

## Kiểm thử thực tế

- `dart format` các file đã sửa: qua.
- `flutter analyze --no-pub` toàn repo lần cuối: **No issues found**, exit 0,
  11,4 giây. Lượt đầu có một import trùng ở MfpCaloriesCard; đã bỏ và chạy lại
  sạch. Log: `build/black-ui-analyze.log`.
- 9 suite đầu: **139/139 qua**, exit 0, 26 giây: home_reference_test,
  journal_timeline_test, progress_test, reference_ui_test, icon_system_test,
  ui_readability_test, ux_progress_profile_test, ux_home_diary_test,
  home_secondary_nutrients_test. Log: `build/black-ui-tests.log`.
- Sau thay đổi cuối: 7 suite **79/79 qua**, exit 0, 22 giây: home_reference_test,
  journal_timeline_test, progress_test, daily_logs_test, dashboard_test,
  compact_ui_test, weekly_reflection_test. Log: `build/black-ui-final-tests.log`.
  Các ca trùng giữa hai lượt không tính là ca riêng.
- `git diff --check` vùng mã sửa: qua (chỉ cảnh báo đổi LF sang CRLF của Git).
- Đã xem ảnh render sáng/tối; các test hiện có kiểm nhiều chiều rộng, text
  scale tới 2. Không thấy overflow hoặc chữ mất tương phản ở ảnh đã xem.
  Ảnh mới: `build/home-reference/home-{dark,light}-meals-water.png`,
  `build/home-reference/home-{dark,light}.png`,
  `build/journal-timeline/{overview,foods}-dark-1.0.png`,
  `build/c5-layout/progress-dark-1.0.png`.
  Fixture chỉ nằm ở test; không thêm số liệu giả vào sản phẩm.

## Cần người dùng làm và giới hạn

- **Hot Restart** app đang chạy để nhận code/theme mới. Không cần cấu hình
  Firebase mới; Android đã cài cần chạy/build lại từ mã mới.
- Không deploy admin/Rules, không ghi production, không thêm dependency.
- Chưa build phát hành hoặc nghiệm thu Android thật; không chạy toàn bộ Flutter
  suite. Ảnh widget không thay thế kiểm tra thiết bị.
- Qua ảnh test thấy hai nhãn ngày `1/1` gần nhau ở mép phải biểu đồ cân nặng
  có timestamp trong cùng ngày. Vấn đề trục ngày sẵn có, chưa sửa trong phạm vi
  đổi màu; không ảnh hưởng giá trị dữ liệu.
- Đề xuất tiếp: nghiệm thu giao diện trên trình duyệt/thiết bị người dùng;
  không tự triển khai giai đoạn khác.
