# Danh mục có ảnh — 11/11/2026

Giai đoạn 4 bổ sung. Người dùng đã chốt **“Bỏ món đó nếu ko có ảnh”**,
thay cho giữ đủ 500 bằng ảnh sai món hoặc ảnh AI.

## Kết quả

- Bộ 500 mục chung giữ **379 mục có ảnh**, ẩn **121 mục chưa đạt yêu cầu**.
  Hai nhóm gợi ý trái cây/đồ uống còn lần lượt 87/80 mục sau lọc.
- Ảnh WebP 512 × 512, khoảng 15,7 MB; app/admin dùng cùng checksum và nguồn.
  Các mục cùng thực phẩm/trạng thái có thể dùng chung ảnh đã duyệt từng ID;
  không coi 379 mục là 379 ảnh chụp gốc khác nhau.
- Đã xem toàn bộ contact sheets. Không chọn ảnh có người, sai thực phẩm hoặc
  sai trạng thái. Lượt cuối loại thêm mứt chuối húng quế còn bánh mì trong
  khung và ảnh chưa xác minh được trạng thái gạo lứt sống.
- Dinh dưỡng vẫn lấy từ catalog có nguồn/cờ ước tính; không suy ra từ ảnh.

`data/food_catalog/photo-release.json` lưu scope, ID giữ lại và lý do loại.
`assets/food_photos/manifest.json` lưu danh tính, nguồn, crop và checksum.
Registry app/admin và attribution được sinh từ manifest này.

Nguồn gồm Commons, Flickr với CC BY/CC BY-SA/CC0/public domain, Pexels và bao
bì nhà sản xuất. Bao bì giữ bản quyền nhà sản xuất; không tự gán giấy phép CC.

## Dữ liệu và đồng bộ

Đã phát hành `photo-visibility-20261111-v1`: **121 cập nhật + 121 audit**.
Đọc lại xác minh đủ 500 document: 379 hoạt động, 121 ẩn, mọi field của 379
document còn lại nguyên vẹn. Review sau apply: 0 cập nhật/0 xung đột.

Chỉ cập nhật `isActive`, thông tin thao tác quản trị và timestamp. Không xóa
document, đổi dinh dưỡng hoặc sửa hồ sơ/món riêng/snapshot nhật ký cũ. Admin
vẫn xem và sửa được các mục đã ẩn. Listener hiện có đưa trạng thái sang app.

Bản app mới áp dụng danh sách loại trừ offline cho catalog, cache và bí danh
USDA theo FDC ID. Admin có thể thêm ảnh custom hợp lệ rồi khôi phục món;
ảnh custom vượt qua loại trừ mặc định, còn trạng thái ẩn của admin ưu tiên.
Khôi phục chỉ với ảnh mặc định khi chưa có ảnh vẫn bị loại trừ offline.

Phạm vi chỉ là **bộ 500 mục chung**. Các bộ USDA tham khảo mở rộng ngoài scope
và món riêng không bị xóa theo đợt này. Sáu ID catalog gốc chưa có bản dinh
dưỡng offline tương ứng, được nhận từ Firestore; ảnh của cả sáu đã đóng gói.
Không dùng số lượng kho USDA để tuyên bố đủ 500 món có ảnh.

## Kiểm tra và bản chạy

Publisher có review trước apply, precondition `updateTime`, mask hẹp, audit
create-only cùng atomic commit, kiểm tra thay đổi đồng thời và đọc lại. Có
test legacy thiếu `isActive`, ảnh custom có khoảng trắng, giữ nguyên field
không liên quan. Review/receipt: `build/photo-visibility-release-20261111-v3/`.

Đã xem ảnh sáng/tối, 320px/chữ 200%, giải mã và đối chiếu mọi ảnh. Contact
sheets: `build/photo-audit/final-0.jpg` đến `final-6.jpg` (trước khi loại hai
ảnh cuối). Ảnh bị loại có bản phục hồi tại `build/full-food-photos/withdrawn/`.
Kết quả kiểm thử/build cuối: `implementation-progress.md`, `test-report.md`.

Cần chạy/cài app mới để nhận ảnh asset. Admin local dùng dist mới sau khi
tải lại. Chưa publish hosting/Functions, thay Rules, bật billing hoặc ký
bản phát hành. Chưa nghiệm thu trên điện thoại thật.

Bước tiếp theo đề xuất: nghiệm thu ảnh trên bản admin được triển khai khi
người dùng yêu cầu; phần Android thật vẫn chưa thực hiện.
