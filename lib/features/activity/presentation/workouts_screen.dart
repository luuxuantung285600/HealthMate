import '../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../models/activity_log.dart';
import '../models/guided_workout.dart';
import '../providers/activity_providers.dart';
import '../providers/workout_exercise_provider.dart';
import 'exercise_gif_preview.dart';
import 'movement_media_preview.dart';
import 'workout_tutorial_sheet.dart';
import 'exercise_library_screen.dart';
import 'workout_ui.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});
  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  bool _showSessions = false;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Offstage(
        offstage: _showSessions,
        child: TickerMode(
          enabled: !_showSessions,
          child: ExerciseLibraryScreen(
            onOpenWorkouts: () => setState(() => _showSessions = true),
          ),
        ),
      ),
      if (_showSessions)
        _TimedWorkouts(onLibrary: () => setState(() => _showSessions = false)),
    ],
  );
}

class _TimedWorkouts extends ConsumerStatefulWidget {
  const _TimedWorkouts({required this.onLibrary});
  final VoidCallback onLibrary;
  @override
  ConsumerState<_TimedWorkouts> createState() => _TimedWorkoutsState();
}

class _TimedWorkoutsState extends ConsumerState<_TimedWorkouts> {
  String? _filter;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), scheme = theme.colorScheme;
    final day = localDateKey(ref.watch(localClockProvider));
    final logs = ref.watch(activityLogsProvider(day));
    final workouts = GuidedWorkouts.all.where(
      (w) => _filter == null || w.tag == _filter,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tập luyện',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Nguồn GIF và tập luyện an toàn',
            onPressed: () => showExerciseMediaInfo(context),
            icon: const Icon(AppIcons.info),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            children: [
              WorkoutSectionTabs(
                sessionsSelected: true,
                onLibrary: widget.onLibrary,
                onSessions: () {},
              ),
              const SizedBox(height: 24),
              const WorkoutHeading(
                eyebrow: 'Tập theo đồng hồ',
                title: 'Một buổi tập.\nTrọn nhịp của bạn.',
                description:
                    'Chọn buổi tập, điều chỉnh nhịp và làm theo từng động tác.',
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(color: scheme.outlineVariant),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    Icon(AppIcons.activity, color: workoutAccent(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: logs.when(
                        data: (items) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VẬN ĐỘNG HÔM NAY',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                letterSpacing: .5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              items.isEmpty
                                  ? 'Chưa có vận động đã ghi'
                                  : '${totalActivityMinutes(items)} phút đã ghi nhận',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        loading: () => const Text('Đang tải vận động hôm nay…'),
                        error: (_, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Chưa tải được nhật ký hôm nay.'),
                            TextButton(
                              onPressed: () =>
                                  ref.invalidate(activityLogsProvider(day)),
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Chọn buổi tập',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final filter in <String?>[
                    null,
                    'Toàn thân',
                    'Không bật nhảy',
                    'Thân giữa',
                  ])
                    ChoiceChip(
                      label: Text(filter ?? 'Tất cả'),
                      selected: _filter == filter,
                      showCheckmark: false,
                      selectedColor: workoutAccent(
                        context,
                      ).withValues(alpha: .16),
                      labelStyle: TextStyle(
                        color: _filter == filter
                            ? workoutAccent(context)
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              for (final workout in workouts) ...[
                _WorkoutCard(workout: workout),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 12),
              Text(
                'Thời lượng gồm thời gian chuẩn bị và nghỉ ở nhịp tiêu chuẩn. Khởi động riêng trước khi bắt đầu; dừng nếu đau, chóng mặt hoặc khó chịu.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutCard extends ConsumerWidget {
  const _WorkoutCard({required this.workout});
  final GuidedWorkout workout;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context), scheme = theme.colorScheme;
    final movement = workout.movements
        .where((item) => workoutExerciseIds.containsKey(item.id))
        .firstOrNull;
    final exercise = movement == null
        ? null
        : ref.watch(workoutExerciseProvider(movement.id));
    final media = exercise == null
        ? const SizedBox(
            height: 150,
            child: Center(child: Icon(AppIcons.workout, size: 40)),
          )
        : ExerciseGifPreview(
            entry: exercise,
            autoLoad: true,
            compact: true,
            thumbnail: true,
            height: 190,
          );
    return Container(
      decoration: workoutPanel(context),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: ValueKey('workout-${workout.id}'),
          onTap: () => context.push('${AppRoutes.workouts}/${workout.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  SizedBox(width: double.infinity, child: media),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          workout.tag.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            workout.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.7,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(AppIcons.arrowUpRight, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      workout.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        Text(
                          '${workoutTime(WorkoutPace.standard.totalDuration(workout))} phút',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${workout.movements.length} động tác',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text('Xem buổi tập', style: theme.textTheme.labelLarge),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkoutDetailScreen extends StatefulWidget {
  const WorkoutDetailScreen({required this.workout, super.key});
  final GuidedWorkout workout;
  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  WorkoutPace _pace = WorkoutPace.standard;
  @override
  Widget build(BuildContext context) {
    final workout = widget.workout, theme = Theme.of(context);
    final previewMovement =
        workout.movements
            .where((movement) => workoutExerciseIds.containsKey(movement.id))
            .firstOrNull ??
        workout.movements.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết buổi tập')),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Align(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('start-workout'),
                  style: workoutButtonStyle(context),
                  onPressed: () => context.push(
                    '${AppRoutes.workouts}/${workout.id}/session?pace=${_pace.name}',
                  ),
                  icon: const Icon(AppIcons.play, size: 20),
                  label: Text(
                    'Bắt đầu · ${workoutTime(_pace.totalDuration(workout))}',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              WorkoutHeading(
                eyebrow: workout.tag,
                title: workout.name,
                description: workout.subtitle,
              ),
              const SizedBox(height: 16),
              MovementMediaPreview(
                movement: previewMovement,
                height: 230,
                onTap: () => showWorkoutTutorial(context, previewMovement),
              ),
              Text(
                'Minh họa: ${previewMovement.name}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              WorkoutMetrics(
                items: [
                  (
                    value: workoutTime(_pace.totalDuration(workout)),
                    label: 'phút, gồm nghỉ',
                  ),
                  (value: '${workout.movements.length}', label: 'động tác'),
                  (value: '${_pace.rounds}', label: 'vòng tập'),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Chọn nhịp tập',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final pace in WorkoutPace.values)
                    ChoiceChip(
                      key: ValueKey('workout-pace-${pace.name}'),
                      label: Text(pace.label),
                      selected: _pace == pace,
                      showCheckmark: false,
                      selectedColor: theme.colorScheme.onSurface,
                      labelStyle: TextStyle(
                        color: _pace == pace
                            ? theme.colorScheme.surface
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      onSelected: (_) => setState(() => _pace = pace),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${_pace.workSeconds} giây tập · ${_pace.restSeconds} giây nghỉ · 5 giây chuẩn bị. Không nghỉ sau lượt cuối.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.onSurface,
                      width: 2,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chuẩn bị',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(workout.equipment),
                      const SizedBox(height: 8),
                      Text(
                        'Khởi động riêng trước khi bắt đầu. Tập trong tầm thoải mái; bộ đếm không xác nhận động tác hay đo calo tiêu hao.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Động tác trong mỗi vòng',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < workout.movements.length; i++)
                MovementInstructionTile(
                  movement: workout.movements[i],
                  number: i + 1,
                  seconds: _pace.workSeconds,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MovementInstructionTile extends StatefulWidget {
  const MovementInstructionTile({
    required this.movement,
    required this.number,
    required this.seconds,
    super.key,
  });
  final WorkoutMovement movement;
  final int number, seconds;
  @override
  State<MovementInstructionTile> createState() =>
      _MovementInstructionTileState();
}

class _MovementInstructionTileState extends State<MovementInstructionTile> {
  bool _open = false;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(vertical: 6),
      shape: const Border(),
      collapsedShape: const Border(),
      key: ValueKey('movement-${widget.number}'),
      leading: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,

        child: Text(
          '${widget.number}'.padLeft(2, '0'),
          style: TextStyle(
            color: workoutAccent(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        widget.movement.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${widget.seconds} giây · ${widget.movement.focus}'),
      onExpansionChanged: (value) => setState(() => _open = value),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_open)
                Center(
                  child: MovementMediaPreview(
                    movement: widget.movement,
                    onTap: () => showWorkoutTutorial(context, widget.movement),
                  ),
                ),
              for (var i = 0; i < widget.movement.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${i + 1}. ${widget.movement.steps[i]}'),
                ),
              Text(
                'Nhẹ hơn: ${widget.movement.easier}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
