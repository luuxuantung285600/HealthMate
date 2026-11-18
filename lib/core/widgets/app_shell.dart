import '../theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/journal/providers/journal_date_provider.dart';
import '../../features/journal/providers/journal_quick_action_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_feature_visuals.dart';
import '../theme/home_palette.dart';

Color _destinationColor(int branch, Brightness brightness) => switch (branch) {
  1 => AppFeatureVisual.nutrition.foreground(brightness),
  7 => AppFeatureVisual.workout.foreground(brightness),
  5 => AppFeatureVisual.report.foreground(brightness),
  _ =>
    brightness == Brightness.dark
        ? const Color(0xFFEEEEEE)
        : const Color(0xFF262626),
};

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _visibleDestinations = [
    (
      branch: 0,
      label: 'Trang chủ',
      icon: AppIcons.home,
      selected: AppIcons.homeSelected,
      key: ValueKey('nav-dashboard'),
    ),
    (
      branch: 1,
      label: 'Nhật ký',
      icon: AppIcons.journal,
      selected: AppIcons.journalSelected,
      key: ValueKey('nav-journal'),
    ),
    (
      branch: 7,
      label: 'Tập luyện',
      icon: AppIcons.workout,
      selected: AppIcons.workoutSelected,
      key: ValueKey('nav-workouts'),
    ),
    (
      branch: 5,
      label: 'Tiến độ',
      icon: AppIcons.progress,
      selected: AppIcons.progressSelected,
      key: ValueKey('nav-progress'),
    ),
  ];

  void _selectBranch(int branch) {
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  void _addMeal(WidgetRef ref) {
    final day = navigationShell.currentIndex <= 1
        ? ref.read(journalDateProvider)
        : DateTime.now();
    ref.read(journalDateProvider.notifier).select(day);
    navigationShell.goBranch(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(journalQuickActionProvider.notifier)
          .request(JournalQuickAction.addMeal);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: navigationShell.currentIndex == 0
          ? HomePalette.of(context)
          : Theme.of(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showRail = constraints.maxWidth >= AppSpacing.railBreakpoint;
          final currentBranch = navigationShell.currentIndex;
          final visibleIndex = _visibleDestinations.indexWhere(
            (destination) => destination.branch == currentBranch,
          );
          return Scaffold(
            body: SafeArea(
              bottom: showRail,
              child: Row(
                children: [
                  if (showRail) ...[
                    NavigationRail(
                      selectedIndex: visibleIndex < 0 ? null : visibleIndex,
                      onDestinationSelected: (index) =>
                          _selectBranch(_visibleDestinations[index].branch),
                      labelType: NavigationRailLabelType.all,
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Column(
                          children: [
                            const Icon(AppIcons.brand, size: 32),
                            const SizedBox(height: AppSpacing.lg),
                            FloatingActionButton.small(
                              key: const ValueKey('quick-add-menu'),
                              heroTag: 'quick-add-rail',
                              tooltip: 'Thêm bữa ăn',
                              onPressed: () => _addMeal(ref),
                              child: const Icon(AppIcons.plus),
                            ),
                          ],
                        ),
                      ),
                      destinations: [
                        for (final destination in _visibleDestinations)
                          NavigationRailDestination(
                            icon: Icon(destination.icon),
                            selectedIcon: Icon(
                              destination.selected,
                              color: _destinationColor(
                                destination.branch,
                                Theme.of(context).brightness,
                              ),
                            ),
                            label: Text(
                              destination.label,
                              style: destination.branch == currentBranch
                                  ? TextStyle(
                                      color: _destinationColor(
                                        destination.branch,
                                        Theme.of(context).brightness,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                  ],
                  Expanded(child: navigationShell),
                ],
              ),
            ),
            bottomNavigationBar: showRail
                ? null
                : _FloatingNavigationBar(
                    currentBranch: currentBranch,
                    destinations: _visibleDestinations,
                    onSelect: _selectBranch,
                    onQuickAdd: () => _addMeal(ref),
                  ),
          );
        },
      ),
    );
  }
}

class _FloatingNavigationBar extends StatelessWidget {
  const _FloatingNavigationBar({
    required this.currentBranch,
    required this.destinations,
    required this.onSelect,
    required this.onQuickAdd,
  });

  final int currentBranch;
  final List<
    ({
      int branch,
      String label,
      IconData icon,
      IconData selected,
      ValueKey<String> key,
    })
  >
  destinations;
  final ValueChanged<int> onSelect;
  final VoidCallback onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
      shape: Border(top: BorderSide(color: scheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final style = Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600);
            var height = 76.0;
            for (final label in [
              ...destinations.map((d) => d.label),
              'Thêm món',
            ]) {
              final painter =
                  TextPainter(
                    text: TextSpan(text: label, style: style),
                    maxLines: 2,
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                  )..layout(
                    maxWidth:
                        (constraints.maxWidth / (destinations.length + 1) - 4)
                            .clamp(1, double.infinity),
                  );
              final needed = painter.height + 56;
              if (needed > height) height = needed;
              painter.dispose();
            }
            return SizedBox(
              height: height,
              child: Row(
                children: [
                  for (final destination in destinations.take(2))
                    Expanded(
                      child: _NavigationButton(
                        key: destination.key,
                        label: destination.label,
                        icon: currentBranch == destination.branch
                            ? destination.selected
                            : destination.icon,
                        selected: currentBranch == destination.branch,
                        selectedColor: _destinationColor(
                          destination.branch,
                          Theme.of(context).brightness,
                        ),
                        onTap: () => onSelect(destination.branch),
                      ),
                    ),
                  Expanded(
                    child: _NavigationButton(
                      key: const ValueKey('quick-add-menu'),
                      label: 'Thêm món',
                      icon: AppIcons.plus,
                      selected: false,
                      actionColor: AppFeatureVisual.nutrition.foreground(
                        Theme.of(context).brightness,
                      ),
                      onTap: onQuickAdd,
                    ),
                  ),
                  for (final destination in destinations.skip(2))
                    Expanded(
                      child: _NavigationButton(
                        key: destination.key,
                        label: destination.label,
                        icon: currentBranch == destination.branch
                            ? destination.selected
                            : destination.icon,
                        selected: currentBranch == destination.branch,
                        selectedColor: _destinationColor(
                          destination.branch,
                          Theme.of(context).brightness,
                        ),
                        onTap: () => onSelect(destination.branch),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.actionColor,
    this.selectedColor,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? actionColor;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        actionColor ??
        (selected
            ? selectedColor ?? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant);
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (actionColor != null)
                ExcludeSemantics(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: actionColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: theme.brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                )
              else ...[
                AnimatedContainer(
                  key: ValueKey('navigation-indicator-$label'),
                  duration: const Duration(milliseconds: 180),
                  width: 52,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: .13)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                    applyTextScaling: false,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
