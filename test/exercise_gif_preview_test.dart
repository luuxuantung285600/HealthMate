import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/activity/data/exercise_db_service.dart';
import 'package:healthmate/features/activity/models/exercise_library_entry.dart';
import 'package:healthmate/features/activity/presentation/exercise_gif_preview.dart';

final _gif = base64Decode(
  'R0lGODlhAwADAIEAAP8AAAAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQACgAAACwAAAAAAwADAAAIBwABCBw4MCAAIfkEAQoAAQAsAAAAAAMAAwCBAAD/AAAAAAAAAAAACAcAAQgcODAgADs=',
);

ExerciseLibraryEntry _entry([String source = 'abc1234']) =>
    ExerciseLibraryEntry(
      id: 'test',
      sourceId: source,
      name: 'Động tác kiểm thử',
      region: 'legs',
      equipment: 'bodyweight',
      target: 'Đùi',
      steps: const ['Đứng vững.', 'Tập chậm.'],
      easier: 'Giảm độ sâu.',
    );

class _Service extends ExerciseDbService {
  _Service({super.enabled = true, Uint8List? bytes}) : _bytes = bytes ?? _gif;
  final Uint8List _bytes;
  int resolves = 0, loads = 0;
  Completer<Uri>? pending;
  @override
  Future<Uri> resolveGif(String sourceId, {Object? owner}) async {
    resolves++;
    return pending == null
        ? Uri.https('test.invalid', '/$sourceId.gif')
        : pending!.future;
  }

  @override
  Future<Uint8List> loadGif(Uri uri, String sourceId, {Object? owner}) async {
    loads++;
    return _bytes;
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Service service, {
  String source = 'abc1234',
  bool reduceMotion = false,
  bool visible = true,
  bool autoLoad = false,
  bool compact = false,
  bool thumbnail = false,
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [exerciseDbServiceProvider.overrideWithValue(service)],
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        themeAnimationDuration: Duration.zero,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: TickerMode(
            enabled: visible,
            child: Scaffold(
              body: SingleChildScrollView(
                child: ExerciseGifPreview(
                  entry: _entry(source),
                  autoLoad: autoLoad,
                  compact: compact,
                  thumbnail: thumbnail,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('load-exercise-gif')));
  await tester.pump();
  // The engine's codec completes outside Flutter's fake clock.
  for (
    var attempt = 0;
    attempt < 20 && find.byType(RawImage).evaluate().isEmpty;
    attempt++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  expect(find.byType(RawImage), findsOneWidget);
}

void main() {
  testWidgets(
    'dark mode clears white backdrop and switching to light restores the same source without a new request',
    (tester) async {
      final whiteGif = Uint8List.fromList(_gif);
      // The existing two-frame GIF has a red first palette entry; make that
      // entry opaque white to exercise background removal in the real codec.
      whiteGif.setRange(13, 16, [255, 255, 255]);
      final service = _Service(bytes: whiteGif);
      addTearDown(service.close);
      await _pump(tester, service, autoLoad: true, reduceMotion: true);
      for (var i = 0; i < 30 && find.byType(RawImage).evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      Future<List<int>> firstPixel() async {
        final frame = tester.widget<RawImage>(find.byType(RawImage)).image!;
        final data = await tester.runAsync(
          () => frame.toByteData(format: ui.ImageByteFormat.rawRgba),
        );
        return data!.buffer.asUint8List(data.offsetInBytes, 4).toList();
      }

      expect(await firstPixel(), [255, 255, 255, 255]);
      await _pump(
        tester,
        service,
        autoLoad: true,
        reduceMotion: true,
        brightness: Brightness.dark,
      );
      for (var i = 0; i < 30 && find.byType(RawImage).evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(await firstPixel(), [0, 0, 0, 0]);
      await _pump(tester, service, autoLoad: true, reduceMotion: true);
      await tester.pumpAndSettle();
      expect(await firstPixel(), [255, 255, 255, 255]);
      expect(service.resolves, 1);
      expect(service.loads, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'card thumbnail pause preserves the frame and exposes an accessible play action',
    (tester) async {
      final service = _Service();
      addTearDown(service.close);
      await _pump(
        tester,
        service,
        autoLoad: true,
        compact: true,
        thumbnail: true,
      );
      for (var i = 0; i < 20 && find.byType(RawImage).evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(find.byType(RawImage), findsOneWidget);
      expect(find.byTooltip('Tạm dừng GIF'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pause-exercise-gif')));
      await tester.pump();
      final frame = tester.widget<RawImage>(find.byType(RawImage)).image;
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, same(frame));
      expect(find.byTooltip('Phát GIF'), findsOneWidget);
      expect(service.resolves, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('inline GIF keeps a fixed frame while loading and can pause', (
    tester,
  ) async {
    final service = _Service()..pending = Completer<Uri>();
    addTearDown(service.close);
    await _pump(tester, service, autoLoad: true, compact: true);
    expect(service.resolves, 1);
    expect(
      tester.getSize(find.byKey(const ValueKey('exercise-gif-frame'))).height,
      150,
    );
    service.pending!.complete(Uri.https('test.invalid', '/abc1234.gif'));
    await tester.pump();
    for (var i = 0; i < 20 && find.byType(RawImage).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(find.byType(RawImage), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('exercise-gif-frame'))).height,
      150,
    );
    await tester.tap(find.byKey(const ValueKey('pause-exercise-gif')));
    await tester.pump();
    final paused = tester.widget<RawImage>(find.byType(RawImage)).image;
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, same(paused));
    expect(find.text('Phát GIF'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('returning to a visible inline card loads it once again', (
    tester,
  ) async {
    final service = _Service();
    addTearDown(service.close);
    await _pump(tester, service, autoLoad: true, compact: true);
    expect(service.resolves, 1);
    await _pump(tester, service, autoLoad: true, compact: true, visible: false);
    expect(find.byType(RawImage), findsNothing);
    await _pump(tester, service, autoLoad: true, compact: true);
    expect(service.resolves, 2);
    await _pump(tester, service, autoLoad: true, compact: true);
    expect(service.resolves, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'detail auto-loads once and background never restarts a download',
    (tester) async {
      final service = _Service();
      addTearDown(service.close);
      await _pump(tester, service, autoLoad: true);
      await tester.pump();
      expect(service.resolves, 1);
      await _pump(tester, service, autoLoad: true);
      expect(service.resolves, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(service.resolves, 1);
      expect(find.byType(RawImage), findsNothing);
      await _pump(tester, service, autoLoad: true, visible: false);
      await _pump(tester, service, autoLoad: true);
      expect(service.resolves, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'GIF loads explicitly; pause retains frame; close releases media',
    (tester) async {
      final service = _Service();
      addTearDown(service.close);
      await _pump(tester, service);
      expect(service.resolves, 0);
      expect(service.loads, 0);
      await _open(tester);
      expect(service.resolves, 1);
      expect(service.loads, 1);
      final initialFrame = tester.widget<RawImage>(find.byType(RawImage)).image;
      await tester.pump(const Duration(milliseconds: 150));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      expect(
        tester.widget<RawImage>(find.byType(RawImage)).image,
        isNot(same(initialFrame)),
      );
      await tester.tap(find.byKey(const ValueKey('pause-exercise-gif')));
      await tester.pump();
      final frame = tester.widget<RawImage>(find.byType(RawImage)).image;
      expect(frame, isNotNull);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, same(frame));
      expect(find.text('Phát GIF'), findsOneWidget);
      await tester.tap(find.text('Đóng GIF'));
      await tester.pump();
      expect(find.byType(RawImage), findsNothing);
      expect(find.text('Xem GIF'), findsOneWidget);
      expect(service.loads, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('background clears media and resume needs explicit reopen', (
    tester,
  ) async {
    final service = _Service();
    addTearDown(service.close);
    await _pump(tester, service);
    await _open(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.byType(RawImage), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(service.resolves, 1);
    expect(find.text('Xem GIF'), findsOneWidget);
    await _open(tester);
    expect(service.loads, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('changed source ignores stale pending resolver', (tester) async {
    final service = _Service()..pending = Completer<Uri>();
    addTearDown(service.close);
    await _pump(tester, service);
    await tester.tap(find.text('Xem GIF'));
    await tester.pump();
    final pending = service.pending!;
    await _pump(tester, service, source: 'def5678');
    pending.complete(Uri.https('test.invalid', '/old.gif'));
    await tester.pumpAndSettle();
    expect(service.loads, 0);
    expect(find.byType(RawImage), findsNothing);
    expect(find.text('Xem GIF'), findsOneWidget);
    service.pending = null;
    await _open(tester);
    expect(service.resolves, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion displays a static initial frame', (tester) async {
    final service = _Service();
    addTearDown(service.close);
    await _pump(tester, service, reduceMotion: true);
    await _open(tester);
    expect(find.text('Phát GIF'), findsOneWidget);
    final frame = tester.widget<RawImage>(find.byType(RawImage)).image;
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, same(frame));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('hidden mounted branch drops media through TickerMode', (
    tester,
  ) async {
    final service = _Service();
    addTearDown(service.close);
    await _pump(tester, service);
    await _open(tester);
    await _pump(tester, service, visible: false);
    expect(find.byType(RawImage), findsNothing);
    await _pump(tester, service);
    expect(find.text('Xem GIF'), findsOneWidget);
    expect(service.loads, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'disabled media explains availability and provides no load action',
    (tester) async {
      final service = _Service(enabled: false);
      addTearDown(service.close);
      await _pump(tester, service, autoLoad: true);
      expect(find.textContaining('chỉ bật ở bản kiểm thử'), findsOneWidget);
      expect(find.byKey(const ValueKey('load-exercise-gif')), findsNothing);
      expect(service.resolves, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
