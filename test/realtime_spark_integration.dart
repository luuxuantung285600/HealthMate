// Opt-in real Flutter SDK test. Fixed local demo only; never production.
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/auth/data/firebase_account_data_repository.dart';
import 'package:healthmate/features/food_library/data/firebase_food_library_repository.dart';
import 'package:healthmate/features/food_library/models/food_library_models.dart';
import 'package:healthmate/features/food_library/providers/food_library_providers.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/data/firebase_nutrition_repository.dart';
import 'package:healthmate/features/support/data/firebase_support_repository.dart';
import 'package:healthmate/features/support/models/support_models.dart';
import 'package:healthmate/features/nutrition_targets/data/firebase_nutrition_target_repository.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/nutrition_targets/providers/nutrition_target_providers.dart';
import 'package:healthmate/features/reports/models/period_report.dart';
import 'package:healthmate/features/reports/providers/report_providers.dart';
import 'package:healthmate/features/water/data/firebase_water_repository.dart';
import 'package:healthmate/features/water/models/water_log.dart';
import 'package:healthmate/features/water/providers/water_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (!const bool.fromEnvironment('HEALTHMATE_EMULATOR_TESTS')) {
    throw StateError('Requires the guarded local demo emulator test runner.');
  }
  late FirebaseApp app, second, adminApp;
  late FirebaseAuth auth, otherAuth, adminAuth;
  late FirebaseFirestore db, remote, adminDb;
  late ProviderContainer container;
  final day = DateTime(2026, 11, 6);
  final range = ReportRange(DateTime(2026, 11, 7), 1);

  Future<void> until(bool Function() matches) async {
    final timeout = DateTime.now().add(const Duration(seconds: 20));
    while (!matches()) {
      if (DateTime.now().isAfter(timeout)) {
        throw StateError('Realtime update timed out');
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  setUpAll(() async {
    FirebaseCoreWeb.registerWith(webPluginRegistrar);
    FirebaseAuthWeb.registerWith(webPluginRegistrar);
    FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
    webPluginRegistrar.registerMessageHandler();
    const options = FirebaseOptions(
      apiKey: 'demo-key',
      appId: '1:123:web:spark-test',
      messagingSenderId: '123',
      projectId: 'demo-healthmate-admin',
      authDomain: 'localhost',
    );
    app = await Firebase.initializeApp(options: options);
    second = await Firebase.initializeApp(
      name: 'spark-second-device',
      options: options,
    );
    adminApp = await Firebase.initializeApp(
      name: 'spark-admin',
      options: options,
    );
    adminAuth = FirebaseAuth.instanceFor(app: adminApp);
    await adminAuth.useAuthEmulator(
      '127.0.0.1',
      9098,
      automaticHostMapping: false,
    );
    await adminAuth.setPersistence(Persistence.NONE);
    await adminAuth.signInWithEmailAndPassword(
      email: 'admin@healthmate.local',
      password: 'LocalHealthMate!2026',
    );
    auth = FirebaseAuth.instanceFor(app: app);
    otherAuth = FirebaseAuth.instanceFor(app: second);
    for (final client in [auth, otherAuth]) {
      await client.useAuthEmulator(
        '127.0.0.1',
        9098,
        automaticHostMapping: false,
      );
      await client.setPersistence(Persistence.NONE);
      await client.signInWithEmailAndPassword(
        email: 'member@healthmate.local',
        password: 'LocalHealthMate!2026',
      );
    }
    db = FirebaseFirestore.instanceFor(app: app);
    remote = FirebaseFirestore.instanceFor(app: second);
    adminDb = FirebaseFirestore.instanceFor(app: adminApp);
    for (final client in [db, remote, adminDb]) {
      client.settings = const Settings(persistenceEnabled: false);
      client.useFirestoreEmulator(
        // Three independent SDK clients share this test browser. The emulator
        // uses HTTP/1.1, so put admin on a separate loopback host to avoid
        // Chrome's per-host socket limit (real devices do not share sockets).
        client == adminDb ? 'localhost' : '127.0.0.1',
        8092,
        automaticHostMapping: false,
      );
    }
    final user = AuthUser(
      uid: auth.currentUser!.uid,
      email: 'member@healthmate.local',
      emailVerified: true,
    );
    container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith((ref) => Stream.value(user)),
        waterRepositoryProvider.overrideWithValue(FirebaseWaterRepository(db)),
        foodLibraryRepositoryProvider.overrideWithValue(
          FirebaseFoodLibraryRepository(db),
        ),
        nutritionTargetRepositoryProvider.overrideWithValue(
          FirebaseNutritionTargetRepository(db, now: () => day),
        ),
      ],
    );
    container.listen(authSessionProvider, (_, _) {});
    await container.read(authSessionProvider.future);
  });
  tearDownAll(() async {
    container.dispose();
    await auth.signOut();
    await otherAuth.signOut();
    await adminAuth.signOut();
    await db.terminate();
    await remote.terminate();
    await adminDb.terminate();
    await app.delete();
    await second.delete();
    await adminApp.delete();
  });

  test(
    'Spark range report receives create, edit and delete from another SDK client without Functions',
    () async {
      final provider = periodWaterProvider(range);
      final sub = container.listen(provider, (_, _) {});
      final source = FirebaseWaterRepository(remote),
          uid = otherAuth.currentUser!.uid;
      String? id;
      try {
        await until(() => container.read(provider).hasValue);
        final before = container.read(provider).value!.length;
        id = await source.add(
          uid: uid,
          draft: WaterLogDraft(amountMl: 250, consumedAt: day),
        );
        await until(
          () =>
              container
                  .read(provider)
                  .value
                  ?.any((row) => row.id == id && row.amountMl == 250) ==
              true,
        );
        await source.update(
          uid: uid,
          logId: id,
          draft: WaterLogDraft(amountMl: 500, consumedAt: day),
        );
        await until(
          () =>
              container
                  .read(provider)
                  .value
                  ?.any((row) => row.id == id && row.amountMl == 500) ==
              true,
        );
        await source.delete(uid: uid, logId: id);
        id = null;
        await until(() => container.read(provider).value?.length == before);
      } finally {
        sub.close();
        if (id != null) await source.delete(uid: uid, logId: id);
      }
    },
  );

  test('Spark open private food reflects remote edit and deletion', () async {
    final source = FirebaseFoodLibraryRepository(remote),
        uid = otherAuth.currentUser!.uid;
    PersonalFood food(String name) => PersonalFood(
      id: 'spark-sdk-food',
      name: name,
      per100g: const NutritionTotals(
        kcal: 100,
        proteinG: 2,
        carbsG: 20,
        fatG: 1,
      ),
    );
    await source.save(uid, food('Before remote edit'), create: true);
    final provider = libraryEntryProvider((
      kind: FoodSourceKind.custom,
      id: 'spark-sdk-food',
    ));
    final sub = container.listen(provider, (_, _) {});
    try {
      await until(
        () => container.read(provider).value?.name == 'Before remote edit',
      );
      await source.save(uid, food('After remote edit'), create: false);
      await until(
        () => container.read(provider).value?.name == 'After remote edit',
      );
      await source.delete(uid, FoodSourceKind.custom, 'spark-sdk-food');
      await until(
        () =>
            container.read(provider).hasValue &&
            !container.read(provider).isLoading &&
            container.read(provider).value == null,
      );
    } finally {
      sub.close();
      await source.delete(uid, FoodSourceKind.custom, 'spark-sdk-food');
    }
  });

  test(
    'Spark target listener updates the effective daily target from another client',
    () async {
      final source = FirebaseNutritionTargetRepository(remote, now: () => day),
          uid = otherAuth.currentUser!.uid;
      final provider = nutritionTargetProvider(localDateKey(day));
      final sub = container.listen(provider, (_, _) {});
      try {
        await source.save(
          uid,
          NutritionTarget(
            effectiveFromDateKey: localDateKey(day),
            kcalTarget: 1800,
          ),
        );
        await until(() => container.read(provider).value?.kcalTarget == 1800);
        await source.save(
          uid,
          NutritionTarget(
            effectiveFromDateKey: localDateKey(day),
            kcalTarget: 1900,
          ),
        );
        await until(() => container.read(provider).value?.kcalTarget == 1900);
      } finally {
        sub.close();
        await remote
            .doc('users/$uid/nutrition_targets/${localDateKey(day)}')
            .delete();
      }
    },
  );

  test(
    'customer support reaches admin, admin replies and status reach app live',
    () async {
      final uid = auth.currentUser!.uid;
      final support = FirebaseSupportRepository(db), id = support.newId();
      final received = adminDb
          .collection('support_tickets')
          .orderBy('updatedAt', descending: true)
          .limit(25)
          .snapshots()
          .firstWhere((page) => page.docs.any((row) => row.id == id));
      await support.create(
        uid,
        id,
        SupportType.bug,
        'Synthetic integration request',
        'Emulator fixture only',
        topic: SupportTopic.nutrition,
      );
      expect(
        (await received.timeout(const Duration(seconds: 20))).docs.first.id,
        id,
      );
      // A retry of the same action must not create another ticket or debit again.
      await support.create(
        uid,
        id,
        SupportType.bug,
        'Synthetic integration request',
        'Emulator fixture only',
        topic: SupportTopic.nutrition,
      );
      expect((await db.doc('support_usage/$uid').get()).data()!['count'], 1);
      final response = support
          .watchMessages(uid, id)
          .firstWhere((messages) => messages.length == 1);
      final ticket = adminDb.doc('support_tickets/$id'),
          message = ticket.collection('messages').doc();
      await adminDb.runTransaction((transaction) async {
        final before = (await transaction.get(ticket)).data()!;
        final count = before['messageCount'] as int;
        transaction.set(message, {
          'authorUid': adminAuth.currentUser!.uid,
          'role': 'admin',
          'text': 'Synthetic admin response',
          'sequence': count + 1,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(ticket, {
          'messageCount': count + 1,
          'lastMessageId': message.id,
          'updatedBy': adminAuth.currentUser!.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      expect(
        (await response.timeout(const Duration(seconds: 20))).single.text,
        'Synthetic admin response',
      );
      final resolved = support
          .watchTicket(uid, id)
          .firstWhere((ticket) => ticket?.status == SupportStatus.resolved);
      await ticket.update({
        'status': 'resolved',
        'updatedBy': adminAuth.currentUser!.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      expect(
        (await resolved.timeout(const Duration(seconds: 20)))!.status,
        SupportStatus.resolved,
      );
      final reopened = adminDb
          .doc('support_tickets/$id')
          .snapshots()
          .firstWhere((ticket) => ticket.data()?['status'] == 'open');
      final replyId = support.newId();
      await support.reply(uid, id, replyId, 'Synthetic customer follow-up');
      await support.reply(uid, id, replyId, 'Synthetic customer follow-up');
      expect(
        (await reopened.timeout(
          const Duration(seconds: 20),
        )).data()!['messageCount'],
        2,
      );
    },
  );

  test(
    'audited admin food create/edit/hide/restore reaches app and preserves meal history',
    () async {
      const id = 'operations-sdk-food';
      Future<T> step<T>(String name, Future<T> action) => action.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw StateError('SDK food scenario timed out: $name'),
      );
      final nutrition = FirebaseNutritionRepository(
        db,
        catalogLoader: () async => [],
      );
      Future<void> save(Map<String, dynamic> patch) async {
        final food = adminDb.doc('food_catalog/$id'),
            audit = adminDb.collection('admin_audit').doc();
        await step(
          'audited catalog write',
          adminDb.runTransaction((transaction) async {
            final before = await transaction.get(food);
            final changes = {
              ...patch,
              'updatedAt': FieldValue.serverTimestamp(),
              'updatedBy': adminAuth.currentUser!.uid,
              'lastAdminOperationId': audit.id,
            };
            transaction.set(food, {...?before.data(), ...changes});
            transaction.set(audit, {
              'actorUid': adminAuth.currentUser!.uid,
              'entityType': 'food_catalog',
              'entityId': id,
              'at': FieldValue.serverTimestamp(),
              // Rules compare actual changes, including unchanged audit fields.
              'changedFields': [
                for (final key in changes.keys)
                  if (!before.exists ||
                      !before.data()!.containsKey(key) ||
                      before.data()![key] != changes[key])
                    key,
              ],
              'reason': 'Synthetic local SDK test',
            });
          }),
        );
      }

      List<FoodCatalogItem>? catalog;
      Object? catalogError;
      final subscription = nutrition.watchFoodCatalog().listen(
        (rows) => catalog = rows,
        onError: (Object error) => catalogError = error,
      );
      Future<void> catalogUntil(bool Function(List<FoodCatalogItem>) matches) =>
          until(() {
            if (catalogError != null) throw catalogError!;
            return catalog != null && matches(catalog!);
          });
      // Keep the same catalog subscription alive as the real app screen does.
      await catalogUntil((_) => true);
      try {
        await save({
          'name': 'Synthetic catalog food',
          'alternateNames': <String>[],
          'category': 'Fixture',
          'servingBasis': 'per_100g',
          'unit': 'g',
          'kcalPer100g': 130,
          'proteinGPer100g': 3,
          'carbsGPer100g': 28,
          'fatGPer100g': 1,
          'fiberGPer100g': null,
          'sourceLabel': 'Synthetic fixture',
          'sourceUrl': 'https://example.com/fixture',
          'isEstimated': true,
          'isActive': true,
          'servingLabel': null,
          'servingGrams': null,
        });
        await catalogUntil((rows) => rows.any((row) => row.id == id));
        final food = catalog!.singleWhere((row) => row.id == id);
        final uid = auth.currentUser!.uid;
        final mealId = await step(
          'meal snapshot write',
          nutrition.addMeal(
            uid: uid,
            draft: MealDraft(
              type: MealType.snack,
              consumedAt: DateTime.now(),
              source: MealSource.manual,
              items: [MealItemSnapshot.fromCatalog(food, 100)],
            ),
          ),
        );
        await save({'name': 'Synthetic edited food', 'kcalPer100g': 140});
        await catalogUntil(
          (rows) => rows.any(
            (row) => row.id == id && row.name == 'Synthetic edited food',
          ),
        );
        await save({'isActive': false});
        await catalogUntil((rows) => rows.every((row) => row.id != id));
        final history =
            (await db
                    .doc('users/$uid/meal_logs/$mealId')
                    .get(const GetOptions(source: Source.server)))
                .data()!;
        expect(history['totalKcal'], 130);
        expect(
          (history['items'] as List).single['name'],
          'Synthetic catalog food',
        );
        await save({'isActive': true});
        await catalogUntil((rows) => rows.any((row) => row.id == id));
      } finally {
        await subscription.cancel().timeout(const Duration(seconds: 3));
      }
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'customer deletion removes admin directory/support live and blocks stale second-device writes',
    () async {
      final uid = auth.currentUser!.uid;
      final directory = adminDb
          .collection('user_directory')
          .snapshots()
          .firstWhere((page) => page.docs.every((row) => row.id != uid));
      final tickets = adminDb
          .collection('support_tickets')
          .where('uid', isEqualTo: uid)
          .snapshots()
          .firstWhere((page) => page.docs.isEmpty);
      final deletion = FirebaseAccountDataRepository(db);
      await auth.currentUser!.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: 'member@healthmate.local',
          password: 'LocalHealthMate!2026',
        ),
      );
      await auth.currentUser!.getIdToken(true);
      await deletion.requestDeletion(uid);
      await expectLater(
        remote.doc('users/$uid/water_logs/late').set({'amountMl': 250}),
        throwsA(
          isA<FirebaseException>().having(
            (error) => error.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      await deletion.deleteAllUserData(uid);
      await deletion.markLocalDataDeleted(uid);
      await directory.timeout(const Duration(seconds: 20));
      await tickets.timeout(const Duration(seconds: 20));
      await auth.currentUser!.delete();
      expect(auth.currentUser, isNull);
      expect((await adminDb.doc('user_directory/$uid').get()).exists, false);
      await expectLater(
        otherAuth.currentUser!.reload(),
        throwsA(isA<FirebaseAuthException>()),
      );
    },
  );
}
