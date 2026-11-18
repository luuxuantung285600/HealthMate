import 'dart:async';
import 'package:healthmate/core/utils/local_date_key.dart';

import 'package:healthmate/features/activity/data/activity_repository.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';

class FakeActivityRepository implements ActivityRepository {
  FakeActivityRepository({List<ActivityLog>? logs}) : _logs = [...?logs];

  final List<ActivityLog> _logs;
  final _changes = StreamController<void>.broadcast();
  int addCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int rangeCalls = 0;
  int activeDayListeners = 0;

  @override
  Stream<List<ActivityLog>> watchLogs(String uid, String dateKey) =>
      Stream.multi((controller) {
        activeDayListeners++;
        void emit() => controller.add(_forDate(dateKey));
        emit();
        final subscription = _changes.stream.listen((_) => emit());
        controller.onCancel = () async {
          activeDayListeners--;
          await subscription.cancel();
        };
      });

  @override
  Future<List<ActivityLog>> loadRange(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    rangeCalls++;
    final first = localDateKey(start), last = localDateKey(end);
    return _logs
        .where(
          (log) =>
              log.dateKey.compareTo(first) >= 0 &&
              log.dateKey.compareTo(last) < 0,
        )
        .toList();
  }

  @override
  Future<String> add({
    required String uid,
    required ActivityLogDraft draft,
    String? operationId,
  }) async {
    addCalls++;
    final id = operationId ?? 'activity-$addCalls';
    if (_logs.any((log) => log.id == id)) return id;
    _logs.add(_toLog(id, draft));
    _changes.add(null);
    return id;
  }

  @override
  Future<void> update({
    required String uid,
    required String logId,
    required ActivityLogDraft draft,
  }) async {
    updateCalls++;
    final index = _logs.indexWhere((log) => log.id == logId);
    if (index >= 0) _logs[index] = _toLog(logId, draft);
    _changes.add(null);
  }

  @override
  Future<void> delete({required String uid, required String logId}) async {
    deleteCalls++;
    _logs.removeWhere((log) => log.id == logId);
    _changes.add(null);
  }

  List<ActivityLog> _forDate(String dateKey) =>
      _logs.where((log) => log.dateKey == dateKey).toList()
        ..sort((a, b) => b.performedAt.compareTo(a.performedAt));

  ActivityLog _toLog(String id, ActivityLogDraft draft) => ActivityLog(
    id: id,
    type: draft.type,
    durationMinutes: draft.durationMinutes,
    performedAt: draft.performedAt,
    dateKey: draft.dateKey,
    timezoneOffsetMinutes: draft.timezoneOffsetMinutes,
    note: draft.note,
    energyEstimate: draft.energyEstimate,
    caloriesBurned: draft.caloriesBurned,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Future<void> dispose() => _changes.close();
}
