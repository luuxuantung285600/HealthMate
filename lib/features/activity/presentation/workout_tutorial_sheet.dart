import '../../../core/theme/app_icons.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/workout_tutorial_player.dart';
import '../models/guided_workout.dart';
import '../models/workout_tutorial.dart';
import 'movement_media_preview.dart';
import 'workout_ui.dart';
import '../providers/workout_exercise_provider.dart';

Future<void> showWorkoutTutorial(
  BuildContext context,
  WorkoutMovement movement,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => WorkoutTutorialSheet(movement: movement),
);

class WorkoutTutorialSheet extends StatelessWidget {
  const WorkoutTutorialSheet({required this.movement, super.key});
  final WorkoutMovement movement;

  @override
  Widget build(BuildContext context) {
    final tutorial = WorkoutTutorials.byMovement[movement.id];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'KỸ THUẬT / HƯỚNG DẪN',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  movement.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.5,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Đóng hướng dẫn',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(AppIcons.x),
              ),
            ],
          ),
          if (workoutExerciseIds.containsKey(movement.id)) ...[
            MovementMediaPreview(movement: movement),
          ] else if (tutorial != null) ...[
            const SizedBox(height: 12),
            Text('Nguồn: ${tutorial.publisher} · YouTube'),
            const SizedBox(height: 6),
            const Text(
              'Video cần Internet, có thể có quảng cáo. Hướng dẫn tiếng Việt bên dưới dùng được khi mất mạng.',
            ),
            TutorialVideoPanel(movement: movement, tutorial: tutorial),
            if (tutorial.note != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  tutorial.note!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
          Text('Cách tập', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (var i = 0; i < movement.steps.length; i++)
            WorkoutStep(number: i + 1, text: movement.steps[i]),
          Text('Nhẹ hơn: ${movement.easier}'),
          const SizedBox(height: 20),
          FilledButton(
            key: const ValueKey('close-workout-tutorial'),
            style: workoutButtonStyle(context),
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}

class TutorialVideoPanel extends ConsumerStatefulWidget {
  const TutorialVideoPanel({
    required this.movement,
    required this.tutorial,
    super.key,
  });
  final WorkoutMovement movement;
  final WorkoutTutorial tutorial;

  @override
  ConsumerState<TutorialVideoPanel> createState() => _TutorialVideoPanelState();
}

class _TutorialVideoPanelState extends ConsumerState<TutorialVideoPanel>
    with WidgetsBindingObserver {
  WorkoutTutorialPlayer? _player;
  bool _failedToCreate = false, _openingSource = false;
  String? _sourceError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _load() {
    if (_player != null && _player!.state != TutorialPlaybackState.failed) {
      return;
    }
    _player?.removeListener(_changed);
    _player?.dispose();
    _player = null;
    _failedToCreate = false;
    try {
      _player = ref.read(workoutTutorialPlayerFactoryProvider)(widget.tutorial)
        ..addListener(_changed);
    } catch (_) {
      _failedToCreate = true;
    }
    setState(() {});
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On web, focusing the YouTube iframe can make Flutter inactive while the
    // page remains visible. Pause when the page is hidden, not on iframe focus.
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        (!kIsWeb && state == AppLifecycleState.inactive)) {
      unawaited(_player?.pause());
    }
  }

  Future<void> _openSource() async {
    if (_openingSource) return;
    setState(() {
      _openingSource = true;
      _sourceError = null;
    });
    await _player?.pause();
    var opened = false;
    try {
      opened = await launchUrl(
        widget.tutorial.watchUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      /* Show a readable error below the source button. */
    }
    if (!mounted) return;
    setState(() {
      _openingSource = false;
      if (!opened) {
        _sourceError =
            'Chưa mở được YouTube. Hãy kiểm tra kết nối rồi thử lại.';
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player?.removeListener(_changed);
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _player?.state;
    final failed = _failedToCreate || state == TutorialPlaybackState.failed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final canEmbed =
                  supportsWorkoutVideo && constraints.maxWidth >= 200;
              if (!canEmbed || _player == null || failed) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MovementMediaPreview(
                      movement: widget.movement,
                      onTap: canEmbed ? _load : _openSource,
                    ),
                    if (failed)
                      const Text(
                        'Chưa phát được video. Có thể mất mạng hoặc video bị giới hạn. Bạn vẫn có thể đọc cách tập bên dưới.',
                      ),
                    if (canEmbed)
                      OutlinedButton.icon(
                        key: const ValueKey('load-workout-video'),
                        onPressed: _load,
                        icon: const Icon(AppIcons.circlePlay),
                        label: Text(
                          failed ? 'Thử tải lại video' : 'Tải video hướng dẫn',
                        ),
                      ),
                  ],
                );
              }
              final height = math.max(200.0, constraints.maxWidth * 9 / 16);
              return Column(
                children: [
                  _player!.buildView(constraints.maxWidth / height),
                  if (state == TutorialPlaybackState.loading) ...[
                    const LinearProgressIndicator(),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Đang kết nối YouTube…'),
                    ),
                  ],
                ],
              );
            },
          ),
          TextButton.icon(
            key: const ValueKey('open-workout-video-source'),
            onPressed: _openingSource ? null : _openSource,
            icon: const Icon(AppIcons.externalLink, size: 18),
            label: const Text('Mở video gốc trên YouTube'),
          ),
          if (_sourceError != null) Text(_sourceError!),
        ],
      ),
    );
  }
}
