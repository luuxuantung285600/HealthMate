import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/auth/models/auth_failure.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';

import 'support/fake_auth_repository.dart';
import 'support/test_app.dart';

Finder control(String name) => find.byKey(ValueKey(name));

TextFormField field(WidgetTester tester, String name) =>
    tester.widget<TextFormField>(control(name));

TextField input(WidgetTester tester, String name) => tester.widget<TextField>(
  find.descendant(of: control(name), matching: find.byType(TextField)),
);

Future<void> press(WidgetTester tester, String name) async {
  await tester.ensureVisible(control(name));
  await tester.pumpAndSettle();
  await tester.tap(control(name));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('switching mode preserves email but clears and masks passwords', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await pumpApp(tester, repository: auth);
    await tester.enterText(control('auth-email'), 'draft@example.com');
    await tester.enterText(control('auth-password'), 'login-secret');
    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await press(tester, 'auth-toggle');
    expect(field(tester, 'auth-email').controller!.text, 'draft@example.com');
    expect(field(tester, 'auth-password').controller!.text, isEmpty);
    expect(field(tester, 'auth-confirmation').controller!.text, isEmpty);
    expect(find.byTooltip('Hiện mật khẩu'), findsOneWidget);
    await tester.enterText(control('auth-password'), 'new-secret');
    await tester.enterText(control('auth-confirmation'), 'new-secret');
    await press(tester, 'auth-toggle');
    expect(field(tester, 'auth-email').controller!.text, 'draft@example.com');
    expect(field(tester, 'auth-password').controller!.text, isEmpty);
    expect(control('auth-confirmation'), findsNothing);
    expect(auth.signInCalls + auth.registerCalls, 0);
    expect(find.text('Chào mừng bạn trở lại').hitTestable(), findsOneWidget);
  });

  testWidgets(
    'Back from registration returns to login with the email retained',
    (tester) async {
      await pumpApp(tester, repository: FakeAuthRepository());
      await tester.enterText(control('auth-email'), 'draft@example.com');
      await press(tester, 'auth-toggle');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(control('auth-confirmation'), findsNothing);
      expect(field(tester, 'auth-email').controller!.text, 'draft@example.com');
      expect(find.text('Chào mừng bạn trở lại').hitTestable(), findsOneWidget);
    },
  );

  testWidgets(
    'validation focuses the first invalid input without sending data',
    (tester) async {
      final auth = FakeAuthRepository();
      await pumpApp(tester, repository: auth);
      await press(tester, 'auth-toggle');
      await press(tester, 'auth-submit');
      expect(input(tester, 'auth-email').focusNode!.hasFocus, isTrue);
      await tester.enterText(control('auth-email'), 'draft@example.com');
      await press(tester, 'auth-submit');
      expect(input(tester, 'auth-password').focusNode!.hasFocus, isTrue);
      await tester.enterText(control('auth-password'), 'new-secret');
      await press(tester, 'auth-submit');
      expect(input(tester, 'auth-confirmation').focusNode!.hasFocus, isTrue);
      expect(auth.registerCalls, 0);
    },
  );

  testWidgets(
    'keyboard Next and Done submit registration; a failure keeps inputs',
    (tester) async {
      final auth = FakeAuthRepository()
        ..failure = AuthFailure.fromCode('network-request-failed');
      await pumpApp(tester, repository: auth);
      await press(tester, 'auth-toggle');
      await tester.enterText(control('auth-email'), 'draft@example.com');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(input(tester, 'auth-password').focusNode!.hasFocus, isTrue);
      await tester.enterText(control('auth-password'), 'new-secret');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(input(tester, 'auth-confirmation').focusNode!.hasFocus, isTrue);
      await tester.enterText(control('auth-confirmation'), 'new-secret');
      await tester.tap(find.byTooltip('Hiện mật khẩu nhập lại'));
      await tester.pump();
      expect(find.byTooltip('Hiện mật khẩu'), findsOneWidget);
      expect(find.byTooltip('Ẩn mật khẩu nhập lại'), findsOneWidget);
      await tester.tap(control('auth-confirmation'));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(auth.registerCalls, 1);
      expect(field(tester, 'auth-email').controller!.text, 'draft@example.com');
      expect(field(tester, 'auth-password').controller!.text, 'new-secret');
      expect(field(tester, 'auth-confirmation').controller!.text, 'new-secret');
      expect(find.text(auth.failure!.message), findsOneWidget);
    },
  );

  testWidgets('reset prefill and both Back paths preserve the login form', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..resetFailure = AuthFailure.fromCode('network-request-failed');
    await pumpApp(tester, repository: auth);
    await tester.enterText(control('auth-email'), 'draft@example.com');
    await tester.enterText(control('auth-password'), 'private-secret');
    await press(tester, 'forgot-password');
    expect(
      field(tester, 'reset-password-email').controller!.text,
      'draft@example.com',
    );
    await press(tester, 'send-reset-password');
    expect(find.text(auth.resetFailure!.message), findsOneWidget);
    await press(tester, 'auth-flow-back');
    expect(find.text(auth.resetFailure!.message), findsNothing);
    expect(field(tester, 'auth-email').controller!.text, 'draft@example.com');
    expect(field(tester, 'auth-password').controller!.text, 'private-secret');
    await press(tester, 'forgot-password');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(field(tester, 'auth-password').controller!.text, 'private-secret');
    expect(auth.signInCalls + auth.registerCalls, 0);
  });

  testWidgets(
    'pending reset blocks Back and duplicate requests, then offers login',
    (tester) async {
      final pending = Completer<void>();
      final auth = FakeAuthRepository()..pending = pending;
      await pumpApp(tester, repository: auth);
      await tester.enterText(control('auth-email'), 'draft@example.com');
      await press(tester, 'forgot-password');
      await tester.tap(control('send-reset-password'));
      await tester.pump();
      expect(auth.resetPasswordCalls, 1);
      expect(field(tester, 'reset-password-email').enabled, isFalse);
      expect(
        tester.widget<IconButton>(control('auth-flow-back')).onPressed,
        isNull,
      );
      expect(
        tester.widget<FilledButton>(control('send-reset-password')).onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 300));
      expect(control('reset-password-email'), findsOneWidget);
      expect(auth.resetPasswordCalls, 1);
      pending.complete();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Nếu email thuộc một tài khoản'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextButton>(control('send-reset-password')).onPressed,
        isNull,
      );
      await press(tester, 'reset-back-to-login');
      expect(field(tester, 'auth-email').controller!.text, 'draft@example.com');
    },
  );

  testWidgets(
    'pending Google uses its own progress label and preserves typed email',
    (tester) async {
      final pending = Completer<void>();
      final auth = FakeAuthRepository()
        ..pending = pending
        ..googleFailure = AuthFailure.fromCode('sign-in-cancelled');
      await pumpApp(tester, repository: auth);
      await tester.enterText(control('auth-email'), 'draft@example.com');
      await tester.ensureVisible(control('auth-google'));
      await tester.tap(control('auth-google'));
      await tester.pump();
      expect(find.text('Đang kết nối Google…'), findsOneWidget);
      expect(find.text('Đang đăng nhập…'), findsNothing);
      expect(
        tester.widget<TextButton>(control('auth-toggle')).onPressed,
        isNull,
      );
      pending.complete();
      await tester.pumpAndSettle();
      expect(auth.googleCalls, 1);
      expect(field(tester, 'auth-email').controller!.text, 'draft@example.com');
      expect(find.textContaining('Bạn đã hủy đăng nhập'), findsOneWidget);
    },
  );

  testWidgets(
    'primary actions are visible and controls have Android touch labels',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await pumpApp(tester, repository: FakeAuthRepository());
        expect(control('auth-submit').hitTestable(), findsOneWidget);
        expect(control('auth-toggle').hitTestable(), findsOneWidget);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await press(tester, 'auth-toggle');
        expect(control('auth-submit').hitTestable(), findsOneWidget);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final width in [320.0, 390.0, 412.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets(
          'account forms reachable ${width}px scale$scale $mode with keyboard',
          (tester) async {
            final auth = FakeAuthRepository();
            await pumpApp(
              tester,
              repository: auth,
              size: Size(width, 844),
              textScale: scale,
              initialThemeMode: mode,
            );
            tester.view.viewInsets = const FakeViewPadding(bottom: 280);
            addTearDown(tester.view.resetViewInsets);
            for (final key in [
              'auth-email',
              'auth-password',
              'auth-submit',
              'auth-google',
              'auth-toggle',
            ]) {
              await tester.ensureVisible(control(key));
              await tester.pumpAndSettle();
              expect(control(key).hitTestable(), findsOneWidget);
            }
            await press(tester, 'auth-toggle');
            for (final key in [
              'auth-email',
              'auth-password',
              'auth-confirmation',
              'auth-submit',
              'auth-google',
              'auth-privacy',
            ]) {
              await tester.ensureVisible(control(key));
              await tester.pumpAndSettle();
              expect(control(key).hitTestable(), findsOneWidget);
            }
            await press(tester, 'auth-toggle');
            await press(tester, 'forgot-password');
            await tester.enterText(control('reset-password-email'), 'invalid');
            await press(tester, 'send-reset-password');
            expect(auth.resetPasswordCalls, 0);
            expect(find.text('Vui lòng nhập email hợp lệ.'), findsOneWidget);
            await tester.enterText(
              control('reset-password-email'),
              'member@example.com',
            );
            await press(tester, 'send-reset-password');
            await tester.ensureVisible(control('reset-back-to-login'));
            expect(
              control('reset-back-to-login').hitTestable(),
              findsOneWidget,
            );
            await press(tester, 'reset-back-to-login');
            auth.emitUser(
              const AuthUser(
                uid: 'test-uid',
                email: 'member@example.com',
                emailVerified: false,
              ),
            );
            await tester.pumpAndSettle();
            for (final key in [
              'verification-check',
              'verification-resend',
              'verification-sign-out',
            ]) {
              await tester.ensureVisible(control(key));
              await tester.pumpAndSettle();
              expect(control(key).hitTestable(), findsOneWidget);
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
