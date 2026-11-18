import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/data_export/presentation/journal_export_dialog.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/reports/presentation/period_report_panel.dart';
import 'support/load_icon_font.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/fake_activity_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/test_app.dart';
import 'weekly_reflection_test.dart' as f show meal, water, activity, weight;

final _monday = DateTime(2026, 12, 28), _before = DateTime(2026, 12, 21);
final _today = DateTime(2027, 1, 1, 12);

class _ScopedMeals extends FakeNutritionRepository {
  _ScopedMeals({super.meals});
  final starts = <DateTime>[];
  Completer<void>? beforePending;
  bool beforeFails = false;
  @override
  Future<List<MealLog>> loadRange(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    starts.add(start);
    if (start == _before) {
      await beforePending?.future;
      if (beforeFails) throw StateError('internal-private-error');
    }
    return super.loadRange(uid, start, end);
  }
}

Future<void> _tap(WidgetTester tester, String key, {bool settle = true}) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(target);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _progress(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('nav-progress')));
  await tester.pumpAndSettle();
}

Future<void> _closeExport(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(JournalExportDialog))).pop();
  await tester.pumpAndSettle();
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
    'comparison loads previous week only when opened and shares current results',
    (tester) async {
      final n = _ScopedMeals(
        meals: [f.meal('now', _monday, 100), f.meal('before', _before, 200)],
      );
      final water = FakeWaterRepository(
        logs: [f.water('now', _monday, 500), f.water('before', _before, 250)],
      );
      await pumpApp(
        tester,
        dashboardNow: _today,
        nutritionRepository: n,
        waterRepository: water,
        activityRepository: FakeActivityRepository(
          logs: [
            f.activity('now', _monday, 20),
            f.activity('before', _before, 10),
          ],
        ),
        profileRepository: FakeHealthProfileRepository(
          profile: FakeHealthProfileRepository.testProfile,
          metrics: [
            f.weight('now', _monday, 61),
            f.weight('before', _before, 62),
          ],
        ),
      );
      await _progress(tester);
      expect(n.starts, [_monday]);
      expect(
        find.byKey(const ValueKey('week-comparison-difference-energy')),
        findsNothing,
      );
      await _tap(tester, 'toggle-week-comparison');
      expect(n.starts, [_monday, _before]);
      expect(water.rangeCalls, 2);
      for (final (kind, difference) in [
        ('energy', '-100 kcal'),
        ('weight', '-1 kg'),
        ('water', '+250 ml'),
        ('activity', '+10 phút'),
      ]) {
        final delta = find.byKey(ValueKey('week-comparison-difference-$kind'));
        await tester.ensureVisible(delta);
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(delta).data, 'Chênh lệch: $difference');
      }
      expect(find.text('Đang xem: 28/12/2026 – 01/01/2027'), findsOneWidget);
      expect(find.text('Tuần trước: 21/12/2026 – 25/12/2026'), findsOneWidget);
      await _tap(tester, 'toggle-week-comparison');
      expect(
        find.byKey(const ValueKey('week-comparison-difference-energy')),
        findsNothing,
      );
      expect(n.starts.length, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'previous week loading/error never becomes a zero difference and retry preserves current week',
    (tester) async {
      final gate = Completer<void>();
      final n = _ScopedMeals(
        meals: [f.meal('now', _monday, 100), f.meal('before', _before, 200)],
      )..beforePending = gate;
      await pumpApp(tester, dashboardNow: _today, nutritionRepository: n);
      await _progress(tester);
      await _tap(tester, 'toggle-week-comparison', settle: false);
      expect(find.text('Đang tải dữ liệu đối chiếu…'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('week-comparison-difference-energy')),
        findsNothing,
      );
      n.beforeFails = true;
      gate.complete();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Chưa tải đủ dữ liệu hai tuần'),
        findsOneWidget,
      );
      expect(find.textContaining('internal-private-error'), findsNothing);
      expect(find.byKey(const ValueKey('weekly-chart')), findsOneWidget);
      n.beforeFails = false;
      await _tap(tester, 'retry-week-comparison');
      expect(n.starts.where((s) => s == _monday).length, 1);
      expect(n.starts.where((s) => s == _before).length, 2);
      expect(
        find.byKey(const ValueKey('week-comparison-difference-energy')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rapid week navigation cannot display late results for a different week',
    (tester) async {
      final gate = Completer<void>();
      final n = _ScopedMeals(
        meals: [
          f.meal('initial', _monday, 100),
          f.meal('late', _before, 200),
          f.meal('selected', DateTime(2026, 12, 14), 2000),
          f.meal('previous', DateTime(2026, 12, 7), 1000),
        ],
      )..beforePending = gate;
      await pumpApp(tester, dashboardNow: _today, nutritionRepository: n);
      await _progress(tester);
      await _tap(tester, 'toggle-week-comparison', settle: false);
      await _tap(tester, 'previous-week', settle: false);
      await _tap(tester, 'previous-week');
      expect(find.text('Đang xem: 14/12/2026 – 20/12/2026'), findsOneWidget);
      expect(find.text('Chênh lệch: +1.000 kcal'), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Chênh lệch: +1.000 kcal'), findsOneWidget);
      expect(find.text('Chênh lệch: -100 kcal'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pending comparison disappears on logout', (tester) async {
    final gate = Completer<void>(),
        auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
    final n = _ScopedMeals()..beforePending = gate;
    await pumpApp(
      tester,
      dashboardNow: _today,
      nutritionRepository: n,
      repository: auth,
    );
    await _progress(tester);
    await _tap(tester, 'toggle-week-comparison', settle: false);
    auth.emitUser(null);
    await tester.pump();
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('week-comparison-card')), findsNothing);
    expect(find.byKey(const ValueKey('progress-screen')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'export follows current partial week, old overview and detailed week navigation',
    (tester) async {
      await pumpApp(tester, dashboardNow: _today);
      await _progress(tester);
      await _tap(tester, 'progress-export');
      var range = tester
          .widget<JournalExportDialog>(find.byType(JournalExportDialog))
          .initialRange!;
      expect(range.start, _monday);
      expect(range.lastDay, DateTime(2027, 1, 1));
      await _closeExport(tester);
      await _tap(tester, 'previous-week');
      await _tap(tester, 'progress-export');
      range = tester
          .widget<JournalExportDialog>(find.byType(JournalExportDialog))
          .initialRange!;
      expect(range.start, _before);
      expect(range.lastDay, DateTime(2026, 12, 27));
      await _closeExport(tester);
      await _tap(tester, 'progress-details');
      await _tap(tester, 'previous-week');
      await _tap(tester, 'progress-export');
      range = tester
          .widget<JournalExportDialog>(find.byType(JournalExportDialog))
          .initialRange!;
      expect(range.start, DateTime(2026, 12, 14));
      expect(range.lastDay, DateTime(2026, 12, 20));
      await _closeExport(tester);
      await _tap(tester, 'progress-details');
      expect(find.text('14/12/2026 – 20/12/2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'export follows rolling period navigation and resets on a different window',
    (tester) async {
      await pumpApp(tester, dashboardNow: _today);
      await _progress(tester);
      await _tap(tester, 'report-window-30');
      await _tap(tester, 'previous-period');
      await _tap(tester, 'progress-export');
      var range = tester
          .widget<JournalExportDialog>(find.byType(JournalExportDialog))
          .initialRange!;
      expect(range.days, 30);
      expect(range.end, DateTime(2026, 12, 3));
      await _closeExport(tester);
      await tester.tap(find.byKey(const ValueKey('nav-dashboard')));
      await tester.pumpAndSettle();
      await _progress(tester);
      final panel = find.byType(PeriodReportPanel);
      expect(
        find.descendant(
          of: panel,
          matching: find.text('03/11/2026 – 02/12/2026'),
        ),
        findsOneWidget,
      );
      await _tap(tester, 'progress-export');
      range = tester
          .widget<JournalExportDialog>(find.byType(JournalExportDialog))
          .initialRange!;
      expect(range.end, DateTime(2026, 12, 3));
      await _closeExport(tester);
      await _tap(tester, 'report-window-90');
      await _tap(tester, 'progress-export');
      range = tester
          .widget<JournalExportDialog>(find.byType(JournalExportDialog))
          .initialRange!;
      expect(range.days, 90);
      expect(range.end, DateTime(2027, 1, 2));
      await _closeExport(tester);
      await _tap(tester, 'report-window-year');
      await _tap(tester, 'previous-report-year');
      await _tap(tester, 'progress-export');
      range = tester
          .widget<JournalExportDialog>(find.byType(JournalExportDialog))
          .initialRange!;
      expect(range.start, DateTime(2026));
      expect(range.end, DateTime(2027));
      expect(tester.takeException(), isNull);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final (width, scale) in [(320.0, 2.0), (390.0, 1.0)]) {
      testWidgets('comparison layout $mode width=$width scale=$scale', (
        tester,
      ) async {
        final key = GlobalKey();
        await pumpApp(
          tester,
          dashboardNow: _today,
          size: Size(width, 844),
          textScale: scale,
          initialThemeMode: mode,
          captureKey: key,
          nutritionRepository: _ScopedMeals(
            meals: [
              f.meal('current', _monday, 1234),
              f.meal('previous', _before, 1000),
            ],
          ),
        );
        await _progress(tester);
        await _tap(tester, 'toggle-week-comparison');
        final delta = find.byKey(
          const ValueKey('week-comparison-difference-energy'),
        );
        await tester.ensureVisible(delta);
        await tester.pumpAndSettle();
        if (width == 390) {
          await Scrollable.ensureVisible(
            tester.element(
              find.byKey(const ValueKey('toggle-week-comparison')),
            ),
            alignment: 0,
          );
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final shot = await boundary.toImage(pixelRatio: 2);
            final bytes = await shot.toByteData(format: ui.ImageByteFormat.png);
            shot.dispose();
            final target = File(
              'build/progress-comparison-20261116/${mode.name}-comparison.png',
            );
            await target.parent.create(recursive: true);
            await target.writeAsBytes(bytes!.buffer.asUint8List());
          });
        }
        expect(find.text('Chênh lệch: +234 kcal'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
