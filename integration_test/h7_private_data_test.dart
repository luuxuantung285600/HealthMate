// Run ONLY through tool/test_h7_android.ps1; synthetic demo backend, no AI.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'support/emulator_email_actions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:healthmate/features/wellness/data/energy_repository.dart';
import 'package:healthmate/features/wellness/providers/energy_providers.dart';
import 'package:healthmate/app.dart';
import 'package:healthmate/features/premium/providers/play_billing_providers.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/core/data/private_local_data.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/auth/data/firebase_auth_repository.dart';
import 'package:healthmate/features/auth/data/firebase_account_data_repository.dart';
import 'package:healthmate/features/nutrition/data/firebase_nutrition_repository.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/profile/data/firebase_health_profile_repository.dart';
import 'package:healthmate/features/profile/models/onboarding_draft.dart';
import 'package:healthmate/features/profile/models/health_goal.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/water/data/firebase_water_repository.dart';
import 'package:healthmate/features/water/models/water_log.dart';
import 'package:healthmate/features/water/providers/water_providers.dart';
import 'package:healthmate/features/activity/data/firebase_activity_repository.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/activity/providers/activity_providers.dart';
import 'package:healthmate/features/goals/data/firebase_goals_repository.dart';
import 'package:healthmate/features/goals/providers/goals_providers.dart';
import 'package:healthmate/features/food_library/data/firebase_food_library_repository.dart';
import 'package:healthmate/features/food_library/data/firebase_favorite_food_repository.dart';
import 'package:healthmate/features/food_library/providers/food_library_providers.dart';
import 'package:healthmate/features/food_library/providers/favorite_food_providers.dart';
import 'package:healthmate/features/nutrition_targets/data/firebase_nutrition_target_repository.dart';
import 'package:healthmate/features/nutrition_targets/providers/nutrition_target_providers.dart';
import 'package:healthmate/features/meal_templates/data/meal_template_repository.dart';
import 'package:healthmate/features/meal_templates/providers/meal_template_providers.dart';
import 'package:healthmate/features/reports/data/day_review_repository.dart';
import 'package:healthmate/features/reports/providers/report_providers.dart';
import 'package:healthmate/features/meal_drafts/data/meal_draft_store.dart';
import 'package:healthmate/features/data_export/data/journal_export_service.dart';
import 'package:healthmate/features/data_export/models/journal_csv.dart';
import 'core_acceptance_test.dart' as ui;

const _password = 'Synthetic-H7-only-123!';
const _emailA = 'h7-process-alice@example.com',
    _emailB = 'h7-process-bob@example.com';

// Observation only: every storage/picker call still uses the real native channel.
class _ObservedAndroidLocal extends PrivateLocalData {
  Completer<void>? pickerStarted;
  @override
  Future<String?> chooseCsv(String filename) {
    final result = super.chooseCsv(filename);
    pickerStarted?.complete();
    pickerStarted = null;
    return result;
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const phase = int.fromEnvironment('HEALTHMATE_H7_PHASE');
  if (!Platform.isAndroid ||
      !const bool.fromEnvironment('HEALTHMATE_CORE_EMULATOR_TESTS') ||
      ![1, 2].contains(phase) ||
      const bool.fromEnvironment(
        'HEALTHMATE_ENABLE_CHATBOT',
        defaultValue: true,
      ) ||
      const bool.fromEnvironment(
        'HEALTHMATE_ENABLE_FOOD_SCANNER',
        defaultValue: true,
      )) {
    throw StateError('Use the guarded H7 QA runner.');
  }
  testWidgets(
    'H7 Android phase $phase real storage, SDK and document picker',
    (tester) async {
      final app = await Firebase.initializeApp(
        name: 'healthmate-h7-private-qa',
        options: const FirebaseOptions(
          apiKey: 'emulator-only-fake-api-key',
          appId: '1:1234567890:android:0123456789abcdef',
          messagingSenderId: '1234567890',
          projectId: 'demo-healthmate-rules',
        ),
      );
      final auth = FirebaseAuth.instanceFor(app: app);
      await auth.useAuthEmulator('10.0.2.2', 9099, automaticHostMapping: false);
      final db = FirebaseFirestore.instanceFor(app: app);
      db.settings = const Settings(persistenceEnabled: false);
      db.useFirestoreEmulator('10.0.2.2', 8080, automaticHostMapping: false);
      final nutrition = FirebaseNutritionRepository(db);
      final profile = FirebaseHealthProfileRepository(db);
      final water = FirebaseWaterRepository(db);
      final activity = FirebaseActivityRepository(db);
      if (phase == 1) {
        await auth.signOut();
        final cred = await auth.createUserWithEmailAndPassword(
          email: _emailA,
          password: _password,
        );
        await verifyEmulatorEmail(auth, projectId: 'demo-healthmate-rules');
        await profile.ensureProfile(uid: cred.user!.uid, email: _emailA);
        await profile.completeOnboarding(
          uid: cred.user!.uid,
          draft: OnboardingDraft(
            displayName: 'QA H7 Alice',
            birthDate: DateTime(2000, 1, 15),
            heightCm: 170,
            currentWeightKg: 70,
            healthGoal: HealthGoal.maintainWeight,
            targetWeightKg: null,
          ),
        );
      } else {
        await auth.signInWithEmailAndPassword(
          email: _emailA,
          password: _password,
        );
      }
      final alice = auth.currentUser!.uid;
      final nativeLocal = _ObservedAndroidLocal();
      final container = ProviderContainer(
        overrides: [
          playBillingSupportedProvider.overrideWithValue(false),
          privateLocalDataProvider.overrideWithValue(nativeLocal),
          authRepositoryProvider.overrideWithValue(
            FirebaseAuthRepository(auth),
          ),
          accountDataRepositoryProvider.overrideWithValue(
            FirebaseAccountDataRepository(db),
          ),
          healthProfileRepositoryProvider.overrideWithValue(profile),
          nutritionRepositoryProvider.overrideWithValue(nutrition),
          energyRepositoryProvider.overrideWithValue(
            FirebaseEnergyRepository(db),
          ),
          nutritionTargetRepositoryProvider.overrideWithValue(
            FirebaseNutritionTargetRepository(db),
          ),
          dayReviewRepositoryProvider.overrideWithValue(
            FirebaseDayReviewRepository(db),
          ),
          foodLibraryRepositoryProvider.overrideWithValue(
            FirebaseFoodLibraryRepository(db),
          ),
          mealTemplateRepositoryProvider.overrideWithValue(
            FirebaseMealTemplateRepository(db),
          ),
          favoriteFoodRepositoryProvider.overrideWithValue(
            FirebaseFavoriteFoodRepository(db),
          ),
          waterRepositoryProvider.overrideWithValue(water),
          activityRepositoryProvider.overrideWithValue(activity),
          goalsRepositoryProvider.overrideWithValue(
            FirebaseGoalsRepository(db),
          ),
        ],
      );
      addTearDown(() async {
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
        container.dispose();
        await db.enableNetwork();
        await db.terminate();
        // Phase 1 keeps local app data and the synthetic backend for process death.
        await app.delete();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HealthMateApp(),
        ),
      );
      await ui.waitFor(tester, ui.keyed('nav-journal'));
      await ui.tap(tester, ui.keyed('nav-journal'));
      await ui.waitFor(tester, ui.keyed('open-meal-drafts'));
      final store = container.read(mealDraftStoreProvider);
      final local = container.read(privateLocalDataProvider);
      final today = localDateOnly(DateTime.now()),
          tomorrow = localDateOnly(DateTime.now()).add(const Duration(days: 1));
      if (phase == 1) {
        expect(await store.list(alice), isEmpty);
        await ui.tap(tester, ui.keyed('open-meal-drafts'));
        await ui.waitFor(tester, find.byType(MealFormDialog));
        await ui.tap(tester, ui.keyed('open-quick-add'));
        await ui.enter(tester, 'quick-name', '=QA Sữa, "Việt"');
        await ui.enter(tester, 'quick-kcal', '150');
        await ui.enter(tester, 'quick-fiber', '3');
        await ui.tap(tester, ui.keyed('confirm-quick-add'));
        await ui.waitFor(tester, find.textContaining('Đã giữ mã hóa'));
        final drafts = await store.list(alice);
        expect(drafts, hasLength(1));
        expect(drafts.single.draft.items.single.nutrition.proteinKnown, false);
        expect(drafts.single.draft.totals.fiberG, 3);
        expect(await nutrition.loadRange(alice, today, tomorrow), isEmpty);
        debugPrint('H7_PHASE1_DRAFT_DURABLE_NO_SERVER_WRITE');
        return;
      }
      final restored = (await store.list(alice)).single;
      expect(restored.draft.items.single.name, '=QA Sữa, "Việt"');
      expect(restored.draft.totals.fiberG, 3);
      expect(restored.draft.totals.proteinKnown, false);
      expect(await nutrition.loadRange(alice, today, tomorrow), isEmpty);
      await ui.tap(tester, ui.keyed('open-meal-drafts'));
      await ui.waitFor(
        tester,
        ui.keyed('restore-draft-${restored.operationId}'),
      );
      await ui.tap(tester, ui.keyed('restore-draft-${restored.operationId}'));
      await ui.waitFor(tester, find.byType(MealFormDialog));
      await ui.waitFor(tester, find.textContaining('Đã giữ mã hóa'));
      expect(await nutrition.loadRange(alice, today, tomorrow), isEmpty);
      // Reproduce the commit-before-client-ack window with the SAME durable ID.
      await db.disableNetwork();
      await ui.tap(tester, ui.keyed('save-meal'));
      await ui.waitFor(
        tester,
        find.textContaining('Chưa thể lưu. Thông tin vẫn'),
      );
      expect(
        (await store.list(alice)).single.operationId,
        restored.operationId,
      );
      await db.enableNetwork();
      final afterReconnect = await nutrition.loadRange(alice, today, tomorrow);
      // A failed/uncertain native SDK acknowledgement is not proof of no commit.
      expect(afterReconnect.length, lessThanOrEqualTo(1));
      expect(afterReconnect.every((m) => m.id == restored.operationId), true);
      debugPrint('H7_OFFLINE_SAVE_PRESERVES_DURABLE_DRAFT');
      await nutrition.addMeal(
        uid: alice,
        draft: restored.draft,
        operationId: restored.operationId,
      );
      await ui.tap(tester, ui.keyed('save-meal'));
      await ui.waitFor(tester, find.byType(MealFormDialog), absent: true);
      final meals = await nutrition.loadRange(alice, today, tomorrow);
      expect(meals, hasLength(1));
      expect(meals.single.id, restored.operationId);
      expect(await store.list(alice), isEmpty);
      debugPrint('H7_PHASE2_RECOVERY_AND_IDEMPOTENT_RETRY_PASSED');
      await water.add(
        uid: alice,
        draft: WaterLogDraft(amountMl: 250, consumedAt: DateTime.now()),
      );
      await activity.add(
        uid: alice,
        draft: ActivityLogDraft(
          type: ActivityType.walking,
          durationMinutes: 20,
          performedAt: DateTime.now(),
          note: '@QA note',
        ),
      );

      // UI privacy consent -> actual Android Storage Access Framework picker.
      await ui.tap(tester, ui.keyed('nav-profile'));
      await ui.tap(tester, ui.keyed('open-journal-export'));
      await ui.tap(tester, ui.keyed('export-consent'));
      debugPrint('H7_EXPORT_PICKER_READY');
      await ui.tap(tester, ui.keyed('export-csv'));
      final deadline = DateTime.now().add(const Duration(seconds: 90));
      while (find.textContaining('Đã lưu và đọc lại').evaluate().isEmpty) {
        if (DateTime.now().isAfter(deadline)) {
          fail('Native document picker/write did not complete.');
        }
        await tester.pump(const Duration(milliseconds: 250));
      }
      debugPrint('H7_EXPORT_OS_PICKER_READBACK_PASSED');
      final exportStart = DateTime(today.year, today.month, today.day - 6);
      final expectedCsv = buildJournalCsv(
        start: exportStart,
        endExclusive: tomorrow,
        meals: await nutrition.loadRange(alice, exportStart, tomorrow),
        water: await water.loadRange(alice, exportStart, tomorrow),
        activities: await activity.loadRange(alice, exportStart, tomorrow),
        weights: await profile.loadBodyMetricsRange(
          alice,
          exportStart,
          tomorrow,
        ),
      );
      await File(
        '/data/data/com.example.healthmate/cache/h7-expected.csv',
      ).writeAsBytes(utf8.encode(expectedCsv));
      await tester.pump(const Duration(milliseconds: 500));
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('c6-h7-export');
      await ui.tap(tester, find.byIcon(Icons.close).last);

      await store.put(
        alice,
        SavedMealDraft(
          operationId: 'h7-a-private',
          draft: restored.draft,
          updatedAt: DateTime.now(),
        ),
      );
      final credB = await auth.createUserWithEmailAndPassword(
        email: _emailB,
        password: _password,
      );
      final bob = credB.user!.uid;
      await verifyEmulatorEmail(auth, projectId: 'demo-healthmate-rules');
      await profile.ensureProfile(uid: bob, email: _emailB);
      await profile.completeOnboarding(
        uid: bob,
        draft: OnboardingDraft(
          displayName: 'QA H7 Bob',
          birthDate: DateTime(2000, 1, 15),
          heightCm: 170,
          currentWeightKg: 70,
          healthGoal: HealthGoal.maintainWeight,
          targetWeightKg: null,
        ),
      );
      await ui.waitFor(tester, ui.keyed('nav-journal'));
      await ui.tap(tester, ui.keyed('nav-journal'));
      await ui.tap(tester, ui.keyed('open-meal-drafts'));
      await ui.waitFor(tester, find.byType(MealFormDialog));
      expect(find.textContaining('=QA Sữa'), findsNothing);
      await ui.tap(tester, find.byTooltip('Hủy'));
      expect((await store.list(bob)).single.draft.items, isEmpty);
      await expectLater(
        nutrition.loadRange(alice, today, tomorrow),
        throwsA(anything),
      );
      expect(await nutrition.loadRange(bob, today, tomorrow), isEmpty);
      debugPrint('H7_B_CANNOT_READ_A_SERVER_OR_DRAFT_UI');

      // Switching UID while the native picker is open must produce no private bytes.
      await auth.signInWithEmailAndPassword(
        email: _emailA,
        password: _password,
      );
      await tester.pump(const Duration(seconds: 1));
      container.read(appRouterProvider).go(AppRoutes.profile);
      await ui.waitFor(tester, ui.keyed('open-journal-export'));
      var rejected = false;
      await tester.runAsync(() async {
        final pickerStarted = Completer<void>();
        nativeLocal.pickerStarted = pickerStarted;
        final observed = container
            .read(journalExportServiceProvider)
            .export(today, tomorrow)
            .then(
              (_) {},
              onError: (Object error) {
                rejected = true;
              },
            );
        await pickerStarted.future.timeout(const Duration(seconds: 35));
        await auth.signInWithEmailAndPassword(
          email: _emailB,
          password: _password,
        );
        debugPrint('H7_EXPORT_SWITCH_PICKER_READY');
        await observed.timeout(const Duration(seconds: 90));
      });
      await tester.pump(const Duration(milliseconds: 500));
      expect(rejected, true);
      debugPrint('H7_EXPORT_UID_SWITCH_REJECTED');
      await auth.signInWithEmailAndPassword(
        email: _emailA,
        password: _password,
      );
      await tester.pump(const Duration(seconds: 1));
      final deletion = container
          .read(accountSecurityControllerProvider.notifier)
          .deleteAccount(_password);
      // Let Auth/provider streams and the async deletion settle without fake SDKs.
      var deleted = false;
      final deleteObserved = deletion.then((v) => deleted = v);
      final deleteEnd = DateTime.now().add(const Duration(seconds: 45));
      while (auth.currentUser != null) {
        if (DateTime.now().isAfter(deleteEnd)) {
          fail('Account deletion did not complete.');
        }
        await tester.pump(const Duration(milliseconds: 250));
      }
      await deleteObserved;
      expect(deleted, true);
      expect(await local.read(alice), isNull);
      expect(await local.read(bob), isNotNull);
      await auth.signInWithEmailAndPassword(
        email: _emailB,
        password: _password,
      );
      await tester.pump(const Duration(seconds: 1));
      expect((await store.list(bob)).single.draft.items, isEmpty);
      await container
          .read(accountSecurityControllerProvider.notifier)
          .deleteAccount(_password);
      expect(await local.read(bob), isNull);
      debugPrint('H7_OWN_UID_LOCAL_AND_FIRESTORE_CLEANUP_PASSED');
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 7)),
  );
}
