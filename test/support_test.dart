import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/support/data/support_repository.dart';
import 'package:healthmate/features/support/models/support_models.dart';
import 'package:healthmate/features/support/presentation/support_screen.dart';
import 'package:healthmate/features/support/providers/support_providers.dart';

const user = AuthUser(
  uid: 'alice',
  email: 'alice@example.com',
  emailVerified: true,
);
final now = DateTime.utc(2026, 10, 30, 14);
SupportTicket ticket({
  SupportStatus status = SupportStatus.resolved,
  SupportTopic? topic,
}) => SupportTicket(
  id: 'AbCdEfGhIjKlMnOpQrSt',
  uid: 'alice',
  type: SupportType.bug,
  topic: topic,
  title: 'Không lưu được bữa sáng',
  description: 'Bấm lưu nhưng không thấy món.',
  status: status,
  createdAt: now,
  updatedAt: now,
  messageCount: 1,
);

class FakeSupport implements SupportRepository {
  bool fail = false, listError = false;
  final created = <String>[], replied = <String>[];
  final createdTopics = <SupportTopic>[];
  int ids = 0;
  int ticketWatches = 0;
  SupportTopic? ticketTopic;
  List<SupportTicketPage>? pages;
  final pageRequests = <SupportTicketCursor?>[];
  @override
  Stream<SupportTicketPage> watchTicketPage(
    String uid, {
    SupportTicketCursor? after,
  }) {
    pageRequests.add(after);
    ticketWatches++;
    return listError
        ? Stream.error(const SupportFailure('Mất kết nối thử nghiệm'))
        : Stream.value(
            pages?[after == null ? 0 : 1] ??
                const SupportTicketPage(tickets: []),
          );
  }

  @override
  String newId() => '${++ids}'.padLeft(20, 'A');
  @override
  Stream<List<SupportTicket>> watchTickets(String uid) {
    ticketWatches++;
    return listError
        ? Stream.error(const SupportFailure('Mất kết nối thử nghiệm'))
        : Stream.value([]);
  }

  @override
  Stream<SupportTicket?> watchTicket(String uid, String id) =>
      Stream.value(ticket(topic: ticketTopic));
  @override
  Stream<List<SupportMessage>> watchMessages(String uid, String id) =>
      Stream.value([
        SupportMessage(
          id: 'reply',
          text: 'Bạn vui lòng cập nhật ứng dụng rồi thử lại.',
          isAdmin: true,
          createdAt: now,
          sequence: 1,
        ),
      ]);
  @override
  Future<void> create(
    String uid,
    String id,
    SupportType type,
    String title,
    String description, {
    required SupportTopic topic,
  }) async {
    created.add(id);
    createdTopics.add(topic);
    if (fail) throw const SupportFailure('Chưa xác nhận gửi yêu cầu');
  }

  @override
  Future<void> reply(
    String uid,
    String ticketId,
    String messageId,
    String text,
  ) async {
    replied.add(messageId);
    if (fail) throw const SupportFailure('Chưa xác nhận gửi tin nhắn');
  }
}

Future<void> open(
  WidgetTester tester,
  FakeSupport repository, {
  Widget? home,
  double scale = 1,
  Stream<AuthUser?>? auth,
}) async {
  tester.view.physicalSize = const Size(320, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWith((ref) => auth ?? Stream.value(user)),
        supportRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: home ?? const SupportScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      key == 'support-topic' ? -300 : 300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> fillTicket(WidgetTester tester) async {
  await tapKey(tester, 'new-support-ticket');
  await tapKey(tester, 'support-topic');
  await tester.tap(find.text(SupportTopic.nutrition.label).last);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('support-title')),
    'Lỗi ghi nhận bữa sáng',
  );
  await tester.enterText(
    find.byKey(const ValueKey('support-description')),
    'Bấm lưu nhưng không thấy món.',
  );
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
}

void main() {
  test(
    'support topics have stable codes and preserve unknown historical topics as unclassified',
    () {
      expect(SupportTopic.values.map((topic) => topic.code), [
        'account',
        'premium',
        'nutrition',
        'activity',
        'tracking',
        'food_scanner',
        'chatbot',
        'other',
      ]);
      for (final topic in SupportTopic.values) {
        expect(SupportTopic.fromCode(topic.code), same(topic));
      }
      for (final missing in [
        null,
        '',
        'invalid',
        42,
        {'code': 'account'},
      ]) {
        expect(SupportTopic.fromCode(missing), isNull);
      }
      expect(ticket().topicLabel, 'Chưa phân loại');
      expect(ticket(topic: SupportTopic.other).topicLabel, 'Vấn đề khác');
    },
  );

  testWidgets(
    'a filled support request cannot send until its topic is selected',
    (tester) async {
      final repository = FakeSupport();
      await open(tester, repository);
      await tapKey(tester, 'new-support-ticket');
      await tester.enterText(
        find.byKey(const ValueKey('support-title')),
        'Cần hỗ trợ',
      );
      await tester.enterText(
        find.byKey(const ValueKey('support-description')),
        'Nội dung kiểm thử',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tapKey(tester, 'send-support-ticket');
      expect(repository.created, isEmpty);
      expect(repository.ids, 0);
      expect(find.textContaining('Hãy chọn chủ đề'), findsOneWidget);
      await tapKey(tester, 'support-topic');
      await tester.tap(find.text(SupportTopic.premium.label).last);
      await tester.pumpAndSettle();
      await tapKey(tester, 'send-support-ticket');
      expect(repository.created, hasLength(1));
      expect(repository.createdTopics, [SupportTopic.premium]);
    },
  );

  testWidgets('topic appears in both ticket history and thread', (
    tester,
  ) async {
    final repository = FakeSupport()
      ..ticketTopic = SupportTopic.premium
      ..pages = [
        SupportTicketPage(tickets: [ticket(topic: SupportTopic.premium)]),
      ];
    await open(tester, repository);
    expect(find.textContaining(SupportTopic.premium.label), findsOneWidget);
    await tapKey(tester, 'support-AbCdEfGhIjKlMnOpQrSt');
    expect(find.text('Chủ đề: ${SupportTopic.premium.label}'), findsOneWidget);
  });

  testWidgets(
    'all topics fit at 320px and 200 percent text; choosing only a topic protects the draft',
    (tester) async {
      await open(tester, FakeSupport(), scale: 2);
      await tapKey(tester, 'new-support-ticket');
      for (final topic in SupportTopic.values) {
        await tapKey(tester, 'support-topic');
        final option = find.text(topic.label);
        await tester.scrollUntilVisible(
          option,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(option.last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ nội dung đang soạn?'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục soạn'));
      await tester.pumpAndSettle();
      final dropdown = tester.widget<DropdownButtonFormField<SupportTopic>>(
        find.byKey(const ValueKey('support-topic')),
      );
      expect(dropdown.initialValue, SupportTopic.other);
    },
  );

  test('same-day quota preserves count from SDK local DateTime timestamps', () {
    final instant = DateTime.utc(2026, 10, 31, 5);
    final utcStart = SupportPolicy.dayStart(instant);
    final localStart = utcStart.toLocal();
    expect(localStart.isUtc, isFalse);
    expect(
      SupportPolicy.usedToday(
        instant: instant,
        previousDayStart: localStart,
        previousCount: 2,
      ),
      2,
    );
    expect(
      SupportPolicy.usedToday(
        instant: instant.add(const Duration(days: 1)),
        previousDayStart: localStart,
        previousCount: 3,
      ),
      0,
    );
  });
  test(
    'support new-ticket policy resets at Vietnam midnight without limiting replies',
    () {
      expect(SupportPolicy.dailyTicketLimit, 3);
      expect(SupportPolicy.createInterval, const Duration(seconds: 60));
      expect(SupportPolicy.pageSize, 25);
      expect(
        SupportPolicy.dayStart(DateTime.utc(2026, 10, 30, 16, 59)),
        DateTime.utc(2026, 10, 29, 17),
      );
      expect(
        SupportPolicy.dayStart(DateTime.utc(2026, 10, 30, 17)),
        DateTime.utc(2026, 10, 30, 17),
      );
    },
  );
  testWidgets(
    'ticket history advances by cursor and returns to newest without losing old threads',
    (tester) async {
      const cursor = SupportTicketCursor(
        seconds: 1793336400,
        nanoseconds: 123456789,
        id: 'boundary',
      );
      SupportTicket row(String id) => SupportTicket(
        id: id,
        uid: 'alice',
        type: SupportType.bug,
        title: 'Yêu cầu $id',
        description: 'Fixture',
        status: SupportStatus.open,
        createdAt: now,
        updatedAt: now,
        messageCount: 0,
      );
      final repository = FakeSupport()
        ..pages = [
          SupportTicketPage(tickets: [row('mới')], nextCursor: cursor),
          SupportTicketPage(tickets: [row('cũ hơn 50')]),
        ];
      await open(tester, repository);
      expect(find.text('Yêu cầu mới'), findsOneWidget);
      await tapKey(tester, 'support-older');
      expect(repository.pageRequests.last, same(cursor));
      expect(find.text('Trang 2'), findsOneWidget);
      expect(find.text('Yêu cầu cũ hơn 50'), findsOneWidget);
      await tapKey(tester, 'support-newer');
      expect(find.text('Trang 1'), findsOneWidget);
      expect(find.text('Yêu cầu mới'), findsOneWidget);
    },
  );
  testWidgets(
    'hidden navigation branch releases support listeners and reconnects on return',
    (tester) async {
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      final repository = FakeSupport();
      await open(
        tester,
        repository,
        home: ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (context, value, child) =>
              TickerMode(enabled: value, child: const SupportScreen()),
        ),
      );
      expect(repository.ticketWatches, 1);
      visible.value = false;
      await tester.pumpAndSettle();
      expect(find.text('Yêu cầu của bạn'), findsNothing);
      visible.value = true;
      await tester.pumpAndSettle();
      expect(repository.ticketWatches, 2);
    },
  );
  test(
    'support text trims, rejects empty and excessive Unicode character count',
    () {
      expect(supportText('  góp ý  ', 120, 'Tiêu đề'), 'góp ý');
      expect(
        () => supportText(' \n ', 120, 'Tiêu đề'),
        throwsA(isA<SupportFailure>()),
      );
      expect(supportText('😀' * 120, 120, 'Tiêu đề').runes.length, 120);
      expect(
        () => supportText('x' * 2001, 2000, 'Nội dung'),
        throwsA(isA<SupportFailure>()),
      );
    },
  );
  testWidgets(
    'empty list, create validation and cancel do not write; confirmed valid submit writes once',
    (tester) async {
      final repository = FakeSupport();
      await open(tester, repository);
      expect(find.textContaining('Chưa có yêu cầu'), findsOneWidget);
      await tapKey(tester, 'new-support-ticket');
      await tapKey(tester, 'send-support-ticket');
      expect(repository.created, isEmpty);
      expect(find.textContaining('Hãy chọn chủ đề'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(repository.created, isEmpty);
      await fillTicket(tester);
      await tapKey(tester, 'send-support-ticket');
      expect(repository.created.length, 1);
      expect(find.text('Yêu cầu của bạn'), findsOneWidget);
    },
  );
  testWidgets(
    'uncertain create failure retains draft and transaction ID on retry',
    (tester) async {
      final repository = FakeSupport()..fail = true;
      await open(tester, repository);
      await fillTicket(tester);
      await tapKey(tester, 'send-support-ticket');
      expect(find.textContaining('Chưa xác nhận'), findsOneWidget);
      expect(find.text('Lỗi ghi nhận bữa sáng'), findsOneWidget);
      repository.fail = false;
      await tapKey(tester, 'send-support-ticket');
      expect(repository.created.length, 2);
      expect(repository.created[0], repository.created[1]);
      expect(repository.createdTopics, [
        SupportTopic.nutrition,
        SupportTopic.nutrition,
      ]);
    },
  );
  testWidgets(
    'admin answer and resolved state are visible, reply retry keeps ID and clears only after ACK',
    (tester) async {
      final repository = FakeSupport()..fail = true;
      await open(
        tester,
        repository,
        home: const SupportThreadScreen(ticketId: 'AbCdEfGhIjKlMnOpQrSt'),
      );
      expect(find.textContaining('Đã giải quyết'), findsOneWidget);
      expect(
        find.text('Bạn vui lòng cập nhật ứng dụng rồi thử lại.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('support-reply')));
      await tester.enterText(
        find.byKey(const ValueKey('support-reply')),
        'Mình đã thử nhưng vẫn lỗi.',
      );
      tester.testTextInput.hide();
      await tapKey(tester, 'send-support-reply');
      expect(repository.replied.length, 1);
      expect(find.textContaining('Chưa xác nhận gửi tin'), findsOneWidget);
      repository.fail = false;
      await tapKey(tester, 'send-support-reply');
      expect(repository.replied[0], repository.replied[1]);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('support-reply')))
            .controller!
            .text,
        '',
      );
    },
  );
  testWidgets(
    'failed list offers reload and recovers without fake empty data',
    (tester) async {
      final repository = FakeSupport()..listError = true;
      await open(tester, repository);
      expect(find.text('Mất kết nối thử nghiệm'), findsOneWidget);
      repository.listError = false;
      await tester.tap(find.text('Tải lại'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa có yêu cầu'), findsOneWidget);
    },
  );
  testWidgets('account switch hides the previous account draft', (
    tester,
  ) async {
    final auth = StreamController<AuthUser?>();
    addTearDown(auth.close);
    final repository = FakeSupport();
    await open(tester, repository, auth: auth.stream);
    auth.add(user);
    await tester.pumpAndSettle();
    await fillTicket(tester);
    auth.add(
      const AuthUser(uid: 'bob', email: 'bob@example.com', emailVerified: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lỗi ghi nhận bữa sáng'), findsNothing);
    expect(repository.created, isEmpty);
  });
  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('support screen and thread fit 320px at text scale $scale', (
      tester,
    ) async {
      await open(tester, FakeSupport(), scale: scale);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await open(
        tester,
        FakeSupport(),
        scale: scale,
        home: const SupportThreadScreen(ticketId: 'AbCdEfGhIjKlMnOpQrSt'),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
