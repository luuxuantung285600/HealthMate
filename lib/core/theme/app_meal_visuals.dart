import 'package:flutter/material.dart';

import '../../features/nutrition/models/nutrition_models.dart';
import 'app_icons.dart';

/// Meal identity uses small accents while surfaces keep the app's neutral theme.
abstract final class AppMealVisuals {
  static Color color(BuildContext context, MealType type) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (type) {
      MealType.breakfast =>
        dark ? const Color(0xFFF5C15A) : const Color(0xFF8A5900),
      MealType.lunch =>
        dark ? const Color(0xFFFFA180) : const Color(0xFFAD4524),
      MealType.dinner =>
        dark ? const Color(0xFF85B8FF) : const Color(0xFF2864AA),
      MealType.snack =>
        dark ? const Color(0xFFEDA8C0) : const Color(0xFF9C3C66),
    };
  }

  static IconData icon(MealType type) => switch (type) {
    MealType.breakfast => AppIcons.coffee,
    MealType.lunch => AppIcons.sandwich,
    MealType.dinner => AppIcons.cookingPot,
    MealType.snack => AppIcons.cookie,
  };
}
