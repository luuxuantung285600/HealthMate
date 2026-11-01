import 'package:flutter/material.dart';

/// Shared brand and nutrition colors. Labels always accompany metric colors.
abstract final class ReferencePalette {
  static const brand = Color(0xFF167553);
  // Retained for existing feature widgets using the original token name.
  static const blue = brand;
  static const ink = Color(0xFF171818);
  static const muted = Color(0xFF5F6269);
  static const carb = Color(0xFF67CAD3);
  static const protein = Color(0xFF76C87A);
  static const fat = Color(0xFFFFCB48);
  static const lightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, .27, .58, 1],
    colors: [
      Color(0xFFF5F7F6),
      Color(0xFFF5F7F6),
      Color(0xFFF5F7F6),
      Color(0xFFF5F7F6),
    ],
  );
  static const darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, .55, 1],
    colors: [Color(0xFF141C19), Color(0xFF141C19), Color(0xFF141C19)],
  );
}

class AppCanvas extends StatelessWidget {
  const AppCanvas({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: Theme.of(context).brightness == Brightness.dark
          ? ReferencePalette.darkGradient
          : ReferencePalette.lightGradient,
    ),
    child: child,
  );
}
