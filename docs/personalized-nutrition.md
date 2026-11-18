# Cá nhân hóa mục tiêu dinh dưỡng — 26/10/2026

## Sửa luồng ngoài phạm vi — 11/11/2026

Trường hợp tái hiện: chiều cao 175 cm, cân hiện tại 55 kg, đích tăng cân64kg.
BMI hiện tại `55 / 1.75² ≈ 17.96` thấp hơn ngưỡng đề xuất tự động18.5 của
phiên bản hiện hành; cân nặng đích64kg không phải nguyên nhân bị từ chối.
Đây là giới hạn sản phẩm của bộ ước tính, không phải chẩn đoán hoặc cấm chọn
mục tiêu Tăng cân. Không đổi ngưỡng/công thức hoặc sửa dữ liệu hồ sơ để vượt chặn.

Thông báo mới nêu BMI hiện tại, số đo đã dùng và phạm vi, đồng thời xác nhận
mục tiêu sức khỏe vẫn được chọn. Nêu rõ giới hạn BMI trước nút tính; sát ngưỡng
18.5 không hiển thị số làm tròn như đã đủ điều kiện. Đổi lựa chọn xóa lỗi cũ.
Sau lỗi có nút kiểm tra thông tin và mở form nhập mục tiêu thủ công ngay trong
planner lưu vào tài khoản. Chỉ form thủ công xác nhận Lưu mục tiêu mới ghi
repository; mở/nhập/hủy không ghi. Hủy form giữ nguyên số đo/đích trong planner.
Planner dùng làm bản nháp (`saveToAccount:false`) không tự mở form ghi tài khoản;
giữ thông báo thiết lập sau. Onboarding dùng cùng model nên nhận lý do chi tiết,
vẫn có thể hoàn tất hồ sơ mà chưa áp dụng đề xuất tự động như trước.

Không thêm schema/dependency, không deploy hoặc sửa quyền Firebase. Cần chạy
lại bản app/web local để thấy thay đổi. Không tự gán kcal khi ngoài phạm vi.
Kiểm thử thực tế ghi trong `docs/test-report.md`, mục cùng ngày.

Phạm vi: hoàn thiện phần mục tiêu dinh dưỡng của Giai đoạn 7 theo yêu cầu mới.
Không triển khai thêm tab điều hướng, bài tập có hướng dẫn hoặc web admin.

## Luồng sử dụng

- Người mới: bước 4/5 của thiết lập ban đầu là **Kế hoạch dinh dưỡng**. Tuổi,
  chiều cao, cân nặng và mục tiêu lấy từ ba bước trước, không hỏi lại. Chọn hệ số
  sinh lý, hoạt động thường ngày, nhịp điều chỉnh và phân bổ ba chất; xem đề xuất
  rồi bấm **Dùng đề xuất này**. Bước 5 hiển thị kế hoạch; **Hoàn tất thiết lập**
  mới xác nhận lưu. Có lựa chọn thiết lập kcal sau, không tự gán số mặc định.
- Người đã dùng: khi chưa có mục tiêu hôm nay, thẻ Năng lượng ở **Hôm nay** có
  nút **Hoàn thiện kế hoạch kcal**. Hoặc vào **Thêm → Mục tiêu dinh dưỡng → Cá nhân
  hóa kế hoạch kcal / Tính lại kế hoạch kcal từ hôm nay**.
- **Nhật ký → Chỉnh mục tiêu → Cá nhân hóa kcal và ba chất**: đề xuất điền vào
  form; kiểm tra ngày áp dụng và bấm Lưu mục tiêu riêng. Nhập tay vẫn hoạt động.
- Người cũ được điền tuổi/chiều cao/mục tiêu từ profile và cân nặng gần nhất trong
  90 ngày. Không dùng cân trong tương lai; cân thiếu/cũ để trống, yêu cầu xác nhận
  số đo hiện tại. Chỉnh thông tin trong bộ tính không tự sửa profile hay lịch sử cân.
- Mục tiêu đang có được hiển thị trước khi lưu kế hoạch trực tiếp. Người dùng
  phải đồng ý thay từ hôm nay; lịch sử trước hôm nay và phiên bản tương lai giữ nguyên.
  Lỗi đọc mục tiêu không được coi là chưa có mục tiêu. Có kiểm tra đọc lại trước lưu.

## Công thức và chính sách phiên bản đầu

Không gọi Gemini/API để tính số kcal. Model thuần Dart, tách khỏi UI và Firebase:

1. Năng lượng nghỉ REE theo hệ số hồi quy gốc Mifflin–St Jeor (1990):
   `9.99 × kg + 6.25 × cm − 4.92 × tuổi + 5` (hệ số nam), hoặc thay `+5` bằng
   `−161` (hệ số nữ). Đây là dự báo theo nhóm dân số, không phải phép đo cá nhân.
2. Nhân mức hoạt động tự chọn `1.4 / 1.6 / 1.8 / 2.0`. Đây là các mức tham khảo
   do HealthMate chọn trong khoảng PAL nêu bởi NIDDK, không phải cảm biến đo và
   không triển khai mô hình động dự báo cân nặng của NIDDK.
3. Duy trì/cải thiện thói quen: giữ mức duy trì. Giảm cân: bớt 10% hoặc 15%.
   Tăng cân: thêm 5% hoặc 10%. Hai nhịp là lựa chọn sản phẩm thận trọng; không
   dùng công thức 7.700 kcal để hứa số kg/tuần hoặc ngày đạt đích. Tăng cân không
   đồng nghĩa tăng cơ; muốn giữ cân khi tập cơ có thể chọn duy trì.
4. Kcal làm tròn tới 10. Phân bổ **đạm/carb/béo**: cân đối `20/50/30%` hoặc ưu
   tiên đạm `25/45/30%`. Gram = kcal × tỷ lệ / `4, 4, 9`, làm tròn 0,1 g. Hai
   lựa chọn nằm trong khoảng AMDR; không khẳng định phù hợp mọi cá nhân.

Giới hạn **đề xuất tự động** của bản này: tuổi 18–65; BMI hiện tại/đích từ 18,5
đến dưới 40; phải xác nhận không mang thai/cho con bú, ăn điều trị, rối loạn ăn uống
hoặc nhu cầu thể thao chuyên nghiệp. Cần kiểm tra hướng cân nặng đích giảm/tăng.
Từ chối thay vì âm thầm ép kết quả khi thấp hơn 1.200 kcal (hệ số nữ), 1.500 kcal
(hệ số nam) hoặc trên 5.000 kcal. Đây là rào kiểm tra sản phẩm, **không phải ngưỡng
an toàn y khoa chung**. Ngoài phạm vi vẫn có luồng nhập mục tiêu được tư vấn riêng.

Nguồn đã đối chiếu:

- [Mifflin và cộng sự, 1990 — bài nghiên cứu gốc](https://pubmed.ncbi.nlm.nih.gov/2305711/?dopt=Abstract).
- [NIDDK Body Weight Planner — thông tin đầu vào, PAL và phạm vi](https://www.niddk.nih.gov/bwp).
- [Health Canada — bảng DRI/AMDR](https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/dietary-reference-intakes/tables/reference-values-macronutrients.html).

## Dữ liệu và an toàn khi lưu

Không thêm collection, field hoặc dependency. Kết quả được xác nhận lưu bằng
`NutritionTargetRepository` hiện có vào `users/{uid}/nutrition_targets/{dateKey}`,
schema 1, source `user_manual` (người dùng chọn và xác nhận). Chỉ lưu kcal và ba
chất; lựa chọn hệ số/nhịp và đầu vào lần tính không được lưu thêm hay gửi AI.
Tương thích Rules MVP đang có; không cần deploy Rules cho tính năng này.

Dashboard, Nhật ký, ngân sách năng lượng và context chatbot đều dùng provider/
repository mục tiêu chung. Thay target vô hiệu hóa credit bước cũ theo quy tắc
đã có; không bật cộng bước tự động. Mức hoạt động đã bao gồm vận động thường ngày.
Không quy đổi giờ ngủ ra kcal, không tự đổi target khi có cân nặng mới.

Form gắn với UID khi mở; đóng và bỏ bản nháp khi đổi tài khoản. Bản nháp trong RAM,
không hứa phục hồi sau khi process bị tắt. Lỗi lưu giữ form; đang chờ máy chủ thì
chặn gửi lặp. Sang ngày mới yêu cầu tính lại, không ghi mục tiêu về ngày cũ.

Onboarding lưu target trước rồi mới hoàn tất profile để tránh router rời màn hình
trước khi target được xác nhận. Hai repository chưa phải một transaction nguyên tử:
nếu target đã lưu mà profile lỗi, app báo đúng trạng thái và lần thử lại dùng cùng
target/ngày, không tạo bản trùng. Không tự xóa target đã được người dùng xác nhận.

## Kiểm thử và giới hạn nghiệm thu

Kiểm thử mới bao phủ công thức/hệ số, rounding macro, giới hạn/thiếu dữ liệu,
hướng cân đích, tuổi/ngày sinh, cân quá cũ/tương lai; luồng cũ/mới, xác nhận thay
target và giữ lịch sử, lỗi đọc/lưu/thử lại, mục tiêu đổi trong lúc xem, qua nửa đêm,
đăng xuất khi chờ lưu, nhất quán Dashboard/Journal/chat, màn 360×800 chữ 150%.
Ảnh widget với font thật ở `build/personal-nutrition-ui/`; chỉ là fixture kiểm thử.

Kết quả cuối xem đầu [test-report.md](test-report.md). Chưa cài/nghiệm thu trên
điện thoại thật trong đợt này; người dùng trước đó đã chọn kết nối sau. Không
triển khai Firebase/Cloudflare, không commit/push mới và không lặp lại shutdown.

APK debug thường, entry point `lib/main.dart`:
`build/releases/healthmate-personalized-nutrition-debug.apk` (236734942 byte).
SHA256 `98EA2B7583EED24247304AE70E6A153586D1AD3670A528146679D3AA27AF644B`.
Đây là bản cục bộ có cấu hình debug App Check đã dùng trước đó, không phải artifact
integration test hay bản phát hành production.
