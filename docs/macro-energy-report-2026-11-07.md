# Giai đoạn 8 — biểu đồ năng lượng dưỡng chất và chi tiết món

Ngày: 07/11/2026. Phạm vi lượt này: Tiến độ/Weekly Reflection và báo cáo theo kỳ.
Chủ dự án yêu cầu làm phần khác, để nghiệm thu Android thật và ký phát hành sau.
Không triển khai giai đoạn đó, AI, thanh toán hoặc dịch vụ mới trong lượt này.

## Người dùng làm được gì

- Mở **Tiến độ → Dưỡng chất** để xem biểu đồ tròn Carb/Đạm/Chất béo của tuần.
- Các báo cáo 30/90 ngày, năm và khoảng ngày tùy chọn có cùng biểu đồ.
- Chạm lát biểu đồ hoặc nút tên dưỡng chất để xem món đóng góp nhiều nhất,
  ngày/bữa, khẩu phần g/ml/phần/lần ghi, số gram dưỡng chất, năng lượng và nguồn.
- Chi tiết xuất hiện tại cùng màn hình và được cuộn vào vùng nhìn thấy.
  Back hoặc nút đóng chỉ đóng chi tiết, giữ bộ lọc/khoảng ngày.
- Danh sách bắt đầu bằng 20 món, có nút xem thêm 20 món khi cần.
- Dữ liệu cùng kỳ thay đổi thì biểu đồ và chi tiết dùng lại dữ liệu mới từ
  provider báo cáo hiện có. Loading/lỗi nguồn không để lại dialog chứa tổng cũ.
  Đổi UID chặn hiển thị snapshot của UID trước và bỏ lựa chọn đang mở.

## Cách tính và tính trung thực của số liệu

Năng lượng Carb = gram Carb × 4; Đạm = gram Đạm × 4; Chất béo = gram Chất béo × 9.
Tỷ lệ mỗi lát = năng lượng dưỡng chất đó / tổng năng lượng ba dưỡng chất.
Đây là cách ước tính từ **snapshot món đã lưu**, không dùng tổng kcal của bữa,
mục tiêu ăn, dữ liệu catalog hiện tại hoặc con số AI để lấp phần thiếu.
Năng lượng suy ra từ macro có thể khác kcal đã ghi; giao diện giải thích mẫu số.

Chi tiết mỗi món tính phần trăm trong **dưỡng chất đang chọn**, khác mẫu số
của lát biểu đồ; giao diện ghi rõ tổng kcal của dưỡng chất đó. Không nhân lại
khẩu phần vì snapshot đã chứa giá trị theo khẩu phần xác nhận. Không quy đổi
ml thành g. Món có cờ ước tính vẫn hiện nhãn ước tính và nguồn đã lưu.

Không có bữa → hướng dẫn ghi nhận; bữa thiếu chi tiết/món thiếu bất kỳ macro
nào hoặc giá trị không hợp lệ → báo chưa đủ dữ liệu và không vẽ tỷ lệ. Đủ
dữ liệu nhưng tổng bằng 0 → giải thích không có tỷ lệ, không chia cho 0.
Không tính tuần/ngày chưa ghi là mức ăn 0, không dùng biểu đồ để chẩn đoán.

Lọc theo `dateKey` đã ghi (fallback ngày địa phương của `consumedAt`), trong
khoảng bao gồm ngày đầu/cuối, bỏ ngày tương lai. Trùng ID bữa chỉ tính một lần;
một món xuất hiện nhiều lần trong các bữa vẫn giữ từng lần đóng góp.

## File chính

- `lib/features/reports/models/macro_energy_report.dart`: tổng hợp thuần Dart.
- `lib/features/reports/presentation/macro_energy_card.dart`: Pie/legend,
  chi tiết, phân trang hiển thị và bảo vệ UID/Back.
- `lib/features/progress/presentation/progress_screen.dart`: ghép vào tuần.
- `lib/features/reports/presentation/period_report_panel.dart`: ghép vào kỳ.
- `test/macro_energy_report_test.dart`: tính toán, tương tác, cập nhật dữ liệu,
  ownership, bố cục và kiểm số lần repository đọc.

Không đổi schema/Rules/indexes, không migration, không thêm package/listener.
Giữ các thay đổi gói Android ở lượt trước. Chỉ dữ liệu fixture trong test;
không seed hay viết số liệu giả vào sản phẩm/production.

## Kiểm chứng

- Bộ kiểm thử mới **24/24 qua**: 4/4/9 khác total kcal; khẩu phần ml; partial,
  unknown, zero, dữ liệu sai; biên ngày/future/dateKey/dedup; thứ tự đóng góp;
  chạm lát/legend; Back; cập nhật cùng kỳ/đổi kỳ/UID; phân trang 20/40/45 món;
  320/390/720 px × chữ 100%/200% × sáng/tối; tuần/kỳ không tăng query khi chạm.
- Analyzer toàn dự án: **không issues**.
- Full suite: **997/997 qua** (bao gồm 24 test mới).
- Sau full suite, bổ sung assertion vào test tích hợp để chặn biểu đồ cũ khi
  nguồn đang tải/lỗi, đổi dữ liệu 1000 → 200 kcal và phục hồi; chạy lại **24/24 qua**.
- Render với font Inter thật: **2/2 qua**, đã xem ảnh sáng/tối và chi tiết.
  Preview chỉ dùng fixture có banner DỮ LIỆU KIỂM THỬ, không phải số liệu tài khoản.
- Format check 5 file Dart: **0 thay đổi**; `git diff --check`: qua.
- `./tool/build_android.ps1`: **7/7** kiểm tra cấu hình admin qua, build
  debug thành công; Gradle assembleDebug 16,9 giây. KGP vẫn có cảnh báo
  deprecation của bản Flutter tương lai; không đổi dependency trong lượt này.

Log full: `build/macro-energy-full-tests.log`; tập trung cuối:
`build/macro-energy-tests-final.log`; analyzer:
`build/macro-energy-analyze-last.log`; render: `build/macro-energy-preview.log`.
Ảnh fixture: `build/macro-energy-light-chart.png`,
`build/macro-energy-dark-detail.png` cùng hai biến thể còn lại.
Các lượt lỗi ban đầu được giữ riêng:
test helper dùng wildcard `_` sai; sau đó helper chưa pump sau khi cuộn nên
chạm ngoài màn hình. Đã sửa fixture, giữ assertions và kiểm tương tác thật.
UI bổ sung cuộn tới tiêu đề chi tiết để người dùng thấy kết quả sau khi chạm.

## Artifact

- APK: `build/releases/healthmate-progress-20261107-debug.apk`.
- Manifest: `build/releases/healthmate-progress-20261107-debug.json`.
- Build lúc `2026-11-07T12:44:55.854113Z`; 237.059.036 byte; Premium demo tắt.
- SHA-256: `F059FB04B20E1C8A1B4146F28785B38B2D35A45BF38AD536212C51F0D62AFAE6`.
- Log build: `build/macro-energy-apk.log`; manifest bằng chứng/hash source:
  `build/macro-energy-evidence-20261107.json`.

Đây là APK debug để xem phần app đã sửa, không phải nghiệm thu hay bản phát
hành ký. Không ghi đè artifact Android-quality của lượt trước.

## Giới hạn và bước tiếp theo

- Tỷ lệ chỉ phản ánh các món đã ghi và chất lượng nguồn snapshot, không phải
  tỷ lệ chính xác của toàn bộ thực phẩm đã ăn hoặc khuyến nghị cá nhân.
- Không nghiệm thu điện thoại thật, không ký/publish release trong lượt này,
  theo lựa chọn chủ dự án. Không bật billing/Functions, không thay production.
- Đề xuất tiếp theo trong phạm vi app: cải thiện luồng Báo lỗi & Góp ý;
  chưa thực hiện trong gói báo cáo này.
