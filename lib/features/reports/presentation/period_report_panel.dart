import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/data/bounded_range.dart';
import '../../../core/utils/local_date_key.dart';
import '../../food_library/presentation/food_nutrition_text.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition_targets/models/nutrition_target.dart';
import '../../profile/presentation/weight_chart.dart';
import '../models/period_report.dart';
import '../providers/report_providers.dart';
import 'day_review_controls.dart';

class PeriodReportPanel extends ConsumerStatefulWidget {
  const PeriodReportPanel({
    required this.days,
    required this.today,
    this.selectedRange,
    super.key,
  });
  final int days;
  final DateTime today;
  final ReportRange? selectedRange;
  @override
  ConsumerState<PeriodReportPanel> createState() => _PeriodReportPanelState();
}

class _PeriodReportPanelState extends ConsumerState<PeriodReportPanel> {
  int _offset = 0;
  int _detailsPage = 0;
  @override
  void didUpdateWidget(covariant PeriodReportPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days != widget.days ||
        oldWidget.selectedRange != widget.selectedRange) {
      _offset = 0;
      _detailsPage = 0;
    }
  }

  Widget _source<T>(
    String title,
    AsyncValue<T> state,
    VoidCallback retry,
    Widget Function(T) show,
  ) => state.when(
    skipLoadingOnRefresh: false,
    skipLoadingOnReload: false,
    skipError: false,
    loading: () => Column(
      children: [const LinearProgressIndicator(), Text('Đang tải $title…')],
    ),
    error: (e, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          e is RangeReadFailure
              ? e.message
              : 'Chưa tải được $title. Không coi dữ liệu thiếu là 0; thử lại hoặc chọn khoảng ngắn hơn.',
        ),
        TextButton(onPressed: retry, child: Text('Thử lại $title')),
      ],
    ),
    data: show,
  );
  bool _ready(AsyncValue<Object?> s) => !s.isLoading && !s.hasError;
  @override
  Widget build(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final rollingEnd = DateTime(
      widget.today.year,
      widget.today.month,
      widget.today.day + 1 + widget.days * _offset,
    );
    final range = widget.selectedRange ?? ReportRange(rollingEnd, widget.days);
    final end = range.end;
    final meals = ref.watch(periodMealsProvider(range));
    final targets = ref.watch(periodTargetsProvider(range));
    final reviews = ref.watch(dayReviewsProvider(range));
    final water = ref.watch(periodWaterProvider(range));
    final activity = ref.watch(periodActivityProvider(range));
    final metrics = ref.watch(periodMetricsProvider(range));
    final date = DateFormat('dd/MM/yyyy', 'vi'),
        number = NumberFormat('0.#', 'vi');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('refresh-period'),
          onPressed: () {
            ref.invalidate(periodMealsProvider(range));
            ref.invalidate(periodWaterProvider(range));
            ref.invalidate(periodActivityProvider(range));
            ref.invalidate(periodMetricsProvider(range));
            ref.invalidate(periodTargetsProvider(range));
            ref.invalidate(dayReviewsProvider(range));
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Tải lại khoảng đã chọn'),
        ),
        Row(
          children: [
            if (widget.selectedRange == null)
              IconButton(
                key: const ValueKey('previous-period'),
                tooltip: 'Khoảng trước',
                onPressed: () => setState(() {
                  _offset--;
                  _detailsPage = 0;
                }),
                icon: const Icon(Icons.chevron_left),
              ),
            Expanded(
              child: Text(
                '${date.format(range.start)} – ${date.format(DateTime(end.year, end.month, end.day - 1))}',
                key: const ValueKey('period-range'),
                textAlign: TextAlign.center,
              ),
            ),
            if (widget.selectedRange == null)
              IconButton(
                key: const ValueKey('next-period'),
                tooltip: 'Khoảng sau',
                onPressed: _offset < 0
                    ? () => setState(() {
                        _offset++;
                        _detailsPage = 0;
                      })
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
          ],
        ),
        const Text(
          'Theo ngày địa phương đã ghi nhận. Kéo biểu đồ để xem từng ngày.',
        ),
        Text(
          '${range.days} ngày · Khoảng xem không phải thời hạn lưu dữ liệu.',
          key: const ValueKey('report-day-count'),
        ),
        if (range.days > 90)
          const Text(
            'Báo cáo dài được tải theo từng phần; nhiều dữ liệu có thể cần thêm thời gian. Chỉ hiện tổng khi nguồn đó đã tải đủ.',
          ),
        _source('bữa ăn', meals, () => ref.invalidate(periodMealsProvider(range)), (
          logs,
        ) {
          final values = {for (final m in logs) m.id: m}.values.toList();
          final total = totalMealNutrition(values);
          final coverage = RecordingCoverage(
            range: range,
            today: widget.today,
            meals: values,
            reviews: _ready(reviews) ? reviews.value! : [],
          );
          final versions = _ready(targets)
              ? targets.value!
              : <NutritionTarget>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${number.format(total.kcal)} kcal đã ghi',
                key: const ValueKey('period-total-kcal'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (values.isEmpty)
                const Text(
                  'Chưa ghi bữa ăn trong khoảng này; chưa có trung bình năng lượng.',
                ),
              Text(nutritionLabel(total)),
              Text(
                '${coverage.recordedDays}/${coverage.dates.length} ngày có ghi bữa; chỉ phản ánh mức độ ghi nhận.',
              ),
              if (_ready(reviews)) ...[
                Text(
                  '${coverage.confirmedRecordedDays} ngày đã xác nhận đủ bữa · ${coverage.partialDays} ngày đang ghi · ${coverage.unrecordedDays} ngày chưa ghi bữa',
                  key: const ValueKey('recording-coverage'),
                ),
                Text(
                  coverage.confirmedAverageKcal == null
                      ? 'Chưa có ngày có bữa ăn được xác nhận để tính trung bình.'
                      : 'Trung bình ${number.format(coverage.confirmedAverageKcal)} kcal / ${coverage.confirmedRecordedDays} ngày có bữa đã xác nhận. Các ngày đang ghi được loại khỏi mẫu số.',
                ),
              ] else
                _source(
                  'xác nhận ngày',
                  reviews,
                  () => ref.invalidate(dayReviewsProvider(range)),
                  (_) => const SizedBox.shrink(),
                ),
              if (!_ready(targets))
                _source(
                  'mục tiêu',
                  targets,
                  () => ref.invalidate(periodTargetsProvider(range)),
                  (_) => const SizedBox.shrink(),
                ),
              if (_ready(targets) && versions.isEmpty)
                const Text('Chưa có mục tiêu hiệu lực trong khoảng này.'),
              const SizedBox(height: 12),
              Text(
                'Năng lượng (kcal)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text(
                'Đường liền: đã ghi · Nét đứt: mục tiêu gốc theo ngày.',
              ),
              const Text('Chạm điểm để xem giá trị; ngày chưa ghi để trống.'),
              _EnergyChart(coverage: coverage, targets: versions),
              if (range.days > 90)
                ExpansionTile(
                  key: const ValueKey('period-month-details'),
                  title: const Text('Tổng hợp theo tháng'),
                  children: [
                    for (final month in {
                      for (final d in coverage.dates) DateTime(d.year, d.month),
                    })
                      Builder(
                        builder: (context) {
                          final days = coverage.dates
                              .where(
                                (d) =>
                                    d.year == month.year &&
                                    d.month == month.month,
                              )
                              .toList();
                          final logs = days.expand(coverage.logs).toList();
                          final confirmedDays = days
                              .where(
                                (d) =>
                                    coverage.logs(d).isNotEmpty &&
                                    coverage.confirmed(d),
                              )
                              .toList();
                          final confirmedAverage = confirmedDays.isEmpty
                              ? null
                              : confirmedDays.fold(
                                      0.0,
                                      (sum, d) =>
                                          sum +
                                          totalMealNutrition(
                                            coverage.logs(d),
                                          ).kcal,
                                    ) /
                                    confirmedDays.length;
                          return ListTile(
                            title: Text(
                              'Tháng ${DateFormat('MM/yyyy').format(month)} · ${number.format(totalMealNutrition(logs).kcal)} kcal đã ghi',
                            ),
                            subtitle: Text(
                              '${days.where((d) => coverage.logs(d).isNotEmpty).length}/${days.length} ngày có ghi · ${nutritionLabel(totalMealNutrition(logs))}\n${confirmedAverage == null ? 'Chưa có trung bình ngày đã xác nhận' : 'Trung bình ${number.format(confirmedAverage)} kcal / ${confirmedDays.length} ngày có bữa đã xác nhận'}',
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ExpansionTile(
                key: const ValueKey('period-day-details'),
                title: const Text('Chi tiết từng ngày / xác nhận'),
                children: [
                  if (coverage.dates.length > 31)
                    Row(
                      children: [
                        IconButton(
                          key: const ValueKey('report-details-previous'),
                          tooltip: 'Nhóm ngày trước',
                          onPressed: _detailsPage > 0
                              ? () => setState(() => _detailsPage--)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            'Trang ${_detailsPage + 1}/${(coverage.dates.length / 31).ceil()}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('report-details-next'),
                          tooltip: 'Nhóm ngày sau',
                          onPressed:
                              (_detailsPage + 1) * 31 < coverage.dates.length
                              ? () => setState(() => _detailsPage++)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  for (final day
                      in coverage.dates.skip(_detailsPage * 31).take(31))
                    ListTile(
                      title: Text(date.format(day)),
                      subtitle: Text(
                        coverage.logs(day).isEmpty
                            ? 'Chưa ghi bữa'
                            : '${number.format(totalMealNutrition(coverage.logs(day)).kcal)} kcal đã ghi · ${!_ready(reviews)
                                  ? 'Chưa tải trạng thái'
                                  : coverage.confirmed(day)
                                  ? 'Bạn đã xác nhận'
                                  : 'Đang ghi'}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Kiểm tra và xác nhận ngày',
                        onPressed: () => openDayReview(context, day),
                        icon: const Icon(Icons.fact_check_outlined),
                      ),
                    ),
                ],
              ),
            ],
          );
        }),
        const Divider(height: 32),
        _source('nước', water, () => ref.invalidate(periodWaterProvider(range)), (
          logs,
        ) {
          final unique = {for (final w in logs) w.id: w}.values;
          return Text(
            '${unique.fold(0, (sum, w) => sum + w.amountMl)} ml nước / ${unique.map((w) => w.dateKey).toSet().length} ngày có ghi',
          );
        }),
        _source(
          'vận động',
          activity,
          () => ref.invalidate(periodActivityProvider(range)),
          (logs) {
            final unique = {for (final a in logs) a.id: a}.values;
            return Text(
              '${unique.fold(0, (sum, a) => sum + a.durationMinutes)} phút vận động / ${unique.map((a) => a.dateKey).toSet().length} ngày có ghi',
            );
          },
        ),
        const SizedBox(height: 16),
        _source(
          'cân nặng',
          metrics,
          () => ref.invalidate(periodMetricsProvider(range)),
          (values) {
            final ordered =
                {
                    for (final m in values) m.id: m,
                  }.values.where((m) => m.measuredAt.isBefore(end)).toList()
                  ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
            if (ordered.isEmpty) {
              return const Text('Chưa có lần cân trong khoảng này.');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${ordered.length} lần cân / ${ordered.map((m) => localDateKey(m.measuredAt.toLocal())).toSet().length} ngày có cân. Đường nối các lần cân theo thời gian thực; không tạo điểm cân cho ngày thiếu.',
                ),
                if (ordered.length > 1)
                  Text(
                    'Chênh lệch ${number.format(ordered.last.weightKg - ordered.first.weightKg)} kg giữa ${date.format(ordered.first.measuredAt)} và ${date.format(ordered.last.measuredAt)}. Chỉ mô tả hai lần cân, không suy ra thay đổi mỡ.',
                  )
                else
                  const Text('Một lần cân chưa đủ để mô tả thay đổi.'),
                WeightChart(metrics: ordered, maxPoints: ordered.length),
              ],
            );
          },
        ),
        ExpansionTile(
          title: const Text('Cách đọc báo cáo'),
          children: const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Trạng thái đủ bữa do bạn xác nhận, không do ứng dụng đoán. Thêm/sửa/xóa nhật ký sau xác nhận làm trạng thái cũ cần kiểm tra lại. Chỗ thiếu nhật ký là khoảng trống, không phải 0 kcal đã ăn và không suy ra đạt/không đạt mục tiêu. Ngày trống không tham gia trung bình năng lượng. Biểu đồ không chẩn đoán sức khỏe.',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EnergyChart extends StatelessWidget {
  const _EnergyChart({required this.coverage, required this.targets});
  final RecordingCoverage coverage;
  final List<NutritionTarget> targets;
  @override
  Widget build(BuildContext context) {
    final actual = <FlSpot>[], goal = <FlSpot>[];
    var maxY = 500.0;
    for (var i = 0; i < coverage.range.days; i++) {
      final day = DateTime(
        coverage.range.start.year,
        coverage.range.start.month,
        coverage.range.start.day + i,
      );
      final logs = coverage.logs(day);
      final target = targetForDate(targets, localDateKey(day));
      if (logs.isEmpty || day.isAfter(localDateOnly(coverage.today))) {
        actual.add(FlSpot.nullSpot);
      } else {
        final kcal = totalMealNutrition(logs).kcal;
        actual.add(FlSpot(i.toDouble(), kcal));
        maxY = math.max(maxY, kcal);
      }
      if (target == null || day.isAfter(localDateOnly(coverage.today))) {
        goal.add(FlSpot.nullSpot);
      } else {
        goal.add(FlSpot(i.toDouble(), target.kcalTarget));
        maxY = math.max(maxY, target.kcalTarget);
      }
    }
    if (actual.every((s) => s.isNull()) && goal.every((s) => s.isNull())) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width:
            math.max(360, coverage.range.days * 12).toDouble() *
            MediaQuery.textScalerOf(context).scale(1),
        height: 240 + MediaQuery.textScalerOf(context).scale(32),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: math.max(1, coverage.range.days - 1).toDouble(),
            minY: 0,
            maxY: maxY * 1.1,
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: maxY / 3,
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipColor: (_) =>
                    Theme.of(context).colorScheme.inverseSurface,
                getTooltipItems: (spots) => spots.map((spot) {
                  final day = DateTime(
                    coverage.range.start.year,
                    coverage.range.start.month,
                    coverage.range.start.day + spot.x.round(),
                  );
                  return LineTooltipItem(
                    '${DateFormat('dd/MM/yyyy').format(day)}\n${spot.barIndex == 0 ? 'Đã ghi' : 'Mục tiêu gốc'}: ${NumberFormat('0.#', 'vi').format(spot.y)} kcal',
                    TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                    ),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: actual,
                isCurved: false,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 2,
                dotData: const FlDotData(show: true),
              ),
              LineChartBarData(
                spots: goal,
                isCurved: false,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                dashArray: [5, 5],
                barWidth: 1,
                dotData: const FlDotData(show: false),
              ),
            ],
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: coverage.range.days > 90
                      ? 30
                      : coverage.range.days > 30
                      ? 14
                      : 7,
                  getTitlesWidget: (v, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      DateFormat('d/M').format(
                        DateTime(
                          coverage.range.start.year,
                          coverage.range.start.month,
                          coverage.range.start.day + v.toInt(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxY / 3,
                  reservedSize: MediaQuery.textScalerOf(context).scale(44),
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      NumberFormat.compact(locale: 'vi').format(value),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
