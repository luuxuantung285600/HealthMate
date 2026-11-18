import 'activity_log.dart';
import 'activity_energy.dart';
import 'guided_workout.dart';

enum WorkoutPhase { prepare, work, rest, finished }

/// Pure interval clock. The caller passes only foreground, unpaused elapsed time.
class WorkoutSession {
  WorkoutSession({required this.workout, required this.pace});
  final GuidedWorkout workout;
  final WorkoutPace pace;
  WorkoutPhase phase = WorkoutPhase.prepare;
  Duration remaining = const Duration(seconds: 5);
  Duration workElapsed = Duration.zero;
  Duration restElapsed = Duration.zero;
  int index = 0;
  int completed = 0;
  int skipped = 0;
  bool paused = false;
  bool endedEarly = false;

  int get total => workout.movements.length * pace.rounds;
  int get round => index ~/ workout.movements.length + 1;
  WorkoutMovement get movement =>
      workout.movements[index % workout.movements.length];
  WorkoutMovement? get next => index + 1 < total
      ? workout.movements[(index + 1) % workout.movements.length]
      : null;
  Duration get phaseDuration => Duration(
    seconds: switch (phase) {
      WorkoutPhase.prepare => 5,
      WorkoutPhase.work => pace.workSeconds,
      WorkoutPhase.rest => pace.restSeconds,
      WorkoutPhase.finished => 0,
    },
  );
  bool get finished => phase == WorkoutPhase.finished;
  bool get canSave => workElapsed.inMinutes >= 1;

  void advance(Duration elapsed) {
    if (paused || finished || elapsed <= Duration.zero) return;
    var left = elapsed;
    while (left > Duration.zero && !finished) {
      final used = left < remaining ? left : remaining;
      if (phase == WorkoutPhase.work) workElapsed += used;
      if (phase == WorkoutPhase.rest) restElapsed += used;
      remaining -= used;
      left -= used;
      if (remaining == Duration.zero) _transition();
    }
  }

  void _transition() {
    switch (phase) {
      case WorkoutPhase.prepare:
        phase = WorkoutPhase.work;
      case WorkoutPhase.work:
        completed++;
        if (index == total - 1) {
          phase = WorkoutPhase.finished;
        } else {
          phase = WorkoutPhase.rest;
        }
      case WorkoutPhase.rest:
        index++;
        phase = WorkoutPhase.work;
      case WorkoutPhase.finished:
        return;
    }
    remaining = phaseDuration;
  }

  void skip() {
    if (finished) return;
    if (phase == WorkoutPhase.work) {
      skipped++;
      if (index == total - 1) {
        phase = WorkoutPhase.finished;
      } else {
        phase = WorkoutPhase.rest;
      }
      remaining = phaseDuration;
    } else {
      _transition();
    }
  }

  void finishEarly() {
    if (finished) return;
    endedEarly = true;
    phase = WorkoutPhase.finished;
    remaining = Duration.zero;
    paused = false;
  }

  ActivityLogDraft toDraft(
    DateTime startedAt, {
    ActivityEnergyEstimate? energyEstimate,
  }) {
    if (!finished || !canSave) {
      throw StateError('Chưa đủ một phút vận động để lưu.');
    }
    return ActivityLogDraft(
      type: ActivityType.strength,
      durationMinutes: workElapsed.inMinutes,
      performedAt: startedAt,
      energyEstimate: energyEstimate,
      note:
          '${workout.name} · ${endedEarly ? 'Dừng sớm' : 'Kết thúc'} · $completed/$total lượt đủ thời gian · bỏ qua $skipped · vận động ${workoutTime(workElapsed)}, nghỉ ${workoutTime(restElapsed)}. Phút làm tròn xuống.',
    );
  }
}
