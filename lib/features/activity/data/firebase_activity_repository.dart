import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/data/bounded_range.dart';
import '../../../core/utils/local_date_key.dart';

import '../../journal/models/daily_log_failure.dart';
import '../models/activity_log.dart';
import 'activity_repository.dart';

class FirebaseActivityRepository implements ActivityRepository {
  FirebaseActivityRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _logs(String uid) =>
      _firestore.collection('users').doc(uid).collection('activity_logs');

  @override
  Stream<List<ActivityLog>> watchLogs(String uid, String dateKey) async* {
    try {
      await for (final snapshot
          in _logs(uid)
              .where('dateKey', isEqualTo: dateKey)
              .orderBy('performedAt', descending: true)
              .snapshots()) {
        yield [for (final doc in snapshot.docs) _fromDoc(doc.id, doc.data())];
      }
    } on FirebaseException catch (error) {
      throw DailyLogFailure.fromCode(error.code);
    }
  }

  @override
  Future<List<ActivityLog>> loadRange(
    String uid,
    DateTime start,
    DateTime end,
  ) => _guard(() async {
    final snapshot = await readBoundedRange(
      _logs(uid)
          .where('dateKey', isGreaterThanOrEqualTo: localDateKey(start))
          .where('dateKey', isLessThan: localDateKey(end)),
      start,
      end,
    );
    return [for (final doc in snapshot.docs) _fromDoc(doc.id, doc.data())];
  });

  @override
  Future<String> add({required String uid, required ActivityLogDraft draft}) =>
      _guard(() async {
        final ref = _logs(uid).doc();
        await ref.set({
          ..._data(draft),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return ref.id;
      });

  @override
  Future<void> update({
    required String uid,
    required String logId,
    required ActivityLogDraft draft,
  }) => _guard(
    () => _logs(uid).doc(logId).update({
      ..._data(draft),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> delete({required String uid, required String logId}) =>
      _guard(() => _logs(uid).doc(logId).delete());

  Map<String, Object> _data(ActivityLogDraft draft) => {
    'activityType': draft.type.name,
    'durationMinutes': draft.durationMinutes,
    'performedAt': Timestamp.fromDate(draft.performedAt),
    'dateKey': draft.dateKey,
    'timezoneOffsetMinutes': draft.timezoneOffsetMinutes,
    'note': draft.note.trim(),
    if (draft.caloriesBurned != null) 'caloriesBurned': draft.caloriesBurned!,
  };

  ActivityLog _fromDoc(String id, Map<String, dynamic> data) => ActivityLog(
    id: id,
    type:
        ActivityType.values
            .where((value) => value.name == data['activityType'])
            .firstOrNull ??
        ActivityType.other,
    durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
    performedAt: _date(data['performedAt']) ?? DateTime.now(),
    dateKey: data['dateKey'] as String? ?? '',
    timezoneOffsetMinutes:
        (data['timezoneOffsetMinutes'] as num?)?.toInt() ?? 0,
    note: data['note'] as String? ?? '',
    caloriesBurned: (data['caloriesBurned'] as num?)?.toDouble(),
    createdAt: _date(data['createdAt']),
    updatedAt: _date(data['updatedAt']),
  );

  DateTime? _date(Object? value) => switch (value) {
    Timestamp timestamp => timestamp.toDate(),
    DateTime date => date,
    _ => null,
  };

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (error) {
      throw DailyLogFailure.fromCode(error.code);
    } catch (_) {
      throw DailyLogFailure.fromCode('unknown');
    }
  }
}
