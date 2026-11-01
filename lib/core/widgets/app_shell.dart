import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/journal/providers/journal_date_provider.dart';
import '../../features/journal/providers/journal_quick_action_provider.dart';
import '../theme/app_spacing.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _visibleDestinations = [
    (
      branch: 0,
      label: 'Hôm nay',
      icon: Icons.home_outlined,
      selected: Icons.home_outlined,
      key: ValueKey('nav-dashboard'),
    ),
    (
      branch: 1,
      label: 'Nhật ký',
      icon: Icons.menu_book_outlined,
      selected: Icons.menu_book_outlined,
      key: ValueKey('nav-journal'),
    ),
    (
      branch: 5,
      label: 'Tiến độ',
      icon: Icons.bar_chart_outlined,
      selected: Icons.bar_chart_outlined,
      key: ValueKey('nav-progress'),
    ),
    (
      branch: 4,
      label: 'Cá nhân',
      icon: Icons.person_outline_rounded,
      selected: Icons.person_rounded,
      key: ValueKey('nav-profile'),
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
    return LayoutBuilder(
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
                          const Icon(Icons.spa_rounded, size: 32),
                          const SizedBox(height: AppSpacing.lg),
                          FloatingActionButton.small(
                            key: const ValueKey('quick-add-menu'),
                            heroTag: 'quick-add-rail',
                            tooltip: 'Thêm bữa ăn',
                            onPressed: () => _addMeal(ref),
                            child: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ),
                    destinations: [
                      for (final destination in _visibleDestinations)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selected),
                          label: Text(destination.label),
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
      color: scheme.surface,
      elevation: 0,
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final style = Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400);
            var height = 68.0;
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
              final needed = painter.height + 45;
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
                        onTap: () => onSelect(destination.branch),
                      ),
                    ),
                  Expanded(
                    child: _NavigationButton(
                      key: const ValueKey('quick-add-menu'),
                      label: 'Thêm món',
                      icon: Icons.add_rounded,
                      selected: false,
                      actionColor: scheme.primary,
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
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? actionColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        actionColor ??
        (selected
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurfaceVariant);
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: actionColor == null
                ? null
                : theme.colorScheme.primaryContainer.withValues(alpha: .35),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? theme.colorScheme.primary : color,
                size: 24,
                applyTextScaling: false,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
