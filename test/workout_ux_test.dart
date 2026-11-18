import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/activity/data/bundled_exercise_library.dart';
import 'package:healthmate/features/activity/data/exercise_db_service.dart';
import 'package:healthmate/features/activity/models/exercise_library_entry.dart';
import 'package:healthmate/features/activity/presentation/exercise_library_screen.dart';
import 'package:healthmate/features/activity/presentation/exercise_gif_preview.dart';
import 'package:healthmate/features/activity/presentation/workouts_screen.dart';
import 'package:healthmate/features/activity/providers/activity_providers.dart';
import 'package:healthmate/features/activity/providers/exercise_library_providers.dart';

import 'support/fake_activity_repository.dart';
import 'support/load_icon_font.dart';

const _entries = [
  ExerciseLibraryEntry(
    id: 'push',
    sourceId: 'I4hDWkc',
    name: 'Chống đẩy',
    region: 'chest',
    equipment: 'bodyweight',
    target: 'Ngực',
    steps: ['Giữ thân thẳng.'],
    easier: 'Chống đẩy tường.',
  ),
  ExerciseLibraryEntry(
    id: 'press',
    sourceId: 'abc1234',
    name: 'Đẩy ngực với tạ',
    region: 'chest',
    equipment: 'dumbbell',
    target: 'Ngực',
    steps: ['Nâng tạ chậm.'],
    easier: 'Chọn tạ nhẹ hơn.',
  ),
  ExerciseLibraryEntry(
    id: 'squat',
    sourceId: 'def1234',
    name: 'Squat',
    region: 'legs',
    equipment: 'bodyweight',
    target: 'Đùi',
    steps: ['Giữ gối theo mũi chân.'],
    easier: 'Hạ nông hơn.',
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(430, 950),
  double scale = 1,
  bool dark = true,
  bool shell = false,
  List<ExerciseLibraryEntry> entries = _entries,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final service = ExerciseDbService(enabled: false);
  addTearDown(service.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        exerciseLibraryProvider.overrideWith((ref) => Stream.value(entries)),
        exerciseDbServiceProvider.overrideWithValue(service),
        activityRepositoryProvider.overrideWithValue(FakeActivityRepository()),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: shell ? const WorkoutsScreen() : const ExerciseLibraryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadIconFont);

  testWidgets(
    'session covers use an exact mapped movement from that workout and follow removal',
    (tester) async {
      final stream = StreamController<List<ExerciseLibraryEntry>>.broadcast();
      addTearDown(stream.close);
      final service = ExerciseDbService(enabled: false);
      addTearDown(service.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseLibraryProvider.overrideWith((ref) => stream.stream),
            exerciseDbServiceProvider.overrideWithValue(service),
            activityRepositoryProvider.overrideWithValue(
              FakeActivityRepository(),
            ),
          ],
          child: MaterialApp(home: const WorkoutsScreen()),
        ),
      );
      stream.add(bundledExerciseLibrary);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-timed-workouts')));
      await tester.pumpAndSettle();
      final cover = find.descendant(
        of: find.byKey(const ValueKey('workout-full_body')),
        matching: find.byType(ExerciseGifPreview),
      );
      expect(cover, findsOneWidget);
      expect(
        tester.widget<ExerciseGifPreview>(cover).entry.sourceId,
        'NCmbLCw',
      );
      stream.add([]);
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseGifPreview), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'region, equipment and query compose; reset clears fields and results',
    (tester) async {
      await _pump(tester);
      await tester.tap(find.byKey(const ValueKey('region-chest')));
      await tester.pump();
      expect(find.text('2 động tác'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('exercise-filters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('equipment-dumbbell')));
      await tester.tap(find.byKey(const ValueKey('apply-exercise-filters')));
      await tester.pumpAndSettle();
      expect(find.text('1 động tác'), findsOneWidget);
      expect(find.text('Đẩy ngực với tạ'), findsOneWidget);
      expect(find.text('Chống đẩy'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('exercise-search')),
        'khong co',
      );
      await tester.pump();
      expect(find.textContaining('Không tìm thấy'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('clear-exercise-filters')));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('exercise-search')))
            .controller!
            .text,
        isEmpty,
      );
      expect(find.text('3 động tác'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dismissed filter draft does not change results', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('exercise-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('equipment-dumbbell')));
    Navigator.of(
      tester.element(find.byKey(const ValueKey('apply-exercise-filters'))),
    ).pop();
    await tester.pumpAndSettle();
    expect(find.text('3 động tác'), findsOneWidget);
  });

  testWidgets(
    'switching timed sessions retains library search and source information is reachable',
    (tester) async {
      await _pump(tester, shell: true);
      await tester.enterText(
        find.byKey(const ValueKey('exercise-search')),
        'chong day',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('open-timed-workouts')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('workout-full_body')), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('open-exercise-library')).hitTestable(),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 động tác'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('exercise-search')))
            .controller!
            .text,
        'chong day',
      );
      await tester.tap(find.byTooltip('Nguồn GIF và tập luyện an toàn'));
      await tester.pumpAndSettle();
      expect(find.textContaining('phi thương mại'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 800),
    const Size(430, 950),
    const Size(900, 1000),
  ]) {
    for (final dark in [true, false]) {
      testWidgets(
        'library, filter sheet and detail fit $size dark=$dark at large text',
        (tester) async {
          await _pump(
            tester,
            size: size,
            scale: 2,
            dark: dark,
            shell: true,
            entries: bundledExerciseLibrary,
          );
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(
            find.byKey(const ValueKey('exercise-filters')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('exercise-filters')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(
            find.byKey(const ValueKey('apply-exercise-filters')),
          );
          await tester.pumpAndSettle();
          final first = find.byKey(
            ValueKey('exercise-${bundledExerciseLibrary.first.id}'),
          );
          final scroll = find
              .descendant(
                of: find.byType(ExerciseLibraryScreen),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                ),
              )
              .first;
          await tester.scrollUntilVisible(first, 250, scrollable: scroll);
          await tester.tap(first);
          await tester.pumpAndSettle();
          expect(find.byType(ExerciseLibraryDetailScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.drag(find.byType(ListView), const Offset(0, -650));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
