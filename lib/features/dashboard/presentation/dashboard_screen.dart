import '../../nutrition_targets/presentation/nutrition_target_card.dart';
import '../../../core/widgets/tracking_page.dart';
import '../../../core/config/app_feature_flags.dart';
import '../../journal/providers/journal_quick_action_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/details_disclosure.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../../activity/models/activity_log.dart';
import '../../activity/providers/activity_providers.dart';
import '../../journal/providers/journal_date_provider.dart';
import '../../journal/presentation/journal_meal_entry.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../nutrition_targets/providers/nutrition_target_providers.dart';
import '../../wellness/providers/energy_providers.dart';
import '../../nutrition_targets/presentation/nutrition_target_form.dart';
import '../../nutrition_targets/presentation/personal_nutrition_planner.dart';
import '../../profile/models/body_metric.dart';
import '../../profile/providers/profile_providers.dart';
import '../../water/models/water_log.dart';
import '../../water/providers/water_providers.dart';
import '../../weekly_reflection/presentation/weekly_reflection_card.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_goals_card.dart';
import 'widgets/mfp_calories_card.dart';
import 'widgets/mfp_macros_card.dart';
import 'widgets/mfp_meal_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime? _selected;
  bool _opening = false;
  void _viewJournal(DateTime day) {
    ref.read(journalDateProvider.notifier).select(day);
    context.go(AppRoutes.journal);
  }

  void _quickEntry(DateTime day, JournalQuickAction action) {
    _viewJournal(day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(journalQuickActionProvider.notifier).request(action);
      }
    });
  }

  Future<void> _enterMeal(DateTime day, MealType type, {MealLog? copy}) async {
    if (_opening) return;
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) return;
    // Keep the auto-disposed catalog alive for this one entry flow only.
    final catalogSubscription = ref.listenManual(
      foodCatalogProvider,
      (_, _) {},
    );
    setState(() => _opening = true);
    try {
      final catalog = await ref
          .read(foodCatalogProvider.future)
          .timeout(const Duration(seconds: 15));
      if (!mounted || ref.read(authSessionProvider).value?.uid != uid) return;
      final now = ref.read(currentLocalTimeProvider)();
      await openJournalMealForm(
        context,
        ref,
        catalog,
        initialConsumedAt: DateTime(
          day.year,
          day.month,
          day.day,
          now.hour,
          now.minute,
        ),
        initialType: type,
        duplicateFrom: copy,
      );
    } catch (error, stack) {
      assert(() {
        debugPrint('Meal entry error: ${error.runtimeType}');
        debugPrintStack(stackTrace: stack);
        return true;
      }());
      if (mounted && ref.read(authSessionProvider).value?.uid == uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa mở được form bữa ăn. Hãy thử lại.'),
          ),
        );
      }
    } finally {
      catalogSubscription.close();
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _quickAddWater(DateTime day) async {
    final now = ref.read(currentLocalTimeProvider)();
    final saved = await ref
        .read(waterControllerProvider.notifier)
        .add(
          WaterLogDraft(
            amountMl: 250,
            consumedAt: DateTime(
              day.year,
              day.month,
              day.day,
              now.hour,
              now.minute,
            ),
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Đã ghi nhanh 250 ml nước.'
              : 'Chưa thể ghi nước. Hãy thử lại.',
        ),
      ),
    );
  }

  void _retry(DateTime day) {
    ref.invalidate(mealLogsProvider(day));
    ref.invalidate(waterLogsProvider(localDateKey(day)));
    ref.invalidate(activityLogsProvider(localDateKey(day)));
    ref.invalidate(latestBodyMetricProvider(day));
  }

  @override
  Widget build(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final now = ref.watch(dashboardClockProvider);
    final today = ref.watch(dashboardTodayProvider);
    final day = _selected ?? today;
    final previous = DateTime(day.year, day.month, day.day - 1);
    final key = localDateKey(day);
    if (localDateKey(ref.read(journalDateProvider)) != key) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && TickerMode.valuesOf(context).enabled) {
          ref.read(journalDateProvider.notifier).select(day);
        }
      });
    }
    final previousMeals = ref.watch(mealLogsProvider(previous));
    final mealsState = ref.watch(mealLogsProvider(day));
    final waterState = ref.watch(waterLogsProvider(key));
    final activityState = ref.watch(activityLogsProvider(key));
    final metricsState = ref.watch(latestBodyMetricProvider(day));
    final targetState = ref.watch(nutritionTargetProvider(key));
    final budgetState = ref.watch(dailyEnergyBudgetProvider(key));
    final budget = !budgetState.isLoading && !budgetState.hasError
        ? budgetState.value
        : null;
    final action = ref.watch(waterControllerProvider);
    final meals = mealsState.value ?? const <MealLog>[];
    final mealReady = !mealsState.isLoading && !mealsState.hasError;
    final totals = mealReady ? totalMealNutrition(meals) : null;
    final water = waterState.value ?? const <WaterLog>[];
    final activities = activityState.value ?? const <ActivityLog>[];
    final metrics = metricsState.value ?? const <BodyMetric>[];
    final latestWeight = _latestWeight(
      metrics
          .where(
            (m) =>
                m.measuredAt.isBefore(localDayRange(day).end) &&
                !m.measuredAt.isAfter(now),
          )
          .toList(),
    );
    final states = [mealsState, waterState, activityState, metricsState];
    final hasError = states.any((s) => s.hasError);
    final theme = Theme.of(context);
    final targetReady = !targetState.isLoading && !targetState.hasError;
    final oldMeals = !previousMeals.isLoading && !previousMeals.hasError
        ? previousMeals.value ?? const <MealLog>[]
        : const <MealLog>[];
    return TrackingPage(
      key: const ValueKey('dashboard-screen'),
      headerHeight: 76,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Hôm nay',
            maxLines: 2,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          InkWell(
            key: const ValueKey('today-date-picker'),
            onTap: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: day,
                firstDate: DateTime(2020),
                lastDate: today,
                helpText: 'Chọn ngày theo dõi',
              );
              if (selected != null && mounted) {
                setState(() => _selected = localDateOnly(selected));
                ref.read(journalDateProvider.notifier).select(selected);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _formatToday(day),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const Icon(Icons.expand_more, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
      children: [
        if (hasError) ...[
          _LoadErrorCard(onRetry: () => _retry(day)),
          const SizedBox(height: 12),
        ],
        MfpCaloriesCard(
          key: const ValueKey('dashboard-today-card'),
          editKey: const ValueKey('today-target-edit'),
          onPersonalize:
              targetReady && targetState.value == null && day == today
              ? () => openPersonalNutritionPlanner(context)
              : null,
          targetStatus: targetState.isLoading || budgetState.isLoading
              ? 'Đang tải mục tiêu dinh dưỡng…'
              : targetState.hasError || budgetState.hasError
              ? 'Chưa tải được mục tiêu.'
              : null,
          consumed: totals?.kcal,
          macros: MfpMacrosCard(
            totals: totals,
            target: targetReady ? targetState.value : null,
            embedded: true,
            showRings: false,
          ),
          target: budget?.kcalTarget,
          budgetNote: budget != null && budget.adjustmentKcal > 0
              ? 'Gốc ${budget.baseTarget.kcalTarget.round()} + bước đã xác nhận ${budget.adjustmentKcal.round()} kcal (ước tính)'
              : budget?.hasUnappliedAdjustment == true
              ? budget!.explanation
              : null,
          onEditTarget: targetReady
              ? () => openNutritionTargetForm(
                  context,
                  ref,
                  key == localDateKey(today) ? targetState.value : null,
                )
              : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('today-add-meal'),
                onPressed: _opening
                    ? null
                    : () => _quickEntry(day, JournalQuickAction.addMeal),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm bữa ăn'),
              ),
            ),
            if (ref.watch(appFeatureFlagsProvider).foodScannerEnabled) ...[
              const SizedBox(width: 8),
              IconButton.filledTonal(
                key: const ValueKey('today-shortcut-scan'),
                tooltip: 'Chụp món ăn',
                onPressed: () => _quickEntry(day, JournalQuickAction.scanFood),
                icon: const Icon(Icons.camera_alt_outlined),
              ),
            ],
          ],
        ),
        if (day != today)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Ghi cho ngày ${DateFormat('dd/MM/yyyy').format(day)}',
              key: const ValueKey('today-entry-date'),
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (targetState.hasError)
          TextButton(
            onPressed: () => ref.invalidate(nutritionTargetProvider(key)),
            child: const Text('Chưa tải được mục tiêu · Thử lại'),
          ),
        if (budgetState.hasError && !targetState.hasError)
          TextButton(
            onPressed: () => retryEnergyBudget(ref, key),
            child: const Text('Chưa tải đủ ngân sách · Thử lại'),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Bữa ăn',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _viewJournal(day),
              child: const Text('Nhật ký'),
            ),
          ],
        ),
        for (final type in MealType.values) ...[
          Builder(
            builder: (context) {
              final entries = meals.where((m) => m.type == type).toList();
              final last = oldMeals.where((m) => m.type == type).firstOrNull;
              final kcal = entries.fold(0.0, (sum, m) => sum + m.totals.kcal);
              return MfpMealCard(
                key: ValueKey('today-meal-${type.name}'),
                icon: switch (type) {
                  MealType.breakfast => Icons.free_breakfast_outlined,
                  MealType.lunch => Icons.lunch_dining_outlined,
                  MealType.dinner => Icons.dinner_dining_outlined,
                  MealType.snack => Icons.cookie_outlined,
                },
                mealName: type.label,
                onLogTap: _opening ? null : () => _enterMeal(day, type),
                summary: !mealReady
                    ? (mealsState.hasError
                          ? 'Chưa tải được bữa ăn'
                          : 'Đang tải…')
                    : entries.isEmpty
                    ? null
                    : '${NumberFormat('#,##0', 'vi').format(kcal)} kcal · ${entries.expand((m) => m.items).map((item) => item.name).take(3).join(', ')}',
                onView: entries.isEmpty ? null : () => _viewJournal(day),
                recentMealHint: last?.items.map((item) => item.name).join(', '),
                onQuickAddTap: last == null || _opening
                    ? null
                    : () => _enterMeal(day, type, copy: last),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        Card(
          key: const ValueKey('today-water-card'),
          child: ListTile(
            leading: const Icon(Icons.water_drop_outlined),
            title: const Text('Nước uống'),
            subtitle: Text(
              waterState.isLoading
                  ? 'Đang tải…'
                  : waterState.hasError
                  ? 'Chưa tải được'
                  : '${NumberFormat.decimalPattern('vi').format(totalWaterMl(water))} ml',
            ),
            onTap: () => _quickEntry(day, JournalQuickAction.addWater),
            trailing: TextButton(
              key: const ValueKey('dashboard-quick-water'),
              onPressed: action.isLoading ? null : () => _quickAddWater(day),
              child: const Text('+250 ml'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        DetailsDisclosure(
          key: const ValueKey('dashboard-details'),
          title: 'Xem thêm',
          builder: (_) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MetricGrid(
                waterMl: totalWaterMl(water),
                waterLoading: waterState.isLoading || waterState.hasError,
                waterActionLoading: action.isLoading,
                onQuickAddWater: () => _quickAddWater(day),
                activityMinutes: totalActivityMinutes(activities),
                activityLoading:
                    activityState.isLoading || activityState.hasError,
                mealCount: meals.length,
                mealLoading: !mealReady,
                latestWeight: latestWeight,
                weightLoading: metricsState.isLoading || metricsState.hasError,
              ),
              const SizedBox(height: 16),
              NutritionTargetCard(day: day, meals: mealsState),
              const SizedBox(height: 16),
              DashboardGoalsCard(
                today: day,
                meals: mealsState,
                water: waterState,
                activity: activityState,
                metrics: metricsState,
              ),
              const SizedBox(height: 16),
              WeeklyReflectionCard(today: today),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const HealthDisclaimer(),
      ],
    );
  }
}

String _formatToday(DateTime date) {
  final formatted = DateFormat('EEEE, d MMMM', 'vi').format(date);
  return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
}

BodyMetric? _latestWeight(List<BodyMetric> metrics) {
  if (metrics.isEmpty) return null;
  return metrics.reduce(
    (latest, current) =>
        current.measuredAt.isAfter(latest.measuredAt) ? current : latest,
  );
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.waterMl,
    required this.waterLoading,
    required this.waterActionLoading,
    required this.onQuickAddWater,
    required this.activityMinutes,
    required this.activityLoading,
    required this.mealCount,
    required this.mealLoading,
    required this.latestWeight,
    required this.weightLoading,
  });

  final int waterMl;
  final bool waterLoading;
  final bool waterActionLoading;
  final VoidCallback onQuickAddWater;
  final int activityMinutes;
  final bool activityLoading;
  final int mealCount;
  final bool mealLoading;
  final BodyMetric? latestWeight;
  final bool weightLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.metricColors;
    final integer = NumberFormat.decimalPattern('vi');
    final decimal = NumberFormat('0.#', 'vi');
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 || textScale < 1.4 ? 2 : 1;
        final width =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        final height = columns == 1 ? 200.0 : 185.0;
        final tiles = [
          MetricTile(
            key: const ValueKey('dashboard-water'),
            title: 'Nước',
            icon: Icons.water_drop_outlined,
            value: waterLoading ? '—' : integer.format(waterMl),
            unit: 'ml',
            accentBackground: colors.waterContainer,
            accentForeground: colors.onWaterContainer,
            action: FilledButton.tonal(
              key: const ValueKey('dashboard-details-water-add'),
              onPressed: waterActionLoading ? null : onQuickAddWater,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('+250 ml'),
            ),
          ),
          MetricTile(
            key: const ValueKey('dashboard-activity'),
            title: 'Vận động',
            icon: Icons.directions_run_rounded,
            value: activityLoading ? '—' : integer.format(activityMinutes),
            unit: 'phút',
            accentBackground: colors.activityContainer,
            accentForeground: colors.onActivityContainer,
          ),
          MetricTile(
            key: const ValueKey('dashboard-meals'),
            title: 'Bữa ăn',
            icon: Icons.restaurant_menu_rounded,
            value: mealLoading ? '—' : integer.format(mealCount),
            unit: 'bữa',
            accentBackground: colors.mealContainer,
            accentForeground: colors.onMealContainer,
          ),
          MetricTile(
            key: const ValueKey('dashboard-weight'),
            title: 'Cân nặng',
            icon: Icons.monitor_weight_outlined,
            value: weightLoading
                ? '—'
                : latestWeight == null
                ? '—'
                : decimal.format(latestWeight!.weightKg),
            unit: latestWeight == null || weightLoading ? '' : 'kg',
            subtitle: latestWeight == null
                ? 'Chưa có lần cân nào'
                : 'Ngày ${DateFormat('dd/MM/yyyy').format(latestWeight!.measuredAt)}',
            accentBackground: colors.weightContainer,
            accentForeground: colors.onWeightContainer,
          ),
        ];
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: width,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: height),
                  child: tile,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LoadErrorCard extends StatelessWidget {
  const _LoadErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppCard(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.sync_problem_rounded,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Một số dữ liệu chưa tải được',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Các phần đã tải thành công vẫn được giữ lại.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ),
        ),
      ],
    ),
  );
}
