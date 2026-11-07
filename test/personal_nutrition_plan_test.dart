import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/chatbot/domain/chat_request.dart';
import 'package:healthmate/features/chatbot/domain/personal_chat_context.dart';
import 'package:healthmate/features/nutrition_targets/models/energy_estimate.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/nutrition_targets/models/personal_nutrition_plan.dart';
import 'package:healthmate/features/nutrition_targets/providers/nutrition_target_providers.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'package:healthmate/features/profile/models/health_goal.dart';
import 'package:healthmate/features/profile/models/profile_failure.dart';
import 'package:healthmate/features/profile/models/user_profile.dart';
import 'package:healthmate/features/wellness/providers/energy_providers.dart';

import 'support/fake_activity_repository.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_nutrition_target_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/test_app.dart';

final now = DateTime(2026, 10, 26, 12);
const today = '2026-10-26';
UserProfile planProfile({
  bool complete = true,
  HealthGoal goal = HealthGoal.maintainWeight,
}) => UserProfile(
  uid: 'test-uid',
  displayName: 'Nguyễn An',
  email: 'member@example.com',
  heightCm: 175,
  birthDate: DateTime(1996, 10, 26),
  healthGoal: goal,
  targetWeightKg: goal.needsTargetWeight ? 65 : null,
  onboardingCompletedAt: complete ? DateTime(2026, 1, 1) : null,
  createdAt: now,
  updatedAt: now,
  schemaVersion: 2,
);
BodyMetric planWeight({DateTime? measuredAt}) => BodyMetric(
  id: 'weight',
  weightKg: 70,
  measuredAt: measuredAt ?? now,
  note: '',
  createdAt: now,
  updatedAt: now,
);
PersonalNutritionInput input({
  int? age = 30,
  double? height = 175,
  double? weight = 70,
  FormulaSex? sex = FormulaSex.male,
  PlanActivity? activity = PlanActivity.light,
  HealthGoal? goal = HealthGoal.maintainWeight,
  double? target,
  PlanPace pace = PlanPace.gentle,
  bool eligible = true,
  PlanMacroSplit macros = PlanMacroSplit.balanced,
}) => PersonalNutritionInput(
  age: age,
  heightCm: height,
  weightKg: weight,
  sex: sex,
  activity: activity,
  goal: goal,
  targetWeightKg: target,
  pace: pace,
  macros: macros,
  eligible: eligible,
);

Future<void> press(
  WidgetTester tester,
  String key, {
  bool settle = true,
}) async {
  final finder = find.byKey(ValueKey(key));
  if (finder.evaluate().isEmpty) {
    final planner = find.byKey(const ValueKey('nutrition-plan-scroll'));
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: planner.evaluate().isNotEmpty
          ? find
                .descendant(of: planner, matching: find.byType(Scrollable))
                .first
          : find.byType(Scrollable).first,
      maxScrolls: 25,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> choose(WidgetTester tester, String key, String label) async {
  await press(tester, key);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> calculate(WidgetTester tester, {bool checkResult = true}) async {
  await choose(tester, 'nutrition-plan-sex', 'Nam · hệ số nghiên cứu');
  await choose(tester, 'nutrition-plan-activity', 'Chủ yếu ngồi');
  await press(tester, 'nutrition-plan-eligible');
  await press(tester, 'nutrition-plan-calculate');
  final error = find.byKey(const ValueKey('nutrition-plan-error'));
  if (checkResult) {
    expect(
      find.byKey(const ValueKey('nutrition-plan-result')),
      findsOneWidget,
      reason: error.evaluate().isEmpty
          ? 'No visible validation error'
          : tester.widget<Text>(error).data,
    );
  }
}

Future<ProviderContainer> existingUser(
  WidgetTester tester,
  FakeNutritionTargetRepository targets, {
  FakeAuthRepository? auth,
  double textScale = 1,
}) async => pumpApp(
  tester,
  dashboardNow: now,
  targetRepository: targets,
  repository: auth,
  textScale: textScale,
  profileRepository: FakeHealthProfileRepository(
    profile: planProfile(),
    metrics: [planWeight()],
  ),
);

Future<void> openFromProfile(
  WidgetTester tester,
  ProviderContainer container,
) async {
  container.read(appRouterProvider).go(AppRoutes.profile);
  await tester.pumpAndSettle();
  await press(tester, 'personalize-nutrition-target');
}

Future<void> reachNutrition(WidgetTester tester) async {
  await choose(tester, 'survey-formulaSex', 'Nam · hệ số công thức');
  await press(tester, 'onboarding-next');
  await press(tester, 'onboarding-next');
  await choose(tester, 'survey-guidance', 'Không, tôi thuộc phạm vi đề xuất');
  await press(tester, 'onboarding-next');
  await choose(tester, 'survey-activity', 'Chủ yếu ngồi');
  for (var i = 0; i < 3; i++) {
    await press(tester, 'onboarding-next');
  }
  expect(
    find.byKey(const ValueKey('onboarding-nutrition-step')),
    findsOneWidget,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
    'Mifflin original coefficients, maintenance and rounded macros are consistent',
    () {
      final plan = input().calculate();
      expect(plan.restingKcal, closeTo(1650.45, .001));
      expect(plan.maintenanceKcal, closeTo(2640.72, .001));
      expect(plan.kcal, 2640);
      expect(plan.proteinG, 132);
      expect(plan.carbsG, 330);
      expect(plan.fatG, 88);
      expect(plan.toTarget(today).validate(), isNull);
      expect(plan.toTarget(today).needsMacroConfirmation, isFalse);
      final female = input(
        weight: 60,
        height: 165,
        sex: FormulaSex.female,
        activity: PlanActivity.sedentary,
      ).calculate();
      expect(female.restingKcal, closeTo(1322.05, .001));
      expect(female.kcal, 1850);
    },
  );

  test(
    'weight intent and chosen pace change energy without predicting a deadline',
    () {
      expect(
        input(goal: HealthGoal.loseWeight, target: 65).calculate().kcal,
        2380,
      );
      expect(
        input(
          goal: HealthGoal.loseWeight,
          target: 65,
          pace: PlanPace.moderate,
        ).calculate().kcal,
        2240,
      );
      expect(
        input(goal: HealthGoal.gainWeightOrMuscle, target: 75).calculate().kcal,
        2770,
      );
      expect(
        input(
          goal: HealthGoal.gainWeightOrMuscle,
          target: 75,
          pace: PlanPace.moderate,
        ).calculate().kcal,
        2900,
      );
      expect(input(goal: HealthGoal.healthierHabits).calculate().kcal, 2640);
    },
  );

  test(
    'every supported macro split preserves energy within rounding tolerance',
    () {
      for (final activity in PlanActivity.values) {
        for (final split in PlanMacroSplit.values) {
          final target = input(
            activity: activity,
            macros: split,
          ).calculate().toTarget(today);
          expect((target.macroKcal! - target.kcalTarget).abs(), lessThan(1));
          expect(target.validate(), isNull);
        }
      }
    },
  );

  test('no silent defaults, nonfinite inputs or unsupported physiology', () {
    for (final invalid in [
      input(eligible: false),
      input(age: null),
      input(age: 17),
      input(age: 66),
      input(sex: null),
      input(activity: null),
      input(goal: null),
      input(weight: double.nan),
      input(height: double.infinity),
      input(weight: -1),
      input(weight: 40),
      input(weight: 150),
      input(goal: HealthGoal.loseWeight),
      input(goal: HealthGoal.loseWeight, target: 75),
      input(goal: HealthGoal.gainWeightOrMuscle, target: 65),
      input(goal: HealthGoal.loseWeight, target: 40),
    ]) {
      expect(invalid.validate(), isNotNull);
      expect(invalid.calculate, throwsFormatException);
    }
  });

  test('below product energy floor is rejected rather than clamped', () {
    final low = input(
      age: 65,
      height: 150,
      weight: 43,
      sex: FormulaSex.female,
      activity: PlanActivity.sedentary,
      goal: HealthGoal.loseWeight,
      target: 42,
      pace: PlanPace.moderate,
    );
    expect(low.validate(), isNull);
    expect(low.calculate, throwsFormatException);
  });

  test('seed age honors birthday and only reuses recent nonfuture weight', () {
    expect(ageOnDate(DateTime(2000, 10, 27), now), 25);
    expect(ageOnDate(DateTime(2000, 10, 26), now), 26);
    final seed = PersonalNutritionSeed.fromProfile(
      planProfile(),
      planWeight(),
      now,
    );
    expect(seed.age, 30);
    expect(seed.weightKg, 70);
    expect(
      PersonalNutritionSeed.fromProfile(
        planProfile(),
        planWeight(measuredAt: now.subtract(const Duration(days: 91))),
        now,
      ).weightKg,
      isNull,
    );
    expect(
      PersonalNutritionSeed.fromProfile(
        planProfile(),
        planWeight(measuredAt: now.add(const Duration(minutes: 1))),
        now,
      ).weightKg,
      isNull,
    );
  });

  testWidgets(
    'existing user reuses profile, must choose factors and explicitly save',
    (tester) async {
      final targets = FakeNutritionTargetRepository();
      final container = await existingUser(tester, targets);
      await press(tester, 'open-personal-nutrition');
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('nutrition-plan-age')),
            )
            .controller!
            .text,
        '30',
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const ValueKey('nutrition-plan-weight')),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        '70.0',
      );
      await press(tester, 'nutrition-plan-calculate');
      expect(
        find.byKey(const ValueKey('nutrition-plan-error')),
        findsOneWidget,
      );
      expect(targets.saveCalls, 0);
      // Return to fields after validation, not a fabricated default result.
      final scroll = find.descendant(
        of: find.byKey(const ValueKey('nutrition-plan-scroll')),
        matching: find.byType(Scrollable),
      );
      await tester.drag(scroll.first, const Offset(0, 2200));
      await tester.pumpAndSettle();
      await calculate(tester);
      expect(targets.saveCalls, 0);
      await press(tester, 'nutrition-plan-save');
      expect(targets.saveCalls, 1);
      final saved = targets.byUid['test-uid']![today]!;
      expect(saved.kcalTarget, 2310);
      expect(saved.hasMacros, isTrue);
      expect(
        container.read(dailyEnergyBudgetProvider(today)).value!.kcalTarget,
        saved.kcalTarget,
      );
      expect(
        find.byKey(const ValueKey('open-personal-nutrition')),
        findsNothing,
      );
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      expect(journalTotals('0 kcal / 2310 kcal'), findsOneWidget);
      final context = PersonalChatContext(
        nutrition: FakeNutritionRepository(),
        water: FakeWaterRepository(),
        activity: FakeActivityRepository(),
        targets: targets,
        profile: FakeHealthProfileRepository(),
      );
      final answer = await context.answer(
        'test-uid',
        planChatRequest('Hôm nay còn bao nhiêu kcal?', now, now),
      );
      expect(answer, contains('2.310'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('replacement requires consent and keeps earlier daily targets', (
    tester,
  ) async {
    const previous = NutritionTarget(
      effectiveFromDateKey: '2026-10-01',
      kcalTarget: 1800,
    );
    final targets = FakeNutritionTargetRepository()
      ..byUid['test-uid'] = {'2026-10-01': previous};
    final container = await existingUser(tester, targets);
    await openFromProfile(tester, container);
    await calculate(tester);
    await press(tester, 'nutrition-plan-save');
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('nutrition-plan-save')),
          )
          .onPressed,
      isNull,
    );
    expect(targets.saveCalls, 0);
    await press(tester, 'nutrition-plan-replace');
    await press(tester, 'nutrition-plan-save');
    expect(targets.byUid['test-uid']!['2026-10-01'], same(previous));
    expect(
      targetForDate(
        targets.byUid['test-uid']!.values,
        '2026-10-25',
      )!.kcalTarget,
      1800,
    );
    expect(targets.byUid['test-uid']![today]!.kcalTarget, 2310);
  });

  testWidgets('save failure retains reviewed result and retries once', (
    tester,
  ) async {
    final targets = FakeNutritionTargetRepository()..failSave = true;
    await existingUser(tester, targets);
    await press(tester, 'open-personal-nutrition');
    await calculate(tester);
    await press(tester, 'nutrition-plan-save');
    expect(find.byKey(const ValueKey('nutrition-plan-save')), findsOneWidget);
    expect(targets.byUid, isEmpty);
    targets.failSave = false;
    await press(tester, 'nutrition-plan-save');
    expect(targets.saveCalls, 2);
    expect(targets.byUid['test-uid']!.length, 1);
  });

  testWidgets('a changed server target requires a new review and consent', (
    tester,
  ) async {
    final targets = FakeNutritionTargetRepository()
      ..byUid['test-uid'] = {
        '2026-10-01': const NutritionTarget(
          effectiveFromDateKey: '2026-10-01',
          kcalTarget: 1800,
        ),
      };
    final container = await existingUser(tester, targets);
    await openFromProfile(tester, container);
    await calculate(tester);
    await press(tester, 'nutrition-plan-replace');
    targets.byUid['test-uid']![today] = const NutritionTarget(
      effectiveFromDateKey: today,
      kcalTarget: 1950,
    );
    await press(tester, 'nutrition-plan-save');
    expect(targets.saveCalls, 0);
    expect(targets.byUid['test-uid']![today]!.kcalTarget, 1950);
    expect(find.byKey(const ValueKey('nutrition-plan-error')), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('nutrition-plan-replace')),
          )
          .value,
      isFalse,
    );
    await press(tester, 'nutrition-plan-replace');
    await press(tester, 'nutrition-plan-save');
    expect(targets.byUid['test-uid']![today]!.kcalTarget, 2310);
  });

  testWidgets(
    'target read error blocks saving and can retry without losing the calculation',
    (tester) async {
      final targets = FakeNutritionTargetRepository();
      final container = await existingUser(tester, targets);
      await press(tester, 'open-personal-nutrition');
      await calculate(tester);
      targets.failRead = true;
      container.invalidate(nutritionTargetProvider(today));
      await tester.pumpAndSettle();
      await press(tester, 'nutrition-plan-save');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('nutrition-plan-save')),
            )
            .onPressed,
        isNull,
      );
      expect(targets.saveCalls, 0);
      targets.failRead = false;
      await press(tester, 'nutrition-plan-retry-target');
      await press(tester, 'nutrition-plan-save');
      expect(targets.byUid['test-uid']![today]!.kcalTarget, 2310);
    },
  );

  testWidgets('crossing midnight never writes yesterday as a new goal', (
    tester,
  ) async {
    var clock = now;
    final targets = FakeNutritionTargetRepository();
    await pumpApp(
      tester,
      dashboardNowSource: () => clock,
      targetRepository: targets,
      profileRepository: FakeHealthProfileRepository(
        profile: planProfile(),
        metrics: [planWeight()],
      ),
    );
    await press(tester, 'open-personal-nutrition');
    await calculate(tester);
    clock = DateTime(2026, 10, 27, 0, 1);
    await press(tester, 'nutrition-plan-save');
    expect(targets.saveCalls, 0);
    expect(find.textContaining('Đã sang ngày mới.'), findsOneWidget);
  });

  testWidgets('small screen and large text keep questions and review usable', (
    tester,
  ) async {
    final captureKey = GlobalKey();
    final targets = FakeNutritionTargetRepository();
    await pumpApp(
      tester,
      dashboardNow: now,
      targetRepository: targets,
      size: const Size(360, 800),
      textScale: 1.5,
      captureKey: captureKey,
      profileRepository: FakeHealthProfileRepository(
        profile: planProfile(),
        metrics: [planWeight()],
      ),
    );
    await press(tester, 'open-personal-nutrition');
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final folder = Directory('build/personal-nutrition-ui');
        await folder.create(recursive: true);
        await File(
          '${folder.path}/$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
      });
    }

    await capture('questions');
    await calculate(tester, checkResult: false);
    await capture('review');
    expect(find.byKey(const ValueKey('nutrition-plan-result')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await press(tester, 'nutrition-plan-save');
    expect(targets.saveCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pending save blocks duplicate submits and logout disposes private draft',
    (tester) async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final targets = FakeNutritionTargetRepository()
        ..pendingSave = Completer<void>();
      final container = await existingUser(tester, targets, auth: auth);
      await press(tester, 'open-personal-nutrition');
      await calculate(tester);
      await press(tester, 'nutrition-plan-save', settle: false);
      expect(targets.saveCalls, 1);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('nutrition-plan-save')),
            )
            .onPressed,
        isNull,
      );
      await container.read(authControllerProvider.notifier).signOut();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('nutrition-plan-result')), findsNothing);
      targets.pendingSave!.complete();
      await tester.pumpAndSettle();
      expect(targets.savedUids, ['test-uid']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'onboarding reviews plan without writing then saves before completing profile',
    (tester) async {
      final profile = FakeHealthProfileRepository(
        profile: planProfile(complete: false),
        metrics: [planWeight()],
      );
      final targets = FakeNutritionTargetRepository();
      final container = await pumpApp(
        tester,
        profileRepository: profile,
        targetRepository: targets,
        dashboardNow: now,
      );
      await reachNutrition(tester);
      await press(tester, 'onboarding-personalize-nutrition');
      expect(targets.saveCalls, 0);
      expect(profile.completeOnboardingCalls, 0);
      await press(tester, 'onboarding-next');
      await press(tester, 'onboarding-complete');
      expect(targets.saveCalls, 1);
      expect(profile.completeOnboardingCalls, 1);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        AppRoutes.dashboard,
      );
      expect(
        container.read(dailyEnergyBudgetProvider(today)).value!.kcalTarget,
        2310,
      );
    },
  );

  testWidgets(
    'onboarding target failure prevents profile completion and preserves proposal',
    (tester) async {
      final profile = FakeHealthProfileRepository(
        profile: planProfile(complete: false),
        metrics: [planWeight()],
      );
      final targets = FakeNutritionTargetRepository()..failSave = true;
      await pumpApp(
        tester,
        profileRepository: profile,
        targetRepository: targets,
        dashboardNow: now,
      );
      await reachNutrition(tester);
      await press(tester, 'onboarding-personalize-nutrition');
      await press(tester, 'onboarding-next');
      await press(tester, 'onboarding-complete');
      expect(profile.completeOnboardingCalls, 0);
      expect(
        find.byKey(const ValueKey('onboarding-nutrition-error')),
        findsOneWidget,
      );
      targets.failSave = false;
      await press(tester, 'onboarding-complete');
      expect(profile.completeOnboardingCalls, 1);
      expect(targets.byUid['test-uid']!.length, 1);
    },
  );

  testWidgets(
    'profile failure after target save retries without creating another target',
    (tester) async {
      final profile = FakeHealthProfileRepository(
        profile: planProfile(complete: false),
        metrics: [planWeight()],
      );
      final targets = FakeNutritionTargetRepository();
      await pumpApp(
        tester,
        profileRepository: profile,
        targetRepository: targets,
        dashboardNow: now,
      );
      await reachNutrition(tester);
      await press(tester, 'onboarding-personalize-nutrition');
      await press(tester, 'onboarding-next');
      profile.failure = const ProfileFailure('Lỗi lưu hồ sơ thử nghiệm.');
      await press(tester, 'onboarding-complete');
      expect(targets.saveCalls, 1);
      expect(
        find.textContaining('Mục tiêu dinh dưỡng đã được lưu.'),
        findsOneWidget,
      );
      profile.failure = null;
      await press(tester, 'onboarding-complete');
      expect(targets.saveCalls, 1);
      expect(profile.currentProfile!.isOnboardingComplete, isTrue);
    },
  );
}
