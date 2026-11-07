import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/journal/providers/journal_date_provider.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_nutrition_target_repository.dart';
import 'support/test_app.dart';
import 'core_journal_test.dart' as fixtures show meal;
import 'weekly_reflection_test.dart' as fixtures show weight;

final captureNow = DateTime(2026, 10, 28, 12);
const captureDirectory = String.fromEnvironment(
  'UX_CAPTURE_DIR',
  defaultValue: 'build/ux-20261101/after',
);

Future<void> saveCapture(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final picture = await boundary.toImage(pixelRatio: 1);
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$captureDirectory/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    picture.dispose();
  });
}

void main() {
  setUpAll(() async {
    final fonts = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/inter/Inter-$weight.ttf'));
    }
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final screen in [
    'home',
    'diary',
    'meal-form',
    'meal-start',
    'progress',
    'onboarding',
  ]) {
    testWidgets('capture deterministic $screen 390x844 light', (tester) async {
      final key = GlobalKey();
      final meals = [
        fixtures.meal(
          'breakfast',
          type: MealType.breakfast,
          date: DateTime(2026, 10, 28, 8),
          grams: 150,
        ),
        fixtures.meal(
          'yesterday',
          date: DateTime(2026, 10, 27, 12),
          grams: 200,
        ),
      ];
      final targets = FakeNutritionTargetRepository()
        ..byUid['test-uid'] = {
          '2026-10-26': const NutritionTarget(
            effectiveFromDateKey: '2026-10-26',
            kcalTarget: 2000,
            proteinGTarget: 100,
            carbsGTarget: 250,
            fatGTarget: 60,
          ),
        };
      final container = await pumpApp(
        tester,
        size: const Size(390, 844),
        textScale: 1,
        initialThemeMode: ThemeMode.light,
        dashboardNow: captureNow,
        captureKey: key,
        nutritionRepository: FakeNutritionRepository(meals: meals),
        targetRepository: targets,
        profileRepository: FakeHealthProfileRepository(
          profile: screen == 'onboarding'
              ? FakeHealthProfileRepository.incompleteProfile
              : FakeHealthProfileRepository.testProfile,
          metrics: [
            fixtures.weight('start', DateTime(2026, 10, 26, 7), 70),
            fixtures.weight('latest', DateTime(2026, 10, 28, 7), 69.5),
          ],
        ),
      );
      if (screen == 'diary' || screen == 'meal-form') {
        container.read(journalDateProvider.notifier).select(captureNow);
        container.read(appRouterProvider).go(AppRoutes.journal);
      } else if (screen == 'progress') {
        container.read(appRouterProvider).go(AppRoutes.progress);
      }
      await tester.pumpAndSettle();
      if (screen == 'meal-start') {
        await tester.tap(find.byKey(const ValueKey('quick-add-menu')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('food-search')).hitTestable(),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('scan-barcode')), findsNothing);
        expect(find.byKey(const ValueKey('open-quick-add')), findsNothing);
        expect(
          tester
              .widget<FilledButton>(find.byKey(const ValueKey('save-meal')))
              .onPressed,
          isNull,
        );
      }
      if (screen == 'meal-form') {
        final context = tester.element(
          find.byKey(const ValueKey('nav-journal')).first,
        );
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => MealFormDialog(
            catalog: const [
              FakeNutritionRepository.rice,
              FakeNutritionRepository.egg,
            ],
            initialConsumedAt: captureNow,
            initialType: MealType.lunch,
            initialItems: [
              MealItemSnapshot.fromCatalog(FakeNutritionRepository.rice, 150),
            ],
            onSave: (_) async => false,
          ),
        );
      }
      await saveCapture(tester, key, screen);
      expect(tester.takeException(), isNull);
    });
  }
}
