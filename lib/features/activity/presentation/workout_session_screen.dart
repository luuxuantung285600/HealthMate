import '../../../core/theme/app_icons.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../auth/providers/auth_providers.dart';
import '../../journal/models/daily_log_failure.dart';
import '../models/guided_workout.dart';
import '../models/workout_session.dart';
import '../models/activity_log.dart';
import 'activity_energy_editor.dart';
import '../providers/activity_providers.dart';
import 'movement_media_preview.dart';
import 'workout_tutorial_sheet.dart';
import 'workout_ui.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  const WorkoutSessionScreen({
    required this.workout,
    required this.pace,
    super.key,
  });
  final GuidedWorkout workout;
  final WorkoutPace pace;
  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final WorkoutSession _session = WorkoutSession(
    workout: widget.workout,
    pace: widget.pace,
  );
  late final Ticker _ticker;
  Duration _previous = Duration.zero;
  late final String? _owner = ref.read(authSessionProvider).value?.uid;
  final DateTime _startedAt = DateTime.now();
  late final String _operationId =
      'workout_${_startedAt.microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 30)}';
  bool _saved = false,
      _saving = false,
      _expired = false,
      _allowPop = false,
      _dialogOpen = false,
      _haptics = true;
  String? _saveError;
  final _energyKey = GlobalKey<ActivityEnergyEditorState>();
  ActivityLogDraft? _pendingDraft;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick);
    _startClock();
  }

  void _startClock() {
    if (_session.finished ||
        _expired ||
        _owner == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.inactive ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.hidden ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.detached) {
      return;
    }
    _previous = Duration.zero;
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    final delta = elapsed - _previous;
    _previous = elapsed;
    final phase = _session.phase, index = _session.index;
    setState(() => _session.advance(delta));
    if (_session.finished) _ticker.stop();
    if (_haptics && (phase != _session.phase || index != _session.index)) {
      unawaited(HapticFeedback.mediumImpact());
    }
  }

  void _pause() {
    _ticker.stop();
    if (mounted && !_session.finished) setState(() => _session.paused = true);
  }

  void _resume() {
    if (_session.finished || _expired) return;
    if (WidgetsBinding.instance.lifecycleState
        case AppLifecycleState.paused ||
            AppLifecycleState.inactive ||
            AppLifecycleState.hidden ||
            AppLifecycleState.detached) {
      return;
    }
    setState(() => _session.paused = false);
    _startClock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _instructions() async {
    _pause();
    final movement = _session.phase == WorkoutPhase.rest
        ? _session.next ?? _session.movement
        : _session.movement;
    await showWorkoutTutorial(context, movement);
  }

  Future<void> _requestExit() async {
    if (_dialogOpen || _saving) return;
    if (_saved || _expired) {
      context.go(AppRoutes.workouts);
      return;
    }
    _pause();
    final finishing = !_session.finished;
    _dialogOpen = true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(finishing ? 'Dừng buổi tập?' : 'Rời tổng kết?'),
        content: Text(
          finishing
              ? 'Bạn có thể xem tổng kết phần đã tập hoặc ở lại để tiếp tục.'
              : 'Phần vận động này chưa được lưu vào nhật ký.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            key: const ValueKey('confirm-end-workout'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(finishing ? 'Xem tổng kết' : 'Rời mà không lưu'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
    if (!mounted || confirm != true || _expired) return;
    if (finishing) {
      setState(_session.finishEarly);
    } else {
      setState(() => _allowPop = true);
      context.go(AppRoutes.workouts);
    }
  }

  Future<void> _save() async {
    if (_saving || _saved || !_session.canSave || _owner == null || _expired) {
      return;
    }
    final auth = ref.read(authSessionProvider);
    if (auth.isLoading || auth.hasError || auth.value?.uid != _owner) return;
    // Keep the same snapshot and operation ID after an uncertain commit.
    _pendingDraft ??= _session.toDraft(
      _startedAt,
      energyEstimate: _energyKey.currentState?.estimate,
    );
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final success = await ref
        .read(activityControllerProvider.notifier)
        .add(_pendingDraft!, operationId: _operationId);
    if (!mounted ||
        _expired ||
        ref.read(authSessionProvider).value?.uid != _owner) {
      return;
    }
    setState(() {
      _saving = false;
      _saved = success;
      if (!success) {
        final error = ref.read(activityControllerProvider).error;
        _saveError = error is DailyLogFailure
            ? error.message
            : 'Chưa lưu được. Hãy kiểm tra kết nối rồi thử lại.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider, (previous, next) {
      if (next.isLoading || next.hasError || next.value?.uid != _owner) {
        _ticker.stop();
        if (mounted) setState(() => _expired = true);
      }
    });
    final theme = Theme.of(context), scheme = theme.colorScheme;
    if (_expired || _owner == null) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(title: const Text('Buổi tập đã dừng')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Phiên đăng nhập đã thay đổi. Hãy mở lại tập luyện với tài khoản hiện tại.',
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.dashboard),
                  child: const Text('Về trang chính'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return PopScope(
      canPop: _allowPop || _saved,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_requestExit());
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: BackButton(onPressed: _saving ? null : _requestExit),
          title: Text(
            _session.finished ? 'Tổng kết buổi tập' : widget.workout.name,
          ),
          actions: [
            if (!_session.finished)
              IconButton(
                tooltip: _haptics
                    ? 'Tắt rung chuyển bài'
                    : 'Bật rung chuyển bài',
                onPressed: () => setState(() => _haptics = !_haptics),
                icon: Icon(_haptics ? AppIcons.vibrate : AppIcons.bellOff),
              ),
          ],
        ),
        body: _session.finished ? _summary(theme) : _player(theme),
      ),
    );
  }

  Widget _player(ThemeData theme) {
    final s = _session, scheme = theme.colorScheme;
    final label = s.paused
        ? 'Đang tạm dừng'
        : switch (s.phase) {
            WorkoutPhase.prepare => 'Chuẩn bị',
            WorkoutPhase.work => 'Cùng vận động',
            WorkoutPhase.rest => 'Nghỉ & thả lỏng',
            WorkoutPhase.finished => 'Kết thúc',
          };
    final seconds = (s.remaining.inMilliseconds / 1000).ceil();
    final shown = s.phase == WorkoutPhase.rest
        ? s.next ?? s.movement
        : s.movement;
    final countdown = Semantics(
      label: 'Còn $seconds giây',
      excludeSemantics: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        children: [
          Text(
            '$seconds'.padLeft(2, '0'),
            key: const ValueKey('workout-countdown'),
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 88,
              height: 1.05,
              letterSpacing: -4,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'giây',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      Text(
                        'Vòng ${s.round}/${s.pace.rounds} · Động tác ${s.index + 1}/${s.total}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${workoutTime(s.workElapsed)} đã tập',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value:
                        (s.index + (s.phase == WorkoutPhase.rest ? 1 : 0)) /
                        s.total,
                    minHeight: 3,
                    color: scheme.onSurface,
                    backgroundColor: scheme.outlineVariant,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    countdown,
                    const SizedBox(height: 16),
                    Text(
                      s.phase == WorkoutPhase.rest
                          ? 'Tiếp theo: ${shown.name}'
                          : shown.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.6,
                      ),
                    ),
                    MovementMediaPreview(
                      movement: shown,
                      height: 170,
                      onTap: _instructions,
                    ),
                    Text(
                      s.phase == WorkoutPhase.rest
                          ? 'Thả lỏng, thở đều và chuẩn bị vị trí cho động tác tiếp theo.'
                          : shown.steps.first,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    TextButton.icon(
                      key: const ValueKey('workout-instructions'),
                      onPressed: _instructions,
                      icon: const Icon(AppIcons.info, size: 18),
                      label: const Text('Xem cách tập'),
                    ),
                    if (s.paused)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Đồng hồ đã dừng. Bấm tiếp tục khi bạn sẵn sàng.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (s.phase == WorkoutPhase.work && s.next != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                AppIcons.skipForward,
                                size: 16,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Kế tiếp · ${s.next!.name}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      FilledButton.icon(
                        key: const ValueKey('pause-workout'),
                        style: workoutButtonStyle(context),
                        onPressed: s.paused ? _resume : _pause,
                        icon: Icon(
                          s.paused ? AppIcons.play : AppIcons.pause,
                          size: 20,
                        ),
                        label: Text(s.paused ? 'Tiếp tục' : 'Tạm dừng'),
                      ),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        children: [
                          TextButton(
                            key: const ValueKey('finish-workout'),
                            onPressed: _requestExit,
                            child: const Text('Kết thúc'),
                          ),
                          TextButton.icon(
                            key: const ValueKey('skip-workout'),
                            onPressed: () => setState(s.skip),
                            icon: const Icon(AppIcons.skipForward, size: 18),
                            label: Text(
                              s.phase == WorkoutPhase.work
                                  ? 'Bỏ qua động tác'
                                  : s.phase == WorkoutPhase.rest
                                  ? 'Bỏ qua nghỉ'
                                  : 'Bắt đầu ngay',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(ThemeData theme) {
    final s = _session;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    _saved ? AppIcons.circleCheck : AppIcons.workout,
                    size: 36,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'TỔNG KẾT / BUỔI TẬP',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.6,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _saved
                      ? 'Đã lưu vận động hôm nay'
                      : s.endedEarly
                      ? 'Bạn đã dành thời gian cho mình'
                      : 'Bạn đã đi hết buổi tập!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.workout.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                WorkoutMetrics(
                  items: [
                    (value: workoutTime(s.workElapsed), label: 'vận động'),
                    (value: workoutTime(s.restElapsed), label: 'nghỉ'),
                    (
                      value: '${s.completed}/${s.total}',
                      label: 'lượt hoàn thành',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${workoutTime(s.workElapsed)} vận động · ${s.skipped} bỏ qua',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  s.canSave
                      ? 'Nhật ký sẽ ghi ${s.workElapsed.inMinutes} phút (làm tròn xuống). Calo dùng ${s.workElapsed.inSeconds} giây vận động; không tính nghỉ hoặc tạm dừng.'
                      : 'Chưa đủ 1 phút vận động trọn vẹn để ghi nhật ký. Bạn vẫn có thể bắt đầu lại khi sẵn sàng.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                if (s.canSave)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ActivityEnergyEditor(
                        key: _energyKey,
                        type: ActivityType.strength,
                        performedAt: _startedAt,
                        durationSeconds: s.workElapsed.inSeconds,
                        guided: true,
                        enabled: _pendingDraft == null,
                        initial: _pendingDraft?.energyEstimate,
                      ),
                    ),
                  ),
                if (_pendingDraft != null && !_saved)
                  const Text(
                    'Đã giữ nguyên nội dung lần lưu đầu. Thử lại sẽ xác nhận cùng buổi tập, không tạo bản trùng.',
                  ),
                if (!_saved)
                  const Text(
                    'Xác nhận nếu bạn đã thực hiện phần vận động trên. Bộ đếm không dùng cảm biến để kiểm tra động tác hoặc đo calo tiêu hao.',
                  ),
                if (_saveError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _saveError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_saved && s.canSave)
                  FilledButton.icon(
                    key: const ValueKey('save-workout'),
                    style: workoutButtonStyle(context),
                    onPressed: _saving ? null : _save,
                    icon: const Icon(AppIcons.check),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _saving
                            ? 'Đang xác nhận lưu…'
                            : _saveError == null
                            ? 'Xác nhận và lưu nhật ký'
                            : 'Thử lưu lại',
                      ),
                    ),
                  ),
                TextButton(
                  key: const ValueKey('close-workout'),
                  onPressed: _saving
                      ? null
                      : _saved
                      ? () => context.go(AppRoutes.workouts)
                      : _requestExit,
                  child: Text(_saved ? 'Xong' : 'Rời mà không lưu'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
