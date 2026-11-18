import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/profile/models/health_goal.dart';

import 'personal_nutrition_plan_test.dart'
    show input, existingUser, press, choose, calculate, today;
import 'support/fake_nutrition_target_repository.dart';
import 'support/load_icon_font.dart';

Future<void> openBlockedGainPlan(WidgetTester tester) async {
  await press(tester, 'open-personal-nutrition');
  await tester.enterText(
    find.byKey(const ValueKey('nutrition-plan-height')),
    '175',
  );
  await tester.enterText(
    find.byKey(const ValueKey('nutrition-plan-weight')),
    '55',
  );
  await choose(
    tester,
    'nutrition-plan-goal',
    HealthGoal.gainWeightOrMuscle.label,
  );
  await tester.enterText(
    find.byKey(const ValueKey('nutrition-plan-target-weight')),
    '64',
  );
  await calculate(tester, checkResult: false);
}

void main() {
  setUpAll(loadIconFont);

  test('underweight gain plan explains current BMI, not target weight', () {
    final blocked = input(
      height: 175,
      weight: 55,
      goal: HealthGoal.gainWeightOrMuscle,
      target: 64,
    );
    final reason = blocked.validate()!;
    for (final detail in ['BMI hiện tại 17,96', '175 cm', '55 kg', '18,5']) {
      expect(reason, contains(detail));
    }
    expect(blocked.calculate, throwsFormatException);
    expect(
      input(
        height: 175,
        weight: 60,
        goal: HealthGoal.gainWeightOrMuscle,
        target: 64,
      ).validate(),
      isNull,
      reason: 'The same 64 kg target is valid with an eligible current BMI.',
    );
  });

  test(
    'current BMI lower boundary stays inclusive without rounded admission',
    () {
      expect(input(height: 200, weight: 74).validate(), isNull);
      expect(input(height: 200, weight: 73.999).validate(), isNotNull);
      expect(
        input(height: 200, weight: 73.999).validate(),
        contains('gần 18,5 nhưng vẫn dưới ngưỡng'),
      );
    },
  );

  testWidgets('manual fallback saves only the explicitly entered target', (
    tester,
  ) async {
    final targets = FakeNutritionTargetRepository();
    await existingUser(tester, targets);
    await openBlockedGainPlan(tester);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('nutrition-plan-error')))
          .data,
      contains('BMI hiện tại 17,96'),
    );
    expect(find.byKey(const ValueKey('nutrition-plan-result')), findsNothing);
    await press(tester, 'nutrition-plan-manual');
    expect(targets.saveCalls, 0);
    await tester.enterText(find.byKey(const ValueKey('target-kcal')), '2100');
    expect(targets.saveCalls, 0);
    await press(tester, 'save-target');
    expect(targets.saveCalls, 1);
    expect(targets.byUid['test-uid']![today]!.kcalTarget, 2100);
    expect(targets.byUid['test-uid']![today]!.hasMacros, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cancelled manual fallback retains planner measurements and goal',
    (tester) async {
      final targets = FakeNutritionTargetRepository();
      await existingUser(tester, targets);
      await openBlockedGainPlan(tester);
      await press(tester, 'nutrition-plan-manual');
      await tester.enterText(find.byKey(const ValueKey('target-kcal')), '2100');
      await tester.tap(find.byTooltip('Đóng').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(targets.saveCalls, 0);
      await press(tester, 'nutrition-plan-review-input');
      for (final entry in {
        'nutrition-plan-height': '175',
        'nutrition-plan-weight': '55',
        'nutrition-plan-target-weight': '64',
      }.entries) {
        expect(
          tester
              .widget<TextFormField>(find.byKey(ValueKey(entry.key)))
              .controller!
              .text,
          entry.value,
        );
      }
      await choose(
        tester,
        'nutrition-plan-goal',
        HealthGoal.maintainWeight.label,
      );
      expect(find.byKey(const ValueKey('nutrition-plan-error')), findsNothing);
      expect(targets.saveCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
