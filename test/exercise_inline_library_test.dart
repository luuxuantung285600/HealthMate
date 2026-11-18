import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/activity/data/bundled_exercise_library.dart';
import 'package:healthmate/features/activity/data/exercise_db_service.dart';
import 'package:healthmate/features/activity/presentation/exercise_library_screen.dart';
import 'package:healthmate/features/activity/providers/exercise_library_providers.dart';

import 'support/load_icon_font.dart';

class _FixtureGifService extends ExerciseDbService {
  _FixtureGifService() : super(enabled: true);
  final requests = <String>[];
  @override
  Future<Uri> resolveGif(String sourceId, {Object? owner}) async {
    requests.add(sourceId);
    return Uri.https('fixture.invalid', '/$sourceId.gif');
  }

  @override
  Future<Uint8List> loadGif(
    Uri uri,
    String sourceId, {
    Object? owner,
  }) async => base64Decode(
    'R0lGODlhAwADAIEAAP8AAAAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQACgAAACwAAAAAAwADAAAIBwABCBw4MCAAIfkEAQoAAQAsAAAAAAMAAwCBAAD/AAAAAAAAAAAACAcAAQgcODAgADs=',
  );
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
  });
  testWidgets(
    'inline GIFs load lazily and keep list media visible without opening detail',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _FixtureGifService();
      addTearDown(service.close);
      final capture = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseLibraryProvider.overrideWith(
              (ref) => Stream.value(bundledExerciseLibrary),
            ),
            exerciseDbServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                disableAnimations: true,
              ),
              child: RepaintBoundary(
                key: capture,
                child: const ExerciseLibraryScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      for (var i = 0; i < 10 && find.byType(RawImage).evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(service.requests, isNotEmpty);
      expect(
        service.requests.length,
        lessThan(5),
        reason: 'Opening the catalog must not request every GIF.',
      );
      expect(find.byType(RawImage), findsWidgets);
      expect(find.byType(ExerciseLibraryDetailScreen), findsNothing);
      final count = service.requests.length;
      await tester.pump();
      expect(service.requests.length, count);
      await tester.runAsync(() async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        await Directory('build/exercise-inline').create(recursive: true);
        await File(
          'build/exercise-inline/list-dark-test-fixture.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
      });
      await tester.drag(
        find.byKey(const ValueKey('exercise-library-scroll')),
        const Offset(0, -550),
      );
      await tester.pump();
      await tester.pump();
      expect(service.requests.length, greaterThan(count));
      expect(service.requests.length, lessThan(10));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
