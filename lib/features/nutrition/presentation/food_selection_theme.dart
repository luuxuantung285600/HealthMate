import 'package:flutter/material.dart';
import '../../../core/theme/home_palette.dart';

/// Food discovery follows the same black/white canvas as Home.
ThemeData foodSelectionTheme(BuildContext context) {
  final base = HomePalette.of(context);
  final scheme = base.colorScheme.copyWith(
    secondaryContainer: base.colorScheme.primaryContainer,
    onSecondaryContainer: base.colorScheme.onPrimaryContainer,
  );
  return base.copyWith(
    colorScheme: scheme,
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: scheme.surfaceContainerLow,
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.primary,
      labelStyle: base.textTheme.labelMedium?.copyWith(color: scheme.onSurface),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      fillColor: scheme.surfaceContainerLow,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    dialogTheme: base.dialogTheme.copyWith(backgroundColor: scheme.surface),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      backgroundColor: scheme.surfaceContainerLow,
      modalBackgroundColor: scheme.surfaceContainerLow,
    ),
  );
}
