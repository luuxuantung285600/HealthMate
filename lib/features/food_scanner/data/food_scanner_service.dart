import 'dart:typed_data';

import '../models/ai_food_suggestion.dart';

abstract interface class FoodScannerService {
  Future<AiFoodSuggestion> analyze({
    required Uint8List bytes,
    required String mimeType,
  });
}

/// A service can disclose a known deployment blocker before camera permission,
/// image selection or processing consent. Independent from barcode lookup.
abstract interface class UnavailablePhotoScanner {
  String get photoUnavailableReason;
}

extension PhotoScannerAvailability on FoodScannerService {
  String? get photoUnavailableReason => switch (this) {
    UnavailablePhotoScanner service => service.photoUnavailableReason,
    _ => null,
  };
}

class FoodScannerFailure implements Exception {
  const FoodScannerFailure(this.message, {this.code = 'unknown'});

  final String message;
  final String code;

  @override
  String toString() => message;
}
