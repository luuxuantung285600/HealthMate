import '../../profile/models/body_metric.dart';
import '../../profile/models/health_goal.dart';
import '../../profile/models/user_profile.dart';
import 'energy_estimate.dart';
import 'nutrition_target.dart';

/// Versioned product policy, not a prediction of weight loss or a medical diet.
enum PlanActivity {
  sedentary('Chủ yếu ngồi', 'Ít đi lại hoặc hoạt động thể lực', 1.4),
  light('Hoạt động nhẹ', 'Có đi bộ, việc nhà và vận động nhẹ thường ngày', 1.6),
  active('Hoạt động vừa', 'Thường xuyên đứng, đi lại hoặc tập luyện vừa', 1.8),
  heavy(
    'Hoạt động nhiều',
    'Công việc thể lực hoặc vận động nhiều hằng ngày',
    2.0,
  );

  const PlanActivity(this.label, this.description, this.factor);
  final String label;
  final String description;
  final double factor;
}

enum PlanPace {
  gentle('Nhẹ', .10, .05),
  moderate('Vừa', .15, .10);

  const PlanPace(this.label, this.lossFraction, this.gainFraction);
  final String label;
  final double lossFraction;
  final double gainFraction;
}

enum PlanMacroSplit {
  balanced('Cân đối', .20, .50, .30),
  proteinFocus('Ưu tiên đạm', .25, .45, .30);

  const PlanMacroSplit(this.label, this.protein, this.carbs, this.fat);
  final String label;
  final double protein;
  final double carbs;
  final double fat;
}

int ageOnDate(DateTime birthDate, DateTime today) {
  var age = today.year - birthDate.year;
  if (today.month < birthDate.month ||
      (today.month == birthDate.month && today.day < birthDate.day)) {
    age--;
  }
  return age;
}

class PersonalNutritionSeed {
  const PersonalNutritionSeed({
    this.age,
    this.heightCm,
    this.weightKg,
    this.goal,
    this.targetWeightKg,
  });

  factory PersonalNutritionSeed.fromProfile(
    UserProfile profile,
    BodyMetric? weight,
    DateTime today,
  ) {
    // Do not silently use a future or stale weight as a current measurement.
    final fresh =
        weight != null &&
        !weight.measuredAt.isAfter(today) &&
        today.difference(weight.measuredAt) <= const Duration(days: 90);
    return PersonalNutritionSeed(
      age: profile.birthDate == null
          ? null
          : ageOnDate(profile.birthDate!, today),
      heightCm: profile.heightCm,
      weightKg: fresh ? weight.weightKg : null,
      goal: profile.healthGoal,
      targetWeightKg: profile.targetWeightKg,
    );
  }

  final int? age;
  final double? heightCm;
  final double? weightKg;
  final HealthGoal? goal;
  final double? targetWeightKg;
}

class PersonalNutritionInput {
  const PersonalNutritionInput({
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.sex,
    required this.activity,
    required this.goal,
    this.targetWeightKg,
    this.pace = PlanPace.gentle,
    this.macros = PlanMacroSplit.balanced,
    this.eligible = false,
  });

  final int? age;
  final double? heightCm;
  final double? weightKg;
  final FormulaSex? sex;
  final PlanActivity? activity;
  final HealthGoal? goal;
  final double? targetWeightKg;
  final PlanPace pace;
  final PlanMacroSplit macros;
  final bool eligible;

  bool get changesWeight => goal?.needsTargetWeight == true;
  double get adjustmentFraction => switch (goal) {
    HealthGoal.loseWeight => -pace.lossFraction,
    HealthGoal.gainWeightOrMuscle => pace.gainFraction,
    _ => 0,
  };

  String? validate() {
    if (!eligible) {
      return 'Hãy xác nhận phạm vi áp dụng hoặc chọn nhập mục tiêu thủ công.';
    }
    if (age == null || age! < 18 || age! > 65) {
      return 'Đề xuất tự động hiện dành cho tuổi 18–65; ngoài phạm vi hãy dùng mục tiêu được tư vấn riêng.';
    }
    if (heightCm == null ||
        !heightCm!.isFinite ||
        heightCm! < 80 ||
        heightCm! > 250 ||
        weightKg == null ||
        !weightKg!.isFinite ||
        weightKg! < 20 ||
        weightKg! > 300) {
      return 'Kiểm tra chiều cao (80–250 cm) và cân nặng hiện tại (20–300 kg).';
    }
    if (sex == null || activity == null || goal == null) {
      return 'Chọn hệ số sinh lý, mức hoạt động và mục tiêu của bạn.';
    }
    final heightM = heightCm! / 100;
    final bmi = weightKg! / (heightM * heightM);
    if (bmi < 18.5 || bmi >= 40) {
      String number(double value, int precision) => value
          .toStringAsFixed(precision)
          .replaceFirst(RegExp(r'\.?0+$'), '')
          .replaceAll('.', ',');
      final range = bmi < 18.5 ? 'dưới 18,5' : 'từ 40 trở lên';
      // Rounding must not tell someone that an ineligible value is exactly
      // on the inclusive boundary (for example 18.49975 displayed as 18.50).
      final bmiLabel = bmi < 18.5 && bmi.toStringAsFixed(2) == '18.50'
          ? 'gần 18,5 nhưng vẫn dưới ngưỡng'
          : '${number(bmi, 2)} ($range)';
      return 'BMI hiện tại $bmiLabel, tính từ '
          '${number(heightCm!, 1)} cm và ${number(weightKg!, 1)} kg. '
          'HealthMate chưa tự đề xuất calo trong phạm vi này. '
          'Bạn vẫn có thể chọn mục tiêu ${goal!.label.toLowerCase()}. '
          'Kiểm tra lại số đo hoặc nhập mục tiêu dinh dưỡng được tư vấn riêng; '
          'BMI chỉ là chỉ số tham khảo.';
    }
    if (changesWeight) {
      final target = targetWeightKg;
      if (target == null || !target.isFinite || target < 20 || target > 300) {
        return 'Nhập cân nặng mục tiêu hợp lệ để kiểm tra kế hoạch.';
      }
      if (goal == HealthGoal.loseWeight && target >= weightKg!) {
        return 'Mục tiêu giảm cân cần thấp hơn cân nặng hiện tại.';
      }
      if (goal == HealthGoal.gainWeightOrMuscle && target <= weightKg!) {
        return 'Mục tiêu tăng cân cần cao hơn cân nặng hiện tại; nếu muốn giữ cân và tập cơ, chọn duy trì.';
      }
      if (target / (heightM * heightM) < 18.5 ||
          target / (heightM * heightM) >= 40) {
        return 'Cân nặng đích nằm ngoài phạm vi đề xuất tự động; hãy kiểm tra lại hoặc dùng mục tiêu được tư vấn riêng.';
      }
    }
    return null;
  }

  PersonalNutritionPlan calculate() {
    final error = validate();
    if (error != null) throw FormatException(error);
    // Mifflin et al. 1990, original regression coefficients (kcal/day).
    final resting =
        9.99 * weightKg! +
        6.25 * heightCm! -
        4.92 * age! +
        (sex == FormulaSex.male ? 5 : -161);
    final maintenance = resting * activity!.factor;
    final target = (maintenance * (1 + adjustmentFraction) / 10).round() * 10.0;
    // Conservative app bounds, NOT universal safe-intake thresholds. Do not
    // silently clamp a requested plan into a different goal or pace.
    final lowerBound = sex == FormulaSex.male ? 1500 : 1200;
    if (!target.isFinite || target < lowerBound || target > 5000) {
      throw const FormatException(
        'Kết quả vượt phạm vi đề xuất của HealthMate. Hãy chọn nhịp nhẹ hơn, kiểm tra thông tin hoặc dùng mục tiêu được tư vấn riêng.',
      );
    }
    return PersonalNutritionPlan(
      input: this,
      restingKcal: resting,
      maintenanceKcal: maintenance,
      kcal: target,
    );
  }
}

class PersonalNutritionPlan {
  const PersonalNutritionPlan({
    required this.input,
    required this.restingKcal,
    required this.maintenanceKcal,
    required this.kcal,
  });
  final PersonalNutritionInput input;
  final double restingKcal;
  final double maintenanceKcal;
  final double kcal;
  double _round(double n) => (n * 10).round() / 10.0;
  double get proteinG => _round(kcal * input.macros.protein / 4);
  double get carbsG => _round(kcal * input.macros.carbs / 4);
  double get fatG => _round(kcal * input.macros.fat / 9);

  NutritionTarget toTarget(
    String dateKey, {
    NutritionTarget? preserveMarkers,
  }) => NutritionTarget(
    effectiveFromDateKey: dateKey,
    kcalTarget: kcal,
    proteinGTarget: proteinG,
    carbsGTarget: carbsG,
    fatGTarget: fatG,
    saltGLimit: preserveMarkers?.saltGLimit,
    sugarGLimit: preserveMarkers?.sugarGLimit,
    fiberGTarget: preserveMarkers?.fiberGTarget,
  );
}

bool sameNutritionTarget(NutritionTarget? a, NutritionTarget? b) =>
    a?.effectiveFromDateKey == b?.effectiveFromDateKey &&
    a?.kcalTarget == b?.kcalTarget &&
    a?.proteinGTarget == b?.proteinGTarget &&
    a?.carbsGTarget == b?.carbsGTarget &&
    a?.fatGTarget == b?.fatGTarget &&
    a?.saltGLimit == b?.saltGLimit &&
    a?.sugarGLimit == b?.sugarGLimit &&
    a?.fiberGTarget == b?.fiberGTarget;
