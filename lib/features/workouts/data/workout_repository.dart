import '../models/workout.dart';

abstract interface class WorkoutRepository {
  Stream<List<WorkoutSession>> watchSessions(String uid);

  Future<WorkoutSession> complete({
    required String uid,
    required WorkoutPlan workout,
    required DateTime startedAt,
    required DateTime completedAt,
    required int activeSeconds,
    required double caloriesBurned,
    required List<String> completedExerciseIds,
  });

  Future<void> delete({required String uid, required String sessionId});
}
