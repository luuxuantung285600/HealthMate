import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/tracking_page.dart';
import '../../../core/widgets/reference_segments.dart';
import '../../../core/widgets/app_inset_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../data_export/presentation/journal_export_dialog.dart';
import '../../weekly_reflection/presentation/weekly_reflection_card.dart';
import '../../weekly_reflection/providers/weekly_reflection_providers.dart';
import '../../weekly_reflection/models/weekly_reflection.dart';
import '../../reports/presentation/period_report_panel.dart';
import '../../reports/presentation/macro_energy_card.dart';
import '../../reports/presentation/report_range_dialog.dart';
import '../../reports/models/period_report.dart';
import '../../reports/providers/report_providers.dart';
import '../../../core/utils/local_date_key.dart';
import 'progress_overview.dart';
import 'week_comparison_card.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _days = 7;
  int _tab = 0;
  int _offset = 0;
  int _periodOffset = 0;
  bool _details = false;
  bool _compare = false;
  String _mode = 'preset';
  int? _year;
  ReportRange? _customRange;
  @override
  Widget build(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final today = ref.watch(localClockProvider);
    final ownerUid = ref.watch(authSessionProvider).value?.uid;
    final weekly = _mode == 'preset' && _days == 7;
    final selectedYear = _year ?? today.year;
    final monday = weekStart(today);
    final start = DateTime(monday.year, monday.month, monday.day + _offset * 7);
    final end = DateTime(start.year, start.month, start.day + 6);
    final exportRange = _mode == 'year'
        ? ReportRange.year(selectedYear, today)
        : _mode == 'custom'
        ? _customRange
        : weekly
        ? ReportRange.inclusive(
            start,
            end.isAfter(localDateOnly(today)) ? today : end,
          )
        : ReportRange(
            DateTime(
              today.year,
              today.month,
              today.day + 1 + _days * _periodOffset,
            ),
            _days,
          );
    final theme = Theme.of(context);
    final state = weekly && !_details
        ? ref.watch(weeklyLogsProvider(start))
        : null;
    final reviews = weekly && !_details
        ? ref.watch(
            dayReviewsProvider(
              ReportRange(DateTime(end.year, end.month, end.day + 1), 7),
            ),
          )
        : null;
    final weeklyControls = AppInsetPanel(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          ReferenceSegments(
            items: [
              for (final entry in const [
                (0, 'Tổng quan'),
                (3, 'Dưỡng chất'),
                (2, 'Thói quen'),
              ])
                (
                  key: ValueKey('progress-tab-${entry.$1}'),
                  label: entry.$2,
                  selected: _tab == entry.$1,
                  onTap: () => setState(() {
                    _tab = entry.$1;
                    _details = false;
                  }),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              IconButton(
                key: const ValueKey('previous-week'),
                tooltip: 'Tuần trước',
                onPressed: () => setState(() => _offset--),
                icon: const Icon(AppIcons.chevronLeft),
              ),
              Expanded(
                child: Text(
                  '${DateFormat('dd/MM/yyyy').format(start)} – ${DateFormat('dd/MM/yyyy').format(end)}',
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                key: const ValueKey('next-week'),
                tooltip: 'Tuần sau',
                onPressed: _offset < 0 ? () => setState(() => _offset++) : null,
                icon: const Icon(AppIcons.chevronRight),
              ),
            ],
          ),
        ],
      ),
    );
    return TrackingPage(
      key: const ValueKey('progress-screen'),
      showProfileAvatar: false,
      header: Row(
        children: [
          Expanded(
            child: Text(
              'Tiến độ',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('progress-export'),
            tooltip: 'Xuất nhật ký CSV',
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => AccountBoundDialog(
                child: JournalExportDialog(initialRange: exportRange),
              ),
            ),
            icon: const Icon(AppIcons.download),
          ),
        ],
      ),
      children: [
        AppInsetPanel(
          padding: const EdgeInsets.all(8),
          child: ReferenceSegments(
            items: [
              for (final days in [7, 30, 90])
                (
                  key: ValueKey('report-window-$days'),
                  label: days == 7 ? 'Tuần' : '$days ngày',
                  selected: _mode == 'preset' && _days == days,
                  onTap: () => setState(() {
                    if (_mode != 'preset' || _days != days) _periodOffset = 0;
                    _mode = 'preset';
                    _days = days;
                  }),
                ),
              (
                key: const ValueKey('report-window-year'),
                label: 'Năm',
                selected: _mode == 'year',
                onTap: () => setState(() {
                  _mode = 'year';
                  _periodOffset = 0;
                }),
              ),
              (
                key: const ValueKey('report-window-custom'),
                label: 'Tùy chọn',
                selected: _mode == 'custom',
                onTap: () async {
                  final range = await chooseReportRange(
                    context,
                    today: today,
                    initial: _customRange,
                  );
                  if (!mounted || range == null) return;
                  setState(() {
                    _mode = 'custom';
                    _periodOffset = 0;
                    _customRange = range;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_mode == 'year') ...[
          Row(
            children: [
              IconButton(
                key: const ValueKey('previous-report-year'),
                tooltip: 'Năm trước',
                onPressed: selectedYear > 1900
                    ? () => setState(() => _year = selectedYear - 1)
                    : null,
                icon: const Icon(AppIcons.chevronLeft),
              ),
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey('report-year-$selectedYear'),
                  initialValue: selectedYear,
                  decoration: const InputDecoration(labelText: 'Năm báo cáo'),
                  items: [
                    for (var y = today.year; y >= 1900; y--)
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (value) => setState(() => _year = value),
                ),
              ),
              IconButton(
                key: const ValueKey('next-report-year'),
                tooltip: 'Năm sau',
                onPressed: selectedYear < today.year
                    ? () => setState(() => _year = selectedYear + 1)
                    : null,
                icon: const Icon(AppIcons.chevronRight),
              ),
            ],
          ),
          if (selectedYear == today.year)
            const Text('Năm hiện tại tính từ 01/01 đến hết hôm nay.'),
          PeriodReportPanel(
            key: ValueKey('year-report-$selectedYear'),
            days: 366,
            today: today,
            selectedRange: ReportRange.year(selectedYear, today),
          ),
        ] else if (_mode == 'custom') ...[
          OutlinedButton.icon(
            key: const ValueKey('edit-custom-report'),
            onPressed: () async {
              final range = await chooseReportRange(
                context,
                today: today,
                initial: _customRange,
              );
              if (mounted && range != null) {
                setState(() => _customRange = range);
              }
            },
            icon: const Icon(AppIcons.calendarRange),
            label: const Text('Đổi khoảng ngày'),
          ),
          PeriodReportPanel(
            key: ValueKey(_customRange),
            days: _customRange!.days,
            today: today,
            selectedRange: _customRange,
          ),
        ] else if (_days != 7)
          PeriodReportPanel(
            key: ValueKey('rolling-progress-$_days'),
            days: _days,
            today: today,
            initialOffset: _periodOffset,
            onOffsetChanged: (offset) => setState(() => _periodOffset = offset),
          )
        else if (_details)
          WeeklyReflectionCard(
            key: const ValueKey('weekly-details'),
            today: today,
            progressMode: true,
            initialWeekOffset: _offset,
            onWeekOffsetChanged: (offset) => setState(() => _offset = offset),
          )
        else ...[
          weeklyControls,
          const SizedBox(height: 16),
          if (_tab == 0) ...[
            WeekComparisonCard(
              start: start,
              today: today,
              expanded: _compare,
              onToggle: () => setState(() => _compare = !_compare),
            ),
            const SizedBox(height: 16),
          ],
          state!.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            skipError: false,
            loading: () => Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
            error: (_, _) => AppInsetPanel(
              child: Column(
                children: [
                  const Text(
                    'Chưa tải đủ dữ liệu tuần. Không tính tổng từ dữ liệu thiếu.',
                  ),
                  TextButton(
                    key: const ValueKey('retry-progress-overview'),
                    onPressed: () => ref.invalidate(weeklyLogsProvider(start)),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
            data: (logs) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_tab == 3 && ownerUid != null) ...[
                  MacroEnergyCard(
                    ownerUid: ownerUid,
                    meals: logs.meals,
                    range: ReportRange(
                      DateTime(end.year, end.month, end.day + 1),
                      7,
                    ),
                    today: today,
                  ),
                  const SizedBox(height: 16),
                ],
                ProgressOverview(
                  reflection: summarizeWeek(start, today, logs),
                  tab: _tab,
                  confirmedDays:
                      reviews == null || reviews.isLoading || reviews.hasError
                      ? null
                      : reviews.value
                            ?.where(
                              (r) => r.matches(
                                logs.meals
                                    .where(
                                      (m) =>
                                          (m.dateKey ??
                                              localDateKey(m.consumedAt)) ==
                                          r.dateKey,
                                    )
                                    .toList(),
                              ),
                            )
                            .length,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (weekly)
          OutlinedButton.icon(
            key: const ValueKey('progress-details'),
            onPressed: () => setState(() => _details = !_details),
            icon: Icon(
              _details ? AppIcons.chartColumnIncreasing : AppIcons.rows3,
            ),
            label: Text(
              _details ? 'Trở về biểu đồ' : 'Chi tiết từng ngày / Mục tiêu',
            ),
          ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          key: const ValueKey('open-weight-progress'),
          onPressed: () => context.push('${AppRoutes.wellness}?tab=5'),
          icon: const Icon(AppIcons.weight),
          label: const Text('Tiến độ cân nặng và ngân sách ăn'),
        ),
        const HealthDisclaimer(),
      ],
    );
  }
}
