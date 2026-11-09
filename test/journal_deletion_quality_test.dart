import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/activity/providers/activity_providers.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/journal/presentation/delete_journal_entry_dialog.dart';
import 'package:healthmate/features/journal/presentation/journal_screen.dart';
import 'package:healthmate/features/journal/providers/journal_date_provider.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:healthmate/features/profile/models/user_profile.dart';
import 'package:healthmate/features/water/models/water_log.dart';
import 'package:healthmate/features/water/providers/water_providers.dart';

import 'support/fake_activity_repository.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/test_app.dart';

final journalAt = DateTime(2026, 11, 7, 12, 30);
const anotherUser = AuthUser(
  uid: 'other-uid',
  email: 'other@example.test',
  emailVerified: true,
);

class DeleteGate {
  Completer<void>? pending;
  bool fail = false;
  bool applyBeforeFailure = false;
  final attempts = <({String uid, String id})>[];

  Future<void> run(
    String uid,
    String id,
    Future<void> Function() commit,
  ) async {
    attempts.add((uid: uid, id: id));
    await pending?.future;
    if (fail && !applyBeforeFailure) throw StateError('Fixture write rejected');
    await commit();
    if (fail) throw StateError('Fixture ACK not received');
  }
}

MealLog journalMeal(String id) {
  final item = MealItemSnapshot.fromCatalog(
    id == 'target' ? FakeNutritionRepository.rice : FakeNutritionRepository.egg,
    100,
  );
  return MealLog(
    id: id,
    type: MealType.lunch,
    consumedAt: journalAt,
    items: [item],
    totals: item.nutrition,
    source: MealSource.manual,
    dateKey: localDateKey(journalAt),
    timezoneOffsetMinutes: journalAt.timeZoneOffset.inMinutes,
  );
}

WaterLog journalWater(String id) => WaterLog(
  id: id,
  amountMl: id == 'target' ? 350 : 200,
  consumedAt: journalAt,
  dateKey: localDateKey(journalAt),
  timezoneOffsetMinutes: journalAt.timeZoneOffset.inMinutes,
);

ActivityLog journalActivity(String id) => ActivityLog(
  id: id,
  type: ActivityType.walking,
  durationMinutes: id == 'target' ? 30 : 15,
  performedAt: journalAt,
  dateKey: localDateKey(journalAt),
  timezoneOffsetMinutes: journalAt.timeZoneOffset.inMinutes,
  note: '',
);

class DeleteNutritionRepository extends FakeNutritionRepository {
  DeleteNutritionRepository(this.gate)
    : super(meals: [journalMeal('target'), journalMeal('keep')]);
  final DeleteGate gate;
  @override
  Future<void> deleteMeal({required String uid, required String mealId}) =>
      gate.run(uid, mealId, () => super.deleteMeal(uid: uid, mealId: mealId));
}

class DeleteWaterRepository extends FakeWaterRepository {
  DeleteWaterRepository(this.gate)
    : super(logs: [journalWater('target'), journalWater('keep')]);
  final DeleteGate gate;
  @override
  Future<void> delete({required String uid, required String logId}) =>
      gate.run(uid, logId, () => super.delete(uid: uid, logId: logId));
}

class DeleteActivityRepository extends FakeActivityRepository {
  DeleteActivityRepository(this.gate)
    : super(logs: [journalActivity('target'), journalActivity('keep')]);
  final DeleteGate gate;
  @override
  Future<void> delete({required String uid, required String logId}) =>
      gate.run(uid, logId, () => super.delete(uid: uid, logId: logId));
}

class JournalDeletionFixture {
  JournalDeletionFixture() {
    nutrition = DeleteNutritionRepository(gate);
    water = DeleteWaterRepository(gate);
    activity = DeleteActivityRepository(gate);
  }
  final gate = DeleteGate();
  final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
  final profiles = FakeHealthProfileRepository(
    profile: FakeHealthProfileRepository.testProfile,
  );
  late final DeleteNutritionRepository nutrition;
  late final DeleteWaterRepository water;
  late final DeleteActivityRepository activity;
  late final ProviderContainer container;

  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double scale = 1,
    ThemeMode mode = ThemeMode.system,
    GlobalKey? captureKey,
  }) async {
    container = await pumpApp(
      tester,
      repository: auth,
      profileRepository: profiles,
      nutritionRepository: nutrition,
      waterRepository: water,
      activityRepository: activity,
      size: size,
      textScale: scale,
      initialThemeMode: mode,
      captureKey: captureKey,
    );
    container.read(journalDateProvider.notifier).select(journalAt);
    container.read(appRouterProvider).go(AppRoutes.journal);
    await tester.pumpAndSettle();
  }

  Future<List<String>> records(String kind) async {
    final end = DateTime(journalAt.year, journalAt.month, journalAt.day + 1);
    return switch (kind) {
      'meal' => nutrition.meals.map((m) => m.id).toList(),
      'water' => (await water.loadRange(
        'test-uid',
        journalAt,
        end,
      )).map((l) => l.id).toList(),
      _ => (await activity.loadRange(
        'test-uid',
        journalAt,
        end,
      )).map((l) => l.id).toList(),
    };
  }

  void switchAccount() {
    final p = FakeHealthProfileRepository.testProfile;
    profiles.emitProfile(
      UserProfile(
        uid: anotherUser.uid,
        displayName: p.displayName,
        email: anotherUser.email!,
        heightCm: p.heightCm,
        birthDate: p.birthDate,
        healthGoal: p.healthGoal,
        targetWeightKg: p.targetWeightKg,
        onboardingCompletedAt: p.onboardingCompletedAt,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
        schemaVersion: p.schemaVersion,
      ),
    );
    auth.emitUser(anotherUser);
  }

  void expectRemainingTotal(String kind) {
    switch (kind) {
      case 'meal':
        expect(
          totalMealNutrition(
            container
                .read(mealLogsProvider(localDateOnly(journalAt)))
                .requireValue,
          ).kcal,
          155,
        );
      case 'water':
        expect(
          totalWaterMl(
            container
                .read(waterLogsProvider(localDateKey(journalAt)))
                .requireValue,
          ),
          200,
        );
      case 'activity':
        expect(
          totalActivityMinutes(
            container
                .read(activityLogsProvider(localDateKey(journalAt)))
                .requireValue,
          ),
          15,
        );
    }
  }

  Future<void> keepJournalMountedAcrossSessions(WidgetTester tester) async {
    // Keep the real journal mounted without router redirects disposing it. This
    // exercises the stale popup callback itself, rather than a route teardown.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const Scaffold(body: JournalScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> tapJournalVisible(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      240,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> openDeleteMenu(WidgetTester tester, String kind) async {
  if (kind == 'activity') {
    final disclosure = find.byKey(const ValueKey('journal-activity-details'));
    await tapJournalVisible(
      tester,
      find.descendant(of: disclosure, matching: find.byType(ExpansionTile)),
    );
  }
  final row = find.byKey(ValueKey('$kind-log-target'));
  await tapJournalVisible(
    tester,
    find.descendant(of: row, matching: find.byType(PopupMenuButton<String>)),
  );
}

String titleFor(String kind) => switch (kind) {
  'meal' => 'Xóa bữa ăn?',
  'water' => 'Xóa lần uống nước?',
  _ => 'Xóa hoạt động?',
};

Future<void> openDelete(WidgetTester tester, String kind) async {
  await openDeleteMenu(tester, kind);
  await tapJournalVisible(tester, find.text('Xóa'));
  expect(find.text(titleFor(kind)), findsOneWidget);
}

void main() {
  for (final kind in ['meal', 'water', 'activity']) {
    testWidgets(
      '$kind delete reviews the exact entry and Cancel never writes',
      (tester) async {
        final fixture = JournalDeletionFixture();
        await fixture.open(tester);
        await openDelete(tester, kind);
        expect(find.textContaining('07/11/2026 · 12:30'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(DeleteJournalEntryDialog),
            matching: find.textContaining(switch (kind) {
              'meal' => FakeNutritionRepository.rice.name,
              'water' => '350 ml',
              _ => 'Đi bộ · 30 phút',
            }),
          ),
          findsOneWidget,
        );
        await tapJournalVisible(tester, find.text('Hủy'));
        expect(find.byType(DeleteJournalEntryDialog), findsNothing);
        expect(fixture.gate.attempts, isEmpty);
        expect(await fixture.records(kind), ['target', 'keep']);
      },
    );

    testWidgets(
      '$kind delete waits for ACK, prevents duplicates and retries the same record',
      (tester) async {
        final fixture = JournalDeletionFixture();
        fixture.gate.pending = Completer<void>();
        await fixture.open(tester);
        await openDelete(tester, kind);
        final confirm = find.byKey(const ValueKey('confirm-delete-journal'));
        await tester.tap(confirm);
        await tester.pump();
        await tester.tap(confirm, warnIfMissed: false);
        await tester.pump();
        expect(fixture.gate.attempts, [(uid: 'test-uid', id: 'target')]);
        expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.byType(DeleteJournalEntryDialog), findsOneWidget);
        expect(await fixture.records(kind), ['target', 'keep']);
        fixture.gate.fail = true;
        fixture.gate.pending!.complete();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('journal-delete-error')),
          findsOneWidget,
        );
        expect(await fixture.records(kind), ['target', 'keep']);
        fixture.gate.pending = null;
        fixture.gate.fail = false;
        await tapJournalVisible(tester, confirm);
        expect(fixture.gate.attempts, [
          (uid: 'test-uid', id: 'target'),
          (uid: 'test-uid', id: 'target'),
        ]);
        expect(find.byType(DeleteJournalEntryDialog), findsNothing);
        expect(await fixture.records(kind), ['keep']);
        expect(find.byKey(ValueKey('$kind-log-target')), findsNothing);
        fixture.expectRemainingTotal(kind);
      },
    );

    testWidgets('$kind confirmation closes on account switch without a write', (
      tester,
    ) async {
      final fixture = JournalDeletionFixture();
      await fixture.open(tester);
      await openDelete(tester, kind);
      fixture.switchAccount();
      await tester.pumpAndSettle();
      expect(find.byType(DeleteJournalEntryDialog), findsNothing);
      expect(fixture.gate.attempts, isEmpty);
      expect(await fixture.records(kind), ['target', 'keep']);
    });

    testWidgets(
      '$kind rejects confirmation immediately when Auth UID changes before its stream publishes',
      (tester) async {
        final fixture = JournalDeletionFixture();
        await fixture.open(tester);
        await openDelete(tester, kind);
        final confirm = tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('confirm-delete-journal')),
            )
            .onPressed!;
        fixture.switchAccount();
        // Invoke before the auth StreamProvider has delivered the new session.
        confirm();
        await tester.pumpAndSettle();
        expect(fixture.gate.attempts, isEmpty);
        expect(find.byType(DeleteJournalEntryDialog), findsNothing);
      },
    );

    testWidgets(
      '$kind menu from the old account cannot open a delete in the next account',
      (tester) async {
        final fixture = JournalDeletionFixture();
        await fixture.open(tester);
        await fixture.keepJournalMountedAcrossSessions(tester);
        final journalState = tester.state(find.byType(JournalScreen));
        await openDeleteMenu(tester, kind);
        fixture.switchAccount();
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(JournalScreen)), same(journalState));
        expect(find.text('Xóa'), findsOneWidget);
        await tapJournalVisible(tester, find.text('Xóa'));
        expect(find.byType(DeleteJournalEntryDialog), findsNothing);
        expect(fixture.gate.attempts, isEmpty);
      },
    );

    testWidgets(
      '$kind pending delete cannot publish late success after logout',
      (tester) async {
        final fixture = JournalDeletionFixture();
        fixture.gate.pending = Completer<void>();
        await fixture.open(tester);
        await openDelete(tester, kind);
        await tester.tap(find.byKey(const ValueKey('confirm-delete-journal')));
        await tester.pump();
        fixture.auth.emitUser(null);
        await tester.pumpAndSettle();
        expect(find.byType(DeleteJournalEntryDialog), findsNothing);
        fixture.gate.pending!.complete();
        await tester.pumpAndSettle();
        expect(find.textContaining('Đã xóa'), findsNothing);
        expect(fixture.gate.attempts, [(uid: 'test-uid', id: 'target')]);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '$kind retry after an unconfirmed applied delete is idempotent',
      (tester) async {
        final fixture = JournalDeletionFixture();
        fixture.gate
          ..fail = true
          ..applyBeforeFailure = true;
        await fixture.open(tester);
        await openDelete(tester, kind);
        final confirm = find.byKey(const ValueKey('confirm-delete-journal'));
        await tapJournalVisible(tester, confirm);
        expect(await fixture.records(kind), ['keep']);
        expect(
          find.byKey(const ValueKey('journal-delete-error')),
          findsOneWidget,
        );
        fixture.gate.fail = false;
        await tapJournalVisible(tester, confirm);
        expect(fixture.gate.attempts, [
          (uid: 'test-uid', id: 'target'),
          (uid: 'test-uid', id: 'target'),
        ]);
        expect(await fixture.records(kind), ['keep']);
        expect(find.byType(DeleteJournalEntryDialog), findsNothing);
      },
    );
  }
}
