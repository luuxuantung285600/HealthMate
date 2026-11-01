import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/journal/providers/journal_date_provider.dart';
import 'package:healthmate/features/journal/presentation/journal_nutrition_overview.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/nutrition_targets/providers/nutrition_target_providers.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/shared/providers/local_clock_provider.dart';

import 'core_journal_test.dart' as meals show meal;
import 'support/fake_activity_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_nutrition_target_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_energy_repository.dart';
import 'package:healthmate/features/wellness/providers/energy_providers.dart';
import 'support/test_app.dart';
import 'weekly_reflection_test.dart' as logs show weight, water, activity;

final uxToday = DateTime(2026, 10, 18, 12);
const captureBefore = bool.fromEnvironment('HEALTHMATE_U1_BEFORE');

FakeNutritionTargetRepository uxTargets() =>
    FakeNutritionTargetRepository()
      ..byUid['test-uid'] = {
        '2026-10-12': const NutritionTarget(
          effectiveFromDateKey: '2026-10-12',
          kcalTarget: 2000,
          proteinGTarget: 100,
          carbsGTarget: 250,
          fatGTarget: 60,
        ),
      };

Future<void> uxCapture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final picture = await boundary.toImage(pixelRatio: 1);
    final data = await picture.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/u1-layout/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    picture.dispose();
  });
}

Future<ProviderContainer> hostOverview(
  WidgetTester tester,
  AsyncValue<List<MealLog>> state,
  FakeNutritionTargetRepository targets, {
  FakeAuthRepository? auth,
  FutureProvider<List<MealLog>>? source,
}) async {
  final session = auth ?? FakeAuthRepository(user: FakeAuthRepository.testUser);
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(session),
      nutritionTargetRepositoryProvider.overrideWithValue(targets),
      energyRepositoryProvider.overrideWithValue(FakeEnergyRepository()),
      localClockProvider.overrideWithValue(uxToday),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await session.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Consumer(
              builder: (_, ref, _) => JournalNutritionOverview(
                day: uxToday,
                meals: source == null ? state : ref.watch(source),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

void main() {
  setUpAll(() async {
    final font = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(
        rootBundle.load('assets/fonts/be_vietnam_pro/BeVietnamPro-$weight.ttf'),
      );
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('U1 first viewport 390x844 full macro target ${mode.name}', (
      tester,
    ) async {
      final boundary = GlobalKey();
      final container = await pumpApp(
        tester,
        captureKey: boundary,
        initialThemeMode: mode,
        dashboardNow: uxToday,
        targetRepository: uxTargets(),
        nutritionRepository: FakeNutritionRepository(
          meals: [
            meals.meal('sun', date: uxToday),
            meals.meal('fri', date: DateTime(2026, 10, 16, 12)),
          ],
        ),
        waterRepository: FakeWaterRepository(
          logs: [logs.water('w', uxToday, 750)],
        ),
        activityRepository: FakeActivityRepository(
          logs: [logs.activity('a', uxToday, 25)],
        ),
        profileRepository: FakeHealthProfileRepository(
          profile: FakeHealthProfileRepository.testProfile,
          metrics: [
            logs.weight('a', DateTime(2026, 10, 12), 70),
            logs.weight('b', uxToday, 69.5),
          ],
        ),
      );
      container.read(journalDateProvider.notifier).select(uxToday);
      final measurements = <String, Object>{};
      for (final page in [AppRoutes.journal, AppRoutes.progress]) {
        container.read(appRouterProvider).go(page);
        await tester.pumpAndSettle();
        final viewport = tester.getRect(find.byType(CustomScrollView).first);
        final nav = tester.getRect(find.byKey(const ValueKey('nav-dashboard')));
        final cutoff = viewport.bottom < nav.top ? viewport.bottom : nav.top;
        // No scroll/ensureVisible before measuring or taking these screenshots.
        final scroll = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(CustomScrollView).first,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(scroll.position.pixels, 0);
        final isJournal = page == AppRoutes.journal;
        final target = find.byKey(
          ValueKey(isJournal ? 'add-meal-breakfast' : 'weekly-chart'),
        );
        final rect = tester.getRect(target);
        final visible = isJournal
            ? rect.top >= viewport.top &&
                  rect.bottom <= cutoff &&
                  target.hitTestable().evaluate().isNotEmpty
            : rect.top < cutoff && rect.bottom > viewport.top;
        measurements[page] = {
          'top': rect.top,
          'bottom': rect.bottom,
          'bodyBottom': cutoff,
          'visible': visible,
          'offset': scroll.position.pixels,
        };
        final stage = captureBefore ? 'before' : 'after';
        await uxCapture(
          tester,
          boundary,
          '$stage-${isJournal ? 'journal' : 'progress'}-${mode.name}-390-1.0',
        );
        if (!captureBefore) {
          expect(
            visible,
            isTrue,
            reason: '$page first viewport: ${measurements[page]}',
          );
        }
        expect(tester.takeException(), isNull);
      }
      await tester.runAsync(() async {
        final file = File(
          'build/u1-layout/${captureBefore ? 'before' : 'after'}-${mode.name}-measurements.json',
        );
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(measurements),
        );
      });
    });
  }

  testWidgets(
    'U1 recent meal uses selected day and type without search or new confirmation steps',
    (tester) async {
      final repo = FakeNutritionRepository(
        meals: [meals.meal('known', date: uxToday)],
      );
      final container = await pumpApp(
        tester,
        nutritionRepository: repo,
        dashboardNow: uxToday,
        targetRepository: uxTargets(),
      );
      container
          .read(journalDateProvider.notifier)
          .select(DateTime(2026, 10, 16));
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      var taps = 0, scrolls = 0;
      Future<void> tap(Finder finder) async {
        if (finder.hitTestable().evaluate().isEmpty) {
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          scrolls++;
        }
        await tester.tap(finder);
        taps++;
        await tester.pumpAndSettle();
      }

      await tap(find.byKey(const ValueKey('add-meal-breakfast')));
      await tap(find.byTooltip('Dùng lại Cơm trắng chín'));
      await tap(find.byKey(const ValueKey('save-meal')));
      expect(find.byType(MealFormDialog), findsNothing);
      expect(repo.addCalls, 1);
      final saved = repo.meals.singleWhere((m) => m.id != 'known');
      expect(saved.dateKey, '2026-10-16');
      expect(saved.type, MealType.breakfast);
      expect(saved.items.single.grams, 150);
      expect(saved.totals.kcal, 195);
      expect(taps, 3);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final file = File('build/h2-recent-flow.json');
        await file.parent.create(recursive: true);
        await file.writeAsString(
          jsonEncode({
            'taps': taps,
            'scrolls': scrolls,
            'typedSearches': 0,
            'extraConfirmations': 0,
            'portionConfirmations': 0,
            'dateKey': saved.dateKey,
            'type': saved.type.name,
          }),
        );
      });
    },
  );

  for (final error in [false, true]) {
    testWidgets(
      'U1 stale diary payload stays unconfirmed on ${error ? 'error' : 'loading'}',
      (tester) async {
        final pending = Completer<List<MealLog>>();
        var reads = 0;
        final source = FutureProvider<List<MealLog>>((ref) async {
          if (reads++ == 0) return [meals.meal('stale', date: uxToday)];
          return pending.future;
        }, retry: (_, _) => null);
        final container = await hostOverview(
          tester,
          const AsyncData([]),
          uxTargets(),
          source: source,
        );
        await tester.pumpAndSettle();
        expect(find.text('195 kcal / 2000 kcal'), findsOneWidget);
        container.invalidate(source);
        await tester.pump();
        await tester.pump();
        expect(container.read(source).isLoading, isTrue);
        expect(container.read(source).value!.single.totals.kcal, 195);
        if (error) pending.completeError(StateError('private'));
        await tester.pumpAndSettle();
        expect(find.text('— kcal / 2000 kcal'), findsOneWidget);
        expect(find.text('Còn 1805 kcal'), findsNothing);
        expect(find.textContaining('195 kcal'), findsNothing);
        expect(find.textContaining('chưa tính còn/vượt'), findsOneWidget);
        if (!pending.isCompleted) pending.complete([]);
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets(
    'U1 target read error and retry keep recorded totals independently',
    (tester) async {
      final targets = uxTargets()..failRead = true;
      await hostOverview(
        tester,
        AsyncData([meals.meal('a', date: uxToday)]),
        targets,
      );
      await tester.pumpAndSettle();
      expect(find.text('195 kcal / — kcal'), findsOneWidget);
      expect(find.text('Chưa đặt mục tiêu'), findsNothing);
      expect(
        find.byKey(const ValueKey('retry-journal-target')),
        findsOneWidget,
      );
      targets.failRead = false;
      await tester.tap(find.byKey(const ValueKey('retry-journal-target')));
      await tester.pumpAndSettle();
      expect(find.text('195 kcal / 2000 kcal'), findsOneWidget);
      expect(targets.readCalls, 2);
    },
  );

  testWidgets('U1 empty day and unconfigured targets stay explicit', (
    tester,
  ) async {
    await hostOverview(
      tester,
      const AsyncData([]),
      FakeNutritionTargetRepository(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa ghi bữa ăn'), findsOneWidget);
    expect(find.text('Chưa đặt mục tiêu'), findsOneWidget);
    expect(find.text('0 kcal / — kcal'), findsOneWidget);
    expect(find.textContaining('Còn '), findsNothing);
  });

  testWidgets(
    'U1 zero macros retain excess and details close when UID changes',
    (tester) async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final targets = FakeNutritionTargetRepository()
        ..byUid['test-uid'] = {
          '2026-10-18': const NutritionTarget(
            effectiveFromDateKey: '2026-10-18',
            kcalTarget: 100,
            proteinGTarget: 0,
            carbsGTarget: 0,
            fatGTarget: 0,
          ),
        };
      await hostOverview(
        tester,
        AsyncData([meals.meal('a', date: uxToday)]),
        targets,
        auth: auth,
      );
      await tester.pumpAndSettle();
      expect(find.text('195 kcal / 100 kcal'), findsOneWidget);
      expect(find.text('Vượt 95 kcal'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('journal-nutrition-details')));
      await tester.pumpAndSettle();
      expect(find.text('Vượt 4 g'), findsOneWidget);
      expect(find.text('Vượt 42,3 g'), findsOneWidget);
      expect(find.text('Vượt 0,4 g'), findsOneWidget);
      expect(find.textContaining('NaN'), findsNothing);
      expect(find.textContaining('Infinity'), findsNothing);
      auth.emitUser(
        const AuthUser(
          emailVerified: true,
          uid: 'other',
          email: 'b@example.com',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết dinh dưỡng'), findsNothing);
    },
  );

  testWidgets('U1 failed weekly logs do not start an additional target query', (
    tester,
  ) async {
    final targets = uxTargets();
    final container = await pumpApp(
      tester,
      dashboardNow: uxToday,
      targetRepository: targets,
      nutritionRepository: FakeNutritionRepository()
        ..rangeError = StateError('unavailable'),
    );
    container.read(appRouterProvider).go(AppRoutes.progress);
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa tải đủ dữ liệu tuần'), findsOneWidget);
    expect(targets.rangeCalls, 0);
    expect(find.byKey(const ValueKey('weekly-chart')), findsNothing);
  });

  for (final size in [const Size(360, 800), const Size(412, 915)]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets(
          'U1 diary/progress/keyboard $size scale$scale ${mode.name}',
          (tester) async {
            final container = await pumpApp(
              tester,
              size: size,
              textScale: scale,
              initialThemeMode: mode,
              dashboardNow: uxToday,
              targetRepository: uxTargets(),
              nutritionRepository: FakeNutritionRepository(
                meals: [meals.meal('a', date: uxToday)],
              ),
            );
            container.read(journalDateProvider.notifier).select(uxToday);
            container.read(appRouterProvider).go(AppRoutes.journal);
            await tester.pumpAndSettle();
            final add = find.byKey(const ValueKey('add-meal-breakfast'));
            await tester.ensureVisible(add);
            await tester.pumpAndSettle();
            await tester.tap(add);
            await tester.pumpAndSettle();
            tester.view.viewInsets = const FakeViewPadding(bottom: 260);
            await tester.pumpAndSettle();
            final save = find.byKey(const ValueKey('save-meal'));
            final rect = tester.getRect(save);
            expect(rect.bottom, lessThanOrEqualTo(size.height - 260));
            expect(save.hitTestable(), findsOneWidget);
            expect(find.textContaining('Còn -'), findsNothing);
            tester.view.resetViewInsets();
            Navigator.of(tester.element(find.byType(MealFormDialog))).pop();
            await tester.pumpAndSettle();
            container.read(appRouterProvider).go(AppRoutes.progress);
            await tester.pumpAndSettle();
            final chart = find.byKey(const ValueKey('weekly-chart'));
            await tester.ensureVisible(chart);
            await tester.pumpAndSettle();
            expect(chart, findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
