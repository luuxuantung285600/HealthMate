import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:healthmate/features/activity/data/workout_tutorial_player.dart';
import 'package:healthmate/features/activity/models/workout_tutorial.dart';

/// Opt-in real-network check. No Firebase account, health data or fake player.
/// flutter test integration_test/workout_video_smoke_test.dart -d ANDROID_DEVICE
///   --dart-define=RUN_WORKOUT_VIDEO_SMOKE=true
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('RUN_WORKOUT_VIDEO_SMOKE');
  final seen = <String>{};
  for (final entry in WorkoutTutorials.byMovement.entries) {
    if (!seen.add(entry.value.videoId)) continue;
    final id = entry.key;
    testWidgets('official YouTube player cues $id on Android', (tester) async {
      final container = ProviderContainer();
      final player = container.read(workoutTutorialPlayerFactoryProvider)(
        WorkoutTutorials.byMovement[id]!,
      );
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(width: 320, child: player.buildView(1.6)),
              ),
            ),
          ),
        );
        final deadline = DateTime.now().add(const Duration(seconds: 25));
        while (player.state == TutorialPlaybackState.loading &&
            DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(
          player.state,
          TutorialPlaybackState.ready,
          reason:
              'The real WebView must cue the source; a thumbnail alone is insufficient.',
        );
        await player.pause();
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        player.dispose();
        container.dispose();
      }
    }, skip: !enabled);
  }
  testWidgets(
    'unplayable source reports failure without an uncaught SDK error',
    (tester) async {
      final container = ProviderContainer();
      final player = container.read(workoutTutorialPlayerFactoryProvider)(
        const WorkoutTutorial(
          videoId: 'not-an-id',
          title: 'Invalid test ID',
          publisher: 'Test only',
        ),
      );
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(width: 320, child: player.buildView(1.6)),
              ),
            ),
          ),
        );
        final deadline = DateTime.now().add(const Duration(seconds: 25));
        while (player.state != TutorialPlaybackState.failed &&
            DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(player.state, TutorialPlaybackState.failed);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        player.dispose();
        container.dispose();
      }
    },
    skip: !enabled,
  );
}
