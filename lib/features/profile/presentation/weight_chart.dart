import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/body_metric.dart';

class WeightChart extends StatelessWidget {
  const WeightChart({required this.metrics, this.maxPoints = 12, super.key})
    : assert(maxPoints > 0);

  final List<BodyMetric> metrics;
  final int maxPoints;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    final sorted = [...metrics]
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    final ordered = sorted.take(maxPoints).toList().reversed.toList();
    // Timestamp distance preserves gaps on sparse weeks (ordinal x did not).
    final origin = ordered.first.measuredAt;
    double xOf(DateTime time) =>
        time.difference(origin).inMilliseconds / Duration.millisecondsPerDay;
    final span = xOf(ordered.last.measuredAt);
    final weights = ordered.map((metric) => metric.weightKg);
    final minimum = weights.reduce(math.min);
    final maximum = weights.reduce(math.max);
    final minY = math.max(0, (minimum - 2).floorToDouble()).toDouble();
    final maxY = math.max(minY + 4, (maximum + 2).ceilToDouble()).toDouble();
    final number = NumberFormat('0.#', 'vi_VN');
    final date = DateFormat('d/M');
    final theme = Theme.of(context);

    return Semantics(
      label:
          'Biểu đồ cân nặng, đơn vị kg. ${ordered.length} lần cân trên ${ordered.map((m) => DateFormat('yyyy-MM-dd').format(m.measuredAt)).toSet().length} ngày. ${ordered.map((m) => '${DateFormat('dd/MM/yyyy').format(m.measuredAt)}: ${number.format(m.weightKg)} kg').join('. ')}. Ngày thiếu không có điểm cân.',
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(
              constraints.maxWidth,
              280 * MediaQuery.textScalerOf(context).scale(1),
            ),
            key: const ValueKey('weight-chart'),
            height: 200 + MediaQuery.textScalerOf(context).scale(32),
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: math.max(1, span).toDouble(),
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: math.max(1, (maxY - minY) / 4),
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
                      reservedSize: MediaQuery.textScalerOf(context).scale(44),
                      interval: math.max(1, ((maxY - minY) / 3).ceilToDouble()),
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(
                          number.format(value),
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize:
                          MediaQuery.textScalerOf(context).scale(24) + 12,
                      interval: math.max(1, (span / 3).ceilToDouble()),
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value > span) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            date.format(
                              origin.add(
                                Duration(
                                  milliseconds:
                                      (value * Duration.millisecondsPerDay)
                                          .round(),
                                ),
                              ),
                            ),
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
                    getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final metric = ordered[spot.spotIndex];
                      return LineTooltipItem(
                        '${DateFormat('dd/MM/yyyy HH:mm').format(metric.measuredAt)}\n${number.format(metric.weightKg)} kg',
                        TextStyle(color: theme.colorScheme.onInverseSurface),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (final entry in ordered.indexed)
                        FlSpot(xOf(entry.$2.measuredAt), entry.$2.weightKg),
                    ],
                    isCurved: false,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
