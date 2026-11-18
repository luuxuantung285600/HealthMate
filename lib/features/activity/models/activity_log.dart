import '../../../core/utils/local_date_key.dart';
import 'activity_energy.dart';

enum ActivityType {
  walking('Đi bộ'),
  running('Chạy bộ'),
  cycling('Đạp xe'),
  strength('Tập sức mạnh'),
  yoga('Yoga'),
  other('Khác');

  const ActivityType(this.label);
  final String label;
}

class ActivityLogDraft {
  const ActivityLogDraft({
    required this.type,
    required this.durationMinutes,
    required this.performedAt,
    this.note = '',
    double? caloriesBurned,
    this.energyEstimate,
  }) : _legacyCaloriesBurned = caloriesBurned;

  final ActivityType type;
  final int durationMinutes;
  final DateTime performedAt;
  final String note;
  final ActivityEnergyEstimate? energyEstimate;
  final double? _legacyCaloriesBurned;

  /// Energy above resting expenditure, never measured calories.
  double? get caloriesBurned =>
      energyEstimate?.activeKcal ?? _legacyCaloriesBurned;

  int get timezoneOffsetMinutes => performedAt.timeZoneOffset.inMinutes;
  String get dateKey =>
      dateKeyFromTimestampAndOffset(performedAt, timezoneOffsetMinutes);
}

class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.type,
    required this.durationMinutes,
    required this.performedAt,
    required this.dateKey,
    required this.timezoneOffsetMinutes,
    required this.note,
    double? caloriesBurned,
    this.energyEstimate,
    this.createdAt,
    this.updatedAt,
  }) : _legacyCaloriesBurned = caloriesBurned;

  final String id;
  final ActivityType type;
  final int durationMinutes;
  final DateTime performedAt;
  final String dateKey;
  final int timezoneOffsetMinutes;
  final String note;
  final ActivityEnergyEstimate? energyEstimate;
  final double? _legacyCaloriesBurned;
  double? get caloriesBurned =>
      energyEstimate?.activeKcal ?? _legacyCaloriesBurned;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ActivityLogDraft toDraft() => ActivityLogDraft(
    type: type,
    durationMinutes: durationMinutes,
    performedAt: performedAt,
    note: note,
    caloriesBurned: caloriesBurned,
    energyEstimate: energyEstimate,
  );
}

int totalActivityMinutes(Iterable<ActivityLog> logs) =>
    logs.fold(0, (sum, log) => sum + log.durationMinutes);

double totalCaloriesBurned(Iterable<ActivityLog> logs) =>
    logs.fold(0.0, (sum, log) => sum + (log.caloriesBurned ?? 0));

abstract final class ActivityValidation {
  static const maxNoteLength = 200;

  static String? duration(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return 'Nhập thời lượng bằng số nguyên.';
    if (parsed < 1 || parsed > 1440) return 'Thời lượng từ 1 đến 1.440 phút.';
    return null;
  }

  static String? note(String? value) {
    if ((value ?? '').trim().length > maxNoteLength) {
      return 'Ghi chú tối đa 200 ký tự.';
    }
    return null;
  }

  static String? performedAt(DateTime value, {DateTime? now}) {
    if (value.isAfter(
      (now ?? DateTime.now()).add(const Duration(minutes: 5)),
    )) {
      return 'Thời điểm vận động không thể ở tương lai.';
    }
    return null;
  }
}
