# Đồng bộ thời gian thực app và admin — 06/11/2026

## Trạng thái và phạm vi

Hoàn thiện **bản kiểm thử local** cho yêu cầu đồng bộ mọi luồng dữ liệu hiện có
giữa app và web, gồm cả báo cáo trong app. Người dùng đã đồng ý bổ sung Cloud
Functions và khả năng phát sinh chi phí. Kiểm tra read-only dự án
`healthmate-app-20261013` trả `billingEnabled: false`; người dùng chọn bật Blaze
sau và hoàn thiện bản kiểm thử trước. **Chưa triển khai Functions/Rules/Hosting,
chưa ghi dữ liệu production, chưa cài APK vào điện thoại.**

Đây là một đợt cải thiện đồng bộ theo yêu cầu hiện tại, không tự chuyển sang
giai đoạn tính năng khác. Menu Bài tập luyện trên web vẫn ghi chờ triển khai.
Không bổ sung quản lý bài tập hoặc quyền đọc hồ sơ sức khỏe cho admin.

## Các luồng đã xử lý

| Luồng hiện có | Cơ chế và hành vi |
| --- | --- |
| Tổng quan web | Lắng nghe thống kê Auth, thống kê vận hành, cấu hình và toàn kỳ doanh thu; tự đổi phạm vi khi qua nửa đêm UTC+7. |
| Đăng ký/xóa Auth | Functions thế hệ 1 nhận sự kiện tạo/xóa, cập nhật tổng đăng ký và danh sách tối thiểu. Tính cả tài khoản chưa xác minh. Xóa Auth khóa quyền dữ liệu của phiên dùng ID token cũ. |
| Khách hàng | Lắng nghe 25 hồ sơ trong trang, cùng role/control của chính các UID đang hiện; tên, khóa/mở, vai trò và xóa khỏi danh sách tự cập nhật. |
| Thực phẩm | Web nghe trang đang xem; app tiếp tục nghe catalog. Policy món bị ẩn lọc thêm cache, USDA và chi tiết đang tải. Khôi phục cập nhật policy; không sửa lịch sử bữa ăn hay món riêng. |
| Premium | Nghe giao dịch trong kỳ để cập nhật tổng, biểu đồ, giao dịch mới và báo cáo. **Vẫn là Premium demo**, không tích hợp thanh toán thật. |
| Hỗ trợ khách hàng | Danh sách ticket và cuộc trao đổi cập nhật trực tiếp, chờ parent/messages khớp cùng phiên bản. Giữ phản hồi đang soạn; không khôi phục nội dung ticket đã đánh dấu xóa. |
| AI, quét ảnh, bảo trì | Web nghe cấu hình; app đã nghe cấu hình/quyền. Giữ bản nháp cài đặt khi admin khác thay đổi, dùng phiên bản cũ để chặn ghi đè xung đột. Cờ build và tình trạng dịch vụ AI vẫn được ưu tiên. |
| Nhật ký, hồ sơ, mục tiêu, quest, thư viện, hội thoại | Giữ các streams theo UID đã có trong app; chi tiết món riêng/công thức đang mở cũng tải lại khi sửa hoặc xóa ở thiết bị khác. Không sao chép hồ sơ, nhật ký hoặc hội thoại riêng tư lên admin. |
| Báo cáo dinh dưỡng/nước/vận động/cân nặng/mục tiêu/xác nhận ngày, tổng kết tuần và giấc ngủ | Functions cập nhật timestamp theo nguồn tại `user_sync/{uid}`. Một listener dùng chung trong app làm tải lại đúng báo cáo/nguồn khi thay đổi từ thiết bị khác. |
| Nhật ký quản trị | Lắng nghe trang audit; vẫn ghi nguyên tử cùng thao tác quản trị. |
| Đăng xuất/thu hồi quyền/chuyển trang | Hủy listeners của màn hình và phiên cũ, bỏ kết quả đến trễ. Web kiểm cả role và khóa của chính admin. |

## Thiết kế máy chủ

- `firebase-functions/src/index.cjs`: 7 background functions tại
  `asia-southeast1`: `authRegistered`, `authDeleted`, bốn bộ xử lý thống kê
  Firestore và `userDataChanged`. Không có HTTP endpoint quản trị công khai.
- `admin_statistics/accounts`: tổng Auth có `method: realtime_auth_events`,
  `ready`, `updatedAt`, `bootstrappedAt`. Không dùng directory làm tổng Auth.
- `admin_statistics/operations`: `foods`, `accounts` (directory), `suspended`
  (chỉ UID còn trong directory), `audits`. Món ẩn vẫn là document trong catalog.
- `admin_sync_state`: trạng thái tối thiểu để xử lý retry/trùng/lệch thứ tự.
  Bộ đếm Firestore tính từ dữ liệu hiện tại trong transaction; sự kiện Auth cũ
  không làm sống lại tài khoản đã xóa. Client không được đọc/ghi collection này.
- `admin_sync_runs`: mốc giờ máy chủ cho bootstrap, tránh lệch đồng hồ laptop.
- `user_sync/{uid}`: chỉ timestamp theo nguồn, không chứa hồ sơ sức khỏe. Client
  không tự ghi được; bị xóa/chặn tạo lại khi Auth đã xóa hoặc đang xóa tài khoản.
  Bao gồm `custom_foods` và `recipes` để chi tiết thư viện đang mở cập nhật theo
  dữ liệu hiện tại; snapshot bữa ăn đã lưu vẫn giữ nguyên lịch sử.
- Bootstrap duyệt dữ liệu hiện có và đối chiếu state trước khi đặt `ready:true`.
  Chạy lại không cộng trùng. Script thống kê thủ công cũ từ chối ghi đè bộ đếm live.

Không tạo bộ đếm từ client hoặc cộng thiếu một trang. Trang web giới hạn 25
document và tối đa 25 cặp role/control; tổng doanh thu live tối đa 5.000 giao
dịch/kỳ, vượt giới hạn báo lỗi và yêu cầu thu ngắn kỳ. Giữ giới hạn đọc báo cáo
app và phân đoạn khoảng ngày hiện có. Listeners được dừng khi không còn dùng.

Bootstrap có lượng đọc/ghi theo số document hiện có, tạo một state nhỏ cho mỗi
đối tượng thống kê. Functions giới hạn 3 instances/function, memory 256 MB,
timeout 120 giây; không có minInstances. Không hứa miễn phí hoặc đồng bộ 0 ms.

## Kiểm thử thực tế

| Kiểm tra | Kết quả |
| --- | --- |
| `dart format` các file Dart của đợt này | Hoàn tất |
| `flutter analyze --no-pub` | Không có issue |
| `flutter test --no-pub --reporter json` | **951/951**, không lỗi/bỏ qua |
| `flutter build apk --debug --no-pub --dart-define-from-file=config/release-candidate.json` | Thành công; chưa cài/test Android thật |
| `npm test --prefix admin-web` | **66/66** |
| `npm run check --prefix admin-web` và check tool đóng gói | Thành công |
| Firebase Web SDK thật: suite cũ | **9/9** trên emulator |
| Firebase Web SDK thật: suite realtime | **6/6** trên emulator |
| Kiểm tra bổ sung cuộc trao đổi bị đánh dấu xóa | Qua trên SDK thật; chạy riêng test support |
| `npm test --prefix firebase-functions` | **2/2** |
| Auth + Firestore + Functions emulator | **3/3**: đăng ký chưa xác minh, xóa, retry cũ, bộ đếm, revision tạo/sửa/xóa từng nguồn (gồm món riêng/công thức), bootstrap lặp |
| Firestore Rules toàn suite | **129/129**, có chặn đọc chéo revision và giả mạo thống kê |
| Rules của bundle tối thiểu dựa trên production | **3/3**: quyền admin, UID riêng tư, khóa admin với ID token cũ |
| `git diff --check` | Qua; cảnh báo CRLF sẵn có của workspace không phải lỗi whitespace |

Log nằm trong `build/realtime-*.log`, `build/admin-realtime-*.log`,
`build/realtime-flutter-final.jsonl` và `build/realtime-flutter-summary.json`.
Log các lần sửa lỗi cũng được giữ, không coi lần lỗi là lần đạt cuối.

Đã phát hiện và sửa lỗi reset trang duyệt món khi policy ban đầu rỗng; thêm test
chặn cache/USDA và kết quả chi tiết đến sau khi món bị ẩn. Một lần cold discovery
Functions vượt 10 giây; chuyển khởi tạo Firestore sang khi cần, chạy lại với
`FUNCTIONS_DISCOVERY_TIMEOUT=60` thành công. Emulator dùng Node 24 của máy;
runtime triển khai cấu hình Node 22. APK có cảnh báo tương thích KGP cho phiên
bản Flutter tương lai; build hiện tại vẫn thành công. Audit dependency Functions
còn 6 cảnh báo mức moderate từ dependencies gián tiếp, không có high/critical;
không nâng cấp dependencies của app/web để xử lý ngoài phạm vi này.

## Bản để xem xét và triển khai sau

- APK: `build/app/outputs/flutter-apk/app-debug.apk`; cấu hình quản trị bật,
  Premium demo/chatbot vẫn theo `config/release-candidate.json`. Hash/size thật
  ở `build/realtime-apk-manifest.json`.
- Bundle: `build/realtime-review-20261106-v2/` chứa site, source Functions,
  Rules, `firebase.review.json` và manifest; **chưa publish**.
- Rules trong bundle được tạo từ bản Rules production đọc lại ngày 06/11,
  chỉ thêm hai đường dẫn đồng bộ và áp dụng khóa cho quyền admin. Không tự mang
  toàn bộ thay đổi Rules của các đợt local trước lên production.
- `firebase.realtime.json` chỉ cấu hình codebase Functions để tránh deploy nhầm
  root Rules; `firebase.realtime-emulators.json` dành riêng cho kiểm thử local.

Sau khi người dùng bật Blaze: kiểm tra billing lại, đọc lại Rules production,
tạo bundle mới từ baseline mới, đối chiếu diff và chạy test Rules bundle. Sau đó
mới deploy Functions và Rules đã kiểm, bootstrap dữ liệu thật, xác nhận
`ready:true`, publish Hosting và cài APK mới. Không chạy seed lên production.

Bootstrap production dùng ADC hoặc phiên Firebase CLI đã đăng nhập, không tạo
service-account JSON:

```powershell
# Chỉ chạy sau khi Functions và Rules đã triển khai, Blaze đã được xác nhận.
$env:FUNCTIONS_DISCOVERY_TIMEOUT = '60'
node firebase-functions/tool/bootstrap.cjs --apply --cli-auth
```

Chạy lại kiểm thử tích hợp local:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
$env:FUNCTIONS_DISCOVERY_TIMEOUT = '60'
firebase emulators:exec --config firebase.realtime-emulators.json --only auth,firestore,functions --project demo-healthmate-admin "node admin-web/seed-emulators.mjs --extended && node --test firebase-functions/test/emulator.integration.cjs && node --test admin-web/test/realtime-sdk.integration.mjs"
```

## Giới hạn cần giữ rõ

- Thời gian thực cần có mạng, đúng Firebase project và bản app/web mới. Máy
  offline không thể nhận thay đổi mới; dữ liệu cache không phải xác nhận máy chủ.
- Auth/Functions cập nhật sau khi sự kiện được xử lý, có độ trễ mạng/cold start.
  Firebase Admin **bulk `deleteUsers`** không phát từng sự kiện xóa: cần dùng
  quy trình từng UID hoặc bootstrap/reconcile sau thao tác bulk/import ngoài app.
- Web chưa có nút xóa Firebase Auth; hiện có khóa/mở quyền. Không tự thêm thao tác
  xóa tài khoản thay người dùng. Vô hiệu hóa Auth trực tiếp trong Console không
  có cùng hook `onDelete`; khóa trong web dùng `account_controls` để cập nhật ngay.
- Premium vẫn demo. Bật cấu hình chatbot/quét ảnh không xác nhận dịch vụ AI đủ
  điều kiện hoạt động hoặc vượt qua cờ tắt trong build.
- Chưa kiểm thử hai thiết bị Android/web production; phải làm sau triển khai.
  Chức năng web chưa được triển khai trước đó không được ghi nhận là đã realtime.

Giai đoạn tiếp theo đề xuất: triển khai bản đồng bộ đã kiểm thử sau khi bật Blaze,
rồi kiểm tra app/web thật. Không thực hiện trong lượt này theo lựa chọn người dùng.

Tham khảo đã đọc: Firebase [Auth events](https://firebase.google.com/docs/functions/auth-events),
[Firestore listeners](https://firebase.google.com/docs/firestore/query-data/listen),
[Functions setup/Blaze](https://firebase.google.com/docs/functions/get-started).
