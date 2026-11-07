/// HealthMate typography, spacing and supporting metric tokens.
library;

import 'package:flutter/material.dart';

/// Design Tokens - Single source of truth cho design system
abstract final class DesignTokens {
  // ============================================================================
  // COLOR PALETTE - Modern Minimalist
  // ============================================================================

  /// Base colors - MyFitnessPal-style dark navy
  static const navy900 = Color(0xFF1C1F2E); // MyFitnessPal dark bg
  static const navy800 = Color(0xFF282B3B); // Card bg
  static const navy700 = Color(0xFF363A4D); // Elevated card
  static const navy600 = Color(0xFF4A5068);
  static const navy500 = Color(0xFF64748B);
  static const navy400 = Color(0xFF94A3B8);
  static const navy300 = Color(0xFFCBD5E1);
  static const navy200 = Color(0xFFE2E8F0);
  static const navy100 = Color(0xFFF1F5F9);
  static const navy50 = Color(0xFFF8FAFC);

  /// Primary accent - MyFitnessPal blue
  static const blue600 = Color(0xFF1E3A8A); // Dark blue
  static const blue500 = Color(0xFF2B5FB8); // MyFitnessPal blue (primary)
  static const blue400 = Color(0xFF3B82F6); // Bright blue
  static const blue300 = Color(0xFF60A5FA);
  static const blue200 = Color(0xFF93C5FD);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue50 = Color(0xFFEFF6FF);

  /// Cyan scale used by the existing themes and water metric cards.
  static const cyan600 = Color(0xFF0891B2);
  static const cyan500 = Color(0xFF06B6D4); // Carbs color
  static const cyan400 = Color(0xFF22D3EE);
  static const cyan300 = Color(0xFF67E8F9);
  static const cyan200 = Color(0xFFA5F3FC);
  static const cyan100 = Color(0xFFCFFAFE);
  static const cyan50 = Color(0xFFECFEFF);

  /// Accent colors - MyFitnessPal style
  static const purple500 = Color(0xFFA855F7); // Fat color
  static const yellow500 = Color(0xFFF59E0B); // Premium button

  /// Secondary accent - Warm orange
  static const orange600 = Color(0xFFEA580C); // Orange dark
  static const orange500 = Color(0xFFF97316); // Warm orange (secondary)
  static const orange400 = Color(0xFFFB923C);
  static const orange300 = Color(0xFFFDBA74);
  static const orange200 = Color(0xFFFED7AA);
  static const orange100 = Color(0xFFFFEDD5);
  static const orange50 = Color(0xFFFFF7ED);

  /// Metric-specific colors (MyFitnessPal style)
  static const waterPrimary = cyan500;
  static const waterLight = Color(0xFF67E8F9);
  static const waterDark = Color(0xFF0891B2);

  static const mealPrimary = orange500;
  static const mealLight = Color(0xFFFDBA74);
  static const mealDark = Color(0xFFEA580C);

  static const activityPrimary = Color(0xFF10B981); // Emerald
  static const activityLight = Color(0xFFA7F3D0);
  static const activityDark = Color(0xFF059669);

  static const weightPrimary = Color(0xFF8B5CF6); // Purple
  static const weightLight = Color(0xFFDDD6FE);
  static const weightDark = Color(0xFF7C3AED);

  /// Macro colors shared with ReferencePalette across nutrition screens.
  static const carbsColor = Color(0xFF67CAD3);
  static const fatColor = Color(0xFFFFCB48);
  static const proteinColor = Color(0xFF76C87A);

  /// Semantic colors
  static const success = Color(0xFF10B981);
  static const warning = orange500;
  static const error = Color(0xFFEF4444);
  static const info = blue500;

  // ============================================================================
  // TYPOGRAPHY
  // ============================================================================

  /// Bundled font with Vietnamese glyphs; no network font loading.
  /// Assets and font license are declared in pubspec.yaml and assets/fonts.
  static const fontFamily = 'Inter';
  static const fontFamilyFallback = 'Inter';

  /// Font weights
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  /// Letter spacing for headings (tight)
  static const double headingLetterSpacing = -0.02;

  /// Line heights
  static const double headingLineHeight = 1.2;
  static const double bodyLineHeight = 1.5;
  static const double compactLineHeight = 1.3;

  // ============================================================================
  // SPACING - 8px base unit
  // ============================================================================

  static const double space0 = 0;
  static const double space4 = 4; // xs
  static const double space8 = 8; // sm
  static const double space12 = 12; // md-sm
  static const double space16 = 16; // md
  static const double space20 = 20; // md-lg
  static const double space24 = 24; // lg
  static const double space32 = 32; // xl
  static const double space40 = 40; // 2xl
  static const double space48 = 48; // 3xl
  static const double space64 = 64; // 4xl
  static const double space80 = 80; // 5xl

  // ============================================================================
  // BORDER RADIUS - Softer than before
  // ============================================================================

  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const double radius2xl = 32;
  static const double radiusFull = 999;

  /// Component-specific radius
  static const double cardRadius = radiusXl;
  static const double buttonRadius = radiusMd; // 16px (was 18px)
  static const double inputRadius = radiusMd; // 16px
  static const double chipRadius = radiusFull; // pill shape

  // ============================================================================
  // SHADOWS - Subtle elevation
  // ============================================================================

  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0D000000), // 5% opacity
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x26000000), // 15% opacity
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // ============================================================================
  // GLASSMORPHISM - Subtle backdrop blur effect
  // ============================================================================

  static const double glassOpacity = 0.7;
  static const double glassBlur = 12;

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================

  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  // ============================================================================
  // ANIMATION CURVES - Spring-like feel
  // ============================================================================

  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseInOut = Curves.easeInOut;
  static const Curve curveSpring = Curves.easeOutCubic; // Spring-like

  // ============================================================================
  // SIZES
  // ============================================================================

  static const double iconSizeSm = 20;
  static const double iconSizeMd = 24;
  static const double iconSizeLg = 32;
  static const double iconSizeXl = 40;

  static const double buttonHeightSm = 40;
  static const double buttonHeightMd = 48;
  static const double buttonHeightLg = 56;

  static const double inputHeight = 56;

  // ============================================================================
  // BREAKPOINTS
  // ============================================================================

  static const double breakpointMobile = 600;
  static const double breakpointTablet = 840;
  static const double breakpointDesktop = 1200;

  /// Content max width for readability
  static const double contentMaxWidth = 960;
}
