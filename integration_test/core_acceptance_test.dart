// Opt-in Android acceptance against the local demo backend only. Never call the
// production main/bootstrap, use a real account, or use the default Firebase app.
import 'dart:convert';
import 'dart:io';
import 'support/emulator_email_actions.dart';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:healthmate/features/wellness/data/energy_repository.dart';
import 'package:healthmate/features/wellness/providers/energy_providers.dart';
import 'package:healthmate/app.dart';
import 'package:healthmate/features/premium/providers/play_billing_providers.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/auth/data/firebase_auth_repository.dart';
import 'package:healthmate/features/auth/data/firebase_account_data_repository.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/chatbot/providers/chat_providers.dart';
import 'package:healthmate/features/food_scanner/providers/food_scanner_providers.dart';
import 'package:healthmate/features/food_library/data/firebase_favorite_food_repository.dart';
import 'package:healthmate/features/food_library/data/firebase_food_library_repository.dart';
import 'package:healthmate/features/food_library/models/food_library_models.dart';
import 'package:healthmate/features/food_library/providers/favorite_food_providers.dart';
import 'package:healthmate/features/food_library/providers/food_library_providers.dart';
import 'package:healthmate/features/nutrition/data/firebase_nutrition_repository.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/data/food_local_database.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/nutrition/presentation/quick_add_dialog.dart';
import 'package:healthmate/features/nutrition_targets/data/firebase_nutrition_target_repository.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/nutrition_targets/providers/nutrition_target_providers.dart';
import 'package:healthmate/features/profile/data/firebase_health_profile_repository.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/water/data/firebase_water_repository.dart';
import 'package:healthmate/features/water/providers/water_providers.dart';
import 'package:healthmate/features/activity/data/firebase_activity_repository.dart';
import 'package:healthmate/features/activity/providers/activity_providers.dart';
import 'package:healthmate/features/goals/data/firebase_goals_repository.dart';
import 'package:healthmate/features/goals/providers/goals_providers.dart';
import 'package:healthmate/features/meal_templates/data/meal_template_repository.dart';
import 'package:healthmate/features/meal_templates/providers/meal_template_providers.dart';
import 'package:healthmate/features/reports/data/day_review_repository.dart';
import 'package:healthmate/features/reports/providers/report_providers.dart';
import 'package:healthmate/features/progress/presentation/progress_overview.dart';
import 'package:healthmate/core/data/user_data_revision.dart';

const _project = 'demo-healthmate-rules';
const _host = '10.0.2.2';
const _password = 'Synthetic-C6-only-123!';
const _catalogId = 'c6-synthetic-rice';
final _today = localDateOnly(DateTime.now());
final _yesterday = DateTime(_today.year, _today.month, _today.day - 1);
Finder keyed(String key) => find.byKey(ValueKey(key));

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  bool absent = false,
}) async {
  final until = DateTime.now().add(const Duration(seconds: 35));
  while ((finder.evaluate().isEmpty) != absent) {
    if (DateTime.now().isAfter(until)) {
      debugPrint(
        'QA_TIMEOUT_VISIBLE_TEXT\n${tester.widgetList<Text>(find.byType(Text)).map((text) => text.data ?? text.textSpan?.toPlainText() ?? '').join('\n')}',
      );
      fail('Timed out waiting for ${absent ? "absence of " : ""}$finder');
    }
    await tester.pump(const Duration(milliseconds: 150));
  }
  await tester.pump(const Duration(milliseconds: 150));
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  // ListView constructs fields lazily. Scroll only the current vertical form.
  for (var attempt = 0; finder.evaluate().isEmpty && attempt < 25; attempt++) {
    final scroll = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .last;
    await tester.drag(scroll, const Offset(0, -220));
    await tester.pump(const Duration(milliseconds: 150));
  }
  expect(finder, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(finder), alignment: .3);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  // Wait for the native IME resize before scrolling to a separate action.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 500));
  await reveal(tester, finder);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> enter(WidgetTester tester, String key, String value) async {
  final finder = keyed(key);
  await reveal(tester, finder);
  await tester.enterText(finder, value);
  await tester.pump(const Duration(milliseconds: 150));
}

Future<void> pickDate(WidgetTester tester, DateTime date) async {
  await waitFor(tester, find.byType(DatePickerDialog));
  final context = tester.element(find.byType(DatePickerDialog));
  final tooltip = MaterialLocalizations.of(context).inputDateModeButtonLabel;
  await tap(tester, find.byTooltip(tooltip));
  final input = find.descendant(
    of: find.byType(DatePickerDialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(
    input,
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
  );
  final confirm =
      tester
          .widget<DatePickerDialog>(find.byType(DatePickerDialog))
          .confirmText ??
      MaterialLocalizations.of(context).okButtonLabel;
  await tap(tester, find.widgetWithText(TextButton, confirm));
  await waitFor(tester, find.byType(DatePickerDialog), absent: true);
}

Future<void> register(
  WidgetTester tester,
  String email,
  FirebaseAuth auth,
) async {
  await waitFor(tester, keyed('auth-toggle'));
  await tap(tester, keyed('auth-toggle'));
  await enter(tester, 'auth-email', email);
  await enter(tester, 'auth-password', _password);
  await enter(tester, 'auth-confirmation', _password);
  await tap(tester, keyed('auth-submit'));
  await waitFor(tester, keyed('verification-check'));
  await verifyEmulatorEmail(
    auth,
    projectId: _project,
    host: _host,
    send: false,
    reload: false,
  );
  await tap(tester, keyed('verification-check'));
  await waitFor(tester, keyed('onboarding-name'));
}

Future<void> onboard(WidgetTester tester, String name) async {
  await enter(tester, 'onboarding-name', name);
  await tap(tester, keyed('onboarding-birth-date'));
  await pickDate(tester, DateTime(2000, 1, 15));
  await enter(tester, 'onboarding-height', '170');
  await enter(tester, 'onboarding-weight', '70');
  await tap(tester, keyed('onboarding-next'));
  await tap(tester, keyed('onboarding-goal-maintain_weight'));
  await tap(tester, keyed('onboarding-next'));
  await tap(tester, keyed('onboarding-next'));
  for (var i = 0; i < 3; i++) {
    await tap(
      tester,
      keyed('onboarding-next'),
    ); // Activity, food, sleep questions.
  }
  await tap(tester, keyed('onboarding-next')); // Optional nutrition plan step.
  await tap(tester, keyed('onboarding-complete'));
  // Auth restores the protected destination (Profile after signing out there).
  // First verify that onboarding exits into the real app shell, then open Home.
  await waitFor(tester, keyed('nav-dashboard'));
  await tap(tester, keyed('nav-dashboard'));
  await waitFor(tester, keyed('dashboard-screen'));
}

Future<void> seedCatalog() async {
  // Guarded static localhost/demo endpoint; the application cannot write catalog.
  final response = await http.patch(
    Uri.parse(
      'http://$_host:8080/v1/projects/$_project/databases/(default)/documents/food_catalog/$_catalogId',
    ),
    headers: {
      'Authorization': 'Bearer owner',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'fields': {
        'name': {'stringValue': 'Cơm fixture C6'},
        'category': {'stringValue': 'Synthetic QA'},
        'servingBasis': {'stringValue': 'per_100g'},
        'unit': {'stringValue': 'g'},
        'servingLabel': {'stringValue': 'phần fixture'},
        'servingGrams': {'doubleValue': 200},
        'kcalPer100g': {'doubleValue': 130},
        'proteinGPer100g': {'doubleValue': 3},
        'carbsGPer100g': {'doubleValue': 28},
        'fatGPer100g': {'doubleValue': .3},
        'sourceLabel': {
          'stringValue': 'Synthetic emulator fixture, not nutrition reference',
        },
        'isEstimated': {'booleanValue': true},
      },
    }),
  );
  expect(response.statusCode, 200);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!const bool.fromEnvironment('HEALTHMATE_CORE_EMULATOR_TESTS') ||
      !Platform.isAndroid ||
      !_project.startsWith('demo-') ||
      const bool.fromEnvironment(
        'HEALTHMATE_ENABLE_CHATBOT',
        defaultValue: true,
      ) ||
      const bool.fromEnvironment(
        'HEALTHMATE_ENABLE_FOOD_SCANNER',
        defaultValue: true,
      )) {
    throw StateError(
      'Use the Android QA runner with the fixed demo backend and AI disabled.',
    );
  }

  testWidgets(
    'Stage10 public SQLite cache preserves zero and hides legacy private rows',
    (tester) async {
      final cache = FoodLocalDatabase.instance;
      const id = 'usda_stage10_cache_fixture';
      const privateId = 'stage10_private_cache_fixture';
      await cache.cacheFood(
        const FoodCatalogItem(
          id: id,
          name: 'Stage10 cache fixture',
          category: 'fixture',
          servingBasis: ServingBasis.per100g,
          sourceLabel: 'Synthetic QA',
          isEstimated: true,
          dataSource: FoodDataSource.usda,
          kcalPer100g: 130,
          proteinGPer100g: 2.69,
          carbsGPer100g: 28.17,
          fatGPer100g: .28,
          fiberGPer100g: 0,
        ),
      );
      final db = await cache.database;
      try {
        final restored = (await cache.getFoodById(id))!;
        expect(restored.nutritionPer100g.kcal, 130);
        expect(restored.nutritionPer100g.fiberKnown, true);
        expect(restored.nutritionPer100g.fiberG, 0);
        final row = (await db.query(
          'foods',
          where: 'id = ?',
          whereArgs: [id],
        )).single;
        await db.insert('foods', {
          ...row,
          'id': privateId,
          'data_source': 'user',
        });
        expect(await cache.getFoodById(privateId), isNull);
        expect(
          (await cache.searchFoods('Stage10 cache fixture')).map((f) => f.id),
          isNot(contains(privateId)),
        );
      } finally {
        await db.delete(
          'foods',
          where: 'id IN (?, ?)',
          whereArgs: [id, privateId],
        );
      }
    },
  );

  testWidgets(
    'C6 Android core acceptance with real Firebase repositories',
    (tester) async {
      final app = await Firebase.initializeApp(
        name: 'healthmate-core-c6-qa',
        options: const FirebaseOptions(
          apiKey: 'emulator-only-fake-api-key',
          appId: '1:1234567890:android:0123456789abcdef',
          messagingSenderId: '1234567890',
          projectId: _project,
        ),
      );
      final auth = FirebaseAuth.instanceFor(app: app);
      await auth.useAuthEmulator(_host, 9099, automaticHostMapping: false);
      final db = FirebaseFirestore.instanceFor(app: app);
      db.settings = const Settings(persistenceEnabled: false);
      db.useFirestoreEmulator(_host, 8080, automaticHostMapping: false);
      await auth.signOut(); // Named QA app only, never the default app/session.
      final nutrition = FirebaseNutritionRepository(db);
      final profile = FirebaseHealthProfileRepository(db);
      final targets = FirebaseNutritionTargetRepository(db);
      final dayReviews = FirebaseDayReviewRepository(db);
      final library = FirebaseFoodLibraryRepository(db);
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
          energyRepositoryProvider.overrideWithValue(
            FirebaseEnergyRepository(db),
          ),
          nutritionTargetRepositoryProvider.overrideWithValue(targets),
          dayReviewRepositoryProvider.overrideWithValue(dayReviews),
          foodLibraryRepositoryProvider.overrideWithValue(library),
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
        ],
      );
      addTearDown(() async {
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 500));
        container.dispose();
        await db.enableNetwork();
        await db.terminate();
        await auth.signOut();
        await app.delete();
      });
      await seedCatalog();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HealthMateApp(),
        ),
      );
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final emailA = 'c6-alice-$suffix@example.com',
          emailB = 'c6-bob-$suffix@example.com';
      Future<void> checkpoint(String label) async {
        debugPrint('C6_CHECKPOINT $label');
        expect(tester.takeException(), isNull);
      }

      var surfaceConverted = false;
      Future<void> capture(String name) async {
        if (!surfaceConverted) {
          await binding.convertFlutterSurfaceToImage();
          surfaceConverted = true;
        }
        // Finish route/IME transitions before recording visual evidence.
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump();
        final bytes = await binding.takeScreenshot(name);
        expect(bytes, isNotEmpty);
      }

      Future<void> profileRoot() async {
        await tap(tester, keyed('nav-profile'));
        if (keyed('open-food-library').evaluate().isEmpty) {
          // A tab remembers its library route; a second tap returns to its root.
          await tap(tester, keyed('nav-profile'));
        }
      }

      await register(tester, emailA, auth);
      await onboard(tester, 'C6 QA Alice');
      final alice = auth.currentUser!.uid;
      expect(
        (await profile.watchProfile(alice).first)!.isOnboardingComplete,
        isTrue,
      );
      await checkpoint('01-auth-onboarding');
      // Precondition: an existing historical target, never backdated via product UI.
      await FirebaseNutritionTargetRepository(db, now: () => _yesterday).save(
        alice,
        NutritionTarget(
          effectiveFromDateKey: localDateKey(_yesterday),
          kcalTarget: 1800,
        ),
      );
      container.invalidate(nutritionTargetProvider);
      await tap(tester, keyed('dashboard-details'));
      await tap(tester, keyed('edit-nutrition-target-${localDateKey(_today)}'));
      await enter(tester, 'target-kcal', '2000');
      await enter(tester, 'target-protein', '100');
      await enter(tester, 'target-carbs', '275');
      await enter(tester, 'target-fat', '60');
      await tap(tester, keyed('save-target'));
      await waitFor(tester, keyed('target-kcal'), absent: true);
      expect(
        (await targets.loadForDay(alice, localDateKey(_today)))!.kcalTarget,
        2000,
      );
      expect(
        (await targets.loadForDay(alice, localDateKey(_yesterday)))!.kcalTarget,
        1800,
      );
      await checkpoint('02-target-history');

      await tap(tester, keyed('nav-journal'));
      await waitFor(tester, keyed('add-meal-lunch'));
      await waitFor(
        tester,
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.key == const ValueKey('nutrition-daily-totals') &&
              w.semanticsLabel == '0 kcal / 2000 kcal',
        ),
      );
      // A target-save SnackBar can temporarily cover an otherwise visible button.
      await waitFor(tester, find.byType(SnackBar), absent: true);
      // Native first viewport proof: no reveal/ensureVisible before measuring.
      final journalViewport = tester.getRect(
        find.byType(CustomScrollView).first,
      );
      final breakfastAdd = tester.getRect(keyed('add-meal-breakfast'));
      expect(breakfastAdd.top, greaterThanOrEqualTo(journalViewport.top));
      expect(breakfastAdd.bottom, lessThanOrEqualTo(journalViewport.bottom));
      expect(keyed('add-meal-breakfast').hitTestable(), findsOneWidget);
      debugPrint('U1_VIEWPORT journal add=$breakfastAdd body=$journalViewport');
      await capture('c6-u1-journal-first-viewport');
      await tap(tester, keyed('add-meal-lunch'));
      await waitFor(tester, keyed('food-search'));
      await enter(tester, 'food-search', 'Cơm fixture C6');
      await waitFor(tester, find.byTooltip('Thêm Cơm fixture C6'));
      await tap(tester, find.byTooltip('Thêm Cơm fixture C6'));
      await tap(tester, keyed('portion-unit'));
      await enter(tester, 'meal-grams', '0,75');
      await capture('c6-h1-catalog-fractional-portion');
      await tap(tester, find.widgetWithText(FilledButton, 'Xác nhận'));
      await tap(tester, keyed('save-meal'));
      await waitFor(tester, find.byType(MealFormDialog), absent: true);
      var todayMeals = await nutrition.loadRange(
        alice,
        _today,
        DateTime(_today.year, _today.month, _today.day + 1),
      );
      expect(todayMeals.single.totals.kcal, 195);
      expect(todayMeals.single.items.single.grams, 150);
      await checkpoint('03-add-meal');

      Future<void> mealMenu(String label) async {
        await tap(tester, find.byType(PopupMenuButton<String>).first);
        await tap(tester, find.text(label).last);
      }

      await mealMenu('Sửa');
      await reveal(tester, keyed('selected-meal-item-0'));
      await tap(tester, find.byTooltip('Sửa khẩu phần'));
      await enter(tester, 'meal-grams', '200');
      await tap(tester, find.widgetWithText(FilledButton, 'Xác nhận'));
      await tap(tester, keyed('save-meal'));
      await waitFor(tester, find.byType(MealFormDialog), absent: true);
      todayMeals = await nutrition.loadRange(
        alice,
        _today,
        DateTime(_today.year, _today.month, _today.day + 1),
      );
      expect(todayMeals.single.totals.kcal, 260);
      final sourceId = todayMeals.single.id;
      await mealMenu('Nhân bản bữa');
      await tap(tester, find.byTooltip('Ngày và giờ ăn'));
      await tap(tester, find.textContaining('Ngày:'));
      await pickDate(tester, _yesterday);
      await tap(tester, keyed('save-meal'));
      await waitFor(tester, find.byType(MealFormDialog), absent: true);
      final copies = await nutrition.loadRange(alice, _yesterday, _today);
      expect(copies.single.items.single.grams, 200);
      expect(copies.single.totals.kcal, 260);
      expect(copies.single.id, isNot(sourceId));
      await tap(tester, keyed('journal-previous-day'));
      await waitFor(
        tester,
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.key == const ValueKey('nutrition-daily-totals') &&
              w.semanticsLabel == '260 kcal / 1800 kcal',
        ),
      );
      await capture('c6-01-journal-history');
      await checkpoint('04-edit-copy-selected-day');

      Future<void> quick(String action) async {
        if (action == 'meal') {
          await tap(tester, keyed('quick-add-menu'));
        } else if (action == 'weight') {
          await profileRoot();
          await tap(tester, keyed('add-metric'));
        } else {
          await tap(tester, keyed('nav-journal'));
          await tap(tester, keyed('add-$action'));
        }
      }

      await tap(tester, keyed('journal-next-day'));
      await quick('water');
      await enter(tester, 'water-amount', '350');
      await tap(tester, keyed('save-water'));
      await waitFor(tester, keyed('water-amount'), absent: true);
      await quick('activity');
      await enter(tester, 'activity-duration', '25');
      await tap(tester, keyed('save-activity'));
      await waitFor(tester, keyed('activity-duration'), absent: true);
      await quick('weight');
      await enter(tester, 'metric-weight', '69,5');
      await tap(tester, keyed('save-metric'));
      await waitFor(tester, keyed('metric-weight'), absent: true);
      expect(
        (await profile.watchLatestBodyMetric(alice, _today).first)
            .single
            .weightKg,
        69.5,
      );
      await tap(tester, keyed('nav-progress'));
      await waitFor(tester, keyed('progress-trend-kcal'));
      // Global quick actions reset the journal date to today, even when the
      // journal previously displayed yesterday. Verify the current week here.
      final progressViewport = tester.getRect(
        find.byType(CustomScrollView).first,
      );
      final chart = tester.getRect(keyed('weekly-chart'));
      expect(chart.top, lessThan(progressViewport.bottom));
      expect(keyed('previous-week').hitTestable(), findsOneWidget);
      expect(
        tester
            .widget<RecordedTrendCard>(keyed('progress-trend-kcal'))
            .points
            .map((p) => p.value),
        contains(260),
      );
      await tap(tester, keyed('progress-tab-2'));
      await waitFor(tester, keyed('progress-trend-water'));
      expect(
        tester
            .widget<RecordedTrendCard>(keyed('progress-trend-water'))
            .points
            .map((p) => p.value),
        contains(350),
      );
      expect(
        tester
            .widget<RecordedTrendCard>(keyed('progress-trend-activity'))
            .points
            .map((p) => p.value),
        contains(25),
      );
      expect(
        find.descendant(
          of: keyed('progress-trend-water'),
          matching: find.text('350 ml'),
        ),
        findsOneWidget,
      );
      await tap(tester, keyed('progress-tab-0'));
      debugPrint('U1_VIEWPORT progress chart=$chart body=$progressViewport');
      await capture('c6-02-progress');
      await checkpoint('05-water-activity-weight-progress');

      // Library CRUD is exercised through actual forms and real server reads.
      await profileRoot();
      await tap(tester, keyed('open-food-library'));
      await tap(tester, keyed('create-custom'));
      for (final entry in {
        'library-name': 'C6 món riêng',
        'library-kcal': '200',
        'library-protein': '10',
        'library-carbs': '30',
        'library-fat': '4',
        'library-fiber': '2',
        'library-default-grams': '100',
      }.entries) {
        await enter(tester, entry.key, entry.value);
      }
      await tap(tester, keyed('library-save'));
      await waitFor(tester, keyed('library-kcal'), absent: true);
      final foodDoc =
          (await db
                  .collection('users/$alice/custom_foods')
                  .get(const GetOptions(source: Source.server)))
              .docs
              .single;
      final foodId = foodDoc.id;
      await tap(tester, find.widgetWithText(ChoiceChip, 'Công thức'));
      await tap(tester, keyed('create-recipe'));
      await enter(tester, 'recipe-name', 'C6 công thức');
      await enter(tester, 'recipe-yield', '80');
      await enter(tester, 'recipe-servings', '2');
      await tap(tester, keyed('add-ingredient'));
      await tap(tester, find.widgetWithText(ChoiceChip, 'Món của tôi').last);
      await waitFor(tester, find.text('C6 món riêng').last);
      await tap(tester, find.text('C6 món riêng').last);
      await enter(tester, 'meal-grams', '100');
      await tap(tester, find.widgetWithText(FilledButton, 'Xác nhận'));
      await tap(tester, keyed('library-save'));
      await waitFor(tester, keyed('recipe-name'), absent: true);
      final recipeDoc =
          (await db
                  .collection('users/$alice/recipes')
                  .get(const GetOptions(source: Source.server)))
              .docs
              .single;
      final recipeId = recipeDoc.id;
      expect(
        (await library.load(
          alice,
          FoodSourceKind.recipe,
          recipeId,
        ))!.asFood().per100g!.kcal,
        250,
      );
      await checkpoint('06-create-personal-and-recipe');

      await quick('meal');
      // Exercise two valid breakfasts regardless of the wall clock. The global
      // quick action still keeps the application's normal time-based default.
      await tap(tester, keyed('meal-type'));
      await tap(tester, find.text(MealType.breakfast.label).last);
      await tap(tester, keyed('food-source-recipes'));
      await waitFor(tester, keyed('choose-recipe-$recipeId'));
      await tap(tester, keyed('choose-recipe-$recipeId'));
      await tap(tester, keyed('portion-unit'));
      await enter(tester, 'meal-grams', '0,5');
      await tap(tester, find.widgetWithText(FilledButton, 'Xác nhận'));
      await tap(tester, keyed('save-meal'));
      await waitFor(tester, find.byType(MealFormDialog), absent: true);
      todayMeals = await nutrition.loadRange(
        alice,
        _today,
        DateTime(_today.year, _today.month, _today.day + 1),
      );
      final recipeMeal = todayMeals.singleWhere(
        (m) => m.items.single.foodId.startsWith('recipe:'),
      );
      expect(recipeMeal.items.single.grams, 20);
      expect(recipeMeal.totals.kcal, 50);
      expect(recipeMeal.type, MealType.breakfast);

      await profileRoot();
      await tap(tester, keyed('open-food-library'));
      await tap(tester, keyed('edit-custom-$foodId'));
      await enter(tester, 'library-kcal', '300');
      await tap(tester, keyed('library-save'));
      await waitFor(tester, keyed('library-kcal'), absent: true);
      await tap(tester, find.widgetWithText(ChoiceChip, 'Công thức'));
      await tap(tester, keyed('edit-recipe-$recipeId'));
      await enter(tester, 'recipe-yield', '160');
      await tap(tester, keyed('library-save'));
      await waitFor(tester, keyed('recipe-name'), absent: true);
      await tap(tester, keyed('delete-recipe-$recipeId'));
      await tap(tester, find.widgetWithText(FilledButton, 'Xóa'));
      await waitFor(tester, keyed('delete-recipe-$recipeId'), absent: true);
      await tap(tester, find.widgetWithText(ChoiceChip, 'Món của tôi'));
      await tap(tester, keyed('delete-custom-$foodId'));
      await tap(tester, find.widgetWithText(FilledButton, 'Xóa'));
      await waitFor(tester, keyed('delete-custom-$foodId'), absent: true);
      todayMeals = await nutrition.loadRange(
        alice,
        _today,
        DateTime(_today.year, _today.month, _today.day + 1),
      );
      expect(
        todayMeals.singleWhere((m) => m.id == recipeMeal.id).totals.kcal,
        50,
      );
      expect(todayMeals.singleWhere((m) => m.id == sourceId).totals.kcal, 260);
      await checkpoint('07-edit-delete-source-keeps-history');

      await tap(tester, keyed('nav-dashboard'));
      await waitFor(tester, keyed('dashboard-details'));
      if (keyed(
        'edit-nutrition-target-${localDateKey(_today)}',
      ).evaluate().isEmpty) {
        await tap(tester, keyed('dashboard-details'));
      }
      await tap(tester, keyed('edit-nutrition-target-${localDateKey(_today)}'));
      await enter(tester, 'target-kcal', '2100');
      await db.disableNetwork();
      await tap(tester, keyed('save-target'));
      await waitFor(
        tester,
        find.textContaining('Thông tin vẫn được giữ trong form'),
      );
      expect(find.text('2100'), findsOneWidget);
      await db.enableNetwork();
      await tap(tester, keyed('save-target'));
      await waitFor(tester, keyed('target-kcal'), absent: true);
      expect(
        (await targets.loadForDay(alice, localDateKey(_today)))!.kcalTarget,
        2100,
      );
      expect(
        (await targets.loadForDay(alice, localDateKey(_yesterday)))!.kcalTarget,
        1800,
      );
      expect(
        (await db.collection('users/$alice/nutrition_targets').get()).size,
        2,
      );
      await checkpoint('08-offline-draft-retry-target-history');

      await tap(tester, keyed('nav-journal'));
      await tap(tester, keyed('add-meal-breakfast'));
      await waitFor(tester, find.byTooltip('Dùng lại Cơm fixture C6'));
      await tap(tester, find.byTooltip('Dùng lại Cơm fixture C6'));
      await tap(tester, keyed('save-meal'));
      await waitFor(tester, find.byType(MealFormDialog), absent: true);
      final repeated = await nutrition.loadRange(
        alice,
        _today,
        DateTime(_today.year, _today.month, _today.day + 1),
      );
      expect(repeated.length, 3);
      final breakfast = repeated.singleWhere(
        (m) => m.id != sourceId && m.id != recipeMeal.id,
      );
      expect(repeated.map((m) => m.id).toSet(), hasLength(3));
      expect(breakfast.id, isNot(sourceId));
      expect(breakfast.id, isNot(recipeMeal.id));
      expect(breakfast.type, MealType.breakfast);
      expect(
        repeated.where((m) => m.type == MealType.breakfast).length,
        greaterThanOrEqualTo(2),
      );
      expect(breakfast.items.single.grams, 200);
      expect(breakfast.totals.kcal, 260);
      expect(breakfast.dateKey, localDateKey(_today));
      debugPrint(
        'H2_RECENT repeated through 3 taps, no typed search or portion confirmation; source amount shown before use',
      );

      await profileRoot();
      await tap(tester, find.widgetWithText(ChoiceChip, 'Tối'));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await tester.pump(const Duration(milliseconds: 300));
      await tap(tester, keyed('nav-progress'));
      await waitFor(tester, keyed('progress-trend-kcal'));
      await capture('c6-03-dark-large-text');
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.pump(const Duration(milliseconds: 300));
      await checkpoint('09-dark-large-text');

      // Create a named multi-food template from an unsaved meal, discard that
      // meal, then use/edit the frozen template after the recipe source is gone.
      await tap(tester, keyed('nav-journal'));
      await tap(tester, keyed('add-meal-dinner'));
      await tap(tester, find.byTooltip('Dùng lại Cơm fixture C6'));
      await tap(tester, find.byTooltip('Dùng lại C6 công thức'));
      await tap(tester, keyed('meal-templates'));
      await tap(tester, keyed('create-meal-template'));
      await enter(tester, 'meal-template-name', 'H2 QA dinner');
      await tap(tester, keyed('save-meal-template'));
      await waitFor(tester, keyed('meal-template-name'), absent: true);
      final template =
          (await db
                  .collection('users/$alice/meal_templates')
                  .get(const GetOptions(source: Source.server)))
              .docs
              .single;
      expect((template.data()['items'] as List).length, 2);
      await tap(tester, keyed('discard-local-draft'));
      await waitFor(tester, find.byType(MealFormDialog), absent: true);
      expect(
        (await nutrition.loadRange(
          alice,
          _today,
          DateTime(_today.year, _today.month, _today.day + 1),
        )).length,
        3,
      );
      await tap(tester, keyed('add-meal-dinner'));
      await tap(tester, keyed('meal-templates'));
      await waitFor(tester, keyed('use-template-${template.id}'));
      await tap(tester, keyed('use-template-${template.id}'));
      await tap(
        tester,
        find.descendant(
          of: keyed('selected-meal-item-0'),
          matching: find.byTooltip('Sửa khẩu phần'),
        ),
      );
      await enter(tester, 'meal-grams', '100');
      await tap(tester, find.widgetWithText(FilledButton, 'Xác nhận'));
      await capture('c6-h2-template-two-foods');
      await tap(tester, keyed('save-meal'));
      await waitFor(tester, find.byType(MealFormDialog), absent: true);
      final withTemplate = await nutrition.loadRange(
        alice,
        _today,
        DateTime(_today.year, _today.month, _today.day + 1),
      );
      final newMeal = withTemplate.singleWhere(
        (m) => !repeated.any((old) => old.id == m.id),
      );
      expect(withTemplate.length, 4);
      expect(newMeal.items.length, 2);
      expect(newMeal.type, MealType.dinner);
      expect(newMeal.dateKey, localDateKey(_today));
      expect(newMeal.totals.kcal, 180);
      await tap(tester, keyed('add-meal-dinner'));
      await tap(tester, keyed('meal-templates'));
      await waitFor(tester, keyed('delete-template-${template.id}'));
      await tap(tester, keyed('delete-template-${template.id}'));
      await tap(tester, find.widgetWithText(FilledButton, 'Xóa bữa mẫu'));
      await waitFor(
        tester,
        keyed('delete-template-${template.id}'),
        absent: true,
      );
      await tap(tester, keyed('discard-local-draft'));
      expect(
        (await nutrition.loadRange(
          alice,
          _today,
          DateTime(_today.year, _today.month, _today.day + 1),
        )).singleWhere((m) => m.id == newMeal.id).totals.kcal,
        180,
      );
      debugPrint(
        'H2_TEMPLATES UI create/cancel/use/edit/delete; source gone; two foods 180 kcal; no history mutation',
      );
      await tap(tester, keyed('add-meal-snack'));
      await tap(tester, keyed('open-quick-add'));
      await enter(tester, 'quick-name', 'H3 QA chỉ kcal');
      await enter(tester, 'quick-kcal', '250');
      await tap(tester, keyed('confirm-quick-add'));
      await tap(tester, keyed('open-quick-add'));
      await tap(tester, keyed('quick-basis'));
      await tap(tester, find.text('Trên 100 ml').last);
      await enter(tester, 'quick-name', 'H3 QA nhãn thể tích');
      await enter(tester, 'quick-amount', '250');
      await enter(tester, 'quick-kcal', '60');
      await enter(tester, 'quick-protein', '3');
      await enter(tester, 'quick-carbs', '0');
      await reveal(tester, keyed('quick-preview'));
      await capture('c6-h3-volume-preview');
      await tap(tester, keyed('confirm-quick-add'));
      await tap(tester, keyed('save-meal'));
      await waitFor(tester, find.byType(MealFormDialog), absent: true);
      final withQuick = await nutrition.loadRange(
        alice,
        _today,
        DateTime(_today.year, _today.month, _today.day + 1),
      );
      expect(withQuick.length, 5);
      final quickMeal = withQuick.singleWhere(
        (m) => !withTemplate.any((old) => old.id == m.id),
      );
      expect(quickMeal.items.length, 2);
      expect(quickMeal.totals.kcal, 400);
      expect(quickMeal.totals.proteinG, 7.5);
      expect(quickMeal.totals.hasCompleteMacros, isFalse);
      expect(quickMeal.items.last.quantityUnit, 'ml');
      expect(quickMeal.items.last.quantity, 250);
      final quickWire =
          (await db.doc('users/$alice/meal_logs/${quickMeal.id}').get())
              .data()!;
      expect(quickWire['schemaVersion'], 3);
      expect(quickWire['totalProteinG'], isNull);
      expect((quickWire['items'] as List).last['grams'], isNull);
      debugPrint(
        'H3_QUICK_ADD UI kcal-only + 250 ml; 400 kcal; known protein subtotal 7.5 g; missing macros stay null',
      );
      await profileRoot();
      await tap(tester, keyed('edit-nutrition-target-${localDateKey(_today)}'));
      await tap(tester, keyed('open-energy-estimate'));
      await tap(tester, keyed('estimate-eligible'));
      await enter(tester, 'estimate-age', '25');
      await enter(tester, 'estimate-weight', '70');
      await tap(tester, keyed('estimate-sex'));
      await tap(tester, find.text('Nam · hệ số theo nghiên cứu').last);
      await tap(tester, keyed('estimate-activity'));
      await tap(tester, find.text('Ít vận động / nhẹ').last);
      await tap(tester, keyed('calculate-estimate'));
      await reveal(tester, keyed('estimate-result'));
      await capture('c6-h4-maintenance-estimate');
      expect(
        (await targets.loadForDay(alice, localDateKey(_today)))!.kcalTarget,
        2100,
      );
      await tap(tester, keyed('accept-estimate'));
      await enter(tester, 'target-kcal', '2600');
      await tap(tester, keyed('save-target'));
      if (keyed('confirm-target-mismatch').evaluate().isNotEmpty) {
        await tap(tester, keyed('confirm-target-mismatch'));
      }
      await waitFor(tester, keyed('target-kcal'), absent: true);
      expect(
        (await targets.loadForDay(alice, localDateKey(_today)))!.kcalTarget,
        2600,
      );
      expect(
        (await targets.loadForDay(alice, localDateKey(_yesterday)))!.kcalTarget,
        1800,
      );
      debugPrint(
        'H4_ESTIMATE reviewed/edited/saved; past target unchanged; inputs not persisted',
      );
      await tap(tester, keyed('nav-journal'));
      await tap(tester, keyed('open-day-review'));
      await waitFor(
        tester,
        find.text('Chưa xác nhận hoặc nhật ký đã thay đổi; hãy kiểm tra lại.'),
      );
      await tap(tester, keyed('confirm-day-review'));
      await waitFor(tester, keyed('confirm-day-review'), absent: true);
      final rangeEnd = DateTime(_today.year, _today.month, _today.day + 1);
      final periodStart = DateTime(_today.year, _today.month, _today.day - 29);
      final recorded = await nutrition.loadRange(alice, periodStart, rangeEnd);
      await tap(tester, keyed('nav-progress'));
      await tap(tester, keyed('report-window-30'));
      await waitFor(tester, keyed('period-total-kcal'));
      expect(
        find.text(
          '${NumberFormat('0.#', 'vi').format(totalMealNutrition(recorded).kcal)} kcal đã ghi',
        ),
        findsOneWidget,
      );
      await waitFor(tester, keyed('recording-coverage'));
      expect(find.textContaining('1 ngày đã xác nhận đủ bữa'), findsOneWidget);
      await capture('c6-h5-period-30');
      await tap(tester, keyed('report-window-90'));
      await waitFor(tester, keyed('period-total-kcal'));
      await waitFor(tester, keyed('recording-coverage'));
      expect(find.textContaining('1 ngày đã xác nhận đủ bữa'), findsOneWidget);
      await tap(tester, keyed('previous-period'));
      await waitFor(
        tester,
        find.textContaining('Chưa ghi bữa ăn trong khoảng này'),
      );
      await tap(tester, keyed('next-period'));
      await waitFor(tester, keyed('period-total-kcal'));
      debugPrint(
        'H5_REPORT 30/90 real totals and effective targets; explicit confirmation; old empty period stays empty',
      );
      await tap(tester, keyed('nav-journal'));
      await tap(tester, keyed('add-meal-snack'));
      await tap(tester, keyed('open-quick-add'));
      await tap(tester, keyed('quick-basis'));
      await tap(tester, find.text(LabelBasis.per100ml.label).last);
      await enter(tester, 'quick-name', 'H6 QA chất xơ');
      await enter(tester, 'quick-amount', '250');
      await enter(tester, 'quick-kcal', '60');
      await enter(tester, 'quick-fiber', '1,2');
      await reveal(tester, keyed('quick-preview'));
      await capture('c6-h6-fiber-volume');
      await tap(tester, keyed('confirm-quick-add'));
      await tap(tester, keyed('save-meal'));
      await waitFor(tester, keyed('save-meal'), absent: true);
      final fiberMeals = await nutrition.loadRange(alice, _today, rangeEnd);
      final fiberMeal = fiberMeals.singleWhere(
        (m) => m.items.any((i) => i.name == 'H6 QA chất xơ'),
      );
      expect(fiberMeal.schemaVersion, 4);
      final fiberItem = fiberMeal.items.singleWhere(
        (i) => i.name == 'H6 QA chất xơ',
      );
      expect(fiberItem.quantityUnit, 'ml');
      expect(fiberItem.quantity, 250);
      expect(fiberItem.nutrition.fiberG, closeTo(3, 1e-9));
      expect(fiberItem.nutrition.fiberKnown, true);
      expect(fiberItem.nutrition.proteinKnown, false);
      final frozenRecipe = fiberMeals.singleWhere((m) => m.id == recipeMeal.id);
      expect(frozenRecipe.totals.fiberKnown, true);
      expect(frozenRecipe.totals.fiberG, closeTo(.5, 1e-9));
      debugPrint(
        'H6_FIBER 250 ml /100 ml -> 3 g; recipe known 0.5 g snapshot survives source deletion',
      );
      await profileRoot();
      await tap(tester, keyed('sign-out'));
      await waitFor(tester, keyed('auth-email'));
      await register(tester, emailB, auth);
      await onboard(tester, 'C6 QA Bob');
      final bob = auth.currentUser!.uid;
      expect(bob, isNot(alice));
      await tap(tester, keyed('nav-progress'));
      await tap(tester, keyed('report-window-7'));
      await tap(tester, keyed('progress-details'));
      await waitFor(
        tester,
        find.textContaining('Chưa có nhật ký bữa ăn, nước hoặc vận động'),
      );
      expect(find.textContaining('C6 món riêng'), findsNothing);
      await expectLater(
        targets.loadForDay(alice, localDateKey(_today)),
        throwsA(isA<NutritionTargetFailure>()),
      );
      expect(await targets.loadForDay(bob, localDateKey(_today)), isNull);
      expect(container.exists(chatControllerProvider), isFalse);
      expect(container.exists(knowledgeServiceProvider), isFalse);
      expect(container.exists(foodScannerServiceProvider), isFalse);
      expect(container.read(appFeatureFlagsProvider).chatbotEnabled, isFalse);
      expect(
        container.read(appFeatureFlagsProvider).foodScannerEnabled,
        isFalse,
      );
      await capture('c6-04-account-isolation');
      await checkpoint('10-signout-second-account-private-data-isolation');
      binding.reportData?['coreAcceptance'] = {
        'project': _project,
        'checkpoints': 10,
        'android': true,
        'production': false,
        'u1ViewportAndRecent': true,
      };
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
