# HealthMate Admin — giao diện tối theo ảnh mới, 06/11/2026

## Phạm vi và trạng thái

Giai đoạn tùy chọn 11, phần polish web admin theo yêu cầu riêng. Thay phong
cách sáng/gradient hồng tím bằng nền đen, sidebar đen, panel xám đậm, viền
mảnh, chữ sáng và điểm nhấn xanh dương theo ảnh mới. Hoàn tất bản source
và kiểm tra local; **web online chưa cập nhật**.

Giữ toàn bộ thay đổi chưa commit từ các lượt dashboard trước. Không thêm
dependency, thay backend/Rules/schema hoặc ghi dữ liệu production. Không
commit, push hoặc deploy trong lượt này.

## Giao diện và hành vi

- Bốn chỉ số ở đầu trang: tổng đăng ký, doanh thu Premium demo, giao dịch
  demo và khách mua. Card xám đậm có icon xanh dương/xanh lá/cam/tím và
  đường nhấn mảnh; bỏ nền gradient sáng và họa tiết vòng tròn trước đó.
- Biểu đồ lớn bên trái dùng nét/diện tích xanh; trạng thái tính năng và
  tài khoản/vận hành xếp bên phải, giao dịch gần đây ở dưới. Giữ kỳ báo
  cáo, bảng số từng ngày, tải lại, lỗi, dữ liệu trống và lối báo cáo/Excel.
- Sidebar giữ Tổng quan, Doanh thu, Khách hàng, Thực phẩm, Bài tập luyện,
  AI Chatbot, Hỗ trợ khách hàng, Nhật ký quản trị và Cài đặt. Nhận diện
  HealthMate dùng logo nền xanh; footer hiển thị tài khoản đăng nhập thật
  và đăng xuất. Bản chỉ đọc không có user thì không dựng danh tính admin.
- Giữ thu gọn desktop/drawer mobile; Tab vòng trong menu gồm cả nút đăng
  xuất, Escape đóng và trả focus. Focus chờ drawer hiển thị, bỏ callback
  nếu trang đã thay shell trong lúc chờ.
- Bảng, lọc, form, dialog, hỗ trợ, trang AI và đăng nhập cùng dùng nền tối;
  `color-scheme: dark` áp dụng cho các control trình duyệt.
- Bài tập vẫn ghi rõ chờ triển khai, AI dùng cấu hình hiện có. Không thêm
  nút tìm kiếm/thông báo giả, chỉ số tăng trưởng, donut hoặc sparkline chưa
  có nguồn dữ liệu. Không thay luồng nghiệp vụ để mô phỏng nội dung ảnh.

## Dữ liệu và ảnh bàn giao

Ảnh dùng dữ liệu Firebase **đọc thật lúc 01:50:46 ngày 06/11/2026 UTC+7**:
Auth **3**, danh mục **158**, tài khoản đã đồng bộ **1**, tạm khóa **0**,
audit **7**. Kỳ **01–06/11/2026** có **0 giao dịch demo / 0 VND mô phỏng /
0 khách mua**. Không seed hoặc ghi server để có số liệu/đường biểu đồ.
Premium vẫn demo, chưa thu tiền thật; không có giao dịch thì biểu đồ là 0.

Ảnh chạy chính shell và dashboard sản phẩm với snapshot chỉ đọc tại máy,
có nhãn và thời điểm đọc. Adapter cung cấp tổng Auth vừa đọc để đối chiếu
giao diện, không có nghĩa summary đã được ghi lên production. Trên sản
phẩm, summary chưa có/không đọc được vẫn hiện “Chưa có số liệu”.

File build được ignore, không chứa token:

- `build/admin-dark-20261106/dashboard-real-desktop.png` — 1440 px.
- `build/admin-dark-20261106/dashboard-real-tablet.png` — 1024 px.
- `build/admin-dark-20261106/dashboard-real-mobile.png` — 390 px.
- `build/admin-dark-20261106/dashboard-real-small.png` — 320 px.
- `production-read.json`, `read-production.cjs`, `readonly-entry.mjs` và
  `preview.cjs` trong cùng thư mục là snapshot/công cụ đối chiếu local.

Thao tác ghi/chuyển trang bị vô hiệu riêng trong ảnh đối chiếu; sản phẩm
giữ điều hướng và thao tác hiện có. Không dùng ảnh test fixture làm bằng
chứng dữ liệu thật hoặc dùng lại ảnh của phong cách trước.

## File chính

| File | Thay đổi |
| --- | --- |
| `admin-web/dist/admin-theme.css` | Thay theme sáng bằng hệ màu/bố cục tối và responsive |
| `admin-web/dist/admin-shell.mjs` | Brand, tài khoản ở footer, logout, icon số liệu, focus drawer |
| `admin-web/dist/dashboard-page.mjs` | Card lên đầu, biểu đồ trái/thông tin phải, icon và chiều cao biểu đồ responsive |
| `admin-web/dist/index.html` | Khai báo color scheme tối |
| `admin-web/test/app-dom.test.mjs` | Hồi quy danh tính/footer và đăng xuất xóa dữ liệu hiển thị |
| `admin-web/README.md`, tiến độ và báo cáo kiểm thử | Ghi phong cách hiện tại và trạng thái source/online |

## Kiểm chứng

- `npm --prefix admin-web run check`: qua.
- `npm --prefix admin-web test`: **61/61 qua**, 0 lỗi/bỏ qua.
- Chrome headless với CSP: ảnh dữ liệu thật ở **1440/1024/390/320 px**,
  không tràn ngang trang, không JavaScript exception; các ô **3/0 ₫/0/0**
  khớp snapshot. Đã xem ảnh desktop/mobile.
- Chạy module `app.mjs` thật với adapter QA chỉ dùng loopback: **9 trang ×
  1440/390/320 px**; panel/input không còn nền sáng, không tràn ngang.
  Kiểm dialog thêm thực phẩm trống, form đăng nhập, Tab/Shift+Tab/Escape
  của drawer. Adapter chặn mọi save, không tải SDK Firebase hoặc gọi mạng
  production. Các danh sách QA rỗng, danh tính ghi rõ kiểm thử local; không
  chụp/bàn giao các màn QA làm bằng chứng dữ liệu dự án.
- Log: `build/admin-dark-20261106/{check,test,browser}.log`.
- `git -c core.safecrlf=false diff --check`: qua.
- `node tool/audit_source_secrets.cjs`: **622 source text files, 0 findings**;
  không quét credential store hoặc APK. Server/Chrome QA đã dừng.

Lần QA đầu phát hiện focus vẫn ở body khi drawer vừa bỏ visibility:hidden.
Đã đợi frame hiển thị trước khi focus, kiểm shell còn gắn vào DOM và menu
còn mở. Chạy lại toàn bộ browser QA qua, giữ assertions. Log trước sửa ở
`browser-initial.log` và `browser-focus-before-fix.log`; không coi các lượt
đó là lượt thành công.

Không sửa Dart/Android hoặc Firestore Rules nên không chạy lại Flutter
format/analyze/test, SDK Emulator hoặc Rules suites trong lượt này.

## Cần nghiệm thu và giới hạn còn lại

Không cần cấu hình Firebase mới cho theme. Người dùng xem ảnh/bản local;
bước tiếp theo đề xuất là nghiệm thu và rollout web, chưa tự thực hiện.
Summary Auth/Rules patch và đồng bộ thủ công vẫn theo báo cáo dashboard
trước; chưa chạy `--apply` hoặc deploy toàn bộ root Rules candidate.
Premium demo và phần quản lý bài tập chờ triển khai vẫn được ghi rõ.
