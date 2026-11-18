import 'package:flutter/material.dart';

import '../../../core/theme/app_feature_visuals.dart';
import '../../../core/theme/app_icons.dart';

Color workoutAccent(BuildContext context) =>
    AppFeatureVisual.workout.foreground(Theme.of(context).brightness);

BoxDecoration workoutPanel(BuildContext context) => BoxDecoration(
  color: Theme.of(context).colorScheme.surfaceContainerLowest,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
);

ButtonStyle workoutButtonStyle(BuildContext context) => FilledButton.styleFrom(
  backgroundColor: Theme.of(context).colorScheme.onSurface,
  foregroundColor: Theme.of(context).colorScheme.surface,
  minimumSize: const Size(0, 56),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  textStyle: Theme.of(
    context,
  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
);

/// A single typographic hierarchy across the library, plan and player.
class WorkoutHeading extends StatelessWidget {
  const WorkoutHeading({
    required this.eyebrow,
    required this.title,
    this.description,
    super.key,
  });
  final String eyebrow, title;
  final String? description;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 12),
          Text(
            description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// Metrics read as one strip rather than a stack of competing cards.
class WorkoutMetrics extends StatelessWidget {
  const WorkoutMetrics({required this.items, super.key});
  final List<({String value, String label})> items;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget metric(({String value, String label}) item) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -.6,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 290 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.5) {
            return Wrap(spacing: 12, children: items.map(metric).toList());
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final item in items) Expanded(child: metric(item))],
          );
        },
      ),
    );
  }
}

class WorkoutStep extends StatelessWidget {
  const WorkoutStep({required this.number, required this.text, super.key});
  final int number;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: SizedBox(
            width: 38,
            child: Text(
              '$number'.padLeft(2, '0'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            label: 'Bước $number. $text',
            child: ExcludeSemantics(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Both destinations are existing features; no extra navigation stack is added.
class WorkoutSectionTabs extends StatelessWidget {
  const WorkoutSectionTabs({
    required this.sessionsSelected,
    required this.onLibrary,
    required this.onSessions,
    super.key,
  });
  final bool sessionsSelected;
  final VoidCallback onLibrary, onSessions;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _tab(
          context,
          'Thư viện động tác',
          AppIcons.dumbbell,
          !sessionsSelected,
          onLibrary,
          const ValueKey('open-exercise-library'),
        ),
      ),
      Expanded(
        child: _tab(
          context,
          'Buổi tập',
          AppIcons.timer,
          sessionsSelected,
          onSessions,
          const ValueKey('open-timed-workouts'),
        ),
      ),
    ],
  );

  Widget _tab(
    BuildContext context,
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
    Key key,
  ) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      selected: selected,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? workoutAccent(context)
                    : theme.colorScheme.outlineVariant,
                width: selected ? 3 : 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkoutTag extends StatelessWidget {
  const WorkoutTag(this.label, {this.icon, super.key});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
        Flexible(
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
      ],
    ),
  );
}

void showExerciseMediaInfo(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Về hướng dẫn tập luyện',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const Text(
            'GIF minh họa: ExerciseDB · AscendAPI · 180p. Bản miễn phí chỉ dùng trong bản kiểm thử phi thương mại. Cần Internet; minh họa không được lưu để xem offline.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Bạn có thể tạm dừng từng GIF. Hướng dẫn chữ vẫn dùng được khi không tải được ảnh động.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Khởi động trước khi tập, chọn mức phù hợp và dừng nếu đau, chóng mặt hoặc khó chịu. Thông tin hỗ trợ thói quen vận động, không thay thế tư vấn y tế.',
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    ),
  ),
);
