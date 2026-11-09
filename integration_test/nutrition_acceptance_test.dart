// Opt-in native Android QA. Uses the named demo backend, never main/production.
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:healthmate/app.dart';
import 'package:healthmate/features/premium/providers/play_billing_providers.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/activity/data/firebase_activity_repository.dart';
import 'package:healthmate/features/activity/providers/activity_providers.dart';
import 'package:healthmate/features/auth/data/firebase_account_data_repository.dart';
import 'package:healthmate/features/auth/data/firebase_auth_repository.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/food_library/data/firebase_favorite_food_repository.dart';
import 'package:healthmate/features/food_library/data/firebase_food_library_repository.dart';
import 'package:healthmate/features/food_library/providers/favorite_food_providers.dart';
import 'package:healthmate/features/food_library/providers/food_library_providers.dart';
import 'package:healthmate/features/goals/data/firebase_goals_repository.dart';
import 'package:healthmate/features/goals/providers/goals_providers.dart';
import 'package:healthmate/features/meal_templates/data/meal_template_repository.dart';
import 'package:healthmate/features/meal_templates/providers/meal_template_providers.dart';
import 'package:healthmate/features/nutrition/data/bundled_vietnamese_foods.dart';
import 'package:healthmate/features/nutrition/data/firebase_nutrition_repository.dart';
import 'package:healthmate/features/nutrition/data/food_local_database.dart';
import 'package:healthmate/features/nutrition/data/usda_api_service.dart';
import 'package:healthmate/features/nutrition/models/food_avoidance.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:healthmate/features/nutrition_targets/data/firebase_nutrition_target_repository.dart';
import 'package:healthmate/features/nutrition_targets/providers/nutrition_target_providers.dart';
import 'package:healthmate/features/profile/data/firebase_health_profile_repository.dart';
import 'package:healthmate/features/profile/models/health_goal.dart';
import 'package:healthmate/features/profile/models/onboarding_draft.dart';
import 'package:healthmate/core/data/user_data_revision.dart';
import 'package:healthmate/features/profile/models/personalization_answers.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/reports/data/day_review_repository.dart';
import 'package:healthmate/features/reports/providers/report_providers.dart';
import 'package:healthmate/features/water/data/firebase_water_repository.dart';
import 'package:healthmate/features/water/providers/water_providers.dart';
import 'package:healthmate/features/wellness/data/energy_repository.dart';
import 'package:healthmate/features/wellness/data/wellness_repository.dart';
import 'package:healthmate/features/wellness/providers/energy_providers.dart';
import 'package:healthmate/features/wellness/providers/wellness_providers.dart';
import 'core_acceptance_test.dart' as ui;
import 'support/emulator_email_actions.dart';

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
      'Use the dedicated nutrition QA runner with demo backend and AI=false.',
    );
  }

  testWidgets(
    'Android nutrition: source search, avoidance, CRUD, kcal plans and ownership',
    (tester) async {
      const project = 'demo-healthmate-rules';
      const password = 'Synthetic-Nutrition-123!';
      final app = await Firebase.initializeApp(
        name: 'healthmate-nutrition-qa',
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
      final account = await auth.createUserWithEmailAndPassword(
        email: 'nutrition-a-$suffix@example.test',
        password: password,
      );
      await verifyEmulatorEmail(auth, projectId: project);
      final alice = account.user!.uid;
      final today = localDateOnly(DateTime.now());
      final end = DateTime(today.year, today.month, today.day + 1);
      final profile = FirebaseHealthProfileRepository(db);
      final nutrition = FirebaseNutritionRepository(db);
      final targets = FirebaseNutritionTargetRepository(db);
      final wellness = WellnessRepository(db);
      await profile.ensureProfile(uid: alice, email: account.user!.email!);
      try {
        await profile.completeOnboarding(
          uid: alice,
          draft: OnboardingDraft(
            displayName: 'Nutrition QA',
            birthDate: DateTime(2000, 1, 15),
            heightCm: 170,
            currentWeightKg: 55,
            healthGoal: HealthGoal.gainWeightOrMuscle,
            targetWeightKg: 60,
            personalization: PersonalizationAnswers({
              'diet': 'vegan',
              'avoidFoods': 'sữa; trứng',
            }),
          ),
        );
      } catch (_) {
        final coverage = await http.get(
          Uri.parse(
            'http://10.0.2.2:8080/emulator/v1/projects/$project:ruleCoverage',
          ),
        );
        await File(
          '${Directory.systemTemp.path}/nutrition-rule-coverage.json',
        ).writeAsString(coverage.body);
        rethrow;
      }
      final httpClient = MockClient(
        (_) async => http.Response(jsonEncode({'foods': []}), 200),
      );
      final container = ProviderContainer(
        overrides: [
          playBillingSupportedProvider.overrideWithValue(false),
          realtimeFirestoreProvider.overrideWithValue(db),
          authRepositoryProvider.overrideWithValue(
            FirebaseAuthRepository(auth),
          ),
          accountDataRepositoryProvider.overrideWithValue(
            FirebaseAccountDataRepository(db),
          ),
          healthProfileRepositoryProvider.overrideWithValue(profile),
          nutritionRepositoryProvider.overrideWithValue(nutrition),
          nutritionTargetRepositoryProvider.overrideWithValue(targets),
          wellnessRepositoryProvider.overrideWithValue(wellness),
          energyRepositoryProvider.overrideWithValue(
            FirebaseEnergyRepository(db),
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
          waterRepositoryProvider.overrideWithValue(
            FirebaseWaterRepository(db),
          ),
          activityRepositoryProvider.overrideWithValue(
            FirebaseActivityRepository(db),
          ),
          goalsRepositoryProvider.overrideWithValue(
            FirebaseGoalsRepository(db),
          ),
          // Offline catalog/SQLite stay real. Avoid external USDA traffic during QA.
          usdaApiServiceProvider.overrideWithValue(
            UsdaApiService(client: httpClient),
          ),
        ],
      );
      addTearDown(() async {
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
        container.dispose();
        httpClient.close();
        await db.enableNetwork();
        await db.terminate();
        await auth.signOut();
        await app.delete();
      });
      var converted = false;
      Future<void> checkpoint(String name) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump(const Duration(milliseconds: 500));
        if (!converted) {
          await binding.convertFlutterSurfaceToImage();
          converted = true;
        }
        await tester.pump(const Duration(milliseconds: 500));
        await binding.takeScreenshot('c6-nutrition-$name');
        expect(tester.takeException(), isNull);
        debugPrint('NUTRITION_CHECKPOINT $name');
      }

      Future<List<MealLog>> meals() => nutrition.loadRange(alice, today, end);
      Future<void> enter(String key, String value) async {
        // Captures dismiss the native IME. Reopen the field before replacing
        // text so Flutter's cached focusedEditable does not target a closed IME.
        await ui.tap(tester, ui.keyed(key));
        await ui.enter(tester, key, value);
        final editable = find.descendant(
          of: ui.keyed(key),
          matching: find.byType(EditableText),
        );
        expect(tester.widget<EditableText>(editable).controller.text, value);
      }

      Future<void> until(bool Function() condition) async {
        final deadline = DateTime.now().add(const Duration(seconds: 35));
        while (!condition()) {
          if (DateTime.now().isAfter(deadline)) {
            fail('Nutrition state did not settle');
          }
          await tester.pump(const Duration(milliseconds: 150));
        }
      }

      Future<void> saveReviewedMeal() async {
        await ui.tap(tester, ui.keyed('save-meal'));
        await tester.pump(const Duration(milliseconds: 500));
        if (find.text('Kiểm tra thực phẩm cần tránh').evaluate().isNotEmpty) {
          expect(
            find.textContaining('Ghi nhật ký không có nghĩa món này an toàn'),
            findsOneWidget,
          );
          await binding.takeScreenshot('c6-nutrition-avoidance-review');
          await ui.tap(tester, find.text('Vẫn ghi nhật ký'));
        }
        await ui.waitFor(tester, find.byType(MealFormDialog), absent: true);
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HealthMateApp(),
        ),
      );
      await ui.waitFor(tester, ui.keyed('dashboard-screen'));
      final watch = Stopwatch()..start();
      final catalog = await loadBundledVietnameseFoods();
      watch.stop();
      expect(catalog, hasLength(11169));
      final apple = catalog.firstWhere(
        (f) => f.originalName == 'Apples, raw, without skin',
      );
      final avoidance = FoodAvoidance.fromText('sữa; trứng');
      expect(avoidance.allows(apple), true);
      final cache = FoodLocalDatabase.instance;
      await cache.cacheFood(apple);
      final cached = (await cache.getFoodById(apple.id))!;
      expect(cached.name, apple.name);
      expect(cached.originalName, apple.originalName);
      expect(cached.ingredientNames, apple.ingredientNames);
      expect(cached.ingredientsKnown, true);
      expect(cached.dietaryClass, apple.dietaryClass);
      expect(avoidance.allows(cached), true);
      debugPrint(
        'NUTRITION_CATALOG count=${catalog.length} decodeMs=${watch.elapsedMilliseconds} SQLite metadata preserved',
      );
      await checkpoint('01-catalog-profile');

      await ui.tap(tester, ui.keyed('dashboard-details'));
      await ui.tap(
        tester,
        ui.keyed('edit-nutrition-target-${localDateKey(today)}'),
      );
      await enter('target-kcal', '2200');
      await ui.tap(tester, ui.keyed('save-target'));
      await ui.waitFor(tester, ui.keyed('target-kcal'), absent: true);
      expect(
        (await targets.loadForDay(alice, localDateKey(today)))!.kcalTarget,
        2200,
      );
      await checkpoint('02-confirmed-target');

      await ui.tap(tester, ui.keyed('nav-journal'));
      await ui.tap(tester, ui.keyed('add-meal-lunch'));
      await ui.tap(tester, ui.keyed('meal-more-tools'));
      await ui.tap(tester, ui.keyed('meal-diet-options'));
      await ui.waitFor(tester, ui.keyed('food-diet-filter'));
      await ui.tap(tester, ui.keyed('food-diet-filter'));
      await ui.tap(tester, find.text('Tất cả chế độ').last);
      await enter('food-search', 'Sữa đặc');
      await tester.pump(const Duration(seconds: 1));
      expect(find.byTooltip('Thêm Sữa đặc có đường'), findsNothing);
      expect(find.textContaining('Đang tránh:'), findsWidgets);
      await checkpoint('03-avoidance-all-diets');
      await enter('food-search', 'Apples, raw, without skin');
      await ui.waitFor(tester, find.byTooltip('Thêm ${apple.name}'));
      await ui.tap(tester, find.byTooltip('Thêm ${apple.name}'));
      await ui.tap(tester, find.text('Tên gốc và nguồn USDA'));
      await ui.waitFor(tester, find.text('Apples, raw, without skin'));
      await enter('meal-grams', '150');
      await checkpoint('04-vietnamese-original-grams');
      await ui.tap(tester, find.widgetWithText(FilledButton, 'Xác nhận'));
      await saveReviewedMeal();
      var logs = await meals();
      expect(logs, hasLength(1));
      expect(logs.single.items.single.grams, 150);
      expect(logs.single.totals.kcal, closeTo(apple.forGrams(150).kcal, .001));
      final mealId = logs.single.id;
      await checkpoint('05-save-snapshot');

      await ui.tap(tester, find.byType(PopupMenuButton<String>).first);
      await ui.tap(tester, find.text('Sửa').last);
      await ui.tap(tester, find.byTooltip('Sửa khẩu phần'));
      await enter('meal-grams', '200');
      await ui.tap(tester, find.widgetWithText(FilledButton, 'Xác nhận'));
      await saveReviewedMeal();
      logs = await meals();
      expect(logs, hasLength(1));
      expect(logs.single.id, mealId);
      expect(logs.single.items.single.grams, 200);
      expect(logs.single.totals.kcal, closeTo(apple.forGrams(200).kcal, .001));
      await ui.waitFor(
        tester,
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.key == const ValueKey('nutrition-daily-totals') &&
              w.semanticsLabel ==
                  '${apple.forGrams(200).kcal.toStringAsFixed(0)} kcal / 2200 kcal',
        ),
      );
      await checkpoint('06-edit-and-daily-total');

      await ui.tap(tester, ui.keyed('nav-profile'));
      await ui.tap(tester, ui.keyed('open-wellness'));
      await ui.tap(tester, ui.keyed('hub-open-1'));
      await ui.tap(tester, ui.keyed('suggest-week-plan'));
      await ui.waitFor(tester, find.text('Xem trước gợi ý 7 ngày'));
      expect(find.textContaining('/ 2200 kcal mục tiêu'), findsWidgets);
      expect((await db.collection('users/$alice/meal_plans').get()).size, 0);
      expect((await meals()), hasLength(1));
      await checkpoint('07-kcal-plan-preview-no-write');
      await ui.tap(tester, find.text('Hủy'));
      expect((await db.collection('users/$alice/meal_plans').get()).size, 0);
      await ui.tap(tester, ui.keyed('suggest-week-plan'));
      await ui.tap(tester, find.text('Thêm bữa còn trống'));
      await ui.waitFor(tester, find.text('Xong'));
      expect(find.textContaining('Đã xử lý 28/28 bữa'), findsOneWidget);
      await ui.tap(tester, find.text('Xong'));
      await ui.waitFor(
        tester,
        find.text('Xem trước gợi ý 7 ngày'),
        absent: true,
      );
      await until(
        () => container.read(plansProvider(today)).value?.length == 28,
      );
      final plans = await wellness.watchPlans(alice, today).first;
      expect(plans, hasLength(28));
      for (var day = 0; day < 7; day++) {
        final key = localDateKey(
          DateTime(today.year, today.month, today.day + day),
        );
        final total = plans
            .where((p) => localDateKey(p.date) == key)
            .fold<double>(0, (total, p) => total + p.totals.kcal);
        expect(total, closeTo(2200, 110));
      }
      for (final plan in plans) {
        expect(avoidance.flaggedSnapshots(plan.items, catalog), isEmpty);
      }
      expect((await meals()), hasLength(1));
      await checkpoint('08-confirmed-plan-28-meals');

      await ui.tap(tester, find.text('Xác nhận đã ăn').first);
      await ui.waitFor(tester, find.byType(MealFormDialog));
      await ui.tap(tester, ui.keyed('save-meal'));
      await ui.waitFor(tester, find.byType(MealFormDialog), absent: true);
      logs = await meals();
      expect(logs, hasLength(2));
      final planned = logs.singleWhere((m) => m.id != mealId);
      expect(planned.id, startsWith('plan-'));
      expect(
        (await wellness.watchPlans(alice, today).first).where(
          (p) => p.loggedMealId != null,
        ),
        hasLength(1),
      );
      await checkpoint('09-plan-to-diary-once');

      // Return through the app navigation; deleting a diary must not delete plans.
      await ui.tap(tester, find.byTooltip('Quay lại').first);
      await ui.tap(tester, ui.keyed('nav-journal'));
      await ui.waitFor(tester, find.byType(PopupMenuButton<String>));
      await ui.tap(tester, find.byType(PopupMenuButton<String>).first);
      await ui.tap(tester, find.text('Xóa').last);
      await ui.tap(tester, find.widgetWithText(FilledButton, 'Xóa'));
      await ui.waitFor(tester, find.text('Xóa bữa ăn?'), absent: true);
      expect((await meals()), hasLength(1));
      expect((await db.collection('users/$alice/meal_plans').get()).size, 28);
      await checkpoint('10-delete-diary-preserves-plan');

      final remainingId = (await meals()).single.id;
      await auth.signOut();
      final b = await auth.createUserWithEmailAndPassword(
        email: 'nutrition-b-$suffix@example.test',
        password: password,
      );
      await verifyEmulatorEmail(auth, projectId: project);
      final bob = b.user!.uid;
      expect(await nutrition.loadRange(bob, today, end), isEmpty);
      await expectLater(
        db
            .doc('users/$alice/meal_logs/$remainingId')
            .get(const GetOptions(source: Source.server)),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      debugPrint(
        'NUTRITION_CHECKPOINT 11-uid-isolation server denied cross-account read',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
