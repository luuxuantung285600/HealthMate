import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/progress/presentation/progress_overview.dart';
import 'package:healthmate/features/profile/presentation/weight_chart.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';

import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'support/test_app.dart';
import 'support/fake_health_profile_repository.dart';

void main() {
  for (final width in [320.0, 390.0, 412.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final brightness in Brightness.values) {
        testWidgets('sparse chart $width scale$scale $brightness', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          final dates = [
            DateTime(2026, 10, 26),
            DateTime(2026, 10, 27),
            DateTime(2026, 10, 28),
          ];
          await tester.pumpWidget(
            MaterialApp(
              theme: brightness == Brightness.light
                  ? AppTheme.light
                  : AppTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      RecordedTrendCard(
                        title: 'Năng lượng',
                        unit: 'kcal',
                        color: Colors.blue,
                        points: [
                          (date: dates[0], value: 0),
                          (date: dates[1], value: null),
                          (date: dates[2], value: 600),
                        ],
                      ),
                      WeightChart(
                        metrics: [
                          for (final entry in [dates[0], dates[2]].indexed)
                            BodyMetric(
                              id: '${entry.$1}',
                              weightKg: 70 - entry.$1.toDouble(),
                              measuredAt: entry.$2,
                              note: '',
                              createdAt: entry.$2,
                              updatedAt: entry.$2,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('300 kcal / ngày có dữ liệu'), findsOneWidget);
          expect(find.text('2 / 3 ngày có dữ liệu'), findsOneWidget);
          expect(
            find.bySemanticsLabel(
              RegExp(
                'Năng lượng, đơn vị kcal.*26/10: 0 kcal.*27/10: chưa ghi.*28/10: 600 kcal',
              ),
            ),
            findsOneWidget,
          );
          final chart = tester.widget<LineChart>(
            find.byKey(const ValueKey('weekly-chart')),
          );
          expect(chart.data.lineBarsData.single.spots[0].y, 0);
          expect(chart.data.lineBarsData.single.spots[1].isNull(), isTrue);
          expect(
            chart.data.titlesData.leftTitles.sideTitles.showTitles,
            isTrue,
          );
          expect(chart.data.lineTouchData.enabled, isTrue);
          await tester.ensureVisible(
            find.byKey(const ValueKey('weight-chart')),
          );
          await tester.pumpAndSettle();
          final weights = tester
              .widgetList<LineChart>(find.byType(LineChart))
              .last;
          expect(weights.data.lineBarsData.single.spots.last.x, 2);
          expect(weights.data.lineTouchData.enabled, isTrue);
          expect(tester.takeException(), isNull);
          semantics.dispose();
        });
      }
    }
  }
  for (final width in [320.0, 390.0, 412.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets('profile access and weight actions $width $scale $mode', (
          tester,
        ) async {
          final day = DateTime(2026, 10, 28);
          final container = await pumpApp(
            tester,
            size: Size(width, 844),
            textScale: scale,
            initialThemeMode: mode,
            dashboardNow: day,
            profileRepository: FakeHealthProfileRepository(
              profile: FakeHealthProfileRepository.testProfile,
              metrics: [
                BodyMetric(
                  id: 'first',
                  weightKg: 70,
                  measuredAt: day,
                  note: 'Ghi chú cân nặng được phép xuống dòng',
                  createdAt: day,
                  updatedAt: day,
                ),
              ],
            ),
          );
          container.read(appRouterProvider).go(AppRoutes.profile);
          await tester.pumpAndSettle();
          expect(find.text('Nhìn lại hôm nay'), findsNothing);
          for (final key in [
            'edit-profile',
            'open-support',
            'open-goals-quests',
            'open-privacy',
            'change-password',
            'add-metric',
            'edit-metric-first',
            'weight-history-older',
            'open-journal-export',
          ]) {
            await tester.ensureVisible(find.byKey(ValueKey(key)));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  }
}
