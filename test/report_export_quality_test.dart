import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:healthmate/features/data_export/data/journal_export_service.dart';
import 'package:healthmate/features/data_export/models/journal_csv.dart';
import 'package:healthmate/features/data_export/presentation/journal_export_dialog.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'package:healthmate/features/water/models/water_log.dart';

import 'support/fake_activity_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_private_local_data.dart';
import 'support/fake_water_repository.dart';

List<Map<String, String>> readSummary(String csv) {
  final rows = csv
      .replaceFirst('\uFEFF', '')
      .trim()
      .split('\r\n')
      .map(
        (line) => RegExp(
          r'"((?:[^"]|"")*)"(?:,|$)',
        ).allMatches(line).map((m) => m[1]!.replaceAll('""', '"')).toList(),
      )
      .toList();
  return [for (final row in rows.skip(1)) Map.fromIterables(rows.first, row)];
}

MealLog recordedMeal() => MealLog(
  id: 'meal',
  type: MealType.lunch,
  source: MealSource.manual,
  consumedAt: DateTime.utc(2024, 2, 28, 17),
  dateKey: '2024-02-29',
  timezoneOffsetMinutes: 420,
  totals: const NutritionTotals(
    kcal: 9999,
  ), // Use snapshots, never an old aggregate.
  items: const [
    MealItemSnapshot(
      foodId: 'a',
      name: 'Món A',
      grams: 100,
      nutrition: NutritionTotals(
        kcal: 100,
        proteinG: 2,
        fatG: 0,
        carbsKnown: false,
        fiberKnown: false,
      ),
      sourceLabel: 'Snapshot',
      isEstimated: true,
    ),
    MealItemSnapshot(
      foodId: 'b',
      name: 'Món B',
      grams: 50,
      nutrition: NutritionTotals(
        kcal: 50,
        proteinG: 1,
        proteinKnown: false,
        carbsKnown: false,
        fiberKnown: false,
      ),
      sourceLabel: 'Snapshot',
      isEstimated: false,
    ),
  ],
);

void main() {
  setUpAll(() => initializeDateFormatting('vi'));
  final start = DateTime(2024, 2, 28), end = DateTime(2024, 3, 2);
  test(
    'daily summary keeps leap day, historical day, snapshot totals and missing nutrients',
    () {
      final rows = readSummary(
        buildDailySummaryCsv(
          start: start,
          endExclusive: end,
          meals: [recordedMeal()],
          water: [
            WaterLog(
              id: 'w',
              amountMl: 250,
              consumedAt: DateTime.utc(2024, 2, 28, 17),
              dateKey: '2024-02-29',
              timezoneOffsetMinutes: 420,
            ),
          ],
        ),
      );
      expect(rows.map((r) => r['Ngày']), [
        '2024-02-28',
        '2024-02-29',
        '2024-03-01',
      ]);
      final day = rows[1];
      expect(day['Số bữa đã ghi'], '1');
      expect(day['Số món đã ghi'], '2');
      expect(day['kcal đã ghi'], '150.0');
      expect(day['Đạm đã ghi (g)'], '3.0');
      expect(day['Trạng thái đạm'], 'Thiếu dữ liệu một phần');
      expect(day['Carb đã ghi (g)'], '');
      expect(day['Trạng thái carb'], 'Chưa có dữ liệu');
      expect(day['Béo đã ghi (g)'], '0.0');
      expect(day['Trạng thái béo'], 'Đủ dữ liệu trong các món đã ghi');
      expect(day['Nước đã ghi (ml)'], '250');
      expect(day['Số món ước tính'], '1');
      expect(day['Đến hết ngày'], '2024-03-01');
      expect(day['Lưu ý'], contains('không xác nhận đầy đủ cả ngày'));
      expect(rows.first['Số bữa đã ghi'], '0');
      for (final field in [
        'kcal đã ghi',
        'Nước đã ghi (ml)',
        'Vận động đã ghi (phút)',
        'Đạm đã ghi (g)',
      ]) {
        expect(rows.first[field], '', reason: 'No log is not zero intake');
      }
      expect(rows.first['Tình trạng ghi nhận'], 'Chưa có nhật ký');
    },
  );

  test('latest weight respects microseconds instead of ISO text sorting', () {
    final at = DateTime(2024, 2, 29, 8);
    BodyMetric metric(String id, DateTime time, double weight) => BodyMetric(
      id: id,
      measuredAt: time,
      weightKg: weight,
      note: '',
      createdAt: time,
      updatedAt: time,
    );
    final rows = readSummary(
      buildDailySummaryCsv(
        start: start,
        endExclusive: end,
        weights: [
          metric('later', at.add(const Duration(microseconds: 1)), 71),
          metric('earlier', at, 70),
        ],
      ),
    );
    expect(rows[1]['Cân nặng gần nhất trong ngày (kg)'], '71.0');
    expect(rows[1]['Thời điểm cân (UTC)'], contains('000001Z'));
  });

  test(
    'both formats reject partial-day ranges, duplicate data and invalid snapshots',
    () {
      for (final build in [buildJournalCsv, buildDailySummaryCsv]) {
        expect(
          () => build(
            start: start.add(const Duration(hours: 12)),
            endExclusive: end,
          ),
          throwsFormatException,
        );
        expect(
          () => build(
            start: start,
            endExclusive: end,
            meals: [recordedMeal(), recordedMeal()],
          ),
          throwsFormatException,
        );
        expect(
          () => build(start: start, endExclusive: DateTime(2025, 3, 2)),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'summary export retains verified native writing and ordered progress stages',
    () async {
      final local = FakePrivateLocalData(), stages = <JournalExportStage>[];
      final nutrition = FakeNutritionRepository(),
          water = FakeWaterRepository();
      final activity = FakeActivityRepository(),
          profile = FakeHealthProfileRepository();
      addTearDown(nutrition.dispose);
      addTearDown(water.dispose);
      addTearDown(activity.dispose);
      addTearDown(profile.dispose);
      final service = JournalExportService(
        local: local,
        nutrition: nutrition,
        water: water,
        activity: activity,
        profile: profile,
        currentUid: () => 'owner',
      );
      expect(
        await service.export(
          start,
          end,
          format: JournalExportFormat.dailySummary,
          onStage: stages.add,
        ),
        greaterThan(0),
      );
      expect(stages, JournalExportStage.values);
      expect(readSummary(utf8.decode(local.csv!)), hasLength(3));
      expect(local.written, 1);
    },
  );

  testWidgets('format selection is usable at 320px and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const JournalExportDialog(),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('export-format')),
      180,
    );
    await tester.tap(find.byKey(const ValueKey('export-format')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tổng hợp theo ngày').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Mỗi ngày một dòng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
