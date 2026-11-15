import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/local_date_key.dart';
import '../../activity/models/activity_log.dart';
import '../models/workout.dart';
import 'workout_repository.dart';

class FirebaseWorkoutRepository implements WorkoutRepository {
  FirebaseWorkoutRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _sessions(String uid) =>
      _firestore.collection('users').doc(uid).collection('workout_sessions');

  CollectionReference<Map<String, dynamic>> _activities(String uid) =>
      _firestore.collection('users').doc(uid).collection('activity_logs');

  @override
  Stream<List<WorkoutSession>> watchSessions(String uid) => _sessions(uid)
      .orderBy('completedAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => [
        for (final doc in snapshot.docs) _fromDoc(doc.id, doc.data()),
      ]);

  @override
  Future<WorkoutSession> complete({
    required String uid,
    required WorkoutPlan workout,
    required DateTime startedAt,
    required DateTime completedAt,
    required int activeSeconds,
    required double caloriesBurned,
    required List<String> completedExerciseIds,
  }) async {
    final sessionId = '${workout.id}-${startedAt.millisecondsSinceEpoch}';
    final sessionRef = _sessions(uid).doc(sessionId);
    final activityRef = _activities(uid).doc(sessionId);
    final dateKey = dateKeyFromTimestampAndOffset(
      completedAt,
      completedAt.timeZoneOffset.inMinutes,
    );
    final activityMinutes = (activeSeconds / 60).ceil().clamp(1, 1440);
    final session = WorkoutSession(
      id: sessionId,
      workoutId: workout.id,
      workoutName: workout.name,
      startedAt: startedAt,
      completedAt: completedAt,
      activeSeconds: activeSeconds,
      caloriesBurned: caloriesBurned,
      completedExerciseIds: List.unmodifiable(completedExerciseIds),
      dateKey: dateKey,
    );
    await _firestore.runTransaction((transaction) async {
      if ((await transaction.get(sessionRef)).exists) return;
      transaction.set(sessionRef, {
        'workoutId': workout.id,
        'workoutName': workout.name,
        'startedAt': Timestamp.fromDate(startedAt),
        'completedAt': Timestamp.fromDate(completedAt),
        'activeSeconds': activeSeconds,
        'caloriesBurned': caloriesBurned,
        'completedExerciseIds': completedExerciseIds,
        'dateKey': dateKey,
        'timezoneOffsetMinutes': completedAt.timeZoneOffset.inMinutes,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(activityRef, {
        'activityType': ActivityType.other.name,
        'durationMinutes': activityMinutes,
        'performedAt': Timestamp.fromDate(completedAt),
        'dateKey': dateKey,
        'timezoneOffsetMinutes': completedAt.timeZoneOffset.inMinutes,
        'note': 'workout:${workout.id}',
        'caloriesBurned': caloriesBurned,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return session;
  }

  @override
  Future<void> delete({required String uid, required String sessionId}) async {
    await _firestore.runTransaction((transaction) async {
      transaction.delete(_sessions(uid).doc(sessionId));
      transaction.delete(_activities(uid).doc(sessionId));
    });
  }

  WorkoutSession _fromDoc(String id, Map<String, dynamic> data) => WorkoutSession(
    id: id,
    workoutId: data['workoutId'] as String? ?? '',
    workoutName: data['workoutName'] as String? ?? 'Buổi tập',
    startedAt: _date(data['startedAt']) ?? DateTime.now(),
    completedAt: _date(data['completedAt']) ?? DateTime.now(),
    activeSeconds: (data['activeSeconds'] as num?)?.toInt() ?? 0,
    caloriesBurned: (data['caloriesBurned'] as num?)?.toDouble() ?? 0,
    completedExerciseIds: [
      for (final value in (data['completedExerciseIds'] as List?) ?? const [])
        if (value is String) value,
    ],
    dateKey: data['dateKey'] as String? ?? '',
    createdAt: _date(data['createdAt']),
  );

  DateTime? _date(Object? value) => switch (value) {
    Timestamp timestamp => timestamp.toDate(),
    DateTime date => date,
    _ => null,
  };
}
