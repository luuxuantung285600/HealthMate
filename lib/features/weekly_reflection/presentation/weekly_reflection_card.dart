import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../food_library/presentation/food_nutrition_text.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../profile/presentation/weight_chart.dart';
import '../../../core/utils/local_date_key.dart';
import '../../nutrition_targets/models/nutrition_target.dart';
import '../../nutrition_targets/providers/nutrition_target_providers.dart';
import '../models/weekly_reflection.dart';
import '../providers/weekly_reflection_providers.dart';
import '../../reports/models/period_report.dart';
import '../../reports/presentation/recording_coverage_block.dart';

enum _ChartMetric {
  kcal('Năng lượng đã ghi', 'kcal'),
  water('Nước đã ghi', 'ml'),
  activity('Vận động đã ghi', 'phút');

  const _ChartMetric(this.label, this.unit);
  final String label, unit;
  double value(DayReflection day) => switch (this) {
    kcal => day.nutrition.kcal,
    water => day.waterMl.toDouble(),
    activity => day.activityMinutes.toDouble(),
  };
  bool recorded(DayReflection day) => switch (this) {
    kcal => day.mealCount > 0,
    water => day.waterCount > 0,
    activity => day.activityCount > 0,
  };
}

class WeeklyReflectionCard extends ConsumerStatefulWidget {
  const WeeklyReflectionCard({
    required this.today,
    this.progressMode = false,
    this.initialWeekOffset = 0,
    super.key,
  });
  final bool progressMode;
  final int initialWeekOffset;
  final DateTime today;
  @override
  ConsumerState<WeeklyReflectionCard> createState() =>
      _WeeklyReflectionCardState();
}

class _WeeklyReflectionCardState extends ConsumerState<WeeklyReflectionCard> {
  bool _expanded = false;
  int _offset = 0;
  _ChartMetric _metric = _ChartMetric.kcal;
  @override
  void initState() {
    super.initState();
    _expanded = widget.progressMode;
    _offset = widget.initialWeekOffset;
  }

  void _refresh(DateTime start) {
    ref.invalidate(weeklyLogsProvider(start));
    if (widget.progressMode) {
      ref.invalidate(weeklyNutritionTargetsProvider(start));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final current = weekStart(widget.today);
    final start = DateTime(
      current.year,
      current.month,
      current.day + 7 * _offset,
    );
    final last = DateTime(start.year, start.month, start.day + 6);
    final date = DateFormat('dd/MM/yyyy');
    final state = _expanded ? ref.watch(weeklyLogsProvider(start)) : null;
    final targets =
        _expanded &&
            widget.progressMode &&
            state != null &&
            !state.isLoading &&
            !state.hasError
        ? ref.watch(weeklyNutritionTargetsProvider(start))
        : null;
    return AppCard(
      padding: EdgeInsets.all(widget.progressMode ? 16 : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.progressMode)
            InkWell(
              key: const ValueKey('open-weekly-reflection'),
              onTap: widget.progressMode
                  ? null
                  : () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(Icons.insights_outlined),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.progressMode ? 'Tuần của bạn' : 'Nhìn lại tuần',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (!widget.progressMode)
                      Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
          if (!_expanded)
            const Text('Xem những gì bạn đã ghi trong tuần. Chỉ tải khi mở.'),
          if (_expanded) ...[
            if (!widget.progressMode) const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                IconButton(
                  key: const ValueKey('previous-week'),
                  tooltip: 'Tuần trước',
                  onPressed: () => setState(() => _offset--),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '${date.format(start)} – ${date.format(last)}',
                    key: const ValueKey('weekly-range'),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  key: const ValueKey('next-week'),
                  tooltip: 'Tuần sau',
                  onPressed: _offset < 0
                      ? () => setState(() => _offset++)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            state!.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              skipError: false,
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Column(
                children: [
                  const Text(
                    'Chưa tải đủ dữ liệu tuần. Không thể tính tổng từ dữ liệu thiếu.',
                  ),
                  TextButton(
                    key: const ValueKey('retry-week'),
                    onPressed: () => _refresh(start),
                    child: const Text('Thử lại báo cáo'),
                  ),
                ],
              ),
              data: (logs) {
                final reflection = summarizeWeek(start, widget.today, logs);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!reflection.hasLogs) ...[
                      const Text(
                        'Chưa có nhật ký bữa ăn, nước hoặc vận động trong tuần này.',
                      ),
                      Text(
                        'Trong ${reflection.eligibleDays} ngày đã tới: 0 ngày ghi bữa ăn, 0 ngày ghi nước, 0 ngày ghi vận động.',
                      ),
                    ] else ...[
                      _ReflectionSummary(
                        reflection: reflection,
                        compact: widget.progressMode,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final metric in _ChartMetric.values)
                            ChoiceChip(
                              key: ValueKey('week-metric-${metric.name}'),
                              selected: metric == _metric,
                              label: Text(switch (metric) {
                                _ChartMetric.kcal => 'Năng lượng',
                                _ChartMetric.water => 'Nước',
                                _ChartMetric.activity => 'Vận động',
                              }),
                              onSelected: (_) =>
                                  setState(() => _metric = metric),
                            ),
                        ],
                      ),
                      if (reflection.days.any(_metric.recorded))
                        _WeekChart(reflection: reflection, metric: _metric)
                      else
                        Text(
                          'Chưa có ghi nhận cho ${_metric.label.toLowerCase()} trong tuần này.',
                        ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    if (reflection.metrics.isEmpty)
                      const Text('Chưa có lần cân trong tuần này.')
                    else ...[
                      Text(
                        'Cân nặng trong tuần',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      WeightChart(
                        metrics: reflection.metrics.reversed.toList(),
                      ),
                      Text(
                        reflection.weightChange == null
                            ? 'Mới có một lần cân; chưa đủ để mô tả thay đổi.'
                            : 'Chênh lệch lần cuối so với lần đầu: ${NumberFormat('+0.#;-0.#', 'vi').format(reflection.weightChange)} kg. Không suy diễn nguyên nhân từ số đo.',
                      ),
                    ],
                    if (widget.progressMode)
                      RecordingCoverageBlock(
                        range: ReportRange(
                          DateTime(start.year, start.month, start.day + 7),
                          7,
                        ),
                        today: widget.today,
                        meals: logs.meals,
                      ),
                    if (targets?.isLoading == true)
                      const Text('Đang tải mục tiêu tuần…'),
                    if (targets?.hasError == true) ...[
                      const Text(
                        'Chưa tải được mục tiêu tuần. Tổng nhật ký phía trên vẫn là dữ liệu đã tải; chưa thể so sánh mục tiêu.',
                      ),
                      TextButton(
                        key: const ValueKey('retry-week-targets'),
                        onPressed: () => ref.invalidate(
                          weeklyNutritionTargetsProvider(start),
                        ),
                        child: const Text('Thử lại mục tiêu'),
                      ),
                    ],
                    ExpansionTile(
                      key: ValueKey('week-details-${localDateKey(start)}'),
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Chi tiết từng ngày / Mục tiêu'),
                      children: [
                        for (final day in reflection.days)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '${DateFormat('EEE d/M', 'vi').format(day.date)}: ${day.isFuture
                                    ? 'Chưa tới ngày'
                                    : !_metric.recorded(day)
                                    ? 'Chưa ghi'
                                    : '${NumberFormat('0.#', 'vi').format(_metric.value(day))} ${_metric.unit} đã ghi'}',
                              ),
                            ),
                          ),
                        for (final metric in reflection.metrics)
                          Text(
                            '${DateFormat('dd/MM/yyyy HH:mm').format(metric.measuredAt)} · ${NumberFormat('0.#', 'vi').format(metric.weightKg)} kg',
                          ),
                        if (targets != null &&
                            !targets.isLoading &&
                            !targets.hasError)
                          _DailyTargets(state: targets, reflection: reflection),
                      ],
                    ),
                    ExpansionTile(
                      key: const ValueKey('week-reading-guide'),
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Cách đọc số liệu'),
                      children: [
                        Text(
                          'Tuần từ Thứ Hai đến Chủ nhật, theo ngày địa phương đã lưu. Giờ thiết bị: ${widget.today.timeZoneName}. Ngày trống chỉ có nghĩa là chưa ghi nhận.',
                        ),
                        Text(
                          'Trong ${reflection.eligibleDays} ngày đã tới: ${reflection.mealDays} ngày ghi bữa ăn, ${reflection.waterDays} ngày ghi nước, ${reflection.activityDays} ngày ghi vận động.',
                        ),
                        const Text(
                          'Có thể vuốt ngang biểu đồ khi cỡ chữ lớn. Chi tiết từng ngày phân biệt 0 đã ghi, chưa ghi và chưa tới ngày. Không coi ngày thiếu nhật ký là ăn 0 kcal.',
                        ),
                        const Text(
                          'Biểu đồ cân nặng tối đa 12 lần gần nhất trong tuần; điểm cách nhau theo thời điểm đo.',
                        ),
                        const Text(
                          'Tổng hợp chỉ phản ánh nhật ký đã ghi, không đại diện toàn bộ lượng ăn/uống hay hoạt động thực tế và không phải đánh giá sức khỏe.',
                        ),
                      ],
                    ),
                    Text(
                      'Cập nhật ${DateFormat('HH:mm dd/MM').format(logs.loadedAt)}. Tải lại sau khi sửa nhật ký.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton.icon(
                      key: const ValueKey('refresh-week'),
                      onPressed: () => _refresh(start),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tải lại báo cáo'),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ReflectionSummary extends StatelessWidget {
  const _ReflectionSummary({required this.reflection, this.compact = false});
  final WeeklyReflection reflection;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final r = reflection;
    final n = NumberFormat('0.#', 'vi');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tổng đã ghi trong tuần',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (compact) ...[
          Text(
            '${n.format(r.nutrition.kcal)} kcal đã ghi',
            key: const ValueKey('weekly-kcal-summary'),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            'Đạm ${macroAmount(r.nutrition.proteinG, r.nutrition.proteinKnown)} · Tinh bột ${macroAmount(r.nutrition.carbsG, r.nutrition.carbsKnown)} · Béo ${macroAmount(r.nutrition.fatG, r.nutrition.fatKnown)}',
          ),
        ] else
          Text(nutritionLabel(r.nutrition)),
        Text(
          'Chất xơ: ${macroAmount(r.nutrition.fiberG, r.nutrition.fiberKnown)} · chỉ cộng phần có nguồn.',
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Nước: ${n.format(r.waterMl)} ml · Vận động: ${n.format(r.activityMinutes)} phút',
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!compact)
          Text(
            'Trong ${r.eligibleDays} ngày đã tới: ${r.mealDays} ngày ghi bữa ăn, ${r.waterDays} ngày ghi nước, ${r.activityDays} ngày ghi vận động.',
          ),
        if (r.averageKcalPerRecordedDay != null)
          Text(
            'Trung bình trên ${r.mealDays} ngày có ghi bữa: ${n.format(r.averageKcalPerRecordedDay)} kcal/ngày.${compact ? '' : ' Không coi ngày thiếu nhật ký là ăn 0 kcal.'}',
          ),
      ],
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.reflection, required this.metric});
  final WeeklyReflection reflection;
  final _ChartMetric metric;
  @override
  Widget build(BuildContext context) {
    final values = reflection.days.map(metric.value);
    final maxY = math.max(1.0, values.reduce(math.max) * 1.2);
    final theme = Theme.of(context);
    return Semantics(
      label:
          'Biểu đồ ${metric.label}, đơn vị ${metric.unit}. Chi tiết ngày ở bên dưới.',
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(
              constraints.maxWidth,
              300 * MediaQuery.textScalerOf(context).scale(1),
            ),
            height: 264,
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: BarChart(
                key: const ValueKey('weekly-chart'),
                duration: Duration.zero,
                dataForChart(theme, maxY),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BarChartData dataForChart(ThemeData theme, double maxY) => BarChartData(
    minY: 0,
    maxY: maxY,
    barTouchData: BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        getTooltipColor: (_) => theme.colorScheme.inverseSurface,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final day = reflection.days[group.x];
          return BarTooltipItem(
            '${DateFormat('dd/MM/yyyy').format(day.date)}\n${NumberFormat('0.#', 'vi').format(rod.toY)} ${metric.unit}',
            TextStyle(color: theme.colorScheme.onInverseSurface),
          );
        },
      ),
    ),
    borderData: FlBorderData(show: false),
    gridData: const FlGridData(show: false),
    titlesData: FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 52,
          interval: maxY / 3,
          getTitlesWidget: (value, meta) => Text(
            NumberFormat.compact(locale: 'vi').format(value),
            style: theme.textTheme.labelSmall,
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            return i < 0 || i >= 7
                ? const SizedBox.shrink()
                : Text(
                    i == 6 ? 'CN' : 'T${i + 2}',
                    style: theme.textTheme.labelSmall,
                  );
          },
        ),
      ),
    ),
    barGroups: [
      for (final entry in reflection.days.indexed)
        BarChartGroupData(
          x: entry.$1,
          barRods: metric.recorded(entry.$2)
              ? [
                  BarChartRodData(
                    toY: metric.value(entry.$2),
                    width: 18,
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ]
              : [],
        ),
    ],
  );
}

// Loaded once for the selected week, never a query per day.
class _DailyTargets extends StatelessWidget {
  const _DailyTargets({required this.state, required this.reflection});
  final AsyncValue<List<NutritionTarget>> state;
  final WeeklyReflection reflection;
  @override
  Widget build(BuildContext context) {
    final n = NumberFormat('0.#', 'vi');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dinh dưỡng và mục tiêu từng ngày',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Text(
          'Biểu đồ phía trên chỉ thể hiện số đã ghi. Mục tiêu dưới đây là mục tiêu gốc theo ngày hiệu lực, chưa cộng điều chỉnh bước và không áp ngược mục tiêu mới.',
        ),
        state.when(
          skipLoadingOnReload: false,
          skipLoadingOnRefresh: false,
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (targets) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final day in reflection.days) ...[
                const Divider(height: 24),
                Text(
                  DateFormat('EEEE, dd/MM/yyyy', 'vi').format(day.date),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  day.isFuture
                      ? 'Chưa tới ngày · không tính vào tổng hoặc số ngày thiếu ghi.'
                      : day.mealCount == 0
                      ? 'Chưa ghi bữa ăn · chưa có số liệu lượng ăn.'
                      : '${n.format(day.nutrition.kcal)} kcal đã ghi · Đạm ${macroAmount(day.nutrition.proteinG, day.nutrition.proteinKnown)} · Tinh bột ${macroAmount(day.nutrition.carbsG, day.nutrition.carbsKnown)} · Béo ${macroAmount(day.nutrition.fatG, day.nutrition.fatKnown)}',
                ),
                _TargetText(
                  target: targetForDate(targets, localDateKey(day.date)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TargetText extends StatelessWidget {
  const _TargetText({required this.target});
  final NutritionTarget? target;
  @override
  Widget build(BuildContext context) {
    final t = target;
    if (t == null) return const Text('Chưa đặt mục tiêu cho ngày này.');
    final n = NumberFormat('0.#', 'vi');
    return Text(
      'Mục tiêu: ${n.format(t.kcalTarget)} kcal · ${t.proteinGTarget == null ? 'Chưa đặt macro' : 'Đạm ${n.format(t.proteinGTarget)} g · Tinh bột ${n.format(t.carbsGTarget)} g · Béo ${n.format(t.fatGTarget)} g'}',
    );
  }
}
