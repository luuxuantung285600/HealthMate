// Opt-in real Firebase web SDK tests. All fixtures use fixed local demo emulators.
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
import 'package:healthmate/core/config/admin_runtime.dart';
import 'package:healthmate/features/auth/data/account_data_repository.dart';
import 'package:healthmate/features/auth/data/firebase_account_data_repository.dart';
import 'package:healthmate/features/auth/models/account_deletion_job.dart';
import 'package:healthmate/features/chatbot/data/firebase_chat_repository.dart';
import 'package:healthmate/features/chatbot/models/chat_models.dart';
import 'package:healthmate/features/nutrition/data/firebase_nutrition_repository.dart';
import 'package:healthmate/features/nutrition/models/nutrition_failure.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/premium/data/firebase_premium_repository.dart';
import 'package:healthmate/features/premium/models/premium_models.dart';
import 'package:healthmate/features/profile/data/firebase_health_profile_repository.dart';
import 'package:healthmate/features/profile/models/profile_failure.dart';
import 'package:healthmate/features/support/data/firebase_support_repository.dart';
import 'package:healthmate/features/support/models/support_models.dart';
import 'support/emulator_email_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const project = 'demo-healthmate-rules';
  const root =
      'http://127.0.0.1:8080/v1/projects/$project/databases/(default)/documents';
  const password = 'Emulator-only-test123!';
  if (!const bool.fromEnvironment('HEALTHMATE_EMULATOR_TESTS') ||
      !project.startsWith('demo-')) {
    throw StateError('Requires explicit local demo Auth/Firestore emulators.');
  }
  late FirebaseApp app, secondApp;
  late FirebaseAuth auth, secondAuth;
  late FirebaseFirestore db, secondDb;
  late FirebaseAccountDataRepository accounts;
  late String uid, email;
  const server = GetOptions(source: Source.server);
  final denied = throwsA(
    isA<FirebaseException>().having((e) => e.code, 'code', 'permission-denied'),
  );

  Map<String, dynamic> wire(Object? value) {
    if (value == null) return {'nullValue': null};
    if (value is String) return {'stringValue': value};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': '$value'};
    if (value is DateTime) {
      return {'timestampValue': value.toUtc().toIso8601String()};
    }
    if (value is List) {
      return {
        'arrayValue': {'values': value.map(wire).toList()},
      };
    }
    if (value is Map<String, dynamic>) {
      return {
        'mapValue': {
          'fields': value.map((key, data) => MapEntry(key, wire(data))),
        },
      };
    }
    throw StateError('Unsupported synthetic fixture value.');
  }

  Future<void> seed(Map<String, Map<String, dynamic>> documents) async {
    // No configurable hostname, cloud project, credential or production fallback.
    final response = await http.post(
      Uri.parse('$root:commit'),
      headers: {
        'Authorization': 'Bearer owner',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'writes': [
          for (final entry in documents.entries)
            {
              'update': {
                'name':
                    'projects/$project/databases/(default)/documents/${entry.key}',
                'fields': entry.value.map(
                  (key, data) => MapEntry(key, wire(data)),
                ),
              },
            },
        ],
      }),
    );
    expect(response.statusCode, 200, reason: 'Local demo fixture commit');
  }

  Future<http.Response> ownerRead(String path) => http.get(
    Uri.parse('$root/$path'),
    headers: {'Authorization': 'Bearer owner'},
  );

  MealDraft draft() => MealDraft(
    type: MealType.breakfast,
    consumedAt: DateTime.now(),
    source: MealSource.manual,
    items: const [
      MealItemSnapshot(
        foodId: 'fixture-rice',
        name: 'Synthetic fixture rice',
        grams: 100,
        nutrition: NutritionTotals(kcal: 130, proteinG: 3, carbsG: 28, fatG: 1),
        sourceLabel: 'Emulator fixture',
        isEstimated: true,
      ),
    ],
  );

  Future<void> reauthenticate() async {
    await auth.currentUser!.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );
    await auth.currentUser!.getIdToken(true);
  }

  Future<List<String>> seedInventory() async {
    final now = DateTime.now().toUtc();
    final paths = <String>[];
    final documents = <String, Map<String, dynamic>>{};
    void add(String path, Map<String, dynamic> data) {
      paths.add(path);
      documents[path] = data;
    }

    add('users/$uid', {'displayName': 'Synthetic deletion fixture'});
    for (final collection in FirebaseAccountDataRepository.privateCollections) {
      add('users/$uid/$collection/fixture', {'fixture': true});
    }
    // Force at least two batches. These are intentionally synthetic historical
    // documents: cleanup must delete, not require rewriting them to today's schema.
    for (var i = 0; i < 102; i++) {
      add('users/$uid/body_metrics/batch-$i', {'fixture': true});
    }
    add('users/$uid/chat_sessions/session', {'fixture': true});
    add('users/$uid/chat_sessions/session/messages/user', {'fixture': true});
    add('users/$uid/chat_sessions/session/messages/assistant', {
      'fixture': true,
    });
    const ticketId = 'DeletionTicket1234567';
    add('support_tickets/$ticketId', {
      'uid': uid,
      'type': 'bug',
      'title': 'Synthetic support fixture',
      'description': 'No real user data',
      'status': 'open',
      'messageCount': 1,
      'lastMessageId': 'DeletionMessage12345',
      'updatedBy': uid,
      'deleting': false,
      'createdAt': now,
      'updatedAt': now,
    });
    add('support_tickets/$ticketId/messages/message', {
      'authorUid': uid,
      'text': 'Synthetic',
    });
    add('demo_premium_accounts/$uid', {'fixture': true});
    add('support_usage/$uid', {'fixture': true});
    add('demo_premium_transactions/synthetic-$uid', {
      'uid': uid,
      'mode': 'demo',
    });
    // Subcollections exist independently of a parent document.
    add('demo_ai_usage/$uid/days/one', {'fixture': true});
    add('demo_ai_usage/$uid/days/two', {'fixture': true});
    for (final scope in FirebaseAccountDataRepository.serverScopes.entries) {
      add('${scope.key}/$uid/${scope.value}/fixture', {'fixture': true});
      add('${scope.key}/$uid', {'fixture': true});
    }
    add('user_directory/$uid', {'displayName': 'Synthetic', 'email': email});
    add('account_controls/$uid', {'status': 'active', 'reason': 'Synthetic'});
    await seed(documents);
    await seed({
      'admin_audit/deletion-retained-$uid': {
        'actorUid': 'synthetic-admin',
        'entityType': 'account_controls',
        'entityId': uid,
        'at': now,
        'changedFields': ['status'],
        'reason': 'Synthetic immutable audit fixture',
      },
    });
    return paths;
  }

  Future<void> expectRemoved(List<String> paths) async {
    for (final path in paths) {
      expect((await ownerRead(path)).statusCode, 404, reason: path);
    }
  }

  setUpAll(() {
    FirebaseCoreWeb.registerWith(webPluginRegistrar);
    FirebaseAuthWeb.registerWith(webPluginRegistrar);
    FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
    webPluginRegistrar.registerMessageHandler();
  });
  setUp(() async {
    // Each scenario owns two isolated SDK clients. Reusing apps while changing
    // users carries the previous scenario's auth/cache/write queue into the next.
    final scenario = DateTime.now().microsecondsSinceEpoch;
    app = await Firebase.initializeApp(
      name: 'account-deletion-sdk-$scenario',
      options: const FirebaseOptions(
        apiKey: 'emulator-only-fake-key',
        appId: '1:1234567890:web:deletion',
        messagingSenderId: '1234567890',
        projectId: project,
        authDomain: 'localhost',
      ),
    );
    secondApp = await Firebase.initializeApp(
      name: 'account-deletion-second-context-$scenario',
      options: app.options,
    );
    auth = FirebaseAuth.instanceFor(app: app);
    secondAuth = FirebaseAuth.instanceFor(app: secondApp);
    for (final instance in [auth, secondAuth]) {
      await instance.useAuthEmulator(
        '127.0.0.1',
        9099,
        automaticHostMapping: false,
      );
      await instance.setPersistence(Persistence.NONE);
    }
    db = FirebaseFirestore.instanceFor(app: app);
    secondDb = FirebaseFirestore.instanceFor(app: secondApp);
    for (final instance in [db, secondDb]) {
      instance.useFirestoreEmulator(
        '127.0.0.1',
        8080,
        automaticHostMapping: false,
      );
    }
    email = 'deletion-$scenario@example.com';
    await auth.createUserWithEmailAndPassword(email: email, password: password);
    await verifyEmulatorEmail(auth, projectId: project, host: '127.0.0.1');
    uid = auth.currentUser!.uid;
    await reauthenticate();
    await secondAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    accounts = FirebaseAccountDataRepository(db);
  });
  tearDown(() async {
    try {
      await Future.wait([
        db.enableNetwork(),
        secondDb.enableNetwork(),
      ]).timeout(const Duration(seconds: 5));
      await Future.wait([
        auth.signOut(),
        secondAuth.signOut(),
      ]).timeout(const Duration(seconds: 5));
    } finally {
      try {
        await Future.wait([
          db.terminate(),
          secondDb.terminate(),
        ]).timeout(const Duration(seconds: 5));
      } finally {
        await Future.wait([
          app.delete(),
          secondApp.delete(),
        ]).timeout(const Duration(seconds: 5));
      }
    }
  });

  test(
    'full client cleanup deletes known inventory and nested data, retaining tombstone and immutable audit',
    () async {
      final paths = await seedInventory();
      final requested = await accounts.requestDeletion(uid);
      expect(requested.state, AccountDeletionState.requested);
      await accounts.deleteAllUserData(uid);
      await expectRemoved(paths);
      final beforeLocal = await accounts.watchDeletion(uid).first;
      expect(beforeLocal!.checkpoint, 4);
      expect(beforeLocal.state, AccountDeletionState.cleaning);
      await accounts.markLocalDataDeleted(uid);
      final pending = await accounts.watchDeletion(uid).first;
      expect(pending!.state, AccountDeletionState.authPending);
      expect(pending.checkpoint, 5);
      expect(pending.requestedAt, requested.requestedAt);
      expect(
        (await ownerRead('admin_audit/deletion-retained-$uid')).statusCode,
        200,
      );
      await expectLater(
        db.doc('admin_audit/deletion-retained-$uid').delete(),
        denied,
      );
      await expectLater(db.doc('account_deletions/$uid').delete(), denied);
    },
  );

  test(
    'deletion request immediately denies valid product writes in another SDK context before cleanup',
    () async {
      final profiles = FirebaseHealthProfileRepository(secondDb);
      await profiles.ensureProfile(uid: uid, email: email);
      final nutrition = FirebaseNutritionRepository(
        secondDb,
        catalogLoader: () async => [],
      );
      await nutrition.addMeal(uid: uid, draft: draft());
      final chat = FirebaseChatRepository(secondDb);
      await chat.saveTurn(
        uid,
        chat.newId(),
        ChatTurn(
          id: chat.newId(),
          question: 'Fixture',
          answer: 'Fixture',
          source: ChatSource.help,
        ),
      );
      final support = FirebaseSupportRepository(secondDb);
      await support.create(
        uid,
        support.newId(),
        SupportType.bug,
        'Fixture',
        'Fixture',
        topic: SupportTopic.account,
      );
      final directory = FirebaseAdminRuntimeRepository(secondDb);
      await directory.syncDirectory(uid: uid, displayName: '', email: email);
      final premium = FirebasePremiumRepository(secondDb);
      await expectLater(
        premium.consume(uid, PremiumAiFeature.chat),
        throwsA(isA<PremiumFailure>()),
      );
      // The app no longer allocates AI quota. Exercise the still-compatible
      // legacy Rules write directly so the deletion test proves server denial.
      final now = DateTime.now();
      final legacyUsage = secondDb.doc(
        'demo_ai_usage/$uid/days/${PremiumDemoPlan.dayId(now)}',
      );
      final legacyPayload = <String, dynamic>{
        'mode': 'demo',
        'dayStart': Timestamp.fromDate(PremiumDemoPlan.dayStart(now)),
        'scans': 0,
        'chats': 1,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await legacyUsage.set(legacyPayload);
      await accounts.requestDeletion(uid);
      await expectLater(
        legacyUsage.update({
          'chats': 2,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
        denied,
      );
      await expectLater(
        nutrition.addMeal(uid: uid, draft: draft()),
        throwsA(isA<NutritionFailure>()),
      );
      await expectLater(
        chat.saveTurn(
          uid,
          chat.newId(),
          ChatTurn(
            id: chat.newId(),
            question: 'Fixture',
            answer: 'Fixture',
            source: ChatSource.help,
          ),
        ),
        throwsA(isA<ChatFailure>()),
      );
      await expectLater(
        support.create(
          uid,
          support.newId(),
          SupportType.bug,
          'Fixture',
          'Fixture',
          topic: SupportTopic.account,
        ),
        throwsA(isA<SupportFailure>()),
      );
      await expectLater(
        directory.syncDirectory(uid: uid, displayName: 'Changed', email: email),
        denied,
      );
      await expectLater(
        premium.purchaseDemo(uid, premium.newTransactionId()),
        throwsA(isA<PremiumFailure>()),
      );
      await expectLater(
        premium.consume(uid, PremiumAiFeature.scan),
        throwsA(isA<PremiumFailure>()),
      );
      // Bootstrap must not recreate the profile even after its parent is deleted.
      await db.doc('users/$uid').delete();
      await expectLater(
        profiles.ensureProfile(uid: uid, email: email),
        throwsA(isA<ProfileFailure>()),
      );
      expect((await ownerRead('users/$uid')).statusCode, 404);
    },
  );

  test(
    'write queued offline before request is rejected on reconnect after cleanup',
    () async {
      final profile = FirebaseHealthProfileRepository(secondDb);
      await profile.ensureProfile(uid: uid, email: email);
      final water = <String, dynamic>{
        'amountMl': 250,
        'consumedAt': Timestamp.now(),
        'dateKey': DateTime.now().toIso8601String().substring(0, 10),
        'timezoneOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      // Prove the payload is valid before queuing it; later rejection must be
      // the deletion guard, not an unrelated malformed fixture.
      await secondDb
          .doc('users/$uid/water_logs/valid-before-request')
          .set(water);
      await secondDb.disableNetwork().timeout(const Duration(seconds: 5));
      final offlineRef = secondDb.doc(
        'users/$uid/water_logs/offline-before-request',
      );
      // Observe latency compensation via the same real SDK snapshot path used
      // by the established offline repository integration tests. No additional
      // cache get is needed to prove that the write is pending locally.
      final pending = offlineRef
          .snapshots(includeMetadataChanges: true)
          .firstWhere((s) => s.exists && s.metadata.hasPendingWrites);
      var settled = false;
      final writeResult = offlineRef
          .set(water)
          .then<Object?>(
            (_) {
              settled = true;
              return null;
            },
            onError: (Object e) {
              settled = true;
              return e;
            },
          );
      try {
        final snapshot = await pending.timeout(const Duration(seconds: 5));
        expect(snapshot.metadata.isFromCache, true);
        expect(settled, false);
        await accounts.requestDeletion(uid).timeout(const Duration(seconds: 8));
        await accounts
            .deleteAllUserData(uid)
            .timeout(const Duration(seconds: 12));
      } finally {
        await secondDb.enableNetwork().timeout(const Duration(seconds: 5));
      }
      final error = await writeResult.timeout(const Duration(seconds: 15));
      expect(
        error,
        isA<FirebaseException>().having(
          (e) => e.code,
          'code',
          'permission-denied',
        ),
      );
      expect(
        (await ownerRead(
          'users/$uid/water_logs/offline-before-request',
        )).statusCode,
        404,
      );
      await expectLater(
        profile.ensureProfile(uid: uid, email: email),
        throwsA(isA<ProfileFailure>()),
      );
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'suspended owner cannot write products but can request and complete cleanup',
    () async {
      final paths = await seedInventory();
      await seed({
        'account_controls/$uid': {
          'status': 'suspended',
          'reason': 'Synthetic suspension',
        },
      });
      await expectLater(
        db.doc('users/$uid/water_logs/blocked').set({'amountMl': 250}),
        denied,
      );
      await expectLater(db.doc('account_controls/$uid').delete(), denied);
      final request = await accounts.requestDeletion(uid);
      expect(request.state, AccountDeletionState.requested);
      await accounts.deleteAllUserData(uid);
      await accounts.markLocalDataDeleted(uid);
      await expectRemoved(paths);
      expect(
        (await accounts.watchDeletion(uid).first)!.state,
        AccountDeletionState.authPending,
      );
      await expectLater(
        db.doc('users/$uid').set({'displayName': 'Cannot return'}),
        denied,
      );
    },
  );

  test(
    'new repository resumes partial checkpoint without skipping leftover data or falsely finalizing',
    () async {
      final paths = await seedInventory();
      await accounts.requestDeletion(uid);
      final marker = db.doc('account_deletions/$uid');
      await marker.update({
        'state': 'cleaning',
        'checkpoint': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await marker.update({
        'checkpoint': 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Simulate the process ending with partial batches and progress already 1.
      await db.doc('users/$uid/body_metrics/batch-0').delete();
      final resumed = FirebaseAccountDataRepository(secondDb);
      await expectLater(
        resumed.markLocalDataDeleted(uid),
        throwsA(isA<AccountDataFailure>()),
      );
      expect((await resumed.watchDeletion(uid).first)!.checkpoint, 1);
      await resumed.deleteAllUserData(uid);
      await expectRemoved(paths);
      await resumed.markLocalDataDeleted(uid);
      expect(
        (await resumed.watchDeletion(uid).first)!.state,
        AccountDeletionState.authPending,
      );
    },
  );

  test(
    'auth identity left intact after cleanup remains auth_pending and retry is safe',
    () async {
      final paths = await seedInventory();
      await accounts.deleteAllUserData(uid);
      await accounts.markLocalDataDeleted(uid);
      // Simulate the final Auth operation failing/not being performed. This is
      // not a network failure injection or a claim that Auth deletion succeeded.
      expect(auth.currentUser?.uid, uid);
      final before = await accounts.watchDeletion(uid).first;
      await FirebaseAccountDataRepository(secondDb).deleteAllUserData(uid);
      await FirebaseAccountDataRepository(secondDb).markLocalDataDeleted(uid);
      await expectRemoved(paths);
      final after = await accounts.watchDeletion(uid).first;
      expect(after!.state, AccountDeletionState.authPending);
      expect(after.requestedAt, before!.requestedAt);
      expect(after.checkpoint, 5);
      await expectLater(
        FirebaseHealthProfileRepository(
          db,
        ).ensureProfile(uid: uid, email: email),
        throwsA(isA<ProfileFailure>()),
      );
    },
  );

  test(
    'another verified UID cannot read, create, reset or delete victim job',
    () async {
      await accounts.requestDeletion(uid);
      await secondAuth.signOut();
      await secondAuth.createUserWithEmailAndPassword(
        email: 'other-${DateTime.now().microsecondsSinceEpoch}@example.com',
        password: password,
      );
      await verifyEmulatorEmail(
        secondAuth,
        projectId: project,
        host: '127.0.0.1',
      );
      expect(secondAuth.currentUser!.uid, isNot(uid));
      final victim = secondDb.doc('account_deletions/$uid');
      await expectLater(victim.get(server), denied);
      await expectLater(
        victim.update({
          'checkpoint': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
        denied,
      );
      await expectLater(victim.delete(), denied);
      await expectLater(
        FirebaseAccountDataRepository(secondDb).requestDeletion(uid),
        throwsA(isA<AccountDataFailure>()),
      );
    },
  );

  test(
    'successful real Auth deletion leaves retained marker auth_pending without client completed claim',
    () async {
      final paths = await seedInventory();
      await accounts.deleteAllUserData(uid);
      await accounts.markLocalDataDeleted(uid);
      await reauthenticate();
      await auth.currentUser!.delete();
      expect(auth.currentUser, isNull);
      await expectRemoved(paths);
      final marker = await ownerRead('account_deletions/$uid');
      expect(marker.statusCode, 200);
      final fields =
          (jsonDecode(marker.body) as Map<String, dynamic>)['fields'] as Map;
      expect((fields['state'] as Map)['stringValue'], 'auth_pending');
      expect(fields.containsKey('completed'), false);
      expect(fields.containsKey('serverVerified'), false);
    },
  );
}
