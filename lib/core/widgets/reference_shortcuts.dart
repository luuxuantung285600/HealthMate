import 'package:flutter/material.dart';
import '../theme/app_feature_visuals.dart';
import 'feature_icon_badge.dart';

typedef ReferenceShortcut = ({
  String label,
  String art,
  VoidCallback onTap,
  Key? key,
});

class ReferenceShortcuts extends StatelessWidget {
  const ReferenceShortcuts({required this.entries, super.key});
  final List<ReferenceShortcut> entries;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final columns = largeText ? 3 : entries.length;
      final width = (c.maxWidth - 10 * (columns - 1)) / columns;
      return Wrap(
        spacing: 10,
        runSpacing: 16,
        children: [
          for (final entry in entries)
            SizedBox(
              width: width,
              child: InkWell(
                key: entry.key,
                onTap: entry.onTap,
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    FeatureIconBadge(
                      AppFeatureVisual.fromArtwork(entry.art),
                      size: 56,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      entry.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: largeText ? 12 : 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
