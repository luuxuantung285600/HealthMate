import '../../../core/utils/local_date_key.dart';

/// Unmodified 2024 Adult Compendium values (ages 19–59).
/// https://pacompendium.com/home/ defines 1 MET = 1 kcal/kg/hour.
class ActivityMet {
  const ActivityMet(this.code, this.type, this.met, this.label, this.page);
  final String code, type, label, page;
  final double met;
  String get sourceUrl => 'https://pacompendium.com/$page/';
}

const activityMetCatalog = <ActivityMet>[
  ActivityMet(
    '17152',
    'walking',
    2.8,
    'Đi bộ chậm · 3,2–3,9 km/h, đường bằng',
    'walking',
  ),
  ActivityMet(
    '17190',
    'walking',
    3.8,
    'Đi bộ vừa · 4,5–5,5 km/h, đường bằng',
    'walking',
  ),
  ActivityMet(
    '17200',
    'walking',
    4.8,
    'Đi bộ nhanh · 5,6–6,3 km/h, đường bằng',
    'walking',
  ),
  ActivityMet(
    '12020',
    'running',
    7.5,
    'Chạy bộ nhẹ · tốc độ tự chọn',
    'running',
  ),
  ActivityMet('12025', 'running', 4.8, 'Chạy tại chỗ', 'running'),
  ActivityMet(
    '01010',
    'cycling',
    4.0,
    'Đạp xe thư giãn · dưới 16 km/h',
    'bicycling',
  ),
  ActivityMet('01020', 'cycling', 6.8, 'Đạp xe · 16–19 km/h', 'bicycling'),
  ActivityMet('01030', 'cycling', 8.0, 'Đạp xe · 19,3–22,4 km/h', 'bicycling'),
  ActivityMet(
    '02024',
    'strength',
    2.8,
    'Thể dục nhẹ · gập bụng, plank',
    'conditioning-exercise',
  ),
  ActivityMet(
    '02056',
    'strength',
    3.0,
    'Kháng lực trọng lượng cơ thể · thông thường',
    'conditioning-exercise',
  ),
  ActivityMet(
    '02022',
    'strength',
    3.8,
    'Thể dục vừa · chống đẩy, gập bụng, lunge',
    'conditioning-exercise',
  ),
  ActivityMet(
    '02020',
    'strength',
    7.5,
    'Thể dục gắng sức mạnh · jumping jack, burpee…',
    'conditioning-exercise',
  ),
  ActivityMet(
    '02054',
    'strength',
    3.5,
    'Tập tạ · nhiều bài, 8–15 lần mỗi hiệp',
    'conditioning-exercise',
  ),
  ActivityMet(
    '02050',
    'strength',
    6.0,
    'Tập tạ · gắng sức mạnh',
    'conditioning-exercise',
  ),
  ActivityMet('02150', 'yoga', 2.3, 'Hatha yoga', 'conditioning-exercise'),
  ActivityMet('02160', 'yoga', 4.0, 'Power yoga', 'conditioning-exercise'),
];

ActivityMet? activityMetForCode(String? code) =>
    activityMetCatalog.where((e) => e.code == code).firstOrNull;

int ageAtActivity(DateTime birthDate, DateTime performedAt) {
  var age = performedAt.year - birthDate.year;
  if (performedAt.month < birthDate.month ||
      (performedAt.month == birthDate.month &&
          performedAt.day < birthDate.day)) {
    age--;
  }
  return age;
}

/// Immutable inputs, rather than caller-supplied calorie totals. Keeping the
/// formula version prevents future catalog/profile changes rewriting history.
class ActivityEnergyEstimate {
  const ActivityEnergyEstimate({
    required this.metCode,
    required this.weightKg,
    required this.weightMeasuredAt,
    required this.ageYears,
    required this.durationSeconds,
    this.budgetTargetFromDateKey,
    this.budgetBaseKcal,
  });
  static const formulaVersion = 1;
  static const sourceLabel = '2024 Adult Compendium · MET × kg × giờ';
  final String metCode;
  final double weightKg;
  final DateTime weightMeasuredAt;
  final int ageYears, durationSeconds;
  final String? budgetTargetFromDateKey;
  final double? budgetBaseKcal;
  ActivityMet get activity => activityMetForCode(metCode)!;
  double get grossKcal => activity.met * weightKg * durationSeconds / 3600;
  double get activeKcal =>
      (activity.met - 1) * weightKg * durationSeconds / 3600;
  bool get includedInBudget => budgetTargetFromDateKey != null;

  ActivityEnergyEstimate withBudget(String? from, double? kcal) =>
      ActivityEnergyEstimate(
        metCode: metCode,
        weightKg: weightKg,
        weightMeasuredAt: weightMeasuredAt,
        ageYears: ageYears,
        durationSeconds: durationSeconds,
        budgetTargetFromDateKey: from,
        budgetBaseKcal: kcal,
      );

  bool validFor({
    required String type,
    required int minutes,
    required DateTime performedAt,
    String? dateKey,
  }) {
    final entry = activityMetForCode(metCode);
    return entry != null &&
        entry.type == type &&
        weightKg.isFinite &&
        weightKg >= 20 &&
        weightKg <= 500 &&
        !weightMeasuredAt.isAfter(performedAt) &&
        ageYears >= 19 &&
        ageYears <= 59 &&
        durationSeconds >= 60 &&
        durationSeconds <= 86400 &&
        durationSeconds ~/ 60 == minutes &&
        ((budgetTargetFromDateKey == null && budgetBaseKcal == null) ||
            (budgetTargetFromDateKey != null &&
                isValidDateKey(budgetTargetFromDateKey!) &&
                budgetTargetFromDateKey!.compareTo(
                      dateKey ?? localDateKey(performedAt),
                    ) <=
                    0 &&
                budgetBaseKcal != null &&
                budgetBaseKcal!.isFinite &&
                budgetBaseKcal! > 0 &&
                budgetBaseKcal! <= 20000));
  }

  Map<String, Object?> toData() => {
    'formulaVersion': formulaVersion,
    'metCode': metCode,
    'weightKg': weightKg,
    'weightMeasuredAtMillis': weightMeasuredAt.millisecondsSinceEpoch,
    'ageYears': ageYears,
    'durationSeconds': durationSeconds,
    'budgetTargetFromDateKey': budgetTargetFromDateKey,
    'budgetBaseKcal': budgetBaseKcal,
  };

  factory ActivityEnergyEstimate.fromData(Map<String, dynamic> d) {
    if (d['formulaVersion'] != formulaVersion) {
      throw const FormatException('Phiên bản ước tính calo chưa hỗ trợ.');
    }
    return ActivityEnergyEstimate(
      metCode: d['metCode'] as String,
      weightKg: (d['weightKg'] as num).toDouble(),
      weightMeasuredAt: DateTime.fromMillisecondsSinceEpoch(
        d['weightMeasuredAtMillis'] as int,
      ),
      ageYears: d['ageYears'] as int,
      durationSeconds: d['durationSeconds'] as int,
      budgetTargetFromDateKey: d['budgetTargetFromDateKey'] as String?,
      budgetBaseKcal: (d['budgetBaseKcal'] as num?)?.toDouble(),
    );
  }
}
