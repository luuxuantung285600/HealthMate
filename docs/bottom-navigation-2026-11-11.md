# Thanh điều hướng — 11/11/2026

Giai đoạn 1 bổ sung: chỉ điều chỉnh điều hướng UI hiện có theo yêu cầu.

Thứ tự từ trái sang phải trên điện thoại:

1. Trang chủ
2. Nhật ký
3. Thêm món
4. Tập luyện
5. Tiến độ

Ô 4 dùng icon tạ của bộ icon hiện tại, mở danh sách buổi tập thật tại
`/workouts`; ô 5 dùng icon tiến độ và mở `/progress`. Thanh điều hướng vẫn
hiện khi duyệt danh sách tập. Menu Hồ sơ/Cá nhân chuyển sang ảnh đại diện
trên Trang chủ, không xóa màn hình hay chức năng tài khoản. NavigationRail
trên màn hình rộng dùng cùng nhóm điểm đến.

Đưa danh sách tập vào nhánh 7 của StatefulShellRoute, giữ các chỉ số nhánh cũ
để không đổi liên kết/luồng đang dùng. URL chi tiết và buổi tập không đổi.
Chi tiết và đồng hồ đếm buổi tập vẫn toàn màn hình trên root navigator;
khai báo `parentNavigatorKey` riêng trên cả hai route, vì GoRouter không tự
kế thừa navigator root từ route chi tiết xuống route session.
Thanh tab không cho phép bỏ qua bước xác nhận dừng hoặc rời tổng kết.

File sản phẩm: `lib/core/widgets/app_shell.dart`,
`lib/core/router/app_router.dart`. Điều chỉnh các test điều hướng hiện có,
helper mở Hồ sơ qua avatar và assertions buổi tập. Không đổi backend,
quyền, dữ liệu, media, thư viện hoặc tính toán tập luyện.

49 kiểm thử tập trung navigation/icon/core-scope đã qua; gồm 320/390 px,
chữ 1/1,5/2 và theme sáng/tối, tab được chọn, nút giữa và truy cập Hồ sơ.
`dart format` 12 file đã chạy; `flutter analyze --no-pub` sạch, exit 0,
12,0 giây ở lượt cuối. Bộ test chung cuối **1.289/1.289 qua**, không lỗi/skip,
exit 0, 134,6 giây. Thêm kiểm navigation bị ẩn trong timer/guard, được khôi phục
sau khi thoát đã xác nhận; 20/20 test trải nghiệm tập luyện qua sau sửa.

Lượt full đầu phát hiện 19 test player thất bại do session nằm ở branch
navigator phía sau trang chi tiết root. Đã sửa route session cũng dùng root;
không bỏ assertion hoặc thay mô hình buổi tập để che lỗi. Log đầu
`build/navigation-workouts-full-test.jsonl`, hồi quy player
`build/navigation-workouts-player-regression.log`; lượt full cuối được lưu riêng.

Cần hot restart ứng dụng đang chạy để dựng lại router. APK đã cài không tự
đổi UI theo source; cần chạy/cài lại bản build mới nếu dùng APK cũ.
Lượt này không phát hành APK, deploy web hoặc nghiệm thu Android thật.
Bước tiếp theo đề xuất là kiểm giao diện thiết bị khi được yêu cầu;
không triển khai thêm giai đoạn khác.
