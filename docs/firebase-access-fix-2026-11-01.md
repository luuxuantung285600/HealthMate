# HealthMate — Sửa lỗi chặn truy cập sau đăng nhập, 01/11/2026

## Nguyên nhân đã xác minh

App đọc `account_deletions/{uid}` ngay sau khi email đã được xác minh, kể cả
khi chưa bật admin runtime. Rules đang triển khai trên Firebase từ
30/10/2026 chưa có match này nên từ chối đọc. Firebase Emulator tái hiện được
permission-denied bằng đúng bản Rules đã tải về. Không coi lỗi này là mất
mạng và không bỏ qua bước kiểm tra trạng thái tài khoản.

Đã đọc metadata/Rules của project `healthmate-app-20261013` bằng Firebase CLI
đã đăng nhập; không đọc hồ sơ/nhật ký người dùng. Rules production khác root
`firestore.rules` của candidate. Không triển khai toàn bộ root Rules để sửa
lỗi khởi động vì chúng còn chứa các thay đổi nghiệp vụ chưa rollout.

Kiểm tra App Check chỉ cho thấy enforcement của Firebase AI Logic; Firestore
không trả enforcement mode ENFORCED. Chưa lấy được log lỗi từ điện thoại:
logcat của process chỉ trả buffer header. Kết luận nguyên nhân dựa trên
đối chiếu code, Rules thật và tái hiện SDK với emulator.

## Sửa cấu hình chạy F5

F5 trước đây không dùng `tool/android_app_arguments.ps1`, bỏ sót cấu hình admin
và token App Check cục bộ. Đã nối preLaunchTask để tạo file debug riêng ngoài
repository rồi nạp bằng `--dart-define-from-file`:

- `.vscode/launch.json`, `.vscode/tasks.json`.
- `tool/prepare_vscode_android.ps1`, dùng cùng helper của run/build Android.
- File riêng: `%LOCALAPPDATA%\HealthMate\vscode-android-debug.json`.
- Không in token, ghi token vào launch.json hoặc truyền giá trị token trên
  dòng lệnh. Task dừng nếu thiếu cấu hình/token hoặc output nằm trong repo.
- `README.md` cập nhật cách dùng. Không dùng file debug này để phát hành release.

## Bản vá Rules nhỏ, đã được duyệt và triển khai

Candidate được tạo từ **đúng Rules production đã sao lưu**, chỉ thêm:

```text
match /account_deletions/{uid} {
  allow get: if request.auth != null
    && request.auth.token.email_verified == true
    && request.auth.uid == uid;
  allow list, create, update, delete: if false;
}
```

Cho phép tài khoản xác minh email đọc trạng thái của chính mình, kể cả trạng
thái không có yêu cầu xóa. Không mở đọc chéo UID, đọc danh sách hoặc quyền ghi.
Không tắt App Check, khóa tài khoản hay maintenance gate.

Chỉ là vá tương thích khởi động; chưa triển khai workflow xóa tài khoản mới.
Quyền tạo/cập nhật/xóa marker vẫn từ chối như production hiện tại. Các gói
deletion/migration/support và Rules root vẫn cần rollout riêng.

File cụ thể để duyệt:

- Candidate: `build/firebase-access-hotfix-20261101/firestore.rules`.
- Firebase config chỉ chứa Rules: `build/firebase-access-hotfix-20261101/firebase.json`.
- Backup: `build/firebase-access-review-20261101/firestore.rules` cùng metadata
  và config rollback. Hash chuẩn hóa bản đang chạy:
  `0767a0a4363296b9cf268591bdb278089b21ef2835d263ce00d79860935c2824`.
- Trước triển khai cần đọc lại release metadata và kiểm hash vẫn khớp baseline;
  nếu ai đã sửa Rules production thì dừng, không ghi đè phiên bản mới.

Người dùng đã chọn **Áp dụng bản vá lên Firebase** trong lượt này. Đã kiểm
baseline lần nữa, deploy **chỉ firestore:rules** bằng config candidate riêng,
project được ghi rõ `healthmate-app-20261013`. Firebase báo Deploy complete.
Sau deploy tải lại Rules, so sánh toàn bộ source chuẩn hóa: khớp candidate.
Hash đang chạy:
`b062a8c0620c83f40a41c33196f14b2d218fd9e134a827aeec9b4d2e697d6bfc`.
Metadata sau deploy: `build/firebase-access-postdeploy-20261101/metadata.json`.
Thời điểm release: 01/11/2026, 14:35:12 (Asia/Saigon).

## Kiểm tra

- `node --test tool/prepare_vscode_android.test.cjs`: **5/5 qua**; kiểm file
  riêng, không in token, thiếu/empty token, runtime tắt/conflict và wiring F5.
- Flutter admin runtime dùng đúng `config/admin-runtime.json`: **7/7 qua**;
  gồm fail-closed, khóa/mở lại, maintenance và retry listener.
- Firestore emulator SDK: **7/7 qua**; tái hiện baseline bị chặn, candidate
  chỉ thay một match, get owner tồn tại/không tồn tại, chặn cross UID/guest/
  email chưa xác minh/list/write, giữ khóa tài khoản và bảo vệ dữ liệu riêng.
- Source secret audit: không có finding. Các file token nằm ngoài scope repo.
- Build Android debug với **đúng file defines mà F5 dùng**: thành công,
  Gradle26,8 giây; không cài app hoặc chạy thử trên điện thoại.
- Chưa chạy lại luồng điện thoại theo lựa chọn người dùng tự test.

Log kiểm tra ở `build/vscode-admin-runtime-tests.log`,
`build/firebase-access-hotfix-emulator.log`, `build/vscode-android-debug-build.log`.
Trạng thái build cuối và việc triển khai sẽ ghi ở `docs/test-report.md`.

## Thao tác tiếp theo

Bấm **Kiểm tra lại** ở màn bị chặn; lần chạy tiếp theo dùng F5 để nạp cấu hình
debug mới. Người dùng tự nghiệm thu trên thiết bị. Chưa xác nhận kết quả thao
tác thật trên điện thoại. Không thay dữ liệu người dùng, bật billing, deploy
root Rules hoặc lên lịch tắt máy. Các rollout nghiệp vụ khác vẫn tách riêng.
