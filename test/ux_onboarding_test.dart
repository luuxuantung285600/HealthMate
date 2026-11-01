import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/meal_drafts/data/meal_draft_store.dart';
import 'package:healthmate/features/profile/models/health_goal.dart';
import 'package:healthmate/features/profile/models/onboarding_progress.dart';
import 'package:healthmate/features/profile/models/personalization_answers.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_private_local_data.dart';
import 'support/fake_auth_repository.dart';
import 'support/test_app.dart';
import 'onboarding_test.dart'
    show legacyProfile, currentWeight, tapOnboardingButton;
import 'h7_private_data_test.dart' show saved;
import 'personalization_questionnaire_test.dart' show selectAnswer;

void main() {
  testWidgets(
    'dirty Back confirms discard and leaves optional setup for journal',
    (tester) async {
      final repository = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.incompleteProfile,
      );
      final container = await pumpApp(tester, profileRepository: repository);
      await tester.enterText(
        find.byKey(const ValueKey('onboarding-name')),
        'Nháp chưa lưu',
      );
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Thoát và bỏ nháp?'), findsOneWidget);
      await tester.tap(find.text('Thoát và bỏ nháp'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        AppRoutes.journal,
      );
      expect(repository.completeOnboardingCalls, 0);
    },
  );

  for (final width in [320.0, 390.0, 412.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets('optional setup reachable ${width}px scale$scale $mode', (
          tester,
        ) async {
          await pumpApp(
            tester,
            size: Size(width, 844),
            textScale: scale,
            initialThemeMode: mode,
            profileRepository: FakeHealthProfileRepository(
              profile: FakeHealthProfileRepository.incompleteProfile,
            ),
          );
          for (final finder in [
            find.byKey(const ValueKey('onboarding-skip-all')),
            find.text('Quyền riêng tư'),
            find.byKey(const ValueKey('onboarding-name')),
            find.byKey(const ValueKey('onboarding-birth-date')),
            find.byKey(const ValueKey('onboarding-height')),
            find.byKey(const ValueKey('onboarding-weight')),
          ]) {
            await tester.ensureVisible(finder);
            await tester.pumpAndSettle();
            expect(finder.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  }
  testWidgets('privacy before sign-in returns to unchanged credentials form', (
    tester,
  ) async {
    await pumpApp(tester, repository: FakeAuthRepository());
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'draft@example.com',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('auth-privacy')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth-privacy')));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('auth-email')))
          .controller!
          .text,
      'draft@example.com',
    );
  });

  testWidgets(
    'calculator takes missing input directly to its section then returns',
    (tester) async {
      final repository = FakeHealthProfileRepository(
        profile: legacyProfile(
          birthDate: DateTime(2000, 1, 15),
          healthGoal: HealthGoal.maintainWeight,
        ),
        metrics: [currentWeight(70)],
      );
      await pumpApp(tester, profileRepository: repository);
      for (var i = 0; i < 2; i++) {
        await tapOnboardingButton(tester, 'onboarding-next');
      }
      await selectAnswer(
        tester,
        'guidance',
        'Không, tôi thuộc phạm vi đề xuất',
      );
      for (var i = 0; i < 4; i++) {
        await tapOnboardingButton(tester, 'onboarding-next');
      }
      await tapOnboardingButton(tester, 'onboarding-personalize-nutrition');
      expect(
        find.byKey(const ValueKey('onboarding-body-step')),
        findsOneWidget,
      );
      await selectAnswer(tester, 'formulaSex', 'Nam · hệ số công thức');
      await tapOnboardingButton(tester, 'onboarding-next');
      expect(
        find.byKey(const ValueKey('onboarding-nutrition-step')),
        findsOneWidget,
      );
      await tapOnboardingButton(tester, 'onboarding-personalize-nutrition');
      expect(
        find.byKey(const ValueKey('onboarding-activity-step')),
        findsOneWidget,
      );
      await selectAnswer(tester, 'activity', 'Chủ yếu ngồi');
      await tapOnboardingButton(tester, 'onboarding-next');
      await tapOnboardingButton(tester, 'onboarding-personalize-nutrition');
      expect(
        find.byKey(const ValueKey('onboarding-nutrition-summary')),
        findsOneWidget,
      );
      expect(repository.completeOnboardingCalls, 0);
    },
  );
  test(
    'encrypted queue keeps onboarding and meal drafts isolated by UID and deletion',
    () async {
      final local = FakePrivateLocalData();
      final store = MealDraftStore(local, now: () => DateTime(2026, 10, 18));
      final draft = OnboardingProgress(
        step: 3,
        name: 'An',
        height: '170',
        weight: '70',
        targetWeight: '',
        birthDate: DateTime(2000, 1, 15),
        goal: HealthGoal.healthierHabits,
        answers: PersonalizationAnswers(),
      );
      await Future.wait([
        store.writeOnboarding('alice', draft.toJson()),
        store.put('alice', saved('meal-operation')),
      ]);
      expect((await store.list('alice')).single.operationId, 'meal-operation');
      expect(
        OnboardingProgress.fromJson(
          (await store.readOnboarding('alice'))!,
        ).step,
        3,
      );
      expect(await store.readOnboarding('bob'), isNull);
      await store.remove('alice', 'meal-operation');
      expect(await store.readOnboarding('alice'), isNotNull);
      await store.clearForAccountDeletion('alice');
      expect(await store.readOnboarding('alice'), isNull);
      await expectLater(
        store.writeOnboarding('alice', draft.toJson()),
        throwsStateError,
      );
    },
  );

  testWidgets(
    'skip whole personalization keeps unknown health fields and creates no target',
    (tester) async {
      final repository = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.incompleteProfile,
      );
      final container = await pumpApp(tester, profileRepository: repository);
      container.read(appRouterProvider).go(AppRoutes.onboarding);
      await tester.pumpAndSettle();
      await tapOnboardingButton(tester, 'onboarding-skip-all');
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        AppRoutes.journal,
      );
      expect(repository.completeOnboardingCalls, 0);
      expect(container.read(userProfileProvider).value!.birthDate, isNull);
      expect(container.read(userProfileProvider).value!.heightCm, isNull);
    },
  );

  testWidgets(
    'encrypted draft restores body input and exact optional step after reopening',
    (tester) async {
      final local = FakePrivateLocalData();
      final repository = FakeHealthProfileRepository(
        profile: legacyProfile(birthDate: DateTime(2000, 1, 15)),
        metrics: [currentWeight(70)],
      );
      final container = await pumpApp(
        tester,
        profileRepository: repository,
        privateLocalData: local,
      );
      final router = container.read(appRouterProvider);
      router.go(AppRoutes.onboarding);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('onboarding-name')),
        'Tên nháp',
      );
      await tapOnboardingButton(tester, 'onboarding-next');
      await tester.pump(const Duration(seconds: 1));
      router.go(AppRoutes.journal);
      await tester.pumpAndSettle();
      router.go(AppRoutes.onboarding);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('onboarding-goal-step')),
        findsOneWidget,
      );
      await tapOnboardingButton(tester, 'onboarding-back');
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('onboarding-name')),
            )
            .controller!
            .text,
        'Tên nháp',
      );
      expect(find.text('Ngày sinh · 15/01/2000'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
