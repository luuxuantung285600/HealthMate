import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/subscription_stream.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/firebase_workout_repository.dart';
import '../data/workout_repository.dart';
import '../models/workout.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => FirebaseWorkoutRepository(FirebaseFirestore.instance),
);

final workoutSessionsProvider = StreamProvider.autoDispose<List<WorkoutSession>>((ref) {
  final uid = ref.watch(authSessionProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return subscriptionStream(ref.watch(workoutRepositoryProvider).watchSessions(uid));
});

final workoutControllerProvider = NotifierProvider<WorkoutController, AsyncValue<void>>(
  WorkoutController.new,
);

class WorkoutController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> delete(WorkoutSession session) async {
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null || state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await ref.read(workoutRepositoryProvider).delete(uid: uid, sessionId: session.id);
      state = const AsyncData(null);
      ref.invalidate(workoutSessionsProvider);
      return true;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      return false;
    }
  }
}
