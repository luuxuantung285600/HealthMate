import 'support/load_icon_font.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/theme/home_palette.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/dashboard/presentation/widgets/home_dashboard_page.dart';
import 'package:healthmate/features/dashboard/presentation/widgets/mfp_calories_card.dart';
import 'package:healthmate/features/dashboard/presentation/widgets/calorie_macro_ring.dart';
import 'package:healthmate/features/journal/providers/journal_date_provider.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/shared/providers/theme_mode_provider.dart';
import 'support/fake_activity_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_nutrition_target_repository.dart';
import 'support/test_app.dart';

final now = DateTime(2026, 11, 10, 12);
const target = NutritionTarget(
  effectiveFromDateKey: '2026-11-01',
  kcalTarget: 2000,
  proteinGTarget: 100,
  carbsGTarget: 250,
  fatGTarget: 67,
);
FakeNutritionTargetRepository targets() =>
    FakeNutritionTargetRepository()..byUid['test-uid'] = {'2026-11-01': target};

MealLog meal(int day, {double grams = 100}) => MealLog(
  id: 'home-fixture-$day',
  type: MealType.breakfast,
  consumedAt: DateTime(2026, 11, day, 8),
  items: [MealItemSnapshot.fromCatalog(FakeNutritionRepository.rice, grams)],
  totals: FakeNutritionRepository.rice.forGrams(grams),
  source: MealSource.manual,
  dateKey: '2026-11-${day.toString().padLeft(2, '0')}',
  timezoneOffsetMinutes: now.timeZoneOffset.inMinutes,
);

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/home-reference/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await loadIconFont();
    final font = FontLoader('Public Sans');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(
        rootBundle.load('assets/fonts/public_sans/PublicSans-$weight.ttf'),
      );
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('Home follows live light, dark and system preferences', (
    tester,
  ) async {
    final container = await pumpApp(tester, dashboardNow: now);
    Color canvas() => tester
        .widget<Material>(
          find
              .descendant(
                of: find.byType(HomeDashboardPage),
                matching: find.byType(Material),
              )
              .first,
        )
        .color!;
    expect(canvas(), Colors.white);
    container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(canvas(), Colors.black);
    container.read(themeModeProvider.notifier).setMode(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(canvas(), Colors.white);
    container.read(themeModeProvider.notifier).setMode(ThemeMode.system);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();
    expect(canvas(), Colors.black);
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'weekday selection changes real totals and retains date for journal',
    (tester) async {
      final repo = FakeNutritionRepository(
        meals: [meal(9, grams: 200), meal(10)],
      );
      final container = await pumpApp(
        tester,
        dashboardNow: now,
        nutritionRepository: repo,
        targetRepository: targets(),
      );
      expect(find.text('1.870'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('home-week-2026-11-09')));
      await tester.pumpAndSettle();
      expect(find.text('1.740'), findsOneWidget);
      expect(container.read(journalDateProvider), DateTime(2026, 11, 9));
      await tester.tap(find.byKey(const ValueKey('home-week-2026-11-11')));
      await tester.pumpAndSettle();
      expect(container.read(journalDateProvider), DateTime(2026, 11, 9));
      await tester.tap(find.byKey(const ValueKey('home-return-today')));
      await tester.pumpAndSettle();
      expect(find.text('1.870'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('home-view-report')));
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        AppRoutes.progress,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final calories in [null, 80.0]) {
    testWidgets(
      'activity estimate $calories is honest and never credits remaining',
      (tester) async {
        await pumpApp(
          tester,
          dashboardNow: now,
          targetRepository: targets(),
          nutritionRepository: FakeNutritionRepository(meals: [meal(10)]),
          activityRepository: FakeActivityRepository(
            logs: [
              ActivityLog(
                id: 'home-activity',
                type: ActivityType.walking,
                durationMinutes: 20,
                performedAt: now,
                dateKey: '2026-11-10',
                timezoneOffsetMinutes: now.timeZoneOffset.inMinutes,
                note: '',
                caloriesBurned: calories,
              ),
            ],
          ),
        );
        final card = tester.widget<MfpCaloriesCard>(
          find.byType(MfpCaloriesCard),
        );
        expect(card.exerciseCalories, calories);
        expect(card.exerciseMinutes, 20);
        expect(card.target, 2000);
        expect(find.text('1.870'), findsOneWidget);
        expect(find.text(calories == null ? '20 phút' : '80'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('over target ring clamps and missing macros stay unknown', (
    tester,
  ) async {
    final missing = meal(10);
    await pumpApp(
      tester,
      dashboardNow: now,
      targetRepository: targets(),
      nutritionRepository: FakeNutritionRepository(
        meals: [
          MealLog(
            id: 'partial-home',
            type: missing.type,
            consumedAt: missing.consumedAt,
            items: missing.items,
            totals: const NutritionTotals(kcal: 2200, proteinKnown: false),
            source: missing.source,
            dateKey: missing.dateKey,
            timezoneOffsetMinutes: missing.timezoneOffsetMinutes,
          ),
        ],
      ),
    );
    expect(find.text('Calo vượt mục tiêu'), findsOneWidget);
    expect(
      tester
          .widget<CalorieMacroRing>(
            find.byKey(const ValueKey('home-calorie-ring')),
          )
          .data
          .progress,
      1,
    );
    final protein = tester.widget<Text>(
      find.byKey(const ValueKey('home-macro-value-0')),
    );
    expect(protein.textSpan!.toPlainText(), '—/100g');
    expect(tester.takeException(), isNull);
  });

  test('Home primary controls have readable contrast in both modes', () {
    for (final theme in [HomePalette.light, HomePalette.dark]) {
      final s = theme.colorScheme;
      for (final pair in [
        (s.primary, s.surface),
        (s.onPrimary, s.primary),
        (s.onSurfaceVariant, s.surface),
      ]) {
        final a = pair.$1.computeLuminance(), b = pair.$2.computeLuminance();
        final contrast = a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
        expect(contrast, greaterThanOrEqualTo(4.5));
      }
    }
  });

  testWidgets(
    'ring follows saved meal changes and removes colors after deletion',
    (tester) async {
      final key = GlobalKey();
      final repo = FakeNutritionRepository(meals: [meal(10)]);
      await pumpApp(
        tester,
        dashboardNow: now,
        initialThemeMode: ThemeMode.dark,
        captureKey: key,
        nutritionRepository: repo,
        targetRepository: targets(),
      );
      CalorieMacroRing current() => tester.widget<CalorieMacroRing>(
        find.byKey(const ValueKey('home-calorie-ring')),
      );
      final before = current().data.shares;
      expect(current().data.progress, closeTo(130 / 2000, .000001));
      await repo.updateMeal(
        uid: 'test-uid',
        mealId: 'home-fixture-10',
        draft: MealDraft(
          type: MealType.breakfast,
          consumedAt: DateTime(2026, 11, 10, 8),
          items: [
            MealItemSnapshot.fromCatalog(FakeNutritionRepository.rice, 500),
            MealItemSnapshot.fromCatalog(FakeNutritionRepository.egg, 250),
          ],
          source: MealSource.manual,
        ),
      );
      await tester.pumpAndSettle();
      expect(current().data.progress, closeTo((650 + 387.5) / 2000, .000001));
      expect(current().data.shares, isNot(before));
      await capture(tester, key, 'home-dark-recorded-macros-test-fixture');
      await repo.deleteMeal(uid: 'test-uid', mealId: 'home-fixture-10');
      await tester.pumpAndSettle();
      expect(current().data.progress, 0);
      expect(current().data.hasComposition, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('capture Home ${mode.name} without demo product data', (
      tester,
    ) async {
      final key = GlobalKey();
      await pumpApp(
        tester,
        dashboardNow: now,
        initialThemeMode: mode,
        captureKey: key,
        targetRepository: targets(),
      );
      await capture(tester, key, 'home-${mode.name}');
      final secondaryPage = find.byKey(const ValueKey('home-nutrient-page-1'));
      await tester.ensureVisible(secondaryPage);
      await tester.pumpAndSettle();
      await tester.tap(secondaryPage);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('home-secondary-nutrients')),
      );
      await tester.pumpAndSettle();
      await capture(tester, key, 'home-${mode.name}-secondary-nutrients');
      await tester.ensureVisible(
        find.byKey(const ValueKey('dashboard-quick-water')),
      );
      await tester.pumpAndSettle();
      await capture(tester, key, 'home-${mode.name}-meals-water');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('large weekday labels fit inside their touch targets', (
    tester,
  ) async {
    final key = GlobalKey();
    await pumpApp(
      tester,
      size: const Size(320, 844),
      textScale: 2,
      dashboardNow: now,
      initialThemeMode: ThemeMode.dark,
      captureKey: key,
      targetRepository: targets(),
    );
    final sunday = tester.getRect(
      find.byKey(const ValueKey('home-week-2026-11-15')),
    );
    final label = tester.getRect(find.text('CN'));
    expect(label.height, lessThan(sunday.height));
    expect(label.width, lessThan(sunday.width));
    await capture(tester, key, 'home-dark-large-text');
    expect(tester.takeException(), isNull);
  });
}
