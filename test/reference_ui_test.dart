import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/profile/models/user_profile.dart';
import 'package:healthmate/features/profile/models/health_goal.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'package:healthmate/features/water/models/water_log.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_nutrition_target_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/fake_day_review_repository.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/journal/providers/journal_date_provider.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/wellness/models/wellness_models.dart';
import 'support/test_app.dart';

Future<void> captureReference(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  await tester.runAsync(() async {
    for (final art in [
      'activity',
      'chat',
      'flag',
      'flame',
      'food',
      'heart',
      'moon',
      'scan',
      'steps',
      'sun',
      'water',
      'weight',
    ]) {
      await precacheImage(
        AssetImage('assets/design/$art.png'),
        key.currentContext!,
      );
    }
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final picture = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/figma-v2/screens/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    picture.dispose();
  });
}

void main() {
  final now = DateTime(2026, 10, 27, 9);
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

  testWidgets('Figma comparison with explicitly test-only recorded fixtures', (
    tester,
  ) async {
    final time = DateTime(2026, 10, 27, 19);
    final key = GlobalKey();
    // Native system insets match the 390 x 844 reference. No fake OS UI is drawn.
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 23);
    tester.view.viewPadding = const FakeViewPadding(top: 44, bottom: 23);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    MealLog fixtureMeal(
      String id,
      DateTime date,
      MealType type,
      String name,
      double kcal, {
      double carbs = 140,
      double protein = 61,
      double fat = 40,
    }) {
      final fraction = kcal / 1160;
      final totals = NutritionTotals(
        kcal: kcal,
        carbsG: carbs * fraction,
        proteinG: protein * fraction,
        fatG: fat * fraction,
      );
      return MealLog(
        id: id,
        type: type,
        consumedAt: date,
        dateKey: localDateKey(date),
        source: MealSource.manual,
        items: [
          MealItemSnapshot(
            foodId: id,
            name: name,
            grams: 100,
            nutrition: totals,
            sourceLabel: 'DỮ LIỆU KIỂM THỬ FIGMA',
            isEstimated: true,
          ),
        ],
        totals: totals,
      );
    }

    final meals = [
      fixtureMeal(
        'breakfast',
        DateTime(2026, 10, 27, 8),
        MealType.breakfast,
        'Bánh mì trứng',
        320,
      ),
      fixtureMeal(
        'lunch',
        DateTime(2026, 10, 27, 12),
        MealType.lunch,
        'Cơm gà rau củ',
        580,
      ),
      fixtureMeal(
        'snack',
        DateTime(2026, 10, 27, 15),
        MealType.snack,
        'Sữa chua',
        260,
      ),
      for (final entry in [
        1600.0,
        1680.0,
        1550.0,
        1720.0,
        1620.0,
        1740.0,
        1878.0,
      ].indexed)
        fixtureMeal(
          'history-${entry.$1}',
          DateTime(2026, 10, 19 + entry.$1, 12),
          MealType.lunch,
          'Nhật ký kiểm thử',
          entry.$2,
        ),
    ];
    final reviews = FakeDayReviewRepository();
    for (var day = 19; day <= 23; day++) {
      await reviews.save(
        'test-uid',
        DateTime(2026, 10, day),
        meals.where((m) => m.consumedAt.day == day).toList(),
        complete: true,
      );
    }
    final targets = FakeNutritionTargetRepository()
      ..byUid['test-uid'] = {
        '2026-10-01': const NutritionTarget(
          effectiveFromDateKey: '2026-10-01',
          kcalTarget: 1800,
          carbsGTarget: 225,
          proteinGTarget: 90,
          fatGTarget: 60,
        ),
      };
    final container = await pumpApp(
      tester,
      dashboardNow: time,
      captureKey: key,
      initialThemeMode: ThemeMode.light,
      featureFlags: const AppFeatureFlags(
        foodScannerEnabled: true,
        chatbotEnabled: true,
      ),
      targetRepository: targets,
      dayReviewRepository: reviews,
      nutritionRepository: FakeNutritionRepository(meals: meals),
      profileRepository: FakeHealthProfileRepository(
        profile: UserProfile(
          uid: 'test-uid',
          displayName: 'Tùng',
          email: 'ban@example.com',
          heightCm: 170,
          birthDate: DateTime(2000, 1, 15),
          healthGoal: HealthGoal.loseWeight,
          targetWeightKg: 66,
          onboardingCompletedAt: DateTime(2026, 1, 1),
          createdAt: time,
          updatedAt: time,
          schemaVersion: 2,
        ),
        metrics: [
          for (final entry in [
            70.0,
            69.4,
            69.7,
            68.8,
            68.4,
            68.2,
            68.0,
          ].indexed)
            BodyMetric(
              id: 'metric-${entry.$1}',
              weightKg: entry.$2,
              measuredAt: DateTime(2026, 10, 21 + entry.$1, 7),
              note: '',
              createdAt: time,
              updatedAt: time,
            ),
        ],
      ),
      waterRepository: FakeWaterRepository(
        logs: [
          for (var i = 0; i < 5; i++)
            WaterLog(
              id: 'water-$i',
              amountMl: 250,
              consumedAt: DateTime(2026, 10, 27, 8 + i * 2),
              dateKey: '2026-10-27',
              timezoneOffsetMinutes: 420,
            ),
        ],
      ),
      stepDays: [
        for (final entry in [4872, 5234, 6020, 3100, 5400, 6320, 4500].indexed)
          StepDay(
            localDateKey(DateTime(2026, 10, 27 - entry.$1)),
            entry.$2,
            DateTime(2026, 10, 27 - entry.$1, 8),
            DateTime(2026, 10, 27 - entry.$1, 18),
          ),
      ],
      sleepLogs: [
        for (var i = 0; i < 7; i++)
          SleepLog(
            id: 'sleep-$i',
            start: DateTime(2026, 10, 26 - i, 23),
            end: DateTime(2026, 10, 27 - i, 6, 20),
            source: 'manual',
          ),
      ],
    );
    await captureReference(tester, key, 'today-populated');
    expect(find.text('1.160 đã ăn'), findsOneWidget);
    expect(find.byTooltip('Chụp món ăn'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-journal')));
    await captureReference(tester, key, 'journal-populated');
    expect(find.byKey(const ValueKey('add-meal-breakfast')), findsOneWidget);
    await openWellnessFromShell(tester);
    await captureReference(tester, key, 'habits-populated');
    expect(find.text('4.872'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await captureReference(tester, key, 'profile-populated');
    expect(find.text('68'), findsWidgets);
    container.read(appRouterProvider).go(AppRoutes.progress);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('previous-week')));
    await captureReference(tester, key, 'reports-populated');
    expect(find.text('1.684 kcal / ngày có dữ liệu'), findsOneWidget);
    expect(find.text('5 / 7 ngày xác nhận đủ bữa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final layout in [(320.0, 2.0), (390.0, 1.0), (412.0, 1.5)]) {
      testWidgets('reference navigation and real empty states $mode $layout', (
        tester,
      ) async {
        final key = GlobalKey();
        await pumpApp(
          tester,
          size: Size(layout.$1, 844),
          textScale: layout.$2,
          initialThemeMode: mode,
          dashboardNow: now,
          captureKey: key,
        );
        expect(find.byKey(const ValueKey('nav-profile')), findsOneWidget);
        expect(find.text('Chưa ghi món'), findsNWidgets(4));
        if (layout.$1 == 390) {
          await captureReference(tester, key, 'today-${mode.name}');
        }
        await openWellnessFromShell(tester);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('wellness-hub')), findsOneWidget);
        expect(find.text('Chưa có bước đã đồng bộ hôm nay'), findsOneWidget);
        if (layout.$1 == 390) {
          await captureReference(tester, key, 'habits-${mode.name}');
        }
        await tester.tap(find.byKey(const ValueKey('wellness-back')));
        await tester.pumpAndSettle();
        expect(find.text('Không gian cá nhân'), findsOneWidget);
        if (layout.$1 == 390) {
          await captureReference(tester, key, 'profile-${mode.name}');
        }
        await tester.tap(find.byKey(const ValueKey('nav-journal')));
        await tester.pumpAndSettle();
        if (layout.$1 == 390) {
          await captureReference(tester, key, 'journal-${mode.name}');
        }
        await tester.tap(find.byKey(const ValueKey('nav-progress')));
        await tester.pumpAndSettle();
        if (layout.$1 == 390) {
          await captureReference(tester, key, 'reports-${mode.name}');
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'habit summaries use synchronized steps and recorded sleep, never a demo',
    (tester) async {
      await pumpApp(
        tester,
        dashboardNow: now,
        stepDays: [
          StepDay(
            '2026-10-27',
            4872,
            now.subtract(const Duration(hours: 2)),
            now,
          ),
        ],
        sleepLogs: [
          SleepLog(
            id: 'recorded',
            start: DateTime(2026, 10, 26, 23),
            end: DateTime(2026, 10, 27, 6, 20),
            source: 'manual',
          ),
        ],
      );
      await openWellnessFromShell(tester);
      await tester.pumpAndSettle();
      expect(find.text('4.872'), findsOneWidget);
      expect(find.text('7g 20p'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('hub-steps')));
      await tester.pumpAndSettle();
      expect(find.text('Bộ đếm bước chân'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('wellness-hub')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'journal summary and shell plus preserve the same historic date',
    (tester) async {
      final container = await pumpApp(tester, dashboardNow: now);
      final historical = DateTime(2026, 10, 20);
      container.read(journalDateProvider.notifier).select(historical);
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      // Use the accessible summary card rather than the long log section.
      final breakfast = find.byKey(const ValueKey('add-meal-breakfast'));
      await tester.ensureVisible(breakfast);
      await tester.tap(breakfast);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MealFormDialog>(find.byType(MealFormDialog))
            .initialConsumedAt
            ?.day,
        20,
      );
      Navigator.of(tester.element(find.byType(MealFormDialog))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('quick-add-menu')));
      await tester.pumpAndSettle();
      expect(container.read(journalDateProvider), historical);
      expect(
        tester
            .widget<MealFormDialog>(find.byType(MealFormDialog))
            .initialConsumedAt
            ?.day,
        historical.day,
      );
    },
  );
}
