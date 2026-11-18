import 'package:flutter/material.dart';

/// Continuous section corners differ from the compact controls inside them.
abstract final class AppShapes {
  static const surface = ContinuousRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(32)),
  );
  static const group = ContinuousRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );
}
