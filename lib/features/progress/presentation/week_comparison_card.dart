import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/app_card.dart';
import '../../weekly_reflection/providers/weekly_reflection_providers.dart';
import '../models/week_comparison.dart';

class WeekComparisonCard extends ConsumerWidget {
  const WeekComparisonCard({
    required this.start,
    required this.today,
    required this.expanded,
    required this.onToggle,
    super.key,
  });
  final DateTime start, today;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final before = DateTime(start.year, start.month, start.day - 7);
    // Subscribe only while this section is visible and open. The current week
    // shares its cached result/listeners with the existing Progress overview.
    final current = expanded ? ref.watch(weeklyLogsProvider(start)) : null;
    final previous = expanded ? ref.watch(weeklyLogsProvider(before)) : null;
    final theme = Theme.of(context);
    return AppCard(
      key: const ValueKey('week-comparison-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton.icon(
            key: const ValueKey('toggle-week-comparison'),
            onPressed: onToggle,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              alignment: Alignment.centerLeft,
              minimumSize: const Size(48, 48),
            ),
            icon: Icon(expanded ? AppIcons.chevronUp : AppIcons.chevronDown),
            label: const Text('So sánh với tuần trước'),
          ),
          if (!expanded)
            const Text(
              'Đối chiếu cân nặng, dinh dưỡng và thói quen theo cùng thứ trong tuần.',
            ),
          if (expanded) ...[
            if (current!.isLoading || previous!.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    LinearProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Đang tải dữ liệu đối chiếu…'),
                  ],
                ),
              )
            else if (current.hasError || previous.hasError) ...[
              const Text(
                'Chưa tải đủ dữ liệu hai tuần. Chưa thể tính chênh lệch.',
              ),
              TextButton(
                key: const ValueKey('retry-week-comparison'),
                onPressed: () {
                  if (current.hasError) {
                    ref.invalidate(weeklyLogsProvider(start));
                  }
                  if (previous.hasError) {
                    ref.invalidate(weeklyLogsProvider(before));
                  }
                },
                child: const Text('Thử lại so sánh'),
              ),
            ] else
              ..._contents(
                context,
                compareWeeks(
                  start: start,
                  today: today,
                  current: current.requireValue,
                  previous: previous.requireValue,
                ),
              ),
          ],
        ],
      ),
    );
  }

  List<Widget> _contents(BuildContext context, WeekComparison comparison) {
    final date = DateFormat('dd/MM/yyyy');
    if (comparison.elapsedDays == 0) {
      return [const Text('Tuần này chưa bắt đầu; chưa có ngày để đối chiếu.')];
    }
    return [
      Text(
        'Đang xem: ${date.format(comparison.start)} – ${date.format(comparison.lastDay)}',
      ),
      Text(
        'Tuần trước: ${date.format(comparison.previousStart)} – ${date.format(comparison.previousLastDay)}',
      ),
      if (comparison.inProgress)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Tuần này đang diễn ra. Hôm nay chưa kết thúc nên số liệu còn thay đổi.',
          ),
        ),
      const SizedBox(height: 12),
      const Text(
        'Trung bình chỉ tính các cặp cùng thứ có dữ liệu ở cả hai tuần. Ngày chưa ghi không tính là 0.',
      ),
      for (final metric in comparison.metrics) ...[
        const Divider(height: 24),
        _MetricComparison(metric: metric, eligibleDays: comparison.elapsedDays),
      ],
      const SizedBox(height: 16),
      Text(
        'Số bữa đã ghi có thể chưa đủ cả ngày. Chênh lệch không đồng nghĩa tốt hơn hay xấu hơn.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];
  }
}

class _MetricComparison extends StatelessWidget {
  const _MetricComparison({required this.metric, required this.eligibleDays});
  final WeekMetricComparison metric;
  final int eligibleDays;
  @override
  Widget build(BuildContext context) {
    final (title, unit) = switch (metric.measure) {
      ProgressMeasure.energy => ('Năng lượng đã ghi', 'kcal'),
      ProgressMeasure.weight => ('Cân nặng', 'kg'),
      ProgressMeasure.water => ('Nước đã ghi', 'ml'),
      ProgressMeasure.activity => ('Vận động đã ghi', 'phút'),
    };
    final number = NumberFormat('#,##0.#', 'vi');
    final delta = metric.difference == null
        ? null
        : (metric.difference! * 10).round() / 10;
    return Column(
      key: ValueKey('week-comparison-${metric.measure.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'Ngày có dữ liệu: đang xem ${metric.currentDays}/$eligibleDays · tuần trước ${metric.previousDays}/$eligibleDays',
        ),
        if (metric.pairs.isEmpty) ...[
          const SizedBox(height: 8),
          const Text('Chưa có cặp cùng thứ đủ dữ liệu để so sánh.'),
        ] else ...[
          Text('${metric.pairs.length} cặp ngày đối chiếu'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final (label, value) in [
                    ('Tuần đang xem', metric.currentAverage!),
                    ('Tuần trước', metric.previousAverage!),
                  ])
                    SizedBox(
                      width: stacked
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 12) / 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${number.format(value)} $unit',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Chênh lệch: ${delta! > 0 ? '+' : ''}${number.format(delta)} $unit',
            key: ValueKey('week-comparison-difference-${metric.measure.name}'),
          ),
          if (metric.measure == ProgressMeasure.weight)
            const Text(
              'Mỗi ngày cân được tính một giá trị trung bình; đây không phải mức tăng/giảm từ đầu đến cuối tuần.',
            ),
        ],
      ],
    );
  }
}
