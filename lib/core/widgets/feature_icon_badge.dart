import 'package:flutter/material.dart';

import '../theme/app_feature_visuals.dart';

/// Decorative feature identity; the accompanying title supplies its semantics.
class FeatureIconBadge extends StatelessWidget {
  const FeatureIconBadge(this.feature, {this.size = 42, super.key});

  final AppFeatureVisual feature;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: feature.background(brightness),
          borderRadius: BorderRadius.circular(size * .28),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Icon(
          feature.icon,
          color: feature.foreground(brightness),
          size: size * .59,
          applyTextScaling: false,
        ),
      ),
    );
  }
}
