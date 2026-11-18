# Web admin đồng bộ giao diện app — 14/11/2026

## 1. Giai đoạn và phạm vi

Giai đoạn tùy chọn 11 — polish web admin theo yêu cầu tiếp nối. Đổi nhận diện
theo app và phát hành phần quản lý thư viện bài tập đã được yêu cầu trước đó.
Không triển khai giai đoạn nghiệp vụ khác, thay Rules/schema, Functions, billing
hoặc dữ liệu production. Bản web: https://healthmate-admin-vn.web.app.

## 2. Đã hoàn thành

- Nền tối đen `#000`, nền sáng trắng; primary đen/trắng trung tính, bỏ primary
  tím và màu trạng thái xanh mint. Panel, sidebar, form, bảng, nút và focus dùng
  chung palette. Thực phẩm cam, bài tập san hô, Premium vàng; màu AI chỉ ở các
  dấu nhận diện phù hợp. Đồng bộ 17 màu feature từ `AppFeatureVisual` hiện tại.
- Giữ Public Sans và icon Lucide được ghim sẵn, không thêm package/CDN.
- Trang **Bài tập luyện** có 50 bài đi kèm cùng override từ Firestore, tổng
  bài/đang hiển thị/đã ẩn, tìm không dấu và bộ lọc nhóm cơ/dụng cụ/trạng thái.
  Xuất Excel theo cùng bộ lọc, kèm ngữ cảnh. Bỏ nhãn **Chỉ đọc** đã lỗi thời.
- Thêm/sửa/ẩn/khôi phục giữ transaction, phiên bản, lý do và audit nguyên tử.
  Thay đổi được nhận qua listener hiện có; lỗi kết nối gỡ dữ liệu chưa xác nhận
  và chặn ghi. Ẩn bài không xóa lịch sử đã lưu trong app.
- Bản thử nghiệm local có GIF ngay trong danh sách: khung cố định, tải khi
  cuộn tới, tối đa hai yêu cầu metadata đồng thời, có dừng/thử lại. Mỗi preview
  có AbortController riêng; lọc/rời trang/chuyển nền gỡ ảnh và hủy đúng yêu cầu.
  Khi không có IntersectionObserver vẫn có nút xem thủ công. Giữ kiểm ID/CDN,
  fresh metadata và backoff 429. Không lưu tệp GIF hoặc URL vào Firestore.
- Giữ cổng môi trường: bản miễn phí ExerciseDB chỉ dùng thử phi thương mại
  trên localhost. Web online quản lý đầy đủ bài tập nhưng **không phát GIF
  miễn phí**; giao diện giải thích rõ điều kiện này. Không tự mua gói media.

## 3. File chính

- `admin-web/dist/appearance.css`, `feature-identity.css`,
  `licenses/lucide-manifest.json`, `admin-shell.mjs`, `index.html`.
- `admin-web/dist/workouts-page.mjs`, `exercise-media-preview.mjs` mới và
  `exercise-library.css` mới.
- Các kiểm thử `exercise-media-preview.test.mjs`, `app-dom.test.mjs`,
  `browser-identity.cjs`, `release-contract.test.mjs`; `package.json` bổ sung
  lệnh kiểm cú pháp phần bài tập. README và hai báo cáo tổng được cập nhật.

Các module `app.mjs`, `firebase.mjs`, `live-data.mjs`, `exercise-library-model.mjs`
và `bundled-exercise-library.mjs` đã có trong source trước lượt này. Phát hành
phần nối thư viện còn thiếu trên website bằng allowlist riêng, giữ các sửa đổi
khác trong working tree ngoài bundle.

## 4. Kiểm thử thực tế

- `npm --prefix admin-web run check`: exit 0.
- `npm --prefix admin-web run check:exercises`: exit 0.
- `npm --prefix admin-web test`: **147/147 qua**, 0 bỏ qua; 9,24 giây.
  Kiểm lazy load, pause/retry, chuyển nền, dispose, late completion, hủy riêng
  từng owner, giới hạn queue và bộ lọc trạng thái với một subscription hoạt động.
- Chrome headless ở profile riêng: **72 lượt trang**, 9 trang × 4 chiều rộng
  1440/1024/390/320 × 2 theme. Kiểm menu bàn phím, dialog, đăng nhập, lưu theme,
  font, canvas, vùng bấm, 10 nhóm món và lọc xuyên trang; không tràn ngang.
  Candidate chính xác cũng qua đủ 72 lượt; `browser-candidate/browser-results.json`.
- Đọc GIF ExerciseDB thật trong browser local trên candidate: Burpee
  `dK9394r` và chống đẩy chân trên bục `i5cEhka`, đều 180×180; ảnh load hoàn tất,
  nút chuyển **Dừng GIF**, mở danh sách 50 bài chỉ có hai ảnh trong DOM. Đã xem
  ảnh chụp kết quả thật; không khẳng định đã xác minh tất cả 50 GIF.
- Firebase Auth/Firestore Emulator với đúng Rules production đang dùng và
  **đúng JS trong candidate**: **1/1 luồng SDK qua**. Tạo, sửa/ẩn, khôi phục,
  audit actor/entity, snapshot trực tiếp và từ chối ghi đè bằng phiên bản cũ.
  Seed cố định trong `demo-healthmate-admin`; không ghi thử production.
- `git diff --check` cho các file sửa: exit 0, chỉ cảnh báo LF/CRLF sẵn có.
  Không sửa Dart/Android nên không chạy lại Flutter format/analyze/test/build.

Các lần kiểm tra đầu có lỗi được ghi nhận, không đổi sản phẩm để che lỗi:

- Assertion browser cũ còn đòi mã món/focus trong form sửa ảnh; form URL-only
  hiện tại chỉ chứa phần ảnh. Đã cập nhật test kiểm đúng món, form ảnh riêng,
  preview và URL nguy hiểm. Test subscription mới đếm cả subscription đã dừng;
  sửa thành xác minh chỉ một subscription **đang hoạt động** sau khi lưu.
- Lần đầu Firebase Emulator từ chối Rules nằm ngoài thư mục config; sao chép
  đúng Rules đã phát hành vào thư mục QA, chạy lại với JBR 21 và thành công.
- Lần kiểm mạng GIF trên candidate đầu hết thời gian; các 72 lượt UI đã qua
  trước đó. Kiểm riêng GIF lại thành công, xác nhận cả load hoàn tất và trạng
  thái nút, không giảm assertion. Không xác định nguyên nhân mạng lần timeout;
  nguồn ngoài vẫn có thể giới hạn lượt tải/gián đoạn.

Log/ảnh tại `build/admin-ui-refresh-20261114/`: `node-tests-final.log`,
`browser-final.log`, `browser-candidate/`, `browser-gif-recheck/`,
`sdk-emulator-rerun.log`, `deploy.log` và `hosted-verification.json`.

## 5. Phát hành và việc người dùng cần làm

Chụp baseline Hosting `3ff1559b0dd77f75` và Ruleset
`4182be7f-4e92-4b3d-b0c3-9944b201dbef`. Tạo candidate từ **430 file đang chạy**,
chỉ thay/thêm 13 file cho phạm vi này. Giữ nguyên byte của 421 file khác, gồm
config, font, ảnh, validation và workflow sửa ảnh URL-only. Một dòng xử lý focus
cũ ngoài phạm vi được giữ ở candidate thay vì cuốn chênh lệch local lên web.

Kiểm trước phát hành: baseline chưa đổi, cấu hình/App Check/`statisticsMode`
giữ nguyên, đủ module phụ thuộc, không phát hiện private key/service account/
refresh token/client secret trong site. Gói phát hành chỉ có cấu hình Hosting,
không có Rules hoặc Functions.

Lệnh phát hành đã chạy, exit 0:

```powershell
node "$env:APPDATA/npm/node_modules/firebase-tools/lib/bin/firebase.js" deploy --project healthmate-app-20261013 --config build/admin-ui-refresh-20261114/candidate/firebase.hosting.json --only hosting --non-interactive
```

Đọc lại sau phát hành: **17/17 URL HTTP 200 và byte/hash khớp candidate**,
Cache-Control `no-store`, CSP giữ nguyên. Hosting version mới
`sites/healthmate-admin-vn/versions/d18532468d67f18a`; Ruleset vẫn là
`4182be7f-4e92-4b3d-b0c3-9944b201dbef`. Không ghi dữ liệu kiểm thử production.

Mở website rồi **Ctrl+F5** để nhận bản mới. Không cần chạy lại Flutter hoặc đổi
cấu hình Firebase. Xem `hosted-verification.json` để biết version mới và hash
của các URL sau phát hành. Bản sao hoàn chỉnh/version rollback được lưu trong
`production-before/`; không commit/push Git ở lượt này.

## 6. Giới hạn

Các ảnh/ca UI dùng adapter kiểm thử local có nhãn, không phải dữ liệu tài khoản
hoặc doanh thu hiện tại. Chưa đăng nhập/lưu bằng tài khoản admin thật trên
production; kiểm ghi được thực hiện bằng SDK thật với emulator. Bản online
không phát GIF miễn phí do điều kiện sử dụng đã chốt. Không nghiệm thu Android,
không ký bản phát hành và không tắt máy người dùng.

## 7. Đề xuất tiếp theo

Nghiệm thu thao tác admin/app với dữ liệu thật theo yêu cầu riêng; không tự
chuyển sang giai đoạn tiếp theo.
