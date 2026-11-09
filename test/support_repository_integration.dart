// Opt-in real SDK tests; never uses production or a configurable remote host.
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
import 'package:healthmate/features/support/data/firebase_support_repository.dart';
import 'package:healthmate/features/support/models/support_models.dart';
import 'support/emulator_email_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const project = 'demo-healthmate-rules';
  const root =
      'http://127.0.0.1:8080/v1/projects/$project/databases/(default)/documents';
  if (!const bool.fromEnvironment('HEALTHMATE_EMULATOR_TESTS')) {
    throw StateError(
      'Requires explicit localhost demo Auth/Firestore emulators.',
    );
  }
  late FirebaseApp app, secondApp;
  late FirebaseAuth auth, secondAuth;
  late FirebaseFirestore db, secondDb;
  late FirebaseSupportRepository repository, secondRepository;
  late String uid;
  Map<String, dynamic> wire(Object? value) {
    if (value == null) return {'nullValue': null};
    if (value is String) return {'stringValue': value};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': '$value'};
    if (value is Timestamp) {
      final second = DateTime.fromMillisecondsSinceEpoch(
        value.seconds * 1000,
        isUtc: true,
      ).toIso8601String().split('.').first;
      return {
        'timestampValue':
            '$second.${value.nanoseconds.toString().padLeft(9, '0')}Z',
      };
    }
    if (value is DateTime) {
      return {'timestampValue': value.toUtc().toIso8601String()};
    }
    throw StateError('Only synthetic scalar fixtures are supported.');
  }

  Future<void> seed(Map<String, Map<String, dynamic>> documents) async {
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
                  (key, value) => MapEntry(key, wire(value)),
                ),
              },
            },
        ],
      }),
    );
    expect(response.statusCode, 200, reason: 'Local synthetic fixture commit');
  }

  Map<String, dynamic> ticketData({String status = 'open'}) => {
    'uid': uid,
    'type': 'bug',
    'title': 'Synthetic report',
    'description': 'Fixture only',
    'status': status,
    'createdAt': DateTime.utc(2026, 10, 1),
    'updatedAt': DateTime.utc(2026, 10, 30, 0, 0, 0, 123, 456),
    'messageCount': 0,
    'lastMessageId': '',
    'updatedBy': uid,
    'deleting': false,
  };
  Future<void> seedQuota(int count) => seed({
    'support_usage/$uid': {
      'schemaVersion': 1,
      'dayStart': SupportPolicy.dayStart(DateTime.now()),
      'count': count,
      'lastCreatedAt': DateTime.now().toUtc().subtract(
        const Duration(minutes: 2),
      ),
      'lastTicketId': 'AbCdEfGhIjKlMnOpQrSt',
      'updatedAt': DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
    },
  });
  setUpAll(() {
    FirebaseCoreWeb.registerWith(webPluginRegistrar);
    FirebaseAuthWeb.registerWith(webPluginRegistrar);
    FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
    webPluginRegistrar.registerMessageHandler();
  });
  setUp(() async {
    final suffix = DateTime.now().microsecondsSinceEpoch;
    app = await Firebase.initializeApp(
      name: 'support-$suffix',
      options: const FirebaseOptions(
        apiKey: 'emulator-fake-key',
        appId: '1:123:web:support-test',
        messagingSenderId: '123',
        projectId: project,
        authDomain: 'localhost',
      ),
    );
    auth = FirebaseAuth.instanceFor(app: app);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    await auth.setPersistence(Persistence.NONE);
    final email = 'support-$suffix@example.com';
    const password = 'Emulator-only-test123!';
    await auth.createUserWithEmailAndPassword(email: email, password: password);
    await verifyEmulatorEmail(auth, projectId: project, host: '127.0.0.1');
    uid = auth.currentUser!.uid;
    db = FirebaseFirestore.instanceFor(app: app);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
    repository = FirebaseSupportRepository(db);
    secondApp = await Firebase.initializeApp(
      name: 'support-second-$suffix',
      options: app.options,
    );
    secondAuth = FirebaseAuth.instanceFor(app: secondApp);
    await secondAuth.useAuthEmulator(
      '127.0.0.1',
      9099,
      automaticHostMapping: false,
    );
    await secondAuth.setPersistence(Persistence.NONE);
    await secondAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    secondDb = FirebaseFirestore.instanceFor(app: secondApp);
    secondDb.useFirestoreEmulator(
      '127.0.0.1',
      8080,
      automaticHostMapping: false,
    );
    secondRepository = FirebaseSupportRepository(secondDb);
  });
  tearDown(() async {
    await db.enableNetwork();
    await secondDb.enableNetwork();
    await secondAuth.signOut();
    await auth.signOut();
    await secondDb.terminate();
    await db.terminate();
    await secondApp.delete();
    await app.delete();
  });

  test(
    'create retry preserves one ticket and one quota debit; direct standalone writes fail',
    () async {
      final id = repository.newId();
      await repository.create(
        uid,
        id,
        SupportType.bug,
        'Fixture report',
        'Fixture body',
        topic: SupportTopic.nutrition,
      );
      expect((await db.doc('support_usage/$uid').get()).data()!['count'], 1);
      expect(
        (await db.doc('support_tickets/$id').get()).data()!['topic'],
        'nutrition',
      );
      expect(
        (await repository.watchTicket(uid, id).first)?.topic,
        SupportTopic.nutrition,
      );
      await expectLater(
        repository.create(
          uid,
          id,
          SupportType.bug,
          'Fixture report',
          'Fixture body',
          topic: SupportTopic.premium,
        ),
        throwsA(isA<SupportFailure>()),
      );
      await expectLater(
        repository.create(
          uid,
          id,
          SupportType.suggestion,
          'Fixture report',
          'Fixture body',
          topic: SupportTopic.nutrition,
        ),
        throwsA(isA<SupportFailure>()),
      );
      await seedQuota(3);
      await repository.create(
        uid,
        id,
        SupportType.bug,
        'Fixture report',
        'Fixture body',
        topic: SupportTopic.nutrition,
      );
      expect(
        (await db
                .doc('support_usage/$uid')
                .get(const GetOptions(source: Source.server)))
            .data()!['count'],
        3,
      );
      expect(
        (await repository.watchTicketPage(uid).first).tickets.map((t) => t.id),
        [id],
      );
      await expectLater(
        repository.create(
          uid,
          repository.newId(),
          SupportType.bug,
          'Other',
          'Fixture',
          topic: SupportTopic.other,
        ),
        throwsA(isA<SupportFailure>()),
      );
      await expectLater(
        db.doc('support_usage/$uid').delete(),
        throwsA(isA<FirebaseException>()),
      );
      await expectLater(
        db.doc('support_tickets/${repository.newId()}').set(ticketData()),
        throwsA(isA<FirebaseException>()),
      );
    },
  );
  test(
    'two independent SDK contexts cannot overdraw the final new-ticket slot',
    () async {
      await seedQuota(2);
      Future<bool> attempt(FirebaseSupportRepository repo) async {
        try {
          await repo.create(
            uid,
            repo.newId(),
            SupportType.suggestion,
            'Synthetic suggestion',
            'Fixture',
            topic: SupportTopic.other,
          );
          return true;
        } on SupportFailure {
          return false;
        }
      }

      final outcomes = await Future.wait([
        attempt(repository),
        attempt(secondRepository),
      ]);
      expect(outcomes.where((success) => success), hasLength(1));
      expect(
        (await db
                .doc('support_usage/$uid')
                .get(const GetOptions(source: Source.server)))
            .data()!['count'],
        3,
      );
      expect(
        (await repository.watchTicketPage(uid).first).tickets,
        hasLength(1),
      );
    },
  );
  test(
    'seventy historical tickets page25/25/20 by timestamp and ID; deleted anchor still advances',
    () async {
      final ids = [for (var i = 0; i < 70; i++) '$i'.padLeft(20, 'A')]
        ..sort((a, b) => b.compareTo(a));
      await seed({
        for (final id in ids)
          'support_tickets/$id': {
            ...ticketData(),
            // Include a fractional timestamp on all rows to exercise the
            // seconds/nanoseconds + document-ID cursor with timestamp ties.
            'updatedAt': Timestamp(1793318400, 123456000),
          },
      });
      final first = await repository.watchTicketPage(uid).first;
      expect(first.tickets, hasLength(25));
      expect(first.tickets.every((ticket) => ticket.topic == null), isTrue);
      expect(first.nextCursor, isNotNull);
      expect(first.nextCursor!.nanoseconds, 123456000);
      final deletion = await http.delete(
        Uri.parse('$root/support_tickets/${first.nextCursor!.id}'),
        headers: {'Authorization': 'Bearer owner'},
      );
      expect(deletion.statusCode, 200);
      final second = await repository
          .watchTicketPage(uid, after: first.nextCursor)
          .first;
      final third = await repository
          .watchTicketPage(uid, after: second.nextCursor)
          .first;
      expect(second.tickets, hasLength(25));
      expect(third.tickets, hasLength(20));
      expect(third.nextCursor, isNull);
      expect(
        [
          ...first.tickets,
          ...second.tickets,
          ...third.tickets,
        ].map((t) => t.id),
        ids,
      );
    },
  );
  test(
    'full daily quota does not block an existing resolved thread reply or idempotent reply retry',
    () async {
      final id = repository.newId(), messageId = repository.newId();
      await seed({'support_tickets/$id': ticketData(status: 'resolved')});
      await seedQuota(3);
      await repository.reply(uid, id, messageId, 'Synthetic follow-up');
      await repository.reply(uid, id, messageId, 'Synthetic follow-up');
      await expectLater(
        repository.reply(uid, id, messageId, 'Changed follow-up'),
        throwsA(isA<SupportFailure>()),
      );
      final thread = await repository.watchTicket(uid, id).first;
      expect(thread!.status, SupportStatus.open);
      expect(thread.messageCount, 1);
      expect((await repository.watchMessages(uid, id).first), hasLength(1));
      expect(
        (await db
                .doc('support_usage/$uid')
                .get(const GetOptions(source: Source.server)))
            .data()!['count'],
        3,
      );
    },
  );
}
