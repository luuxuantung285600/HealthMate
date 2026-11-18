import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/activity/data/bundled_exercise_library.dart';
import 'package:healthmate/features/activity/data/exercise_library_repository.dart';
import 'package:healthmate/features/activity/models/exercise_library_entry.dart';

ExerciseLibraryEntry overrideEntry(
  ExerciseLibraryEntry base, {
  String? id,
  String? name,
  bool isActive = true,
}) => ExerciseLibraryEntry(
  id: id ?? base.id,
  sourceId: base.sourceId,
  name: name ?? base.name,
  region: base.region,
  equipment: base.equipment,
  target: base.target,
  steps: base.steps,
  easier: base.easier,
  isActive: isActive,
);

void main() {
  test(
    'partial initial cache emits nothing; confirmed empty server emits the full bundled library',
    () async {
      final source = StreamController<ExerciseLibrarySnapshot>();
      final values = <List<ExerciseLibraryEntry>>[];
      final subscription = confirmedExerciseLibraryStream(
        source.stream,
        initialTimeout: const Duration(milliseconds: 20),
      ).listen(values.add);
      source.add((confirmed: false, entries: const []));
      await Future<void>.delayed(Duration.zero);
      expect(values, isEmpty);
      source.add((confirmed: true, entries: const []));
      await Future<void>.delayed(Duration.zero);
      expect(values.single, hasLength(bundledExerciseLibrary.length));
      await subscription.cancel();
      await source.close();
    },
  );

  test(
    'confirmed edits, additions and tombstones merge; later partial cache cannot resurrect',
    () async {
      final source = StreamController<ExerciseLibrarySnapshot>();
      final values = <List<ExerciseLibraryEntry>>[];
      final subscription = confirmedExerciseLibraryStream(
        source.stream,
        initialTimeout: const Duration(milliseconds: 20),
      ).listen(values.add);
      final first = bundledExerciseLibrary.first,
          second = bundledExerciseLibrary[1];
      source.add((
        confirmed: true,
        entries: [
          overrideEntry(first, isActive: false),
          overrideEntry(second, name: 'Tên đã sửa'),
          overrideEntry(first, id: 'custom-entry'),
        ],
      ));
      await Future<void>.delayed(Duration.zero);
      expect(values.single, hasLength(bundledExerciseLibrary.length));
      expect(values.single.any((e) => e.id == first.id), isFalse);
      expect(
        values.single.singleWhere((e) => e.id == second.id).name,
        'Tên đã sửa',
      );
      expect(values.single.any((e) => e.id == 'custom-entry'), isTrue);
      source.add((confirmed: false, entries: const []));
      await Future<void>.delayed(Duration.zero);
      expect(values, hasLength(1));
      await subscription.cancel();
      await source.close();
    },
  );

  test('idle confirmed subscription has no initial timeout', () async {
    final source = StreamController<ExerciseLibrarySnapshot>();
    final errors = <Object>[];
    final subscription = confirmedExerciseLibraryStream(
      source.stream,
      initialTimeout: const Duration(milliseconds: 20),
    ).listen((_) {}, onError: errors.add);
    source.add((confirmed: true, entries: const []));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(errors, isEmpty);
    await subscription.cancel();
    await source.close();
  });

  test(
    'initial cached timeout reports an error and same listener recovers on server confirmation',
    () async {
      final source = StreamController<ExerciseLibrarySnapshot>();
      final values = <List<ExerciseLibraryEntry>>[], errors = <Object>[];
      final subscription = confirmedExerciseLibraryStream(
        source.stream,
        initialTimeout: const Duration(milliseconds: 20),
      ).listen(values.add, onError: errors.add);
      source.add((confirmed: false, entries: const []));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(values, isEmpty);
      expect(errors.single, isA<TimeoutException>());
      expect(source.hasListener, isTrue);
      source.add((confirmed: true, entries: const []));
      await Future<void>.delayed(Duration.zero);
      expect(values.single, hasLength(bundledExerciseLibrary.length));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(errors, hasLength(1));
      await subscription.cancel();
      await source.close();
    },
  );

  test('cancellation removes source listener and initial timer', () async {
    var cancelled = false;
    final source = StreamController<ExerciseLibrarySnapshot>(
      onCancel: () {
        cancelled = true;
      },
    );
    final errors = <Object>[];
    final subscription = confirmedExerciseLibraryStream(
      source.stream,
      initialTimeout: const Duration(milliseconds: 20),
    ).listen((_) {}, onError: errors.add);
    await subscription.cancel();
    expect(cancelled, isTrue);
    expect(source.hasListener, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(errors, isEmpty);
    await source.close();
  });
}
