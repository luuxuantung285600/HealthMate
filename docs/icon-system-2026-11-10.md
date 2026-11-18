# Bộ icon HealthMate — 10/11/2026

> Bản ghi lịch sử. App đã thay Lucide bằng Phosphor 2.1.2 ngày 11/11/2026;
> xem [phosphor-ui-2026-11-11.md](phosphor-ui-2026-11-11.md). Admin giữ nguồn
> Lucide riêng; các lệnh kiểm tra font app hiện dùng manifest Phosphor.

Giai đoạn tùy chọn 11: hoàn thiện giao diện theo yêu cầu đổi bộ icon toàn app.

## Kết quả

- Thống nhất các icon do HealthMate khai báo trong `lib/` sang Lucide: nét
  bo tròn, cùng độ dày, rõ ở cỡ 16–26px. Áp dụng cho đăng nhập, câu hỏi ban
  đầu, Trang chủ, nhật ký, chọn món, scanner, tập luyện, mục tiêu, chatbot,
  hồ sơ, hỗ trợ, Premium và báo cáo.
- Điểm vào tính năng dùng hình riêng kèm màu ổn định: dinh dưỡng cam,
  nước xanh dương, tập luyện chàm, AI tím, mục tiêu xanh lá, Premium vàng.
  Thẻ chỉ số và lối tắt dùng chung bảng nhận diện sáng/tối.
- Thanh điều hướng giữ nhãn tiếng Việt; tab đang mở có nền hình viên thuốc,
  trạng thái selected cho trình đọc màn hình và vùng chạm tối thiểu 48px.
  Nút thêm món và các thao tác hiện có giữ hành vi thật.
- Đạm dùng hình thực phẩm, tinh bột dùng bông lúa, chất béo dùng giọt;
  phần tập luyện dùng tạ. Icon cân nặng dùng ký hiệu quả cân thay vì cân
  công lý. Các lối tắt thói quen thay ảnh mini cũ bằng cùng bộ nét.
- Font chữ vẫn là Inter. Icon được đóng gói offline, không tải từ mạng
  khi sử dụng và không thêm Flutter dependency.

## Nguồn và bản quyền

- [Lucide Static 1.70.0](https://www.npmjs.com/package/lucide-static/v/1.70.0),
  tải từ bản phát hành npm và ghim SHA-256 trong manifest.
- 119 glyph khác nhau, 138 tên hằng/alias; font subset **47.284 byte**.
- Giấy phép ISC và MIT cho phần kế thừa Feather được giữ đầy đủ trong
  `assets/fonts/healthmate_icons/LICENSE.txt`, đi kèm APK.
- Manifest ghi nguồn, codepoint, hash font và ánh xạ các tên Material cũ.
  `tool/build_app_icons.py --verify` kiểm hash, glyph có nét, registry Dart,
  giấy phép và không còn tham chiếu trực tiếp `Icons.*` trong mã sản phẩm.
- Dùng `IconData` hằng để tương thích quy trình đóng gói Flutter; không
  tạo bảng tra icon động trong luồng sản phẩm.

## File chính

- `lib/core/theme/app_icons.dart`: registry và alias theo ý nghĩa.
- `lib/core/theme/app_feature_visuals.dart`, `app_colors.dart`: hình/màu nhận diện.
- `lib/core/widgets/feature_icon_badge.dart`, `icon_chip.dart`: khung icon.
- `lib/core/widgets/app_shell.dart`: điều hướng và trạng thái đang chọn.
- Profile, wellness, Home và thẻ món: điểm vào tính năng và dưỡng chất.
- Các presentation widget còn lại: migrate icon, giữ callback và nhãn.
- `assets/fonts/healthmate_icons/`, `pubspec.yaml`: font và giấy phép offline.
- `tool/build_app_icons.py`: tái tạo subset từ font upstream đã xác minh.
- `test/icon_system_test.dart`, `test/support/load_icon_font.dart`: kiểm
  điều hướng, khả năng truy cập và render font thật. Các test chụp giao diện
  hiện có được nạp thêm font icon để ảnh kiểm tra không thành ô vuông.

## Kiểm chứng đã chạy

- `flutter analyze`: sạch, exit 0; lần cuối 16,9 giây.
- `flutter test`: **1.217/1.217 qua**, exit 0, 2 phút 12 giây;
  log `build/icon-system/full-tests.log`.
- Nhóm icon/Home/food detail/MFP: **34/34 qua**. Kiểm 320/390px, chữ
  100/200%, sáng/tối, chuyển bốn tab, selected semantics, vùng chạm và mở
  thêm món. Kiểm tương phản icon badge ít nhất 3:1 và giữ test nhãn chỉ số
  ít nhất 4,5:1.
- Sau khi chốt màu icon Home theo nhận diện chung và màu trung tính của
  icon nền sáng/tối, chạy lại nhóm **34/34 qua**, exit 0, 10 giây;
  `build/icon-system/focused-final.log`. Lượt toàn bộ 1.217 test ở trên chạy
  trước chỉnh màu cuối; các chỉnh cuối chỉ thay màu icon.
- `python tool/build_app_icons.py --verify`: qua, đủ 119 glyph/138 tên,
  đúng hash và giấy phép; đã xem ảnh render toàn bộ 119 glyph.
- Đã xem ảnh render Home, menu Cá nhân, bộ icon sáng/tối và màn chọn món.
  Preview: `build/icon-system/preview-20261110.jpg`.
- `dart format` các file liên quan: lần cuối 103 file/0 đổi; `git diff
  --check` sạch, exit 0.
- `flutter build apk --debug --no-pub --dart-define-from-file=...`: qua,
  exit 0, 14,8 giây. Dùng cấu hình debug riêng hiện có, không đưa nội dung
  cấu hình vào tài liệu/log.
- Bản cài `build/releases/healthmate-icons-20261110-debug.apk`; kiểm ZIP:
  font đúng hash, giấy phép khớp nguyên bản, family đăng ký đúng trong
  FontManifest. Kết quả `build/icon-system/apk-verification.json`.
- Build hiện có cảnh báo từ Flutter về các plugin đang dùng KGP và khả
  năng tương thích với Flutter tương lai; build hiện tại thành công.
- Hai lần kiểm thử đầu phát hiện lỗi trong harness mới: so sánh selected
  với bool thay vì `Tristate` và giải phóng semantics handle quá muộn.
  Đã sửa vòng đời/kiểu assertion; giữ nguyên kiểm chứng hành vi.

## Sử dụng và giới hạn

Cần chạy lại app hoặc cài APK mới để nhận font asset. Không cần cấu hình
Firebase. Icon trong bộ chọn ngày/nút hệ thống do Flutter hoặc Android
quản lý vẫn theo nền tảng. Logo khởi chạy và nhận diện Google giữ nguyên.

Chưa nghiệm thu trên điện thoại thật hoặc ký bản phát hành. Không push Git
hay deploy trong lượt này. Bước tiếp theo chỉ đề xuất: kiểm tra trực quan
trên Android thật khi người dùng yêu cầu.
