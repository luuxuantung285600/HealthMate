import 'package:flutter/material.dart';

import '../theme/app_shapes.dart';

/// A quiet visual group that leaves each child's interaction and semantics intact.
class AppInsetPanel extends StatelessWidget {
  const AppInsetPanel({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.color,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color, borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color ?? scheme.surfaceContainerLow,
        shape: AppShapes.group.copyWith(
          side: borderColor == null
              ? BorderSide.none
              : BorderSide(color: borderColor!),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
