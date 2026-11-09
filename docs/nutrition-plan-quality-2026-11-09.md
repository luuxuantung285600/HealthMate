# Mục tiêu dinh dưỡng và kế hoạch bữa ăn — 09/11/2026

## Phạm vi

Giai đoạn 10, tiếp tục hoàn thiện các luồng mục tiêu/kế hoạch đã có theo
yêu cầu của người dùng. Tập trung bảo vệ nội dung đang nhập, ngày áp dụng,
chờ xác nhận lưu và ràng buộc tài khoản. Không thêm package, backend,
dịch vụ trả phí, schema, query hoặc Security Rules; giữ các sửa đổi trước.

## Hành vi đã cải thiện

- Form mục tiêu nhập tay xác nhận trước khi đóng/Back nếu có thay đổi.
  Chọn tiếp tục giữ nguyên ngày và cả bốn ô nhập; nhập lại đúng nội dung
  ban đầu thì đóng trực tiếp, không hỏi thừa.
- Đổi ngày áp dụng khi đang sửa số liệu phải xác nhận trước khi tải mục
  tiêu của ngày mới. Hủy giữ nguyên ngày và dữ liệu. Chấp nhận giữ nghiệp
  vụ cũ: tải phiên bản đang áp dụng cho ngày đã chọn. Nếu tải lỗi, giữ
  nội dung và chặn lưu cho tới khi tải lại thành công.
- Công cụ cá nhân hóa bảo vệ cả số đo nhập tay, lựa chọn hệ số/hoạt động/
  mục tiêu/phân bổ chất và đề xuất đã tính. Nút Đóng, Back và “Để sau” đều
  qua xác nhận bỏ thay đổi; chấp nhận đề xuất vẫn dùng luồng lưu hiện có.
- Form kế hoạch bữa ăn xác nhận trước khi bỏ thay đổi món hoặc khẩu phần.
  Thay đổi ô tìm kiếm/bộ lọc để duyệt món không bị coi là thay đổi bữa.
  Nội dung đang sửa được so với snapshot ban đầu theo dữ liệu lưu thực.
- Nút lưu kế hoạch chuyển xuống cuối màn hình, có trạng thái chờ và khóa
  gửi lặp; tiêu đề xuống hai dòng khi tăng cỡ chữ. Footer mục tiêu có cuộn
  và giới hạn chiều cao để phần trợ giúp/lỗi không đẩy nút khỏi màn hình.
- Controller mục tiêu, form nhập tay, công cụ cá nhân hóa và callback lưu/
  ghi nhật ký của kế hoạch kiểm tra thêm currentUid từ Auth repository.
  Chặn khoảng trễ Auth đã đổi nhưng auth stream chưa chuyển UID; kiểm tra
  lại trước khi nhận thành công. AccountBoundDialog tiếp tục đóng form
  riêng tư khi phiên thay đổi.
- MealPlannerPanel dùng đồng hồ chung cho tuần đang mở, kiểm tra ngày khi
  ghi nhật ký và hiển thị nút xác nhận đã ăn. Khi sang ngày mới, bữa trước
  đó còn ở tương lai có thể được xác nhận mà không cần mở lại màn hình.

Không thay đổi công thức năng lượng/macro hay cách chọn mục tiêu theo ngày.
Chỉ bữa xác nhận đã ăn mới được ghi nhật ký; kế hoạch tương lai vẫn là kế
hoạch. Luồng liên kết kế hoạch/nhật ký bằng transaction hiện có được giữ.

## File chính

- `lib/features/nutrition_targets/presentation/nutrition_target_form.dart`:
  bảo vệ nội dung, xác nhận đổi ngày, footer và kiểm tra phiên.
- `lib/features/nutrition_targets/presentation/personal_nutrition_planner.dart`:
  bảo vệ đầu vào/đề xuất, đóng form và kiểm tra tài khoản.
- `lib/features/nutrition_targets/providers/nutrition_target_providers.dart`:
  kiểm tra Auth trực tiếp trước và sau lưu.
- `lib/features/wellness/presentation/wellness_screen.dart`: chỉ bổ sung cho
  MealPlannerPanel/PlanMealDialog trong lượt này; các sửa đổi cũ được giữ.
- `test/nutrition_plan_quality_test.dart`: 12 regression mới.
- `test/plan_meal_ui_test.dart`: thêm hai regression Auth trước stream,
  nối harness với FakeAuthRepository thật của test và dọn subscription.
- `test/nutrition_personalization_test.dart`: cập nhật loại nút lưu;
  giữ nguyên kiểm tra món cần tránh và khả năng lưu sau khi bỏ món đó.
- Báo cáo này, `docs/implementation-progress.md`, `docs/test-report.md`.

## Kiểm thử thực tế

- Format bốn source và ba test, kiểm tra lại: **0 file thay đổi**.
- `test/plan_meal_ui_test.dart` cuối: **6/6 qua**.
- `flutter test --no-pub` cuối: **1.115/1.115 qua**, 2 phút 1 giây,
  gồm 14 regression mới và các test công thức, ngày hiệu lực, số 0 thật,
  quá nửa đêm, mất ACK/lỗi lưu, liên kết nhật ký và onboarding đang có.
- `flutter analyze --no-pub` cuối: **không có vấn đề**.
- Preview Inter/MaterialIcons thật **6/6 qua**: ba form, 390 px sáng 100%
  và 320 px tối 200%. Đã xem 20 ảnh qua ba contact sheet, gồm đang sửa,
  xác nhận đổi ngày/bỏ thay đổi, pending và lỗi/thử lại. Tiêu đề xuống
  dòng; nội dung/footer cuộn, nút vẫn tiếp cận được, không layout exception.
- Khẩu phần **225,5 g** được giữ qua hộp xác nhận và gửi đúng snapshot
  **293,15 kcal** từ fixture cơm 130 kcal/100 g; không làm tròn mất phần lẻ.
- `flutter build apk --debug --no-pub`: **thành công**, Gradle 31,6 giây.
  Cảnh báo plugin KGP hiện hữu còn; không nâng dependencies ngoài phạm vi.
- Source secret audit không phát hiện theo pattern; phạm vi source được
  Git theo dõi và file mới không bị ignore, không phải audit APK/credential
  store. `git diff --check`: qua, chỉ còn cảnh báo LF/CRLF hiện hữu.

Các lỗi test trung gian đã sửa: finder cũ ép kiểu TextButton sau khi UI
đổi sang FilledButton; harness Auth từng dùng stream độc lập với currentUid;
finder tooltip có vị trí cũ sau cuộn; pumpAndSettle không phù hợp khi panel
còn hiển thị tiến trình trong lúc dialog mở. Đã dùng nút thật và pump theo
frame ở trạng thái đó, giữ assertion không ghi nhầm tài khoản và không
giảm kiểm tra nghiệp vụ. Cảnh báo mounted/braces của analyzer cũng đã sửa.

Log chính trong `build/`: `nutrition-plan-account.log`,
`nutrition-plan-full-final.log`, `nutrition-plan-analyze-final.log`,
`nutrition-plan-preview.log`, `nutrition-plan-apk.log`,
`nutrition-plan-secret-audit.log`, `nutrition-plan-diff-check.log`.
Log focused trung gian được giữ, có các lỗi fixture đã mô tả ở trên.
Ảnh/harness tại `build/nutrition-plan-quality/` có nhãn dữ liệu fixture,
không phải dữ liệu người dùng và không được ghi vào Firebase production.

APK: `build/releases/healthmate-nutrition-plans-20261109-debug.apk`.
Kích thước **237.545.189 byte**, SHA-256:
`0E2FB6B8C4231BC711EE141D447E5A0FB86E3A8AD3C57D3187E61CB371CF4759`.
Manifest JSON cùng tên ghi trạng thái build và triển khai.

## Giới hạn và bước sau

- Không cần cấu hình Firebase mới; cài app cập nhật để dùng thay đổi.
  Chưa nghiệm thu Android thật, ký release, deploy hoặc push GitHub.
- Nội dung mục tiêu/công cụ cá nhân hóa/kế hoạch chỉ giữ trong bộ nhớ
  của form; xác nhận thoát không phục hồi sau process death hoặc logout.
  Không tuyên bố đã có nháp bền vững như luồng nhật ký bữa ăn.
- Test mạng/lỗi dùng repository giả lập. Không chạy lại Rules emulator
  trong lượt này vì không sửa Rules, query hoặc repository Firestore.
- Chưa thêm kiểm soát phiên bản khi nhiều thiết bị cùng sửa mục tiêu/
  kế hoạch: lần ghi máy chủ sau cùng vẫn có thể ghi đè. Kiểm tra lại
  mục tiêu trong công cụ cá nhân hóa hiện có không phải khóa nguyên tử
  xuyên bước đọc và ghi.
- Luồng xóa kế hoạch và lưu gợi ý nhiều bữa chưa được nâng cấp trong
  lượt này. Đề xuất tiếp theo: rà soát hai luồng đó trong Giai đoạn 10;
  không tự triển khai nhóm tiếp theo.
