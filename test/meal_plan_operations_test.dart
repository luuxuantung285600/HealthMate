import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:healthmate/features/nutrition_targets/providers/nutrition_target_providers.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/wellness/data/wellness_repository.dart';
import 'package:healthmate/features/wellness/models/wellness_models.dart';
import 'package:healthmate/features/wellness/presentation/delete_meal_plan_dialog.dart';
import 'package:healthmate/features/wellness/presentation/meal_plan_suggestion_dialog.dart';
import 'package:healthmate/features/wellness/presentation/wellness_screen.dart';
import 'package:healthmate/features/wellness/providers/wellness_providers.dart';
import 'package:healthmate/shared/providers/local_clock_provider.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_health_profile_repository.dart';

// Synthetic fixtures only; no Firebase connection or production catalog writes.
const operationFood = FoodCatalogItem(
  id: 'vn-fixture',
  name: 'Cơm kiểm thử',
  category: 'Fixture',
  servingBasis: ServingBasis.per100g,
  servingGrams: 200,
  servingLabel: 'Phần kiểm thử',
  kcalPer100g: 130,
  proteinGPer100g: 3,
  carbsGPer100g: 28,
  fatGPer100g: 1,
  sourceLabel: 'Synthetic test fixture',
  isEstimated: true,
);
final operationDate = DateTime(2026, 11, 9);

class OperationPlans implements WellnessRepository {
  final attempts = <MealDraft>[];
  final owners = <String>[];
  final committed = <String>{};
  int deleteCalls = 0;
  int? failAt;
  bool loseAck = false;
  Object? deleteFailure;
  Completer<bool>? pendingAdd;
  Completer<void>? pendingDelete;
  PlannedMeal? deletedSnapshot;
  PlannedMeal get plan => PlannedMeal(
    id: '2026-11-09-breakfast',
    date: operationDate,
    type: MealType.breakfast,
    items: [MealItemSnapshot.fromCatalog(operationFood, 200)],
    createdAt: operationDate,
    updatedAt: operationDate,
  );
  @override
  Future<bool> addSuggestedPlan(String uid, MealDraft draft) async {
    attempts.add(draft);
    owners.add(uid);
    if (pendingAdd != null) return pendingAdd!.future;
    final id = '${draft.dateKey}-${draft.type.name}';
    if (attempts.length == failAt) {
      if (loseAck) committed.add(id);
      throw StateError('Synthetic network failure');
    }
    return committed.add(id);
  }

  @override
  Future<void> deletePlan(
    String uid,
    String id, {
    PlannedMeal? expected,
  }) async {
    deleteCalls++;
    owners.add(uid);
    deletedSnapshot = expected;
    if (pendingDelete != null) await pendingDelete!.future;
    if (deleteFailure != null) throw deleteFailure!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PlanOperationsFixture {
  final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
  final repo = OperationPlans();
  Completer<List<FoodCatalogItem>>? catalogPending;
  Future<void> start(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double scale = 1,
    ThemeMode mode = ThemeMode.light,
    GlobalKey? captureKey,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(FakeHealthProfileRepository.testProfile),
          ),
          foodCatalogProvider.overrideWith(
            (ref) => catalogPending != null
                ? Stream.fromFuture(catalogPending!.future)
                : Stream.value([operationFood]),
          ),
          plansProvider.overrideWith((ref, start) => Stream.value([repo.plan])),
          weeklyNutritionTargetsProvider.overrideWith((ref, start) async => []),
          wellnessRepositoryProvider.overrideWithValue(repo),
          currentLocalTimeProvider.overrideWithValue(() => operationDate),
          localClockProvider.overrideWith((ref) => operationDate),
        ],
        child: RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            locale: const Locale('vi'),
            supportedLocales: const [Locale('vi')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Consumer(
              builder: (context, ref, child) {
                ref.watch(authSessionProvider);
                ref.watch(userProfileProvider);
                return const Scaffold(body: MealPlannerPanel());
              },
            ),
          ),
        ),
      ),
    );
    // A pending catalog intentionally leaves a loading source alive.
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> suggest(WidgetTester tester) async {
    await operationTap(tester, find.byKey(const ValueKey('suggest-week-plan')));
    expect(find.byType(MealPlanSuggestionDialog), findsOneWidget);
  }

  Future<void> remove(WidgetTester tester) async {
    await operationTap(tester, find.text('Xóa kế hoạch').first);
    expect(find.byType(DeleteMealPlanDialog), findsOneWidget);
  }
}

Future<void> operationTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets(
    'preview does not write and cancellation leaves all meals untouched',
    (tester) async {
      final f = PlanOperationsFixture();
      await f.start(tester);
      await f.suggest(tester);
      expect(f.repo.attempts, isEmpty);
      await operationTap(tester, find.text('Hủy'));
      expect(find.byType(MealPlanSuggestionDialog), findsNothing);
      expect(f.repo.attempts, isEmpty);
    },
  );

  testWidgets(
    'partial failure resumes unresolved preview without repeating acknowledged meals',
    (tester) async {
      final f = PlanOperationsFixture();
      f.repo.failAt = 3;
      await f.start(tester);
      await f.suggest(tester);
      final dialog = tester.widget<MealPlanSuggestionDialog>(
        find.byType(MealPlanSuggestionDialog),
      );
      final expected = dialog.suggestion.drafts;
      await operationTap(
        tester,
        find.byKey(const ValueKey('save-suggested-plans')),
      );
      expect(find.textContaining('Đã xử lý 2/27 bữa'), findsOneWidget);
      expect(find.byKey(const ValueKey('suggestion-error')), findsOneWidget);
      expect(f.repo.attempts, expected.take(3).toList());
      await operationTap(tester, find.text('Lưu tiếp'));
      expect(f.repo.attempts, [...expected.take(3), ...expected.skip(2)]);
      expect(f.repo.committed, hasLength(27));
      expect(
        find.textContaining('Đã xử lý 27/27 bữa · Thêm 27 · Giữ nguyên 0'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('save-suggested-plans')), findsNothing);
      await operationTap(tester, find.text('Xong'));
      expect(find.byType(MealPlanSuggestionDialog), findsNothing);
    },
  );

  testWidgets(
    'lost ACK retries the same slot and reports preserved meals honestly',
    (tester) async {
      final f = PlanOperationsFixture();
      f.repo.failAt = 2;
      f.repo.loseAck = true;
      await f.start(tester);
      await f.suggest(tester);
      await operationTap(
        tester,
        find.byKey(const ValueKey('save-suggested-plans')),
      );
      expect(f.repo.committed, hasLength(2));
      expect(find.textContaining('Đã xử lý 1/27'), findsOneWidget);
      await operationTap(tester, find.text('Lưu tiếp'));
      expect(f.repo.committed, hasLength(27));
      expect(find.textContaining('Thêm 26 · Giữ nguyên 1'), findsOneWidget);
    },
  );

  testWidgets('pending bulk save blocks double-submit and Back', (
    tester,
  ) async {
    final f = PlanOperationsFixture();
    f.repo.pendingAdd = Completer<bool>();
    await f.start(tester);
    await f.suggest(tester);
    final save = find.byKey(const ValueKey('save-suggested-plans'));
    await tester.tap(save);
    await tester.tap(save);
    await tester.pump();
    expect(f.repo.attempts, hasLength(1));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(MealPlanSuggestionDialog), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Hủy'))
          .onPressed,
      isNull,
    );
    f.repo.pendingAdd!.completeError(StateError('Synthetic pending failure'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('suggestion-error')), findsOneWidget);
  });

  testWidgets(
    'closing after partial save explicitly keeps acknowledged meals',
    (tester) async {
      final f = PlanOperationsFixture();
      f.repo.failAt = 2;
      await f.start(tester);
      await f.suggest(tester);
      await operationTap(
        tester,
        find.byKey(const ValueKey('save-suggested-plans')),
      );
      expect(
        find.textContaining('Các bữa đã lưu được giữ lại'),
        findsOneWidget,
      );
      await operationTap(tester, find.text('Đóng'));
      expect(f.repo.committed, hasLength(1));
      expect(find.byType(MealPlanSuggestionDialog), findsNothing);
    },
  );

  for (final deletion in [true, false]) {
    testWidgets(
      '${deletion ? 'delete' : 'bulk'} rejects immediate Auth change before stream',
      (tester) async {
        final f = PlanOperationsFixture();
        await f.start(tester);
        if (deletion) {
          await f.remove(tester);
        } else {
          await f.suggest(tester);
        }
        final button = tester.widget<FilledButton>(
          find.byKey(
            ValueKey(deletion ? 'confirm-delete-plan' : 'save-suggested-plans'),
          ),
        );
        f.auth.emitUser(null);
        button.onPressed!();
        await tester.pumpAndSettle();
        expect(f.repo.deleteCalls, 0);
        expect(f.repo.attempts, isEmpty);
        expect(find.byType(DeleteMealPlanDialog), findsNothing);
        expect(find.byType(MealPlanSuggestionDialog), findsNothing);
      },
    );

    testWidgets(
      '${deletion ? 'delete' : 'bulk'} late ACK cannot continue after logout and same UID login',
      (tester) async {
        final f = PlanOperationsFixture();
        if (deletion) {
          f.repo.pendingDelete = Completer<void>();
        } else {
          f.repo.pendingAdd = Completer<bool>();
        }
        await f.start(tester);
        if (deletion) {
          await f.remove(tester);
        } else {
          await f.suggest(tester);
        }
        await operationTap(
          tester,
          find.byKey(
            ValueKey(deletion ? 'confirm-delete-plan' : 'save-suggested-plans'),
          ),
        );
        f.auth.emitUser(null);
        await tester.pump(const Duration(milliseconds: 300));
        f.auth.emitUser(FakeAuthRepository.testUser);
        await tester.pump(const Duration(milliseconds: 300));
        if (deletion) {
          f.repo.pendingDelete!.complete();
        } else {
          f.repo.pendingAdd!.complete(true);
        }
        await tester.pumpAndSettle();
        expect(f.repo.deleteCalls, deletion ? 1 : 0);
        expect(f.repo.attempts, hasLength(deletion ? 0 : 1));
        expect(
          find.text('Đã xóa kế hoạch. Nhật ký được giữ nguyên.'),
          findsNothing,
        );
        expect(find.byType(DeleteMealPlanDialog), findsNothing);
        expect(find.byType(MealPlanSuggestionDialog), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('catalog loading cannot reopen an old preview after relogin', (
    tester,
  ) async {
    final f = PlanOperationsFixture();
    f.catalogPending = Completer<List<FoodCatalogItem>>();
    await f.start(tester);
    await operationTap(tester, find.byKey(const ValueKey('suggest-week-plan')));
    f.auth.emitUser(null);
    await tester.pump(const Duration(milliseconds: 300));
    f.auth.emitUser(FakeAuthRepository.testUser);
    await tester.pump(const Duration(milliseconds: 300));
    f.catalogPending!.complete([operationFood]);
    await tester.pumpAndSettle();
    expect(find.byType(MealPlanSuggestionDialog), findsNothing);
    expect(f.repo.attempts, isEmpty);
  });

  testWidgets(
    'delete waits for ACK, blocks repeated taps and permits retry after network failure',
    (tester) async {
      final f = PlanOperationsFixture();
      f.repo.pendingDelete = Completer<void>();
      await f.start(tester);
      await f.remove(tester);
      final save = find.byKey(const ValueKey('confirm-delete-plan'));
      await tester.tap(save);
      await tester.tap(save);
      await tester.pump();
      expect(f.repo.deleteCalls, 1);
      expect(f.repo.deletedSnapshot, isNotNull);
      expect(f.repo.deletedSnapshot!.updatedAt, operationDate);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(DeleteMealPlanDialog), findsOneWidget);
      f.repo.pendingDelete!.completeError(
        StateError('Synthetic connection failure'),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text(
          'Chưa xác nhận xóa thành công. Hãy kiểm tra kết nối và thử lại.',
        ),
        findsOneWidget,
      );
      f.repo.pendingDelete = null;
      await operationTap(tester, save);
      await tester.pumpAndSettle();
      expect(f.repo.deleteCalls, 2);
      expect(find.byType(DeleteMealPlanDialog), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Đã xóa kế hoạch. Nhật ký được giữ nguyên.'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Đã xóa kế hoạch. Nhật ký được giữ nguyên.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('delete cancel does not write', (tester) async {
    final f = PlanOperationsFixture();
    await f.start(tester);
    await f.remove(tester);
    await operationTap(tester, find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(f.repo.deleteCalls, 0);
    expect(find.byType(DeleteMealPlanDialog), findsNothing);
  });

  testWidgets(
    'changed plan remains open with conflict reason and can be cancelled',
    (tester) async {
      final f = PlanOperationsFixture();
      f.repo.deleteFailure = const FormatException(
        'Kế hoạch đã thay đổi. Hãy kiểm tra lại.',
      );
      await f.start(tester);
      await f.remove(tester);
      await operationTap(
        tester,
        find.byKey(const ValueKey('confirm-delete-plan')),
      );
      expect(
        find.text('Kế hoạch đã thay đổi. Hãy kiểm tra lại.'),
        findsOneWidget,
      );
      expect(find.byType(DeleteMealPlanDialog), findsOneWidget);
      await operationTap(tester, find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.byType(DeleteMealPlanDialog), findsNothing);
      expect(f.repo.deleteCalls, 1);
      expect(
        find.text('Đã xóa kế hoạch. Nhật ký được giữ nguyên.'),
        findsNothing,
      );
    },
  );

  for (final deletion in [true, false]) {
    testWidgets(
      '${deletion ? 'delete' : 'bulk'} controls remain reachable at 320px and 200% text',
      (tester) async {
        final f = PlanOperationsFixture();
        if (deletion) {
          f.repo.deleteFailure = StateError('Synthetic network failure');
        } else {
          f.repo.failAt = 2;
        }
        await f.start(
          tester,
          size: const Size(320, 844),
          scale: 2,
          mode: ThemeMode.dark,
        );
        if (deletion) {
          await f.remove(tester);
        } else {
          await f.suggest(tester);
        }
        final save = find.byKey(
          ValueKey(deletion ? 'confirm-delete-plan' : 'save-suggested-plans'),
        );
        await operationTap(tester, save);
        expect(
          find.byKey(
            ValueKey(deletion ? 'plan-delete-error' : 'suggestion-error'),
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(save);
        await tester.pump(const Duration(milliseconds: 300));
        expect(save.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
