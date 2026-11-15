// Opt-in production QA. Intentionally NOT named *_test.dart.
// Requires explicit authorization for two synthetic QA accounts. Never use a
// real user's credentials, default Firebase app, Admin SDK, or an emulator token.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/activity/data/firebase_activity_repository.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/auth/data/firebase_account_data_repository.dart';
import 'package:healthmate/features/daily_quest/models/daily_quest.dart';
import 'package:healthmate/features/food_library/data/firebase_favorite_food_repository.dart';
import 'package:healthmate/features/food_library/data/firebase_food_library_repository.dart';
import 'package:healthmate/features/food_library/models/food_library_models.dart';
import 'package:healthmate/features/goals/data/firebase_goals_repository.dart';
import 'package:healthmate/features/goals/models/tracking_goal.dart';
import 'package:healthmate/features/nutrition/data/firebase_nutrition_repository.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition_targets/data/firebase_nutrition_target_repository.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/profile/data/firebase_health_profile_repository.dart';
import 'package:healthmate/features/profile/models/health_goal.dart';
import 'package:healthmate/features/profile/models/onboarding_draft.dart';
import 'package:healthmate/features/water/data/firebase_water_repository.dart';
import 'package:healthmate/features/water/models/water_log.dart';
import 'package:healthmate/firebase_options.dart';

const _run = String.fromEnvironment('HEALTHMATE_QA_RUN');
const _password = String.fromEnvironment('HEALTHMATE_QA_PASSWORD');
const _emails = [
  String.fromEnvironment('HEALTHMATE_QA_EMAIL_A'),
  String.fromEnvironment('HEALTHMATE_QA_EMAIL_B'),
];
const _server = GetOptions(source: Source.server);
const _collections = [
  'body_metrics',
  'meal_logs',
  'water_logs',
  'activity_logs',
  'workout_sessions',
  'goals',
  'daily_quests',
  'nutrition_targets',
  'favorite_foods',
  'custom_foods',
  'recipes',
  'chat_sessions',
];

class _QaClient {
  _QaClient(this.app, this.auth, this.db, this.email);
  final FirebaseApp app;
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final String? email;
  String? registeredUid;

  String get uid {
    final user = auth.currentUser;
    if (email == null || user?.email != email || user?.uid != registeredUid) {
      throw StateError('QA identity guard failed; no cleanup/write allowed.');
    }
    return user!.uid;
  }

  Future<void> signInOrCreate() async {
    try {
      await auth.signInWithEmailAndPassword(email: email!, password: _password);
    } on FirebaseAuthException catch (e) {
      if (!['user-not-found', 'invalid-credential'].contains(e.code)) rethrow;
      // Existing emails are never overwritten. A retry uses the same two emails.
      await auth.createUserWithEmailAndPassword(
        email: email!,
        password: _password,
      );
    }
    registeredUid = auth.currentUser!.uid;
    uid; // Validate before any Firestore operation.
  }

  Future<void> cleanup() async {
    if (registeredUid == null) return;
    if (auth.currentUser == null) {
      await auth.signInWithEmailAndPassword(email: email!, password: _password);
    }
    final ownedUid = uid;
    await db.enableNetwork();
    await FirebaseAccountDataRepository(db).deleteAllUserData(ownedUid);
    expect((await db.doc('users/$ownedUid').get(_server)).exists, isFalse);
    for (final name in _collections) {
      expect(
        (await db.collection('users/$ownedUid/$name').limit(1).get(_server))
            .docs,
        isEmpty,
        reason: 'QA cleanup: $name',
      );
    }
    // Auth accounts are deliberately retained; only QA Firestore data is deleted.
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (!const bool.fromEnvironment('HEALTHMATE_PRODUCTION_QA_TESTS') ||
      !RegExp(r'^\d{13,20}$').hasMatch(_run) ||
      _password.length < 24 ||
      _emails[0] != 'healthmate.qa.u2.$_run.a@example.com' ||
      _emails[1] != 'healthmate.qa.u2.$_run.b@example.com' ||
      DefaultFirebaseOptions.web.projectId != 'healthmate-app-20261013') {
    throw StateError(
      'Explicit production QA opt-in and private QA-only defines required.',
    );
  }
  final clients = <_QaClient>[];

  setUpAll(() async {
    FirebaseCoreWeb.registerWith(webPluginRegistrar);
    FirebaseAuthWeb.registerWith(webPluginRegistrar);
    FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
    webPluginRegistrar.registerMessageHandler();
    for (var i = 0; i < 3; i++) {
      final app = await Firebase.initializeApp(
        name: 'healthmate-u2-qa-$_run-$i',
        options: DefaultFirebaseOptions.web,
      );
      final auth = FirebaseAuth.instanceFor(app: app);
      await auth.setPersistence(Persistence.NONE);
      final db = FirebaseFirestore.instanceFor(app: app);
      db.settings = const Settings(persistenceEnabled: false);
      clients.add(_QaClient(app, auth, db, i < 2 ? _emails[i] : null));
    }
  });

  tearDownAll(() async {
    // Attempt BOTH cleanups even after a failed assertion/network error.
    final errors = <Object>[];
    for (final client in clients) {
      try {
        await client.cleanup().timeout(const Duration(seconds: 60));
      } catch (e) {
        errors.add(e);
      }
      try {
        await client.auth.signOut();
        await client.app.delete();
      } catch (e) {
        errors.add(e);
      }
    }
    expect(
      errors,
      isEmpty,
      reason: 'QA cleanup must be verified, never assumed.',
    );
    // ignore: avoid_print
    print('U2 QA cleanup verified for both accounts; Auth accounts retained.');
  });

  test(
    'U2 production repositories and deployed access controls',
    () async {
      final a = clients[0], b = clients[1], guest = clients[2];
      await a.signInOrCreate();
      await b.signInOrCreate();
      expect(a.uid, isNot(b.uid));
      final uid = a.uid;
      final db = a.db;
      final day = localDateOnly(DateTime.now());
      final yesterday = DateTime(day.year, day.month, day.day - 1);
      final tomorrow = DateTime(day.year, day.month, day.day + 1);
      final key = localDateKey(day), oldKey = localDateKey(yesterday);
      final profiles = FirebaseHealthProfileRepository(db);
      await profiles.ensureProfile(uid: uid, email: a.email!);
      await FirebaseHealthProfileRepository(
        b.db,
      ).ensureProfile(uid: b.uid, email: b.email!);
      await profiles.completeOnboarding(
        uid: uid,
        draft: OnboardingDraft(
          displayName: 'QA U2 synthetic profile',
          birthDate: DateTime(2000, 1, 15),
          heightCm: 170,
          currentWeightKg: 70,
          healthGoal: HealthGoal.maintainWeight,
          targetWeightKg: null,
        ),
      );
      expect(
        (await profiles
                .watchProfile(uid)
                .firstWhere((v) => v?.isOnboardingComplete == true))!
            .displayName,
        'QA U2 synthetic profile',
      );
      checkpoint('01 two QA identities and onboarding persisted');

      // A historical synthetic fixture ONLY under the QA UID; no real migration.
      await FirebaseNutritionTargetRepository(db, now: () => yesterday).save(
        uid,
        NutritionTarget(effectiveFromDateKey: oldKey, kcalTarget: 1800),
      );
      final targets = FirebaseNutritionTargetRepository(db);
      await targets.save(
        uid,
        NutritionTarget(
          effectiveFromDateKey: key,
          kcalTarget: 2000,
          proteinGTarget: 100,
          carbsGTarget: 250,
          fatGTarget: 60,
        ),
      );
      await targets.save(
        uid,
        NutritionTarget(
          effectiveFromDateKey: key,
          kcalTarget: 2100,
          proteinGTarget: 110,
          carbsGTarget: 260,
          fatGTarget: 60,
        ),
      );
      expect((await targets.loadForDay(uid, oldKey))!.kcalTarget, 1800);
      expect((await targets.loadForDay(uid, key))!.kcalTarget, 2100);
      expect(
        (await targets.loadForRange(
          uid,
          oldKey,
          localDateKey(tomorrow),
        )).length,
        2,
      );
      checkpoint('02 target effective dates and history');

      final library = FirebaseFoodLibraryRepository(db);
      final customId = 'qa_$_run', recipeId = 'recipe_$_run';
      final custom = PersonalFood(
        id: customId,
        name: 'QA U2 synthetic ingredient',
        per100g: const NutritionTotals(
          kcal: 200,
          proteinG: 10,
          carbsG: 30,
          fatG: 4,
        ),
        sourceLabel: 'QA U2 synthetic fixture',
      );
      await library.save(uid, custom, create: true);
      expect(
        (await library.load(
          uid,
          FoodSourceKind.custom,
          customId,
        ))!.asFood().per100g!.kcal,
        200,
      );
      final recipe = FoodRecipe(
        id: recipeId,
        name: 'QA U2 synthetic recipe',
        ingredients: [MealItemSnapshot.fromCatalog(custom.asFood(), 100)],
        yieldGrams: 80,
        servingsCount: 2,
        sourceLabel: 'QA U2 synthetic fixture',
      );
      await library.save(uid, recipe, create: true);
      expect(
        (await library.load(
          uid,
          FoodSourceKind.recipe,
          recipeId,
        ))!.asFood().per100g!.kcal,
        250,
      );
      final favorites = FirebaseFavoriteFoodRepository(db);
      await favorites.setFavorite(
        uid,
        customId,
        true,
        sourceKind: FoodSourceKind.custom,
      );
      await favorites.setFavorite(
        uid,
        recipeId,
        true,
        sourceKind: FoodSourceKind.recipe,
      );
      await favorites.setFavorite(
        uid,
        recipeId,
        true,
        sourceKind: FoodSourceKind.recipe,
      );
      expect(
        (await favorites.watch(uid).firstWhere((p) => !p.fromCache))
            .items
            .length,
        2,
      );
      checkpoint('03 personal food, recipe, idempotent favorites');

      final nutrition = FirebaseNutritionRepository(db);
      final mealId = 'meal_$_run';
      final draft = MealDraft(
        type: MealType.lunch,
        consumedAt: day.add(const Duration(hours: 12)),
        source: MealSource.manual,
        items: [MealItemSnapshot.fromCatalog(recipe.asFood(), 20)],
      );
      await nutrition.addMeal(uid: uid, draft: draft, operationId: mealId);
      await nutrition.addMeal(uid: uid, draft: draft, operationId: mealId);
      var meal = (await nutrition.loadRange(uid, day, tomorrow)).single;
      expect(meal.totals.kcal, 50);
      await library.save(
        uid,
        PersonalFood(
          id: customId,
          name: custom.name,
          per100g: const NutritionTotals(kcal: 900),
          sourceLabel: custom.sourceLabel,
        ),
        create: false,
      );
      await library.save(
        uid,
        FoodRecipe(
          id: recipeId,
          name: recipe.name,
          ingredients: [MealItemSnapshot.fromCatalog(custom.asFood(), 100)],
          yieldGrams: 40,
          servingsCount: 2,
          sourceLabel: recipe.sourceLabel,
        ),
        create: false,
      );
      await library.delete(uid, FoodSourceKind.custom, customId);
      await library.delete(uid, FoodSourceKind.recipe, recipeId);
      meal = (await nutrition.loadRange(uid, day, tomorrow)).single;
      expect(meal.totals.kcal, 50);
      expect(meal.items.single.grams, 20);
      final scaled = MealDraft(
        type: meal.type,
        consumedAt: meal.consumedAt,
        source: meal.source,
        items: [meal.items.single.withGrams(40)],
      );
      await nutrition.updateMeal(uid: uid, mealId: mealId, draft: scaled);
      expect(
        (await nutrition.loadRange(uid, day, tomorrow)).single.totals.kcal,
        100,
      );
      await nutrition.addMeal(
        uid: uid,
        draft: meal.copyDraft(day: yesterday),
        operationId: 'copy_$_run',
      );
      expect(
        (await nutrition.loadRange(uid, yesterday, day)).single.totals.kcal,
        50,
      );
      checkpoint(
        '04 recipe meal snapshot survives source edit/delete; scale/copy date',
      );

      final water = FirebaseWaterRepository(db),
          activity = FirebaseActivityRepository(db);
      await water.add(
        uid: uid,
        draft: WaterLogDraft(amountMl: 250, consumedAt: DateTime.now()),
      );
      await activity.add(
        uid: uid,
        draft: ActivityLogDraft(
          type: ActivityType.walking,
          durationMinutes: 20,
          performedAt: DateTime.now(),
          note: 'QA U2 synthetic',
        ),
      );
      // Server reads exercise the real composite indexes, not emulator/cache behavior.
      for (final pair in [
        ('water_logs', 'consumedAt'),
        ('activity_logs', 'performedAt'),
      ]) {
        expect(
          (await db
                  .collection('users/$uid/${pair.$1}')
                  .where('dateKey', isEqualTo: key)
                  .orderBy(pair.$2, descending: true)
                  .get(_server))
              .docs
              .length,
          1,
        );
      }
      expect(totalWaterMl(await water.loadRange(uid, day, tomorrow)), 250);
      expect(
        totalActivityMinutes(await activity.loadRange(uid, day, tomorrow)),
        20,
      );
      checkpoint('05 daily logs and production composite queries');

      final goals = FirebaseGoalsRepository(db);
      final goalId = 'goal_$_run';
      final goal = GoalDraft(
        type: GoalType.water,
        targetValue: 1000,
        startDate: day,
        endDate: day.add(const Duration(days: 7)),
      );
      await goals.saveGoal(uid, goal, id: goalId, create: true);
      await goals.saveGoal(uid, goal, id: goalId, create: true);
      expect(
        (await goals.watchGoals(uid).firstWhere((g) => g.isNotEmpty)).length,
        1,
      );
      final quest = DailyQuest(
        dateKey: key,
        type: QuestType.water,
        title: 'QA U2 synthetic quest',
        description: 'QA only',
        reason: 'Synthetic verification',
        targetValue: 250,
        unit: 'ml',
      );
      await goals.ensureQuest(uid, quest);
      await goals.finishQuest(uid, key, QuestStatus.completed);
      await goals.ensureQuest(uid, quest);
      expect(
        (await goals
                .watchQuest(uid, key)
                .firstWhere((q) => q?.status == QuestStatus.completed))!
            .status,
        QuestStatus.completed,
      );
      checkpoint('06 goal and stable completed quest');

      await a.auth.signOut();
      expect(a.auth.currentUser, isNull);
      await a.auth.signInWithEmailAndPassword(
        email: a.email!,
        password: _password,
      );
      expect(a.uid, uid);
      expect((await targets.loadForDay(uid, key))!.kcalTarget, 2100);
      expect(
        (await nutrition.loadRange(uid, day, tomorrow)).single.totals.kcal,
        100,
      );
      checkpoint('07 logout/login reload');

      final offlineId = 'offline_$_run';
      var acknowledged = false;
      Object? pendingError;
      await db.disableNetwork();
      final pending = nutrition
          .addMeal(uid: uid, draft: draft, operationId: offlineId)
          .then(
            (_) {
              acknowledged = true;
            },
            onError: (Object e) {
              pendingError = e;
            },
          );
      try {
        await Future<void>.delayed(const Duration(seconds: 3));
        expect(
          acknowledged,
          isFalse,
          reason: 'Offline write must not be claimed saved.',
        );
      } finally {
        await db.enableNetwork();
      }
      await pending;
      // Some web transaction versions fail immediately offline; same-ID retry is
      // valid after either a pending operation completes or an explicit failure.
      if (pendingError != null) expect(acknowledged, isFalse);
      await nutrition.addMeal(uid: uid, draft: draft, operationId: offlineId);
      final records = await nutrition.loadRange(uid, day, tomorrow);
      expect(records.where((m) => m.id == offlineId).length, 1);
      expect(records.singleWhere((m) => m.id == offlineId).totals.kcal, 50);
      checkpoint('08 offline/reconnect/retry same operation ID; no duplicate');

      var denied = 0;
      for (final client in [b, guest]) {
        await expectLater(
          client.db.doc('users/$uid').get(_server),
          _permissionDenied,
        );
        denied++;
        for (final collection in _collections) {
          final path = 'users/$uid/$collection';
          await expectLater(
            client.db.collection(path).limit(1).get(_server),
            _permissionDenied,
          );
          await expectLater(
            client.db.doc('$path/qa-denied-$_run').set({'qa': true}),
            _permissionDenied,
          );
          denied += 2;
        }
        await expectLater(
          client.db.doc('users/$uid').update({'displayName': 'QA denied'}),
          _permissionDenied,
        );
        await expectLater(
          client.db.doc('users/$uid/meal_logs/$mealId').delete(),
          _permissionDenied,
        );
        denied += 2;
      }
      expect(denied, 50);
      checkpoint(
        '09 50 denied cross-account/guest read-query-write-delete attempts',
      );

      await a.cleanup();
      expect(
        (await b.db.doc('users/${b.uid}').get(_server)).exists,
        isTrue,
        reason: 'Cleaning A must preserve B.',
      );
      await b.cleanup();
      checkpoint(
        '10 QA data cleanup verified; B survives A cleanup; Auth retained',
      );
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

final _permissionDenied = throwsA(
  isA<FirebaseException>().having((e) => e.code, 'code', 'permission-denied'),
);

void checkpoint(String name) {
  // No credentials, ID tokens, or real account identifiers in logs.
  // ignore: avoid_print
  print('U2 PASS $name');
}
