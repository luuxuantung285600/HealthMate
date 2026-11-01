import 'support/fake_health_profile_repository.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/dashboard/presentation/widgets/mfp_calories_card.dart';
import 'package:healthmate/features/dashboard/presentation/widgets/mfp_meal_card.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/progress/presentation/progress_overview.dart';
import 'package:healthmate/features/data_export/presentation/journal_export_dialog.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/core/theme/app_colors.dart';
import 'support/test_app.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_nutrition_target_repository.dart';

final now = DateTime(2026, 10, 20, 9);
MealLog meal(String id, int day, double grams) => MealLog(
  id: id,
  type: MealType.breakfast,
  consumedAt: DateTime(2026, 10, day, 8),
  items: [MealItemSnapshot.fromCatalog(FakeNutritionRepository.rice, grams)],
  totals: FakeNutritionRepository.rice.forGrams(grams),
  source: MealSource.manual,
  dateKey: '2026-10-$day',
  timezoneOffsetMinutes: now.timeZoneOffset.inMinutes,
);
Future<void> visibleTap(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: .3);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/figma-v2/mfp/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

class PendingDay extends FakeNutritionRepository {
  PendingDay() : super(meals: [meal('today', 20, 200)]);
  final pending = Completer<List<MealLog>>();
  @override
  Stream<List<MealLog>> watchMealLogs(String uid, DateTime date) =>
      date.day == 19
      ? Stream.fromFuture(pending.future)
      : super.watchMealLogs(uid, date);
}

void main() {
  setUpAll(() async {
    final font = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(
        rootBundle.load('assets/fonts/be_vietnam_pro/BeVietnamPro-$weight.ttf'),
      );
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  test('theme text, buttons and metric labels have at least 4.5 contrast', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05));
    }

    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final s = theme.colorScheme;
      final m = theme.extension<AppMetricColors>()!;
      for (final pair in [
        (s.onSurface, s.surface),
        (s.onSurfaceVariant, s.surface),
        (s.onPrimary, s.primary),
        (m.onWaterContainer, m.waterContainer),
        (m.onMealContainer, m.mealContainer),
        (m.onActivityContainer, m.activityContainer),
        (m.onWeightContainer, m.weightContainer),
      ]) {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
    }
  });
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('Today and navigation fit ${mode.name} scale $scale', (
        tester,
      ) async {
        final key = GlobalKey();
        final targets = FakeNutritionTargetRepository()
          ..byUid['test-uid'] = {
            '2026-10-19': const NutritionTarget(
              effectiveFromDateKey: '2026-10-19',
              kcalTarget: 2000,
              proteinGTarget: 100,
              carbsGTarget: 250,
              fatGTarget: 60,
            ),
          };
        await pumpApp(
          tester,
          size: const Size(390, 844),
          textScale: scale,
          initialThemeMode: mode,
          dashboardNow: now,
          captureKey: key,
          targetRepository: targets,
          profileRepository: FakeHealthProfileRepository(
            profile: FakeHealthProfileRepository.testProfile,
            metrics: [
              BodyMetric(
                id: 'qa-weight-a',
                weightKg: 68.5,
                measuredAt: DateTime(2026, 10, 19, 7),
                note: '',
                createdAt: now,
                updatedAt: now,
              ),
              BodyMetric(
                id: 'qa-weight-b',
                weightKg: 68.3,
                measuredAt: DateTime(2026, 10, 20, 7),
                note: '',
                createdAt: now,
                updatedAt: now,
              ),
            ],
          ),
          nutritionRepository: FakeNutritionRepository(
            meals: [meal('today', 20, 100), meal('previous', 19, 200)],
          ),
        );
        expect(
          tester.widget<MfpCaloriesCard>(find.byType(MfpCaloriesCard)).consumed,
          130,
        );
        expect(find.byType(MfpMealCard), findsNWidgets(4));
        expect(find.text('Hôm nay'), findsNWidgets(2));
        expect(find.text('Go Premium'), findsNothing);
        expect(find.text('Còn 2.420 kcal'), findsNothing);
        await capture(tester, key, 'today-${mode.name}-$scale');
        await Scrollable.ensureVisible(
          tester.element(find.byKey(const ValueKey('today-meal-breakfast'))),
          alignment: .1,
        );
        await tester.pumpAndSettle();
        await capture(tester, key, 'meals-${mode.name}-$scale');
        await tester.tap(find.byKey(const ValueKey('nav-progress')));
        await tester.pumpAndSettle();
        expect(find.byType(ProgressOverview), findsOneWidget);
        await capture(tester, key, 'progress-${mode.name}-$scale');
        await Scrollable.ensureVisible(
          tester.element(
            find.byKey(const ValueKey('progress-weight-overview')),
          ),
          alignment: .2,
        );
        await tester.pumpAndSettle();
        await capture(tester, key, 'weight-${mode.name}-$scale');
        await visibleTap(tester, find.byKey(const ValueKey('progress-tab-3')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('progress-trend-carbs')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('progress-trend-kcal')), findsNothing);
        await capture(tester, key, 'macros-${mode.name}-$scale');
        await tester.tap(find.byKey(const ValueKey('quick-add-menu')));
        await tester.pumpAndSettle();
        expect(find.byType(MealFormDialog), findsOneWidget);
        expect(find.byKey(const ValueKey('save-meal')), findsOneWidget);
        await capture(tester, key, 'actions-${mode.name}-$scale');
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('empty day has zero recorded calories with no invented target', (
    tester,
  ) async {
    await pumpApp(tester, dashboardNow: now);
    final card = tester.widget<MfpCaloriesCard>(find.byType(MfpCaloriesCard));
    expect(card.consumed, 0);
    expect(card.target, isNull);
    expect(find.text('Chưa ghi món'), findsNWidgets(4));
    expect(find.textContaining('Chưa đặt mục tiêu'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('date switch and late response never replace current day', (
    tester,
  ) async {
    final repo = PendingDay();
    await pumpApp(tester, dashboardNow: now, nutritionRepository: repo);
    expect(
      tester.widget<MfpCaloriesCard>(find.byType(MfpCaloriesCard)).consumed,
      260,
    );
    await selectHomeDate(tester, DateTime(2026, 10, 19), settle: false);
    await tester.pump();
    await tester.pump();
    expect(
      tester.widget<MfpCaloriesCard>(find.byType(MfpCaloriesCard)).consumed,
      isNull,
    );
    await selectHomeDate(tester, DateTime(2026, 10, 20), settle: false);
    await tester.pumpAndSettle();
    repo.pending.complete([meal('late', 19, 300)]);
    await tester.pumpAndSettle();
    expect(
      tester.widget<MfpCaloriesCard>(find.byType(MfpCaloriesCard)).consumed,
      260,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('target loading and read errors do not mean no target', (
    tester,
  ) async {
    final targets = FakeNutritionTargetRepository()
      ..pendingRead = Completer<void>();
    await pumpApp(
      tester,
      dashboardNow: now,
      targetRepository: targets,
      settle: false,
    );
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Chưa đặt mục tiêu'), findsNothing);
    targets.failRead = true;
    targets.pendingRead!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Chưa tải được mục tiêu.'), findsOneWidget);
    expect(find.textContaining('Chưa đặt mục tiêu'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'remaining uses saved target and never adds estimated exercise calories',
    (tester) async {
      final targets = FakeNutritionTargetRepository();
      targets.byUid['test-uid'] = {
        '2026-10-20': const NutritionTarget(
          effectiveFromDateKey: '2026-10-20',
          kcalTarget: 2000,
        ),
      };
      await pumpApp(
        tester,
        dashboardNow: now,
        targetRepository: targets,
        nutritionRepository: FakeNutritionRepository(
          meals: [meal('today', 20, 100)],
        ),
      );
      expect(find.text('1.870'), findsOneWidget);
      expect(find.text('kcal còn lại'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('reuse yesterday opens confirmation and writes once after save', (
    tester,
  ) async {
    final repo = FakeNutritionRepository(meals: [meal('yesterday', 19, 100)]);
    await pumpApp(tester, dashboardNow: now, nutritionRepository: repo);
    await visibleTap(tester, find.byTooltip('Tùy chọn Bữa sáng'));
    await visibleTap(tester, find.textContaining('Ghi lại bữa hôm trước:'));
    expect(find.byType(MealFormDialog), findsOneWidget);
    expect(repo.addCalls, 0);
    final form = tester.widget<MealFormDialog>(find.byType(MealFormDialog));
    expect(form.initialType, MealType.breakfast);
    expect(form.initialItems.single.nutrition.kcal, 130);
    await visibleTap(tester, find.byKey(const ValueKey('save-meal')));
    expect(repo.addCalls, 1);
    expect(
      tester.widget<MfpCaloriesCard>(find.byType(MfpCaloriesCard)).consumed,
      130,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'progress tabs share one weekly load, export is a working action',
    (tester) async {
      final repo = FakeNutritionRepository(meals: [meal('today', 20, 100)]);
      await pumpApp(tester, dashboardNow: now, nutritionRepository: repo);
      await tester.tap(find.byKey(const ValueKey('nav-progress')));
      await tester.pumpAndSettle();
      expect(repo.rangeCalls, 1);
      for (final index in [3, 2, 0]) {
        await visibleTap(tester, find.byKey(ValueKey('progress-tab-$index')));
      }
      expect(repo.rangeCalls, 1);
      await visibleTap(tester, find.byKey(const ValueKey('progress-export')));
      await tester.pumpAndSettle();
      expect(find.byType(JournalExportDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('weekly error stays an error until explicit successful retry', (
    tester,
  ) async {
    final repo = FakeNutritionRepository()
      ..rangeError = StateError('test range failure');
    await pumpApp(tester, dashboardNow: now, nutritionRepository: repo);
    await tester.tap(find.byKey(const ValueKey('nav-progress')));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressOverview), findsNothing);
    expect(
      find.byKey(const ValueKey('retry-progress-overview')),
      findsOneWidget,
    );
    repo.rangeError = null;
    await visibleTap(
      tester,
      find.byKey(const ValueKey('retry-progress-overview')),
    );
    expect(find.byType(ProgressOverview), findsOneWidget);
    expect(repo.rangeCalls, 2);
    expect(tester.takeException(), isNull);
  });
}
