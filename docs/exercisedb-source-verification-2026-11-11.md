# ExerciseDB: kiểm tra nguồn ngày 11/11/2026

> Cập nhật 17/11/2026: đã bổ sung bốn GIF nhân vật nữ, tổng danh mục hiện là
> **54 bài**; 50 bài dưới đây là danh sách tại thời điểm kiểm tra ban đầu.
> Đã rà soát bảy mã nữ, loại ba mã có metadata nhưng GIF HTTP 404. Bảng ID,
> kết quả kiểm tra media và kiểm thử mới ở
> [female-exercise-gifs-2026-11-17.md](female-exercise-gifs-2026-11-17.md).

## Phạm vi đã chấp thuận

Danh mục gồm đúng **50 động tác** dùng cho thử nghiệm miễn phí, phi thương mại theo lựa chọn của người dùng. Điều kiện OSS hiện tại không cho phép sản phẩm thương mại, SaaS hoặc hình thức kiếm tiền nếu chưa có gói/quyền phù hợp. Cần ghi công **[AscendAPI](https://ascendapi.com)** tại nơi dùng dữ liệu/GIF. Không suy ra quyền sử dụng media từ giấy phép mã nguồn AGPL của repository.

Nguồn chính thức đã đối chiếu:

- [ExerciseDB V1 overview](https://docs.ascendapi.com/products/edb-v1/overview.md).
- [Caching](https://docs.ascendapi.com/guides/caching.md): không cache dữ liệu/media của nhà cung cấp khi chưa được gói sử dụng cho phép; dùng ID ổn định để yêu cầu dữ liệu lúc cần.
- [Rate limiting](https://docs.ascendapi.com/guides/ratelimiting.md).
- [OSS API/OpenAPI](https://oss.exercisedb.dev/docs): mô tả giới hạn sử dụng phi thương mại, GIF 180p, giới hạn truy cập và ghi công.
- [Repository chính thức](https://github.com/ExerciseDB/exercisedb-api).

## Cách kiểm tra

Gửi GET trực tiếp tới endpoint `https://oss.exercisedb.dev/api/v1/exercises/{sourceId}`. Chỉ đối chiếu ID, tên chuyển động và việc response có trường GIF không rỗng trong bộ nhớ; không tải byte GIF, không giữ response hoặc sao chép hướng dẫn nhà cung cấp vào catalog. Các ID vẫn có thể bị nhà cung cấp thay đổi/gỡ trong tương lai; kết quả không bảo đảm tính sẵn sàng lâu dài.

Lượt đầu dùng bốn yêu cầu đồng thời gặp HTTP 429 sau 11 kết quả thành công. Sau khi chờ, chuyển sang tuần tự, cách nhau khoảng 7 giây. Một lần thử thiếu User-Agent nhận HTTP 403; lần thử tiếp theo với User-Agent mô tả mục đích thử nghiệm thành công. Không dùng proxy hoặc thay IP để vượt hạn mức.

Trạng thái kiểm tra cuối: **50/50 endpoint trả HTTP 200, ID trùng catalog và có trường `gifUrl` không rỗng**. Đã đối chiếu tên chuyển động cho từng ID trong bảng dưới; cách viết hoa và tên đồng nghĩa của nhà cung cấp không ảnh hưởng ID. Hai tên hiện tại là “Dumbbell Single-Arm Shoulder Press” (`84RyJf8`) và “Dumbbell Single-Arm Bent-Over Row” (`C0MA9bC`), đều khớp tên tiếng Việt. Không tuyên bố đã tải hoặc kiểm tra từng khung hình GIF.

## Nội dung được đóng gói

`data/workouts/exercise-library.json` chỉ chứa ID ổn định và nội dung tiếng Việt do HealthMate biên soạn độc lập: tên, nhóm cơ, dụng cụ, các bước ngắn và cách giảm độ khó. Không bundle URL media, hướng dẫn gốc hoặc GIF. Tên tiếng Anh chỉ dùng để xác định đúng biến thể trong lúc kiểm tra; tên tiếng Việt của bài plank bên được sửa thành “nâng chân” để khớp hip abduction. Deadlift chân ít gập không hướng dẫn khóa cứng gối.

`tool/build_exercise_library.cjs` kiểm tra đúng 50 ID duy nhất, ID nguồn gồm 7 ký tự chữ/số, nhóm cơ/dụng cụ hợp lệ, 2–6 bước và không có URL; sinh catalog Dart và JavaScript từ cùng JSON. Chạy `node tool/build_exercise_library.cjs --check` để kiểm tra đầu ra; bước kiểm tra Dart chấp nhận khoảng trắng và dấu phẩy cuối do formatter thêm.

## Danh sách ID ổn định

| # | ID | Tên HealthMate |
|---|---|---|
| 1 | `I4hDWkc` | Chống đẩy cơ bản |
| 2 | `ZOuKWir` | Chống đẩy quỳ gối |
| 3 | `NCmbLCw` | Chống đẩy tường |
| 4 | `F7vjXqT` | Chống đẩy tay trên bục |
| 5 | `i5cEhka` | Chống đẩy chân trên bục |
| 6 | `x6KpKpq` | Chống đẩy tay hẹp |
| 7 | `JmMVpR3` | Chống đẩy tay rộng |
| 8 | `9E25EOx` | Squat chân trước chân sau |
| 9 | `LIlE5Tn` | Squat bật nhảy |
| 10 | `kMzUs9Y` | Chùng chân về trước |
| 11 | `IZVHb27` | Chùng chân bước đi |
| 12 | `u0cNiij` | Nâng hông trên sàn |
| 13 | `rmEukuS` | Nâng hông một chân |
| 14 | `6HmFgmx` | Nhón bắp chân trên bậc |
| 15 | `RJgzwny` | Leo núi tại chỗ |
| 16 | `dK9394r` | Burpee |
| 17 | `iny3m5y` | Dead bug |
| 18 | `TFqbd8t` | Gập bụng trên sàn |
| 19 | `nCU1Ekp` | Gập bụng ngược |
| 20 | `1ZFqTDN` | Gập bụng đạp xe |
| 21 | `rbu5UUb` | Gập bụng chéo |
| 22 | `h1ezqSu` | Plank quỳ chạm vai |
| 23 | `VO2qeJg` | Plank bên nâng chân |
| 24 | `tFToB7l` | Plank ngược nâng chân |
| 25 | `3s4NnTh` | Cuốn tay trước với tạ đơn |
| 26 | `slDvUAU` | Cuốn tạ đơn kiểu búa |
| 27 | `kXaIn5A` | Cuốn tạ Zottman |
| 28 | `F3xgbjF` | Cuốn tạ trên ghế dốc |
| 29 | `DsgkuIt` | Nâng tạ đơn sang ngang |
| 30 | `3eGE2JC` | Nâng tạ đơn phía trước |
| 31 | `84RyJf8` | Đẩy vai một tay với tạ đơn |
| 32 | `EAs3xL9` | Dang tạ đơn cúi người |
| 33 | `C0MA9bC` | Kéo tạ đơn một tay |
| 34 | `BJ0Hz5L` | Kéo tạ đơn cúi người |
| 35 | `SpYC0Kp` | Đẩy ngực với tạ đơn |
| 36 | `yz9nUhF` | Ép ngực với tạ đơn |
| 37 | `9XjtHvS` | Kéo tạ đơn qua đầu |
| 38 | `nUwVh7b` | Deadlift với tạ đơn |
| 39 | `oom75KC` | Deadlift chân ít gập với tạ đơn |
| 40 | `RRWFUcw` | Chùng chân với tạ đơn |
| 41 | `SSsBDwB` | Chùng chân lùi với tạ đơn |
| 42 | `NJzBsGJ` | Nhún vai với tạ đơn |
| 43 | `lBDjFxJ` | Kéo xà tay sấp |
| 44 | `T2mxWqc` | Kéo xà tay ngửa |
| 45 | `EIeI8Vf` | Đẩy ngực với thanh tạ |
| 46 | `qXTaZnJ` | Squat với thanh tạ |
| 47 | `LEprlgG` | Kéo xô với cáp |
| 48 | `fUBheHs` | Ngồi kéo cáp |
| 49 | `10Z2DXU` | Đạp chân trên máy nghiêng |
| 50 | `3ZflifB` | Duỗi tay sau với cáp |

## Kiểm tra local

- `node tool/build_exercise_library.cjs`: thành công, sinh đúng 50 bản ghi.
- `D:/Flutter/flutter/bin/dart.bat format lib/features/activity/data/bundled_exercise_library.dart`: thành công.
- `node tool/build_exercise_library.cjs --check`: thành công sau formatter.
- Flutter analyze/test và kiểm tra màn hình tích hợp được báo trong báo cáo triển khai chung; tài liệu này không thay thế kiểm thử runtime hoặc quyền sử dụng production.
