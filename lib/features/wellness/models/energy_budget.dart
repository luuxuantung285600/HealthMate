import '../../../core/utils/local_date_key.dart';
import '../../nutrition_targets/models/nutrition_target.dart';
import '../../activity/models/activity_log.dart';

class WellnessPreferences {
  const WellnessPreferences({
    this.stepLengthCm,
    this.baselineSteps,
    this.sleepGoalMinutes,
  });
  final double? stepLengthCm;
  final int? baselineSteps, sleepGoalMinutes;
  String? validate() {
    if (stepLengthCm != null &&
        (!stepLengthCm!.isFinite ||
            stepLengthCm! < 20 ||
            stepLengthCm! > 200)) {
      return 'Độ dài một bước từ 20 đến 200 cm; để trống nếu chưa đo.';
    }
    if (baselineSteps != null &&
        (baselineSteps! < 0 || baselineSteps! > 150000)) {
      return 'Số bước đã tính trong mục tiêu gốc từ 0 đến 150.000.';
    }
    if (sleepGoalMinutes != null &&
        (sleepGoalMinutes! < 60 || sleepGoalMinutes! > 1440)) {
      return 'Mục tiêu giờ ngủ tự chọn từ 1 đến 24 giờ.';
    }
    return null;
  }

  Map<String, Object?> toData() => {
    'stepLengthCm': stepLengthCm,
    'baselineSteps': baselineSteps,
    'sleepGoalMinutes': sleepGoalMinutes,
    'schemaVersion': 1,
  };
  factory WellnessPreferences.fromData(Map<String, dynamic> d) {
    if (d['schemaVersion'] != 1) {
      throw const FormatException('Phiên bản thiết lập chưa hỗ trợ.');
    }
    final result = WellnessPreferences(
      stepLengthCm: (d['stepLengthCm'] as num?)?.toDouble(),
      baselineSteps: d['baselineSteps'] as int?,
      sleepGoalMinutes: d['sleepGoalMinutes'] as int?,
    );
    if (result.validate() != null) {
      throw const FormatException('Thiết lập chưa hợp lệ.');
    }
    return result;
  }
}

/// Reference only: horizontal/net part of the level ACSM walking equation,
/// 0.1 ml O2/kg/m * approx 5 kcal/L => 0.5 kcal/kg/km above rest.
/// Assumes ordinary level walking; no speed, running, incline or measured burn.
double walkingNetKcal(int steps, double stepLengthCm, double weightKg) =>
    steps * stepLengthCm / 100000 * weightKg * .5;

class StepEnergyEstimate {
  const StepEnergyEstimate(
    this.steps,
    this.stepLengthCm,
    this.weightKg,
    this.baselineSteps,
  );
  final int steps, baselineSteps;
  final double stepLengthCm, weightKg;
  double get distanceKm => steps * stepLengthCm / 100000;
  double get netKcal => walkingNetKcal(steps, stepLengthCm, weightKg);
  double get extraKcal => walkingNetKcal(
    (steps - baselineSteps).clamp(0, 150000),
    stepLengthCm,
    weightKg,
  );
}

class EnergyAdjustment {
  const EnergyAdjustment({
    required this.dateKey,
    required this.timezoneOffsetMinutes,
    required this.steps,
    required this.baselineSteps,
    required this.stepLengthCm,
    required this.weightKg,
    required this.weightMeasuredAt,
    required this.targetFromDateKey,
    required this.baseKcalTarget,
    required this.kcal,
  });
  final String dateKey, targetFromDateKey;
  final int timezoneOffsetMinutes, steps, baselineSteps;
  final double stepLengthCm, weightKg, baseKcalTarget, kcal;
  final DateTime weightMeasuredAt;
  StepEnergyEstimate get estimate =>
      StepEnergyEstimate(steps, stepLengthCm, weightKg, baselineSteps);
  String? validate() {
    if (!isValidDateKey(dateKey) ||
        !isValidDateKey(targetFromDateKey) ||
        targetFromDateKey.compareTo(dateKey) > 0 ||
        timezoneOffsetMinutes < -840 ||
        timezoneOffsetMinutes > 840 ||
        steps < 0 ||
        steps > 150000 ||
        weightKg < 20 ||
        weightKg > 300 ||
        !weightKg.isFinite ||
        WellnessPreferences(
              stepLengthCm: stepLengthCm,
              baselineSteps: baselineSteps,
            ).validate() !=
            null ||
        !baseKcalTarget.isFinite ||
        baseKcalTarget <= 0 ||
        baseKcalTarget > 20000 ||
        !kcal.isFinite ||
        kcal <= 0 ||
        kcal > 5000 ||
        kcal > estimate.extraKcal + .001) {
      return 'Điều chỉnh phải nằm trong phần ước tính vượt mức đã tính sẵn; tối đa 5.000 kcal nhập liệu.';
    }
    return null;
  }
}

class DailyEnergyBudget {
  const DailyEnergyBudget(
    this.baseTarget,
    this.adjustmentKcal,
    this.explanation, {
    this.hasUnappliedAdjustment = false,
    this.activityAdjustmentKcal = 0,
  });
  final NutritionTarget baseTarget;
  final double adjustmentKcal;
  final String explanation;
  final bool hasUnappliedAdjustment;
  final double activityAdjustmentKcal;
  double get stepAdjustmentKcal => adjustmentKcal - activityAdjustmentKcal;
  double get kcalTarget => baseTarget.kcalTarget + adjustmentKcal;
  double remaining(double recordedKcal) => kcalTarget - recordedKcal;
}

DailyEnergyBudget resolveEnergyBudget(
  NutritionTarget target,
  EnergyAdjustment? adjustment, {
  required bool hasManualActivity,
  Iterable<ActivityLog> activities = const [],
}) {
  var activityKcal = 0.0;
  var unapplied = false;
  for (final log in activities) {
    final e = log.energyEstimate;
    if (e == null || !e.includedInBudget) continue;
    if (e.validFor(
          type: log.type.name,
          minutes: log.durationMinutes,
          performedAt: log.performedAt,
          dateKey: log.dateKey,
        ) &&
        e.budgetTargetFromDateKey == target.effectiveFromDateKey &&
        (e.budgetBaseKcal! - target.kcalTarget).abs() <= .001) {
      activityKcal += e.activeKcal;
    } else {
      unapplied = true;
    }
  }
  if (activities.isNotEmpty) hasManualActivity = true;
  if (adjustment == null) {
    return DailyEnergyBudget(
      target,
      activityKcal,
      unapplied
          ? 'Mục tiêu đã đổi; cần xác nhận lại phần vận động chưa áp dụng.'
          : activityKcal > 0
          ? 'Đã cộng vận động ngoài mức thường ngày bạn xác nhận · ước tính; macro giữ nguyên.'
          : 'Mục tiêu gốc · chưa áp dụng điều chỉnh vận động.',
      activityAdjustmentKcal: activityKcal,
      hasUnappliedAdjustment: unapplied,
    );
  }
  if (adjustment.validate() != null) {
    throw const FormatException('Điều chỉnh không hợp lệ.');
  }
  if (target.effectiveFromDateKey != adjustment.targetFromDateKey ||
      (target.kcalTarget - adjustment.baseKcalTarget).abs() > .001) {
    return DailyEnergyBudget(
      target,
      activityKcal,
      'Mục tiêu gốc đã đổi; cần xác nhận lại điều chỉnh.',
      hasUnappliedAdjustment: true,
      activityAdjustmentKcal: activityKcal,
    );
  }
  if (hasManualActivity) {
    return DailyEnergyBudget(
      target,
      activityKcal,
      'Có vận động nhập tay hoặc buổi tập; tạm không cộng bước để tránh tính trùng. Chỉ cộng calo buổi tập đã xác nhận ngoài mức thường ngày.',
      hasUnappliedAdjustment: true,
      activityAdjustmentKcal: activityKcal,
    );
  }
  return DailyEnergyBudget(
    target,
    adjustment.kcal,
    'Đã cộng phần bước bạn xác nhận · ước tính, không đổi mục tiêu macro.',
  );
}
