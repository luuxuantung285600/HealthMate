# Xóa kế hoạch và lưu gợi ý thực đơn — 09/11/2026

## Phạm vi và trạng thái

Hoàn tất nhóm này của Giai đoạn 10 theo yêu cầu “tiếp tục”. Giữ toàn bộ
các sửa đổi trước. Không thêm package, dịch vụ, schema, field, index hay
Security Rules; không deploy, ghi dữ liệu production, commit hoặc push.
Android thật và ký bản phát hành tiếp tục để sau theo yêu cầu người dùng.

## Hành vi đã cải thiện

- Hộp xem trước không đóng ngay khi bắt đầu thêm thực đơn. Hiện số bữa
  đã được máy chủ xác nhận, số thêm và số giữ nguyên. Chờ ACK từng bữa,
  khóa gửi lặp và Back trong khi đang lưu.
- Mỗi bữa dùng transaction riêng: chỉ tạo nếu chưa có kế hoạch và chưa
  có nhật ký dành cho ID đó. Bữa vừa được thêm/sửa trên thiết bị khác
  được giữ nguyên, kể cả khi khác bản xem trước; không ghi đè timestamp,
  nội dung hoặc nhật ký. Không gom 28 bữa vào một transaction vượt giới
  hạn truy cập Rules.
- Lỗi ở giữa giữ nguyên bản xem trước và các bữa đã xác nhận. “Lưu tiếp”
  bắt đầu từ bữa chưa nhận ACK, không gửi lại các bữa đã xác nhận. Mất
  ACK sau commit được xử lý bằng kiểm tra document đã có; bộ đếm ghi
  bữa đó là “Giữ nguyên”. Không tuyên bố toàn bộ gợi ý lưu nguyên tử.
- Đóng sau lỗi không hoàn tác các bữa đã lưu; UI giải thích rõ. Khi đã
  xử lý xong, giữ kết quả để người dùng đọc rồi bấm “Xong”. Kcal/ngày là
  bản xem trước; nếu có thay đổi từ thiết bị khác, cần xem lại thực đơn.
- Xóa kế hoạch có hộp xác nhận theo bữa/ngày/món, giữ đến khi máy chủ
  xác nhận. Lỗi mạng giữ hộp thoại để thử lại; xung đột hiện đúng lý do.
  Chặn bấm lặp và Back lúc chờ. Hủy không gọi repository.
- Xóa từ UI luôn gửi snapshot đã hiển thị. Transaction kiểm tra cả thời
  điểm tạo/cập nhật, ngày, loại bữa, món và liên kết nhật ký; từ chối khi
  bản đó đã sửa/ghi nhật ký/tạo lại. Nếu đã xóa thì retry thành công.
  Chỉ xóa plan, giữ nguyên journal và dữ liệu dinh dưỡng thực tế.
- Hai luồng kiểm tra UID trực tiếp của Auth, UID stream và thế hệ phiên.
  AccountBoundDialog đóng nội dung riêng tư khi phiên đổi. ACK muộn sau
  đăng xuất rồi đăng nhập lại cùng UID không tiếp tục đợt cũ; gợi ý đang
  chờ tải danh mục cũng không mở lại bản xem trước của phiên trước.
- Nút sửa/ghi/xóa kế hoạch không hoạt động trong lúc hộp gợi ý đang mở.
  Nội dung dài và footer có cuộn, hỗ trợ màn hình hẹp/cỡ chữ lớn.

## File chính

- `lib/features/wellness/data/wellness_repository.dart`: thêm phương thức
  create-only cho gợi ý và xóa có snapshot kỳ vọng, không sửa nhật ký.
- `lib/features/wellness/presentation/meal_plan_suggestion_dialog.dart`:
  xem trước, tiến độ sau ACK, giữ trạng thái lỗi và lưu tiếp.
- `lib/features/wellness/presentation/delete_meal_plan_dialog.dart`: xác
  nhận, chờ ACK, lỗi/thử lại và thông báo xung đột.
- `lib/features/wellness/presentation/wellness_screen.dart`: tích hợp hai
  hộp thoại, guard tài khoản và khóa thao tác liên quan; giữ sửa đổi cũ.
- `test/meal_plan_operations_test.dart`: 15 regression mới.
- `test/plan_meal_repository_integration.dart`: thêm 9 regression SDK.
- `test/catalog_expansion_test.dart`: nối Auth repository fixture để
  kiểm tra preview thuần chay vẫn dùng được guard Auth trực tiếp.
- README, database-design, implementation-progress, test-report và báo cáo này.

## Kiểm thử đã chạy

| Kiểm tra | Kết quả thật |
| --- | --- |
| `flutter test --no-pub --reporter expanded` | **1.130/1.130 qua**, 2:16 |
| Focused cuối: operations, plan UI, catalog expansion | **34/34 qua**, sau sửa lint cuối |
| Regression UI mới | **15/15 qua**, gồm mạng lỗi, ACK mất/muộn, gửi lặp, Back, hủy, phiên A→logout→A và Auth trước stream |
| `npm test --prefix rules-tests` trong demo emulator | **143/143 qua**, có chặn UID chéo và các quyền đang có |
| SDK `plan_meal_repository_integration.dart` trên Chrome/emulator | **22/22 qua**, gồm **9 ca mới** |
| `flutter analyze --no-pub` cuối | **Không có vấn đề** |
| `dart format --output=none --set-exit-if-changed` trên 7 Dart file | **0 file thay đổi** |
| Preview với Inter và MaterialIcons thật | **4/4 qua**, xem **14 ảnh** |
| `flutter build apk --debug --no-pub` | **Qua**, Gradle 23,3 giây |
| `node tool/audit_source_secrets.cjs` | Không phát hiện theo pattern trong source được theo dõi/file mới không bị ignore |
| `git diff --check` | Qua; có cảnh báo LF/CRLF hiện hữu |

SDK test dùng duy nhất `demo-healthmate-rules`, Auth `127.0.0.1:9099` và
Firestore `127.0.0.1:8080`, có guard loopback. Hai FirebaseApp riêng kiểm
tra cùng thêm một slot chỉ có một winner. Ca 28 bữa xác nhận mọi transaction
đều hợp Rules; replay giữ nguyên cả nội dung và timestamp. Ca xóa kiểm tra
plan vừa sửa, vừa liên kết nhật ký, vừa tạo lại, retry sau mất ACK, nhật ký
không đổi và từ chối UID khác. Không dùng tài khoản hay dữ liệu production.

Hai SDK test ban đầu phát hiện FormatException trong callback transaction
bị SDK web bọc thành lỗi chung. Đã chuyển kết quả xung đột ra ngoài callback
rồi mới ném thông báo nghiệp vụ; chạy lại toàn Rules và SDK đều qua. Không
đổi matcher để bỏ qua sai loại lỗi. Lỗi fixture trung gian gồm override nhầm
kiểu đồng hồ, thiếu Auth repository, kiểm tra dialog trước khi animation đóng
xong và tìm thông báo đang ngoài vùng cuộn; đã sửa fixture, giữ assertion
nghiệp vụ. Analyzer ban đầu có import thừa/braces/mounted; bản cuối sạch.

Preview gồm 390 px sáng/100% và 320 px tối/200%, mỗi cấu hình có xem trước,
pending, lỗi/thử lại; gợi ý thêm trạng thái hoàn tất. Đã kiểm tra nút có thể
cuộn tới và bấm được, không layout exception. Ảnh được gắn nhãn fixture.
Các log trung gian có lỗi được giữ để truy vết, không phải kết quả cuối.

Log: `build/meal-plan-operations-{full,focused-final,emulator-final,
analyze-final,format,preview,apk,secret-audit,diff-check}.log`.
Harness và ảnh: `build/meal-plan-operations/`.

## APK kiểm thử

`build/releases/healthmate-meal-plan-operations-20261109-debug.apk`

- Kích thước: **237.555.913 byte**.
- SHA-256: `A7EC36BFCA9FFCC25C60AF7105DB4BEC675BCA735CCAB4C435993E54DDA57AFD`.
- Manifest JSON cùng tên ghi số test, build và cờ chưa triển khai/acceptance.
- Đây là APK debug; không phải bản phát hành đã ký bằng khóa production.
  Cảnh báo KGP của các plugin hiện hữu còn; không nâng dependency ngoài phạm vi.

## Cấu hình, giới hạn và bước sau

- Không cần bật Blaze, Play Console hay cấu hình Firebase mới cho thay đổi
  này. Cài bản app cập nhật khi muốn sử dụng. Chưa nghiệm thu Android thật,
  ký release hoặc triển khai production.
- Ghi đang ở máy chủ có thể hoàn tất cho tài khoản cũ sau logout. Guard
  dừng các bữa chưa gửi và không chuyển dữ liệu/thông báo sang tài khoản mới;
  không hứa hủy được transaction đã gửi.
- Tiến độ chỉ giữ trong bộ nhớ của hộp thoại. Đóng/process death không giữ
  hàng đợi; các bữa đã commit vẫn nằm trên Firestore, mở lại sẽ dùng dữ liệu
  hiện có để gợi ý bữa còn trống. Không hoàn tác tự động phần đã lưu.
- API xóa không truyền snapshot còn cho tương thích/test nghiệp vụ trước;
  xóa trên UI luôn truyền snapshot. Rules hiện có vẫn cho chủ tài khoản xóa
  plan; cơ chế tránh xóa nhầm là kiểm tra transaction của ứng dụng.
- Lượt này xử lý xung đột khi thêm gợi ý và xóa kế hoạch. Chỉnh thủ công mục
  tiêu/kế hoạch vẫn còn giới hạn ghi sau cùng; không tuyên bố đã xử lý mọi
  xung đột nhiều thiết bị. Bản gợi ý không tự tái tính nếu hồ sơ/mục tiêu đổi
  sau khi mở preview.
- Secret audit là kiểm tra source theo pattern, không phải audit APK hoặc
  kho credential. Emulator không chứng minh cấu hình production/App Check.
- Đề xuất nhóm sau của Giai đoạn 10: kiểm soát xung đột khi chỉnh thủ công
  mục tiêu và kế hoạch. Chỉ đề xuất, không triển khai trong lượt này.
