import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/activity/data/workout_tutorial_player.dart';
import 'package:healthmate/features/activity/models/guided_workout.dart';
import 'package:healthmate/features/activity/models/workout_tutorial.dart';
import 'package:healthmate/features/activity/presentation/workout_session_screen.dart';
import 'package:healthmate/features/activity/presentation/workout_tutorial_sheet.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';

import 'support/fake_auth_repository.dart';

class _Player extends WorkoutTutorialPlayer {
  TutorialPlaybackState _state = TutorialPlaybackState.loading;
  int pauses = 0, disposals = 0;
  final ratios = <double>[];
  @override
  TutorialPlaybackState get state => _state;
  void emit(TutorialPlaybackState value) {
    _state = value;
    notifyListeners();
  }

  @override
  Future<void> pause() async => pauses++;
  @override
  Widget buildView(double aspectRatio) {
    ratios.add(aspectRatio);
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: const ColoredBox(color: Colors.black),
    );
  }

  @override
  void dispose() {
    disposals++;
    super.dispose();
  }
}

Future<void> _sheet(
  WidgetTester tester,
  List<_Player> players, {
  double width = 390,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workoutTutorialPlayerFactoryProvider.overrideWithValue((_) {
          final player = _Player();
          players.add(player);
          return player;
        }),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: WorkoutTutorialSheet(movement: GuidedWorkouts.wallSit),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test(
    'every current movement has a source and both side cues stay explicit',
    () {
      final movements = GuidedWorkouts.all.expand((w) => w.movements);
      expect(movements.map((m) => m.id).toSet().length, 14);
      for (final movement in movements) {
        final tutorial = WorkoutTutorials.byMovement[movement.id]!;
        expect(tutorial.videoId, matches(RegExp(r'^[a-zA-Z0-9_-]{11}$')));
        expect(tutorial.watchUri.host, 'www.youtube.com');
        expect(tutorial.watchUri.queryParameters['v'], tutorial.videoId);
        expect(tutorial.publisher, isNotEmpty);
      }
      expect(
        WorkoutTutorials.byMovement['side_plank_left']!.note,
        contains('TRÁI'),
      );
      expect(
        WorkoutTutorials.byMovement['side_plank_right']!.note,
        contains('PHẢI'),
      );
      expect(WorkoutTutorials.byMovement['wall_push']!.endSeconds, 36);
    },
  );

  testWidgets(
    'player is lazy; errors retain instructions and retry disposes old player',
    (tester) async {
      final players = <_Player>[];
      await _sheet(tester, players);
      expect(players, isEmpty);
      expect(find.textContaining('Nguồn:'), findsOneWidget);
      expect(find.textContaining('Video cần Internet'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('load-workout-video')));
      await tester.pump();
      expect(players, hasLength(1));
      expect(find.text('Đang kết nối YouTube…'), findsOneWidget);
      players.single.emit(TutorialPlaybackState.failed);
      await tester.pump();
      expect(find.textContaining('Chưa phát được video.'), findsOneWidget);
      expect(find.textContaining('Tựa lưng vào tường'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('open-workout-video-source')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('load-workout-video')));
      await tester.pump();
      expect(players, hasLength(2));
      expect(players.first.disposals, 1);
      players.last.emit(TutorialPlaybackState.ready);
      await tester.pump();
      expect(find.text('Đang kết nối YouTube…'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(players.last.pauses, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(players.last.disposals, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'video viewing and closing never resume the workout or credit time',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final players = <_Player>[];
      final c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(user: FakeAuthRepository.testUser),
          ),
          workoutTutorialPlayerFactoryProvider.overrideWithValue((_) {
            final p = _Player();
            players.add(p);
            return p;
          }),
        ],
      );
      addTearDown(c.dispose);
      c.listen(authSessionProvider, (_, _) {});
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(
        c.read(authSessionProvider).value?.uid,
        FakeAuthRepository.testUser.uid,
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            home: WorkoutSessionScreen(
              workout: GuidedWorkouts.all.first,
              pace: WorkoutPace.standard,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 8));
      final clock = find.byKey(const ValueKey('workout-countdown'));
      final before = tester.widget<Text>(clock).data;
      final info = find.byKey(const ValueKey('workout-instructions'));
      await tester.ensureVisible(info);
      await tester.tap(info);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('load-workout-video')),
      );
      await tester.tap(find.byKey(const ValueKey('load-workout-video')));
      await tester.pump();
      players.single.emit(TutorialPlaybackState.ready);
      await tester.pump(const Duration(minutes: 5));
      expect(tester.widget<Text>(clock).data, before);
      final close = find.byKey(const ValueKey('close-workout-tutorial'));
      await tester.ensureVisible(close);
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(players.single.disposals, 1);
      expect(find.text('Đang tạm dừng'), findsOneWidget);
      await tester.pump(const Duration(minutes: 1));
      expect(tester.widget<Text>(clock).data, before);
      await tester.tap(find.byKey(const ValueKey('pause-workout')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(tester.widget<Text>(clock).data, isNot(before));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'unsupported desktop retains a working source action without creating WebView',
    (tester) async {
      final players = <_Player>[];
      await _sheet(tester, players);
      expect(players, isEmpty);
      expect(find.byKey(const ValueKey('load-workout-video')), findsNothing);
      expect(
        find.byKey(const ValueKey('open-workout-video-source')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  for (final width in [240.0, 320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'tutorial stays readable width=$width scale=$scale; player >=200px',
        (tester) async {
          final players = <_Player>[];
          await _sheet(tester, players, width: width, scale: scale);
          final load = find.byKey(const ValueKey('load-workout-video'));
          await tester.ensureVisible(load);
          await tester.tap(load);
          await tester.pump();
          final ratio = players.single.ratios.last;
          expect((width - 40) / ratio, greaterThanOrEqualTo(200));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
