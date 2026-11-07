import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/profile/models/personalization_answers.dart';
import 'package:healthmate/features/profile/models/health_goal.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_auth_repository.dart';
import 'support/test_app.dart';
import 'onboarding_test.dart'
    show legacyProfile, currentWeight, tapOnboardingButton;

Future<void> selectAnswer(WidgetTester tester, String id, String label) async {
  final finder = find.byKey(ValueKey('survey-$id'));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/inter/Inter-$weight.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  test(
    'exactly twenty unique question numbers with the five profile questions',
    () {
      final numbers = [
        1,
        3,
        4,
        5,
        6,
        ...personalizationQuestions.map((q) => q.number),
      ]..sort();
      expect(numbers, List.generate(20, (i) => i + 1));
    },
  );
  test(
    'round trip preserves unanswered separately from zero and private free text',
    () {
      final answers = PersonalizationAnswers({
        'exerciseDays': 0,
        'sleepHours': 0,
        'avoidFoods': 'Đậu phộng',
        'guidance': 'preferNotSay',
      }).normalized(HealthGoal.maintainWeight);
      final restored = PersonalizationAnswers.fromMap(answers.toMap());
      expect(restored['sleepHours'], 0);
      expect(restored['sweetDrinks'], isNull);
      expect(restored['avoidFoods'], 'Đậu phộng');
      expect(restored.eligible, isFalse);
      expect(restored.segmentLabels, isEmpty);
    },
  );
  test('rejects unknown fields, out of range and unsupported answers', () {
    for (final values in [
      {'role': 'admin'},
      {'exerciseDays': 8},
      {'exerciseMinutes': -30},
      {'formulaSex': 'made-up'},
      {'sleepHours': double.nan},
      {'sleepHours': 25},
      {'avoidFoods': 'x' * 201},
      {'exerciseDays': 0, 'exerciseMinutes': 30},
    ]) {
      expect(PersonalizationAnswers(values).validate(), isNotNull);
      expect(
        () => PersonalizationAnswers(values).toMap(),
        throwsFormatException,
      );
    }
    expect(
      () => PersonalizationAnswers.fromMap({'version': 99}),
      throwsFormatException,
    );
  });
  test(
    'branch changes remove answers that no longer apply and consent is explicit',
    () {
      final answers = PersonalizationAnswers({
        'pace': 'moderate',
        'exerciseDays': 0,
        'exerciseMinutes': 30,
        'exerciseType': 'vigorous',
      }).normalized(HealthGoal.maintainWeight);
      expect(answers['pace'], isNull);
      expect(answers['exerciseMinutes'], isNull);
      expect(answers['exerciseType'], isNull);
      expect(answers.eligible, isFalse);
      expect(answers.withAnswer('guidance', 'eligible').eligible, isTrue);
      expect(HealthGoal.gainMuscle.needsTargetWeight, isFalse);
      expect(
        HealthGoal.fromValue('gain_weight_or_muscle'),
        HealthGoal.gainWeightOrMuscle,
      );
    },
  );

  testWidgets(
    'existing user can fill optional survey, reload it and preserve weight history',
    (tester) async {
      final repo = FakeHealthProfileRepository(
        metrics: [currentWeight(70)],
        profile: legacyProfile(
          birthDate: DateTime(2000, 1, 15),
          healthGoal: HealthGoal.maintainWeight,
          completedAt: DateTime(2026, 1, 1),
        ),
      );
      final container = await pumpApp(tester, profileRepository: repo);
      container.read(appRouterProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      await tapOnboardingButton(tester, 'open-personalization');
      expect(find.text('Cập nhật cá nhân hóa'), findsOneWidget);
      await selectAnswer(tester, 'formulaSex', 'Nam · hệ số công thức');
      for (var i = 0; i < 3; i++) {
        await tapOnboardingButton(tester, 'onboarding-next');
      }
      expect(find.byKey(const ValueKey('survey-pace')), findsNothing);
      await selectAnswer(tester, 'exerciseDays', 'Chưa tập thường xuyên');
      expect(
        find.byKey(const ValueKey('survey-exerciseMinutes')),
        findsNothing,
      );
      await selectAnswer(tester, 'activity', 'Hoạt động nhẹ');
      await tapOnboardingButton(tester, 'onboarding-next');
      await selectAnswer(tester, 'diet', 'Thuần chay');
      await tester.enterText(
        find.byKey(const ValueKey('survey-avoidFoods')),
        'Đậu phộng',
      );
      await tapOnboardingButton(tester, 'onboarding-next');
      await selectAnswer(tester, 'priority', 'Giấc ngủ');
      for (var i = 0; i < 2; i++) {
        await tapOnboardingButton(tester, 'onboarding-next');
      }
      await tapOnboardingButton(tester, 'onboarding-complete');
      expect(repo.currentProfile!.personalization!['diet'], 'vegan');
      expect(repo.currentProfile!.personalization!['avoidFoods'], 'Đậu phộng');
      expect(repo.currentProfile!.personalization!['sleepHours'], isNull);
      expect(repo.metrics.length, 1);
      expect(repo.metrics.single.measuredAt, DateTime(2026, 10, 1));
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        AppRoutes.profile,
      );
      await tapOnboardingButton(tester, 'open-personalization');
      for (var i = 0; i < 4; i++) {
        await tapOnboardingButton(tester, 'onboarding-next');
      }
      expect(find.text('Thuần chay'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('survey-avoidFoods')),
            )
            .initialValue,
        'Đậu phộng',
      );
    },
  );

  testWidgets(
    'guidance or unanswered eligibility cannot generate an automatic calorie target',
    (tester) async {
      final repo = FakeHealthProfileRepository(
        metrics: [currentWeight(70)],
        profile: legacyProfile(
          birthDate: DateTime(2000, 1, 15),
          healthGoal: HealthGoal.maintainWeight,
        ),
      );
      await pumpApp(tester, profileRepository: repo);
      for (var i = 0; i < 2; i++) {
        await tapOnboardingButton(tester, 'onboarding-next');
      }
      await selectAnswer(tester, 'guidance', 'Có, tôi cần hướng dẫn riêng');
      for (var i = 0; i < 4; i++) {
        await tapOnboardingButton(tester, 'onboarding-next');
      }
      await tapOnboardingButton(tester, 'onboarding-personalize-nutrition');
      expect(
        find.byKey(const ValueKey('onboarding-nutrition-summary')),
        findsNothing,
      );
      expect(
        find.textContaining('Bạn vẫn có thể thiết lập kcal sau.'),
        findsOneWidget,
      );
      expect(repo.completeOnboardingCalls, 0);
    },
  );

  testWidgets(
    'small screen and large text support answers, back navigation and logout isolation',
    (tester) async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final repo = FakeHealthProfileRepository(
        metrics: [currentWeight(70)],
        profile: legacyProfile(
          birthDate: DateTime(2000, 1, 15),
          healthGoal: HealthGoal.maintainWeight,
        ),
      );
      final captureKey = GlobalKey();
      final container = await pumpApp(
        tester,
        repository: auth,
        profileRepository: repo,
        size: const Size(360, 800),
        textScale: 1.5,
        captureKey: captureKey,
      );
      await selectAnswer(tester, 'formulaSex', 'Nam · hệ số công thức');
      await tapOnboardingButton(tester, 'onboarding-next');
      await tapOnboardingButton(tester, 'onboarding-back');
      expect(find.text('Nam · hệ số công thức'), findsOneWidget);
      await tester.runAsync(() async {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        await Directory('build/questionnaire-ui').create(recursive: true);
        await File(
          'build/questionnaire-ui/body-large-text.png',
        ).writeAsBytes(data!.buffer.asUint8List());
      });
      expect(tester.takeException(), isNull);
      await container.read(authControllerProvider.notifier).signOut();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('survey-formulaSex')), findsNothing);
      expect(repo.completeOnboardingCalls, 0);
    },
  );
}
