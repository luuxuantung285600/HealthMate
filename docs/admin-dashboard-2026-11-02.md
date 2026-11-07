# Dashboard admin — 02/11/2026

Phạm vi người dùng yêu cầu: sửa dashboard quản trị để thấy tổng tài khoản
đã đăng ký, doanh thu Premium và các số liệu kinh doanh liên quan. Đây là
một thay đổi admin riêng, không mở lại các giai đoạn MVP hoặc phần tập luyện.
Source candidate đã hoàn thiện và kiểm thử local; **chưa publish, chưa deploy
Rules và chưa ghi thống kê production**.

## Đính chính bàn giao — 03/11/2026

Ảnh `build/admin-dashboard-20261102/dashboard-desktop.png` trước đó dùng
fixture 42 tài khoản, 240.000đ, 12 giao dịch, 4 khách mua. Đó là dữ liệu
test do agent dựng để kiểm bố cục, **không phải số liệu dự án**. Việc dùng
ảnh này để bàn giao cho người dùng là không phù hợp yêu cầu số liệu thật;
ảnh cũ chỉ giữ làm bằng chứng kiểm thử, không dùng để trình bày hiện trạng.

Đã đọc lại production ở **00:58:12 ngày 03/11/2026 UTC+7**, chỉ GET Auth/
config và POST các endpoint truy vấn read-only của Firestore, không ghi:

| Chỉ số | Số được máy chủ trả về |
| --- | ---: |
| Tài khoản Auth còn tồn tại | 3 |
| Directory đã đồng bộ | 1 |
| Tài khoản đang tạm khóa | 0 |
| Món trong catalog Firestore | 158 |
| Nhật ký thao tác quản trị | 7 |
| Receipt Premium demo từ 01–03/11/2026 | 0 |
| Số tiền mô phỏng trong kỳ | 0 VND |
| UID mua trong kỳ | 0 |

Không lấy danh mục offline trong APK làm count Firestore. Không có bản cấu
hình runtime ở lần đọc này; hiển thị chưa có cấu hình, không tự bật AI.
Receipt lưu trên server vẫn có nghĩa là giao dịch demo, không phải bằng
chứng thanh toán tiền thật.

Ảnh thay thế: `build/admin-dashboard-real-20261103/dashboard-real-desktop.png`
và `dashboard-real-mobile.png`. Chúng render snapshot **đọc từ Firebase**,
không seed số, không sửa số trên ảnh; có thời điểm đọc và nhãn bản đối
chiếu chỉ đọc. Đây là bản tại máy, không phải ảnh chứng minh đã triển khai
web online. Bản đối chiếu vô hiệu hóa thao tác ghi/quản trị vì chỉ phục vụ
xem số liệu; app/web thật không thêm nút giả hoặc bỏ Auth/App Check.

Kiểm tra Chrome thật1440/390px: tổng Auth3, tiền mô phỏng0 VND,
giao dịch0, khách0; không tràn ngang hoặc lỗi JS. Các script đọc/ảnh/JSON
chỉ nằm trong build bị ignore, không chứa credential và không được đưa
lên Hosting. Không chạy lại suite Flutter/Rules vì không sửa mã sản phẩm
hoặc Rules trong lượt đính chính này.

## Các chỉ số

| Chỉ số | Cách lấy và giới hạn |
| --- | --- |
| Tổng tài khoản đăng ký | Đọc một document `admin_statistics/accounts` do chủ dự án đồng bộ từ Firebase Authentication. Gồm tài khoản admin, chưa xác minh, bị vô hiệu hóa còn tồn tại; không phải số online hay tổng đăng ký tích lũy sau khi đã xóa. Hiển thị thời điểm và nhãn cập nhật thủ công. |
| Doanh thu Premium demo | Cộng receipt demo hợp lệ trong kỳ, không lấy số gói nhân giá. Không có thanh toán thật. |
| Giao dịch Premium demo | Số receipt mô phỏng thành công trong kỳ. |
| Khách mua Premium demo | Số UID khác nhau có receipt trong kỳ; không phải số gói còn hạn. |
| Tài khoản đã đồng bộ | Count `user_directory`, tách khỏi tổng Firebase Auth. |
| Vận hành | Count danh mục, trạng thái tạm khóa và audit; giữ quyền dữ liệu cũ. |

Chọn tháng này, hôm nay, 7 ngày hoặc 30 ngày qua theo UTC+7, tính cả ngày
cuối. Chỉ thay kỳ doanh thu, không biến tổng tài khoản thành số đăng ký mới
trong kỳ. Biểu đồ có bảng số liệu mở theo nhu cầu; 5 giao dịch gần nhất
trong kỳ có lối sang báo cáo/Excel đã tồn tại.

Revenue dùng lại bộ đọc phân trang và validator hiện có, tối đa 5.000 giao
dịch/kỳ. Quá giới hạn, sai receipt hoặc lỗi quyền/mạng thì không hiện tổng
thiếu hoặc số 0 giả; có thử lại và chọn kỳ ngắn hơn. Đổi kỳ, refresh,
đăng xuất/thu hồi quyền/chuyển trang bỏ kết quả cũ. Cấu hình, count và
revenue lỗi độc lập; thiếu cấu hình không bị coi là tính năng đang bật.
Không thêm listener, chart package, dependency, AI hoặc nguồn thanh toán.

## Đồng bộ tổng tài khoản

Firebase Web Auth SDK không có quyền liệt kê tất cả tài khoản. Cũng không
cấp quyền đọc toàn bộ `users` để đếm vì đó là hồ sơ sức khỏe riêng tư.
Thay vào đó, helper dùng **phiên Firebase CLI của chủ dự án đang có**:

```powershell
# Chỉ đọc Auth, in tổng; mặc định KHÔNG ghi Firestore.
node admin-web/tool/sync-account-statistics.cjs

# Chỉ chạy khi chủ dự án yêu cầu cập nhật thống kê thật:
node admin-web/tool/sync-account-statistics.cjs --apply
```

Helper cố định project `healthmate-app-20261013`, chỉ yêu cầu `localId`
để loại trùng, phân trang 1.000 và tối đa 100 trang. Token ở bộ nhớ, không
ghi/in danh tính hoặc secret. Nếu Firebase CLI ở chỗ khác, truyền
`--cli-root <thư-mục-firebase-tools>`. Không cần service-account, Functions,
backend hoặc billing mới. Firebase CLI internal auth adapter phụ thuộc bản
CLI đang cài; nếu adapter thay đổi, helper báo lỗi, không tự lấy credential
bằng cách khác.

Chỉ sau khi tải đủ và kiểm dữ liệu, `--apply` ghi đúng một document tổng,
server timestamp và precondition phiên bản để một phiên đồng bộ cũ không
đè bản mới. Chạy lại cập nhật document này; không thay tài khoản/dữ liệu
sức khỏe hoặc receipt. Nếu timeout lúc commit, kết quả chưa được xác nhận;
đọc/đồng bộ lại trước khi coi là đã xong.

Đây là **bản thống kê cập nhật thủ công**, không phải bộ đếm realtime.
Chủ dự án chạy lại sau đăng ký/xóa tài khoản. Liệt kê Auth nhiều trang không
là snapshot nguyên tử trước các thay đổi đồng thời; nên chạy lúc ít biến
động. Chưa có nguồn/Rules chưa rollout/dữ liệu sai sẽ hiển thị “Chưa có số
liệu”, không lấy `user_directory` thay thế.

Kiểm tra production chỉ đọc ngày 02/11 ghi nhận **3** tài khoản, một trang,
`applied:false`; không lưu danh sách UID hoặc ghi số này lên server.

## Rollout còn chờ chủ dự án yêu cầu

1. Đóng gói web và lấy bản Rules production hiện hành làm baseline; chỉ
   bổ sung match `admin_statistics/accounts` get bởi verified admin, client
   không list/write. Kiểm thử bản ghép trước khi phát hành. Root Rules đang
   có các candidate khác, **không deploy toàn bộ root để đưa dashboard lên**.
2. Publish Hosting sau khi được yêu cầu; không thay App Check/quyền admin.
3. Chạy đồng bộ có `--apply`, kiểm tra số tổng và thời gian trên web thật.
   Hiện chưa thực hiện ba bước này, chưa nghiệm thu tài khoản admin thật.

## Kiểm chứng

- Syntax check admin và helper: qua.
- Node/DOM/helper: **55/55** qua.
- Firebase Web SDK thật trên Auth/Firestore Emulator: **9/9** qua, gồm
  aggregate get, server timestamp, tạo/cập nhật summary có precondition.
- Toàn bộ Firestore Rules Emulator: **128/128** qua. Test mới chặn Alice,
  Bob, guest, admin chưa xác minh/đã thu hồi, list, document khác và mọi
  client ghi/xóa; admin vẫn không đọc được hồ sơ sức khỏe người khác.
- Chrome headless: 1440, 390 và 320 px, không tràn ngang/JS exception; biểu
  đồ hoạt động dưới CSP không cho inline style. Ảnh trong
  `build/admin-dashboard-20261102/` dùng fixture, được ghi nhãn rõ.
- Source secret audit: 0 finding; không phải chứng minh audit toàn bộ APK.
- Không sửa Dart/Android; đã cân nhắc `dart format`, `flutter analyze`,
  `flutter test`, không chạy vì phạm vi chỉ web/Rules, không chạy lại Android.

Lượt kiểm Rules đầu dùng sai working directory của runner, một số suite
không tìm thấy `../firestore.rules`. Đã sửa runner về `rules-tests` rồi chạy
lại đầy đủ 128/128; không đổi assertion hoặc Rules để giấu lỗi. DOM test
đầu bắt cả giá gói 20.000 ₫ trong chú thích khi kiểm dữ liệu tới muộn; sửa
assertion kiểm đúng ô tổng doanh thu và UID nhạy cảm, giữ kiểm tra race.
Log `sdk.log`, `rules.log`, `rules-initial-cwd.log` nằm trong thư mục build
nêu trên. Emulator do task tạo đã dừng sau kiểm thử.

Tài liệu Auth REST đã đối chiếu ngày 02/11/2026:
[projects.accounts.batchGet](https://cloud.google.com/identity-platform/docs/reference/rest/v1/projects.accounts/batchGet).
