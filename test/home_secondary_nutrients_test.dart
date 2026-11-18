import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/home_palette.dart';
import 'package:healthmate/features/dashboard/presentation/widgets/home_nutrient_panels.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/nutrition_targets/models/personal_nutrition_plan.dart';
import 'package:healthmate/features/nutrition_targets/presentation/nutrition_target_form.dart';
import 'support/load_icon_font.dart';
import 'support/test_app.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_nutrition_target_repository.dart';

const totals = NutritionTotals(
  kcal: 400,
  proteinG: 20,
  carbsG: 60,
  fatG: 10,
  fiberG: 6,
  fiberKnown: true,
  extraNutrients: {'sodium': 800, 'sugar': 24},
);
const target = NutritionTarget(
  effectiveFromDateKey: '2026-11-10',
  kcalTarget: 2000,
  saltGLimit: 5,
  sugarGLimit: 50,
  fiberGTarget: 25,
);

String amount(WidgetTester tester, int index) => tester
    .widget<Text>(find.byKey(ValueKey('home-secondary-value-$index')))
    .textSpan!
    .toPlainText();

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
  });
  test(
    'salt conversion, portion snapshots and missing nutrients never invent zero',
    () {
      expect(totals.saltEquivalentG, 2);
      expect(totals.scale(.5).saltEquivalentG, 1);
      expect(totals.scale(.5).totalSugarG, 12);
      final complete = totals + totals;
      expect(complete.saltEquivalentG, 4);
      expect(complete.totalSugarG, 48);
      expect(complete.fiberKnown, isTrue);
      final partial = totals + const NutritionTotals(kcal: 100);
      expect(partial.saltEquivalentG, isNull);
      expect(partial.totalSugarG, isNull);
      expect(partial.fiberKnown, isFalse);
      const knownZero = NutritionTotals(
        fiberKnown: true,
        extraNutrients: {'sodium': 0, 'sugar': 0},
      );
      expect(knownZero.saltEquivalentG, 0);
      expect(knownZero.totalSugarG, 0);
      final snapshot = MealItemSnapshot(
        foodId: 'secondary-fixture',
        name: 'Fixture',
        grams: 100,
        nutrition: totals,
        sourceLabel: 'Fixture',
        isEstimated: true,
      );
      final restored = MealItemSnapshot.fromData(snapshot.toData());
      expect(restored.nutrition.saltEquivalentG, 2);
      expect(restored.nutrition.totalSugarG, 24);
    },
  );
  test(
    'optional markers validate independently and are included in conflict comparisons',
    () {
      expect(target.validate(), isNull);
      expect(
        const NutritionTarget(
          effectiveFromDateKey: '2026-11-10',
          kcalTarget: 1800,
          saltGLimit: 0,
        ).validate(),
        isNull,
      );
      for (final v in [-1.0, double.nan, double.infinity, 501.0]) {
        expect(
          NutritionTarget(
            effectiveFromDateKey: '2026-11-10',
            kcalTarget: 1800,
            sugarGLimit: v,
          ).validate(),
          isNotNull,
        );
      }
      const recalculated = NutritionTarget(
        effectiveFromDateKey: '2026-11-10',
        kcalTarget: 2200,
      );
      final retained = recalculated.withMarkersFrom(target);
      expect(retained.kcalTarget, 2200);
      expect(retained.saltGLimit, 5);
      expect(retained.sugarGLimit, 50);
      expect(retained.fiberGTarget, 25);
      expect(sameNutritionTarget(recalculated, retained), isFalse);
    },
  );
  testWidgets(
    'swipe reveals the second group, can return, and unknown differs from known zero',
    (tester) async {
      Future<void> show(
        NutritionTotals? value, {
        NutritionTarget? goal = target,
      }) => tester.pumpWidget(
        MaterialApp(
          theme: HomePalette.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeNutrientPanels(totals: value, target: goal),
            ),
          ),
        ),
      );
      await show(totals);
      await tester.drag(
        find.byKey(const ValueKey('home-macro-panel')),
        const Offset(-220, 0),
      );
      await tester.pumpAndSettle();
      expect(amount(tester, 0), '2/5g');
      expect(amount(tester, 1), '24/50g');
      expect(amount(tester, 2), '6/25g');
      await tester.drag(
        find.byKey(const ValueKey('home-secondary-nutrients')),
        const Offset(220, 0),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-macro-panel')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('home-nutrient-page-1')));
      await tester.pumpAndSettle();
      await show(const NutritionTotals());
      await tester.pumpAndSettle();
      expect(amount(tester, 0), '—/5g');
      expect(find.text('Chưa đủ dữ liệu'), findsNWidgets(3));
      await show(
        const NutritionTotals(
          fiberKnown: true,
          extraNutrients: {'sodium': 0, 'sugar': 0},
        ),
        goal: null,
      );
      await tester.pumpAndSettle();
      expect(amount(tester, 0), '0 g');
      expect(find.text('Chưa đặt mốc'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Home uses diary snapshots and saves optional markers through the existing form',
    (tester) async {
      final now = DateTime(2026, 11, 10, 12);
      final item = MealItemSnapshot(
        foodId: 'fixture',
        name: 'Món fixture',
        grams: 100,
        nutrition: totals,
        sourceLabel: 'Fixture',
        isEstimated: true,
      );
      final repo = FakeNutritionRepository(
        meals: [
          MealLog(
            id: 'fixture',
            type: MealType.lunch,
            consumedAt: now,
            items: [item],
            totals: totals,
            source: MealSource.manual,
            dateKey: '2026-11-10',
          ),
        ],
      );
      final targets = FakeNutritionTargetRepository()
        ..byUid['test-uid'] = {'2026-11-10': target};
      await pumpApp(
        tester,
        dashboardNow: now,
        nutritionRepository: repo,
        targetRepository: targets,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('home-nutrient-page-1')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('home-nutrient-page-1')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('home-nutrient-page-1')));
      await tester.pumpAndSettle();
      expect(amount(tester, 0), '2/5g');
      await tester.ensureVisible(
        find.byKey(const ValueKey('home-edit-secondary-targets')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('home-edit-secondary-targets')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('home-edit-secondary-targets')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NutritionTargetForm), findsOneWidget);
      for (final entry in [
        ('target-salt', '4,5'),
        ('target-sugar', ''),
        ('target-fiber', '30'),
      ]) {
        final field = find.byKey(ValueKey(entry.$1));
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.enterText(field, entry.$2);
      }
      final save = find.byKey(const ValueKey('save-target'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(save.hitTestable(), findsOneWidget);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final saved = targets.byUid['test-uid']!['2026-11-10']!;
      expect(saved.saltGLimit, 4.5);
      expect(saved.sugarGLimit, isNull);
      expect(saved.fiberGTarget, 30);
      expect(tester.takeException(), isNull);
    },
  );

  for (final dark in [false, true]) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'secondary nutrients fit width=$width scale=$scale dark=$dark',
          (tester) async {
            tester.view.physicalSize = Size(width, 1000);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final key = GlobalKey();
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? HomePalette.dark : HomePalette.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: RepaintBoundary(
                    key: key,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: HomeNutrientPanels(
                        totals: totals,
                        target: target,
                        onEditTarget: () {},
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.tap(
              find.byKey(const ValueKey('home-nutrient-page-1')),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (width == 390 && scale == 1) {
              await tester.runAsync(() async {
                final picture =
                    await (key.currentContext!.findRenderObject()!
                            as RenderRepaintBoundary)
                        .toImage(pixelRatio: 2);
                final bytes = await picture.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final file = File(
                  'build/secondary-nutrients/${dark ? 'dark' : 'light'}.png',
                );
                await file.parent.create(recursive: true);
                await file.writeAsBytes(bytes!.buffer.asUint8List());
                picture.dispose();
              });
            }
          },
        );
      }
    }
  }
}
