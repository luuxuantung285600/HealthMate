import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/activity/presentation/workouts_screen.dart';
import 'package:healthmate/features/activity/models/exercise_library_entry.dart';
import 'package:healthmate/features/activity/presentation/exercise_library_screen.dart';
import 'package:healthmate/features/activity/providers/exercise_library_providers.dart';
import 'package:healthmate/features/activity/providers/activity_providers.dart';
import 'package:healthmate/features/activity/models/guided_workout.dart';
import 'package:healthmate/features/activity/presentation/movement_media_preview.dart';
import 'package:healthmate/features/activity/presentation/exercise_gif_preview.dart';
import 'support/fake_activity_repository.dart';

const _entry = ExerciseLibraryEntry(
  id: 'test-squat',
  name: 'Ngồi xuống',
  sourceId: 'test-source',
  region: 'legs',
  equipment: 'bodyweight',
  target: 'Đùi trước',
  steps: ['Đứng vững.', 'Hạ người trong tầm thoải mái.'],
  easier: 'Giảm độ sâu.',
  isActive: true,
);

Future<void> _pump(
  WidgetTester tester,
  Stream<List<ExerciseLibraryEntry>> stream, {
  double scale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [exerciseLibraryProvider.overrideWith((ref) => stream)],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const ExerciseLibraryScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'guided preview uses exact GIF identity and respects admin removal',
    (tester) async {
      final stream = StreamController<List<ExerciseLibraryEntry>>.broadcast();
      addTearDown(stream.close);
      const wallPush = ExerciseLibraryEntry(
        id: 'edb-NCmbLCw',
        sourceId: 'admin-source',
        name: 'Chống đẩy tường',
        region: 'chest',
        equipment: 'bodyweight',
        target: 'Ngực',
        steps: ['Đẩy tường.'],
        easier: 'Đứng gần hơn.',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseLibraryProvider.overrideWith((ref) => stream.stream),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    MovementMediaPreview(movement: GuidedWorkouts.wallPush),
                    MovementMediaPreview(movement: GuidedWorkouts.crunch),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      stream.add([wallPush]);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ExerciseGifPreview>(find.byType(ExerciseGifPreview))
            .entry
            .sourceId,
        'admin-source',
      );
      expect(
        find.byType(Image),
        findsNothing,
        reason:
            'Unmapped standing crunch must not use a floor crunch GIF or human thumbnail.',
      );
      stream.add([]);
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseGifPreview), findsNothing);
      expect(find.textContaining('đã được ẩn'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('search accepts unaccented text and shows empty result', (
    tester,
  ) async {
    await _pump(tester, Stream.value([_entry]));
    expect(find.text('Ngồi xuống'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('exercise-search')),
      'ngoi xuong',
    );
    await tester.pump();
    expect(find.text('Ngồi xuống'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('exercise-search')),
      'khong co',
    );
    await tester.pump();
    expect(find.textContaining('Không tìm thấy'), findsOneWidget);
  });

  testWidgets(
    'detail follows live edits and removal without requesting media',
    (tester) async {
      final stream = StreamController<List<ExerciseLibraryEntry>>.broadcast();
      addTearDown(stream.close);
      await _pump(tester, stream.stream);
      stream.add([_entry]);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('exercise-test-squat')));
      await tester.pumpAndSettle();
      expect(find.text('Cách thực hiện'), findsOneWidget);
      stream.add([
        const ExerciseLibraryEntry(
          id: 'test-squat',
          name: 'Ngồi xuống đã sửa',
          sourceId: 'test-source',
          region: 'legs',
          equipment: 'bodyweight',
          target: 'Đùi trước',
          steps: ['Đứng vững.', 'Chậm rãi hạ người.'],
          easier: 'Giảm độ sâu.',
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Ngồi xuống đã sửa'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Bước 2. Chậm rãi hạ người.'),
        findsOneWidget,
      );
      stream.add([]);
      await tester.pumpAndSettle();
      expect(find.textContaining('hiện không còn'), findsOneWidget);
    },
  );

  testWidgets('320 pixel screen supports doubled text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, Stream.value([_entry]), scale: 2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('exercise-test-squat')),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ExerciseLibraryScreen),
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            ),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-test-squat')));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseLibraryDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workouts opens GIF library first and retains timed sessions', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.workouts,
      routes: [
        GoRoute(
          path: AppRoutes.workouts,
          builder: (_, _) => const WorkoutsScreen(),
          routes: [
            GoRoute(
              path: 'exercises',
              builder: (_, _) => const ExerciseLibraryScreen(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exerciseLibraryProvider.overrideWith((ref) => Stream.value([_entry])),
          activityRepositoryProvider.overrideWithValue(
            FakeActivityRepository(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseLibraryScreen), findsOneWidget);
    expect(find.text('Ngồi xuống'), findsOneWidget);
    expect(
      GoRouterState.of(
        tester.element(find.byType(ExerciseLibraryScreen)),
      ).uri.path,
      AppRoutes.workouts,
    );
    await tester.tap(find.byKey(const ValueKey('open-timed-workouts')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('workout-full_body')), findsOneWidget);
    await tester.tap(find.text('Thư viện động tác'));
    await tester.pumpAndSettle();
    expect(find.text('Ngồi xuống'), findsOneWidget);
  });

  testWidgets('loading, error and retry states are available', (tester) async {
    final stream = StreamController<List<ExerciseLibraryEntry>>.broadcast();
    addTearDown(stream.close);
    await _pump(tester, stream.stream);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    stream.addError(StateError('offline'));
    await tester.pump();
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.textContaining('Chưa tải được'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    stream.add([_entry]);
    await tester.pump();
    expect(find.text('Ngồi xuống'), findsOneWidget);
  });
}
