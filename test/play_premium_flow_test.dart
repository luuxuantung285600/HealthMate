import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/premium/data/play_billing_repository.dart';
import 'package:healthmate/features/premium/data/play_store.dart';
import 'package:healthmate/features/premium/models/play_billing_models.dart';
import 'package:healthmate/features/premium/presentation/play_premium_screen.dart';
import 'package:healthmate/features/premium/providers/play_billing_controller.dart';
import 'package:healthmate/features/premium/providers/play_billing_providers.dart';
import 'package:healthmate/shared/providers/local_clock_provider.dart';

import 'support/load_icon_font.dart';

final _now = DateTime.utc(2026, 11, 10, 3);
const _config = PlayBillingConfig(
  enabled: true,
  productId: 'premium-fixture',
  basePlanId: 'monthly-fixture',
  packageName: 'com.example.healthmate',
  accountId: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
);
const _verified = BillingVerification(
  verified: true,
  pending: false,
  completionAllowed: true,
  active: true,
);

VerifiedMembership _member(
  String status, {
  bool active = true,
  bool renew = true,
  bool expired = false,
}) => VerifiedMembership(
  active: active,
  autoRenewing: renew,
  status: status,
  environment: 'test',
  startedAt: _now.subtract(const Duration(days: 10)),
  expiresAt: expired
      ? _now.subtract(const Duration(minutes: 1))
      : _now.add(const Duration(days: 20)),
);

class _Repository implements PlayBillingRepository {
  final changes = StreamController<VerifiedMembership?>.broadcast(sync: true);
  bool fail = false;
  BillingVerification result = _verified;
  Completer<BillingVerification>? held;
  VerifiedMembership? member;
  @override
  Future<PlayBillingConfig> prepare() async => _config;
  @override
  Future<BillingVerification> verify(String token) async {
    if (fail) throw StateError('Local verification fixture failure');
    return held?.future ?? result;
  }

  @override
  Stream<VerifiedMembership?> watchMembership(String uid) async* {
    yield member;
    yield* changes.stream;
  }
}

class _Store implements PlayStore {
  final events = StreamController<List<StorePurchase>>.broadcast(sync: true);
  int purchasesStarted = 0, restores = 0, completions = 0;
  StorePurchase? restored;
  @override
  Stream<List<StorePurchase>> get purchases => events.stream;
  @override
  Future<PlayProduct?> load(PlayBillingConfig config) async =>
      const PlayProduct(id: 'premium-fixture', price: '29.000 ₫');
  @override
  Future<bool> buy(PlayBillingConfig config) async {
    purchasesStarted++;
    return true;
  }

  @override
  Future<void> restore() async {
    restores++;
    if (restored case final event?) events.add([event]);
  }

  @override
  Future<void> complete(StorePurchase purchase) async => completions++;
  void emit(StorePurchaseStatus status) => events.add([
    StorePurchase(
      status: status,
      token: 'local-receipt',
      needsCompletion: true,
    ),
  ]);
}

class _Fixture {
  final repo = _Repository();
  final store = _Store();
  late final controller = PlayBillingController(
    repo,
    store,
    isCurrent: () => true,
    now: () => _now,
  );
  Future<void> dispose() async {
    controller.dispose();
    await store.events.close();
    await repo.changes.close();
  }
}

Future<void> _flush() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Fixture fixture, {
  bool disabled = false,
  bool dark = false,
  double width = 390,
  double scale = 1,
  Future<bool> Function(Uri)? open,
  Stream<VerifiedMembership?>? membership,
  GlobalKey? captureKey,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await fixture.controller.start();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playBillingEnabledProvider.overrideWithValue(!disabled),
        playBillingControllerProvider.overrideWithValue(
          disabled ? null : fixture.controller,
        ),
        verifiedMembershipProvider.overrideWith(
          (ref) => membership ?? fixture.repo.watchMembership('fixture-user'),
        ),
        currentLocalTimeProvider.overrideWithValue(() => _now),
        openPlaySubscriptionsProvider.overrideWithValue(
          open ?? (_) async => true,
        ),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: RepaintBoundary(key: captureKey, child: child!),
        ),
        home: const PlayPremiumScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await fixture.dispose();
  });
}

Future<void> _show(WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(find.byKey(ValueKey(key)), 250);
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadIconFont();
    final font = FontLoader('Public Sans');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(
        rootBundle.load('assets/fonts/public_sans/PublicSans-$weight.ttf'),
      );
    }
    await font.load();
  });

  test(
    'verification failure blocks repurchase until the receipt is recovered',
    () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      f.repo.fail = true;
      await f.controller.start();
      expect(f.controller.message, isNull);
      f.store.emit(StorePurchaseStatus.purchased);
      await _flush();
      expect(f.controller.needsRecovery, isTrue);
      expect(f.controller.canBuy, isFalse);
      expect(f.controller.canRestore, isTrue);
      await f.controller.buy();
      await f.controller.restore();
      expect(f.store.purchasesStarted, 0);
      expect(f.controller.needsRecovery, isTrue);
      f.repo.fail = false;
      f.store.restored = const StorePurchase(
        status: StorePurchaseStatus.restored,
        token: 'local-receipt',
        needsCompletion: true,
      );
      await f.controller.restore();
      expect(f.store.completions, 1);
      expect(f.controller.needsRecovery, isFalse);
      expect(f.controller.awaitingActivation, isTrue);
      expect(f.controller.canBuy, isFalse);
      f.controller.acceptMembership(_member('SUBSCRIPTION_STATE_ACTIVE'));
      expect(f.controller.awaitingActivation, isFalse);
      expect(f.controller.canBuy, isFalse);
      f.controller.acceptMembership(
        _member('SUBSCRIPTION_STATE_EXPIRED', active: false, expired: true),
      );
      expect(f.controller.canBuy, isTrue);
    },
  );

  test(
    'server pending cancellation permits a new checkout without granting access',
    () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      f.repo.result = const BillingVerification(verified: true, pending: true);
      await f.controller.start();
      f.store.emit(StorePurchaseStatus.purchased);
      await _flush();
      expect(f.controller.pending, isTrue);
      expect(f.controller.canBuy, isFalse);
      f.store.emit(StorePurchaseStatus.cancelled);
      await _flush();
      expect(f.controller.needsRecovery, isFalse);
      expect(f.controller.canBuy, isTrue);
      expect(f.store.completions, 0);
    },
  );

  test(
    'resume recovers a lost checkout callback and skips in-flight verification',
    () async {
      final f = _Fixture();
      addTearDown(f.dispose);
      await f.controller.start();
      await f.controller.buy();
      expect(f.controller.openingCheckout, isTrue);
      await f.controller.onResume();
      expect(f.controller.openingCheckout, isFalse);
      expect(f.store.restores, 2);
      f.repo.held = Completer<BillingVerification>();
      f.store.emit(StorePurchaseStatus.purchased);
      await _flush();
      await f.controller.onResume();
      expect(f.store.restores, 2);
      f.repo.held!.complete(_verified);
      await _flush();
    },
  );

  test('management URL targets the actual package and subscription', () {
    expect(_config.managementUri.host, 'play.google.com');
    expect(_config.managementUri.queryParameters, {
      'sku': 'premium-fixture',
      'package': 'com.example.healthmate',
    });
    expect(
      const PlayBillingConfig(enabled: false).managementUri.query,
      isEmpty,
    );
  });

  testWidgets(
    'checkout and verification never substitute for the membership stream',
    (tester) async {
      final f = _Fixture();
      await _pump(tester, f);
      expect(find.text('29.000 ₫ / tháng'), findsOneWidget);
      await _show(tester, 'buy-play-premium');
      await tester.tap(find.byKey(const ValueKey('buy-play-premium')));
      await tester.pump();
      expect(f.store.purchasesStarted, 1);
      f.store.emit(StorePurchaseStatus.pending);
      await tester.pumpAndSettle();
      expect(f.store.completions, 0);
      f.repo.held = Completer<BillingVerification>();
      f.store.emit(StorePurchaseStatus.purchased);
      await tester.pump();
      expect(f.controller.verifying, isTrue);
      expect(find.text('Premium đang hoạt động'), findsNothing);
      f.repo.held!.complete(_verified);
      await tester.pumpAndSettle();
      expect(f.store.completions, 1);
      expect(f.controller.canBuy, isFalse);
      expect(find.text('Premium đang hoạt động'), findsNothing);
      final member = _member('SUBSCRIPTION_STATE_ACTIVE');
      f.repo.changes.add(member);
      f.controller.acceptMembership(member);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 1800));
      await tester.pumpAndSettle();
      expect(find.text('Premium đang hoạt động'), findsOneWidget);
    },
  );

  for (final entry in [
    (
      'SUBSCRIPTION_STATE_CANCELED',
      true,
      false,
      false,
      'Đã tắt gia hạn, vẫn dùng đến hết hạn',
    ),
    (
      'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
      true,
      true,
      false,
      'Cần cập nhật thanh toán gia hạn',
    ),
    (
      'SUBSCRIPTION_STATE_ON_HOLD',
      false,
      true,
      false,
      'Gói tạm ngưng do thanh toán',
    ),
    (
      'SUBSCRIPTION_STATE_PAUSED',
      false,
      true,
      false,
      'Gói đăng ký đang tạm dừng',
    ),
    (
      'SUBSCRIPTION_STATE_PENDING',
      false,
      false,
      false,
      'Thanh toán đang chờ Google Play',
    ),
    (
      'SUBSCRIPTION_STATE_EXPIRED',
      false,
      false,
      true,
      'Gói Premium đã hết hiệu lực',
    ),
  ]) {
    testWidgets(
      'membership ${entry.$1} has truthful status and checkout availability',
      (tester) async {
        final f = _Fixture();
        f.repo.member = _member(
          entry.$1,
          active: entry.$2,
          renew: entry.$3,
          expired: entry.$4,
        );
        await _pump(tester, f);
        await _show(tester, 'verified-premium-status');
        expect(find.text(entry.$5), findsOneWidget);
        await _show(tester, 'buy-play-premium');
        final buy = tester.widget<FilledButton>(
          find.byKey(const ValueKey('buy-play-premium')),
        );
        expect(buy.onPressed != null, entry.$4);
      },
    );
  }

  testWidgets(
    'management opens the scoped Play page and failure has a usable fallback',
    (tester) async {
      final opened = <Uri>[];
      await _pump(
        tester,
        _Fixture(),
        open: (uri) async {
          opened.add(uri);
          throw StateError('Local link fixture');
        },
      );
      await _show(tester, 'manage-play-subscription');
      await tester.tap(find.byKey(const ValueKey('manage-play-subscription')));
      await tester.pumpAndSettle();
      expect(opened.single, _config.managementUri);
      expect(find.textContaining('Mở Play Store'), findsOneWidget);
    },
  );

  testWidgets(
    'a failed receipt exposes recovery and cannot open another checkout',
    (tester) async {
      final f = _Fixture();
      f.repo.fail = true;
      await _pump(tester, f);
      f.store.emit(StorePurchaseStatus.purchased);
      await tester.pumpAndSettle();
      await _show(tester, 'buy-play-premium');
      expect(find.text('Cần khôi phục giao dịch'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('buy-play-premium')),
            )
            .onPressed,
        isNull,
      );
      await _show(tester, 'restore-play-premium');
      await tester.tap(find.byKey(const ValueKey('restore-play-premium')));
      await tester.pumpAndSettle();
      expect(f.store.purchasesStarted, 0);
      expect(f.controller.needsRecovery, isTrue);
    },
  );

  testWidgets(
    'privacy is accessible without abandoning the subscription screen',
    (tester) async {
      await _pump(tester, _Fixture());
      await _show(tester, 'premium-privacy');
      await tester.tap(find.byKey(const ValueKey('premium-privacy')));
      await tester.pumpAndSettle();
      expect(find.text('Dữ liệu tài khoản'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(PlayPremiumScreen), findsOneWidget);
    },
  );

  testWidgets(
    'unavailable billing shows useful information without a price or checkout',
    (tester) async {
      await _pump(tester, _Fixture(), disabled: true);
      expect(find.textContaining('Premium chưa mở bán'), findsOneWidget);
      expect(find.textContaining('29.000'), findsNothing);
      await _show(tester, 'buy-play-premium');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('buy-play-premium')),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'membership read failure blocks a new charge until a successful retry',
    (tester) async {
      final f = _Fixture();
      var reads = 0;
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await f.controller.start();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playBillingControllerProvider.overrideWithValue(f.controller),
            verifiedMembershipProvider.overrideWith(
              (ref) => ++reads == 1
                  ? Stream.error(StateError('Local membership fixture'))
                  : Stream.value(null),
            ),
          ],
          child: const MaterialApp(home: PlayPremiumScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await _show(tester, 'buy-play-premium');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('buy-play-premium')),
            )
            .onPressed,
        isNull,
      );
      await _show(tester, 'retry-premium-membership');
      await tester.tap(find.byKey(const ValueKey('retry-premium-membership')));
      await tester.pumpAndSettle();
      await _show(tester, 'buy-play-premium');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('buy-play-premium')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await f.dispose();
    },
  );

  testWidgets(
    'session lifecycle listener restores on resume and stops after signout',
    (tester) async {
      final repo = _Repository(), store = _Store();
      final auth = StreamController<AuthUser?>.broadcast(sync: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playBillingEnabledProvider.overrideWithValue(true),
            playBillingSupportedProvider.overrideWithValue(true),
            playBillingRepositoryProvider.overrideWithValue(repo),
            playStoreProvider.overrideWithValue(store),
            currentLocalTimeProvider.overrideWithValue(() => _now),
            authSessionProvider.overrideWith((ref) => auth.stream),
          ],
          child: const MaterialApp(home: PlayPremiumScreen()),
        ),
      );
      auth.add(
        const AuthUser(
          uid: 'fixture-owner',
          email: 'owner@example.test',
          emailVerified: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(store.restores, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(store.restores, 2);
      store.emit(StorePurchaseStatus.purchased);
      await tester.pumpAndSettle();
      expect(store.completions, 1);
      expect(find.text('Premium đang hoạt động'), findsNothing);
      repo.changes.add(_member('SUBSCRIPTION_STATE_ACTIVE'));
      await tester.pumpAndSettle();
      expect(find.text('Premium đang hoạt động'), findsOneWidget);
      auth.add(null);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(store.restores, 2);
      store.emit(StorePurchaseStatus.purchased);
      await tester.pumpAndSettle();
      expect(store.completions, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await auth.close();
      await store.events.close();
      await repo.changes.close();
    },
  );

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('subscription flow fits 320px, scale $scale, dark $dark', (
        tester,
      ) async {
        final key = GlobalKey();
        await _pump(
          tester,
          _Fixture(),
          dark: dark,
          width: 320,
          scale: scale,
          captureKey: key,
        );
        if (scale == 1) {
          await tester.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              'build/premium-flow/ready-${dark ? 'dark' : 'light'}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await _show(tester, 'buy-play-premium');
        await _show(tester, 'premium-privacy');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
