import 'package:flutter/material.dart';

import 'app_icons.dart';

/// Distinct feature shapes on the same neutral controls in every app flow.
enum AppFeatureVisual {
  nutrition(AppIcons.nutrition),
  water(AppIcons.water),
  workout(AppIcons.workout),
  activity(AppIcons.activity),
  chatbot(AppIcons.chatbot),
  scanner(AppIcons.scanner),
  weight(AppIcons.weight),
  goals(AppIcons.goals),
  quest(AppIcons.quest),
  profile(AppIcons.profile),
  report(AppIcons.report),
  premium(AppIcons.premium),
  support(AppIcons.support),
  wellness(AppIcons.wellness),
  sleep(AppIcons.sleep),
  steps(AppIcons.steps),
  reminder(AppIcons.sun);

  const AppFeatureVisual(this.icon);

  final IconData icon;

  Color foreground(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xFFEEEEEE)
      : const Color(0xFF262626);

  Color background(Brightness brightness) =>
      foreground(brightness).withValues(alpha: .08);

  static AppFeatureVisual fromArtwork(String name) => switch (name) {
    'steps' => steps,
    'moon' => sleep,
    'water' => water,
    'activity' => workout,
    'sun' => reminder,
    'food' => nutrition,
    'heart' => wellness,
    'weight' => weight,
    'flag' => goals,
    _ => wellness,
  };
}
