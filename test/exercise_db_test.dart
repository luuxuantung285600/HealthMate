import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/activity/data/bundled_exercise_library.dart';
import 'package:healthmate/features/activity/data/exercise_db_service.dart';
import 'package:healthmate/features/activity/models/exercise_library_entry.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _map({bool active = true}) => {
  'sourceId': 'I4hDWkc',
  'name': 'Chống đẩy thử',
  'region': 'chest',
  'equipment': 'bodyweight',
  'target': 'Ngực',
  'steps': ['Đặt tay vững.', 'Hạ người chậm.'],
  'easier': 'Chống tường.',
  'isActive': active,
  'schemaVersion': 1,
};
String _response({String id = 'I4hDWkc', String? url}) => jsonEncode({
  'success': true,
  'data': {
    'exerciseId': id,
    'gifUrl': url ?? 'https://static.exercisedb.dev/media/$id.gif',
  },
});

class _AbortClient extends http.BaseClient {
  final started = Completer<void>();
  bool aborted = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final abortable = request as http.Abortable;
    started.complete();
    await abortable.abortTrigger;
    aborted = true;
    throw http.RequestAbortedException(request.url);
  }
}

class _ParallelClient extends http.BaseClient {
  final started = <String, Completer<void>>{};
  final responses = <String, Completer<http.StreamedResponse>>{};
  final aborted = <String>{};

  Future<void> waitFor(String id) =>
      started.putIfAbsent(id, Completer<void>.new).future;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final id = request.url.pathSegments.last;
    final response = Completer<http.StreamedResponse>();
    responses[id] = response;
    started.putIfAbsent(id, Completer<void>.new).complete();
    return Future.any([
      response.future,
      (request as http.Abortable).abortTrigger!.then<http.StreamedResponse>((
        _,
      ) {
        aborted.add(id);
        throw http.RequestAbortedException(request.url);
      }),
    ]);
  }
}

void main() {
  test('disposing one visible GIF does not cancel a neighboring GIF', () async {
    final client = _ParallelClient();
    final service = ExerciseDbService(client: client);
    addTearDown(service.close);
    final firstOwner = Object(), secondOwner = Object();
    final first = service.resolveGif('I4hDWkc', owner: firstOwner);
    final second = service.resolveGif('NCmbLCw', owner: secondOwner);
    await Future.wait([client.waitFor('I4hDWkc'), client.waitFor('NCmbLCw')]);
    service.cancelPending(owner: firstOwner);
    await expectLater(first, throwsA(isA<ExerciseMediaFailure>()));
    expect(client.aborted, {'I4hDWkc'});
    client.responses['NCmbLCw']!.complete(
      http.StreamedResponse(
        Stream.value(utf8.encode(_response(id: 'NCmbLCw'))),
        200,
      ),
    );
    expect(
      await second,
      Uri.parse('https://static.exercisedb.dev/media/NCmbLCw.gif'),
    );
    expect(client.aborted, {'I4hDWkc'});
  });

  test('closing the viewer cancels in-flight metadata request', () async {
    final client = _AbortClient();
    final active = ExerciseDbService(client: client);
    final result = active.resolveGif('I4hDWkc');
    await client.started.future;
    active.cancelPending();
    await expectLater(result, throwsA(isA<ExerciseMediaFailure>()));
    expect(client.aborted, isTrue);
    active.close();
  });

  test('disposing service cancels in-flight GIF byte download', () async {
    final client = _AbortClient();
    final active = ExerciseDbService(client: client);
    final result = active.loadGif(
      Uri.parse('https://static.exercisedb.dev/media/I4hDWkc.gif'),
      'I4hDWkc',
    );
    await client.started.future;
    active.close();
    await expectLater(result, throwsA(isA<ExerciseMediaFailure>()));
    expect(client.aborted, isTrue);
  });
  test('60 editorial entries have unique stable IDs and valid content', () {
    expect(bundledExerciseLibrary.length, 60);
    expect(bundledExerciseLibrary.map((e) => e.id).toSet().length, 60);
    expect(bundledExerciseLibrary.map((e) => e.sourceId).toSet().length, 60);
    for (final e in bundledExerciseLibrary) {
      expect(e.id, 'edb-${e.sourceId}');
      expect(
        () => ExerciseLibraryEntry.fromMap(e.id, {
          'sourceId': e.sourceId,
          'sourceProvider': e.sourceProvider,
          'name': e.name,
          'region': e.region,
          'equipment': e.equipment,
          'target': e.target,
          'steps': e.steps,
          'easier': e.easier,
          'isActive': e.isActive,
          'schemaVersion': 1,
        }),
        returnsNormally,
      );
    }
  });

  test(
    'remote edit, archive and addition replace bundled content before visibility',
    () {
      final original = ExerciseLibraryEntry.fromMap('one', _map());
      final edit = ExerciseLibraryEntry.fromMap('one', {
        ..._map(),
        'name': 'Tên mới',
      });
      final hidden = ExerciseLibraryEntry.fromMap('one', _map(active: false));
      final added = ExerciseLibraryEntry.fromMap('two', _map());
      expect(
        mergeExerciseLibrary([original], [edit, added]).map((e) => e.name),
        ['Tên mới', 'Chống đẩy thử'],
      );
      expect(
        mergeExerciseLibrary([original], [hidden, added]).map((e) => e.id),
        ['two'],
      );
      expect(mergeExerciseLibrary([original], [edit]).single.name, 'Tên mới');
    },
  );

  test(
    'malformed remote data is rejected rather than reviving bundled entry',
    () {
      for (final patch in [
        {'sourceId': '../unsafe'},
        {
          'steps': ['only one'],
        },
        {'schemaVersion': 2},
        {'isActive': 'false'},
        {'region': 'invalid'},
        {'equipment': 'unknown'},
        {'target': ''},
        {'name': ' '},
        {
          'steps': ['a', 3],
        },
      ]) {
        expect(
          () => ExerciseLibraryEntry.fromMap('one', {..._map(), ...patch}),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'search handles tone-free and combining characters with both filters',
    () {
      final e = ExerciseLibraryEntry.fromMap('one', _map());
      expect(
        filterExerciseLibrary(
          [e],
          query: 'chong đẩy',
          region: 'chest',
          equipment: 'bodyweight',
        ),
        [e],
      );
      expect(filterExerciseLibrary([e], region: 'legs'), isEmpty);
      expect(filterExerciseLibrary([e], equipment: 'dumbbell'), isEmpty);
    },
  );

  test('release gate and invalid IDs make zero requests', () async {
    var calls = 0;
    final client = MockClient((r) async {
      calls++;
      return http.Response('{}', 200);
    });
    final disabled = ExerciseDbService(client: client, enabled: false);
    await expectLater(
      disabled.resolveGif('I4hDWkc'),
      throwsA(isA<ExerciseMediaFailure>()),
    );
    final enabled = ExerciseDbService(client: client);
    await expectLater(
      enabled.resolveGif('../unsafe'),
      throwsA(isA<ExerciseMediaFailure>()),
    );
    expect(calls, 0);
  });

  test('every open resolves fresh media without caching details', () async {
    var calls = 0;
    final service = ExerciseDbService(
      client: MockClient((r) async {
        calls++;
        expect(
          r.url.toString(),
          'https://oss.exercisedb.dev/api/v1/exercises/I4hDWkc',
        );
        expect(r.followRedirects, isFalse);
        return http.Response(_response(), 200);
      }),
    );
    addTearDown(service.close);
    await service.resolveGif('I4hDWkc');
    await service.resolveGif('I4hDWkc');
    expect(calls, 2);
  });

  test(
    'forged host, wrong ID, http, credentials and redirected media are rejected',
    () async {
      for (final payload in [
        _response(id: 'AAAAAAA'),
        _response(url: 'https://evil.test/media/I4hDWkc.gif'),
        _response(url: 'http://static.exercisedb.dev/media/I4hDWkc.gif'),
        _response(url: 'https://user@static.exercisedb.dev/media/I4hDWkc.gif'),
        _response(url: 'https://static.exercisedb.dev:444/media/I4hDWkc.gif'),
        _response(url: 'https://static.exercisedb.dev/media/AAAAAAA.gif'),
        '{"success":false,"data":{}}',
        '[]',
        '{bad',
      ]) {
        final service = ExerciseDbService(
          client: MockClient((_) async => http.Response(payload, 200)),
        );
        await expectLater(
          service.resolveGif('I4hDWkc'),
          throwsA(isA<ExerciseMediaFailure>()),
        );
        service.close();
      }
    },
  );

  test(
    '429 respects retry-after, never loops and blocks immediate retries',
    () async {
      var calls = 0;
      final service = ExerciseDbService(
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 429, headers: {'retry-after': '120'});
        }),
      );
      await expectLater(
        service.resolveGif('I4hDWkc'),
        throwsA(
          isA<ExerciseMediaFailure>().having(
            (e) => e.retryAfter,
            'wait',
            const Duration(seconds: 120),
          ),
        ),
      );
      await expectLater(
        service.resolveGif('I4hDWkc'),
        throwsA(isA<ExerciseMediaFailure>()),
      );
      expect(calls, 1);
      service.close();
    },
  );

  test('network timeout gives actionable failure', () async {
    final service = ExerciseDbService(
      client: MockClient((_) async => throw TimeoutException('test')),
    );
    await expectLater(
      service.resolveGif('I4hDWkc'),
      throwsA(
        isA<ExerciseMediaFailure>().having(
          (e) => e.message,
          'text',
          contains('quá lâu'),
        ),
      ),
    );
    service.close();
  });

  test('GIF download verifies type, signature and size', () async {
    final uri = Uri.parse('https://static.exercisedb.dev/media/I4hDWkc.gif');
    for (final response in [
      http.Response(
        'not a gif payload',
        200,
        headers: {'content-type': 'image/gif'},
      ),
      http.Response(
        'GIF89a123456789',
        200,
        headers: {'content-type': 'text/html'},
      ),
      http.Response(
        'GIF89a123456789',
        302,
        headers: {'content-type': 'image/gif'},
      ),
    ]) {
      final service = ExerciseDbService(
        client: MockClient((_) async => response),
      );
      await expectLater(
        service.loadGif(uri, 'I4hDWkc'),
        throwsA(isA<ExerciseMediaFailure>()),
      );
      service.close();
    }
    final service = ExerciseDbService(
      client: MockClient(
        (_) async => http.Response(
          'GIF89a123456789',
          200,
          headers: {'content-type': 'image/gif'},
        ),
      ),
    );
    expect(await service.loadGif(uri, 'I4hDWkc'), hasLength(15));
    service.close();
  });
}
