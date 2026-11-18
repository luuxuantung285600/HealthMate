import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/activity/data/bundled_exercise_library.dart';
import 'package:healthmate/features/activity/data/exercise_db_service.dart';
import 'package:healthmate/features/activity/models/exercise_library_entry.dart';
import 'package:healthmate/features/activity/presentation/exercise_gif_preview.dart';
import 'package:healthmate/features/activity/presentation/exercise_library_screen.dart';
import 'package:healthmate/features/activity/providers/exercise_library_providers.dart';

import 'support/load_icon_font.dart';

const femaleSourceIds = [
  'Nh3mvOO',
  'Pjbc0Kt',
  'yT9tk17',
  'BCs0G2F',
  'r5DgrW9',
  'daBmy1Y',
  'BmrwWzo',
  'gFyFj9z',
  'wSScovH',
  'eOG0r6v',
];

void main() {
  setUpAll(loadIconFont);

  test(
    'unaccented search finds all 10 female illustrations and composes with filters',
    () {
      final entries = filterExerciseLibrary(
        bundledExerciseLibrary,
        query: 'mau nu',
      );
      expect(
        entries.map((entry) => entry.sourceId),
        unorderedEquals(femaleSourceIds),
      );
      expect(
        filterExerciseLibrary(
          bundledExerciseLibrary,
          query: 'nu',
          region: 'back',
        ).map((e) => e.sourceId),
        unorderedEquals(['Nh3mvOO']),
      );
      expect(
        filterExerciseLibrary(
          bundledExerciseLibrary,
          query: 'nu',
          equipment: 'band',
        ).map((e) => e.sourceId),
        unorderedEquals(['Pjbc0Kt', 'wSScovH']),
      );
    },
  );

  test(
    'admin can edit, archive and restore female bundled entries without losing the original catalog',
    () {
      final base = bundledExerciseLibrary.singleWhere(
        (entry) => entry.sourceId == 'Nh3mvOO',
      );
      ExerciseLibraryEntry override(bool active) => ExerciseLibraryEntry(
        id: base.id,
        sourceId: base.sourceId,
        name: 'Tên bài do admin sửa',
        region: base.region,
        equipment: base.equipment,
        target: base.target,
        steps: base.steps,
        easier: base.easier,
        isActive: active,
      );
      final archived = mergeExerciseLibrary(bundledExerciseLibrary, [
        override(false),
      ]);
      expect(archived, hasLength(59));
      expect(archived.any((entry) => entry.id == base.id), isFalse);
      expect(
        archived.where((entry) => !femaleSourceIds.contains(entry.sourceId)),
        hasLength(50),
      );
      final restored = mergeExerciseLibrary(bundledExerciseLibrary, [
        override(true),
      ]);
      expect(restored, hasLength(60));
      expect(
        restored.singleWhere((entry) => entry.id == base.id).name,
        'Tên bài do admin sửa',
      );
    },
  );

  for (final sourceId in femaleSourceIds) {
    testWidgets('female exercise $sourceId opens its own exact illustration', (
      tester,
    ) async {
      final entry = bundledExerciseLibrary.singleWhere(
        (entry) => entry.sourceId == sourceId,
      );
      final service = ExerciseDbService(enabled: false);
      addTearDown(service.close);
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
            home: const ExerciseLibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('exercise-search')),
        entry.name,
      );
      await tester.pumpAndSettle();
      expect(find.text('1 động tác'), findsOneWidget);
      final card = find.byKey(ValueKey('exercise-${entry.id}'));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      final media = find.descendant(
        of: find.byType(ExerciseLibraryDetailScreen),
        matching: find.byType(ExerciseGifPreview),
      );
      expect(media, findsOneWidget);
      expect(tester.widget<ExerciseGifPreview>(media).entry.sourceId, sourceId);
      expect(find.text(entry.name), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
