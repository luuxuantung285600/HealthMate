class PlayBillingConfig {
  const PlayBillingConfig({
    required this.enabled,
    this.productId = '',
    this.basePlanId = '',
    this.accountId = '',
    this.packageName = '',
  });
  final bool enabled;
  final String productId, basePlanId, accountId, packageName;
  Uri get managementUri => Uri.https(
    'play.google.com',
    '/store/account/subscriptions',
    productId.isNotEmpty && packageName.isNotEmpty
        ? {'sku': productId, 'package': packageName}
        : null,
  );
  factory PlayBillingConfig.fromData(Map<String, dynamic> data) {
    if (data['enabled'] == false) {
      return const PlayBillingConfig(enabled: false);
    }
    if (data['enabled'] != true ||
        !['productId', 'basePlanId', 'accountId', 'packageName'].every(
          (key) => data[key] is String && (data[key] as String).isNotEmpty,
        ) ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(data['accountId'] as String)) {
      throw const FormatException('Cấu hình thanh toán chưa hợp lệ.');
    }
    return PlayBillingConfig(
      enabled: true,
      productId: data['productId'],
      basePlanId: data['basePlanId'],
      accountId: data['accountId'],
      packageName: data['packageName'],
    );
  }
}

class PlayProduct {
  const PlayProduct({required this.id, required this.price});
  final String id, price;
}

enum StorePurchaseStatus { pending, purchased, restored, cancelled, error }

class StorePurchase {
  const StorePurchase({
    required this.status,
    this.token = '',
    this.needsCompletion = false,
    this.handle,
  });
  final StorePurchaseStatus status;
  final String token;
  final bool needsCompletion;
  final Object? handle;
}

class VerifiedMembership {
  const VerifiedMembership({
    required this.active,
    required this.expiresAt,
    required this.startedAt,
    required this.environment,
    required this.autoRenewing,
    required this.status,
  });
  final bool active, autoRenewing;
  final DateTime expiresAt, startedAt;
  final String environment, status;
  bool activeAt(DateTime now) =>
      active && !now.isBefore(startedAt) && now.isBefore(expiresAt);

  /// An owned subscription in these states is repaired or resumed in Play,
  /// rather than starting another checkout for the same product.
  bool blocksNewPurchaseAt(DateTime now) =>
      activeAt(now) ||
      const {
        'SUBSCRIPTION_STATE_ON_HOLD',
        'SUBSCRIPTION_STATE_PAUSED',
        'SUBSCRIPTION_STATE_PENDING',
      }.contains(status);
}

class BillingVerification {
  const BillingVerification({
    required this.verified,
    required this.pending,
    this.completionAllowed = false,
    this.active = false,
  });
  final bool verified, pending, completionAllowed, active;
  factory BillingVerification.fromData(Map<String, dynamic> data) {
    if (data['verified'] is! bool ||
        data['pending'] is! bool ||
        data['completionAllowed'] is! bool ||
        data.containsKey('active') && data['active'] is! bool ||
        data['active'] == true &&
            (data['verified'] != true || data['pending'] == true) ||
        data['pending'] == true && data['completionAllowed'] == true) {
      throw const FormatException(
        'Máy chủ chưa xác nhận trạng thái thanh toán.',
      );
    }
    return BillingVerification(
      verified: data['verified'],
      pending: data['pending'],
      completionAllowed: data['completionAllowed'],
      active: data['active'] == true,
    );
  }
}
