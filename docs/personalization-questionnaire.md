# Cá nhân hóa HealthMate — bộ 20 câu hỏi

Triển khai ngày 27/10/2026 theo yêu cầu. Mở rộng hồ sơ/onboarding (Giai đoạn 3), không mở giai đoạn sản phẩm khác.

## Trải nghiệm

- Cập nhật 09/11/2026: mỗi màn tập trung một câu theo tham khảo trải nghiệm Wao, dùng nhận diện HealthMate và Inter. Phần thiết yếu gồm tên, hệ số công thức, ngày sinh, số đo, một trong năm mục tiêu, vận động, phạm vi đề xuất và nhịp điều chỉnh khi thay đổi cân nặng.
- Chiều cao/cân nặng có thanh kéo và nhập số chính xác; BMI tham khảo thay đổi theo số đo. Nhịp nhẹ/vừa hiển thị phần trăm điều chỉnh và cập nhật kcal ngay, không quy đổi thành cam kết kg/tuần.
- Phần ngày tập, ăn uống, thực phẩm tránh, giấc ngủ, khó khăn và ưu tiên là nhánh tùy chọn. Số bước thay đổi theo mục tiêu và câu trả lời; không bắt người dùng hoàn thành mọi câu.
- Người đã hoàn tất hồ sơ vào app bình thường. Mở **Cá nhân → Cá nhân hóa thêm** để điền/sửa.
- Các thông tin bắt buộc cũ (ngày sinh, chiều cao, cân nặng, mục tiêu) giữ validation. Tên hiển thị là thông tin hồ sơ ngoài bộ khảo sát.
- Mọi câu bổ sung có thể để sau; không suy ra câu trả lời từ trường trống. Không tập thường xuyên bỏ câu 11–12. Duy trì/tăng cơ/thói quen bỏ câu 6–7: thường còn 16–20 câu phù hợp.
- Xem lại câu trả lời trước khi lưu; hủy không ghi dữ liệu. Chỉ nút hoàn tất ghi hồ sơ. Không xóa lịch sử.
- Trang cuối tự tạo bản đề xuất khi đủ thông tin phù hợp: mục tiêu, kcal/ngày, tổng 7 ngày nếu giữ cùng mục tiêu, năng lượng nghỉ, TDEE, phần điều chỉnh và ba chất. Có lựa chọn không áp dụng calo. Mục tiêu đang có cần đồng ý thay từ hôm nay; không thay ngầm.
- Nháp cục bộ version 2 dùng ID màn ổn định và lựa chọn nhánh tùy chọn; đọc và chuyển nháp version 1, giữ câu trả lời, không di chuyển dữ liệu sức khỏe trên Firestore.

## Danh sách và mục đích

| Câu | Nội dung | Sử dụng |
|---|---|---|
| 1 | Ngày sinh | Tuổi và phạm vi công thức |
| 2 | Hệ số nam/nữ cho công thức | Ước tính năng lượng; có thể không trả lời |
| 3 | Chiều cao | Công thức, chỉ số tham khảo |
| 4 | Cân nặng hiện tại | Công thức và lịch sử số đo |
| 5 | Mục tiêu | Giảm, duy trì, tăng cân, tăng cơ, cải thiện thói quen |
| 6 | Cân nặng đích | Chỉ giảm/tăng cân |
| 7 | Nhịp điều chỉnh nhẹ/vừa | Chỉ giảm/tăng cân; không hứa thời điểm đạt đích |
| 8 | Cần hướng dẫn riêng hay thuộc phạm vi đề xuất | Chặn đề xuất tự động nếu không xác nhận đủ điều kiện |
| 9 | Mức hoạt động thường ngày | Hệ số hoạt động tự khai, tính cả tập thường lệ |
| 10 | Ngày tập/tuần | Mô tả thói quen, không cộng kcal hai lần |
| 11 | Thời lượng một buổi | Các mốc tham khảo 15–240 phút, có thể để sau |
| 12 | Loại hình/cường độ tập | Mô tả thói quen tự khai |
| 13 | Lựa chọn ăn uống | Đặc điểm hồ sơ, chưa áp dụng bộ lọc thực đơn tự động |
| 14 | Dị ứng/thực phẩm tránh | Ghi chú tự khai ≤200 ký tự, không đảm bảo món an toàn dị ứng |
| 15 | Tần suất rau/trái cây | Ghi nhận thói quen, không suy ra gram dưỡng chất |
| 16 | Tần suất đồ uống thêm đường | Ghi nhận thói quen |
| 17 | Giờ ngủ trung bình/24 giờ | Tự khai, không tạo sleep_log hoặc tự cộng/trừ kcal |
| 18 | Lịch ngủ | Đặc điểm hồ sơ |
| 19 | Khó khăn chính | Đặc điểm hồ sơ |
| 20 | Ưu tiên ngoài mục tiêu chính | Hướng dẫn hành động đầu tiên: ghi bữa/vận động/giấc ngủ |

Tăng cơ dùng năng lượng duy trì khởi đầu; luồng thiết lập mới chọn phân bổ ưu tiên đạm có sẵn (25% đạm, 45% carb, 30% béo). Không tự tính thặng dư hay chương trình tập cơ. Giá trị `gain_weight_or_muscle` đã lưu được giữ nguyên (nhãn Tăng cân); không sửa dữ liệu người cũ. Thiết bị cũ cần cập nhật app để hiểu lựa chọn `gain_muscle`.

## Nguồn và giới hạn

Bộ câu hỏi do HealthMate tổng hợp, rút gọn và diễn đạt lại. Không phải bản GPAQ/DSQ đầy đủ, không phải công cụ WHO kiểm định, không tính điểm bệnh hay điểm sức khỏe tổng hợp.

- [WHO STEPS, bộ chuẩn 2024](https://www.who.int/publications/m/item/standard-steps-instrument): khung thông tin thể trạng, ăn uống, vận động.
- [WHO STEPS Việt Nam 2021, công bố 2025](https://www.who.int/westernpacific/publications/i/item/9789290620266): bối cảnh đã áp dụng ở Việt Nam.
- [WHO GPAQ và hướng dẫn](https://www.who.int/teams/noncommunicable-diseases/surveillance/systems-tools/physical-activity-surveillance): tham khảo lĩnh vực/cường độ/tần suất vận động; không dùng điểm GPAQ cho bản rút gọn.
- [NCI/NIH DSQ](https://epi.grants.cancer.gov/nhanes/dietscreen/): tham khảo tần suất nhóm thực phẩm. Câu 15 gộp rau/trái cây, không áp thuật toán DSQ từ mẫu Hoa Kỳ cho người Việt.
- [CDC BRFSS giấc ngủ](https://www.cdc.gov/sleep/data-research/facts-stats/adults-sleep-facts-and-stats.html): câu thời lượng ngủ trong 24 giờ.
- [NIDDK Body Weight Planner](https://www.niddk.nih.gov/health-information/weight-management/body-weight-planner): tham khảo phạm vi người trưởng thành, không phải công thức mới của app.

Câu mục tiêu, lựa chọn ăn uống, thực phẩm tránh, lịch ngủ, khó khăn và ưu tiên có phần do sản phẩm tự thiết kế. Chưa kiểm định tâm lý/độ chính xác phân nhóm. Nhóm là các đặc điểm người dùng chọn, có thể đồng thời thuộc nhiều nhóm và sửa sau.

## Lưu trữ và quyền riêng tư

`users/{uid}.personalization` là map tùy chọn có `version:1` và 15 trường câu bổ sung. Core câu 1/3/4/5/6 dùng hồ sơ và số đo hiện có, không nhân bản trong map. Trường chưa trả lời lưu null. Owner đã xác minh email mới đọc/ghi; admin không có quyền đọc hồ sơ này. Không đồng bộ sang user_directory, không gửi cho AI, không lưu lý do/y bạ chi tiết ở câu 8. Xóa tài khoản xóa map cùng hồ sơ.

Rules giữ schema hồ sơ 2, cho phép field tùy chọn để tương thích app cũ; whitelist map/enum/range/độ dài. Cần triển khai Rules trước khi dùng APK mới để lưu map. Không có database/backend/package mới.

Khi sửa khảo sát: giữ `onboardingCompletedAt` và các số đo cũ. Cân nặng không đổi không tạo số đo; nếu đổi thì thêm số đo mới. Không sửa document `onboarding-current` cũ khi cập nhật hồ sơ. Mục tiêu kcal chỉ lưu sau xem lại và hoàn tất; mục tiêu có sẵn cần xác nhận thay từ hôm nay, lịch sử giữ nguyên. Câu 8 không trả lời/cần hướng dẫn riêng không tạo đề xuất tự động nhưng vẫn dùng app/nhập mục tiêu được tư vấn riêng.

## Kiểm thử

Xem kết quả thực tế mới nhất ở [test-report.md](test-report.md). Có model/codec/nhánh/null/validation, widget tạo-sửa-tải lại/giữ số đo/đăng xuất, lỗi và thử lại mục tiêu, Rules UID/admin/ẩn danh và giới hạn payload. Ảnh kiểm tra mới dùng Inter; chưa thay cho nghiệm thu trên điện thoại.
