import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/support/data/support_repository.dart';
import 'package:healthmate/features/support/models/support_models.dart';
import 'package:healthmate/features/support/presentation/support_screen.dart';
import 'package:healthmate/features/support/providers/support_providers.dart';

const _alice = AuthUser(
  uid: 'alice',
  email: 'alice@example.test',
  emailVerified: true,
);
const _bob = AuthUser(
  uid: 'bob',
  email: 'bob@example.test',
  emailVerified: true,
);
const _ticketId = 'AbCdEfGhIjKlMnOpQrSt';
final _now = DateTime.utc(2026, 11, 7, 12);

typedef _Attempt = ({String uid, String id, String text});

class _LiveSupport implements SupportRepository {
  final changes = StreamController<void>.broadcast();
  final creates = <_Attempt>[], replies = <_Attempt>[];
  int ids = 0, reads = 0, active = 0, count = 1;
  SupportStatus status = SupportStatus.inProgress;
  Object? failure, readError, messageError;
  Completer<void>? createGate, replyGate;
  List<SupportMessage> messages = [];

  SupportTicket get ticket => SupportTicket(
    id: _ticketId,
    uid: _alice.uid,
    type: SupportType.bug,
    title: 'Yêu cầu kiểm thử',
    description: 'Mô tả fixture',
    status: status,
    createdAt: _now,
    updatedAt: _now,
    messageCount: count,
  );
  void emit() => changes.add(null);
  Stream<T> _watch<T>(T Function() value) => Stream.multi((controller) {
    reads++;
    active++;
    void publish() {
      try {
        controller.add(value());
      } catch (error, stack) {
        controller.addError(error, stack);
      }
    }

    publish();
    final sub = changes.stream.listen((_) => publish());
    controller.onCancel = () async {
      active--;
      await sub.cancel();
    };
  });
  @override
  String newId() => 'fixture-${++ids}';
  @override
  Stream<List<SupportTicket>> watchTickets(String uid) =>
      watchTicketPage(uid).map((page) => page.tickets);
  @override
  Stream<SupportTicketPage> watchTicketPage(
    String uid, {
    SupportTicketCursor? after,
  }) => _watch(
    () => SupportTicketPage(tickets: uid == _alice.uid ? [ticket] : []),
  );
  @override
  Stream<SupportTicket?> watchTicket(String uid, String ticketId) => _watch(() {
    if (readError != null) throw readError!;
    return uid == _alice.uid ? ticket : null;
  });
  @override
  Stream<List<SupportMessage>> watchMessages(String uid, String ticketId) =>
      _watch(() {
        if (messageError != null) throw messageError!;
        return uid == _alice.uid ? [...messages] : [];
      });
  @override
  Future<void> create(
    String uid,
    String id,
    SupportType type,
    String title,
    String description, {
    required SupportTopic topic,
  }) async {
    creates.add((uid: uid, id: id, text: '${topic.code}/$title/$description'));
    await createGate?.future;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> reply(
    String uid,
    String ticketId,
    String messageId,
    String text,
  ) async {
    replies.add((uid: uid, id: messageId, text: text));
    await replyGate?.future;
    if (failure != null) throw failure!;
  }

  Future<void> dispose() => changes.close();
}

Future<void> _tap(WidgetTester tester, String key, {bool settle = true}) async {
  final target = find.byKey(ValueKey(key));
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      key == 'support-topic' ? -300 : 300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<({StreamController<AuthUser?> auth, ProviderContainer container})> _open(
  WidgetTester tester,
  _LiveSupport repository, {
  bool thread = false,
  double scale = 1,
  double width = 390,
  Brightness brightness = Brightness.light,
  AuthUser initial = _alice,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  final auth = StreamController<AuthUser?>.broadcast();
  final container = ProviderContainer(
    overrides: [
      authSessionProvider.overrideWith((ref) async* {
        yield initial;
        yield* auth.stream;
      }),
      supportRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    if (repository.createGate?.isCompleted == false) {
      repository.createGate!.complete();
    }
    if (repository.replyGate?.isCompleted == false) {
      repository.replyGate!.complete();
    }
    await repository.dispose();
    await auth.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const SupportScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (thread) await _tap(tester, 'support-$_ticketId');
  return (auth: auth, container: container);
}

Future<void> _draft(WidgetTester tester, {required bool thread}) async {
  if (thread) {
    await tester.enterText(
      find.byKey(const ValueKey('support-reply')),
      'Nội dung đang soạn',
    );
  } else {
    await _tap(tester, 'new-support-ticket');
    await _tap(tester, 'support-topic');
    await tester.tap(find.text(SupportTopic.nutrition.label).last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('support-title')),
      'Lỗi kiểm thử',
    );
    await tester.enterText(
      find.byKey(const ValueKey('support-description')),
      'Nội dung đang soạn',
    );
  }
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;

void main() {
  for (final thread in [false, true]) {
    final field = thread ? 'support-reply' : 'support-description';
    final send = thread ? 'send-support-reply' : 'send-support-ticket';
    testWidgets(
      'Back preserves or explicitly discards support draft, reply=$thread',
      (tester) async {
        final repository = _LiveSupport();
        await _open(tester, repository, thread: thread);
        await _draft(tester, thread: thread);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Bỏ nội dung đang soạn?'), findsOneWidget);
        await tester.tap(find.text('Tiếp tục soạn'));
        await tester.pumpAndSettle();
        expect(_text(tester, field), 'Nội dung đang soạn');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bỏ nội dung'));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey(field)), findsNothing);
        expect(find.text('Yêu cầu của bạn'), findsOneWidget);
        expect(repository.creates, isEmpty);
        expect(repository.replies, isEmpty);
      },
    );

    testWidgets(
      'pending support request blocks Back and duplicate sends, reply=$thread',
      (tester) async {
        final repository = _LiveSupport();
        final gate = Completer<void>();
        if (thread) {
          repository.replyGate = gate;
        } else {
          repository.createGate = gate;
        }
        await _open(tester, repository, thread: thread);
        await _draft(tester, thread: thread);
        await _tap(tester, send, settle: false);
        expect(find.textContaining('Đang gửi. Vui lòng chờ'), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pump();
        await tester.binding.handlePopRoute();
        await tester.pump(const Duration(seconds: 3));
        expect(find.text('Bỏ nội dung đang soạn?'), findsNothing);
        expect(_text(tester, field), 'Nội dung đang soạn');
        expect(
          tester.widget<TextField>(find.byKey(ValueKey(field))).readOnly,
          true,
        );
        await _tap(tester, send, settle: false);
        expect(
          thread ? repository.replies.length : repository.creates.length,
          1,
        );
        gate.complete();
        await tester.pumpAndSettle();
        if (thread) {
          expect(_text(tester, field), '');
        } else {
          expect(find.byKey(ValueKey(field)), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'unknown send failure retains frozen text and same retry ID, reply=$thread',
      (tester) async {
        final repository = _LiveSupport()
          ..failure = StateError('fixture network');
        await _open(tester, repository, thread: thread);
        await _draft(tester, thread: thread);
        await _tap(tester, send);
        expect(find.textContaining('Chưa xác nhận gửi.'), findsOneWidget);
        if (!thread) {
          expect(
            tester
                .widget<DropdownButtonFormField<SupportTopic>>(
                  find.byKey(const ValueKey('support-topic')),
                )
                .onChanged,
            isNull,
          );
        }
        expect(_text(tester, field), 'Nội dung đang soạn');
        expect(
          tester.widget<TextField>(find.byKey(ValueKey(field))).readOnly,
          true,
        );
        repository.failure = null;
        await _tap(tester, send);
        final attempts = thread ? repository.replies : repository.creates;
        expect(attempts, hasLength(2));
        expect(attempts.first, attempts.last);
      },
    );
  }

  testWidgets('blank composer exits without asking or writing', (tester) async {
    final repository = _LiveSupport();
    await _open(tester, repository);
    await _tap(tester, 'new-support-ticket');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ nội dung đang soạn?'), findsNothing);
    expect(find.text('Yêu cầu của bạn'), findsOneWidget);
    expect(repository.creates, isEmpty);
  });

  testWidgets(
    'long live history keeps composer visible and preserves text on admin updates',
    (tester) async {
      final repository = _LiveSupport()
        ..messages = [
          for (var i = 0; i < 80; i++)
            SupportMessage(
              id: '$i',
              text: 'Fixture tin nhắn $i',
              isAdmin: true,
              createdAt: _now,
              sequence: i + 1,
            ),
        ]
        ..count = 80;
      await _open(tester, repository, thread: true);
      final field = find.byKey(const ValueKey('support-reply'));
      expect(tester.getRect(field).bottom, lessThan(844));
      await _draft(tester, thread: true);
      repository.status = SupportStatus.resolved;
      repository.messages.add(
        SupportMessage(
          id: 'new-admin',
          text: 'Phản hồi mới',
          isAdmin: true,
          createdAt: _now,
          sequence: 81,
        ),
      );
      repository.emit();
      await tester.pumpAndSettle();
      expect(_text(tester, 'support-reply'), 'Nội dung đang soạn');
      expect(find.textContaining('Gửi tin nhắn mới sẽ mở lại'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Phản hồi mới'),
        500,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('support-message-history')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Phản hồi mới'), findsOneWidget);
      expect(tester.getRect(field).bottom, lessThan(844));
    },
  );

  testWidgets(
    '100th-message update retains unsent draft for copy and blocks a new send',
    (tester) async {
      final repository = _LiveSupport()..count = 99;
      await _open(tester, repository, thread: true);
      await _draft(tester, thread: true);
      repository.count = 100;
      repository.emit();
      await tester.pumpAndSettle();
      expect(_text(tester, 'support-reply'), 'Nội dung đang soạn');
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('support-reply')))
            .readOnly,
        true,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('send-support-reply')),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.textContaining('vẫn được giữ để bạn sao chép'),
        findsOneWidget,
      );
      expect(repository.replies, isEmpty);
    },
  );

  testWidgets(
    'uncertain last-message ACK can retry same operation after count reaches 100',
    (tester) async {
      final repository = _LiveSupport()
        ..count = 99
        ..replyGate = Completer<void>();
      await _open(tester, repository, thread: true);
      await _draft(tester, thread: true);
      await _tap(tester, 'send-support-reply', settle: false);
      repository.count = 100;
      repository.emit();
      await tester.pump(const Duration(milliseconds: 200));
      repository.replyGate!.completeError(
        const SupportFailure('Chưa xác nhận gửi tin nhắn'),
      );
      await tester.pumpAndSettle();
      expect(_text(tester, 'support-reply'), 'Nội dung đang soạn');
      repository.replyGate = null;
      await _tap(tester, 'send-support-reply');
      expect(repository.replies, hasLength(2));
      expect(repository.replies[0], repository.replies[1]);
      expect(find.byKey(const ValueKey('support-reply')), findsNothing);
    },
  );

  testWidgets(
    'old ACK after A to B to A cannot close a newly opened composer',
    (tester) async {
      final repository = _LiveSupport()..createGate = Completer<void>();
      final fixture = await _open(tester, repository);
      await _draft(tester, thread: false);
      await _tap(tester, 'send-support-ticket', settle: false);
      fixture.auth.add(_bob);
      fixture.auth.add(_alice);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('support-description')), findsNothing);
      await _draft(tester, thread: false);
      repository.createGate!.complete();
      await tester.pumpAndSettle();
      expect(_text(tester, 'support-description'), 'Nội dung đang soạn');
      expect(find.textContaining('Đã gửi yêu cầu. Bạn có thể'), findsNothing);
      expect(repository.creates, hasLength(1));
    },
  );

  testWidgets(
    'auth error stops reads and hides private composer, same UID recovery preserves it',
    (tester) async {
      final repository = _LiveSupport();
      final fixture = await _open(tester, repository, thread: true);
      await _draft(tester, thread: true);
      fixture.auth.addError(StateError('fixture auth unavailable'));
      await tester.pumpAndSettle();
      expect(fixture.container.read(authSessionProvider).hasError, true);
      expect(fixture.container.read(supportSessionUidProvider), isNull);
      expect(find.byKey(const ValueKey('support-reply')), findsNothing);
      expect(repository.active, 0);
      fixture.auth.add(_alice);
      await tester.pumpAndSettle();
      expect(_text(tester, 'support-reply'), 'Nội dung đang soạn');
      expect(repository.active, greaterThan(0));
    },
  );

  testWidgets(
    'unverified account starts no support listeners or send controls',
    (tester) async {
      final repository = _LiveSupport();
      await _open(
        tester,
        repository,
        initial: const AuthUser(
          uid: 'unverified',
          email: 'fixture@example.test',
          emailVerified: false,
        ),
      );
      expect(repository.reads, 0);
      expect(find.byKey(const ValueKey('new-support-ticket')), findsNothing);
      expect(find.textContaining('xác minh email'), findsOneWidget);
    },
  );

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'support composer fits keyboard $width / $scale / $brightness',
          (tester) async {
            final repository = _LiveSupport();
            await _open(
              tester,
              repository,
              thread: true,
              width: width,
              scale: scale,
              brightness: brightness,
            );
            tester.view.viewInsets = const FakeViewPadding(bottom: 260);
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byKey(const ValueKey('support-reply')),
              'Dòng 1\nDòng 2\nDòng 3\nDòng 4',
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await _tap(tester, 'send-support-reply');
            expect(repository.replies, hasLength(1));
            expect(_text(tester, 'support-reply'), '');
            tester.view.viewInsets = const FakeViewPadding();
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
