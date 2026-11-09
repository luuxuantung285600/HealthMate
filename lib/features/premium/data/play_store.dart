import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

import '../models/play_billing_models.dart';

abstract interface class PlayStore {
  Stream<List<StorePurchase>> get purchases;
  Future<PlayProduct?> load(PlayBillingConfig config);
  Future<bool> buy(PlayBillingConfig config);
  Future<void> restore();
  Future<void> complete(StorePurchase purchase);
}

class GooglePlayStore implements PlayStore {
  GooglePlayStore(this.store);
  final InAppPurchase store;
  GooglePlayProductDetails? _product;
  PlayBillingConfig? _configuration;
  int _loadRevision = 0;
  @override
  Stream<List<StorePurchase>> get purchases => store.purchaseStream.map(
    (rows) => rows
        .map(
          (p) => StorePurchase(
            status: switch (p.status) {
              PurchaseStatus.pending => StorePurchaseStatus.pending,
              PurchaseStatus.purchased => StorePurchaseStatus.purchased,
              PurchaseStatus.restored => StorePurchaseStatus.restored,
              PurchaseStatus.canceled => StorePurchaseStatus.cancelled,
              PurchaseStatus.error => StorePurchaseStatus.error,
            },
            token: p.verificationData.serverVerificationData,
            needsCompletion: p.pendingCompletePurchase,
            handle: p,
          ),
        )
        .toList(),
  );
  @override
  Future<PlayProduct?> load(PlayBillingConfig config) async {
    final revision = ++_loadRevision;
    _product = null;
    _configuration = null;
    if (!await store.isAvailable()) return null;
    final response = await store.queryProductDetails({config.productId});
    if (revision != _loadRevision) return null;
    if (response.error != null) {
      throw StateError('Chưa tải được gói từ Google Play.');
    }
    for (final p
        in response.productDetails.whereType<GooglePlayProductDetails>()) {
      final index = p.subscriptionIndex;
      if (p.id != config.productId || index == null) continue;
      final offer = p.productDetails.subscriptionOfferDetails![index];
      // Initial rollout: one monthly auto-renew base plan, no trial/offer whose
      // multi-phase price would need a different subscription disclosure.
      if (offer.basePlanId == config.basePlanId &&
          offer.offerId == null &&
          offer.installmentPlanDetails == null &&
          offer.pricingPhases.length == 1 &&
          offer.pricingPhases.single.recurrenceMode ==
              RecurrenceMode.infiniteRecurring &&
          offer.pricingPhases.single.billingPeriod == 'P1M') {
        _product = p;
        _configuration = config;
        return PlayProduct(id: p.id, price: p.price);
      }
    }
    return null;
  }

  @override
  Future<bool> buy(PlayBillingConfig config) {
    final product = _product;
    if (product == null ||
        product.id != config.productId ||
        !identical(config, _configuration)) {
      throw StateError('Hãy tải lại gói Google Play.');
    }
    return store.buyNonConsumable(
      purchaseParam: GooglePlayPurchaseParam(
        productDetails: product,
        offerToken: product.offerToken,
        applicationUserName: config.accountId,
      ),
    );
  }

  @override
  Future<void> restore() => store.restorePurchases();
  @override
  Future<void> complete(StorePurchase purchase) =>
      store.completePurchase(purchase.handle as PurchaseDetails);
}
