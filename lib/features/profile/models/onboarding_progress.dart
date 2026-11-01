import 'health_goal.dart';
import 'personalization_answers.dart';

/// Incomplete input is a private draft, never a completed health profile.
class OnboardingProgress {
  const OnboardingProgress({
    required this.step,
    required this.name,
    required this.height,
    required this.weight,
    required this.targetWeight,
    required this.answers,
    this.birthDate,
    this.goal,
  });
  final int step;
  final String name, height, weight, targetWeight;
  final DateTime? birthDate;
  final HealthGoal? goal;
  final PersonalizationAnswers answers;
  Map<String, Object?> toJson() => {
    'version': 1,
    'step': step,
    'name': name,
    'height': height,
    'weight': weight,
    'targetWeight': targetWeight,
    'birthDate': birthDate?.toIso8601String(),
    'goal': goal?.value,
    'answers': answers.toMap(),
  };

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    final step = json['step'] as int;
    if (json['version'] != 1 || step < 0 || step > 7) {
      throw const FormatException('Bước thiết lập không hợp lệ.');
    }
    String text(String key, int max) {
      final value = json[key] as String;
      if (value.length > max) throw const FormatException('Nháp quá dài.');
      return value;
    }

    final goal = HealthGoal.fromValue(json['goal']);
    if (json['goal'] != null && goal == null) {
      throw const FormatException('Mục tiêu trong nháp không hợp lệ.');
    }
    return OnboardingProgress(
      step: step,
      name: text('name', 200),
      height: text('height', 40),
      weight: text('weight', 40),
      targetWeight: text('targetWeight', 40),
      birthDate: json['birthDate'] == null
          ? null
          : DateTime.parse(json['birthDate'] as String),
      goal: goal,
      answers: PersonalizationAnswers.fromMap(
        Map<String, dynamic>.from(json['answers'] as Map),
      ),
    );
  }
}
