# Admin đồng bộ nhận diện với app — 10/11/2026

**Giai đoạn tùy chọn 11 — UI polish.** Hoàn thiện source và kiểm tra local.
Bản web đã publish trước đó chưa nhận thay đổi trong lượt này.

## Kết quả

- Giữ Inter đang dùng, đổi icon vẽ tay cũ sang **Lucide Static 1.70.0**,
  cùng bản phát hành với Flutter `AppIcons`: nét 2px, đầu/khớp bo tròn,
  viewBox 24px. Dùng cho sidebar, logo lá HealthMate, tiêu đề trang, thẻ
  thống kê, trang AI, đóng form và các thao tác thêm/sửa/xóa/tải/xuất.
- Bộ 29 tên icon nằm trong `admin-icons.mjs`; không tải icon qua CDN,
  không thêm npm dependency. Giữ ISC/MIT trong `dist/licenses/lucide.txt`.
- **17 bảng màu nhận diện lấy trực tiếp từ `AppFeatureVisual` của app**:
  thực phẩm cam, tập luyện chàm, AI tím, khách hàng xanh dương, Premium vàng,
  hỗ trợ xanh cyan. Khung icon mềm, hình riêng đi kèm nhãn tiếng Việt.
- Nền **trắng khi sáng**, **đen #000 khi tối**, panel trung tính và điểm
  nhấn tím như Trang chủ app. Bảng, bộ lọc, dialog, hỗ trợ, trang AI và đăng
  nhập đổi theo theme; nút thao tác và trạng thái được kiểm tra tương phản.
- Chọn **Thiết bị / Sáng / Tối** ở header và màn đăng nhập. Lưu lựa chọn
  riêng của trình duyệt, theo thay đổi hệ thống khi chọn Thiết bị, đồng bộ
  giữa các tab và hoạt động khi localStorage bị chặn. Script áp dụng trước
  CSS để giảm chớp màu. Không lưu dữ liệu tài khoản trong preference này.
- Sidebar có nền đánh dấu trang hiện tại, giữ `aria-current`, nhãn khi thu
  gọn, menu mobile có Tab/Shift+Tab/Escape và trả focus. Nút header 44px,
  mục menu ít nhất 48px; icon trang trí ẩn khỏi trình đọc màn hình.
- Giữ nguyên repository, listener, kiểm tra quyền, thao tác dữ liệu, báo
  cáo, phiên đăng nhập và cảnh báo bỏ nháp đang hoạt động.

## File chính

| File | Vai trò |
| --- | --- |
| `admin-web/dist/admin-icons.mjs` | SVG Lucide được trích từ cùng archive với font Flutter |
| `admin-web/dist/feature-identity.css` | Màu feature sáng/tối tạo từ Dart, tránh hai bảng màu khác nhau |
| `admin-web/dist/appearance.css` | Theme trung tính, kích thước icon/vùng bấm, sidebar, form và responsive |
| `admin-web/dist/appearance.js` | Khởi tạo, lưu/khôi phục và theo thay đổi giao diện thiết bị |
| `admin-web/dist/admin-shell.mjs` | Icon renderer, nhận diện menu/brand và chọn giao diện |
| `admin-web/dist/app.mjs`, `dashboard-page.mjs`, `index.html` | Áp dụng vào các điểm vào và thao tác hiện có |
| `admin-web/dist/licenses/` | ISC/MIT, manifest nguồn/hash và ánh xạ icon với app |
| `tool/build_admin_icons.py` | Tái tạo từ archive Lucide có font đúng hash đã ghim |
| `admin-web/test/appearance.test.mjs` | Lưu theme, fallback, thiết bị/tab và kiểm nguồn icon/màu/giấy phép |
| `admin-web/test/browser-identity.cjs` | QA Chrome cô lập cho giao diện sản phẩm |
| `admin-web/test/app-dom.test.mjs`, `release-contract.test.mjs` | Cập nhật nhãn nút thêm và xác minh asset đi kèm gói release |

## Kiểm tra thực tế

- `npm --prefix admin-web run check`: qua, exit 0; gồm module icon và script theme mới.
- `npm --prefix admin-web test`: **104/104 qua**, 0 lỗi/bỏ qua. Bao gồm
  các kiểm thử nghiệp vụ/DOM hiện có và 5 kiểm thử nhận diện/preference mới.
- `npm --prefix admin-web run test:ui`: qua, exit 0, Chrome headless thật
  trên profile riêng. **9 trang × 4 chiều rộng × 2 theme = 72 lượt trang**:
  1440, 1024, 390, 320px; không tràn ngang, canvas đen/trắng đúng, Inter,
  đủ icon điều hướng, vùng bấm header từ 44px.
- Kiểm drawer mobile bằng bàn phím, thu gọn desktop, form thêm món ở mọi
  kích thước/theme, trang đăng nhập, đổi theme theo thiết bị và lưu sau
  reload. Không có JavaScript exception trong lần QA cuối.
- Đã xem ảnh thật của dashboard sáng/tối, AI, danh mục, đăng nhập và drawer.
  Ảnh nằm ở `build/admin-identity-20261110/`.
- `git diff --check`: qua. Không sửa Flutter nên không chạy lại build/test
  Android trong giai đoạn chỉ thay web.

Các lỗi đầu ở harness mới đã sửa: giả lập EventTarget của linkedom, chờ
document mới tải xong trước khi đọc control và chờ transition drawer kết
thúc trước chụp ảnh. Không giảm assertion hoặc đổi dữ liệu để che lỗi.

## Dữ liệu của ảnh QA và phạm vi triển khai

QA browser chạy chính module giao diện với **adapter local trống**, nhãn
kiểm thử hiện trên trang. CSP chỉ cho kết nối cùng loopback; adapter không
import Firebase SDK, không đọc/ghi production và chặn save. Số 0/trạng thái
trống trong ảnh chỉ là điều kiện kiểm giao diện, **không phải số liệu khách
hàng/doanh thu hiện tại**. Adapter chỉ nằm trong file test, không đi vào
module sản phẩm hoặc gói phát hành.

Không thay Rules/schema/config Firebase, tài khoản hoặc billing; không
commit, push hay deploy. Chạy lại web local/tải lại trang để xem source mới.
Giấy phép và các asset theme/icon được test có mặt trong bundle chuẩn bị
release. Bước tiếp theo đề xuất: nghiệm thu trên web có đăng nhập thật rồi
phát hành Hosting theo yêu cầu riêng.
