import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/auth/data/account_data_repository.dart';
import 'package:healthmate/features/auth/models/auth_failure.dart';
import 'package:healthmate/shared/providers/theme_mode_provider.dart';

import 'support/fake_account_data_repository.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_theme_preference_store.dart';
import 'support/test_app.dart';

void main() {
  testWidgets('forgot password validates email and sends a neutral response', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await pumpApp(tester, repository: auth);

    await tester.tap(find.byKey(const ValueKey('forgot-password')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('send-reset-password')));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập email.'), findsOneWidget);
    expect(auth.resetPasswordCalls, 0);

    await tester.enterText(
      find.byKey(const ValueKey('reset-password-email')),
      '  member@example.com  ',
    );
    await tester.tap(find.byKey(const ValueKey('send-reset-password')));
    await tester.pumpAndSettle();

    expect(auth.resetPasswordCalls, 1);
    expect(auth.lastEmail, 'member@example.com');
    expect(
      find.textContaining('Nếu email thuộc một tài khoản'),
      findsOneWidget,
    );
  });

  testWidgets('change password reauthenticates before updating it', (
    tester,
  ) async {
    final events = <String>[];
    final auth = FakeAuthRepository(
      user: FakeAuthRepository.testUser,
      events: events,
    );
    final container = await pumpApp(tester, repository: auth);
    container.read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('change-password')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('change-password')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('current-password')),
      'current-secret',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-password')),
      'new-secret-123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-password-confirmation')),
      'new-secret-123',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-change-password')));
    await tester.pumpAndSettle();

    expect(events, ['reauthenticate', 'update-password']);
    expect(auth.lastPassword, 'current-secret');
    expect(auth.lastNewPassword, 'new-secret-123');
    expect(find.text('Đã đổi mật khẩu.'), findsOneWidget);
  });

  testWidgets('wrong current password does not attempt an update', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: FakeAuthRepository.testUser)
      ..reauthenticateFailure = const AuthFailure(
        'unsafe sdk detail',
        code: 'wrong-password',
      );
    final container = await pumpApp(tester, repository: auth);
    container.read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('change-password')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('change-password')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('current-password')),
      'wrong-secret',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-password')),
      'new-secret-123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-password-confirmation')),
      'new-secret-123',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-change-password')));
    await tester.pumpAndSettle();

    expect(auth.updatePasswordCalls, 0);
    expect(find.text('Mật khẩu hiện tại chưa đúng.'), findsOneWidget);
    expect(find.textContaining('unsafe sdk detail'), findsNothing);
  });

  testWidgets('account deletion removes data before Firebase Auth', (
    tester,
  ) async {
    final events = <String>[];
    final auth = FakeAuthRepository(
      user: FakeAuthRepository.testUser,
      events: events,
    );
    final data = FakeAccountDataRepository(events: events);
    final container = await pumpApp(
      tester,
      repository: auth,
      accountDataRepository: data,
    );
    container.read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('delete-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-account')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('confirm-delete-account')),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(
      find.byKey(const ValueKey('delete-account-password')),
      'current-secret',
    );
    await tester.tap(find.byKey(const ValueKey('delete-account-understood')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-delete-account')));
    await tester.pumpAndSettle();

    expect(events, [
      'reauthenticate',
      'request-deletion',
      'delete-data',
      'local-deleted',
      'delete-auth',
    ]);
    expect(data.lastUid, FakeAuthRepository.testUser.uid);
    expect(find.text('Chào mừng bạn trở lại'), findsOneWidget);
  });

  testWidgets('data deletion failure keeps Auth and supports a safe retry', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
    final data = FakeAccountDataRepository()
      ..failure = const AccountDataFailure();
    final container = await pumpApp(
      tester,
      repository: auth,
      accountDataRepository: data,
    );
    container.read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('delete-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-account')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('delete-account-password')),
      'current-secret',
    );
    await tester.tap(find.byKey(const ValueKey('delete-account-understood')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-delete-account')));
    await tester.pumpAndSettle();

    expect(auth.deleteUserCalls, 0);
    expect(find.text('Không gian cá nhân'), findsOneWidget);
    expect(
      find.textContaining('một phần dữ liệu có thể đã xóa'),
      findsOneWidget,
    );
  });

  testWidgets('Auth deletion failure reports that health data was removed', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: FakeAuthRepository.testUser)
      ..deleteUserFailure = AuthFailure.fromCode('network-request-failed');
    final data = FakeAccountDataRepository();
    final container = await pumpApp(
      tester,
      repository: auth,
      accountDataRepository: data,
    );
    container.read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('delete-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-account')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('delete-account-password')),
      'current-secret',
    );
    await tester.tap(find.byKey(const ValueKey('delete-account-understood')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-delete-account')));
    await tester.pumpAndSettle();

    expect(data.deleteCalls, 1);
    expect(auth.deleteUserCalls, 1);
    expect(find.textContaining('Dữ liệu ứng dụng đã dọn'), findsOneWidget);
    expect(find.text('Không gian cá nhân'), findsOneWidget);
  });

  testWidgets('information pages are real routes with privacy explanations', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    for (final page in [
      (AppRoutes.about, 'Giới thiệu HealthMate'),
      (AppRoutes.privacy, 'Quyền riêng tư'),
      (AppRoutes.disclaimer, 'Lưu ý sức khỏe'),
    ]) {
      container.read(appRouterProvider).go(page.$1);
      await tester.pumpAndSettle();
      expect(find.text(page.$2), findsWidgets);
      final back = find.widgetWithText(OutlinedButton, 'Quay lại');
      await tester.ensureVisible(back);
      await tester.pumpAndSettle();
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        AppRoutes.profile,
      );
    }
  });

  testWidgets('theme choice is written to local storage', (tester) async {
    final store = FakeThemePreferenceStore();
    final container = await pumpApp(tester, themePreferenceStore: store);
    container.read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Tối'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tối'));
    await tester.pumpAndSettle();

    expect(store.savedMode, ThemeMode.dark.name);
    expect(store.writeCalls, 1);
    expect(await loadThemeMode(store), ThemeMode.dark);
  });
}
