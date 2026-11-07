# Inter cho app và web admin — 06/11/2026

## Phạm vi và trạng thái

Giai đoạn tùy chọn 11, polish typography theo yêu cầu đổi sang Inter.
Hoàn tất source local cho cả Flutter app và web admin; chưa publish web,
build/cài APK hoặc nghiệm thu thiết bị thật. Không đổi nghiệp vụ/backend/
Rules, thêm dependency hoặc ghi dữ liệu production.

## Font và cấu hình

Inter v4.1 từ [release chính thức](https://github.com/rsms/inter/releases/tag/v4.1),
giữ nguyên file upstream; SIL Open Font License 1.1. Archive SHA-256 và
nguồn ghi tại [README font](../assets/fonts/inter/README.md).

- App: `assets/fonts/inter/Inter-{Regular,Medium,SemiBold,Bold}.ttf`,
  mapping weight **400/500/600/700** trong `pubspec.yaml`. Theme sáng/tối
  đều kế thừa `DesignTokens.fontFamily = 'Inter'`.
- Web: bốn WOFF2 cùng phiên bản, đóng gói tại `admin-web/dist/fonts/inter/`;
  `@font-face` khai báo đủ weight và `font-display: swap`. Body, nút, input,
  bảng và dialog kế thừa Inter. Server local hỗ trợ MIME `font/woff2`.
- Giấy phép đi cùng font ở cả hai thư mục; `LICENSE.txt` cũng là asset app.
  Không gọi Google Fonts hoặc dịch vụ font khác khi mở ứng dụng.
- Cập nhật FontLoader và đường dẫn trong **20 file test** để các kiểm thử
  bố cục dùng Inter thật; giữ nguyên assertions và các ca nghiệp vụ.
  File Be Vietnam Pro cũ được giữ trong source lịch sử, không còn khai báo
  font đó trong pubspec/theme/CSS hoặc test loader đang dùng.

File chính: `pubspec.yaml`, `lib/core/theme/design_tokens.dart`,
`admin-web/dist/style.css`, `admin-web/server.mjs`, hai thư mục font, các
test loader, README và tài liệu tiến độ/kiểm thử.

## Kiểm chứng thực tế

| Kiểm tra | Kết quả |
| --- | --- |
| `dart format lib/core/theme/design_tokens.dart test` | 104 file, 20 file được định dạng sau đổi đường dẫn |
| `flutter analyze --no-pub` | No issues found, 91,1 giây |
| `flutter test --no-pub --reporter json` | **944/944 qua**, 0 lỗi/bỏ qua; runner 111,865 giây |
| `npm --prefix admin-web run check` | Qua |
| `npm --prefix admin-web test` | **61/61 qua**, 0 lỗi/bỏ qua |
| Font TTF metadata/coverage | Đúng 400/500/600/700; đủ **187 codepoint** kiểm tra gồm chữ Việt, dấu ghép, số và ₫ |
| Server local, HEAD bốn WOFF2 | HTTP 200 và `Content-Type: font/woff2` |
| Chrome font loading/CDP | Đủ bốn face loaded; tiêu đề thực sự render bằng custom font **Inter SemiBold** |
| Browser 1440/1024/390/320 px | Không tràn ngang hoặc JS exception |
| App module thật + adapter QA local | 9 trang × 1440/390/320 px; drawer, dialog, login qua |
| Format kiểm tra cuối + `git diff --check` | 104 file, 0 thay đổi; diff qua |
| Source secret audit | 626 source text files, 0 findings; không quét APK/credential store |

SDK: Flutter 3.44.1/Dart 3.12.1 tại `D:/Flutter/flutter/bin/`. Không nâng
SDK hoặc dependencies. Không cần Firebase/emulator để kiểm typography.

Log, metadata và ảnh nằm ở `build/inter-font-20261106/`: `format.log`,
`analyze.log`, `flutter-test.jsonl`, `flutter-summary.json`, `admin-check.log`,
`admin-test.log`, `font-verification.json`, `server-font-check.log`, `browser.log`.
Đã xem ảnh web desktop, app đăng nhập và form 320 px/chữ 200%.

Ảnh web dùng lại snapshot Firebase chỉ đọc lúc **01:50:46 ngày 06/11 UTC+7**
từ lượt đổi theme: 3 tài khoản đăng ký, 0 giao dịch/0 VND Premium demo của
kỳ 01–06/11. Nhãn thời điểm vẫn giữ nguyên; không mô tả đây là lần đọc mới
hoặc số realtime. App screenshot là widget test để kiểm font/bố cục, không
phải nghiệm thu Android thật hoặc dữ liệu production.

## Cách xem và bước tiếp theo

Dừng rồi chạy lại app bằng F5 để nhận font asset mới. Web local tải lại
trang sau khi khởi động lại server nếu đang dùng tiến trình cũ. Không cần
cấu hình Firebase mới. Bản online chỉ đổi font sau rollout; bước tiếp theo
đề xuất là nghiệm thu giao diện dùng Inter và rollout khi được yêu cầu.
