import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/data/bounded_range.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/data_export/data/journal_export_service.dart';
import 'package:healthmate/features/data_export/models/journal_csv.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/reports/data/report_range_loader.dart';
import 'package:healthmate/features/reports/models/period_report.dart';
import 'package:healthmate/features/reports/providers/report_providers.dart';

import 'h5_period_report_test.dart' show meal;
import 'support/fake_activity_repository.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_day_review_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_nutrition_target_repository.dart';
import 'support/fake_private_local_data.dart';
import 'support/fake_water_repository.dart';
import 'support/test_app.dart';

final reportToday = DateTime(2026, 10, 27, 12);

class BoundedYearMeals extends FakeNutritionRepository {
  BoundedYearMeals({super.meals});
  final calls = <(String, DateTime, DateTime)>[];
  int? failOnCall;
  Completer<void>? hold;
  @override
  Future<List<MealLog>> loadRange(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    calendarRangeDays(
      start,
      end,
    ); // Same public repository contract as Firebase.
    calls.add((uid, start, end));
    await hold?.future;
    if (failOnCall == calls.length) throw StateError('QA later slice offline');
    if (uid == 'b') return [];
    return super.loadRange(uid, start, end);
  }
}

Future<void> tapReport(WidgetTester t, String key) async {
  final finder = find.byKey(ValueKey(key));
  if (finder.evaluate().isEmpty) {
    await t.scrollUntilVisible(
      finder,
      250,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
      maxScrolls: 35,
    );
  }
  await t.ensureVisible(finder);
  await t.pumpAndSettle();
  await t.tap(finder);
  await t.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/inter/Inter-$weight.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  test(
    'calendar years include leap days and current year only through today',
    () {
      final leap = ReportRange.year(2024, reportToday);
      expect(leap.days, 366);
      expect(leap.start, DateTime(2024));
      expect(leap.lastDay, DateTime(2024, 12, 31));
      expect(ReportRange.year(2025, reportToday).days, 365);
      final current = ReportRange.year(2026, reportToday);
      expect(current.start, DateTime(2026));
      expect(current.lastDay, DateTime(2026, 10, 27));
      expect(current.days, 300);
      expect(
        () => ReportRange.year(2027, reportToday),
        throwsA(isA<RangeReadFailure>()),
      );
      expect(
        () => ReportRange.year(1899, reportToday),
        throwsA(isA<RangeReadFailure>()),
      );
    },
  );

  test(
    'inclusive custom ranges handle one day, 366 days, leap and year boundaries',
    () {
      expect(
        ReportRange.inclusive(
          DateTime(2024, 2, 29),
          DateTime(2024, 2, 29),
        ).days,
        1,
      );
      final across = ReportRange.inclusive(
        DateTime(2023, 12, 31),
        DateTime(2024, 1, 2),
      );
      expect(across.days, 3);
      expect(across.end, DateTime(2024, 1, 3));
      expect(
        () => ReportRange.inclusive(DateTime(2024), DateTime(2025)),
        throwsA(isA<RangeReadFailure>()),
      );
      expect(
        () => ReportRange.inclusive(DateTime(2026, 2), DateTime(2026)),
        throwsA(isA<RangeReadFailure>()),
      );
      expect(
        () => ReportRange(DateTime(2026), 0).validate(),
        throwsA(isA<RangeReadFailure>()),
      );
    },
  );

  test(
    'annual slices cover every date exactly once and retain 90-day repository bounds',
    () {
      final range = ReportRange.year(2024, reportToday);
      final seen = <String>{};
      expect(range.chunks.map((c) => c.days), [90, 90, 90, 90, 6]);
      for (final chunk in range.chunks) {
        expect(calendarRangeDays(chunk.start, chunk.end), chunk.days);
        for (var i = 0; i < chunk.days; i++) {
          expect(
            seen.add(
              localDateKey(
                DateTime(
                  chunk.start.year,
                  chunk.start.month,
                  chunk.start.day + i,
                ),
              ),
            ),
            isTrue,
          );
        }
      }
      expect(seen.length, 366);
      expect(seen.contains('2024-02-29'), isTrue);
      expect(seen.first, '2024-01-01');
      expect(seen.last, '2024-12-31');
    },
  );

  test(
    'range loader deduplicates target versions and never returns truncated or partial totals',
    () async {
      var calls = 0;
      final range = ReportRange.year(2024, reportToday);
      final rows = await loadReportRange(range, (_) async {
        calls++;
        return ['same', '$calls'];
      }, keyOf: (s) => s);
      expect(calls, 5);
      expect(rows.where((r) => r == 'same').length, 1);
      calls = 0;
      await expectLater(
        loadReportRange(range, (_) async {
          calls++;
          if (calls == 3) throw StateError('offline');
          return ['$calls'];
        }, keyOf: (s) => s),
        throwsStateError,
      );
      expect(calls, 3);
      await expectLater(
        loadReportRange(
          range,
          (_) async => ['a', 'b'],
          keyOf: (s) => s,
          maxRecords: 1,
        ),
        throwsA(isA<RangeReadFailure>()),
      );
    },
  );

  test(
    'closing a range or changing account stops subsequent slice reads',
    () async {
      var open = true, calls = 0;
      await expectLater(
        loadReportRange(
          ReportRange.year(2024, reportToday),
          (_) async {
            calls++;
            open = false;
            return ['private'];
          },
          keyOf: (s) => s,
          isCurrent: () => open,
        ),
        throwsStateError,
      );
      expect(calls, 1);
    },
  );

  test(
    'annual provider owner switch discards old result and stops the next request',
    () async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final repo = BoundedYearMeals(meals: [meal('a', DateTime(2024, 2, 29))])
        ..hold = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          nutritionRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(repo.dispose);
      addTearDown(auth.dispose);
      final session = container.listen(authSessionProvider, (_, _) {});
      addTearDown(session.close);
      await container.read(authSessionProvider.future);
      final provider = periodMealsProvider(ReportRange.year(2024, reportToday));
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      await pumpEventQueue();
      expect(repo.calls.length, 1);
      auth.emitUser(
        const AuthUser(uid: 'b', emailVerified: true, email: 'b@example.com'),
      );
      await pumpEventQueue();
      repo.hold!.complete();
      await pumpEventQueue(times: 40);
      expect(repo.calls.where((c) => c.$1 == 'test-uid').length, 1);
      expect(container.read(provider).value, isEmpty);
    },
  );

  testWidgets(
    'year report keeps old records, leap day, monthly totals and dated targets',
    (t) async {
      final repo = BoundedYearMeals(
        meals: [
          meal('feb', DateTime(2024, 2, 29), kcal: 500),
          meal('dec', DateTime(2024, 12, 31), kcal: 700),
          meal('next', DateTime(2025, 1, 1), kcal: 900),
        ],
      );
      final reviews = FakeDayReviewRepository()
        ..byUid['test-uid'] = {
          '2024-02-29': DayReview(
            dateKey: '2024-02-29',
            complete: true,
            mealCount: 1,
            latestMealUpdate: DateTime(2024, 2, 29).toUtc(),
          ),
        };
      final targets = FakeNutritionTargetRepository()
        ..byUid['test-uid'] = {
          '2023-12-01': const NutritionTarget(
            effectiveFromDateKey: '2023-12-01',
            kcalTarget: 1800,
          ),
          '2024-06-01': const NutritionTarget(
            effectiveFromDateKey: '2024-06-01',
            kcalTarget: 2000,
          ),
        };
      final c = await pumpApp(
        t,
        dashboardNow: reportToday,
        nutritionRepository: repo,
        targetRepository: targets,
        dayReviewRepository: reviews,
      );
      c.read(appRouterProvider).go(AppRoutes.progress);
      await t.pumpAndSettle();
      await tapReport(t, 'report-window-year');
      await tapReport(t, 'previous-report-year');
      await tapReport(t, 'previous-report-year');
      expect(find.text('1200 kcal đã ghi'), findsOneWidget);
      expect(find.text('01/01/2024 – 31/12/2024'), findsOneWidget);
      expect(find.textContaining('366 ngày'), findsWidgets);
      expect(find.textContaining('2/366 ngày có ghi bữa'), findsOneWidget);
      final range = ReportRange.year(2024, reportToday);
      final versions = await c.read(periodTargetsProvider(range).future);
      expect(versions.length, 2);
      expect(targetForDate(versions, '2024-02-29')!.kcalTarget, 1800);
      expect(targetForDate(versions, '2024-12-31')!.kcalTarget, 2000);
      await tapReport(t, 'period-month-details');
      expect(find.textContaining('Tháng 02/2024 · 500'), findsOneWidget);
      expect(find.textContaining('Tháng 12/2024 · 700'), findsOneWidget);
      await tapReport(t, 'period-day-details');
      expect(find.text('Trang 1/12'), findsOneWidget);
      await tapReport(t, 'report-details-next');
      expect(find.text('Trang 2/12'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'custom day count validates, applies once and supports a one-day chart',
    (t) async {
      final repo = BoundedYearMeals(
        meals: [meal('today', DateTime(2026, 10, 27), kcal: 400)],
      );
      final c = await pumpApp(
        t,
        dashboardNow: reportToday,
        nutritionRepository: repo,
      );
      c.read(appRouterProvider).go(AppRoutes.progress);
      await t.pumpAndSettle();
      await tapReport(t, 'report-window-custom');
      final before = repo.calls.length;
      await tapReport(t, 'range-mode-days');
      await t.enterText(
        find.byKey(const ValueKey('report-custom-days')),
        '367',
      );
      await tapReport(t, 'report-custom-apply');
      expect(find.byKey(const ValueKey('report-custom-error')), findsOneWidget);
      expect(repo.calls.length, before);
      await t.enterText(
        find.byKey(const ValueKey('report-custom-days')),
        '123',
      );
      await tapReport(t, 'report-custom-apply');
      expect(find.textContaining('123 ngày ·'), findsOneWidget);
      expect(find.text('400 kcal đã ghi'), findsOneWidget);
      await tapReport(t, 'edit-custom-report');
      await tapReport(t, 'range-mode-days');
      await t.enterText(find.byKey(const ValueKey('report-custom-days')), '1');
      await tapReport(t, 'report-custom-apply');
      expect(find.text('27/10/2026 – 27/10/2026'), findsOneWidget);
      expect(find.text('400 kcal đã ghi'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'later slice failure hides incomplete kcal, retains independent sources, retries',
    (t) async {
      final repo = BoundedYearMeals(meals: [meal('jan', DateTime(2026, 1, 1))]);
      final c = await pumpApp(
        t,
        dashboardNow: reportToday,
        nutritionRepository: repo,
      );
      c.read(appRouterProvider).go(AppRoutes.progress);
      await t.pumpAndSettle();
      repo.failOnCall = repo.calls.length + 2;
      await tapReport(t, 'report-window-year');
      expect(find.byKey(const ValueKey('period-total-kcal')), findsNothing);
      expect(find.textContaining('Chưa tải được bữa ăn'), findsOneWidget);
      expect(find.textContaining('0 ml nước'), findsOneWidget);
      repo.failOnCall = null;
      await tapReport(t, 'refresh-period');
      expect(find.text('200 kcal đã ghi'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'custom calendar endpoints are inclusive and cancellation keeps the previous report',
    (t) async {
      final c = await pumpApp(t, dashboardNow: reportToday);
      c.read(appRouterProvider).go(AppRoutes.progress);
      await t.pumpAndSettle();
      await tapReport(t, 'report-window-custom');
      await tapReport(t, 'report-custom-start');
      final firstPicker = t.element(find.byType(DatePickerDialog));
      Navigator.of(firstPicker).pop(DateTime(2024, 12, 30));
      await t.pumpAndSettle();
      await tapReport(t, 'report-custom-end');
      final lastPicker = t.element(find.byType(DatePickerDialog));
      Navigator.of(lastPicker).pop(DateTime(2025, 1, 2));
      await t.pumpAndSettle();
      await tapReport(t, 'report-custom-apply');
      expect(find.text('30/12/2024 – 02/01/2025'), findsOneWidget);
      expect(find.textContaining('4 ngày ·'), findsOneWidget);
      await tapReport(t, 'edit-custom-report');
      Navigator.of(
        t.element(find.byKey(const ValueKey('report-custom-apply'))),
      ).pop();
      await t.pumpAndSettle();
      expect(find.text('30/12/2024 – 02/01/2025'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('export is prefilled with the selected annual report', (t) async {
    final c = await pumpApp(t, dashboardNow: reportToday);
    c.read(appRouterProvider).go(AppRoutes.progress);
    await t.pumpAndSettle();
    await tapReport(t, 'report-window-year');
    await tapReport(t, 'previous-report-year');
    await tapReport(t, 'previous-report-year');
    await tapReport(t, 'progress-export');
    expect(find.text('Từ 1/1/2024'), findsOneWidget);
    expect(find.text('Đến hết 31/12/2024'), findsOneWidget);
    expect(
      t
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('export-consent')),
          )
          .value,
      isFalse,
    );
    expect(t.takeException(), isNull);
  });

  test(
    'CSV includes full leap year with correct source snapshots and bounded reads',
    () async {
      final repo = BoundedYearMeals(
        meals: [
          MealLog(
            id: 'leap',
            type: MealType.lunch,
            consumedAt: DateTime(2024, 2, 29),
            dateKey: '2024-02-29',
            source: MealSource.manual,
            items: [
              MealItemSnapshot.fromCatalog(FakeNutritionRepository.rice, 100),
            ],
            totals: MealItemSnapshot.fromCatalog(
              FakeNutritionRepository.rice,
              100,
            ).nutrition,
          ),
        ],
      );
      addTearDown(repo.dispose);
      final local = FakePrivateLocalData();
      final service = JournalExportService(
        local: local,
        nutrition: repo,
        water: FakeWaterRepository(),
        activity: FakeActivityRepository(),
        profile: FakeHealthProfileRepository(),
        currentUid: () => 'test-uid',
      );
      expect(
        await service.export(DateTime(2024), DateTime(2025)),
        greaterThan(100),
      );
      expect(repo.calls.length, 5);
      final csv = utf8.decode(local.csv!);
      expect(csv, contains('2024-02-29'));
      expect(csv, contains('"2024-01-01","2025-01-01"'));
      expect(local.written, 1);
      expect(
        () => buildJournalCsv(
          start: DateTime(2024),
          endExclusive: DateTime(2025, 1, 2),
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'CSV never opens a destination or writes after a later range failure',
    () async {
      final repo = BoundedYearMeals()..failOnCall = 3;
      addTearDown(repo.dispose);
      final local = FakePrivateLocalData();
      final service = JournalExportService(
        local: local,
        nutrition: repo,
        water: FakeWaterRepository(),
        activity: FakeActivityRepository(),
        profile: FakeHealthProfileRepository(),
        currentUid: () => 'test-uid',
      );
      await expectLater(
        service.export(DateTime(2024), DateTime(2025)),
        throwsStateError,
      );
      expect(repo.calls.length, 3);
      expect(local.picked, 0);
      expect(local.written, 0);
    },
  );

  testWidgets(
    'annual and custom controls render at large text on small screens',
    (t) async {
      final capture = GlobalKey();
      final c = await pumpApp(
        t,
        dashboardNow: reportToday,
        size: const Size(360, 800),
        textScale: 1.5,
        captureKey: capture,
        nutritionRepository: BoundedYearMeals(
          meals: [meal('one', DateTime(2026, 1, 1), kcal: 500)],
        ),
      );
      c.read(appRouterProvider).go(AppRoutes.progress);
      await t.pumpAndSettle();
      await tapReport(t, 'report-window-year');
      expect(find.text('500 kcal đã ghi'), findsOneWidget);
      await t.runAsync(() async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final folder = Directory('build/year-report-ui');
        await folder.create(recursive: true);
        await File(
          '${folder.path}/year.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
      });
      await tapReport(t, 'report-window-custom');
      await tapReport(t, 'range-mode-days');
      await t.enterText(find.byKey(const ValueKey('report-custom-days')), '45');
      await tapReport(t, 'report-custom-apply');
      expect(find.textContaining('45 ngày ·'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
