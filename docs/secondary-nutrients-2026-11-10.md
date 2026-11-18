# Muối, đường và chất xơ — 10/11/2026

Phạm vi: mở rộng dinh dưỡng trên Trang chủ theo yêu cầu người dùng (Giai đoạn 8),
kèm trường catalog/admin và mốc ngày cần thiết. Không thêm package, backend,
dịch vụ trả phí hoặc dữ liệu dinh dưỡng suy đoán.

Trang chủ giữ nhóm Đạm · Bột · Béo; vuốt hoặc chọn nút để xem Muối · Đường · Xơ.
Nhóm mới dùng tổng snapshot các món trong ngày đang xem, có thanh tiến độ và
nút mở form đặt mốc ngày. Chế độ sáng/tối và cỡ chữ lớn dùng theme hiện có.

Muối là muối quy đổi từ natri: natri (mg) × 2,5 / 1.000 = muối (g).
[WHO](https://www.who.int/news-room/fact-sheets/detail/salt-reduction) xác nhận
2.000 mg natri tương đương 5 g muối. Không đồng nhất natri với lượng muối thêm
khi nấu. Đường là đường tổng, gồm đường tự nhiên; không suy từ carbohydrate,
không áp giới hạn của đường tự do cho đường tổng. Chất xơ dùng dữ liệu hiện có.

Các mốc muối/đường/xơ do người dùng tự đặt, không có giá trị y tế mặc định.
Thiếu mốc hiển thị “Chưa đặt mốc”; lỗi tải có nhãn riêng. Thiếu dữ liệu ở một
món làm tổng chất đó hiện “Chưa đủ dữ liệu”; số 0 thật vẫn được giữ. Info trên
card giải thích đơn vị, công thức và cách hiểu. Mốc quá khứ giữ cách đọc theo
ngày hiệu lực, UI chỉ sửa từ hôm nay. Tính lại kcal/macros giữ ba mốc này.

Admin sửa đường tổng, natri và xơ trên mỗi 100 g; form xem trước muối, giữ
những vi chất khác và audit/version hiện có. Để trống gỡ dữ liệu chưa biết,
không chuyển thành 0. Món chỉ trong bundle cần bản ghi Firestore cùng ID để
admin quản lý như quy trình hiện có. Không tự điền thông tin thiếu cho catalog.

File chính:

- `home_nutrient_panels.dart`, `dashboard_screen.dart`, `nutrition_models.dart`,
  `food_nutrition_panel.dart`.
- Model/repository/form/card mục tiêu dinh dưỡng, personal planner và onboarding.
- `admin-web/dist/nutrition-values.mjs`, `validation.mjs`, `app.mjs`,
  `firestore.rules` và test liên quan.

Kiểm thử local đã chạy:

- `npm --prefix admin-web test`: 110/110 qua; `npm --prefix admin-web run check` qua.
- Auth/Firestore Emulator, Node admin/core Rules: 71/71 qua, gồm nullable/zero,
  bounds/key/type, quyền admin và chặn truy cập chéo UID.
- Flutter Web SDK thật trên Auth/Firestore Emulator: 1/1 qua, lưu mục tiêu,
  sửa/gỡ mốc, catalog và snapshot khẩu phần 200 g rồi đọc lại tổng đúng.
- Chrome admin: 72 lượt trang và form ảnh ở 8 kích thước/theme; không ghi production.
- Nhóm Flutter Home/target/planner trước kiểm thử toàn bộ: 71/71 qua.
- Toàn bộ Flutter: **1.233/1.233 qua**, exit 0, 2 phút 19 giây;
  `build/secondary-nutrients-full-tests-final.log`.
- `flutter analyze`: **No issues found**, exit 0, 38,2 giây;
  `build/secondary-nutrients-analyze-final.log`.
- `flutter build apk --debug --no-pub`: **thành công**, exit 0,
  assembleDebug 49,4 giây; `build/app/outputs/flutter-apk/app-debug.apk`.
  Có cảnh báo KGP tương thích Flutter tương lai từ plugin hiện có, không chặn
  build; không nâng dependencies ngoài phạm vi.
- Dart format 15 file: 0 thay đổi; `git diff --check` qua. Đã xem ảnh render
  nhóm mới sáng/tối bằng Inter/icon thật, với dữ liệu fixture.
- Lượt toàn bộ đầu phát hiện nút chuyển nhóm tràn ngang ở cỡ chữ lớn; đã sửa
  nhãn co giãn/xuống dòng. Assertion bảng dinh dưỡng cập nhật thêm hàng muối;
  không bỏ kiểm tra trạng thái thiếu dữ liệu. Toàn bộ lượt chạy lại đã qua,
  gồm giữ mốc khi cá nhân hóa và giữ cả mốc chưa lưu khi mở công cụ tính kcal.

Log: `build/secondary-nutrients-*.log`. Ảnh: `build/secondary-nutrients/light.png`,
`dark.png`. Test không chỉnh Rules hoặc credential để truy cập production.

Rollout: chưa deploy/push/ghi Firebase production, chưa nghiệm thu điện thoại
Android thật hoặc ký release. Cần phát hành Rules trước bản app/web mới để
cho phép field mục tiêu/catalog. Dữ liệu cũ đọc được, nhật ký cũ thiếu vi chất
giữ trạng thái chưa biết; sửa catalog không thay snapshot lịch sử. Ảnh QA dùng
fixture, không phải dữ liệu người dùng. Đề xuất tiếp: nghiệm thu bản phát hành
đồng bộ khi người dùng yêu cầu; không triển khai trong lượt này.
