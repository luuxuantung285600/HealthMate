import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/data/bounded_range.dart';
import '../../../core/utils/local_date_key.dart';

import '../../journal/models/daily_log_failure.dart';
import '../models/water_log.dart';
import 'water_repository.dart';

class FirebaseWaterRepository implements WaterRepository {
  FirebaseWaterRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _logs(String uid) =>
      _firestore.collection('users').doc(uid).collection('water_logs');

  @override
  Stream<List<WaterLog>> watchLogs(String uid, String dateKey) async* {
    try {
      await for (final snapshot
          in _logs(uid)
              .where('dateKey', isEqualTo: dateKey)
              .orderBy('consumedAt', descending: true)
              .snapshots()) {
        yield [for (final doc in snapshot.docs) _fromDoc(doc.id, doc.data())];
      }
    } on FirebaseException catch (error) {
      throw DailyLogFailure.fromCode(error.code);
    }
  }

  @override
  Future<List<WaterLog>> loadRange(String uid, DateTime start, DateTime end) =>
      _guard(() async {
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
  Future<String> add({required String uid, required WaterLogDraft draft}) =>
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
  Future<void> undoAdd({
    required String uid,
    required String logId,
    required WaterLogDraft draft,
  }) => _guard(() async {
    final reference = _logs(uid).doc(logId);
    final expected = _data(draft);
    final undone = await _firestore.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) return true;
      final data = snapshot.data()!;
      if (expected.entries.any((entry) => data[entry.key] != entry.value) ||
          data['createdAt'] == null ||
          data['createdAt'] != data['updatedAt']) {
        return false;
      }
      transaction.delete(reference);
      return true;
    });
    // Keep domain errors outside the SDK callback: the web bridge wraps thrown
    // Dart exceptions in a FirebaseException and loses their specific code.
    if (!undone) {
      throw const DailyLogFailure(
        'Lần ghi này đã được chỉnh sửa. Hãy kiểm tra trong nhật ký để sửa hoặc xóa.',
        code: 'water-entry-changed',
      );
    }
  });

  @override
  Future<void> update({
    required String uid,
    required String logId,
    required WaterLogDraft draft,
  }) => _guard(
    () => _logs(uid).doc(logId).update({
      ..._data(draft),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> delete({required String uid, required String logId}) =>
      _guard(() => _logs(uid).doc(logId).delete());

  Map<String, Object> _data(WaterLogDraft draft) => {
    'amountMl': draft.amountMl,
    'consumedAt': Timestamp.fromDate(draft.consumedAt),
    'dateKey': draft.dateKey,
    'timezoneOffsetMinutes': draft.timezoneOffsetMinutes,
  };

  WaterLog _fromDoc(String id, Map<String, dynamic> data) => WaterLog(
    id: id,
    amountMl: (data['amountMl'] as num?)?.toInt() ?? 0,
    consumedAt: _date(data['consumedAt']) ?? DateTime.now(),
    dateKey: data['dateKey'] as String? ?? '',
    timezoneOffsetMinutes:
        (data['timezoneOffsetMinutes'] as num?)?.toInt() ?? 0,
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
    } on DailyLogFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw DailyLogFailure.fromCode(error.code);
    } catch (_) {
      throw DailyLogFailure.fromCode('unknown');
    }
  }
}
