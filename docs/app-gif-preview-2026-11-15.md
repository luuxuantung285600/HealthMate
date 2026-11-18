# Xác nhận GIF hiển thị trong app — 15/11/2026

Người dùng yêu cầu kiểm tra và xem ảnh. Không sửa mã sản phẩm hoặc phát hành
APK/web trong lượt này. Dùng đúng `WorkoutsScreen` mở `ExerciseLibraryScreen`,
`AppTheme` và `ExerciseDbService` đang có trong repository.

Harness local nằm trong `build/app-gif-review-20261115/main.dart`: chỉ override
stream thư viện bằng 50 bản ghi bundled hiện có để xem độc lập, không khởi tạo
Firebase hoặc đọc/ghi hồ sơ. Service GIF giữ nguyên, không có media giả, không
tải GIF vào assets. Bản debug đáp ứng lựa chọn kiểm thử phi thương mại đã chốt.

Lệnh đã chạy:

```powershell
flutter build web --debug --target build/app-gif-review-20261115/main.dart --output build/app-gif-review-20261115/web --no-pub --no-web-resources-cdn
node build/app-gif-review-20261115/capture.cjs
```

- Build exit 0, 140,7 giây. Có cảnh báo dry-run Wasm của `mobile_scanner`
  (`dart:html`/`package:js`); bản JavaScript được build thành công. Không nâng
  package hoặc sửa scanner vì ngoài yêu cầu xem GIF.
- Chrome headless profile riêng, server loopback, viewport 430×1060. GIF thật
  trên danh sách tải hoàn tất: `I4hDWkc`, `ZOuKWir`, `NCmbLCw`; metadata và GIF
  đều HTTP 200, 180×180. Chỉ có 3 request metadata cho phần danh sách hiển thị.
- Ảnh đã xem: `build/app-gif-review-20261115/tap-luyen-gif-dark.png`, có tên bài,
  nhóm cơ, bộ lọc, tổng 50 động tác và nút **Tạm dừng GIF**. Không dùng ảnh fixture
  3 px hoặc ảnh web admin làm bằng chứng cho màn app.
- Lần capture đầu bằng emulated mobile viewport có assertion debug từ Flutter
  engine khi xử lý kích thước bàn phím. Chuyển harness sang viewport desktop
  hẹp cùng kích thước, không đổi app; capture lại exit 0, **0 JS exception**,
  3 GIF tải hoàn tất. `capture.log` ghi lần đầu; `capture-rerun.log` và
  `capture-report.json` ghi lần cuối.

Đây là ảnh chụp widget thực chạy trong bản kiểm thử Flutter trên Chrome, không
phải ảnh thiết kế hoặc kết quả nghiệm thu Android vật lý. Không xác nhận mọi
GIF trong 50 bài. GIF miễn phí vẫn debug-only, có mạng; release thương mại
chưa bật nguồn miễn phí. Bản APK/app đang cài cũ cần được cập nhật để nhận code.

Không chạy lại toàn bộ analyze/test vì không sửa mã sản phẩm. Lần kiểm này
chỉ gồm build debug và xác minh mạng/render thực tế, không kế thừa số test cũ
như kết quả mới. Không thay dữ liệu Firebase, billing, Rules hoặc Git.
