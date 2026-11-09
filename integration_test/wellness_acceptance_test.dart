// Synthetic Android/backend only. Never initializes the default Firebase app.
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/core/data/user_data_revision.dart';
import 'package:healthmate/features/auth/data/firebase_auth_repository.dart';
import 'package:healthmate/features/auth/data/firebase_account_data_repository.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/nutrition/data/food_local_database.dart';
import 'package:healthmate/features/nutrition/data/bundled_vietnamese_foods.dart';
import 'package:healthmate/features/nutrition/data/firebase_nutrition_repository.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:healthmate/features/wellness/data/wellness_device.dart';
import 'package:healthmate/features/wellness/data/wellness_repository.dart';
import 'package:healthmate/features/wellness/data/energy_repository.dart';
import 'package:healthmate/features/wellness/presentation/energy_panel.dart';
import 'package:healthmate/features/wellness/providers/sleep_insight_providers.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/wellness/providers/energy_providers.dart';
import 'package:healthmate/features/nutrition_targets/data/firebase_nutrition_target_repository.dart';
import 'package:healthmate/features/nutrition_targets/providers/nutrition_target_providers.dart';
import 'package:healthmate/features/profile/data/firebase_health_profile_repository.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/activity/data/firebase_activity_repository.dart';
import 'package:healthmate/features/activity/providers/activity_providers.dart';
import 'package:healthmate/features/wellness/models/wellness_models.dart';
import 'package:healthmate/features/wellness/presentation/wellness_screen.dart';
import 'package:healthmate/features/wellness/providers/wellness_providers.dart';
import 'core_acceptance_test.dart' as ui;
import 'support/emulator_email_actions.dart';

Widget routedWellness(Widget screen) {
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (context, state) => screen)],
  );
  addTearDown(router.dispose);
  return MaterialApp.router(
    theme: AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('vi')],
    routerConfig: router,
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isAndroid ||
      !const bool.fromEnvironment('HEALTHMATE_CORE_EMULATOR_TESTS') ||
      const bool.fromEnvironment(
        'HEALTHMATE_ENABLE_CHATBOT',
        defaultValue: true,
      ) ||
      const bool.fromEnvironment(
        'HEALTHMATE_ENABLE_FOOD_SCANNER',
        defaultValue: true,
      )) {
    throw StateError(
      'Use the dedicated QA runner with the demo backend and explicit AI=false.',
    );
  }
  testWidgets(
    'Android wellness: native notification, sleep, plans, nutrition and UID isolation',
    (tester) async {
      const project = 'demo-healthmate-rules',
          password = 'Synthetic-wellness-123!';
      final app = await Firebase.initializeApp(
        name: 'healthmate-wellness-qa',
        options: const FirebaseOptions(
          apiKey: 'emulator-only-fake-api-key',
          appId: '1:1234567890:android:0123456789abcdef',
          messagingSenderId: '1234567890',
          projectId: project,
        ),
      );
      final auth = FirebaseAuth.instanceFor(app: app);
      await auth.useAuthEmulator('10.0.2.2', 9099, automaticHostMapping: false);
      final db = FirebaseFirestore.instanceFor(app: app);
      db.settings = const Settings(persistenceEnabled: false);
      db.useFirestoreEmulator('10.0.2.2', 8080, automaticHostMapping: false);
      await auth.signOut();
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final a = await auth.createUserWithEmailAndPassword(
        email: 'wellness-a-$suffix@example.test',
        password: password,
      );
      await verifyEmulatorEmail(auth, projectId: project);
      final alice = a.user!.uid,
          nutrition = FirebaseNutritionRepository(db),
          repo = WellnessRepository(db);
      final device = WellnessDevice();
      final container = ProviderContainer(
        overrides: [
          realtimeFirestoreProvider.overrideWithValue(db),
          authRepositoryProvider.overrideWithValue(
            FirebaseAuthRepository(auth),
          ),
          accountDataRepositoryProvider.overrideWithValue(
            FirebaseAccountDataRepository(db),
          ),
          nutritionRepositoryProvider.overrideWithValue(nutrition),
          wellnessRepositoryProvider.overrideWithValue(repo),
          wellnessDeviceProvider.overrideWithValue(device),
          energyRepositoryProvider.overrideWithValue(
            FirebaseEnergyRepository(db),
          ),
          healthProfileRepositoryProvider.overrideWithValue(
            FirebaseHealthProfileRepository(db),
          ),
          nutritionTargetRepositoryProvider.overrideWithValue(
            FirebaseNutritionTargetRepository(db),
          ),
          activityRepositoryProvider.overrideWithValue(
            FirebaseActivityRepository(db),
          ),
        ],
      );
      final bootstrap = container.listen(wellnessBootstrapProvider, (_, _) {});
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        bootstrap.close();
        container.dispose();
        await device.setAccount(null);
        await db.enableNetwork();
        await db.terminate();
        await auth.signOut();
        await app.delete();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: routedWellness(const WellnessScreen()),
        ),
      );
      Future<void> until(bool Function() condition) async {
        final deadline = DateTime.now().add(const Duration(seconds: 25));
        while (!condition()) {
          if (DateTime.now().isAfter(deadline)) {
            fail('Wellness state did not settle.');
          }
          await tester.pump(const Duration(milliseconds: 150));
        }
      }

      var converted = false;
      Future<void> capture(String name) async {
        if (!converted) {
          await binding.convertFlutterSurfaceToImage();
          converted = true;
        }
        await tester.pump(const Duration(milliseconds: 400));
        await binding.takeScreenshot('c6-wellness-$name');
      }

      await until(
        () => container.read(localWellnessProvider).value?.uid == alice,
      );
      expect(await device.notificationsAllowed(), true); // Dedicated API30 AVD.
      final r = defaultMealReminders.first;
      await container.read(localWellnessProvider.notifier).saveReminders([
        MealReminder(
          r.meal,
          (DateTime.now().hour * 60 + DateTime.now().minute + 5) % 1440,
          enabled: true,
        ),
        ...defaultMealReminders.skip(1),
      ]);
      await tester.pump(const Duration(milliseconds: 300));
      await device.testReminder(alice);
      await tester.pump(const Duration(milliseconds: 400));
      expect(await device.activeNotificationIds(alice), contains(5100));
      debugPrint('WELLNESS_ALARMS_READY native notification posted');
      await capture('reminders');
      const food = FoodCatalogItem(
        id: 'wellness-native-fixture',
        name: 'Wellness fixture',
        category: 'Synthetic QA',
        servingBasis: ServingBasis.per100g,
        sourceLabel: 'Synthetic',
        isEstimated: true,
        per100g: NutritionTotals(
          kcal: 100,
          proteinG: 10,
          carbsG: 10,
          fatG: 2,
          fiberKnown: true,
          extraNutrients: {'sodium': 120, 'sugar': 0},
        ),
      );
      final now = DateTime.now();
      await nutrition.addMeal(
        uid: alice,
        draft: MealDraft(
          type: MealType.breakfast,
          consumedAt: now,
          items: [MealItemSnapshot.fromCatalog(food, 150)],
          source: MealSource.manual,
        ),
      );
      var cleared = false;
      for (var i = 0; i < 30 && !cleared; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        cleared = !(await device.activeNotificationIds(alice)).contains(5100);
      }
      expect(cleared, true);
      expect(await device.readSettings(alice), hasLength(4));
      debugPrint('WELLNESS_NOTIFICATION posted and cleared after actual meal');

      final cache = FoodLocalDatabase.instance;
      await cache.cacheFood(food);
      final stored = (await cache.getFoodById(food.id))!;
      expect(stored.nutritionPer100g.extraNutrients['sodium'], 120);
      final bundled = await loadBundledVietnameseFoods();
      await cache.cacheFoodsBatch(bundled);
      expect(
        (await cache.searchFoods(
          'com tam suon trung',
        )).any((f) => f.id == 'vn-com-suon-trung' && f.hasValidServing),
        true,
      );
      final version = await (await cache.database).rawQuery(
        'PRAGMA user_version',
      );
      expect(version.single['user_version'], 3);
      debugPrint(
        'WELLNESS_SQLITE v3 nutrients aliases and reference portion roundtrip',
      );

      await ui.tap(tester, ui.keyed('hub-sleep'));
      await ui.waitFor(tester, ui.keyed('start-sleep'));
      await ui.tap(tester, ui.keyed('start-sleep'));
      await ui.waitFor(tester, ui.keyed('finish-sleep'));
      final started = (await repo.watchSleepStart(alice).first)!;
      await ui.tap(tester, ui.keyed('finish-sleep'));
      await ui.waitFor(tester, ui.keyed('save-sleep'));
      await ui.tap(tester, ui.keyed('save-sleep'));
      await ui.waitFor(tester, find.byType(SleepTimeDialog), absent: true);
      expect((await repo.watchSleepLogs(alice).first), hasLength(1));
      expect(
        (await db
                .doc('users/$alice/wellness_state/sleep')
                .get(const GetOptions(source: Source.server)))
            .exists,
        false,
      );
      expect((await repo.watchSleepLogs(alice).first).single.start, started);
      await capture('sleep');
      debugPrint('WELLNESS_SLEEP actual UI start confirm save history');
      await ui.tap(tester, ui.keyed('configure-sleep-goal'));
      await ui.enter(tester, 'step-length', '75');
      await ui.enter(tester, 'baseline-steps', '4000');
      await ui.enter(tester, 'sleep-goal-hours', '8');
      await ui.tap(tester, ui.keyed('save-wellness-preferences'));
      await ui.waitFor(
        tester,
        find.byType(WellnessPreferencesDialog),
        absent: true,
      );
      expect(
        (await container
                .read(energyRepositoryProvider)
                .watchPreferences(alice)
                .first)
            .sleepGoalMinutes,
        480,
      );
      await ui.tap(tester, ui.keyed('bedtime-enabled'));
      await ui.waitFor(tester, ui.keyed('test-bedtime'));
      await ui.tap(tester, ui.keyed('test-bedtime'));
      expect(await device.activeNotificationIds(alice), contains(7300));
      expect((await device.readSleepReminder(alice)).enabled, true);
      expect((await device.readSettings(alice)).first.enabled, true);
      await repo.saveSleep(
        alice,
        now.subtract(const Duration(hours: 9)),
        now.subtract(const Duration(hours: 1)),
        id: 'insight-night-a',
      );
      await repo.saveSleep(
        alice,
        now.subtract(const Duration(hours: 33)),
        now.subtract(const Duration(hours: 25)),
        id: 'insight-night-b',
      );
      container.invalidate(sleepRangeProvider);
      await ui.tap(tester, ui.keyed('sleep-window-30'));
      await ui.waitFor(
        tester,
        find.textContaining('/30 ngày · tính theo ngày thức dậy'),
      );
      await capture('sleep-insights');
      debugPrint(
        'WELLNESS_INSIGHTS preferences, native bedtime notification and 30-day sleep chart',
      );

      await ui.tap(tester, ui.keyed('wellness-tab-1'));
      await ui.waitFor(tester, find.byTooltip('7 ngày sau'));
      await ui.tap(tester, find.byTooltip('7 ngày sau'));
      await ui.tap(tester, find.byTooltip('Chỉnh kế hoạch').first);
      await ui.waitFor(tester, ui.keyed('plan-food-search'));
      await tester.enterText(ui.keyed('plan-food-search'), 'pho bo');
      await tester.pump(const Duration(milliseconds: 200));
      final pho = bundled.singleWhere((f) => f.id == 'vn-pho-bo');
      await ui.tap(tester, find.text(pho.name).first);
      await ui.enter(tester, 'meal-grams', '300');
      await ui.tap(tester, find.widgetWithText(FilledButton, 'Xác nhận'));
      await ui.tap(tester, ui.keyed('save-meal-plan'));
      await ui.waitFor(tester, find.byType(PlanMealDialog), absent: true);
      final future = DateTime(now.year, now.month, now.day + 7);
      final plans = await repo.watchPlans(alice, future).first;
      expect(plans.single.items.single.grams, 300);
      expect(
        await nutrition.loadRange(
          alice,
          future,
          DateTime(future.year, future.month, future.day + 1),
        ),
        isEmpty,
      );
      await capture('plans');
      debugPrint('WELLNESS_PLAN future meal saved separately from journal');

      await ui.tap(tester, ui.keyed('wellness-tab-4'));
      await ui.waitFor(tester, find.text('180 mg'));
      expect(find.text('0 g'), findsOneWidget);
      expect(find.text('Chưa có dữ liệu'), findsWidgets);
      await capture('nutrients');
      debugPrint(
        'WELLNESS_NUTRIENTS schema5 native load and truthful missing values',
      );
      await ui.tap(tester, ui.keyed('wellness-tab-2'));
      final steps = await device.steps(alice);
      debugPrint('WELLNESS_STEP_SENSOR supported=${steps['supported']}');
      if (steps['supported'] != true) {
        await ui.waitFor(tester, find.textContaining('chưa cung cấp cảm biến'));
        expect(steps['days'], isNull);
      }
      await capture('steps');

      // Synthetic steps exercise the budget UI; never pretend the AVD has a sensor.
      final testNow = DateTime.now();
      await FirebaseHealthProfileRepository(db).addBodyMetric(
        uid: alice,
        draft: BodyMetricDraft(
          weightKg: 70,
          // Fixture is an earlier measurement, independent of AVD/server clock skew.
          measuredAt: testNow.subtract(const Duration(hours: 1)),
          note: 'Synthetic acceptance fixture',
        ),
      );
      await FirebaseNutritionTargetRepository(db).save(
        alice,
        NutritionTarget(
          effectiveFromDateKey: localDateKey(testNow),
          kcalTarget: 1800,
        ),
      );
      container.invalidate(nutritionTargetProvider(localDateKey(testNow)));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('vi'),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('vi')],
            home: const Scaffold(
              body: SingleChildScrollView(child: StepEnergyCard(steps: 6000)),
            ),
          ),
        ),
      );
      await ui.tap(tester, ui.keyed('confirm-step-budget'));
      await ui.enter(tester, 'step-adjustment-kcal', '50');
      await ui.tap(tester, ui.keyed('ack-step-budget'));
      await ui.tap(tester, ui.keyed('save-step-budget'));
      await ui.waitFor(tester, find.byType(StepAdjustmentDialog), absent: true);
      expect(
        (await container
                .read(energyRepositoryProvider)
                .watchAdjustment(alice, localDateKey(testNow))
                .first)!
            .kcal,
        50,
      );
      await ui.waitFor(tester, find.text('Ngân sách: 1850 kcal'));
      await capture('step-energy');
      debugPrint(
        'WELLNESS_BUDGET confirmed synthetic estimate saves and updates budget',
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: routedWellness(const WellnessScreen(initialTab: 5)),
        ),
      );
      await ui.waitFor(tester, find.textContaining('70 kg ·'));
      await capture('weight-progress');

      final b = await auth.createUserWithEmailAndPassword(
        email: 'wellness-b-$suffix@example.test',
        password: password,
      );
      await verifyEmulatorEmail(auth, projectId: project);
      await until(
        () => container.read(localWellnessProvider).value?.uid == b.user!.uid,
      );
      await expectLater(
        device.readSettings(alice),
        throwsA(isA<PlatformException>()),
      );
      expect(
        (await device.readSettings(b.user!.uid)).every((r) => !r.enabled),
        true,
      );
      expect(
        await device.activeNotificationIds(b.user!.uid),
        isNot(contains(5100)),
      );
      expect(
        await device.activeNotificationIds(b.user!.uid),
        isNot(contains(7300)),
      );
      expect((await device.readSleepReminder(b.user!.uid)).enabled, false);
      await expectLater(
        repo.watchSleepLogs(alice).first,
        throwsA(isA<FirebaseException>()),
      );
      await ui.tap(tester, ui.keyed('wellness-tab-4'));
      await ui.waitFor(tester, find.text('Chưa ghi bữa ăn trong ngày này.'));
      expect(find.text('180 mg'), findsNothing);
      expect(tester.takeException(), isNull);
      debugPrint(
        'WELLNESS_UID old settings health history and notification isolated',
      );
      binding.reportData?['wellnessAcceptance'] = {
        'native': true,
        'production': false,
        'stepSensorSupported': steps['supported'],
        'checkpoints': 7,
      };
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
