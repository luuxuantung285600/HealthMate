import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/food_photo_provider.dart';
import '../models/food_photo.dart';

class FoodPhotoThumbnail extends ConsumerWidget {
  const FoodPhotoThumbnail({
    required this.foodId,
    required this.foodName,
    this.size = 72,
    this.onTap,
    super.key,
  });

  final String foodId, foodName;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = ref.watch(foodPhotoProvider((foodId, foodName)));
    if (photo == null) return const SizedBox.shrink();
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Semantics(
          button: true,
          label: onTap != null
              ? 'Xem chi tiết món $foodName'
              : 'Xem ảnh minh họa $foodName',
          child: Tooltip(
            message: onTap != null
                ? 'Xem chi tiết món'
                : 'Ảnh minh họa · Chạm để xem ảnh',
            child: InkWell(
              key: ValueKey('food-photo-$foodId'),
              onTap: onTap ?? () => showFoodPhotoDetails(context, photo),
              child: ExcludeSemantics(
                child: FoodPhotoImage(
                  photo: photo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(
                    child: Text(
                      'Ảnh chưa khả dụng',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showFoodPhotoDetails(BuildContext context, FoodPhoto photo) =>
    showDialog<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(
            foodPhotoProvider((photo.foodId, photo.foodName)),
          );
          if (current == null) {
            return AlertDialog(
              title: Text(photo.foodName),
              content: const Text('Ảnh món này đã được gỡ hoặc thay đổi.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            );
          }
          return _photoDetails(context, current);
        },
      ),
    );

Widget _photoDetails(BuildContext context, FoodPhoto photo) => AlertDialog(
  title: Text(photo.foodName),
  content: SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FoodPhotoImage(
            photo: photo,
            height: 220,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox(
              height: 100,
              child: Center(child: Text('Chưa hiển thị được ảnh.')),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Ảnh minh họa; cách chế biến và khẩu phần thực tế có thể khác. '
          'Dinh dưỡng được tính từ dữ liệu món và lượng bạn nhập.',
        ),
        if (photo.author.isNotEmpty || photo.license.isNotEmpty) ...[
          const SizedBox(height: 12),
          SelectableText(
            [
              if (photo.title.isNotEmpty) 'Ảnh: ${photo.title}',
              if (photo.author.isNotEmpty) 'Tác giả: ${photo.author}',
            ].join('\n'),
          ),
          if (photo.license.isNotEmpty)
            Text(
              'Giấy phép: ${photo.license}.${photo.imageUrl == null ? ' Đã cắt khung và thu nhỏ ảnh.' : ''}',
            ),
        ],
        if (photo.sourceUrl.isNotEmpty || photo.licenseUrl.isNotEmpty)
          Wrap(
            spacing: 8,
            children: [
              if (photo.sourceUrl.isNotEmpty)
                TextButton(
                  onPressed: () => _openSource(context, photo.sourceUrl),
                  child: const Text('Trang ảnh gốc'),
                ),
              if (photo.licenseUrl.isNotEmpty)
                TextButton(
                  onPressed: () => _openSource(context, photo.licenseUrl),
                  child: const Text('Xem giấy phép'),
                ),
            ],
          ),
      ],
    ),
  ),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Đóng'),
    ),
  ],
);

Future<void> _openSource(BuildContext context, String value) async {
  var opened = false;
  try {
    opened = await launchUrl(Uri.parse(value));
  } catch (_) {
    // The local photo remains usable when a browser or Internet is unavailable.
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Chưa mở được liên kết nguồn ảnh.')),
    );
  }
}

/// Both image sources share loading/error behavior and never affect nutrients.
class FoodPhotoImage extends StatelessWidget {
  const FoodPhotoImage({
    required this.photo,
    this.height,
    this.fit = BoxFit.cover,
    required this.errorBuilder,
    super.key,
  });
  final FoodPhoto photo;
  final double? height;
  final BoxFit fit;
  final ImageErrorWidgetBuilder errorBuilder;
  @override
  Widget build(BuildContext context) => photo.imageUrl != null
      ? Image.network(
          photo.imageUrl!,
          key: ValueKey(photo.imageUrl),
          height: height,
          fit: fit,
          cacheWidth: 512,
          // Admin image hosts may allow <img> while withholding CORS headers.
          // The web image element can display those public URLs directly.
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: errorBuilder,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: Text('Đang tải ảnh…')),
        )
      : Image.asset(
          photo.assetPath,
          height: height,
          fit: fit,
          cacheWidth: 512,
          errorBuilder: errorBuilder,
        );
}
