import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_shapes.dart';
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
          primary: isLight ? ReferencePalette.brand : const Color(0xFFEEEEEE),
          onPrimary: isLight ? Colors.white : const Color(0xFF171717),
          primaryContainer: isLight
              ? const Color(0xFFEAEAEA)
              : const Color(0xFF292929),
          onPrimaryContainer: isLight
              ? const Color(0xFF262626)
              : const Color(0xFFEEEEEE),
          secondary: isLight
              ? const Color(0xFF555555)
              : const Color(0xFFCCCCCC),
          onSecondary: isLight ? Colors.white : const Color(0xFF202020),
          secondaryContainer: isLight
              ? const Color(0xFFEEEEEE)
              : const Color(0xFF282828),
          onSecondaryContainer: isLight
              ? const Color(0xFF252525)
              : const Color(0xFFE8E8E8),
          tertiary: isLight ? const Color(0xFF444444) : const Color(0xFFDDDDDD),
          onTertiary: isLight ? Colors.white : const Color(0xFF202020),
          tertiaryContainer: isLight
              ? const Color(0xFFEAEAEA)
              : const Color(0xFF292929),
          onTertiaryContainer: isLight
              ? const Color(0xFF262626)
              : const Color(0xFFEEEEEE),
          primaryFixed: const Color(0xFFEAEAEA),
          primaryFixedDim: const Color(0xFFCCCCCC),
          onPrimaryFixed: const Color(0xFF171717),
          onPrimaryFixedVariant: const Color(0xFF444444),
          secondaryFixed: const Color(0xFFEAEAEA),
          secondaryFixedDim: const Color(0xFFCCCCCC),
          onSecondaryFixed: const Color(0xFF171717),
          onSecondaryFixedVariant: const Color(0xFF444444),
          tertiaryFixed: const Color(0xFFEAEAEA),
          tertiaryFixedDim: const Color(0xFFCCCCCC),
          onTertiaryFixed: const Color(0xFF171717),
          onTertiaryFixedVariant: const Color(0xFF444444),
          surface: isLight ? Colors.white : const Color(0xFF121212),
          surfaceTint: Colors.transparent,
          onSurface: isLight ? ReferencePalette.ink : const Color(0xFFF5F5F5),
          onSurfaceVariant: isLight
              ? ReferencePalette.muted
              : const Color(0xFFBDBDBD),
          outline: isLight ? const Color(0xFF808080) : const Color(0xFF858585),
          outlineVariant: isLight
              ? const Color(0xFFDFDFDF)
              : const Color(0xFF353535),
          surfaceDim: isLight ? const Color(0xFFE8E8E8) : Colors.black,
          surfaceBright: isLight ? Colors.white : const Color(0xFF303030),
          surfaceContainerLowest: isLight
              ? const Color(0xFFF5F5F5)
              : const Color(0xFF121212),
          surfaceContainerLow: isLight
              ? const Color(0xFFF5F5F5)
              : const Color(0xFF181818),
          surfaceContainer: isLight
              ? const Color(0xFFF0F0F0)
              : const Color(0xFF202020),
          surfaceContainerHigh: isLight
              ? const Color(0xFFEAEAEA)
              : const Color(0xFF282828),
          surfaceContainerHighest: isLight
              ? const Color(0xFFE4E4E4)
              : const Color(0xFF353535),
          inverseSurface: isLight
              ? const Color(0xFF292929)
              : const Color(0xFFE8E8E8),
          onInverseSurface: isLight
              ? const Color(0xFFF5F5F5)
              : const Color(0xFF202020),
          error: isLight ? const Color(0xFFBA2432) : const Color(0xFFFFAEB7),
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: DesignTokens.fontFamily,
      scaffoldBackgroundColor: isLight ? Colors.white : Colors.black,
      extensions: [isLight ? AppMetricColors.light : AppMetricColors.dark],
    );
    final text = base.textTheme
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
        .copyWith(
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontSize: 13,
            color: scheme.onSurface,
          ),
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
    );
    final button = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return base.copyWith(
      iconTheme: IconThemeData(size: 24, color: scheme.onSurfaceVariant),
      textTheme: text.copyWith(
        displayLarge: text.displayLarge?.copyWith(
          fontSize: 40,
          fontWeight: FontWeight.w600,
        ),
        displayMedium: text.displayMedium?.copyWith(
          fontSize: 35,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: text.displaySmall?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: text.headlineLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          height: 1.3,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          height: 1.3,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          height: 1.35,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.35,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        titleSmall: text.titleSmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 15, height: 1.5),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 13, height: 1.5),
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
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: AppShapes.surface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: shape,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        titleTextStyle: text.titleLarge?.copyWith(fontSize: 18, height: 1.3),
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
        selectedColor: scheme.primary.withValues(alpha: .12),
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.outlineVariant,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.groupRadius),
        ),
        labelStyle: text.labelMedium?.copyWith(color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: .7,
        space: 1,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isLight ? Colors.white : Colors.black,
        indicatorColor: scheme.surfaceContainerHigh,
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
