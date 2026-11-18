import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/data/bounded_range.dart';
import '../../../core/utils/local_date_key.dart';

import '../../journal/models/daily_log_failure.dart';
import '../models/activity_log.dart';
import '../models/activity_energy.dart';
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
  Future<String> add({
    required String uid,
    required ActivityLogDraft draft,
    String? operationId,
  }) => _guard(() async {
    if (operationId != null &&
        !RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(operationId)) {
      throw const DailyLogFailure(
        'Mã buổi tập không hợp lệ. Hãy mở lại buổi tập.',
      );
    }
    final ref = _logs(uid).doc(operationId);
    final data = _data(draft);
    bool same(Map<String, dynamic>? previous) =>
        previous != null &&
        data.entries.every(
          (entry) => entry.value is Map
              ? mapEquals(previous[entry.key] as Map?, entry.value as Map)
              : previous[entry.key] == entry.value,
        );
    final payload = {
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (operationId == null) {
      await ref.set(payload);
    } else {
      await _firestore.runTransaction((transaction) async {
        final previous = await transaction.get(ref);
        if (previous.exists) {
          if (!same(previous.data())) {
            throw const DailyLogFailure(
              'Buổi tập này đã lưu với nội dung khác. Hãy kiểm tra nhật ký.',
            );
          }
          return;
        }
        transaction.set(ref, payload);
      });
      final confirmed = await ref.get(const GetOptions(source: Source.server));
      if (!confirmed.exists ||
          confirmed.metadata.hasPendingWrites ||
          confirmed.metadata.isFromCache ||
          !same(confirmed.data())) {
        throw const DailyLogFailure(
          'Chưa xác nhận được buổi tập trên máy chủ. Hãy thử lưu lại.',
        );
      }
    }
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

  Map<String, Object?> _data(ActivityLogDraft draft) {
    if (ActivityValidation.duration(draft.durationMinutes.toString()) != null ||
        ActivityValidation.note(draft.note) != null ||
        (draft.energyEstimate != null &&
            !draft.energyEstimate!.validFor(
              type: draft.type.name,
              minutes: draft.durationMinutes,
              performedAt: draft.performedAt,
            ))) {
      throw const DailyLogFailure(
        'Dữ liệu vận động hoặc ước tính calo không hợp lệ.',
      );
    }
    return {
      'activityType': draft.type.name,
      'durationMinutes': draft.durationMinutes,
      'performedAt': Timestamp.fromDate(draft.performedAt),
      'dateKey': draft.dateKey,
      'timezoneOffsetMinutes': draft.timezoneOffsetMinutes,
      'note': draft.note.trim(),
      'energyEstimate': draft.energyEstimate?.toData(),
    };
  }

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
    energyEstimate: _energy(data),
    createdAt: _date(data['createdAt']),
    updatedAt: _date(data['updatedAt']),
  );

  ActivityEnergyEstimate? _energy(Map<String, dynamic> data) {
    final raw = data['energyEstimate'];
    if (raw == null) return null;
    final estimate = ActivityEnergyEstimate.fromData(
      Map<String, dynamic>.from(raw as Map),
    );
    if (!estimate.validFor(
      type: data['activityType'] as String,
      minutes: (data['durationMinutes'] as num).toInt(),
      performedAt: _date(data['performedAt'])!,
      dateKey: data['dateKey'] as String,
    )) {
      throw const FormatException('Ước tính calo đã lưu không hợp lệ.');
    }
    return estimate;
  }

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
    } on DailyLogFailure {
      rethrow;
    } catch (_) {
      throw DailyLogFailure.fromCode('unknown');
    }
  }
}
