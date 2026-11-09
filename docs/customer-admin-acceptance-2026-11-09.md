# Kiểm thử vai khách hàng và quản trị viên — 09/11/2026

## Giai đoạn và kết luận

Giai đoạn 10: kiểm thử tích hợp và nghiệm thu các luồng hiện có. **Đạt một
phần; chưa đủ cơ sở nghiệm thu toàn bộ app/web hoặc bản phát hành.** Đã
thao tác web bằng trình duyệt thật, chạy app trên Android Emulator và kiểm
tra các repository/provider bằng Firebase SDK thật với Security Rules.

Mọi tài khoản, món và hội thoại QA trong lượt này nằm ở Firebase Emulator.
Không gửi hỗ trợ tới người thật, không thu tiền, không deploy hay ghi dữ
liệu production. Dữ liệu local mang nhãn kiểm thử; không dùng để kết luận
doanh thu hoặc số người dùng thực tế.

## Môi trường và bằng chứng

- Web: `http://127.0.0.1:4173/`, Firebase project demo-healthmate-admin,
  Auth 9098 và Firestore 8092. Không chạy Cloud Functions local.
- App: AVD HealthMateMaintenanceQA, emulator-5580, Android API 30 x86_64.
  Firebase demo-healthmate-rules, Auth 9099, Firestore 8080. SDK trong app
  kết nối qua 10.0.2.2. Không khởi tạo Firebase production.
- Bản sao build đường dẫn ngắn:
  `D:/HealthMateMaintenanceQA/customer-admin-20261109`. Đã đối chiếu hash
  281 file lib/integration_test khi sao chép; các test sửa tiếp được chép
  sang trước mỗi lượt chạy. Chỉ bản sao đặt kotlin.incremental=false.
- AI trực tuyến và thanh toán Play được tắt trong harness Android.
  Dinh dưỡng USDA trực tuyến trong bài nutrition được thay bằng HTTP test
  trả danh sách rỗng; dữ liệu bundled và SQLite vẫn chạy thật.
- Log/bằng chứng web: `build/customer-admin-qa/`. Log Android và PNG gốc:
  `D:/HealthMateMaintenanceQA/customer-admin-20261109/build/`.
- Đã chép bốn log Android về `build/customer-admin-qa/android-*.log`.
  Ảnh xem lại: admin-support.jpg, admin-audit.jpg, admin-overview.jpg,
  admin-report-export.jpg, app-journal.png và app-sleep.png. File XLSX
  tải bằng UI được giữ ở revenue-export.xlsx cùng xlsx-verify.log.

## Luồng quản trị đã thao tác qua giao diện

| Luồng | Quan sát thực tế |
|---|---|
| Đăng nhập admin | Đăng nhập bằng fixture đã xác minh email, mở được các trang quản trị. |
| Tổng quan | Phân biệt tài khoản đã đăng ký với hồ sơ đã đồng bộ; thống kê Auth có nhãn thời điểm cập nhật thủ công. Không cộng doanh thu demo vào Google Play. |
| Thêm món | Form trống bị validation chặn. Tạo món QA có ID, nguồn, cơ sở 100 g và khẩu phần 200 g; lưu thành công. |
| Sửa món | Đổi kcal từ 130 thành 140, tra cứu lại theo ID xác nhận đúng. |
| Ẩn/khôi phục | Cả hai trạng thái hiển thị đúng và có lý do trong audit. Sau tải bản sửa, thử lại ẩn và khôi phục đều đóng form, báo máy chủ xác nhận. |
| Nhật ký quản trị | Quan sát đủ bản ghi tạo/sửa/ẩn/khôi phục cùng mã món và lý do. |
| Hỗ trợ theo chủ đề | Client khách đăng nhập SDK thật gửi yêu cầu chủ đề dinh dưỡng. Admin thấy yêu cầu, trả lời qua UI, client khách nhận phản hồi live. Admin đổi sang đã giải quyết thành công. |
| Khách hàng | Danh sách hiển thị tài khoản đồng bộ và vai trò; tra cứu toàn danh sách được kiểm tra thêm bằng SDK, bao gồm dữ liệu ngoài trang đầu. |
| Báo cáo | Nguồn Google Play không có giao dịch trả empty state. Chọn demo riêng và xuất XLSX qua nút thật; trình duyệt tải file và thông báo đúng 0 dòng dữ liệu. ZIP và toàn bộ 5 XML của file hợp lệ, có sheet Doanh thu mô phỏng và Thông tin báo cáo. |
| Bài tập luyện | Có 33 bài, tìm/lọc/xuất danh mục từ mã nguồn. Trang ghi rõ chỉ đọc. **Không có CRUD từ xa hoặc đồng bộ thay đổi danh mục bài tập tới app đã cài.** |

Hội thoại QA thủ công đã được dọn khỏi emulator sau khi lưu bằng chứng để
không làm nhiễu test phân trang vốn giả định danh sách support trống.
Món QA đã được khôi phục; chỉ tồn tại trong emulator.

Lần thử ẩn món ban đầu từng gặp thông báo chưa xác nhận máy chủ dù dòng
đã chuyển trạng thái. Thử lại cùng thao tác thành công và audit chỉ có một
bản ghi ẩn. Sau tải bản sửa không tái hiện trong lần ẩn/khôi phục tiếp theo.
Chưa có bằng chứng đủ để quy nguyên nhân lần lỗi đầu cho một thay đổi cụ thể.

## Lỗi phát hiện và sửa trong phạm vi kiểm thử

1. Web dùng `SnapshotMetadata.isFromCache` của Dart trong Firebase JS.
   SDK JS 13.0.0 dùng `fromCache`; đọc sai thuộc tính làm dữ liệu cache có
   thể bị coi là đã xác nhận từ máy chủ. Sửa tại live listener, kiểm tra
   role/control và xác nhận sau lưu. Bổ sung regression bằng SDK thật:
   dữ liệu cache đầu tiên phải bị giữ lại đến khi máy chủ xác nhận.
2. Config local mặc định trông chờ bộ thống kê Cloud Functions dù runner
   chỉ có Auth/Firestore. Chọn statisticsMode=firestore riêng cho config
   demo local; không thay mặc định production hoặc thêm dịch vụ.
3. Trang hỗ trợ truyền null trực tiếp vào replaceChildren, hiện chữ
   `null` sau bảng có dữ liệu. Loại bỏ child rỗng; bổ sung DOM regression.
4. Mô tả doanh thu vẫn nói cố định chỉ có demo. Đổi thành mô tả theo nguồn
   được chọn, giữ các cảnh báo/nhãn demo, test và tiền thật của từng nguồn.

Không thay quy tắc nghiệp vụ, schema, dependencies hoặc mã Flutter sản
phẩm trong lượt này. Không ghi đè thay đổi có từ các lượt trước.

### File chính thay đổi

- admin-web/dist/firebase.mjs, live-data.mjs: đọc metadata đúng SDK JS.
- admin-web/dist/config.js: chế độ thống kê phù hợp emulator.
- admin-web/dist/support-page.mjs, admin-shell.mjs: sửa hiển thị.
- admin-web/test/realtime-sdk.integration.mjs, app-dom.test.mjs:
  regression bằng SDK/DOM.
- integration_test/core_acceptance_test.dart,
  nutrition_acceptance_test.dart, wellness_acceptance_test.dart:
  cập nhật hành trình UI và chẩn đoán lỗi harness.
- docs/customer-admin-acceptance-2026-11-09.md,
  docs/implementation-progress.md, docs/test-report.md: báo cáo lượt này.

## Kiểm thử tự động

| Lệnh / nhóm | Kết quả |
|---|---|
| dart format các integration test đã sửa | Đã chạy. |
| flutter analyze --no-pub | Không có issue, exit 0. |
| dart analyze ba integration test sửa trong lượt này | Không có issue, exit 0, sau các cập nhật harness. |
| flutter test --no-pub --reporter expanded | 1.130/1.130 đạt, exit 0. |
| npm --prefix admin-web test | 99/99 đạt, gồm regression không hiện null. |
| npm --prefix admin-web run check | Đạt. |
| npm --prefix admin-web run check:billing | Đạt. |
| node --test admin-web/test/sdk.integration.mjs | 9/9 đạt với Firebase SDK/Rules thật. |
| node --test admin-web/test/realtime-sdk.integration.mjs | 12/12 đạt, tiến trình thoát bình thường. |
| Flutter Chrome test/admin_runtime_integration.dart | 3/3 đạt. Khóa/mở tài khoản, đồng bộ danh bạ và cờ bảo trì/AI tới provider thật. |
| Flutter Chrome test/realtime_spark_integration.dart | 6/6 đạt. Báo cáo/nước, món cá nhân, mục tiêu, support hai chiều, món admin và xóa tài khoản liên client. |
| Android wellness_acceptance_test.dart | Kịch bản đạt; output +2 gồm teardown. Nhắc bữa, SQLite, giấc ngủ/biểu đồ, thực đơn, dưỡng chất thiếu, ngân sách và tách UID. Cảm biến bước chân của AVD báo không hỗ trợ. |
| Android daily_reliability_acceptance_test.dart | Kịch bản đạt; output +2 gồm teardown. Draft mã hóa, offline nước/vận động, retry một lần và đổi UID đóng form. |
| Android core_acceptance_test.dart | Chưa đạt toàn kịch bản. Đã qua đăng ký/onboarding, lịch sử mục tiêu, thêm/sửa/nhân bản bữa với giá trị 195/260 kcal. Dừng ở thao tác vận động do harness chưa mở phần chi tiết đang thu gọn. Không kết luận phần sau đạt. |
| Android nutrition_acceptance_test.dart | Đạt toàn kịch bản 11 checkpoint, exit 0; output +2 gồm teardown. Catalog bundled 11.169 mục; filter tránh thực phẩm; chọn/sửa/lưu khẩu phần; tổng kcal; preview không ghi; xác nhận 28 kế hoạch; ghi nhật ký một lần; xóa nhật ký giữ kế hoạch; UID khác bị từ chối đọc. |

Các bài Chrome opt-in chạy qua tool/chrome_test_adapter.cmd. Runtime dùng
config/admin-runtime.json và HEALTHMATE_ADMIN_EMULATOR_TESTS=true;
realtime dùng HEALTHMATE_EMULATOR_TESTS=true. Runner Android dùng
HEALTHMATE_CORE_EMULATOR_TESTS=true, HEALTHMATE_ENABLE_CHATBOT=false và
HEALTHMATE_ENABLE_FOOD_SCANNER=false, driver core_acceptance_driver.dart.

Một số harness Android cũ chưa theo UI hiện tại: Text.rich phải so chính
xác semanticsLabel, tìm món cần nhập truy vấn, ngày ăn nằm trong menu,
Wellness cần router/hub, bộ lọc món nằm trong công cụ và phần mở rộng,
catalog bundled hiện có 11.169 mục thay vì 7.606. Đã sửa các điểm đã đối
chiếu. Không hạ các assertion dinh dưỡng/quyền sở hữu để làm test xanh.

Luồng nutrition từng chờ form đóng ở bước lưu trong khi app đang hiện
hộp thoại kiểm tra thực phẩm cần tránh. Sau khi harness kiểm tra nội dung
cảnh báo và bấm xác nhận ghi lại bữa đã ăn, lưu/sửa món và tổng kcal đạt.
Đây là bước xác nhận của sản phẩm, không phải lỗi Firestore. Một lượt
chẩn đoán còn lỗi biên dịch vì gọi helper capture không tồn tại; đã bỏ
lời gọi đó, dùng API screenshot của binding và analyze lại thành công.
Một lượt tiếp theo dùng Finder.first trước khi dữ liệu nhật ký về, gây
No element trong chính test. Đã chờ finder gốc có dữ liệu trước khi chọn
phần tử đầu, chạy lại toàn bộ nutrition và đạt cả 11 checkpoint.

Lưu ý phạm vi danh mục: app ghép dữ liệu bundled với Firestore theo ID,
còn bảng/thống kê thực phẩm của admin đọc food_catalog trong Firestore.
Không dùng số món trên web để khẳng định tổng mọi nguồn món tìm được
trong app. Lượt này không nhập toàn bộ catalog bundled lên máy chủ.

Bản thử regression tắt/bật network của Node SDK có 12 assertion đạt nhưng
không kết thúc do stream timer khi dọn SDK, nên **không dùng làm kết quả
12/12 đạt**. Bản cuối kiểm tra cache ban đầu bằng listener thật, dọn SDK
đầy đủ và thoát exit 0; offline Android được kiểm chứng bằng suite daily.
Một lượt SDK khác bị nhiễu bởi hội thoại QA thủ công trong test phân trang;
đã dọn đúng fixture đó rồi chạy lại cả hai suite tuần tự, đều đạt.

## Giới hạn còn lại và việc người dùng cần làm

- Chưa nghiệm thu trên điện thoại Android thật hoặc ký phát hành, theo
  quyết định để sau của người dùng.
- Chưa chạy mua/hoàn/gia hạn Google Play thật vì chưa có Play Console và
  cấu hình máy chủ thanh toán production. Không coi ledger emulator là
  tiền thu được.
- Chưa gọi Gemini scanner/chatbot thật, camera/barcode thật hoặc kiểm
  tra App Check production. Unit/widget test không thay thế việc này.
- Auth tổng đăng ký đang có chế độ snapshot thủ công. Muốn cập nhật cả
  đăng ký/xóa qua Firebase Console bằng event máy chủ cần triển khai
  Functions/billing đã được đồng ý nhưng đang hoãn cấu hình.
- Bài tập admin chỉ đọc; yêu cầu quản trị danh mục bài tập realtime vẫn
  chưa được đáp ứng. Đây là khoảng trống tính năng, không tự mở rộng
  kiến trúc trong lượt kiểm thử này.
- Harness core còn lệch luồng UI như ghi ở trên; phải sửa và chạy hết
  trước khi gọi là nghiệm thu Android đầy đủ. Cảnh báo plugin KGP hiện
  hữu vẫn còn dù các APK harness build được.
- Không cần người dùng nhập khóa hoặc cấu hình mới cho các kiểm thử local
  đã hoàn thành. Các giới hạn production cần cấu hình và một lượt nghiệm
  thu riêng.

Giai đoạn tiếp theo đề xuất: hoàn tất các hành trình Android còn thiếu và
chốt danh mục quản trị nào thực sự cần sửa từ xa; chưa triển khai giai đoạn
hoặc tính năng kế tiếp trong lượt này.

Kết thúc QA đã dừng đúng web server, Firebase Emulator và AVD do lượt này
khởi chạy. Đã kiểm tra các cổng 4173/8092/9098/8080/9099 không còn listener.
Ảnh và log vẫn giữ trên đĩa; URL localhost cần khởi chạy lại nếu muốn xem.
