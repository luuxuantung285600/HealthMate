# Sửa lỗi từ chối lưu món trên admin — 11/11/2026

Phạm vi: bảo trì Giai đoạn 4, sửa thao tác cập nhật danh mục thực phẩm đang
phát hành. Đã triển khai tại https://healthmate-admin-vn.web.app/.

## Nguyên nhân và thay đổi

- Tài khoản quản trị đã xác minh, không bị vô hiệu hóa và có role enabled khi
  kiểm tra chỉ đọc. Rules production đã hỗ trợ ảnh và extra nutrients.
- `changedFields()` dùng JSON.stringify để so sánh map. Form dựng lại các
  trường ảnh/dinh dưỡng theo thứ tự khác với document hiện có dù giá trị không
  đổi. Firestore không tính đổi thứ tự key là thay đổi; audit không khớp
  `affectedKeys()`, nên transaction món + audit bị từ chối.
- Kiểm tra chỉ đọc 300 document đầu (còn trang tiếp) thấy 171 món có thay đổi
  giả ở map dinh dưỡng; ví dụ banana-raw, egg-boiled. Không suy rộng số này
  thành tổng toàn catalog. Không thay dữ liệu món để kiểm thử production.
- So sánh map theo cấu trúc, không phụ thuộc thứ tự key; array vẫn xét thứ tự,
  khác biệt giá trị thật vẫn được ghi audit. Giữ hành vi timestamp/SDK cũ.
- Đổi nhãn thành “Đường dẫn nguồn dinh dưỡng (HTTPS)” và thêm hướng dẫn dùng
  phần ảnh món ăn để đổi ảnh. URL ảnh Pinterest trong screenshot là ô nguồn
  dinh dưỡng bị nhập nhầm, nhưng tự nó không gây lỗi permission-denied này.
- Hai ô khẩu phần cùng trống và lý do “Thích” đều hợp lệ theo hợp đồng hiện có.

File chính: `admin-web/dist/validation.mjs`, `admin-web/dist/app.mjs`,
`admin-web/test/validation.test.mjs`,
`admin-web/test/realtime-sdk.integration.mjs`.

## Kiểm thử thực tế

- `node --test admin-web/test/validation.test.mjs`: **8/8 qua**.
- `npm --prefix admin-web run check`: qua.
- `npm --prefix admin-web test`: **140/140 qua**.
- Auth/Firestore Emulator với đúng Rules đọc từ production:
  `node --test admin-web/test/realtime-sdk.integration.mjs`: **15/15 qua**;
  `node --test admin-web/test/sdk.integration.mjs`: **9/9 qua**.
- Regression mới lưu full form có map đổi thứ tự: chỉ sửa tên, giữ dữ liệu,
  lưu cùng giá trị, thay ảnh/đường thật sự, nhận stream ở phiên đọc khác.
  Kiểm tra danh sách audit chính xác; audit khai thêm field không đổi vẫn bị
  từ chối và không làm thay đổi món đã lưu.
- Kiểm tra lại riêng regression với đúng module trong gói Hosting chuẩn bị
  phát hành: **1/1 qua**. Không gọi kết quả này là test UI production.
- Lần chạy integration đầu có assertion giả định emulator luôn đảo thứ tự
  map ảnh; assertion thất bại trước lưu. Fixture được sửa để chủ động tạo hai
  map cùng giá trị, khác thứ tự. Không đổi Rules hoặc nới kiểm tra quyền.
- `node --check` các file sửa/gói phát hành và `git diff --check`: qua.
  Không sửa Dart/Android nên không chạy lại Flutter format/analyze/test/build.

Log và gói phát hành nằm trong `build/admin-food-save-fix-20261111/`.

## Phát hành và giới hạn

- Sao lưu Rules và phiên bản Hosting trước phát hành; tái kiểm baseline trước
  deploy. Gói giữ đúng toàn bộ site hiện hành, chỉ sửa validation.mjs và nhãn/
  hint trong app.mjs; không phát hành các thay đổi bài tập đang chờ trong source.
- `firebase deploy --project healthmate-app-20261013 --config
  build/admin-food-save-fix-20261111/candidate-v2/firebase.review.json --only
  hosting --non-interactive`: exit 0; 430 file, upload 2 file thay đổi.
- Hosting version mới: `sites/healthmate-admin-vn/versions/c4e199755afa8c6e`.
  Đọc lại 5 URL qua HTTPS: HTTP 200, bytes khớp gói, no-store và CSP đúng.
- Ruleset trước/sau giữ nguyên
  `projects/healthmate-app-20261013/rulesets/38076bf8-ba26-4578-a415-0233e508c4aa`.
  Không đổi quyền, cấu trúc database hoặc dịch vụ; không bật billing.
- Không thực hiện ghi kiểm thử, tự sửa nguồn dinh dưỡng hoặc thay ảnh món thật
  ở production. Lưu production bằng phiên người dùng vẫn cần người dùng thử.
  Cửa sổ Chrome đang thu nhỏ nên không đọc được form trực tiếp bằng computer-use;
  đã đối chiếu screenshot, code online, dữ liệu catalog và Rules chỉ đọc.
- Người dùng sao chép URL đang nhập trước khi tải lại tab bằng Ctrl+F5, mở lại
  món và lưu. URL ảnh đặt ở phần **Ảnh món ăn**; nguồn dinh dưỡng giữ link trang
  cung cấp số liệu. Không cần chạy lại Flutter/VS Code cho thay đổi dữ liệu.
- Tiếp theo đề xuất: nghiệm thu lưu món/ảnh trên phiên admin đang sử dụng;
  không triển khai giai đoạn khác trong lượt sửa này.
