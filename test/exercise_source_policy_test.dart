import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/activity/data/bundled_exercise_library.dart';
import 'package:healthmate/features/activity/data/exercise_db_service.dart';
import 'package:healthmate/features/activity/models/exercise_library_entry.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _data() => {
  'sourceId': 'Nh3mvOO',
  'name': 'Kéo tạ đơn (mẫu nữ)',
  'region': 'back',
  'equipment': 'dumbbell',
  'target': 'Lưng',
  'steps': ['Giữ lưng vững.', 'Kéo tạ có kiểm soát.'],
  'easier': 'Chọn tạ nhẹ.',
  'isActive': true,
  'schemaVersion': 1,
};

ExerciseLibraryEntry _entry(
  String sourceProvider, {
  String id = 'edb-Nh3mvOO',
}) => ExerciseLibraryEntry(
  id: id,
  sourceId: 'Nh3mvOO',
  sourceProvider: sourceProvider,
  name: 'Kéo tạ đơn (mẫu nữ)',
  region: 'back',
  equipment: 'dumbbell',
  target: 'Lưng',
  steps: const ['Giữ lưng vững.', 'Kéo tạ có kiểm soát.'],
  easier: 'Chọn tạ nhẹ.',
);

void main() {
  test(
    'legacy and explicit ExerciseDB records work; other sources fail parsing',
    () {
      for (final data in [
        _data(),
        {..._data(), 'sourceProvider': 'exercisedb'},
      ]) {
        expect(
          ExerciseLibraryEntry.fromMap('edb-Nh3mvOO', data).sourceProvider,
          'exercisedb',
        );
      }
      for (final source in ['repdb', 'unknown', '', 4]) {
        expect(
          () => ExerciseLibraryEntry.fromMap('edb-Nh3mvOO', {
            ..._data(),
            'sourceProvider': source,
          }),
          throwsFormatException,
        );
      }
    },
  );

  test('non-ExerciseDB media is rejected before any outgoing request', () {
    var calls = 0;
    final service = ExerciseDbService(
      enabled: true,
      client: MockClient((_) async {
        calls++;
        return http.Response('unexpected request', 500);
      }),
    );
    addTearDown(service.close);
    for (final provider in ['repdb', 'unknown']) {
      final entry = _entry(provider);
      expect(
        () => service.resolveEntryMedia(entry),
        throwsA(isA<ExerciseMediaFailure>()),
      );
      expect(
        () => service.loadEntryMedia(
          Uri.parse('https://static.exercisedb.dev/media/Nh3mvOO.gif'),
          entry,
        ),
        throwsA(isA<ExerciseMediaFailure>()),
      );
    }
    expect(calls, 0);
  });

  test(
    'non-ExerciseDB overrides cannot reappear through a bundled fallback',
    () {
      final original = _entry('exercisedb');
      final rejected = _entry('repdb');
      expect(mergeExerciseLibrary([original], [rejected]), isEmpty);
      expect(mergeExerciseLibrary([rejected], []), isEmpty);
      expect(filterExerciseLibrary([original, rejected]), [original]);
      expect(mergeExerciseLibrary([original], [_entry('repdb', id: 'other')]), [
        original,
      ]);
    },
  );

  test(
    'female ExerciseDB media resolves its own ID through entry API',
    () async {
      final calls = <Uri>[];
      final service = ExerciseDbService(
        enabled: true,
        client: MockClient((request) async {
          calls.add(request.url);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'exerciseId': 'Nh3mvOO',
                'gifUrl': 'https://static.exercisedb.dev/media/Nh3mvOO.gif',
              },
            }),
            200,
          );
        }),
      );
      addTearDown(service.close);
      expect(
        await service.resolveEntryMedia(_entry('exercisedb')),
        Uri.parse('https://static.exercisedb.dev/media/Nh3mvOO.gif'),
      );
      expect(calls, [
        Uri.parse('https://oss.exercisedb.dev/api/v1/exercises/Nh3mvOO'),
      ]);
      expect(
        bundledExerciseLibrary.every((e) => e.sourceProvider == 'exercisedb'),
        isTrue,
      );
    },
  );
}
