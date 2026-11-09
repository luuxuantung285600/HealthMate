import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'package:healthmate/features/premium/data/play_store.dart';
import 'package:healthmate/features/premium/models/play_billing_models.dart';

class PurchaseClient implements InAppPurchase {
  final queries = <Completer<ProductDetailsResponse>>[];
  PurchaseParam? lastPurchase;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) {
    final result = Completer<ProductDetailsResponse>();
    queries.add(result);
    return result.future;
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    lastPurchase = purchaseParam;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PlayBillingConfig configuration(String account) => PlayBillingConfig(
  enabled: true,
  productId: 'premium',
  basePlanId: 'monthly',
  accountId: account,
  packageName: 'com.example.healthmate',
);

ProductDetailsResponse response({String? offerId, String period = 'P1M'}) =>
    ProductDetailsResponse(
      productDetails: GooglePlayProductDetails.fromProductDetails(
        ProductDetailsWrapper(
          description: 'Premium test fixture',
          name: 'Premium',
          title: 'Premium',
          productId: 'premium',
          productType: ProductType.subs,
          subscriptionOfferDetails: [
            SubscriptionOfferDetailsWrapper(
              basePlanId: 'monthly',
              offerId: offerId,
              offerTags: [],
              offerIdToken: 'offer-fixture',
              pricingPhases: [
                PricingPhaseWrapper(
                  billingCycleCount: 0,
                  billingPeriod: period,
                  formattedPrice: '29.000 ₫',
                  priceAmountMicros: 29000000000,
                  priceCurrencyCode: 'VND',
                  recurrenceMode: RecurrenceMode.infiniteRecurring,
                ),
              ],
            ),
          ],
        ),
      ),
      notFoundIDs: [],
    );

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'out-of-order product responses cannot switch checkout to a previous account',
    () async {
      final client = PurchaseClient(),
          store = GooglePlayStore(PurchaseClient());
      // Share one adapter across both account lifetimes, as the app provider does.
      final shared = GooglePlayStore(client);
      final alice = configuration('alice'), bob = configuration('bob');
      final older = shared.load(alice);
      await flush();
      final newer = shared.load(bob);
      await flush();
      client.queries[1].complete(response());
      expect((await newer)?.price, '29.000 ₫');
      client.queries[0].complete(response());
      expect(await older, isNull);
      expect(() => shared.buy(alice), throwsStateError);
      expect(() => shared.buy(configuration('bob')), throwsStateError);
      await shared.buy(bob);
      expect(client.lastPurchase?.applicationUserName, 'bob');
      expect(
        (client.lastPurchase as GooglePlayPurchaseParam).offerToken,
        'offer-fixture',
      );
      expect(() => store.buy(alice), throwsStateError);
    },
  );

  test(
    'unsupported offer and billing period expose no misleading monthly checkout',
    () async {
      for (final product in [
        response(offerId: 'trial'),
        response(period: 'P1Y'),
      ]) {
        final client = PurchaseClient(), config = configuration('alice');
        final store = GooglePlayStore(client);
        final loading = store.load(config);
        await flush();
        client.queries.single.complete(product);
        expect(await loading, isNull);
        expect(() => store.buy(config), throwsStateError);
        expect(client.lastPurchase, isNull);
      }
    },
  );
}
