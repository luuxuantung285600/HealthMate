import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';

import 'support/fake_auth_repository.dart';
import 'support/test_app.dart';
import 'ux_capture_test.dart' show saveCapture;

final authCaptureWidth = double.parse(
  const String.fromEnvironment('AUTH_CAPTURE_WIDTH', defaultValue: '390'),
);
final authCaptureScale = double.parse(
  const String.fromEnvironment('AUTH_CAPTURE_SCALE', defaultValue: '1'),
);
const authCaptureDark = bool.fromEnvironment('AUTH_CAPTURE_DARK');

void main() {
  setUpAll(() async {
    final fonts = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(
        rootBundle.load('assets/fonts/be_vietnam_pro/BeVietnamPro-$weight.ttf'),
      );
    }
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final screen in ['login', 'register', 'reset', 'reset-sent', 'verify']) {
    testWidgets(
      'capture auth $screen width$authCaptureWidth scale$authCaptureScale dark$authCaptureDark',
      (tester) async {
        final key = GlobalKey();
        await pumpApp(
          tester,
          size: Size(authCaptureWidth, 844),
          textScale: authCaptureScale,
          repository: FakeAuthRepository(
            user: screen == 'verify'
                ? const AuthUser(
                    uid: 'test-uid',
                    email: 'member@example.com',
                    emailVerified: false,
                  )
                : null,
          ),
          initialThemeMode: authCaptureDark ? ThemeMode.dark : ThemeMode.light,
          captureKey: key,
        );
        await tester.runAsync(
          () => precacheImage(
            const AssetImage('assets/branding/google_g.png'),
            key.currentContext!,
          ),
        );
        await tester.pumpAndSettle();
        if (screen == 'register') {
          await tester.ensureVisible(find.byKey(const ValueKey('auth-toggle')));
          await tester.tap(find.byKey(const ValueKey('auth-toggle')));
          await tester.pumpAndSettle();
        }
        if (screen.startsWith('reset')) {
          await tester.enterText(
            find.byKey(const ValueKey('auth-email')),
            'member@example.com',
          );
          await tester.ensureVisible(
            find.byKey(const ValueKey('forgot-password')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('forgot-password')));
          await tester.pumpAndSettle();
          if (screen == 'reset-sent') {
            await tester.ensureVisible(
              find.byKey(const ValueKey('send-reset-password')),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('send-reset-password')));
            await tester.pumpAndSettle();
          }
          tester.testTextInput.hide();
          await tester.pumpAndSettle();
        }
        final scroll = find.byType(Scrollable).last;
        tester.state<ScrollableState>(scroll).position.jumpTo(0);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await saveCapture(tester, key, 'auth-$screen');
      },
    );
  }
}
