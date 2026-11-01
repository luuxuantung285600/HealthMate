import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/design_illustration.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../core/widgets/tracking_page.dart';
import '../../../core/widgets/reference_shortcuts.dart';
import '../../../core/widgets/recorded_sparkline.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../activity/models/activity_log.dart';
import '../../activity/providers/activity_providers.dart';
import '../../journal/providers/journal_date_provider.dart';
import '../../water/models/water_log.dart';
import '../../water/providers/water_providers.dart';
import '../providers/wellness_providers.dart';

class WellnessHub extends ConsumerWidget {
  const WellnessHub({required this.onOpen, super.key});
  final ValueChanged<int> onOpen;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final today = localDateOnly(ref.watch(localClockProvider));
    final date = localDateKey(today);
    final steps = ref.watch(stepHistoryProvider);
    final sleep = ref.watch(sleepHistoryProvider);
    final active = ref.watch(sleepStartProvider);
    final water = ref.watch(waterLogsProvider(date));
    final activity = ref.watch(activityLogsProvider(date));
    final format = NumberFormat.decimalPattern('vi');
    final step = !steps.isLoading && !steps.hasError
        ? steps.value?.where((s) => s.day == date).firstOrNull
        : null;
    final lastSleep = !sleep.isLoading && !sleep.hasError
        ? sleep.value
              ?.where((s) => !s.end.isAfter(today.add(const Duration(days: 1))))
              .fold<Duration?>(null, (value, s) => value ?? s.duration)
        : null;
    String stateLabel(AsyncValue<Object?> state, String empty) => state.hasError
        ? 'Chưa tải được · xem chi tiết'
        : state.isLoading
        ? 'Đang tải…'
        : empty;
    void journal() {
      ref.read(journalDateProvider.notifier).select(today);
      context.go(AppRoutes.journal);
    }

    final tiles = <Widget>[
      HabitMetricCard(
        minHeight: 195,
        key: const ValueKey('hub-steps'),
        title: 'Bước chân',
        art: 'steps',
        value: step == null ? '—' : format.format(step.steps),
        subtitle: stateLabel(
          steps,
          step == null
              ? 'Chưa có bước đã đồng bộ hôm nay'
              : 'bước đã ghi hôm nay',
        ),
        onTap: () => onOpen(2),
        chart: RecordedSparkline(
          values:
              steps.value?.reversed.map((s) => s.steps.toDouble()).toList() ??
              [],
          color: Theme.of(context).colorScheme.primary,
          bars: true,
        ),
      ),
      HabitMetricCard(
        minHeight: 195,
        key: const ValueKey('hub-sleep'),
        title: 'Giấc ngủ',
        art: 'moon',
        value: !active.hasError && !active.isLoading && active.value != null
            ? 'Đang ngủ'
            : lastSleep == null
            ? '—'
            : '${lastSleep.inHours}g ${lastSleep.inMinutes % 60}p',
        subtitle: active.hasError
            ? 'Chưa tải được lần ngủ đang ghi'
            : stateLabel(
                sleep,
                lastSleep == null
                    ? 'Bấm ngủ/dậy hoặc nhập giờ'
                    : 'giờ · tự ghi nhận',
              ),
        onTap: () => onOpen(3),
        chart: RecordedSparkline(
          values:
              sleep.value?.reversed
                  .map((s) => s.duration.inMinutes / 60)
                  .toList() ??
              [],
          color: const Color(0xFF9D94FF),
          bars: true,
        ),
      ),
      HabitMetricCard(
        minHeight: 195,
        title: 'Nước uống',
        art: 'water',
        value:
            water.isLoading || water.hasError || (water.value?.isEmpty ?? true)
            ? '—'
            : format.format(totalWaterMl(water.value ?? const <WaterLog>[])),
        subtitle: stateLabel(
          water,
          (water.value?.isEmpty ?? true)
              ? 'Chưa ghi nước hôm nay'
              : 'ml đã ghi hôm nay',
        ),
        onTap: journal,
      ),
      HabitMetricCard(
        minHeight: 195,
        title: 'Vận động',
        art: 'activity',
        value:
            activity.isLoading ||
                activity.hasError ||
                (activity.value?.isEmpty ?? true)
            ? '—'
            : format.format(
                totalActivityMinutes(activity.value ?? const <ActivityLog>[]),
              ),
        subtitle: stateLabel(
          activity,
          (activity.value?.isEmpty ?? true)
              ? 'Chưa ghi vận động hôm nay'
              : 'phút đã ghi hôm nay',
        ),
        onTap: journal,
      ),
    ];
    return TrackingPage(
      key: const ValueKey('wellness-hub'),
      headerHeight: 90,
      showProfileAvatar: !context.canPop(),
      header: Row(
        children: [
          if (context.canPop())
            BackButton(
              key: const ValueKey('wellness-back'),
              onPressed: () => context.pop(),
            ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thói quen của bạn',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  DateFormat('EEEE, dd/MM', 'vi').format(today),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final columns =
                c.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.4
                ? 1
                : 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final tile in tiles)
                  SizedBox(
                    width: (c.maxWidth - 12 * (columns - 1)) / columns,
                    child: tile,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Text(
          'Thói quen & kế hoạch',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ReferenceShortcuts(
          entries: [
            (
              label: 'Nhắc bữa',
              art: 'sun',
              key: const ValueKey('hub-open-0'),
              onTap: () => onOpen(0),
            ),
            (
              label: 'Thực đơn',
              art: 'food',
              key: const ValueKey('hub-open-1'),
              onTap: () => onOpen(1),
            ),
            (
              label: 'Dưỡng chất',
              art: 'heart',
              key: const ValueKey('hub-open-4'),
              onTap: () => onOpen(4),
            ),
            (
              label: 'Cân nặng',
              art: 'weight',
              key: const ValueKey('hub-open-5'),
              onTap: () => onOpen(5),
            ),
            (
              label: 'Mục tiêu',
              art: 'flag',
              key: null,
              onTap: () => context.go(AppRoutes.quest),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const HealthDisclaimer(),
      ],
    );
  }
}

class HabitMetricCard extends StatelessWidget {
  const HabitMetricCard({
    required this.title,
    required this.art,
    required this.value,
    required this.subtitle,
    required this.onTap,
    this.chart,
    this.minHeight = 192,
    super.key,
  });
  final String title, art, value, subtitle;
  final VoidCallback onTap;
  final Widget? chart;
  final double minHeight;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minHeight: minHeight),
    child: AppCard(
      padding: const EdgeInsets.all(13),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: DesignIllustration(art, size: 26),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 29,
              height: 1.2,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          chart ?? const SizedBox(height: 28),
        ],
      ),
    ),
  );
}
