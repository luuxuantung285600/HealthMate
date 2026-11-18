import 'health_goal.dart';
import 'personalization_answers.dart';

/// Stable screen identifiers keep private drafts independent of screen order.
enum OnboardingStep {
  name,
  formulaSex,
  birthDate,
  height,
  weight,
  goal,
  targetWeight,
  activity,
  guidance,
  pace,
  details,
  exerciseDays,
  exerciseMinutes,
  exerciseType,
  diet,
  avoidFoods,
  produce,
  sweetDrinks,
  sleepHours,
  sleepSchedule,
  barrier,
  priority,
  review,
  plan;

  int get legacySection => switch (this) {
    name || formulaSex || birthDate || height || weight => 0,
    goal => 1,
    targetWeight || guidance || pace => 2,
    activity || exerciseDays || exerciseMinutes || exerciseType => 3,
    diet || avoidFoods || produce || sweetDrinks => 4,
    sleepHours || sleepSchedule || barrier || priority => 5,
    details || plan => 6,
    review => 7,
  };

  static OnboardingStep fromLegacy(int section) => switch (section) {
    1 => goal,
    2 => targetWeight,
    3 => activity,
    4 => diet,
    5 => sleepHours,
    6 => plan,
    7 => review,
    _ => name,
  };
}

List<OnboardingStep> onboardingJourney({
  required HealthGoal? goal,
  required PersonalizationAnswers answers,
  required bool includeDetails,
}) => [
  OnboardingStep.name,
  OnboardingStep.formulaSex,
  OnboardingStep.birthDate,
  OnboardingStep.height,
  OnboardingStep.weight,
  OnboardingStep.goal,
  if (goal?.needsTargetWeight == true) OnboardingStep.targetWeight,
  OnboardingStep.activity,
  OnboardingStep.guidance,
  if (goal?.needsTargetWeight == true) OnboardingStep.pace,
  OnboardingStep.details,
  if (includeDetails) ...[
    OnboardingStep.exerciseDays,
    if (answers['exerciseDays'] != 0) ...[
      OnboardingStep.exerciseMinutes,
      OnboardingStep.exerciseType,
    ],
    OnboardingStep.diet,
    OnboardingStep.avoidFoods,
    OnboardingStep.produce,
    OnboardingStep.sweetDrinks,
    OnboardingStep.sleepHours,
    OnboardingStep.sleepSchedule,
    OnboardingStep.barrier,
    OnboardingStep.priority,
  ],
  OnboardingStep.review,
  OnboardingStep.plan,
];
