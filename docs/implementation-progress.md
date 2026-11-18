# Tiến độ HealthMate

## 19/11/2026 — Bàn giao dự án và chuẩn bị GitHub

- Đã tạo HANDOVER.md đủ bảy phần: sản phẩm/môi trường, checklist, cấu trúc,
  quyết định thiết kế, vấn đề, code cốt lõi và quy tắc cho AI tiếp theo.
  README liên kết tới bản bàn giao; chỉ đóng gói hiện trạng, không thêm tính năng.
- Kiểm tra toàn bộ trước push: Flutter 1.434 qua/1 ca chụp tùy chọn skip,
  analyze sạch (25,3s); format 260 file không đổi. Admin 176/176,
  chat-api 49/49, Functions 29/29, tool 64/64; Firestore Emulator 183/183 qua.
- Sửa harness: chờ scroll/layout và kiểm hit-test trước bấm ở ba suite;
  thêm fake activity repository cho bốn ca U1 ngân sách; hai Rules fixture
  đọc file theo __dirname để chạy từ CI/rules-tests. Không bỏ assertion
  nghiệp vụ hoặc sửa Rules để che lỗi. Dọn whitespace báo bởi diff-check.
- Source audit không phát hiện secret; build/cache, token và signing key
  bị loại khỏi Git. Nhánh đẩy: codex/nutrition, giữ nguyên nhánh main.
- Cần người dùng: cấu hình/nghiệm thu Play/Blaze/AI/signing/Android thật
  theo checklist HANDOVER; không deploy hoặc bật phí trong lượt này.
  Đề xuất tiếp: người dùng chọn hạng mục từ checklist; chưa tự triển khai.

## 19/11/2026 — Giai đoạn 11: ảnh xem trước trong kho ExerciseDB

- Hoàn thành ảnh tĩnh thật trên từng thẻ; bấm ảnh/nút mới mở GIF chuyển động.
  Lazy load, hai lượt tải đồng thời, hủy khi rời thẻ đang tải/chuyển tab;
  đổi trang/bộ lọc/đóng picker giải phóng ảnh. Có thử lại khi ảnh lỗi.
- Đồng bộ nền đen/trắng; sửa khung mobile tối thiểu 96px để filter vẫn hoạt
  động. Không đổi backend/Rules/schema, dependency hoặc điều kiện media.
- Admin 176/176 qua; JS check/generator qua. Chrome thật sáu bố cục qua,
  ảnh tĩnh không đổi qua hai screenshot, mở GIF thật và lưu adapter QA qua.
  Kiểm pixel nền đen/trắng cả sáu bố cục. Không ghi production/push/deploy.
- File/lệnh/bằng chứng/giới hạn: docs/exercisedb-thumbnails-2026-11-19.md.
  Ctrl+F5 admin local; không cần cấu hình Firebase mới. Flutter/Rules không
  sửa logic nên không chạy lại. Đề xuất nghiệm thu môi trường người dùng
  khi được yêu cầu; chưa chuyển tính năng/giai đoạn khác.

## 19/11/2026 — Giai đoạn 11: admin duyệt kho ExerciseDB

- Hoàn thành nút “Thêm từ ExerciseDB”: duyệt kho nguồn1.500 bài, tìm tên,
  lọc nhóm/dụng cụ, phân trang25 bài, xem GIF/hướng dẫn, chuyển sang form
  có mã nguồn tự điền; admin biên tập tiếng Việt rồi lưu/audit như trước.
- Chặn ảnh lỗi khi thêm trong môi trường bật GIF; mở bản đã có/kể cả đang
  ẩn, chặn thêm trùng; xử lý mất mạng,429,retry,abort và phản hồi tới muộn.
- Giữ listener app hiện có; không đổi schema/Rules/backend/dependency/phí.
  Chuyển CSS profile GIF ra file ngoài để đúng CSP hiện có, không nới CSP.
- Admin169/169, Flutter27/27, Emulator6/6 qua; analyze sạch; check JS/generator
  qua. Chrome thật6 bố cục sáng/tối không tràn, nguồn/GIF thật và lưu adapter
  QA qua; không ghi Firebase production. Chi tiết:
  docs/exercisedb-admin-browser-2026-11-19.md.
- Ctrl+F5 admin local; không cần tải GitHub/tài khoản ExerciseDB. Chưa deploy/
  push hoặc nghiệm thu Android vật lý. Đề xuất tiếp: nghiệm thu môi trường
  người dùng khi được yêu cầu; chưa chuyển tính năng/giai đoạn khác.


## 19/11/2026 — Giai đoạn 11: xóa các khoảng nền trắng khép kín GIF nữ

- Hoàn thành xử lý các vùng nền đã rà trên 10 GIF nữ; nền đen cả khoảng
  giữa tay/thanh tạ, dây tập và khung ghế, giữ chi tiết trắng thuộc nhân vật.
- Dữ liệu tọa độ chung + generator cho native/app web/admin; SVG v4 dùng
  điều kiện màu theo khung, ảnh vuông bảo đảm tọa độ khi hiển thị thẻ nhỏ.
- Flutter 36/36, admin 155/155; sau chỉnh khung vuông DOM/media 63/63;
  analyze sạch. Native kiểm đủ126 khung,110 vùng nền/27.378pixel được xóa;
  SVG kiểm24 khung có điều kiện và9 ảnh mẫu. App/admin8 filter khớp.
- File/lệnh/bằng chứng/giới hạn: docs/exercise-enclosed-background-2026-11-19.md.
  Không cần cấu hình Firebase; Hot Restart và Ctrl+F5 để nạp mã mới. Chưa
  nghiệm thu Android/Chrome vật lý hoặc deploy/push. Đề xuất tiếp: nghiệm thu
  thiết bị khi được yêu cầu, chưa chuyển giai đoạn.


## 17/11/2026 — Giai đoạn 11: tìm thêm GIF nữ không cần tài khoản

- Đã nghiên cứu tiếp theo lựa chọn của người dùng; chưa tìm thêm media đủ
  điều kiện để tích hợp. Danh mục giữ 54 bài / bốn GIF nữ đã xác minh.
- Kiểm tra nguồn chính thức ExerciseDB, V2/pricing, repo dataset 1.324 bài,
  đủ 394 ảnh wger và mở cả năm GIF của wger. Hai mã Smith không gắn giới tính
  trong ExerciseDB đều là nam. Một GIF nữ wger cần xác minh quyền nguồn gốc;
  V2 cần tài khoản nên không phù hợp lựa chọn hiện tại.
- Chỉ cập nhật tài liệu, không đổi code/schema/Rules/phí hoặc deploy/push.
  Không chạy lại tests của lượt trước thành kết quả mới. Báo cáo và nguồn:
  docs/female-gif-source-expansion-2026-11-17.md; bằng chứng cục bộ:
  build/exercise-female-expansion-20261117/.
- Phần tăng thêm GIF chưa hoàn tất; cần nguồn media phù hợp đã xác minh.

## 17/11/2026 — Giai đoạn 11: GIF nhân vật nữ

- Hoàn thành bổ sung bốn bài nữ đã xem GIF thật từ ExerciseDB, danh mục app/
  admin từ 50 lên 54; 50 bản ghi cũ giữ nguyên. Tìm `mau nu` để xem; bộ lọc,
  mở đúng GIF, admin sửa/ẩn/khôi phục và merge realtime dùng cơ chế hiện có.
- File chính: data/workouts/exercise-library.json, generator, catalog Dart/JS,
  test/female_exercise_library_test.dart và các test danh mục/admin.
- Catalog check qua; format sáu file 0 thay đổi; analyze sạch; 11 suite Flutter
  99 ca qua + một ca chụp tùy chọn skip; toàn bộ admin 149/149 qua, npm check qua.
- Hot Restart app, tải lại admin local. Không đổi Rules/schema/package/phí,
  không deploy/push Git. Chưa Android vật lý; nguồn miễn phí giữ gate kiểm thử
  phi thương mại. Chi tiết: docs/female-exercise-gifs-2026-11-17.md; log ở
  build/exercise-female-review-20261117/.
- Đề xuất tiếp: nghiệm thu bốn bài trên thiết bị; chưa tự thực hiện.

## 17/11/2026 — Giai đoạn 4: tìm món và giữ ngữ cảnh chọn món

- Hoàn thành UX nút X xóa nhanh, phím Tìm chạy ngay/đóng bàn phím và số hàng
  hiển thị/số món đã tải ở danh mục trực tiếp và phần chọn thư viện. Xóa hủy
  request cũ, giữ bộ lọc; không coi số hàng đã tải là tổng của API ngoài.
- Sửa key của item thư viện/scanner trong ListView để từ khóa và nhóm không
  bị reset khi thêm món làm xuất hiện danh sách đã chọn. Giữ snapshot, phép
  tính, xác nhận lưu, giới hạn món và quyền hiện có.
- File chính: food_search_widgets.dart, meal_entry_sources.dart,
  meal_food_sources.dart, meal_form_dialog.dart và ba file test. Chi tiết:
  docs/food-search-ux-2026-11-17.md.
- Format bảy file qua/0 thay đổi; analyze sạch; chín suite 87/87 qua,
  gồm nút xóa khi request chờ, phản hồi cũ, keyboard submit không chạy lặp
  debounce, giữ nhóm sau thêm món và layout sáng/tối 320px/chữ 2x.
  Build JavaScript web release qua (122,7 giây); Wasm dry-run warning của
  mobile_scanner hiện có vẫn còn.
- Không đổi schema/Rules/index/package hoặc ghi production/deploy/push Git.
  Người dùng Hot Restart để thử. Chưa nghiệm thu Android vật lý hoặc API
  production; kết quả kiểm tra và log ghi trong báo cáo riêng. Đề xuất
  tiếp Giai đoạn 10 nghiệm thu thiết bị; chưa thực hiện.

## 17/11/2026 — Giai đoạn 3: tên, ảnh hồ sơ và điều chỉnh cỡ chữ

- Hoàn thành theo yêu cầu: mục Tên & ảnh hồ sơ cho đổi tên, chọn/xem trước/
  gỡ avatar, bìa và nền hồ sơ; lưu có xác nhận máy chủ, giữ bản nháp khi lỗi,
  chặn gửi lặp và đóng form khi đổi UID. Listener hồ sơ cập nhật tên/ảnh.
- Giảm nhẹ font theme và các chỉ số/heading lớn; giữ Public Sans, vùng chạm,
  chữ hệ thống, chế độ sáng/tối. Không thêm dependency hoặc dịch vụ trả phí.
- Thêm map tùy chọn users/{uid}.profileAppearance: ba PNG thu nhỏ tối đa64KiB/
  ảnh, không lưu bản gốc/EXIF/vị trí. Giữ dữ liệu sức khỏe, hồ sơ cũ và cơ chế
  xóa tài khoản. Rules bảo vệ UID, xác minh email, khóa/xóa tài khoản.
- Format21file qua, analyze sạch;12suite138/138 qua, rules61/61 qua,
  Firebase SDK Chrome + emulator1/1 qua; web JS release build qua. Có kiểm
  sáng/tối320px chữ2x, xử lý ảnh thật qua decoder, lỗi/thử lại và đổi phiên.
- Đã deploy riêng Rules, đọc lại khớp SHA256 local; miễn index riêng map ảnh
  và xác minh subfield kế thừa. Ba composite index production không đổi.
  Không deploy indexes toàn bộ, không ghi fixture production, push Git hay
  deploy app/admin/Functions. File/lệnh/giới hạn: docs/profile-identity-2026-11-17.md.
- Người dùng Hot Restart rồi mở ảnh đại diện → Tên & ảnh hồ sơ; không cần
  cấu hình Firebase. Ảnh là thumbnail cắt giữa; nền thuộc trang hồ sơ.
  Chưa nghiệm thu Android vật lý/ký bản phát hành; Wasm warning của scanner
  vẫn còn, JS build qua. Đề xuất tiếp Giai đoạn10 nghiệm thu thiết bị, chưa làm.

## 17/11/2026 — Giai đoạn 1: icon Tabler, UI đen và vòng calo dưỡng chất

- Hoàn thành local: thay bộ icon app bằng Tabler Icons 3.52.0 (MIT), giữ142
  tên API/116 glyph; icon nét và tab chọn icon đặc. Nút/chip/badge và các luồng
  dùng màu đen/xám nhất quán ở tối, trắng ở sáng; giữ Public Sans.
- Vòng calo lấy tổng ngày đã ghi: độ dài theo kcal/mục tiêu, chia màu theo
  tỷ lệ năng lượng đạm4/tinh bột4/chất béo9 kcal/g. Có legend/giải thích và
  semantics; thiếu dữ liệu dùng xám, không thêm tỷ lệ giả. Màu dưỡng chất đồng
  bộ ở danh sách/chi tiết món, trang chủ và báo cáo. Sửa ký hiệu phút thiếu glyph.
- File chính: core theme/icon font/generator, FeatureIconBadge, DashboardScreen,
  MfpCaloriesCard, CalorieRingData, CalorieMacroRing, giao diện món/quét mã,
  WellnessHub và3 file test. Chi tiết: `docs/neutral-icons-calorie-ring-2026-11-17.md`.
- 14 suite UI/calculation: **187/187 qua**, 23giây; analyze sạch (19,2giây);
  build JS web release qua (60giây). Generator xác minh hash/cmap/license/
  glyph/alias offline qua. Đã xem render sáng/tối và trang chủ có fixture;
  kiểm layout320px/chữ2x, cập nhật/xóa bữa và giữ hành vi hiện có.
- Build có cảnh báo Wasm từ `mobile_scanner` dùng API web cũ; bản JS build
  thành công. Không nhận nghiệm thu Android vật lý, ký phát hành hay runtime
  Firebase từ các test dùng fake repository. Không push/deploy/đổi rule/schema.
- Người dùng dừng và chạy lại app để nạp font mới; không cần cấu hình Firebase
  thêm. Giai đoạn tiếp theo đề xuất:10, nghiệm thu UI trên thiết bị; chưa làm.

## 16/11/2026 — Giai đoạn 6: nhật ký nước, chọn dung tích và hoàn tác

- Hoàn thành local: form có 100/250/350/500/750 ml và nhập tùy chọn, hiện đủ
  ngày/tháng/năm. Giữ nút ghi nhanh cùng empty state; loading/error không
  hiện tổng 0 ml chưa xác định. Trang chủ/Nhật ký dùng cùng thông báo có Hoàn
  tác sau xác nhận ghi; thông báo gắn UID/ID, bỏ receipt khi đổi tài khoản.
- Transaction chỉ xóa đúng lần ghi chưa sửa, so dữ liệu và createdAt/updatedAt;
  giữ cả mục đã sửa rồi quay về giá trị cũ. Mục đã xóa cho thử lại an toàn,
  lỗi có retry. Lỗi domain trả ngoài SDK callback để web giữ đúng mã lỗi.
- File chính: water repository/controller/form/section, quick_water_entry.dart,
  DailyLogSectionCard, JournalScreen, DashboardScreen và 3 file test. Danh sách
  đầy đủ: `docs/water-quick-entry-2026-11-16.md`.
- Format 12 file qua/0 đổi, analyze toàn repo sạch (24,9 giây), 7 suite cuối
  **56/56** qua (11 giây); Firebase Auth/Firestore SDK Chrome với demo emulator
  **1/1** qua, gồm bảo vệ sửa và chặn UID khác. Đã xem render form sáng/tối;
  layout tới chữ2x/màn320px. Diff-check qua.
- Công cụ: Flutter Windows test server trả 404 CanvasKit; chỉ cấp lại đúng
  artifact SDK trong browser test riêng, không sửa app/SDK hay mock Firebase.
  Các lượt lỗi và cách sửa ghi trong báo cáo; không tính là lượt thành công.
- Người dùng Hot Restart để dùng. Không đổi schema/rules/package/cấu hình
  Firebase. Chưa Android vật lý/build ký/phát hành/push/deploy; không ghi QA
  production. Hoàn tác cần online. Không có blocker đã biết cho phần đã test.
- Đề xuất tiếp Giai đoạn 10: nghiệm thu nhật ký trên môi trường người dùng;
  chưa thực hiện giai đoạn khác.

## 16/11/2026 — Giai đoạn 8: so sánh tuần và đồng bộ khoảng xuất báo cáo

- Hoàn thành local mục So sánh với tuần trước trong Tiến độ/Tuần/Tổng quan:
  cân nặng, năng lượng đã ghi, nước và phút vận động; độ phủ từng chỉ số,
  chỉ ghép cùng thứ có dữ liệu ở cả hai phía, không coi thiếu là 0. Cân nhiều
  lần được trung bình ngày. Có nhắc tuần/ngày chưa kết thúc và dữ liệu thiếu.
- Sửa xuất báo cáo theo tuần/khoảng 30/90 ngày đang xem. Đồng bộ tuần ở chi
  tiết với biểu đồ; giữ khoảng dài khi rời tab rồi quay lại. Dùng provider
  theo UID hiện có; chỉ đọc tuần trước khi mở mục so sánh, chia sẻ tuần hiện
  tại. Không thêm dependency, collection hoặc thay đổi backend/rules.
- File chính: week_comparison.dart, week_comparison_card.dart, progress_screen,
  weekly_reflection_card, period_report_panel và hai file test mới. Chi tiết:
  `docs/progress-comparison-2026-11-16.md`.
- Format 7 file/0 thay đổi; analyze toàn repo sạch (20,2 giây); 7 suite liên
  quan cuối **88/88** qua (23 giây), diff-check qua. Đã xem render sáng/tối,
  kiểm màn hẹp/chữ lớn, lỗi/thử lại, chuyển tuần nhanh và đăng xuất đang tải.
- Người dùng Hot Restart rồi mở Tiến độ/Tuần/Tổng quan/So sánh với tuần trước;
  không cần cấu hình Firebase. Chưa kiểm Android thật/Firebase production,
  build ký, push Git hoặc deploy; ảnh render chỉ dùng fixture test.
- Không có blocker đã biết trong phạm vi. Đề xuất Giai đoạn 10: nghiệm thu
  luồng Tiến độ/xuất báo cáo trên môi trường người dùng; chưa thực hiện.

## 15/11/2026 — Giai đoạn tùy chọn 11: đường bao GIF và bộ lọc web phiên bản 3

Tiếp tục theo phản hồi còn răng cưa: chuyển sang matte mềm hơn kết hợp
loại màu trắng trộn ở mép, giữ chi tiết trong cơ thể, resampling high ở
native. Web dùng filter ID có phiên bản, thay SVG/style cũ khi hot restart/
hot reload, không để nhiều định nghĩa cùng ID giữ bộ lọc cũ.

54/54 test qua; kiểm mã Dart biên dịch JS với DOM giả 5/5 qua; render native
GIF thật 1/1 qua, xem frame 0/6/11; analyze sạch; build web debug qua59,6s.
Đã xem SVG thật bằng rasterizer offline và đối chiếu cùng frame trước/sau.
Không kiểm trực tiếp Chrome đang mở vì công cụ không xác định được URL;
đã dừng thao tác UI. Không phát hành, thêm package, đổi nguồn hoặc phát
sinh phí. Nguồn miễn phí chỉ180p; không tuyên bố hết răng cưa100%/thành HD.
Cần hot restart; Chrome Ctrl+F5. Đề xuất tiếp: nguồn GIF độ phân giải cao
khi được yêu cầu; chưa thay. [Chi tiết](workout-gif-smoothing-v3-2026-11-15.md).

## 15/11/2026 — Giai đoạn tùy chọn 11: giảm viền trắng/răng cưa của GIF

Theo phản hồi còn quầng trắng quanh nhân vật, đã bổ sung co matte khoảng
một pixel nguồn và làm mềm alpha ở đường bao; không blur màu cơ thể.
Native xuất đúng RGB premultiplied; web áp dụng tương đương qua SVG.
Chế độ sáng dùng ảnh gốc, giữ gate media debug/phi thương mại hiện có.

Format qua; analyze sạch; 6 suite **54/54** qua; build web debug exit 0
(47,3 giây). Đã xem chi tiết/danh sách tối và danh sách sáng với GIF thật,
0 JS exception; ảnh so sánh crop từ hai screenshot thật cho thấy giảm
rõ quầng trắng. GIF nguồn 180p vẫn có giới hạn chi tiết khi phóng lớn.
Cần hot restart; web Ctrl+F5. Chưa nghiệm thu Android vật lý hoặc phát
hành. Đề xuất tiếp: nghiệm thu Android, chưa triển khai.
[File, log, ảnh và giới hạn](workout-gif-edge-refinement-2026-11-15.md).

## 15/11/2026 — Giai đoạn tùy chọn 11: nền GIF tập luyện theo sáng/tối

Đã đổi phần nền trắng quanh nhân vật ExerciseDB sang đen khi bật chế độ
tối, áp dụng chung cho danh sách, chi tiết và cover buổi tập. Tách vùng
gần trắng nối với mép ảnh; giữ màu cơ, chi tiết sáng bên trong nhân vật
và dụng cụ màu xám. Chế độ sáng dùng lại ảnh gốc/nền trắng.

Format qua; analyze **No issues found**; 6 suite **51/51** qua; web debug
harness build exit 0. Đã xem Flutter thật: danh sách sáng/tối và chi tiết
tối tải GIF thật, lần lượt 4/4/1 ảnh hoàn tất, 0 JS exception mỗi màn.
Không thêm package, backend hoặc tài nguyên GIF vào app; giữ gate debug
kiểm thử phi thương mại. Cần hot restart; chưa nghiệm thu Android vật lý
hoặc phát hành web/APK. Tiếp theo đề xuất: nghiệm thu Android, chưa làm.
[File, kiểm thử, ảnh và giới hạn](workout-gif-black-background-2026-11-15.md).

## 15/11/2026 — Giai đoạn tùy chọn 11: UX/UI Tập luyện

Đã tổ chức lại thư viện/buổi tập theo tham khảo giao diện chính thức Nike
Training Club và Seven. Thẻ GIF ngang, nhóm cơ vuốt ngang, bộ lọc có áp dụng/
hủy nháp/reset, giữ tìm kiếm khi chuyển tab; chi tiết có các bước đánh số,
biến thể nhẹ hơn và thông tin nguồn/an toàn. Buổi tập dùng cover đúng động
tác được ghép GIF, thời lượng thật và nút bắt đầu rõ hơn. Giữ đen/trắng,
Public Sans, Phosphor và san hô; không sửa backend/dữ liệu hoặc thêm package.

Format qua; analyze **No issues found**; 9 suite **88/88** qua. Build web
debug harness exit 0. Đã xem ảnh Flutter thật sáng/tối, chi tiết, bảng lọc
và buổi tập với GIF thật; không đọc/ghi Firebase. GIF vẫn chỉ bật ở debug
kiểm thử phi thương mại. Cần hot restart app đang mở; chưa nghiệm thu Android
hoặc phát hành APK/web. Đề xuất tiếp: nghiệm thu UX trên Android, chưa làm.
[File, kiểm thử, ảnh và giới hạn](workout-ui-refresh-2026-11-15.md).

## 15/11/2026 — Xác nhận GIF trên màn Tập luyện của app

Không sửa mã sản phẩm. Build debug harness dùng đúng WorkoutsScreen/theme và
service GIF, chỉ thay stream bằng danh mục bundled để xem độc lập. Build web
exit 0; Chrome viewport 430×1060 tải 3 GIF thật hoàn tất, metadata/GIF HTTP 200,
0 JS exception ở lần capture cuối, không đọc/ghi Firebase. Đã chụp và xem ảnh
`build/app-gif-review-20261115/tap-luyen-gif-dark.png` cho người dùng.

GIF miễn phí vẫn chỉ bật ở debug; chưa nghiệm thu Android hay cập nhật APK
trên máy người dùng. Cảnh báo Wasm scanner và assertion emulated viewport
ở lần capture đầu được ghi trong [báo cáo](app-gif-preview-2026-11-15.md).

## 14/11/2026 — Giai đoạn tùy chọn 11: giao diện web admin

Đã đổi primary sang đen/trắng, bỏ mint/tím chủ đạo và đồng bộ 17 màu feature
với app. Phát hành thư viện 50 bài trên web với thêm/sửa/ẩn/khôi phục, bộ lọc
trạng thái và thống kê. GIF inline có lazy load/hủy riêng từng owner ở local
phi thương mại; web online giữ gate tắt GIF miễn phí theo điều kiện đã chốt.

Node **147/147**, kiểm cú pháp qua; Chrome **72 lượt trang** ở sáng/tối và bốn
chiều rộng, candidate cũng qua. Hai GIF ExerciseDB thật đã load hoàn tất trong
browser local. SDK emulator **1/1** kiểm đúng candidate: CRUD/archive/restore,
audit, phiên bản và nhận snapshot. Không sửa hoặc chạy lại Flutter.

Hosting đã phát hành 434 tệp, version `d18532468d67f18a`; đọc lại **17/17 URL**
khớp byte/hash candidate. Chỉ thay/thêm 13 tệp; giữ byte của 421 tệp khác
và config/App Check/Rules. Không ghi thử production, đổi billing hoặc push Git.
Cần mở https://healthmate-admin-vn.web.app rồi Ctrl+F5; chưa nghiệm thu thao tác
ghi bằng tài khoản production. File, log, lỗi kiểm thử đầu và giới hạn:
[báo cáo](admin-ui-refresh-2026-11-14.md).
Đề xuất tiếp: nghiệm thu admin/app thật khi được yêu cầu, chưa triển khai.

## 10/11/2026 — Giai đoạn 4: đã phát hành bộ dinh dưỡng xác minh

Đã phát hành Firebase `verified-nutrients-2026-11-10-v1`: cập nhật 110 món,
106 natri/74 đường/4 xơ có nguồn; atomic commit với 110 audit, backup và
updateTime. Đọc lại 110/110 món + 110/110 audit, giữ các field ngoài patch;
review lại 0 cập nhật/0 xung đột. Không sửa nhật ký người dùng.

Web live `60d6d4c5fd3c672b` chỉ thêm dòng số liệu trong chi tiết món/ngắt URL,
giữ 31 file khác và config/Rules. APK kiểm thử đã chuẩn bị, asset khớp nguồn.
Node catalog/release25/25, admin113/113, hồi quy sau sửa URL50/50, Chrome9/9
qua; verify Firestore/Hosting qua. Không sửa Dart hoặc chạy lại full Flutter.
Không cần cấu hình mới; Android vật lý/ký release/Play Store chưa làm.

File chính: tool/publish_verified_nutrients.cjs và test, admin-web/tool/
publish-nutrient-display.cjs và test, app.mjs ngắt URL, báo cáo phát hành.
Tiếp theo đề xuất: nghiệm thu Android khi được yêu cầu; chưa triển khai.
[Báo cáo phát hành và bản cài](verified-nutrients-release-2026-11-10.md).

## 10/11/2026 — Giai đoạn 4: tra cứu và bổ sung natri/đường có nguồn

Đã tự tra Acecook, bảng Viện Dinh dưỡng 2007 do FAO lưu và archive USDA SR
Legacy đã có. Nhóm 213 mục Việt Nam/đồ gói hiện có 106 mục natri, 74 mục
đường, 4 mục chất xơ tổng; trước đó là 0/0/4. Không đổi calo/ba chất, ID,
ảnh hay snapshot nhật ký. Giữ dấu thiếu, số 0 thật và cơ sở gói khô đúng vị.

File chính: ingredients/packaged/legacy_usda JSON, asset Vietnamese foods,
importer kiểm tra source/đơn vị và catalog_food_reader cho document cũ hoàn
toàn thiếu extras; test nguồn/khẩu phần và docs. Không thêm package/schema.

Node catalog/ảnh **15/15**, Flutter nhóm nguồn/đồ gói/Home **17/17**, toàn
Flutter **1.235/1.235** qua (2m17s), analyze sạch (24,8s), format/diff qua.
Đã kiểm mã/trang đủ 101 mục PDF và render đối chiếu mẫu; đối chiếu tab/ảnh/
bốn macro cho từng gói, exact FDC ID cho bốn mục USDA.
Debug APK build qua20,7s; asset trong APK khớp hash source và dữ liệu mới.
Còn cảnh báo KGP tương lai từ plugin hiện có, không chặn build.

Trạng thái cuối lượt chuẩn bị (trước lần phát hành ghi ở trên): chưa ghi
production/deploy/push. Khi đó web admin còn dữ liệu Firestore cũ;
cần phát hành app và cập nhật catalog online có audit/version. Chưa đủ đơn
vị đường Miến Phú Hương gà; TH trả403; bảng Acecook không có số xơ. Không
coi Celluloza của bảng2007 là chất xơ tổng. Công thức chưa đủ gia vị giữ
chỉ số chưa biết. Chưa nghiệm thu Android thật/ký release. Đề xuất tiếp:
nghiệm thu/phát hành dữ liệu có kiểm soát khi được yêu cầu.
[Nguồn, file và giới hạn](vietnamese-nutrients-2026-11-10.md).

## 10/11/2026 — Giai đoạn 8 mở rộng: muối, đường và chất xơ

Hoàn tất source local: Trang chủ vuốt/chọn hai nhóm Đạm · Bột · Béo và
Muối · Đường · Xơ, tính theo snapshot nhật ký và khẩu phần thật. Có thanh
tiến độ, mốc ngày tùy chọn và thông tin giải thích. Muối quy đổi từ natri;
đường tổng khác carb/đường tự do. Thiếu dữ liệu không hiển thị thành số 0.

Admin thêm/sửa đường tổng, natri, chất xơ và xem trước muối; giữ vi chất khác,
quyền admin/audit/version. Ba mốc ngày được lưu/đọc bằng repository, giữ khi
cá nhân hóa/onboarding tính lại kcal; form còn giữ các mốc đang nhập.

File chính: HomeNutrientPanels/dashboard, NutritionTotals/bảng dinh dưỡng,
model/repository/form/card mục tiêu, planner/onboarding; admin app/validation/
nutrition-values, Rules và test. Không thêm package/dịch vụ/collection.

Kiểm thử: Flutter **1.233/1.233**, analyze sạch, admin **110/110**, Rules
**71/71**, Flutter SDK trên Emulator **1/1**, Chrome **72 lượt trang và form
ở 8 cấu hình**. Format 15 file/0 đổi và diff check qua; đã xem ảnh sáng/tối.
Lượt full đầu tìm ra tràn nhãn nút ở chữ lớn, đã sửa và chạy lại toàn bộ.
Debug APK build thành công, assembleDebug 49,4s. Cảnh báo KGP tương lai từ
plugin hiện có vẫn còn; chưa nâng dependencies ngoài phạm vi.

Chưa deploy/push, chưa nghiệm thu điện thoại Android thật hoặc ký release.
Cần phát hành Rules rồi app/web mới để dùng field mới online. Món/nhật ký
thiếu vi chất vẫn chưa đủ dữ liệu; không tự điền hoặc sửa lịch sử. Đề xuất
tiếp: nghiệm thu/phát hành đồng bộ khi người dùng yêu cầu.
[Chi tiết, kiểm thử và giới hạn](secondary-nutrients-2026-11-10.md).

## 10/11/2026 — Giai đoạn 4 mở rộng: ảnh món ăn trong admin

Hoàn tất source local: admin thay ảnh bằng URL HTTPS có credits/giấy phép,
xem trước, gỡ ảnh hoặc khôi phục ảnh bundled. Danh sách/chi tiết có preview;
51 preview giữ đúng hash/license của app. Lưu qua transaction/audit/version
hiện có. App dùng stream catalog chung, cập nhật cả modal ảnh đang mở;
gỡ ảnh không bật lại ảnh cũ và không đổi snapshot dinh dưỡng.

File chính: food-photos.mjs/css/registry/assets trên web; app/validation và
CSP/release tools; FoodPhoto/model/parser/provider/thumbnail/card/portion
trong Flutter; firestore.rules và test Node/DOM/SDK/Rules/widget.

Kiểm tra thật: Node **108/108**, admin Rules **13/13**, realtime Firebase
SDK emulator **13/13**, Chrome **72 lượt trang + form ảnh ở 8 kích thước/theme**;
Flutter **1.220/1.220**, analyze sạch, debug APK thành công. Dart format và
diff check qua. Log `build/admin-photo-*.log`; ảnh QA đã xem.

Không cần bật Storage/billing cho phương án URL; chưa có upload tệp từ máy.
Món chỉ có trong bundle cần bản ghi catalog cùng ID trước khi quản trị ảnh.
Chưa deploy/push, chưa ghi dữ liệu production hoặc cài APK lên máy thật.
Cần phát hành Rules/web/app mới để dùng online; ảnh custom cần mạng và
URL còn hoạt động. Build có cảnh báo KGP từ plugin hiện tại, không chặn build.
Đề xuất tiếp: nghiệm thu/phát hành đồng bộ khi người dùng yêu cầu.
[Chi tiết, file và giới hạn](admin-food-photos-2026-11-10.md).


## 10/11/2026 — Giai đoạn tùy chọn 11: admin đồng bộ nhận diện với app

Đã đưa Lucide cùng phiên bản với Flutter vào sidebar, brand, tiêu đề,
thống kê và thao tác; 17 màu nhận diện lấy từ Dart. Web dùng Inter, nền
trắng/đen theo lựa chọn Thiết bị/Sáng/Tối, nhớ preference và hỗ trợ đổi
theo thiết bị/các tab. Form, bảng, hỗ trợ và đăng nhập cùng theme.

File chính: admin-shell/app/dashboard/index, admin-icons, appearance.js/css,
feature-identity.css, giấy phép/manifest và tool tái tạo; test UI/DOM/bundle.
Node **104/104 qua**, syntax check qua; Chrome **72 lượt trang** ở
320/390/1024/1440px × sáng/tối, form, đăng nhập, drawer/thu gọn, lưu theme
qua. Ảnh QA dùng adapter local trống, không phải số liệu production.

Source local đã hoàn thiện; web online chưa deploy. Cần chạy lại/tải lại
web local để xem. Không đổi backend/Rules hoặc dữ liệu Firebase.
Đề xuất tiếp: nghiệm thu đăng nhập thật và phát hành Hosting khi được yêu cầu.
[Báo cáo đầy đủ](admin-app-identity-2026-11-10.md).

## 10/11/2026 — Giai đoạn tùy chọn 11: bộ icon toàn app

Thống nhất icon sản phẩm sang Lucide nét bo tròn; tạo registry dùng chung,
nhận diện tính năng bằng hình/màu, khung icon nhất quán và nền tab đang mở.
Áp dụng các màn Auth/onboarding, Home, nhật ký, dinh dưỡng/scanner, tập luyện,
mục tiêu, AI, hồ sơ, hỗ trợ, Premium và báo cáo. Font icon offline 47.284 byte,
119 glyph/138 tên; kèm ISC/MIT, không thêm package hoặc đổi backend.

File chính: `app_icons.dart`, `app_feature_visuals.dart`, `app_colors.dart`,
`feature_icon_badge.dart`, `app_shell.dart`, menu Profile/Wellness/Home và
presentation icon; assets font/manifest/license, pubspec và tool tái tạo.

Toàn Flutter **1.217/1.217 qua** (2m12s), nhóm UI trọng tâm **34/34 qua**,
analyze sạch. Kiểm font/hash/license/glyph/migration qua; đã xem ảnh render
119 glyph, Home, Cá nhân và bảng icon sáng/tối. Màn nhỏ/chữ lớn giữ nhãn,
vùng bấm và thao tác thật. Chi tiết kết quả cuối và bản cài:
[báo cáo bộ icon](icon-system-2026-11-10.md).

Cần chạy lại/cài app mới để nhận font; không cần cấu hình Firebase mới.
Chưa nghiệm thu điện thoại thật/ký release; không push hoặc deploy.
Đề xuất tiếp theo: kiểm tra trực quan icon trên Android thật khi được yêu cầu.

## 10/11/2026 — Giai đoạn 4 bổ sung: chọn món và dinh dưỡng theo ảnh tham khảo

Đã đổi danh sách/thẻ và trang chi tiết món theo mẫu: ảnh lớn, calo và tỷ lệ
ba chất theo khẩu phần; bảng dinh dưỡng kéo lên; nguyên liệu theo nguồn
công thức và ảnh hợp lệ. Bỏ dropdown bữa sáng/trưa/tối/phụ khỏi màn chọn món,
giữ ngày/giờ và tương thích dữ liệu cũ. Nền đen/trắng theo theme, Inter.
Thêm4 ảnh nguyên liệu, tổng51 ảnh512px, giữ nguyên số món/dinh dưỡng.

File chính: food_portion_dialog, food_nutrition_panel, food_selection_theme,
meal_form_dialog, selection card/photo/registry; model/parser/catalog loader,
recipe asFood và test luồng/ảnh. Không thêm package/chi phí/ghi Firebase.

Toàn Flutter **1.210/1.210 qua**, exit0 (2m8s), Node **14/14**, analyze sạch
(28,2s), format20 file/0 đổi, diff sạch. Đã xem ảnh render sáng/tối/chữ lớn.
Debug APK build qua34,2s, kiểm ZIP51 ảnh đúng hash; bản cài
`build/releases/healthmate-food-detail-20261110-debug.apk`.

Cần cài lại/chạy lại app để nhận ảnh/UI; không cần cấu hình Firebase mới.
Thiếu dưỡng chất hoặc nguyên liệu sẽ ghi rõ, không điền theo mẫu. Chưa
nghiệm thu Android vật lý/ký phát hành; chưa push/deploy. Bước tiếp đề xuất:
nghiệm thu chọn/ghi món Android thật, chưa tự thực hiện.
Chi tiết: [báo cáo giao diện](food-selection-detail-2026-11-10.md).


## 09/11/2026 — Giai đoạn tùy chọn 11: tập luyện theo tham khảo Seven

Đã bổ sung thư viện ba buổi, 14 động tác có hướng dẫn/biến thể nhẹ hơn và
minh họa chuyển động, ba nhịp tập, bộ đếm tập/nghỉ, pause/skip/dừng sớm,
tự tạm dừng khi ra nền và tổng kết/xác nhận lưu. Dùng repository nhật ký
vận động hiện có; chỉ lưu phút tập trọn vẹn và operation ID chống trùng.
Không thêm dependency/schema/Rules/billing hoặc giả calo tiêu hao.

Model **13/13**, UI **20/20** (gồm matrix 12 màn/chữ/theme), SDK emulator
**1/1** với hai tài khoản và ghi cùng ID đồng thời đã qua. Toàn bộ Flutter
**1173/1173** qua (2 phút), analyzer sạch (31,4s), format/diff qua; debug APK
build thành công (30,4s), source audit 725 file/0 finding. Đã xem ảnh thật
của widget Inter sáng/tối.
Cần nối lại Android để nghiệm thu rung, nhập/xem bài và ra nền/khóa màn hình;
chưa deploy, ký release hoặc đẩy Git. Session chưa phục hồi khi tiến trình
bị tắt. Chỉ đề xuất nghiệm thu Android tiếp theo. File và kết quả đầy đủ:
[báo cáo tập luyện](guided-workouts-2026-11-09.md).

## 09/11/2026 — Giai đoạn tùy chọn 11: câu hỏi ban đầu theo tham khảo Wao

Đã đổi thành mỗi màn một câu, nhập/kéo số đo và BMI phản hồi ngay; giữ đủ
năm mục tiêu, tách thói quen thành nhánh tùy chọn. Trang cuối tự tạo đề xuất
kcal/TDEE/điều chỉnh/macro khi đủ thông tin, chỉ lưu sau xác nhận, có thể giữ
mục tiêu cũ hoặc không áp dụng calo. Tăng cơ dùng mức duy trì với phân bổ
ưu tiên đạm. Nháp version 2 dùng ID màn và đọc được nháp cũ; không đổi schema
Firestore, Rules, backend hay dependency.

File chính: onboarding journey/progress/screen/widgets; 10 test mới và cập
nhật harness/test hiện có. Toàn bộ Flutter **1140/1140 qua**, sau câu chữ cuối
**17/17 qua**, analyzer sạch, format/diff qua; Android runtime **7/7**, debug
APK build thành công. Đã xem ảnh Inter của mục tiêu/kế hoạch; UX kiểm màn
320/390/412px, chữ 100/150/200%, sáng/tối.

Cần kết nối lại điện thoại và F5; người đã thiết lập mở Cá nhân → Cá nhân
hóa thêm. Chưa cài bản mới vì thiết bị ngắt USB, chưa nghiệm thu Android
thật/ký phát hành hoặc đẩy Git. Tiếp theo chỉ đề xuất nghiệm thu trên điện
thoại. File, số liệu và giới hạn: [báo cáo onboarding](onboarding-journey-2026-11-09.md).

## 08/11/2026 — Giai đoạn 10: cải thiện hồ sơ người dùng

Đã thêm lối tắt Hồ sơ/Cân nặng/Tài khoản; giữ độ chính xác khi sửa dữ liệu;
chọn giờ cân, hiển thị ngày đủ năm và nguồn tính BMI; đưa về trang mới nhất
sau thêm/sửa; phân biệt trang cũ rỗng. Xóa lần cân có xác nhận từ repository,
chặn gửi lặp, giữ lỗi/thử lại và đóng khi đổi phiên. Hiện provider đăng nhập,
email đã xác minh và giải thích mật khẩu cho Google. Cải thiện chữ lớn và
trạng thái tải/lỗi. Không đổi schema, Rules, dependency hoặc query.

File chính: profile screen/overview/forms/chart, mới delete dialog và formatter;
`test/profile_quality_test.dart` thêm 12 ca. Flutter toàn bộ **1052/1052**;
hồi quy/preview cuối **84/84**, analyzer sạch, format 23 file/0 đổi; secret
audit 694 file/0 findings. APK debug qua, runtime config **7/7**. Chi tiết trong
[báo cáo hồ sơ 08/11](profile-quality-2026-11-08.md).
Cần chạy lại app/cài `healthmate-profile-quality-20261108-debug.apk`; không
cần cấu hình Firebase mới. Chưa nghiệm
thu Android thật/ký phát hành hoặc deploy. Bước kế tiếp chỉ đề xuất nghiệm thu
hồ sơ trên Android khi sẵn sàng, không tự triển khai thêm giai đoạn.

## 08/11/2026 — Giai đoạn 10: độ tin cậy thanh toán Premium

Đã sửa chặn giao dịch thử ghi đè membership thật, completion chỉ sau máy chủ
xác nhận acknowledge, tải/restore/verify chạy chồng, callback trùng, timeout
và đổi tài khoản. RTDN kiểm tra JSON/package/payload, retry lỗi tạm thời với
lỗi đã lọc secret, nhận diện refund review cần xử lý thủ công. Admin không
hiện/xuất số tiền cũ đang chờ đối soát và từ chối đơn trùng/dữ liệu mâu thuẫn.

File chính: billing model/service/notifications/functions; controller/store/
repository/screen Premium Flutter; dashboard/verified-revenue/live-scope admin;
unit/widget/emulator tests. Không thêm dependency/schema/Rules trong đợt này.
Flutter **1040/1040**, kiểm lại billing sau chỉnh cuối **18/18**; analyzer sạch;
Functions **29/29**, web **93/93**, gateway **49/49**, release guard **6/6**,
Rules **143/143**, liên thông Firestore billing **2/2**, syntax/format qua.

Cần người dùng: Play Console/app/product, Blaze và cấu hình IAM/App Check/RTDN
trước triển khai và nghiệm thu sandbox. Source local, chưa triển khai các sửa
này hoặc mở thu tiền. Android thật/ký phát hành tiếp tục để sau. Chi tiết,
APK và giới hạn: [báo cáo 08/11](billing-reliability-2026-11-08.md).
Tiếp theo đề xuất nghiệm thu Google sandbox; chưa tự thực hiện.

## 07/11/2026 — Giai đoạn 10: hoàn thiện web admin

Đã bổ sung tra cứu máy chủ UID/email/đầu tên món, audit mới nhất và lọc/xuất
ngày Việt Nam, bảo vệ bản nháp editor/cấu hình/hỗ trợ, retry lỗi, URL theo
trang và danh mục chỉ đọc 33 bài tập lấy từ app. Qua 83/83 web, 20/20 SDK,
9 trang × 3 kích thước Chrome, script Dart analyze sạch và kiểm catalog khớp.
Ba query production HTTP200 chỉ đọc. Đã publish Hosting và đọc lại khớp đủ
30 tệp; Rules giữ nguyên. Không sửa app hoặc bật billing. Rollout/giới hạn trong
[báo cáo web admin](admin-completion-2026-11-07.md).

Cần người dùng: tải lại web và nghiệm thu các thao tác bằng admin thật. Auth
total vẫn snapshot; Premium demo; bài tập chỉ đọc. Tiếp theo chỉ đề xuất
nghiệm thu, không tự làm luồng backend trả phí hoặc nghiệp vụ mới.

## 07/11/2026 — Giai đoạn 10: sửa vận hành và đồng bộ app/admin

Đã sửa và publish Rules + web lúc khoảng 14:20 UTC+7. Đọc lại Rules và 27
tệp Hosting khớp bản đã kiểm. Ba luồng xóa tài khoản, hỗ trợ hai chiều và
danh mục đã qua SDK thực trên emulator. Release tool dùng nguyên Rules
chuẩn; không bỏ sót deletion job/support quota. Qua 129 Rules, 35 SDK,
71 web; 952 Flutter trước sửa listener cuối và 29 hồi quy sau sửa cuối;
analyze sạch. Giữ Spark, billing false, không deploy Functions. Chưa nghiệm
thu thiết bị Android thật; tổng Auth vẫn snapshot thủ công, Premium demo.
APK debug mới build thành công lúc 14:21:18; cấu hình admin qua 7/7.
File: `build/releases/healthmate-operations-20261107-debug.apk`, chưa cài
vì không có thiết bị adb. Cần cài APK mới và tải lại web để nghiệm thu.
File/bằng chứng và giới hạn: [báo cáo đợt sửa](operations-hardening-2026-11-07.md).

## 06/11/2026 — Giai đoạn tùy chọn 11: đổi font sang Inter

1. **Phạm vi/trạng thái:** hoàn tất typography app + web admin theo yêu
   cầu; source local, chưa publish web hoặc build/cài APK.
2. **Đã hoàn thành:** Inter chính thức v4.1, đủ 400/500/600/700 và tiếng
   Việt, đóng gói offline; cả theme sáng/tối và web dùng font mới. Giữ
   giấy phép OFL, server local hỗ trợ WOFF2; không thêm dependency.
3. **File chính:** `pubspec.yaml`, `design_tokens.dart`, `style.css`,
   `server.mjs`, hai thư mục font Inter, 20 test loader, README và báo cáo.
4. **Kiểm thử:** format qua, analyzer sạch; Flutter **944/944**, web
   **61/61**, 0 skip. Kiểm 187 codepoint/weight, font Chrome thực render,
   bốn kích thước web và 9 trang × 3 kích thước qua. Đã xem ảnh app/web.
5. **Cần người dùng làm:** dừng và chạy lại app bằng F5; web local tải
   lại/khởi động lại server cũ. Không cần cấu hình Firebase mới.
6. **Còn lại:** chưa nghiệm thu Android thật hoặc cập nhật web online.
   Ảnh web dùng snapshot đọc thật trước đó, giữ nhãn thời điểm; không
   tạo số mới. Không đổi nghiệp vụ, Rules/backend hoặc ghi production.
7. **Tiếp theo đề xuất:** nghiệm thu Inter và rollout theo yêu cầu;
   chưa tự triển khai bước khác.

Chi tiết: [Inter cho app và admin](inter-font-2026-11-06.md).

## 06/11/2026 — Giai đoạn tùy chọn 11: đổi admin sang phong cách tối

1. **Phạm vi/trạng thái:** hoàn tất polish web admin theo ảnh mới người
   dùng gửi; source local đã kiểm thử, online chưa cập nhật. Giữ các thay
   đổi trước đó, không triển khai nghiệp vụ/giai đoạn khác.
2. **Đã hoàn thành:** nền đen, sidebar đen, panel xám đậm, điểm nhấn xanh;
   bốn card ở đầu, biểu đồ trái/thông tin vận hành phải. Bảng/form/dialog/
   đăng nhập cùng theme; danh tính thật và logout ở footer sidebar. Giữ
   menu/chức năng, sửa focus drawer, hỗ trợ desktop/mobile.
3. **File chính:** `admin-theme.css`, `admin-shell.mjs`,
   `dashboard-page.mjs`, `index.html`, DOM tests, README và báo cáo UI/test.
4. **Kiểm thử:** syntax/diff qua, secret audit 0 findings;
   Node/DOM **61/61**, 0 skip. Ảnh dữ liệu thật
   ở **1440/1024/390/320 px** không tràn ngang/lỗi JS. Browser QA 9 trang
   ở **1440/390/320 px**, dialog/login/Tab/Escape qua sau sửa focus drawer.
   Không chạy lại Flutter/SDK/Rules vì không sửa các phần đó.
5. **Cần người dùng làm:** xem bản mới và nghiệm thu; theme không cần cấu
   hình Firebase mới. Rollout web và summary Auth là bước còn chờ riêng.
6. **Còn lại:** Premium vẫn demo; bài tập chờ triển khai. Ảnh dùng snapshot
   Firebase thật lúc **01:50:46 ngày 06/11 UTC+7**: Auth 3, kỳ 01–06/11 có
   0 giao dịch/0 VND mô phỏng/0 khách mua. Không thêm số/tăng trưởng minh
   họa, thêm package, đổi Rules/backend hoặc ghi production/commit/deploy.
7. **Tiếp theo đề xuất:** nghiệm thu và rollout UI admin, chưa thực hiện.

Chi tiết: [Admin phong cách tối](admin-dark-ui-2026-11-06.md).

## 03/11/2026 — Polish UI admin theo ảnh tham khảo

1. **Phạm vi/trạng thái:** hoàn tất UI admin theo yêu cầu riêng, tương ứng
   phần polish; đã kiểm thử local, chưa publish. Không mở thêm giai đoạn
   nghiệp vụ hoặc sửa backend/Rules trong lượt này.
2. **Đã hoàn thành:** sidebar trắng với Tổng quan, Doanh thu, Khách hàng,
   Thực phẩm, Bài tập luyện, AI Chatbot và các trang vận hành đang có;
   header, panel, bảng/form và bốn card gradient theo ảnh. Thu gọn desktop,
   drawer mobile; biểu đồ lấy giao dịch đã lưu, dữ liệu trống hiện đường 0.
   Trang bài tập ghi rõ chờ triển khai; AI dùng cấu hình/audit hiện có.
3. **File chính:** mới `admin-web/dist/admin-shell.mjs`, `admin-theme.css`;
   sửa `index.html`, `app.mjs`, `dashboard-page.mjs`, DOM tests, package
   check, README và báo cáo UI/test. Giữ thay đổi chưa commit từ lượt trước.
4. **Kiểm thử:** syntax/diff check qua, source secret audit 0 findings;
   Node/DOM **60/60**, 0 skip. Chrome ở
   **1440/1024/390/320 px** không tràn ngang hoặc lỗi JS. Ảnh dùng dữ liệu
   Firebase đọc thật lúc **02:01:25 ngày 03/11 UTC+7**: Auth 3; kỳ 01–03/11
   có 0 giao dịch demo, 0 VND mô phỏng, 0 khách mua. Không chạy lại Flutter,
   SDK/Rules vì không thay code thuộc các phần đó.
5. **Cần chủ dự án làm:** nghiệm thu bản xem trước; rollout web là bước
   riêng còn chờ. Tổng Auth trên sản phẩm vẫn cần summary/Rules patch
   tối thiểu theo báo cáo dashboard trước; chưa chạy `--apply`.
6. **Còn lại:** Premium vẫn demo, chưa thu tiền; bài tập chưa có catalog
   hoặc CRUD. Không dùng ảnh fixture để bàn giao, không tự điền số, không
   thêm package hoặc ghi production. Web online chưa thay đổi.
7. **Tiếp theo đề xuất:** nghiệm thu và rollout UI admin; chưa thực hiện.

Chi tiết: [Giao diện theo ảnh mẫu](admin-ui-reference-2026-11-03.md).

## 03/11/2026 — Đính chính ảnh dashboard dùng dữ liệu test

- Người dùng yêu cầu số thực, phản đối ảnh có42 tài khoản/240.000đ.
  Agent nhận lỗi dùng ảnh fixture làm bàn giao, thay bằng bản đối chiếu
  chỉ đọc từ Firebase thật, không tự điền số hoặc ghi dữ liệu production.
- Lần đọc00:58:12 UTC+7: Auth3, directory1, suspended0, catalog158,
  audit7; kỳ01–03/11 có0 receipt demo,0 VND mô phỏng,0 khách mua.
- Ảnh mới nằm trong `build/admin-dashboard-real-20261103/`; Chrome1440/
  390px xác minh ô hiển thị khớp dữ liệu đọc, không tràn ngang/lỗi JS.
  Không sửa mã sản phẩm/Rules nên không chạy lại toàn suite Flutter/Rules.
- File cập nhật: tài liệu dashboard, implementation-progress, test-report;
  script đọc/ảnh đối chiếu chỉ ở build ignored. Online chưa thay đổi;
  rollout và đồng bộ summary vẫn là bước còn chờ, không tự thực hiện.

## 02/11/2026 — Sửa dashboard admin theo yêu cầu

1. **Phạm vi/trạng thái:** dashboard admin, candidate đã sửa và kiểm thử
   local; chưa publish/Rules rollout/ghi summary production. Không thực hiện
   giai đoạn MVP hoặc phần tập luyện kế tiếp.
2. **Đã hoàn thành:** tổng tài khoản lấy aggregate Auth có thời điểm, doanh
   thu Premium demo, giao dịch/khách mua theo kỳ UTC+7, biểu đồ có bảng,
   5 giao dịch gần nhất, lối báo cáo/Excel; count/config lỗi độc lập, race
   sau refresh/đổi kỳ/logout được bỏ. Đồng bộ tổng bằng helper chủ dự án.
3. **File chính:** admin-web/dist/{app,firebase,dashboard-page,dashboard-model}.mjs,
   style.css; helper sync-account-statistics.cjs và tests; firestore.rules,
   admin.rules.test.cjs; database-design/README/tài liệu dashboard.
4. **Kiểm thử:** Node/DOM/helper55/55; SDK Emulator9/9; Rules128/128;
   syntax qua, Chrome1440/390/320px không tràn ngang; secret audit0 finding.
   Không sửa Dart/Android nên không chạy format/analyze/test Flutter.
5. **Cần chủ dự án làm:** yêu cầu rollout web + Rules patch tối thiểu dựa
   trên production hiện hành, đồng bộ tổng có `--apply`, nghiệm thu web.
6. **Còn lại:** tổng Auth cập nhật thủ công, có thể cũ sau đăng ký/xóa;
   revenue vẫn mô phỏng, 5.000 giao dịch/kỳ. Truy vấn chỉ đọc thấy3 tài khoản,
   chưa ghi lên server. Không deploy toàn root candidate Rules.
7. **Tiếp theo đề xuất:** rollout dashboard admin có kiểm soát và nghiệm
   thu; không tự mở giai đoạn hoặc tính năng khác.

Chi tiết và lỗi kiểm thử trung gian: [admin-dashboard-2026-11-02.md](admin-dashboard-2026-11-02.md).

Trạng thái mới nhất (01/11/2026): đã thu gọn giao diện theo dõi dinh dưỡng;
944/944 kiểm thử Flutter qua, analyzer sạch. Gói10 chưa nghiệm thu signed release/native.
Các giai đoạn/mốc cũ giữ làm lịch sử.

## 02/11/2026 — Kiểm tra trước commit/push GitHub

- Người dùng yêu cầu đưa code hiện tại lên repository GitHub HealthMate.
  Đã fetch và xác nhận `main` cùng baseline với `origin/main` trước commit.
- Kiểm tra source không phát hiện secret. Giữ token debug và tệp build ngoài
  commit theo cấu hình ignore. Kết quả Flutter gần nhất944/944, analyzer sạch.
- Sửa đúng điểm chặn CI: bốn kiểm thử gọi `powershell.exe` chỉ chạy Windows;
  thêm job `windows-launcher` trên GitHub Actions để vẫn chạy đủ các ca này.
  Kiểm tra wiring bằng đọc source vẫn chạy Linux. Windows local5/5 qua,
  không skip; chưa coi workflow hosted là đã qua trước khi GitHub chạy.
- Không thay Dart/backend/Rules hoặc triển khai tính năng/giai đoạn mới.

## 01/11/2026 — Giai đoạn tùy chọn 11: thu gọn giao diện dinh dưỡng

1. **Trạng thái:** hoàn tất phạm vi UI theo phản hồi quá nhiều thông tin,
   thao tác rối; giữ các sửa đổi đã có trong workspace.
2. **Đã làm:** Hôm nay ưu tiên kcal và bữa ăn; bỏ cụm lối tắt, bảng lặp;
   nút + mở thẳng thêm món. Nhật ký còn một danh sách chỉnh sửa; form đưa
   tìm món lên đầu, lưu cố định, công cụ phụ/hướng dẫn mở theo yêu cầu.
   Quay lại chi tiết thói quen đúng cấp; sửa cân từ Cá nhân làm mới Tiến độ.
3. **File chính:** app_shell/profile_avatar; dashboard và ba widget năng lượng/
   macro/bữa; journal_screen; meal_form_dialog/meal_entry_sources/meal_log_section;
   meal_food_sources/food_portion_dialog; profile_screen và wellness screen/hub.
   [Chi tiết và ảnh trước/sau](nutrition-ui-simplification-2026-11-01.md).
4. **Kiểm thử:** toàn Flutter **944/944 qua**, không bỏ qua ca nào; analyzer
   **No issues found**. Kiểm tra ngày cũ, món/khẩu phần, nháp, retry/UID,
   camera giả lập và bố cục 320/390/412, chữ1/1,5/2, sáng/tối. Sáu capture
   widget qua; đã xem ảnh Hôm nay/Nhật ký/thêm món, lưu gallery so sánh.
5. **Cần người dùng làm:** hot restart hoặc chạy F5 để xem bản mới; tự test
   Android theo lựa chọn trước đó. Không cần cấu hình Firebase cho phần UI.
6. **Còn lại:** chưa nghiệm thu thiết bị hoặc build APK trong lượt này.
   Các blocker backend ảnh/signed release trước đó còn nguyên. Không đổi
   Rules/dữ liệu production, thêm package, deploy, push hoặc tắt laptop.
7. **Tiếp theo đề xuất:** người dùng tự nghiệm thu giao diện Android và chỉ
   rõ màn cần chỉnh tiếp; chưa thực hiện thêm giai đoạn.

## 01/11/2026 — Sửa lỗi quyền truy cập sau đăng nhập

1. **Trạng thái:** hoàn tất sửa cấu hình và deploy bản vá nhỏ theo phê duyệt
   trực tiếp **Áp dụng bản vá lên Firebase**. Chưa nghiệm thu điện thoại.
2. **Nguyên nhân:** Rules production chưa cho đọc `account_deletions/{uid}`
   mà app dùng ở startup. Đã tái hiện với đúng Rules đang chạy trên emulator.
3. **Đã sửa:** bổ sung riêng owner-get đã xác minh email; không mở list/write
   hoặc cross UID. Giữ toàn bộ Rules production khác, không deploy root Rules.
   F5 nạp cấu hình chung và token App Check từ file riêng ngoài repository.
4. **File chính:** `.vscode/launch.json`, `.vscode/tasks.json`,
   `tool/prepare_vscode_android.ps1`, README và các test. Candidate/backup/
   postdeploy hashes: [báo cáo sửa truy cập](firebase-access-fix-2026-11-01.md).
5. **Kiểm tra:** launcher5/5, admin runtime7/7, SDK emulator7/7; build debug
   với đúng cấu hình F5 thành công (26,8 giây). Postdeploy source khớp chính
   xác candidate đã duyệt. Secret audit không có finding; diff check qua.
6. **Cần người dùng làm/còn lại:** bấm Kiểm tra lại; dùng F5 ở lần chạy sau,
   tự test Android. Chưa rollout toàn bộ deletion/migration/support candidate,
   chưa signed release. Không thay dữ liệu người dùng/push/hẹn tắt laptop.
7. **Tiếp theo đề xuất:** người dùng xác nhận mở được app trên điện thoại.

## 01/11/2026 — Sửa lỗi build Android từ VS Code

1. **Phạm vi/trạng thái:** hoàn tất sửa lỗi build được người dùng gửi ảnh;
   không mở rộng sang tính năng hoặc nâng cấp thư viện.
2. **Đã sửa:** import `java.io.File` và dùng `File(...)` để tránh tên extension
   `java` của Gradle che package Java; cấu hình Android qua public
   `ApplicationExtension` thay accessor `android {}` đã deprecated.
3. **File chính:** `android/app/build.gradle.kts`; không thay signing guard,
   AGP/Gradle/Kotlin version, dependencies, Rules hoặc Firebase configuration.
4. **Kiểm tra:** tái hiện lỗi trước sửa; `gradlew help --offline` qua sau sửa;
   `flutter build apk --debug --no-pub` thành công (48,3 giây); release
   preflight unit tests6/6; release dry-run vẫn chặn đúng khi thiếu khóa ký.
5. **Cần người dùng làm:** bấm F5 trong VS Code để chạy lại và tự test Android.
6. **Còn lại:** cảnh báo tương thích Kotlin từ plugins hiện có chưa chặn build;
   chưa cài/chạy app trên điện thoại, chưa nghiệm thu signed release. Không
   deploy, push hoặc hẹn tắt máy. Log chi tiết ở `test-report.md`.
7. **Tiếp theo đề xuất:** người dùng nghiệm thu giao diện trên thiết bị.

## 01/11/2026 — Giai đoạn tùy chọn 11: làm lại giao diện tài khoản

1. **Trạng thái:** hoàn tất phạm vi đăng nhập/đăng ký theo yêu cầu trực tiếp.
2. **Đã hoàn thành:** giao diện chung cho đăng nhập, đăng ký, quên mật khẩu,
   gửi liên kết, xác minh email và chờ/lỗi phiên. Giữ email khi chuyển chế độ;
   Back/Next/Done rõ; lỗi đưa focus đúng ô; giữ form sau lỗi và khi trở lại từ
   quên mật khẩu; tiến trình Google/email riêng; nhãn đầy đủ ở chữ lớn.
3. **File chính:** `auth_flow_page.dart` mới cùng bốn màn Auth hiện có và phần
   reset trong `account_security_dialogs.dart`; 26 ca UX và 5 capture mới.
   [Chi tiết và ảnh](auth-ux-2026-11-01.md).
4. **Kiểm thử:** full Flutter **943/943**, analyzer không có vấn đề, format10
   file không lệch, diff check qua. Ma trận320/390/412 × scale1/1,5/2 × sáng/tối
   có bàn phím mô phỏng; guideline vùng chạm/nhãn trên đăng nhập/đăng ký qua.
5. **Cần người dùng làm:** tự nghiệm thu Android, TalkBack, bàn phím, Google
   và email thật. Không cần cấu hình Firebase mới cho việc đổi UI.
6. **Còn lại:** chưa nghiệm thu native/build APK; blocker production trước đó
   còn nguyên. Không đổi Rules/backend/dependencies, deploy, push hay tắt máy.
7. **Tiếp theo đề xuất:** nghiệm thu luồng tài khoản trên Android.

## 01/11/2026 — Toàn bộ cải thiện UX/UI theo tài liệu

1. **Phạm vi/trạng thái:** triển khai cả tài liệu UX/UI trong một lượt theo
   yêu cầu trực tiếp; không tự chuyển sang tính năng/giai đoạn khác.
2. **Đã hoàn thành:** giao diện xanh/trung tính, CTA thêm bữa rõ và giữ đúng
   ngày; bỏ qua cá nhân hóa để ghi nhật ký; nháp thiết lập theo UID/đúng bước;
   privacy trước Auth; calculator dẫn đúng trường; gate ảnh trước camera;
   Back/close giữ hoặc xác nhận bỏ nháp; biểu đồ có đơn vị và ngày thiếu;
   Profile gọn, báo cáo đầy đủ và tải khi cần.
3. **File chính:** core theme/router/shell; dashboard/journal; onboarding,
   encrypted MealDraftStore; form/controller/scanner; progress/profile/
   reports; 5 bộ UX tests mới. Danh sách và ảnh trong
   [báo cáo UX/UI](ux-ui-implementation-2026-11-01.md).
4. **Kiểm thử:** full Flutter **912/912**; analyzer không có vấn đề;
   format các file Dart thay đổi đạt. Ma trận 320/390/412 × chữ1/1,5/2 ×
   sáng/tối, kiểm tra bàn phím/Back/nguồn nhập bằng widget. Có 5 cặp ảnh
   trước/sau cùng fixture390×844; bước polish cuối được kiểm lại riêng.
5. **Cần người dùng làm:** nghiệm thu Android/TalkBack/bàn phím thật theo
   lựa chọn tự test thiết bị. Không cần thêm Firebase config cho phần UX.
6. **Còn lại:** backend ảnh chưa sẵn sàng, private drafts ngoài Android chưa
   hỗ trợ; signed release và blocker production cũ vẫn giữ. Chưa deploy,
   commit/push, đổi Rules/dữ liệu production hoặc hẹn tắt laptop.
7. **Tiếp theo đề xuất:** nghiệm thu Android và chốt bản giao diện; chưa tự
   triển khai thêm tính năng.

## 27/10/2026 — Giai đoạn tùy chọn 11: giao diện gọn và dễ đọc

Đã chỉnh bố cục các màn hình dinh dưỡng hằng ngày: nền tiêu đề khi cuộn, khoảng
cách dòng, hiển thị khẩu phần/dưỡng chất, tìm món, nhập bữa, mục tiêu và thực đơn
chia theo ngày. Hướng dẫn phụ đóng mặc định, giữ các cảnh báo/xác nhận cần thiết.
Không thêm thông báo, không sửa thuật toán hoặc lớp dữ liệu trong lượt UI.
File chính và phạm vi: [báo cáo UI](ui-polish-2026-10-27.md).

Format 22 file: 0 lệch; analyze 0 issues; full Flutter **685/685 qua**.
APK thường `build/releases/healthmate-ui-polish-debug.apk` build thành công; 7/7 runtime tests qua.
Không chạy lại luồng Android theo yêu cầu người dùng; người dùng tự nghiệm thu
bản UI mới. Không cần cấu hình mới. Không deploy/push/tắt laptop.
Bước tiếp theo đề xuất: người dùng kiểm tra UI trên Android; chưa tự triển khai.

## 27/10/2026 — Soạn SRS và product backlog từ GitHub

1. **Phạm vi/trạng thái:** hoàn tất tài liệu v0.1 theo yêu cầu; chờ người dùng/
   giảng viên review, không triển khai chức năng mới. GitHub `main` qua API khớp
   HEAD `14bb579b6d1549db1569ee7710b7b1733e92c5de`. Các thay đổi USDA/catalog/form
   chưa commit ở working tree được giữ nguyên và không tính là đã phát hành.
2. **Đã làm:** SRS có 52 FR, 12 NFR, actors, quy tắc, use cases, dữ liệu và ma
   trận 15 mục rubric. Backlog có 13 Epic, 52 Story, 6 Task; 174 tiêu chí nghiệm
   thu, priority, dependency và nguồn/test. Tách CODE/PARTIAL/PROPOSED; không tự
   gán Done, sprint, assignee hoặc ước lượng. Chưa tạo board/issue Jira thật.
3. **File chính:** `docs/requirements/HealthMate-SRS-2026-10-27.md`,
   `docs/requirements/HealthMate-Backlog-2026-10-27.md`, README cùng thư mục.
4. **Kiểm tra:** validator tài liệu exit 0: 116 đường dẫn nguồn/test tồn tại tại
   commit baseline, ID/anchor/link tương đối/dependency không lỗi, không chu
   trình. Đây là kiểm tra tài liệu, không phải 174 test ứng dụng. Không chạy lại
   format/analyze/Flutter/Rules/web tests vì lượt này không sửa code; kết quả
   test lịch sử trong SRS có ghi rõ nguồn và giới hạn.
5. **Cần làm tiếp:** review bốn báo cáo áp dụng toàn app hay admin, SMS có bắt
   buộc không, phạm vi ảnh/chi phí và hai luồng in; cung cấp/chọn Jira project
   khi muốn đồng bộ thật. File mới là Draft, chưa phải SRS đã duyệt.
6. **Giới hạn:** không commit/push/deploy, không đổi cấu hình/billing/dữ liệu,
   không triển khai các mục Proposed. Bước đề xuất là review SRS/backlog.

## 27/10/2026 — Sửa tích hợp admin và bản Android Figma

1. **Giai đoạn/trạng thái:** hoàn tất phạm vi sửa tích hợp admin được yêu cầu
   trong Giai đoạn 10; không mở rộng các module admin khác.
2. **Đã hoàn thành:** script run/build dùng chung cấu hình bật admin; build
   kiểm thử cờ trước khi đóng gói, ghi manifest không chứa token. App dừng đọc
   cấu hình khi bị khóa/chưa xác nhận và tự nối lại khi mở khóa. Ca thay đổi
   cấu hình lúc khóa đã tái hiện lỗi trước sửa và qua sau sửa; UI Figma giữ nguyên.
3. **File chính:** `config/admin-runtime.json`, `tool/android_app_arguments.ps1`,
   `tool/run_android.ps1`, `tool/build_android.ps1`,
   `lib/core/config/admin_runtime.dart`, `test/admin_runtime_test.dart`,
   `test/admin_runtime_integration.dart`, `tool/test_admin_integration.ps1`,
   README và tài liệu admin/test-report. Chi tiết: [admin-runtime-integration.md](admin-runtime-integration.md).
4. **Kiểm thử:** full Flutter **656/656**; runtime cấu hình build **7/7**;
   emulator **77/77 Rules + 4/4 web SDK + 3/3 Flutter SDK**; web unit **20/20**;
   analyze No issues found; format ba file 0 lệch; PS parser 4/4 và diff check qua.
   APK build exit 0, Gradle 34,0 giây; checksum manifest khớp tệp thật.
5. **Cần người dùng làm:** cài `build/releases/healthmate-figma-admin-debug.apk`
   và nghiệm thu trên Android thật. Không cần cấu hình Firebase mới; dùng token
   debug App Check hiện có. APK 236.844.262 byte; SHA256
   `07EB53A0DE0087818C2195BF6BFE0B7AD18D1E391899B1911E25446FB1DD9837`.
6. **Giới hạn:** chưa có thiết bị ADB, chưa thử live admin production → Android;
   còn cảnh báo KGP plugin cũ. Chưa sửa giới hạn danh sách 5.000 mục, chi phí
   đọc role theo UID hoặc bổ sung RBAC. Không đổi Rules/schema/backend/billing,
   không deploy/commit/push; không thực hiện yêu cầu tắt máy đã hủy.
7. **Tiếp theo đề xuất:** phân trang/lọc phía máy chủ cho danh sách và audit
   admin; chưa tự thực hiện.

## 27/10/2026 — Bộ 20 câu cá nhân hóa đã hoàn tất

Phạm vi mở rộng hồ sơ/onboarding (Giai đoạn 3): đúng 20 câu, chia các phần ngắn;
nhánh không tập/không đổi cân nặng bỏ câu không liên quan. Câu bổ sung có thể để
sau, null không phải 0/không có. Câu 1–9 dùng bộ tính kcal hiện có, phải xem lại
và xác nhận trước lưu. Người cũ không bị ép làm lại; vào Thêm → Cá nhân hóa ·
20 câu hỏi. Có 5 mục tiêu, tách thêm Tăng cơ; giá trị tăng cân cũ giữ nguyên.
Lưu map version1 theo UID, không gửi AI/không cho admin đọc. Sửa câu trả lời giữ
số đo cũ; cân nặng đổi thêm số đo, không đổi không tạo log. Giữ toàn bộ source
admin/cá nhân hóa/báo cáo đang chờ commit trước đó theo yêu cầu up GitHub.

Kiểm tra thực tế: format phần thay đổi 0 lệch; analyze 0 issues (7 giây);
full Flutter **646/646** (66 giây). Sau chỉnh text phân nhóm/giới hạn subtitle,
chạy lại analyze 0 issues và **7/7** ca khảo sát (3 giây). **39/39** ca hồi quy
Auth/account/widget/khảo sát qua sau sửa vị trí entry, không sửa test Auth để
bỏ qua lỗi. Rules **77/77** (24,8 giây); web **20/20**, SDK Emulator **4/4**.
Lần thử Rules đầu thiếu Java21 ở PATH/Emulator chưa lên nên không kết nối được;
đã chạy bằng Java21 và server8092. SDK lượt đầu thiếu fixture, seed local
--extended rồi 4/4; không hạ rule. Secret scan 478 file text, 0 mẫu credential
nhạy cảm; không phải chứng nhận audit toàn bộ lịch sử Git/APK.

Rules đã deploy scoped `firestore:rules`, không đổi Hosting/indexes/billing.
Readback hash `04a81618172e2a843e71c57b21208a080aa2643c14c55efce2dd24e6ab0c0428` khớp source,
ruleset `04f3777e-84c5-42a2-b242-56c1640a0bbe`. Backup trước/sau chỉ ở build/.
Warning knownNumber unused có sẵn; build còn warning Kotlin plugin có sẵn.
APK debug build qua **30,1 giây**, giữ define admin + AI debug cục bộ:
`build/releases/healthmate-questionnaire-20-debug.apk` (236777378 byte),
SHA256 `3afab0533edc044304ec1105a5b09d02e8c1063273ec332a3d02a1b32f20e984`. Chưa cài/thử trên điện thoại, không public APK/debug token.
Ảnh font thật 360×800/chữ150% đã xem, không overflow; một số lựa chọn dài hiển
thị dấu …, có toàn bộ nội dung trong phần xem lại. Không coi đây là nghiệm thu native.

File chính: models/personalization_answers.dart, presentation/personalization_questions.dart,
onboarding_screen.dart, profile_screen.dart, repository/model hồ sơ, router,
firestore.rules, test/personalization_questionnaire_test.dart và Rules tests.
Thiết kế/nguồn/giới hạn: [personalization-questionnaire.md](personalization-questionnaire.md).
Chưa áp bộ lọc thực đơn tự động theo chế độ ăn/dị ứng, chưa tự sửa lịch nhắc ngủ.
Bước kế tiếp đề xuất: nghiệm thu luồng 20 câu trên điện thoại; không tự mở giai đoạn khác.


## 27/10/2026 — Rollout admin production theo yêu cầu

Đã cấu hình reCAPTCHA Enterprise SCORE/App Check web cho hai domain Firebase,
giữ threshold0,5 và enforcement AI cũ; billing vẫn false. Cấp role đúng email
`luuxuantung285600@gmail.com` đã verified. Vì tài khoản chỉ có Google provider,
bổ sung nút Google sign-in và xử lý popup, CSP; production đợi App Check token.
Deploy scoped Rules/Hosting thành công, URL https://healthmate-app-20261013.web.app.
Rules đọc lại khớp hash5d02e187…/rulesete4c952fa…, không đổi indexes/health data.

File chính: admin-web Firebase adapter/UI/server/prepare tool, DOM auth test,
production-smoke opt-in; docs/admin-production/README/handoff/test-report.
20/20 web,4/4 SDK Emulator,74/74 Rules;17 kiểm tra end-user trên Firebase thật
qua, cleanup6 danh tính QA/fixture đã xác minh, giữ7 audit QA thành công.
11/11 tệp HTTPS khớp nguồn/header; token App Check sai bị403; runtime5/5 với
cờ true. Build debug21,6giây qua, giữ warningKGP cũ. APK
`build/releases/healthmate-admin-enabled-debug.apk`, chưa cài; source flag vẫn
false, build mới đã truyền true. Không commit/push, không nâng billing.

Người dùng chọn thử browser sau. Chưa nghiệm thu popup/token App Check hợp lệ
trình duyệt thật hoặc inbox email; không bật enforcement Firestore/Auth toàn
project trước metrics/mobileQA. Bước đề xuất: nghiệm thu thủ công web/APK khi
sẵn sàng, không tự làm tính năng mới. [Chi tiết](admin-production.md).

## 27/10/2026 — Hoàn thiện admin: danh mục/tài khoản/cấu hình

Theo yêu cầu mới, tiếp tục admin từng tạm gác; không chuyển sang giai đoạn mobile
khác. Hoàn thiện dashboard 4 số đếm, tìm/lọc toàn bộ danh sách ≤5.000 mục, trang
25 mục/STT, chi tiết/archive/restore có xác nhận, XLSX toàn bộ kết quả lọc và
trạng thái lỗi/đổi phiên. Ghi có audit/version/server ACK. Admin GET role theo UID
đã biết, không list/cấp role; dữ liệu sức khỏe vẫn riêng tư.

File chính: `admin-web/dist/{app,firebase,list-model,xlsx-export}.mjs`, style,
tests DOM/list/XLSX/SDK, seed extended, package/lock, tool kiểm tra chỉ đọc/gói
review, `firestore.rules`, hai suite Rules và tài liệu. Linkedom chỉ dev test;
không đổi Dart/schema/index/production config. Giữ toàn bộ thay đổi cũ chưa commit.

Kiểm thử: syntax qua, 19/19 Node/DOM, 4/4 SDK Emulator, 74/74 Rules, 5/5 Flutter
runtime, audit production deps 0; XLSX được openpyxl đọc đủ 67 dòng/16 cột, HTTP
headers/path checks qua. Chưa kiểm tra trực quan trình duyệt vì local browser bị
tắt trong Work settings; chưa chứng minh email inbox/App Check thật.

Admin chọn `luuxuantung285600@gmail.com`, đã kiểm tra chỉ đọc tồn tại/verified.
Thiếu web App Check site key, chưa grant role/deploy Rules/Hosting/bật flag mobile.
Backup Rules thật và gói review dưới build; giữ bản MVP production đang chạy.
Chi tiết và checklist còn thiếu: [admin-completion.md](admin-completion.md).
Tiếp theo đề xuất: cấu hình và nghiệm thu admin production; chưa tự thực hiện.

## 27/10/2026 — Giai đoạn 8 mở rộng: báo cáo năm và khoảng tùy chọn

Thêm chọn năm, từ ngày–đến ngày hoặc số ngày 1–366 trong Tiến độ; năm hiện tại
đến hôm nay, năm cũ đầy đủ; tổng hợp tháng và chi tiết ngày phân trang. CSV Android
hỗ trợ 366 ngày, prefill khoảng đang xem. Không tự xóa dữ liệu sau 7/30/90 ngày,
không đổi schema/Rules/backend hoặc mở rộng màn wellness riêng.
Files chính: ReportRange/range loader/providers, PeriodReportPanel, ProgressScreen,
ReportRangeDialog, CSV model/service/dialog và tests. Giữ thay đổi cá nhân hóa cũ.
Kết quả cuối kiểm thử/analyze/build và giới hạn: đầu test-report; tài liệu
[year-and-custom-reports.md](year-and-custom-reports.md).
Full cuối 639/639 (112 giây), analyze 0 issues (48,2 giây), format 15 file 0 thay
đổi, build debug qua (26,8 giây), diff check qua, source audit 449 tệp không khớp
mẫu secret. APK riêng `build/releases/healthmate-year-reports-debug.apk`, chưa cài.
Không commit/push/deploy/cài điện thoại. Tiếp theo đề xuất: nghiệm thu báo cáo/CSV
trên điện thoại khi kết nối; không tự triển khai giai đoạn khác.

## 26/10/2026 — Giai đoạn 7 bổ sung: cá nhân hóa mục tiêu dinh dưỡng

Theo yêu cầu mới, nối onboarding 5 bước với đề xuất kcal/macros, thêm lối hoàn
thiện kế hoạch cho tài khoản cũ ở Hôm nay/Thêm và bộ tính trong form mục tiêu.
Model Mifflin–St Jeor + hoạt động/nhịp/phân bổ có nguồn và giới hạn; phải xác nhận
trước lưu, không tự thay mục tiêu cũ/hồi tố lịch sử. Không thêm API/dependency/schema.

Files chính: `personal_nutrition_plan.dart`, `personal_nutrition_planner.dart`,
onboarding, target card/form, dashboard calorie card; test mới và fixture onboarding
trong core acceptance. Cập nhật database/README/handoff/test-report.
Full cuối 625/625 (92 giây), analyze cuối 0 issues (18,1 giây), format 10 file
0 thay đổi. Build debug Android thành công (72,5 giây); diff check qua và audit
445 tệp nguồn không phát hiện mẫu secret. Kết quả/log trong test-report.
Mô tả nguồn/cách dùng/giới hạn:
[personalized-nutrition.md](personalized-nutrition.md).
Không deploy/push hoặc cài máy thật; không tự chuyển sang thiết kế tab/bài tập.
Tiếp theo đề xuất: nghiệm thu kế hoạch dinh dưỡng trên điện thoại khi kết nối.

## 26/10/2026 — Xuất bản mã nguồn và đề xuất giao diện

Phạm vi theo yêu cầu mới: commit/push mã nguồn Flutter, Worker và admin thử nghiệm
đang có; không triển khai backend hoặc cài điện thoại. Bổ sung ignore dependency,
credential/artifact và mẫu kiểm tra debug token dạng đối số. Lưu bản chụp Rules MVP
đã đọc lại trước đó tại `deploy/`; không thay đổi Rules hay dữ liệu trên server.

Tạo [đề xuất giao diện](ui-navigation-proposal.md): hồ sơ góc trái trên và năm mục
Hôm nay/Dinh dưỡng/Tập luyện/Tiến độ/Trợ lý. Chưa sửa UI hoặc làm buổi tập có hướng dẫn.
Kiểm tra trước commit: audit 441 tệp văn bản không phát hiện mẫu secret; diff
whitespace qua; bản Rules đúng hash đã ghi trong `deploy/README.md`.
Không chạy lại bộ 608 test/analyze/build vì không thay đổi code Flutter/native.
Các kết quả kiểm thử bên dưới là của đợt triển khai tính năng trước.

## Mới nhất26/10/2026 — Mục2–3–4: bước/calo, tiến độ và giấc ngủ

User yêu cầu cả3 mục. Đã nối ước tính bước chân và điều chỉnh xác nhận theo ngày
với ngân sách ở Tổng quan/Nhật ký/chat; màn hình tiến độ cân nặng7/30/90ngày;
biểu đồ ngủ7/30ngày, trung bình/độ đều, mục tiêu và nhắc giờ ngủ local opt-in.
Mặc định không cộng bước, không quy đổi giờ ngủ thành calo. Giữ dữ liệu gốc.

Files chính: model/repository/provider/UI mới dưới `features/wellness`; tích hợp
budget ở dashboard/journal/nutrition_targets/chat, liên kết Progress, sửa vòng đời
provider latest weight/activity; native BedtimeReminders/WellnessBridge/bootstrap,
Manifest và account cleanup; Rules/tests/runner candidate. Không thêm dependency.
Full608/608, Rules73/73,SDK23/23,candidate64/64,native51giâyqua,build24giâyqua.
Analyze cuối0issues,49,2giây;format34file0thayđổi;diffcheckqua;sourceaudit438file0.
Rules mới đã deploy và đọc lại khớp6a1762dd…; chỉ thêm2collectionriêng, không admin.
Chi tiết, file/log/giới hạn: [wellness-insights.md](wellness-insights.md).

APK mới ởbuild/releases/healthmate-wellness-insights-debug.apk; chưa cài máy thật
theo lựa chọn kết nối sau của user. Chưa đo độ chính xác bước/calo hoặc kiểm OEM.
Không push/commit/resetdirty, không billing/model/admin. Tiếp theo chỉ nghiệm thu
điện thoại khi user kết nối; không lặp lại shutdown hoặc tự làm giai đoạn khác.

## 26/10/2026 — Mục1: rollout Firebase, chờ nghiệm thu điện thoại

User yêu cầu “làm mục1”, sau đó chọn “Tôi sẽ kết nối sau”. Đã kiểm baseline và
backup Rules production, chạy lại61/61 ca của candidate không admin, deploy chỉ
`firestore:rules` đúng project và đọc lại server khớp hash. Ruleset mới
`8add3549-ea41-4a5d-9f5c-22d1b62808cc`, lúc15:53:38 UTC+7. Không bật admin,
không đổi dữ liệu/billing/model/index, không commit/push. Không sửa Flutter/native,
không cần build/test lại artifact không đổi; hash/manifest APK kiểm tra lại đúng.

Files tài liệu cập nhật: `wellness-rollout.md`, `wellness-expansion.md`, database,
test-report, handoff, README. Log/backup/hash và checklist máy thật trong
[báo cáo rollout](wellness-rollout.md). Compiler qua, có1warning unused knownNumber.
Chưa có ADB device nên chưa cài/thử sensor hoặc lưu/đọc production từ điện thoại;
không tuyên bố hoàn tất toàn bộ mục1. Chờ user kết nối, không triển khai mục2.

## Lịch sử trước rollout26/10/2026 — Đợt mở rộng theo yêu cầu: 6 tính năng

Đã hoàn thiện source/UI cho nhắc bữa local, 162 món Việt/tham chiếu và khẩu phần,
8 dưỡng chất, thực đơn7 ngày, step counter Android opt-in và ngủ/dậy thủ công có
sửa/lịch sử. Đây là một đợt mở rộng được user yêu cầu trực tiếp; không tự chuyển
giai đoạn hoặc tiếp tục web admin. Giữ mọi thay đổi chưa commit, không push/deploy.

Files chính: `lib/features/wellness/`, native `Wellness*.kt`, `MealReminders.kt`,
`StepTrackingService.kt`, Manifest/MainActivity, asset/dữ liệu recipe, model/parser/
cache dinh dưỡng, model món riêng/công thức/mẫu bữa/bản nháp; auth cleanup, router,
Profile entry, `firestore.rules`, tests và runner Android. Không thêm package.

Kết quả cuối: analyze0; Flutter597/597; Rules70/70; SDK22/22; catalog10/10;
candidate không admin61/61; Android native toàn luồng exit0. Debug APK đã build,
lưu `build/releases/healthmate-wellness-debug.apk`. Quét424file source không có
khớp mẫu secret. Chi tiết/log/hash: [wellness-expansion.md](wellness-expansion.md).

**Chưa live:** Rules production chưa có collection/schema mới, cần duyệt candidate
MVP trước triển khai; không deploy toàn bộ Rules local có admin. Chưa cài APK lên
điện thoại; cần thử sensor/quyềnAndroid13+/pinOEM trên máy thật. AVD không có cảm
biến và app báo đúng. Kế hoạch gợi ý chưa cá nhân hóa; ngủ không đo chất lượng.
Giai đoạn kế tiếp đề xuất: duyệt Rules và nghiệm thu thiết bị, chưa thực hiện.
User yêu cầu tắt laptop sau hoàn tất; lưu báo cáo/APK trước khi gửi shutdown thường.

## 25–26/10/2026 — Giai đoạn 10: kiểm thử tích hợp và bảo mật

Người dùng yêu cầu Giai đoạn 10. Đã sửa USDA detail parser, validation dữ liệu
thiếu/zero, chặn món riêng trong cache danh mục và làm mới cache USDA cũ ở v2;
bỏ exception tìm kiếm thô khỏi log. Chỉ thay đổi cache công khai, không sửa hoặc
xóa dữ liệu Firestore thật. Admin tiếp tục tạm gác; email gate của role admin
chỉ được củng cố trong source và thử với Emulator.

Files chính: `usda_api_service.dart`, `food_local_database.dart`,
`unified_food_search_service.dart`, `nutrition_models.dart`, hai widget Dashboard
đổi API deprecated; regression test USDA, fixture xác minh email, bài thử
Android và hai runner native; `firestore.rules`/Rules tests; các script audit,
read-only config và prepare/test candidate trong `tool/`.

Analyze toàn dự án 0 issues; Flutter 584/584; Rules 52 MVP + 9 admin; SDK 19/19;
OOB email verify/reset 1/1; Worker 21/21/syntax/audit qua; Rules dependency audit0.
MVP candidate 52/52. APK debug build15,1s,236.547.388byte, URL chat thật, chưa
cài điện thoại theo lựa chọn của người dùng. Android core qua10checkpoint và
cache SQLite (4phút13giây); H7 hai pha qua17giây/44giây: force-stop/recovery,
encrypted draft, offline/retry, CSV/readback, UID isolation và deletion. Các runner
đều exit0. [Báo cáo](stage10-security-review.md) ghi cả các lượt lỗi trước đó.

Đã đọc cấu hình production, không deploy: Rules thật còn thiếu verified email
gate và snapshot dinh dưỡng mới; AI App Check ENFORCED, Firestore chưa xác nhận
enforcement. Candidate riêng loại admin, giữ chat50; hash/baseline/rollback và
giới hạn release/điện thoại ở báo cáo. Cần duyệt trước khi chặn truy cập tài
khoản chưa xác minh; không deploy cả file Rules local. Chưa commit/push, bảo toàn
dirty tree. Giai đoạn11 chỉ đề xuất sau nghiệm thu/rollout MVP, chưa thực hiện.

## 25/10/2026 — Giai đoạn 9: 50 lượt/cuộc và tiếp tục hội thoại khi chuyển tab

Hoàn thành code và APK theo yêu cầu: 50 lượt (100 messages), tự mở cuộc đã chọn
hoặc cuộc mới nhất khi vào chat, giữ lựa chọn “Cuộc trò chuyện mới”, reset theo
UID và chặn lựa chọn cũ từ save hoàn tất muộn. Tra cứu nhanh dùng repository,
không gọi AI; loại bảng tham chiếu lặp khỏi history gửi AI. Không tăng rate,
đổi model/provider, bật billing hoặc thêm database. Người dùng sẽ cài/thử sau.

Files chính: chat_resume_provider.dart, chat_providers.dart, chat_models.dart,
firebase_chat_repository.dart, chat_screen.dart, assistant_request.dart;
chatbot_resume_test.dart/chatbot_api_test.dart/chatbot_test.dart;
firestore.rules, rules-tests/firestore.rules.test.cjs; hai script prepare/test
candidate Rules trong tool/. Bảo toàn toàn bộ thay đổi chưa commit từ trước.

Kiểm tra: format qua; focused chat 62/62; full Flutter 578/578 (67s);
analyze cuối 18info có sẵn/0warning/error; Rules local 52/52 và candidate chat
4/4; APK debug build42,2s,236.539.039bytes; diff-check/syntax qua. Lượt Rules
đầu có một assertion onboarding thất bại, chạy riêng baseline và full lại qua;
ghi nhận dấu hiệu phụ thuộc thời điểm, không sửa test che lỗi.

Đã deploy Rules production chỉ đổi trần chat40→100 trên snapshot production,
không deploy các thay đổi Rules khác đang chờ. Đọc lại source sau deploy khớp
hash candidate; không migrate/xóa lịch sử. APK build/releases/healthmate-chat-50-debug.apk.
Chưa cài/nghiệm thu APK mới trên điện thoại vì người dùng chọn thử sau.
Chi tiết và rollback backup: [báo cáo](chatbot-capacity-update.md).
Giai đoạn kế tiếp đề xuất:10 — security và kiểm thử tích hợp, chưa thực hiện.

## 25/10/2026 — Giai đoạn9, API Cloudflare thật và APK kết nối

Đã OAuth Wrangler, triển khai Worker tại URL trong config/chat-api.json; chọn
Qwen planner + Llama3.3 70B answer sau benchmark model thật. Không thêm database,
billing, scanner hoặc admin. Đã kiểm tra 21Worker tests, syntax, auditproduction0,
request thật thiếu/saiJWT401, build APK debug45,9s. Benchmark20fixture cuối đều
hoàn tất và đúng nguồn/khoảng ngày, median1,892s qua REST; không phải native E2E.
Files chính: chat-api/src/protocol.mjs,index.mjs,test/api.test.mjs,wrangler.jsonc,
tool/*.mjs; config/chat-api.json; tool/run_android.ps1 và tài liệu liên quan.
Người dùng đã nối USB, cài đè APK giữ dữ liệu thành công và app đã mở. Đã yêu cầu
thử câu hỏi đầu tiên: app báo "Phản hồi AI vượt giới hạn". Đã sửa SSE wire budget
32KB bị cộng envelope; capture45.817byte chỉ844chữ được Dart replay qua. Giữ
text3.800, wire2MiB/event16k.55focusedtests qua,APK sửa17,1s qua,analyze3file sạch.
Cài đè lần hai Success,lastUpdateTime25/10/2026 02:59:04; người dùng xác nhận câu
kiến thức chung trả lời đầy đủ; mục tiêu kcal và follow-up đạm khớp số liệu hoặc
báo thiếu dữ liệu đúng. Kết nối/luồng cốt lõi stage9 hiện tại hoàn tất trên máy.
Full analyze cuối8,9s:18info có sẵn,0warning/error; không còn lint mới.
Native mất mạng/quota/đổi UID/lịch sử mở lại chưa thử thủ công.
Chi tiết, lỗi model quan sát được và rủi ro: [báo cáo live](chatbot-live-qa.md).
Giai đoạn kế tiếp đề xuất:10 — security và kiểm thử tích hợp; không tự thực hiện.

## 2026-10-13 — Giai đoạn 1: Nền tảng Flutter và UI system

Trạng thái: **hoàn thành Giai đoạn 1**. Source, analyze, widget tests, build web,
APK debug và khởi chạy trên Android emulator đã được kiểm chứng.

### Hiện trạng đầu vào

Repository chỉ có `.git`, nhánh `main` chưa có commit hoặc remote.
Không có ứng dụng cũ để bảo tồn. Flutter SDK được tìm thấy tại
`D:\Flutter\flutter`: Flutter 3.44.1, Dart 3.12.1; chưa có trên PATH.

### Đã thực hiện

- Khởi tạo Flutter cho Android và web (web phục vụ kiểm tra UI).
- Theme Material 3 sáng/tối, typography, spacing, SafeArea và nội dung cuộn.
- 5 tab và trang Auth; navigation bar/rail theo chiều rộng, route lỗi có đường lui.
- Riverpod cho router và lựa chọn theme trong phiên; dispose router theo vòng đời.
- Trang khung ghi rõ đang chờ triển khai; không có dữ liệu sức khỏe giả,
  form đăng nhập giả, truy vấn Firestore hoặc lời gọi AI.
- Việt hóa Material localizations, tiêu đề app Android/web.
- Đặt bản nguyên văn AGENTS.md người dùng cung cấp tại gốc repository.
- README hướng dẫn môi trường, chạy Android/web, kiểm tra và giới hạn hiện tại.

### File chính

`AGENTS.md`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`,
`lib/main.dart`, `lib/app.dart`, `lib/core/router/*`, `lib/core/theme/*`,
`lib/core/widgets/*`, `lib/features/*/presentation/*`,
`lib/shared/providers/theme_mode_provider.dart`, `test/widget_test.dart`,
`android/*`, `web/*`, `README.md`, tài liệu này,
`docs/screenshots/dashboard-android.png` (ảnh chụp runtime thực tế).

### Dependencies

Thêm `flutter_riverpod` 3.4.3 (state/DI), `go_router` 18.0.2 (routing),
`flutter_localizations` từ SDK (tiếng Việt) và `cupertino_icons` 2.0.0 (font icon
được thư viện UI mà router tham chiếu sử dụng). Ban đầu bỏ icon package của
template vì màn hình chỉ dùng Material; build web phát hiện thiếu font
CupertinoIcons trong thư viện tham chiếu, nên đã thêm lại phiên bản do tooling
resolve tương thích để xử lý cảnh báo. Pub solver resolve thành công với SDK
hiện có; lockfile giữ phiên bản thực tế. Không thêm Firebase, AI, biểu đồ hoặc
image picker.

### Kiểm tra thực tế

- `flutter --version`: Flutter 3.44.1, Dart 3.12.1.
- `flutter doctor -v`: Android SDK 36.1.0 có sẵn; cảnh báo PATH, một số Android
  licenses chưa chấp nhận; Windows C++ toolchain thiếu (không là target giai đoạn này).
- `flutter create --project-name healthmate --platforms android,web --org com.example ... .`:
  thành công; resolve dependencies thành công.
- `flutter pub remove cupertino_icons` và `flutter pub add flutter_riverpod go_router
  "flutter_localizations:{sdk: flutter}"`: thành công.
- `dart format .`: đã định dạng 18 file Dart.
- `flutter analyze` và lần cuối `flutter analyze --no-pub`: không có vấn đề.
- `flutter test`: lần đầu 6/8 pass; phát hiện brand row tràn ngang khi chữ 200%
  và test theme bấm trước khi layout sau cuộn được cập nhật. Đã sửa UI bằng
  `Flexible` và test chờ frame sau cuộn. Chạy lại: **8/8 pass**.
- `dart format --output=none --set-exit-if-changed .` chạy trong lúc Gradle
  đang build gặp `PathNotFoundException` khi đọc thư mục build tạm. Đã đổi sang
  kiểm tra đúng source: `dart format --output=none --set-exit-if-changed lib test`:
  thành công, 18 file, 0 thay đổi. README dùng lệnh này để tránh quét build artifacts.
- `flutter build web`: thành công lần đầu (40.4s); sau khi thêm font dependency,
  build lại thành công (59.3s), không còn cảnh báo thiếu font.
- `flutter build apk --debug`: thành công lần đầu (128.9s), tạo
  `build/app/outputs/flutter-apk/app-debug.apk`; build lại với font dependency:
  thành công (9.1s).
- Kiểm tra cuối sau thay đổi dependencies: `flutter analyze --no-pub` không có
  vấn đề; `flutter test --no-pub` **8/8 pass**; format source 18 file, 0 thay đổi.
- Cài APK vào Pixel_4 read-only thất bại với `INSTALL_FAILED_INSUFFICIENT_STORAGE`.
  Không xóa ứng dụng/dữ liệu máy ảo người dùng. Đã dừng phiên read-only và tạo
  AVD tạm riêng trên D: để tiếp tục kiểm chứng chạy ứng dụng.
- Chạy thực tế trên AVD tạm Android 16 (API 36.1), port 5582:
  sau khi hệ điều hành boot xong, `adb install -r` trả `Success`;
  `adb shell am start -W -n com.example.healthmate/.MainActivity` trả
  `Status: ok`, `LaunchState: COLD`, `Complete`. Tiến trình ứng dụng có PID,
  ảnh chụp màn hình hiển thị UI HealthMate đúng; đã xem ảnh để kiểm tra trực quan.
  Bộ lọc log `flutter:E AndroidRuntime:E` không có lỗi tại thời điểm kiểm tra.
- Trong quá trình boot AVD mới, lần cài thử sớm báo chưa có package service;
  script chờ boot có một lần đọc property null. Sau khi boot hoàn tất,
  cài đặt/khởi chạy đã thành công; không sửa source để che lỗi môi trường.
- Ảnh runtime: [`screenshots/dashboard-android.png`](screenshots/dashboard-android.png).
  Máy ảo đã dừng; `avdmanager delete avd -n healthmate_stage1_check` trả
  `AVD 'healthmate_stage1_check' deleted.` và danh sách ADB không còn thiết bị.
  Dữ liệu AVD tạm đã xóa; chỉ còn log emulator (~9 KB) tại
  `D:\CodexTemp\healthmate-stage1-20261013-a54e1`, ngoài repository.

### Việc người dùng cần làm và giới hạn

- Thêm `D:\Flutter\flutter\bin` vào PATH hoặc dùng đường dẫn đầy đủ.
- Tự đọc/chấp nhận Android licenses còn thiếu khi cần, không tự chấp nhận thay người dùng.
- Mở emulator hoặc kết nối thiết bị Android khi chạy trên Android.
- Chốt application ID trước Giai đoạn 2; hiện `com.example.healthmate`.
- Theme preference chỉ trong bộ nhớ; restart về chế độ theo thiết bị.
- Icon còn là template; chưa có release signing. Các nghiệp vụ vẫn chờ triển khai.
- Chưa kiểm tra Firestore rules, Auth hoặc AI vì chưa triển khai các giai đoạn đó.

### Đề xuất sau khi kết thúc Giai đoạn 1

Giai đoạn 2 — Firebase setup và Authentication. Chưa thực hiện tại thời điểm
kết thúc Giai đoạn 1; kết quả triển khai được ghi ở mục tiếp theo.

## 2026-10-13 — Giai đoạn 2: Firebase setup và Authentication

Trạng thái: **hoàn thành Giai đoạn 2**. Ứng dụng đã kết nối Firebase thật cho
Android/web; Email/Password Auth đã được kiểm chứng ở backend thật, trong test UI
và qua hai bản build. Không thêm nghiệp vụ sức khỏe hoặc Firestore.

### Hiện trạng đầu vào

Repository chưa có Firebase project, `firebase_options.dart` hoặc dependency
Firebase. Firebase CLI và FlutterFire CLI có sẵn; Firebase CLI đã đăng nhập.
Sau khi kiểm tra danh sách project hiện có và tránh nối nhầm dữ liệu, người dùng
chọn tạo project mới tên HealthMate.

### Firebase thực tế

- Tạo Firebase project `healthmate-app-20261013`, project number
  `471712188542`, display name `HealthMate`.
- Chạy FlutterFire CLI cho Android và web; đăng ký Android app
  `com.example.healthmate` và web app, sinh `lib/firebase_options.dart`,
  `android/app/google-services.json` và `firebase.json`.
- Thêm `.firebaserc` với project mặc định `healthmate-app-20261013`.
- Người dùng đăng nhập Firebase Console và bật provider Email/Password.
- Kiểm tra lại bằng Firebase API: Email provider `enabled: true`, password bắt
  buộc, các authorized domain gồm `localhost`, domain Firebase Hosting và
  `firebaseapp.com` của project.
- Client configuration do FlutterFire sinh được giữ trong source theo cơ chế
  Firebase client SDK. Không thêm service account, Admin credential, private key
  hoặc secret server.

### Đã thực hiện

- Thêm `firebase_core` 4.15.0 và `firebase_auth` 6.7.0 bằng Flutter tooling;
  phiên bản thực tế được khóa trong `pubspec.lock`.
- Khởi tạo Firebase bất đồng bộ trước `runApp`; nếu khởi tạo thất bại, hiển thị
  màn hình lỗi thân thiện có nút thử lại thay vì vào app ở trạng thái giả.
- Tách `AuthRepository` khỏi Firebase SDK, ánh xạ Firebase user sang model nội bộ
  tối thiểu và ánh xạ mã lỗi sang thông báo tiếng Việt không lộ chi tiết SDK.
- Thêm đăng ký, đăng nhập, đăng xuất và theo dõi `authStateChanges`; form trim
  email nhưng không biến đổi mật khẩu.
- Validation email, mật khẩu đăng ký tối thiểu 6 ký tự và xác nhận mật khẩu;
  loading vô hiệu hóa thao tác lặp, hỗ trợ Autofill và ẩn/hiện mật khẩu.
- Route riêng tư đi qua màn hình chờ session. Người dùng chưa đăng nhập được đưa
  tới Auth; sau thành công quay lại đúng route nội bộ đã yêu cầu. Destination từ
  query được giới hạn vào các route nội bộ hợp lệ.
- Trang Tài khoản hiển thị email của session hiện tại và đăng xuất thật; lỗi đăng
  xuất giữ nguyên phiên để người dùng có thể thử lại.
- Thêm quyền Internet cho Android và input theme dùng chung. Không thêm profile,
  body metrics, nhật ký, Firestore, AI hoặc dữ liệu sức khỏe mẫu.

### File chính

`lib/main.dart`, `lib/firebase_options.dart`,
`lib/core/config/firebase_bootstrap.dart`, `lib/core/router/auth_redirect.dart`,
`lib/core/router/app_router.dart`, `lib/core/router/app_routes.dart`,
`lib/core/widgets/startup_error_app.dart`, `lib/features/auth/models/*`,
`lib/features/auth/data/*`, `lib/features/auth/providers/*`,
`lib/features/auth/presentation/*`,
`lib/features/profile/presentation/profile_screen.dart`,
`android/app/google-services.json`, Android Gradle config,
`android/app/src/main/AndroidManifest.xml`, `.firebaserc`, `firebase.json`,
`test/auth_test.dart`, `test/support/*`, `test/widget_test.dart`, `README.md` và
tài liệu này.

### Kiểm tra thực tế

- `flutterfire configure --project=healthmate-app-20261013
  --platforms=android,web --android-package-name=com.example.healthmate --yes`:
  thành công; hai Firebase app ở trạng thái ACTIVE.
- Kiểm thử trực tiếp Firebase Identity Toolkit bằng tài khoản ngẫu nhiên tạm:
  đăng ký thành công, mật khẩu sai bị từ chối, đăng nhập đúng thành công và tài
  khoản kiểm thử được xóa thành công ngay sau đó. Script tạm đã xóa khỏi workspace.
- `dart format --output=none --set-exit-if-changed lib test`: 32 file, 0 thay đổi.
- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test --no-pub`: **22/22 pass**. Test bao phủ validation và thông báo
  an toàn, route guard, session loading/error, login/register/logout, retry lỗi
  mạng/đăng xuất, chống gửi lặp, external sign-out, startup failure, màn hình nhỏ
  với text scale lớn/keyboard inset, cùng toàn bộ test điều hướng Giai đoạn 1.
- `flutter build web --no-pub`: thành công; Wasm dry run thành công.
- `flutter build apk --debug --no-pub`: thành công, tạo
  `build/app/outputs/flutter-apk/app-debug.apk`.
- Gradle phát cảnh báo các plugin Firebase hiện còn áp dụng Kotlin Gradle Plugin
  và một bản Flutter tương lai sẽ yêu cầu plugin hỗ trợ Built-in Kotlin. Đây là
  cảnh báo upstream; build hiện tại vẫn thành công và không cần ghim package cũ.

### Giới hạn và việc người dùng cần biết

- Cần giữ quyền truy cập Firebase project `healthmate-app-20261013` và kết nối
  mạng để Auth thật hoạt động.
- Android application ID vẫn là `com.example.healthmate`; nên đổi sang namespace
  thương hiệu trước khi phát hành, khi đó phải đăng ký lại Android app Firebase.
- Chưa có email verification, khôi phục mật khẩu, MFA hoặc xóa tài khoản vì nằm
  ngoài phạm vi Auth tối thiểu của Giai đoạn 2.
- Chưa có Firestore hoặc Security Rules; app hiện chỉ lưu trạng thái session theo
  cơ chế của Firebase Auth. Các trang sức khỏe vẫn là placeholder trung thực.

### Giai đoạn kế tiếp đề xuất

Giai đoạn 3 — Hồ sơ và Body Metrics: profile theo UID, lịch sử thể trạng,
Firestore Security Rules và CRUD thật. Chưa triển khai trong lượt này.

## 2026-10-13 — Giai đoạn 3: Hồ sơ và Body Metrics

Trạng thái: **hoàn thành Giai đoạn 3**. Profile và lịch sử cân nặng đã CRUD trên
Cloud Firestore thật; dữ liệu được tách theo UID, Security Rules đã qua test chéo
UID trên emulator và đã deploy lên project production. Không triển khai dinh
dưỡng, nước, hoạt động, AI hoặc phạm vi Giai đoạn 4.

### Firestore thực tế

- Bật Cloud Firestore API và tạo database `(default)` Native mode, Standard
  edition tại `asia-southeast1` (Singapore) cho `healthmate-app-20261013`.
- Database đang dùng free tier, realtime updates bật, PITR và delete protection
  chưa bật.
- Thêm `cloud_firestore` 6.10.0 bằng Flutter tooling; lockfile giữ dependency
  thực tế tương thích với Flutter 3.44.1/Dart 3.12.1.
- Thêm `firestore.rules`, `firestore.indexes.json` và cấu hình emulator trong
  `firebase.json`; rules/indexes đã deploy thành công vào database mặc định.
- Không thêm service account, Admin credential hoặc secret vào repository.

### Mô hình dữ liệu và nghiệp vụ

- `users/{uid}` lưu `displayName`, email khớp Auth token, `heightCm`, server
  timestamps và `schemaVersion: 1`.
- Hồ sơ được bootstrap theo session ngay sau khi đăng nhập, không phụ thuộc người
  dùng có mở tab Cá nhân hay không. Quy trình chạy lại an toàn: chỉ tạo khi chưa
  tồn tại và chỉ đồng bộ email/schema khi cần.
- `users/{uid}/body_metrics/{metricId}` lưu cân nặng, ngày đo, ghi chú và server
  timestamps. Firestore tự sinh ID cho mỗi lần đo nên lịch sử không bị ghi đè.
- UI cho phép sửa hồ sơ, thêm/sửa/xóa lần đo, hiển thị loading/error/retry và
  trạng thái không dữ liệu. Ngày đo không cho chọn tương lai.
- Validation Flutter: tên 2–50 ký tự; chiều cao tùy chọn 80–250 cm; cân nặng
  20–500 kg; ghi chú tối đa 200 ký tự; hỗ trợ dấu phẩy thập phân.
- BMI chỉ tính khi chiều cao/cân nặng hợp lệ và luôn ghi nhãn “BMI tham khảo”,
  kèm thông báo không phải chẩn đoán y khoa.
- Chi tiết schema và quyền truy cập ghi tại `docs/database-design.md`.

### Security Rules

- Chỉ `request.auth.uid == uid` được đọc hoặc ghi profile/body metrics tương ứng.
- Email profile phải khớp email claim trong token; field ngoài schema bị từ chối.
- Rules kiểm tra kiểu dữ liệu, khoảng chiều cao/cân nặng, độ dài chuỗi, timestamp
  phía server và giữ `createdAt` bất biến.
- Client không được xóa profile; body metric chỉ chủ sở hữu mới được xóa.
- Mọi collection/path chưa khai báo bị từ chối mặc định.

### File chính

`pubspec.yaml`, `pubspec.lock`, `firebase.json`, `firestore.rules`,
`firestore.indexes.json`, `docs/database-design.md`, `lib/app.dart`,
`lib/features/profile/models/*`, `lib/features/profile/data/*`,
`lib/features/profile/providers/profile_providers.dart`,
`lib/features/profile/presentation/*`, `test/profile_test.dart`,
`test/support/fake_health_profile_repository.dart`, `test/support/test_app.dart`,
`rules-tests/package.json`, `rules-tests/package-lock.json`,
`rules-tests/firestore.rules.test.cjs`, `.gitignore`, `README.md` và tài liệu này.

### Kiểm tra thực tế

- `dart format --output=none --set-exit-if-changed lib test`: 43 file,
  0 thay đổi ở lần kiểm tra cuối.
- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test --no-pub`: **27/27 pass**. Ngoài regression Auth/navigation,
  test mới kiểm tra validation/BMI, profile bootstrap ngay sau chuyển trạng thái
  đăng nhập và toàn bộ thêm/sửa/xóa body metric qua repository giả.
- Firestore Emulator 1.21.0 chạy với Java 21 từ Android Studio và demo project
  `demo-healthmate-rules`: **5/5 rules tests pass**. Đã kiểm tra owner CRUD, client
  ẩn danh, đọc/ghi chéo hai UID, field ngoài schema, email/chiều cao/cân nặng sai,
  sửa `createdAt` và xóa profile trái phép.
- `firebase deploy --only firestore:rules,firestore:indexes`: rules compile và
  release thành công; indexes deploy thành công cho `(default)`.
- Kiểm thử production bằng Firebase web client SDK và tài khoản ngẫu nhiên tạm:
  tạo/cập nhật profile thành công; thêm, query có sắp xếp, sửa và xóa body metric
  thành công. Dữ liệu profile và tài khoản thử đã được xóa khỏi production ngay
  sau kiểm tra; script tạm đã xóa khỏi workspace.
- `npm audit --prefix rules-tests`: ban đầu phát hiện advisory của
  `@grpc/grpc-js` 1.13.5 trong test-only dependency. Thêm override lên 1.13.6,
  cài lại và kiểm tra cuối: **0 vulnerabilities**; 5/5 rules tests vẫn pass.
- `flutter build web --no-pub`: thành công; Wasm dry run thành công.
- `flutter build apk --debug --no-pub`: thành công, tạo
  `build/app/outputs/flutter-apk/app-debug.apk`.

### Việc người dùng cần làm và giới hạn

- Không còn bước Firebase Console bắt buộc cho Giai đoạn 3. Khi đổi project hoặc
  môi trường, phải deploy lại `firestore.rules` và `firestore.indexes.json`.
- Java mặc định trên máy là Java 8, không chạy được Firestore Emulator hiện hành;
  README hướng dẫn đặt `JAVA_HOME` tạm sang JBR Java 21 của Android Studio.
- Gradle vẫn phát cảnh báo upstream về Firebase plugin áp dụng Kotlin Gradle
  Plugin và một bản Flutter tương lai sẽ yêu cầu Built-in Kotlin; build hiện tại
  thành công. `cloud_firestore` cũng phát một note Java unchecked ở code plugin.
- Android application ID vẫn là `com.example.healthmate`; cần đổi trước phát hành.
- Firestore PITR và database delete protection chưa bật. Chưa có UI xóa toàn bộ
  tài khoản/profile; profile delete từ client đang bị Security Rules chặn.
- Repository vẫn chưa có commit gốc nên toàn bộ source đang ở trạng thái untracked.

### Giai đoạn kế tiếp đề xuất

Giai đoạn 4 — Food Catalog và nhật ký dinh dưỡng thủ công. Chưa triển khai trong
lượt này.

## 2026-10-13 — Giai đoạn 4 và 5: Nutrition + AI Food Scanner

Trạng thái: **hoàn thành Giai đoạn 4 và 5 theo yêu cầu gộp của người dùng**.

### Hành vi đã hoàn thành

- Seed 10 món tham khảo theo cơ sở 100 g, đơn vị gram, macro, nguồn USDA FoodData
  Central và `isEstimated: true`; catalog chỉ đọc với người dùng đã đăng nhập.
- Tìm/chọn món, nhập/sửa gram, loại bữa và ngày/giờ; tổng kcal/protein/carb/fat
  được tính từ catalog. Meal log lưu snapshot, nguồn manual/AI-assisted và hỗ trợ
  xem/sửa/xóa thật dưới `users/{uid}/meal_logs`.
- Chụp/chọn ảnh bằng `image_picker`; kiểm tra định dạng/kích thước tối đa 8 MB.
  Firebase AI Logic dùng Gemini Developer API free tier và model hiện hành
  `gemini-3.8-flash` (có thể override bằng `HEALTHMATE_AI_MODEL`).
- Gemini chỉ trả tên, mô tả, nguyên liệu và từ khóa đối chiếu. Người dùng có thể
  sửa tên, chọn món catalog và nhập khẩu phần; không tự lưu và không dùng AI để
  tạo số dinh dưỡng. Lỗi mạng/quota/JSON có thông báo và đường lui nhập thủ công.
- Ảnh chỉ giữ trong bộ nhớ của dialog, không có Cloud Storage và không lưu đường
  dẫn ảnh vào Firestore.

### Firebase thật

- Đã bật `firebasevertexai.googleapis.com`, `generativelanguage.googleapis.com`
  và `firebaseappcheck.googleapis.com`; Firebase AI Logic cấu hình Gemini
  Developer API.
- App Check Android: debug provider có token đăng ký riêng trên máy phát triển;
  release dùng Play Integrity. Đã đăng ký SHA-256 debug, cấu hình Play Integrity
  TTL 1 giờ và bật `ENFORCED` cho `firebaseml.googleapis.com`.
- Debug token được lưu ngoài repository tại Local AppData; `tool/run_android.ps1`
  nạp token qua `--dart-define`. Không có API key hoặc token trong source.
- Firestore Rules/indexes đã deploy lại. Rules bảo vệ catalog và meal logs theo
  Auth UID, schema/range/timestamp; giới hạn tối đa 5 item mỗi bữa.

### File chính

- `lib/features/nutrition/**`, `lib/features/food_scanner/**`,
  `lib/features/journal/presentation/journal_screen.dart`
- `lib/core/config/firebase_bootstrap.dart`, `pubspec.yaml`, `pubspec.lock`
- `firestore.rules`, `docs/database-design.md`, `README.md`
- `test/nutrition_test.dart`, `test/support/fake_nutrition_repository.dart`,
  `integration_test/firebase_ai_smoke_test.dart`, `tool/run_android.ps1`

### Kiểm tra thực tế trong quá trình triển khai

- `flutter analyze`: không có issue sau khi thêm feature.
- `flutter test --exclude-tags=integration`: **30/30 pass**, gồm toàn bộ regression
  Auth/Profile/navigation và test mới cho công thức, parser, layout và thêm bữa.
- Firestore Emulator với Java 21: 8/8 rules tests pass; rules/indexes deploy thật
  thành công vào `healthmate-app-20261013`.
- Android integration test đã build/cài APK trên API 36, gọi Gemini thật qua App
  Check enforcement và nhận structured JSON hợp lệ: 1/1 pass.
- Production smoke test tạo tài khoản tạm, đọc đủ 10 catalog item và thêm/sửa/xóa
  meal log qua rules thật: pass; tài khoản/dữ liệu thử được xóa sau kiểm tra.
- `flutter build web --no-pub` và `flutter build apk --debug --no-pub`: thành công.
  `npm audit --prefix rules-tests`: 0 vulnerabilities.
- Lượt emulator đầu tiên không cài được APK vì máy ảo hết dung lượng; chuyển sang
  emulator `Pixel_4` sạch và kiểm thử AI thành công. Đây không phải lỗi app.

### Giới hạn và việc phát hành

- Web chỉ là UI preview; scanner chủ động hướng dẫn nhập thủ công vì chưa có
  reCAPTCHA Enterprise site key/domain production. Android là nền tảng chính.
- Android application ID còn là `com.example.healthmate`. Trước phát hành cần đổi
  namespace, đăng ký lại app Firebase và SHA-256 release/Play App Signing.
- Gemini Developer API có free tier nhưng vẫn có quota; UI đã xử lý trường hợp
  chạm quota và không cam kết miễn phí vô hạn.
- Repository chưa có commit gốc nên toàn bộ source vẫn ở trạng thái untracked.

### Giai đoạn kế tiếp đề xuất

Giai đoạn 6 — nhật ký nước uống và hoạt động. Chưa triển khai trong lượt này.

## 2026-10-13 — Giai đoạn 6: Nước uống và hoạt động

Trạng thái: **hoàn thành Giai đoạn 6**. Người dùng có thể chọn ngày và CRUD dữ
liệu thật cho nước uống/vận động; tổng trong ngày cập nhật theo dữ liệu hiện tại.

### Đã thực hiện

- Tách model, Firebase repository và Riverpod controller cho `water` và
  `activity`; mọi đường dẫn dữ liệu nằm dưới `users/{uid}`.
- Nhật ký nước lưu ml và thời điểm; nhật ký vận động lưu loại, phút, thời điểm và
  ghi chú tùy chọn. Form kiểm tra giới hạn trước khi ghi.
- Thêm bộ chọn ngày, loading/empty/error/success states, thêm/sửa/xóa và tổng ml,
  lít/phút theo ngày đã chọn.
- Chuẩn hóa `dateKey` theo ngày địa phương, lưu `timezoneOffsetMinutes`, tính lại
  khi sửa thời điểm. UI nói rõ dữ liệu do người dùng nhập, không tự đo bước chân
  hoặc khẳng định calories tiêu hao.
- Mở rộng Security Rules và composite indexes cho hai collection; rules/indexes
  đã deploy vào `healthmate-app-20261013`.

### File chính

`lib/core/utils/local_date_key.dart`, `lib/features/journal/**`,
`lib/features/water/**`, `lib/features/activity/**`, `firestore.rules`,
`firestore.indexes.json`, `rules-tests/firestore.rules.test.cjs`,
`test/daily_logs_test.dart`, `test/support/fake_water_repository.dart`,
`test/support/fake_activity_repository.dart`, `README.md`,
`docs/database-design.md` và tài liệu này.

### Kiểm tra thực tế

- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  74 file, 0 thay đổi ở lần kiểm tra cuối.
- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test test/daily_logs_test.dart`: **4/4 pass**; kiểm tra date key,
  validation, tổng và luồng thêm/sửa/xóa nước cùng thêm hoạt động trên UI.
- Firestore Emulator với Java 21: **10/10 rules tests pass**, gồm CRUD chủ sở hữu,
  chặn UID khác, giá trị sai và thay đổi `createdAt` cho water/activity.
- `firebase deploy --only firestore:rules,firestore:indexes`: rules compile,
  indexes deploy và rules release thành công vào database `(default)`.
- `flutter test --no-pub --exclude-tags=integration`: **34/34 pass**, gồm toàn bộ
  regression Auth/Profile/Nutrition/navigation và test Giai đoạn 6.
- Production smoke test bằng tài khoản tạm: thêm, query theo `dateKey` có sắp xếp,
  sửa và xóa cả water/activity log qua rules thật thành công. Dữ liệu và tài
  khoản tạm đã xóa; script tạm không còn trong workspace.
- `flutter build web --no-pub`: thành công; Wasm dry run thành công.
- `flutter build apk --debug --no-pub`: thành công, tạo
  `build/app/outputs/flutter-apk/app-debug.apk`.
- `npm audit --prefix rules-tests`: **0 vulnerabilities**.

### Việc người dùng cần làm và giới hạn

- Không có bước Firebase Console bắt buộc cho Giai đoạn 6; cần kết nối mạng để
  đồng bộ Firestore. Index mới có thể cần ít phút để hoàn tất xây dựng.
- Nhật ký vận động chỉ dùng dữ liệu người dùng nhập; chưa tích hợp cảm biến,
  Health Connect, đo bước chân hoặc ước tính calories.
- Repository chưa có commit gốc nên toàn bộ source vẫn ở trạng thái untracked.

### Giai đoạn kế tiếp đề xuất

Giai đoạn 7 — Goals và Daily Health Quest. Chưa triển khai trong lượt này.

## 2026-10-13 — Đợt 6.1: Củng cố tính toàn vẹn dữ liệu

Trạng thái: **hoàn thành Đợt 6.1**. Chỉ củng cố các chức năng của Giai đoạn 1–6;
không triển khai Đợt 6.2, Goals, Daily Health Quest, Dashboard nâng cao hoặc
Chatbot. Không deploy Rules/indexes, không dùng dữ liệu production và không
commit/push trong đợt này.

### Hiện trạng Git trước khi sửa

- Working tree sạch, nhánh `main`, remote `origin` trỏ tới
  `https://github.com/galaxy197/HealthMate.git`.
- Sau `git fetch origin`, local `HEAD` và `origin/main` cùng commit
  `900bee809d4dd508e5239d4ba6c1a8aee7bcf0e2`; ahead/behind là `0/0`.
- Không có thay đổi cục bộ hoặc file untracked cần bảo toàn. Các ghi chú cũ ở
  phần Giai đoạn 3–6 rằng repository chưa có commit chỉ là lịch sử tại thời điểm
  viết và không còn phản ánh hiện trạng Git.

### Đã thực hiện

- `validMealItems` kiểm tra có điều kiện mọi item đang tồn tại ở vị trí 0–4,
  giữ giới hạn 1–5 món, whitelist field và toàn bộ giới hạn giá trị hiện có.
- Rút gọn các phép kiểm tra kiểu số dư thừa: phép so sánh range trong Rules tự
  từ chối kiểu không tương thích và đã có test riêng cho kiểu chuỗi. Việc này giữ
  bảo vệ schema nhưng giúp bữa 5 món nằm dưới giới hạn 1.000 biểu thức Rules.
- Thêm test bữa 1/5 món hợp lệ; list rỗng/quá 5; sai item riêng ở từng vị trí;
  sai kiểu/field thừa; CRUD, chéo UID và `createdAt` bất biến.
- Rules của `dateKey` nay loại tháng ngoài 01–12 và ngày ngoài 01–31. Client có
  kiểm tra ngày lịch thực sự tồn tại, hàm suy ra ngày bằng timestamp + offset,
  kiểm tra quan hệ ba field và test ranh giới nửa đêm.
- `WaterLogDraft` và `ActivityLogDraft` suy ra `dateKey` bằng chính timestamp và
  offset sẽ ghi; repository tiếp tục tính lại các field này khi thêm/sửa.
- Cập nhật `docs/database-design.md` để tách rõ bảo đảm ở client và Rules, cùng
  các giới hạn còn lại.

### File chính đã sửa

`firestore.rules`, `rules-tests/firestore.rules.test.cjs`,
`lib/core/utils/local_date_key.dart`,
`lib/features/water/models/water_log.dart`,
`lib/features/activity/models/activity_log.dart`, `test/daily_logs_test.dart`,
`docs/database-design.md` và tài liệu này.

### Kiểm tra thực tế

- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  74 file, 0 thay đổi ở lần kiểm tra cuối.
- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test --no-pub --exclude-tags=integration`: **38/38 pass**.
- Firestore Emulator với Java 21 và demo project `demo-healthmate-rules`:
  **18/18 rules tests pass**. Có test riêng cho từng vị trí item 0–4 và toàn bộ
  regression profile/body metrics/water/activity.
- Lần thử rules đầu tiên với kiểm tra lặp nguyên trạng vượt giới hạn 1.000 biểu
  thức cho bữa 5 món. Rules được rút gọn mà không bỏ schema/range; lần chạy cuối
  chấp nhận 5 món hợp lệ và từ chối kiểu số sai.

### Rủi ro còn lại và việc người dùng cần làm

- Rules chưa cộng lại tổng dinh dưỡng từ 1–5 item. Làm vậy vừa tăng biểu thức khi
  rules đã gần giới hạn, vừa cần dung sai số thực nên không cho phép đối chiếu
  tuyệt đối. Client và test vẫn tính tổng từ snapshot, nhưng client tùy biến có
  thể gửi tổng khác chi tiết nếu tổng vẫn trong khoảng được phép.
- Rules chưa thể xác minh đầy đủ `dateKey` dạng chuỗi với timestamp + offset khi
  giữ schema hiện tại. Client chặn ngày không tồn tại và luôn tạo lại bộ field,
  nhưng client tùy biến vẫn có thể gửi bộ ba không nhất quán. Phương án chặt hơn
  cần schema ngày dạng số hoặc backend tin cậy và migration tương thích.
- Không có thao tác Firebase Console bắt buộc. Vì chưa deploy, production vẫn
  dùng phiên bản Rules trước Đợt 6.1; người dùng cần review diff và chủ động cho
  phép deploy trong một lượt riêng nếu muốn áp dụng bảo vệ mới.

### Bước kế tiếp đề xuất

Review và deploy riêng thay đổi Rules của Đợt 6.1 khi người dùng chấp thuận;
Đợt 6.2 chỉ thực hiện khi được yêu cầu rõ ràng.

## 2026-10-13 — Nhiệm vụ 6.2A: Nhật ký theo ngày đã chọn

Trạng thái: **hoàn thành 6.2A**. Chỉ sửa bộ chọn ngày và nguồn dữ liệu của Nhật
ký; không triển khai 6.2B–6.2H, Giai đoạn 7–9, không deploy Firebase và không
commit/push.

### Đã thực hiện

- `NutritionRepository.watchMealLogs` nhận ngày địa phương được chọn. Firebase
  query trực tiếp `consumedAt >= startOfDay` và `consumedAt < startOfNextDay`,
  sắp xếp giảm dần; bỏ truy vấn 100 meal mới nhất của toàn lịch sử.
- Khoảng ngày dùng hai mốc local calendar độc lập, không cộng cố định 24 giờ;
  bản ghi đúng đầu ngày được nhận và đúng đầu ngày kế tiếp bị loại.
- `mealLogsProvider` trở thành family theo ngày và tự hủy listener khi không còn
  được dùng. Đổi ngày tạo trạng thái tải riêng, nên kết quả stream ngày cũ không
  thể thay thế kết quả của ngày mới.
- `JournalScreen` đặt bộ chọn ngày trước các card và truyền cùng ngày cho meal;
  water/activity tiếp tục dùng cùng `dateKey`. Tổng kcal, protein, carbohydrate,
  chất béo, ml nước và phút vận động đều tính từ danh sách của ngày đang chọn.
- Empty state của meal nói rõ chưa có dữ liệu trong ngày; loading, error và retry
  hiện có được giữ lại, trong đó retry meal nhắm đúng provider của ngày hiện tại.
- Không sửa `firestore.indexes.json`: query meal chỉ range/order trên một field
  `consumedAt`, được phục vụ bởi single-field index mặc định.

### File chính đã sửa

`lib/core/utils/local_date_key.dart`,
`lib/features/nutrition/data/nutrition_repository.dart`,
`lib/features/nutrition/data/firebase_nutrition_repository.dart`,
`lib/features/nutrition/providers/nutrition_providers.dart`,
`lib/features/nutrition/models/nutrition_models.dart`,
`lib/features/journal/presentation/journal_screen.dart`,
`test/support/fake_nutrition_repository.dart`, `test/nutrition_test.dart`,
`docs/database-design.md` và tài liệu này.

### Kiểm tra thực tế

- `flutter test test/nutrition_test.dart --no-pub`: **6/6 pass**. Test mới bao
  phủ nhiều ngày, ngày trống, hai biên nửa đêm, tổng của meal/water/activity và
  đổi ngày khi meal stream vẫn đang tải.
- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  74 file, 0 thay đổi ở lần kiểm tra cuối.
- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test --no-pub --exclude-tags=integration`: **41/41 pass**.

### Việc người dùng cần làm và giới hạn

- Không có thao tác Firebase Console bắt buộc và không có index mới cần deploy.
- Chưa chạy smoke test với dữ liệu production vì nhiệm vụ cấm thao tác production;
  hành vi truy vấn và chuyển ngày được xác minh bằng unit/widget test.
- Các thay đổi Đợt 6.1 vẫn còn nguyên trong working tree và chưa deploy. Nhiệm vụ
  6.2A cũng chưa commit hoặc push.

### Bước tiếp theo

Dừng tại 6.2A và chờ yêu cầu tiếp theo của người dùng.

## 2026-10-13 — Nhiệm vụ 6.2B: Tái cấu trúc JournalScreen

Trạng thái: **hoàn thành 6.2B**. Đây chỉ là tái cấu trúc presentation; không đổi
nghiệp vụ, repository, provider, schema, Security Rules, indexes hoặc cấu hình
Firebase. Không triển khai 6.2C trở đi, không deploy, commit hoặc push.

### Cấu trúc sau tái cấu trúc

- `JournalScreen` giảm từ 802 xuống 292 dòng, tiếp tục đọc ngày/provider, mở các
  dialog, điều phối CRUD, xác nhận xóa và truyền state/callback xuống section.
- `MealLogSection` hiển thị tổng dinh dưỡng, danh sách meal, loading/error/empty,
  nút thêm thủ công, Food Scanner và callback sửa/xóa.
- `WaterLogSection` hiển thị tổng ml, danh sách water log và callback CRUD.
- `ActivityLogSection` hiển thị tổng phút, danh sách activity log và callback
  CRUD.
- `JournalDateSelector` chỉ hiển thị ngày cùng callback trước/sau/chọn ngày;
  `journalDateProvider` vẫn là nguồn trạng thái duy nhất.
- `DailyLogSectionCard` và `DailyLogEntryMenu` chứa UI dùng chung của water và
  activity, không đọc provider và không truy vấn dữ liệu.

Toàn bộ `ValueKey` đang được test (`add-meal`, `scan-food`, `add-water`,
`add-activity`, các nút chọn ngày, item water/activity và tổng dinh dưỡng) được
giữ nguyên.

### Hành vi được bảo toàn

- Meal vẫn lọc bằng khoảng nửa mở của ngày đã chọn; water/activity vẫn dùng
  `dateKey`, tổng của ba nhóm vẫn đổi đồng bộ theo ngày.
- Loading, error, retry, empty và đổi ngày trong lúc stream tải vẫn hoạt động.
- Thêm/sửa/xóa meal, water và activity vẫn đi qua controller hiện có.
- Food Scanner vẫn trả `FoodScanChoice` về `JournalScreen`, sau đó mở
  `MealFormDialog` với món gợi ý để người dùng xác nhận.
- Section widgets không chứa Firestore query, provider hoặc controller mới.

### File đã tạo

`lib/features/nutrition/presentation/meal_log_section.dart`,
`lib/features/water/presentation/water_log_section.dart`,
`lib/features/activity/presentation/activity_log_section.dart`,
`lib/features/journal/presentation/journal_date_selector.dart`,
`lib/features/journal/presentation/daily_log_section_card.dart` và
`test/journal_sections_test.dart`.

### File đã sửa

`lib/features/journal/presentation/journal_screen.dart`,
`test/nutrition_test.dart` và tài liệu này.

### Kiểm tra thực tế

- Test tập trung cho journal/nutrition/daily logs: **18/18 pass**.
- `dart format lib test`: 79 file, 0 thay đổi ở lần kiểm tra cuối.
- `flutter analyze --no-pub`: không có vấn đề.
- `flutter test --no-pub`: **45/45 pass**.
- Test mới kiểm tra callback thêm/sửa/xóa của từng section, loading/error/empty,
  callback bộ chọn ngày và đường đi từ kết quả Food Scanner tới form xác nhận.

### Việc người dùng cần làm và vấn đề còn lại

- Không có cấu hình thủ công bắt buộc. Chưa chạy trên thiết bị thật vì thay đổi
  chỉ tách widget và toàn bộ widget/regression test đã đạt.
- Working tree vẫn chứa nguyên thay đổi 6.1 và 6.2A; toàn bộ thay đổi chưa được
  commit, push hoặc deploy.

### Bước tiếp theo

Dừng tại 6.2B và chờ yêu cầu tiếp theo của người dùng.

## 2026-10-13 — Đợt 6.3: Onboarding và thiết lập mục tiêu sức khỏe

Trạng thái: **hoàn thành code và kiểm thử cục bộ**. Chỉ triển khai onboarding,
mở rộng hồ sơ và tích hợp điều hướng liên quan; không triển khai Dashboard,
Chatbot, Quest hoặc bất kỳ giai đoạn tiếp theo nào.

### Hành vi đã hoàn thành

- Tài khoản mới và tài khoản cũ chưa đủ thông tin được điều hướng tới onboarding
  sau khi Auth và hồ sơ tải xong. Tài khoản đã hoàn tất tiếp tục tới route đã yêu
  cầu và không phải thiết lập lại.
- Onboarding gồm bốn bước: thể trạng cơ bản, chọn mục tiêu, nhập cân nặng mục tiêu
  khi mục tiêu cần, rồi xem lại và xác nhận. Người dùng có thể quay lại mà không
  mất dữ liệu đã nhập.
- Validation kiểm tra tên, tuổi 13–120, chiều cao 80–250 cm, cân nặng hiện tại và
  cân nặng mục tiêu 20–500 kg. Ứng dụng không thu thập giới tính hoặc mức vận động
  vì chưa có nghiệp vụ sử dụng.
- Hoàn tất onboarding dùng Firestore transaction để cập nhật `users/{uid}` và
  upsert `body_metrics/onboarding-current`; ID ổn định ngăn retry tạo bản ghi cân
  nặng trùng.
- Trang Cá nhân cho phép sửa tên, ngày sinh, chiều cao, mục tiêu và cân nặng mục
  tiêu; cân nặng hiện tại tiếp tục được quản lý qua lịch sử Body Metrics.
- Lỗi tải/lưu có nội dung thân thiện, retry được; thao tác bị khóa trong lúc lưu.

### Schema và quyền truy cập

- Hồ sơ schema 2 thêm `birthDate`, `healthGoal`, `targetWeightKg` và
  `onboardingCompletedAt`. `ensureProfile` bổ sung field nullable cho hồ sơ cũ.
- Rules chỉ cho UID sở hữu đọc/ghi, kiểm tra whitelist mục tiêu, khoảng giá trị,
  dữ liệu bắt buộc khi hoàn tất và giữ `onboardingCompletedAt` bất biến sau lần
  ghi đầu tiên.
- Không cần Firestore index mới. Rules chỉ được sửa trong repository và **chưa
  deploy** lên Firebase production.

### File chính đã tạo/sửa

- Tạo `lib/features/profile/models/health_goal.dart`,
  `lib/features/profile/models/onboarding_draft.dart`,
  `lib/features/profile/presentation/onboarding_screen.dart` và
  `test/onboarding_test.dart`.
- Sửa router, session gate, profile model/repository/provider, form/trang hồ sơ,
  `firestore.rules`, rules test, Auth/Profile test và tài liệu database.
- Bảo toàn mọi thay đổi chưa commit của 6.1, 6.2A và 6.2B.

### Kiểm tra thực tế

- `dart format lib test`: **83 file, 0 thay đổi** ở lần chạy cuối.
- `flutter analyze --no-pub`: **No issues found**.
- `flutter test --no-pub`: **55/55 pass**.
- Firestore Emulator với JDK 21 đi kèm Android Studio:
  `firebase emulators:exec --only firestore "npm test --prefix rules-tests"`:
  **19/19 pass**.
- `git diff --check`: không có lỗi whitespace; Git chỉ cảnh báo quy đổi LF/CRLF
  trên Windows.

### Việc người dùng cần làm và vấn đề còn lại

- Trước khi dùng onboarding với Firebase production, cần review rồi deploy bản
  `firestore.rules` mới. Việc deploy cố ý chưa được thực hiện trong Đợt 6.3.
- Chưa chạy luồng onboarding thủ công trên thiết bị Android thật. Widget test,
  unit test và Rules emulator đều đạt.
- `java` mặc định của máy là Java 8; Firebase CLI cần Java 21. Lần kiểm thử này
  dùng `C:\Program Files\Android\Android Studio\jbr` cho riêng tiến trình, không
  thay đổi cấu hình hệ thống.
- Không commit, push hoặc deploy Firebase.

### Bước tiếp theo

Dừng tại Đợt 6.3 và chờ yêu cầu tiếp theo của người dùng.

## 2026-10-13 — Giai đoạn 6A: Hoàn thiện tài khoản và quyền riêng tư

Trạng thái: **hoàn thành code và kiểm thử cục bộ**. Chỉ triển khai quản lý tài
khoản, lưu theme và nội dung quyền riêng tư; không triển khai Giai đoạn 7 trở
đi.

### Hành vi đã hoàn thành

- Màn đăng nhập có luồng quên mật khẩu, kiểm tra email và dùng thông báo trung
  tính để không tiết lộ email đã đăng ký hay chưa.
- Trang Cá nhân cho đổi mật khẩu sau khi xác thực lại bằng mật khẩu hiện tại.
  Mật khẩu mới được kiểm tra độ dài, xác nhận trùng khớp và phải khác mật khẩu
  cũ.
- Xóa tài khoản yêu cầu nhập lại mật khẩu và xác nhận hậu quả. Trình tự là xác
  thực lại, xóa dữ liệu Firestore theo lô, xóa hồ sơ, rồi mới xóa Firebase Auth.
  Nếu xóa dữ liệu hoặc Auth lỗi giữa chừng, tài khoản còn lại có thông báo rõ và
  thao tác có thể chạy lại an toàn. Người chưa hoàn tất onboarding cũng có nút
  xóa tài khoản.
- Theme sáng/tối/theo thiết bị được lưu bằng `shared_preferences` và nạp trước
  khi dựng `MaterialApp`.
- Ba route thật cho Giới thiệu, Quyền riêng tư và Lưu ý sức khỏe đã được nối từ
  trang Cá nhân.

### Dữ liệu và Security Rules

- Repository xóa toàn bộ collection riêng tư đang triển khai hoặc đã thiết kế:
  `body_metrics`, `meal_logs`, `water_logs`, `activity_logs`, `goals`,
  `daily_quests`, `chat_sessions/messages`, sau đó xóa `users/{uid}`.
- Rules cho phép chủ UID đọc để liệt kê và xóa dữ liệu con của chính mình, đồng
  thời tiếp tục chặn UID khác và không mở quyền create/update cho đường dẫn chưa
  có nghiệp vụ.
- Không dùng Cloud Functions, backend mới hoặc dịch vụ trả phí.

### File chính đã tạo/sửa

- Tạo account data repository, controller lỗi theo giai đoạn, ba dialog bảo mật,
  màn thông tin tài khoản, theme preference store và test tương ứng.
- Sửa Auth repository/provider/screen, Profile/Onboarding, router, `main.dart`,
  `firestore.rules`, rules tests, `pubspec.yaml` và tài liệu database.

### Kiểm tra thực tế

- `dart format lib test`: không còn thay đổi định dạng ở lần chạy cuối.
- `flutter analyze --no-pub`: **No issues found**.
- Test tập trung Auth/Profile/Onboarding/Theme: **47/47 pass**.
- Firestore Emulator với Java 21: **20/20 pass**, gồm xóa hồ sơ, dữ liệu lồng
  nhau và chặn xóa chéo UID.
- `flutter test --no-pub`: **65/65 pass**.
- `flutter build apk --debug --no-pub`: build thành công tại
  `build/app/outputs/flutter-apk/app-debug.apk`; Flutter cảnh báo các plugin
  Firebase hiện vẫn áp dụng Kotlin Gradle Plugin cũ, chưa phải lỗi build.
- Lần chạy `dart format lib test rules-tests` ban đầu đi vào `node_modules` bị
  thiếu một thư mục package trung gian; formatter sau đó được chạy đúng trên
  `lib test`. Đây không phải lỗi mã nguồn hay rules test.

### Deploy và việc còn lại

- Đã deploy **chỉ** `firestore.rules` lên project
  `healthmate-app-20261013`; Firebase xác nhận compile và release thành công.
  Không deploy indexes hoặc dịch vụ khác.
- Chưa cài/smoke test APK mới trên Android vì điện thoại ngắt khỏi ADB ở bước
  cài đặt cuối. Build APK và toàn bộ test tự động đều đạt.
- Không commit hoặc push. Mọi thay đổi chưa commit của 6.1–6.3 được bảo toàn.

### Bước tiếp theo

Dừng tại Giai đoạn 6A sau khi hoàn tất kiểm thử; không tự triển khai Giai đoạn 7.

## 2026-10-13 — Giai đoạn 6B: Hoàn thiện nhật ký

Trạng thái: **hoàn thành code và kiểm thử cục bộ**. Chỉ hoàn thiện meal/water/
activity journal và biểu đồ cân nặng; không triển khai Goals, Quest hoặc Chatbot.

### Hành vi đã hoàn thành

- Meal schema 2 lưu `dateKey` và `timezoneOffsetMinutes`, dùng cùng quy ước ngày
  với nước/vận động. Danh sách chính truy vấn equality theo ngày đang chọn và
  được sắp theo `consumedAt` tại client.
- Bữa schema 1 thiếu `dateKey` vẫn xuất hiện bằng truy vấn khoảng thời gian nửa
  mở giới hạn trong ngày. Hai nguồn được gộp theo document ID; sửa bữa cũ sẽ tự
  nâng document lên schema 2. Không chạy migration hàng loạt.
- Thẻ tóm tắt ngày hiển thị kcal, protein/carb/chất béo, ml nước và phút vận động
  từ đúng các log đã tải của ngày đang chọn. Trạng thái chưa tải/lỗi dùng dấu `—`
  thay vì coi là số 0.
- Form bữa ăn có món gần đây, món ngoài catalog có nhãn `Ước tính`, giữ bước xác
  nhận khẩu phần và validation. Menu bữa cho phép nhân bản sang ngày đang xem.
- Nước có nút ghi nhanh 250/350/500 ml và vẫn đi qua repository/controller thật.
- Trang Cá nhân có biểu đồ tối đa 12 lần đo cân nặng gần nhất bằng `fl_chart`.
- Ngày và số ở phần UI mới dùng `intl`, theo định dạng Việt Nam phù hợp.

### Schema, migration và indexes

- `meal_logs` schema 2 thêm `dateKey`, `timezoneOffsetMinutes`; Rules bắt buộc hai
  field này cho create/update mới và cho phép nâng cấp document schema 1 khi sửa.
- Chưa migration dữ liệu production. Kế hoạch backfill có kiểm soát được ghi tại
  `docs/database-design.md`; phải xin xác nhận trước khi chạy.
- Không cần index mới: equality một field cho meal và range/order trên cùng
  `consumedAt` đều dùng single-field index mặc định. `firestore.indexes.json`
  không thay đổi bởi Giai đoạn 6B.
- Firestore Rules chỉ được sửa trong repository và **không deploy** trong lượt
  này.

### File chính đã tạo/sửa

- Tạo `lib/features/journal/presentation/daily_summary_card.dart`,
  `lib/features/nutrition/presentation/custom_food_dialog.dart`,
  `lib/features/profile/presentation/weight_chart.dart` và
  `test/stage_6b_test.dart`.
- Sửa model/repository/provider/presentation của nutrition, `JournalScreen`,
  water/activity presentation, `ProfileScreen`, Rules/test Rules, dependency và
  tài liệu. Mọi thay đổi chưa commit từ các đợt trước được giữ nguyên.

### Kiểm tra thực tế

- `dart format lib test`: **97 file, không còn thay đổi định dạng**.
- `flutter analyze --no-pub`: **No issues found**.
- `flutter test --no-pub`: **71/71 pass**.
- Firestore Emulator với JDK 21: **21/21 pass**, gồm quyền UID, schema meal v2,
  chặn date metadata sai và nâng cấp bữa schema 1.
- `flutter build apk --debug --no-pub`: thành công tại
  `build/app/outputs/flutter-apk/app-debug.apk`.
- Build còn cảnh báo từ các Firebase plugin về cách áp dụng Kotlin Gradle Plugin
  cũ; đây chưa phải lỗi build.

### Việc người dùng cần làm và vấn đề còn lại

- Trước khi chạy code 6B với Firebase production, cần review và deploy
  `firestore.rules`; lượt này không deploy Firebase, không commit và không push.
- Truy vấn tương thích bữa cũ tạo thêm một listener giới hạn trong ngày. Chỉ bỏ
  listener này sau một migration đã được người dùng duyệt và xác minh đầy đủ.
- Chưa smoke test thủ công trên điện thoại thật trong lượt này; unit/widget/rules
  test và APK debug đều đạt.

### Bước tiếp theo

Dừng tại Giai đoạn 6B và chờ yêu cầu tiếp theo của người dùng.

## 2026-10-13 — Giai đoạn 6D: UI nền tảng, Tổng quan và điều hướng nhanh

Trạng thái: **hoàn thành code và kiểm thử cục bộ theo phạm vi đã duyệt**. Chỉ
thực hiện token/component cần cho màn Tổng quan, màn Tổng quan dùng dữ liệu thật
và thanh điều hướng mới; không làm 6D-3 trở đi.

### Hành vi đã hoàn thành

- Theme sáng/tối dùng nền kem ấm hoặc xanh đen, xanh lá làm màu chính và màu
  nhấn riêng cho nước, bữa ăn, vận động và cân nặng. Font Be Vietnam Pro được
  đóng gói cục bộ với giấy phép SIL Open Font License 1.1.
- Tổng quan chào theo giờ và tên hồ sơ, hiển thị ngày địa phương, kcal và macro
  đã ghi, tổng nước, phút vận động, số bữa và cân nặng gần nhất.
- Tổng quan dùng trực tiếp `mealLogsProvider`, `waterLogsProvider`,
  `activityLogsProvider`, `userProfileProvider` và `bodyMetricsProvider`; không
  thêm repository hoặc query Firestore mới. Có loading, lỗi từng phần, retry và
  empty state hướng dẫn bắt đầu.
- Thẻ nước có nút ghi nhanh 250 ml và tiếp tục ghi qua `WaterController` thật.
- Thanh điều hướng di động dạng thẻ nổi chỉ hiển thị Tổng quan, Nhật ký và Cá
  nhân. Route/code Quest và Chat vẫn được giữ. Bố cục rộng tiếp tục dùng rail.
- Nút cộng mở bottom sheet đúng bốn hành động. Hành động chuyển sang Nhật ký và
  tái sử dụng dialog/controller hiện có; Quét món được nhấn mạnh nhưng không gắn
  nhãn nhà cung cấp AI trên giao diện.

### File chính đã tạo/sửa

- Tạo token màu, `AppCard`, `IconChip`, `MetricValue`, `MetricTile`, `EmptyState`
  và asset font tại `assets/fonts/be_vietnam_pro/`.
- Sửa `app_theme.dart`, `app_spacing.dart`, `app_shell.dart`,
  `dashboard_screen.dart`, `JournalScreen` và các nhãn hiển thị của luồng quét
  món.
- Tạo provider đồng hồ/ngày của Dashboard, provider lệnh nhanh một lần và
  `test/dashboard_test.dart`; cập nhật test router/auth/onboarding liên quan.

### Kiểm tra thực tế

- `dart format lib test`: **106 file, không còn thay đổi định dạng ở lần chạy
  cuối**.
- `flutter analyze --no-pub`: **No issues found**.
- `flutter test --no-pub`: **76/76 pass**.
- Test mới bao phủ Dashboard trống/có dữ liệu từ fake repository, ghi nhanh
  nước, điều hướng ở text scale 1.0/1.5, bốn hành động của bottom sheet và việc
  mở lại dialog Nhật ký hiện có.

### Việc người dùng cần xem và vấn đề còn lại

- Cần xem trên điện thoại thật ở theme sáng/tối: tương phản chữ, độ ấm của nền,
  độ cao thẻ khi tên dài, cuộn tới hàng metric thứ hai và vùng chạm của nút cộng.
- Cần thử cỡ chữ hệ thống mặc định và khoảng 150%, bàn phím khi mở bốn form, cùng
  thao tác back từ bottom sheet/dialog.
- Chưa chạy build APK hoặc smoke test thiết bị trong lượt này. Không sửa/deploy
  Firebase, không commit và không push.

### Bước tiếp theo

Dừng trước 6D-3 và chờ yêu cầu tiếp theo của người dùng.

## 2026-10-16 — Giai đoạn 7: Goals và Daily Health Quest

Trạng thái: **hoàn thành code, kiểm thử cục bộ và build APK debug**. Chỉ làm
Giai đoạn 7; giữ nguyên các thay đổi chưa commit của đợt 6D.

### Hành vi và dữ liệu

- Mở **Cá nhân → Mục tiêu và nhiệm vụ hằng ngày** để thêm/sửa/xóa mục tiêu số
  bữa, ml nước, phút vận động theo ngày hoặc cân nặng theo thời hạn. Có giá trị,
  đơn vị, ngày bắt đầu/kết thúc và trạng thái active/paused/completed.
- Định hướng sức khỏe onboarding trong hồ sơ được giữ riêng. Không tự tạo mục
  tiêu định lượng hoặc di chuyển dữ liệu cũ.
- Tiến độ thói quen chỉ cộng nhật ký thực đúng ngày. Cân nặng dùng khoảng cách
  từ baseline đến target, hỗ trợ cả tăng/giảm và chỉ lấy lần cân trong thời hạn.
- Engine thuần tạo một gợi ý/ngày, có lý do hiển thị. Chỉ gợi ý nước/vận động
  khi người dùng đã đặt mục tiêu tương ứng. Không AI, điểm/phạt hoặc suy đoán
  tình trạng sức khỏe từ nhật ký trống.
- Quest lưu `users/{uid}/daily_quests/{dateKey}`. Transaction create-if-absent
  giữ nguyên gợi ý và trạng thái khi mở nhiều lần hoặc có thao tác đồng thời.
  Hoàn thành/bỏ qua được lưu, không tự ghi log hoặc cộng tiến độ.
- Có loading/error/empty/success, thử lại dữ liệu lỗi, giữ input khi lưu form
  thất bại. Ngày cập nhật theo đồng hồ địa phương; timer được hủy cùng provider.
- Rules chỉ cho chủ UID thao tác, kiểm tra schema/giá trị/đơn vị/ngày lịch thật,
  bảo vệ baseline/createdAt và chặn sửa nội dung hoặc mở lại quest đã kết thúc.
- Xóa tài khoản hiện có đã bao phủ goals/daily_quests. Không thêm package,
  composite index hoặc dịch vụ trả phí.

### File chính

- Tạo feature `lib/features/goals/`: model, validation/progress, repository
  Firestore/interface, Riverpod providers/controller và form.
- Tạo `daily_quest/models/daily_quest.dart`, `domain/quest_engine.dart`; thay
  nội dung trang Quest chờ triển khai bằng giao diện thật.
- Thêm một lối vào trong `ProfileScreen`; bổ sung Rules/test Rules, fake
  repository và `test/goals_quest_test.dart`.
- Cập nhật `README.md`, `docs/database-design.md` và tài liệu này.

### Kiểm tra thực tế

- `dart format lib test` và kiểm tra lại
  `dart format --output=none --set-exit-if-changed lib test`: **116 file, 0 thay
  đổi ở lần cuối**.
- `flutter analyze --no-pub`: **No issues found**.
- `flutter test --no-pub`: **89/89 pass**. Trong đó 13 test mới bao phủ các công
  thức tiến độ, validation, quy tắc có thể tái lập, dữ liệu trống/đang tải/lỗi,
  lưu/sửa/xóa/retry, terminal status khi mở lại, đổi ngày và màn nhỏ với chữ lớn.
- Firebase Emulator (project demo, JBR Java 21): **24/24 pass**. Test mới kiểm
  tra schema, hai UID/khách chưa đăng nhập, ngày không hợp lệ, immutable fields,
  chuyển trạng thái và tạo quest đồng thời cùng ID. Đây là Rules/JS transaction
  tests; widget tests dùng fake repositories.
- `flutter build apk --debug --no-pub`: **thành công** tại
  `build/app/outputs/flutter-apk/app-debug.apk` (assembleDebug 59,4 giây).
- Build còn cảnh báo Firebase plugins dùng Kotlin Gradle Plugin cũ. Không nâng
  dependencies trong giai đoạn này.

### Việc còn lại và triển khai

- **Chưa deploy Firebase Rules**. Cần review/deploy `firestore.rules` trước khi
  tạo mục tiêu/nhiệm vụ trên Firebase production; không cần index mới.
- Chưa smoke test trực tiếp trên điện thoại với Firebase thật. Cần thử tạo mục
  tiêu cả bốn loại, tiến độ khi thêm/xóa log, giữ trạng thái quest sau mở lại,
  lỗi mạng và cỡ chữ hệ thống lớn.
- Transaction cần mạng; dữ liệu Firestore không bị ghi sang backend khác.
  API đã đối chiếu tài liệu chính thức:
  https://firebase.google.com/docs/firestore/manage-data/transactions
- Không commit, push, migration hoặc deploy production. Các thay đổi có sẵn
  của đợt 6D được bảo toàn.

### Giai đoạn kế tiếp đề xuất

Giai đoạn 8 — Dashboard và Weekly Reflection. Chưa triển khai.

## 2026-10-16 — Giai đoạn 8: Dashboard và Weekly Reflection

Trạng thái: **hoàn thành code, kiểm thử cục bộ và APK debug**. Chỉ làm Giai
đoạn 8, bảo toàn mọi thay đổi chưa commit của 6D và Giai đoạn 7.

### Hành vi đã hoàn thành

- Tổng quan giữ bố cục đã duyệt, lấy tổng kcal/macro, nước, phút vận động và số
  bữa từ provider ngày chung với Nhật ký. Thêm thẻ tiến độ mục tiêu và trạng thái
  nhiệm vụ đã lưu; có hành động mở màn Goals/Quest hiện có, không tự tạo quest
  chỉ vì mở Dashboard.
- Có ngày và nhãn múi giờ thiết bị. Đồng hồ dùng chung cập nhật qua phút/ngày,
  khi app trở lại foreground và được hủy khi không còn consumer.
- Nguồn chưa tải/lỗi hiển thị `—`, không coi lỗi là số 0. Tổng quan có trạng
  thái trống, dữ liệu thật, retry từng phần và thêm nhanh nước qua controller.
- Cân nặng Dashboard dùng listener `limit(1)` theo measuredAt. Lịch sử đầy đủ
  chỉ được dùng tại nơi cần quản lý hồ sơ; báo cáo dùng range tuần riêng.
- Mục **Nhìn lại tuần** chỉ truy vấn khi mở. Chọn tuần trước/hiện tại, xem tổng
  kcal/macro/ml/phút, số ngày có ghi nhận, trung bình kcal trên ngày có bữa và
  biểu đồ theo ngày bằng fl_chart. Có biểu đồ tối đa 12 lần cân trong tuần và
  chênh lệch số đo khi có ít nhất hai lần cân.
- Ngày trống ghi rõ chưa ghi; ngày chưa tới không cộng. Không giả dữ liệu,
  không chia bình quân mặc định 7 ngày, không suy đoán sức khỏe hoặc nguyên nhân
  biến động cân nặng.
- Báo cáo là snapshot lấy từ server: nhãn giờ tải, nút tải lại, lỗi khi thiếu
  một nguồn. Sau sửa log cần mở lại/làm mới báo cáo; không tạo listener báo cáo
  chạy nền hoặc ghi collection thống kê mới.

### Truy vấn và vòng đời

- Một lượt báo cáo gọi mỗi repository range đúng một lần: nutrition (2 query
  để giữ legacy), water (1), activity (1), body metrics (1), tổng cộng **5 query
  get**. Rebuild cùng UID/tuần không đọc lại; đóng/rời tab giải phóng cache.
- Khoảng ngày nửa mở; meal theo dateKey đã lưu, bữa cũ thiếu dateKey theo
  consumedAt địa phương và gộp theo ID. Không migration.
- Screen ngừng watch khi branch của indexed shell bị ẩn; autoDispose hủy các
  listener không còn consumer. Thẻ metric có chiều cao tự giãn để không tràn
  khi trở lại màn ở cỡ chữ lớn hoặc giá trị dài.
- Fake counters kiểm tra trước khi mở báo cáo có 0 lượt range; mở là 1 lượt
  mỗi repository; rebuild giữ 1; làm mới thành 2. Dashboard active có 1 listener
  meal/water/activity mỗi nguồn; rời sang Cá nhân còn 0 và quay lại là 1.
- Test xác nhận Dashboard không mở listener lịch sử cân nặng đầy đủ. Đây là số
  lần gọi và subscription đo trong fake tests; chưa đo billing/document reads
  Firebase production.

### File chính tạo/sửa

- Tạo `features/weekly_reflection/models/weekly_reflection.dart`,
  `providers/weekly_reflection_providers.dart`,
  `presentation/weekly_reflection_card.dart`.
- Tạo `dashboard/presentation/dashboard_goals_card.dart`, đồng hồ chung tại
  `shared/providers/local_clock_provider.dart`, `test/weekly_reflection_test.dart`.
- Sửa Dashboard/provider, range APIs và implementations của nutrition/water/
  activity/profile, providers lifecycle và guard nhỏ tại Journal/Profile/Quest.
- Sửa `MetricTile`, fake repositories/test harness, test Dashboard, thêm query
  range tests trên emulator; cập nhật README/database-design/progress.
- Không thêm package, không đổi Rules hoặc indexes trong Giai đoạn 8. Thay đổi
  Rules và font dependency có sẵn từ các đợt trước được giữ nguyên.

### Kiểm tra thực tế

- `dart format lib test` và kiểm tra lại
  `dart format --output=none --set-exit-if-changed lib test`: **122 file, 0 thay
  đổi ở lần cuối**.
- `flutter analyze --no-pub`: **No issues found**.
- `flutter test --no-pub`: **103/103 pass** (14 test mới Giai đoạn 8).
- Nhóm mới gồm tổng/macro/đơn vị, tuần qua năm, ngày rỗng/ít dữ liệu/future,
  ranh giới nửa đêm, dateKey ưu tiên timestamp, dedupe, lỗi/retry, đổi tuần khi
  đang tải, số query/listener, Goal/Quest Dashboard, rollover/resume, theme
  sáng/tối và cỡ chữ 1.0/1.5 trên màn nhỏ.
- Firestore Emulator project demo, JBR Java 21: **25/25 pass**. Query test mới
  xác minh dateKey/timestamp ranges, legacy merge, cuối khoảng không lặp,
  cân nặng limit(1) và chặn UID khác. Không gọi Firebase production.
- `flutter build apk --debug --no-pub`: **thành công**, lần cuối assembleDebug
  15,3 giây; APK tại `build/app/outputs/flutter-apk/app-debug.apk`.
- Cảnh báo KGP cũ từ Firebase plugins vẫn còn, không phải lỗi build. Không nâng
  dependencies ngoài phạm vi.

### Việc người dùng cần làm và giới hạn

- Cần thử trên điện thoại thật: Tổng quan đối chiếu Nhật ký, thêm/sửa/xóa rồi
  tải lại báo cáo, cỡ chữ lớn, theme tối, nhãn múi giờ, mất mạng và back/dialog.
  Chưa chạy smoke test với Firebase thật hoặc profiling production.
- Báo cáo tuần cần mạng để lấy tập dữ liệu đầy đủ từ server. Dashboard vẫn theo
  cơ chế cache/realtime của SDK hiện có; không tuyên bố số liệu chưa ghi là đủ.
- Giai đoạn 8 không cần Rules/index mới. Rules Giai đoạn 7 trong source vẫn
  chưa deploy; cần review/deploy trước khi ghi mục tiêu/nhiệm vụ production.
- Không commit, push, deploy Firebase hoặc migration. Không làm Giai đoạn 9.

### Giai đoạn kế tiếp đề xuất

Giai đoạn 9 — AI Health Chatbot có ngữ cảnh HealthMate. Chưa triển khai.

## Giai đoạn 9 — Trò chuyện HealthMate (16/10/2026)

### Trạng thái và phạm vi được xác nhận

Đã triển khai mã nguồn, kiểm thử tự động và build Android debug. Chưa kiểm thử
đầu cuối trên Android/Firebase AI thật vì `flutter devices` chỉ nhận Windows,
Chrome, Edge; chưa nhận điện thoại Android. Không tuyên bố production đã chạy.

Đã đọc toàn bộ AGENTS.md, kiểm tra code/dependencies/Android/Rules và Git trước
khi sửa. Có nhiều thay đổi chưa commit của 6D/7/8; giữ nguyên các thay đổi đó.
Không thêm/nâng cấp package, không đổi cấu hình Firebase/App Check hoặc indexes.

Sau khi đối chiếu điều khoản Gemini Developer API Unpaid Services hiện hành,
người dùng đã xác nhận: **giữ miễn phí; số liệu trả lời tại app, AI chỉ nhận câu
hỏi kiến thức chung định sẵn**. Đây là điều chỉnh rõ ràng so với phạm vi Giai
đoạn 9 ban đầu gửi ngữ cảnh cá nhân tới AI. Không có tùy chọn gửi sức khỏe cá
nhân tới model, không bật billing hoặc đổi sang dịch vụ trả phí.

### Hành vi đã triển khai

- Mở từ Cá nhân → Trò chuyện cùng HealthMate, giữ nguyên thanh điều hướng.
- Tra cứu kcal/macro, nước, phút vận động hoặc tóm tắt ngày bằng repository
  thật. Hỗ trợ hôm nay/hôm qua và chọn ngày; nhãn ngày/UTC offset/đơn vị rõ.
  Chỉ đọc nguồn liên quan; phân biệt dữ liệu trống với lỗi/giá trị bằng 0.
- AI chỉ nhận enum ba chủ đề: bữa ăn cân bằng, đọc nhãn dinh dưỡng, bắt đầu ghi
  nhật ký. System instruction riêng, không đưa nội dung tự nhập, UID, hồ sơ,
  nhật ký hoặc lịch sử hội thoại vào prompt. Không cấp tool/Firestore cho AI.
- Đã kiểm tra tài liệu chính thức Firebase AI Logic models/chat/thinking và
  Gemini terms ngày 16/10/2026. Model mặc định `gemini-3.8-flash`, override bằng
  `HEALTHMATE_CHAT_MODEL`; generation 2048 output tokens, thinking low. Chưa gọi
  model thật trong lượt này; không gửi dữ liệu sức khỏe thật đi kiểm thử.
- Có thông báo xử lý dữ liệu trước lần chọn AI đầu trong mỗi lần vào Chat,
  disclaimer, streaming, bản tạm chưa lưu, dừng nhận, timeout, retry và thông báo
  lỗi thân thiện. Không bảo đảm dừng request trên server/hoàn quota.
- Session/messages lưu dưới UID, 20 lượt mỗi phiên, tối đa 1000/6000 ký tự,
  tải 20 phiên gần nhất. Ghi nguyên tử theo cặp với ID ổn định; lỗi lưu giữ đáp
  án để retry cùng ID, không gọi AI lại. Chặn câu hỏi mới khi lưu chưa được xác
  nhận; người dùng có thể retry hoặc chủ động tạo phiên mới.
- Không thêm listener lịch sử. Khi rời nhánh hoặc đổi UID, hủy stream nhận và
  bỏ kết quả đến muộn; không chờ cleanup mạng để giao diện tiếp tục. Composer
  và consent tạm theo UID. Luồng xóa tài khoản cũ đã có xóa messages trước
  sessions nên được tái sử dụng, không sửa Auth/account deletion.
- Rules mới kiểm tra chủ UID, schema, role/source/độ dài, sequence, bộ đếm và
  cặp message; không cho cập nhật tin đã tạo. Rules không chứng thực nguồn AI
  ở phía máy chủ vì client ghi cả hai role; không dùng nhãn này để cấp quyền.

### File chính tạo/sửa trong Giai đoạn 9

- Tạo `lib/features/chatbot/models/chat_models.dart`.
- Tạo `lib/features/chatbot/data/chat_repository.dart`,
  `firebase_chat_repository.dart`, `knowledge_service.dart`,
  `firebase_knowledge_service.dart`.
- Tạo `lib/features/chatbot/domain/journal_chat_context.dart` và
  `lib/features/chatbot/providers/chat_providers.dart`.
- Thay placeholder `lib/features/chatbot/presentation/chat_screen.dart` bằng
  luồng Chat hoạt động; sửa nhỏ `profile_screen.dart` để thêm lối vào và
  `account_information_screen.dart` để giải thích quyền riêng tư.
- Cập nhật cục bộ `firestore.rules`, `rules-tests/firestore.rules.test.cjs`.
- Tạo `test/chatbot_test.dart`, `test/support/fake_chat_repository.dart`; thêm
  overrides test vào `test/support/test_app.dart` để test không gọi Firebase/AI.
- Tạo `docs/chatbot.md`; cập nhật README, database-design và báo cáo này.

### Kiểm tra thực tế cuối lượt

- `dart format lib test`: 131 file; kiểm tra lại
  `dart format --output=none --set-exit-if-changed lib test`: **0 thay đổi**.
- `flutter analyze --no-pub`: **No issues found** (12,0 giây lần cuối).
- `flutter test --no-pub`: **121/121 pass** (18 test mới, tổng 17 giây).
  Bao phủ chọn ngày/ranh giới nửa đêm/tổng, ngày rỗng, nguồn lỗi/retry, không
  gửi text/context cá nhân tới AI, streaming/partial/trống/lỗi quota/timeout/
  hủy, đổi UID và rời nhánh lúc tải, retry ghi không trùng, giới hạn phiên,
  disclosure, sáng/tối, keyboard, textScale 1.0/1.5/2.0 và lối vào từ Profile.
- Firebase Firestore Emulator project `demo-healthmate-rules`:
  **29/29 pass** (4 test mới, 10,75 giây). Xác minh transaction cặp thật trên
  emulator, idempotency, read order, cross-UID/guest, immutable message, giới
  hạn/invalid schema và quy trình delete child/parent; không gọi production.
- `flutter build apk --debug --no-pub`: **thành công**, assembleDebug 17,7 giây,
  APK: `build/app/outputs/flutter-apk/app-debug.apk`.
- Cảnh báo KGP của các Firebase plugins vẫn còn như Giai đoạn 8; không làm
  build thất bại. Không tự nâng SDK/dependencies ngoài phạm vi.
- `git -c core.safecrlf=false diff --check`: sạch. HEAD vẫn
  `310c8971ee2189ab4f01f2002edd4f93ff1e5535`, không stage thay đổi.

### Cần làm thủ công và giới hạn còn lại

- Review/deploy Rules mới trong một nhiệm vụ được yêu cầu riêng trước khi ghi
  Chat production; Rules Giai đoạn 7 trong source cũng còn chưa triển khai.
  Lượt này không deploy Rules/indexes, không commit/push, không migration.
- Cần Android thật để xác minh App Check/model/quota/streaming và lưu/tải lịch
  sử với tài khoản kiểm thử sau khi rule được triển khai. Web/desktop chỉ tra
  cứu nhật ký; gọi AI báo nền tảng chưa hỗ trợ.
- Kiểm tra bằng mắt: bố cục sáng/tối, chữ lớn/keyboard, nút dừng, auto scroll,
  mất mạng/retry, nhật ký nhiều ngày và đổi tài khoản. Checklist tại chatbot.md.
- Chưa hỗ trợ hội thoại AI tự do hoặc phân tích số liệu sức khỏe bằng model;
  đúng lựa chọn miễn phí đã xác nhận. Tra cứu hiện giới hạn tổng theo ngày cho
  bữa ăn/nước/vận động. Lịch sử là snapshot, không realtime hoặc phân trang
  hơn 20 phiên; chưa lưu bản nháp qua khởi động lại.
- AI vẫn có thể sai; các test giả lập không chứng minh chất lượng nội dung hay
  xác thực App Check của backend thật. Không tự bảo đảm miễn phí vô hạn.

### Giai đoạn kế tiếp đề xuất

Giai đoạn 10 — Security, kiểm thử tích hợp và hoàn thiện MVP. Chưa triển khai.

## Giai đoạn 10 — Security, kiểm thử tích hợp và hoàn thiện MVP

Ngày: **16/10/2026**. Hoàn thành rà soát, sửa lỗi trong phạm vi và kiểm thử
cục bộ/emulator; APK debug build thành công. Demo Android thật và phát hành
production còn các bước thủ công, không tuyên bố đã xác minh live AI.

### Quyết định và thay đổi

- Đọc toàn bộ AGENTS.md, khảo sát source/dependencies/tests/Android, Git status
  và diff. Lưu baseline hash cục bộ để phân biệt thay đổi Phase 10 với các đợt
  6D/7/8/9 còn chưa commit; không bỏ hoặc ghi đè các thay đổi sẵn có.
- Người dùng đã duyệt **MVP/demo 18+** sau câu hỏi về điều khoản Gemini. Cập
  nhật validation/ngày sinh/onboarding, cổng AI dùng chung kiểm tra session,
  UID/profile và hoàn tất thiết lập; giữ dữ liệu cũ. Đây là tự khai, không phải
  chứng thực danh tính/tuổi. Onboarding lặp giữ completion marker đã có.
- Chặn NaN/Infinity/overflow ở dữ liệu nhập thể trạng/dinh dưỡng và BMI.
  Rules kiểm tra dateKey thực sự khớp timestamp + UTC offset, bao gồm ca
  nửa đêm/ngày nhuận. Không thêm field/index, không migration dữ liệu cũ.
- Scanner có picker injectable, kiểm tra size/MIME/decode/dimensions, re-encode
  PNG bỏ metadata gốc, đồng ý từng ảnh, xử lý quyền/lỗi/timeout45s, đóng/đổi UID
  không nhận kết quả muộn; vẫn nhập thủ công khi catalog rỗng. Tăng giới hạn
  output JSON có chặn kích thước; không tự lưu kết quả AI thành meal log.
- Thông báo journal đang chờ server xác nhận, khóa gửi nhanh lặp khi pending;
  không retry tự động tạo thêm record. Privacy giải thích cache/offline,
  ảnh tạm/provider processing và giới hạn free tier. Android loại dữ liệu
  app khỏi OS backup/cloud/device-transfer; APK compile cấu hình mới.
- Thêm runner Auth+Firestore emulator dùng project demo cố định; test Flutter
  gọi SDK/repository thật. Bốn plugin web đã có transitive được khai báo
  thêm dev dependency, pub get offline giữ nguyên version, không thêm runtime
  dependency hoặc nâng cấp hàng loạt.

### File chính của riêng Giai đoạn 10

- Mới: `lib/core/config/ai_access_policy.dart`,
  `lib/features/food_scanner/data/food_image_picker.dart`,
  `android/app/src/main/res/xml/data_extraction_rules.xml`,
  `firebase.emulators.json`, `tool/test_emulators.ps1`,
  `tool/chrome_test_adapter.cmd`, `tool/chrome_test_adapter.cjs`.
- Sửa: `firestore.rules`, `rules-tests/firestore.rules.test.cjs`,
  `android/app/src/main/AndroidManifest.xml`, `pubspec.yaml`, `pubspec.lock`;
  `lib/features/profile/models/profile_validation.dart`, `user_profile.dart`,
  `lib/features/profile/data/firebase_health_profile_repository.dart`,
  `lib/features/profile/presentation/onboarding_screen.dart`,
  `profile_form_dialog.dart`, `account_information_screen.dart`;
  `lib/features/nutrition/models/nutrition_validation.dart`,
  `lib/features/journal/presentation/journal_screen.dart`,
  `lib/features/chatbot/providers/chat_providers.dart`,
  `lib/features/food_scanner/data/firebase_food_scanner_service.dart`,
  `models/ai_food_suggestion.dart`, `presentation/food_scanner_dialog.dart`,
  `providers/food_scanner_providers.dart`.
- Test mới: `test/security_regression_test.dart`, `test/food_scanner_test.dart`,
  `test/firebase_repository_integration.dart` (opt-in, không tự discover).
  Sửa hỗ trợ `test/support/test_app.dart`, `fake_health_profile_repository.dart`.
- Tài liệu: tạo `docs/test-report.md`; cập nhật README,
  `docs/database-design.md`, `docs/chatbot.md` và báo cáo này.

### Kiểm thử thực tế

- `dart format lib test tool`: **136 file, 0 thay đổi** ở lần cuối.
- `flutter analyze --no-pub`: **No issues found**, 7,5 giây.
- `flutter test --no-pub`: **134/134 pass**, khoảng 14 giây, không skip;
  gồm 13 bài mới và chạy lại tất cả test cũ.
- `tool/test_emulators.ps1`: **31/31 Rules + 4/4 real SDK integration pass**,
  Auth9099/Firestore8080, project `demo-healthmate-rules`, không production.
  SDK xác minh lưu/tải profile/onboarding/logs/Goals/Quest/Chat, chặn UID khác,
  offline pending/reconnect chỉ ghi một lần và xóa dữ liệu trước Auth.
- SDK web test runner Windows từng lỗi CanvasKit404/path slash; adapter
  phục vụ file cache SDK nguyên bản trong Chrome test headless đã giải quyết.
  Không sửa SDK hay bỏ qua assertions. Runner portable cuối đã chạy thành công.
- `flutter pub get --offline`: thành công; 4 dependency đổi từ transitive
  sang direct dev trong lockfile, không đổi version.
- Kiểm tra cuối `dart format --output=none --set-exit-if-changed lib test tool`:
  136 file, 0 thay đổi; `git -c core.safecrlf=false diff --check`: sạch.
- `flutter build apk --debug --no-pub`: **thành công**, assembleDebug16,2 giây.
  `build/app/outputs/flutter-apk/app-debug.apk`. Cảnh báo KGP Firebase plugins
  vẫn có như trước, chưa nâng SDK/plugin ngoài phạm vi.
- Rà soát secret source nonignored: không thấy private/service-account/key
  Gemini riêng; Firebase public config vẫn có. Không audit toàn Git history/
  ignored files. Storage không dùng, nên không có Storage Rules để test.

### Việc cần người dùng và giới hạn

- Không có Android kết nối khi kiểm tra. Cần thử camera/permissions, live
  App Check/Gemini/quota, offline kill/restart, sáng/tối/chữ lớn, đổi tài khoản
  và xóa tài khoản kiểm thử theo checklist README. Không chạy smoke test AI
  Android thật trong lượt này.
- Rules mới chưa deploy; cần review và yêu cầu riêng trước ghi Goals/Quest/
  Chat production. Không bật billing, thêm backend, đổi Firebase project,
  chạy migration, commit, stage hoặc push. HEAD vẫn
  `310c8971ee2189ab4f01f2002edd4f93ff1e5535`.
- Trước public release cần chốt application ID/icon/signing thay debug
  template và cấu hình SHA-256/Play Integrity. Native cache không tự xóa khi
  logout; backup/device transfer OEM chưa thử. Client cleanup phải được cập
  nhật khi thêm collection mới. Không gọi bản debug là sẵn sàng phát hành.
- Quyền UID/schema được test, không bảo đảm tính đúng dinh dưỡng/nguồn catalog
  hay tuổi tự khai. AI có thể sai, hủy chờ không hoàn quota. Các giới hạn và
  cách chạy lại được ghi đầy đủ trong `docs/test-report.md`.

### Giai đoạn kế tiếp đề xuất

Giai đoạn tùy chọn 11 — Thông báo và polish, chỉ sau kiểm tra Android thật và
khi người dùng yêu cầu. **Chưa triển khai.**

## Bổ sung Food Catalog — 16/10/2026

Theo yêu cầu thêm món Việt và các món cơ bản, chỉ mở rộng danh mục dinh dưỡng
(phạm vi Giai đoạn 4), không thực hiện Giai đoạn 11 hay tính năng khác.

### Đã hoàn thành

- Đọc lại AGENTS.md, kiểm tra Git/source/catalog repository/model/form/tests.
  Catalog production thực có 10 mục, UI chỉ cho thấy 8 kết quả mà chưa có xem
  tiếp. Lưu baseline hash cục bộ để giữ thay đổi các đợt trước.
- Bổ sung **148 mục**: 101 thực phẩm tham chiếu Viện Dinh dưỡng 2007, có
  mã/trang/basis; 47 món từ công thức HealthMate ước tính, có gram nguyên liệu
  và khối lượng thành phẩm. Tất cả mục mới có nhãn ước tính, `100 g`/`g`.
  Không coi một tô/ổ là 100 g; phân biệt sống/khô/chín. Không điền 0 cho số thiếu.
- Nạp quản trị bằng Firebase CLI login hiện có vào đúng `food_catalog` project
  `healthmate-app-20261013`. Commit nguyên tử/create-if-absent, không ghi đè
  mục cũ, không ghi đường dẫn `users/*`, không cập nhật meal snapshots.
- Đã đọc lại: tổng **158 mục**, **148/148 mục mới khớp dữ liệu**, có server
  timestamp; **10/10 document cũ giữ nguyên**, gồm timestamps. Dry-run lần nữa
  additions0/skipped148, không tạo trùng.
- Form tìm tiếng Việt không dấu/có dấu/NFD và alias; xem tiếp từng 12 món,
  tìm trên toàn bộ catalog, nhắc khối lượng và hiển thị ước tính. Không thêm
  query/Firestore listener. Danh mục vẫn từ repository Firestore hiện có.

### File chính

- Mới: `data/food_catalog/ingredients.json`, `data/food_catalog/recipes.json`,
  `tool/import_food_catalog.cjs`, `tool/food_catalog.test.cjs`,
  `lib/features/nutrition/models/food_catalog_search.dart`,
  `test/food_catalog_test.dart`, `docs/food-catalog.md`.
- Sửa: `lib/features/nutrition/presentation/meal_form_dialog.dart`, README,
  `docs/database-design.md` và báo cáo này. Không sửa Rules/index/dependencies.

### Kiểm thử thực tế

- `node --test tool/food_catalog.test.cjs`: **7/7 pass** (nguồn/đơn vị/số hữu
  hạn, công thức thành phẩm, tham chiếu công thức, idempotence/precondition và
  chặn đường dẫn ngoài catalog).
- `flutter test --no-pub test/food_catalog_test.dart`: **4/4 pass** (tìm kiếm,
  duyệt quá trang đầu ở textScale1.0/1.5, tìm mục chưa hiển thị và snapshot200g).
- `dart format lib test tool`; kiểm tra lại với `--output=none
  --set-exit-if-changed`: **138 file, 0 thay đổi** lần cuối.
- `flutter analyze --no-pub`: **No issues found**, 7,1 giây.
- `flutter test --no-pub`: **138/138 pass**, khoảng 12 giây.
- Nạp/read-back production và dry-run chống tạo trùng đã chạy thật như trên.
- `git -c core.safecrlf=false diff --check`: sạch. HEAD giữ nguyên
  `310c8971ee2189ab4f01f2002edd4f93ff1e5535`, không stage/commit/push.

### Giới hạn và cách xem

- Dinh dưỡng món chế biến là công thức giả định, chưa được phân tích/chuẩn hóa
  cho mọi quán hay nhãn hàng; khác lượng dầu/nước dùng/khẩu phần sẽ khác số liệu.
  Nguồn năm 2007, không gọi là nguồn mới nhất. Chi tiết tại `docs/food-catalog.md`.
- Mở lại **Thêm bữa ăn** khi có mạng để nhận catalog; chạy lại bản code mới để
  có tìm không dấu và nút Xem thêm. Thử `pho bo`, `com tam`, `dau phu`.
- Không build APK mới hoặc thử điện thoại trong lượt này. Không cần deploy
  Rules/index, không chạy migration, không thay cấu hình AI hoặc bật billing;
  chỉ catalog production được thêm theo yêu cầu.
- Chờ yêu cầu tiếp theo, không tự triển khai giai đoạn khác.

## 17/10/2026 — Bảo trì MVP F01–F06 và R01

Phạm vi theo tài liệu sửa lỗi do người dùng cung cấp; không triển khai giai đoạn mới.
Xem [báo cáo bảo trì](maintenance-2026-10-17.md) để biết từng file và bằng chứng.

- **Đã sửa local và kiểm chứng:** giữ bản nháp bữa/nước/vận động đến xác nhận ghi;
  chống gửi lặp và completion UID cũ; scale snapshot lịch sử; tóm tắt2×2 theo
  constraint; dòng phụ thẻ nước đầy đủ; mục tiêu retry với ID thao tác ổn định.
- **Quest:** thêm chẩn đoán nguồn và retry thực; Rules local/SDK emulator đạt.
  Rules đang deploy thiếu quyền ghi Goals/Quest/Chat, đọc xác nhận trong lượt này.
  Chờ review và yêu cầu deploy riêng, rồi kiểm tra backend thật.
- **AI:** thêm chẩn đoán an toàn + standalone QA probe. Cloud Android có một lượt
  thành công nhưng lặp lại timeout sau HTTP send, chưa có response/status;
  chưa xác định/sửa dứt điểm F04. Không đổi provider/model, timeout hay enforcement.
- **Kiểm tra cuối:** format145file/0thay đổi, analyze sạch, Flutter176/176,
  Node7/7, Rules31/31 + SDK6/6 (demo emulator), APK Android x64 debug build thành công.
- **File chính:** confirmed_save/operation_diagnostics mới; JournalScreen và form/controller
  meal/water/activity; nutrition snapshot/parser; Goals repository/form/provider;
  Quest screen; Chat/Scanner diagnostics; DailySummaryCard/MetricTile; ba bộ test
  maintenance, SDK integration và probe Android; tài liệu kết quả nối thêm.
- **Còn lại:** review Rules + deploy theo yêu cầu riêng; điều tra F04 bằng log/response
  cụ thể, retest QA Android và điện thoại thật. Không tự phát triển tính năng tiếp theo.
- Git HEAD giữ `3e8e9cc756c0a8caf1a882f6829088216736e56b`; thay đổi ở working tree,
  không stage/commit/push/PR hoặc production deploy/migration/billing.
- Người dùng đã yêu cầu tắt laptop sau khi hoàn thành: chỉ hẹn shutdown bình thường,
  không ép đóng chương trình có nội dung chưa lưu.

## 17/10/2026 — C1: nền tảng và chuyển sang phạm vi core

Yêu cầu C1 theo file `Sửa` của chủ sản phẩm thay thứ tự tính năng cũ trong đợt core.
Đầu mối hiện hành: [core-scope.md](core-scope.md), không ghi đè lịch sử ở trên.

- **Local đạt:** hai feature flags build cục bộ mặc địnhfalse cho Chatbot/Scanner;
  ẩn menu Cá nhân/CTA Nhật ký/quick action; chặn /chat/deep link/return link sau
  Auth/onboarding; giữ branch0–4, Profile4 và Quest hiện có.
- Không khởi tạo ngầm AI qua UI/điều hướng; controller Chat tắt không đọc lịch sử,
  checked service Scanner và knowledge service từ chối trước Firebase AI. Giữ code,
  dependency, Firebase/App Check, lịch sử Chat, snapshot AI và cleanup tài khoản.
- Giữ core CRUD/snapshot/pending/UID/dateKey+legacy, không đổi database/schema/index,
  không thêm mục tiêu kcal/macros, thư viện hoặc tab Tiến độ rỗng.
- File chính: app_feature_flags.dart mới; app_router/app_shell, Profile/Journal/
  MealLogSection, quick action; Chat/Scanner UI/provider gates; core_scope_test mới,
  helper và fixture hồi quy; README/database-design/test-report và tài liệu core.
- Kiểm tra mới: baseline176/176; cuối201/201Flutter, Node7/7, Rules31/31+SDK6/6
  demo emulator; format147file/0thay đổi, analyze sạch10,7s; debugAPK x64build11,8s.
  18tổ hợp UI và3ảnh đã xem, Auth/cold link/Back/noAI init; không gọi cloudAI.
- **Production chưa nghiệm thu:** đọc lại release11:59 UTC+07,17/10/2026;
  vẫn thiếu match ghi Goals/Quest/Chat, updateTime2026-10-13T06:25:21.345792Z.
  Cần review và yêu cầu deploy riêng, hướng dẫn project cụ thể ở core-scope.md.
- Không có Android kết nối: chưa E2E điện thoại, chỉ build, không cài/xóa app.
  Cảnh báoKGP còn; không nâng package/Gradle trong C1.
- HEAD giữ86238197a9f8e24a2222da2da9e74164c35844ea; không stage/commit/push/deploy,
  billing, migration hoặc sửa dữ liệu production. Không tự làm C2–C6.
- Tiếp theo đề xuất **C2 — mục tiêu kcal/macros có lịch sử hiệu lực theo ngày**.

## 17/10/2026 — C2: mục tiêu kcal/macros theo ngày hiệu lực

**Local đạt; production chưa nghiệm thu/chưa được cấp ghi collection mới.**
Chi tiết tại [core-scope.md](core-scope.md), schema tại database-design.md.

- Thêm feature nutrition_targets theoUID, IDyyyy-MM-dd, queryserver<=ngàyD giảm
  dầnlimit1; lịch sử không áp ngược. Kcal và đủ 3 macro hoặc cùngnull,0được giữ,
  bounds hữu hạn, cảnh báo lệch4P+4C+9F>5% cần xác nhận; không tự tínhBMR/TDEE.
- Form từ Tổng quan/Cá nhân, hôm nay/tương lai, nạp đúng phiên bản khi đổi ngày;
  so sánh Tổng quan/Nhật ký đã ghi/mục tiêu/còn/vượt. Lỗi/loading không thành0
  hay chưa đặt. Giữ form/pending/error, chốngdouble tap và completionUIDcũ.
- Repositorytransaction cùng ID, giữcreatedAt, serverread-back trước success;
  SDKđã tái hiện write có thể tới server dù normal reads bịdisableNetwork.
  Retry không nhân đôi; không coi lỗi ack là rollback.
- Ruleslocal nutrition_targets vớischema/UID/bounds/timestamps và cleanup account
  đã cập nhật, không đổiindexes/dependency/config hoặc dữ liệu cũ.
- File chính mới: models/data/providers/presentation dướifeatures/nutrition_targets;
  targetcard ghépDashboard/Journal/Profile; Rules/cleanup;33testsC2, fake/helper,
  thêm1SDK và4Rules tests; README/core-scope/database-design/test-report.
- Kiểm tra mới: baseline201; cuối234/234Flutter,35/35Rules+7/7SDK demo,
  7/7Nodecatalog; format155 file/0 thay đổi, analyze sạch11,6s,APKdebugx64build18,0s.
  Matrix18 UI và3 ảnh xem bằng mắt, keyboardmôphỏng; chưaE2Eđiệnthoại.
- ProductionGET12:23UTC+07 ngày17/10: RulesupdateTime2026-10-13T06:25:21.345792Z,
  thiếu quyền ghi nutrition_targets/Goals/Quest/Chat. Cầnreview và yêu cầu deploy riêng;
  hướng dẫn lệnh với project cụ thể trong core-scope, chưa chạy deploy.
- HEAD86238197a9f8e24a2222da2da9e74164c35844ea; giữ C1 chưa commit,
  không stage/commit/push/deploy/billing/migration. AI vẫn tắt; không làm C3–C6.
- Tiếp theo đề xuất **C3 — nhật ký nhanh, yêu thích catalog và sao chép bữa**.

## Core C3 — Nhật ký nhanh, yêu thích và sao chép (17/10/2026)

- **Local đạt** trong phạm vi unit/widget, Rules, SDK emulator và build. Chỉ làm C3;
  giữ toàn bộ C1/C2 chưa commit trên main, HEAD `86238197a9f8e24a2222da2da9e74164c35844ea`.
- Nhật ký chia Sáng/Trưa/Tối/Phụ, mỗi nhóm có tổng kcal, số bản ghi và nút Thêm
  đúng ngày/loại. MealLog vẫn độc lập; sửa/xóa cập nhật tổng nhóm, ngày và macro.
  Lỗi catalog không che nhật ký đã tải.
- Form có Tìm món/Gần đây/Yêu thích. Recent cập nhật live, giới hạn 20 bữa/8 món;
  favorite catalog riêng theo UID, ID ổn định, tải 40 rồi tăng 40 theo yêu cầu.
  Có loading/error/retry/cache, xử lý nguồn mất, pending và đổi tài khoản.
  Không thay dữ liệu thiếu bằng 0 kcal hoặc tạo các nguồn C4 chưa hoạt động.
- Copy mở draft giữ snapshot/source; cho sửa ngày/giờ/loại/gram. Hủy không ghi.
  ID cấp một lần mỗi form; transaction create-if-absent và server read-back.
  Retry cùng payload không nhân đôi; payload khác báo tải lại/chọn Sửa. Vẫn tối đa
  5 món/bản ghi, gram chuẩn và nhập món ngoài catalog một lần. Draft chỉ giữ RAM.
- Mới features/food_library, core_journal_test.dart và fake favorite. Sửa nutrition
  model/repository/provider/form/section, JournalScreen, Rules, account cleanup,
  SDK/Rules tests, helper và tài liệu. Schema favorite chỉ gồm tham chiếu catalog,
  timestamps và schemaVersion dưới UID; cleanup đã có test tài khoản A/B.
  Không đổi schema MealLog, indexes, package hoặc cấu hình backend.
- Baseline 234/234; kết quả cuối: 270/270 Flutter, 39/39 Rules + 9/9 SDK trên
  demo-healthmate-rules, 7/7 catalog. Format 162 file, không còn thay đổi; analyze
  sạch; APK debug android-x64 build thành công. Thời gian chạy cuối và bằng chứng
  nằm trong docs/test-report.md. Có 18 tổ hợp UI và 3 ảnh đã xem, keyboard mô phỏng.
- `flutter devices` chỉ có Windows/Chrome/Edge, chưa E2E Android hoặc cài APK.
  Không uninstall/clear app hay thay session người dùng. Cảnh báo KGP đã có còn.
- **Production chưa đạt**: GET Rules read-only lúc 12:45:30 UTC+07 xác nhận release
  vẫn ngày 13/10/2026, chưa có favorite_foods/nutrition_targets/Goals/Quest/Chat.
  Cần review và yêu cầu deploy Rules riêng, sau đó QA Android bằng tài khoản thử.
- Không stage/commit/push/deploy/billing/migration hoặc gọi AI; AI vẫn tắt.
  Dừng C3. Tiếp theo chỉ đề xuất **C4 — món cá nhân và công thức**, chưa thực hiện.

## Core C4 — Món cá nhân, công thức và khẩu phần (17/10/2026)

- **Local đạt** unit/widget/Rules/SDK Emulator/build. Chỉ C4 trên main,
  HEAD `86238197a9f8e24a2222da2da9e74164c35844ea`, giữ toàn bộ C1–C3 chưa commit.
  Baseline mới270/270 Flutter pass19s, không lấy kết quả C3 làm baseline thay thế.
- Thư viện từ Cá nhân, Món của tôi/Công thức trong form bữa. CRUD món cá nhân đủ
  bốn chất/100g, nguồn, tên khác, gram mặc định và cặp tên/gram khẩu phần tùy chọn.
  Nhập một lần giữ mặc định; lưu thư viện là lựa chọn chủ động và có ID ổn định.
- Recipe gồm1–6 snapshot catalog/món cá nhân, không lồng recipe. Yield có thể khác
  tổng nguyên liệu, số phần thập phân; cộng snapshot và scale theo yield, không
  cache tổng dẫn xuất. Dialog gram/phần kiểm tra cả số dinh dưỡng sau quy đổi.
- Sửa/xóa nguồn giữ MealLog và ingredient snapshot. Yêu thích cả3namespace, đọc
  nguồn private trực tiếp theo UID/ID, phân biệt lỗi/cache/missing; nguồn mất vẫn
  bỏ favorite được. Không đổi schema MealLog, giới hạn5món hoặc lịch sử cũ.
- Create retry cùngID/payload không trùng; server read-back trước ack. Edit không
  tự tạo lại nguồn đã xóa, delete chờ xác nhận. Form pending/error giữ draft RAM;
  logout/đổi UID đóng form và bỏ completion cũ. Library đã lưu nhưng bữa lỗi được
  báo riêng; retry bữa không tạo thêm món thư viện. Macro thiếu không tự thành0.
- Mới food_library_models, library repository/provider, library screen/forms,
  portion dialog/nutrition text, test/food_library_test.dart và fake library.
  Sửa favorite stack, Sources, Journal/nutrition forms/model, Profile/router,
  Rules/cleanup, SDK/Rules/fake/helper/regression tests và tài liệu hiện có.
- Thêm custom_foods/recipes dưới UID, mở favorite sourceKind; Rules exact fields,
  bounds/type/timestamps/createdAt và mọi dòng. Payload6 ban đầu vượt ngân sách
  Rules; đã tối ưu validator,47/47 Rules pass gồm dòng giữa/cuối và vượt giới hạn.
  Cleanup SDK xóa hai collection mới của A trước Auth, giữ dữ liệu B.
- Cuối308/308 Flutter pass39s, analyze sạch7,4s;47/47Rules+11/11SDK pass19s;
  7/7catalog; format172file không còn đổi; APKdebugandroid-x64 build45,5s.
  18tổ hợpUI cho hai form/6dòng/nhập một lần/keyboard;4ảnh đã xem. Lỗi test ban đầu
  errno112 do C thiếu chỗ đã xử lý bằng TEMP/TMP trên D rồi chạy lại đầy đủ.
- ProductionGET read-only16:11:23UTC+07: Rules vẫn13/10/2026, thiếu custom_foods/
  recipes/favorite_foods/nutrition_targets/Goals/Quest/Chat. **Production chưa đạt**,
  cần review và yêu cầu deploy riêng. Không Android trong flutterdevices, chưa
  E2E máy thật/ARM/release; KGP warning đã có còn. Không clear/uninstall/session thật.
- Không stage/commit/push/deploy/billing/migration/cloudAI hoặc nâng dependency.
  AI vẫn tắt. Chi tiết file/kết quả tại core-scope.md phầnC4 và test-report.md.
- DừngC4; chỉ đề xuất **C5 — Tiến độ, cân nặng và tổng hợp tuần**, chưa thực hiện.


## 2026-10-17 — Core C5: Tiến độ, cân nặng và tổng hợp tuần

- Hoàn thành C5 local; main/HEAD86238197 không đổi, C1–C4 uncommitted được giữ.
  Baseline mới308/308pass33s. Không chuyển sang C6, commit/push/deploy/migration.
- Thêm ProgressScreen/route branch5,4tab + nút thêm bữa/nước/vận động/cân nặng;
  giữ Profile4/Quest2/Chat3 và Auth/onboarding. Tổng quan có link Tiến độ.
- Dùng WeeklyReflectionCard, weeklyLogsProvider/summarizeWeek và nguồn cân hiện
  có; tổng/macros/số ngày/mẫu số đúng, tương lai không thành thiếu ghi. WeightChart
  sort/spacing timestamp, chi tiết ngày đo, ít hơn2điểm không mô tả thay đổi.
- Mục tiêu tuần2range query bounded, parser chung, chọn đúng phiên bản cho từng
  ngày. Loading/error/retry riêng không che tổng logs. Giữ tuần khi đổi tab nhưng
  nhả data consumer lúc ẩn; không listener ngày hoặc toàn lịch sử ở Progress.
- BodyMetricFormDialog có callback ConfirmedSave cho nút+; error giữ draft,
  pending chặn gửi lặp, AccountBoundDialog bỏ draft khi logout/đổiUID và refresh
  tuần khi thành công. Không thêm schema/Rules/index/package trong C5.
- File chính: progress/presentation/progress_screen mới; router/shell/dashboard,
  weekly_reflection_card, weight_chart/body_metric_form_dialog, nutrition_targets
  repository/provider; progress_test mới và core_scope/dashboard/profile/SDK/fake
  target tests. README/database-design/core-scope/test-report cập nhật.
- Cuối337/337Flutterpass41s; analyze sạch7,1s; format174file0đổi ở check;
  47/47Rules+13/13SDKpass21s;7/7catalog; APKdebugandroid-x64build21,6s;
  diff--check sạch.29test C5 mới,18tổ hợp layout; SDK có cân nặng/nhật ký thật qua
  năm mới, target history/ownership/offline/corrupt data. Không có Android kết nối.
- Full đầu lỗi test tìm vùng cuộn mơ hồ; đổi ensureVisible đúng nút, giữ assert.
  SDK mới đầu sai tham số fixture, đã sửa; các lượt cuối đủ337/13pass, không skip.
- Production GET read-only16:33:55UTC+07,17/10/2026, Rules release13/10/2026 vẫn
  thiếu nutrition_targets/favorite_foods/custom_foods/recipes/Goals/Quest/Chat.
  Production chưa đạt, chưa deploy. Chi tiết/hash/giới hạn trong core-scope C5.
- Cần review/deploy được yêu cầu riêng rồi QA Android (ngày/tuần/mục tiêu cũ,
  offline/UID, chữ lớn/sáng tối, bàn phím/safe area). TEMP/TMP dùng D, không clear/
  uninstall/session thật. KGP warning cũ còn; chưa ARM/release/Android E2E.
- Đề xuất tiếp **C6 — Nghiệm thu bản core trên Android và chuẩn bị bàn giao**;
  chưa thực hiện. AI vẫn tắt.

## Core C6 — Nghiệm thu Android và bàn giao (17/10/2026)

- **Local đạt**, production chưa nghiệm thu. Main/HEAD86238197 giữ nguyên;
  bảo toàn working tree C1–C5. Không stage/commit/push/deploy/migration/billing/AI.
- Sửa core phát hiện khi nghiệm thu: form Cá nhân giữ draft hồ sơ/cân khi lỗi,
  chờ ack và gắn UID; Profile/AccountSecurity controllers bỏ completion phiên cũ;
  SDK Auth kiểm tra expectedUid trước reauth/đổi mật khẩu/xóa. Cleanup vẫn xóa
  data trước Auth sau; test cũ về lỗi giữa chừng được giữ.
- Lần cân mới giữ giờ hiện tại, chỉnh cân không làm mất timestamp cũ. Sửa lỗi
  native sau onboarding cùng ngày cân mới không được coi là gần nhất.
- subscriptionStream sở hữu lỗi Future hủy stream khi logout, không bỏ lỗi đọc/
  ghi đang hoạt động. Áp dụng tại provider của các repository streaming liên quan.
- File chính: auth data/providers, profile providers/3form-screen, core/utils/
  subscription_stream.dart; nutrition/water/activity/goals/library/favorite
  providers; test/core_acceptance_regression_test.dart (12test mới), SDK test
  expectedUid, integration_test/core_acceptance_test.dart, test_driver và
  tool/test_android_core.ps1. Android debug network config chỉ cho HTTP localhost/
  10.0.2.2, không đổi release/main manifest. README/core-scope/database/test-report
  cập nhật. Không thay schema/Rules/index/dependency so với C5.
- Kết quả mới: baseline337pass34s; format178file0đổi; analyze sạch10,8s;
  Flutter349/349pass37s; catalog7/7pass; Rules47/47 + SDK14/14pass (SDK22s).
- Native Android API30/x86_64, AVD riêngHealthMateMaintenanceQA/UTC+07:
  10/10checkpoints E2E pass137s, repository Firebase thật qua emulator demo.
  Luồng đủ hồ sơ → target → thêm/sửa/copy bữa → nước/vận động/cân → tuần → đổi
  target/giữ lịch sử → libraryCRUD/giữ MealLog → offline/retry → logout/UID B.
  B bị chặn đọc A; AI không khởi tạo. Bốn PNG + log trong build/c6-android.
- Build normal lib/main.dart debug ARM64 pass24,8s; APK ở
  D:\HealthMateMaintenanceQA\HealthMate-core-debug-arm64.apk. Copy QA trên D khớp
  SHA256 của213file nguồn/asset/test/config với repo; gradle.properties tạm tắt
  incremental do khác ổ C/D đã khôi phục nguyên byte. Không cài máy thật.
  TEMP/TMP ở D do C còn ít dung lượng; QA AVD được tắt sau kiểm tra.
- Read-only production Rules17:04:32UTC+07: release13/10/2026 chưa đổi, thiếu
  targets/favorites/custom/recipes/Goals/Quest/Chat; water/activity indexes READY.
  Không deploy, không CRUD dữ liệu thật. Scan155file không thấy pattern private
  key/service-account/OAuth/GitHub token (giới hạn scan ghi rõ trong test-report).
- Chưa release signing/Play Integrity/điện thoại thật/process-death. Kiểm tra phụ
  release merged manifest offline không chạy hết vì thiếu Flutter release cache;
  KGP warning Firebase plugins còn. Không hạ dependency để giấu cảnh báo.
- Bước tiếp chỉ đề xuất: review backend và yêu cầu deploy riêng, rồi QA tài khoản
  thử trên máy thật (ngày/mục tiêu cũ, lưu/offline/UID, keyboard/safe-area, font
  100/150/200%, sáng/tối/vuốt chart). Chi tiết bằng chứng và lỗi đã sửa tại
  docs/test-report.md/core-scope.md phần C6. Dừng C6, không mở giai đoạn khác.

## U1 — UX Nhật ký/Tiến độ + chuẩn bị Firebase (18/10/2026)

- Local hoàn thành; production chưa deploy/nghiệm thu. Base main/fd2f72b, code
  U1 để working tree review, chưa commit/push. Không U2/billing/migration/AI.
- Nhật ký có overview kcal/macros/mục tiêu đúng ngày, trạng thái tải/lỗi độc lập;
  mục tiêu lỗi không chặn ghi, thiếu không tự điền số. Details sheet gắn UID.
  Header gọn, bữa/nút+ theo ngày chọn xuất hiện sớm; nước/vận động vẫn CRUD thật
  bên dưới, global+ vẫn hôm nay. Không gộp/xóa MealLog cũ.
- Tiến độ ưu tiên khoảng tuần/tổng/biểu đồ; hướng dẫn và lịch sử ngày mở khi cần.
  Giữ số ngày ghi/mẫu số, mục tiêu lịch sử, trọng số timestamp, query/vòng đời;
  target lỗi có retry ngoài vùng đóng. Không tạo aggregate/listener mới.
- File chính: FeaturePage; JournalScreen + journal_nutrition_overview mới;
  MealLogSection; ProgressScreen/WeeklyReflectionCard;21test mới trong u1_ux_test;
  finder/scroll/expand test cũ và native core_acceptance; tool inspect GET/backup;
  README/core-scope/test-report/firebase-deployment-plan và gallery docs/ux/u1.
- Baseline349/349pass36s; final format180file0đổi, analyze sạch43,8s,
  Flutter370/370pass64s, catalog7/7, Rules47/47 + SDK14/14pass24s. Android E2E
  API30/QA AVD/backend demo đủ10core + viewport/Gần đây pass164s.
- Viewport390×844/100%/sáng-tối/đủ macro/offset0: addBreakfast1319→497dp,
  toàn bộ nút đến545<748dp; chart888→362dp. Gần đây5bấm, không search; cuộn1→0.
  8ảnh trước/sau/JSON +2native ở docs/ux/u1.12matrix360/412×100/150/200%×2theme,
  keyboard260dp không che Lưu. Không ép chữ lớn đạt viewport100%.
- APK lib/main.dart debug ARM64 build39,6s:
  D:\HealthMateMaintenanceQA\HealthMate-U1-debug-arm64.apk (150690083bytes).
  Source copy D khớp217file; gradle.properties tạm override đã khôi phục. QA AVD
  đã tắt; không clear/wipe phiên thật. build/app cũ được giữ ở D:\HealthMateMaintenanceQA\
  archived-project-build-app-20261018 do C gần đầy; không mất source/APK C6.
- Rules/index không đổi; review47Rules/14SDK gồm ownership/schema/snapshot/cleanup.
  GET metadata19:12:59UTC+07 vẫn13/10/hash0b7a11…khác locald33e01…;
 7nhóm core chưa có create/update;2indexes READY. Tool/read-only backup và
  playbook đúng project/default DB/rollback đã chuẩn bị, chưa deploy/rollback.
- Còn QA điện thoại thật/Play Integrity/release/production. KGP warning và
  AVD Impeller/SwiftShader uniform warning được ghi rõ, ảnh/native E2E đã xem/pass.
  Bước sau chỉ đề xuất U2 khi được giao rõ, không tự làm.

## U2 — Triển khai Rules và nghiệm thu SDK production (18/10/2026)

- Chủ sản phẩm yêu cầu hoàn tất file UX/Firebase và cho phép đúng hai tài khoản
  QA tổng hợp; chỉ dọn dữ liệu QA. Base main/fd2f72b; giữ toàn bộ working tree U1,
  chưa stage/commit/push. Không đổi nghiệp vụ, schema, Rules source hoặc indexes.
- Backup source/metadata/config rollback trước deploy tại
  D:\HealthMateMaintenanceQA\u2-before-20261018-193138; bản copy được đối chiếu.
  Chạy lại 47/47 Rules + 14/14 SDK emulator, exit 0 (SDK 20 giây).
- Deploy đúng `firebase deploy --only firestore:rules --project healthmate-app-20261013`,
  exit 0. Release 2026-10-18T12:33:45.507953Z, ruleset 423ff6c8-79b7-4158-ba4f-2de9871a715d;
  GET sau deploy và cuối QA cùng hash LF-trim d33e017ecc4ca63ef1068ec55ab3ff732df0430492e57fcbfee6b4a89b796877,
  matchesLocal=true; hai composite nước/vận động READY. Không deploy index/rollback.
- Harness opt-in test/firebase_production_qa.dart và runner tool/test_production_qa.ps1:
  named Firebase apps QA A/B/guest, không default session/Admin SDK/emulator;
  email QA cố định, retry không tạo thêm tài khoản, credentials ngoài repo/ACL riêng.
- SDK production Chrome đạt 1 scenario / 10 checkpoint trong 27 giây, cả teardown:
  onboarding, mục tiêu lịch sử, favorite/custom/recipe, meal snapshot sau sửa/xóa
  nguồn, scale/copy ngày, daily queries/index, Goal/Quest, logout/login và offline
  3 giây/reconnect/retry cùng ID. 50 yêu cầu B/guest read/query/write/delete A bị
  chặn. Dọn/xác minh dữ liệu Firestore hai QA, A cleanup giữ B; giữ hai Auth QA.
- Format 180 file, 0 đổi; analyze final sạch 6,7 giây (lượt đầu có unnecessary
  dart:async ở harness mới, đã bỏ). Không thay app code sau U1; dùng kết quả U1
  370 Flutter / 7 catalog / Android E2E / APK đã ghi, không ghi thành lần chạy U2.
- Metadata/log không credential tại docs/firebase/u2; README/core-scope/test-report/
  deployment-plan cập nhật trạng thái hiện hành. Không đổi App Check/billing/AI,
  seed/migrate hoặc dữ liệu thật. Chưa kiểm chứng Android UI production/máy thật,
  Play Integrity, release signing. Hoàn tất U1/U2 trong file, dừng phạm vi này.

## H0 — 19/10/2026: kiểm thử theo identity và release guard

Đã sửa fixture để recipe là breakfast và chọn bữa mới theo ID; đủ 3 ID,
breakfast đúng ngày/200g/260kcal, ít nhất 2 breakfast hợp lệ. Không thay app clock.
Format 1 file/0 đổi, analyze sạch 33,8s, Flutter 370/370 pass 56s. Android QA
emulator-5580/HealthMateMaintenanceQA/API30 với Auth+Firestore demo-healthmate-rules:
10 checkpoint + viewport/recent pass 159s, debug build 42,7s. Runner trên QA copy D,
log D:\HealthMateMaintenanceQA\h0-android.log. KGP/SwiftShader warnings còn.
Release bỏ ký debug ngầm; private key.properties được ignore. Gradle dry-run release
thiếu khóa dừng đúng thông báo; chưa build release hoặc tạo keystore/đổi package.
Chi tiết docs/release-readiness.md và docs/h-improvements.md. Theo yêu cầu trực tiếp
thực hiện tuần tự H0–H7, chuyển H1 sau mốc H0 này; không deploy/import production.

## H1 — 19/10/2026: khẩu phần catalog, tìm kiếm và dữ liệu có nguồn

Hoàn thành code/data review, chưa import production. Reader khẩu phần tương thích
cũ, fallback gram khi metadata hỏng, không dùng basis/unit không hỗ trợ. Đổi đơn vị
giữ lượng, phần phân số preview/snapshot đúng. Tìm exact/alias/token trước substring;
giữ tìm dấu/không dấu/NFD. Ba dòng TH yogurt100g có nguồn nhà sản xuất;47 công thức
đề xuất phần tham khảo theo yield, không coi tô=100g. docs/h1-catalog-review.md.
Node9/9; Flutter379/379 (42s), focused51/51, H1 cuối9/9; analyze sạch9,6s.
Rules47/47 + SDK15/15 (21s); import emulator151create, retry0create/update/conflict.
Fixture import ban đầu bỏ pagination và fail; diagnostic xác định vn2007-9007,
sửa đọc nextPageToken rồi đạt. Benchmark tool đầu5lint imports/braces đã sửa.
Android QA emulator-5580/API30/demo-healthmate-rules đủ10checkpoint pass154s;
phần0,75 ×200g lưu150g/195kcal qua repository thật. Ảnh docs/ux/h1/catalog-fractional-portion.png
đã xem; benchmark19truy vấn có nhóm held-out/brand/missing,15positive+4rỗng có chủ đích,
19đúng first/empty, giữ và báo kết quả nhiễu. Dataset branch151 khác production158.
Dry-run production: existing158/create3/skip148/proposedMetadataUpdates47/conflict0;
manifest/benchmark ở docs/ux/h1. Tool --apply chỉcreate, metadataupdates cần review/
maintenance riêng. Không đổi Rules/index/schema nhật ký hoặc deploy/AI/billing.
Chưa máy thật/release ký. Hạn mức5h còn60%; chuyển H2 theo yêu cầu chuỗi.

## H2 — 19/10/2026: ghi quen nhanh và bữa mẫu, đạt local/emulator

Recent ưu tiên khi có lịch sử, tài khoản mới về Tìm món; dùng trực tiếp lượng
hiển thị vào bản nháp, Hoàn tác/Sửa riêng, Lưu mới ghi server. Hay dùng đếm theo
20 bản ghi gần nhất/tối đa8 món, không tải toàn lịch sử. Cùng fixture/điểm bắt
đầu đo3tap/0scroll/0gõ/0xác nhận lượng thay cho5tap; đúng ngày/bữa/gram/snapshot.
Bữa mẫu thuộc UID, CRUD tên+1–5snapshot, tạo từ bữa cũ/món đang chọn, dùng bản sao
vào ngày/bữa chọn và sửa từng món. Không gộp thành recipe, nguồn mất vẫn giữ lịch
sử. Cleanup client mới thêm meal_templates; cần nâng client trước enable backend
để client cũ không bỏ sót collection mới khi xóa tài khoản.
Format20file0đổi; analyze sạch11,4s; Flutter385/385 pass52s; targeted6/6 (UID+
pending/retry/bounds/widget100/150/200%). Rules48/48 + SDK16/16 pass25s; test A/B,
guest,5món/overflow/timestamps, offline/retry snapshot và cleanup A giữ B.
Rules đầu vượt1000expressions khi5món; dùng regex/let/sum bounded giữ đủ validation
rồi focused/full pass. UI test đầu chưa prewarm Auth làm dialog đóng, sau đó
x2 chữ dài đẩy ô tên khỏi lazy viewport: sửa harness auth và đưa tên lên trước
hướng dẫn ngắn; cuối6pass. UID test cần giữ subscription Auth trước await.future;
đã sửa và full385pass. Không bỏ assertion hoặc nới Rules lấy pass.
Android final: emulator-5580/HealthMateMaintenanceQA/API30/demo-healthmate-rules,
10checkpoint +H1portion/H2recent vàtemplate UI pass176s. Tạo mẫu2món từ draft,
hủy không log; dùng/chỉnh100g +20grecipe nguồn đã xóa =180kcal đúng ngày/Bữa tối;
xóa mẫu không đổi meal; logoutBriêng tư. Ảnh/flow ở docs/ux/h2.
Lượt Android đầu cần reveal trường lazy sau bố cục mới; lượt sau dùng Rules cũ
trong QA copy nên lưu bị từ chối. Thêm tool/sync_qa_workspace.ps1 đối chiếu241
source/config/asset gồm root Rules rồi final pass. Không deploy production để
sửa lỗi QA copy. Raw logs D:\HealthMateMaintenanceQA\h2-android*.log.
Schema/Rules/rollback và client compatibility trong h2-templates-deployment.md;
local Rules mới chưa deploy, catalog H1 mới chưa import. Không commit/push/AI/billing.
H3–H7 chưa triển khai tại mốc H2; tiếp tục tuần tự theo yêu cầu, còn40% hạn mức5h
ở lần kiểm tra trước Android final.

## H3 checkpoint 19/10/2026 — code/Rules/SDK đạt, Android đang chạy

Chi tiết hành vi, file, schema/rollout, log và các vòng lỗi/sửa trong
[H3 Quick Add](h3-quick-add.md). Ghi100g/100ml/khẩu phần/tổng, kcal-only/macro
optional, unknown khác0; nhật ký/copy/template/history dùng snapshot.
Format32file; analyze sạch9.8s; fullFlutter397/397(52s),focusedcuối13/13(4s);
Rules49/49(13.2s),SDK17/17(23s), importerEmulator151/0retrychanges.
Android H3 đang chạyQA AVDemulator-5580/demo-healthmate-rules, chưa kết luận đạt.
Production chưa ghi/import/deploy, Git chưacommit/push. H4–H7 chưa triển khai.
Hạn mức5h còn7% lần kiểm tra gần nhất; sẽ theo yêu cầu dừng/lưu/tắt máy khi<5%.

### H3 cập nhật kiểm chứng cuối

FullFlutter398/398(56s), analyze sạch10.2s sau fix UI, focused13/13(3s),
Rules49/49(13.5s), SDK17/17(23s). AndroidH3đủ10checkpoint pass206s; hiện chạy
lần cuối sau cải thiện spacing/helper/snackbar từ ảnh kiểm tra. Chi tiết cả lần
lỗi và sửa trong h3-quick-add.md. Hạn mức5h đã<5%(còn4%); chốtH3/dừngH4–H7,
lưu tiến độ và tắt laptop theo yêu cầu. Không commit/push/deploy/importproduction.

### H3 đạt; tiếp tục theo yêu cầu mới sau khi hạn mức reset

Android visual-final đạt200s, đủ10checkpoint/H2templates/H3QuickAdd. Đã xem ảnh
volume-preview mới: khoảng cách/hướng dẫn rõ và không còn snackbar cũ che form.
Nguồn243fileQAđối chiếu. H3 hoàn tất local/Emulator; chưa nghiệm thu production.
Người dùng gửi “tiếp tục đi” sau khoảng nghỉ; kiểm tra mới: hạn mức5h used0%,
còn100%. Chưa có lệnh shutdown nào được thực thi/lập lịch. Tiếp tục H4–H7 theo
lệnh mới, vẫn theo dõi điều kiện<5% và tắt máy ở cuối chuỗi hoặc tại ngưỡng đó.
Các mục “Android đang chạy” ở trên là checkpoint lịch sử, đã có kết quả cuối này.

## H4 — đạt local/Android Emulator

Helper tùy chọn mức duy trì từ FAO/WHO/UNU/Schofield; đầu vào tự chọn, chưa lưu
sinh lý, phạm vi18–59 và đường quay về nhập tay. Xem cách tính, đưa kcal vàoform,
chỉnh rồi xác nhận lưu với ngày hiệu lực; giữ macro/historical target. Không tự
thâm hụt/dư năng lượng hoặc cộng kcal vận động. Quyết định/nguồn/giới hạn và file
chính trong h4-goal-guidance.md; cần chuyên gia rà soát trước phát hành rộng.
Format10file/5đổi rồi9file0; analyze sạch12.9s; focused9/9(7s); full407/407(49s).
Android h4-android-final.log:10checkpoint +H1/H2/H3/H4pass235s trênAVDQA/API30,
demo-healthmate-rules. H4 UIxemkếtquả2670kcal chưa ghi, sửa2600rồiLưu, đọcSDK
đúng2600, ngàytrước1800khôngđổi; BkhôngđọcA. Ảnhdocs/ux/h4/maintenance-estimate.png.
Lượt nativeđầu bị guardchặn vìAVDđãđóng trong khoảngnghỉ; khởi độnglạiđúngAVDQA,
khôngchuyểnsangmáythật. KGP/SwiftShaderwarningscũcòn. H4khôngđổischema/Rules,
khôngdeploy/importproduction, khôngcommit/push, AIgiữtắt. TiếptheoH5.

## H5 — đạt local/Emulator

Báo cáo30/90, giữtuầncũ; mụctiêuđúnghiệulực; trạngtháixácnhậnđủbữa theoUID+
ngày+revision, không tự coi1bữa làđủ. Ngàytrống khônglà0kcalđãăn; macrothiếu giữ
coverage. Range2001sentinel/chặn>2000doc mỗiquery,1–90ngày; lỗi nguồn riêng,
refresh rõ, không thêmrealtime. Cân hiển thịđiểmthật/khoảngcáchthời gian/sốmẫu.
File/schema/rollout và lỗi đãsửa trongh5-period-reports.md. Cleanupday_reviews,
Rulesmớiđãtestnhưngchưadeploy, khôngindexmới/migration/AI/importproduction.
Focused53/53(19s); H5+UID11/11(13s), full417/417(122s) trước thêmtestUIDcuối;
analyze sạch39s. Rules50/50 vàSDK18/18(31s), kểcả2.001waterfixturebịbáooverflow,
xáoriêngfixturetrongfinally. NativeAndroid227s/10checkpoint+H1–H5đạttrênAVDQA/
demo-healthmate-rules: UIxácnhậnngày,30/90tổngkhớpSDK,1ngàyxácnhận, khoảngcũ
trống/next/trởvềvàBriêngtư. Ảnhdocs/ux/h5/period-30.png. Khôngcommit/push/deploy.
Tiếp theoH6; H7chưatriểnkhai. Hạnmức5h lần gầnnhất còn66%, tiếptụctheodõi.


## H6 — đạt local/Emulator, chưa triển khai production

Thêm chất xơ có nguồn, phân biệt 0 thật/thiếu/tổng biết một phần; giữ coverage khi
nhân khẩu phần, recipe yield, snapshot, sửa/copy/bữa mẫu và báo cáo. Nguồn 4 ID
USDA có sẵn; branch 155 mục, production dry-run 158 đang có/3 create/51 metadata/
0 conflict/152 skip, không apply. Hợp đồng meal4, custom/recipe2, template3,
chống hạ phiên bản và rollout/rollback xem h6-fiber.md và database-design.md.
File chính: nutrition_models/catalog_food_reader, firebase_nutrition_repository,
food_library models/forms/text/repository, quick_add_dialog, meal_templates,
journal/weekly summary, firestore.rules, legacy_usda.json, importer và tests.
Format 59 file/0 đổi ở kiểm tra cuối; analyze sạch (62.1s); Flutter423/423(67s);
unit H6 mới nhất5/5 sau thêm assert round-trip. Rules51/51, importer Emulator155
create/retry0change, Firebase Flutter Web SDK19/19(43s), gồm thiếu nguồn, retry,
A/B, cleanup và H5 overflow2.001rows. Android QA API30/emulator-5580 +
demo-healthmate-rules: 10checkpoint và H1–H6 đạt239s; 250ml/100ml ->3g, nguồn
recipe đã xóa nhưng bữa cũ vẫn0.5g, B riêng tư. Lượt native đầu221s thất bại do
assert nhầm recipe một nguyên liệu biết chất xơ thành thiếu; sửa kỳ vọng và đọc
lại bản ghi thật rồi chạy lại. Các lỗi Rules/codec phát triển ghi ở h6-fiber.md.
Ảnh h6/fiber-volume.png và ảnh H5 mới đã xem: nút xác nhận rõ, preview3g,
macro thiếu không thành0, nội dung báo cáo có thể cuộn. Còn cảnh báo KGP/
SwiftShader/Impeller cũ; cần xem thêm máy thật. Không commit/push/deploy/index/
import production/AI. H6 hoàn thành; tiếp H7 theo yêu cầu, theo dõi ngưỡng5%.


## H7 — checkpoint chưa hoàn thành, dừng do hạn mức còn 4%

Đã chốt lõi CSV thuần journal_csv.dart + test/h7_csv_test.dart:4/4 qua; định dạng
UTF-8 BOM/CRLF/quote, chặn formula injection, range1–90 ngày, dateKey/UTC/offset/
schema và missing/0/partial. Chưa nối UI/controller/file picker hoặc quyền UID
cho export; chưa lưu/phục hồi draft bền vững. Không gọi đây là H7 hoàn chỉnh.
Format2file; analyze lượt đầu1lint thiếu ngoặc, đã sửa; lượt cuối xem log và
h7-checkpoint.md. Không chạy lại toàn bộ suite sau4test mới; fullH6 trước đó423/423,
Rules51/51, SDK19/19, Android239s/10checkpoint+H1–H6 đã đạt. H7 chưa testAndroid.
Không có package/collection/Rules/index/localstorage mới cho H7, không production
write/commit/push. Còn lại và hướng nối tiếp ghi rõ h7-checkpoint.md. Theo chỉ thị
người dùng, lưu checkpoint và tắt máy bình thường sau khi chốt phần CSV này.


Chốt checkpoint H7: analyze cuối sạch (11.5s), format2file; CSV4/4. Bản sao323file nguồn/tài liệu và log nằm ở D:/HealthMateMaintenanceQA/h0-h6-h7-checkpoint-20261019; patchtracked riêng h0-h6-h7-working-tree.patch. H7 còn thiếu đúng như danh sách trên, không công bố hoàn tất.

## H7 — hoàn thành local/Android Emulator sau khi tiếp tục

Tiếp tục từ checkpoint 4% sau khi cửa sổ 5 giờ reset; H0–H6 và toàn bộ thay đổi
chưa commit được giữ. H7 hoàn thành, không tự chuyển mốc khác. Hạn mức được đọc
ở các mốc; không cần dùng lý do hạn mức để bỏ phần nghiệm thu còn lại.

- Android giữ nháp mã hóa AES-256/GCM, khóa AndroidKeyStore và AtomicFile trong
  noBackupFilesDir. UID/ngày/bữa, snapshot nguồn, unit, missing/0/partial, UTC,
  offset, operationId và minimum schema giữ xuyên restart. Tối đa20nháp/512KiB,
  TTL7ngày, dọn khi mở kho; khôi phục/bỏ nháp do người dùng chọn, không tự submit.
- Mọi entry point MealFormDialog nối cùng kho. Lưu operationId+payload local
  trước gửi Firestore; chỉ dọn sau ack. Gián đoạn có thể vẫn commit; retry giữ
  ID cũ, không mặc định lỗi Future đồng nghĩa chưa có bản ghi máy chủ.
- Cá nhân có Xuất nhật ký CSV, ngày1–90, bốn nguồn nhật ký/cân nặng, query giới
  hạn H5; không export profile/chat/goals/draft và không gọi đây là toàn bộ account.
  CSV BOM/CRLF/quote/chặn công thức, schema/đơn vị/timezone/basis và nutrient status.
  Consent riêng tư, Android document picker, kiểm tra UID trực tiếp SDK và phiên
  trước ghi bytes, native đọc lại khớp mới báo thành công. Không email/upload tự động.
- Xóa tài khoản dọn nháp đúng UID sau Firestore/trước Auth; lỗi giữa chừng giữ Auth
  cho retry, chặn callback trễ ghi lại. Không xóa B hoặc CSV người dùng đã xuất.
- Sửa hai guard ref.mounted ở userProfileProvider/bodyMetricsProvider: lỗi cũ được
  native H7 phát hiện khi đổi UID lúc bootstrap, trực tiếp chặn nghiệm thu A/B.
  Không refactor toàn bộ profile; regression có completer theo sự kiện thực.

File chính: core/data/private_local_data.dart; Android PrivateLocalData.kt và
MainActivity.kt; meal_drafts/data/meal_draft_store.dart, presentation/draft_picker.dart;
MealFormDialog, JournalScreen, MealDraft; data_export/models/journal_csv.dart,
data/journal_export_service.dart, presentation/journal_export_dialog.dart;
ProfileScreen, auth repository/currentUid và controller cleanup; profile_providers;
test/h7_csv_test.dart, h7_private_data_test.dart; integration_test/h7_private_data_test.dart;
tool/test_h7_android.ps1 và verify_h7_export.ps1. Đường dẫn/contract đầy đủ:
[h7-private-data.md](h7-private-data.md), ảnh và chứng cứ [ux/h7](ux/h7/README.md).

Kiểm tra cuối (19/10/2026):
- flutter test --no-pub: **454/454 qua, 43s**, build/h7-flutter-final-6.log.
- flutter analyze --no-pub: **No issues found, 17.4s**, build/h7-analyze-final-5.log.
- Native QA: **phase1 12s + phase2 32s, exit0**; D:/HealthMateMaintenanceQA/h7-android-final.log
  và c6-workspace/build/h7-android/phase-1.log, phase-2.log. Process death/restore,
  offline/uncertain commit/retry, OS picker/file readback, UID switch và A/B cleanup đều qua.
- tool/verify_h7_export.ps1: **file Downloads1554byte khớp từng byte** với CSV từ
  repository thật; BOM và đủ bốn loại dữ liệu. build/h7-export-final.log.
- H7 không sửa Rules/indexes. Bộ Rules51/51, Web SDK19/19 và native H0–H6 trước đó
  vẫn là kết quả lịch sử đã ghi, không giả là vừa chạy lại các suite đó trong H7.

Các lượt phát triển thất bại được giữ log: lỗi dùng navigator context của màn
thay dialog; thêm nút export làm test vị trí metric cần sửa layout; lỗi provider
đã disposed (đã thêm guard); runner Windows ExitCode/file sharing và chờ frame
khi OS picker mở (sửa harness). Một kỳ vọng offline=0 sau reconnect không đúng
hợp đồng acknowledgement; giữ assert chưa tự gửi trước Lưu, sau retry đúng một
ID trên server. Bài regression đầu có chờ theo thời gian bị flaky; đổi sang
completer/sự kiện bootstrap, full suite452qua. Script đọc CSV ban đầu quote sai
đường dẫn có khoảng trắng qua exec-out; đã sửa và đối chiếu byte thật, không bỏ assert.

Không thêm package, collection, Rules/index hoặc migration H7. Không commit/push,
không deploy Firebase/import production, không bật AI/billing hoặc sửa package ID.
Production vẫn cần review/ủy quyền rollout Rules/schema H2–H6 và catalog manifest
riêng; APK E2E trỏ demo không phải APK phát hành. Web/desktop chưa có nháp bền vững
hoặc lưu CSV; local không đồng bộ nhiều thiết bị, không xóa được bản sao offline
trên thiết bị khác, file CSV do người dùng quản lý. Cần QA điện thoại thật và cấu
hình release/signing còn thiếu như release-readiness.md. Đề xuất tiếp theo: review
rollout và kiểm tra máy thật; **không triển khai** trong lượt này.

Đóng kiểm tra: dart format --output=none --set-exit-if-changed trên toàn bộ76file
Dart thay đổi: 0file cần format, exit0. git diff --check với cr-at-eol phù hợp
Windows: exit0; không thay line ending hàng loạt. HEAD vẫn
1c258b37366d47ef562eed65f326e490efabae99, không stage/commit/push. Ảnh export đã xem
và lưu docs/ux/h7/export-android.png. Chỉ định tiếp theo là review/máy thật, không
chạy thêm giai đoạn hoặc deploy. Sau khi sao lưu, tắt máy bình thường theo chỉ thị
người dùng; không dùng /f để ép mất tài liệu đang mở.

Bổ sung chốt hồi quy H7 trên bố cục cuối:
- Android core H0–H6: 221s, đủ10checkpoint và H1–H6, exit0;
  D:/HealthMateMaintenanceQA/h7-core-regression-3.log. Recent vẫn3tap; U1 kiểm tra
  vùng bấm thêm bữa trong viewport đầu thật. Hai thao tác hủy hẳn trong fixture
  dùng Bỏ bản nháp để phù hợp UX H7, không bỏ các assert dữ liệu/ngày/snapshot.
- Lượt core đầu phát hiện nút nháp riêng đẩy nút thêm bữa xuống: chuyển thành icon
  cạnh Bữa ăn. Lượt sau cho thấy nút bỏ nháp trong body khó truy cập khi cuộn:
  đưa lên AppBar, chống bấm lặp. Test360/chữ2/tối phát hiện dropdown bữa tràn1.2px;
  isExpanded xử lý đúng, không giảm cỡ chữ/ẩn lỗi. Test xóa nháp lỗi rồi retry và
  xóa account lỗi server/local giữ Auth, giữ UID B đã bổ sung; full cuối454/454.
- H7 native chạy lại trên bố cục cuối:12s/32s, exit0. Đọc lại file Downloads thật
  sau lượt cuối vẫn1554byte khớp từng byte. Không dùng ảnh cũ để kết luận UI mới;
  ảnh journal-android.png lấy từ core lượt đã qua, đã kiểm tra bằng mắt.

Bản sao cuối gồm nguồn/tài liệu chưa commit và log kiểm chứng: D:\HealthMateMaintenanceQA\h0-h7-complete-20261019-191713. Hạn mức được kiểm tra trước tắt máy; không đợi xuống dưới5% vì công việc đã hoàn tất.

## 20/10/2026 — Sửa lỗi build barcode trên code GitHub hiện tại

Phạm vi: đồng bộ GitHub và sửa lỗi `await controller.dispose()` trong ảnh người
dùng gửi; không triển khai thêm giai đoạn hoặc refactor luồng tìm món.

- Đã đọc AGENTS.md, kiểm tra trạng thái/diff, Flutter, dependencies, Android và
  các caller của scanner. Working tree sạch trước khi sửa. `git fetch origin`
  và `git pull --ff-only origin main`: Already up to date, HEAD/origin/main đều
  `8702565` (không cần ghi đè hoặc merge thay đổi cục bộ).
- `pubspec.lock` và package_config cùng trỏ `mobile_scanner 4.0.1`.
  SDK cài trên máy khai báo `void MobileScannerController.dispose()`;
  dùng `await` với kết quả void gây lỗi compile, không phải lỗi Kotlin.
  BarcodeScannerService.dispose chuyển sang void và gọi controller.dispose()
  đồng bộ; giữ reset controller về null trước khi giải phóng. Caller trong
  State.dispose vốn không await nên không cần sửa màn hình.
- Analyze ban đầu có 8 error, 24 info. Ngoài scanner còn 7 lỗi truy cập
  FoodCatalogItem.per100g nullable trong test. Thêm non-null assertions cho
  các fixture vốn yêu cầu có dữ liệu dinh dưỡng; giữ nguyên expected values,
  không thay bằng 0, bỏ test hoặc đổi nullable contract của model.

File sửa:
- lib/features/food_scanner/data/barcode_scanner_service.dart
- integration_test/core_acceptance_test.dart
- test/firebase_production_qa.dart
- test/firebase_repository_integration.dart
- test/h6_fiber_test.dart
- docs/implementation-progress.md

Kiểm tra thực tế (Flutter 3.44.1, Dart 3.12.1):
- `dart format` 5 file Dart sửa: 0 file cần đổi định dạng, exit 0.
- `flutter analyze --no-pub`: **0 error, 0 warning, 23 info**, exit 1;
  chưa đạt analyze sạch. Info gồm withOpacity deprecated, avoid_print và http
  đang nằm ở dev_dependencies nhưng được import trong lib. Không tắt lint.
  Logs: build/barcode-analyze-before.log và barcode-analyze-after.log.
- `flutter test --no-pub --reporter expanded`: **406 qua, 48 lỗi**, 49s,
  exit 1. Log đầy đủ: build/barcode-flutter-test.log. Các nhóm lỗi:
  core_journal 9, core_scope 6, food_catalog 3, food_library 7,
  maintenance_regression 6, nutrition_targets 6, nutrition 1, progress 6,
  u1_ux 4. Có lỗi không tìm thấy widget/source cũ và RenderFlex overflow
  ở bố cục chữ lớn. Chưa sửa các nhóm này trong nhiệm vụ sửa build barcode.
- `flutter test --no-pub test/food_scanner_test.dart test/h6_fiber_test.dart
  --reporter expanded`: **12/12 qua**, exit 0;
  build/barcode-related-test.log. Đây là test scanner ảnh và fiber hiện có,
  không phải bằng chứng camera barcode đã được kiểm thử trên điện thoại.
  Log có fallback SQLite chưa init/USDA400 trong widget harness; test vẫn qua,
  không che những thông báo này hoặc coi đó là kiểm thử API thành công.
- `flutter build apk --debug --no-pub`: **thành công**, assembleDebug 54.1s,
  exit 0; build/barcode-build-debug.log. APK tại
  build/app/outputs/flutter-apk/app-debug.apk.
  KGP warning với các plugin Firebase/mobile_scanner vẫn còn; không chặn
  build hiện tại. Không nâng package/AGP/Kotlin để xử lý cảnh báo riêng này.

Người dùng: dừng phiên debug lỗi rồi F5 lại, chọn điện thoại Android; cần thử
quyền camera và mở/đóng barcode trên máy thật. Chưa chạy/cài APK lên điện thoại
hoặc chạy các test emulator/production QA trong lượt này. Chưa xác nhận toàn bộ
app ổn định vì full suite còn 48 lỗi. Không thêm package, không sửa Rules/index,
không deploy Firebase, không commit/push thay đổi sửa lỗi. Đề xuất công việc
tiếp theo: xem xét riêng lỗi hồi quy giao diện/tìm món và khai báo dependency
http trong bản GitHub mới; chưa triển khai.

## 20/10/2026 — Sửa lỗi bảng màu sau commit giao diện ba0557d

Phạm vi: sửa các lỗi compile trong ảnh người dùng gửi sau khi chạy bản giao diện
mới. Git sạch trước sửa, HEAD ba0557d. Đã đối chiếu design_tokens.dart,
app_colors.dart, DashboardHeroSection, AppTheme và phiên bản tokens trước đó.

- Commit giao diện xóa thang cyan trong khi theme/hero vẫn tham chiếu các màu,
  đồng thời khai báo orange500 hai lần với cùng giá trị.
- Khôi phục cyan600/400/300/200/100/50 theo đúng giá trị trước commit; giữ
  cyan500, các màu navy/blue và các component MyFitnessPal mới. Bỏ duy nhất
  khai báo orange500 bị trùng, giữ màu orange500 hiện có cho macro/semantic.
- File nguồn sửa: lib/core/theme/design_tokens.dart. Chạy dart format trên
  file này; các thay đổi spacing comment khác trong diff do formatter.
- Tài liệu cập nhật: docs/implementation-progress.md. Không đổi nghiệp vụ,
  dependency, Android Gradle/Kotlin, Firebase Rules hoặc indexes.

Kiểm tra thực tế:
- `dart format lib/core/theme/design_tokens.dart`: thành công; kiểm tra lại
  `--output=none --set-exit-if-changed` không cần thay đổi.
- `flutter --no-version-check analyze --no-pub`: **0 error, 0 warning,
  23 info**, exit 1, 6.1s. Chưa đạt analyze sạch; vẫn có các lint withOpacity,
  print, http dependency đã nêu ở báo cáo sửa barcode. Logs:
  build/palette-analyze-before.log và build/palette-analyze-after.log.
- `flutter --no-version-check test --no-pub --reporter expanded`:
  **406 qua, 48 lỗi**, exit 1, 47s; build/palette-flutter-test.log.
  Đối chiếu chính xác tên từng case lỗi với build/barcode-flutter-test.log:
  hai tập cùng 48 case, không có case lỗi thêm/bớt. Chưa sửa các lỗi giao diện,
  tìm món/fixture cũ ngoài phạm vi khôi phục tokens; không bỏ test/đổi expected.
- `flutter --no-version-check build apk --debug --no-pub`: **thành công**,
  exit 0, assembleDebug 25.1s; build/palette-build-debug.log.
  APK: build/app/outputs/flutter-apk/app-debug.apk. KGP warning vẫn xuất hiện
  nhưng không chặn bản build này. Không tuyên bố đã kiểm thử trên máy thật.

Người dùng: dừng phiên debug lỗi rồi F5 lại từ lib/main.dart và chọn điện thoại.
Cần kiểm tra giao diện sáng/tối trên máy thật. Không commit/push hoặc deploy
Firebase trong lượt sửa lỗi này. Tiếp theo đề xuất: xử lý riêng 48 case hồi quy
đã ghi nhận và 23 info; không tự mở rộng nhiệm vụ sang các thay đổi đó.

## 20/10/2026 — Hoàn thành đợt UI/UX theo ảnh MyFitnessPal

1. **Giai đoạn:** tích hợp lại trải nghiệm theo năm ảnh tham chiếu người dùng;
   không triển khai giai đoạn backend khác. Bảo toàn bản sửa tokens chưa commit
   từ lượt trước. Nền Git vẫn ba0557d, không reset/pull đè thay đổi cục bộ.
2. **Đã hoàn thành:** Hôm nay chọn ngày, header giữ khi cuộn; calo/macro thật;
   bốn thẻ bữa, ghi bữa đúng loại/ngày, dùng lại bữa trước phải xác nhận; thêm nước
   nhanh; Hôm nay–Tiến độ–Thêm và +; tab biểu đồ năng lượng/chất/cân nặng/nước/
   vận động; chi tiết báo cáo, 30/90 ngày và nút xuất CSV thật. Mục tiêu/nhiệm vụ
   có nhãn ngày đang xem. Các route Auth/Nhật ký/Quest/Chat/Cá nhân vẫn được giữ.
3. **File chính:** core/theme/app_colors.dart, design_tokens.dart;
   core/widgets/app_shell.dart, tracking_page.dart; dashboard_screen.dart,
   dashboard_goals_card.dart và ba mfp_*_card.dart; progress_screen.dart,
   progress_overview.dart; journal_screen.dart, journal_meal_entry.dart;
   meal_form_dialog.dart, meal_food_sources.dart. Test mới mfp_ui_test.dart,
   mfp_search_test.dart, fake_food_search_service.dart; cập nhật các test UI và
   fixture ProviderScope/DI. Danh sách/thiết kế: [mfp-ui-redesign.md](mfp-ui-redesign.md).
4. **Kiểm thử cuối trên code cuối:**
   - Dart format trên 25 file Dart thay đổi: kiểm tra lại 0 file cần format.
   - `flutter --no-version-check test --no-pub --reporter expanded`:
     **468/468 qua, 52s, exit 0**, build/mfp-flutter-complete.log.
     Gồm 454 test cũ và 14 test mới; không bỏ case hoặc hạ expected để che lỗi.
   - `flutter --no-version-check analyze --no-pub`: **0 error, 0 warning,
     21 info**, 7.7s, **exit 1**, build/mfp-analyze-complete.log. Chưa analyze sạch:
     withOpacity cũ, print trong unified search, http nằm ở dev_dependencies.
     Không disable lint hoặc nâng dependencies để làm xanh báo cáo.
   - `flutter --no-version-check build apk --debug --no-pub`: **thành công,
     assembleDebug 16.4s, exit 0**, build/mfp-build-complete.log. APK:
     build/app/outputs/flutter-apk/app-debug.apk. KGP warning vẫn còn.
   - 24 ảnh widget QA: docs/ux/mfp/, sáng/tối, 390×844, textScale 1.0/1.5;
     dùng font asset thật, dữ liệu tổng hợp. Đã xem các ảnh Hôm nay, Bữa ăn,
     Tiến độ, Cân nặng, Macro. Suite cũ cũng chạy layout 360/390/412, chữ đến 2.0.
   - Test tương phản >=4.5:1 cho chữ chính/phụ, nút và bốn cặp màu chỉ số;
     ngày trống/loading/error, đổi ngày khi đang tải, mục tiêu lỗi riêng biệt;
     copy không ghi trước xác nhận; tab báo cáo chỉ một lần đọc range; export
     mở đúng dialog; hai test tìm kiếm trả kết quả đảo thứ tự vẫn giữ query mới.
5. **Cần người dùng làm:** dừng debug cũ, F5 từ lib/main.dart; chọn Thêm →
   Giao diện → Tối để xem kiểu tối trong ảnh. Kiểm tra máy thật theo checklist
   trong mfp-ui-redesign.md, đặc biệt bàn phím/chữ lớn/camera/offline/xuất CSV.
6. **Vấn đề/giới hạn:** 21 info chưa xử lý; chưa QA thiết bị thật hoặc xác minh
   USDA/Open Food Facts/mã vạch online trong lượt này. Widget test dùng fake
   external search để không truy cập API thật hoặc plugin SQLite trên host.
   Chưa chạy lại security emulator vì không đổi Rules. Không đổi schema,
   indexes, pubspec/dependencies, Android config, AI hoặc billing. Không commit,
   push, deploy Firebase hoặc nhập dữ liệu production.
7. **Tiếp theo đề xuất:** nghiệm thu trên điện thoại và chỉnh chi tiết theo phản
   hồi thực tế; chưa triển khai giai đoạn mới.

Những lỗi từng ghi ở đợt sửa build (406 qua/48 lỗi) là kết quả lịch sử trước đợt
UI này; trạng thái cuối hiện tại là 468/468 qua. Đã sửa luồng duyệt món trống,
search trả chậm, ProviderScope thiếu ở fixture cũ và layout/locator do đổi giao
điện; không che những lượt thất bại. Log phát triển, gồm fixture ảnh cân nặng
thiếu createdAt/updatedAt trước khi được bổ sung, được giữ trong build/mfp-*.

### 2026-10-20 — Điều hướng 5 ô và hiển thị lại tính năng

1. **Phạm vi:** yêu cầu bổ sung sau đợt UI MyFitnessPal; chỉ sửa điều hướng và
   khả năng tìm thấy tính năng sẵn có, không triển khai giai đoạn nghiệp vụ mới.
2. **Đã hoàn thành:** thanh điện thoại có đúng 5 ô Hôm nay / Nhật ký / + / Tiến độ /
   Thêm, + ở giữa. Menu + có Quét món, thêm bữa/nước/vận động/cân nặng và lối tắt
   Mục tiêu/Nhiệm vụ, Chat. Hai mục sau cũng được đưa lên đầu màn Cá nhân (Thêm).
   Khi mở Quest/Chat, Thêm vẫn được đánh dấu đang chọn. Quét mã vạch được đưa ra
   phần chung của form bữa ăn nên không bị ẩn khi dùng MealFoodSources.
   Nút này chặn mở khi đang lưu/bỏ nháp và khi đã đủ 5 món.
3. **File chính:** lib/core/widgets/app_shell.dart,
   lib/core/config/app_feature_flags.dart,
   lib/features/dashboard/presentation/dashboard_screen.dart (đổi key icon nhật ký
   trên header để tránh trùng key tab mới),
   lib/features/profile/presentation/profile_screen.dart,
   lib/features/nutrition/presentation/meal_form_dialog.dart,
   test/navigation_features_test.dart, test/core_scope_test.dart,
   test/core_journal_test.dart, README.md và docs/mfp-ui-redesign.md.
4. **Kiểm thử thực tế:** dart format 8 file Dart của đợt này qua, kiểm tra lại 0 file
   thay đổi; flutter test --no-pub --reporter expanded qua **485/485** trong 60 giây;
   flutter analyze --no-pub còn **21 info, 0 warning, 0 error**, exit 1;
   flutter build apk --debug --no-pub qua, assembleDebug 26,3 giây. Log nằm ở
   build/navigation-full-test-final.log, build/navigation-analyze-final.log,
   build/navigation-build.log. Bộ điều hướng/core ban đầu qua 50 test.
   Một lượt full trước đó có 484 qua/1 lỗi locator sửa khẩu phần ở dưới vùng nhìn;
   test được bổ sung thao tác cuộn thật, không bỏ assertion dữ liệu; 36 test nhật ký
   sau sửa và toàn bộ suite sau cùng đều qua.
5. **Cần người dùng làm:** dừng phiên chạy cũ và F5 lại (để áp dụng cờ compile-time);
   kiểm tra camera quét ảnh/mã vạch, điều kiện AI, mạng/App Check trên máy thật.
   Mặc định Scanner/Chat hiển thị, không cần define=true; nếu launch cũ truyền
   define=false thì bỏ chúng. Vẫn hỗ trợ build core-only qua hai define=false.
6. **Giới hạn:** chưa QA camera hoặc gọi dịch vụ AI/API mã vạch thật trong lượt này.
   Việc hiện nút không chứng minh cloud/camera đã hoạt động. Kiểm tra hồ sơ 18+,
   consent trước gửi AI, quyền UID, luồng xác nhận lưu bữa vẫn được giữ. Mở tab/menu
   không tự gửi ảnh/câu hỏi. 21 info và cảnh báo Kotlin plugin còn tồn tại.
   Giữ toàn bộ thay đổi chưa commit trước đó; không sửa package/schema/Rules/index,
   không commit/push/deploy hoặc thay dữ liệu Firebase production.
7. **Tiếp theo đề xuất:** nghiệm thu 5 ô và scanner/chat trên điện thoại; chưa thực hiện
   giai đoạn mới.

### 2026-10-20 — Rút gọn thông tin ở các màn chính

1. **Phạm vi:** phản hồi UI quá nhiều thông tin; chỉ tinh gọn trình bày và cách mở
   chi tiết, không đổi nghiệp vụ hay triển khai giai đoạn mới.
2. **Đã hoàn thành:** Hôm nay ưu tiên kcal/macro/bữa/ghi nhanh. Mục tiêu dinh dưỡng,
   Goal/Quest và tổng kết tuần chuyển vào “Mục tiêu và tổng kết” mặc định đóng,
   chỉ dựng nội dung khi mở. Bỏ nút tiến độ trùng với tab, dòng UTC cố định chuyển
   vào tooltip ngày. Thẻ chỉ số nhỏ hơn, bớt nhãn lặp; thẻ bữa bớt câu rỗng và giới
   hạn tên dài (nhật ký vẫn xem đủ). Nút ⓘ mở hướng dẫn dinh dưỡng/nước/vận động/
   khẩu phần. Nước chỉ hiện ml; form bữa đếm n/5 ngắn. Cá nhân bỏ email lặp.
   Thanh dưới 5 ô và Scanner/Chat vẫn được giữ. Thông báo lỗi, thao tác lưu, xác
   nhận và consent AI/nhãn ước tính không bị ẩn. Dấu — vẫn phân biệt với 0.
3. **File:** danh sách đầy đủ theo khu vực ở docs/compact-ui.md; 2 widget chung mới
   details_disclosure.dart và information_button.dart; các màn Dashboard/Journal,
   meal_form_dialog/meal_log_section, water_log_section, Profile; thêm
   test/compact_ui_test.dart và cập nhật thao tác mở chi tiết/nhãn trong test cũ.
4. **Kiểm thử:** dart format 20 file Dart thuộc lượt này, kiểm tra lại 0 thay đổi;
   flutter test --no-pub --reporter expanded **490/490 qua**, 65 giây, exit 0;
   flutter analyze --no-pub **21 info, 0 warning/error**, exit 1 (21,7 giây);
   flutter build apk --debug --no-pub qua, assembleDebug 49,1 giây, exit 0.
   Log build/compact-full-final.log, compact-analyze.log, compact-build.log.
   Các lượt phát triển có lỗi text/locator sau đổi chữ và mở chi tiết; đã sửa cách
   thao tác/giới hạn finder, không bỏ assertion tính toán, không skip test. Lượt
   full trước cuối 489 qua/1 lỗi nhãn thiếu macro; cuối cùng giữ giải thích ngắn
   “Dấu —: chưa có số liệu, không phải 0.” và toàn bộ test qua.
5. **Cần người dùng làm:** chạy lại app, kiểm tra bố cục/cỡ chữ/sáng tối trên điện
   thoại; bấm mục mở rộng và ⓘ khi cần chi tiết. Hướng dẫn ở docs/compact-ui.md.
6. **Giới hạn:** chỉ QA widget/render và build; chưa thử tương tác thiết bị thật,
   camera hoặc gọi API AI/mã vạch. 21 info và cảnh báo Kotlin plugin còn tồn tại.
   Không đổi nguồn dữ liệu, package, schema, Rules/indexes, không commit/push/
   deploy hay cập nhật dữ liệu Firebase production; bảo toàn thay đổi trước đó.
7. **Tiếp theo đề xuất:** nghiệm thu trực quan trên điện thoại, chờ phản hồi;
   không tự triển khai thêm.

## 23/10/2026 — Giai đoạn 5: sửa quét mã vạch, mở rộng kết quả ảnh và lưu món riêng

1. **Trạng thái/phạm vi:** hoàn thành mã nguồn và kiểm thử local theo yêu cầu mới.
   Sửa lỗi barcode liên quan; chưa nghiệm thu thiết bị/cloud AI/production.
   Nền Git `63cda3f`, working tree sạch trước khi bắt đầu; không commit/push/deploy.
2. **Hành vi:** giữ đúng khẩu phần barcode, tính kcal/macros/chất xơ theo gram,
   chặn input không hợp lệ, giữ missing khác 0, phân biệt lỗi mạng/quota và không
   tìm thấy. Quét ảnh trả tên/mô tả/thành phần, kcal/macros/chất xơ trên 100 g và
   theo khẩu phần. Catalog ưu tiên, AI chỉ ước tính; unknown giữ null/chưa có dữ
   liệu. Món chưa có mở form kiểm tra và lưu vào Món của tôi, có UID guard/retry
   cùng ID. Lưu thư viện riêng rồi mới xác nhận và lưu bữa với đúng gram/snapshot.
3. **File chính:** `lib/features/food_scanner/{data,models,presentation}`;
   `food_library/presentation/library_forms.dart`; form bữa ăn và hai file
   journal meal entry/screen; `test/barcode_scanner_test.dart`,
   `test/food_scanner_test.dart`; README, database-design và scanner-update.md.
4. **Kiểm thử thực tế:**
   - Dart format các file liên quan: thành công; kiểm tra cuối ghi ở test-report.
   - `flutter --no-version-check test --no-pub --reporter expanded`:
     **501/501 qua**, 54 giây, exit 0; `build/scanner-full-test.log`.
   - `flutter --no-version-check analyze --no-pub`: **20 info, 0 warning/error**,
     exit 1, 11,1 giây; `build/scanner-analyze.log`. Không có lint mới; đã sửa
     withOpacity trong barcode screen đang chỉnh. Các info cũ còn ở glass/skeleton,
     print search và http nằm trong dev_dependencies. Không gọi analyze sạch.
   - `flutter --no-version-check build apk --debug --no-pub`: **qua**, 37,6 giây,
     exit 0; `build/scanner-build.log`; APK `build/app/outputs/flutter-apk/app-debug.apk`.
   - Firestore demo emulator: **51/51 qua**, không skip; `build/scanner-rules.log`.
     Có kiểm tra hai UID, custom_foods, macro thiếu, chất xơ và schema hiện có.
5. **Cần người dùng làm:** chạy lại app trên Android, kiểm tra camera/quyền,
   App Check debug token hợp lệ và kết quả AI thật. Kiểm tra đồng bộ Rules
   production với schema H0–H7 trước nghiệm thu lưu dữ liệu mới (chưa deploy).
6. **Giới hạn:** không có thiết bị/emulator kết nối qua ADB trong chat này.
   Không gọi AI cloud, tạo tài khoản, thay billing/App Check hoặc dữ liệu production.
   Không cam kết AI suy ra mọi vi chất/dị ứng từ ảnh. Vitamin/khoáng chất chưa
   xác minh hiển thị rõ; mô tả/thành phần quét chưa lưu thêm field trong thư viện.
   Luồng barcode nhập gram, không suy ra mật độ từ ml. Cảnh báo KGP vẫn còn.
7. **Tiếp theo đề xuất:** nghiệm thu Android và kiểm tra/đồng bộ Rules production
   trong yêu cầu riêng; không tự thực hiện giai đoạn khác.

### 2026-10-23 — Đồng bộ mã nguồn theo yêu cầu GitHub

- Phạm vi: commit/push toàn bộ thay đổi UI/test/tài liệu đang có; không làm giai đoạn mới.
- Đã fetch và kiểm tra main không lệch origin/main trước khi gom commit; giữ nguyên
  nội dung sửa trước đó, không reset/clean hoặc loại bỏ chức năng.
- Kiểm tra trước commit: format 40 file không cần sửa; toàn suite 490/490 qua,
  analyze 21 info cũ, 0 warning/error (exit 1); kiểm tra diff whitespace qua.
- Nội dung gồm UI Hôm nay/Tiến độ, thanh 5 ô, lối vào Scanner/Chat/Quest, tìm món,
  phần chi tiết thu gọn, test/fake repository, ảnh fixture và docs/chat-handoff.md.
- Danh sách/rủi ro chi tiết ở docs/mfp-ui-redesign.md, docs/compact-ui.md,
  docs/test-report.md. Không cài dependency, đổi schema/Rules/indexes hoặc deploy
  Firebase. Mã commit và xác nhận remote được cung cấp sau khi push thành công.

## 23/10/2026 — Giai đoạn 5: sửa lỗi phân tích ảnh trên điện thoại

1. **Trạng thái:** hoàn thành bản sửa scanner và xác minh một lượt ảnh thật trên
   Android; người dùng xác nhận “Đã ra kết quả món ăn”. Bảo toàn toàn bộ thay đổi
   chưa commit; không commit/push/deploy backend hoặc chuyển giai đoạn khác.
2. **Hành vi:** scanner mặc định dùng gemini-3.5-flash-lite, thinking minimal;
   ảnh tối đa cạnh 1024 px. Kiểm tra App Check, giới hạn service 40 giây, đóng
   HTTP client khi kết thúc và hiển thị lỗi theo nguyên nhân. Giữ kết quả dinh
   dưỡng/khẩu phần ước tính, catalog ưu tiên và bước xác nhận của người dùng.
3. **File chính:** firebase_food_scanner_service.dart, food_scanner_service.dart,
   food_image_picker.dart, test/scanner_runtime_test.dart, pubspec.yaml/lock,
   README, scanner-update.md và các tài liệu tiến độ/kiểm thử. Chuyển http sang
   runtime dependency cùng phiên bản; không nâng package hay đổi chatbot.
4. **Kiểm thử thực tế:** toàn suite **504/504 qua** (91 giây); analyze **18 info,
   0 warning/error** (exit 1, 7,6 giây); debug APK build qua (57,1 giây). Format
   4 file Dart của bản sửa: 0 thay đổi. Test mới kiểm tra cấu hình/schema,
   phân loại lỗi và HTTP transport/close; parser kiểm tra response cloud thật.
   Không chạy lại rules emulator vì không thay Rules/schema (lượt trước 51/51).
5. **Thiết bị:** cập nhật bằng adb install -r -t thành công, giữ dữ liệu ứng dụng.
   App Check 44 ms, HTTP 200 tại 6743 ms, parse thành công tại 6767 ms; người dùng
   xác nhận đã thấy kết quả. Bằng chứng và giới hạn ở scanner-update.md.
6. **Giới hạn/cấu hình:** chưa xác định được mã lỗi gốc của lượt SDK cũ sau 8,868
   giây; các probe model cũ timeout 30 giây, model mới trả kết quả. Một lượt điện
   thoại thành công không phải cam kết tốc độ hay độ chính xác dinh dưỡng.
   Camera capture và lưu production chưa nghiệm thu lại; Rules H0–H7 production
   vẫn cần kiểm tra riêng. Không thay billing, enforcement App Check hoặc ghi
   dữ liệu production. Analyze còn info cũ và build còn cảnh báo Kotlin Gradle.
7. **Tiếp theo đề xuất:** nghiệm thu camera và lưu món/nhật ký trên Android khi
   được yêu cầu; không tự thực hiện trong lượt sửa phân tích ảnh này.

## 23/10/2026 — Kiểm tra chênh lệch kết quả hai món theo yêu cầu

- Phạm vi Giai đoạn 5: chỉ chẩn đoán kết quả, chưa sửa code hoặc cài lại APK.
- Xác nhận lỗi ghép Cơm trắng chín cho cả đĩa cơm tấm 450 g; lỗi nằm ở substring
  matching, tự chọn phần tử đầu và ưu tiên số catalog dù không cùng phạm vi món.
- Mẫu bít tết quy đổi và hiển thị đúng số AI; chưa có dữ liệu đo để phân xử AI
  nào chính xác. Kết quả app khác không được dùng làm chuẩn dinh dưỡng mặc định.
- Hai widget probe tái hiện qua (2/2); chi tiết ở scanner-update.md/test-report.md.
- Chỉ bổ sung tài liệu, giữ mọi thay đổi chưa commit; không push/deploy.
- Tiếp theo đề xuất: sửa chọn nguồn cho món nhiều thành phần; chưa thực hiện.

## 23/10/2026 — Giai đoạn 5: sửa ghép nguồn dinh dưỡng cho món nhiều thành phần

1. **Trạng thái:** hoàn thành bản sửa mã nguồn và kiểm thử; APK debug đã build.
   Chưa cài lên điện thoại vì cả hai lần `adb devices` đều không có thiết bị.
   Giữ toàn bộ thay đổi trước đó; không commit/push/deploy hoặc chuyển giai đoạn.
2. **Hành vi:** tên/tên tương đương cả món phải khớp đầy đủ; chỉ một kết quả mới
   được tự chọn. SearchTerms, substring và tên nguyên liệu không còn chọn nguồn
   cả đĩa. Nhiều kết quả cần chọn rõ; đổi tên xóa lựa chọn cũ. Chưa khớp giữ
   ước tính AI toàn món; có thể lưu qua form kiểm tra rồi ghi bữa đúng gram.
   Nêu rõ món/nguồn và có nút dùng lại ước tính AI thay cho catalog. Prompt nhắc
   xét toàn đĩa và không cộng dầu hai lần; không đổi model/API/schema/provider.
3. **File chính:** models/food_scan_catalog_matcher.dart mới;
   presentation/food_scanner_dialog.dart và data/firebase_food_scanner_service.dart;
   test/food_scan_catalog_matcher_test.dart mới, test/food_scanner_test.dart;
   README, scanner-update.md và tài liệu tiến độ/kiểm thử.
4. **Kiểm thử:** nhóm scanner **25/25 qua** (13 giây); full suite **512/512 qua**
   (68 giây); analyze cuối **18 info cũ, 0 warning/error**, exit 1 (7,1 giây);
   build APK debug **qua**, assembleDebug 28,4 giây. Format 5 file: 0 thay đổi;
   git diff whitespace check qua. Log chi tiết ở test-report.md.
5. **Cần người dùng làm:** kết nối lại điện thoại USB để cập nhật APK giữ dữ
   liệu và nghiệm thu ảnh thật. Chưa xác nhận bản sửa này chạy trên điện thoại.
6. **Giới hạn:** không đo độ chính xác dinh dưỡng, không cố khớp số Calz/Foodvisor.
   Khớp chặt có thể không tìm thấy món cùng nghĩa nhưng khác tên; vẫn có đường
   tìm rộng/nhập tay. Kết quả chưa tách khối lượng từng nguyên liệu. Chưa gọi lại
   AI cloud trong lượt này. Không đổi dependencies, Rules, schema, billing hoặc
   App Check; cảnh báo Kotlin Gradle còn. Không sửa nhật ký/món đã lưu trước đó.
7. **Tiếp theo đề xuất:** nghiệm thu hai ảnh trên điện thoại và luồng lưu món;
   chưa tự triển khai giai đoạn hay tính năng tiếp theo.

## 23/10/2026 — Giai đoạn 5: hợp nhất thêm bữa ăn, quét ảnh và yêu thích

1. **Trạng thái:** hoàn thành mã nguồn UI, kiểm thử và APK debug theo ảnh tham
   khảo. Cùng một MealFormDialog có Nhập tay/Ảnh/Yêu thích; chưa cài/nghiệm thu
   camera thật vì ADB không có thiết bị. Bảo toàn mọi thay đổi chưa commit.
2. **Hành vi:** nhập tay và lối tắt Quét món mở hai tab của cùng bản nháp. Camera
   preview, nút chụp/thư viện và mã vạch; gửi ảnh chỉ sau consent + Phân tích.
   Kết quả xác nhận hoặc món yêu thích được thêm vào bữa đang có, không mở bữa
   khác. Giữ ngày/loại bữa, giới hạn 5 món, snapshot, UID guard, lưu chờ máy chủ
   và nháp mã hóa. Camera đóng khi đổi tab/xuống nền/chuyển barcode; lỗi quyền
   vẫn có nhập tay/chọn ảnh. Giữ bản sửa nguồn dinh dưỡng cho cả món.
3. **File chính:** food_camera_service.dart, food_camera_view.dart mới;
   meal_form_dialog.dart, food_scanner_dialog.dart, barcode_scanner_screen.dart,
   journal_meal_entry.dart/journal_screen.dart, meal_food_sources.dart, app_shell;
   pubspec.yaml/lock, AndroidManifest.xml; fake camera/test unified meal mới và
   các test scanner/nutrition/navigation/layout; docs/unified-meal-entry.md.
4. **Kiểm thử thực tế:** test mới **6/6 qua**, nhóm hồi quy **70/70** và **18/18**
   qua; full suite cuối **518/518 qua** (67 giây); analyze **18 info cũ, 0
   warning/error**, exit 1 (8,7 giây); APK debug **qua**, assembleDebug 29,9 giây.
   Format 18 file 0 thay đổi; whitespace check qua. AAPT xác nhận APK có CAMERA,
   không RECORD_AUDIO/WRITE_EXTERNAL_STORAGE. Log ở test-report.md.
5. **Cần người dùng làm:** kết nối Android qua USB để cập nhật APK giữ dữ liệu,
   thử quyền camera/ảnh, chụp và quay lại sau xuống nền, barcode rồi lưu cùng bữa.
6. **Giới hạn:** thêm camera chính thức 0.12.0+2 và 5 dependency chuyển tiếp từ
   cache, không nâng package có sẵn. enableAudio=false; loại các quyền video/audio
   và public storage plugin khai báo thừa. Native preview/capture/barcode chưa
   nghiệm thu trên điện thoại. Test dùng fake adapters; screenshot widget camera
   đen là fake session, không giả là ảnh thiết bị. Không đổi AI model/provider,
   backend/schema/Rules/App Check/billing; không push/deploy. KGP warning còn.
7. **Tiếp theo đề xuất:** nghiệm thu Android cho chính luồng hợp nhất này;
   không tự chuyển giai đoạn khác. Cách dùng/nguồn tham khảo ở unified-meal-entry.md.
# Web quản trị — 23/10/2026

1. **Giai đoạn:** mở rộng admin do người dùng yêu cầu, bản local hoàn tất;
   không tự chuyển sang deploy production.
2. **Đã hoàn thành:** web HTML/CSS/JavaScript + Firebase Web SDK, đăng nhập và
   role, CRUD catalog qua thêm/sửa/ẩn, khóa/mở quyền HealthMate qua Firestore,
   config chatbot/scanner/maintenance, nhật ký quản trị nguyên tử. Phân trang
   25, lỗi/empty/loading, phát hiện xung đột timestamp, form có lý do xác nhận.
   Admin không đọc nhật ký sức khỏe. Mobile có remote gate, đồng bộ directory
   tối thiểu và lọc catalog ẩn; cờ rollout mặc định false.
3. **File chính:** `admin-web/` (UI, Firebase adapter, validation, server,
   seed demo, README, tests/font license); `firebase.admin-emulators.json`;
   `firestore.rules`, `rules-tests/admin.rules.test.cjs`, package/test host;
   `lib/core/config/admin_runtime*.dart`, `admin_access_gate.dart`, app,
   AI/feature policy, nutrition/account-data repositories;
   `test/admin_runtime_test.dart`; README/database-design/test-report.
4. **Kiểm thử:** JavaScript syntax qua, 5/5 web unit; Rules **59/59** qua trên
   emulator (8 mới +51 hồi quy); Flutter runtime **5/5**, full **523/523** qua
   (78 giây); analyze **18 info cũ, không warning/error** (35,9 giây, exit 1);
   APK debug build qua (27,7 giây). Format các file Dart mới/sửa qua; diff
   whitespace qua. Thử UI trình duyệt có dữ liệu Firebase Emulator thật: tạo,
   sửa/ẩn món, khóa/mở tài khoản, tắt/bật lại scanner, audit và user không role.
5. **Cần cấu hình:** chưa chọn UID admin thật, chưa cấu hình public Web App/
   domain/App Check, chưa deploy Rules/hosting, chưa bật cờ rollout mobile.
   Các bước trong `admin-web/README.md`; không tự cấp role hoặc nâng billing.
6. **Giới hạn:** account lock không disable Auth/revoke token/chặn AI API ở
   server; directory chỉ gồm tài khoản đã đồng bộ. Bản bật cờ cần server xác
   minh, hạn chế truy cập offline. KGP warning và 18 analyze info cũ còn.
   Browser/CDN và emulator kiểm thử, chưa nghiệm thu production/điện thoại
   cho phần quản trị. Không commit/push/deploy, giữ mọi thay đổi trước lượt.
7. **Tiếp theo đề xuất:** cấu hình và nghiệm thu admin trên Firebase thật sau
   yêu cầu riêng; không thực hiện trong lượt này.
# Hoàn thiện auth mobile — 24/10/2026

1. **Giai đoạn:** mở rộng Giai đoạn 2 — Google, email verification và password
   recovery. Mã app/local QA hoàn tất; nghiệm thu Google/email production còn
   chờ cấu hình và thiết bị. Người dùng bỏ Facebook và tạm gác web admin.
2. **Đã làm:** Google native qua SDK + Firebase, xử lý cancel/config/provider
   collision, khóa bấm trùng; email verification gate trước dữ liệu/onboarding,
   gửi lại 60s, kiểm tra/resume reload user + token; forgot-password dialog có
   xác nhận, lỗi, cooldown, link Firebase tiếng Việt; mật khẩu mới tối thiểu 8,
   đăng nhập vẫn nhận mật khẩu cũ; Google-only ẩn đổi password và reauth bằng
   Google khi xóa. Rules yêu cầu verified claim cho owner health data.
3. **File chính:** auth repository/models/providers/screens, Google identity
   service, route verify-email, profile/bootstrap/reauth, AI gate; Rules và
   tests, `firebase.auth-emulators.json`; `google_sign_in` 7.2.0 + 5 dependency
   chuyển tiếp (không nâng package cũ), logo Google nguồn chính thức;
   `test/auth_completion_test.dart`, verified fixtures và helper C6/H7;
   `docs/authentication-flow.md`, README/schema/test report, snapshot auth.
4. **Kiểm thử:** full Flutter **534/534 qua** (82s); nhóm auth cuối sau chỉnh
   copy/logo **35/35 qua**, gồm 11 test mới và snapshot font thật; Rules
   **60/60 qua** (18s); Auth Emulator email E2E **1/1 qua** (1,3s); APK debug
   build qua (101,4s khi thêm plugin, cuối 10,8s). Analyze 18 info cũ, không
   warning/error; format và whitespace check qua. Chi tiết ở test-report.
5. **Cần cấu hình:** Google IDP thật chưa có (GET trả404), danh sách IDP rỗng,
   Email/Password bật. Cần bật Google, thêm SHA debug/release phù hợp, tải JSON
   có Web OAuth client. Hướng dẫn có SHA thực của máy. Kiểm tra email templates,
   triển khai Rules sau rà soát toàn bộ diff và nghiệm thu bằng email thật.
6. **Giới hạn:** không có ADB device nên chưa cài APK/chạy native C6/H7;
   chưa đăng nhập Google thật hoặc chứng minh email tới inbox production.
   Emulator chứng minh email action/link/token/password, không giao email thật.
   Không tự nâng billing/cấp role/deploy Rules/commit/push; giữ thay đổi cũ.
   Không tiếp tục tính năng web admin. Cờ rollout admin mặc định vẫn false.
7. **Tiếp theo:** cấu hình Google và nghiệm thu cùng luồng auth trên điện thoại;
   chưa thực hiện production/config khi thiếu yêu cầu và public OAuth config.

## Tiếp tục cấu hình Google — 24/10/2026 (chờ email hỗ trợ)

- Người dùng đã yêu cầu bật Google. Đã thêm SHA-1 debug vào đúng Android app
  qua Firebase CLI; đọc lại xác nhận SHA-1 và SHA-256 đã có, không xóa hash cũ.
- Firebase Console đã chuẩn bị tên HealthMate. Chưa lưu provider: chờ xác nhận
  email hỗ trợ sẽ hiển thị công khai cho người đăng nhập, theo quy tắc an toàn
  điều khiển trình duyệt. Chưa thay đổi email/người dùng hay bật Google.
- Tải thử SDK config vào build/: đúng project/package/app ID, OAuth client vẫn
  rỗng. Chưa thay android/app/google-services.json hoặc build lại APK. Không có
  thiết bị ADB; chưa kiểm thử Google thật. Không đổi Rules/billing, không deploy.
- Bước còn lại: xác nhận email, lưu Google provider, tải/cập nhật JSON có OAuth
  client, build APK và nghiệm thu trên điện thoại. Web admin vẫn tạm gác.

## Google production đã bật — 24/10/2026 (thay trạng thái chờ phía trên)

- Người dùng đã xác nhận email hỗ trợ. Lưu Google trên Firebase thành công,
  tên công khai HealthMate; Console Enabled và đọc API200 enabled=true có
  client ID. Email/Password giữ bật, Spark không đổi.
- File chính: `android/app/google-services.json` cập nhật từ CLI, Android client
  đúng SHA-1 debug và Web client_type3. Chỉ OAuth client thay đổi, cấu hình
  Firebase khác giữ nguyên; không đưa client secret vào repo/app. README,
  authentication-flow, handoff/test-report cập nhật trạng thái thực.
- Build APK debug qua11,1s, resource default_web_client_id khớp Web client từ
  JSON; diff whitespace qua. Không sửa Dart nên không chạy lại format/analyze/
  unit suite đã qua ở lượt auth. KGP warning cũ vẫn có.
- Không có ADB device: chưa cài APK hoặc thử Google account thật; chưa chứng
  minh thư xác minh/reset tới inbox. Rules mới chưa deploy, admin vẫn tạm gác.
- Tiếp theo đề xuất: cài APK mới và nghiệm thu auth trên điện thoại. Không tự
  chuyển giai đoạn, deploy Rules/hosting, đổi billing hoặc commit/push.

# Mở rộng chatbot — 25/10/2026

1. **Giai đoạn:** mở rộng Giai đoạn9 theo yêu cầu xây chatbot. Giữ Gemini
   Developer API miễn phí, không backend/package mới, không tiếp tục web admin.
2. **Hành vi:** nhập tiếng Việt có/không dấu; nhật ký một ngày/ngày cụ thể/
   hôm nay/hôm qua/hôm kia/tuần này/tuần trước/7ngày; tổng kcal/macro/fiber,
   nước/phút, cân nặng có ngày đo, lượng còn/vượt so target thật theo từng ngày.
   Câu nối tiếp giữ khoảng ngày, thiếu dữ liệu không thành0 hoặc mục tiêu giả.
   Câu hỏi mục tiêu nước/cân nặng/vận động được giải thích phạm vi, không trả
   nhầm ngân sách kcal. Không tự ghi/sửa/xóa nhật ký hoặc kê chế độ ăn.
3. **AI:**10chủ đề dinh dưỡng/thói quen. Câu tự nhập được map ở app sang enum;
   sau đồng ý chỉ prompt chủ đề cố định được gửi tới Gemini. Không gửi dữ liệu
   cá nhân/history. Model mặc định gemini-3.5-flash-lite, thinking minimal,
  2048output tokens; tài liệu model/điều khoản đã kiểm tra25/10. Chưa là LLM
   tự do có ngữ cảnh sức khỏe hoặc Meal Planner. Giữ giới hạn20lượt/phiên.
4. **File chính:** thêm domain/chat_request.dart, personal_chat_context.dart;
   sửa chat models/KnowledgePrompt/FirebaseKnowledgeService/controller/UI;
   thêm14test trong chatbot_personal_test.dart, cập nhật test navigation theo
   nhãn mới và vẫn kiểm tra composer/route. README/chatbot/schema/handoff/test
   report và4snapshot font thật trong docs/ux/chatbot cập nhật.
5. **Kiểm thử:** nhóm chat32/32qua; full cuối548/548qua (73s), vòng
   chốt có log build/chatbot-personal-accepted-tests.log. Format12file0thay đổi;
   analyze cuối18info cũ,0warning/error,48s exit1; APK cuối build25,7s,
   build/chatbot-personal-build-final.log, vẫn KGP warning cũ. Whitespace qua.
   Không đổi Rules/schema/index nên không chạy lại Rules emulator ở lượt này.
6. **Giới hạn/cần nghiệm thu:** không có ADB device. Chưa cài APK hoặc thử
   Gemini API live. Snapshot và tests dùng repositories fake, không chứng minh
   cloud end-to-end. Cần kiểm tra Android qua Thêm→Chat, dữ liệu thật, target,
   Gemini/quota/mạng/stop/history/đổi UID. Rules verified/schema mới và lỗi USDA
   từ audit chưa sửa/deploy trong lượt này, giữ mọi thay đổi cũ.
7. **Tiếp theo đề xuất:** nghiệm thu chatbot trên Android; chưa thực hiện gợi
   ý thực đơn, billing, deploy Rules/hosting/admin, commit hoặc push.

## 25/10/2026 — Giai đoạn 9, đánh giá API chatbot miễn phí

- Người dùng yêu cầu linh hoạt như MyFitnessPal, giữ miễn phí và làm rõ muốn
  gọi API cloud; không cần tải model vào điện thoại. Chỉ nghiên cứu, chưa tích hợp.
- Đã kiểm tra Git/code/dependencies, giữ nguyên các thay đổi chưa commit. Thêm
  docs/chatbot-free-evaluation.md, cập nhật quyết định trong chatbot-flexible-plan.md.
- Ưu tiên thử Workers AI/Qwen3-30B-A3B-FP8, dự phòng Groq Free; quota, giữ key,
  dữ liệu và proxy ngoài Firebase được ghi rõ. Chưa chốt thay đổi kiến trúc.
- Có bộ 20 tình huống tổng hợp dự kiến. Chưa gọi inference, tạo tài khoản,
  gửi dữ liệu cá nhân hay đo tiếng Việt/độ trễ. ADB không có thiết bị.
- Kiểm tra tài liệu và whitespace; không chạy lại Flutter format/analyze/test/
  build do chỉ sửa Markdown. Không coi kết quả test app trước là benchmark AI.
- Tiếp theo đề xuất: thử API trên dữ liệu tổng hợp trước khi quyết định tích hợp;
  không tự bật billing, deploy, sửa admin/scanner, commit hoặc push.

## 25/10/2026 — Giai đoạn 9, triển khai code chatbot API miễn phí

1. **Trạng thái:** người dùng yêu cầu làm phương án Cloudflare API sau đánh giá.
   Code app/Worker và QA local hoàn tất; **chưa rollout**, chờ tài khoản Cloudflare
   Free. Người dùng nói chưa có tài khoản và sẽ tạo; `wrangler whoami` chưa đăng nhập.
2. **Hành vi đã triển khai:** khi cấu hình URL thật, nhập câu hỏi tự do và tối đa
   3 lượt chat gần nhất cho Qwen lập kế hoạch; app đọc tối đa 3 nguồn hợp lệ, tính
   số liệu qua repositories rồi AI trả SSE. Có consent, tra cứu không gửi AI,
   stop/cancel transport, UID guards, retry lưu cùng ID và không lưu stream dở.
   Không cấu hình URL thì báo rõ chưa kết nối và giữ luồng hiện có.
3. **File chính:** chat-api/src/{auth,index,protocol}.mjs, wrangler.jsonc và README;
   Flutter assistant_request, ChatDataReader, ChatAssistant/CloudflareChatAssistant,
   assistant_providers; sửa controller/UI chat, test helper và chatbot_api_test.dart.
   Không đổi schema/Rules/index/Firebase billing, scanner/USDA hoặc admin.
4. **Kiểm thử thực tế:** Flutter full cuối **569/569 qua, 56s**;
   build/chat-api-full-tests-final.log. Nhóm chat trước thêm layout **51/51**, 6s;
   capture layout **2/2**, 2s, 4 PNG font thật 360px/100–200%, đã xem trực quan.
   Analyze cuối **18 info cũ, 0 warning/error**, 6,8s, exit1. Format 17 file không
   thay đổi; whitespace qua. APK debug cuối build **10,9s**, exit0, còn KGP warning
   cũ; build/chat-api-android-build-final.log. APK chưa đóng URL thật/chưa cài máy.
5. **Worker:** **18/18 test qua**, có JWT RSA ký/verify thật với key test; kiểm
   tra project/verified/expiry/App Check app/UID/schema/body/rate/stream. AI binding
   dùng fake, không coi là model benchmark. Node syntax check, npm audit **0**,
   Wrangler dry-run bundle **48,14 KiB** qua; logs chat-api-worker-tests/build.log.
   Pin jose 6.2.13, Wrangler 4.152.0; override undici 7.30.1 sửa dev dependency audit.
6. **Còn chờ:** chủ dự án hoàn tất Cloudflare Free, đăng nhập CLI, xác nhận account,
   triển khai Worker, build URL thật rồi nghiệm thu Qwen/JSON/SSE/JWKS/CPU/quota và
   tiếng Việt/latency trên Android. ADB không có thiết bị; chưa có API call live,
   chưa gửi dữ liệu thật cho provider. Không tuyên bố chất lượng ngang MyFitnessPal.
7. **Tiếp theo đề xuất:** kết nối và nghiệm thu API đã chuẩn bị sau khi tài khoản
   sẵn sàng, vẫn trong giai đoạn 9. Không chuyển giai đoạn khác hoặc tự nâng Paid,
   deploy Firebase/admin, commit hay push. Setup cụ thể: chat-api/README.md.

## 27/10/2026 — UI theo Figma / Reference v2

1. **Giai đoạn:** hoàn tất phạm vi UI system/polish được người dùng yêu cầu;
   dùng Figma và HealthMate UI Kit v2 local. Không chuyển giai đoạn nghiệp vụ.
2. **Đã hoàn thành:** theme gradient sáng/tối, card/input/typography thống nhất;
   bố cục Hôm nay, Nhật ký, Cá nhân, Tiến độ và hub Thói quen. Thanh dưới có
   dấu + giữa; avatar mở hồ sơ. Tất cả lối tắt dùng luồng thật đang có; Nhật ký
   giữ ngày lịch sử, ghi nhanh shell dùng hôm nay. Giữ CRUD/xác nhận/AI hiện có.
3. **File chính:** core theme/widgets/router, dashboard và kcal/macro, journal
   summary grid, personal overview, wellness hub, progress line chart;
   assets/design, pubspec asset entry và test/reference_ui_test.dart. Chi tiết
   và ảnh: [figma-v2-implementation.md](figma-v2-implementation.md).
4. **Kiểm thử:** format 36 file Dart tạo/sửa 0 thay đổi; analyze No issues found;
   full Flutter test **654/654 qua (72s)**; build APK debug thành công (Gradle
   19,7s); git diff --check qua. Logs `build/figma-v2-*`. Xem trực quan 10 ảnh
   font thật sáng/tối; kiểm thử có màn 320–412px và text scale tới 200%.
5. **Cần người dùng làm:** cài `build/releases/healthmate-figma-v2-debug.apk`
   và nghiệm thu trên Android thật. Không cần cấu hình Firebase mới cho lượt UI.
6. **Vấn đề còn lại:** không có ADB device; chưa chứng minh cloud/camera/cảm biến
   end-to-end. APK còn cảnh báo KGP plugin cũ với Flutter tương lai. BeVietnamPro
   được giữ thay Arial trong kit; màu chữ/nút điều chỉnh tương phản. Không đổi
   package/backend/rules/billing, không deploy/commit/push; giữ handoff untracked.
7. **Tiếp theo đề xuất:** nghiệm thu UI trên Android thật; chưa tự thực hiện.


## 27/10/2026 — Làm lại UI sau phản hồi chưa giống Figma

1. **Giai đoạn/trạng thái:** hoàn tất sửa UI system/polish được yêu cầu trong phạm vi Giai đoạn 1 trên app hiện có; không chuyển giai đoạn nghiệp vụ. Báo cáo/ảnh/APK ở mục này thay kết quả UI v2 trước đó.
2. **Đã hoàn thành:** đối chiếu trực tiếp T01 trên Figma và geometry của kit; thay đúng ngọn lửa, 64 nét vòng macro, tỷ lệ kcal/footer/lối tắt; Nhật ký ba phần/lưới bữa/nút xác nhận; Hồ sơ hàng danh tính/analytics/chỉ số; Thói quen lưới/lối tắt; Tiến độ đổi hierarchy/chiều cao biểu đồ/tổng kết; thanh dưới sát mép và thích nghi chữ lớn. Giữ dữ liệu thật và luồng xác nhận/CRUD.
3. **File chính:** dashboard kcal/macro, core widgets/theme, journal, macro_distribution, personal_overview, wellness_hub, progress; test/helper; 12 art assets, hai script xuất/so ảnh. Chi tiết: [figma-v2-implementation.md](figma-v2-implementation.md).
4. **Kiểm thử cuối:** format 50 file 0 thay đổi; analyze No issues found (36,3s); full **655/655 qua (78s)**; APK debug build thành công (23,1s); node syntax và whitespace qua. Logs `build/figma-v2/redo-*-accepted.log`. Có ảnh so năm màn cùng kích thước; dữ liệu populated chỉ trong test.
5. **Cần người dùng làm:** cài `build/releases/healthmate-figma-redo-debug.apk` và nghiệm thu trên Android; không cần Firebase config mới cho lượt UI.
6. **Vấn đề/giới hạn:** không có ADB device, chưa chứng minh live end-to-end. Font dự phòng BeVietnamPro, icon Material và màu chữ tương phản có khác thiết kế. Build còn KGP warning cũ. Không đổi backend/schema/rules/billing/package, không deploy/commit/push. Snapshot mfp lịch sử giữ nguyên, ảnh mới đặt trong `docs/ux/reference-v2/`.
7. **Tiếp theo đề xuất:** nghiệm thu giao diện trên Android thật; chưa triển khai giai đoạn khác.

## 27/10/2026 — Giai đoạn 4, mở rộng catalog và lọc lựa chọn ăn

1. **Trạng thái:** hoàn tất phạm vi người dùng yêu cầu: kiểm đếm/đối chiếu quy mô,
   tăng danh mục và áp dụng lựa chọn ăn theo người. Không thực hiện giai đoạn mới.
2. **Đã hoàn thành:** 162 → **7.606 mục**; 58 → **7.169 mục có khẩu phần**. Thêm
   7.444 mục USDA có provenance/core macros, giữ món Việt. Chay/thuần chay trong
   hồ sơ được dùng làm bộ lọc ban đầu của form Nhật ký và lọc gợi ý thực đơn Việt.
   Mục tiêu tăng/giảm/giữ cân tiếp tục dùng cơ chế chỉ tiêu kcal hiện có. Chưa rõ
   thành phần bị ẩn khi lọc chay; không thay nhật ký đã lưu.
3. **File chính:** asset `usda-sr-legacy.json`; importer/test Python và manifest;
   bundled loader, catalog reader/model/search, `food_diet.dart`, meal form,
   journal entry và planner; pubspec asset; `catalog_expansion_test.dart`.
   Nguồn/cách dùng/giới hạn: [catalog-expansion-and-diets.md](catalog-expansion-and-diets.md).
4. **Kiểm thử thật:** format 12 file Dart (1 file test được định dạng); analyze
   **No issues found (7,3s)**; full Flutter **663/663 qua (74s)**; importer Python
   **5/5**, bộ nguồn Việt Node **10/10**; runtime config build **7/7**. APK debug
   build thành công, Gradle **17,6s**. Kiểm tra ZIP xác nhận cả hai asset trong
   APK trùng byte với source và tổng 7.606 mục. Logs: `build/catalog-expansion/`.
5. **Cần người dùng làm:** cài `build/releases/healthmate-food-catalog-debug.apk`
   để nghiệm thu trên Android thật. Không cần Firebase setup/deploy mới cho
   phần catalog; APK giữ cấu hình runtime admin. SHA256/size có manifest cạnh APK.
6. **Vấn đề/giới hạn:** vẫn nhỏ hơn quy mô MyFitnessPal/Calz công bố; USDA là bản
   lịch sử 2018, nhiều tên/khẩu phần còn tiếng Anh. Phân loại chỉ sàng lọc theo
   mô tả, không chứng nhận chay; chưa lọc dị ứng hoặc tối ưu thực đơn theo kcal.
   Các lối món cá nhân/lịch sử chưa được phân loại đầy đủ. Admin Firestore không
   hiện toàn bộ asset offline. ADB không có thiết bị; chưa đo tốc độ trên Android
   thật hoặc kiểm production end-to-end. Còn warning KGP plugin cũ khi build.
7. **Tiếp theo đề xuất:** nghiệm thu danh mục và chế độ ăn trên Android thật.
   Không tự triển khai thêm, ghi catalog cloud, push GitHub hoặc tắt laptop.

## 27/10/2026 — Giai đoạn 4, sửa các điểm chưa ổn trong luồng người dùng

1. **Trạng thái:** hoàn tất sửa code và kiểm thử luồng dinh dưỡng theo yêu cầu
   làm nốt các điểm chưa ổn; tiếp tục cùng Giai đoạn 4. Không triển khai backlog
   báo cáo/in/ảnh trong `docs/requirements/` hoặc chuyển giai đoạn khác.
2. **Đã sửa:** phát hiện preference mới chỉ được đưa vào constructor trong luồng
   chính nhưng nhánh `sourcesBuilder` chưa dùng bộ lọc. Nay màn Nhập tay thực sự
   lọc danh mục/duyệt/tìm/kết quả ngoài, đổi chế độ ăn hủy response cũ. Bộ lọc có
   trong Yêu thích; catalog favorite ngoài chế độ bị khóa nút thêm, vẫn bỏ lưu
   được. Sửa kế hoạch và xác nhận đã ăn nhận chế độ ăn từ hồ sơ. Giữ nguyên món
   đã chọn/lịch sử khi đổi bộ lọc. Món riêng/lịch sử chưa có phân loại được nhắc
   kiểm tra thành phần, không giả được chứng nhận chay.
3. **Khả năng phục hồi:** lỗi tìm thêm không làm mất kết quả local; hiện lời nhắn
   tiếng Việt/thử lại, không lộ raw exception. Catalog đổi trong khi tìm cập nhật
   truy vấn hiện tại. Asset mở rộng thiếu/hỏng vẫn giữ 162 mục gốc, phân loại
   thiếu là unknown. Không thay dữ liệu riêng tư hoặc ghi production.
4. **File chính:** `food_diet_filter.dart`, `meal_form_dialog.dart`,
   `meal_food_sources.dart`, `journal_meal_entry.dart`, `wellness_screen.dart`,
   bundled loader, `catalog_expansion_test.dart` và callback test core journal.
   Docs nguồn/cách dùng: [catalog-expansion-and-diets.md](catalog-expansion-and-diets.md).
5. **Kiểm thử thực tế:** format cuối 15 file Dart 0 thay đổi; analyze No issues
   found (7,1s); full Flutter cuối **668/668 qua (68s)**; nhóm catalog **12/12**.
   Log ở `build/nutrition-polish/`. Test cũ chỉ kiểm constructor được mở rộng
   thành thao tác thật trên form chính; không coi kết quả 663 trước là bằng chứng
   nhánh `sourcesBuilder` đã lọc đúng. APK/kết quả build ghi trong test-report.
6. **Cần người dùng làm / giới hạn:** cài APK mới và thử trên Android thật; ADB
   không có thiết bị. Không cần Firebase setup mới. Vẫn còn tên USDA tiếng Anh,
   chưa lọc dị ứng tự động/chứng nhận chay hoặc cân thực đơn khớp kcal; không tự
   đoán thành phần để lấp dữ liệu. Không khẳng định toàn bộ app đã nghiệm thu UAT.
7. **Tiếp theo đề xuất:** nghiệm thu luồng dinh dưỡng trên Android thật; chỉ đề
   xuất, không chuyển giai đoạn hoặc tự tắt laptop.

APK cuối của lượt sửa: `build/releases/healthmate-nutrition-polish-debug.apk`.
Build thành công (Gradle16,7s), runtime config7/7; ZIP xác nhận2asset/tổng7.606
mục; SHA256/size có manifest cạnh APK. Còn warning KGP cũ; chưa có thiết bị ADB.

## 27/10/2026 — Giai đoạn 4, hoàn thiện ba giới hạn theo yêu cầu

1. **Trạng thái:** hoàn tất triển khai và kiểm thử phần thực phẩm cần tránh,
   gợi ý theo kcal, Việt hóa USDA trong cùng phạm vi dinh dưỡng.
2. **Người dùng làm được:** khai báo thực phẩm cần tránh để tự lọc danh mục/
   tìm kiếm/gợi ý, kể cả món chưa rõ thành phần. Kế hoạch chặn lưu snapshot cần
   tránh/chưa rõ; nhật ký cho phép ghi bữa đã ăn sau xác nhận rõ. Không mở form
   với bộ lọc rỗng nếu chưa tải được hồ sơ. Thực đơn dùng mục tiêu kcal có hiệu
   lực từng ngày, giữ bữa đã lên kế hoạch, điều chỉnh gram có giới hạn và xem
   tổng/mức lệch trước lưu; không tự ghi nhật ký. Danh mục có tên Việt rút gọn,
   xem/tìm tên gốc tiếng Anh, giữ dinh dưỡng/portion/snapshot cũ.
3. **File chính:** `food_avoidance.dart`, `meal_plan_suggestion.dart`,
   `meal_form_dialog.dart`, `meal_food_sources.dart`, `food_portion_dialog.dart`,
   `journal_meal_entry.dart`, `wellness_screen.dart`, food model/reader/cache,
   bundled loader, `usda_vietnamese.py`, importer/asset/manifest và tests/docs.
4. **Kiểm thử:** full678/678; hồi quy cuối33/33; Python7/7; analyze sạch.
   Format21file thay đổi sạch, 4file cũ ngoài phạm vi cần format; `dart format .`
   vướng cache Chrome không tồn tại. Đã kiểm source nutrient/portion7.444mục
   không đổi so APK trước. Chi tiết và log ở `docs/test-report.md`.
5. **Cần người dùng làm:** cài APK mới, khai báo tên cần tránh ngăn cách bằng `;`
   tại Cá nhân hóa, xác nhận mục tiêu kcal và nghiệm thu thực đơn/nhật ký trên
   Android thật. Không cần cấu hình Firebase mới cho phần này.
6. **Giới hạn:** từ khóa và thành phần công thức tham khảo không đại diện mọi
   món/nhãn hàng, không kiểm nhiễm chéo. Không bảo đảm khớp kcal với mọi hạn chế/
   mục tiêu; không tối ưu riêng macro/vi chất. 475 mục USDA còn giữ thương hiệu/
   tên hiếm kèm nhóm tiếng Việt, đối chiếu tên gốc khi chọn món. Chưa có ADB
   device, chưa thử production/Android thật; warning KGP cũ còn.
7. **Đề xuất tiếp theo:** nghiệm thu dinh dưỡng trên thiết bị Android.

APK bàn giao: `build/releases/healthmate-personalized-food-debug.apk`,
236.866.438byte, build14,3s, runtime config7/7, hash/asset đã đối chiếu với
manifest JSON. SHA256 `5C2FB0C58A262521BF4A4A45B1BFF86F78D2372513B3BB8484A631B1B7104726`.

## 27/10/2026 — Giai đoạn 10, nghiệm thu dinh dưỡng trên Android

1. **Trạng thái:** hoàn tất nghiệm thu local có điều kiện;11/11 checkpoint
   nghiệp vụ qua trên AVD Android11/API30, chưa kiểm điện thoại vật lý.
2. **Hành vi đã xác minh:**7.606món và metadata SQLite; mục tiêu2200kcal;
   tránh sữa/trứng vẫn áp dụng khi chọn Tất cả chế độ; tìm tên USDA/xem tên
   gốc; thêm150g/sửa200g/xóa; snapshot/tổng kcal; preview/Hủy không ghi;
   28bữa/7ngày khớp±5%; chỉ xác nhận đã ăn mới ghi nhật ký; UID B không đọc A.
3. **Sửa blocker:** `firestore.rules` thiếu `personalization` trong allowlist
   update hồ sơ. Bổ sung field, giữ validation/quyền; thêm regression trong
   `rules-tests/firestore.rules.test.cjs`. Thêm native suite
   `integration_test/nutrition_acceptance_test.dart`, mở rộng runner
   `tool/test_android_core.ps1`; cập nhật database-design và test-report.
4. **Kiểm thử:** native suite qua khoảng74s, Gradle14,8s; Rules56/56;
   analyzer cuối sạch20,3s; format test mới0thay đổi; diff-check qua.10ảnh
   và log tại `build/android-nutrition-20261027`; không chạy lại full678test.
5. **Cần làm trước production:** triển khai Rules đã review tới đúng Firebase
   project, rồi nghiệm thu trên điện thoại. Chưa deploy; APK không tự sửa Rules.
6. **Còn lại:** thực đơn thuần chay của fixture khớp kcal nhưng lặp bún/cam,
   khẩu phần lớn, chưa cân bằng macro; header dashboard chồng khi cuộn;
   qualifier khẩu phần USDA còn tiếng Anh. Chưa kiểm API ngoài/AI/offline mọi
   trường hợp. Không có APK sản phẩm mới vì không đổi Dart runtime sản phẩm.
7. **Đề xuất kế tiếp:** cải thiện chất lượng thực đơn/UX dinh dưỡng, sau đó
   nghiệm thu production trên điện thoại. Chưa tự triển khai giai đoạn tiếp.

Chi tiết, lần lỗi trước khi đạt và bằng chứng:
[android-nutrition-acceptance.md](android-nutrition-acceptance.md).

## 27/10/2026 — Giai đoạn 4, cập nhật nguồn dữ liệu thực phẩm

1. **Trạng thái:** hoàn tất bảo trì catalog. Thêm 308 Foundation Foods từ
   USDA 04/2026 và 3.255 FNDDS 2021–2023 phát hành 10/2024; tổng 11.169 mục.
   Nguồn mới có tên Việt rút gọn, tên gốc, phiên bản và FDC ID; ưu tiên trước
   USDA SR Legacy khi mức khớp bằng nhau. Không thay ID/snapshot cũ.
2. **File chính:** `assets/nutrition/usda-current.json`,
   `data/food_catalog/usda-current-manifest.json`, `tool/import_usda_current.py`,
   `tool/test_usda_current.py`, `test/current_food_catalog_test.dart`;
   bổ sung loader/parser/sort/pubspec, translator tùy chọn mapping, test đếm
   catalog, benchmark, README và báo cáo nguồn.
3. **Kiểm thử:** importer17/17, nhóm dinh dưỡng25/25, full Flutter688/688,
   file mới sau bổ sung snapshot3/3; analyzer cuối sạch9,1s; format7file sạch.
   Build debug Gradle19,4s, cấu hình7/7; asset APK khớp SHA nguồn.
4. **Cần người dùng làm:** cài `build/releases/healthmate-current-foods-debug.apk`
   để tự test. Không cần thêm key hay cấu hình Firebase cho catalog offline.
5. **Giới hạn:** Foundation bản2026 chứa bản ghi công bố2019–2025; FNDDS có
   giá trị biên soạn/kế thừa. Chưa có bản số Việt Nam2017 chính thức để nhập.
   Survey chưa rõ thành phần giữ unknown; không coi là chứng nhận dị ứng.
   KGP warning cũ và whitespace có sẵn `lib/main.dart:32` còn.
6. **Triển khai:** chưa deploy/push; không chạy lại luồng Android. APK chuẩn
   `lib/main.dart`,222.932.966byte, hash
   `FF1F1E256F1C566D42172BABA2CC34F58374460A54358F6E3A12522FD018792B`.
7. **Bước tiếp theo đề xuất:** người dùng nghiệm thu bản cập nhật; bổ sung
   nguồn Việt2017 khi có bộ dữ liệu số có quyền sử dụng. Chưa tự triển khai.

Chi tiết: [current-food-data-2026-10-27.md](current-food-data-2026-10-27.md).
# 27/10/2026 — Sửa khởi chạy web admin trong VS Code

1. **Giai đoạn/phạm vi:** bảo trì vận hành thuộc Giai đoạn10, chỉ sửa lệnh mở
   admin; không đổi UI/nghiệp vụ, cấu hình Firebase hay deploy.
2. **Đã hoàn thành:** xác định localhost4173 không có listener; launch Chrome
   thiếu preLaunchTask. F5 local nay gọi script bật server nền, kiểm HTTP sẵn
   sàng và dùng lại server đang chạy. Thêm lựa chọn Admin(online) cho dữ liệu thật.
3. **File chính:** `.vscode/launch.json`, `.vscode/tasks.json`,
   `tool/start_admin_local.ps1`, `admin-web/README.md` và báo cáo này.
4. **Kiểm tra:** chạy đúng lệnh PowerShell5.1 của task thành công; lần thứ hai
   dùng lại cùng PID. HTML/config/app/firebase/CSS đều HTTP200, giữ nosniff.
   Online `https://healthmate-app-20261013.web.app` HTTP200 và đúng trang admin.
   Lần đầu PowerShell5.1 chặn script theo policy mặc định; task đã thêm cờ
   execution policy cho riêng tiến trình, không đổi policy Windows đã lưu.
5. **Cần người dùng làm:** tải lại trang, hoặc chọn Admin(online) và đăng nhập
   Google bằng tài khoản admin đã cấp. Local vẫn cần Emulator theo README.
6. **Còn lại:** chưa bấm F5 qua UI VS Code hoặc đăng nhập thay người dùng;
   Auth9098/Firestore8092 hiện chưa chạy. Không seed/reset fixture, không thử
   lại luồng Android. Server local được giữ chạy tại loopback4173.
7. **Tiếp theo:** người dùng thử đăng nhập đúng môi trường; không tự mở rộng.

## 30/10/2026 — Mở rộng theo yêu cầu: Premium demo và doanh thu admin

1. **Phạm vi:** một đợt Premium demo, theo lựa chọn mô phỏng đồ án của người
   dùng; 20.000đ/30 ngày, không thu tiền hoặc tự gia hạn. Không mở dịch vụ trả
   phí, không thêm dependency hoặc chuyển sang giai đoạn MVP khác.
2. **Đã hoàn thành:** Cá nhân → Premium có mua/xác nhận/Hủy, hạn dùng và lượt
   hôm nay. Free 3 ảnh/5 câu AI, Premium 20 ảnh/50 câu AI, chung theo UID,
   reset 00:00 Việt Nam; reserve lượt nguyên tử trước AI, không tính mã vạch/
   lookup local/thử lưu lại. Admin có doanh thu mô phỏng, lọc ngày, tổng hợp
   từng ngày, chi tiết và Excel. Không suy doanh thu từ số gói.
3. **File chính:** `lib/features/premium/` (model/repository/providers/UI),
   router/profile/scanner/chat providers, `firestore.rules`,
   `admin-web/dist/revenue-model.mjs`, `revenue-page.mjs`, app/list model,
   `tool/build_android.ps1`, các test Premium/Rules/admin/chat và tài liệu.
4. **Kiểm thử:** full Flutter **697/697**; analyzer sạch **10,6s**; admin
   **25/25**, syntax qua; Rules Emulator **84/84**, gồm 6 Premium test và
   tranh lượt cuối trên 2 thiết bị. Runtime build **7/7**, Gradle **55,4s**,
   debug APK thành công, SHA/3 catalog assets khớp. Không chạy lại luồng Android.
5. **Bàn giao:** `build/releases/healthmate-premium-demo-debug.apk`,
   **222.955.916 byte**, SHA-256
   `974348DCF030F070FAE1FA9760F6E3D379510C62ACA66E84236A5331FF94A449`,
   manifest cùng tên có `premiumDemoEnabled:true`. Cờ demo mặc định false,
   build riêng với `tool/build_android.ps1 -PremiumDemo`.
6. **Triển khai:** đã cập nhật Firebase Hosting/Rules sau backup và đối
   chiếu production; đọc lại Rules khớp source, cả 13 file HTTP200/hash đúng.
   Web: https://healthmate-app-20261013.web.app. Ngoài Premium, Rules chỉ sửa allowlist
   `personalization` đã kiểm thử khi nghiệm thu dinh dưỡng; không đổi validation
   hoặc mở quyền người khác. Không nâng billing, đổi App Check hoặc cấp role.
   Người dùng cài APK mới/tải lại web để nghiệm thu; không cần tự deploy.
7. **Giới hạn:** quota trong client chính thức + counter Rules, chưa có chặn
   AI ở backend chống client sửa. Không tăng quota dịch vụ AI. Metadata demo
   chưa tự xóa theo tài khoản Auth, đã công khai trước mua. Chưa test Android
   thật/AI thật/offline toàn luồng; người dùng tự nghiệm thu. Warning KGP cũ còn.
8. **Bước tiếp theo đề xuất:** người dùng test APK demo và báo cáo; gói thu
   tiền thật cần đợt riêng thiết kế xác minh thanh toán/quota phía server.

Chi tiết: [premium-demo-2026-10-30.md](premium-demo-2026-10-30.md).

## 30/10/2026 — Đổi địa chỉ web admin theo lựa chọn người dùng

- **Phạm vi:** bảo trì Hosting thuộc Giai đoạn 10, chỉ đổi link; không thiết
  kế lại giao diện hoặc mở giai đoạn MVP tiếp theo.
- Tên `healthmate-admin.web.app` bị dự án khác giữ. Sau khi kiểm tra tên trống,
  người dùng chọn **https://healthmate-admin-vn.web.app**.
- Đã tạo site `healthmate-admin-vn` trong project hiện có và clone bản live
  Premium demo từ site cũ. Không tạo project/database/Auth account mới.
- Cấu hình Firebase Auth authorized domains và reCAPTCHA Enterprise allowlist
  bổ sung hai hostname `.web.app`/`.firebaseapp.com` của site mới, giữ domain
  cũ, key App Check/ngưỡng kiểm tra/quyền/billing. `billingEnabled:false`.
- HTTPS 13/13 file HTTP200/hash khớp bản phát hành, header bảo vệ giữ nguyên;
  link cũ HTTP200. Hosting version `74c1043d0c4d1f45`. Log/backup cấu hình tại
  `build/admin-domain-switch-20261030/`.
- File sửa: `.vscode/launch.json`, `admin-web/tool/prepare-release.cjs`, README
  gốc/admin, docs admin-production/Premium/progress/test-report. Tool đóng gói
  đã chạy thử với site mới, syntax check qua. Không sửa Dart/Rules, không cần
  build lại APK hoặc chạy lại Flutter/Android.
- **Cần người dùng làm:** mở link mới và đăng nhập tài khoản admin như trước.
  Browser đã qua App Check và mở form đăng nhập sau tải lại; chưa thử Google
  popup bằng tài khoản của người dùng. Chi tiết trong test-report.
- **Tiếp theo đề xuất:** người dùng kiểm tra đăng nhập tại địa chỉ mới; không
  tự mở rộng tính năng hoặc đổi giao diện.

## 30/10/2026 — Mở rộng theo yêu cầu: Báo lỗi, góp ý và admin phản hồi

1. **Giai đoạn/phạm vi:** đợt hỗ trợ khách hàng được người dùng yêu cầu riêng,
   chỉ làm báo lỗi/góp ý/trao đổi/trạng thái; không mở các giai đoạn khác.
2. **Đã hoàn thành:** Cá nhân → Báo lỗi & Góp ý, tạo yêu cầu, xem trạng thái/
   phản hồi, bổ sung thông tin. Web admin → Hỗ trợ khách hàng có tìm kiếm,
   bộ lọc, phân trang, xem/trả lời, cập nhật xử lý. Khách bổ sung mở lại yêu
   cầu đã đóng; gửi lại dùng cùng ID, không nhân bản. Xóa tài khoản xóa cả
   ticket/messages, freeze trước để ngăn phản hồi đồng thời tạo dữ liệu mồ côi.
3. **File chính:** `lib/features/support/`, router/profile/privacy,
   `firebase_account_data_repository.dart`, `firestore.rules`,
   `firestore.indexes.json`, `admin-web/dist/support-model.mjs`,
   `support-page.mjs`, app/firebase/list/CSS, tests Flutter/Rules/DOM/SDK.
4. **Kiểm thử:** full cuối **707/707 Flutter**; analyzer sạch; admin **29/29**,
   Rules **91/91**, SDK thật qua Emulator **5/5**. Build runtime **7/7**,
   Gradle **21,8s**, APK debug thành công. Không chạy lại luồng Android.
5. **Bàn giao:** `build/releases/healthmate-support-debug.apk`,222.973.794byte,
   SHA256 `68D2B3F50ADDC5681FE4E589CA99E77CF53763A0096DFB1DFA2473C3A1A14854`.
   Giữ Premium demo; người dùng cần cài APK mới, tải lại web admin.
6. **Triển khai:** đã phát hành tại https://healthmate-admin-vn.web.app và
   Rules project hiện có; Rules đọc lại khớp bản đã test;15/15file HTTPS/hash
   đúng. Index support UID/updatedAt READY, giữ index cũ. Không nâng billing,
   thêm dependency hoặc cấp quyền. Không gửi phản hồi tới khách thật để test.
7. **Giới hạn:** chưa push/email/ảnh đính kèm, tối đa100tin/cuộc,2000ký tự/tin;
   app hiện50ticket cập nhật gần nhất; admin loader5000. Gửi đồng thời có thể
   cần bấm thử lại, draft/ID được giữ. Chưa rate limit/đánh dấu đã đọc; chưa
   nghiệm thu điện thoại thật. Xóa Auth bên ngoài app không tự chạy cleanup.
8. **Tiếp theo đề xuất:** người dùng test ticket A → admin reply → A xem/bổ sung
   và kiểm UID B; không tự làm thông báo đẩy hoặc giai đoạn khác.

Chi tiết: [customer-support-2026-10-30.md](customer-support-2026-10-30.md).

## 30/10/2026 — Gói cải thiện 1: barcode validation và layout

1. **Phạm vi:** Gói 1 theo kế hoạch chủ dự án cung cấp; kiểm baseline Gói 0.
   Bắt đầu `main@0e897eca3cbdb7907012197830b9d365763e4faf`, working tree sạch.
2. **Hoàn thành local:** validator trên 100 g dùng chung barcode/USDA;
   chặn dữ liệu sai trước snapshot, giữ unknown/zero, chuyển khoáng chất đúng
   một lần. OFF chưa rõ cơ sở cần xác nhận g/ml; thể tích giữ ml khi lưu.
   Barcode sheet không tràn ở 320/360/412 px × chữ 1/1,5/2.
3. **File chính:** service/model/sheet barcode, `nutrition_validation.dart`,
   `usda_api_service.dart`, `firestore.rules`, test barcode, Rules regression
   mới và [improvement-progress.md](improvement-progress.md).
4. **Kiểm thử:** 11 test Flutter mới và 3 test Rules đã thất bại trước sửa;
   cuối 726/726 Flutter, 95/95 Rules qua, analyzer sạch (104,2s), format và
   diff check qua. Không giảm giới hạn 5 món/6 nguyên liệu để tránh Rules budget.
5. **Cần quyết định trước production:** phát hành client và triển khai Rules
   candidate sau review/backup/dry-run phù hợp. Không thay schema/index hoặc
   sửa dữ liệu cũ; snapshot sai khi cập nhật lại cần người dùng sửa chủ động.
6. **Giới hạn:** chưa nghiệm thu native, chưa build APK/commit/push/deploy.
   Xác nhận g/ml dựa trên nhãn do người dùng đọc; không tự suy mật độ.
7. **Tiếp theo đề xuất:** Gói 2 — tìm USDA có giới hạn request/deadline và
   trạng thái lỗi; chưa triển khai.

## 31/10/2026 — Gói cải thiện 2: tìm USDA có giới hạn

1. **Phạm vi:** chỉ Gói 2 của kế hoạch cải thiện; HEAD vẫn
   `main@0e897eca3cbdb7907012197830b9d365763e4faf`, bảo toàn working tree Gói 1.
2. **Đã hoàn thành local:** tìm USDA trả metadata, chỉ tải detail khi chọn;
   dùng local/cache ngay khi online chậm/lỗi. Deadline chung 8 giây mỗi
   thao tác tìm/tải detail, hủy khi đổi query/nguồn/bộ lọc/UID/ẩn màn hoặc
   dispose. Retry hủy tác vụ trước; không nhân chuỗi detail. Phân biệt lỗi
   quota, mạng, provider, JSON, timeout và kết quả partial/rỗng hợp lệ.
3. **File chính:** `food_search_request.dart`, `food_search_cache.dart`,
   `unified_food_search_service.dart`, `usda_api_service.dart`, database/provider
   dinh dưỡng và cả `meal_form_dialog.dart`, `meal_food_sources.dart`; hai
   regression suite mới và các fake/search test hiện có.
4. **Kiểm thử:** fixture trước sửa 51 request cho 50 kết quả; sau sửa 1
   search, không detail nếu chưa chọn, thêm đúng 1 detail cho món đã chọn.
   Focused **49/49**, toàn bộ Flutter **753/753** qua; analyzer sạch, format
   và diff check qua. Có fake clock, client quan sát abort và test hai UI.
5. **Cần người dùng làm:** không cần cấu hình thêm cho source demo. Chưa
   phát hành client/APK mới; khi chạy bản source này có thể tự test Android
   theo quy trình của chủ dự án. Không tự deploy, push GitHub hoặc chạy
   lại luồng native trong gói này.
6. **Giới hạn:** `DEMO_KEY` vẫn bị hạn mức USDA theo IP, không thêm key
   riêng. Cache SQLite đã chạy không rollback được khi hủy; HTTP abort
   phụ thuộc transport, không thu hồi request đã tới máy chủ. Chưa xác minh
   API USDA thật/thiết bị thật/production. Không thay Rules/schema/dependency.
7. **Tiếp theo đề xuất:** Gói 3 — toàn vẹn kế hoạch–nhật ký; chưa thực hiện.

Chi tiết giới hạn, bằng chứng và file:
[improvement-progress.md](improvement-progress.md).

## 31/10/2026 — Gói cải thiện 3: toàn vẹn kế hoạch–nhật ký

1. **Giai đoạn/phạm vi:** chỉ Gói 3 của kế hoạch cải thiện. Bảo toàn thay
   đổi Gói 1–2; không triển khai Gói 4.
2. **Đã hoàn thành local:** xác nhận ghi meal + pointer bằng transaction;
   xóa meal + gỡ pointer nguyên tử, cho ghi lại; xóa plan giữ lịch sử.
   Retry cùng payload không trùng/ghi đè, khác payload bị báo xung đột.
   Form cũ sau sửa/xóa không tái tạo dữ liệu. Nút kiểm tra liên kết khôi
   phục pointer treo hoặc thiếu marker mà không sửa lịch sử ăn uống.
3. **File chính:** serializer `meal_document.dart`, hai repository dinh
   dưỡng/wellness, model và UI plan, Rules; cleanup chỉ đổi thứ tự plan
   trước meal. Thêm Rules, SDK và widget regression tests. Không đổi schema.
4. **Kiểm thử:** trước sửa SDK 0 qua/3 lỗi; sau sửa SDK Gói 3 **13/13**,
   widget **4/4**, Rules focused **17/17**, Rules đầy đủ **100/100**, SDK
   repository rộng **23/23**, Flutter mặc định **757/757**. Analyze sạch.
   Format 29 Dart đang thay đổi và diff check qua; format toàn repo đọc
   kiểm còn 5 lệch có sẵn ngoài phạm vi, giữ nguyên.
5. **Cần người dùng làm:** khi phát hành cần phối hợp client và Rules mới,
   vì client cũ ghi hai bước sẽ bị candidate Rules chặn. Chưa deploy,
   build APK, push GitHub hoặc chạy lại Android; chủ dự án tự test thiết bị.
6. **Giới hạn:** concurrency dùng hai Firebase app SDK cùng UID trên emulator;
   mất ACK mô phỏng bằng bỏ kết quả đã commit, chưa cắt ACK mạng thật.
   Chưa giải quyết vòng đời xóa tài khoản/tombstone/job của Gói 4. Những
   lỗi setup fixture và giới hạn budget ở vòng đầu đã ghi trong báo cáo.
7. **Gói kế tiếp đề xuất:** Gói 4 — vòng đời xóa tài khoản và chính sách
   lưu giữ; chưa thực hiện.

Chi tiết và bằng chứng: [improvement-progress.md](improvement-progress.md).

## 31/10/2026 — Gói cải thiện 4: xóa tài khoản và chính sách lưu giữ

1. **Giai đoạn/phạm vi:** chỉ Gói 4 của kế hoạch cải thiện; bảo toàn Gói
   1–3 và HEAD `main@0e897eca3cbdb7907012197830b9d365763e4faf`. Trạng thái:
   client fallback/Rules candidate đã xác minh local; chưa đủ điều kiện
   production vì thiếu server job và chính sách retention thực thi được.
2. **Đã hoàn thành:** server xác nhận tombstone trước cleanup; khóa mọi
   create/update sản phẩm, giữ quyền cleanup cùng UID kể cả suspended.
   Retry dùng cùng yêu cầu và luôn kiểm tra lại dữ liệu, không tin checkpoint
   để bỏ qua. Dọn inventory đã biết gồm Premium demo, support, directory,
   controls; dừng/chặn native và dọn nháp trước server cleanup/Auth. Gate
   tiếp tục xóa sau mở lại, chặn bootstrap/directory/native/export tái ghi.
   Báo đúng Auth chưa xóa; không tự chứng nhận `completed` hoặc xóa hết UID.
3. **File chính:** `firebase_account_data_repository.dart`, interface/model
   job, auth controller/repository, gate/dialog, profile/admin/wellness/export
   providers, Rules; `AccountDeletionBlock.kt`, storage/bridge/draft native.
   ADR inventory + retention mới, schema trong `database-design.md`, README
   rollout; Rules/SDK/controller/gate/export/host regression tests mới.
4. **Kiểm thử:** SDK deletion **8/8**, SDK repository hồi quy **23/23**,
   Rules deletion **9/9**, toàn Rules **109/109**, budget plan **5/5**.
   Flutter focused **75/75**, export **4/4**, wellness **11/11**, toàn Flutter
   **772/772**. Analyze sạch; format 54 Dart đang đổi 0 thay đổi, diff check
   qua. Host native contract **5/5**, compile Kotlin offline nonincremental
   thành công; không build APK. QA sync đối chiếu hash 458 file.
5. **Cần người dùng làm:** trước production cần provision job xóa đặc quyền,
   inventory đệ quy/orphan, xác minh Auth/revocation, chính sách thời hạn và
   purge audit/marker/provenance/role admin. Sau đó phối hợp Rules/client,
   đánh giá tương thích client cũ và hỗ trợ yêu cầu dở. Chưa cấp credential,
   thêm dịch vụ trả phí, deploy hoặc xóa tài khoản thật trong lượt này.
6. **Vấn đề còn lại:** cleanup client chỉ chạy khi app mở/có mạng; không
   tìm được mọi orphan mất parent/collection chưa biết. Marker UID/metadata
   giữ không có TTL tự động; audit và dấu vết admin cần quy trình server.
   Sau Auth delete marker vẫn `auth_pending`, chưa có server xác minh xong.
   Không thu hồi từ xa cache offline/file export/provider data; chưa nghiệm
   thu Android native theo lựa chọn chủ dự án. Lỗi harness/budget/compile
   và giới hạn bằng chứng đều ghi trong báo cáo, không giảm assertions.
7. **Gói kế tiếp đề xuất:** Gói 5 — AI policy/quota tại dịch vụ tin cậy;
   chưa triển khai. Không commit/push, phát hành APK hay tắt máy.

Chi tiết: [improvement-progress.md](improvement-progress.md),
[account-deletion-adr.md](account-deletion-adr.md), [test-report.md](test-report.md).

## 31/10/2026 — Gói cải thiện 5, 6, 7

1. **Phạm vi:** ba gói kế tiếp theo yêu cầu trực tiếp; bảo toàn Gói 1–4,
   không chuyển sang Gói 8. Đây là improvement packages, không phải MVP stages.
2. **Đã làm:** gateway chat reserve quota/policy tin cậy, client bỏ quyền tự
   cấp lượt và direct AI; query dinh dưỡng có chứng nhận migration, lịch sử
   cân có cursor; admin phân trang server, export/báo cáo theo khoảng riêng.
   Hồi quy transaction đồng thời có retry giới hạn theo cặp đã xác nhận server.
3. **File chính:** chat-api policy/Firestore adapter/auth/entry/config;
   Flutter assistant/Premium/scanner/knowledge/cleanup; nutrition/profile/
   wellness repositories và UI; admin server-paging/firebase/app/revenue/
   support; Rules/indexes; tool meal_query_migration và các regression tests.
4. **Kiểm thử:** full Flutter780/780; Rules119/119; chat Node48/48,
   REST emulator3/3, dry-run Worker qua; admin Node42/42, SDK7/7;
   migration6/6. Analyze/format/diff và SDK repository cuối ghi tại
   [test-report.md](test-report.md), evidence manifest cùng log/hash.
5. **Cần cấu hình trước production:** identity/IAM và secrets server bằng
   quy trình riêng, kiểm revoke/provider thật, chặn direct Firebase AI từ
   client cũ, retention/server deletion jobs, gateway ảnh; duyệt migration
   timezone/backup/rollout client+Rules+indexes; publish admin sau review.
6. **Còn lại:** Gói 5 chưa production-ready; gateway mặc định tắt, scanner AI
   ảnh tạm chưa khả dụng, barcode/nhập tay vẫn dùng. Chưa deploy/migrate/push,
   không nâng billing. Không nghiệm thu native Android hay build APK.
7. **Tiếp theo đề xuất:** Gói 8 — chống spam support và lịch sử ticket;
   chưa triển khai. Chủ dự án yêu cầu tắt laptop sau khi lưu và kiểm tra xong;
   tiến trình kiểm thử task được dừng trước khi lên lịch tắt, không ép đóng app.

Chi tiết hành vi trước/sau, schema, giới hạn local/production và rollback:
[improvement-progress.md](improvement-progress.md),
[ai-policy-quota-adr.md](ai-policy-quota-adr.md),
[package6-query-migration.md](package6-query-migration.md),
[package7-admin-pagination.md](package7-admin-pagination.md).

## 31/10/2026 — Gói cải thiện 8, 9, 10

1. **Phạm vi/trạng thái:** Gói 8/9 candidate đã xác minh local; Gói 10 đã
   chuẩn bị và kiểm preflight/load local, signed release/native còn bị chặn.
   Giữ `main@0e897eca3cbdb7907012197830b9d365763e4faf`, Gói 1–7 chưa commit;
   package/version demo `com.example.healthmate`, `1.0.0+1` theo chủ dự án.
2. **Đã làm:** hạn mức ticket authority 3/ngày, cooldown60s, atomic counter,
   idempotent retry và lịch sử25/trang; tách draft/submit/search/source UI;
   rút README/lưu CHANGELOG, thêm bảng hashes và CI không deploy; release
   guard/config/preflight/helper và bounded load probe emulator.
3. **File chính:** support repository/models/providers/screen/Rules và tests;
   auth cleanup inventory; meal_form_controller, meal_search_controller,
   meal_entry_sources, meal_form_dialog và tests; README/CHANGELOG, workflow/
   CI helpers; Gradle/config/release_preflight/build_release, tài liệu gói.
4. **Kiểm thử:** Flutter803/803; Rules127/127; Flutter web SDK52/52;
   admin42/42 +SDK7/7; chat48/48 +REST3/3; tools28/28; REST migration1/1;
   analyzer sạch, format92 files0 changes, audit/diff/parse qua. Load10 workers:
   100 queries/1.000 docs/0 errors, p95 58.452ms trên emulator admin bypass.
   Release preflight exit1 đúng vì thiếu signing, không gọi đó là release pass.
5. **Cần chủ dự án làm:** cung cấp private signing/certificate và nghiệm thu
   Android tự test theo ma trận; xử lý server deletion/retention và AI trusted
   identity/direct-route blockers trước production; duyệt rollout client+
   Rules/indexes/migration và chi phí. Không thêm credential/billing/deploy.
6. **Còn lại:** chưa có signed APK/hash/native acceptance, chưa chạy hosted CI;
   Gói10 chưa thể hoàn tất nghiệm thu. Local load không đo quota/billing/capacity.
   Ticket Rules mới cần phối hợp client; không nới để tương thích client cũ.
7. **Tiếp theo đề xuất:** hoàn tất các blocker và nghiệm thu signed release;
   không tự chuyển Giai đoạn11 hoặc triển khai production.

Kết quả thật, lỗi trung gian và đường dẫn log:
[test-report.md](test-report.md), [candidate-verification.md](candidate-verification.md),
[improvement-progress.md](improvement-progress.md), [release-readiness.md](release-readiness.md).


## 06/11/2026 — Đồng bộ thời gian thực app/admin (bản kiểm thử)

- Phạm vi theo yêu cầu: mọi luồng dữ liệu chung đã triển khai; bổ sung invalidation
  cho báo cáo theo kỳ/tuần/giấc ngủ và chi tiết thư viện trong app, không tự làm
  tính năng web còn thiếu.
- Web: snapshot listeners cho dashboard, doanh thu, khách hàng/role/control,
  thực phẩm, audit, cấu hình và hỗ trợ; hủy theo màn hình/phiên, giữ bản nháp.
- App: lọc món ẩn ở cache/USDA/chi tiết đang tải; báo cáo nhận revision theo UID.
- Cloud Functions: Auth/Firestore events, bộ đếm server, bootstrap có kiểm tra
  trùng/lệch thứ tự; không dùng số directory thay tổng Auth, không dùng số giả.
- File chính: `admin-web/dist/live-data.mjs`, `live-scope.mjs`, các page module;
  `firebase-functions/`; `lib/core/data/user_data_revision.dart`; nutrition
  visibility/repository/service và report/target/sleep/weekly/library providers;
  `firestore.rules`.
- Đạt: Flutter 951/951; analyze sạch; admin 66/66; Rules 129/129; SDK cũ 9/9,
  SDK realtime 6/6; Functions unit 2/2, integration 3/3; Rules bundle 3/3;
  APK debug build thành công. Log và lần lỗi đã sửa ghi trong báo cáo chi tiết.
- Người dùng đã đồng ý Functions/có thể tính phí, nhưng chọn bật Blaze sau.
  Preflight thật: billing chưa bật. Chưa deploy/ghi production/cài Android thật.
- Bundle review dựa trên Rules production, chỉ thêm các quyền cần thiết cho
  realtime. Không deploy toàn bộ Rules candidate đang có từ các lượt trước.
- Cần làm thủ công: bật Blaze. Đề xuất tiếp theo: triển khai và xác nhận app/web
  thật sau bước đó; chưa thực hiện. [Báo cáo](realtime-sync-2026-11-06.md).

## 06/11/2026 — Đã triển khai realtime trên Spark

- Tiếp tục yêu cầu đồng bộ hiện có: đã publish Hosting và Rules tối thiểu lên
  healthmate-admin-vn.web.app, đọc lại file/Rules khớp. Không bật billing/Functions.
- Web nghe dữ liệu trực tiếp; app thêm listeners đúng khoảng báo cáo/tuần,
  mục tiêu, giấc ngủ và chi tiết thư viện, không chờ revision server.
- File chính: live-data.mjs, firebase.mjs, prepare-realtime-release.cjs;
  private_data_changes.dart, user_data_revision.dart và các providers liên quan.
- Đạt: Flutter952/952, analyze sạch, admin66/66, Spark SDK1/1, Flutter SDK3/3,
  Rules bundle3/3, APK debug build qua. Snapshot Auth thật3 có nhãn thủ công.
- Cần cài APK mới; chưa có thiết bị Android kết nối, chưa nghiệm thu hai thiết
  bị production. Tổng Auth tự động còn chờ Functions/Blaze; Premium vẫn demo.
- Tiếp theo đề xuất: nghiệm thu app/web thật, không tự thêm nghiệp vụ khác.
- Chi tiết và bằng chứng: [realtime-spark-2026-11-06.md](realtime-spark-2026-11-06.md).

## 07/11/2026 — Giai đoạn 10, ổn định thao tác hằng ngày trên Android

1. **Giai đoạn/trạng thái:** hoàn tất gói sửa và kiểm thử local của lượt này;
   Giai đoạn 10 tổng thể vẫn cần nghiệm thu điện thoại thật và signed release.
2. **Đã hoàn thành:** form nước/vận động/cân nặng/hồ sơ hỏi trước khi bỏ nội
   dung đã sửa, giữ giá trị khi lưu lỗi, chờ ACK không gửi lặp; resume làm mới
   quyền/lịch nhắc và chặn kết quả cài đặt cũ; bước chân dừng polling UI khi
   nền/ẩn tab, đồng bộ đúng ngày và thử lại khi quay về. Không thêm dữ liệu giả.
3. **File chính:** `confirmed_save.dart` và bốn form; `wellness_providers.dart`,
   `wellness_screen.dart`; Firestore realtime injection trong
   `user_data_revision.dart`/`private_data_changes.dart`; hai test hồi quy mới,
   native `daily_reliability_acceptance_test.dart`, runner và ba harness native.
4. **Kiểm thử cuối:** Flutter **973/973**, **21** regression tests mới nằm trong
   suite; nhóm tập trung **44/44**; analyze sạch; format 15 file không đổi;
   native suite `daily` qua trên AVD Android API 30 và Auth/Firestore Emulator;
   diff check và PowerShell parse qua. Kết quả APK và hash trong báo cáo chi tiết.
5. **Cần người dùng làm:** cài APK debug mới và nghiệm thu trên điện thoại;
   cung cấp signing/certificate qua cơ chế private trước bản phát hành.
6. **Còn lại:** form bốn loại trên chưa có nháp bền vững khi tiến trình bị kết
   thúc; nháp bữa ăn mã hóa giữ cơ chế sẵn có. Native suite `core` cũ chưa qua
   do finder tổng kcal không phù hợp UI mới. Chưa nghiệm thu API 33+ permission,
   cảm biến thật, Play Integrity hoặc signed release. AI/phí Premium thật,
   tổng Auth tự động và worker xóa nền còn theo blocker các báo cáo trước.
   Không thêm package, đổi Rules/schema, bật Blaze hoặc deploy production.
7. **Tiếp theo đề xuất:** nghiệm thu Android thật và hoàn tất signing;
   chưa triển khai giai đoạn khác.

Hành vi, lệnh, lỗi trung gian, giới hạn và APK:
[android-quality-2026-11-07.md](android-quality-2026-11-07.md).

## 07/11/2026 — Giai đoạn 8, biểu đồ dưỡng chất và chi tiết đóng góp

1. **Giai đoạn/trạng thái:** hoàn tất phần cải thiện báo cáo local; chủ dự án
   yêu cầu làm phần khác, để nghiệm thu Android thật/signing sau.
2. **Đã hoàn thành:** Pie thật từ snapshot món theo hệ số Carb/Đạm/Béo 4/4/9;
   chạm lát hoặc legend mở đóng góp từng món, Back đóng chi tiết giữ bộ lọc;
   tuần (tab Dưỡng chất), 30/90 ngày, năm và khoảng tùy chọn dùng cùng hành vi.
   Thiếu macro/chi tiết/0 có thông báo riêng; không tạo tỷ lệ giả. Chi tiết
   cập nhật cùng nguồn báo cáo, giữ đơn vị g/ml, hiển thị nguồn/nhãn ước tính.
3. **File chính:** `reports/models/macro_energy_report.dart`,
   `reports/presentation/macro_energy_card.dart`; ghép vào `progress_screen.dart`,
   `period_report_panel.dart`; `test/macro_energy_report_test.dart` và báo cáo.
4. **Kiểm thử:** full Flutter **997/997 qua**, nhóm mới **24/24 qua**, analyzer
   sạch; render Inter sáng/tối **2/2 qua**, đã xem ảnh fixture. Không thêm query
   khi mở chi tiết; kiểm nguồn tải/lỗi, đổi UID/kỳ và 320 px/chữ 200%.
   Kết quả APK/hash và kiểm tra cuối tại báo cáo chi tiết.
5. **Cần người dùng cấu hình:** không có dịch vụ hoặc cấu hình mới.
6. **Giới hạn:** tỷ lệ theo các món đã ghi, không thay thế tổng kcal nhật ký
   hoặc khuyến nghị ăn uống. Không đổi Rules/schema/dependency/billing,
   không deploy và không chạy nghiệm thu Android thật/ký phát hành.
7. **Tiếp theo đề xuất:** cải thiện Báo lỗi & Góp ý; chưa thực hiện.

Chi tiết, lệnh, lỗi trung gian và artifact:
[macro-energy-report-2026-11-07.md](macro-energy-report-2026-11-07.md).

## 07/11/2026 — Giai đoạn 10, cải thiện Báo lỗi & Góp ý

1. **Giai đoạn/trạng thái:** hoàn tất gói hỗ trợ local của lượt này; nghiệm thu
   Android thật/signing tiếp tục được hoãn theo yêu cầu chủ dự án.
2. **Đã hoàn thành:** Back hỏi trước khi bỏ bản soạn; chờ ACK không cho gửi
   lặp/rời màn hình; giữ payload/mã thao tác để retry; ô trả lời riêng dưới
   lịch sử, cuộn được khi bàn phím/chữ lớn; phản hồi admin giữ phần đang gõ.
   Giới hạn 100 giữ nội dung để sao chép, cho retry thao tác chưa rõ ACK.
   Chặn dữ liệu/gửi khi Auth chưa sẵn sàng và loại bỏ route khi đổi tài khoản.
3. **File chính:** `support_screen.dart`, `support_draft_guard.dart`,
   `support_providers.dart`, hai file test hỗ trợ và báo cáo chi tiết.
4. **Kiểm thử:** Flutter **1018/1018 qua**; nhóm hỗ trợ **34/34 qua**, gồm 21
   test mới; full/scoped analyzer sạch; format 5 file không đổi; render Inter
   **2/2 qua**, đã xem PNG; runtime config **7/7 qua**; APK debug build qua.
5. **Cần người dùng cấu hình:** không có cấu hình/dịch vụ mới.
6. **Giới hạn:** bản soạn chỉ trong bộ nhớ màn hình; chưa kiểm thử hỗ trợ trên
   Android/backend production ở lượt này. Rules/schema/backend/dependencies
   giữ nguyên; warning KGP tương lai ghi trong báo cáo. Không deploy/push.
7. **Tiếp theo đề xuất:** Giai đoạn 10, trải nghiệm lỗi/mất mạng Scanner và
   Chatbot; chưa thực hiện.

Hành vi, lệnh, lỗi trung gian, giới hạn và artifact:
[support-quality-2026-11-07.md](support-quality-2026-11-07.md).

## 07/11/2026 — Giai đoạn 10, chọn chủ đề trước khi gửi hỗ trợ

1. **Giai đoạn/trạng thái:** hoàn tất mã nguồn và kiểm thử local theo yêu cầu
   phân loại vấn đề; chưa triển khai Rules/web production.
2. **Đã hoàn thành:** app bắt buộc chọn một trong tám chủ đề, tách với Báo
   lỗi/Góp ý; lưu Firestore, hiển thị app/admin, lọc/tìm chủ đề ở admin; retry
   giữ nguyên chủ đề và ID. Yêu cầu cũ có nhãn Chưa phân loại, không migrate.
3. **File chính:** model/repository/screen support, hai module admin support,
   firestore.rules, test Flutter/Rules/admin/SDK và database-design.md.
4. **Kiểm thử:** source cuối Flutter **1022/1022 qua**, analyzer sạch; admin
   **86/86**, syntax check qua; Rules **139/139**; Flutter SDK **4/4**, admin
   SDK **9/9** trên emulator; format 11 file không đổi; diff check qua;
   preview Inter đã xem; APK debug và runtime **7/7** qua.
5. **Cần khi áp dụng:** publish Rules có topic trước app mới, cập nhật web rồi
   phân phối APK; không cần dịch vụ mới/Blaze. Có gói review/hash local.
6. **Giới hạn:** bản đang chạy chưa được cập nhật; Rules cũ từ chối topic.
   Topic thiếu vẫn được Rules nhận cho client cũ nhưng UI mới bắt buộc chọn.
   Nghiệm thu Android thật/signing tiếp tục để sau theo yêu cầu chủ dự án.
7. **Tiếp theo đề xuất:** áp dụng Rules/web và APK đã kiểm thử; chưa thực hiện.

Chi tiết hành vi, hợp đồng dữ liệu, test và artifact:
[support-topics-2026-11-07.md](support-topics-2026-11-07.md).

## 07/11/2026 — Giai đoạn 10 mở rộng, thanh toán Premium Google Play

1. **Trạng thái:** hoàn tất phần code và kiểm thử local; chưa mở bán/deploy.
   Chủ dự án chưa có Play Console, Blaze để bật sau; chưa thể nghiệm thu
   giao dịch thật hoặc Google sandbox. Không tự ký release.
2. **Đã làm:** checkout Android lấy giá Google, restore, account binding,
   server verification và acknowledge, membership realtime, quota AI đã xác
   minh; RTDN + vòng bù; ledger tiền/hoàn từ Orders, admin production/test/
   demo riêng, export, Rules chỉ máy chủ ghi, nhắc hủy gói trước xóa account.
3. **File chính:** feature premium `play_*`, app/profile/privacy, Functions
   billing, AI policy, admin revenue/dashboard/live queries, Rules/index và
   tests. Thêm dependency đúng nhu cầu, giữ các thay đổi trước đó.
4. **Kiểm thử:** Flutter **1030/1030 qua**; analyzer sạch. Sau bổ sung mô tả
   privacy, suite account **8/8** và preview Inter **2/2** qua. Admin **90/90**,
   Functions **17/17**, gateway **49/49**, Rules **143/143**, billing integration
   Firestore + owner/admin listener **1/1**, release preflight **6/6** qua.
   Syntax checks qua; APK debug build thành công, runtime **7/7** qua.
5. **Cần cấu hình:** Play Console + subscription/base plan/package, Blaze,
   Android Publisher IAM/ADC, Functions/Rules/index/RTDN, App Check, gateway,
   license tester/testing track. Cờ client/server thanh toán mặc định tắt;
   release guard chặn mở trước nghiệm thu.
6. **Giới hạn:** không có bằng chứng Google sandbox/live; chưa backfill mọi
   gia hạn cũ hoặc nghiệm thu refund token cũ không còn đọc được. Báo cáo chỉ
   gồm order đã đồng bộ, cần đối soát Console trước chốt sổ. Chính sách lưu
   giữ tài chính và 6 cảnh báo moderate từ dependency Firebase cần review
   trước production. Không cộng tiền thử vào tiền thật.
7. **Tiếp theo đề xuất:** cấu hình Play Console/Blaze và nghiệm thu sandbox;
   chưa tự triển khai.

Chi tiết cấu hình, hành vi, giới hạn và artifact:
[google-play-billing-2026-11-07.md](google-play-billing-2026-11-07.md).

## 08/11/2026 — Giai đoạn 10, chất lượng xuất báo cáo app và admin

- **Trạng thái:** hoàn tất code và kiểm thử local; chưa publish admin,
  chưa nghiệm thu xuất trên Android thật hoặc ký release.
- **App:** CSV chi tiết/tổng hợp theo ngày, số liệu từ snapshot thật,
  blank/zero và dưỡng chất thiếu tách rõ, chọn lần cân cuối đúng timestamp,
  kiểm tra khoảng đầu ngày trước khi đọc, tiến trình tải/chọn nơi lưu/ghi.
- **Admin:** lọc toàn bộ khoảng qua mọi trang theo lựa chọn, thông tin
  nguồn/phạm vi/bộ lọc/tổng hợp theo tiền tệ trong sheet riêng; Excel Inter,
  xuống dòng/rộng cột phù hợp, bảo toàn chữ số dài; tải lỗi có thông báo
  và chặn nút cũ khi phiên thay đổi. Phạm vi catalog/danh bạ được ghi rõ.
- **File:** feature data_export; admin XLSX/download, app/revenue/workouts;
  regression tests mới và tài liệu chi tiết bên dưới.
- **Kiểm thử:** Flutter **1.057/1.057**, analyzer sạch, admin **99/99**,
  syntax check qua, hai XLSX đọc độc lập bằng openpyxl/ZIP/XML qua;
  Inter previews **2/2** qua và đã xem. APK debug build thành công.
- **Cần cấu hình:** không phát sinh cấu hình Firebase/package mới. Muốn
  dùng trên bản cài/web hiện hữu cần cài app cập nhật và publish admin.
- **Giới hạn:** chưa kiểm tra thao tác lưu trên Android thật; các nguồn
  tải riêng, không phải snapshot nguyên tử xuyên collection; vẫn giữ
  giới hạn dữ liệu và phạm vi xuất được nêu rõ trong UI.
- **Tiếp theo đề xuất:** nghiệm thu xuất tệp trên thiết bị/trình duyệt
  production khi người dùng sẵn sàng, chưa tự thực hiện.

Chi tiết: [report-export-quality-2026-11-08.md](report-export-quality-2026-11-08.md).

## 08/11/2026 — Giai đoạn 10, độ tin cậy thư viện món/công thức

1. **Trạng thái:** hoàn tất code và kiểm thử local cho nhóm thư viện;
   không tự chuyển nhóm tiếp theo, không deploy hoặc ký release.
2. **Đã làm:** xác nhận bỏ nội dung chưa lưu (kể cả nguyên liệu), xóa
   chờ máy chủ và thử lại đúng món, chống gửi lặp, bỏ kết quả muộn khi
   đổi phiên. Kiểm tra lại nguồn sau khi nhập khẩu phần, yêu cầu chọn lại
   nếu món bị ẩn/xóa/thay đổi; nguồn thiếu macro không được thêm.
3. **File chính:** library_forms, food_library_screen, dialog xóa mới,
   ingredient_selection, food_library_quality_test và food_library_test.
4. **Kiểm thử:** suite thư viện **52/52**, toàn Flutter **1.071/1.071**,
   analyzer sạch, format sạch, preview Inter **2/2** (tám ảnh đã xem),
   APK debug build thành công; source secret audit/diff check qua.
5. **Cần người dùng làm:** không cần cấu hình mới; cài APK cập nhật
   khi muốn dùng. Android thật và release signing vẫn để sau.
6. **Giới hạn:** nháp nằm trong bộ nhớ, không phục hồi qua process death.
   Kiểm tra nguồn dùng stream đã nhận, không phải transaction xuyên nguồn.
   Chưa nghiệm thu mạng/thiết bị thật; cảnh báo KGP hiện hữu còn tồn tại.
7. **Tiếp theo đề xuất:** nghiệm thu thư viện trên Android khi sẵn sàng;
   chưa tự thực hiện.

Chi tiết và artifact: [food-library-quality-2026-11-08.md](food-library-quality-2026-11-08.md).

## 08/11/2026 — Giai đoạn 10, độ tin cậy khi xóa nhật ký

1. **Trạng thái:** hoàn tất nhóm xóa bữa ăn/nước/vận động; chưa deploy
   hoặc ký release, không tự triển khai nhóm kế tiếp.
2. **Đã làm:** hiển thị đúng bản ghi/ngày giờ, chờ ACK trong hộp xóa,
   lỗi có thể thử lại cùng ID, chặn gửi lặp và Back khi pending. Kiểm tra
   UID stream/Auth trực tiếp, đóng dialog khi đổi phiên, dispose menu cũ
   theo UID và không báo thành công muộn sang tài khoản khác.
3. **File:** journal_screen, delete_journal_entry_dialog mới,
   meal_log_section (key dòng), journal_deletion_quality_test và tài liệu.
4. **Kiểm thử:** suite nhật ký **60/60**, toàn Flutter **1.092/1.092**;
   sau tăng độ chặt của test menu đổi phiên, regression **21/21** qua lại.
   Analyzer/format sạch, preview Inter **6/6** (18 ảnh đã xem), build debug
   qua; source secret audit/diff check qua. Tổng dữ liệu còn lại khớp.
5. **Cần người dùng làm:** không cần cấu hình mới; cài APK cập nhật khi
   muốn sử dụng. Nghiệm thu Android thật/signing tiếp tục để sau.
6. **Giới hạn:** chưa có nghiệm thu mạng trên thiết bị thật; không hủy
   lệnh đã được máy chủ nhận trước khi đổi tài khoản; chưa có hoàn tác.
   Cảnh báo plugin KGP hiện hữu còn tồn tại.
7. **Tiếp theo đề xuất:** rà soát khôi phục nháp và chỉnh sửa bữa ăn;
   chưa tự thực hiện.

Chi tiết: [journal-deletion-quality-2026-11-08.md](journal-deletion-quality-2026-11-08.md).

## 09/11/2026 — Giai đoạn 10, khôi phục nháp và chỉnh sửa bữa ăn

1. **Trạng thái:** hoàn tất code và kiểm thử local cho nhóm nháp bữa ăn;
   dừng ở nhóm này, chưa deploy hoặc ký release.
2. **Đã làm:** mỗi lần sửa mới có mã riêng để giữ nháp cũ; khôi phục
   update đúng bữa và chỉ dọn nháp đã lưu. Thêm tên món/thời điểm giữ,
   nhãn sửa đúng, giữ timezone cũ, hỗ trợ bữa schema 1. Chặn mở trùng
   từ lúc tải profile/đĩa và vô hiệu thao tác cũ qua đổi phiên/dispose.
   Tiêu đề form đọc đầy đủ trên màn nhỏ khi tăng cỡ chữ.
3. **File:** journal_meal_entry, draft_picker, meal_form_dialog,
   nutrition_models, meal_draft_quality_test mới và tài liệu.
4. **Kiểm thử:** regression/preview **11/11**, toàn Flutter cuối
   **1.101/1.101**, analyzer/format sạch. Đã xem 12 ảnh Inter thật;
   build APK debug qua, source secret audit/diff check qua.
5. **Cần người dùng làm:** không cần cấu hình mới; cài APK cập nhật
   khi muốn sử dụng. Android thật/signing tiếp tục để sau.
6. **Giới hạn:** bảo vệ nháp cục bộ, chưa xử lý hai thiết bị sửa cùng
   một bữa; lần ghi máy chủ sau cùng vẫn có thể ghi đè. Chưa nghiệm thu
   mất mạng/process death trên máy thật; cảnh báo KGP hiện hữu còn.
7. **Tiếp theo đề xuất:** rà soát mục tiêu dinh dưỡng/kế hoạch bữa ăn;
   chưa tự thực hiện.

Chi tiết và artifact: [meal-draft-quality-2026-11-09.md](meal-draft-quality-2026-11-09.md).

## 09/11/2026 — Giai đoạn 10, mục tiêu dinh dưỡng/kế hoạch bữa ăn

1. **Trạng thái:** hoàn tất nhóm bảo vệ nội dung form, phiên tài khoản
   và ngày của kế hoạch; dừng tại nhóm này, chưa deploy/ký release.
2. **Đã làm:** xác nhận khi đóng/Back/đổi ngày để giữ nội dung đang sửa;
   bảo vệ số đo/lựa chọn/đề xuất cá nhân hóa và món/khẩu phần trong kế
   hoạch. Lưu lỗi giữ form, khóa gửi lặp; footer cuộn, nút kế hoạch ở
   cuối màn hình. Kiểm tra Auth trực tiếp trước ghi và dùng đồng hồ
   chung để hiển thị nút xác nhận đã ăn khi sang ngày mới.
3. **File:** nutrition_target_form, personal_nutrition_planner,
   nutrition_target_providers, MealPlannerPanel/PlanMealDialog trong
   wellness_screen; test chất lượng mới và hai test cập nhật.
4. **Kiểm thử:** toàn Flutter **1.115/1.115**, gồm **14 regression mới**;
   suite plan UI cuối **6/6**. Analyzer/format sạch, preview Inter **6/6**
   và 20 ảnh đã xem. APK debug, source secret audit/diff check qua.
5. **Cần người dùng làm:** không cần cấu hình mới; cài APK cập nhật khi
   muốn sử dụng. Android thật/signing tiếp tục để sau.
6. **Giới hạn:** nội dung form chỉ giữ trong RAM, chưa phục hồi qua
   process death/logout; chưa xử lý xung đột nhiều thiết bị sửa cùng
   mục tiêu/kế hoạch. Cảnh báo KGP của plugin hiện hữu còn.
7. **Tiếp theo đề xuất:** rà soát xóa kế hoạch và lưu gợi ý nhiều bữa;
   chưa tự thực hiện.

Chi tiết và artifact: [nutrition-plan-quality-2026-11-09.md](nutrition-plan-quality-2026-11-09.md).

## 09/11/2026 — Giai đoạn 10, xóa kế hoạch/lưu gợi ý nhiều bữa

1. **Trạng thái:** hoàn tất nhóm này; dừng sau kiểm thử và báo cáo.
2. **Đã làm:** gợi ý chỉ thêm slot trống qua transaction từng bữa, hiện
   tiến độ sau ACK và cho lưu tiếp phần chưa xác nhận. Giữ nguyên bữa đã
   có/sửa từ thiết bị khác. Xóa chờ ACK, giữ lỗi để thử lại, kiểm tra
   snapshot trước khi xóa và giữ nguyên nhật ký. Hai luồng chặn gửi lặp,
   Back lúc chờ và phiên cũ kể cả A→logout→A.
3. **File:** wellness_repository, wellness_screen; hai dialog mới;
   meal_plan_operations_test, plan_meal_repository_integration và fixture
   catalog_expansion; README, database-design và báo cáo test.
4. **Kiểm thử:** toàn Flutter **1.130/1.130**; focused cuối **34/34**;
   emulator Rules **143/143**, SDK **22/22** (9 ca mới). Analyzer/format
   sạch, preview Inter **4/4**, 14 ảnh đã xem; APK debug build qua.
   Source secret audit/diff check qua.
5. **Cần người dùng làm:** không cần cấu hình mới; cài app cập nhật khi
   muốn dùng. Android thật/signing vẫn để sau.
6. **Giới hạn:** tiến độ gợi ý chỉ trong RAM; đã commit không hoàn tác
   khi đóng. Ghi đang gửi có thể hoàn tất cho UID cũ; các bữa sau dừng.
   Chưa giải quyết xung đột chỉnh thủ công mục tiêu/kế hoạch. Cảnh báo
   plugin KGP hiện hữu còn; chưa deploy/ký release/push GitHub.
7. **Tiếp theo đề xuất:** kiểm soát xung đột khi chỉnh thủ công mục tiêu
   và kế hoạch; chưa thực hiện.

Chi tiết và artifact: [meal-plan-operations-2026-11-09.md](meal-plan-operations-2026-11-09.md).

## Giai đoạn 10 — kiểm thử vai khách hàng và admin, 09/11/2026

- **Trạng thái:** nghiệm thu một phần bằng browser thật, Firebase Emulator và
  Android AVD; chưa kết luận toàn bộ ứng dụng trơn tru.
- **Đã kiểm:** đăng ký/onboarding, nhật ký và dinh dưỡng, thao tác món/audit,
  support có chủ đề và phản hồi hai chiều, khóa/mở tài khoản, cấu hình runtime,
  xóa tài khoản liên client, báo cáo và tải XLSX. Wellness và daily reliability
  đã đạt trên Android Emulator. Bài tập admin hiện chỉ đọc 33 mục từ mã nguồn.
- **Sửa trực tiếp:** metadata Firebase JS dùng fromCache; local config thống
  kê Firestore; chữ null ở danh sách support; mô tả doanh thu theo nguồn.
  Bổ sung SDK/DOM regression và cập nhật các thao tác integration test cũ.
- **File chính:** admin-web/dist/{firebase,live-data,support-page,admin-shell}.mjs,
  config.js; admin-web/test/{realtime-sdk.integration,app-dom.test}.mjs;
  integration_test/{core,nutrition,wellness}_acceptance_test.dart;
  docs/customer-admin-acceptance-2026-11-09.md.
- **Kiểm tra:** Flutter 1.130/1.130, analyze sạch; web 99/99, SDK 9/9 và
  realtime SDK 12/12; Flutter Chrome runtime 3/3 và realtime 6/6; format,
  JS check và check:billing qua. XLSX tải bằng browser có ZIP/XML hợp lệ,
  đúng 0 dòng dữ liệu của kỳ kiểm thử. Core Android chưa chạy hết do hành
  trình cũ chưa mở phần Vận động đang thu gọn. Nutrition Android đã
  chạy hết 11 checkpoint, exit 0; gồm 28 kế hoạch, ghi một lần, xóa nhật ký
  vẫn giữ kế hoạch và chặn UID khác. Lỗi trung gian ghi ở báo cáo chi tiết.
- **Cần cấu hình thủ công:** không cần thêm cho QA local. Play Console,
  Functions/billing, AI/App Check production và thiết bị thật vẫn cần lượt
  cấu hình/nghiệm thu riêng; không deploy hoặc thu tiền trong lượt này.
- **Giới hạn:** core Android còn chưa đạt toàn kịch bản; bài tập không sửa
  từ xa; tổng Auth có chế độ snapshot thủ công. App ghép catalog bundled
  và Firestore, số mục quản trị Firestore không đại diện mọi nguồn món.
- **Lượt tiếp theo đề xuất:** tiếp tục nghiệm thu Giai đoạn 10 cho các hành
  trình Android còn thiếu; chưa triển khai giai đoạn hoặc tính năng mới.

Chi tiết: [customer-admin-acceptance-2026-11-09.md](customer-admin-acceptance-2026-11-09.md).

## 10/11/2026 — Giai đoạn 11, video hướng dẫn miễn phí

- **Trạng thái:** đã thay minh họa tự vẽ bằng nguồn video trực tuyến miễn phí
  theo lựa chọn người dùng; hoàn thiện kiểm thử và build ở lượt hiện tại.
- **Hành vi:** 13 video nguồn cho 14 động tác từ Nuffield Health, NHS
  Lanarkshire, Hinge Health, Rehab My Patient, DAREBEE. Chỉ tải player khi bấm;
  hiển thị nguồn, yêu cầu Internet, retry và mở video gốc. Hướng dẫn chữ vẫn
  dùng offline. Mở hướng dẫn pause buổi tập, đóng không tự resume.
- **File chính:** workout_tutorial.dart, workout_tutorial_player.dart,
  movement_media_preview.dart, workout_tutorial_sheet.dart, workouts_screen.dart,
  workout_session_screen.dart, pubspec.{yaml,lock}; bỏ movement_illustration.dart.
  Thêm mô tả dữ liệu YouTube ở account_information_screen.dart và README.
- **Kiểm thử:** toàn Flutter 1.183/1.183; bộ workout/video 43 test;
  Android AVD đã cue 13/13 video thật; web đã phát/tạm dừng video nhúng.
  Bản cuối format 18 file không đổi, analyze sạch, 43/43 test workout/media,
  1/1 test thông tin tài khoản và 14/14 Android mạng thật qua (13 nguồn + lỗi).
  Một lượt AVD mất DNS đã được cold boot với DNS tạm để chạy lại thành công;
  log lỗi và log thành công đều giữ trong build/exercise-video-research.
- **Cấu hình thủ công:** không cần mua media, API key hay bật Blaze. Cần
  Internet khi xem video; nếu đổi applicationId phải đổi native Referer tương ứng.
- **Giới hạn:** video là bản gốc tiếng Anh, có thể có quảng cáo/hạn chế theo
  YouTube. Plank nghiêng hai bên cùng video kỹ thuật, nhắc rõ bên trái/phải.
  Không cấp quyền tải/đóng gói offline; chưa nghiệm thu Android vật lý/ký release.
- **Bước tiếp đề xuất:** nghiệm thu trên Android thật, chưa thực hiện.

Chi tiết nguồn và quyền: [workout-media-sourcing-2026-11-10.md](workout-media-sourcing-2026-11-10.md).
- **Build cuối:** APK debug app thành công, Gradle 51,2s; bản cài ở
  `build/releases/healthmate-workout-videos-20261110-debug.apk`. Không ký release.

### Đính chính 10/11/2026 — yêu cầu GIF hoạt họa 3D

- **Trạng thái Giai đoạn 11:** chưa hoàn tất theo yêu cầu mới được làm rõ.
  Người dùng muốn GIF nhân vật 3D kiểu Gym Visual, không phải video người
  thật. Lựa chọn chỉ dùng nguồn miễn phí vẫn có hiệu lực. Phương án YouTube
  và APK ở mục trước chưa đáp ứng yêu cầu này.
- **Đã làm:** kiểm tra mẫu và giấy phép Exercise Animatic, LottieFiles,
  Pixabay. Có mẫu GIF chống đẩy sàn của DEZYNE_3D trên Pixabay, nhưng chưa
  xác minh được bộ đồng nhất đúng 14 biến thể đang có trong app.
- **File sửa trong lượt đính chính:** tài liệu tiến độ này và
  `docs/workout-media-sourcing-2026-11-10.md`; chưa sửa mã nguồn.
- **Kiểm thử:** không chạy lại format/analyze/test/build vì lượt này chỉ
  nghiên cứu nguồn và sửa tài liệu. Kết quả test cũ không xác nhận GIF.
- **Cần người dùng cấu hình:** chưa có bước cấu hình; không yêu cầu mua media.
- **Còn thiếu:** nguồn hoạt họa miễn phí đúng động tác và quyền tích hợp rõ
  ràng; sau đó mới thay player và kiểm thử hiển thị/vòng đời. Không tự đổi
  bài tập để dùng một GIF sai biến thể hoặc chuyển sang tính năng khác.

## 10/11/2026 — Giai đoạn 11, giao diện Trang chủ theo mẫu mới

- **Trạng thái:** hoàn tất phần giao diện Trang chủ và kiểm thử trong lượt.
  Phần tìm GIF tập luyện tạm gác theo yêu cầu.
- **Hành vi:** đổi nhãn tab Hôm nay thành Trang chủ; thanh chọn thứ T2–CN,
  lịch chọn ngày, vòng calo, ba chỉ số mục tiêu/đã nạp/tập luyện, thanh đạm/
  bột/béo và nút cộng tròn ở giữa thanh điều hướng. Giữ Inter và các thao
  tác ghi bữa, quét món, nước uống, mục tiêu, báo cáo đang có.
- **Giao diện:** Trang chủ dùng nền đen `#000000` trong chế độ tối, trắng
  `#FFFFFF` trong chế độ sáng; theo lựa chọn Sáng/Tối/Hệ thống hiện có.
  Màu tím chỉ làm điểm nhấn, không phủ nền hoặc làm mờ nội dung.
- **Dữ liệu:** tiếp tục dùng repository và cách tính mục tiêu hiện có.
  Calo tập luyện có nhãn ước tính, không tự cộng vào mục tiêu. Nhật ký
  thiếu calo vận động hiện số phút; lỗi/tải dữ liệu hiện dấu chờ, không bịa
  số. Các con số trong ảnh xem trước chỉ thuộc fixture trong test.
- **File chính:** `lib/core/theme/home_palette.dart`,
  `lib/core/widgets/app_shell.dart`, `dashboard_screen.dart`,
  `widgets/{home_dashboard_page,home_day_selector,home_macro_panel,mfp_calories_card}.dart`;
  `test/home_reference_test.dart` và các test giao diện hiện có.
- **Kiểm thử đã đạt:** format 14 file không còn thay đổi, analyzer không
  issue; 73/73 test hồi quy tập trung, 18/18 test Home/reference cuối.
  Toàn bộ Flutter **1.192/1.192**, exit 0; build APK debug thành công,
  Gradle 38,1 giây. Bản cài `build/releases/healthmate-home-20261110-debug.apk`;
  ảnh sáng/tối `build/home-reference/home-light-dark.png`.
- **Cấu hình thủ công:** không cần thêm Firebase, dependency hoặc billing.
- **Giới hạn:** đã xem ảnh Flutter sáng/tối và 320px với chữ 200%; chưa
  nghiệm thu trên Android vật lý hoặc ký phát hành. Cảnh báo plugin KGP
  hiện hữu vẫn còn; không nâng package ngoài phạm vi giao diện.
- **Bước tiếp đề xuất:** nghiệm thu Trang chủ trên Android thật khi người
  dùng yêu cầu; chưa thực hiện.

## 10/11/2026 — Giai đoạn 11, ảnh món ăn và ưu tiên món Việt

- **Trạng thái:** hoàn tất phần ảnh món và thứ tự gợi ý, đã kiểm thử/build.
- **Đã làm:** thêm 19 ảnh minh họa có nguồn/giấy phép vào danh sách chọn,
  hộp khẩu phần và món đã chọn. Thẻ có ảnh hiển thị kcal và đạm/bột/béo;
  món chưa có ảnh giữ dòng chữ cũ theo yêu cầu người dùng. Gợi ý đưa món
  Việt lên trước, vẫn ưu tiên độ khớp chính xác khi tìm kiếm và giữ bộ lọc.
- **Nơi lưu:** `assets/food_photos/`, tổng WebP 294.392 byte; đóng gói cùng
  app để dùng offline, không ghi Firebase/Cloud Storage. Bấm ảnh xem nguồn
  và giấy phép. Đổi/bổ sung ảnh cần cập nhật bản app. Chưa làm upload ảnh
  từ admin. Không lưu ảnh chụp bữa ăn của người dùng trong catalog.
- **File chính:** food_photo.dart, bundled_food_photos.dart,
  food_photo_thumbnail.dart, food_selection_card.dart, food_catalog_search.dart;
  meal_entry_sources.dart, meal_form_dialog.dart, meal_food_sources.dart,
  food_portion_dialog.dart; assets, pubspec.yaml và test/food_photos_test.dart.
- **Kiểm thử đã đạt:** nhóm 8 file cuối 69/69; 19/19 ảnh decode/ID/tên/license
  khớp; kiểm hash và dung lượng qua. Format 11 file không đổi; đã xem 4 ảnh
  sáng/tối ở 390px/100% và 320px/200%. Toàn bộ Flutter **1.201/1.201**, exit 0;
  analyze không issue; APK debug build qua (Gradle 32,2 giây) và kiểm ZIP có
  đủ 19 ảnh/attribution đúng hash. Bản cài
  `build/releases/healthmate-food-photos-20261110-debug.apk`.
- **Cần cấu hình:** không cần Firebase, package hoặc billing mới.
- **Giới hạn:** mới có ảnh cho 19 món đã kiểm nguồn; không gán ảnh suy đoán
  cho những món còn lại. Chưa nghiệm thu thiết bị Android vật lý/ký release.
- **Tiếp theo đề xuất:** bổ sung ảnh có kiểm nguồn cho các món còn thiếu
  nếu người dùng yêu cầu; chưa thực hiện.

Chi tiết: [food-photos-2026-11-10.md](food-photos-2026-11-10.md).

## 10/11/2026 — Giai đoạn 4 bổ sung, món Việt/đồ gói và chất lượng ảnh

- **Trạng thái:** hoàn tất dữ liệu và code, kiểm thử đã qua.
- **Đã làm:** thêm 29 công thức món Việt ghi rõ ước tính và 22 sản phẩm
  Acecook (9 Hảo Hảo, 2 phở, 4 miến, 5 hủ tiếu, 2 phở trộn). Dữ liệu nhãn
  đúng từng vị/khối lượng, nhập theo gói khô; nhắc không tính nước/topping.
- **Ảnh:** tăng 19 lên 47 ảnh, 512×512, tổng 2.025.086 byte. Thay ảnh phở
  gà có người, thay/cắt các ảnh rối; đã xem tất cả khung cuối. Nguồn CC/PD,
  metadata tác giả/giấy phép/hash đầy đủ. Món thiếu ảnh vẫn giữ dòng chữ cũ.
  Không đưa ảnh bao bì chưa rõ quyền tái sử dụng vào sản phẩm.
- **Đồng bộ dữ liệu:** đã thêm đúng 51 mục vào Firebase catalog chung;
  đọc lại xác minh 51/51 khớp và 158/158 document cũ giữ nguyên fields/timestamps.
  Catalog cloud209, local Việt213, tổng local11.220. Dry-run sau additions0,
  skipped51, conflicts0. Không thay lịch sử hoặc dữ liệu người dùng.
- **File chính:** data/food_catalog/{recipes,packaged,additions-2026-11-10}.json,
  assets/nutrition/vietnamese-foods.json, assets/food_photos/, photo registry,
  catalog_food_reader.dart, food_photo_thumbnail.dart, food_portion_dialog.dart;
  tooling build/import/photo registry và tests ảnh/đồ gói/catalog.
- **Kiểm thử cuối:** Node14/14; Flutter tập trung72/72 và hồi quy server20/20;
  toàn Flutter **1.204/1.204**, exit0, 2 phút6 giây. Analyze cuối **No issues
  found**, exit0, 14 giây; format8 file, 0 thay đổi. Đã xem ảnh Flutter
  sáng/tối, 390px/chữ100% và 320px/chữ200%, bảng nguồn và 47 ảnh WebP cuối.
- **Cấu hình thủ công:** không cần Firebase/package/billing mới. Cập nhật
  bản app để thấy ảnh mới; dữ liệu mới đã ở catalog chung app/admin.
- **Bản cài:** Android debug build qua, Gradle15 giây. APK
  `build/releases/healthmate-vietnamese-foods-20261110-debug.apk`; đã kiểm ZIP
  đủ47 ảnh đúng hash, nguồn/giấy phép và11.220 mục khớp asset. Cảnh báo plugin
  Kotlin hiện hữu chưa xử lý vì không thuộc thay đổi này.
- **Giới hạn:** ảnh đóng gói cùng app, chưa có upload ảnh động từ admin;
  nhãn sản phẩm có thể đổi theo lô, cần đối chiếu bao bì. Chưa nghiệm thu
  Android vật lý/ký phát hành, không push/deploy frontend hoặc backend.
- **Bước tiếp đề xuất:** nghiệm thu ghi bữa ăn trên Android thật; chưa thực hiện.

Chi tiết: [vietnamese-food-expansion-2026-11-10.md](vietnamese-food-expansion-2026-11-10.md).

## 10/11/2026 — Giai đoạn 4 bổ sung, 100 trái cây và 100 đồ uống

- **Trạng thái:** hoàn tất dữ liệu, bộ lọc, phát hành Firebase, kiểm thử và APK.
- **Đã làm:** chuẩn hóa 100 mục trái cây và 100 mục đồ uống; phân biệt trạng
  thái tươi/khô/đóng hộp, có đường/không đường và cách pha. Bộ chọn chính và
  bộ chọn dùng chung có Tất cả/Trái cây/Đồ uống; ưu tiên 100 mục đã rà soát
  mỗi nhóm, giữ tìm kiếm, chế độ ăn, món cần tránh và trạng thái admin ẩn.
  Đổi nhóm hủy request cũ, không xóa món đã chọn hoặc sửa nhật ký lịch sử.
- **Nguồn:** thêm 27 dòng VDD (22 trái cây, 5 đồ uống), cơ sở 240 và toàn
  offline 11.247 ID. Chuẩn hóa tên/nhóm/khẩu phần của 154 bản ghi USDA;
  dinh dưỡng và nguồn của toàn bộ 11.007 bản ghi USDA giữ nguyên. Đối chiếu
  độc lập 147 bản ghi SR và 27 dòng PDF; 63 cốc có gram weight nguồn.
  Giữ thiếu dữ liệu chất xơ/đường; loại 8 ô đường mới có mâu thuẫn với carb.
- **Đồng bộ:** Firebase healthmate-app-20261013 đã thêm 177 thực phẩm +177
  audit trong một commit nguyên tử, xác minh đọc lại; 209 document cũ giữ
  nguyên, cloud tổng 386. Review lại creates 0 / skipped 200 / conflicts 0. Không
  đổi dữ liệu cá nhân, Hosting, Rules, Functions, dependency hoặc billing.
- **File chính:** food_browse_group.dart, food_browse_index.dart,
  food_browse_filter.dart; meal_form_dialog.dart, meal_entry_sources.dart,
  meal_food_sources.dart, meal_search_controller.dart, unified_food_search_service.dart,
  food_portion_dialog.dart; fruit-drink-browse.json, fruits-drinks-2026-11-10.json,
  3 asset dinh dưỡng; tooling metadata/đối chiếu/phát hành và tests.
- **Kiểm thử:** Node 28/28; Flutter tập trung 45/45, UI/paging cuối 12/12;
  toàn bộ Flutter cuối **1.244/1.244**, exit0; analyze **No issues found**.
  Đã xem PDF nguồn và UI sáng/tối, 390px/chữ100%, 320px/chữ200%. Một lỗi
  thao tác test paging ở lượt đầu được sửa bằng cuộn nút vào vùng bấm;
  không thay assertion hoặc dữ liệu để bỏ qua lỗi.
- **Bản cài:** APK debug build qua, Gradle 62,9 giây;
  `build/releases/healthmate-fruit-drinks-20261110-debug.apk`, 238.271.433 byte.
  Đã kiểm ZIP 3 asset dinh dưỡng khớp source, đủ 11.247 ID riêng biệt.
  Cảnh báo plugin KGP hiện hữu vẫn còn; không đổi dependency ngoài phạm vi.
- **Cần người dùng làm:** cài APK mới để có bộ lọc/thứ tự và tên offline;
  app cũ nhận mục cloud mới bằng listener hiện có. Không cần cấu hình mới.
- **Giới hạn:** 100 là số mục gồm các trạng thái/giống; ảnh thiếu giữ dòng
  chữ hiện có. Chưa thêm cóc/thanh long/vú sữa do VDD thiếu lipid. Ba dòng
  Foundation giữ nguồn hiện có, không tuyên bố kiểm lại archive chưa có.
  Chưa nghiệm thu Android vật lý hoặc ký phát hành.
- **Bước tiếp đề xuất:** nghiệm thu chọn/ghi trái cây và đồ uống trên Android
  thật khi người dùng yêu cầu; chưa thực hiện.

Chi tiết: [fruit-drink-catalog-2026-11-10.md](fruit-drink-catalog-2026-11-10.md).

## 10/11/2026 — Giai đoạn 4 bổ sung, bộ lọc 10 nhóm thực phẩm

- **Trạng thái:** hoàn tất phân loại, UI, kiểm thử và bản cài debug.
- **Đã làm:** 10 nhóm với Thịt riêng, Cá & hải sản riêng; có Món ăn Việt,
  Trái cây, Rau củ, Trứng & sữa, Ngũ cốc/đậu/hạt, Đồ uống, Đồ đóng gói và
  Tất cả. Thanh nhóm cuộn ngang và menu toàn bộ nhóm, tự đưa nhóm chọn vào
  vùng nhìn thấy; nhãn dài xuống dòng ở màn hình nhỏ/chữ lớn.
- **Nghiệp vụ:** cả hai bộ chọn đều kết hợp tìm kiếm, chế độ ăn, món cần
  tránh và trạng thái ẩn của admin; đổi nhóm giữ snapshot món đã chọn.
  Tách trứng khỏi category Thịt và trứng; giữ phở bò/bún thịt nướng trong
  Món ăn Việt. Sữa thực vật không thuộc sữa động vật; sữa chua đóng gói có
  thể thuộc cả Trứng & sữa và Đồ đóng gói. Không sửa dinh dưỡng/lịch sử.
- **File chính:** food_browse_group.dart, food_browse_filter.dart,
  food_browse_groups_test.dart và báo cáo nhóm thực phẩm.
- **Kiểm thử:** format 3 file, 0 thay đổi; analyze No issues found, exit 0,
  34 giây; tập trung16/16; toàn Flutter **1.252/1.252**, exit 0, 3 phút18
  giây. Đã xem ảnh sáng390px/chữ100%, tối320px/chữ200%; kiểm thử đủ10 nhóm,
  nhãn không bị cắt và món đã chọn giữ đúng kcal/khẩu phần.
- **Bản cài:** debug APK qua, Gradle53,7 giây;
  `build/releases/healthmate-food-groups-20261110-debug.apk`, 238.279.331 byte.
  Cảnh báo plugin KGP hiện hữu vẫn còn; không nâng dependency ngoài phạm vi.
- **Cần người dùng làm:** cập nhật app để thấy bộ lọc mới; không cần cấu
  hình Firebase/billing. Không ghi dữ liệu cloud, deploy hoặc push Git.
- **Giới hạn:** món chưa đủ metadata hoặc món tổng hợp vẫn ở Tất cả; các
  nhóm có thể giao nhau hợp lý. Chưa nghiệm thu Android vật lý/ký release.
- **Tiếp theo đề xuất:** nghiệm thu bộ lọc trên Android thật khi được yêu
  cầu; chưa thực hiện.

Chi tiết: [food-browse-groups-2026-11-10.md](food-browse-groups-2026-11-10.md).

## 10/11/2026 — Giai đoạn 10, sửa VS Code chạy web nhầm task Android

- **Trạng thái:** hoàn tất sửa cấu hình, build và smoke test trình duyệt.
- **Đã làm:** thêm HealthMate App (Web - Chrome) và (Web - Edge), pin đúng
  deviceId và nạp hai config chung trực tiếp. Đổi launcher cũ thành
  HealthMate App (Android); giữ App Check Android riêng. Web không còn phụ
  thuộc file app-check-debug-token.txt hoặc task chuẩn bị Android.
- **File chính:** .vscode/launch.json, README.md,
  tool/prepare_vscode_android.test.cjs và báo cáo sửa lỗi web.
- **Kiểm thử:** Node5/5, exit0; analyze No issues found, exit0,14,1 giây;
  build web JavaScript qua, exit0,68 giây. Đã mở bản build localhost:7357
  bằng trình duyệt và thấy màn hình đăng nhập HealthMate. Không thay Dart,
  không chạy lại full Flutter tests trong lượt sửa launcher này.
- **Cần người dùng làm:** chọn mục Web - Chrome hoặc Web - Edge rồi F5.
  Không cần token Android/Firebase/billing mới cho khởi động web.
- **Giới hạn:** chưa bấm F5 trực tiếp trong VS Code, chưa đăng nhập tài khoản
  thật trên Chrome/Edge; không xác nhận các tính năng Android trên web.
  Wasm dry run còn cảnh báo mobile_scanner hiện hữu; build JavaScript qua.
- **Bước tiếp đề xuất:** nghiệm thu các luồng web người dùng cần; chưa làm.

Chi tiết: [web-launch-fix-2026-11-10.md](web-launch-fix-2026-11-10.md).

## 10/11/2026 — Giai đoạn 4 bổ sung, nhật ký dinh dưỡng theo giờ

- **Trạng thái:** hoàn tất giao diện, nghiệp vụ phân nhóm và kiểm thử.
- **Đã làm:** món ghi09:30 tự vào khung09:00, giữ giờ chính xác; mỗi giờ có
  nút+, tổng kcal/đạm/carb/chất béo và thẻ từng món với ảnh/khẩu phần. Giờ
  khuya thu gọn khi trống, tự hiện khi có dữ liệu stream mới. Giữ CRUD bữa,
  xác nhận xóa, bản nháp, account guard và stream repository hiện có.
- **Dữ liệu:** dùng snapshot thật; dưỡng chất thiếu giữ chưa biết, món thiếu
  ảnh giữ chữ. Dữ liệu cũ không cần migration; loại bữa vẫn được giữ trong
  bản ghi. Phân nhóm/sắp xếp dùng giờ tại offset đã lưu, gồm món legacy
  thiếu offset. Sửa giờ tự chuyển nhóm, không nhân đôi hoặc đổi tổng ngày.
- **Giao diện:** Inter hiện có; nền đen ở chế độ tối, trắng ở chế độ sáng;
  bốn thanh mục tiêu thật theo ngày, bảng chi tiết dinh dưỡng vẫn truy cập
  được. Đã xem ảnh390px/chữ100% sáng/tối và320px/chữ200%.
- **File chính:** meal_timeline.dart, hourly_meal_timeline.dart,
  journal_screen.dart, journal_nutrition_overview.dart,
  journal_date_provider.dart, meal_log_section.dart và test nhật ký.
- **Kiểm thử:** format16 file,0 thay đổi; analyze No issues found, exit0,
  121,1 giây; tập trung51/51 và14/14 trước bổ sung ca mixed-offset; toàn
  Flutter cuối **1.261/1.261 qua**, exit0,2 phút59 giây. Có9 test timeline
  mới. Đã sửa thao tác cuộn trong test camera200%, giữ assertions.
- **Android:** build debug qua, exit0,Gradle60,5 giây;
  `build/releases/healthmate-hourly-journal-20261110-debug.apk`,
  238.290.841 byte. Cảnh báo KGP từ plugin hiện hữu còn.
- **Web:** JavaScript build qua, exit0,79,1 giây, output `build/web`;
  Wasm dry run còn cảnh báo mobile_scanner hiện hữu. Không deploy hosting.
- **Cần người dùng làm:** cài/chạy lại app để thấy giao diện mới; không cần
  cấu hình Firebase/billing. Không deploy hoặc ghi dữ liệu cloud trong lượt.
- **Giới hạn:** chưa nghiệm thu Android vật lý, chưa chạy lại Firebase
  integration và chưa ký bản phát hành. Hai kịch bản integration đã cập
  nhật selector theo UI mới và qua analyzer.
- **Tiếp theo đề xuất:** nghiệm thu nhật ký theo giờ trên điện thoại thật
  khi được yêu cầu; chưa thực hiện.

Chi tiết: [hourly-journal-2026-11-10.md](hourly-journal-2026-11-10.md).

## 10/11/2026 — Giai đoạn tùy chọn 11, font theo phong cách X

- **Trạng thái:** hoàn tất đổi font app/web admin và kiểm thử giao diện.
- **Đã làm:** Public Sans là font giao diện chung, đóng gói offline với
  bốn độ đậm 400/500/600/700. Mỗi TTF đủ 134 ký tự tiếng Việt có dấu;
  kiểm tra tám checksum nguồn và hai bản giấy phép SIL OFL 1.1 đều qua.
  Public Sans được chọn theo phong cách X; Chirp là font thiết kế riêng
  của X. Giữ cỡ chữ/độ đậm/màu/bố cục hiện có.
- **File chính:** design_tokens.dart, pubspec.yaml,
  assets/fonts/public_sans/, admin-web/dist/style.css,
  admin-web/dist/fonts/public_sans/, appearance.css, browser-identity.cjs,
  README app/admin và font loader trong 30 file kiểm thử.
- **Kiểm thử:** format31 file; analyze No issues found, exit0,124,1 giây;
  Flutter **1.261/1.261 qua**, exit0,2 phút36 giây. Admin check qua,
  Node **113/113 qua**, exit0; browser QA8 cấu hình/72 lượt trang, sáng/tối
  ở320/390/1024/1440px,0 lỗi và0 lần ghi production. Browser xác nhận
  bốn độ đậm đã tải thành công từ bundle. Đã xem ảnh Trang chủ sáng,
  Nhật ký tối320px/chữ200% và admin tối390px.
- **Cần người dùng làm:** khởi động/cài lại bản app mới; tải lại web admin
  khi bản này được chạy/publish. Không cần cấu hình Firebase hoặc billing.
- **Giới hạn:** chưa nghiệm thu font trên điện thoại thật; không thay font
  trong nội dung XLSX. Không deploy, ghi cloud hoặc push Git trong lượt.
- **Tiếp theo đề xuất:** nghiệm thu font trên Android thật khi được yêu
  cầu; chưa thực hiện. Phần GIF tập luyện vẫn tạm gác theo yêu cầu.

Chi tiết: [x-style-typography-2026-11-10.md](x-style-typography-2026-11-10.md).

- **Bản build đã xác minh:** APK debug qua, exit0,Gradle24,9 giây;
  `build/releases/healthmate-public-sans-20261110-debug.apk`,238.291.163 byte.
  Đã kiểm tra FontManifest trong APK: Public Sans có4 file font, kèm
  OFL.txt. Web JavaScript build qua, exit0,83 giây, output `build/web`.
  Cảnh báo KGP/plugin và mobile_scanner Wasm dry run hiện hữu còn;
  không chặn hai bản build. Chưa ký bản phát hành/publish hosting.

## 10/11/2026 — Giai đoạn 10 bổ sung, luồng đăng ký Premium Google Play

- **Trạng thái:** hoàn tất source và kiểm thử local; chưa mở bán hoặc
  nghiệm thu mua qua Google Play thật/sandbox.
- **Đã làm:** trang Premium có quyền lợi, giá từ Google, điều khoản gia
  hạn và quyền riêng tư. Chặn mua lại khi receipt trước chưa xác minh xong;
  ưu tiên khôi phục. Khi quay về foreground tự truy vấn lại giao dịch,
  giữ một observer/listener theo phiên và cleanup khi đăng xuất. Chờ stream
  membership xác nhận trước khi hiện kích hoạt; cờ active từ response chỉ
  chặn mua lặp. Hiển thị đúng canceled còn hạn/grace/hold/paused/pending/
  expired; link quản lý mở đúng package/product, có hướng dẫn khi mở lỗi.
- **File chính:** play_billing_models.dart, play_billing_controller.dart,
  play_billing_providers.dart, play_premium_screen.dart,
  test/play_premium_flow_test.dart, play_billing_test.dart và README.
  Không thêm package, collection/index hoặc thay Rules/backend.
- **Kiểm thử:** format14 file,0 thay đổi; analyze cuối No issues found,
  exit0,33,7 giây; tập trung39/39 và toàn Flutter **1.282/1.282 qua**,
  exit0,3 phút09 giây. Có21 test mới. Functions syntax và **29/29 test**
  qua, exit0. Đã xem ảnh Premium tối320px/chữ100%; kiểm thử đủ sáng/tối
  và chữ200%. Ảnh/giá/receipt fixture chỉ dùng local, không ghi cloud.
- **Cần người dùng làm:** Play Console/app, package/signing/Firebase tương
  ứng, subscription/base plan tháng thật; khi sẵn sàng bật Blaze thì cấu
  hình/deploy Functions/Publisher IAM/App Check/RTDN và nghiệm thu internal
  testing. Billing/demo tiếp tục giữ cổng cấu hình hiện có.
- **Giới hạn:** chưa có bằng chứng mua/gia hạn/hoàn Google thật hoặc sandbox,
  chưa nghiệm thu Android vật lý/ký phát hành. Không triển khai máy chủ,
  publish hoặc push Git trong lượt.
- **Tiếp theo đề xuất:** cấu hình Play Console/Blaze và nghiệm thu Google
  Play sandbox khi được yêu cầu; chưa thực hiện.

Chi tiết: [premium-subscription-flow-2026-11-10.md](premium-subscription-flow-2026-11-10.md).

- **Bản build cuối:** APK debug qua, exit0,Gradle36,7 giây;
  `build/releases/healthmate-premium-flow-20261110-debug.apk`,238.301.480
  byte. Cấu hình debug hiện tại không bật Play Billing; không mở thu tiền.
  Web JavaScript build qua, exit0,97,9 giây, output `build/web`.
  Cảnh báo KGP/plugin và Wasm dry run mobile_scanner hiện hữu còn.
  Audit812 source text files có0 findings; không phải audit APK/credential.


## 10/11/2026 — Giai đoạn 4 bổ sung, danh mục 500 mục và ảnh

- **Trạng thái:** đã mở rộng/phát hành catalog 500 mục; ảnh mới đạt 86/500,
  chưa hoàn thành ảnh cho toàn danh mục.
- **Đã hoàn thành:** thêm 114 mục VDD có bằng chứng ô bảng, trong đó có 17
  mục đồ hộp/mứt; giữ 100 g phần ăn được, không tự đặt trọng lượng lon hoặc
  đổi ml thành g. Mục không có hãng ghi rõ tham khảo/không nhãn hàng. Giữ
  bộ lọc và danh sách gợi ý trái cây/đồ uống. Thêm 35 ảnh đúng món, nguồn
  Commons/OFF có giấy phép; tổng 86 ảnh. Mục chưa có ảnh giữ dạng chữ.
- **File chính:** data/food_catalog/catalog-500-selection.tsv,
  expanded-vietnamese-2026-11-10.json, catalog-500-photo-selection.json;
  tool/extract_catalog_reference.py, build_catalog_500_reference.py,
  build_catalog_500_photos.py, publish_catalog_500.cjs, import_food_catalog.cjs;
  assets/nutrition/vietnamese-foods.json, assets/food_photos/manifest.json,
  bundled_food_photos.dart và ảnh/registry admin dist; test catalog/photo.
- **Phát hành:** review-v2 386 existing/114 creates/0 conflict. Apply đọc lại
  xác minh 114 mục mới, 386 document cũ giữ nguyên, 114 audit, tổng 500.
  Review sau phát hành: 500 existing/0 creates/114 skipped. Không ghi users/*
  hoặc thay Rules, không deploy hosting/Functions, không bật billing.
- **Kiểm thử:** analyze No issues found, exit0; Flutter cuối 1.282/1.282 qua,
  2 phút32 giây; Node24/24, admin113/113 qua. Scoped format6 file0 thay đổi.
  Format toàn lib/test/tool phát hiện lib/main.dart từ thay đổi trước cần
  format; không sửa ngoài phạm vi. Python compile7 công cụ qua. Diff check
  qua. Secret source audit817 tệp/0 findings, không phải audit APK.
- **Bản chạy:** APK debug qua, Gradle25,5 giây; 238.312.985 byte,
  build/releases/healthmate-catalog-500-20261110-debug.apk. Mở ZIP kiểm tra
  86 ảnh đúng hash và354 mục core. Tổng offline11.361 ID gồm nguồn USDA;
  không dùng số này thay cho500 mục chung. Web JavaScript build qua95,2 giây.
- **Cần người dùng làm:** cài APK/chạy source mới để nhận ảnh offline;
  catalog500 đã có trên Firebase và dùng listener hiện có. Admin dist mới
  chưa publish hosting. Không yêu cầu cung cấp tài khoản/secret mới.
- **Giới hạn:**414 mục chưa có ảnh đạt yêu cầu. Nguồn miễn phí giới hạn tải;
  không thêm ảnh sai để lấp chỗ trống. VDD2007 là tham khảo, không phải nhãn
  hãng hiện hành; cellulose không phải tổng chất xơ. Cảnh báo KGP/Wasm hiện
  hữu còn. Chưa nghiệm thu điện thoại thật/ký phát hành, không push Git.
- **Tiếp theo đề xuất:** hoàn thiện ảnh và nhãn hãng đã xác minh của chính
  danh mục này; chưa chuyển sang giai đoạn/tính năng khác.

Chi tiết: [catalog-500-2026-11-10.md](catalog-500-2026-11-10.md).

## 11/11/2026 — Giai đoạn 4 bổ sung, chỉ giữ mục có ảnh

- **Trạng thái:** hoàn tất theo yêu cầu mới “Bỏ món đó nếu ko có ảnh”. Bộ 500
  mục giữ 379 mục có ảnh, ẩn 121; nhóm gợi ý trái cây/đồ uống còn 87/80.
- **Đã làm:** bổ sung 293 ảnh ròng so với 86 ảnh trước; WebP512×512 có nguồn,
  crop/checksum/attribution, cùng ảnh trên app/admin. Rà toàn bộ contact
  sheets; loại hai ảnh cuối chưa đúng món/trạng thái. Áp dụng loại trừ
  offline cho catalog/cache/bí danh USDA; giữ món riêng và lịch sử bữa ăn.
  Ảnh custom hợp lệ cho phép admin khôi phục; trạng thái ẩn vẫn ưu tiên.
  Admin chặn bật lại mục bị loại nếu chưa có ảnh, dẫn sang chỉnh ảnh.
- **File chính:** data/food_catalog/photo-release.json, full-photo-selection.json;
  assets/food_photos/, bundled_food_photos.dart, bundled_food_photo_visibility.dart;
  food_visibility.dart, nutrition_providers.dart, unified_food_search_service.dart;
  tool/stage_full_food_photos.py, build_food_photo_registry.cjs,
  build_admin_food_photos.cjs, publish_photo_visibility.cjs và test;
  admin-web/dist/{bundled-food-photos,food-photos,validation,app}.mjs và ảnh.
- **Firebase:** apply121 cập nhật và121 audit, đọc lại xác minh379 document
  còn lại nguyên vẹn. Tổng500 document:379 active/121 inactive. Review sau
  apply0 updates/121 already-inactive/0 conflict. Chỉ đổi visibility và
  thông tin audit; không ghi users/*, sửa dinh dưỡng hay xóa document.
- **Kiểm thử:** format9 file0 thay đổi; analyze cuối No issues found,
  exit0,14,2 giây. Flutter cuối **1.289/1.289 qua**, exit0,2 phút11 giây;
  Node catalog/photo/publisher **31/31 qua**; admin check và **115/115 qua**.
  Python compile công cụ qua. Source secret audit833 tệp/0 findings;
  không phải audit APK/credential. Diff check qua, có cảnh báo CRLF hiện hữu.
- **Chỉnh test có lý do:** giờ thật00:55 khiến fixture chọn07:00 hôm nay bị
  chặn đúng nghiệp vụ; chuyển helper sang hôm qua. Fixture cá chép bị loại
  đổi sang cá rô phi cùng nhóm còn ảnh. Một lỗi shader transient ở lượt đầu
  không tái hiện khi chạy riêng và toàn suite cuối. Không bỏ assertion.
- **Bản chạy:** APK debug qua, Gradle40,7 giây;
  build/releases/healthmate-food-photos-20261111-debug.apk,238.402.763 byte.
  Mở ZIP xác minh manifest và379 ảnh đúng hash. SHA256:
  d8f581c26b8ac46e1828a45dbf8b7e7d14d598dbb7f4d56468572a4b2d2838d9.
  Web JavaScript build qua, exit0,64,7 giây, output build/web.
- **Cần người dùng làm:** cài/chạy app mới để nhận ảnh asset; admin local
  tải lại bản dist mới. Trạng thái ẩn đã cập nhật Firebase. Chưa publish
  hosting nên admin online chưa nhận asset mới; không cần billing/config mới.
- **Giới hạn:** scope là500 mục chung, không xóa các bộ USDA tham khảo khác
  hoặc món riêng. Sáu mục cũ nhận dinh dưỡng từ Firestore. Cảnh báo KGP và
  Wasm mobile_scanner hiện hữu; chưa nghiệm thu Android thật/ký phát hành.
  Không deploy Functions/Rules, push Git hoặc thay kiến trúc.
- **Tiếp theo đề xuất:** Giai đoạn tùy chọn11 — nghiệm thu ảnh trên bản
  admin được triển khai khi người dùng yêu cầu; chưa thực hiện.

Chi tiết: [food-photo-release-2026-11-11.md](food-photo-release-2026-11-11.md).

## 11/11/2026 — Giai đoạn 4 bổ sung: phát hành ảnh admin và bộ lọc

- Đã hoàn thành và deploy https://healthmate-admin-vn.web.app: Sửa ảnh tại từng dòng,
  xác minh ảnh custom tải được, 10 nhóm như app, lọc/tìm toàn kết quả trước phân trang,
  kết hợp trạng thái và dùng cùng bộ lọc khi xuất Excel.
- File chính: admin-web/dist/app.mjs, live-data.mjs, food-photos.mjs, list-model.mjs,
  food-browse-groups.mjs, food-browse-metadata.mjs; generator
  tool/build_admin_food_browse_groups.cjs; các test Node/DOM/SDK/browser liên quan.
- Kiểm thử: syntax qua; admin129/129, exact Rules14/14, SDK14/14; browser72 lượt
  trang/8 theme-kích thước. Không sửa Dart nên không chạy lại Flutter trong lượt này.
- Rules chỉ bổ sung catalog photo/extra nutrients từ baseline production đã sao lưu;
  không đưa các chênh lệch local ngoài phạm vi lên. Deploy exit0,430 tệp/379 ảnh.
  HTTP14 URL khớp hash/no-store/CSP; Rules đọc lại khớp bản đã kiểm thử.
- Cần người dùng: tải lại tab admin; app trên thiết bị cần bản hỗ trợ metadata ảnh.
  URL ảnh HTTPS cần public và có quyền sử dụng; chưa có upload tệp.
- Giới hạn: chưa thao tác ghi bằng tài khoản admin thật trên production; không test
  Android thật. Không thêm billing/Functions. Toàn kết quả có giới hạn5.000 món.
- Đề xuất tiếp theo: nghiệm thu thực tế admin/app khi được yêu cầu; dừng giai đoạn.

Chi tiết: [admin-food-release-2026-11-11.md](admin-food-release-2026-11-11.md).

## 11/11/2026 — Giai đoạn 10 bổ sung: sửa quyền người dùng đang bị chặn

- Đã sửa tương thích production: support topic bug/suggestion theo8 chủ đề,
  lưu mục tiêu saltGLimit/sugarGLimit/fiberGTarget nullable, đọc membership riêng.
  Không nâng người dùng thành admin, không mở quyền ghi catalog/billing hoặc UID khác.
- Nguyên nhân: Rules phát hành thiếu field/match mà repository hiện tại đã dùng.
  Tái hiện trên bản production:16/16 tổ hợp support và1 ca marker target bị từ chối.
- Đã deploy chỉ firestore:rules, exit0. Đọc lại source/live khớpSHA52970f1cd1f96944234ce6567d133f57cabbf7982f2ff4c6811c085d15cbaaae,
  ruleset38076bf8-ba26-4578-a415-0233e508c4aa. Không ghi dữ liệu thử production.
- File chính: firestore.rules (contract đã có, nay triển khai đầy đủ),
  rules-tests/user-support-permissions.rules.test.cjs,
  rules-tests/firestore.rules.test.cjs, tool/test_operations_local.cjs,
  tool/reset_operations_emulator.cjs và báo cáo user-permissions-2026-11-11.md.
- Kiểm thử:170/170 Rules,63/63 Flutter SDK Chrome với Auth/Firestore Emulator,
  contract release1/1, syntax/diff-check qua. flutter analyze --no-pub sạch;
  flutter test --no-pub --reporter json1289/1289 qua,137,5s. Không sửa Dart,
  không chạy format hoặc build APK lại. Test negative quyền vẫn được giữ nguyên.
- Cần người dùng: mở lại mục Hỗ trợ/thử gửi lại, không cần APK mới cho Rules.
  Hạn mức3 yêu cầu mới/ngày VN và60giây giữa hai yêu cầu vẫn có hiệu lực;
  trả lời trong yêu cầu cũ không tiêu tốn hạn mức tạo mới.
- Giới hạn: chưa nghiệm thu điện thoại thật/tài khoản người dùng thật. Không bật
  Play billing/AI/Blaze; tài khoản chưa xác minh, bị khóa hoặc đang xóa vẫn bị chặn.
  Compiler cảnh báo knownNumber chưa dùng từ trước, không chặn deploy.
- Đề xuất tiếp theo: nghiệm thu người dùng/admin trên thiết bị thật khi được yêu cầu;
  không thực hiện thêm giai đoạn trong lượt này.

Chi tiết: [user-permissions-2026-11-11.md](user-permissions-2026-11-11.md).

## 11/11/2026 — Giai đoạn 1 bổ sung: tab Tập luyện và Tiến độ

- Đã hoàn thành thứ tự5ô: Trang chủ/Nhật ký/Thêm món/Tập luyện/Tiến độ.
  Workout mở danh sách thật và có trạng thái chọn; Cá nhân mở qua avatar Trang chủ.
- File chính: lib/core/widgets/app_shell.dart, lib/core/router/app_router.dart;
  các test navigation/icon/widget/profile-entry và test/support/test_app.dart.
  Workouts thêm branch7, giữ chỉ số nhánh/URL cũ. Chi tiết và timer dùng root
  navigator riêng, không để tab bỏ qua xác nhận thoát buổi tập.
- Kiểm thử: dart format12file qua; flutter analyze --no-pub sạch (12s);
  focused navigation/icon/core49/49, player20/20, fullcuối1289/1289 (134,6s),
  exit0 từng lệnh; diff-check qua. Đã xem ảnh UI có đúng thứ tự tab.
- Lượt fullđầu phát hiện19lỗi player vì session nằm sau trangdetailroot;
  đã đặt parentNavigatorKeyroot riêng cho session, giữ test/luồng thoát và
  chạy lại focused+full qua. Không che lỗi hoặc giảmassertion.
- Cần người dùng: hot restart nếu chạy từ source; APK cũ cần build/cài bản mới
  để nhận UI. Không có cấu hình Firebase mới hoặc cập nhật dữ liệu.
- Giới hạn: không build/deployAPK hoặc nghiệm thu Androidthật tronglượt này.
- Tiếp theo đề xuất: kiểm giao diện thiết bị khi yêu cầu; dừng trong scope UI.

Chi tiết: [bottom-navigation-2026-11-11.md](bottom-navigation-2026-11-11.md).

## 11/11/2026 — Giai đoạn 1 bổ sung: khung nhóm nội dung bo nhẹ

- Hoàn thành polish Flutter: viền card mảnh, bộ lọc/chip bo 12 px, trạng thái
  chọn rõ; AppInsetPanel nhóm nội dung mà không gộp thao tác/semantics.
- Trang chủ nhóm ngày, calo, bảng dưỡng chất và nút chuyển; Nhật ký nhóm chọn
  ngày; Tiến độ nhóm thời gian/tuần; Tập luyện nhóm bộ lọc và thông tin buổi tập;
  màn chọn món nhóm thanh lọc. Giữ font và canvas Home đen/trắng hiện tại.
- File chính: core/theme và widgets app_card/app_inset_panel/reference_segments;
  dashboard/widgets, journal_date_selector, progress_screen, workouts_screen,
  food_browse_filter; home_reference_test thêm ảnh kiểm tra phần dưới.
- Kiểm thử thật: format 15 file qua; focused 130/130; full 1289/1289, không
  fail/skip, 136846 ms; analyze cuối sạch 11,8s; diff-check qua. Đã xem ảnh
  light/dark, 320 px chữ 2×, dưỡng chất, bữa ăn/nước và Progress.
- Cần người dùng: hot restart khi chạy từ source; APK cũ cần build/cài lại.
  Không cần cấu hình Firebase mới. Không build/deploy APK hoặc web trong lượt này.
- Giới hạn: chưa nghiệm thu Android vật lý; kiểm tra widget dùng fixture.
- Đề xuất tiếp: nghiệm thu giao diện trên thiết bị khi được yêu cầu; dừng scope UI.

Chi tiết: [rounded-ui-2026-11-11.md](rounded-ui-2026-11-11.md).

## 11/11/2026 — Giai đoạn 1 bổ sung: Phosphor từ nguồn Figma và hình khối mới

- Thay icon app sang Phosphor 2.1.2, đối chiếu plugin Figma chính thức và
  giấy phép MIT. Bộ font offline 32.892 byte/125 glyph/142 aliases, giữ đủ
  138 tên cũ, thêm 4 icon tab được chọn dạng fill. Regular cho thao tác/tab
  chưa chọn; fill cho nhiều nội dung và tab đang mở. Không thêm dependency app.
- Card dùng góc cong liền, giảm viền/hộp lồng; nhóm bữa ăn thành một mặt nền
  với đường phân cách. Giữ nền Home đen/trắng, font Public Sans và nghiệp vụ.
- File chính: core/theme/app_icons+app_shapes+theme, core/widgets, dashboard;
  assets/fonts/healthmate_icons và build_app_icons.py; icon_system_test.dart.
  Admin giữ Lucide: snapshot nguồn/generator/test được tách khỏi font app;
  không đổi icon runtime admin, không deploy.
- Kiểm thử: font/hash/license/aliases qua và rebuild cùng hash; format 14 file
  qua; focused 94/94; full cuối 1289/1289, 0 fail/skip, 140238 ms, exit 0;
  analyze sạch; Node appearance 5/5. Đã xem ảnh icon/Home sáng/tối và bữa ăn.
- Cần người dùng: dừng/chạy lại app để nạp font; APK cũ cần build/cài lại.
  Không có cấu hình Firebase/billing mới. Chưa build APK hoặc nghiệm thu Android thật.
- Đề xuất tiếp: nghiệm thu giao diện trên thiết bị khi được yêu cầu; dừng scope UI.

Chi tiết: [phosphor-ui-2026-11-11.md](phosphor-ui-2026-11-11.md).

## 11/11/2026 — Giai đoạn 6 bổ sung: 50 động tác và admin realtime

- Hoàn thành source bản kiểm thử phi thương mại đã được người dùng chọn:
  50 ID ExerciseDB đã đối chiếu API, hướng dẫn tiếng Việt tự biên soạn,
  tìm không dấu/lọc nhóm cơ/dụng cụ, GIF theo yêu cầu và release gate.
- Admin thêm/sửa/gỡ/khôi phục, lọc/xuất; Firestore exercise_library đồng bộ
  với app, có audit nguyên tử, optimistic concurrency và quyền admin thực.
  Gỡ bằng tombstone, không sửa lịch sử tập. Cache chưa xác nhận không làm
  sống lại bài đã gỡ; request và codec được dọn khi đóng/ẩn/chuyển nền.
- File chính: activity models/data/providers/presentation, router;
  data/workouts/exercise-library.json + generator + bundle Dart/JS;
  admin workouts-page/exercise-library-model/firebase/live-data và Rules.
  Chi tiết schema đã ghi trong database-design.md; thêm các test tương ứng.
- Cuối cùng: format 15 file sạch; generator check 50/50; analyze sạch 18s;
  full Flutter **1317/1317**, 0 fail/skip, exit0, 137133ms;
  admin **138/138**, syntax check qua; Rules bài tập **4/4** (có realtime
  server snapshot), Rules admin hiện có **14/14** qua trong lượt kiểm tra trước.
  Đã mở widget thật trên web local và thấy GIF ExerciseDB hiển thị.
- Chưa deploy Rules/web/app, chưa ghi production, không thêm phí/dependency.
  Cần cập nhật cả app/web/Rules cùng project khi phát hành kiểm thử thực tế;
  admin GIF local dùng emulator hoặc enableFreeExerciseMedia:true.
  GIF free chỉ phi thương mại/180p/cần Internet, API có thể giới hạn lượt gọi;
  bản thương mại cần quyền phù hợp. Chưa nghiệm thu Android vật lý/ký release.
- Đề xuất tiếp: nghiệm thu thiết bị khi người dùng yêu cầu; không thực hiện.

Chi tiết: [exercise-library-2026-11-11.md](exercise-library-2026-11-11.md).

## 11/11/2026 — Giai đoạn 7 sửa lỗi UX kế hoạch ngoài phạm vi

- Tái hiện trường hợp người dùng cung cấp175cm/55kg, mục tiêu tăng tới64kg:
  BMI17.96 bị bộ ước tính chặn ở ngưỡng18.5 hiện hành, không do đích64kg.
- Đổi thông báo chung thành BMI/số đo/phạm vi cụ thể; không đổi công thức hay
  ngưỡng nghiệp vụ. Thêm nút kiểm tra thông tin và mở form mục tiêu thủ công;
  hủy form giữ đầu vào, lưu chỉ sau xác nhận. Đổi lựa chọn xóa lỗi cũ.
- File chính: personal_nutrition_plan.dart, personal_nutrition_planner.dart,
  test/nutrition_plan_scope_test.dart; cập nhật personalized-nutrition.md.
- Kiểm thử: 3 suite hồi quy61/61 qua; 4 ca mới qua; format3file sạch,
  diff-check qua. Phân tích toàn repo phát hiện1lint async BuildContext trong
  code mới, đã thêm mounted guard; analyze3file cuối sạch, exit0,6.3s.
- Cần người dùng: tải lại/chạy lại app local. Chưa deploy, không cần Firebase
  config mới. Đề xuất tự động vẫn giới hạn BMI hiện tại/đích18.5..<40; trường
  hợp ngoài phạm vi tiếp tục chọn mục tiêu sức khỏe và nhập mốc được tư vấn riêng.
- Đề xuất tiếp: nghiệm thu luồng trên bản local của người dùng; không triển khai
  giai đoạn khác hoặc đổi chính sách BMI trong lượt sửa này.

## 11/11/2026 — Sửa lỗi không lưu được món trên admin online

- Phạm vi Giai đoạn 4 bảo trì; đã sửa và phát hành lên admin online. Map ảnh/
  dinh dưỡng đổi thứ tự key bị so sánh sai, làm audit lệch với Firestore và bị
  từ chối quyền. So sánh cấu trúc không phụ thuộc thứ tự map, giữ thứ tự array.
- File chính: validation.mjs, app.mjs (nhãn/hint nguồn dinh dưỡng),
  validation.test.mjs và realtime-sdk.integration.mjs trong admin-web.
- Check syntax qua; admin unit **140/140**, realtime SDK **15/15**, SDK hồi quy
  **9/9** qua với đúng Rules production trên emulator. Regression với module
  gói Hosting thực tế **1/1** qua. Không sửa Flutter nên không chạy lại bộ Dart.
- Chỉ deploy Hosting, upload 2 file, exit0. Đọc lại 5 URL khớp bytes/header;
  Rules không đổi, không ghi dữ liệu kiểm thử production hoặc đổi quyền admin.
- Cần người dùng giữ URL đang nhập, Ctrl+F5 rồi mở món/lưu lại. Ảnh chỉnh ở
  phần Ảnh món ăn; nguồn dinh dưỡng giữ trang cung cấp số liệu.
- Giới hạn: chưa lưu bằng phiên admin thật. Đề xuất tiếp: nghiệm thu thao tác
  đang lỗi trên trình duyệt người dùng; không mở giai đoạn khác.
- Chi tiết/log: docs/admin-food-save-fix-2026-11-11.md và
  build/admin-food-save-fix-20261111/.

## 11/11/2026 — Đổi ảnh chỉ cần URL

- Giai đoạn 4 bổ sung, hoàn thành và đã phát hành admin/Rules. Bỏ 5 ô metadata
  ảnh; Sửa ảnh có form riêng chỉ chế độ+URL, không hỏi lý do, chỉ ghi photo với
  audit tự động. Giữ kiểm tra URL/tải ảnh/phiên bản và quyền admin hiện có.
- App đọc photo mode/url, giữ credits cũ, không hiện dòng hoặc link rỗng.
  File chính: admin-web/dist/{food-photos,validation,app}.mjs, food_photo.dart,
  food_photo_thumbnail.dart, firestore.rules và các test tương ứng.
- npm check qua; admin unit **142/142**; Rules **14/14**, realtime SDK với đúng
  module candidate **16/16**, SDK hồi quy **9/9** qua. Format 3 file Dart qua,
  analyze 3 file sạch, Flutter ảnh/detail **19/19** qua. Không build Android.
- Deploy Rules/Hosting exit0, chỉ validCatalogPhoto và 3 module web. 6 URL
  online khớp bytes/header; Rules đọc lại khớp candidate. Không ghi QA production.
- Người dùng Ctrl+F5 admin, chọn Sửa ảnh. App Chrome Hot Restart một lần để nhận
  code reader mới; các lần đổi dữ liệu sau nhận realtime. Android cần build mới.
- Giới hạn: chưa lưu trên phiên admin thật/Android thật. Đề xuất tiếp: nghiệm
  thu URL ảnh trên phiên người dùng, không mở giai đoạn khác.
- Chi tiết: docs/admin-photo-url-only-2026-11-11.md; logs/candidate tại
  build/admin-photo-url-only-20261111/.

## 11/11/2026 — Giai đoạn 1 bảo trì: nền đen và màu nhận diện

- Hoàn thành UI local: nền tối #000000, thẻ xám trung tính; chế độ sáng trắng.
  Trang chủ/nhật ký dùng AppTheme chung, giảm tím. Bữa sáng vàng, trưa san hô,
  tối xanh dương, phụ mint; nước xanh, tập luyện san hô, cân nặng hồng,
  Tiến độ cyan. Đồng bộ icon/nhãn/nút/biểu đồ, giữ nền thẻ trung tính.
- File chính: core/theme, app_shell, tracking_page, dashboard, journal,
  các section dinh dưỡng/nước/vận động, progress_overview, weight_chart,
  period_report_panel và weekly_reflection_card. Không đổi dữ liệu/luồng CRUD.
- Format qua; analyze toàn repo cuối sạch; 9 suite đầu 139/139 qua, 7 suite
  sau thay đổi cuối 79/79 qua. Diff-check qua. Đã xem ảnh render sáng/tối.
- Cần Hot Restart app đang chạy. Chưa build/nghiệm thu Android thật hoặc deploy;
  không thêm cấu hình Firebase/phí. Hai nhãn ngày cân nặng sát nhau trong ảnh
  test là vấn đề trục ngày hiện có, ghi nhận ngoài phạm vi đổi màu.
- Đề xuất tiếp: nghiệm thu giao diện trên thiết bị người dùng; chưa triển khai.
- Chi tiết, file và lệnh/log: docs/black-ui-meal-colors-2026-11-11.md.

## 11/11/2026 — Bỏ xanh mint và hiển thị GIF ngay danh sách tập luyện

- Hoàn thành mã nguồn bảo trì UI tập luyện: primary trắng/xám, dinh dưỡng cam,
  bữa phụ hồng; giảm các accent mint. Tab Tập luyện mở thư viện 50 bài, có GIF
  inline tự tải theo viewport, phát/dừng/thử lại; Buổi tập mở timer cũ.
- SliverList lazy và khung 150 px cố định, không tải cả 50 khi mở. Hủy request
  theo từng owner để bỏ một thẻ không hủy thẻ khác. Giữ admin override/ẩn bài.
  Hai biến thể khớp chính xác có GIF trong buổi cũ, bỏ thumbnail người thật.
- File chính: core/theme + app_shell; exercise_db_service, exercise_gif_preview,
  exercise_library_screen, workout_exercise_provider và các màn tập luyện.
- Format/diff-check qua, analyze toàn repo sạch; 10 suite cuối 89/89 qua.
  18/18 Rules trên candidate qua. Đã phát hành riêng block exercise_library/
  audit entity lên Firebase; đọc lại khớp candidate. Không ghi QA production,
  push Git hoặc deploy Hosting. Nguồn API+GIF chống đẩy đọc thật HTTP 200.
- Người dùng bấm Esc dừng Computer Use trước Hot Restart bản inline cuối;
  đã dừng UI automation. Cần Ctrl+Shift+F5 trong VS Code. Chưa xem GIF thật
  trên Chrome sau bản cuối hoặc kiểm Android vật lý/build release.
- Đề xuất tiếp: nghiệm thu bản inline trên phiên người dùng; chưa triển khai.
- Chi tiết/log và giới hạn: docs/workout-gif-ui-fix-2026-11-11.md.

### 16/11/2026 — Giai đoạn 6: calo vận động và ngân sách ngày

- Hoàn thành bộ tính MET 2024 có nguồn, snapshot cân nặng/tuổi/giây/mã hoạt
  động; phân biệt calo tổng và phần vận động thêm so với nghỉ. Không dùng API
  ExerciseDB/AI để đoán năng lượng, không thêm dependency hoặc dịch vụ tính phí.
- Đấu nối form nhập tay, tổng kết timer và lưu Firestore; timer loại nghỉ/tạm
  dừng/nền/bỏ qua. Retry giữ cùng draft/ID. Sửa ghi chú hay xác nhận ngân sách
  giữ snapshot; đổi loại/phút/thời điểm tính lại và bỏ xác nhận ngân sách cũ.
- Tổng quan/nhật ký/mục tiêu/màn năng lượng/chatbot dùng ngân sách chung; chỉ
  cộng calo vận động thêm khi xác nhận ngoài mức thường ngày, tránh trùng bước
  chân. Sửa/xóa realtime. CSV có cột calo vận động riêng.
- Format qua; analyze sạch; 12 file test liên quan 142/142 qua; UI kiểm lại cuối
  4/4 qua. Candidate: 3 ca rules mới + 1 ca CRUD cũ và 1 ca SDK thật Chrome
  (Auth/Firestore emulator, idempotency, snapshot, chặn chéo UID) qua.
- Đã deploy rules chỉ cho phần hoạt động, đọc lại khớp candidate; không deploy
  Hosting/Functions hay ghi dữ liệu QA production. Danh sách file, nguồn và
  kết quả chi tiết: `docs/activity-energy-2026-11-16.md`.
- Người dùng: Hot Restart; có ngày sinh/cân nặng thật trước buổi tập; chọn cách
  tập khi lưu. Kết quả vẫn là ước tính nhóm, không đo cảm biến; bảng tuổi 19–59.
- Đề xuất tiếp: nghiệm thu buổi tập trên thiết bị. Chưa thực hiện trong lượt này.


## 17/11/2026 — Giai đoạn 11: thiết kế lại luồng tập luyện

- Hoàn thành thư viện lưới GIF thích nghi, bìa buổi tập, dải số liệu, nhịp
  tập, danh sách đánh số, màn đếm giờ và tổng kết. Giữ đen/trắng, Public Sans,
  icon hiện có; giảm khung lồng nhau và làm rõ hành động chính.
- Giữ nguyên truy vấn, ánh xạ GIF theo bài và admin ẩn/sửa, công thức calo,
  pause nền, xác nhận lưu và retry cùng operation ID. Không đổi Firebase,
  package, nguồn/giấy phép media; không push/deploy.
- Chín file Dart format sạch; analyze sạch. Mười suite 84 ca qua + một ca
  chụp opt-in; ba suite giao diện cuối 20 ca qua + một ca opt-in. Chụp riêng
  đạt, xuất tám ảnh sáng/tối bằng widget/font/icon thật và GIF đúng nguồn.
  Tài khoản/nhật ký của bản chụp là fixture. Build web thành công.
- File chính: workout_ui, exercise_library_screen, workouts_screen,
  workout_session_screen, workout_tutorial_sheet, exercise_gif_preview,
  movement_media_preview và test/workout_flow_design_test.dart.
- Người dùng Hot Restart để xem; không cần cấu hình Firebase mới. Chưa kiểm
  Android vật lý; GIF miễn phí vẫn chỉ dùng cho kiểm thử phi thương mại.
- Chi tiết/log/ảnh: docs/workout-flow-ui-2026-11-17.md và
  build/workout-flow-20261117/. Đề xuất tiếp: nghiệm thu trên thiết bị;
  chưa tự thực hiện.


## 17/11/2026 — Giai đoạn 11: thêm 30 minh họa nữ RepDB

- Đã hoàn thành phần code và kiểm thử local: thêm 30 động tác với mẫu nữ từ
  preview chính thức RepDB, không cần tài khoản, CC BY-NC 4.0; tổng 84 bài,
  gồm 34 mẫu nữ. WebP động nền trong suốt, 512×512 từ URL công khai, giữ viền
  trên nền đen/trắng. Không dùng người thật, không gán clip khác bài.
- Đã xác minh đủ 30 URL HTTP 200/MIME/CORS/alpha/nhiều khung/chuyển động pixel;
  xem toàn bộ contact sheet và ảnh chụp widget thật sáng/tối. Master ZIP và
  từng URL có hash/thông số trong manifest; giấy phép preview lưu trong docs.
- File chính: data/workouts/exercise-library.json, repdb-preview-manifest.json;
  generator và hai catalog/two ID allowlists; ExerciseLibraryEntry,
  ExerciseDbService, ExerciseGifPreview, workout_ui; admin model/preview/page/
  CSS; firestore.rules, Flutter/admin/rules tests. Schema thêm sourceProvider
  tùy chọn, mặc định exercisedb; quyền admin/audit giữ nguyên.
- Format 9 file sạch, generator --check khớp 84 mục. Flutter 12 suite: 135 ca
  qua, 1 ca chụp cũ bỏ qua; có chụp riêng RepDB thật trong cùng lượt chạy.
  Admin: 152 ca qua; npm check và check:exercises qua. Emulator Rules: 5/5
  qua bằng JBR 21. Build web debug thành công; Wasm dry-run còn cảnh báo của
  mobile_scanner/dart:html hiện có. Analyze cuối sạch (No issues found, 13,0 giây).
- Không mua dịch vụ, đổi bảng MET/calo, ghi dữ liệu người dùng hoặc đưa media
  vào assets thương mại. Không push GitHub/deploy hosting/Rules production.
- Người dùng: Hot Restart app, tải lại admin local; emulator nạp Rules mới.
  Trước nghiệm thu Firebase thật cần phát hành riêng Rules và bản admin mới;
  chưa triển khai working tree có nhiều thay đổi ngoài phạm vi.
- Chưa kiểm thử Android vật lý/thiết bị yếu; cần Internet để tải media, nguồn
  bên ngoài có thể đổi. Chỉ dùng preview trong bản kiểm thử phi thương mại.
- Chi tiết: docs/repdb-female-30-2026-11-17.md; log/ảnh/nguồn trong ignored
  build/female-30-research-20261117/. Tiếp theo đề xuất: nghiệm thu thiết bị
  khi người dùng yêu cầu; chưa tự thực hiện.

## 18/11/2026 — Giai đoạn 11: chỉ dùng ExerciseDB

- Theo lựa chọn mới, bỏ 30 mục RepDB và phần tích hợp riêng; app/admin dùng
  chung 54 bài ExerciseDB, gồm 50 mẫu nam cũ và 4 mẫu nữ đã xác minh. Chưa đủ
  30 GIF nữ từ ExerciseDB; không bổ sung nguồn khác để đủ số.
- Kiểm tra lại 7 ID nữ cũ: 4 GIF HTTP 200 giải mã/chuyển động được; 3 GIF 404
  bị loại. Đã xem contact sheet; không kết luận chỉ có 4 GIF nữ toàn nguồn.
- Admin vẫn thêm/sửa/ẩn/khôi phục, tìm không dấu, lọc và xuất danh mục; chỉ
  chấp nhận mã ExerciseDB 7 ký tự. Model/service/Rules chặn provider khác.
- File chính: catalog JSON/generator/Dart/JS, ExerciseLibraryEntry,
  ExerciseDbService, ExerciseGifPreview/workout_ui, admin model/media/page/CSS,
  firestore.rules và tests. Giữ sourceProvider tùy chọn chỉ giá trị exercisedb.
- Format 8 file sạch; generator khớp 54 mục; analyze sạch. Flutter 103 ca qua,
  1 capture opt-in bỏ qua; admin 152/152, npm check/check:exercises qua;
  emulator Rules 5/5 gồm listener nhận trực tiếp CRUD, emulator đã dừng.
- `flutter build web --debug --no-pub`: thành công (Built build/web, 77,6 giây). Wasm dry-run còn cảnh báo mobile_scanner/dart:html hiện có; bản JavaScript đã build thành công.
- Người dùng Hot Restart app/tải lại admin local. Không mua dịch vụ, thêm
  dependency, push GitHub, deploy Rules/hosting hoặc ghi dữ liệu người dùng.
- Còn thiếu 26 GIF nữ để đạt 30 từ cùng nguồn; media free vẫn chỉ ở bản kiểm
  thử phi thương mại. Chưa nghiệm thu Android vật lý.
- Chi tiết: docs/exercisedb-only-2026-11-18.md; log/ảnh/hash ở
  build/exercisedb-only-20261118/. Đề xuất tiếp: xác minh thêm GIF nữ cùng
  nguồn khi có quyền truy cập phù hợp, chưa tự thực hiện giai đoạn tiếp.
- Theo yêu cầu trực tiếp của người dùng, đã hẹn tắt laptop sau 120 giây vào 00:26:02 18/11/2026 +07:00. Worker PowerShell chạy ẩn, gọi shutdown /s /t 0 không /f; Windows có thể chờ tài liệu chưa lưu. Receipt: build/exercisedb-only-20261118/shutdown-scheduled.json.

## 18/11/2026 — Giai đoạn 11: rà soát toàn bộ GIF ExerciseDB

- Sửa thiếu sót của cách tìm theo nhãn female: đã đọc đủ 60 trang API / 1.500
  ID hiện tại, khớp dữ liệu cũ; kiểm tra 1.500 URL, có 1.324 GIF nhiều khung
  HTTP 200 và 176 URL 404. Đã xem toàn bộ 1.324 ảnh, phóng to các ứng viên.
- Xác minh 10 mẫu nữ thực hiện động tác, gồm 4 đã có và 6 không có nhãn giới
  tính trong tên. Không tính nữ chỉ xuất hiện làm tải cho người nam đang tập.
- Thêm r5DgrW9, daBmy1Y, BmrwWzo, gFyFj9z, wSScovH, eOG0r6v vào JSON chung
  và sinh Dart/JS. Danh mục 60 bài / 10 nữ; 54 bản ghi trước giữ nguyên.
  Cả 60 media tải được; 10 nữ giải mã từng khung, chuyển động/hash khác nhau.
- File chính: catalog JSON, hai bundled catalog, female_exercise_library_test,
  exercise_db_test, admin exercise-library/app-dom tests; báo cáo nguồn và
  lịch sử. Không đổi schema/Rules/model/listener/dependency/calo/quyền.
- Format 3 file sạch; generator --check 60 mục; Flutter 109 qua/1 capture
  opt-in bỏ qua; admin 152/152 và hai lệnh check qua. Analyze sạch (116,3s),
  build web debug thành công (113,4s); Wasm còn cảnh báo mobile_scanner cũ.
- Không chạy lại emulator vì Rules/backend không đổi; không dùng kết quả cũ
  làm test mới. Chưa nghiệm thu Android vật lý hoặc phiên Chrome đang mở.
- Hot Restart app/tải lại admin local và tìm mẫu nữ. Không cần account/API
  key mới; chưa push/deploy hosting/Rules hay ghi dữ liệu Firebase thật.
- Người dùng giảm mục tiêu xuống 20 nữ. Xem lại đủ 1.324 khung giữa trên
  14 sheet, không tìm thêm bài nữ; hiện đạt 10/20, còn thiếu 10. Kiểm tra
  repo/tài liệu chính thức và các nguồn bổ sung công khai chưa tìm được
  GIF thêm cùng nguồn, miễn phí và không tài khoản; không trộn nguồn khác.
  Không kết luận mọi
  gói của ExerciseDB đều chỉ có 10 nữ. Chi tiết và bằng chứng:
  docs/exercisedb-full-visual-audit-2026-11-18.md và
  build/exercisedb-wide-review-20261118/. Đề xuất tiếp: nghiệm thu media trên
  thiết bị khi người dùng yêu cầu, chưa tự chuyển giai đoạn.

## 18/11/2026 — Giai đoạn 11: chốt 10 GIF nữ, nền đen và viền

- Người dùng chọn giữ 10 GIF ExerciseDB và hoàn thiện nền đen/viền. Catalog
  vẫn 60 bài/10 nữ. Đã kiểm tra 176 tệp 404 qua bản lưu lịch sử, phát hiện
  5 ID nữ nhưng so sánh RGBA từng khung/thời lượng chứng minh trùng với
  clip đã có. Không tính trùng thành bài mới hoặc mở host mới trong app.
- App đã có bộ lọc dùng chung nam/nữ; xác minh 30 khung từ 10 GIF thật qua
  renderer Flutter. Admin trước còn nền trắng; thêm module SVG v3 dùng
  chung, áp dụng nền đen/bộ lọc ở danh sách và chi tiết khi tối; sáng giữ
  ảnh gốc, chuyển theme không tải lại GIF. Giữ pause/abort/dispose.
- File chính: admin exercise-gif-background.mjs, exercise-media-preview.mjs,
  workouts-page.mjs, exercise-library.css, package.json và hai file test.
  Không đổi Dart implementation, catalog/schema/Rules/dependency/calo.
- Format 5 Dart: 0 thay đổi; analyze sạch (47,7s). Flutter 6 suite 40/40;
  lượt native harness + hai suite có 18/18 (test lặp, không cộng gộp).
  Admin 154/154; check/check:exercises qua; SVG offline 20/20 góc nền đen.
- Nguồn 180p vẫn có giới hạn: vùng trắng khép kín và bóng tư thế từ nguồn
  có thể còn. Chưa nghiệm thu Android/Chrome thực, không chạy build/emulator
  mới vì Dart/backend không đổi. Không push/deploy hoặc thêm dữ liệu thật.
- Người dùng Hot Restart nếu app còn catalog cũ; admin local Ctrl+F5, chọn
  tối. Chi tiết: docs/female-gif-black-2026-11-18.md. Bước đề xuất: nghiệm
  thu thiết bị khi được yêu cầu; chưa tự chuyển giai đoạn.
