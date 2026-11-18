import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/nutrition_targets/models/energy_estimate.dart';
import 'package:healthmate/features/nutrition_targets/presentation/energy_estimate_dialog.dart';
import 'package:healthmate/features/nutrition_targets/presentation/nutrition_target_form.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'support/test_app.dart';
import 'support/fake_nutrition_target_repository.dart';

Finder verticalScroll() => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .last;

Future<void> fill(WidgetTester t) async {
  Future<void> show(Finder f) async {
    await t.scrollUntilVisible(f, 180, scrollable: verticalScroll());
    await t.ensureVisible(f);
    await t.pumpAndSettle();
  }

  final eligible = find.byKey(const ValueKey('estimate-eligible'));
  await show(eligible);
  await t.tap(eligible);
  await t.pumpAndSettle();
  for (final pair in [('estimate-age', '25'), ('estimate-weight', '70')]) {
    final field = find.byKey(ValueKey(pair.$1));
    await show(field);
    await t.enterText(field, pair.$2);
  }
  for (final pair in [
    ('estimate-sex', 'Nam · hệ số theo nghiên cứu'),
    ('estimate-activity', 'Ít vận động / nhẹ'),
  ]) {
    final f = find.byKey(ValueKey(pair.$1));
    await show(f);
    await t.tap(f);
    await t.pumpAndSettle();
    await t.tap(find.text(pair.$2).last);
    await t.pumpAndSettle();
  }
  final calculate = find.byKey(const ValueKey('calculate-estimate'));
  await show(calculate);
  await t.tap(calculate);
  await t.pumpAndSettle();
}

void main() {
  test('FAO coefficients and adult age bands use kg and exact example PAL', () {
    for (final sex in FormulaSex.values) {
      for (final age in [18, 29, 30, 59]) {
        for (final activity in HabitualActivity.values) {
          final r = EnergyEstimateInput(
            age: age,
            weightKg: 70,
            sex: sex,
            activity: activity,
            eligible: true,
          ).calculate();
          final expected = sex == FormulaSex.male
              ? (age < 30 ? 1746.19 : 1676.14)
              : (age < 30 ? 1523.86 : 1414.42);
          expect(r.basalKcal, closeTo(expected, .00001));
          expect(
            r.maintenanceKcal,
            closeTo(expected * activity.factor, .00001),
          );
          expect(r.roundedKcal % 10, 0);
        }
      }
    }
  });
  test(
    'missing, declined, nonfinite, unit and scope limits cannot produce a target',
    () {
      for (final input in [
        const EnergyEstimateInput(),
        for (final age in [null, 17, 60, 120])
          EnergyEstimateInput(
            age: age,
            weightKg: 70,
            sex: FormulaSex.male,
            activity: HabitualActivity.light,
            eligible: true,
          ),
        for (final kg in [null, -1.0, 19.9, 300.1, double.nan, double.infinity])
          EnergyEstimateInput(
            age: 25,
            weightKg: kg,
            sex: FormulaSex.male,
            activity: HabitualActivity.light,
            eligible: true,
          ),
        const EnergyEstimateInput(
          age: 25,
          weightKg: 70,
          activity: HabitualActivity.light,
          eligible: true,
        ),
        const EnergyEstimateInput(
          age: 25,
          weightKg: 70,
          sex: FormulaSex.male,
          eligible: true,
        ),
      ]) {
        expect(input.validate(), isNotNull);
        expect(input.calculate, throwsFormatException);
      }
      for (final kg in [20.0, 300.0]) {
        expect(
          EnergyEstimateInput(
            age: 25,
            weightKg: kg,
            sex: FormulaSex.female,
            activity: HabitualActivity.moderate,
            eligible: true,
          ).validate(),
          isNull,
        );
      }
    },
  );
  testWidgets(
    'optional estimate is not saved before review; editable confirmed target uses current day',
    (t) async {
      final repo = FakeNutritionTargetRepository();
      final c = await pumpApp(
        t,
        targetRepository: repo,
        dashboardNow: DateTime(2026, 10, 19),
      );
      c.read(appRouterProvider).go(AppRoutes.profile);
      await t.pumpAndSettle();
      final edit = find.byKey(
        const ValueKey('edit-nutrition-target-2026-10-19'),
      );
      await t.ensureVisible(edit);
      await t.pumpAndSettle();
      await t.tap(edit);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('open-energy-estimate')));
      await t.pumpAndSettle();
      await fill(t);
      expect(repo.saveCalls, 0);
      final accept = find.byKey(const ValueKey('accept-estimate'));
      await t.scrollUntilVisible(accept, 180, scrollable: verticalScroll());
      await t.pumpAndSettle();
      expect(accept.hitTestable(), findsOneWidget);
      await t.tap(accept);
      await t.pumpAndSettle();
      expect(find.byType(NutritionTargetForm), findsOneWidget);
      expect(repo.saveCalls, 0);
      final kcal = find.byKey(const ValueKey('target-kcal'));
      await t.ensureVisible(kcal);
      expect(t.widget<TextField>(kcal).controller!.text, '2670');
      await t.enterText(kcal, '2600');
      final save = find.byKey(const ValueKey('save-target'));
      await t.ensureVisible(save);
      await t.pumpAndSettle();
      expect(save.hitTestable(), findsOneWidget);
      await t.tap(save);
      await t.pumpAndSettle();
      expect(repo.byUid['test-uid']!['2026-10-19']!.kcalTarget, 2600);
    },
  );
  for (final (width, scale) in [(360.0, 1.0), (390.0, 1.5), (412.0, 2.0)]) {
    for (final mode in Brightness.values) {
      testWidgets(
        'estimate usable $width $scale $mode and changes invalidate result',
        (t) async {
          t.view.physicalSize = Size(width, 844);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          await t.pumpWidget(
            MaterialApp(
              theme: ThemeData(brightness: mode),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const EnergyEstimateDialog(),
            ),
          );
          await fill(t);
          expect(find.byKey(const ValueKey('estimate-result')), findsOneWidget);
          final age = find.byKey(const ValueKey('estimate-age'));
          await t.scrollUntilVisible(age, -200, scrollable: verticalScroll());
          await t.enterText(age, '60');
          await t.pumpAndSettle();
          expect(find.byKey(const ValueKey('accept-estimate')), findsNothing);
          final calculate = find.byKey(const ValueKey('calculate-estimate'));
          await t.scrollUntilVisible(
            calculate,
            200,
            scrollable: verticalScroll(),
          );
          await t.tap(calculate);
          await t.pumpAndSettle();
          expect(find.byKey(const ValueKey('estimate-error')), findsOneWidget);
          expect(find.byKey(const ValueKey('accept-estimate')), findsNothing);
          expect(t.takeException(), isNull);
        },
      );
    }
  }
}
