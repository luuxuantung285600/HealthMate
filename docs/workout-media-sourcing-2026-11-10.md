# Video hướng dẫn tập luyện — 10/11/2026

## Quyết định và phạm vi

Giai đoạn 11, thay minh họa tự vẽ theo yêu cầu người dùng. Người dùng chọn
**chỉ nguồn miễn phí**. Đã bỏ painter/hoạt họa tự tạo và tích hợp trình phát
YouTube chính thức, mở theo yêu cầu; không mua media, không thêm billing,
API key, backend, collection hoặc thay đổi nhật ký.

Đây là **video phát trực tuyến miễn phí**, không phải thư viện được cấp quyền
tải/đóng gói offline. Không tải MP4/GIF từ YouTube, không tách logo, không
xóa watermark, không che quảng cáo/điều khiển. Các tổ chức nguồn không bảo
trợ hay xác nhận HealthMate. Hướng dẫn chữ tiếng Việt, timer, pause/skip và
luồng ghi nhật ký hiện có không phụ thuộc việc phát video.

## Nguồn đã chọn

Đối chiếu trang video, tên kênh và mô tả/khung hình; xác minh oEmbed chính
thức cho từng ID (13/13, ngày kiểm tra ở trên). Các link đều từ kênh của
đơn vị cung cấp, không ghép bản re-upload của kênh khác.

| Động tác HealthMate | Video nguồn | Đơn vị | Biến thể và lưu ý |
| --- | --- | --- | --- |
| Bước ngang mở tay | [Step Jacks](https://www.youtube.com/watch?v=JHdVMkRBuRA) | DAREBEE | Bước luân phiên, không bật nhảy |
| Tựa tường hạ người | [Quarter wall squat](https://www.youtube.com/watch?v=tloL0ZiDN3g) | Rehab My Patient | Hạ nông; mô tả nguồn cho phép giữ yên hoặc lên xuống. App chỉ dẫn giữ yên |
| Chống đẩy tường | [Wall assisted push-up](https://www.youtube.com/watch?v=IlgO8Sppw0Y) | Nuffield Health | Dừng ở giây 36 sau phần tường; phần ghế ở video gốc không thuộc lượt tập |
| Co gối chéo | [Knee-to-Elbows](https://www.youtube.com/watch?v=ZL9Y-IIedb0) | DAREBEE | Đứng, gối về khuỷu đối diện; nhắc không kéo cổ, không ép chạm gối |
| Squat vừa sức | [How to Do Squats](https://www.youtube.com/watch?v=L61HQqjYFdQ) | Hinge Health | Squat không tạ, hạ vừa sức |
| Chùng chân lùi | [How to Do a Reverse Lunge](https://www.youtube.com/watch?v=6rKA_et3dGk) | Hinge Health | Bước ra sau; app nhắc đổi chân |
| Đi bộ tại chỗ | [How to march on the spot](https://www.youtube.com/watch?v=9wl_AiNhYP0) | Rehab My Patient | Nhịp chậm, nâng gối thấp tùy sức; không yêu cầu tiến triển nâng tay qua đầu |
| Plank chống gối | [How to do a kneeling plank](https://www.youtube.com/watch?v=UOXuHkBfDhU) | Rehab My Patient | Cẳng tay và gối trên thảm |
| Nâng hông | [Hip Bridge](https://www.youtube.com/watch?v=AQOJhgB1O-I) | Nuffield Health | Nằm ngửa, hai chân trên sàn |
| Duỗi tay chân đối bên | [Bird Dog](https://www.youtube.com/watch?v=xEDnlOxeJH4) | Hinge Health | Tư thế tay/gối, duỗi tay và chân đối diện |
| Plank nghiêng trái | [Side plank kneeling](https://www.youtube.com/watch?v=UurF0EhHFLg) | Rehab My Patient | Gối gập; ghi rõ chống cẳng tay TRÁI |
| Plank nghiêng phải | [Side plank kneeling](https://www.youtube.com/watch?v=UurF0EhHFLg) | Rehab My Patient | Cùng video kỹ thuật một bên; ghi rõ chống cẳng tay PHẢI; không lật/sửa video |
| Nhón gót | [Standing Heel Raises](https://www.youtube.com/watch?v=MikhwO7lrLI) | NHS Lanarkshire | Hai chân trên sàn, vịn tường |
| Gập hông đứng | [How to Do a Hip Hinge](https://www.youtube.com/watch?v=2W_gXhut5S8) | Hinge Health | Không tạ, gối chùng, gập tại hông |

Nuffield Health/NHS là các đơn vị y tế tại Anh; Hinge Health cung cấp video
hướng dẫn từ chuyên viên vật lý trị liệu; Rehab My Patient là thư viện bài
tập phục hồi; DAREBEE cung cấp thư viện thể lực. App dùng video để minh họa
động tác, không biến các hướng dẫn phục hồi thành chỉ định điều trị.

## Quyền sử dụng và giới hạn

- Dùng [YouTube embedded player](https://developers.google.com/youtube/iframe_api_reference)
  và tuân thủ [Required Minimum Functionality](https://developers.google.com/youtube/terms/required-minimum-functionality).
  oEmbed có sẵn không phải giấy phép tải hoặc phân phối tệp nguồn.
- Trình phát giữ branding/controls/fullscreen. Cần Internet và có thể có quảng
  cáo; nguồn có thể gỡ video hoặc tắt nhúng về sau. Có thử lại và nút mở video
  gốc; lỗi không chặn đọc hướng dẫn.
- Chiều rộng/chiều cao player ít nhất 200px, giữ toàn bộ hình, không cắt clip.
  Windows/Linux hoặc vùng dưới 200px mở nguồn ngoài, không tạo WebView lỗi.
- Native Referer dùng app ID thật `https://com.example.healthmate` theo tài
  liệu YouTube; web dùng origin thật. Nếu đổi applicationId phải cập nhật
  giá trị này. Không mượn domain của nhà cung cấp để vượt lỗi 153.
- Chỉ tạo player khi người dùng bấm tải, không autoplay, không tạo player
  cho mọi card. Ảnh xem trước lấy từ thumbnail của chính video YouTube.
  Khi tải/phát, YouTube nhận dữ liệu kết nối thông thường; không gửi hồ sơ,
  UID hoặc dữ liệu sức khỏe cho trình phát.
- Native inactive/hidden/paused dừng phát; web hidden dừng nhưng iframe focus
  không bị coi là ra nền. Đóng sheet giải phóng controller/subscription/timer.
- Mở hướng dẫn trong buổi tập luôn pause trước; đóng không tự resume và không
  cộng thời gian xem vào vận động. Người dùng bấm Tiếp tục khi sẵn sàng.

## Triển khai

- `models/workout_tutorial.dart`: manifest và ghi chú biến thể.
- `data/workout_tutorial_player.dart`: adapter SDK, timeout/lỗi, pause/dispose.
- `presentation/movement_media_preview.dart`: thumbnail có fallback.
- `presentation/workout_tutorial_sheet.dart`: nguồn, tải có chủ đích, retry,
  hướng dẫn chữ, mở YouTube gốc.
- `workouts_screen.dart`, `workout_session_screen.dart`: dùng media mới.
- `youtube_player_iframe` 6.0.2 (BSD-3-Clause), kiểm tra tương thích với
  Flutter 3.44.1/Dart 3.12.1; chỉ thêm package cần cho official player.
- `test/workout_tutorial_test.dart`: lazy init, lỗi/retry, dispose/pause, không
  cộng thời gian xem, cỡ chữ lớn/màn hẹp, nền tảng không hỗ trợ.
- `integration_test/workout_video_smoke_test.dart`: opt-in mạng thật Android,
  không truy cập Firebase hoặc dữ liệu khách hàng.

## Kiểm thử và giới hạn nghiệm thu

- Toàn bộ Flutter suite: **1.183/1.183** qua; log
  `build/exercise-video-research/flutter-tests.log`.
- 13/13 video nguồn đã cue thành công bằng WebView thật trên Android AVD
  HealthMateMaintenanceQA, exit 0. Đây là kiểm tra khả năng tải/cue, không
  khẳng định đã xem hết mọi giây trên Android thật.
- Đã phát và tạm dừng video Nuffield Health trong giao diện Flutter web qua
  browser. Ảnh QA: `build/workout-preview/tutorial-web.png`.
- Bản cuối: format 18 file không đổi, analyze không có issue; 43/43 test
  workout/media và 1/1 test route/thông tin quyền riêng tư qua. Android
  opt-in 14/14 qua (13 nguồn duy nhất + 1 ID không hợp lệ), log
  `build/exercise-video-research/android-video-smoke-verified.log`.
- Một lượt Android trung gian thất bại 13/13 do DNS trong AVD không phân giải
  được YouTube; host vẫn HTTP 200. Cold boot AVD với DNS tạm thời ổn định
  đã khắc phục, không đổi VPN/DNS hoặc tắt bảo vệ trên Windows. Log lỗi giữ
  tại `build/exercise-video-research/android-video-smoke-final.log`.
- Browser kiểm tra thêm 390px: player cao 200px, giữ đủ ảnh, có tên nguồn,
  cách tập và nút đóng; ảnh `build/workout-preview/tutorial-mobile.png`.
- Chưa nghiệm thu Android vật lý hoặc ký phát hành. Không cần người dùng
  mở Blaze, đăng ký dịch vụ hay mua media cho phương án này.

## Những nguồn không dùng

Gym Visual bị loại sau lựa chọn miễn phí của người dùng; không đưa preview
có bản quyền vào app. wger chưa đủ đúng biến thể; NHS terms không tự cấp
quyền đóng gói mọi video có người; MuscleWiki API cần gói có phí. Pexels
có giấy phép dùng phù hợp nhưng các clip xem thử không đủ góc quay. DVIDS
có một số clip public domain nhưng quyền khác nhau theo tài sản và tải cần
tài khoản. Không dùng chúng làm lý do để lấy tệp của nguồn khác không phép.

## Bước tiếp theo đề xuất

Nghiệm thu video trên Android thật trong một lượt riêng. Không tự triển khai
đồng bộ catalog bài tập, media offline hoặc thay đổi giai đoạn sản phẩm khác.

Build app cuối `flutter build apk --debug`: exit 0, Gradle 51,2s.
APK: `build/releases/healthmate-workout-videos-20261110-debug.apk`.
Log: `build/exercise-video-research/app-debug-build.log`.
Không dùng APK integration để bàn giao.

## Đính chính yêu cầu — GIF nhân vật 3D, không dùng người thật

Người dùng đã xác nhận muốn hoạt họa lặp kiểu Gym Visual và vẫn chỉ dùng
nguồn miễn phí. Phương án YouTube phía trên và APK tương ứng **không đáp ứng
yêu cầu hình thức này**. Những kết quả kiểm thử phía trên chỉ chứng minh
phương án video cũ hoạt động, không phải nghiệm thu phương án GIF.

Đã kiểm tra trực tiếp các nguồn sau trong lượt đính chính:

- [Exercise Animatic free samples](https://www.exerciseanimatic.com/free-fitness-exercise-videos)
  có mẫu Bodyweight Squat 3D. Tuy nhiên [license](https://www.exerciseanimatic.com/license)
  ghi quyền tích hợp app cho nội dung đã mua; chưa có căn cứ áp dụng quyền
  đó cho các mẫu miễn phí. Chưa đưa nội dung này vào app.
- [LottieFiles: 3D Character Exercises Pose](https://lottiefiles.com/free-animation/3d-character-exercises-pose-7BKufoGgZA)
  ghi Lottie Simple License, nhưng hình là nhân vật hoạt hình làm động tác
  bụng và dẫn nguồn dự án cá nhân Behance của người khác. Không đủ căn cứ
  dùng làm bộ hướng dẫn kỹ thuật 14 động tác.
- [Pixabay: Push Up Exercise, DEZYNE_3D](https://pixabay.com/gifs/push-up-exercise-fitness-gym-21525/)
  là GIF nhân vật 3D, trang tài sản ghi Pixabay Content License. Đã đọc
  [điều khoản mục 5](https://pixabay.com/service/terms/#section-5-content-license):
  cho phép dùng thương mại/phi thương mại và sửa đổi, cấm phân phối tệp
  riêng lẻ như thư viện stock. Đây là mẫu tham khảo hình thức; chống đẩy sàn
  không khớp `wall_push` hiện tại. Không gắn mẫu này vào sai bài tập.

**Trạng thái:** chưa xác minh được bộ GIF miễn phí đồng nhất, đúng biến thể,
đủ 14 động tác. Không mua media, không dùng bản sao Gym Visual chưa rõ
quyền, không sửa chương trình tập để khớp tài sản tìm được. Lượt này chỉ
nghiên cứu và đính chính tài liệu; chưa thay code media hoặc chạy lại test/build.
Bước tiếp theo trong cùng phạm vi: hoàn tất nguồn hoạt họa hợp lệ trước khi
thay player YouTube và nghiệm thu GIF. Không coi giai đoạn này đã hoàn tất.
