import 'health_goal.dart';
import 'onboarding_journey.dart';
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
    this.screen,
    this.includeDetails = false,
  });
  final int step;
  final String name, height, weight, targetWeight;
  final DateTime? birthDate;
  final HealthGoal? goal;
  final PersonalizationAnswers answers;
  final OnboardingStep? screen;
  final bool includeDetails;
  Map<String, Object?> toJson() => {
    'version': 2,
    'step': step,
    'screen': (screen ?? OnboardingStep.fromLegacy(step)).name,
    'includeDetails': includeDetails,
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
    if (![1, 2].contains(json['version']) || step < 0 || step > 7) {
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
    final screen = json['version'] == 1
        ? OnboardingStep.fromLegacy(step)
        : OnboardingStep.values
              .where((s) => s.name == json['screen'])
              .firstOrNull;
    if (screen == null ||
        (json['version'] == 2 && json['includeDetails'] is! bool)) {
      throw const FormatException('Màn thiết lập trong nháp không hợp lệ.');
    }
    return OnboardingProgress(
      step: step,
      screen: screen,
      includeDetails: json['version'] == 1
          ? step == 4 || step == 5
          : json['includeDetails'] as bool,
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
