# 17/11/2026 — Tìm và chọn món thuận tiện hơn

## Giai đoạn và phạm vi

Bảo trì Giai đoạn 4 — Food Catalog và nhật ký dinh dưỡng thủ công, theo
yêu cầu người dùng tự chọn một phần khác để cải thiện. Chỉ sửa UX tìm món
và giữ trạng thái khi chọn thêm món; không chuyển sang giai đoạn tiếp theo.

## Hành vi đã hoàn thành

- Ô tìm món có nút X để xóa toàn bộ từ khóa bằng một lần bấm. Xóa trả về
  danh mục phù hợp nhóm/chế độ ăn/thực phẩm cần tránh đang chọn, đồng thời
  hủy yêu cầu tìm kiếm cũ; kết quả đến muộn không thay danh sách mới.
- Phím Tìm trên bàn phím chạy tìm kiếm ngay và đóng bàn phím. Debounce
  đang chờ được hủy nên một lần bấm không phát sinh thêm lượt tìm từ timer.
- Hiển thị số món đang xem so với số món đã tải, ví dụ 12/40. Con số này
  thuộc kết quả đã tải hiện tại, không phải tổng thực phẩm của API ngoài.
  Xem thêm tiếp tục tăng số hàng như trước, không đổi giới hạn nguồn ngoài.
- Giữ từ khóa, nhóm thực phẩm và trạng thái phần chọn món dùng lại khi
  danh sách món đã chọn xuất hiện/thay đổi. Trước đây item ListView không
  có key ổn định nên phần tìm kiếm có thể bị tạo lại khi thêm món đầu tiên.
  Nhánh món từ scanner có key theo truy vấn để chỉ reset khi kết quả quét đổi.
- Áp dụng ở tìm món trực tiếp và thành phần chọn từ thư viện. Các nguồn
  Gần đây/Yêu thích/Món của tôi/Công thức dùng chung ô có nút xóa; bấm Tìm
  trên các nguồn này chỉ đóng bàn phím, không gọi tìm kiếm ngoài.

Không thay đổi cách tính dinh dưỡng, snapshot nhật ký, giới hạn món, quy tắc
ẩn món, quyền UID hoặc cách xác nhận lưu. Không thêm package, collection,
schema, index, backend hay dịch vụ trả phí. Không ghi dữ liệu production,
deploy hoặc push Git trong lượt này.

## File chính

- `lib/features/nutrition/presentation/food_search_widgets.dart`: ô tìm dùng
  chung và thông báo số hàng đã tải; controller hiện có tiếp tục sở hữu query.
- `lib/features/nutrition/presentation/meal_entry_sources.dart`: dùng ô tìm
  và số kết quả trong danh mục trực tiếp.
- `lib/features/food_library/presentation/meal_food_sources.dart`: cùng UX ở
  phần chọn từ thư viện, giữ lifecycle/cancellation/filter hiện có.
- `lib/features/nutrition/presentation/meal_form_dialog.dart`: key ổn định
  cho phần thư viện và nguồn kết quả scanner trong danh sách cuộn.
- `test/food_search_lifecycle_test.dart`: thêm bốn ca kiểm nút xóa lúc chờ
  mạng, phản hồi đến muộn, keyboard search tức thì/hủy debounce ở cả hai cách.
- `test/mfp_search_test.dart`, `test/food_browse_groups_test.dart`: dùng nút
  xóa thật; vẫn kiểm kết quả mới nhất và nhóm được giữ sau khi thêm món/lưu.

## Kiểm tra thực tế

- `dart format --output=none --set-exit-if-changed` trên bảy file Dart trong
  phạm vi: 0 thay đổi, exit 0, 0,17 giây.
- `flutter analyze --no-pub`: No issues found, exit 0, 62,4 giây.
- `flutter test --no-pub` với chín suite dưới đây: **87/87 qua**, exit 0,
  34 giây. Không cộng lặp lượt chạy tập trung 23/23 trước đó.

```text
test/food_search_lifecycle_test.dart
test/mfp_search_test.dart
test/food_browse_groups_test.dart
test/meal_search_controller_test.dart
test/food_search_request_test.dart
test/unified_meal_entry_test.dart
test/food_detail_ui_test.dart
test/daily_form_recovery_test.dart
test/ui_readability_test.dart
```

Các suite còn kiểm chuyển UID/nguồn, tải chi tiết USDA, phản hồi cũ, lỗi/
thử lại, bảo vệ bộ lọc và ảnh món bị admin ẩn, lưu snapshot, bản nháp và
layout sáng/tối tới 320 px/chữ hệ thống 2x. Đã xem render sáng; các ảnh
render dùng fixture kiểm thử, không phải dữ liệu tài khoản thật.

- `flutter build web --release --no-pub --output build/food-search-ux-20261117/web`:
  thành công, exit 0, 122,7 giây. Bản JavaScript build được; Wasm dry run
  vẫn cảnh báo mobile_scanner hiện có dùng dart:html/package:js. Không sửa
  dependency ngoài phạm vi hoặc tuyên bố bản Wasm đã chạy.

Log trong `build/food-search-ux-20261117/`: `regression-final.log`,
`analyze-final.log`, `build-web.log`. Ảnh của suite dùng lại:
`build/food-groups-ui/{meat,seafood}-{light-1.0,dark-2.0}.png`.

Lượt đầu có hai assertion tìm loading toàn app bắt nhầm các thanh tiến độ
trang chủ phía sau dialog; đã giới hạn assertion vào đúng phần tìm món,
giữ kiểm request bị hủy và phản hồi đến muộn. Ca bấm nút xóa sau khi thêm
món còn phát hiện phần thư viện mất trạng thái: sửa key item thật trong
ListView, giữ assertion dùng nút xóa và nhóm vẫn được chọn, chạy lại qua.

## Cần người dùng làm, giới hạn và đề xuất

Hot Restart, mở Thêm bữa ăn rồi thử gõ từ khóa, bấm Tìm hoặc nút X. Không
cần cấu hình Firebase mới. Chưa nghiệm thu Android vật lý, bàn phím thiết
bị thật hay gọi USDA/Firebase production trong lượt này; các request test
dùng fake service có điều khiển phản hồi. Không có lỗi chặn đã biết trong
phạm vi đã kiểm tra. Đề xuất tiếp Giai đoạn 10 — nghiệm thu luồng ghi bữa
trên thiết bị; chỉ đề xuất, chưa thực hiện.
