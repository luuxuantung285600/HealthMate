import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/journal/providers/journal_date_provider.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/dashboard/presentation/widgets/mfp_calories_card.dart';

import 'support/fake_nutrition_repository.dart';
import 'support/test_app.dart';

void main() {
  final today = DateTime(2026, 10, 20, 12);
  final earlier = DateTime(2026, 10, 19);
  for (final width in [320.0, 390.0, 412.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets(
          'Home and Diary keep meal action and dates readable $width/$scale/$mode',
          (tester) async {
            final c = await pumpApp(
              tester,
              size: Size(width, 844),
              textScale: scale,
              initialThemeMode: mode,
              dashboardNow: today,
            );
            final homeAdd = find.byKey(const ValueKey('today-add-meal'));
            expect(
              find.byKey(const ValueKey('today-recorded-energy')),
              findsOneWidget,
            );
            expect(homeAdd, findsOneWidget);
            expect(
              find.byKey(const ValueKey('today-date-picker')),
              findsOneWidget,
            );
            if (width == 390 && scale == 1) {
              // The main action and actual energy summary are visible together
              // without scroll, including with the shell's navigation present.
              expect(homeAdd.hitTestable(), findsOneWidget);
              expect(
                find
                    .byKey(const ValueKey('today-recorded-energy'))
                    .hitTestable(),
                findsOneWidget,
              );
            }
            expect(tester.getSize(homeAdd).height, greaterThanOrEqualTo(48));
            expect(tester.takeException(), isNull);
            c.read(journalDateProvider.notifier).select(earlier);
            c.read(appRouterProvider).go(AppRoutes.journal);
            await tester.pumpAndSettle();
            final diaryAdd = find.byKey(const ValueKey('journal-add-meal'));
            expect(find.text('Ghi cho ngày 19/10/2026'), findsOneWidget);
            expect(diaryAdd, findsOneWidget);
            if (width == 390 && scale == 1) {
              expect(diaryAdd.hitTestable(), findsOneWidget);
              expect(
                find
                    .byKey(const ValueKey('nutrition-daily-totals'))
                    .hitTestable(),
                findsOneWidget,
              );
            }
            expect(tester.getSize(diaryAdd).height, greaterThanOrEqualTo(48));
            final lunchAdd = find.byKey(const ValueKey('add-meal-lunch'));
            await tester.ensureVisible(lunchAdd);
            await tester.pumpAndSettle();
            expect(find.byTooltip('Thêm bữa trưa'), findsOneWidget);
            expect(tester.getSize(lunchAdd).height, greaterThanOrEqualTo(48));
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'Home meal action keeps selected date through the confirmed repository save',
    (tester) async {
      final repo = FakeNutritionRepository();
      final c = await pumpApp(
        tester,
        nutritionRepository: repo,
        dashboardNow: today,
      );
      await selectHomeDate(tester, earlier);
      expect(c.read(journalDateProvider), earlier);
      expect(find.text('Ghi cho ngày 19/10/2026'), findsOneWidget);
      final add = find.byKey(const ValueKey('today-add-meal'));
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      final form = tester.widget<MealFormDialog>(find.byType(MealFormDialog));
      expect(DateUtils.dateOnly(form.initialConsumedAt!), earlier);
      // Select real catalog nutrition and confirm grams; no direct repository
      // injection or synthetic product totals bypass the form's save path.
      final choose = find.byTooltip('Thêm Cơm trắng chín');
      await tester.ensureVisible(choose.first);
      await tester.pumpAndSettle();
      await tester.tap(choose.first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('meal-grams')), '100');
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-meal')));
      await tester.pumpAndSettle();
      expect(repo.addCalls, 1);
      expect(repo.meals.single.dateKey, '2026-10-19');
      expect(repo.meals.single.totals.kcal, 130);
      expect(repo.meals.single.items.single.grams, 100);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty Diary meal action keeps type and date; completion stays secondary',
    (tester) async {
      final c = await pumpApp(tester, dashboardNow: today);
      c.read(journalDateProvider.notifier).select(earlier);
      c.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      expect(
        tester.widget(find.byKey(const ValueKey('open-day-review'))),
        isA<TextButton>(),
      );
      final add = find.byKey(const ValueKey('add-meal-lunch'));
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      final form = tester.widget<MealFormDialog>(find.byType(MealFormDialog));
      expect(form.initialType, MealType.lunch);
      expect(DateUtils.dateOnly(form.initialConsumedAt!), earlier);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Home read failure never turns an unverified total into zero', (
    tester,
  ) async {
    final repo = FakeNutritionRepository()
      ..dayError = StateError('Unavailable');
    await pumpApp(tester, nutritionRepository: repo, dashboardNow: today);
    expect(
      tester.widget<MfpCaloriesCard>(find.byType(MfpCaloriesCard)).consumed,
      isNull,
    );
    expect(find.byKey(const ValueKey('today-add-meal')), findsOneWidget);
    expect(find.text('Thử lại'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
