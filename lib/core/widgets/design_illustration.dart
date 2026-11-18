import 'package:flutter/material.dart';
import '../theme/app_feature_visuals.dart';

/// Feature artwork kept in the same stroke family as navigation and actions.
class DesignIllustration extends StatelessWidget {
  const DesignIllustration(this.name, {this.size = 40, super.key});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Icon(
      AppFeatureVisual.fromArtwork(name).icon,
      size: size,
      color: AppFeatureVisual.fromArtwork(
        name,
      ).foreground(Theme.of(context).brightness),
      applyTextScaling: false,
    ),
  );
}
