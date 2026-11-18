import '../../../core/utils/local_date_key.dart';

class NutritionTargetFailure implements Exception {
  const NutritionTargetFailure([
    this.message = 'Chưa thể tải hoặc lưu mục tiêu dinh dưỡng. Hãy thử lại.',
  ]);
  final String message;
}

class NutritionTarget {
  const NutritionTarget({
    required this.effectiveFromDateKey,
    required this.kcalTarget,
    this.proteinGTarget,
    this.carbsGTarget,
    this.fatGTarget,
    this.saltGLimit,
    this.sugarGLimit,
    this.fiberGTarget,
  });
  final String effectiveFromDateKey;
  final double kcalTarget;
  final double? proteinGTarget;
  final double? carbsGTarget;
  final double? fatGTarget;
  // Optional user-defined daily markers; no automatic medical recommendation.
  final double? saltGLimit, sugarGLimit, fiberGTarget;
  NutritionTarget withMarkersFrom(NutritionTarget? previous) => NutritionTarget(
    effectiveFromDateKey: effectiveFromDateKey,
    kcalTarget: kcalTarget,
    proteinGTarget: proteinGTarget,
    carbsGTarget: carbsGTarget,
    fatGTarget: fatGTarget,
    saltGLimit: previous?.saltGLimit,
    sugarGLimit: previous?.sugarGLimit,
    fiberGTarget: previous?.fiberGTarget,
  );
  bool get hasMacros =>
      proteinGTarget != null && carbsGTarget != null && fatGTarget != null;
  double? get macroKcal => hasMacros
      ? 4 * proteinGTarget! + 4 * carbsGTarget! + 9 * fatGTarget!
      : null;
  bool get needsMacroConfirmation =>
      hasMacros && (macroKcal! - kcalTarget).abs() / kcalTarget > .05;

  String? validate({String? earliestDateKey}) {
    if (!isValidDateKey(effectiveFromDateKey)) {
      return 'Ngày áp dụng không hợp lệ.';
    }
    if (earliestDateKey != null &&
        effectiveFromDateKey.compareTo(earliestDateKey) < 0) {
      return 'Chỉ áp dụng từ hôm nay hoặc ngày tương lai; lịch sử được giữ nguyên.';
    }
    if (!kcalTarget.isFinite || kcalTarget <= 0 || kcalTarget > 20000) {
      return 'Nhập mục tiêu năng lượng lớn hơn 0 và tối đa 20.000 kcal.';
    }
    final macros = [proteinGTarget, carbsGTarget, fatGTarget];
    if (macros.any((v) => v != null) && macros.any((v) => v == null)) {
      return 'Nhập đủ cả ba chất hoặc để trống cả ba.';
    }
    if (macros.any((v) => v != null && (!v.isFinite || v < 0 || v > 5000))) {
      return 'Mỗi mục tiêu chất phải là số từ 0 đến 5.000 g.';
    }
    for (final entry in [
      ('muối', saltGLimit, 50),
      ('đường tổng', sugarGLimit, 500),
      ('chất xơ', fiberGTarget, 200),
    ]) {
      final value = entry.$2;
      if (value != null && (!value.isFinite || value < 0 || value > entry.$3)) {
        return 'Mốc ${entry.$1}: nhập từ 0 đến ${entry.$3} g/ngày hoặc để trống.';
      }
    }
    return null;
  }
}

/// Pure date selection used by fixtures/range consumers; repository queries one
/// applicable version instead of downloading all versions.
NutritionTarget? targetForDate(Iterable<NutritionTarget> targets, String day) {
  NutritionTarget? result;
  for (final target in targets) {
    if (target.effectiveFromDateKey.compareTo(day) <= 0 &&
        (result == null ||
            target.effectiveFromDateKey.compareTo(result.effectiveFromDateKey) >
                0)) {
      result = target;
    }
  }
  return result;
}

class TargetComparison {
  const TargetComparison({required this.recorded, required this.target});
  final double recorded;
  final double target;
  double get remaining => (target - recorded).clamp(0, double.infinity);
  double get excess => (recorded - target).clamp(0, double.infinity);
  double? get progress => target > 0 ? (recorded / target).clamp(0, 1) : null;
}
