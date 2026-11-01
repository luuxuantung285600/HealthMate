import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/chatbot/models/chat_models.dart';
import 'package:healthmate/features/chatbot/providers/chat_providers.dart';
import 'package:healthmate/features/food_scanner/data/food_scanner_service.dart';
import 'package:healthmate/features/food_scanner/presentation/food_scanner_dialog.dart';
import 'package:healthmate/features/food_scanner/providers/food_scanner_providers.dart';
import 'package:healthmate/features/journal/providers/journal_quick_action_provider.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_chat_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/test_app.dart';

void _expectAiUnused(ProviderContainer container, FakeChatRepository history) {
  expect(history.loadCalls, 0);
  expect(history.saveCalls, 0);
  expect(container.exists(chatControllerProvider), isFalse);
  expect(container.exists(knowledgeServiceProvider), isFalse);
  expect(container.exists(foodScannerServiceProvider), isFalse);
  expect(container.exists(foodImagePickerProvider), isFalse);
}

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
  test(
    'default build exposes AI entry points without starting AI or Firebase',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final flags = container.read(appFeatureFlagsProvider);
      expect(flags.chatbotEnabled, isTrue);
      expect(flags.foodScannerEnabled, isTrue);
      expect(container.exists(knowledgeServiceProvider), isFalse);
      expect(container.exists(foodScannerServiceProvider), isFalse);
      expect(container.exists(authSessionProvider), isFalse);
    },
  );
  test('explicit core-only configuration blocks both AI services', () async {
    final container = ProviderContainer(
      overrides: [
        appFeatureFlagsProvider.overrideWithValue(const AppFeatureFlags()),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container
          .read(knowledgeServiceProvider)
          .explain(KnowledgeTopic.balancedMeals)
          .toList(),
      throwsA(isA<ChatFailure>()),
    );
    await expectLater(
      Future.sync(
        () => container
            .read(foodScannerServiceProvider)
            .analyze(bytes: Uint8List.fromList([1]), mimeType: 'image/png'),
      ),
      throwsA(
        isA<FoodScannerFailure>().having(
          (error) => error.message,
          'message',
          contains('tạm tắt'),
        ),
      ),
    );
    expect(container.exists(authSessionProvider), isFalse);
  });

  for (final width in [360.0, 390.0, 412.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final theme in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets(
          'core navigation $width scale$scale $theme never starts AI',
          (tester) async {
            final history = FakeChatRepository();
            final captureKey = GlobalKey();
            history.sessions['test-uid'] = {'retained-history': []};
            final container = await pumpApp(
              tester,
              size: Size(width, 844),
              textScale: scale,
              initialThemeMode: theme,
              chatRepository: history,
              captureKey: captureKey,
            );
            _expectAiUnused(container, history);
            for (final tab in [
              'nav-journal',
              'nav-progress',
              'nav-profile',
              'nav-dashboard',
            ]) {
              if (tab == 'nav-profile') {
                await openProfileFromShell(tester);
              } else {
                await tester.tap(find.byKey(ValueKey(tab)));
              }
              await tester.pumpAndSettle();
              expect(find.byKey(const ValueKey('open-chat')), findsNothing);
              expect(find.byKey(const ValueKey('scan-food')), findsNothing);
              _expectAiUnused(container, history);
            }
            await tester.tap(find.byKey(const ValueKey('quick-add-menu')));
            await tester.pumpAndSettle();
            expect(find.byType(MealFormDialog), findsOneWidget);
            expect(find.byKey(const ValueKey('food-search')), findsOneWidget);
            expect(
              find.byKey(const ValueKey('quick-action-scan')),
              findsNothing,
            );
            expect(find.text('Quét món'), findsNothing);
            if ((width == 360 && scale == 1 && theme == ThemeMode.light) ||
                (width == 390 && scale == 1.5 && theme == ThemeMode.dark) ||
                (width == 412 && scale == 2 && theme == ThemeMode.light)) {
              await tester.runAsync(() async {
                final boundary =
                    captureKey.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                final picture = await boundary.toImage();
                final bytes = await picture.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                picture.dispose();
                final directory = Directory('build/c1-layout');
                await directory.create(recursive: true);
                await File(
                  '${directory.path}/$width-$scale-${theme.name}.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
              });
            }
            _expectAiUnused(container, history);
            expect(history.sessions['test-uid']!.keys, ['retained-history']);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'direct chat links and login return links cannot open disabled AI',
    (tester) async {
      final auth = FakeAuthRepository();
      final history = FakeChatRepository();
      final container = await pumpApp(
        tester,
        repository: auth,
        chatRepository: history,
      );
      final router = container.read(appRouterProvider);
      router.go('/chat?topic=balancedMeals');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.auth);
      auth.emitUser(FakeAuthRepository.testUser);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.dashboard,
      );
      for (final link in [
        '/chat',
        '/chat/?topic=x',
        '/chat/history',
        '/auth?from=%2Fchat',
      ]) {
        router.go(link);
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.dashboard,
        );
        _expectAiUnused(container, history);
      }
      await openProfileFromShell(tester);
      await tester.pumpAndSettle();
      final quest = find.byKey(const ValueKey('open-goals-quests'));
      await tester.ensureVisible(quest);
      await tester.pumpAndSettle();
      await tester.tap(quest);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.quest);
      await openProfileFromShell(tester);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.profile);
      _expectAiUnused(container, history);
    },
  );

  testWidgets('cold start from disabled chat never constructs an AI branch', (
    tester,
  ) async {
    tester.platformDispatcher.defaultRouteNameTestValue =
        '/chat?topic=balancedMeals';
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    final history = FakeChatRepository();
    final container = await pumpApp(tester, chatRepository: history);
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      AppRoutes.dashboard,
    );
    _expectAiUnused(container, history);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back from a blocked chat push returns to the current core tab', (
    tester,
  ) async {
    final history = FakeChatRepository();
    final container = await pumpApp(tester, chatRepository: history);
    final router = container.read(appRouterProvider);
    await openProfileFromShell(tester);
    await tester.pumpAndSettle();
    router.push<void>(AppRoutes.chat);
    await tester.pumpAndSettle();
    // Imperative pushes do not update the URL by default in go_router.
    expect(find.byKey(const ValueKey('dashboard-screen')), findsOneWidget);
    expect(router.canPop(), isTrue);
    router.pop();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.profile);
    _expectAiUnused(container, history);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding gate takes priority over disabled chat redirect', (
    tester,
  ) async {
    final container = await pumpApp(
      tester,
      profileRepository: FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.incompleteProfile,
      ),
    );
    container.read(appRouterProvider).go('/chat');
    await tester.pumpAndSettle();
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      AppRoutes.onboarding,
    );
    expect(container.exists(chatControllerProvider), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'disabled controller and queued scanner cannot call services or read history',
    (tester) async {
      final history = FakeChatRepository();
      final ai = FakeKnowledgeService();
      final container = await pumpApp(
        tester,
        chatRepository: history,
        knowledgeService: ai,
      );
      final subscription = container.listen(chatControllerProvider, (_, _) {});
      addTearDown(subscription.close);
      await tester.pumpAndSettle();
      final chat = container.read(chatControllerProvider.notifier);
      await chat.loadSessions();
      await chat.openSession('retained-history');
      expect(
        await chat.send(
          '',
          DateTime.now(),
          topic: KnowledgeTopic.balancedMeals,
        ),
        isFalse,
      );
      expect(history.loadCalls, 0);
      expect(history.saveCalls, 0);
      expect(ai.topics, isEmpty);
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      container
          .read(journalQuickActionProvider.notifier)
          .request(JournalQuickAction.scanFood);
      await tester.pumpAndSettle();
      expect(container.read(journalQuickActionProvider), isNull);
      expect(find.byType(FoodScannerDialog), findsNothing);
      expect(container.exists(foodImagePickerProvider), isFalse);
      await tester.tap(find.byKey(const ValueKey('quick-add-menu')));
      await tester.pumpAndSettle();
      expect(find.byType(MealFormDialog), findsOneWidget);
      expect(find.byKey(const ValueKey('save-meal')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'chat and scanner flags are independent and keep existing branch indexes',
    (tester) async {
      final container = await pumpApp(
        tester,
        featureFlags: const AppFeatureFlags(foodScannerEnabled: true),
      );
      container.read(appRouterProvider).go(AppRoutes.chat);
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        AppRoutes.dashboard,
      );
      await openProfileFromShell(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('open-chat')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('quick-add-menu')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('meal-entry-photo')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
