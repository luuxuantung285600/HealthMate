import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/auth/models/auth_failure.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/models/auth_validation.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/auth/providers/email_verification_provider.dart';
import 'support/test_app.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_account_data_repository.dart';

const unverified = AuthUser(
  uid: 'test-uid',
  email: 'member@example.com',
  emailVerified: false,
);
const googleUser = AuthUser(
  uid: 'test-uid',
  email: 'member@example.com',
  emailVerified: true,
  providerIds: ['google.com'],
);
Future<void> tap(WidgetTester t, String key) async {
  final f = find.byKey(ValueKey(key));
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> captureAuth(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  if (!const bool.fromEnvironment('HEALTHMATE_CAPTURE_AUTH')) return;
  await tester.runAsync(() async {
    final image =
        await (key.currentContext!.findRenderObject() as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('docs/ux/auth').create(recursive: true);
    await File(
      'docs/ux/auth/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!const bool.fromEnvironment('HEALTHMATE_CAPTURE_AUTH')) return;
    final font = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/inter/Inter-$weight.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  test(
    'new passwords require 8 characters while existing short passwords can still sign in',
    () {
      expect(AuthValidation.password('1234567', registering: true), isNotNull);
      expect(AuthValidation.password('12345678', registering: true), isNull);
      expect(AuthValidation.password('old123', registering: false), isNull);
      expect(AuthValidation.password('        ', registering: true), isNotNull);
    },
  );
  testWidgets(
    'Google is a real controller action; cancellation and provider collision preserve login and retry works',
    (t) async {
      final a = FakeAuthRepository()
        ..googleFailure = AuthFailure.fromCode('sign-in-cancelled');
      final root = GlobalKey();
      await pumpApp(t, repository: a, captureKey: root);
      await captureAuth(t, root, 'login');
      await tap(t, 'auth-google');
      expect(a.googleCalls, 1);
      expect(find.textContaining('Bạn đã hủy đăng nhập'), findsOneWidget);
      a.googleFailure = AuthFailure.fromCode(
        'account-exists-with-different-credential',
      );
      await tap(t, 'auth-google');
      expect(find.textContaining('cách đăng nhập khác'), findsOneWidget);
      expect(a.registerCalls, 0);
      expect(a.signInCalls, 0);
      a.googleFailure = null;
      await tap(t, 'auth-google');
      expect(a.googleCalls, 3);
      expect(find.text('Chào mừng bạn trở lại'), findsNothing);
    },
  );
  testWidgets(
    'pending Google authentication prevents duplicate calls and email submission',
    (t) async {
      final a = FakeAuthRepository()..pending = Completer<void>();
      await pumpApp(t, repository: a);
      await t.ensureVisible(find.byKey(const ValueKey('auth-google')));
      await t.tap(find.byKey(const ValueKey('auth-google')));
      await t.pump();
      expect(
        t
            .widget<OutlinedButton>(find.byKey(const ValueKey('auth-google')))
            .onPressed,
        isNull,
      );
      expect(
        t
            .widget<FilledButton>(find.byKey(const ValueKey('auth-submit')))
            .onPressed,
        isNull,
      );
      expect(a.googleCalls, 1);
      a.pending!.complete();
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'unverified existing user cannot bootstrap private data; only confirmed refresh unlocks routes',
    (t) async {
      final a = FakeAuthRepository(user: unverified),
          p = FakeHealthProfileRepository(
            profile: FakeHealthProfileRepository.testProfile,
          );
      final root = GlobalKey();
      final c = await pumpApp(
        t,
        repository: a,
        profileRepository: p,
        captureKey: root,
      );
      await captureAuth(t, root, 'verify-email');
      expect(find.text('Xác minh email của bạn'), findsOneWidget);
      expect(p.ensureCalls, 0);
      expect(a.verificationCalls, 1);
      c.read(appRouterProvider).go(AppRoutes.journal);
      await t.pumpAndSettle();
      expect(find.text('Xác minh email của bạn'), findsOneWidget);
      await tap(t, 'verification-check');
      expect(a.reloadCalls, 1);
      expect(p.ensureCalls, 0);
      a.verifiedOnReload = true;
      await tap(t, 'verification-check');
      expect(find.text('Xác minh email của bạn'), findsNothing);
      expect(p.ensureCalls, greaterThan(0));
    },
  );
  testWidgets(
    'verification sends once, observes cooldown at zero, and refreshes on app resume',
    (t) async {
      var now = DateTime(2026, 10, 24);
      final a = FakeAuthRepository(user: unverified);
      await pumpApp(t, repository: a, authNow: () => now);
      expect(a.verificationCalls, 1);
      expect(find.text('Gửi lại sau 60s'), findsOneWidget);
      now = now.add(const Duration(seconds: 61));
      await t.pump(const Duration(seconds: 1));
      await t.pumpAndSettle();
      expect(
        t
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('verification-resend')),
            )
            .onPressed,
        isNotNull,
      );
      await tap(t, 'verification-resend');
      expect(a.verificationCalls, 2);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pumpAndSettle();
      expect(a.reloadCalls, 1);
    },
  );
  testWidgets(
    'verification errors are visible and sending can be retried without losing the account',
    (t) async {
      final a = FakeAuthRepository(user: unverified)
        ..verificationFailure = AuthFailure.fromCode('network-request-failed');
      await pumpApp(t, repository: a);
      expect(find.textContaining('Không thể kết nối'), findsOneWidget);
      a.verificationFailure = null;
      await tap(t, 'verification-resend');
      expect(a.verificationCalls, 2);
      expect(
        find.byKey(const ValueKey('verification-message')),
        findsOneWidget,
      );
      await tap(t, 'verification-sign-out');
      expect(find.text('Chào mừng bạn trở lại'), findsOneWidget);
    },
  );
  testWidgets(
    'late verification response from UID A cannot update UID B state',
    (t) async {
      final a = FakeAuthRepository(user: unverified)
        ..pending = Completer<void>();
      final c = await pumpApp(t, repository: a, settle: false);
      await t.pump(const Duration(milliseconds: 200));
      expect(a.verificationCalls, 1);
      a.emitUser(
        const AuthUser(uid: 'B', email: 'b@example.com', emailVerified: false),
      );
      await t.pump(const Duration(milliseconds: 200));
      a.pending!.complete();
      await t.pumpAndSettle();
      expect(
        c.read(emailVerificationProvider).message,
        isNot(contains('member@example.com')),
      );
      expect(c.read(authSessionProvider).value?.uid, 'B');
      expect(c.read(emailVerificationProvider).error, isNull);
      expect(a.verificationCalls, 2);
      expect(find.text('Xác minh email của bạn'), findsOneWidget);
    },
  );
  testWidgets(
    'reset email has visible errors, neutral success, duplicate guard and resend cooldown',
    (t) async {
      var now = DateTime(2026, 10, 24);
      final a = FakeAuthRepository()
        ..resetFailure = AuthFailure.fromCode('network-request-failed');
      final root = GlobalKey();
      await pumpApp(t, repository: a, authNow: () => now, captureKey: root);
      await tap(t, 'forgot-password');
      await t.enterText(
        find.byKey(const ValueKey('reset-password-email')),
        'member@example.com',
      );
      await tap(t, 'send-reset-password');
      expect(a.resetPasswordCalls, 1);
      expect(find.textContaining('Không thể kết nối'), findsOneWidget);
      a.resetFailure = AuthFailure.fromCode('user-not-found');
      await tap(t, 'send-reset-password');
      expect(find.text('Kiểm tra hộp thư'), findsOneWidget);
      await captureAuth(t, root, 'reset-email');
      expect(
        find.textContaining('Nếu email thuộc một tài khoản'),
        findsOneWidget,
      );
      expect(
        t
            .widget<TextButton>(
              find.byKey(const ValueKey('send-reset-password')),
            )
            .onPressed,
        isNull,
      );
      now = now.add(const Duration(seconds: 61));
      await t.pump(const Duration(seconds: 1));
      await t.pumpAndSettle();
      a.resetFailure = null;
      await tap(t, 'send-reset-password');
      expect(a.resetPasswordCalls, 3);
    },
  );
  testWidgets(
    'Google-only account hides password change and reauthenticates with Google before deleting',
    (t) async {
      final events = <String>[],
          a = FakeAuthRepository(user: googleUser, events: events),
          data = FakeAccountDataRepository(events: events);
      final c = await pumpApp(t, repository: a, accountDataRepository: data);
      c.read(appRouterProvider).go(AppRoutes.profile);
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('change-password')), findsNothing);
      await tap(t, 'delete-account');
      expect(
        find.byKey(const ValueKey('delete-account-password')),
        findsNothing,
      );
      await tap(t, 'delete-account-understood');
      await tap(t, 'confirm-delete-account');
      expect(a.googleReauthCalls, 1);
      expect(a.reauthenticateCalls, 0);
      expect(events.first, 'reauthenticate-google');
      expect(a.deleteUserCalls, 1);
    },
  );
  for (final size in [const Size(360, 800), const Size(390, 844)]) {
    testWidgets('verification fits $size at text scale 2', (t) async {
      await pumpApp(
        t,
        size: size,
        textScale: 2,
        repository: FakeAuthRepository(user: unverified),
      );
      await t.ensureVisible(find.byKey(const ValueKey('verification-resend')));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }
}
