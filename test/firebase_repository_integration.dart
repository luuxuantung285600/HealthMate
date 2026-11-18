// Opt-in real SDK test: the filename deliberately does not end in _test.dart.
// Keep this at test/ root for the Windows web runner's path handling.
// Run only with the demo Auth + Firestore emulators; see docs/test-report.md.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'support/emulator_email_actions.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/reports/data/day_review_repository.dart';
import 'package:healthmate/features/reports/models/period_report.dart';
import 'package:healthmate/features/auth/data/firebase_auth_repository.dart';
import 'package:healthmate/features/auth/models/auth_failure.dart';
import 'package:healthmate/features/auth/data/firebase_account_data_repository.dart';
import 'package:healthmate/features/profile/data/firebase_health_profile_repository.dart';
import 'package:healthmate/features/profile/models/onboarding_draft.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'package:healthmate/features/profile/models/profile_appearance.dart';
import 'package:healthmate/features/profile/models/profile_failure.dart';
import 'package:healthmate/features/weekly_reflection/models/weekly_reflection.dart';
import 'package:healthmate/features/profile/models/health_goal.dart';
import 'package:healthmate/features/nutrition/data/firebase_nutrition_repository.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/models/nutrition_failure.dart';
import 'package:healthmate/features/food_library/data/firebase_favorite_food_repository.dart';
import 'package:healthmate/features/food_library/data/firebase_food_library_repository.dart';
import 'package:healthmate/features/food_library/models/food_library_models.dart';
import 'package:healthmate/features/food_library/models/favorite_food.dart';
import 'package:healthmate/features/nutrition_targets/data/firebase_nutrition_target_repository.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/water/data/firebase_water_repository.dart';
import 'package:healthmate/features/water/models/water_log.dart';
import 'package:healthmate/features/activity/data/firebase_activity_repository.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/activity/models/activity_energy.dart';
import 'package:healthmate/features/journal/models/daily_log_failure.dart';
import 'package:healthmate/features/goals/data/firebase_goals_repository.dart';
import 'package:healthmate/features/goals/models/tracking_goal.dart';
import 'package:healthmate/features/daily_quest/models/daily_quest.dart';
import 'package:healthmate/features/chatbot/data/firebase_chat_repository.dart';
import 'package:healthmate/features/chatbot/models/chat_models.dart';
import 'package:healthmate/features/meal_templates/data/meal_template_repository.dart';
import 'package:healthmate/features/meal_templates/models/meal_template.dart';
import 'package:healthmate/features/wellness/data/wellness_repository.dart';
import 'package:healthmate/features/wellness/data/energy_repository.dart';
import 'package:healthmate/features/wellness/models/energy_budget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('HEALTHMATE_EMULATOR_TESTS');
  const projectId = 'demo-healthmate-rules';
  if (!enabled || !projectId.startsWith('demo-')) {
    throw StateError(
      'Requires HEALTHMATE_EMULATOR_TESTS=true and a demo project. No production fallback.',
    );
  }
  late FirebaseApp app;
  late FirebaseAuth auth;
  late FirebaseFirestore db;
  late FirebaseAuthRepository authentication;
  late FirebaseHealthProfileRepository profiles;
  late FirebaseNutritionRepository nutrition;
  late FirebaseWaterRepository water;
  late FirebaseActivityRepository activities;
  late FirebaseGoalsRepository goals;
  late FirebaseChatRepository chats;
  late String alice;
  late String bob;
  late String chatSessionId;
  late String chatTurnId;
  final suffix = DateTime.now().microsecondsSinceEpoch;
  final aliceEmail = 'alice-$suffix@example.com';
  final bobEmail = 'bob-$suffix@example.com';
  const password = 'Emulator-only-test-123!';
  final day = localDateOnly(DateTime.now());

  setUpAll(() async {
    FirebaseCoreWeb.registerWith(webPluginRegistrar);
    FirebaseAuthWeb.registerWith(webPluginRegistrar);
    FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
    webPluginRegistrar.registerMessageHandler();
    app = await Firebase.initializeApp(
      name: 'stage10-emulator',
      options: const FirebaseOptions(
        apiKey: 'emulator-only-fake-api-key',
        appId: '1:1234567890:web:stage10emulator',
        messagingSenderId: '1234567890',
        projectId: projectId,
        authDomain: 'localhost',
      ),
    );
    auth = FirebaseAuth.instanceFor(app: app);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    await auth.setPersistence(Persistence.NONE);
    db = FirebaseFirestore.instanceFor(app: app);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
    authentication = FirebaseAuthRepository(auth);
    profiles = FirebaseHealthProfileRepository(db);
    // This suite tests real Firestore data. UI assets are verified separately
    // in Flutter/native tests; Chrome's SDK test harness has no asset channel.
    nutrition = FirebaseNutritionRepository(db, catalogLoader: () async => []);
    water = FirebaseWaterRepository(db);
    activities = FirebaseActivityRepository(db);
    goals = FirebaseGoalsRepository(db);
    chats = FirebaseChatRepository(db);
    await authentication.register(email: aliceEmail, password: password);
    alice = auth.currentUser!.uid;
    await verifyEmulatorEmail(auth, projectId: projectId, host: '127.0.0.1');
  });

  tearDownAll(() async {
    await db.enableNetwork();
    await auth.signOut();
    await app.delete();
  });

  Future<void> seedC3Catalog(
    String id, {
    double kcal = 130,
    bool corrupt = false,
    Map<String, double> extras = const {},
    double? fiber,
  }) async {
    // Emulator-only owner token; never use this against a non-demo project/host.
    final fields = <String, dynamic>{
      'name': {'stringValue': 'Cơm fixture C3'},
      'servingBasis': {'stringValue': 'per_100g'},
      'unit': {'stringValue': 'g'},
      'category': {'stringValue': 'Fixture'},
      'sourceLabel': {'stringValue': 'Emulator synthetic fixture'},
      'isEstimated': {'booleanValue': true},
      'kcalPer100g': {'doubleValue': kcal},
      'proteinGPer100g': {'doubleValue': 2.69},
      'carbsGPer100g': {'doubleValue': 28.17},
      if (!corrupt) 'fatGPer100g': {'doubleValue': .28},
      if (fiber != null) 'fiberGPer100g': {'doubleValue': fiber},
      if (extras.isNotEmpty)
        'extraNutrientsPer100g': {
          'mapValue': {
            'fields': {
              for (final entry in extras.entries)
                entry.key: {'doubleValue': entry.value},
            },
          },
        },
    };
    final response = await http.patch(
      Uri.parse(
        'http://127.0.0.1:8080/v1/projects/$projectId/databases/(default)/documents/food_catalog/$id',
      ),
      headers: {
        'Authorization': 'Bearer owner',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fields': fields}),
    );
    expect(response.statusCode, 200);
  }

  test(
    'secondary nutrient markers and catalog snapshots persist with real Firebase repositories',
    () async {
      await profiles.ensureProfile(uid: alice, email: aliceEmail);
      const foodId = 'secondary-sdk-fixture';
      final key = localDateKey(day), mealId = 'secondary-sdk-$suffix';
      final targets = FirebaseNutritionTargetRepository(db);
      try {
        await seedC3Catalog(
          foodId,
          extras: {'sodium': 400, 'sugar': 12},
          fiber: 3,
        );
        final catalog = await nutrition.watchFoodCatalog().firstWhere(
          (foods) => foods.any((f) => f.id == foodId),
        );
        final food = catalog.singleWhere((f) => f.id == foodId);
        final item = MealItemSnapshot.fromCatalog(food, 200);
        await nutrition.addMeal(
          uid: alice,
          operationId: mealId,
          draft: MealDraft(
            type: MealType.lunch,
            consumedAt: day,
            items: [item],
            source: MealSource.manual,
          ),
        );
        final logs = await nutrition
            .watchMealLogs(alice, day)
            .firstWhere((logs) => logs.any((m) => m.id == mealId));
        final recorded = logs.singleWhere((m) => m.id == mealId).totals;
        expect(recorded.saltEquivalentG, 2);
        expect(recorded.totalSugarG, 24);
        expect(recorded.fiberG, 6);
        expect(recorded.fiberKnown, isTrue);
        await targets.save(
          alice,
          NutritionTarget(
            effectiveFromDateKey: key,
            kcalTarget: 2000,
            saltGLimit: 5,
            sugarGLimit: 50,
            fiberGTarget: 30,
          ),
        );
        final saved = (await targets.loadForDay(alice, key))!;
        expect(saved.saltGLimit, 5);
        expect(saved.sugarGLimit, 50);
        expect(saved.fiberGTarget, 30);
        await targets.save(
          alice,
          NutritionTarget(
            effectiveFromDateKey: key,
            kcalTarget: 2000,
            saltGLimit: 0,
            sugarGLimit: null,
            fiberGTarget: 25,
          ),
        );
        final updated = (await targets.loadForRange(
          alice,
          key,
          localDateKey(DateTime(day.year, day.month, day.day + 1)),
        )).single;
        expect(updated.saltGLimit, 0);
        expect(updated.sugarGLimit, isNull);
        expect(updated.fiberGTarget, 25);
      } finally {
        await db.doc('users/$alice/meal_logs/$mealId').delete();
        await db.doc('users/$alice/nutrition_targets/$key').delete();
        await http.delete(
          Uri.parse(
            'http://127.0.0.1:8080/v1/projects/$projectId/databases/(default)/documents/food_catalog/$foodId',
          ),
          headers: {'Authorization': 'Bearer owner'},
        );
      }
    },
  );

  test(
    'water quick undo is atomic, preserves edits and enforces UID privacy',
    () async {
      await profiles.ensureProfile(uid: alice, email: aliceEmail);
      final draft = WaterLogDraft(amountMl: 350, consumedAt: DateTime.now());
      final ids = <String>[];
      final fresh = await water.add(uid: alice, draft: draft);
      ids.add(fresh);
      final baseline = await water.add(
        uid: alice,
        draft: WaterLogDraft(amountMl: 500, consumedAt: draft.consumedAt),
      );
      ids.add(baseline);
      final path = db.doc('users/$alice/water_logs/$fresh');
      final created = (await path.get(
        const GetOptions(source: Source.server),
      )).data()!;
      expect(created['createdAt'], created['updatedAt']);
      await water.undoAdd(uid: alice, logId: fresh, draft: draft);
      await water.undoAdd(uid: alice, logId: fresh, draft: draft);
      expect(
        (await path.get(const GetOptions(source: Source.server))).exists,
        isFalse,
      );
      final remaining = await water.watchLogs(alice, draft.dateKey).first;
      expect(remaining.any((entry) => entry.id == fresh), isFalse);
      expect(
        remaining.singleWhere((entry) => entry.id == baseline).amountMl,
        500,
      );

      final edited = await water.add(uid: alice, draft: draft);
      ids.add(edited);
      await water.update(
        uid: alice,
        logId: edited,
        draft: WaterLogDraft(amountMl: 750, consumedAt: draft.consumedAt),
      );
      final conflict = isA<DailyLogFailure>().having(
        (error) => error.code,
        'code',
        'water-entry-changed',
      );
      await expectLater(
        water.undoAdd(uid: alice, logId: edited, draft: draft),
        throwsA(conflict),
      );
      final editedPath = db.doc('users/$alice/water_logs/$edited');
      expect(
        (await editedPath.get(
          const GetOptions(source: Source.server),
        )).data()!['amountMl'],
        750,
      );
      // An edit back to the original values must still be protected.
      await water.update(uid: alice, logId: edited, draft: draft);
      await expectLater(
        water.undoAdd(uid: alice, logId: edited, draft: draft),
        throwsA(conflict),
      );
      expect(
        (await editedPath.get(const GetOptions(source: Source.server))).exists,
        isTrue,
      );

      await authentication.signOut();
      final otherEmail = 'water-undo-bob-$suffix@example.com';
      await authentication.register(email: otherEmail, password: password);
      await verifyEmulatorEmail(auth, projectId: projectId, host: '127.0.0.1');
      final other = auth.currentUser!.uid;
      await profiles.ensureProfile(uid: other, email: otherEmail);
      try {
        await expectLater(
          water.undoAdd(uid: alice, logId: edited, draft: draft),
          throwsA(isA<DailyLogFailure>()),
        );
        final own = await water.add(uid: other, draft: draft);
        await water.undoAdd(uid: other, logId: own, draft: draft);
        expect(
          (await db
                  .doc('users/$other/water_logs/$own')
                  .get(const GetOptions(source: Source.server)))
              .exists,
          isFalse,
        );
      } finally {
        await authentication.signOut();
        await authentication.signIn(email: aliceEmail, password: password);
        expect(
          (await editedPath.get(
            const GetOptions(source: Source.server),
          )).exists,
          isTrue,
        );
        for (final id in ids) {
          await water.delete(uid: alice, logId: id);
        }
      }
    },
  );

  test(
    'guided workout save is idempotent, confirms server data and enforces UID privacy',
    () async {
      await profiles.ensureProfile(uid: alice, email: aliceEmail);
      final at = DateTime.now();
      final draft = ActivityLogDraft(
        type: ActivityType.strength,
        durationMinutes: 6,
        performedAt: at,
        note: 'Guided workout emulator fixture',
        energyEstimate: ActivityEnergyEstimate(
          metCode: '02022',
          weightKg: 60,
          weightMeasuredAt: at.subtract(const Duration(days: 1)),
          ageYears: 26,
          durationSeconds: 377,
        ),
      );
      final operation = 'workout-emulator-$suffix';
      final ids = await Future.wait([
        activities.add(uid: alice, draft: draft, operationId: operation),
        activities.add(uid: alice, draft: draft, operationId: operation),
      ]);
      expect(ids.toSet(), {operation});
      final path = db.doc('users/$alice/activity_logs/$operation');
      final first = (await path.get(
        const GetOptions(source: Source.server),
      )).data()!;
      expect(first['durationMinutes'], 6);
      await activities.add(uid: alice, draft: draft, operationId: operation);
      final retried = (await path.get(
        const GetOptions(source: Source.server),
      )).data()!;
      expect(retried['createdAt'], first['createdAt']);
      expect(retried['updatedAt'], first['updatedAt']);
      final logs = await activities.watchLogs(alice, draft.dateKey).first;
      expect(logs.where((log) => log.id == operation).length, 1);
      final savedEnergy = logs
          .singleWhere((log) => log.id == operation)
          .energyEstimate!;
      expect(savedEnergy.toData(), draft.energyEstimate!.toData());
      expect(savedEnergy.activeKcal, closeTo(17.593333333333, .000001));
      await expectLater(
        activities.add(
          uid: alice,
          operationId: operation,
          draft: ActivityLogDraft(
            type: ActivityType.strength,
            durationMinutes: 9,
            performedAt: at,
          ),
        ),
        throwsA(isA<DailyLogFailure>()),
      );
      expect(
        (await path.get(
          const GetOptions(source: Source.server),
        )).data()!['durationMinutes'],
        6,
      );
      await expectLater(
        activities.add(uid: alice, operationId: 'unsafe/path', draft: draft),
        throwsA(isA<DailyLogFailure>()),
      );
      await authentication.signOut();
      await authentication.register(
        email: 'workout-bob-$suffix@example.com',
        password: password,
      );
      await verifyEmulatorEmail(auth, projectId: projectId, host: '127.0.0.1');
      final other = auth.currentUser!.uid;
      await profiles.ensureProfile(
        uid: other,
        email: 'workout-bob-$suffix@example.com',
      );
      try {
        await expectLater(
          path.get(const GetOptions(source: Source.server)),
          throwsA(isA<FirebaseException>()),
        );
        await expectLater(
          activities.add(uid: alice, draft: draft, operationId: operation),
          throwsA(isA<DailyLogFailure>()),
        );
        await activities.add(uid: other, draft: draft, operationId: operation);
        expect(
          (await db
                  .doc('users/$other/activity_logs/$operation')
                  .get(const GetOptions(source: Source.server)))
              .data()!['durationMinutes'],
          6,
        );
        await activities.delete(uid: other, logId: operation);
      } finally {
        await authentication.signOut();
        await authentication.signIn(email: aliceEmail, password: password);
        await activities.delete(uid: alice, logId: operation);
      }
    },
  );

  test(
    'H1 repository reads real catalog portions and snapshots fractional servings',
    () async {
      // Imported by the emulator-only Node createWrites fixture before this suite.
      final catalog = await nutrition.watchFoodCatalog().first;
      final pho = catalog.singleWhere((f) => f.id == 'vn-pho-bo');
      expect(pho.hasValidServing, isTrue);
      expect(pho.servingGrams, 600);
      final yogurt = catalog.singleWhere(
        (f) => f.id == 'th-yogurt-sweetened-100g',
      );
      expect(yogurt.brand, 'TH true YOGURT');
      expect(yogurt.forGrams(50).kcal, closeTo(47.45, .001));
      final phoPer100g = pho.per100g!;
      final phoServingGrams = pho.servingGrams!;
      final draft = MealDraft(
        type: MealType.snack,
        consumedAt: DateTime.now(),
        items: [MealItemSnapshot.fromCatalog(pho, phoServingGrams * .25)],
        source: MealSource.manual,
      );
      final id = await nutrition.addMeal(uid: alice, draft: draft);
      final read = (await nutrition.loadRange(
        alice,
        day,
        DateTime(day.year, day.month, day.day + 1),
      )).singleWhere((m) => m.id == id);
      expect(read.items.single.grams, 150);
      expect(read.totals.kcal, closeTo(phoPer100g.kcal * 1.5, .001));
      await nutrition.deleteMeal(uid: alice, mealId: id);
    },
  );

  test(
    'real Flutter repositories persist and reload onboarding, logs, goal, quest and chat',
    () async {
      await profiles.ensureProfile(uid: alice, email: aliceEmail);
      final draft = OnboardingDraft(
        displayName: 'Emulator Alice',
        birthDate: DateTime(2000, 1, 15),
        heightCm: 170,
        currentWeightKg: 70,
        healthGoal: HealthGoal.maintainWeight,
        targetWeightKg: null,
      );
      await profiles.completeOnboarding(uid: alice, draft: draft);
      final first =
          (await db
                  .doc('users/$alice')
                  .get(const GetOptions(source: Source.server)))
              .data()!['onboardingCompletedAt'];
      // Repeating setup must preserve the immutable completion marker.
      await profiles.completeOnboarding(uid: alice, draft: draft);
      final profile = await profiles.watchProfile(alice).first;
      expect(profile!.isOnboardingComplete, isTrue);
      expect(profile.onboardingCompletedAt, (first as Timestamp).toDate());
      expect((await profiles.watchBodyMetrics(alice).first).length, 1);
      final now = DateTime.now();
      await nutrition.addMeal(
        uid: alice,
        draft: MealDraft(
          type: MealType.lunch,
          consumedAt: now,
          source: MealSource.manual,
          items: const [
            MealItemSnapshot(
              foodId: 'test-rice',
              name: 'Cơm kiểm thử',
              grams: 150,
              nutrition: NutritionTotals(
                kcal: 195,
                proteinG: 4,
                carbsG: 42,
                fatG: 0.4,
              ),
              sourceLabel: 'Emulator fixture',
              isEstimated: true,
            ),
          ],
        ),
      );
      await water.add(
        uid: alice,
        draft: WaterLogDraft(amountMl: 250, consumedAt: now),
      );
      await activities.add(
        uid: alice,
        draft: ActivityLogDraft(
          type: ActivityType.walking,
          durationMinutes: 20,
          performedAt: now,
        ),
      );
      final end = DateTime(day.year, day.month, day.day + 1);
      expect(
        totalMealNutrition(await nutrition.loadRange(alice, day, end)).kcal,
        195,
      );
      expect(totalWaterMl(await water.loadRange(alice, day, end)), 250);
      expect(
        totalActivityMinutes(await activities.loadRange(alice, day, end)),
        20,
      );
      expect(
        (await nutrition.watchMealLogs(alice, day).first).single.totals.kcal,
        195,
      );
      await goals.saveGoal(
        alice,
        GoalDraft(
          type: GoalType.water,
          targetValue: 500,
          startDate: day,
          endDate: end,
        ),
      );
      expect(
        (await goals.watchGoals(alice).first).single.draft.targetValue,
        500,
      );
      final quest = DailyQuest(
        dateKey: localDateKey(day),
        type: QuestType.water,
        title: 'Ghi nước',
        description: 'Ghi một lần uống nước.',
        reason: 'Kiểm thử',
        targetValue: 250,
        unit: 'ml',
      );
      await goals.ensureQuest(alice, quest);
      await goals.finishQuest(alice, quest.dateKey, QuestStatus.completed);
      await goals.ensureQuest(alice, quest);
      expect(
        (await goals.watchQuest(alice, quest.dateKey).first)!.status,
        QuestStatus.completed,
      );
      final session = chats.newId();
      chatSessionId = session;
      final turn = ChatTurn(
        id: chats.newId(),
        question: 'Kcal đã ghi',
        answer: '195 kcal theo dữ liệu kiểm thử.',
        source: ChatSource.journal,
      );
      chatTurnId = turn.id;
      await chats.saveTurn(alice, session, turn);
      await chats.saveTurn(alice, session, turn);
      expect((await chats.loadSessions(alice)).single.messageCount, 2);
      expect(
        (await chats.loadMessages(
          alice,
          session,
        )).map((message) => message.isUser),
        [true, false],
      );
    },
  );

  test(
    'real Auth credentials cannot read or write another UID through Firestore',
    () async {
      await authentication.signOut();
      await authentication.register(email: bobEmail, password: password);
      bob = auth.currentUser!.uid;
      await verifyEmulatorEmail(auth, projectId: projectId, host: '127.0.0.1');
      expect(bob, isNot(alice));
      await expectLater(
        db.doc('users/$alice').get(const GetOptions(source: Source.server)),
        throwsA(
          isA<FirebaseException>().having(
            (error) => error.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      await expectLater(
        water.add(
          uid: alice,
          draft: WaterLogDraft(amountMl: 250, consumedAt: DateTime.now()),
        ),
        throwsA(anything),
      );
      await authentication.signOut();
      await authentication.signIn(email: aliceEmail, password: password);
      expect(auth.currentUser!.uid, alice);
    },
  );

  test(
    'offline writes stay pending locally and commit once after reconnect',
    () async {
      final reference = db.collection('users/$alice/water_logs');
      await db.disableNetwork();
      var confirmed = false;
      final local = reference
          .snapshots(includeMetadataChanges: true)
          .firstWhere(
            (snapshot) =>
                snapshot.metadata.hasPendingWrites &&
                snapshot.docs.any((doc) => doc.data()['amountMl'] == 333),
          );
      final write = water.add(
        uid: alice,
        draft: WaterLogDraft(amountMl: 333, consumedAt: DateTime.now()),
      );
      final confirmation = write.then((value) {
        confirmed = true;
        return value;
      });
      try {
        final snapshot = await local.timeout(const Duration(seconds: 10));
        expect(snapshot.metadata.isFromCache, isTrue);
        expect(confirmed, isFalse);
      } finally {
        await db.enableNetwork();
      }
      final id = await confirmation;
      expect(
        (await reference.doc(id).get(const GetOptions(source: Source.server)))
            .data()!['amountMl'],
        333,
      );
      expect(
        totalWaterMl(
          await water.loadRange(
            alice,
            day,
            DateTime(day.year, day.month, day.day + 1),
          ),
        ),
        583,
      );
    },
  );

  test(
    'F02 snapshot scaling survives repository save/reload independently of catalog',
    () async {
      const old = MealItemSnapshot(
        foodId: 'rice-cooked',
        name: 'Cơm cũ',
        grams: 100,
        nutrition: NutritionTotals(
          kcal: 130,
          proteinG: 2.69,
          carbsG: 28.17,
          fatG: .28,
        ),
        sourceLabel: 'Nguồn lịch sử',
        isEstimated: true,
      );
      final id = await nutrition.addMeal(
        uid: alice,
        draft: MealDraft(
          type: MealType.lunch,
          consumedAt: DateTime.now(),
          items: [old],
          source: MealSource.manual,
        ),
      );
      for (final grams in [100.0, 150.0]) {
        await nutrition.updateMeal(
          uid: alice,
          mealId: id,
          draft: MealDraft(
            type: MealType.lunch,
            consumedAt: DateTime.now(),
            items: [old.withGrams(grams)],
            source: MealSource.manual,
          ),
        );
        final loaded = (await nutrition.loadRange(
          alice,
          day,
          DateTime(day.year, day.month, day.day + 1),
        )).singleWhere((meal) => meal.id == id).items.single;
        expect(loaded.nutrition.kcal, 130 * grams / 100);
        expect(loaded.nutrition.carbsG, closeTo(28.17 * grams / 100, 1e-9));
        expect(loaded.sourceLabel, 'Nguồn lịch sử');
        expect(loaded.hasNutritionData, isTrue);
      }
      const current = FoodCatalogItem(
        id: 'rice-cooked',
        name: 'Cơm hiện tại',
        alternateNames: [],
        category: 'Ngũ cốc',
        servingBasis: ServingBasis.per100g,
        unit: 'g',
        per100g: NutritionTotals(kcal: 260),
        sourceLabel: 'Nguồn mới',
        isEstimated: true,
      );
      final newer = await nutrition.addMeal(
        uid: alice,
        draft: MealDraft(
          type: MealType.dinner,
          consumedAt: DateTime.now(),
          items: [MealItemSnapshot.fromCatalog(current, 150)],
          source: MealSource.manual,
        ),
      );
      final loaded = (await nutrition.loadRange(
        alice,
        day,
        DateTime(day.year, day.month, day.day + 1),
      )).singleWhere((meal) => meal.id == newer);
      expect(loaded.totals.kcal, 390);
    },
  );

  test(
    'R01 goal write remains pending across 15 seconds offline and commits once',
    () async {
      final collection = db.collection('users/$alice/goals');
      final before = (await collection.get(
        const GetOptions(source: Source.server),
      )).size;
      await db.disableNetwork();
      var settled = false;
      Object? error;
      final write = goals
          .saveGoal(
            alice,
            GoalDraft(
              type: GoalType.water,
              targetValue: 501,
              startDate: day,
              endDate: DateTime(day.year, day.month, day.day + 2),
            ),
          )
          .then(
            (_) {
              settled = true;
            },
            onError: (Object failure) {
              settled = true;
              error = failure;
            },
          );
      bool settledOffline;
      try {
        await Future<void>.delayed(const Duration(seconds: 16));
        settledOffline = settled;
      } finally {
        await db.enableNetwork();
        await write;
        await db.waitForPendingWrites();
      }
      expect(
        (await collection.get(const GetOptions(source: Source.server))).size,
        before + 1,
      );
      expect(
        settledOffline,
        isFalse,
        reason:
            'A timeout must not claim rejection while the SDK still commits the write.',
      );
      expect(error, isNull);
      final stable = goals.newGoalId();
      final draft = GoalDraft(
        type: GoalType.water,
        targetValue: 502,
        startDate: day,
        endDate: DateTime(day.year, day.month, day.day + 2),
      );
      await goals.saveGoal(alice, draft, id: stable, create: true);
      await goals.saveGoal(alice, draft, id: stable, create: true);
      await expectLater(
        goals.saveGoal(
          alice,
          GoalDraft(
            type: GoalType.water,
            targetValue: 503,
            startDate: day,
            endDate: DateTime(day.year, day.month, day.day + 2),
          ),
          id: stable,
          create: true,
        ),
        throwsA(anything),
      );
      expect(
        (await collection.get(const GetOptions(source: Source.server))).size,
        before + 2,
      );
      await goals.saveGoal(alice, draft, id: goals.newGoalId(), create: true);
      expect(
        (await collection.get(const GetOptions(source: Source.server))).size,
        before + 3,
      );
    },
  );

  test(
    'C3 favorites and copied meals preserve source, idempotency and ownership with real repositories',
    () async {
      await seedC3Catalog('c3-rice');
      await seedC3Catalog('c3-corrupt', corrupt: true);
      final catalog = await nutrition.watchFoodCatalog().firstWhere(
        (items) => items.any((food) => food.id == 'c3-corrupt'),
      );
      expect(
        catalog.singleWhere((food) => food.id == 'c3-rice').hasNutritionData,
        isTrue,
      );
      expect(
        catalog.singleWhere((food) => food.id == 'c3-corrupt').hasNutritionData,
        isFalse,
      );
      final favorites = FirebaseFavoriteFoodRepository(db);
      await favorites.setFavorite(alice, 'c3-rice', true);
      final favoriteRef = db.doc('users/$alice/favorite_foods/catalog_c3-rice');
      final createdAt = (await favoriteRef.get(
        const GetOptions(source: Source.server),
      )).data()!['createdAt'];
      await favorites.setFavorite(alice, 'c3-rice', true);
      final page = await favorites
          .watch(alice)
          .firstWhere((page) => !page.fromCache);
      expect(
        page.items.where((food) => food.sourceId == 'c3-rice'),
        hasLength(1),
      );
      expect(
        (await favoriteRef.get(
          const GetOptions(source: Source.server),
        )).data()!['createdAt'],
        createdAt,
      );
      await favorites.setFavorite(alice, 'c3-rice', false);
      expect(
        (await favoriteRef.get(const GetOptions(source: Source.server))).exists,
        isFalse,
      );
      await favorites.setFavorite(alice, 'c3-rice', true);
      await authentication.signOut();
      await authentication.signIn(email: bobEmail, password: password);
      await favorites.setFavorite(bob, 'c3-rice', true);
      await expectLater(
        db
            .doc('users/$alice/favorite_foods/catalog_c3-rice')
            .get(const GetOptions(source: Source.server)),
        throwsA(isA<FirebaseException>()),
      );
      await authentication.signOut();
      await authentication.signIn(email: aliceEmail, password: password);

      final sourceDay = DateTime(day.year, day.month, day.day - 1);
      final copiedDay = DateTime(day.year, day.month, day.day - 2);
      final snapshot = MealItemSnapshot.fromCatalog(
        catalog.singleWhere((food) => food.id == 'c3-rice'),
        150,
      );
      final sourceId = await nutrition.addMeal(
        uid: alice,
        draft: MealDraft(
          type: MealType.dinner,
          consumedAt: sourceDay,
          items: [snapshot],
          source: MealSource.manual,
        ),
      );
      final source = (await nutrition.loadRange(
        alice,
        sourceDay,
        day,
      )).singleWhere((meal) => meal.id == sourceId);
      final sourceBefore =
          (await db
                  .doc('users/$alice/meal_logs/$sourceId')
                  .get(const GetOptions(source: Source.server)))
              .data();
      await seedC3Catalog('c3-rice', kcal: 260);
      final draft = source.copyDraft(day: copiedDay);
      final stable = nutrition.newMealId();
      await nutrition.addMeal(uid: alice, draft: draft, operationId: stable);
      await nutrition.addMeal(uid: alice, draft: draft, operationId: stable);
      var copied = (await nutrition.loadRange(alice, copiedDay, sourceDay));
      expect(copied.where((meal) => meal.id == stable), hasLength(1));
      expect(copied.singleWhere((meal) => meal.id == stable).totals.kcal, 195);
      expect(
        copied.singleWhere((meal) => meal.id == stable).dateKey,
        localDateKey(copiedDay),
      );
      expect(
        copied.singleWhere((meal) => meal.id == stable).timezoneOffsetMinutes,
        draft.timezoneOffsetMinutes,
      );
      final changed = MealDraft(
        type: draft.type,
        consumedAt: draft.consumedAt,
        items: [snapshot.withGrams(100)],
        source: draft.source,
      );
      await expectLater(
        nutrition.addMeal(uid: alice, draft: changed, operationId: stable),
        throwsA(isA<NutritionFailure>()),
      );
      await nutrition.updateMeal(uid: alice, mealId: stable, draft: changed);
      copied = await nutrition.loadRange(alice, copiedDay, sourceDay);
      expect(copied.singleWhere((meal) => meal.id == stable).totals.kcal, 130);
      final another = await nutrition.addMeal(
        uid: alice,
        draft: draft,
        operationId: nutrition.newMealId(),
      );
      expect(another, isNot(stable));
      await nutrition.deleteMeal(uid: alice, mealId: stable);
      copied = await nutrition.loadRange(alice, copiedDay, sourceDay);
      expect(copied.where((meal) => meal.id == stable), isEmpty);
      expect(copied.singleWhere((meal) => meal.id == another).totals.kcal, 195);
      expect(
        (await db
                .doc('users/$alice/meal_logs/$sourceId')
                .get(const GetOptions(source: Source.server)))
            .data(),
        sourceBefore,
      );
    },
  );

  test(
    'C3 unconfirmed offline writes retry without duplicate meals or favorites',
    () async {
      final favorites = FirebaseFavoriteFoodRepository(db);
      await favorites.setFavorite(alice, 'c3-rice', false);
      final id = nutrition.newMealId();
      final draft = MealDraft(
        type: MealType.snack,
        consumedAt: DateTime(day.year, day.month, day.day - 3, 9, 15),
        items: [
          MealItemSnapshot(
            foodId: 'historical-rice',
            name: 'Snapshot không có catalog',
            grams: 150,
            nutrition: const NutritionTotals(
              kcal: 195,
              proteinG: 4.035,
              carbsG: 42.255,
              fatG: .42,
            ),
            sourceLabel: 'Emulator snapshot fixture',
            isEstimated: true,
          ),
        ],
        source: MealSource.manual,
      );
      await db.disableNetwork();
      try {
        await expectLater(
          favorites.setFavorite(alice, 'c3-rice', true),
          throwsA(isA<FavoriteFoodFailure>()),
        );
        await expectLater(
          nutrition.addMeal(uid: alice, draft: draft, operationId: id),
          throwsA(isA<NutritionFailure>()),
        );
      } finally {
        await db.enableNetwork();
      }
      // A failed acknowledgment is not proof of rollback. Retrying the desired
      // operation must work whether the transaction reached the server or not.
      await favorites.setFavorite(alice, 'c3-rice', true);
      await nutrition.addMeal(uid: alice, draft: draft, operationId: id);
      await nutrition.addMeal(uid: alice, draft: draft, operationId: id);
      expect(
        (await db
                .collection('users/$alice/favorite_foods')
                .get(const GetOptions(source: Source.server)))
            .docs,
        hasLength(1),
      );
      final meals = await nutrition.loadRange(
        alice,
        DateTime(day.year, day.month, day.day - 3),
        DateTime(day.year, day.month, day.day - 2),
      );
      expect(meals, hasLength(1));
      expect(meals.single.id, id);
      expect(meals.single.totals.kcal, 195);
      await db.disableNetwork();
      bool completed = false;
      final removal = favorites
          .setFavorite(alice, 'c3-rice', false)
          .then((_) => completed = true);
      try {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(completed, isFalse);
      } finally {
        await db.enableNetwork();
      }
      await removal;
      expect(
        (await db
                .doc('users/$alice/favorite_foods/catalog_c3-rice')
                .get(const GetOptions(source: Source.server)))
            .exists,
        isFalse,
      );
      await favorites.setFavorite(alice, 'c3-rice', true);
    },
  );

  test(
    'C4 real library CRUD, fractional portions and frozen meal/ingredient snapshots survive source changes',
    () async {
      final library = FirebaseFoodLibraryRepository(db);
      final favorites = FirebaseFavoriteFoodRepository(db);
      final food = PersonalFood(
        id: 'c4-personal',
        name: 'Cơm riêng fixture',
        per100g: const NutritionTotals(
          kcal: 130,
          proteinG: 2.69,
          carbsG: 28.17,
          fatG: .28,
        ),
        defaultServingGrams: 150,
        servingLabel: 'bát',
        servingGrams: 150,
        alternateNames: ['cơm riêng'],
      );
      await library.save(alice, food, create: true);
      await library.save(alice, food, create: true);
      final ref = db.doc('users/$alice/custom_foods/${food.id}');
      final createdAt = (await ref.get(
        const GetOptions(source: Source.server),
      )).data()!['createdAt'];
      final loaded =
          await library.load(alice, FoodSourceKind.custom, food.id)
              as PersonalFood;
      expect(loaded.asFood().servingGrams, 150);
      expect(loaded.asFood().forGrams(150).kcal, 195);
      expect(
        (await library
                .watch(alice, FoodSourceKind.custom)
                .firstWhere((page) => !page.fromCache))
            .items,
        hasLength(1),
      );
      final recipe = FoodRecipe(
        id: 'c4-recipe',
        name: 'Công thức sáu nguyên liệu',
        ingredients: List.generate(
          6,
          (_) => MealItemSnapshot.fromCatalog(loaded.asFood(), 100),
        ),
        yieldGrams: 450,
        servingsCount: 2.5,
      );
      await library.save(alice, recipe, create: true);
      await library.save(alice, recipe, create: true);
      final reloaded =
          await library.load(alice, FoodSourceKind.recipe, recipe.id)
              as FoodRecipe;
      expect(reloaded.ingredients, hasLength(6));
      expect(reloaded.totals.kcal, 780);
      expect(reloaded.portionGrams, 180);
      final halfPortion = MealItemSnapshot.fromCatalog(
        reloaded.asFood(),
        reloaded.portionGrams! * .5,
      );
      expect(halfPortion.grams, 90);
      expect(halfPortion.nutrition.kcal, 156);
      final mealId = nutrition.newMealId();
      final mealDraft = MealDraft(
        type: MealType.dinner,
        consumedAt: DateTime(day.year, day.month, day.day - 4, 18),
        items: [
          MealItemSnapshot.fromCatalog(loaded.asFood(), 150),
          halfPortion,
        ],
        source: MealSource.manual,
      );
      await nutrition.addMeal(
        uid: alice,
        draft: mealDraft,
        operationId: mealId,
      );
      final mealRef = db.doc('users/$alice/meal_logs/$mealId');
      final historical = (await mealRef.get(
        const GetOptions(source: Source.server),
      )).data();
      expect(historical!['totalKcal'], 351);
      await favorites.setFavorite(
        alice,
        food.id,
        true,
        sourceKind: FoodSourceKind.custom,
      );
      await favorites.setFavorite(
        alice,
        recipe.id,
        true,
        sourceKind: FoodSourceKind.recipe,
      );
      final favoritePage = await favorites
          .watch(alice)
          .firstWhere((page) => !page.fromCache && page.items.length >= 3);
      expect(
        favoritePage.items.map((item) => item.id),
        containsAll(['custom_c4-personal', 'recipe_c4-recipe']),
      );
      await library.save(
        alice,
        PersonalFood(
          id: food.id,
          name: 'Cơm đổi nguồn',
          per100g: const NutritionTotals(
            kcal: 260,
            proteinG: 5.38,
            carbsG: 56.34,
            fatG: .56,
          ),
        ),
        create: false,
      );
      expect(
        (await ref.get(
          const GetOptions(source: Source.server),
        )).data()!['createdAt'],
        createdAt,
      );
      expect(
        (await library.load(alice, FoodSourceKind.recipe, recipe.id)
                as FoodRecipe)
            .totals
            .kcal,
        780,
      );
      await library.save(
        alice,
        FoodRecipe(
          id: recipe.id,
          name: 'Công thức sửa yield',
          ingredients: recipe.ingredients,
          yieldGrams: 900,
          servingsCount: 3,
        ),
        create: false,
      );
      expect(
        (await mealRef.get(const GetOptions(source: Source.server))).data(),
        historical,
      );
      await library.delete(alice, FoodSourceKind.custom, food.id);
      await library.delete(alice, FoodSourceKind.recipe, recipe.id);
      expect(await library.load(alice, FoodSourceKind.custom, food.id), isNull);
      expect(
        await library.load(alice, FoodSourceKind.recipe, recipe.id),
        isNull,
      );
      expect(
        (await mealRef.get(const GetOptions(source: Source.server))).data(),
        historical,
      );
      await favorites.setFavorite(
        alice,
        food.id,
        false,
        sourceKind: FoodSourceKind.custom,
      );
      await favorites.setFavorite(
        alice,
        recipe.id,
        false,
        sourceKind: FoodSourceKind.recipe,
      );
      await expectLater(
        library.save(alice, food, create: false),
        throwsA(isA<FoodLibraryFailure>()),
        reason: 'editing a deleted source must not silently recreate it',
      );
      await library.save(alice, food, create: true);
      await library.save(alice, recipe, create: true);
      await favorites.setFavorite(
        alice,
        food.id,
        true,
        sourceKind: FoodSourceKind.custom,
      );
      await authentication.signIn(email: bobEmail, password: password);
      await library.save(bob, food, create: true);
      await library.save(bob, recipe, create: true);
      await favorites.setFavorite(
        bob,
        recipe.id,
        true,
        sourceKind: FoodSourceKind.recipe,
      );
      for (final kind in [FoodSourceKind.custom, FoodSourceKind.recipe]) {
        final id = kind == FoodSourceKind.custom ? food.id : recipe.id;
        await expectLater(
          library.load(alice, kind, id),
          throwsA(isA<FoodLibraryFailure>()),
        );
        await expectLater(
          library.save(
            alice,
            kind == FoodSourceKind.custom ? food : recipe,
            create: false,
          ),
          throwsA(isA<FoodLibraryFailure>()),
        );
        await expectLater(
          library.delete(alice, kind, id),
          throwsA(isA<FoodLibraryFailure>()),
        );
      }
      await authentication.signIn(email: aliceEmail, password: password);
    },
  );

  test(
    'C4 offline unconfirmed library writes keep the same ID; retries do not duplicate or overwrite another payload',
    () async {
      final library = FirebaseFoodLibraryRepository(db);
      final food = PersonalFood(
        id: library.newId(),
        name: 'Món retry fixture',
        per100g: const NutritionTotals(
          kcal: 100,
          proteinG: 10,
          carbsG: 10,
          fatG: 2,
        ),
      );
      final recipe = FoodRecipe(
        id: library.newId(),
        name: 'Công thức retry fixture',
        ingredients: [MealItemSnapshot.fromCatalog(food.asFood(), 150)],
        yieldGrams: 120,
        servingsCount: 1.5,
      );
      for (final entry in <LibraryEntry>[food, recipe]) {
        await db.disableNetwork();
        try {
          await expectLater(
            library.load(alice, entry.kind, entry.id),
            throwsA(isA<FoodLibraryFailure>()),
          );
          await expectLater(
            library.save(alice, entry, create: true),
            throwsA(isA<FoodLibraryFailure>()),
          );
        } finally {
          await db.enableNetwork();
        }
        await library.save(alice, entry, create: true);
        await library.save(alice, entry, create: true);
        expect(
          (await library.load(alice, entry.kind, entry.id))!.toData(),
          entry.toData(),
        );
      }
      await expectLater(
        library.save(
          alice,
          PersonalFood(
            id: food.id,
            name: 'Changed draft',
            per100g: food.per100g,
          ),
          create: true,
        ),
        throwsA(isA<FoodLibraryFailure>()),
      );
      expect(
        (await db
                .collection('users/$alice/custom_foods')
                .get(const GetOptions(source: Source.server)))
            .docs,
        hasLength(2),
      );
      expect(
        (await db
                .collection('users/$alice/recipes')
                .get(const GetOptions(source: Source.server)))
            .docs,
        hasLength(2),
      );
      await db.disableNetwork();
      bool completed = false;
      final deletion = library
          .delete(alice, food.kind, food.id)
          .then((_) => completed = true);
      try {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(completed, isFalse);
      } finally {
        await db.enableNetwork();
      }
      await deletion;
      expect(await library.load(alice, food.kind, food.id), isNull);
    },
  );

  test(
    'C2 targets preserve effective history and retry the same ID after an unknown acknowledgement',
    () async {
      final targets = FirebaseNutritionTargetRepository(db);
      final key = localDateKey(day);
      final next = localDateKey(DateTime(day.year, day.month, day.day + 1));
      final later = localDateKey(DateTime(day.year, day.month, day.day + 2));
      final first = NutritionTarget(
        effectiveFromDateKey: key,
        kcalTarget: 1800,
      );
      await targets.save(alice, first);
      final reference = db.doc('users/$alice/nutrition_targets/$key');
      final createdAt = (await reference.get(
        const GetOptions(source: Source.server),
      )).data()!['createdAt'];
      await targets.save(
        alice,
        NutritionTarget(
          effectiveFromDateKey: next,
          kcalTarget: 2000,
          proteinGTarget: 100,
          carbsGTarget: 250,
          fatGTarget: 60,
        ),
      );
      expect(
        await targets.loadForDay(
          alice,
          localDateKey(DateTime(day.year, day.month, day.day - 1)),
        ),
        isNull,
      );
      expect((await targets.loadForDay(alice, key))!.kcalTarget, 1800);
      expect((await targets.loadForDay(alice, next))!.kcalTarget, 2000);
      await targets.save(alice, first);
      expect(
        (await reference.get(
          const GetOptions(source: Source.server),
        )).data()!['createdAt'],
        createdAt,
      );
      expect(
        (await db.collection('users/$alice/nutrition_targets').get()).size,
        2,
      );
      await expectLater(
        targets.save(
          alice,
          NutritionTarget(
            effectiveFromDateKey: localDateKey(
              DateTime(day.year, day.month, day.day - 1),
            ),
            kcalTarget: 1800,
          ),
        ),
        throwsA(isA<NutritionTargetFailure>()),
        reason: 'C2 rejects writes to a past effective date',
      );
      await db.disableNetwork();
      try {
        await expectLater(
          targets.loadForDay(alice, key),
          throwsA(isA<NutritionTargetFailure>()),
          reason: 'C2 offline reads must fail instead of returning no target',
        );
        await expectLater(
          targets.save(
            alice,
            NutritionTarget(effectiveFromDateKey: later, kcalTarget: 1900),
          ),
          throwsA(isA<NutritionTargetFailure>()),
          reason: 'C2 offline transaction must not acknowledge a write',
        );
      } finally {
        await db.enableNetwork();
      }
      expect(
        (await db
                .doc('users/$alice/nutrition_targets/$later')
                .get(const GetOptions(source: Source.server)))
            .exists,
        isTrue,
        reason:
            'Web emulator transaction reached server while normal reads were disabled; failure is an unconfirmed acknowledgement, not rollback.',
      );
      await targets.save(
        alice,
        NutritionTarget(effectiveFromDateKey: later, kcalTarget: 1900),
      );
      await targets.save(
        alice,
        NutritionTarget(effectiveFromDateKey: later, kcalTarget: 1900),
      );
      expect(
        (await db.collection('users/$alice/nutrition_targets').get()).size,
        3,
      );
      expect((await targets.loadForDay(alice, later))!.kcalTarget, 1900);
    },
  );

  test(
    'C5 real repositories save weights and aggregate a sparse week across New Year',
    () async {
      final start = DateTime(2025, 12, 29), end = DateTime(2026, 1, 5);
      for (final entry in [(start, 150.0), (DateTime(2026, 1, 1), 450.0)]) {
        await nutrition.addMeal(
          uid: alice,
          draft: MealDraft(
            type: MealType.lunch,
            source: MealSource.manual,
            consumedAt: entry.$1,
            items: [
              MealItemSnapshot(
                foodId: 'c5-emulator-fixture',
                name: 'Món kiểm thử emulator',
                grams: 100,
                nutrition: NutritionTotals(
                  kcal: entry.$2,
                  proteinG: entry.$2 / 15,
                  carbsG: entry.$2 / 7.5,
                  fatG: entry.$2 / 50,
                ),
                sourceLabel: 'Synthetic emulator fixture',
                isEstimated: true,
              ),
            ],
          ),
        );
      }
      await water.add(
        uid: alice,
        draft: WaterLogDraft(amountMl: 250, consumedAt: DateTime(2025, 12, 31)),
      );
      await activities.add(
        uid: alice,
        draft: ActivityLogDraft(
          type: ActivityType.walking,
          durationMinutes: 20,
          performedAt: DateTime(2026, 1, 1),
        ),
      );
      for (final entry in [
        (DateTime(2025, 12, 28), 80.0),
        (DateTime(2026, 1, 2), 69.5),
        (start, 70.0),
      ]) {
        await profiles.addBodyMetric(
          uid: alice,
          draft: BodyMetricDraft(
            weightKg: entry.$2,
            measuredAt: entry.$1,
            note: 'Synthetic emulator fixture',
          ),
        );
      }
      final range = await (
        nutrition.loadRange(alice, start, end),
        water.loadRange(alice, start, end),
        activities.loadRange(alice, start, end),
        profiles.loadBodyMetricsRange(alice, start, end),
      ).wait;
      final report = summarizeWeek(
        start,
        DateTime(2026, 1, 2),
        WeekLogs(
          meals: range.$1,
          water: range.$2,
          activities: range.$3,
          metrics: range.$4,
          loadedAt: DateTime.now(),
        ),
      );
      expect(report.nutrition.kcal, 600);
      expect(report.nutrition.proteinG, 40);
      expect(report.nutrition.carbsG, 80);
      expect(report.nutrition.fatG, 12);
      expect(report.waterMl, 250);
      expect(report.activityMinutes, 20);
      expect(report.mealDays, 2);
      expect(report.averageKcalPerRecordedDay, 300);
      expect(report.eligibleDays, 5);
      expect(report.metrics.map((m) => m.weightKg), [70, 69.5]);
      expect(report.metrics.map((m) => localDateKey(m.measuredAt)), [
        '2025-12-29',
        '2026-01-02',
      ]);
      expect(report.weightChange, -.5);
      await authentication.signOut();
      try {
        await authentication.signIn(email: bobEmail, password: password);
        await expectLater(
          profiles.loadBodyMetricsRange(alice, start, end),
          throwsA(anything),
        );
      } finally {
        await authentication.signOut();
        await authentication.signIn(email: aliceEmail, password: password);
      }
    },
  );

  test(
    'C5 bounded weekly targets carry history, reject cross-UID/offline and keep past versions',
    () async {
      final targets = FirebaseNutritionTargetRepository(db);
      String keyAt(int offset) =>
          localDateKey(DateTime(day.year, day.month, day.day + offset));
      // Future dates avoid writing any past target; only demo emulator data.
      final begin = keyAt(14), end = keyAt(21);
      await targets.save(
        alice,
        NutritionTarget(effectiveFromDateKey: keyAt(12), kcalTarget: 1750),
      );
      await targets.save(
        alice,
        NutritionTarget(
          effectiveFromDateKey: keyAt(16),
          kcalTarget: 1950,
          proteinGTarget: 90,
          carbsGTarget: 220,
          fatGTarget: 55,
        ),
      );
      await targets.save(
        alice,
        NutritionTarget(effectiveFromDateKey: end, kcalTarget: 2500),
      );
      final versions = await targets.loadForRange(alice, begin, end);
      expect(versions.map((t) => t.effectiveFromDateKey), [
        keyAt(12),
        keyAt(16),
      ]);
      expect(targetForDate(versions, begin)!.kcalTarget, 1750);
      expect(targetForDate(versions, keyAt(15))!.kcalTarget, 1750);
      expect(targetForDate(versions, keyAt(16))!.proteinGTarget, 90);
      await targets.save(
        alice,
        NutritionTarget(effectiveFromDateKey: keyAt(16), kcalTarget: 2050),
      );
      final changed = await targets.loadForRange(alice, begin, end);
      expect(targetForDate(changed, keyAt(15))!.kcalTarget, 1750);
      expect(targetForDate(changed, keyAt(16))!.kcalTarget, 2050);
      final beforeFirst = await targets.loadForRange(
        alice,
        keyAt(-14),
        keyAt(-7),
      );
      expect(beforeFirst, isEmpty);
      await expectLater(
        targets.loadForRange(alice, begin, keyAt(105)),
        throwsA(isA<NutritionTargetFailure>()),
      );
      await expectLater(
        targets.loadForRange(alice, end, begin),
        throwsA(isA<NutritionTargetFailure>()),
      );
      await expectLater(
        targets.loadForRange(alice, '2026-02-30', end),
        throwsA(isA<NutritionTargetFailure>()),
      );
      await db.disableNetwork();
      try {
        await expectLater(
          targets.loadForRange(alice, begin, end),
          throwsA(isA<NutritionTargetFailure>()),
        );
      } finally {
        await db.enableNetwork();
      }
      await authentication.signOut();
      try {
        await authentication.signIn(email: bobEmail, password: password);
        await expectLater(
          targets.loadForRange(alice, begin, end),
          throwsA(isA<NutritionTargetFailure>()),
        );
        expect(await targets.loadForRange(bob, begin, end), isEmpty);
      } finally {
        await authentication.signOut();
        await authentication.signIn(email: aliceEmail, password: password);
      }
      // Reader rejects malformed target versions; never substitutes zeros.
      final bad = db.doc('users/$alice/nutrition_targets/${keyAt(20)}');
      final response = await http.patch(
        Uri.parse(
          'http://127.0.0.1:8080/v1/projects/$projectId/databases/(default)/documents/${bad.path}',
        ),
        headers: {
          'Authorization': 'Bearer owner',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fields': {
            'effectiveFromDateKey': {'stringValue': keyAt(20)},
            'kcalTarget': {'doubleValue': 999},
          },
        }),
      );
      expect(response.statusCode, 200);
      await expectLater(
        targets.loadForRange(alice, begin, end),
        throwsA(isA<NutritionTargetFailure>()),
      );
      // This deliberately malformed emulator document belongs only to this
      // reader-error fixture; do not contaminate later report/cleanup tests.
      await bad.delete();
    },
  );

  test(
    'C6 Auth SDK rejects an unexpected UID before reauth, password update or deletion',
    () async {
      expect(auth.currentUser!.uid, alice);
      for (final operation in [
        () => authentication.reauthenticateWithPassword(
          password,
          expectedUid: bob,
        ),
        () => authentication.updatePassword(
          'Never-applied-C6-password-123!',
          expectedUid: bob,
        ),
        () => authentication.deleteCurrentUser(expectedUid: bob),
      ]) {
        await expectLater(
          operation(),
          throwsA(
            isA<AuthFailure>().having((e) => e.code, 'code', 'user-mismatch'),
          ),
        );
        expect(auth.currentUser!.uid, alice);
      }
      await authentication.reauthenticateWithPassword(
        password,
        expectedUid: alice,
      );
    },
  );

  test(
    'H3 real SDK stores calorie-only, zero, volume and partial template snapshots without fake grams',
    () async {
      const energy = MealItemSnapshot(
        foodId: 'h3-energy',
        name: 'QA H3 kcal',
        grams: 0,
        quantityUnit: 'entry',
        quantityValue: 1,
        nutrition: NutritionTotals(
          kcal: 250,
          proteinKnown: false,
          carbsKnown: false,
          fatKnown: false,
        ),
        sourceLabel: 'QA H3 synthetic',
        isEstimated: true,
      );
      const volume = MealItemSnapshot(
        foodId: 'h3-volume',
        name: 'QA H3 ml',
        grams: 0,
        quantityUnit: 'ml',
        quantityValue: 250,
        nutrition: NutritionTotals(
          kcal: 150,
          proteinG: 7.5,
          carbsG: 0,
          fatKnown: false,
        ),
        sourceLabel: 'QA H3 synthetic /100 ml',
        isEstimated: true,
      );
      final id = nutrition.newMealId();
      final draft = MealDraft(
        type: MealType.snack,
        consumedAt: DateTime.now(),
        items: [energy, volume],
        source: MealSource.manual,
      );
      await nutrition.addMeal(uid: alice, draft: draft, operationId: id);
      await nutrition.addMeal(uid: alice, draft: draft, operationId: id);
      final raw =
          (await db
                  .doc('users/$alice/meal_logs/$id')
                  .get(const GetOptions(source: Source.server)))
              .data()!;
      expect(raw['schemaVersion'], 3);
      expect(raw['totalProteinG'], isNull);
      expect((raw['items'] as List).last['grams'], isNull);
      expect((raw['items'] as List).last['quantity'], 250);
      var read = (await nutrition.loadRange(
        alice,
        day,
        DateTime(day.year, day.month, day.day + 1),
      )).singleWhere((m) => m.id == id);
      expect(read.totals.kcal, 400);
      expect(read.totals.proteinG, 7.5);
      expect(read.totals.proteinKnown, isFalse);
      expect(read.items.last.nutrition.carbsKnown, isTrue);
      expect(read.items.last.nutrition.carbsG, 0);
      expect(read.items.first.nutrition.carbsKnown, isFalse);
      final copy = read.copyDraft(
        day: DateTime(day.year, day.month, day.day - 1),
      );
      final copyId = await nutrition.addMeal(
        uid: alice,
        draft: copy,
        operationId: nutrition.newMealId(),
      );
      final copied = (await nutrition.loadRange(
        alice,
        DateTime(day.year, day.month, day.day - 1),
        day,
      )).singleWhere((m) => m.id == copyId);
      expect(copied.items.last.toData(), read.items.last.toData());
      final templates = FirebaseMealTemplateRepository(db);
      final t = MealTemplate(
        id: 'h3-template',
        name: 'QA partial template',
        items: read.items,
      );
      await templates.save(alice, t, create: true);
      expect(
        (await templates.watch(alice).first)
            .singleWhere((v) => v.id == t.id)
            .items
            .first
            .nutrition
            .hasCompleteMacros,
        isFalse,
      );
      await templates.delete(alice, t.id);
      await nutrition.deleteMeal(uid: alice, mealId: id);
      await nutrition.deleteMeal(uid: alice, mealId: copyId);
    },
  );

  test(
    'H2 named templates, frozen snapshots, offline retry and owner isolation',
    () async {
      final templates = FirebaseMealTemplateRepository(db);
      final item = MealItemSnapshot(
        foodId: 'h2-fixture',
        name: 'QA H2 rice',
        grams: 150,
        nutrition: const NutritionTotals(
          kcal: 195,
          proteinG: 4,
          carbsG: 42,
          fatG: .4,
        ),
        sourceLabel: 'Synthetic emulator snapshot',
        isEstimated: true,
      );
      final t = MealTemplate(
        id: 'h2-template',
        name: 'QA H2 two foods',
        items: [item, item.withGrams(100)],
      );
      await templates.save(alice, t, create: true);
      await templates.save(alice, t, create: true);
      var rows = await templates.watch(alice).first;
      expect(rows.length, 1);
      expect(rows.single.items.length, 2);
      final id = nutrition.newMealId();
      await nutrition.addMeal(
        uid: alice,
        draft: MealDraft(
          type: MealType.lunch,
          consumedAt: DateTime.now(),
          items: rows.single.items,
          source: MealSource.manual,
        ),
        operationId: id,
      );
      await templates.save(
        alice,
        MealTemplate(
          id: t.id,
          name: 'QA changed',
          items: [item.withGrams(200)],
        ),
        create: false,
      );
      await templates.delete(alice, t.id);
      final logged = (await nutrition.loadRange(
        alice,
        day,
        DateTime(day.year, day.month, day.day + 1),
      )).singleWhere((m) => m.id == id);
      expect(logged.items.length, 2);
      expect(logged.totals.kcal, 325);
      await db.disableNetwork();
      try {
        await expectLater(
          templates.save(alice, t, create: true),
          throwsA(isA<MealTemplateFailure>()),
        );
      } finally {
        await db.enableNetwork();
      }
      await templates.save(alice, t, create: true);
      await templates.save(alice, t, create: true);
      expect((await templates.watch(alice).first).length, 1);
      await authentication.signOut();
      await authentication.signIn(email: bobEmail, password: password);
      await expectLater(
        templates.watch(alice).first,
        throwsA(isA<MealTemplateFailure>()),
      );
      await expectLater(
        templates.save(alice, t, create: true),
        throwsA(isA<MealTemplateFailure>()),
      );
      await templates.save(bob, t, create: true);
      await authentication.signOut();
      await authentication.signIn(email: aliceEmail, password: password);
    },
  );

  test(
    'H6 sourced fiber survives library changes, partial recipes, retry and UID isolation',
    () async {
      final library = FirebaseFoodLibraryRepository(db);
      final templates = FirebaseMealTemplateRepository(db);
      final food = PersonalFood(
        id: 'h6-fiber',
        name: 'QA fiber',
        per100g: const NutritionTotals(
          kcal: 100,
          fiberG: 2.4,
          fiberKnown: true,
        ),
      );
      await library.save(alice, food, create: true);
      final known = MealItemSnapshot.fromCatalog(food.asFood(), 100);
      final unknown = MealItemSnapshot(
        foodId: 'qa-unknown',
        name: 'QA unknown',
        grams: 100,
        nutrition: const NutritionTotals(kcal: 100),
        sourceLabel: 'Synthetic QA',
        isEstimated: true,
      );
      final recipe = FoodRecipe(
        id: 'h6-recipe',
        name: 'QA mixed fiber',
        ingredients: [known, unknown],
        yieldGrams: 400,
      );
      await library.save(alice, recipe, create: true);
      final template = MealTemplate(
        id: 'h6-template',
        name: 'QA fiber template',
        items: [MealItemSnapshot.fromCatalog(recipe.asFood(), 150)],
      );
      await templates.save(alice, template, create: true);
      final id = nutrition.newMealId();
      final draft = MealDraft(
        type: MealType.snack,
        consumedAt: DateTime.now(),
        items: template.items,
        source: MealSource.manual,
      );
      await nutrition.addMeal(uid: alice, draft: draft, operationId: id);
      await nutrition.addMeal(uid: alice, draft: draft, operationId: id);
      final raw = await db
          .doc('users/$alice/meal_logs/$id')
          .get(const GetOptions(source: Source.server));
      expect(raw.data()!['schemaVersion'], 4);
      expect(
        (raw.data()!['items'] as List).single['fiberG'],
        closeTo(.9, 1e-9),
      );
      await library.delete(alice, FoodSourceKind.custom, food.id);
      await library.delete(alice, FoodSourceKind.recipe, recipe.id);
      await templates.delete(alice, template.id);
      final rows = await nutrition.loadRange(
        alice,
        day,
        DateTime(day.year, day.month, day.day + 1),
      );
      expect(rows.where((m) => m.id == id).length, 1);
      final logged = rows.singleWhere((m) => m.id == id);
      expect(logged.totals.fiberG, closeTo(.9, 1e-9));
      expect(logged.totals.fiberKnown, false);
      await nutrition.updateMeal(
        uid: alice,
        mealId: id,
        draft: MealDraft(
          type: logged.type,
          consumedAt: logged.consumedAt,
          items: [unknown],
          source: logged.source,
          minimumSchemaVersion: logged.schemaVersion,
        ),
      );
      expect(
        (await db.doc('users/$alice/meal_logs/$id').get())
            .data()!['schemaVersion'],
        4,
      );
      await authentication.signOut();
      await authentication.signIn(email: bobEmail, password: password);
      await expectLater(
        db
            .doc('users/$alice/meal_logs/$id')
            .get(const GetOptions(source: Source.server)),
        throwsA(isA<FirebaseException>()),
      );
      await authentication.signOut();
      await authentication.signIn(email: aliceEmail, password: password);
      await nutrition.deleteMeal(uid: alice, mealId: id);
    },
  );

  test(
    'H5 90-day SDK reporting, confirmation revisions, owner isolation and bounded overflow',
    () async {
      final reviews = FirebaseDayReviewRepository(db);
      final end = DateTime(day.year, day.month, day.day + 1),
          range = ReportRange(DateTime(day.year, day.month, day.day + 1), 90);
      var meals = await nutrition.loadRange(alice, day, end);
      await reviews.save(alice, day, meals, complete: true);
      var saved = (await reviews.load(
        alice,
        range,
      )).singleWhere((r) => r.dateKey == localDateKey(day));
      expect(saved.matches(meals), isTrue);
      final editable = meals.firstWhere(
        (m) => m.items.isNotEmpty && m.items.every((i) => i.hasNutritionData),
      );
      await nutrition.updateMeal(
        uid: alice,
        mealId: editable.id,
        draft: editable.toDraft(),
      );
      meals = await nutrition.loadRange(alice, day, end);
      expect(saved.matches(meals), isFalse);
      await reviews.save(alice, day, meals, complete: true);
      saved = (await reviews.load(
        alice,
        range,
      )).singleWhere((r) => r.dateKey == localDateKey(day));
      expect(saved.matches(meals), isTrue);
      final targets = FirebaseNutritionTargetRepository(db);
      final future = DateTime(day.year, day.month, day.day + 14);
      final targetVersions = await targets.loadForRange(
        alice,
        localDateKey(future),
        localDateKey(DateTime(future.year, future.month, future.day + 90)),
      );
      expect(
        targetForDate(targetVersions, localDateKey(future))!.kcalTarget,
        1750,
      );
      expect(
        targetForDate(
          targetVersions,
          localDateKey(DateTime(future.year, future.month, future.day + 2)),
        )!.kcalTarget,
        2050,
      );
      await expectLater(
        nutrition.loadRange(
          alice,
          DateTime(day.year, day.month, day.day - 91),
          day,
        ),
        throwsA(anything),
      );
      await authentication.signOut();
      await authentication.signIn(email: bobEmail, password: password);
      await expectLater(reviews.load(alice, range), throwsA(anything));
      await expectLater(
        reviews.save(alice, day, [], complete: true),
        throwsA(anything),
      );
      await reviews.save(bob, day, [], complete: false);
      await authentication.signOut();
      await authentication.signIn(email: aliceEmail, password: password);
      // Prove that a bounded server read reports overflow rather than a false total.
      final old = DateTime(day.year, day.month, day.day - 60),
          oldEnd = DateTime(day.year, day.month, day.day - 59);
      final references = [
        for (var i = 0; i < 2001; i++)
          db.doc('users/$alice/water_logs/h5-bound-$i'),
      ];
      try {
        for (var offset = 0; offset < references.length; offset += 400) {
          final batch = db.batch();
          for (final ref in references.skip(offset).take(400)) {
            batch.set(ref, {
              'amountMl': 50,
              'consumedAt': Timestamp.fromDate(old),
              'dateKey': localDateKey(old),
              'timezoneOffsetMinutes': old.timeZoneOffset.inMinutes,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          await batch.commit();
        }
        await expectLater(
          water.loadRange(alice, old, oldEnd),
          throwsA(anything),
        );
      } finally {
        for (var offset = 0; offset < references.length; offset += 400) {
          final batch = db.batch();
          for (final ref in references.skip(offset).take(400)) {
            batch.delete(ref);
          }
          await batch.commit();
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'wellness sleep timer persists, finishes idempotently and isolates UID',
    () async {
      await authentication.signIn(email: aliceEmail, password: password);
      final repo = WellnessRepository(db);
      await repo.startSleep(alice);
      final start = (await repo.watchSleepStart(alice).first)!;
      await expectLater(repo.startSleep(alice), throwsFormatException);
      final began = start.subtract(const Duration(hours: 8)),
          end = DateTime.now();
      await repo.saveSleep(
        alice,
        began,
        end,
        finishTimer: true,
        expectedTimerStart: start,
      );
      await repo.saveSleep(
        alice,
        began,
        end,
        finishTimer: true,
        expectedTimerStart: start,
      );
      expect(
        (await db
                .doc('users/$alice/wellness_state/sleep')
                .get(const GetOptions(source: Source.server)))
            .exists,
        false,
      );
      expect(
        await repo.watchSleepStart(alice).firstWhere((value) => value == null),
        isNull,
      );
      final history = await repo.watchSleepLogs(alice).first;
      expect(history, hasLength(1));
      expect(history.single.start, began);
      await repo.saveSleep(
        alice,
        began.add(const Duration(minutes: 15)),
        end,
        id: history.single.id,
      );
      await authentication.signIn(email: bobEmail, password: password);
      await expectLater(
        repo.watchSleepLogs(alice).first,
        throwsA(isA<FirebaseException>()),
      );
      await authentication.signIn(email: aliceEmail, password: password);
    },
  );

  test(
    'wellness plan remains separate until confirmation and preserves v5 nutrition snapshot',
    () async {
      await authentication.signIn(email: aliceEmail, password: password);
      final repo = WellnessRepository(db), now = DateTime.now();
      final future = DateTime(now.year, now.month, now.day + 2, 12);
      const food = FoodCatalogItem(
        id: 'wellness-fixture',
        name: 'Wellness fixture',
        category: 'Fixture',
        servingBasis: ServingBasis.per100g,
        sourceLabel: 'Synthetic',
        isEstimated: true,
        per100g: NutritionTotals(
          kcal: 120,
          proteinG: 6,
          carbsG: 15,
          fatG: 4,
          fiberKnown: true,
          extraNutrients: {'sodium': 120, 'sugar': 0},
        ),
      );
      final items = List.filled(5, MealItemSnapshot.fromCatalog(food, 100));
      final planned = MealDraft(
        type: MealType.lunch,
        consumedAt: future,
        items: items,
        source: MealSource.manual,
      );
      await repo.savePlan(alice, planned);
      await repo.savePlan(alice, planned);
      final plans = await repo.watchPlans(alice, localDateOnly(future)).first;
      expect(plans, hasLength(1));
      expect(plans.single.items.last.nutrition.extraNutrients['sodium'], 120);
      expect(
        await nutrition.loadRange(
          alice,
          localDateOnly(future),
          DateTime(future.year, future.month, future.day + 1),
        ),
        isEmpty,
      );
      final actual = MealDraft(
        type: MealType.lunch,
        consumedAt: now,
        items: items,
        source: MealSource.manual,
      );
      await repo.savePlan(alice, actual);
      final id = '${actual.dateKey}-lunch';
      expect(await repo.existingPlanMeal(alice, id), false);
      final confirmation = (await repo.loadPlan(alice, id))!;
      await repo.recordPlanMeal(alice, confirmation, actual);
      await repo.recordPlanMeal(alice, confirmation, actual);
      final meals = await nutrition.loadRange(
        alice,
        localDateOnly(now),
        DateTime(now.year, now.month, now.day + 1),
      );
      final saved = meals.singleWhere((m) => m.id == 'plan-$id');
      expect(saved.schemaVersion, 5);
      expect(saved.items, hasLength(5));
      expect(saved.totals.extraNutrients['sodium'], 600);
      expect(saved.totals.extraNutrients['sugar'], 0);
      await expectLater(repo.savePlan(alice, actual), throwsFormatException);
      await repo.deletePlan(alice, id);
      expect(await repo.existingPlanMeal(alice, id), true);
    },
  );

  test(
    'wellness step synchronization never lowers an existing day and denies other UID',
    () async {
      await authentication.signIn(email: aliceEmail, password: password);
      final repo = WellnessRepository(db), now = DateTime.now();
      final data = <String, dynamic>{
        'day': localDateKey(now),
        'steps': 120,
        'startedAt': now
            .subtract(const Duration(minutes: 5))
            .millisecondsSinceEpoch,
        'measuredAt': now.millisecondsSinceEpoch,
        'timezoneOffsetMinutes': now.timeZoneOffset.inMinutes,
      };
      await repo.syncSteps(alice, data);
      await repo.syncSteps(alice, {...data, 'steps': 10});
      expect((await repo.watchStepDays(alice).first).single.steps, 120);
      await authentication.signIn(email: bobEmail, password: password);
      await expectLater(
        repo.watchStepDays(alice).first,
        throwsA(isA<FirebaseException>()),
      );
      await authentication.signIn(email: aliceEmail, password: password);
    },
  );

  test(
    'wellness preferences and confirmed step budget persist and isolate cached UID',
    () async {
      await authentication.signIn(email: aliceEmail, password: password);
      final repo = FirebaseEnergyRepository(db), now = DateTime.now();
      await repo.savePreferences(
        alice,
        const WellnessPreferences(
          stepLengthCm: 75,
          baselineSteps: 4000,
          sleepGoalMinutes: 480,
        ),
      );
      expect((await repo.watchPreferences(alice).first).sleepGoalMinutes, 480);
      final targets = FirebaseNutritionTargetRepository(db);
      await targets.save(
        alice,
        NutritionTarget(
          effectiveFromDateKey: localDateKey(now),
          kcalTarget: 1800,
        ),
      );
      final adjustment = EnergyAdjustment(
        dateKey: localDateKey(now),
        timezoneOffsetMinutes: now.timeZoneOffset.inMinutes,
        steps: 6000,
        baselineSteps: 4000,
        stepLengthCm: 75,
        weightKg: 70,
        weightMeasuredAt: now.subtract(const Duration(days: 1)),
        targetFromDateKey: localDateKey(now),
        baseKcalTarget: 1800,
        kcal: 50,
      );
      await repo.saveAdjustment(alice, adjustment);
      final loaded = (await repo
          .watchAdjustment(alice, localDateKey(now))
          .first)!;
      expect(loaded.kcal, 50);
      expect(
        (await repo.loadAdjustments(
          alice,
          localDateOnly(now),
          DateTime(now.year, now.month, now.day + 1),
        )).single.kcal,
        50,
      );
      expect(
        (await targets.loadForDay(alice, localDateKey(now)))!.kcalTarget,
        1800,
      );
      await authentication.signIn(email: bobEmail, password: password);
      await expectLater(
        repo.watchPreferences(alice).first,
        throwsA(isA<FirebaseException>()),
      );
      await expectLater(
        repo.watchAdjustment(alice, localDateKey(now)).first,
        throwsA(isA<FirebaseException>()),
      );
      await authentication.signIn(email: aliceEmail, password: password);
      await repo.clearAdjustment(alice, localDateKey(now));
      expect(
        (await db
                .doc('users/$alice/energy_adjustments/${localDateKey(now)}')
                .get(const GetOptions(source: Source.server)))
            .exists,
        false,
      );
      await repo.saveAdjustment(
        alice,
        adjustment,
      ); // Account cleanup must remove this.
      final sleepRepo = WellnessRepository(db);
      await sleepRepo.saveSleep(
        alice,
        now.subtract(const Duration(hours: 9)),
        now.subtract(const Duration(hours: 1)),
        id: 'insight-range',
      );
      expect(
        (await sleepRepo.loadSleepRange(
          alice,
          now.subtract(const Duration(days: 30)),
          now,
        )).any((s) => s.id == 'insight-range'),
        true,
      );
    },
  );
  test(
    'profile identity saves real thumbnails, preserves health fields and enforces UID privacy',
    () async {
      await authentication.signIn(email: aliceEmail, password: password);
      await profiles.ensureProfile(uid: alice, email: aliceEmail);
      await profiles.updateProfile(
        uid: alice,
        displayName: 'Hồ sơ kiểm thử SDK',
        heightCm: 175,
        birthDate: DateTime(1998, 1, 1),
        healthGoal: 'maintain_weight',
        targetWeightKg: null,
      );
      final reference = db.doc('users/$alice');
      final before = (await reference.get(
        const GetOptions(source: Source.server),
      )).data()!;
      final photo = ProfileImage.tryDecode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6VSEAAAAASUVORK5CYII=',
      )!;
      final appearance = ProfileAppearance(
        avatar: photo,
        cover: photo,
        background: photo,
      );
      final liveUpdate = profiles
          .watchProfile(alice)
          .firstWhere(
            (profile) =>
                profile?.displayName == 'Nguyễn An' &&
                profile?.appearance.cover != null,
          );
      await profiles.updateIdentity(
        uid: alice,
        draft: ProfileIdentityDraft(
          displayName: '  Nguyễn An  ',
          appearance: appearance,
        ),
      );
      final live = await liveUpdate.timeout(const Duration(seconds: 10));
      expect(live!.appearance.sameAs(appearance), isTrue);
      final saved = (await reference.get(
        const GetOptions(source: Source.server),
      )).data()!;
      expect(saved['displayName'], 'Nguyễn An');
      expect(saved['profileAppearance'], appearance.toMap());
      for (final field in [
        'email',
        'heightCm',
        'birthDate',
        'healthGoal',
        'targetWeightKg',
        'onboardingCompletedAt',
        'createdAt',
        'schemaVersion',
      ]) {
        expect(
          saved[field],
          before[field],
          reason: 'Identity preserves $field',
        );
      }
      expect(saved['updatedAt'], isA<Timestamp>());
      await profiles.updateProfile(
        uid: alice,
        displayName: 'Nguyễn An',
        heightCm: 176,
        birthDate: DateTime(1998, 1, 1),
        healthGoal: 'maintain_weight',
        targetWeightKg: null,
      );
      expect(
        (await profiles.watchProfile(alice).first)!.appearance.sameAs(
          appearance,
        ),
        isTrue,
      );
      final withoutCover = appearance.replace(ProfileImageSlot.cover, null);
      await profiles.updateIdentity(
        uid: alice,
        draft: ProfileIdentityDraft(
          displayName: 'Nguyễn An',
          appearance: withoutCover,
        ),
      );
      await authentication.signOut();
      await authentication.signIn(email: aliceEmail, password: password);
      expect(
        (await profiles.watchProfile(alice).first)!.appearance.sameAs(
          withoutCover,
        ),
        isTrue,
      );

      await authentication.register(
        email: 'identity-other-$suffix@example.com',
        password: password,
      );
      await verifyEmulatorEmail(auth, projectId: projectId, host: '127.0.0.1');
      await expectLater(
        reference.get(const GetOptions(source: Source.server)),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      await expectLater(
        profiles.updateIdentity(
          uid: alice,
          draft: ProfileIdentityDraft(
            displayName: 'Không được sửa',
            appearance: const ProfileAppearance(),
          ),
        ),
        throwsA(isA<ProfileFailure>()),
      );
      await authentication.deleteCurrentUser();
      await authentication.signIn(email: aliceEmail, password: password);
      expect(
        (await profiles.watchProfile(alice).first)!.appearance.sameAs(
          withoutCover,
        ),
        isTrue,
      );
      await profiles.updateIdentity(
        uid: alice,
        draft: const ProfileIdentityDraft(
          displayName: 'Hồ sơ kiểm thử SDK',
          appearance: ProfileAppearance(),
        ),
      );
      expect(
        (await reference.get(
          const GetOptions(source: Source.server),
        )).data()!['profileAppearance'],
        const ProfileAppearance().toMap(),
      );
    },
  );
  test(
    'reauthenticated password change and account cleanup remove data before Auth',
    () async {
      await authentication.reauthenticateWithPassword(password);
      await authentication.updatePassword('Changed-emulator-only-123!');
      await FirebaseAccountDataRepository(db).deleteAllUserData(alice);
      expect(auth.currentUser!.uid, alice);
      expect(
        (await db
                .doc('users/$alice')
                .get(const GetOptions(source: Source.server)))
            .exists,
        isFalse,
      );
      for (final name in [
        'body_metrics',
        'meal_logs',
        'water_logs',
        'activity_logs',
        'goals',
        'daily_quests',
        'nutrition_targets',
        'favorite_foods',
        'custom_foods',
        'recipes',
        'meal_templates',
        'day_reviews',
        'sleep_logs',
        'wellness_state',
        'step_logs',
        'energy_adjustments',
        'wellness_preferences',
        'meal_plans',
        'chat_sessions',
      ]) {
        expect(
          (await db
                  .collection('users/$alice/$name')
                  .get(const GetOptions(source: Source.server)))
              .docs,
          isEmpty,
        );
      }
      for (final suffix in ['u', 'a']) {
        expect(
          (await db
                  .doc(
                    'users/$alice/chat_sessions/$chatSessionId/messages/${chatTurnId}_$suffix',
                  )
                  .get(const GetOptions(source: Source.server)))
              .exists,
          isFalse,
        );
      }
      await authentication.deleteCurrentUser();
      expect(auth.currentUser, isNull);
      await authentication.signIn(email: bobEmail, password: password);
      expect(
        (await db
                .doc('users/$bob/custom_foods/c4-personal')
                .get(const GetOptions(source: Source.server)))
            .exists,
        isTrue,
      );
      expect(
        (await db
                .doc('users/$bob/recipes/c4-recipe')
                .get(const GetOptions(source: Source.server)))
            .exists,
        isTrue,
      );
      expect(
        (await db
                .doc('users/$bob/favorite_foods/recipe_c4-recipe')
                .get(const GetOptions(source: Source.server)))
            .exists,
        isTrue,
      );
      expect(
        (await db
                .doc('users/$bob/favorite_foods/catalog_c3-rice')
                .get(const GetOptions(source: Source.server)))
            .exists,
        isTrue,
      );
      expect(
        (await db
                .doc('users/$bob/meal_templates/h2-template')
                .get(const GetOptions(source: Source.server)))
            .exists,
        isTrue,
      );
      await authentication.signOut();
    },
  );
}
