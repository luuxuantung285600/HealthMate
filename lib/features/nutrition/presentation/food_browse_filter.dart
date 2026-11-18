import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/app_inset_panel.dart';
import '../models/food_browse_group.dart';

class FoodBrowseFilter extends StatefulWidget {
  const FoodBrowseFilter({
    required this.value,
    required this.onChanged,
    super.key,
  });
  final FoodBrowseGroup value;
  final ValueChanged<FoodBrowseGroup>? onChanged;

  @override
  State<FoodBrowseFilter> createState() => _FoodBrowseFilterState();
}

class _FoodBrowseFilterState extends State<FoodBrowseFilter> {
  final _scroll = ScrollController();
  final _anchors = {
    for (final group in FoodBrowseGroup.values) group: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _revealSelected();
  }

  @override
  void didUpdateWidget(covariant FoodBrowseFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _revealSelected();
  }

  void _revealSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target = _anchors[widget.value]?.currentContext?.findRenderObject();
      if (target == null) return;
      // Reveal on this horizontal axis only; do not move the meal form itself.
      _scroll.position.ensureVisible(
        target,
        duration: const Duration(milliseconds: 180),
        alignment: .5,
      );
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => AppInsetPanel(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('food-groups-scroll'),
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final group in FoodBrowseGroup.values)
                    Padding(
                      key: _anchors[group],
                      padding: const EdgeInsets.only(right: 8),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: (constraints.maxWidth - 80).clamp(120, 280),
                        ),
                        child: ChoiceChip(
                          key: ValueKey('food-group-${group.name}'),
                          label: Text(group.label, softWrap: true, maxLines: 3),
                          // Stable widths keep the selected label fully visible
                          // while chip selection animates at large text sizes.
                          showCheckmark: false,
                          selected: widget.value == group,
                          onSelected: widget.onChanged == null
                              ? null
                              : (_) => widget.onChanged!(group),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          PopupMenuButton<FoodBrowseGroup>(
            key: const ValueKey('food-groups-menu'),
            tooltip: 'Chọn nhóm thực phẩm',
            enabled: widget.onChanged != null,
            initialValue: widget.value,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(AppIcons.slidersHorizontal),
            onSelected: widget.onChanged,
            itemBuilder: (_) => [
              for (final group in FoodBrowseGroup.values)
                CheckedPopupMenuItem(
                  key: ValueKey('food-group-menu-${group.name}'),
                  value: group,
                  checked: widget.value == group,
                  child: Text(group.label),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
