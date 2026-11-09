# Rà soát và cải thiện xuất báo cáo — 08/11/2026

## Giai đoạn và phạm vi

Giai đoạn 10 — hoàn thiện, kiểm thử luồng xuất báo cáo hiện có trên app và
admin. Hoàn tất mã nguồn và kiểm thử local. Không thêm dependency, dịch vụ
trả phí, collection, Rules hoặc thay đổi quyền truy cập; không deploy/push.
Giữ nguyên những thay đổi đang có trước lượt này.

## Kết quả rà soát

Nền tảng hiện có đã dùng dữ liệu repository theo UID, tải khoảng có giới
hạn, xử lý lỗi thay vì xuất thiếu âm thầm, chống công thức CSV và dùng
inline string trong XLSX. Android chỉ xác nhận thành công sau khi ghi rồi
đọc lại so sánh byte. Các bảo vệ này được giữ nguyên.

Những điểm đã cải thiện:

- App trước đây chỉ có CSV chi tiết với cột kỹ thuật. Thêm lựa chọn
  **Tổng hợp theo ngày**, tiêu đề tiếng Việt, đơn vị rõ ràng.
- Sửa thứ tự bản ghi khi timestamp có độ chính xác microsecond: so sánh
  thời điểm thật thay vì chuỗi ISO, để chọn đúng lần cân cuối trong ngày.
- Trước đây tham số khoảng có giờ lẻ có thể được chuẩn hóa khi tải nhưng
  giữ giá trị khác lúc mã hóa. Nay từ chối khoảng không bắt đầu/kết thúc
  ở đầu ngày trước khi đọc repository.
- App hiển thị giai đoạn tải dữ liệu, chờ chọn nơi lưu, ghi/đọc lại; báo
  thành công kèm đúng khoảng ngày. Đưa mô tả kỹ thuật dài vào phần mở rộng.
- Admin trước đây xuất theo khoảng độc lập với bộ lọc trang. Nay cho chọn
  áp dụng tìm kiếm/nhóm/trạng thái/vai trò trên **toàn bộ khoảng xuất**,
  gồm mọi trang. Bộ lọc được chụp khi mở hộp xuất; không dùng riêng trang
  25 mục để tạo báo cáo. Khoảng mã mặc định dùng min/max ID của trang.
- Khoảng không có bản ghi phù hợp giữ hộp thoại và thông báo để điều
  chỉnh, không tải file rỗng khó hiểu cho các danh sách quản trị.
- Excel có sheet **Thông tin báo cáo**: nguồn, phạm vi, bộ lọc, số dòng,
  thời điểm tạo UTC. Doanh thu có tổng theo từng tiền tệ, hoàn tiền,
  đơn chờ đối soát và nhãn production/test/demo riêng.
- XLSX dùng Inter, tiêu đề xanh, xuống dòng, rộng cột/chiều cao hàng theo
  nội dung, giữ cố định dòng tiêu đề và bộ lọc Excel. Số có trên 15 chữ
  số giữ dạng text để tránh Excel làm mất chữ số; dữ liệu sai kiểu hoặc
  dư cột bị từ chối thay vì âm thầm mất cột.
- Dùng chung cơ chế yêu cầu trình duyệt tải xuống cho danh sách, doanh
  thu và bài tập: gỡ link, thu hồi blob, hiển thị lỗi/thử lại và kiểm tra
  phiên trước khi tải. Nút bài tập cũ không tải sau khi đăng xuất.

## Hợp đồng dữ liệu và cách sử dụng

App: **Cá nhân → Xuất nhật ký CSV**, hoặc nút xuất trên màn hình tiến độ.
Chọn Nhật ký chi tiết/Tổng hợp theo ngày, khoảng ngày và đồng ý xuất tệp
riêng tư. Khoảng trên màn hình tiến độ tiếp tục được điền sẵn.

CSV chi tiết giữ hợp đồng v1 cũ. Tổng hợp theo ngày có một dòng cho mỗi
ngày trong khoảng, tính từ snapshot món đã lưu, không dùng catalog hiện
tại hoặc tổng bữa cũ có thể lệch snapshot. Số bữa/món là số nhật ký;
không có nhật ký thì kcal/nước/phút/cân nặng để trống. Số 0 thật được giữ.
Dưỡng chất được phân biệt chưa có, thiếu một phần và đủ trong các món
đã ghi; không khẳng định một ngày đã ghi đủ. Cân nặng là lần cân cuối
trong ngày theo múi giờ thiết bị lúc xuất, kèm thời điểm UTC.

Admin: chọn xuất trong danh sách, kiểm tra khoảng và checkbox áp dụng bộ
lọc. Xuất thực phẩm chỉ gồm collection Firebase, không gồm toàn bộ thư
viện đi kèm app/món riêng. Danh bạ xuất là tài khoản đã đồng bộ, không
khẳng định đầy đủ Firebase Authentication. Các giới hạn này có trong file.

Doanh thu giữ số tiền chính xác dạng văn bản; không đổi/ghép tiền tệ.
Đơn chờ đối soát không cộng vào tổng; số còn sau hoàn chưa trừ phí/thuế
và không phải tiền ngân hàng nhận. File chỉ gồm order đã đồng bộ, vẫn
cần đối chiếu Play Console trước chốt sổ. Tệp tải về không tự cập nhật.

## File chính

- `lib/features/data_export/models/journal_csv.dart`
- `lib/features/data_export/data/journal_export_service.dart`
- `lib/features/data_export/presentation/journal_export_dialog.dart`
- `admin-web/dist/xlsx-export.mjs`, `report-download.mjs` (mới)
- `admin-web/dist/app.mjs`, `revenue-page.mjs`, `play-revenue-page.mjs`,
  `workouts-page.mjs`
- `admin-web/package.json`: kiểm tra syntax module tải file mới
- `test/report_export_quality_test.dart` (mới)
- `admin-web/test/xlsx.test.mjs`, `app-dom.test.mjs`

## Kiểm thử thực tế

- `dart format lib/features/data_export test/report_export_quality_test.dart`:
  hoàn tất; lần kiểm tra cuối không thay đổi định dạng.
- `flutter test --no-pub`: **1.057/1.057 qua**, 1 phút 44 giây.
- `flutter analyze --no-pub`: **không có vấn đề**, 28,7 giây.
- `npm test` trong admin-web: **99/99 qua**.
- `npm run check`: qua, bao gồm module tải báo cáo mới.
- Đọc hai XLSX kiểm thử bằng **openpyxl 3.1.5**, độc lập với encoder:
  ZIP CRC, XML/relationship, hai sheet, giữ tiêu đề/bộ lọc, font/màu,
  xuống dòng, text giống công thức, blank/zero và số 16 chữ số đều đúng.
- Preview với font Inter thật: **2/2 qua**, đã xem ảnh 390 px sáng 100%
  và 320 px tối 200%; mỗi chế độ có phần tùy chọn và xác nhận.
- `flutter build apk --debug --no-pub`: thành công, 24,5 giây.
- `git diff --check` trên các file sửa trong lượt: qua.
- `node tool/audit_source_secrets.cjs`: 697 file nguồn dạng text, không có
  phát hiện theo bộ mẫu kiểm tra; không phải kiểm toán credential store/APK.

Các lần thử trung gian phát hiện fixture BodyMetric thiếu/sai kiểu note,
widget test chưa cuộn đến dropdown, và DOM giả lập chưa mô phỏng checked
của input. Đã sửa harness/fixture, giữ nguyên assertion lọc/xuất rồi chạy
lại thành công; không bỏ kiểm thử hoặc nới điều kiện để che lỗi.

Log trong `build/`: `export-all-flutter-tests.log`, `export-analyze-final.log`,
`export-admin-final-tests.log`, `export-admin-check.log`, `export-preview.log`,
`export-apk.log`. XLSX kiểm thử và ảnh trong `build/export-quality/` đều
phục vụ kiểm thử; không ghi fixture vào Firebase production.

APK: `build/releases/healthmate-report-export-20261108-debug.apk`.
Kích thước 237.526.135 byte. SHA-256:
`5E08C7BD7DB8059F7D770F23BE09301780624AFDAA2B5FBC68A851B6F1CCAD1E`.
Có manifest JSON cùng tên.

## Giới hạn và việc còn lại

- Chưa nghiệm thu hộp chọn nơi lưu/nhà cung cấp tài liệu trên Android thật
  theo yêu cầu trước đó; không ký bản phát hành. APK là debug.
- Admin chưa được publish; bản web production chưa tự nhận mã nguồn này.
- CSV chỉ gồm bữa ăn/nước/vận động/cân nặng, không gồm giấc ngủ, hồ sơ,
  hội thoại, mục tiêu hay nháp. Giao diện nói rõ phạm vi.
- Giữ giới hạn 1–366 ngày, 10.000 bản ghi mỗi nguồn qua các phần tối đa
  90 ngày/2.000 bản ghi và 5 MB cho app; admin tối đa 5.000 dòng/12 MB.
- Các nguồn/phần được đọc riêng, không phải snapshot giao dịch nguyên tử
  xuyên mọi collection/trang. Nếu dữ liệu đổi trong lúc tải, xuất lại
  sau khi các thao tác đã hoàn tất.
- Trình duyệt chỉ xác nhận đã yêu cầu tải, không chứng minh lưu xuống đĩa.
- Cảnh báo KGP có sẵn vẫn xuất hiện khi build; build hiện tại thành công.

Bước tiếp theo đề xuất: nghiệm thu xuất tệp trên Android thật và trình
duyệt production khi người dùng sẵn sàng. Không tự triển khai bước này.
