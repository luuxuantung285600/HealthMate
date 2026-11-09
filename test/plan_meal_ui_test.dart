import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/wellness/data/wellness_repository.dart';
import 'package:healthmate/features/wellness/models/wellness_models.dart';
import 'package:healthmate/features/wellness/presentation/wellness_screen.dart';
import 'package:healthmate/features/wellness/providers/wellness_providers.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_food_search_service.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_repository.dart';

class ControlledPlans implements WellnessRepository {
  int checks = 0, loads = 0, saves = 0;
  int planSaves = 0;
  bool marked = true;
  bool recorded = false;
  Completer<bool>? checking;
  Completer<String>? saving;
  PlannedMeal? confirmed;
  final date = localDateOnly(DateTime.now());
  PlannedMeal get plan => PlannedMeal(
    id: '${localDateKey(date)}-breakfast',
    date: date,
    type: MealType.breakfast,
    items: [MealItemSnapshot.fromCatalog(FakeNutritionRepository.rice, 100)],
    loggedMealId: marked ? 'plan-${localDateKey(date)}-breakfast' : null,
    createdAt: date,
    updatedAt: date,
  );
  @override
  Future<bool> existingPlanMeal(String uid, String id) {
    checks++;
    return checking?.future ?? Future.value(recorded);
  }

  @override
  Future<PlannedMeal?> loadPlan(String uid, String id) async {
    loads++;
    return plan;
  }

  @override
  Future<String> recordPlanMeal(String uid, PlannedMeal plan, MealDraft draft) {
    saves++;
    confirmed = plan;
    return saving?.future ?? Future.value('plan-${plan.id}');
  }

  @override
  Future<void> savePlan(String uid, MealDraft draft) async {
    planSaves++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> pumpPlanner(
  WidgetTester tester,
  ControlledPlans repo, {
  Stream<AuthUser?>? session,
  FakeAuthRepository? repository,
}) async {
  final auth =
      repository ?? FakeAuthRepository(user: FakeAuthRepository.testUser);
  addTearDown(auth.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        authSessionProvider.overrideWith(
          (ref) => session ?? auth.authStateChanges(),
        ),
        userProfileProvider.overrideWith(
          (ref) => Stream.value(FakeHealthProfileRepository.testProfile),
        ),
        foodCatalogProvider.overrideWith(
          (ref) => Stream.value([FakeNutritionRepository.rice]),
        ),
        plansProvider.overrideWith((ref, start) => Stream.value([repo.plan])),
        wellnessRepositoryProvider.overrideWithValue(repo),
        unifiedFoodSearchProvider.overrideWithValue(FakeFoodSearchService()),
        appFeatureFlagsProvider.overrideWithValue(const AppFeatureFlags()),
      ],
      child: MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Consumer(
          builder: (context, ref, child) {
            ref.watch(authSessionProvider);
            ref.watch(userProfileProvider);
            return const Scaffold(body: MealPlannerPanel());
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(
    find.text(repo.marked ? 'Đã ghi · Kiểm tra' : 'Xác nhận đã ăn'),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final editing in [true, false]) {
    testWidgets(
      'plan ${editing ? 'editing' : 'logging'} rejects Auth change before stream delivery',
      (tester) async {
        final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
        final repo = ControlledPlans()..marked = !editing;
        await pumpPlanner(tester, repo, repository: auth);
        if (editing) {
          final editButton = find
              .byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Chỉnh kế hoạch',
              )
              .first;
          await tester.ensureVisible(editButton);
          await tester.pumpAndSettle();
          await tester.tap(editButton);
        } else {
          await tester.tap(find.text('Đã ghi · Kiểm tra'));
        }
        // The panel remains busy while its entry dialog is open.
        await tester.pump(const Duration(milliseconds: 300));
        final save = find.byKey(
          ValueKey(editing ? 'save-meal-plan' : 'save-meal'),
        );
        await tester.ensureVisible(save);
        await tester.pump(const Duration(milliseconds: 300));
        auth.emitUser(null);
        tester.widget<FilledButton>(save).onPressed!();
        await tester.pumpAndSettle();
        expect(repo.planSaves, 0);
        expect(repo.saves, 0);
        expect(find.byType(PlanMealDialog), findsNothing);
        expect(find.byType(MealFormDialog), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('dangling marker is checkable and duplicate taps open one form', (
    tester,
  ) async {
    final repo = ControlledPlans()..checking = Completer<bool>();
    await pumpPlanner(tester, repo);
    final button = find.text('Đã ghi · Kiểm tra');
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();
    expect(repo.checks, 1);
    expect(repo.loads, 0);
    repo.checking!.complete(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MealFormDialog), findsOneWidget);
    expect(repo.loads, 1);
    expect(repo.saves, 0);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(repo.saves, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'existing journal entry is checked without opening or rewriting',
    (tester) async {
      final repo = ControlledPlans()..recorded = true;
      await pumpPlanner(tester, repo);
      await tester.tap(find.text('Đã ghi · Kiểm tra'));
      await tester.pumpAndSettle();
      expect(repo.checks, 1);
      expect(repo.loads, 0);
      expect(repo.saves, 0);
      expect(find.byType(MealFormDialog), findsNothing);
    },
  );

  testWidgets(
    'pending save prevents duplicate writes; failure keeps draft for retry',
    (tester) async {
      final repo = ControlledPlans()..saving = Completer<String>();
      await pumpPlanner(tester, repo);
      await tester.tap(find.text('Đã ghi · Kiểm tra'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final save = find.byKey(const ValueKey('save-meal'));
      await tester.tap(save);
      await tester.tap(save);
      await tester.pump();
      expect(repo.saves, 1);
      expect(repo.confirmed?.id, repo.plan.id);
      repo.saving!.completeError(
        const FormatException(
          'Bữa đã có nội dung khác. Hãy xem hoặc sửa tại Nhật ký.',
        ),
      );
      // Planner remains busy while its dialog is open.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(MealFormDialog), findsOneWidget);
      expect(find.textContaining('Bữa đã có nội dung khác.'), findsOneWidget);
      expect(find.textContaining('Cơm trắng chín'), findsWidgets);
      repo.saving = null;
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.saves, 2);
      expect(find.byType(MealFormDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'account change during reconciliation never opens old user form',
    (tester) async {
      final session = StreamController<AuthUser?>.broadcast();
      addTearDown(session.close);
      final repo = ControlledPlans()..checking = Completer<bool>();
      final stream = Stream<AuthUser?>.multi((controller) {
        controller.add(FakeAuthRepository.testUser);
        final sub = session.stream.listen(controller.add);
        controller.onCancel = sub.cancel;
      });
      await pumpPlanner(tester, repo, session: stream);
      await tester.tap(find.text('Đã ghi · Kiểm tra'));
      await tester.pump();
      session.add(null);
      await tester.pump();
      repo.checking!.complete(false);
      await tester.pumpAndSettle();
      expect(find.byType(MealFormDialog), findsNothing);
      expect(repo.saves, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
