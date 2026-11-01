import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'design_tokens.dart';
import 'reference_palette.dart';

/// Reference v2 UI with the bundled, distributable Vietnamese font.
abstract final class AppTheme {
  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: ReferencePalette.blue,
          brightness: brightness,
        ).copyWith(
          primary: isLight ? ReferencePalette.brand : const Color(0xFF8CDBB9),
          onPrimary: isLight ? Colors.white : const Color(0xFF073B28),
          surface: isLight ? Colors.white : const Color(0xFF202B26),
          onSurface: isLight ? ReferencePalette.ink : const Color(0xFFF5F6FA),
          onSurfaceVariant: isLight
              ? ReferencePalette.muted
              : const Color(0xFFBCCBC3),
          outline: isLight ? const Color(0xFF78877F) : const Color(0xFF879B90),
          outlineVariant: isLight
              ? const Color(0xFFDEDFE3)
              : const Color(0xFF41564A),
          surfaceContainerLowest: isLight
              ? Colors.white
              : const Color(0xFF202B26),
          surfaceContainerLow: isLight
              ? const Color(0xFFF6F8F7)
              : const Color(0xFF29372F),
          surfaceContainer: isLight ? Colors.white : const Color(0xFF29372F),
          surfaceContainerHighest: isLight
              ? const Color(0xFFE5EDE8)
              : const Color(0xFF41564A),
          error: isLight ? const Color(0xFFBA2432) : const Color(0xFFFFAEB7),
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: DesignTokens.fontFamily,
      scaffoldBackgroundColor: Colors.transparent,
      extensions: [isLight ? AppMetricColors.light : AppMetricColors.dark],
    );
    final text = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
    );
    final button = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return base.copyWith(
      textTheme: text.copyWith(
        displayLarge: text.displayLarge?.copyWith(
          fontSize: 44,
          fontWeight: FontWeight.w600,
        ),
        displayMedium: text.displayMedium?.copyWith(
          fontSize: 38,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: text.displaySmall?.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: text.headlineLarge?.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w400,
          height: 1.3,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          height: 1.3,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          height: 1.35,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          height: 1.35,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        titleSmall: text.titleSmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
        bodySmall: text.bodySmall?.copyWith(fontSize: 12, height: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: shape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: shape,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        titleTextStyle: text.titleLarge?.copyWith(fontSize: 20, height: 1.3),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: button,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w400),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: button,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: button,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        errorMaxLines: 4,
        helperMaxLines: 3,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: isLight ? Colors.white : scheme.primaryContainer,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: text.labelMedium?.copyWith(color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: .7,
        space: 1,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isLight ? ReferencePalette.blue : scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
    );
  }
}
