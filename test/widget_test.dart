import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/shared/providers/theme_mode_provider.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('starts in Vietnamese with an honest dashboard empty state', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      dashboardNow: DateTime(2026, 10, 13, 9),
    );
    expect(find.byKey(const ValueKey('dashboard-screen')), findsOneWidget);
    expect(find.text('Hôm nay'), findsNWidgets(2));
    expect(find.text('Chưa ghi món'), findsNWidgets(4));
    expect(find.textContaining('sẽ có trong các bản tiếp theo'), findsNothing);
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      AppRoutes.dashboard,
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('vi'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'visible navigation opens three core routes and keeps opt-in hidden routes',
    (tester) async {
      final container = await pumpApp(
        tester,
        featureFlags: const AppFeatureFlags(chatbotEnabled: true),
      );
      for (final destination in [
        (
          key: const ValueKey('nav-journal'),
          route: AppRoutes.journal,
          title: 'Nhật ký',
        ),
        (
          key: const ValueKey('nav-profile'),
          route: AppRoutes.profile,
          title: 'Không gian cá nhân',
        ),
      ]) {
        await tester.tap(find.byKey(destination.key));
        await tester.pumpAndSettle();
        expect(
          destination.route == AppRoutes.journal
              ? find.byKey(const ValueKey('journal-screen'))
              : find.text(destination.title),
          findsOneWidget,
        );
        expect(
          container
              .read(appRouterProvider)
              .routeInformationProvider
              .value
              .uri
              .path,
          destination.route,
        );
      }
      await tester.tap(find.byKey(const ValueKey('nav-dashboard')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dashboard-screen')), findsOneWidget);
      expect(find.text('Quest'), findsNothing);
      expect(find.text('AI / Chat'), findsNothing);

      container.read(appRouterProvider).go(AppRoutes.quest);
      await tester.pumpAndSettle();
      expect(find.text('Nhịp khỏe mỗi ngày'), findsOneWidget);
      container.read(appRouterProvider).go(AppRoutes.chat);
      await tester.pumpAndSettle();
      expect(find.text('Hiểu nhật ký của bạn'), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-input')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('core navigation reaches account and account can sign out', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('nav-journal')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('journal-screen')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sign-out')));
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng bạn trở lại'), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-add-menu')), findsNothing);
  });

  testWidgets('authenticated user is redirected away from auth', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    container.read(appRouterProvider).go(AppRoutes.auth);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dashboard-screen')), findsOneWidget);
  });

  testWidgets('unknown route has a working recovery action', (tester) async {
    final container = await pumpApp(tester);
    container.read(appRouterProvider).go('/missing');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy trang'), findsOneWidget);
    await tester.tap(find.text('Về Tổng quan'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dashboard-screen')), findsOneWidget);
  });

  testWidgets('theme preference changes the app and survives navigation', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Tối'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tối'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(
      Theme.of(
        tester.element(find.byKey(const ValueKey('nav-profile'))),
      ).brightness,
      Brightness.dark,
    );
    container.read(appRouterProvider).go(AppRoutes.dashboard);
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(tester.takeException(), isNull);
  });

  for (final layout in [
    (
      name: 'small phone with large text',
      size: const Size(320, 640),
      scale: 2.0,
      rail: false,
    ),
    (name: 'wide screen', size: const Size(1024, 768), scale: 1.0, rail: true),
  ]) {
    testWidgets('routes fit ${layout.name} without layout exceptions', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        size: layout.size,
        textScale: layout.scale,
      );
      for (final route in [
        AppRoutes.dashboard,
        AppRoutes.journal,
        AppRoutes.quest,
        AppRoutes.chat,
        AppRoutes.profile,
        AppRoutes.auth,
      ]) {
        container.read(appRouterProvider).go(route);
        await tester.pumpAndSettle();
        if (route != AppRoutes.auth) {
          expect(
            find.byType(NavigationRail),
            layout.rail ? findsOneWidget : findsNothing,
          );
          expect(find.byKey(const ValueKey('quick-add-menu')), findsOneWidget);
        }
        expect(tester.takeException(), isNull, reason: route);
      }
    });
  }
}
