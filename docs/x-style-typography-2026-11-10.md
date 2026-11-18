# 10/11/2026 — Typography theo phong cách X

## Phạm vi

Giai đoạn tùy chọn 11: đổi font giao diện HealthMate và web admin theo yêu
cầu người dùng. Phần tìm GIF tập luyện tiếp tục tạm gác.

X có font Chirp được thiết kế riêng. HealthMate dùng **Public Sans**, một
font miễn phí được chọn để tạo phong cách chữ tương tự; không gọi Public
Sans là Chirp và không sao chép file font từ X.

## Thay đổi

- Flutter dùng Public Sans qua `DesignTokens.fontFamily` và `AppTheme` cho
  cả sáng/tối. Giữ cỡ chữ, độ đậm, màu và bố cục hiện có.
- Bốn file TTF gốc 400/500/600/700 được khai báo trong `pubspec.yaml`.
  Kiểm tra cmap bằng fontTools: mỗi file đủ 134 ký tự tiếng Việt có dấu
  dạng dựng sẵn, gồm Đ/đ, Ă/ă, Â/â, Ê/ê, Ô/ô, Ơ/ơ và Ư/ư.
- Web admin dùng bốn file WOFF2 gốc của cùng upstream, với font-display
  swap. Form và nút tiếp tục kế thừa font giao diện.
- Font và giấy phép được đóng gói cùng app/web; không thêm package,
  dịch vụ tải font hoặc yêu cầu billing.
- 30 file kiểm thử giao diện dùng font mới để kiểm tra bố cục thực;
  chỉ đổi font loader và format, giữ các assertion nghiệp vụ.
- Browser QA admin chờ tải đủ cả bốn độ đậm và xác nhận font đã load,
  đồng thời giữ kiểm tra sidebar, form, nút, theme và tràn ngang.
- Tệp Inter cũ vẫn được giữ làm nguồn lịch sử; không đăng ký làm font
  giao diện trong pubspec/CSS. Font trong nội dung xuất XLSX giữ nguyên.

## Nguồn và giấy phép

- Upstream: https://github.com/uswds/public-sans
- Commit: `c7923167a592d941646f99fb7b5fba17aa7d69e1`.
- Font, tác giả và SIL OFL 1.1: `assets/fonts/public_sans/README.md`,
  `OFL.txt` và `manifest.json`. Web có bản giấy phép riêng.
- Manifest ghi URL gốc, số byte và SHA-256 cho cả tám font. Đã đối chiếu
  checksum sau khi tải; không sửa dữ liệu nhị phân của font.

## File chính

`lib/core/theme/design_tokens.dart`, `pubspec.yaml`,
`assets/fonts/public_sans/`, `admin-web/dist/style.css`,
`admin-web/dist/fonts/public_sans/`, `admin-web/dist/appearance.css`,
`admin-web/test/browser-identity.cjs`, README app/admin và các font loader
trong kiểm thử giao diện.

Kết quả kiểm thử/build cuối lượt được ghi trong `test-report.md` và
`implementation-progress.md`.
