# Bộ lọc thực phẩm — 10/11/2026

Giai đoạn 4 bổ sung: mở rộng nhóm thực phẩm, tách **Thịt** khỏi
**Cá & hải sản** theo yêu cầu. Chỉ đổi phân loại và giao diện chọn món.

## Hành vi

- Có 10 nhóm: Tất cả, Món ăn Việt, Trái cây, Rau củ, Thịt, Cá & hải sản,
  Trứng & sữa, Ngũ cốc, đậu & hạt, Đồ uống, Đồ đóng gói.
- Thanh nhóm cuộn ngang; nút “Chọn nhóm thực phẩm” mở toàn bộ danh sách.
  Chọn trong menu tự đưa nhóm đó vào vùng nhìn thấy. Nhãn dài xuống dòng;
  kiểm thử cả màn hình 320 px với chữ 200%.
- Áp dụng ở bộ chọn mặc định và bộ chọn dùng chung đang được nhật ký sử dụng.
  Nhóm kết hợp với tìm kiếm, chế độ ăn, món cần tránh và trạng thái admin ẩn.
- Đổi nhóm không bỏ món đã chọn; lưu nhiều nhóm trong cùng một bữa vẫn giữ
  đúng khẩu phần và snapshot dinh dưỡng.
- Giữ ưu tiên món Việt và 100 mục đã rà soát của mỗi nhóm trái cây/đồ uống.

## Phân loại

Ưu tiên category nguồn; tham chiếu chung chưa phân nhóm chỉ dùng tên định
danh chính xác trước dấu phẩy. Không dò từ khóa nguyên liệu trong toàn bộ
tên để suy ra thịt/cá. Phở bò, bún thịt nướng, thịt kho trứng vẫn là món
Việt; nước mắm, súp cá, bánh mì kẹp cá không bị đưa vào nhóm cá nguyên liệu.
Trứng trong category cũ “Thịt và trứng” được tách sang Trứng & sữa.

Một số nhóm có thể giao nhau: sữa động vật vừa là đồ uống vừa thuộc Trứng
& sữa; sữa chua đóng gói vừa thuộc Trứng & sữa vừa thuộc Đồ đóng gói. Sữa
đậu nành/hạnh nhân/yến mạch không thuộc sữa động vật. Đồ đóng gói dựa trên
category/brand/packageLabel, không coi mọi mục tham khảo đóng hộp là một
sản phẩm có nhãn hiệu.

Số kết quả trên catalog offline hiện tại, trước bộ lọc ăn kiêng/tránh/ẩn:

| Nhóm | Số mục |
| --- | ---: |
| Tất cả | 11.247 |
| Món ăn Việt | 85 |
| Trái cây | 409 |
| Rau củ | 1.243 |
| Thịt | 2.737 |
| Cá & hải sản | 467 |
| Trứng & sữa | 595 |
| Ngũ cốc, đậu & hạt | 1.520 |
| Đồ uống | 773 |
| Đồ đóng gói | 25 |

Số lượng là số bản ghi (có biến thể sống/chín/khô và nguồn khác nhau), không
phải số loại thực phẩm duy nhất. Các nhóm không bao phủ riêng biệt mọi món;
món tổng hợp hoặc chưa đủ metadata vẫn tìm được ở Tất cả. Thịt và Cá & hải
sản không có ID giao nhau trong catalog hiện tại.

## File chính

- `lib/features/nutrition/models/food_browse_group.dart`
- `lib/features/nutrition/presentation/food_browse_filter.dart`
- `test/food_browse_groups_test.dart`

Không sửa dinh dưỡng, asset dữ liệu, model/field Firestore, luật bảo mật,
backend hay dependency. Không phát hành lại Firebase hoặc push Git.

## Kiểm chứng

- Test tập trung: `flutter test test/food_browse_groups_test.dart
  test/fruit_drink_browse_test.dart --reporter expanded`: **16/16 qua**.
  Bao gồm hai đường chọn món, dữ liệu thật, thực phẩm dễ phân nhầm, giao
  nhóm sữa, chế độ ăn/tránh/ẩn và truy cập đủ 10 nhóm bằng menu.
- Lượt đầu phát hiện sữa có category Đồ uống bị thiếu nhóm sữa và việc tự
  cuộn chỉ hoạt động theo một hướng; đã sửa logic và giữ assertions.
  Sau đó kiểm tra mép nhãn phát hiện animation dấu chọn làm dịch kích thước;
  chip dùng nền chọn với chiều rộng ổn định và text xuống dòng.
- Đã xem ảnh chụp widget sáng 390 px/chữ 100% và tối 320 px/chữ 200% tại
  `build/food-groups-ui/`; nhóm đang chọn hiển thị đủ tên.
- `dart format --output=none --set-exit-if-changed` trên 3 file Dart thay đổi:
  0 thay đổi, exit 0.
- `flutter analyze`: **No issues found**, exit 0, 34 giây.
- `flutter test --reporter expanded`: **1.252/1.252 qua**, exit 0, 3 phút
  18 giây. Log: `build/food-groups-full.log`.
- `flutter build apk --debug --dart-define-from-file=<cấu hình riêng>`: qua,
  exit 0, Gradle 53,7 giây. Cảnh báo plugin KGP hiện hữu vẫn còn; không nâng
  dependency ngoài phạm vi. Bản cài:
  `build/releases/healthmate-food-groups-20261110-debug.apk`, 238.279.331 byte.
  SHA-256: `f6e1625dd90c40773f833d83099a22a3d0c0013f9e1c2233f05a090a039d79ab`.
- `git diff --check`: exit 0; chỉ có cảnh báo LF/CRLF hiện hữu.

## Cấu hình và giới hạn

Không cần Firebase/billing hoặc cấu hình thủ công mới. Cần cập nhật bản app
để nhận giao diện bộ lọc. Món thiếu ảnh tiếp tục dùng dòng chữ hiện có.
Chưa nghiệm thu Android vật lý hoặc ký bản phát hành theo yêu cầu hoãn
trước đó. Bước tiếp đề xuất: nghiệm thu bộ lọc trên điện thoại khi người
dùng yêu cầu; chưa thực hiện.
