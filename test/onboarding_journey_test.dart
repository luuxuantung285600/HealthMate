import 'support/load_icon_font.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/profile/models/health_goal.dart';
import 'package:healthmate/features/profile/models/onboarding_journey.dart';
import 'package:healthmate/features/profile/models/onboarding_progress.dart';
import 'package:healthmate/features/profile/models/personalization_answers.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';

import 'onboarding_test.dart'
    show legacyProfile, currentWeight, advanceToOnboarding, tapOnboardingButton;
import 'personalization_questionnaire_test.dart' show selectAnswer;
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_target_repository.dart';
import 'support/test_app.dart';

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await Directory('build/onboarding-journey').create(recursive: true);
    await File(
      'build/onboarding-journey/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
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

  test(
    'five goal branches ask for target and pace only when changing weight',
    () {
      for (final goal in HealthGoal.values) {
        final screens = onboardingJourney(
          goal: goal,
          answers: PersonalizationAnswers(),
          includeDetails: false,
        );
        expect(
          screens.contains(OnboardingStep.targetWeight),
          goal.needsTargetWeight,
        );
        expect(screens.contains(OnboardingStep.pace), goal.needsTargetWeight);
        expect(screens.contains(OnboardingStep.diet), isFalse);
        expect(screens.last, OnboardingStep.plan);
        expect(screens.toSet().length, screens.length);
      }
      final details = onboardingJourney(
        goal: HealthGoal.gainMuscle,
        answers: PersonalizationAnswers({'exerciseDays': 0}),
        includeDetails: true,
      );
      expect(details, contains(OnboardingStep.diet));
      expect(details, isNot(contains(OnboardingStep.exerciseMinutes)));
      expect(details, isNot(contains(OnboardingStep.exerciseType)));
    },
  );

  test(
    'version 1 drafts migrate without losing answers and version 2 uses stable screens',
    () {
      for (var section = 0; section < 8; section++) {
        final old = OnboardingProgress(
          step: section,
          name: 'An',
          height: '172',
          weight: '55.6',
          targetWeight: '65.4',
          goal: HealthGoal.gainWeightOrMuscle,
          answers: PersonalizationAnswers({'diet': 'vegan'}),
        ).toJson();
        old['version'] = 1;
        old.remove('screen');
        old.remove('includeDetails');
        final migrated = OnboardingProgress.fromJson(old);
        expect(migrated.screen, OnboardingStep.fromLegacy(section));
        expect(migrated.weight, '55.6');
        expect(migrated.answers['diet'], 'vegan');
        expect(
          OnboardingProgress.fromJson(migrated.toJson()).screen,
          migrated.screen,
        );
      }
      final draft = OnboardingProgress(
        step: 4,
        screen: OnboardingStep.avoidFoods,
        includeDetails: true,
        name: 'An',
        height: '172',
        weight: '55.6',
        targetWeight: '',
        answers: PersonalizationAnswers(),
      ).toJson();
      expect(
        OnboardingProgress.fromJson(draft).screen,
        OnboardingStep.avoidFoods,
      );
      expect(
        () => OnboardingProgress.fromJson({...draft, 'screen': 'unknown'}),
        throwsFormatException,
      );
    },
  );

  for (final goal in HealthGoal.values) {
    testWidgets('automatic proposal and confirmed save respect ${goal.value}', (
      tester,
    ) async {
      final profiles = FakeHealthProfileRepository(
        profile: legacyProfile(birthDate: DateTime(1996, 10, 26)),
        metrics: [currentWeight(70)],
      );
      final targets = FakeNutritionTargetRepository();
      final captureKey = GlobalKey();
      await pumpApp(
        tester,
        profileRepository: profiles,
        targetRepository: targets,
        dashboardNow: DateTime(2026, 10, 26, 12),
        size: const Size(390, 844),
        initialThemeMode: ThemeMode.dark,
        captureKey: captureKey,
      );
      expect(find.byKey(const ValueKey('onboarding-name')), findsOneWidget);
      expect(find.byKey(const ValueKey('onboarding-weight')), findsNothing);
      await selectAnswer(tester, 'formulaSex', 'Nam · hệ số công thức');
      await advanceToOnboarding(tester, 'onboarding-goal-step');
      if (goal == HealthGoal.gainMuscle) {
        await capture(tester, captureKey, 'goals-dark');
      }
      await tapOnboardingButton(tester, 'onboarding-goal-${goal.value}');
      if (goal.needsTargetWeight) {
        await advanceToOnboarding(tester, 'onboarding-target-weight');
        await tester.enterText(
          find.byKey(const ValueKey('onboarding-target-weight')),
          goal == HealthGoal.loseWeight ? '65' : '75',
        );
      }
      await selectAnswer(tester, 'activity', 'Chủ yếu ngồi');
      await selectAnswer(
        tester,
        'guidance',
        'Không, tôi thuộc phạm vi đề xuất',
      );
      if (goal.needsTargetWeight) {
        await selectAnswer(tester, 'pace', 'Nhẹ · dễ bắt đầu');
        expect(
          find.byKey(const ValueKey('onboarding-pace-preview')),
          findsOneWidget,
        );
      }
      await advanceToOnboarding(tester, 'onboarding-nutrition-step');
      expect(
        find.byKey(const ValueKey('onboarding-nutrition-summary')),
        findsOneWidget,
      );
      expect(find.text('Mục tiêu của bạn: ${goal.label}'), findsOneWidget);
      expect(targets.saveCalls, 0);
      expect(profiles.completeOnboardingCalls, 0);
      if (goal == HealthGoal.gainMuscle) {
        await capture(tester, captureKey, 'plan-dark');
      }
      await tapOnboardingButton(tester, 'onboarding-complete');
      expect(profiles.currentProfile!.healthGoal, goal);
      expect(targets.saveCalls, 1);
      final target = targets.byUid['test-uid']!.values.single;
      expect(target.kcalTarget, switch (goal) {
        HealthGoal.loseWeight => 2040,
        HealthGoal.gainWeightOrMuscle => 2380,
        _ => 2270,
      });
      final proteinFraction = goal == HealthGoal.gainMuscle ? .25 : .20;
      expect(
        target.proteinGTarget,
        closeTo(target.kcalTarget * proteinFraction / 4, .051),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'BMI responds to input and choosing no calorie plan never writes a target',
    (tester) async {
      final profiles = FakeHealthProfileRepository(
        profile: legacyProfile(
          birthDate: DateTime(1996, 10, 26),
          healthGoal: HealthGoal.healthierHabits,
        ),
        metrics: [currentWeight(70)],
      );
      final targets = FakeNutritionTargetRepository();
      await pumpApp(
        tester,
        profileRepository: profiles,
        targetRepository: targets,
      );
      await selectAnswer(tester, 'formulaSex', 'Nam · hệ số công thức');
      await advanceToOnboarding(tester, 'onboarding-weight');
      await tester.enterText(
        find.byKey(const ValueKey('onboarding-weight')),
        '80',
      );
      await tester.pumpAndSettle();
      expect(find.text('BMI hiện tại: 27.7'), findsOneWidget);
      await selectAnswer(tester, 'activity', 'Chủ yếu ngồi');
      await selectAnswer(
        tester,
        'guidance',
        'Không, tôi thuộc phạm vi đề xuất',
      );
      await advanceToOnboarding(tester, 'onboarding-nutrition-step');
      await tapOnboardingButton(tester, 'onboarding-apply-plan');
      await tapOnboardingButton(tester, 'onboarding-complete');
      expect(targets.saveCalls, 0);
      expect(profiles.completeOnboardingCalls, 1);
    },
  );

  testWidgets('pace changes calorie preview immediately without writing', (
    tester,
  ) async {
    final profiles = FakeHealthProfileRepository(
      profile: legacyProfile(
        birthDate: DateTime(1996, 10, 26),
        healthGoal: HealthGoal.loseWeight,
      ),
      metrics: [currentWeight(70)],
    );
    final targets = FakeNutritionTargetRepository();
    await pumpApp(
      tester,
      profileRepository: profiles,
      targetRepository: targets,
      dashboardNow: DateTime(2026, 10, 26, 12),
    );
    await selectAnswer(tester, 'formulaSex', 'Nam · hệ số công thức');
    await advanceToOnboarding(tester, 'onboarding-target-weight');
    await tester.enterText(
      find.byKey(const ValueKey('onboarding-target-weight')),
      '65',
    );
    await selectAnswer(tester, 'activity', 'Chủ yếu ngồi');
    await selectAnswer(tester, 'guidance', 'Không, tôi thuộc phạm vi đề xuất');
    await selectAnswer(tester, 'pace', 'Nhẹ · dễ bắt đầu');
    expect(find.text('Mức khởi đầu: 2040 kcal/ngày'), findsOneWidget);
    await selectAnswer(tester, 'pace', 'Vừa');
    expect(find.text('Mức khởi đầu: 1930 kcal/ngày'), findsOneWidget);
    expect(targets.saveCalls, 0);
    await advanceToOnboarding(tester, 'onboarding-nutrition-step');
    expect(find.text('1930 kcal'), findsOneWidget);
  });

  testWidgets(
    'declining replacement preserves the existing calorie target and can finish profile',
    (tester) async {
      final profiles = FakeHealthProfileRepository(
        profile: legacyProfile(
          birthDate: DateTime(1996, 10, 26),
          healthGoal: HealthGoal.maintainWeight,
        ),
        metrics: [currentWeight(70)],
      );
      final targets = FakeNutritionTargetRepository();
      const existing = NutritionTarget(
        effectiveFromDateKey: '2026-10-26',
        kcalTarget: 2000,
        proteinGTarget: 100,
        carbsGTarget: 250,
        fatGTarget: 65,
      );
      targets.byUid['test-uid'] = {'2026-10-26': existing};
      await pumpApp(
        tester,
        profileRepository: profiles,
        targetRepository: targets,
        dashboardNow: DateTime(2026, 10, 26, 12),
      );
      await selectAnswer(tester, 'formulaSex', 'Nam · hệ số công thức');
      await selectAnswer(tester, 'activity', 'Chủ yếu ngồi');
      await selectAnswer(
        tester,
        'guidance',
        'Không, tôi thuộc phạm vi đề xuất',
      );
      await advanceToOnboarding(tester, 'onboarding-nutrition-step');
      final complete = find.byKey(const ValueKey('onboarding-complete'));
      await tester.ensureVisible(complete);
      await tester.pumpAndSettle();
      await tester.tap(complete);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Thay mục tiêu từ hôm nay?'), findsOneWidget);
      await tester.tap(find.text('Giữ mục tiêu hiện tại'));
      await tester.pumpAndSettle();
      expect(targets.saveCalls, 0);
      expect(profiles.completeOnboardingCalls, 0);
      await tapOnboardingButton(tester, 'onboarding-complete');
      expect(profiles.completeOnboardingCalls, 1);
      expect(targets.saveCalls, 0);
      expect(targets.byUid['test-uid']!.values.single, same(existing));
    },
  );
}
