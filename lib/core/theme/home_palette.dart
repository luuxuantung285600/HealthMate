import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'reference_palette.dart';

/// A true black Home canvas with colored accents, without tinted overlays.
abstract final class HomePalette {
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Colors.black
      : Colors.white;
  static const protein = ReferencePalette.protein;
  static const carbs = ReferencePalette.carb;
  static const fat = ReferencePalette.fat;

  static final light = AppTheme.light;
  static final dark = AppTheme.dark;
  static ThemeData of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
