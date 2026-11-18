import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/activity/models/activity_log.dart';
import 'package:healthmate/features/activity/models/guided_workout.dart';
import 'package:healthmate/features/activity/models/workout_session.dart';

void main() {
  WorkoutSession session([WorkoutPace pace = WorkoutPace.standard]) =>
      WorkoutSession(workout: GuidedWorkouts.all.first, pace: pace);
  test(
    'catalog has real instructions, balanced sides and no missing movement content',
    () {
      expect(GuidedWorkouts.all.map((w) => w.id).toSet().length, 3);
      for (final workout in GuidedWorkouts.all) {
        expect(workout.movements.length, greaterThanOrEqualTo(8));
        for (final movement in workout.movements) {
          expect(movement.steps.length, greaterThanOrEqualTo(3));
          expect(movement.easier, isNotEmpty);
        }
        expect(
          workout.movements.contains(GuidedWorkouts.sideLeft),
          workout.movements.contains(GuidedWorkouts.sideRight),
        );
      }
    },
  );
  test('displayed duration includes preparation and each rest except last', () {
    expect(
      WorkoutPace.standard.totalDuration(GuidedWorkouts.all.first),
      const Duration(seconds: 475),
    );
    expect(
      WorkoutPace.twoRounds.totalDuration(GuidedWorkouts.all.first),
      const Duration(seconds: 955),
    );
    expect(workoutTime(const Duration(seconds: 475)), '7:55');
    for (final workout in GuidedWorkouts.all) {
      for (final pace in WorkoutPace.values) {
        final s = WorkoutSession(workout: workout, pace: pace);
        s.advance(
          pace.totalDuration(workout) - const Duration(milliseconds: 1),
        );
        expect(s.finished, isFalse);
        s.advance(const Duration(milliseconds: 1));
        expect(s.finished, isTrue);
        expect(s.completed, s.total);
        expect(
          s.workElapsed.inSeconds,
          workout.movements.length * pace.rounds * pace.workSeconds,
        );
        expect(s.restElapsed.inSeconds, (s.total - 1) * pace.restSeconds);
      }
    }
  });
  test('exact boundaries move prepare to work to rest to next work', () {
    final s = session();
    s.advance(const Duration(seconds: 5));
    expect(s.phase, WorkoutPhase.work);
    expect(s.remaining, const Duration(seconds: 30));
    expect(s.workElapsed, Duration.zero);
    s.advance(const Duration(seconds: 30));
    expect(s.phase, WorkoutPhase.rest);
    expect(s.completed, 1);
    expect(s.index, 0);
    s.advance(const Duration(seconds: 10));
    expect(s.phase, WorkoutPhase.work);
    expect(s.index, 1);
    expect(s.workElapsed, const Duration(seconds: 30));
  });
  test(
    'fractional foreground elapsed is retained across ticks without drift',
    () {
      final a = session(), b = session();
      for (var i = 0; i < 1000; i++) {
        a.advance(const Duration(milliseconds: 97));
      }
      b.advance(const Duration(seconds: 97));
      expect(a.remaining, b.remaining);
      expect(a.workElapsed, b.workElapsed);
      expect(a.restElapsed, b.restElapsed);
      expect(a.index, b.index);
    },
  );
  test('paused time is not credited and resume starts with remaining time', () {
    final s = session()..advance(const Duration(seconds: 12));
    s.paused = true;
    s.advance(const Duration(hours: 1));
    expect(s.workElapsed, const Duration(seconds: 7));
    expect(s.remaining, const Duration(seconds: 23));
    s.paused = false;
    s.advance(const Duration(seconds: 3));
    expect(s.workElapsed, const Duration(seconds: 10));
  });
  test(
    'skipped work credits only actual seconds and never full completion',
    () {
      final s = session()..advance(const Duration(seconds: 12));
      s.skip();
      expect(s.workElapsed, const Duration(seconds: 7));
      expect(s.completed, 0);
      expect(s.skipped, 1);
      expect(s.phase, WorkoutPhase.rest);
      s.skip();
      expect(s.index, 1);
      expect(s.restElapsed, Duration.zero);
      expect(s.phase, WorkoutPhase.work);
    },
  );
  test('skip preparation does not mark a movement completed or skipped', () {
    final s = session()..skip();
    expect(s.phase, WorkoutPhase.work);
    expect(s.completed, 0);
    expect(s.skipped, 0);
    expect(s.index, 0);
  });
  test('skip every movement finishes with zero exercise and cannot save', () {
    final s = session()..skip();
    while (!s.finished) {
      s.skip();
    }
    expect(s.skipped, 12);
    expect(s.completed, 0);
    expect(s.workElapsed, Duration.zero);
    expect(s.canSave, isFalse);
    expect(() => s.toDraft(DateTime.now()), throwsStateError);
  });
  test('finishing early freezes elapsed and marks honest partial result', () {
    final s = session()..advance(const Duration(seconds: 89));
    s.finishEarly();
    expect(s.endedEarly, isTrue);
    expect(s.workElapsed, const Duration(seconds: 64));
    expect(s.completed, 2);
    final before = s.workElapsed;
    s.advance(const Duration(days: 1));
    s.skip();
    s.finishEarly();
    expect(s.workElapsed, before);
    final draft = s.toDraft(DateTime(2026, 11, 9, 23, 59));
    expect(draft.durationMinutes, 1);
    expect(draft.caloriesBurned, isNull);
    expect(draft.note, contains('Dừng sớm'));
    expect(ActivityValidation.note(draft.note), isNull);
    expect(draft.performedAt, DateTime(2026, 11, 9, 23, 59));
  });
  test('sub-minute partial work is never rounded up to one minute', () {
    final s = session()..advance(const Duration(seconds: 74));
    s.finishEarly();
    expect(s.workElapsed, const Duration(seconds: 59));
    expect(s.canSave, isFalse);
  });
  test(
    'completion saves only work minutes with no rest or calorie estimate',
    () {
      final s = session()..advance(const Duration(hours: 1));
      final draft = s.toDraft(DateTime(2026, 11, 9, 10));
      expect(draft.durationMinutes, 6);
      expect(draft.note, contains('12/12'));
      expect(draft.note, contains('nghỉ 1:50'));
      expect(s.endedEarly, isFalse);
      expect(s.remaining, Duration.zero);
      expect(s.next, isNull);
    },
  );
  test('second round wraps movements and counts cumulative repetitions', () {
    final s = session(WorkoutPace.twoRounds)
      ..advance(const Duration(seconds: 485));
    expect(s.round, 2);
    expect(s.index, 12);
    expect(s.movement.id, GuidedWorkouts.all.first.movements.first.id);
    expect(s.total, 24);
    s.advance(const Duration(hours: 1));
    expect(s.completed, 24);
    expect(ActivityValidation.note(s.toDraft(DateTime.now()).note), isNull);
  });
  test('negative and zero tick cannot subtract earned time', () {
    final s = session()..advance(const Duration(seconds: 6));
    s.advance(const Duration(seconds: -10));
    s.advance(Duration.zero);
    expect(s.workElapsed, const Duration(seconds: 1));
  });
}
