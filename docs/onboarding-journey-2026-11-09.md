# HealthMate — Luồng câu hỏi ban đầu, 09/11/2026

## Phạm vi

Giai đoạn tùy chọn 11: cải thiện luồng thiết lập theo ảnh tham khảo Wao do
người dùng cung cấp. Giữ nhận diện HealthMate, Inter và năm mục tiêu; không
thêm đăng nhập Facebook, package, dịch vụ hay thay đổi kiến trúc Firebase.

## Hành vi đã triển khai

- Mỗi màn tập trung một câu; thanh tiến độ theo nhánh, nút tiếp tục luôn
  nằm ngoài vùng cuộn, có quay lại và truy cập quyền riêng tư/tài khoản.
- Phần chính: tên, hệ số công thức, ngày sinh, chiều cao, cân nặng, mục tiêu,
  cân nặng đích khi tăng/giảm cân, vận động, phạm vi đề xuất và nhịp điều chỉnh.
  Nhánh chính có 11–13 màn tính cả lựa chọn bổ sung/tổng kết/kế hoạch.
- Đủ năm lựa chọn: giảm cân, duy trì, tăng cân, tăng cơ, cải thiện thói quen.
  Không tự gán mục tiêu từ BMI. Tăng cơ/thói quen không bắt nhập cân nặng đích.
- Số đo có thanh kéo và nhập số, đơn vị rõ; BMI tham khảo cập nhật theo số
  đang nhập. Không coi BMI là chẩn đoán hoặc tự chọn cân nặng người dùng.
- Có thể mở nhánh câu bổ sung về tập luyện, ăn uống, thực phẩm tránh, rau/
  trái cây, đồ uống thêm đường, giấc ngủ, khó khăn và ưu tiên. Không tập
  thường xuyên bỏ câu thời lượng/loại bài tập. Không bắt điền các câu này.
- Nhịp nhẹ/vừa hiển thị tỷ lệ điều chỉnh và kcal thay đổi ngay. Xem lại toàn
  bộ trước trang cuối; có lối sửa câu trả lời.
- Đủ thông tin phù hợp thì trang cuối tự tạo đề xuất: mục tiêu đã chọn,
  kcal/ngày, tổng 7 ngày nếu giữ cùng mục tiêu, năng lượng nghỉ, TDEE,
  điều chỉnh tăng/giảm và đạm/carb/béo, công thức và nguồn tham khảo.
- Không dự báo ngày chắc chắn đạt cân nặng hoặc số kg/tuần. Phạm vi tính
  tự động và các ngưỡng hiện có được giữ; có thể hoàn tất hồ sơ mà không áp
  dụng calo khi thiếu thông tin, cần hướng dẫn riêng hoặc tự bỏ chọn.

## Tính và lưu kế hoạch

Giữ Mifflin–St Jeor và hệ số vận động hiện có. Giảm cân giảm 10/15%; tăng
cân tăng 5/10%; ba mục tiêu còn lại dùng mức duy trì khởi đầu. Tăng cơ chọn
phân bổ ưu tiên đạm đã có (25/45/30%); các mục tiêu khác dùng 20/50/30%.
Đây là chính sách khởi đầu của sản phẩm, không phải chương trình tập cơ
hoặc chế độ ăn điều trị. Không cộng calo thêm từ giờ ngủ/ngày tập.

Đề xuất chưa ghi dữ liệu. Nút hoàn tất mới lưu mục tiêu qua repository theo
UID và ngày hiệu lực, sau đó hoàn tất hồ sơ. Mục tiêu đang có phải đồng ý
thay từ hôm nay; từ chối có thể giữ mục tiêu cũ và hoàn tất hồ sơ. Giữ xử lý
lưu lỗi/thử lại, không gửi lặp, đổi tài khoản và không tạo bản trùng sau khi
mục tiêu đã lưu nhưng hồ sơ thất bại. Không thay đổi lịch sử cũ.

Nháp riêng tư trên thiết bị dùng version 2 với `screen` ổn định và
`includeDetails`. Đọc được version 1 và giữ dữ liệu khi chuyển; không dùng
chỉ số bước mới để diễn giải nhầm nháp cũ. Giữ cách ly theo UID. Không đổi
schema/Rules Firestore hay đồng bộ câu trả lời sức khỏe sang admin.

## File chính

- `lib/features/profile/models/onboarding_journey.dart`: nhánh và ID màn.
- `lib/features/profile/models/onboarding_progress.dart`: codec nháp 1/2.
- `lib/features/profile/presentation/onboarding_screen.dart`: điều hướng,
  xem trước, xác nhận và lưu qua repository hiện có.
- `lib/features/profile/presentation/onboarding_widgets.dart`: câu hỏi,
  thẻ chọn, nhập số, BMI và trang kế hoạch.
- `test/onboarding_journey_test.dart`: 10 ca mới; cập nhật các test cũ và
  `integration_test/core_acceptance_test.dart` cho việc hỏi từng màn.
- `docs/personalization-questionnaire.md`, `docs/database-design.md`,
  tiến độ và báo cáo kiểm thử.

## Kiểm tra thực tế

- `dart format --output=none --set-exit-if-changed` trên 11 file Dart
  liên quan: qua, không cần đổi định dạng.
- `flutter analyze --no-pub`: **No issues found**, 43,1 giây.
- `flutter test --no-pub --reporter expanded`: **1140/1140 qua**, 2 phút
  56 giây. Sau chỉnh câu chữ phạm vi đề xuất, chạy lại questionnaire/journey:
  **17/17 qua**.
- Android runtime với admin flag thực: **7/7 qua**.
- `flutter build apk --debug --no-pub` với file defines riêng của F5:
  đã build lại thành công sau chỉnh câu chữ cuối cùng (26,4 giây); APK ở
  `build/releases/healthmate-onboarding-20261109-debug.apk`.
- `git diff --check`: qua. Source secret audit cuối: **717 file, 0 finding**;
  token App Check vẫn ngoài repo.
- Đã render và xem ảnh Inter thật trong `build/onboarding-journey/`:
  chọn mục tiêu và kế hoạch ở 390px/tối. Bộ UX còn kiểm 320/390/412px ×
  100/150/200% × sáng/tối. Số liệu ảnh là fixture kiểm thử, không phải hồ sơ
  hoặc thống kê người dùng thật.

Ca lỗi ban đầu đã xử lý: nhãn số đo tràn trên màn 320px/chữ 200%; các test
điều hướng cũ cần tới đúng màn ngày sinh; test hộp xác nhận không chờ kết
thúc loading trước khi người dùng trả lời. Không nới validation/Rules để
vượt kiểm thử. Hộp từ chối thay mục tiêu vẫn giữ nguyên dữ liệu cũ.

## Thao tác thủ công và giới hạn

Điện thoại đã ngắt kết nối khi kiểm bản mới; chưa cài hoặc nghiệm thu bản
onboarding này trên Android thật. Kết nối lại, chọn thiết bị trong VS Code
và F5; tài khoản đã thiết lập mở **Cá nhân → Cá nhân hóa thêm**. Không cần
cấu hình Firebase hoặc bật dịch vụ mới. Chưa ký bản phát hành, chưa deploy
backend/web hoặc đẩy Git trong lượt này. Integration harness đã cập nhật
nhưng không tuyên bố đã chạy lại kiểm thử end-to-end trên thiết bị.

Đề xuất tiếp theo: nghiệm thu luồng thiết lập trên điện thoại thật. Chưa
tự triển khai thêm giai đoạn hoặc chính sách dự báo cân nặng.
