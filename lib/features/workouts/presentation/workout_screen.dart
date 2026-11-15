import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../models/workout.dart';
import '../providers/workout_providers.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  WorkoutPlan? _selected;
  int _exerciseIndex = 0;
  int _secondsLeft = 0;
  int _activeSeconds = 0;
  DateTime? _startedAt;
  Timer? _timer;
  bool _paused = false;
  bool _resting = false;
  final _completed = <String>[];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(workoutSessionsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tập luyện')),
      body: _selected == null
          ? _catalog(context, theme, sessions)
          : _running(context, theme),
    );
  }

  Widget _catalog(BuildContext context, ThemeData theme, AsyncValue<List<WorkoutSession>> sessions) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text('Chọn buổi tập', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text('Tập ngắn, rõ ràng và phù hợp với nhịp độ của bạn.'),
        const SizedBox(height: 16),
        for (final workout in WorkoutCatalog.plans)
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey('workout-${workout.id}'),
              onTap: () => _showDetails(context, workout),
              child: Row(
                children: [
                  Container(width: 88, height: 104, color: Color(workout.color), child: const Icon(Icons.fitness_center, color: Colors.white, size: 36)),
                  Expanded(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(workout.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text(workout.category),
                    const SizedBox(height: 8),
                    Text('${workout.durationMinutes} phút · ${workout.equipment}', style: theme.textTheme.bodySmall),
                  ]))),
                  const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.chevron_right)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 22),
        Text('Lịch sử gần đây', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        sessions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Chưa tải được lịch sử. Hãy thử lại.'),
          data: (items) => items.isEmpty
              ? const Text('Chưa có buổi tập hoàn thành.')
              : Column(children: [for (final session in items) _historyTile(context, session)]),
        ),
      ],
    );
  }

  Widget _historyTile(BuildContext context, WorkoutSession session) => Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.check)),
      title: Text(session.workoutName),
      subtitle: Text('${DateFormat('dd/MM · HH:mm').format(session.completedAt)} · ${session.activeMinutes} phút · ${session.caloriesBurned.round()} kcal'),
      trailing: IconButton(
        tooltip: 'Xóa bản ghi',
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
            title: const Text('Xóa buổi tập?'),
            content: const Text('Bản ghi vận động và kcal của buổi này sẽ được xóa.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa'))],
          ));
          if (confirmed == true && context.mounted) await ref.read(workoutControllerProvider.notifier).delete(session);
        },
      ),
    ),
  );

  void _showDetails(BuildContext context, WorkoutPlan workout) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(workout.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6), Text(workout.description),
        const SizedBox(height: 12), Text('${workout.durationMinutes} phút · ${workout.equipment}'),
        const SizedBox(height: 14),
        for (final exercise in workout.exercises) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.play_circle_outline), title: Text(exercise.name), subtitle: Text('${exercise.workSeconds} giây · ${exercise.instruction}')),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: () { Navigator.pop(context); _start(workout); }, icon: const Icon(Icons.play_arrow), label: const Text('Bắt đầu')),
      ]))),
    );
  }

  void _start(WorkoutPlan workout) {
    _timer?.cancel();
    setState(() { _selected = workout; _exerciseIndex = 0; _secondsLeft = workout.exercises.first.workSeconds; _activeSeconds = 0; _startedAt = DateTime.now(); _paused = false; _resting = false; _completed.clear(); });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _paused || _selected == null) return;
    setState(() { _secondsLeft--; _activeSeconds++; });
    if (_secondsLeft <= 0) _advance();
  }

  void _advance() {
    final workout = _selected!;
    final exercise = workout.exercises[_exerciseIndex];
    if (!_completed.contains(exercise.id)) _completed.add(exercise.id);
    if (_resting) { _resting = false; if (_exerciseIndex + 1 >= workout.exercises.length) { _finish(); return; } _exerciseIndex++; _secondsLeft = workout.exercises[_exerciseIndex].workSeconds; }
    else { _resting = true; _secondsLeft = exercise.restSeconds; }
    setState(() {});
  }

  void _skip() { if (_selected == null) return; _advance(); }

  Future<void> _finish() async {
    _timer?.cancel();
    final workout = _selected!;
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null || _startedAt == null) return;
    final profile = ref.read(userProfileProvider).value;
    final weightKg = profile?.targetWeightKg ?? 70;
    final calories = workout.exercises.fold<double>(0, (sum, exercise) => sum + 4.0 * weightKg * (exercise.workSeconds / 3600));
    final repository = ref.read(workoutRepositoryProvider);
    await repository.complete(uid: uid, workout: workout, startedAt: _startedAt!, completedAt: DateTime.now(), activeSeconds: _activeSeconds, caloriesBurned: calories, completedExerciseIds: List.of(_completed));
    if (!mounted) return;
    ref.invalidate(workoutSessionsProvider);
    setState(() { _selected = null; _startedAt = null; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã lưu buổi tập · ${calories.round()} kcal ước tính')));
  }

  Widget _running(BuildContext context, ThemeData theme) {
    final workout = _selected!;
    final exercise = workout.exercises[_exerciseIndex];
    final progress = (_exerciseIndex + (_resting ? 1 : 0)) / workout.exercises.length;
    return PopScope(canPop: false, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Text('${_exerciseIndex + 1}/${workout.exercises.length}'), const Spacer(), Text(_resting ? 'Nghỉ' : 'Đang tập', style: theme.textTheme.titleMedium)]),
      const SizedBox(height: 10), LinearProgressIndicator(value: progress.clamp(0, 1)),
      const Spacer(),
      Icon(_resting ? Icons.self_improvement : Icons.fitness_center, size: 82, color: theme.colorScheme.primary),
      const SizedBox(height: 18),
      Text(_resting ? 'Nghỉ một chút' : exercise.name, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
      const SizedBox(height: 10), Text(_resting ? 'Chuẩn bị cho động tác tiếp theo.' : exercise.instruction, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      Text('${_secondsLeft}s', textAlign: TextAlign.center, style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700)),
      const Spacer(),
      Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => setState(() => _paused = !_paused), icon: Icon(_paused ? Icons.play_arrow : Icons.pause), label: Text(_paused ? 'Tiếp tục' : 'Tạm dừng'))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: _skip, icon: const Icon(Icons.skip_next), label: const Text('Bỏ qua')))]),
      const SizedBox(height: 10), FilledButton(onPressed: _finish, child: const Text('Kết thúc và lưu')),
    ])));
  }
}
