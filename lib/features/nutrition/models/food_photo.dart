/// Public illustrative catalog media; never a user's meal photo or a source of
/// nutrition values. Attribution and image licenses apply to the image only.
class FoodPhoto {
  const FoodPhoto({
    required this.foodId,
    required this.foodName,
    this.assetPath = '',
    this.imageUrl,
    required this.title,
    required this.author,
    required this.sourceUrl,
    required this.license,
    required this.licenseUrl,
  });

  final String foodId, foodName, assetPath, title, author;
  final String sourceUrl, license, licenseUrl;
  final String? imageUrl;
}

/// Admin overrides require a public HTTPS image URL. Existing credits remain
/// available when supplied; a missing credit is never inferred or invented.
FoodPhoto? readCatalogPhoto(String id, String name, Object? value) {
  if (value is! Map || value['mode'] != 'custom') return null;
  String? text(String key, int max) {
    final raw = value[key];
    return raw is String && raw.trim().isNotEmpty && raw.length <= max
        ? raw.trim()
        : null;
  }

  final url = text('url', 1000);
  if (!isPublicPhotoUrl(url)) return null;
  final source = text('sourceUrl', 500);
  final licenseUrl = text('licenseUrl', 500);
  return FoodPhoto(
    foodId: id,
    foodName: name,
    imageUrl: url,
    title: text('title', 200) ?? name,
    author: text('author', 120) ?? '',
    sourceUrl: isPublicPhotoUrl(source) ? source! : '',
    license: text('license', 80) ?? '',
    licenseUrl: isPublicPhotoUrl(licenseUrl) ? licenseUrl! : '',
  );
}

bool isPublicPhotoUrl(String? value) {
  if (value == null || RegExp(r'\s').hasMatch(value)) return false;
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9.-]*$').hasMatch(uri.host);
}
