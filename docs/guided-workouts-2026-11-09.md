# HealthMate — Tập luyện theo nhịp, 09/11/2026

> Cập nhật 10/11: minh họa vector bên dưới đã được thay bằng video hướng
> dẫn miễn phí, phát trực tuyến từ kênh gốc. Xem
> [nguồn, quyền sử dụng và kiểm thử mới](workout-media-sourcing-2026-11-10.md).
> Các kết quả ngày 09/11 chỉ mô tả phiên bản trước khi thay media.

## Phạm vi

Giai đoạn tùy chọn 11, theo yêu cầu bổ sung tập luyện lấy cảm hứng từ cách
dùng Seven: chọn buổi, xem hướng dẫn, bộ đếm tập/nghỉ và xác nhận nhật ký.
Giữ thương hiệu HealthMate, Inter và theme sáng/tối. Không thêm package,
dịch vụ, billing, backend, collection hoặc thay Security Rules.

## Hành vi đã làm

- Mở từ Cá nhân → Tập luyện, Thói quen & kế hoạch → Tập luyện hoặc
  Nhật ký → Vận động → Tập theo hướng dẫn.
- Ba buổi nội dung có sẵn: Toàn thân (12 động tác), Bắt đầu nhẹ nhàng
  (8 lượt đứng, không bật nhảy/nằm sàn), Vững thân giữa (8 lượt).
  Có bộ lọc, dụng cụ cần chuẩn bị, hướng dẫn từng bước, biến thể nhẹ hơn
  và minh họa vector chuyển động. Tổng cộng 14 động tác riêng biệt.
- Ba nhịp: nhẹ hơn 20s tập/20s nghỉ; tiêu chuẩn 30s/10s; hai vòng 30s/10s.
  Chuẩn bị 5 giây, không nghỉ sau lượt cuối. Toàn thân tiêu chuẩn là
  **7:55 tổng thời gian**, gồm 6 phút tập và 1:50 nghỉ; không ghi nhầm
  là 7 phút hoặc tính thời gian nghỉ thành vận động.
- Bộ đếm có vòng/lượt hiện tại, xem trước động tác kế tiếp, tạm dừng,
  tiếp tục, bỏ qua động tác/nghỉ, xem cách tập và rung khi chuyển giai đoạn.
  Ra nền/khóa màn hình thì tạm dừng; quay lại cần bấm tiếp tục.
- Kết thúc sớm hoặc quay lại có xác nhận. Tổng kết phân biệt thời gian
  tập/nghỉ, lượt đủ thời gian và lượt bỏ qua; không tự ghi nhật ký.
- Nút xác nhận mới lưu số phút vận động trọn vẹn qua repository hiện có.
  Dưới 60 giây không làm tròn thành một phút. Không đoán calo hoặc nhận
  là đã phát hiện động tác. Ngày của nhật ký là thời điểm bắt đầu buổi.
- Lưu thành công cập nhật luồng `activity_logs` thật, được nhật ký,
  dashboard, mục tiêu/nhiệm vụ và báo cáo đang đọc luồng này sử dụng.
  Màn thư viện có tổng vận động hôm nay với loading/error/retry/empty.

## Tính đúng dữ liệu và quyền riêng tư

Session/timer là model Dart riêng; UI không chứa query Firestore. Thời gian
tạm dừng không được bù sau khi tiếp tục. Bỏ qua chỉ giữ số giây đã đếm,
không coi động tác bỏ qua là đã hoàn thành đủ. Bản ghi không có calo giả.

`ActivityRepository.add` bổ sung `operationId` tùy chọn; luồng nhập tay
hiện có vẫn giữ cách ghi cũ. Buổi tập dùng ID ổn định trong phiên và
transaction: nội dung giống nhau trả lại cùng bản ghi, nội dung khác bị
từ chối, không thay `createdAt`/`updatedAt` khi thử lại. Xác nhận lại bằng
server read trước khi báo lưu thành công. Chặn bấm lặp và đổi tài khoản
trong khi lưu; UID đích luôn thuộc phiên đã bắt đầu thao tác.

Không đổi schema `users/{uid}/activity_logs/{id}`. Tên buổi, số lượt và
giây thực tế nằm trong `note` hiện có; `durationMinutes` chỉ giữ phút tập
trọn vẹn, không cộng nghỉ. Không mở quyền dữ liệu sức khỏe cho admin.
Buổi/hướng dẫn là nội dung cục bộ theo phiên bản app, tách khỏi 33 loại
hoạt động/MET cũ. Chưa thêm quản lý buổi hướng dẫn từ web admin.

## File chính

- `lib/features/activity/models/guided_workout.dart`: buổi và hướng dẫn.
- `lib/features/activity/models/workout_session.dart`: máy trạng thái thời gian.
- `lib/features/activity/presentation/workouts_screen.dart`: thư viện/chi tiết.
- `lib/features/activity/presentation/workout_session_screen.dart`: tập/tổng kết.
- `lib/features/activity/presentation/movement_illustration.dart`: minh họa.
- Repository/provider activity, router và các lối vào profile/wellness/journal.
- `test/workout_session_test.dart`, `test/workout_experience_test.dart`,
  thêm ca opt-in trong `test/firebase_repository_integration.dart`.

## Kiểm tra

- Model **13/13 qua**: tổng thời gian, ranh giới giai đoạn, sai số tick,
  tạm dừng, bỏ qua, dừng sớm, nhiều vòng, phút lẻ và không tạo calo.
- UI **20/20 qua**: lối vào/bộ lọc/nhịp/hướng dẫn, tập/nghỉ, ra nền,
  tổng kết, xác nhận/lưu, lỗi/thử lại, bấm lặp, đổi tài khoản và system back.
  Gồm 12 tổ hợp 320/390/412px × chữ 100/200% × sáng/tối.
- SDK Firestore/Auth thật trên emulator demo **1/1 qua**: hai lần ghi đồng
  thời cùng ID, thử lại không đổi timestamp, nội dung khác bị chặn,
  ID không hợp lệ, stream chỉ có một bản và tài khoản B không thể đọc/ghi A.
- Đã render và xem `build/workout-preview/library-light.png`,
  `player-dark.png`, `summary-dark.png`. Ảnh dùng fixture kiểm thử.
- Analyzer toàn dự án: **No issues found**, 31,4 giây.
- `flutter test --no-pub --reporter expanded`: toàn bộ **1173/1173 qua**,
  2 phút; log `build/workout-final-full-tests.log`.
- `dart format` các file liên quan: qua, lượt cuối 18 file/0 thay đổi.
- `flutter build apk --debug --no-pub` dùng defines riêng của F5: qua,
  Gradle 30,4 giây. APK `build/releases/healthmate-guided-workouts-20261109-debug.apk`
  (237.634.917 byte), chưa cài trên điện thoại.
- `git diff --check`: qua. Source secret audit: **725 file, 0 finding**;
  không phải kiểm toán APK/kho credential. Token App Check vẫn ngoài repo.

Đã sửa lỗi tràn bộ đếm khi chữ 200% bằng kích thước vòng thích ứng. Một
test thao tác lối vào cần đợi cuộn hoàn tất trước khi bấm; không tắt kiểm
tra overflow hoặc nới validation/Rules. Firebase CLI trên Windows cần
script con để truyền tên test có khoảng trắng; lần chạy lại đã qua.

## Chạy và giới hạn

Không cần cấu hình Firebase mới. Chạy F5 hoặc cài APK debug mới rồi mở
Cá nhân → Tập luyện. Điện thoại hiện không có trong `adb devices`; chưa
nghiệm thu buổi tập/rung/khóa màn hình trên Android thật và chưa ký release.
Chưa deploy hoặc đẩy Git trong lượt này.

Buổi đang tập chỉ giữ trong bộ nhớ, chưa phục hồi sau khi hệ điều hành
tắt tiến trình. Lưu nhật ký cần kết nối máy chủ; khi lỗi còn ở tổng kết
thì có thể thử lại với cùng ID. Minh họa là gợi ý tư thế đơn giản, không
phải video huấn luyện hoặc nhận diện tư thế. Chưa thêm giọng huấn luyện,
thử thách xã hội, lịch tập hay nội dung trả phí.

Bước tiếp theo đề xuất: nghiệm thu buổi tập trên Android thật. Không tự
triển khai giai đoạn khác hoặc thay đổi dữ liệu cũ.
