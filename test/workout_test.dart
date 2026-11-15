import 'package:flutter_test/flutter_test.dart';

import 'package:healthmate/features/workouts/models/workout.dart';

void main() {
  test('catalog includes accessible starter sessions', () {
    expect(WorkoutCatalog.plans.length, greaterThanOrEqualTo(4));
    expect(
      WorkoutCatalog.plans.every((plan) =>
          plan.name.isNotEmpty &&
          plan.durationMinutes > 0 &&
          plan.exercises.isNotEmpty &&
          plan.exercises.every((exercise) => exercise.workSeconds > 0)),
      isTrue,
    );
  });

  test('workout session rounds active time up to activity minutes', () {
    final session = WorkoutSession(
      id: 'session',
      workoutId: 'full_body_easy',
      workoutName: 'Toàn thân nhẹ nhàng',
      startedAt: DateTime(2026, 11, 16, 8),
      completedAt: DateTime(2026, 11, 16, 8, 1),
      activeSeconds: 61,
      caloriesBurned: 4.2,
      completedExerciseIds: const ['march'],
      dateKey: '2026-11-16',
    );
    expect(session.activeMinutes, 2);
    expect(session.caloriesBurned, 4.2);
  });
}
