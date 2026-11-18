import 'support/load_icon_font.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/activity/presentation/workout_session_screen.dart';
import 'package:healthmate/features/activity/presentation/workouts_screen.dart';
import 'package:healthmate/features/journal/models/daily_log_failure.dart';

import 'support/fake_activity_repository.dart';
import 'support/fake_auth_repository.dart';
import 'support/test_app.dart';

class _ConfirmingActivity extends FakeActivityRepository {
  Completer<void>? pending;
  bool loseFirstResponse = false;
  final operations = <String?>[];
  final owners = <String>[];
  @override
  Future<String> add({
    required String uid,
    required ActivityLogDraft draft,
    String? operationId,
  }) async {
    operations.add(operationId);
    owners.add(uid);
    if (pending != null) await pending!.future;
    final id = await super.add(
      uid: uid,
      draft: draft,
      operationId: operationId,
    );
    if (loseFirstResponse && operations.length == 1) {
      throw const DailyLogFailure('Chưa nhận được xác nhận. Thử lại.');
    }
    return id;
  }
}

Future<ProviderContainer> _session(
  WidgetTester tester, {
  FakeActivityRepository? activities,
  FakeAuthRepository? auth,
  Size size = const Size(390, 844),
  double scale = 1,
  GlobalKey? captureKey,
  ThemeMode mode = ThemeMode.light,
}) async {
  final c = await pumpApp(
    tester,
    activityRepository: activities,
    repository: auth,
    size: size,
    textScale: scale,
    captureKey: captureKey,
    initialThemeMode: mode,
  );
  c
      .read(appRouterProvider)
      .go('${AppRoutes.workouts}/full_body/session?pace=standard');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  return c;
}

Future<void> _end(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('finish-workout')));
  await tester.pump(const Duration(milliseconds: 250));
  await tester.tap(find.byKey(const ValueKey('confirm-end-workout')));
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final shot = await boundary.toImage(pixelRatio: 2);
    final bytes = await shot.toByteData(format: ui.ImageByteFormat.png);
    shot.dispose();
    await Directory('build/workout-preview').create(recursive: true);
    await File(
      'build/workout-preview/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    await loadIconFont();
    final font = FontLoader('Public Sans');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(
        rootBundle.load('assets/fonts/public_sans/PublicSans-$weight.ttf'),
      );
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets(
    'profile entry, filters, instructions and pace controls are usable',
    (tester) async {
      final key = GlobalKey();
      await pumpApp(tester, captureKey: key);
      await openProfileFromShell(tester);
      final entry = find.byKey(const ValueKey('open-workouts'));
      await tester.ensureVisible(entry);
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();
      await _capture(tester, key, 'library-light');
      await tester.tap(find.byKey(const ValueKey('open-timed-workouts')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Thân giữa'));
      await tester.pump();
      expect(find.byKey(const ValueKey('workout-full_body')), findsNothing);
      expect(
        find.byKey(const ValueKey('workout-core_stability')),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả'));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('workout-full_body')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('workout-full_body')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Bắt đầu · 7:55'), findsOneWidget);
      final pace = find.byKey(const ValueKey('workout-pace-twoRounds'));
      await tester.ensureVisible(pace);
      await tester.tap(pace);
      await tester.pump();
      expect(find.text('Bắt đầu · 15:55'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -350));
      await tester.pump(const Duration(milliseconds: 250));
      final tile = find.byKey(const ValueKey('movement-1'));
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Nhẹ hơn: Bước ngắn'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'foreground pause, background and resume never credit time away',
    (tester) async {
      await _session(tester);
      await tester.pump(const Duration(seconds: 10));
      await tester.tap(find.byKey(const ValueKey('pause-workout')));
      await tester.pump();
      final before = tester
          .widget<Text>(find.byKey(const ValueKey('workout-countdown')))
          .data;
      await tester.pump(const Duration(minutes: 5));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('workout-countdown')))
            .data,
        before,
      );
      await tester.tap(find.byKey(const ValueKey('pause-workout')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('workout-countdown')))
            .data,
        isNot(before),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      final background = tester
          .widget<Text>(find.byKey(const ValueKey('workout-countdown')))
          .data;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(minutes: 10));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Đang tạm dừng'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('workout-countdown')))
            .data,
        background,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'instructions during rest describe upcoming movement and pause clock',
    (tester) async {
      await _session(tester);
      await tester.pump(const Duration(seconds: 35));
      expect(find.text('Nghỉ & thả lỏng'), findsOneWidget);
      final info = find.byKey(const ValueKey('workout-instructions'));
      await tester.ensureVisible(info);
      await tester.tap(info);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Tựa tường hạ người'), findsOneWidget);
      expect(find.textContaining('Tựa lưng vào tường'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'partial session requires confirmation and saves only full work minutes',
    (tester) async {
      final activities = _ConfirmingActivity();
      final c = await _session(tester, activities: activities);
      await tester.pump(const Duration(seconds: 75));
      expect(activities.addCalls, 0);
      await _end(tester);
      expect(find.textContaining('Nhật ký sẽ ghi 1 phút'), findsOneWidget);
      expect(activities.addCalls, 0);
      await tester.tap(find.byKey(const ValueKey('save-workout')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Đã lưu vận động hôm nay'), findsOneWidget);
      expect(activities.addCalls, 1);
      expect(activities.operations.single, startsWith('workout_'));
      expect(activities.owners.single, FakeAuthRepository.testUser.uid);
      await tester.tap(find.byKey(const ValueKey('close-workout')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-timed-workouts')));
      await tester.pumpAndSettle();
      expect(find.text('1 phút đã ghi nhận'), findsOneWidget);
      c.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      await openActivityDetails(tester);
      expect(find.textContaining('Tập sức mạnh · 1 phút'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'lost server response retries the same operation without duplicate log',
    (tester) async {
      final activities = _ConfirmingActivity()..loseFirstResponse = true;
      await _session(tester, activities: activities);
      await tester.pump(const Duration(seconds: 75));
      await _end(tester);
      await tester.tap(find.byKey(const ValueKey('save-workout')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Thử lưu lại'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('save-workout')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(activities.operations.length, 2);
      expect(activities.operations.toSet().length, 1);
      final day = DateTime.now();
      final logs = await activities.loadRange(
        FakeAuthRepository.testUser.uid,
        DateTime(day.year, day.month, day.day),
        DateTime(day.year, day.month, day.day + 1),
      );
      expect(logs.length, 1);
      expect(find.text('Đã lưu vận động hôm nay'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'save blocks repeat taps and account switch cannot write as new user',
    (tester) async {
      final activities = _ConfirmingActivity()..pending = Completer<void>();
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      await _session(tester, activities: activities, auth: auth);
      await tester.pump(const Duration(seconds: 75));
      await _end(tester);
      final save = find.byKey(const ValueKey('save-workout'));
      await tester.tap(save);
      await tester.pump();
      await tester.tap(save);
      await tester.pump();
      expect(activities.operations.length, 1);
      auth.emitUser(null);
      await tester.pump(const Duration(milliseconds: 100));
      activities.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutSessionScreen), findsNothing);
      expect(find.text('Đã lưu vận động hôm nay'), findsNothing);
      expect(activities.owners, [FakeAuthRepository.testUser.uid]);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'system back asks before stopping and sub-minute summary has no save',
    (tester) async {
      final activities = _ConfirmingActivity();
      await _session(tester, activities: activities);
      expect(find.byKey(const ValueKey('nav-workouts')), findsNothing);
      expect(find.byKey(const ValueKey('nav-progress')), findsNothing);
      expect(find.byKey(const ValueKey('quick-add-menu')), findsNothing);
      await tester.pump(const Duration(seconds: 8));
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Dừng buổi tập?'), findsOneWidget);
      expect(find.byType(WorkoutSessionScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-workouts')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('confirm-end-workout')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const ValueKey('save-workout')), findsNothing);
      expect(find.textContaining('Chưa đủ 1 phút'), findsOneWidget);
      expect(activities.addCalls, 0);
      await tester.tap(find.byKey(const ValueKey('close-workout')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Rời tổng kết?'), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-workouts')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('confirm-end-workout')));
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutsScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-workouts')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-progress')), findsOneWidget);
      expect(find.byKey(const ValueKey('quick-add-menu')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('natural completion shows actual work and illustration preview', (
    tester,
  ) async {
    final key = GlobalKey();
    await _session(tester, captureKey: key, mode: ThemeMode.dark);
    await tester.pump(const Duration(seconds: 7));
    await tester.tap(find.byKey(const ValueKey('pause-workout')));
    await tester.pump();
    await _capture(tester, key, 'player-dark');
    await tester.tap(find.byKey(const ValueKey('pause-workout')));
    await tester.pump();
    await tester.pump(const Duration(minutes: 9));
    expect(find.text('Bạn đã đi hết buổi tập!'), findsOneWidget);
    expect(find.textContaining('6:00 vận động'), findsOneWidget);
    expect(find.textContaining('Nhật ký sẽ ghi 6 phút'), findsOneWidget);
    await _capture(tester, key, 'summary-dark');
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final width in [320.0, 390.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets('workout layouts width=$width scale=$scale theme=$mode', (
          tester,
        ) async {
          final c = await _session(
            tester,
            size: Size(width, 844),
            scale: scale,
            mode: mode,
          );
          await tester.pump(const Duration(seconds: 8));
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(const ValueKey('pause-workout')));
          await tester.pump();
          await _end(tester);
          expect(tester.takeException(), isNull);
          c.read(appRouterProvider).go('${AppRoutes.workouts}/full_body');
          await tester.pump(const Duration(milliseconds: 350));
          expect(tester.takeException(), isNull);
          c.read(appRouterProvider).go(AppRoutes.workouts);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
}
