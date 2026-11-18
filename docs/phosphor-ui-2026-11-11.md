# 11/11/2026 — Giai đoạn 1 bổ sung: icon Phosphor và phân cấp hình khối

## Yêu cầu và phạm vi

Thay bộ icon Lucide theo yêu cầu tìm nguồn Figma, đồng thời chỉnh các khung
bo góc đang lặp lại. Chỉ thay UI/tài nguyên Flutter và công cụ kiểm tra nguồn;
giữ dữ liệu, luồng nghiệp vụ, font Public Sans và nền Home sáng trắng/tối đen.

## Nguồn đã đối chiếu

- Trang chính thức: https://phosphoricons.com/
- Kho plugin Figma chính thức: https://github.com/phosphor-icons/figma
- Plugin Figma được kho chính thức liên kết:
  https://www.figma.com/community/plugin/898620911119764089/Phosphor-Icons
- Tài nguyên triển khai: `@phosphor-icons/web` phiên bản 2.1.2, nguồn
  https://github.com/phosphor-icons/web và npm registry. Giấy phép MIT cho phép
  phân phối trong app; kèm nguyên văn copyright/giấy phép tại
  `assets/fonts/healthmate_icons/LICENSE.txt`.

Nguồn Figma được xác minh từ kho chính thức; không tuyên bố đã mở/sửa một file
thiết kế Figma của người dùng. Font triển khai lấy từ cùng dự án Phosphor,
không lấy ảnh chụp hoặc trích icon từ thiết kế của bên khác.

## Thay đổi giao diện

- Các thao tác dùng nét regular; tính năng dinh dưỡng, nước, dưỡng chất, AI,
  Premium và một số biểu tượng nội dung dùng fill. Thanh điều hướng có icon
  regular khi chưa chọn, fill khi đang chọn; giữ nhãn và semantics selected.
- Đạm dùng trứng, đường bột dùng ngũ cốc, chất béo dùng quả bơ, nước dùng giọt,
  dinh dưỡng dùng bát thức ăn; cân nặng dùng mặt đồng hồ đo.
- Card lớn dùng `ContinuousRectangleBorder` và mặt nền nhẹ; giảm viền toàn
  khối. Nhóm nhỏ dùng đường cong riêng, không mặc định thêm viền; trạng thái
  chọn vẫn rõ và không phụ thuộc chỉ vào khác biệt nét icon.
- Bỏ nền hộp lồng ở ba chỉ số calo. Các lựa chọn bảng dưỡng chất nằm trong
  cùng một mặt nền, chỉ mục đang chọn có nền nhấn.
- Bốn bữa ăn dùng chung một mặt nền với đường phân cách thụt lề. Giữ thao tác
  xem/thêm/ghi lại bữa cũ, dữ liệu rỗng/loading/error và keys hiện có.
- Vùng chạm, chữ lớn, điều hướng, chế độ sáng/tối và các luồng hiện tại vẫn
  được kiểm tra bằng suite có sẵn.

## Tài nguyên và khả năng tái tạo

Giữ tên font `HealthMateIcons`, đường dẫn font và API aliases hiện có. Công cụ
subset regular/fill vào một font offline, gán codepoint riêng để hai kiểu nét
không đè nhau. Manifest ghi nguồn chính xác, SHA256 font/CSS/giấy phép, aliases
và hash font đầu ra. Không thêm dependency vào app hoặc tải icon lúc chạy.

Bản cuối có 125 glyph và 142 tên API, giữ đủ 138 tên cũ và thêm 4 trạng thái
tab được chọn. Font 32.892 byte, SHA256
`7172ab346a9dad564b3f9afb7d4f6758e8fd88cdac9961e60683e5f546573335`.
Hai lần tái tạo có cùng hash; font/registry/giấy phép được kiểm tra độc lập.

Admin đang dùng Lucide được tách nguồn ghim riêng ở
`admin-web/dist/licenses/lucide-source.json`; generator và test admin kiểm tra
nguồn này thay vì phụ thuộc bản font Flutter. Không đổi SVG/giao diện admin
hoặc deploy admin trong lượt này. Màu tính năng vẫn lấy từ `AppFeatureVisual`.

File chính: `app_icons.dart`, `app_shapes.dart`, `app_theme.dart`,
`home_palette.dart`; AppCard/AppInsetPanel/IconChip/FeatureIconBadge/AppShell;
dashboard và các widget calo/dưỡng chất/bữa ăn; font/manifest/license,
`tool/build_app_icons.py`, `tool/build_admin_icons.py`,
`test/icon_system_test.dart`, `admin-web/test/appearance.test.mjs`.

## Kiểm thử

- `tool/build_app_icons.py --verify`: qua; cmap riêng cho regular/fill, glyph
  không rỗng, hash font/giấy phép khớp, đủ aliases cũ và không còn `Icons.*`
  trong mã sản phẩm. Hash nguồn TTF/CSS/giấy phép được ghim và kiểm khi tái tạo.
- Nhóm Flutter icon/navigation/Home/dưỡng chất/nhật ký/Progress: 94/94 qua,
  exit 0, 23 giây. Sau đó tinh chỉnh icon cân nặng và trứng trước lượt full.
- `flutter analyze --no-pub`: sạch, exit 0, lần đầu 15,6 giây; lần cuối sau
  khi chốt font 16,4 giây.
- `node --test admin-web/test/appearance.test.mjs`: 5/5 qua, exit 0; nguồn
  Lucide admin, giấy phép, alias dùng chung và bảng màu vẫn được kiểm tra.
- Đã xem ảnh Home sáng/tối, các bảng icon cuối (cân nặng đã dùng gauge), bữa ăn
  nhóm mới và các kích thước nhỏ/chữ lớn trong suite hiện có. Không thấy glyph
  trống hoặc bị thay thành ô vuông.
- `flutter test --no-pub --reporter json`: 1.289/1.289 qua, không lỗi/skip,
  exit 0, 140.238 ms. Hash font trong tài nguyên chạy test khớp bản nguồn cuối.
- `dart format --output=none --set-exit-if-changed`: 14 file qua, không thay đổi.
- `git diff --check` trong phạm vi thay đổi: qua.

Log: `build/phosphor-ui/focused.log`, `full-test.jsonl`, `test-summary.json`,
`analyze.log`, `analyze-final.log`, `admin-appearance.log`. Ảnh thực tế của
widget test: `build/icon-system/` và `build/home-reference/`.

## Cần thực hiện thủ công và giới hạn

Dừng và chạy lại app từ source để nạp bộ font mới; APK cũ cần build/cài lại.
Không cần cấu hình Firebase, không bật billing. Chưa build APK/ký phát hành,
deploy web hoặc nghiệm thu Android vật lý. Ảnh chụp từ widget test có fixture
kiểm thử, không phải dữ liệu production.

Đề xuất tiếp theo: nghiệm thu giao diện trên thiết bị khi được yêu cầu;
không tự triển khai giai đoạn kế tiếp.
