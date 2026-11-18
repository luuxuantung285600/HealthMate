# Tìm thêm GIF nữ không cần tài khoản — 17/11/2026

> Cập nhật lượt rà soát mở rộng 18/11/2026: đã kiểm tra toàn bộ 1.500 ID/1.324 GIF tải được, tìm thêm 6 mẫu nữ không có nhãn giới tính. App/admin hiện **60 bài / 10 mẫu nữ**. Xem [báo cáo đầy đủ](exercisedb-full-visual-audit-2026-11-18.md). Nội dung bên dưới là lịch sử.



## Trạng thái và phạm vi

Tiếp tục Giai đoạn 11 theo yêu cầu tăng số GIF nữ. Người dùng xác nhận chỉ
tìm GIF miễn phí không cần tài khoản, giữ yêu cầu nhân vật minh họa thay cho
người thật. Chưa tìm thêm được media đủ điều kiện để nhập vào sản phẩm trong
lượt này; danh mục vẫn có 54 bài, trong đó bốn bài có GIF nữ đã xác minh.

Không sửa mã nguồn app/admin, schema, Rules, dependency hoặc dữ liệu sản phẩm.
Không dùng số lượng bài của cả thư viện nhà cung cấp làm số GIF nữ đã có.

## Nguồn đã kiểm tra

### ExerciseDB OSS và GitHub chính thức

- Đọc lại README, nhánh GitHub chính thức (hiện chỉ công khai `main`), danh
  sách repo của tổ chức, OpenAPI OSS và tài liệu V1/V2 hiện hành.
- Bảy tên có nhãn nữ trong dữ liệu V1 trước đây vẫn chỉ có bốn tệp hoạt động
  đã ghi ở `female-exercise-gifs-2026-11-17.md`; ba URL còn lại bị 404 trong
  lượt xác minh trước.
- Kiểm tra thêm `wWFspEi` (smith single leg split squat) và `HsjbB1z` (smith
  sprint lunge) vì tên không ghi giới tính: API và GIF HTTP 200 nhưng mở khung
  hình thật đều là nhân vật nam. Không dùng chúng làm GIF nữ.
- Không kết luận rằng mọi GIF nữ đều phải có chữ `female` trong tên, hoặc
  rằng trên toàn Internet chỉ tồn tại bốn GIF phù hợp.

Nguồn: [repository chính thức](https://github.com/ExerciseDB/exercisedb-api),
[V1](https://docs.ascendapi.com/products/edb-v1/overview.md),
[OpenAPI OSS](https://oss.exercisedb.dev/swagger).

### ExerciseDB V2 / RapidAPI

Tài liệu chính thức nói gói miễn phí có media watermark, cần tài khoản và
API key RapidAPI; media là ảnh/video MP4. Trang pricing tại thời điểm đọc
công bố BASIC miễn phí, 2.000 request/tháng theo hard limit và thư viện 200
bài, không phải toàn bộ thư viện hơn 11.000 bài. Chưa có tài khoản để xác
minh số bài nữ nằm trong tập con này. Người dùng đã chọn không dùng nguồn
cần tài khoản nên không triển khai hướng này.

Nguồn: [V2](https://docs.ascendapi.com/products/edb-v2/overview.md),
[pricing](https://rapidapi.com/ascendapi/api/edb-with-videos-and-images-by-ascendapi/pricing).

### Dataset GitHub đóng gói sẵn 1.324 bài

Đọc README và NOTICE của `hasaneyldrm/exercises-dataset`. Repository nói
media thuộc Gym visual, được phân phối theo quyền riêng của chủ repo; người
tái sử dụng phải xem điều khoản và có giấy phép của mình khi được yêu cầu.
MIT cho code/data không tự cấp phép media. Chưa có quyền media phù hợp để
nhập thêm GIF từ repo này.

Nguồn: [NOTICE của repository](https://github.com/hasaneyldrm/exercises-dataset/blob/main/NOTICE.md).

### wger

- Đọc đủ 394 bản ghi của endpoint exerciseimage (không còn trang kế tiếp).
  Có năm URL GIF; cả năm HTTP 200 và giải mã được nhiều khung.
- Xem khung đầu/giữa của cả năm. Bốn tệp là người thật hoặc nhân vật nam.
  Một tệp là nhân vật nữ: image 548, exercise 1593, Smith Machine Split Squat.
- wger khai báo CC-BY-SA 4.0 cho image 548, nhưng metadata trỏ về bài gốc
  Docteur Fitness và không ghi tên tác giả của ảnh. Bài gốc ghi credit
  Aliaksandr Makatserchyk; chưa tìm được tuyên bố cấp quyền CC tại nguồn gốc.
  Đây là ứng viên cần xác minh quyền, chưa phải media đã được chấp thuận để
  tích hợp. Không khẳng định người tải lên đã vi phạm hoặc chắc chắn có quyền.

Nguồn: [API ảnh wger](https://wger.de/api/v2/exerciseimage/?format=json&limit=1000),
[chi tiết bài](https://wger.de/api/v2/exerciseinfo/1593/?format=json),
[bài gốc](https://www.docteur-fitness.com/split-squat-a-la-smith-machine).

## Bằng chứng và kiểm tra

Tài liệu mạng, kết quả đọc API, bản chụp khung GIF và bộ lọc pricing công khai
lưu trong ignored `build/exercise-female-expansion-20261117/`, gồm
`smith-candidate-probe.json`, `smith-candidates.png`, `wger-images.json`,
`wger-gif-review.json`, `wger-review.png`, `v2-public-plans.json` và các trang
nguồn đã đọc. Tệp media chỉ phục vụ đánh giá cục bộ, không vào assets/app.

Không chạy lại Flutter/admin tests vì lượt này chỉ nghiên cứu và cập nhật tài
liệu, không thay đổi hành vi sản phẩm. Các kết quả 99 Flutter / 149 admin của
lượt bổ sung bốn GIF trước được giữ nguyên, không tính thành test mới.

## Phần chưa hoàn tất

Chưa đạt yêu cầu tăng thêm nhiều GIF nữ theo đồng thời các điều kiện hiện có.
Không có gói trả phí, tài khoản hoặc cấu hình Firebase nào được tạo. Chỉ có
thể nhập thêm khi xác minh được tệp phù hợp và quyền dùng của nguồn đó.
