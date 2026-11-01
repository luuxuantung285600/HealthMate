import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/chatbot/providers/chat_providers.dart';
import 'package:healthmate/features/food_scanner/presentation/food_scanner_dialog.dart';
import 'package:healthmate/features/food_scanner/providers/food_scanner_providers.dart';
import 'package:healthmate/features/food_scanner/data/food_scanner_service.dart';
import 'package:healthmate/features/food_scanner/data/food_camera_service.dart';
import 'package:healthmate/features/food_scanner/models/ai_food_suggestion.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';

import 'support/fake_chat_repository.dart';
import 'support/test_app.dart';
import 'support/fake_food_camera.dart';

class _NeverAnalyzeScanner implements FoodScannerService {
  int calls = 0;
  @override
  Future<AiFoodSuggestion> analyze({
    required List<int> bytes,
    required String mimeType,
  }) async {
    calls++;
    throw StateError('Opening the camera must not analyze an image.');
  }
}

const enabled = AppFeatureFlags(chatbotEnabled: true, foodScannerEnabled: true);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets('five bottom slots $width scale $scale ${mode.name}', (
          tester,
        ) async {
          final container = await pumpApp(
            tester,
            size: Size(width, 844),
            textScale: scale,
            initialThemeMode: mode,
            featureFlags: enabled,
          );
          final keys = [
            'nav-dashboard',
            'nav-journal',
            'quick-add-menu',
            'nav-progress',
            'nav-profile',
          ];
          final rects = [
            for (final key in keys) tester.getRect(find.byKey(ValueKey(key))),
          ];
          for (var i = 0; i < rects.length; i++) {
            expect(find.byKey(ValueKey(keys[i])), findsOneWidget);
            expect(rects[i].width, greaterThanOrEqualTo(48));
            expect(rects[i].height, greaterThanOrEqualTo(48));
            if (i > 0) {
              expect(rects[i].left, greaterThanOrEqualTo(rects[i - 1].right));
            }
          }
          expect(rects[2].center.dx, closeTo(width / 2, 1));
          for (final entry in [
            ('nav-journal', AppRoutes.journal),
            ('nav-progress', AppRoutes.progress),
            ('nav-profile', AppRoutes.profile),
            ('nav-dashboard', AppRoutes.dashboard),
          ]) {
            if (entry.$1 == 'nav-profile') {
              await openProfileFromShell(tester);
            } else {
              await tester.tap(find.byKey(ValueKey(entry.$1)));
            }
            await tester.pumpAndSettle();
            expect(
              container
                  .read(appRouterProvider)
                  .routeInformationProvider
                  .value
                  .uri
                  .path,
              entry.$2,
            );
          }
          // Browsing tabs must not create an AI service or scanner session.
          expect(container.exists(chatControllerProvider), isFalse);
          expect(container.exists(foodScannerServiceProvider), isFalse);
          expect(container.exists(foodImagePickerProvider), isFalse);
          await tester.tap(find.byKey(const ValueKey('quick-add-menu')));
          await tester.pumpAndSettle();
          expect(find.byType(MealFormDialog), findsOneWidget);
          expect(find.byKey(const ValueKey('food-search')), findsOneWidget);
          expect(find.byType(FoodScannerDialog), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets(
    'available photo service opens camera without uploading an image',
    (tester) async {
      final scanner = _NeverAnalyzeScanner();
      final camera = FakeFoodCamera();
      final container = await pumpApp(
        tester,
        featureFlags: enabled,
        foodScannerService: scanner,
        foodCameraService: FoodCameraService(createSession: () => camera),
      );
      await tester.tap(find.byKey(const ValueKey('quick-add-menu')));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('meal-entry-photo')));
      expect(find.byType(FoodScannerDialog), findsOneWidget);
      expect(find.byKey(const ValueKey('camera-shutter')), findsOneWidget);
      expect(find.byKey(const ValueKey('camera-gallery')), findsOneWidget);
      expect(scanner.calls, 0);
      expect(camera.starts, 1);
      expect(camera.captures, 0);
      expect(container.exists(foodImagePickerProvider), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  for (final fromMenu in [false, true]) {
    testWidgets(
      'goals and chat are reachable from ${fromMenu ? 'avatar' : 'profile tab'}',
      (tester) async {
        final ai = FakeKnowledgeService();
        final container = await pumpApp(
          tester,
          featureFlags: enabled,
          knowledgeService: ai,
        );
        for (final destination in [
          ('quests', 'open-goals-quests', AppRoutes.quest),
          ('chat', 'open-chat', AppRoutes.chat),
        ]) {
          if (fromMenu) {
            container.read(appRouterProvider).go(AppRoutes.dashboard);
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('profile-avatar')));
            await tester.pumpAndSettle();
          } else {
            await openProfileFromShell(tester);
          }
          await tapVisible(tester, find.byKey(ValueKey(destination.$2)));
          expect(
            container
                .read(appRouterProvider)
                .routeInformationProvider
                .value
                .uri
                .path,
            destination.$3,
          );
        }
        expect(ai.topics, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'real add-meal flow exposes barcode with custom food sources and AI off',
    (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('quick-add-menu')));
      await tester.pumpAndSettle();
      await openMealTools(tester);
      final form = tester.widget<MealFormDialog>(find.byType(MealFormDialog));
      expect(form.sourcesBuilder, isNotNull);
      final barcode = find.byKey(const ValueKey('scan-barcode'));
      await tester.scrollUntilVisible(
        barcode,
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('meal-manual-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(tester.widget<OutlinedButton>(barcode).onPressed, isNotNull);
      expect(find.text('Quét mã vạch'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
