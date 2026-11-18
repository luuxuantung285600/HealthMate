import 'dart:async';
import 'package:healthmate/core/utils/local_date_key.dart';

import 'package:healthmate/features/water/data/water_repository.dart';
import 'package:healthmate/features/water/models/water_log.dart';
import 'package:healthmate/features/journal/models/daily_log_failure.dart';

class FakeWaterRepository implements WaterRepository {
  FakeWaterRepository({List<WaterLog>? logs}) : _logs = [...?logs];

  final List<WaterLog> _logs;
  final _changes = StreamController<void>.broadcast();
  int addCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int undoCalls = 0;
  final _editedIds = <String>{};
  int rangeCalls = 0;
  Object? rangeError;
  int activeDayListeners = 0;

  List<WaterLog> get logs => List.unmodifiable(_logs);

  @override
  Stream<List<WaterLog>> watchLogs(String uid, String dateKey) =>
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
  Future<List<WaterLog>> loadRange(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    rangeCalls++;
    if (rangeError != null) throw rangeError!;
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
    required WaterLogDraft draft,
  }) async {
    addCalls++;
    final id = 'water-$addCalls';
    _logs.add(_toLog(id, draft));
    _changes.add(null);
    return id;
  }

  @override
  Future<void> undoAdd({
    required String uid,
    required String logId,
    required WaterLogDraft draft,
  }) async {
    undoCalls++;
    final index = _logs.indexWhere((log) => log.id == logId);
    if (index < 0) return;
    final log = _logs[index];
    if (_editedIds.contains(logId) ||
        log.amountMl != draft.amountMl ||
        log.consumedAt != draft.consumedAt ||
        log.dateKey != draft.dateKey ||
        log.timezoneOffsetMinutes != draft.timezoneOffsetMinutes) {
      throw const DailyLogFailure(
        'Lần ghi này đã được chỉnh sửa. Hãy kiểm tra trong nhật ký để sửa hoặc xóa.',
        code: 'water-entry-changed',
      );
    }
    _logs.removeAt(index);
    _changes.add(null);
  }

  @override
  Future<void> update({
    required String uid,
    required String logId,
    required WaterLogDraft draft,
  }) async {
    updateCalls++;
    _editedIds.add(logId);
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

  List<WaterLog> _forDate(String dateKey) =>
      _logs.where((log) => log.dateKey == dateKey).toList()
        ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));

  WaterLog _toLog(String id, WaterLogDraft draft) => WaterLog(
    id: id,
    amountMl: draft.amountMl,
    consumedAt: draft.consumedAt,
    dateKey: draft.dateKey,
    timezoneOffsetMinutes: draft.timezoneOffsetMinutes,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Future<void> dispose() => _changes.close();
}
