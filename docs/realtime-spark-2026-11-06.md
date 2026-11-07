# Realtime trên Spark — 06/11/2026

**Đính chính 07/11:** dưới đây là lịch sử đợt triển khai. Rules đóng gói khi đó
chưa có quyền ghi deletion job và support_usage của app mới; 3 bài Rules không
bao phủ hai luồng này. Xem [đợt sửa và trạng thái mới](operations-hardening-2026-11-07.md).

## Trạng thái

Theo yêu cầu “vậy realtime đi”, đã triển khai web và Rules lên
<https://healthmate-admin-vn.web.app>. Không bật billing, không deploy Functions.
Đây là tiếp tục đợt đồng bộ hiện có, không mở thêm giai đoạn nghiệp vụ.

Đã đọc lại 8 file Hosting và Rules production: khớp bundle
`build/realtime-spark-release-20261106`. Ruleset mới:
`1cf2d419-c6e5-42d9-9d62-3126422e7768`, publish lúc 13:00 ngày 06/11, UTC+7.
Rules được tạo từ baseline production đọc ngay trước triển khai, chỉ thêm các
đường dẫn thống kê/revision có kiểm soát và áp dụng account lock cho admin.
Không deploy toàn bộ root Rules có các thay đổi local khác.

## Các luồng

- Web tự nhận thay đổi về thực phẩm, khách hàng/control/role, audit, cấu hình
  chatbot/quét ảnh/bảo trì, hỗ trợ và giao dịch Premium demo trong kỳ.
- Thống kê vận hành dùng `statisticsMode: firestore`, nghe đầy đủ bốn tập nhỏ:
  catalog, directory, controls, audit. Mỗi nguồn giới hạn 5.001 để phát hiện
  vượt 5.000; vượt giới hạn báo lỗi, không cộng một trang làm tổng. Tài khoản
  khóa chỉ tính UID còn trong directory. Hiện production có 158 món, 1 hồ sơ
  directory, 0 control và 7 audit ở thời điểm preflight; không dùng directory
  thay tổng Auth.
- Đã xuất một snapshot thật **3 tài khoản Firebase Auth**, có timestamp và
  nhãn cập nhật thủ công. Tổng này chưa tự thay đổi theo mọi lần tạo/xóa Auth;
  phần máy chủ vẫn chờ Blaze.
- App giữ các streams theo UID cho nhật ký, hồ sơ, goals/quest, thư viện và
  hội thoại. Policy thực phẩm ẩn lọc cache/USDA/chi tiết đang tải. Lịch sử bữa
  ăn và dữ liệu riêng tư không được chuyển lên admin.
- Báo cáo theo kỳ/tuần, mục tiêu, giấc ngủ và chi tiết món riêng/công thức đang
  mở nhận thêm listeners đúng nguồn/khoảng/document; thay đổi làm tải lại dữ
  liệu thật từ repository. Không cần Functions ở bản Spark.
- Listeners family dùng chung, autoDispose, chia báo cáo thành khoảng <=90
  ngày, giữ giới hạn bản ghi. Bữa ăn nghe dateKey và consumedAt cho legacy;
  mục tiêu nghe bản áp dụng trước khoảng và thay đổi trong khoảng. Không tự
  ghi bộ đếm/revision từ client. Chế độ `HEALTHMATE_SERVER_REVISIONS` mặc định
  false; chỉ bật trong tương lai sau khi Functions hoạt động.

## File chính

- `admin-web/dist/live-data.mjs`, `firebase.mjs`: profile thống kê trực tiếp,
  vô hiệu hóa snapshot chưa xác nhận trước khi ghép dữ liệu.
- `admin-web/tool/prepare-realtime-release.cjs`: profile `spark` không khai báo
  hay đóng gói Functions, giữ baseline production.
- `lib/core/data/private_data_changes.dart`, `user_data_revision.dart` và
  providers reports/weekly/nutrition_targets/wellness/food_library.
- `test/realtime_sync_test.dart`, `test/realtime_spark_integration.dart`,
  `admin-web/test/realtime-sdk.integration.mjs`.

## Kiểm thử thực tế

| Kiểm tra | Kết quả |
| --- | --- |
| dart format các file của đợt này | Qua |
| flutter analyze --no-pub | Không issue |
| flutter test --no-pub --reporter json | **952/952**, không lỗi/bỏ qua |
| npm test --prefix admin-web | **66/66** |
| npm run check --prefix admin-web, check tool đóng gói | Qua |
| Spark operational counters, Firebase Web SDK thật | **1/1** trên Auth/Firestore emulator, không có Functions |
| Flutter Chrome, hai Firebase SDK clients | **3/3**: nước thêm/sửa/xóa, chi tiết món sửa/xóa, mục tiêu đổi từ client thứ hai |
| Rules chính xác của bundle triển khai | **3/3**: quyền admin, revision riêng UID/server-written, token admin bị khóa |
| Build APK debug bằng cấu hình Android hiện có | Thành công |
| Audit source, git diff --check | Qua |
| Deploy firestore:rules + hosting | Thành công; 27 file Hosting |
| HTTP và Rules đọc lại | 8 file Hosting và Rules khớp release |

Một test mới ban đầu dùng khoảng 60 ngày nhưng kỳ vọng vượt giới hạn 90 nên
fail; đã sửa input thành khoảng >90 ngày và chạy lại toàn suite đạt 952/952.
Lint thiếu braces trong test SDK đã sửa, analyze chạy lại sạch. Giữ logs lần
lỗi và lần đạt. Gradle còn cảnh báo KGP cho Flutter tương lai, APK hiện tại vẫn
build thành công. Không nới Rules/assertion để che lỗi.

Bằng chứng: `build/realtime-spark-{admin,check,sdk,flutter-sdk,deploy}.log`,
`build/realtime-spark-analyze-final.log`, `build/realtime-spark-flutter-final.jsonl`,
`build/realtime-spark-flutter-summary.json`, `build/realtime-spark-http-verification.json`,
`build/realtime-spark-deployed-rules-20261106/metadata.json`.

## APK và phần cần nghiệm thu

APK: `build/releases/healthmate-realtime-spark-debug.apk`.
Hash/cấu hình: `build/realtime-spark-apk-manifest.json`. Dùng App Check debug
token cục bộ đã có; không ghi token vào tài liệu hoặc source. Đây là APK debug
để kiểm thử riêng, không phải bản ký để phát hành store.

Đã mở trang đăng nhập production bằng trình duyệt. Chưa đăng nhập thay chủ
tài khoản hoặc sửa dữ liệu thật để thử. Không tạo món, tài khoản hay doanh thu
giả trên production; thao tác dữ liệu production duy nhất ngoài deploy là
snapshot tổng Auth thật. Kiểm thử thay đổi dữ liệu chạy trên emulator cô lập.

Không có điện thoại hoặc Android emulator kết nối khi kiểm tra ADB. Người dùng
cần cài APK mới để nhận đầy đủ thay đổi app, mở lại web (Ctrl+F5 nếu tab cũ)
và đăng nhập admin như thường lệ. Chưa nghiệm thu hai thiết bị trên production.

## Giới hạn và bước tiếp theo

Spark có quota đọc/ghi, không phải miễn phí vô hạn. Không hứa độ trễ 0 ms hoặc
nhận thay đổi khi mất mạng. Tổng Auth và xử lý xóa Auth từ Console vẫn cần
Functions; web hiện có khóa/mở, chưa có nút xóa Auth. Premium vẫn demo (APK giữ
demo tắt theo cấu hình hiện có); Bài tập luyện và các mục web chưa triển khai
không được tính là đã có nghiệp vụ realtime.

Tiếp theo đề xuất: cài APK và nghiệm thu app/web thật. Nếu sau này dùng Blaze,
phải lấy baseline Rules mới, deploy Functions, bootstrap rồi đổi profile.
Không thực hiện phần đó trong lượt này.
