# Giao diện HealthMate Admin theo ảnh tham khảo — 03/11/2026

## Phạm vi và trạng thái

Hoàn tất phần UX/UI web admin theo yêu cầu: sidebar trắng, nền xám nhạt,
panel trắng, điểm nhấn hồng/tím và bốn card gradient. Đây là phần polish
UI admin theo yêu cầu riêng, không triển khai thêm giai đoạn nghiệp vụ.
Source đã kiểm thử local; bản web online chưa cập nhật.

Không thêm dependency, backend, collection hoặc quyền Firestore trong lượt
UI này. Bảo toàn những thay đổi dashboard chưa commit từ lượt trước;
không commit/push, deploy Hosting/Rules hoặc ghi dữ liệu production.

## Hành vi và giao diện

- Sidebar theo thứ tự: **Tổng quan, Doanh thu, Khách hàng, Thực phẩm,
  Bài tập luyện, AI Chatbot**; giữ Hỗ trợ khách hàng, Nhật ký quản trị và
  Cài đặt. Trang đang mở có trạng thái active; có thu gọn sidebar trên
  desktop và drawer/overlay trên mobile, đóng bằng Escape hoặc vùng nền.
- Header có breadcrumb, tài khoản đang đăng nhập, đăng xuất và lối Cài đặt.
  Các trang danh sách, bộ lọc, phân trang, form, dialog, hỗ trợ và trang
  đăng nhập dùng cùng theme; giữ hành động dữ liệu đã có.
- Tổng quan gồm biểu đồ doanh thu theo ngày và trạng thái tính năng,
  bốn card số liệu, thông tin vận hành và giao dịch gần đây. Biểu đồ SVG
  lấy dữ liệu giao dịch đã lưu; kỳ không có giao dịch vẽ đường 0 và giải
  thích trạng thái trống. Có bảng số liệu từng ngày để đọc bằng văn bản.
- **Bài tập luyện** có nhãn “Sắp có”, trang “Chờ triển khai / Chưa kết nối
  danh mục bài tập”. Chưa có nghiệp vụ/catalog nên không thêm bài tập mẫu,
  nút CRUD giả hoặc query dữ liệu chưa tồn tại.
- **AI Chatbot** đọc cấu hình AI hiện có; khi thiếu cấu hình hiển thị chưa
  xác định, không tự cho là bật/tắt. Nút điều chỉnh mở form cấu hình có
  audit đang dùng. Bỏ kết quả async cũ sau đổi trang hoặc đăng xuất.

## Dữ liệu và bản xem trước

Tổng đăng ký vẫn đọc summary Authentication có thời điểm từ dashboard
candidate; không dùng số hồ sơ đồng bộ làm tổng tài khoản. Nếu summary
chưa được đồng bộ/không có quyền đọc, sản phẩm hiện “Chưa có số liệu”.
Phần UI không tự ghi summary lên production.

Premium hiện là **demo, không thu tiền**. Các giao dịch demo đã lưu là dữ
liệu đầu vào của báo cáo, không phải doanh thu thực nhận. Không thêm số
tài khoản, doanh thu, giao dịch hoặc đường biểu đồ để làm đẹp giao diện.

Bản xem trước chỉ đọc tại máy dùng snapshot Firebase thật lúc **02:01:25,
03/11/2026 (UTC+7)**: Auth **3**; món **158**; tài khoản đã đồng bộ **1**;
tạm khóa **0**; audit **7**. Kỳ **01–03/11/2026** có **0 giao dịch demo,
0 VND mô phỏng và 0 khách mua**. Đây là thời điểm đọc, không phải dữ liệu
realtime hoặc trạng thái đã publish.

Snapshot chạy chính `admin-shell.mjs` và `dashboard-page.mjs` mới qua adapter
chỉ đọc. Header ghi rõ “ĐỐI CHIẾU · CHỈ ĐỌC”; thao tác ghi/chuyển trang bị
vô hiệu hóa riêng trong bản đối chiếu này. Web sản phẩm giữ các route và
hành động hiện có. Không đưa credential vào snapshot hoặc in token ra log.

Ảnh và công cụ đối chiếu nằm trong thư mục build được ignore:

- `build/admin-ui-reference-20261103/dashboard-real-desktop.png`
- `build/admin-ui-reference-20261103/dashboard-real-tablet.png`
- `build/admin-ui-reference-20261103/dashboard-real-mobile.png`
- `build/admin-ui-reference-20261103/dashboard-real-small.png`

Không dùng lại ảnh fixture cũ làm bằng chứng dữ liệu thật.

## File chính

| File | Thay đổi |
| --- | --- |
| `admin-web/dist/admin-shell.mjs` | Menu, icon SVG, brand, header, sidebar/drawer |
| `admin-web/dist/admin-theme.css` | Theme và responsive cho các trang admin |
| `admin-web/dist/index.html` | Nạp theme sau stylesheet hiện có |
| `admin-web/dist/app.mjs` | Dùng shell mới, trang bài tập chờ triển khai, trang cấu hình AI |
| `admin-web/dist/dashboard-page.mjs` | Bố cục tổng quan và biểu đồ SVG từ dữ liệu thật |
| `admin-web/test/app-dom.test.mjs` | Hồi quy menu, drawer, trang bài tập, cấu hình AI và response cũ |
| `admin-web/package.json` | Thêm shell mới vào kiểm tra cú pháp |

## Kiểm thử và giới hạn

- `npm --prefix admin-web run check`: qua.
- `npm --prefix admin-web test`: **60/60 qua**, 0 lỗi, 0 bỏ qua. Log:
  `build/admin-ui-reference-20261103/check.log` và `test.log`.
- Chrome headless ở **1440, 1024, 390, 320 px**: không tràn ngang trang,
  không JavaScript exception; các ô **3 / 0 ₫ / 0 / 0** khớp snapshot.
  Đã xem ảnh desktop và mobile sau lần chỉnh nhãn biểu đồ responsive cuối.
- `git -c core.safecrlf=false diff --check`: qua.
- `node tool/audit_source_secrets.cjs`: **621 source text files, 0 findings**;
  không quét credential store hoặc APK.
- Không đổi Dart/Android hoặc Rules trong lượt UI nên không chạy lại
  `dart format`, Flutter analyze/test, SDK Emulator hoặc Rules suites.
  Kết quả các lượt trước được giữ riêng trong báo cáo kiểm thử.

## Việc còn lại

Để bản online có giao diện mới cần rollout web sau review. Tổng đăng ký
trên sản phẩm vẫn cần Rules patch tối thiểu và đồng bộ summary theo báo
cáo dashboard trước đó; không deploy toàn bộ root Rules candidate.
Chưa triển khai catalog/CRUD bài tập, thanh toán thật hoặc chức năng quản
trị hội thoại cá nhân. Bước tiếp theo đề xuất: nghiệm thu và rollout UI
admin; chỉ triển khai bài tập khi người dùng yêu cầu phạm vi nghiệp vụ.
