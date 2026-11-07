# Giai đoạn 10 — Hoàn thiện vận hành web admin, 07/11/2026

Theo yêu cầu bổ sung những phần còn thiếu của web admin. Tiếp tục hoàn thiện
các tính năng hiện có; giữ Firebase/Spark, quyền admin và dữ liệu riêng tư.
Không mở thêm dịch vụ hoặc thay luồng thanh toán/quyền quản trị.

## Hành vi đã bổ sung

- **Tra cứu toàn danh sách:** khách hàng bằng UID hoặc email đầy đủ, thực
  phẩm bằng mã hoặc đầu tên. Truy vấn máy chủ, tối đa 25 mục/trang; quyền và
  trạng thái tài khoản vẫn cập nhật trực tiếp. Tìm UID đọc đúng document,
  không quét directory. Đầu tên phân biệt chữ hoa/dấu; email so khớp đúng
  giá trị đã lưu. Bộ lọc/tìm nhanh phía dưới vẫn chỉ áp dụng trang đang xem,
  giao diện phân biệt rõ hai phạm vi. Tra cứu mới bỏ bộ lọc cũ để tránh ẩn
  kết quả tìm được. Không tải toàn bộ collection về trình duyệt để tìm.
- **Nhật ký quản trị:** xếp `at DESC, documentId DESC`, mới nhất lên đầu;
  lọc và xuất khoảng ngày Việt Nam, gồm ngày cuối. Cursor giữ giá trị thời
  gian Firestore trả về, không làm tròn millisecond; vẫn phân trang được khi
  bản ghi ở biên bị xóa. Export tối đa 5.000 mục/366 ngày và báo lỗi nếu vượt,
  không xuất một phần rồi gọi là đầy đủ. Khoảng mã cũ vẫn được API hỗ trợ.
- **Bản nháp:** hỏi trước khi rời form, đổi trang, đăng xuất hoặc bỏ cấu hình/
  phản hồi chưa lưu. Có lựa chọn ở lại; cảnh báo khi tải lại/đóng tab bằng
  beforeunload của trình duyệt. Đang lưu editor thì chặn chuyển trang/đăng
  xuất qua UI. Bản nháp chỉ ở bộ nhớ, không ghi email/nội dung hỗ trợ vào
  localStorage/sessionStorage. Mất quyền/đổi phiên xóa cả field editor khỏi DOM.
- **Phục hồi:** danh sách lỗi có nút thử lại; hỗ trợ vẫn có nút tải lại cuộc
  trao đổi khi listener lỗi và giữ phản hồi đang soạn. Cấu hình khác phiên
  bản làm vô hiệu hóa lưu, giữ bản nháp và có nút tải cấu hình mới với xác
  nhận bỏ bản nháp. Lỗi đăng xuất có thông báo, giữ màn hình hiện tại.
- **Điều hướng:** URL `#/food_catalog`, `#/support`, v.v. dùng whitelist;
  tải lại, Back và Forward giữ đúng trang sau kiểm tra quyền. Không đưa UID,
  email hoặc nội dung bản nháp vào URL. Title trình duyệt theo trang hiện tại.
- **Bài tập luyện:** thay màn hình trống bằng 33 bài tập thật trong
  `ExerciseCatalog` của app. Tìm không dấu, lọc nhóm, xem MET tham khảo/nguồn
  và xuất các mục đang lọc. Có nhãn **Chỉ đọc**; bản app đã cài có thể khác
  khi chưa cập nhật. Không tạo điều khiển sửa/xóa không có backend tương ứng.

## File chính

| File | Vai trò |
| --- | --- |
| `admin-web/dist/app.mjs` | Tra cứu, nhật ký, cấu hình, điều hướng, phiên |
| `admin-web/dist/server-paging.mjs` | Scope/cursor và chung query constraints |
| `admin-web/dist/firebase.mjs`, `live-data.mjs` | Truy vấn thật và listener cùng thứ tự |
| `admin-web/dist/draft-guard.mjs` | Xác nhận bỏ bản nháp và whitelist route |
| `admin-web/dist/support-page.mjs` | Bản nháp, trạng thái, phục hồi cuộc trao đổi |
| `admin-web/dist/workouts-page.mjs`, `exercise-catalog.mjs` | Danh mục bài tập chỉ đọc |
| `tool/export_admin_exercises.dart` | Xuất/kiểm danh mục từ nguồn Flutter |
| `admin-web/dist/admin-shell.mjs`, `admin-theme.css` | Nhãn menu, responsive, dialog |
| `admin-web/test/app-dom.test.mjs`, `server-paging.test.mjs`, `realtime-sdk.integration.mjs` | Hồi quy UI và SDK thật |
| `tool/test_operations_admin_local.cjs`, `admin-web/package.json` | Runner Node riêng, syntax checks |

## Kiểm thử thật

| Lệnh/kiểm tra | Kết quả |
| --- | --- |
| `npm --prefix admin-web run check` | Qua, gồm các module mới |
| `npm --prefix admin-web test` | **83/83**, 0 lỗi, 0 bỏ qua |
| SDK production modules trên Auth/Firestore emulator demo | **9/9 + 11/11** |
| Chrome headless, 9 trang × 1440/390/320 px | Không tràn trang hoặc JS exception; theme tối qua |
| Chrome drawer Tab/Shift+Tab/Escape ở mobile | Qua |
| Chrome dialog bỏ bản nháp / ở lại / hủy / reload deep link | Qua |
| `dart format tool/export_admin_exercises.dart` | Qua |
| `dart analyze tool/export_admin_exercises.dart` | No issues found |
| `dart run tool/export_admin_exercises.dart --check` | Khớp **33 bài tập** từ mã nguồn app |
| Ba query chỉ đọc trên production: email, đầu tên, audit ngày | HTTP **200**, index có sẵn |
| Source audit và git diff --check | **656 file / 0 findings**, diff qua |

SDK kiểm tra khách nằm ngoài trang đầu, email/UID cập nhật và biến mất trực
tiếp; tìm đầu tên qua nhiều trang; cursor khi biên bị xóa; thứ tự live/one-shot
giống nhau; thời điểm ranh giới ngày Việt Nam khi export. Firestore lưu thời
gian đến microsecond; không kỳ vọng fixture giữ precision cao hơn backend.
Không đổi Rules để nới quyền khi test lỗi; UID dùng direct document get/watch.

UI QA dùng adapter local được ghi nhãn rõ, không SDK/mạng production. Ảnh QA
không được dùng làm bằng chứng số lượng khách/doanh thu thật. Các fixture SDK
chỉ ở `demo-healthmate-admin`. Không tạo tài khoản, món hay doanh thu giả trên
production. Chỉ deploy Hosting; Rules giữ hash của bản đã kiểm 129 ca ở lượt
trước: `6504f7f66ed8054537fe74b30ebc4685ab7f63adfac6a959af42c7f2b8310c8f`.

Không chạy lại Flutter unit/widget, build/cài APK hoặc toàn bộ Rules suite
trong lượt này: app và Rules không thay đổi. Script Dart mới được analyze,
format, chạy thật và kiểm đối chiếu với `ExerciseCatalog`.

Log: `build/admin-completion-tests-verified.log`,
`build/admin-completion-sdk-final-acceptance.log`,
`build/admin-completion-browser-verified.log`,
`build/admin-completion-query-preflight.json`. Ảnh QA tại
`build/admin-completion-browser/qa-*.png`; đã xem ảnh mobile và dialog/desktop.
Giữ các log thất bại ban đầu để truy vết, không coi chúng là kết quả cuối.

## Triển khai và việc còn lại

Bundle: `build/admin-completion-release-20261107/`, profile Spark, Hosting only.
Đã deploy thành công lên https://healthmate-admin-vn.web.app. Đọc lại toàn bộ
**30 tệp Hosting** khớp byte release, có CSP/no-store. Đọc lại Rules xác nhận
cùng ruleset/hash trước triển khai; không thay quyền dữ liệu trong lượt này.
Cần tải lại web để nhận module mới. Billing đọc lại vẫn false; không deploy
Functions. Lượt này chỉ cập nhật web, không yêu cầu APK khác.

Bằng chứng triển khai: `build/admin-completion-deploy.log`,
`build/admin-completion-hosting-readback.json`,
`build/admin-completion-postdeploy/metadata.json`,
`build/admin-completion-release-verification.json`.

Các phần vẫn cần quyết định/cấu hình máy chủ: bộ đếm Auth tự động, xóa nền khi
app đóng, quản trị Auth bằng đặc quyền, phân quyền admin chi tiết, thanh toán
Premium thật và xác minh giao dịch. Premium hiện vẫn demo có nhãn. Chưa thêm
chỉnh sửa bài tập từ xa vì app dùng catalog đóng gói; cần thiết kế schema,
quyền và cập nhật app cùng nhau trước khi triển khai luồng đó.

Tiếp theo đề xuất: nghiệm thu bằng tài khoản admin thật; riêng worker Auth/xóa
nền thực hiện khi chủ dự án sẵn sàng bật Blaze. Không tự chuyển giai đoạn.

Khi sửa danh mục Flutter: chạy `dart run tool/export_admin_exercises.dart`,
rồi `dart run tool/export_admin_exercises.dart --check` trước khi đóng gói web.
