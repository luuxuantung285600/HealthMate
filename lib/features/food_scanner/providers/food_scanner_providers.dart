import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

import '../../../core/config/ai_access_policy.dart';
import '../../../core/config/app_feature_flags.dart';
import '../models/ai_food_suggestion.dart';
import '../data/food_image_picker.dart';

import '../data/firebase_food_scanner_service.dart';
import '../data/food_scanner_service.dart';
import '../../premium/providers/premium_providers.dart';
import '../../premium/models/premium_models.dart';

final foodImagePickerProvider = Provider<FoodImagePicker>(
  (ref) => DeviceFoodImagePicker(),
);

final foodScannerServiceProvider = Provider<FoodScannerService>(
  (ref) => _CheckedFoodScannerService(
    reserve: () => ref.read(premiumQuotaProvider)(PremiumAiFeature.scan),
    check: () {
      if (!ref.read(appFeatureFlagsProvider).foodScannerEnabled) {
        return const AiAccess(
          allowed: false,
          message: 'Quét món đang tạm tắt trong bản core.',
        );
      }
      return ref.read(aiAccessProvider);
    },
  ),
);

class _CheckedFoodScannerService
    implements FoodScannerService, UnavailablePhotoScanner {
  _CheckedFoodScannerService({required this.check, required this.reserve});
  final AiAccess Function() check;
  final Future<void> Function() reserve;
  FoodScannerService? _delegate;

  @override
  String get photoUnavailableReason =>
      'Phân tích ảnh chưa sẵn sàng. Bạn có thể quét mã vạch hoặc tìm món.';

  @override
  Future<AiFoodSuggestion> analyze({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final access = check();
    if (!access.allowed) throw FoodScannerFailure(access.message);
    if (bytes.isEmpty ||
        bytes.length > FoodScannerConfig.maxImageBytes ||
        !['image/jpeg', 'image/png', 'image/webp'].contains(mimeType)) {
      throw const FoodScannerFailure('Ảnh chưa hợp lệ hoặc quá lớn.');
    }
    try {
      await reserve();
    } on PremiumFailure catch (error) {
      throw FoodScannerFailure(error.message, code: 'demo-quota');
    }
    final current = check();
    if (!current.allowed) throw FoodScannerFailure(current.message);
    return (_delegate ??= FirebaseFoodScannerService()).analyze(
      bytes: bytes,
      mimeType: mimeType,
    );
  }
}
