import '../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/guided_workout.dart';
import '../models/workout_tutorial.dart';
import '../providers/workout_exercise_provider.dart';
import 'exercise_gif_preview.dart';

/// A still preview, never an auto-playing video in the workout list or timer.
class MovementMediaPreview extends ConsumerWidget {
  const MovementMediaPreview({
    required this.movement,
    this.height = 180,
    this.onTap,
    super.key,
  });

  final WorkoutMovement movement;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (workoutExerciseIds.containsKey(movement.id)) {
      final exercise = ref.watch(workoutExerciseProvider(movement.id));
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: exercise == null
            ? const Text(
                'GIF đang chờ thư viện xác nhận hoặc đã được ẩn. Hướng dẫn từng bước vẫn có bên dưới.',
              )
            : ExerciseGifPreview(entry: exercise, stage: true, height: height),
      );
    }
    final tutorial = WorkoutTutorials.byMovement[movement.id];
    final scheme = Theme.of(context).colorScheme;
    final preview = SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: scheme.surfaceContainerHighest,
            child: const Icon(AppIcons.workout, size: 48),
          ),
          if (onTap != null && tutorial != null)
            const Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(AppIcons.play, color: Colors.white, size: 36),
                ),
              ),
            ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: onTap == null
                ? preview
                : Semantics(
                    button: true,
                    label: 'Xem hướng dẫn ${movement.name}',
                    child: Material(
                      child: InkWell(onTap: onTap, child: preview),
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            tutorial == null
                ? 'Hướng dẫn từng bước bên dưới'
                : 'Hướng dẫn từng bước · Có video tùy chọn',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
