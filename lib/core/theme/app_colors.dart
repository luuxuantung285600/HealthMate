import 'package:flutter/material.dart';

import 'app_feature_visuals.dart';

/// App-wide color definitions
/// Neutral canvases and controls shared by every feature.
abstract final class AppColors {
  // ============================================================================
  // LIGHT THEME COLORS
  // ============================================================================

  /// Canvas/Scaffold background - Pure white
  static const lightCanvas = Colors.white;

  /// Surface - Pure white cards
  static const lightSurface = Color(0xFFFFFFFF);

  /// Surface muted - Subtle gray
  static const lightSurfaceMuted = Color(0xFFF5F5F5);

  /// Primary controls follow the neutral app theme.
  static const lightPrimary = Color(0xFF262626);

  /// On primary - White on dark controls
  static const lightOnPrimary = Color(0xFFFFFFFF);

  /// Text - Near black
  static const lightText = Color(0xFF171717);

  /// Text muted - Neutral gray
  static const lightTextMuted = Color(0xFF606060);

  /// Outline - Light gray
  static const lightOutline = Color(0xFFDFDFDF);

  // ============================================================================
  // DARK THEME COLORS
  // ============================================================================

  /// Canvas - True black for OLED
  static const darkCanvas = Colors.black;

  /// Surface - Neutral charcoal
  static const darkSurface = Color(0xFF121212);

  /// Surface elevated - Neutral raised layer
  static const darkSurfaceElevated = Color(0xFF202020);

  /// Primary controls stay readable on the black canvas.
  static const darkPrimary = Color(0xFFEEEEEE);

  /// On primary - Near black on light controls
  static const darkOnPrimary = Color(0xFF171717);

  /// Text - Off-white
  static const darkText = Color(0xFFF5F5F5);

  /// Text muted - Light gray
  static const darkTextMuted = Color(0xFFBDBDBD);

  /// Outline - Dark gray
  static const darkOutline = Color(0xFF353535);
}

@immutable
class AppMetricColors extends ThemeExtension<AppMetricColors> {
  const AppMetricColors({
    required this.waterContainer,
    required this.onWaterContainer,
    required this.mealContainer,
    required this.onMealContainer,
    required this.activityContainer,
    required this.onActivityContainer,
    required this.weightContainer,
    required this.onWeightContainer,
  });

  static final light = _forBrightness(Brightness.light);
  static final dark = _forBrightness(Brightness.dark);

  static AppMetricColors _forBrightness(Brightness brightness) =>
      AppMetricColors(
        waterContainer: _background(AppFeatureVisual.water, brightness),
        onWaterContainer: AppFeatureVisual.water.foreground(brightness),
        mealContainer: _background(AppFeatureVisual.nutrition, brightness),
        onMealContainer: AppFeatureVisual.nutrition.foreground(brightness),
        activityContainer: _background(AppFeatureVisual.activity, brightness),
        onActivityContainer: AppFeatureVisual.activity.foreground(brightness),
        weightContainer: _background(AppFeatureVisual.weight, brightness),
        onWeightContainer: AppFeatureVisual.weight.foreground(brightness),
      );

  final Color waterContainer;
  final Color onWaterContainer;
  final Color mealContainer;
  final Color onMealContainer;
  final Color activityContainer;
  final Color onActivityContainer;
  final Color weightContainer;
  final Color onWeightContainer;

  @override
  AppMetricColors copyWith({
    Color? waterContainer,
    Color? onWaterContainer,
    Color? mealContainer,
    Color? onMealContainer,
    Color? activityContainer,
    Color? onActivityContainer,
    Color? weightContainer,
    Color? onWeightContainer,
  }) => AppMetricColors(
    waterContainer: waterContainer ?? this.waterContainer,
    onWaterContainer: onWaterContainer ?? this.onWaterContainer,
    mealContainer: mealContainer ?? this.mealContainer,
    onMealContainer: onMealContainer ?? this.onMealContainer,
    activityContainer: activityContainer ?? this.activityContainer,
    onActivityContainer: onActivityContainer ?? this.onActivityContainer,
    weightContainer: weightContainer ?? this.weightContainer,
    onWeightContainer: onWeightContainer ?? this.onWeightContainer,
  );

  static Color _background(AppFeatureVisual feature, Brightness brightness) =>
      Color.alphaBlend(
        feature.background(brightness),
        brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
      );

  @override
  AppMetricColors lerp(AppMetricColors? other, double t) {
    if (other == null) return this;
    return AppMetricColors(
      waterContainer: Color.lerp(waterContainer, other.waterContainer, t)!,
      onWaterContainer: Color.lerp(
        onWaterContainer,
        other.onWaterContainer,
        t,
      )!,
      mealContainer: Color.lerp(mealContainer, other.mealContainer, t)!,
      onMealContainer: Color.lerp(onMealContainer, other.onMealContainer, t)!,
      activityContainer: Color.lerp(
        activityContainer,
        other.activityContainer,
        t,
      )!,
      onActivityContainer: Color.lerp(
        onActivityContainer,
        other.onActivityContainer,
        t,
      )!,
      weightContainer: Color.lerp(weightContainer, other.weightContainer, t)!,
      onWeightContainer: Color.lerp(
        onWeightContainer,
        other.onWeightContainer,
        t,
      )!,
    );
  }
}

extension AppMetricColorsX on BuildContext {
  AppMetricColors get metricColors =>
      Theme.of(this).extension<AppMetricColors>() ?? AppMetricColors.light;
}
