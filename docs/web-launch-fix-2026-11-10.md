# Sửa cấu hình chạy app web — 10/11/2026

Giai đoạn 10, sửa lỗi khởi chạy. Hoàn tất cấu hình và kiểm tra khởi động.

## Nguyên nhân và thay đổi

Ảnh lỗi cho thấy VS Code chạy task `HealthMate: prepare Android debug` và
dừng vì thiếu `%LOCALAPPDATA%/HealthMate/app-check-debug-token.txt`. Cấu hình
cũ có tên chung “HealthMate App (Flutter)” nhưng luôn chạy bước chuẩn bị
Android, kể cả khi thiết bị được chọn là Chrome/Edge. Flutter chưa được
khởi chạy trong trường hợp này.

Đã thêm hai cấu hình Dart có `deviceId` rõ ràng:

- **HealthMate App (Web - Chrome)**: `chrome`.
- **HealthMate App (Web - Edge)**: `edge`.

Hai mục web nạp `config/chat-api.json` và `config/admin-runtime.json` trực
tiếp, không dùng preLaunchTask hoặc file token Android. Mục Android được
đổi tên thành **HealthMate App (Android)** và giữ bước chuẩn bị riêng.
Không sửa Firebase bootstrap, App Check, Rules hoặc dịch vụ production.

## Cách chạy

Trong VS Code: mở Run and Debug, chọn một trong hai mục Web rồi nhấn F5.
Cấu hình web mới nằm trước mục Android để tránh lựa chọn mặc định nhầm.
Nếu chọn Android, cần thiết bị/emulator và cấu hình Android như trước.

Từ terminal tại gốc repository:

```powershell
flutter run -d chrome --dart-define-from-file=config/chat-api.json --dart-define-from-file=config/admin-runtime.json
```

Có thể thay `chrome` bằng `edge`. Các mục HealthMate Admin vẫn mở website
quản trị riêng, không phải bản web của Flutter app.

## File chính

- `.vscode/launch.json`: hai mục web và tên Android rõ nền tảng.
- `tool/prepare_vscode_android.test.cjs`: thêm kiểm tra hồi quy hai launcher
  web không gọi bước chuẩn bị/token Android.
- `README.md`: hướng dẫn F5 và terminal cho từng nền tảng.

## Kiểm chứng thực tế

- `flutter devices`: có Chrome và Edge; không có thiết bị Android kết nối
  tại thời điểm kiểm tra.
- `node --test tool/prepare_vscode_android.test.cjs`: **5/5 qua**, exit 0,
  gồm fixture Android thiếu/empty token và hai launcher web.
- `flutter analyze`: **No issues found**, exit 0, 14,1 giây.
- `flutter build web --dart-define-from-file=config/chat-api.json
  --dart-define-from-file=config/admin-runtime.json`: qua, exit 0, 68 giây;
  output `build/web`.
- Phục vụ bản build trên loopback `http://localhost:7357/`, mở bằng trình
  duyệt trong Codex và quan sát màn hình đăng nhập HealthMate tại
  `/#/auth?from=/dashboard`, có Email, Mật khẩu và Tiếp tục với Google.
  Không đăng nhập, tạo tài khoản hoặc ghi dữ liệu production trong kiểm tra.
- Không sửa Dart nên không format hoặc chạy lại toàn bộ Flutter unit/widget
  tests chỉ để kiểm tra thay đổi launcher. Build thật và browser smoke test
  xác minh phạm vi lỗi khởi chạy; kết quả cũ 1.252 tests không được coi là
  một lượt chạy mới trong lần sửa này.

## Giới hạn và bước tiếp

- Đã kiểm chứng build và khởi động web, chưa trực tiếp bấm F5 trong VS Code
  hoặc kiểm thử đăng nhập với tài khoản thật trên Chrome/Edge.
- Web hiện là bản xem thử và các luồng hỗ trợ trình duyệt. Health Connect,
  Google Play Billing và AI scanner/App Check vẫn có giới hạn nền tảng hiện
  có; không tuyên bố khởi động web đồng nghĩa mọi tính năng Android chạy web.
- Build JavaScript thành công; Wasm dry run còn cảnh báo `mobile_scanner`
  dùng `dart:html`/`package:js`. Không nâng package ngoài phạm vi lỗi này.
- Không cần cấu hình Firebase/billing mới để mở bản web. Chủ dự án chọn
  đúng mục Web và F5; không cần tạo/copy token Android cho web.
- Bước tiếp đề xuất: nghiệm thu luồng cần dùng trên web nếu người dùng yêu
  cầu; chưa thực hiện.
