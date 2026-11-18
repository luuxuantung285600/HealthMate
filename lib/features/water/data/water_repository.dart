import '../models/water_log.dart';

abstract interface class WaterRepository {
  Stream<List<WaterLog>> watchLogs(String uid, String dateKey);

  Future<List<WaterLog>> loadRange(String uid, DateTime start, DateTime end);

  Future<String> add({required String uid, required WaterLogDraft draft});

  /// Undo a newly added entry only if it has not been edited since creation.
  /// An already absent entry is a successful, idempotent undo.
  Future<void> undoAdd({
    required String uid,
    required String logId,
    required WaterLogDraft draft,
  });

  Future<void> update({
    required String uid,
    required String logId,
    required WaterLogDraft draft,
  });

  Future<void> delete({required String uid, required String logId});
}
