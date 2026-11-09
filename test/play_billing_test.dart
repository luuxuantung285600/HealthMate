import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/premium/data/play_billing_repository.dart';
import 'package:healthmate/features/premium/data/play_store.dart';
import 'package:healthmate/features/premium/models/play_billing_models.dart';
import 'package:healthmate/features/premium/presentation/play_premium_screen.dart';
import 'package:healthmate/features/premium/providers/play_billing_controller.dart';
import 'package:healthmate/features/premium/providers/play_billing_providers.dart';

const config = PlayBillingConfig(
  enabled: true,
  productId: 'premium',
  basePlanId: 'monthly',
  accountId: 'hashed-user',
  packageName: 'com.example.healthmate',
);

class Repository implements PlayBillingRepository {
  PlayBillingConfig configuration = config;
  int verifications = 0;
  int preparations = 0;
  bool fail = false, pending = false, completionAllowed = true;
  Completer<PlayBillingConfig>? preparing;
  Completer<BillingVerification>? held;
  @override
  Future<PlayBillingConfig> prepare() async {
    preparations++;
    return preparing?.future ?? configuration;
  }

  @override
  Future<BillingVerification> verify(String token) async {
    verifications++;
    if (fail) throw StateError('receipt rejected');
    return held?.future ??
        BillingVerification(
          verified: true,
          pending: pending,
          completionAllowed: !pending && completionAllowed,
        );
  }

  @override
  Stream<VerifiedMembership?> watchMembership(String uid) => Stream.value(null);
}

class Store implements PlayStore {
  final events = StreamController<List<StorePurchase>>.broadcast(sync: true);
  int completions = 0, purchasesStarted = 0, restores = 0, loads = 0;
  bool available = true;
  Completer<void>? restoring;
  Completer<PlayProduct?>? loading;
  @override
  Stream<List<StorePurchase>> get purchases => events.stream;
  @override
  Future<PlayProduct?> load(PlayBillingConfig config) async {
    loads++;
    return loading?.future ??
        (available
            ? const PlayProduct(id: 'premium', price: '29.000 ₫')
            : null);
  }

  @override
  Future<bool> buy(PlayBillingConfig config) async {
    purchasesStarted++;
    return true;
  }

  @override
  Future<void> restore() async {
    restores++;
    await restoring?.future;
  }

  @override
  Future<void> complete(StorePurchase purchase) async {
    completions++;
  }

  void emit(StorePurchaseStatus status, {String token = 'test-receipt'}) =>
      events.add([
        StorePurchase(status: status, token: token, needsCompletion: true),
      ]);
}

Future<void> settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test(
    'verification response requires explicit consistent completion permission',
    () {
      for (final data in <Map<String, dynamic>>[
        {'verified': true, 'pending': false},
        {'verified': true, 'pending': false, 'completionAllowed': 'true'},
        {'verified': true, 'pending': true, 'completionAllowed': true},
      ]) {
        expect(() => BillingVerification.fromData(data), throwsFormatException);
      }
      expect(
        BillingVerification.fromData({
          'verified': true,
          'pending': false,
          'completionAllowed': false,
        }).completionAllowed,
        isFalse,
      );
    },
  );
  test(
    'start and concurrent reload share one preparation and one listener',
    () async {
      final repo = Repository()..preparing = Completer<PlayBillingConfig>();
      final store = Store();
      final controller = PlayBillingController(
        repo,
        store,
        isCurrent: () => true,
      );
      final first = controller.start(), second = controller.start();
      expect(identical(first, second), isTrue);
      final load1 = controller.reload(), load2 = controller.reload();
      expect(identical(load1, load2), isTrue);
      expect(repo.preparations, 1);
      await controller.buy();
      expect(store.purchasesStarted, 0);
      repo.preparing!.complete(config);
      await Future.wait([first, second, load1, load2]);
      expect(store.loads, 1);
      store.emit(StorePurchaseStatus.purchased);
      await settle();
      expect(repo.verifications, 1);
      expect(store.completions, 1);
      controller.dispose();
      await store.events.close();
    },
  );
  test(
    'restore blocks checkout, reload and overlapping restore until finished',
    () async {
      final repo = Repository(), store = Store();
      final controller = PlayBillingController(
        repo,
        store,
        isCurrent: () => true,
      );
      await controller.start();
      store.restoring = Completer<void>();
      final restore = controller.restore();
      await settle();
      expect(controller.busy, isTrue);
      expect(controller.canRestore, isFalse);
      await controller.buy();
      await controller.reload();
      await controller.restore();
      expect(store.purchasesStarted, 0);
      expect(repo.preparations, 1);
      expect(store.restores, 2);
      store.restoring!.complete();
      await restore;
      expect(controller.busy, isFalse);
      expect(controller.canRestore, isTrue);
      controller.dispose();
      await store.events.close();
    },
  );
  test(
    'known pending survives an empty restore and clears on terminal event',
    () async {
      final repo = Repository(), store = Store();
      final controller = PlayBillingController(
        repo,
        store,
        isCurrent: () => true,
      );
      await controller.start();
      store.emit(StorePurchaseStatus.pending, token: '');
      await settle();
      await controller.restore();
      await controller.buy();
      expect(controller.busy, isTrue);
      expect(store.purchasesStarted, 0);
      expect(controller.message, contains('Chưa cấp Premium'));
      store.emit(StorePurchaseStatus.cancelled);
      await settle();
      expect(controller.busy, isFalse);
      expect(store.completions, 0);
      controller.dispose();
      await store.events.close();
    },
  );
  test(
    'duplicate in-flight callbacks share verification; later renewal can reverify',
    () async {
      final repo = Repository()..held = Completer<BillingVerification>();
      final store = Store();
      final controller = PlayBillingController(
        repo,
        store,
        isCurrent: () => true,
      );
      await controller.start();
      store.emit(StorePurchaseStatus.purchased);
      store.emit(StorePurchaseStatus.restored);
      await controller.buy();
      expect(store.purchasesStarted, 0);
      await settle();
      expect(repo.verifications, 1);
      expect(store.completions, 0);
      repo.held!.complete(
        const BillingVerification(
          verified: true,
          pending: false,
          completionAllowed: true,
        ),
      );
      await settle();
      expect(store.completions, 1);
      repo.held = null;
      store.emit(StorePurchaseStatus.restored);
      await settle();
      expect(repo.verifications, 2);
      expect(store.completions, 2);
      controller.dispose();
      await store.events.close();
    },
  );
  test(
    'late timed-out verification cannot complete; later restore recovers without buying',
    () async {
      final repo = Repository()..held = Completer<BillingVerification>();
      final store = Store();
      final controller = PlayBillingController(
        repo,
        store,
        isCurrent: () => true,
        verificationTimeout: const Duration(milliseconds: 20),
      );
      await controller.start();
      store.emit(StorePurchaseStatus.purchased);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(controller.busy, isFalse);
      expect(controller.message, contains('không cần mua lại'));
      repo.held!.complete(
        const BillingVerification(
          verified: true,
          pending: false,
          completionAllowed: true,
        ),
      );
      await settle();
      expect(store.completions, 0);
      repo.held = null;
      store.emit(StorePurchaseStatus.restored);
      await settle();
      expect(store.completions, 1);
      expect(store.purchasesStarted, 0);
      controller.dispose();
      await store.events.close();
    },
  );
  test(
    'server denies client completion for an unacknowledged expired purchase',
    () async {
      final repo = Repository()..completionAllowed = false;
      final store = Store();
      final controller = PlayBillingController(
        repo,
        store,
        isCurrent: () => true,
      );
      await controller.start();
      store.emit(StorePurchaseStatus.purchased);
      await settle();
      expect(store.completions, 0);
      expect(controller.busy, isFalse);
      expect(controller.message, contains('chưa đủ điều kiện'));
      controller.dispose();
      await store.events.close();
    },
  );
  test(
    'product load finishing after signout cannot publish a purchasable product',
    () async {
      var current = true;
      final repo = Repository(),
          store = Store()..loading = Completer<PlayProduct?>();
      final controller = PlayBillingController(
        repo,
        store,
        isCurrent: () => current,
      );
      final startup = controller.start();
      await settle();
      current = false;
      store.loading!.complete(
        const PlayProduct(id: 'premium', price: '29.000 ₫'),
      );
      await startup;
      await controller.buy();
      expect(controller.product, isNull);
      expect(store.purchasesStarted, 0);
      controller.dispose();
      await store.events.close();
    },
  );
  test(
    'disabled backend exposes no purchasable product and never opens checkout',
    () async {
      final repo = Repository()
        ..configuration = const PlayBillingConfig(enabled: false);
      final store = Store();
      final controller = PlayBillingController(
        repo,
        store,
        isCurrent: () => true,
      );
      await controller.start();
      await controller.buy();
      expect(controller.product, isNull);
      expect(store.purchasesStarted, 0);
      expect(store.restores, 0);
      controller.dispose();
      await store.events.close();
    },
  );
  test(
    'pending and cancellation never verify or complete; buy guarded against double tap',
    () async {
      final repo = Repository(), store = Store();
      final controller = PlayBillingController(
        repo,
        store,
        isCurrent: () => true,
      );
      await controller.start();
      await controller.buy();
      await controller.buy();
      expect(store.purchasesStarted, 1);
      store.emit(StorePurchaseStatus.pending);
      await settle();
      expect(controller.busy, isTrue);
      expect(repo.verifications, 0);
      store.emit(StorePurchaseStatus.cancelled);
      await settle();
      expect(controller.busy, isFalse);
      expect(store.completions, 0);
      controller.dispose();
      await store.events.close();
    },
  );
  test(
    'server verification precedes completion and failure is recoverable without repurchase',
    () async {
      final repo = Repository()..fail = true;
      final store = Store();
      final controller = PlayBillingController(
        repo,
        store,
        isCurrent: () => true,
      );
      await controller.start();
      store.emit(StorePurchaseStatus.purchased);
      await settle();
      expect(store.completions, 0);
      expect(controller.message, contains('không cần mua lại'));
      repo.fail = false;
      store.emit(StorePurchaseStatus.restored);
      await settle();
      expect(store.completions, 1);
      expect(repo.verifications, 2);
      expect(store.purchasesStarted, 0);
      controller.dispose();
      await store.events.close();
    },
  );
  test('server pending does not complete purchase', () async {
    final repo = Repository()..pending = true;
    final store = Store();
    final controller = PlayBillingController(
      repo,
      store,
      isCurrent: () => true,
    );
    await controller.start();
    store.emit(StorePurchaseStatus.purchased);
    await settle();
    expect(store.completions, 0);
    controller.dispose();
    await store.events.close();
  });
  test(
    'signout during verification never completes receipt in next account or publishes success',
    () async {
      var current = true;
      final repo = Repository()..held = Completer<BillingVerification>();
      final store = Store();
      final controller = PlayBillingController(
        repo,
        store,
        isCurrent: () => current,
      );
      await controller.start();
      store.emit(StorePurchaseStatus.purchased);
      await settle();
      current = false;
      repo.held!.complete(
        const BillingVerification(
          verified: true,
          pending: false,
          completionAllowed: true,
        ),
      );
      await settle();
      expect(store.completions, 0);
      controller.dispose();
      await store.events.close();
    },
  );
  test(
    'membership expiry independently removes access even before listener notification',
    () {
      final now = DateTime.utc(2026, 11, 7);
      final membership = VerifiedMembership(
        active: true,
        expiresAt: now,
        startedAt: now.subtract(const Duration(days: 30)),
        environment: 'production',
        autoRenewing: false,
        status: 'SUBSCRIPTION_STATE_CANCELED',
      );
      expect(membership.activeAt(now), isFalse);
      expect(
        membership.activeAt(now.subtract(const Duration(seconds: 1))),
        isTrue,
      );
    },
  );
  testWidgets('not ready screen has no invented price or enabled checkout', (
    tester,
  ) async {
    final repo = Repository()
      ..configuration = const PlayBillingConfig(enabled: false);
    final store = Store();
    final controller = PlayBillingController(
      repo,
      store,
      isCurrent: () => true,
    );
    await controller.start();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playBillingControllerProvider.overrideWithValue(controller),
          verifiedMembershipProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(home: PlayPremiumScreen()),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Premium chưa mở bán'), findsOneWidget);
    expect(find.textContaining('20.000'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('buy-play-premium')))
          .onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await store.events.close();
  });
  testWidgets(
    'store price shown and restore exists when Google product is available',
    (tester) async {
      final repo = Repository();
      final store = Store();
      final controller = PlayBillingController(
        repo,
        store,
        isCurrent: () => true,
      );
      await controller.start();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playBillingControllerProvider.overrideWithValue(controller),
            verifiedMembershipProvider.overrideWith(
              (ref) => Stream.value(null),
            ),
          ],
          child: const MaterialApp(home: PlayPremiumScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('29.000 ₫ / tháng'), findsOneWidget);
      expect(find.text('Khôi phục giao dịch'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('buy-play-premium')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await store.events.close();
    },
  );
}
