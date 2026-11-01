import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../profile/presentation/weight_chart.dart';
import '../../weekly_reflection/models/weekly_reflection.dart';

typedef TrendPoint = ({DateTime date, double? value});

/// An absent observation stays distinct from an explicitly recorded zero.
class ProgressOverview extends StatelessWidget {
  const ProgressOverview({
    required this.reflection,
    required this.tab,
    this.controls,
    this.confirmedDays,
    super.key,
  });
  final WeeklyReflection reflection;
  final int tab;
  final Widget? controls;
  final int? confirmedDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget trend(
      String title,
      String unit,
      Color color,
      double? Function(DayReflection) get,
      String id,
    ) => RecordedTrendCard(
      key: ValueKey('progress-trend-$id'),
      title: title,
      unit: unit,
      color: color,
      points: [
        for (final day in reflection.days)
          (date: day.date, value: day.isFuture ? null : get(day)),
      ],
    );
    final cards = <Widget>[
      if (tab == 0 || tab == 1)
        trend(
          'Năng lượng',
          'kcal',
          theme.colorScheme.primary,
          (day) => day.mealCount > 0 ? day.nutrition.kcal : null,
          'kcal',
        ),
      if (tab == 0)
        AppCard(
          key: const ValueKey('progress-weight-overview'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cân nặng', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              if (reflection.metrics.isEmpty)
                const Text('Chưa có lần cân trong tuần này.')
              else ...[
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _WeightLabel('Đầu kỳ', reflection.metrics.first.weightKg),
                    _WeightLabel('Gần nhất', reflection.metrics.last.weightKg),
                    if (reflection.weightChange != null)
                      _WeightLabel('Thay đổi', reflection.weightChange!),
                  ],
                ),
                const SizedBox(height: 16),
                WeightChart(metrics: reflection.metrics.reversed.toList()),
                if (reflection.metrics.length == 1)
                  const Text('Một lần đo chưa đủ để mô tả xu hướng.'),
              ],
            ],
          ),
        ),
      if (tab == 3) ...[
        trend(
          'Carb',
          'g',
          DesignTokens.carbsColor,
          (d) => d.mealCount > 0 && d.nutrition.carbsKnown
              ? d.nutrition.carbsG
              : null,
          'carbs',
        ),
        trend(
          'Đạm',
          'g',
          DesignTokens.proteinColor,
          (d) => d.mealCount > 0 && d.nutrition.proteinKnown
              ? d.nutrition.proteinG
              : null,
          'protein',
        ),
        trend(
          'Chất béo',
          'g',
          DesignTokens.fatColor,
          (d) =>
              d.mealCount > 0 && d.nutrition.fatKnown ? d.nutrition.fatG : null,
          'fat',
        ),
        trend(
          'Chất xơ',
          'g',
          theme.colorScheme.tertiary,
          (d) => d.mealCount > 0 && d.nutrition.fiberKnown
              ? d.nutrition.fiberG
              : null,
          'fiber',
        ),
      ],
      if (tab == 2) ...[
        trend(
          'Nước',
          'ml',
          theme.colorScheme.primary,
          (d) => d.waterCount > 0 ? d.waterMl.toDouble() : null,
          'water',
        ),
        trend(
          'Vận động',
          'phút',
          theme.colorScheme.tertiary,
          (d) => d.activityCount > 0 ? d.activityMinutes.toDouble() : null,
          'activity',
        ),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?controls,
        if (!reflection.hasLogs)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Chưa có nhật ký bữa ăn, nước hoặc vận động trong tuần này.',
            ),
          ),
        if (tab == 0) ...[
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Mức độ ghi nhận', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '${reflection.days.where((d) => d.hasLogs).length} / ${reflection.eligibleDays} ngày đã ghi nhật ký',
                ),
                Text(
                  '${confirmedDays ?? '—'} / ${reflection.eligibleDays} ngày xác nhận đủ bữa',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text('Ngày chưa ghi để trống, không tính là 0 trong trung bình.'),
        const SizedBox(height: 12),
        for (final card in cards) ...[card, const SizedBox(height: 16)],
      ],
    );
  }
}

class _WeightLabel extends StatelessWidget {
  const _WeightLabel(this.label, this.value);
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 4),
      Text(
        '${NumberFormat('0.#', 'vi').format(value)} kg',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ],
  );
}

class RecordedTrendCard extends StatelessWidget {
  const RecordedTrendCard({
    required this.title,
    required this.unit,
    required this.color,
    required this.points,
    this.controls,
    this.referenceHero = false,
    super.key,
  });
  final String title, unit;
  final Color color;
  final List<TrendPoint> points;
  final Widget? controls;
  final bool referenceHero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recorded = points.where((point) => point.value != null).toList();
    final average = recorded.isEmpty
        ? null
        : recorded.fold(0.0, (sum, point) => sum + point.value!) /
              recorded.length;
    final largest = recorded.fold(
      1.0,
      (max, point) => math.max(max, point.value!),
    );
    // Four readable Y intervals, rounded to a human-friendly unit.
    final roughStep = largest / 3;
    final magnitude = math
        .pow(10, (math.log(roughStep) / math.ln10).floor())
        .toDouble();
    final step =
        [1.0, 2.0, 5.0, 10.0].firstWhere((n) => n * magnitude >= roughStep) *
        magnitude;
    final maximum = (largest / step).ceil() * step;
    final number = NumberFormat('#,##0.#', 'vi');
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('$title ($unit)', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            average == null
                ? 'Chưa có dữ liệu đã ghi'
                : '${number.format(average)} $unit / ngày có dữ liệu',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${recorded.length} / ${points.length} ngày có dữ liệu',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ?controls,
          if (recorded.isNotEmpty) ...[
            const Text('Chạm điểm để xem ngày và giá trị.'),
            const SizedBox(height: 12),
            Semantics(
              label:
                  '$title, đơn vị $unit. ${points.map((p) => '${DateFormat('dd/MM').format(p.date)}: ${p.value == null ? 'chưa ghi' : '${number.format(p.value)} $unit'}').join('. ')}',
              child: ExcludeSemantics(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: math.max(constraints.maxWidth, 280 * scale),
                      height: 180 + MediaQuery.textScalerOf(context).scale(32),
                      child: LineChart(
                        key: title == 'Năng lượng'
                            ? const ValueKey('weekly-chart')
                            : null,
                        LineChartData(
                          minX: 0,
                          maxX: math.max(1, points.length - 1).toDouble(),
                          minY: 0,
                          maxY: maximum,
                          gridData: FlGridData(
                            drawVerticalLine: false,
                            horizontalInterval: step,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: theme.colorScheme.outlineVariant,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: step,
                                reservedSize: 44 * scale,
                                getTitlesWidget: (value, meta) =>
                                    SideTitleWidget(
                                      meta: meta,
                                      child: Text(
                                        NumberFormat.compact(
                                          locale: 'vi',
                                        ).format(value),
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: points.length > 4 ? 2 : 1,
                                reservedSize:
                                    MediaQuery.textScalerOf(context).scale(24) +
                                    12,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 ||
                                      index >= points.length ||
                                      value != index.toDouble()) {
                                    return const SizedBox.shrink();
                                  }
                                  return SideTitleWidget(
                                    meta: meta,
                                    child: Text(
                                      DateFormat(
                                        'd/M',
                                      ).format(points[index].date),
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              getTooltipColor: (_) =>
                                  theme.colorScheme.inverseSurface,
                              getTooltipItems: (spots) => spots.map((spot) {
                                final point = points[spot.x.round()];
                                return LineTooltipItem(
                                  '${DateFormat('dd/MM/yyyy').format(point.date)}\n${number.format(point.value)} $unit',
                                  TextStyle(
                                    color: theme.colorScheme.onInverseSurface,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (final entry in points.indexed)
                                  entry.$2.value == null
                                      ? FlSpot.nullSpot
                                      : FlSpot(
                                          entry.$1.toDouble(),
                                          entry.$2.value!,
                                        ),
                              ],
                              color: color,
                              barWidth: 2.5,
                              isCurved: false,
                              dotData: const FlDotData(show: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
