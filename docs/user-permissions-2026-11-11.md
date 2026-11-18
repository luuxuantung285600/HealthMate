# Rà soát quyền người dùng — 11/11/2026

Giai đoạn 10 bổ sung: tương thích Security Rules với các chức năng app đang có.
Không thêm chức năng, dịch vụ, billing hoặc thay mô hình quyền quản trị.

## Nguyên nhân

Rules production trước sửa có SHA256 chuẩn hóa
`6569cc8744a52e1c9ea0001ba3b14d9448a3c600d4260f5c2ead2f3bd7195088`.
So sánh với repository hiện tại xác nhận ba chênh lệch:

1. App luôn gửi `topic` khi tạo báo lỗi/góp ý. `validSupportTicket` production
   không chấp nhận field này nên transaction tạo yêu cầu và hạn mức bị từ chối.
   Reproduce bằng bản Rules production trên emulator: **16/16** tổ hợp
   bug/suggestion × 8 chủ đề thất bại `permission-denied`.
2. Lưu mục tiêu luôn gửi `saltGLimit`, `sugarGLimit`, `fiberGTarget`, kể cả khi
   chúng là null. Allowlist production thiếu ba trường nên lưu mới/sửa bị chặn.
3. Repository Premium đã có stream đọc `premium_memberships/{uid}`, nhưng
   production chưa khai báo quyền đọc này. Chức năng thanh toán vẫn mặc định
   tắt; thêm quyền đọc bản ghi đã xác minh không bật mua hàng hoặc cấp Premium.

Đây là lỗi tương thích bản Rules phát hành. Không cần cấp quyền admin cho khách,
cho phép ghi tự do hoặc yêu cầu khách mua Premium để gửi hỗ trợ.

## Quyền đúng của tài khoản thường

Áp dụng cho phiên đăng nhập đã xác minh email, tài khoản hoạt động và chưa xóa.

| Chức năng | Quyền được phép | Giới hạn giữ nguyên |
| --- | --- | --- |
| Hồ sơ, onboarding, cân nặng | Đọc/sửa hồ sơ và lịch sử của mình | Không sửa UID hoặc nâng vai trò |
| Nhật ký ăn, nước, vận động | CRUD dữ liệu riêng và xem tổng hợp | Không truy cập UID khác |
| Mục tiêu dinh dưỡng | Lưu/sửa calo, macro và mốc muối/đường/xơ | Nullable; muối ≤50 g, đường ≤500 g, xơ ≤200 g; không thay lịch sử cũ |
| Món yêu thích, món riêng, công thức, mẫu bữa | Quản lý dữ liệu của mình | Không ghi catalog chung |
| Mục tiêu, quest, kế hoạch ăn | Đọc/ghi tiến độ và kế hoạch riêng | Validation, timestamp và thao tác liên kết nguyên tử |
| Báo lỗi/góp ý | Tạo theo 8 chủ đề; đọc và trả lời yêu cầu của mình | 3 yêu cầu mới/ngày Việt Nam; cách nhau 60 giây; tối đa 100 tin/cuộc trao đổi |
| Premium | Đọc đúng membership của mình khi luồng Premium được bật | Không liệt kê membership; không tự cấp hoặc ghi giao dịch |
| Danh mục thực phẩm | Đọc danh mục và thay đổi đã công bố | Chỉ admin được ghi với audit |
| Chat và dữ liệu cá nhân | Truy cập hội thoại riêng | Không đọc UID khác; quyền AI theo dịch vụ đã cấu hình |
| Xóa tài khoản | Tiếp tục quy trình xóa có kiểm soát | Không dùng quy trình xóa để lấy lại quyền ghi sản phẩm |

Đối với hỗ trợ, khách không được giả vai admin, đổi chủ sở hữu/chủ đề của yêu cầu
đã tạo, đọc yêu cầu người khác hoặc gửi yêu cầu độc lập với cập nhật hạn mức.
Yêu cầu cũ không có topic vẫn đọc/trả lời được, không tự đoán chủ đề.
Quyền đọc sổ giao dịch vẫn chỉ dành cho admin; mọi client, kể cả admin,
không được đọc billing token hoặc tự ghi membership/giao dịch đã xác minh.

## File và quy trình kiểm chứng

- `firestore.rules`: contract chuẩn có enum topic hợp lệ, trường mục tiêu
  nullable có giới hạn và quyền đọc membership theo UID. Bản phát hành dùng đúng
  file chuẩn, không thay bằng schema production cũ.
- `rules-tests/user-support-permissions.rules.test.cjs`: regression trên dữ liệu
  giả lập; `HEALTHMATE_RULES_FILE` có thể trỏ bản production đã sao lưu để tái hiện.
  Có kiểm transaction đọc document chưa tồn tại, quota, legacy, giả danh và UID khác.
- `tool/test_operations_local.cjs`: runner nay kiểm cả repository chính, hỗ trợ,
  xóa tài khoản, kế hoạch bữa ăn và truy vấn. Nhập fixture H1 trước chạy. Các file
  Flutter Chrome chạy bằng từng tiến trình nối tiếp vì web bỏ qua `--concurrency`.
- `tool/reset_operations_emulator.cjs`: xóa fixture ở đúng localhost:8080,
  project demo-healthmate-rules trước nhập H1. Yêu cầu cả hai biến môi trường
  emulator cố định, không nhận URL/project bên ngoài, không dùng credential.
- `rules-tests/firestore.rules.test.cjs`: cho chọn project test có tiền tố demo-
  để regression có thể chạy song song với Flutter trên project khác.
- Sao lưu, diff review, candidate và log ở
  `build/user-permissions-release-20261111/`; regression hỗ trợ ở
  `build/user-support-permissions-20261111/`.

Chỉ dùng project `demo-` trên Auth/Firestore Emulator để tạo/xóa fixture.
Không ghi yêu cầu hỗ trợ, hồ sơ, giao dịch hoặc nhật ký giả vào production.
## Kết quả đã xác minh

- Rules: **170/170** qua (57 chính, 89 module khác, 24 regression hỗ trợ).
  Production backup cũng tái hiện lỗi lưu mục tiêu muối/đường/xơ. Assertion lỗi
  này là bằng chứng trước sửa; không được tính vào lượt test bản sửa đã qua.
- Flutter thật trên Chrome + Auth/Firestore Emulator: **63/63** qua, gồm
  repository chính 25, hỗ trợ 4, xóa tài khoản 8, kế hoạch bữa ăn 22, truy vấn 4.
  Không giả repository. Kiểm owner khác, offline, replay và cạnh tranh giao dịch
  nằm trong các suite tương ứng. Không chứng nhận luồng mua hàng Google Play.
- Test đóng gói contract chuẩn: **1/1** qua. Node syntax và diff-check qua.
- `flutter analyze --no-pub`: không có lỗi/cảnh báo, exit 0, 81,5 giây.
- `flutter test --no-pub --reporter json`: **1.289/1.289** qua, 0 lỗi/skip,
  exit 0, 137,5 giây. Không sửa Dart trong lượt này nên không format/build APK lại.
- Bản main SDK đầu thiếu fixture H1; lần kế còn dữ liệu C3 cũ nên có snapshot
  không đúng điều kiện fixture. Reset đúng project demo + nhập H1 giải quyết,
  main cuối 25/25 qua mà không sửa assertion/app. Giữ log các lượt lỗi và thêm
  prerequisite reset/import vào runner để lần sau có thể tái lập.

## Đã triển khai

Lệnh `firebase deploy --project healthmate-app-20261013 --config
build/user-permissions-release-20261111/candidate/firebase.rules.json
--only firestore:rules --non-interactive` hoàn thành exit 0. Chỉ phát hành Rules,
không publish lại web/app, không thay dữ liệu. Firebase compile có cảnh báo
`knownNumber` chưa dùng từ trước, không chặn triển khai.

Đọc lại production xác nhận **khớp toàn bộ source contract chuẩn**:

- Ruleset: `38076bf8-ba26-4578-a415-0233e508c4aa`.
- SHA256 chuẩn hóa: `52970f1cd1f96944234ce6567d133f57cabbf7982f2ff4c6811c085d15cbaaae`.
- Release: 11/11/2026 lúc 01:38:55 UTC+7.
- Sao lưu/rollback: `build/user-permissions-release-20261111/production-before/`.

App hiện tại chỉ cần thử lại thao tác hoặc mở lại màn hình sau khi mạng kết nối.
Không cần cài APK mới để nhận thay đổi Rules. Không yêu cầu nâng vai trò hoặc
bật Blaze. Kết quả bộ test Flutter mặc định được ghi trong `docs/test-report.md`
và manifest candidate.

## Giới hạn

Rà soát code và SDK emulator không thay nghiệm thu trên điện thoại thật hoặc
chứng minh mọi đường đi UI đã được bấm trên thiết bị. Không thay App Check,
chính sách xác minh email, trạng thái khóa/xóa tài khoản hay hạn mức hỗ trợ.
Nếu phiên bị chặn bởi các điều kiện này, cần xử lý đúng điều kiện tài khoản;
không cấp thêm quyền để vượt qua. Chức năng AI/thanh toán còn cần cấu hình dịch vụ
phù hợp; phát hành Rules không tự triển khai backend hoặc bật thanh toán.

Giai đoạn kế tiếp đề xuất: nghiệm thu người dùng và admin trên thiết bị thật khi
người dùng yêu cầu. Không chuyển sang giai đoạn đó trong lượt sửa quyền này.
