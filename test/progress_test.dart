import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/router/auth_redirect.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/profile/models/profile_failure.dart';
import 'package:healthmate/features/profile/presentation/weight_chart.dart';
import 'package:healthmate/features/weekly_reflection/providers/weekly_reflection_providers.dart';
import 'package:healthmate/features/weekly_reflection/models/weekly_reflection.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_nutrition_target_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/fake_activity_repository.dart';
import 'support/test_app.dart';
import 'weekly_reflection_test.dart'
    as fixtures
    show meal, water, activity, weight;
import 'nutrition_targets_test.dart' show profileForUid;

final monday = DateTime(2026, 12, 28);
final today = DateTime(2027, 1, 1, 12);

Future<void> tapVisible(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  for (var frame = 0; frame < 3; frame++) {
    await tester.pump();
    await Scrollable.ensureVisible(tester.element(finder), alignment: .3);
    await tester.pump();
  }
  await tester.tap(finder);
}

// Historical per-day targets remain available from the new report details action.
Future<void> openProgress(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('nav-progress')));
  await tester.pumpAndSettle();
  await tapVisible(tester, 'progress-details');
  await tester.pumpAndSettle();
}

Future<void> openDailyDetails(WidgetTester tester) async {
  final tile = find.byType(ExpansionTile).first;
  await Scrollable.ensureVisible(tester.element(tile), alignment: .2);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Chi tiết từng ngày / Mục tiêu'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final fonts = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(
        rootBundle.load('assets/fonts/be_vietnam_pro/BeVietnamPro-$weight.ttf'),
      );
    }
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  test(
    'calendar year boundary, recorded zero, missing and future use different denominators',
    () {
      final reflection = summarizeWeek(
        weekStart(today),
        today,
        WeekLogs(
          meals: [
            fixtures.meal('zero', monday, 0),
            fixtures.meal('new-year', today, 600),
            fixtures.meal('future', DateTime(2027, 1, 2), 999),
          ],
          water: [],
          activities: [],
          loadedAt: today,
        ),
      );
      expect(weekStart(today), monday);
      expect(reflection.days.last.date, DateTime(2027, 1, 3));
      expect(reflection.eligibleDays, 5);
      expect(reflection.mealDays, 2);
      expect(reflection.nutrition.kcal, 600);
      expect(reflection.averageKcalPerRecordedDay, 300);
      expect(reflection.days[1].mealCount, 0);
      expect(reflection.days[5].isFuture, isTrue);
    },
  );

  testWidgets(
    'Progress uses real weekly sources and historical targets without per-day queries or listeners',
    (tester) async {
      final n = FakeNutritionRepository(
        meals: [
          fixtures.meal('zero', monday, 0),
          fixtures.meal('new-year', today, 600),
        ],
      );
      final w = FakeWaterRepository(logs: [fixtures.water('w', monday, 750)]);
      final a = FakeActivityRepository(
        logs: [fixtures.activity('a', today, 25)],
      );
      final p = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
        metrics: [
          fixtures.weight('end', today, 69.5),
          fixtures.weight('begin', monday, 70),
        ],
      );
      final t = FakeNutritionTargetRepository()
        ..byUid['test-uid'] = {
          '2026-12-29': const NutritionTarget(
            effectiveFromDateKey: '2026-12-29',
            kcalTarget: 1800,
          ),
          '2027-01-01': const NutritionTarget(
            effectiveFromDateKey: '2027-01-01',
            kcalTarget: 2100,
            proteinGTarget: 100,
            carbsGTarget: 250,
            fatGTarget: 60,
          ),
          '2027-01-04': const NutritionTarget(
            effectiveFromDateKey: '2027-01-04',
            kcalTarget: 9999,
          ),
        };
      final container = await pumpApp(
        tester,
        dashboardNow: today,
        nutritionRepository: n,
        waterRepository: w,
        activityRepository: a,
        profileRepository: p,
        targetRepository: t,
      );
      expect(n.rangeCalls, 0);
      await openProgress(tester);
      if (find.text('Trở về biểu đồ').evaluate().isEmpty) {
        await tapVisible(tester, 'progress-details');
        await tester.pump();
        await tester.pump();
      }
      expect(find.text('600 kcal đã ghi'), findsOneWidget);
      expect(find.text('Đạm 60 g · Tinh bột 120 g · Béo 30 g'), findsOneWidget);
      expect(
        find.textContaining('Nước: 750 ml · Vận động: 25 phút'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Trung bình trên 2 ngày có ghi bữa: 300 kcal/ngày'),
        findsOneWidget,
      );
      await openDailyDetails(tester);
      expect(find.text('Chưa đặt mục tiêu cho ngày này.'), findsOneWidget);
      expect(
        find.text('Mục tiêu: 1800 kcal · Chưa đặt macro'),
        findsNWidgets(3),
      );
      expect(
        find.textContaining('Mục tiêu: 2100 kcal · Đạm 100 g'),
        findsNWidgets(3),
      );
      expect(find.textContaining('Mục tiêu: 9999'), findsNothing);
      expect(
        find.textContaining('Chưa tới ngày · không tính'),
        findsNWidgets(2),
      );
      expect(
        find.textContaining('Chênh lệch lần cuối so với lần đầu: -0,5 kg'),
        findsOneWidget,
      );
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData.single.spots.map((s) => s.y), [70, 69.5]);
      expect(chart.data.lineBarsData.single.spots.last.x, 4.5);
      expect(n.rangeCalls, 1);
      expect(w.rangeCalls, 1);
      expect(a.rangeCalls, 1);
      expect(p.metricRangeCalls, 1);
      expect(t.rangeCalls, 1);
      expect(n.activeDayListeners, 0);
      expect(w.activeDayListeners, 0);
      expect(a.activeDayListeners, 0);
      expect(p.latestMetricListeners, 0);
      expect(p.fullMetricWatchCalls, 0);
      // Rebuilds and a second consumer share this UID/week rather than requery.
      final sub = container.listen(weeklyLogsProvider(monday), (_, _) {});
      await tester.pump();
      expect(n.rangeCalls, 1);
      sub.close();
      await openProfileFromShell(tester);
      await tester.pumpAndSettle();
      expect(find.text('Không gian cá nhân'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-dashboard')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-journal')));
      await tester.pumpAndSettle();
      expect(n.activeDayListeners, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty week plus one weight does not invent intake or a trend', (
    tester,
  ) async {
    await pumpApp(
      tester,
      dashboardNow: today,
      profileRepository: FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
        metrics: [fixtures.weight('one', today, 70)],
      ),
    );
    await openProgress(tester);
    expect(
      find.textContaining('Chưa có nhật ký bữa ăn, nước hoặc vận động'),
      findsOneWidget,
    );
    expect(find.textContaining('Mới có một lần cân; chưa đủ'), findsOneWidget);
    expect(find.textContaining('Trung bình trên'), findsNothing);
    expect(find.textContaining('Chênh lệch lần cuối'), findsNothing);
    await openDailyDetails(tester);
    expect(find.text('Chưa đặt mục tiêu cho ngày này.'), findsNWidgets(7));
  });

  testWidgets(
    'target loading/error never hides verified logs and retry does not reload logs',
    (tester) async {
      final gate = Completer<void>();
      final t = FakeNutritionTargetRepository()..pendingRead = gate;
      final n = FakeNutritionRepository(
        meals: [fixtures.meal('m', monday, 600)],
      );
      await pumpApp(
        tester,
        dashboardNow: today,
        targetRepository: t,
        nutritionRepository: n,
        settle: false,
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('nav-progress')));
      await tester.pump();
      await tester.pump();
      if (find.text('Trở về biểu đồ').evaluate().isEmpty) {
        await tapVisible(tester, 'progress-details');
        await tester.pump();
        await tester.pump();
      }
      expect(find.text('600 kcal đã ghi'), findsOneWidget);
      expect(find.text('Chưa đặt mục tiêu cho ngày này.'), findsNothing);
      t.failRead = true;
      gate.complete();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Chưa tải được mục tiêu tuần.'),
        findsOneWidget,
      );
      if (find.text('Trở về biểu đồ').evaluate().isEmpty) {
        await tapVisible(tester, 'progress-details');
        await tester.pump();
        await tester.pump();
      }
      expect(find.text('600 kcal đã ghi'), findsOneWidget);
      t.failRead = false;
      await tapVisible(tester, 'retry-week-targets');
      await tester.pumpAndSettle();
      await openDailyDetails(tester);
      expect(find.text('Chưa đặt mục tiêu cho ngày này.'), findsNWidgets(7));
      expect(t.rangeCalls, 2);
      expect(n.rangeCalls, 1);
    },
  );

  testWidgets(
    'log errors cannot masquerade as zero or empty; retry loads the same week',
    (tester) async {
      final n = FakeNutritionRepository()
        ..rangeError = StateError('private-error');
      await pumpApp(tester, dashboardNow: today, nutritionRepository: n);
      await openProgress(tester);
      expect(find.textContaining('Chưa tải đủ dữ liệu tuần'), findsOneWidget);
      expect(find.textContaining('private-error'), findsNothing);
      expect(find.textContaining('Chưa có nhật ký bữa ăn'), findsNothing);
      expect(find.byKey(const ValueKey('weekly-chart')), findsNothing);
      n.rangeError = null;
      await tapVisible(tester, 'retry-week');
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa có nhật ký bữa ăn'), findsOneWidget);
      expect(n.rangeCalls, 2);
    },
  );

  testWidgets(
    'rapid week changes while reads are pending discard old results',
    (tester) async {
      final gate = Completer<void>();
      final n = FakeNutritionRepository(
        meals: [fixtures.meal('m', monday, 600)],
      )..rangePending = gate;
      await pumpApp(tester, dashboardNow: today, nutritionRepository: n);
      await tester.tap(find.byKey(const ValueKey('nav-progress')));
      await tester.pump();
      await tapVisible(tester, 'previous-week');
      await tester.pump();
      await tapVisible(tester, 'previous-week');
      await tester.pump();
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('14/12/2026 – 20/12/2026'), findsOneWidget);
      expect(find.text('600 kcal đã ghi'), findsNothing);
      expect(n.rangeCalls, 3);
      await openProfileFromShell(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-progress')));
      await tester.pumpAndSettle();
      expect(find.text('14/12/2026 – 20/12/2026'), findsOneWidget);
      await tapVisible(tester, 'next-week');
      await tester.pumpAndSettle();
      await tapVisible(tester, 'next-week');
      await tester.pumpAndSettle();
      final next = tester.widget<IconButton>(
        find.byKey(const ValueKey('next-week')),
      );
      expect(next.onPressed, isNull);
    },
  );

  testWidgets('pending targets from UID A cannot populate UID B', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
    final profile = FakeHealthProfileRepository(
      profile: FakeHealthProfileRepository.testProfile,
    );
    final gate = Completer<void>();
    final t = FakeNutritionTargetRepository()
      ..pendingRead = gate
      ..byUid['test-uid'] = {
        '2026-01-01': const NutritionTarget(
          effectiveFromDateKey: '2026-01-01',
          kcalTarget: 7777,
        ),
      };
    final container = await pumpApp(
      tester,
      dashboardNow: today,
      targetRepository: t,
      repository: auth,
      profileRepository: profile,
      settle: false,
    );
    await tester.pump();
    await tester.pump();
    container.read(appRouterProvider).go(AppRoutes.progress);
    await tester.pump();
    await tapVisible(tester, 'progress-details');
    await tester.pump();
    await tester.pump();
    await tester.pump();
    auth.emitUser(
      const AuthUser(
        emailVerified: true,
        uid: 'user-b',
        email: 'b@example.com',
      ),
    );
    profile.emitProfile(profileForUid('user-b'));
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('7777'), findsNothing);
    if (find.text('Trở về biểu đồ').evaluate().isEmpty) {
      await tapVisible(tester, 'progress-details');
      await tester.pumpAndSettle();
    }
    await openDailyDetails(tester);
    expect(find.text('Chưa đặt mục tiêu cho ngày này.'), findsNWidgets(7));
    expect(tester.takeException(), isNull);
  });

  test('Progress auth destination survives sign-in and session gates', () {
    expect(
      authRedirect(const AsyncData(null), Uri.parse('/progress')),
      '/auth?from=%2Fprogress',
    );
    expect(
      authRedirect(const AsyncLoading(), Uri.parse('/progress')),
      '/session?from=%2Fprogress',
    );
    expect(
      authRedirect(
        AsyncData(FakeAuthRepository.testUser),
        Uri.parse('/auth?from=%2Fprogress'),
        AsyncData(FakeHealthProfileRepository.testProfile),
      ),
      '/progress',
    );
  });

  testWidgets(
    'quick weight preserves failed draft, blocks duplicate pending writes, saves and refreshes progress',
    (tester) async {
      final p = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
      );
      await pumpApp(tester, dashboardNow: DateTime.now(), profileRepository: p);
      await openProgress(tester);
      await openProfileFromShell(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('add-metric')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-metric')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('metric-weight')),
        '71,5',
      );
      p.failure = const ProfileFailure('test-only');
      await tester.tap(find.byKey(const ValueKey('save-metric')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Thông tin vẫn được giữ'), findsOneWidget);
      expect(find.text('71,5'), findsOneWidget);
      p.failure = null;
      final gate = Completer<void>();
      p.pending = gate;
      await tester.tap(find.byKey(const ValueKey('save-metric')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('save-metric')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(p.addMetricCalls, 2);
      expect(p.metrics, isEmpty);
      gate.complete();
      await tester.pumpAndSettle();
      expect(p.metrics.single.weightKg, 71.5);
      expect(find.text('Thêm cân nặng'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('nav-progress')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Mới có một lần cân; chưa đủ'),
        findsOneWidget,
      );
      expect(p.metricRangeCalls, 2);
    },
  );

  testWidgets(
    'weekly timeout is an error rather than an empty week and refresh can recover',
    (tester) async {
      final gate = Completer<void>();
      final n = FakeNutritionRepository()..rangePending = gate;
      await pumpApp(tester, dashboardNow: today, nutritionRepository: n);
      await tester.tap(find.byKey(const ValueKey('nav-progress')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 16));
      expect(find.textContaining('Chưa tải đủ dữ liệu tuần'), findsOneWidget);
      expect(find.textContaining('Chưa có nhật ký bữa ăn'), findsNothing);
      gate.complete();
      await tester.pumpAndSettle();
      await tapVisible(tester, 'retry-progress-overview');
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa có nhật ký bữa ăn'), findsOneWidget);
    },
  );

  testWidgets(
    'pending quick weight draft is removed on account change without a success notification',
    (tester) async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final p = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
      );
      await pumpApp(tester, repository: auth, profileRepository: p);
      await openProfileFromShell(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('add-metric')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-metric')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('metric-weight')), '77');
      final gate = Completer<void>();
      p.pending = gate;
      await tester.tap(find.byKey(const ValueKey('save-metric')));
      await tester.pump();
      auth.emitUser(null);
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('metric-weight')), findsNothing);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Đã thêm lần đo.'), findsNothing);
      expect(find.byKey(const ValueKey('progress-screen')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [360.0, 390.0, 412.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets('Progress populated layout $width scale$scale $mode', (
          tester,
        ) async {
          final key = GlobalKey();
          final n = FakeNutritionRepository(
            meals: [fixtures.meal('m', today, 1234)],
          );
          final container = await pumpApp(
            tester,
            size: Size(width, 844),
            textScale: scale,
            initialThemeMode: mode,
            dashboardNow: today,
            captureKey: key,
            nutritionRepository: n,
            profileRepository: FakeHealthProfileRepository(
              profile: FakeHealthProfileRepository.testProfile,
              metrics: [
                fixtures.weight('a', monday, 71),
                fixtures.weight('b', today, 70),
              ],
            ),
          );
          container.read(appRouterProvider).go(AppRoutes.progress);
          await tester.pump();
          await tapVisible(tester, 'progress-details');
          await tester.pump();
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('progress-screen')), findsOneWidget);
          final push = container
              .read(appRouterProvider)
              .push<void>(AppRoutes.about);
          await tester.pumpAndSettle();
          container.read(appRouterProvider).pop();
          await tester.pumpAndSettle();
          await push;
          expect(find.byKey(const ValueKey('progress-screen')), findsOneWidget);
          final chart = find.byKey(const ValueKey('weekly-chart'));
          await Scrollable.ensureVisible(tester.element(chart), alignment: .2);
          await tester.pumpAndSettle();
          if (width == 390 && (scale == 1 || scale == 2)) {
            await tester.runAsync(() async {
              final boundary =
                  key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final picture = await boundary.toImage(pixelRatio: 1);
              final bytes = await picture.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                'build/c5-layout/progress-${mode.name}-$scale.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              picture.dispose();
            });
          }
          final weight = find.byType(WeightChart);
          await Scrollable.ensureVisible(tester.element(weight), alignment: .2);
          await tester.pumpAndSettle();
          await openProfileFromShell(tester);
          await tester.pumpAndSettle();
          expect(find.text('Không gian cá nhân'), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('nav-progress')));
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('progress-screen')), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
