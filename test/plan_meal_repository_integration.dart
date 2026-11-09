// Opt-in real Firebase SDK tests, only against local demo emulators.
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:http/http.dart' as http;
import 'package:healthmate/features/auth/data/firebase_account_data_repository.dart';
import 'package:healthmate/features/nutrition/data/firebase_nutrition_repository.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/wellness/data/wellness_repository.dart';
import 'package:healthmate/features/wellness/models/wellness_models.dart';
import 'support/emulator_email_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const project = 'demo-healthmate-rules';
  if (!const bool.fromEnvironment('HEALTHMATE_EMULATOR_TESTS') ||
      !project.startsWith('demo-')) {
    throw StateError('Requires explicit local demo Auth/Firestore emulators.');
  }
  late FirebaseApp app;
  late FirebaseAuth auth;
  late FirebaseApp secondApp;
  late WellnessRepository secondPlans;
  late FirebaseFirestore db;
  late WellnessRepository plans;
  late FirebaseNutritionRepository nutrition;
  late String uid;
  final day = DateTime.now().subtract(const Duration(days: 1));
  MealDraft draft({double grams = 100}) => MealDraft(
    type: MealType.breakfast,
    consumedAt: DateTime(day.year, day.month, day.day, 8),
    source: MealSource.manual,
    items: [
      MealItemSnapshot.fromCatalog(
        const FoodCatalogItem(
          id: 'fixture',
          name: 'Fixture rice',
          category: 'fixture',
          servingBasis: ServingBasis.per100g,
          sourceLabel: 'Synthetic fixture',
          isEstimated: true,
          kcalPer100g: 120,
          proteinGPer100g: 6,
          carbsGPer100g: 15,
          fatGPer100g: 4,
        ),
        grams,
      ),
    ],
  );
  String getId() => '${draft().dateKey}-breakfast';
  DocumentReference<Map<String, dynamic>> planRef() =>
      db.doc('users/$uid/meal_plans/${getId()}');
  DocumentReference<Map<String, dynamic>> mealRef() =>
      db.doc('users/$uid/meal_logs/plan-${getId()}');
  Future<void> record(MealDraft value) async {
    final plan = await plans.loadPlan(uid, getId());
    await plans.recordPlanMeal(uid, plan!, value);
  }

  Future<void> seedDanglingLink({bool linked = true}) async {
    // The owner credential is emulator-only, with a hard-coded loopback/demo URL.
    final response = await http.patch(
      Uri.parse(
        'http://127.0.0.1:8080/v1/projects/$project/databases/(default)/documents/users/$uid/meal_plans/${getId()}?updateMask.fieldPaths=loggedMealId',
      ),
      headers: {
        'Authorization': 'Bearer owner',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fields': {
          if (linked) 'loggedMealId': {'stringValue': 'plan-${getId()}'},
        },
      }),
    );
    expect(response.statusCode, 200);
  }

  setUpAll(() async {
    FirebaseCoreWeb.registerWith(webPluginRegistrar);
    FirebaseAuthWeb.registerWith(webPluginRegistrar);
    FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
    webPluginRegistrar.registerMessageHandler();
    app = await Firebase.initializeApp(
      name: 'plan-meal-sdk',
      options: const FirebaseOptions(
        apiKey: 'emulator-only-fake-key',
        appId: '1:1234567890:web:planmeal',
        messagingSenderId: '1234567890',
        projectId: project,
        authDomain: 'localhost',
      ),
    );
    auth = FirebaseAuth.instanceFor(app: app);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    await auth.setPersistence(Persistence.NONE);
    db = FirebaseFirestore.instanceFor(app: app);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
    final email = 'plan-${DateTime.now().microsecondsSinceEpoch}@example.com';
    await auth.createUserWithEmailAndPassword(
      email: email,
      password: 'Emulator-only-test123!',
    );
    await verifyEmulatorEmail(auth, projectId: project, host: '127.0.0.1');
    uid = auth.currentUser!.uid;
    secondApp = await Firebase.initializeApp(
      name: 'plan-meal-second-device',
      options: app.options,
    );
    final secondAuth = FirebaseAuth.instanceFor(app: secondApp);
    await secondAuth.useAuthEmulator(
      '127.0.0.1',
      9099,
      automaticHostMapping: false,
    );
    await secondAuth.setPersistence(Persistence.NONE);
    await secondAuth.signInWithEmailAndPassword(
      email: email,
      password: 'Emulator-only-test123!',
    );
    final secondDb = FirebaseFirestore.instanceFor(app: secondApp);
    secondDb.useFirestoreEmulator(
      '127.0.0.1',
      8080,
      automaticHostMapping: false,
    );
    secondPlans = WellnessRepository(secondDb);
    plans = WellnessRepository(db);
    nutrition = FirebaseNutritionRepository(db, catalogLoader: () async => []);
  });
  setUp(() async {
    final response = await http.delete(
      Uri.parse(
        'http://127.0.0.1:8080/emulator/v1/projects/$project/databases/(default)/documents',
      ),
    );
    expect(response.statusCode, 200);
  });
  tearDownAll(() async {
    await FirebaseAuth.instanceFor(app: secondApp).signOut();
    await secondApp.delete();
    await auth.signOut();
    await app.delete();
  });

  test(
    'suggestion replay preserves the committed snapshot and timestamps',
    () async {
      expect(await plans.addSuggestedPlan(uid, draft()), true);
      final original = (await planRef().get()).data();
      expect(await plans.addSuggestedPlan(uid, draft(grams: 200)), false);
      expect((await planRef().get()).data(), original);
      expect((await mealRef().get()).exists, false);
    },
  );

  test('suggestion cannot overwrite a plan edited after preview', () async {
    await secondPlans.savePlan(uid, draft(grams: 250));
    final original = (await planRef().get()).data();
    expect(await plans.addSuggestedPlan(uid, draft()), false);
    expect((await planRef().get()).data(), original);
  });

  test('suggestion preserves a journal whose plan was removed', () async {
    await plans.savePlan(uid, draft());
    await record(draft());
    await plans.deletePlan(uid, getId());
    final original = (await mealRef().get()).data();
    expect(await plans.addSuggestedPlan(uid, draft(grams: 200)), false);
    expect((await planRef().get()).exists, false);
    expect((await mealRef().get()).data(), original);
  });

  test(
    'two devices suggest the same slot and retain exactly one winner',
    () async {
      final outcomes = await Future.wait([
        plans.addSuggestedPlan(uid, draft()),
        secondPlans.addSuggestedPlan(uid, draft(grams: 200)),
      ]);
      expect(outcomes.where((created) => created), hasLength(1));
      final saved = await plans.loadPlan(uid, getId());
      expect(saved!.items.single.grams, outcomes.first ? 100 : 200);
      expect(
        (await db.collection('users/$uid/meal_plans').get()).docs,
        hasLength(1),
      );
    },
  );

  test(
    '28 suggestion transactions fit existing Rules and replay without writes',
    () async {
      final drafts = [
        for (var offset = 0; offset < 7; offset++)
          for (final type in MealType.values)
            MealDraft(
              type: type,
              consumedAt: DateTime(day.year, day.month, day.day + offset, 8),
              source: MealSource.manual,
              items: draft().items,
            ),
      ];
      for (final value in drafts) {
        expect(await plans.addSuggestedPlan(uid, value), true);
      }
      final before = (await db.collection('users/$uid/meal_plans').get()).docs;
      for (final value in drafts) {
        expect(await plans.addSuggestedPlan(uid, value), false);
      }
      final after = (await db.collection('users/$uid/meal_plans').get()).docs;
      expect(
        after.map((d) => d.data()).toList(),
        before.map((d) => d.data()).toList(),
      );
      expect(after, hasLength(28));
    },
  );

  test(
    'stale delete refuses a changed plan and a newly recorded link',
    () async {
      await plans.savePlan(uid, draft());
      final original = (await plans.loadPlan(uid, getId()))!;
      await secondPlans.savePlan(uid, draft(grams: 250));
      await expectLater(
        plans.deletePlan(uid, getId(), expected: original),
        throwsFormatException,
      );
      final changed = (await plans.loadPlan(uid, getId()))!;
      await secondPlans.recordPlanMeal(uid, changed, draft(grams: 250));
      await expectLater(
        plans.deletePlan(uid, getId(), expected: changed),
        throwsFormatException,
      );
      expect((await planRef().get()).exists, true);
      expect((await mealRef().get()).data()?['totalKcal'], 300);
    },
  );

  test('confirmed delete keeps journal and supports lost-ACK replay', () async {
    await plans.savePlan(uid, draft());
    await record(draft());
    final confirmation = (await plans.loadPlan(uid, getId()))!;
    final original = (await mealRef().get()).data();
    await plans.deletePlan(uid, getId(), expected: confirmation);
    await plans.deletePlan(uid, getId(), expected: confirmation);
    expect((await planRef().get()).exists, false);
    expect((await mealRef().get()).data(), original);
  });

  test('stale delete cannot remove a newly recreated plan', () async {
    await plans.savePlan(uid, draft());
    final original = (await plans.loadPlan(uid, getId()))!;
    await secondPlans.deletePlan(uid, getId());
    await secondPlans.savePlan(uid, draft());
    await expectLater(
      plans.deletePlan(uid, getId(), expected: original),
      throwsFormatException,
    );
    expect((await planRef().get()).exists, true);
  });

  test('suggestion and guarded delete reject another UID', () async {
    await expectLater(
      plans.addSuggestedPlan('another-uid', draft()),
      throwsA(isA<FirebaseException>()),
    );
    await plans.savePlan(uid, draft());
    final confirmation = (await plans.loadPlan(uid, getId()))!;
    await expectLater(
      plans.deletePlan('another-uid', getId(), expected: confirmation),
      throwsA(isA<FirebaseException>()),
    );
    expect((await planRef().get()).exists, true);
  });

  test(
    'deleting a planned journal meal clears the link and permits exactly one re-record',
    () async {
      await plans.savePlan(uid, draft());
      await record(draft());
      await nutrition.deleteMeal(uid: uid, mealId: mealRef().id);
      expect(
        (await planRef().get(
          const GetOptions(source: Source.server),
        )).data()?['loggedMealId'],
        isNull,
      );
      await record(draft());
      await record(draft());
      expect(
        (await db.collection('users/$uid/meal_logs').get()).docs,
        hasLength(1),
      );
    },
  );
  test(
    'checking a legacy dangling reference repairs it without creating a meal',
    () async {
      await plans.savePlan(uid, draft());
      await seedDanglingLink();
      expect(await plans.existingPlanMeal(uid, getId()), false);
      expect(
        (await planRef().get(
          const GetOptions(source: Source.server),
        )).data()?['loggedMealId'],
        isNull,
      );
      expect((await mealRef().get()).exists, false);
    },
  );
  test(
    'editing a legacy dangling plan unlocks it while retaining historical meals',
    () async {
      await plans.savePlan(uid, draft());
      await seedDanglingLink();
      await plans.savePlan(uid, draft(grams: 150));
      expect((await planRef().get()).data()?['loggedMealId'], isNull);
      expect((await mealRef().get()).exists, false);
    },
  );

  test(
    'replay after committed-but-unacknowledged confirmation is idempotent and rejects a changed payload',
    () async {
      await plans.savePlan(uid, draft());
      final confirmation = (await plans.loadPlan(uid, getId()))!;
      // Simulate losing the caller's ACK: commit succeeds, discard the return value.
      await plans.recordPlanMeal(uid, confirmation, draft());
      final original = (await mealRef().get()).data();
      await plans.recordPlanMeal(uid, confirmation, draft());
      await expectLater(
        plans.recordPlanMeal(uid, confirmation, draft(grams: 150)),
        throwsFormatException,
      );
      expect((await mealRef().get()).data(), original);
      await expectLater(
        plans.savePlan(uid, draft(grams: 200)),
        throwsFormatException,
      );
      expect((await mealRef().get()).data(), original);
    },
  );

  test(
    'two independent Firebase apps confirm concurrently and create exactly one meal',
    () async {
      await plans.savePlan(uid, draft());
      final first = (await plans.loadPlan(uid, getId()))!;
      final second = (await secondPlans.loadPlan(uid, getId()))!;
      final ids = await Future.wait([
        plans.recordPlanMeal(uid, first, draft()),
        secondPlans.recordPlanMeal(uid, second, draft()),
      ]);
      expect(ids.toSet(), {'plan-${getId()}'});
      expect(
        (await db.collection('users/$uid/meal_logs').get()).docs,
        hasLength(1),
      );
      expect((await planRef().get()).data()?['loggedMealId'], mealRef().id);
    },
  );

  test(
    'concurrent confirmations with different portions preserve one winner without overwriting it',
    () async {
      await plans.savePlan(uid, draft());
      final first = (await plans.loadPlan(uid, getId()))!;
      final second = (await secondPlans.loadPlan(uid, getId()))!;
      Future<bool> attempt(
        WellnessRepository repo,
        PlannedMeal plan,
        MealDraft value,
      ) async {
        try {
          await repo.recordPlanMeal(uid, plan, value);
          return true;
        } on FormatException {
          return false;
        }
      }

      final outcomes = await Future.wait([
        attempt(plans, first, draft()),
        attempt(secondPlans, second, draft(grams: 200)),
      ]);
      expect(outcomes.where((success) => success), hasLength(1));
      final original = (await mealRef().get()).data()!;
      expect(original['totalKcal'], outcomes.first ? 120 : 240);
      expect(
        (await db.collection('users/$uid/meal_logs').get()).docs,
        hasLength(1),
      );
    },
  );

  test(
    'stale confirmation after plan edit cannot write an outdated snapshot',
    () async {
      await plans.savePlan(uid, draft());
      final original = (await plans.loadPlan(uid, getId()))!;
      await plans.savePlan(uid, draft(grams: 200));
      await expectLater(
        plans.recordPlanMeal(uid, original, draft()),
        throwsFormatException,
      );
      expect((await mealRef().get()).exists, false);
      await record(draft(grams: 200));
      expect((await mealRef().get()).data()?['totalKcal'], 240);
    },
  );

  test(
    'deleting a plan preserves history and a stale form cannot recreate the plan or overwrite meal',
    () async {
      await plans.savePlan(uid, draft());
      final original = (await plans.loadPlan(uid, getId()))!;
      await plans.recordPlanMeal(uid, original, draft());
      final recorded = (await mealRef().get()).data();
      await plans.deletePlan(uid, getId());
      expect((await mealRef().get()).data(), recorded);
      await expectLater(
        plans.recordPlanMeal(uid, original, draft()),
        throwsFormatException,
      );
      await expectLater(
        plans.savePlan(uid, draft(grams: 200)),
        throwsFormatException,
      );
      expect((await planRef().get()).exists, false);
      await nutrition.deleteMeal(uid: uid, mealId: mealRef().id);
      await plans.savePlan(uid, draft());
      await expectLater(
        plans.recordPlanMeal(uid, original, draft()),
        throwsFormatException,
      );
    },
  );

  test(
    'confirmation from a deleted plan fails without creating either document',
    () async {
      await plans.savePlan(uid, draft());
      final original = (await plans.loadPlan(uid, getId()))!;
      await plans.deletePlan(uid, getId());
      await expectLater(
        plans.recordPlanMeal(uid, original, draft()),
        throwsFormatException,
      );
      expect((await mealRef().get()).exists, false);
      expect((await planRef().get()).exists, false);
    },
  );

  test(
    'legacy unlinked recorded meal is repaired without rewriting its historical snapshot',
    () async {
      await plans.savePlan(uid, draft());
      await record(draft());
      final original = (await mealRef().get()).data();
      await seedDanglingLink(linked: false);
      expect(await plans.existingPlanMeal(uid, getId()), true);
      expect((await planRef().get()).data()?['loggedMealId'], mealRef().id);
      expect((await mealRef().get()).data(), original);
    },
  );

  test(
    'stale retry after journal deletion cannot resurrect the removed meal',
    () async {
      await plans.savePlan(uid, draft());
      final original = (await plans.loadPlan(uid, getId()))!;
      await plans.recordPlanMeal(uid, original, draft());
      await nutrition.deleteMeal(uid: uid, mealId: mealRef().id);
      await expectLater(
        plans.recordPlanMeal(uid, original, draft()),
        throwsFormatException,
      );
      expect((await mealRef().get()).exists, false);
      await record(draft());
      expect((await mealRef().get()).exists, true);
    },
  );

  test(
    'ordinary manual meal deletion leaves unrelated plan and recorded meal unchanged',
    () async {
      await plans.savePlan(uid, draft());
      await record(draft());
      final original = (await mealRef().get()).data();
      await nutrition.addMeal(
        uid: uid,
        draft: draft(),
        operationId: 'manual-entry',
      );
      await nutrition.deleteMeal(uid: uid, mealId: 'manual-entry');
      expect((await mealRef().get()).data(), original);
      expect((await planRef().get()).data()?['loggedMealId'], mealRef().id);
    },
  );

  test(
    'existing account cleanup removes linked plans before journal batches',
    () async {
      await plans.savePlan(uid, draft());
      await record(draft());
      await FirebaseAccountDataRepository(db).deleteAllUserData(uid);
      expect((await planRef().get()).exists, false);
      expect((await mealRef().get()).exists, false);
      // Cleanup is tested independently of deleting the Auth identity.
      expect(auth.currentUser?.uid, uid);
    },
  );
}
