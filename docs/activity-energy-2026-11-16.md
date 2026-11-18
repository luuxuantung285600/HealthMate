# Calo vận động — 16/11/2026

Giai đoạn 6, bổ sung ước tính năng lượng cho nhật ký vận động và timer đang có;
đấu nối ngân sách ngày/tổng quan/nhật ký/chatbot/CSV để các nơi dùng cùng kết quả.
Không thêm package, backend, cảm biến hoặc dịch vụ tính phí.

## Nguồn và công thức

Đã đọc trực tiếp trang chính thức ngày 16/11/2026:

- https://pacompendium.com/home/ — định nghĩa **1 MET = 1 kcal/kg/giờ**;
  cho phép sử dụng thương mại miễn phí, yêu cầu giữ nguyên MET và ghi nguồn.
- https://pacompendium.com/adult-compendium/ — bộ Adult 2024 cho tuổi **19–59**.
- https://pacompendium.com/conditioning-exercise/
- https://pacompendium.com/walking/
- https://pacompendium.com/running/
- https://pacompendium.com/bicycling/

Quy ước `formulaVersion: 1`:

```
grossKcal  = MET       × weightKg × durationSeconds / 3600
activeKcal = (MET - 1) × weightKg × durationSeconds / 3600
```

`grossKcal` gồm năng lượng cơ thể vốn tiêu hao khi nghỉ trong cùng khoảng thời
gian. `activeKcal` trừ phần nghỉ chuẩn 1 MET; dùng số này khi người dùng xác nhận
buổi tập là hoạt động bổ sung ngoài mức thường ngày đã dùng để đặt mục tiêu ăn.
Không trộn công thức trên với biến thể quy đổi oxy `MET × 3.5 × kg / 200 × phút`.

Ví dụ kiểm thử, không phải số liệu người dùng: **60 kg, 30 phút, 3,8 MET** cho
**114 kcal tổng**, **84 kcal vận động thêm**. Một lượt 64 giây dùng đủ 64 giây
để tính năng lượng, dù trường phút của nhật ký hiển thị 1 phút làm tròn xuống.
Chỉ làm tròn khi hiển thị, không làm tròn từng khoảng trước khi cộng.

Đây là ước tính theo nhóm hoạt động, không phải phép đo chuyển hóa cá nhân.
Người dùng chọn cách tập thực tế; app không suy ra MET từ GIF, nhịp timer,
cân nặng mục tiêu, API ExerciseDB hoặc AI. Một buổi có hướng dẫn dùng một nhóm
thể dục/kháng lực phù hợp cho phần thời gian vận động đã xác nhận; không tuyên
bố biết chính xác năng lượng của từng động tác. Khi cách tập không khớp các lựa
chọn, người dùng có thể chỉ lưu phút. Khác biệt thể trạng, kỹ thuật, cường độ và
chuyển hóa có thể khiến năng lượng thực khác ước tính.

Các cặp mã–MET v1 giữ nguyên từ bảng 2024:

| Nhóm | Mã Compendium và MET |
|---|---|
| Đi bộ đường bằng | 17152: 2,8; 17190: 3,8; 17200: 4,8 |
| Chạy bộ / chạy tại chỗ | 12020: 7,5; 12025: 4,8 |
| Đạp xe | 01010: 4,0; 01020: 6,8; 01030: 8,0 |
| Thể dục / kháng lực | 02024: 2,8; 02056: 3,0; 02022: 3,8; 02020: 7,5; 02054: 3,5; 02050: 6,0 |
| Yoga | 02150: 2,3; 02160: 4,0 |

Khi thêm bảng mới phải tạo phiên bản công thức/bảng riêng, giữ nguyên bảng v1
để mã cũ không đổi ý nghĩa. Các giá trị trong `exercise_catalog.dart` cũ không
được nối vào tính toán sản phẩm này.

## Hành vi đã hoàn thành

- Timer chỉ tính giây foreground thực sự vận động; chuẩn bị, nghỉ, tạm dừng,
  thời gian ở nền và phần bài bị bỏ qua không được tự ghi đủ thời lượng.
- Màn tổng kết và form thêm/sửa hoạt động có lựa chọn cách tập, calo tổng/calo
  vận động thêm, cân nặng và ngày cân, nút giải thích công thức/nguồn.
- Lấy đúng một lần cân gần nhất **không sau thời điểm hoạt động** bằng truy vấn
  có giới hạn 1 document, thay vì lấy số cân tương lai cùng ngày.
- Thiếu ngày sinh, thiếu cân nặng, tuổi ngoài 19–59 hoặc nhóm chưa có hệ số:
  vẫn lưu phút, không tự tạo calo bằng 0 hoặc một giá trị mặc định.
- Lưu snapshot đầu vào trong document nhật ký; cập nhật cân nặng sau này không
  đổi lịch sử. Sửa ghi chú hoặc bật/tắt cộng ngân sách giữ nguyên snapshot.
  Sửa thời gian, loại hoặc phút tính lại theo hồ sơ và bỏ xác nhận ngân sách cũ.
- Buổi tập giữ nguyên draft và mã thao tác khi máy chủ chưa xác nhận; thử lại
  không đổi số calo và không tạo bản ghi trùng. Nút lưu luôn ở cuối màn hình.
- Cộng ngân sách chỉ khi chủ tài khoản đánh dấu xác nhận hoạt động bổ sung;
  không trừ calo món đã ăn, không sửa mục tiêu gốc hoặc macro. Nếu mục tiêu gốc
  đổi, xác nhận cũ không tự áp dụng. Có nhật ký vận động thì không cộng thêm
  điều chỉnh bước chân để tránh tính trùng.
- Sửa/xóa nhật ký cập nhật ngân sách qua stream đang có. Tổng quan, nhật ký,
  mục tiêu, màn năng lượng và ngữ cảnh chatbot dùng cùng bộ tính ngân sách.
- Nhật ký cũ không có snapshot tiếp tục đọc/sửa được. CSV thêm cột năng lượng
  vận động riêng, không đặt calo tiêu hao vào cột `kcal` của thức ăn.

## File chính

- `lib/features/activity/models/activity_energy.dart`, `activity_log.dart`,
  `workout_session.dart`.
- `lib/features/activity/providers/activity_energy_providers.dart`,
  `data/firebase_activity_repository.dart`.
- `lib/features/activity/presentation/activity_energy_editor.dart`,
  `activity_log_dialog.dart`, `activity_log_section.dart`, `workout_session_screen.dart`.
- Profile repository: thêm lựa chọn truy vấn cân tại/trước thời điểm cụ thể.
- `lib/features/wellness/models/energy_budget.dart`, `providers/energy_providers.dart`
  và các màn hiển thị ngân sách; `personal_chat_context.dart`, `journal_csv.dart`.
- `firestore.rules`, `rules-tests/activity-energy.rules.test.cjs`,
  `test/activity_energy_test.dart`, `test/activity_energy_ui_test.dart`,
  `test/firebase_repository_integration.dart` và fake repositories tương ứng.

## Kiểm tra thực tế

- `dart format` các file sửa: qua.
- `flutter analyze --no-pub`: sạch (kiểm lại cuối lượt trong log).
- 12 file Flutter test liên quan: **142/142 qua**, bao gồm công thức/snapshot,
  timer, giao diện, lịch sử, sửa/xóa realtime, ngân sách, CSV, mục tiêu và chatbot.
- Sau bổ sung kiểm tra bật/tắt ngân sách giữ cân cũ: `activity_energy_ui_test.dart`
  **4/4 qua**. Kiểm lại 3 suite timer/giao diện sau sửa nhãn phút/giây:
  **37/37 qua**, log `final-workout-tests.log`.
- Firestore Emulator: **3/3** ca năng lượng mới + **1/1** ca CRUD/quyền vận động
  đang có qua. Bao gồm hai UID, email chưa xác minh, nguồn/MET không hợp lệ,
  số cân tương lai, tuổi ngoài bảng, NaN, thời lượng không khớp và key lạ.
- Firebase Auth/Firestore SDK thật trên Chrome + demo emulators: **1/1 qua**;
  tạo đồng thời cùng operation ID, đọc lại snapshot từ server, thử lại không
  đổi timestamp, chặn nội dung khác và chặn đọc/ghi chéo UID.

Log tại `build/activity-energy-20261116/`. Không ghi tài khoản/dữ liệu QA vào
production. Không tuyên bố đã nghiệm thu Android vật lý hoặc đo thực nghiệm
chuyển hóa của người dùng.

## Firestore production

Đã lưu bản rules cũ, tạo candidate chỉ đổi validation và field cập nhật của
`activity_logs`, kiểm tra candidate bằng emulator và SDK, kiểm tra rules trên
máy chủ chưa đổi trước khi phát hành. Không triển khai Hosting, indexes hay Functions.

Đã deploy `firestore:rules` vào `healthmate-app-20261013` và tải lại xác nhận
khớp candidate. Ruleset: `e2355bb6-6064-4c3f-a314-a26ca125b74f`;
SHA-256 nội dung chuẩn hóa:
`fe0850c138b3a6a12abdb5ddb5ee849ddef5f7c40e455b54687593ae9b18c9eb`.
CLI có cảnh báo hàm `knownNumber` cũ chưa dùng; không có lỗi biên dịch rules.

## Người dùng cần làm và giới hạn

Hot Restart app đang chạy để nạp code mới. Trong hồ sơ cần ngày sinh và bản ghi
cân nặng thật có trước buổi tập. Chọn cách tập phù hợp khi lưu tổng kết; chỉ
đánh dấu cộng ngân sách nếu buổi đó chưa nằm trong mức hoạt động thường ngày.
Không cần API key, Blaze hoặc tài khoản thanh toán cho bộ tính MET này.

App chưa tự đo cường độ hay calo qua cảm biến. Bảng hiện tại chỉ áp dụng tuổi
19–59; cân cũ hơn 90 ngày có nhắc cập nhật, không biến thành số đo mới. Chưa
build/ký phát hành Android hay nghiệm thu điện thoại thật trong lượt này.
Giai đoạn tiếp theo đề xuất: nghiệm thu buổi tập trên thiết bị; chưa triển khai.
