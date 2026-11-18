import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/activity/data/bundled_exercise_library.dart';
import 'package:healthmate/features/activity/data/exercise_db_service.dart';
import 'package:healthmate/features/activity/presentation/exercise_library_screen.dart';
import 'package:healthmate/features/activity/providers/exercise_library_providers.dart';

import 'support/load_icon_font.dart';
import 'support/test_app.dart';

/// Optional visual review uses exact source GIFs downloaded to ignored build/.
/// Missing media fails explicitly; it is never replaced with another exercise.
class _CapturedMedia extends ExerciseDbService {
  _CapturedMedia(this.media) : super(enabled: true);
  final Map<String, Uint8List> media;
  @override
  Future<Uri> resolveGif(String sourceId, {Object? owner}) async {
    if (!media.containsKey(sourceId)) {
      throw const ExerciseMediaFailure(
        'Không có tệp minh họa trong bản chụp kiểm thử.',
      );
    }
    return Uri.https('static.exercisedb.dev', '/media/$sourceId.gif');
  }

  @override
  Future<Uint8List> loadGif(Uri uri, String sourceId, {Object? owner}) async =>
      media[sourceId]!;
}

Future<void> _decode(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.pump(const Duration(milliseconds: 500));
  await _decode(tester);
  expect(tester.takeException(), isNull);
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final shot = await boundary.toImage(pixelRatio: 2);
    final bytes = await shot.toByteData(format: ui.ImageByteFormat.png);
    shot.dispose();
    await File(
      'build/workout-flow-20261117/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    await loadIconFont();
    final font = FontLoader('Public Sans');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(
        rootBundle.load('assets/fonts/public_sans/PublicSans-$weight.ttf'),
      );
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final config in [
    (width: 360.0, scale: 1.0),
    (width: 390.0, scale: 1.2),
    (width: 430.0, scale: 1.0),
    (width: 900.0, scale: 1.0),
  ]) {
    testWidgets(
      'all catalog titles fit at width=${config.width} scale=${config.scale}',
      (tester) async {
        tester.view.physicalSize = Size(config.width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final media = ExerciseDbService(enabled: false);
        addTearDown(media.close);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              exerciseLibraryProvider.overrideWith(
                (ref) => Stream.value(bundledExerciseLibrary),
              ),
              exerciseDbServiceProvider.overrideWithValue(media),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(config.scale)),
                child: child!,
              ),
              home: const ExerciseLibraryScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final scroll = find.byKey(const ValueKey('exercise-library-scroll'));
        final last = find.byKey(
          ValueKey('exercise-${bundledExerciseLibrary.last.id}'),
        );
        for (var i = 0; i < 45 && last.evaluate().isEmpty; i++) {
          await tester.drag(scroll, const Offset(0, -420));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(last, findsOneWidget);
        await tester.ensureVisible(last);
        await tester.pumpAndSettle();
        expect(last.hitTestable(), findsOneWidget);
        await tester.tap(last);
        await tester.pumpAndSettle();
        expect(find.byType(ExerciseLibraryDetailScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'capture the real workout widgets in dark and light themes',
    (tester) async {
      final media = <String, Uint8List>{};
      await tester.runAsync(() async {
        for (final file in Directory(
          'build/workout-flow-20261117/media',
        ).listSync().whereType<File>()) {
          media[file.uri.pathSegments.last.split('.').first] = await file
              .readAsBytes();
        }
      });
      expect(media, contains('NCmbLCw'));
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      for (final mode in [ThemeMode.dark, ThemeMode.light]) {
        final key = GlobalKey();
        final container = await pumpApp(
          tester,
          captureKey: key,
          size: const Size(430, 950),
          initialThemeMode: mode,
          exerciseMediaService: _CapturedMedia(media),
        );
        final router = container.read(appRouterProvider);
        router.go(AppRoutes.workouts);
        await tester.pump(const Duration(milliseconds: 400));
        await _decode(tester);
        await _capture(tester, key, 'library-${mode.name}');
        await tester.tap(find.byKey(const ValueKey('open-timed-workouts')));
        await tester.pump(const Duration(milliseconds: 400));
        await _decode(tester);
        await tester.drag(find.byType(ListView), const Offset(0, -170));
        await tester.pump(const Duration(milliseconds: 400));
        await _decode(tester);
        await _capture(tester, key, 'sessions-${mode.name}');
        router.go('${AppRoutes.workouts}/full_body');
        await tester.pump(const Duration(milliseconds: 400));
        await _decode(tester);
        await tester.tap(find.byKey(const ValueKey('load-exercise-gif')).first);
        await tester.pump(const Duration(milliseconds: 400));
        await _decode(tester);
        await _capture(tester, key, 'detail-${mode.name}');
        router.go('${AppRoutes.workouts}/full_body/session?pace=standard');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(seconds: 90));
        await tester.tap(find.byKey(const ValueKey('pause-workout')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('load-exercise-gif')).first);
        await tester.pump();
        await _capture(tester, key, 'player-${mode.name}');
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
    skip: !const bool.fromEnvironment('WORKOUT_CAPTURE'),
  );
}
