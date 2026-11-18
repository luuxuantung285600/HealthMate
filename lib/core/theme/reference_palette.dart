import 'package:flutter/material.dart';

/// Shared brand and nutrition colors. Labels always accompany metric colors.
abstract final class ReferencePalette {
  static const brand = Color(0xFF262626);
  // Retained for existing feature widgets using the original token name.
  static const blue = brand;
  static const ink = Color(0xFF171717);
  static const muted = Color(0xFF606060);
  static const carb = Color(0xFF79A8F2);
  static const protein = Color(0xFFF18B88);
  static const fat = Color(0xFFEEC45A);
  static const lightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, .27, .58, 1],
    colors: [Colors.white, Colors.white, Colors.white, Colors.white],
  );
  static const darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, .55, 1],
    colors: [Colors.black, Colors.black, Colors.black],
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
