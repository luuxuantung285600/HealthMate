import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/chatbot/data/chat_assistant.dart';
import 'package:healthmate/features/chatbot/data/cloudflare_chat_assistant.dart';
import 'package:healthmate/features/chatbot/domain/chat_data_reader.dart';
import 'package:healthmate/features/chatbot/domain/personal_chat_context.dart';
import 'package:healthmate/features/chatbot/models/assistant_request.dart';
import 'package:healthmate/features/chatbot/models/chat_models.dart';
import 'package:healthmate/features/chatbot/providers/chat_providers.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'support/fake_activity_repository.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_chat_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_nutrition_target_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/test_app.dart';

final today = DateTime(2026, 10, 25, 12);
const endpoint = 'https://healthmate.example.workers.dev/v1/chat';
AssistantConversation conversation([
  String question = 'Tôi không thích món vừa gợi ý, có món khác không?',
]) => AssistantConversation(
  question: question,
  history: const [],
  today: today,
  selectedDate: today,
);
Stream<List<int>> bytes(String value) =>
    Stream.fromIterable(utf8.encode(value).map((b) => [b]));
const complete =
    'data: {"choices":[{"delta":{"content":"Chào bạn"},"finish_reason":null}]}\n\n'
    'data: {"choices":[{"delta":{},"finish_reason":"stop"}]}\n\ndata: [DONE]\n\n';

class FakeAssistant implements ChatAssistant {
  final conversations = <AssistantConversation>[];
  StreamController<String>? pending;
  bool cancelled = false;
  @override
  Stream<String> reply(
    AssistantConversation conversation, {
    required String uid,
    required bool Function() isCurrent,
    required Future<List<ChatDataResult>> Function(List<ChatDataRequest>)
    readData,
  }) {
    conversations.add(conversation);
    if (pending == null) {
      return Stream.value('Bạn có thể chọn món khác trong danh mục.');
    }
    return Stream.multi((c) {
      final sub = pending!.stream.listen(
        c.add,
        onError: c.addError,
        onDone: c.close,
      );
      c.onCancel = () {
        cancelled = true;
        sub.cancel().ignore();
      };
    });
  }
}

class TrackingClient extends http.BaseClient {
  bool closed = false;
  final Future<http.StreamedResponse> Function(http.BaseRequest) handle;
  TrackingClient(this.handle);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handle(request);
  @override
  void close() {
    closed = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!const bool.fromEnvironment('HEALTHMATE_CAPTURE_CHAT_API')) return;
    final font = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/inter/Inter-$weight.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  test('planner requests reject UID, invalid/future/wide dates and writes', () {
    for (final raw in [
      {'kind': 'delete'},
      {
        'kind': 'nutrition',
        'startDate': '2026-10-25',
        'endDate': '2026-10-25',
        'uid': 'victim',
      },
      {'kind': 'nutrition', 'startDate': '2026-02-30', 'endDate': '2026-10-25'},
      {'kind': 'nutrition', 'startDate': '2026-10-26', 'endDate': '2026-10-26'},
      {'kind': 'nutrition', 'startDate': '2026-10-01', 'endDate': '2026-10-25'},
      {'kind': 'foods', 'query': '', 'grams': double.nan},
    ]) {
      expect(
        () => ChatDataRequest.parse(raw, today),
        throwsA(isA<ChatFailure>()),
      );
    }
  });
  test(
    'history contains only last three role-separated turns, no message metadata',
    () {
      final history = List.generate(
        10,
        (i) => ChatMessage(
          id: 'private-id',
          isUser: i.isEven,
          text: i == 9 ? 'a' * 6000 : 'message $i',
          sequence: i,
          source: ChatSource.ai,
        ),
      );
      final request = AssistantConversation(
        question: 'Còn đạm?',
        history: history,
        today: today,
        selectedDate: today,
      ).body('plan');
      final wire = jsonEncode(request);
      expect((request['history'] as List).length, 6);
      expect(wire, contains('message 4'));
      expect(wire, isNot(contains('message 0')));
      expect(wire, isNot(contains('private-id')));
      expect(wire, isNot(contains('sequence')));
      expect(
        ((request['history'] as List).last as Map)['content'].length,
        1200,
      );
    },
  );
  test(
    'UTF-8 split across every byte is decoded and reasoning is hidden',
    () async {
      expect(await decodeChatEvents(bytes(complete)).join(), 'Chào bạn');
      final thought =
          'data: {"response":"<thi"}\n\ndata: {"response":"nk>private reasoning"}\n\n'
          'data: {"response":"</think>Xin chào"}\n\ndata: [DONE]\n\n';
      expect(await decodeChatEvents(bytes(thought)).join(), 'Xin chào');
    },
  );
  test('conversation context omits duplicated app reference tables', () {
    final history = [
      const ChatMessage(
        id: 'u',
        isUser: true,
        text: 'Hôm nay tôi ăn bao nhiêu?',
        sequence: 0,
        source: ChatSource.ai,
      ),
      const ChatMessage(
        id: 'a',
        isUser: false,
        text:
            'Bạn đã ghi 500 kcal.\n\nSố liệu tra cứu từ HealthMate:\nDUPLICATE_REFERENCE_TABLE',
        sequence: 1,
        source: ChatSource.ai,
      ),
    ];
    final body = AssistantConversation(
      question: 'Còn đạm thì sao?',
      history: history,
      today: today,
      selectedDate: today,
    ).body('plan');
    expect(jsonEncode(body), contains('Bạn đã ghi 500 kcal.'));
    expect(jsonEncode(body), isNot(contains('DUPLICATE_REFERENCE_TABLE')));
  });
  test(
    'truncated and token-limited streams are not complete answers',
    () async {
      for (final s in [
        'data: {"response":"dở"}\n\n',
        'data: {"choices":[{"delta":{},"finish_reason":"length"}]}\n\n',
        'data: {"error":"private provider error"}\n\n',
      ]) {
        await expectLater(
          decodeChatEvents(bytes(s)).toList(),
          throwsA(isA<ChatFailure>()),
        );
      }
    },
  );
  test(
    'token envelopes above 32 KB do not reject a short valid answer',
    () async {
      final frame =
          'data: ${jsonEncode({
            'response': 'a',
            'p': 'padding' * 30,
            'usage': {'total_tokens': 500},
          })}\n\n';
      final sse = '${frame * 300}data: [DONE]\n\n';
      expect(utf8.encode(sse).length, greaterThan(32000));
      expect(
        await decodeChatEvents(Stream.value(utf8.encode(sse))).join(),
        'a' * 300,
      );
    },
  );
  test('oversized wire or individual events still fail closed', () async {
    for (final sse in [
      ':${'x' * (2 * 1024 * 1024)}\n\n',
      'data: ${jsonEncode({'response': 'x' * 16001})}\n\n',
    ]) {
      await expectLater(
        decodeChatEvents(Stream.value(utf8.encode(sse))).join(),
        throwsA(isA<ChatFailure>()),
      );
    }
  });
  test(
    'API plans first, reads only requested data, and sends credentials only as headers',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((r) async {
        requests.add(r);
        expect(r.followRedirects, false);
        final body = jsonDecode(r.body) as Map;
        if (body['phase'] == 'plan') {
          return http.Response(
            '{"requests":[{"kind":"water","startDate":"2026-10-25","endDate":"2026-10-25"}]}',
            200,
          );
        }
        expect(body['results'][0]['text'], 'Nước đã ghi: 250 ml.');
        return http.Response.bytes(utf8.encode(complete), 200);
      });
      final assistant = CloudflareChatAssistant(
        endpoint: Uri.parse(endpoint),
        clientFactory: () => client,
        credentials: (_) async =>
            const ChatApiCredentials('private-auth', 'private-appcheck'),
      );
      var reads = 0;
      final result = await assistant
          .reply(
            conversation('Nước hôm nay?'),
            uid: 'private-uid',
            isCurrent: () => true,
            readData: (r) async {
              reads++;
              expect(r.single.kind, 'water');
              return [ChatDataResult(r.single, 'Nước đã ghi: 250 ml.')];
            },
          )
          .join();
      expect(reads, 1);
      expect(requests.length, 2);
      expect(
        requests.map((r) => r.headers['x-healthmate-request-id']).toSet(),
        hasLength(1),
      );
      expect(
        requests.first.headers['x-healthmate-request-id'],
        matches(RegExp(r'^[A-Za-z0-9_-]{16,80}$')),
      );
      expect(result, contains('250 ml'));
      for (final r in requests) {
        expect(r.headers['authorization'], 'Bearer private-auth');
        expect(r.body, isNot(contains('private-auth')));
        expect(r.body, isNot(contains('private-uid')));
        expect(r.body, isNot(contains('private-appcheck')));
      }
    },
  );
  test('general questions do not prefetch personal data', () async {
    final assistant = CloudflareChatAssistant(
      endpoint: Uri.parse(endpoint),
      credentials: (_) async => const ChatApiCredentials('auth', 'check'),
      clientFactory: () => MockClient(
        (r) async => http.Response.bytes(
          utf8.encode(
            jsonDecode(r.body)['phase'] == 'plan'
                ? '{"requests":[]}'
                : complete,
          ),
          200,
        ),
      ),
    );
    await assistant
        .reply(
          conversation(),
          uid: 'u',
          isCurrent: () => true,
          readData: (r) async {
            expect(r, isEmpty);
            return [];
          },
        )
        .drain<void>();
  });
  for (final status in [401, 429, 503]) {
    test('HTTP $status has safe error text and no tool read', () async {
      final assistant = CloudflareChatAssistant(
        endpoint: Uri.parse(endpoint),
        credentials: (_) async => const ChatApiCredentials('auth', 'check'),
        clientFactory: () =>
            MockClient((_) async => http.Response('SECRET', status)),
      );
      await expectLater(
        assistant
            .reply(
              conversation(),
              uid: 'u',
              isCurrent: () => true,
              readData: (_) async => fail('must not read'),
            )
            .toList(),
        throwsA(
          isA<ChatFailure>().having(
            (e) => e.message,
            'safe message',
            isNot(contains('SECRET')),
          ),
        ),
      );
    });
  }
  test(
    'malformed or excessive planner output never reads a repository',
    () async {
      final assistant = CloudflareChatAssistant(
        endpoint: Uri.parse(endpoint),
        credentials: (_) async => const ChatApiCredentials('auth', 'check'),
        clientFactory: () => MockClient(
          (_) async => http.Response('{"requests":[{"kind":"write"}]}', 200),
        ),
      );
      await expectLater(
        assistant
            .reply(
              conversation(),
              uid: 'u',
              isCurrent: () => true,
              readData: (_) async => fail('must not read'),
            )
            .toList(),
        throwsA(isA<ChatFailure>()),
      );
    },
  );
  test(
    'account changes during credentials silently discard the old response before transmission',
    () async {
      var active = true, calls = 0;
      final assistant = CloudflareChatAssistant(
        endpoint: Uri.parse(endpoint),
        credentials: (_) async {
          active = false;
          return const ChatApiCredentials('auth', 'check');
        },
        clientFactory: () => MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
      );
      await expectLater(
        assistant
            .reply(
              conversation(),
              uid: 'u',
              isCurrent: () => active,
              readData: (_) async => [],
            )
            .toList(),
        completion(isEmpty),
      );
      expect(calls, 0);
    },
  );
  test('account change after a personal read blocks the answer upload', () async {
    var active = true, calls = 0;
    final assistant = CloudflareChatAssistant(
      endpoint: Uri.parse(endpoint),
      credentials: (_) async => const ChatApiCredentials('auth', 'check'),
      clientFactory: () => MockClient((_) async {
        calls++;
        return http.Response(
          '{"requests":[{"kind":"water","startDate":"2026-10-25","endDate":"2026-10-25"}]}',
          200,
        );
      }),
    );
    final result = await assistant
        .reply(
          conversation(),
          uid: 'u',
          isCurrent: () => active,
          readData: (requests) async {
            active = false;
            return [
              ChatDataResult(requests.single, 'Old account private data'),
            ];
          },
        )
        .toList();
    expect(result, isEmpty);
    expect(calls, 1);
  });
  test(
    'cancel immediately closes transport while request is pending',
    () async {
      final pending = Completer<http.StreamedResponse>();
      final started = Completer<void>();
      final client = TrackingClient((_) {
        started.complete();
        return pending.future;
      });
      final assistant = CloudflareChatAssistant(
        endpoint: Uri.parse(endpoint),
        credentials: (_) async => const ChatApiCredentials('auth', 'check'),
        clientFactory: () => client,
      );
      final sub = assistant
          .reply(
            conversation(),
            uid: 'u',
            isCurrent: () => true,
            readData: (_) async => [],
          )
          .listen((_) {});
      await started.future;
      await sub.cancel();
      expect(client.closed, true);
      pending.complete(
        http.StreamedResponse(
          Stream.value(utf8.encode('{"requests":[]}')),
          200,
        ),
      );
    },
  );
  test('non-HTTPS endpoints never receive credentials', () async {
    final assistant = CloudflareChatAssistant(
      endpoint: Uri.parse('http://unsafe.example/v1/chat'),
      credentials: (_) async => fail('must not fetch tokens'),
    );
    await expectLater(
      assistant
          .reply(
            conversation(),
            uid: 'u',
            isCurrent: () => true,
            readData: (_) async => [],
          )
          .toList(),
      throwsA(isA<ChatFailure>()),
    );
  });
  test(
    'data reader only reads requested source and rejects old UID after await',
    () async {
      final meals = FakeNutritionRepository();
      final water = FakeWaterRepository();
      final activity = FakeActivityRepository();
      final profile = FakeHealthProfileRepository();
      final targets = FakeNutritionTargetRepository();
      addTearDown(meals.dispose);
      addTearDown(water.dispose);
      addTearDown(activity.dispose);
      final reader = ChatDataReader(
        personal: PersonalChatContext(
          nutrition: meals,
          water: water,
          activity: activity,
          targets: targets,
          profile: profile,
        ),
        loadCatalog: () async => [],
      );
      final r = ChatDataRequest(kind: 'water', start: today, end: today);
      final result = await reader.read('u', [r], today, () => true);
      expect(result.single.text, contains('chưa có bản ghi'));
      expect(meals.rangeCalls, 0);
      await expectLater(
        reader.read('u', [r], today, () => false),
        throwsA(isA<ChatFailure>()),
      );
    },
  );
  test(
    'food choices use catalog math/source, exclude faulty USDA branch and private identifiers',
    () async {
      final meals = FakeNutritionRepository();
      final water = FakeWaterRepository();
      final activity = FakeActivityRepository();
      addTearDown(meals.dispose);
      addTearDown(water.dispose);
      addTearDown(activity.dispose);
      FoodCatalogItem food(FoodDataSource source) => FoodCatalogItem(
        id: 'private-catalog-id',
        name: 'Cơm chín',
        category: 'grain',
        servingBasis: ServingBasis.per100g,
        sourceLabel: 'Nguồn thử tổng hợp',
        isEstimated: true,
        dataSource: source,
        per100g: const NutritionTotals(kcal: 130, proteinG: 2.7),
      );
      final reader = ChatDataReader(
        personal: PersonalChatContext(
          nutrition: meals,
          water: water,
          activity: activity,
          targets: FakeNutritionTargetRepository(),
          profile: FakeHealthProfileRepository(),
        ),
        loadCatalog: () async => [
          food(FoodDataSource.local),
          food(FoodDataSource.usda),
        ],
      );
      final result = await reader.read(
        'u',
        [const ChatDataRequest(kind: 'foods', query: 'com', grams: 150)],
        today,
        () => true,
      );
      expect(result.single.text, contains('195 kcal'));
      expect(result.single.text, contains('ước tính'));
      expect(result.single.text, isNot(contains('private-catalog-id')));
      expect('Cơm chín'.allMatches(result.single.text).length, 1);
    },
  );
  testWidgets(
    'free-form consent, multi-turn history and idempotent retry work',
    (t) async {
      final assistant = FakeAssistant();
      final repo = FakeChatRepository();
      final c = await pumpApp(
        t,
        chatAssistant: assistant,
        chatApiEndpoint: endpoint,
        chatRepository: repo,
        dashboardNow: today,
        featureFlags: const AppFeatureFlags(chatbotEnabled: true),
      );
      c.read(appRouterProvider).go(AppRoutes.chat);
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const ValueKey('chat-input')),
        'Tôi muốn đổi món tối, có gì khác không?',
      );
      await t.tap(find.byKey(const ValueKey('chat-send')));
      await t.pumpAndSettle();
      expect(assistant.conversations, isEmpty);
      await t.tap(find.text('Để sau'));
      await t.pumpAndSettle();
      expect(repo.saveCalls, 0);
      await t.tap(find.byKey(const ValueKey('chat-send')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('chat-accept-assistant')));
      await t.pumpAndSettle();
      expect(assistant.conversations.single.question, contains('đổi món tối'));
      repo.failAfterSave = true;
      final ctrl = c.read(chatControllerProvider.notifier);
      await ctrl.send(
        'Còn món nào nhiều đạm hơn?',
        today,
        allowAssistant: true,
      );
      await t.pumpAndSettle();
      expect(assistant.conversations.last.history.length, 2);
      expect(c.read(chatControllerProvider).canRetry, true);
      repo.failAfterSave = false;
      await ctrl.retry();
      await t.pumpAndSettle();
      expect(assistant.conversations.length, 2);
      expect(c.read(chatControllerProvider).messages.length, 4);
      expect(
        c.read(chatControllerProvider).messages.last.source,
        ChatSource.ai,
      );
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'local mode never calls either AI and direct free-form send requires consent',
    (t) async {
      final assistant = FakeAssistant();
      final knowledge = FakeKnowledgeService();
      final c = await pumpApp(
        t,
        chatAssistant: assistant,
        chatApiEndpoint: endpoint,
        knowledgeService: knowledge,
        dashboardNow: today,
        featureFlags: const AppFeatureFlags(chatbotEnabled: true),
      );
      c.read(appRouterProvider).go(AppRoutes.chat);
      await t.pumpAndSettle();
      final ctrl = c.read(chatControllerProvider.notifier);
      expect(await ctrl.send('Bữa tối ăn gì?', today), false);
      await t.tap(find.byKey(const ValueKey('chat-local-only')));
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const ValueKey('chat-input')),
        'Protein là gì?',
      );
      await t.tap(find.byKey(const ValueKey('chat-send')));
      await t.pumpAndSettle();
      expect(assistant.conversations, isEmpty);
      expect(knowledge.topics, isEmpty);
      expect(
        c.read(chatControllerProvider).messages.last.source,
        ChatSource.help,
      );
    },
  );
  testWidgets(
    'quick journal chips read real data without spending either AI quota',
    (t) async {
      final assistant = FakeAssistant();
      final knowledge = FakeKnowledgeService();
      final repo = FakeChatRepository();
      final c = await pumpApp(
        t,
        chatAssistant: assistant,
        chatApiEndpoint: endpoint,
        knowledgeService: knowledge,
        chatRepository: repo,
        dashboardNow: today,
        featureFlags: const AppFeatureFlags(chatbotEnabled: true),
      );
      c.read(appRouterProvider).go(AppRoutes.chat);
      await t.pumpAndSettle();
      final chip = find.widgetWithText(ActionChip, 'Kcal đã ghi');
      await t.ensureVisible(chip);
      await t.tap(chip);
      await t.pumpAndSettle();
      expect(assistant.conversations, isEmpty);
      expect(knowledge.topics, isEmpty);
      expect(repo.saveCalls, 1);
      expect(
        c.read(chatControllerProvider).messages.last.source,
        ChatSource.journal,
      );
      expect(
        c.read(chatControllerProvider).messages.last.text,
        contains('chưa có bản ghi'),
      );
      expect(find.text('Đồng ý'), findsNothing);
    },
  );
  testWidgets('cancel and account switch discard late flexible answers', (
    t,
  ) async {
    final assistant = FakeAssistant()..pending = StreamController<String>();
    final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
    final repo = FakeChatRepository();
    final c = await pumpApp(
      t,
      chatAssistant: assistant,
      chatApiEndpoint: endpoint,
      repository: auth,
      chatRepository: repo,
      dashboardNow: today,
      featureFlags: const AppFeatureFlags(chatbotEnabled: true),
    );
    c.read(appRouterProvider).go(AppRoutes.chat);
    await t.pumpAndSettle();
    final ctrl = c.read(chatControllerProvider.notifier);
    final sending = ctrl.send('Gợi ý bữa tối?', today, allowAssistant: true);
    await t.pump();
    ctrl.cancel();
    await t.pump();
    await sending;
    expect(assistant.cancelled, true);
    expect(repo.saveCalls, 0);
    assistant.pending!.close().ignore();
    assistant.pending = StreamController<String>();
    assistant.cancelled = false;
    final late = ctrl.send('Còn đạm?', today, allowAssistant: true);
    await t.pump();
    await auth.signOut();
    await t.pumpAndSettle();
    await late;
    expect(repo.saveCalls, 0);
    expect(assistant.cancelled, true);
    assistant.pending!.close().ignore();
    expect(t.takeException(), isNull);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('flexible chat and consent fit 360px at scale $scale', (
      t,
    ) async {
      final root = GlobalKey();
      final c = await pumpApp(
        t,
        size: const Size(360, 800),
        textScale: scale,
        captureKey: root,
        chatAssistant: FakeAssistant(),
        chatApiEndpoint: endpoint,
        dashboardNow: today,
        featureFlags: const AppFeatureFlags(chatbotEnabled: true),
      );
      c.read(appRouterProvider).go(AppRoutes.chat);
      await t.pumpAndSettle();
      Future<void> capture(String name) async {
        if (!const bool.fromEnvironment('HEALTHMATE_CAPTURE_CHAT_API')) return;
        await t.runAsync(() async {
          final image =
              await (root.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('docs/ux/chatbot-api').create(recursive: true);
          await File(
            'docs/ux/chatbot-api/$name-$scale.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await t.enterText(
        find.byKey(const ValueKey('chat-input')),
        'Có món nào nhiều đạm cho bữa tối?',
      );
      await t.tap(find.byKey(const ValueKey('chat-send')));
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chat-accept-assistant')),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
      await capture('consent');
      await t.tap(find.byKey(const ValueKey('chat-accept-assistant')));
      await t.pumpAndSettle();
      expect(c.read(chatControllerProvider).messages.length, 2);
      expect(t.takeException(), isNull);
      await capture('conversation');
    });
  }
}
