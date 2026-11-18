import 'package:flutter/material.dart';

class ReferenceSegments extends StatelessWidget {
  const ReferenceSegments({required this.items, super.key});
  final List<({String label, bool selected, VoidCallback onTap, Key key})>
  items;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final theme = Theme.of(context);
      final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final children = [
        for (final item in items)
          Semantics(
            selected: item.selected,
            child: TextButton(
              key: item.key,
              onPressed: item.onTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                minimumSize: const Size(48, 48),
                backgroundColor: item.selected
                    ? theme.colorScheme.surface
                    : Colors.transparent,
                side: BorderSide(
                  color: item.selected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: item.selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
      ];
      return large
          ? Wrap(spacing: 6, runSpacing: 6, children: children)
          : Row(
              children: [for (final child in children) Expanded(child: child)],
            );
    },
  );
}
