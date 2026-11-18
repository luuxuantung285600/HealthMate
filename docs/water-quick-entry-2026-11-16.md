# Nhật ký nước uống: chọn dung tích và hoàn tác — 16/11/2026

## Giai đoạn và kết quả

Giai đoạn 6 bảo trì, hoàn thành code và kiểm thử. Theo yêu cầu làm phần khác,
chọn cải thiện nhật ký nước uống; không bổ sung nhắc nền hoặc mở giai đoạn khác.

- Form thêm/sửa nước có nút chọn **100/250/350/500/750 ml**, vẫn nhập được
  dung tích tùy ý trong giới hạn cũ 50–5.000 ml. Hiện ngày đầy đủ dd/MM/yyyy
  và cho chọn giờ. Đổi giờ xóa thông báo lỗi thời điểm cũ để kiểm tra lại.
- Mục nước hiện cả nút ghi nhanh và thông báo chưa có dữ liệu. Trước đây nút
  ghi nhanh nằm chung danh sách bản ghi, làm mất empty state. Đã tách riêng
  phần thao tác, giữ nguyên các màn dùng thẻ nhật ký chung.
- Khi đang tải hoặc lỗi đọc, không hiển thị 0 ml như một tổng đã xác định.
- Ghi nhanh ở Trang chủ và Nhật ký có thông báo ngày/giờ, dung tích và nút
  **Hoàn tác**. Mỗi thông báo gắn đúng UID/ID/nội dung của lần ghi vừa được
  repository xác nhận. Không tạo thông báo thành công khi ghi chưa xong/lỗi.
- Ghi liên tiếp chỉ giữ thông báo hoàn tác mới nhất; hoàn tác không ảnh hưởng
  các lần ghi trước. Các lần khác vẫn sửa/xóa qua nhật ký như cũ.
- Lỗi hoàn tác có nút thử lại; chỉ báo hoàn tất sau xác nhận repository.
  Đổi tài khoản/đăng xuất đóng thông báo và làm hết hiệu lực receipt cũ.

## Bảo vệ dữ liệu khi hoàn tác

Repository dùng transaction đọc đúng `users/{uid}/water_logs/{logId}`. Chỉ
xóa nếu amountMl, consumedAt, dateKey và timezoneOffsetMinutes còn khớp
lần ghi ban đầu, đồng thời createdAt tồn tại và bằng updatedAt. Bản ghi đã
được sửa, kể cả sửa rồi quay về giá trị cũ, được giữ nguyên và báo lý do.
Transaction bảo vệ cả trường hợp có thay đổi đồng thời sau lượt đọc.
Nếu bản ghi đã bị xóa, hoàn tác coi như hoàn tất; thử lại không xóa mục khác.

Mã lỗi nghiệp vụ được trả sau callback transaction vì Firebase web bridge
có thể bọc exception Dart thành lỗi Firebase chung. Không bỏ qua lỗi quyền,
không cập nhật trực tiếp UI để giả vờ đã xóa thành công.

Không thêm field/collection, package, provider AI hoặc dịch vụ trả phí.
Receipt chỉ tồn tại trong bộ nhớ, không đổi schema/rules. Không cần deploy
Rules/Functions để chạy chức năng mới trong cấu hình hiện có.

## File chính

- `lib/features/water/data/water_repository.dart`: hợp đồng undoAdd.
- `lib/features/water/data/firebase_water_repository.dart`: transaction an toàn.
- `lib/features/water/providers/water_providers.dart`: receipt sau xác nhận,
  chống gửi khi đang lưu, kiểm UID và phiên trước khi hoàn tác.
- `lib/features/water/presentation/quick_water_entry.dart`: ghi nhanh, thông
  báo/hoàn tác/thử lại dùng chung, gắn thông báo với tài khoản.
- `lib/features/water/presentation/water_log_dialog.dart`: chọn dung tích/ngày.
- `lib/features/water/presentation/water_log_section.dart`: trạng thái dữ liệu.
- `lib/features/journal/presentation/daily_log_section_card.dart`: tách thao tác
  khỏi danh sách để giữ empty state; tùy chọn mới không đổi các thẻ khác.
- `lib/features/journal/presentation/journal_screen.dart` và
  `lib/features/dashboard/presentation/dashboard_screen.dart`: dùng chung luồng.
- `test/water_quick_entry_test.dart`, `test/support/fake_water_repository.dart`,
  `test/firebase_repository_integration.dart`: UI, lỗi, UID và Firebase SDK thật.

## Kiểm thử đã chạy

- `dart format --output=none --set-exit-if-changed` với 12 file Dart thay đổi:
  **0 file cần định dạng lại**, exit 0. Diff-check vùng thay đổi qua.
- `flutter analyze --no-pub` toàn repo: **No issues found**, 24,9 giây, exit 0.
- `flutter test --no-pub test/water_quick_entry_test.dart test/dashboard_test.dart test/daily_logs_test.dart test/daily_form_recovery_test.dart test/journal_sections_test.dart test/security_regression_test.dart test/stage_6b_test.dart`:
  **56/56 qua**, 11 giây, exit 0. Không cộng các lượt chạy lặp vào số ca này.
- 15 ca mới: empty/loading/error, hoàn tác ở hai tab, ngày cũ, nhiều lần ghi,
  chờ xác nhận/chặn bấm lặp, lỗi ghi, lỗi hoàn tác/thử lại, bảo vệ bản ghi đã
  sửa, đã xóa/thử lại, đổi tài khoản/đăng nhập lại, phản hồi đến sau đăng xuất,
  dung tích nhanh/tùy chọn và layout sáng/tối 320px chữ2x, 390px chữ1x.
- `flutter test --verbose --no-pub --platform chrome --dart-define=HEALTHMATE_EMULATOR_TESTS=true test/firebase_repository_integration.dart --plain-name 'water quick undo is atomic, preserves edits and enforces UID privacy'`:
  **1/1 qua** với Firebase Auth/Firestore SDK thật, Java21 và project emulator
  `demo-healthmate-rules`, exit 0. Xác minh timestamp server, xóa đúng ID,
  thử lại khi mục đã mất, giữ bản ghi khác, giữ bản ghi đã sửa/đổi về giá trị
  ban đầu, chặn UID khác và cho phép chủ tài khoản hoàn tác dữ liệu của mình.
- Đã xem ảnh render form sáng/tối dùng font Public Sans thật, không thấy tràn
  chữ ở ảnh đã kiểm tra. Ảnh dùng fixture test, không phải dữ liệu production.

Log cuối nằm trong `build/water-quick-entry-20261116/`:
`regression-final.log`, `analyze-final.log`, `sdk-emulator-rerun.log`.
Ảnh: `form-light.png`, `form-dark.png`.

## Sự cố kiểm thử và cách xử lý

- Snapshot code ban đầu có đuôi .dart dưới build nên analyzer đọc như source
  và báo import tương đối không tồn tại. Đổi đuôi snapshot thành .dart.before;
  không thay cấu hình analyzer hay bỏ qua lỗi production.
- Ca đổi tài khoản ban đầu dùng profile giả của UID cũ khiến router chờ. Đã
  cung cấp profile đúng UID cho cả hai phiên, giữ nguyên assertion chống chéo.
  Một import fixture qua file không export đã sửa về đúng file định nghĩa.
- Lượt emulator đầu dùng Java hệ thống cũ; đặt JAVA_HOME và PATH cho riêng
  tiến trình về JBR21. Config emulator dùng bản sao Rules local trong cùng
  thư mục vì Firebase CLI không cho Rules nằm ngoài thư mục config.
- Flutter test server trên Windows trả 404 cho CanvasKit dù artifact đúng
  phiên bản có sẵn trong SDK, khiến suite không khởi tạo. Đã ghi chẩn đoán
  `browser-diagnostics.json`; không sửa Flutter SDK hoặc code sản phẩm.
  Workaround chỉ trong Chrome headless do lượt test này tạo: cấp đúng bytes
  CanvasKit từ SDK cho hai request engine rồi khởi tạo lại iframe test.
  Không chặn/thay dữ liệu Firebase, không mock transaction/rules/auth hoặc
  thay mã app/test. Script `serve-test-canvaskit.cjs` và hash bytes được lưu
  cùng `canvaskit-workaround-final.log`. Browser/emulator đã dừng sau test.
- Lượt SDK đầu chạy được phát hiện lỗi domain code bị web bridge bọc thành
  lỗi chung. Đã sửa repository như mô tả trên và chạy lại **1/1 qua**, giữ
  nguyên kiểm tra mã lỗi. Không dùng lượt treo/lỗi để tuyên bố thành công.

## Cần người dùng làm và giới hạn

Hot Restart app, thử ghi nhanh nước ở Trang chủ hoặc Nhật ký rồi bấm Hoàn tác.
Form Ghi nước uống có các dung tích chọn nhanh. Không cần cấu hình Firebase
mới. Hoàn tác cần kết nối máy chủ để transaction kiểm tra bản ghi hiện tại;
lỗi có thể thử lại, các mục khác vẫn quản lý qua nhật ký.

Chưa nghiệm thu Android vật lý hoặc build/ký/phát hành. Không push Git, deploy
Hosting/Functions/Rules, thay native permissions hoặc ghi fixture production
trong lượt này. Không có blocker đã biết trong phạm vi đã kiểm thử.

Đề xuất tiếp: Giai đoạn 10 — nghiệm thu luồng nhật ký trên môi trường người
dùng. Chỉ đề xuất; chưa triển khai giai đoạn khác.
