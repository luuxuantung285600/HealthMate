import '../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../core/widgets/app_card.dart';
import '../../activity/models/activity_log.dart';
import '../../goals/models/tracking_goal.dart';
import '../../goals/providers/goals_providers.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../profile/models/body_metric.dart';
import '../../water/models/water_log.dart';

class DashboardGoalsCard extends ConsumerWidget {
  const DashboardGoalsCard({
    required this.today,
    required this.meals,
    required this.water,
    required this.activity,
    required this.metrics,
    super.key,
  });
  final DateTime today;
  final AsyncValue<List<MealLog>> meals;
  final AsyncValue<List<WaterLog>> water;
  final AsyncValue<List<ActivityLog>> activity;
  final AsyncValue<List<BodyMetric>> metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final key = localDateKey(today);
    final quest = ref.watch(dailyQuestProvider(key));
    AsyncValue<Object?> source(GoalType type) => switch (type) {
      GoalType.meals => meals,
      GoalType.water => water,
      GoalType.activity => activity,
      GoalType.weight => metrics,
    };
    return AppCard(
      key: const ValueKey('dashboard-goals'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mục tiêu · ${DateFormat('dd/MM').format(today)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          goals.when(
            skipLoadingOnRefresh: false,
            skipError: false,
            loading: () => const Text('Đang tải mục tiêu…'),
            error: (_, _) => TextButton(
              onPressed: () => ref.invalidate(goalsProvider),
              child: const Text('Thử lại mục tiêu'),
            ),
            data: (items) {
              final active = items
                  .where((goal) => goal.appliesOn(today))
                  .toList();
              if (active.isEmpty) {
                return const Text(
                  'Chưa có mục tiêu đang theo dõi trong ngày này. Bạn có thể tự chọn mục tiêu phù hợp.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final goal in active.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Builder(
                        builder: (_) {
                          final state = source(goal.draft.type);
                          if (state.isLoading || state.hasError) {
                            return Text(
                              '${goal.draft.type.label}: — (${state.hasError ? 'chưa tải được' : 'đang tải'})',
                            );
                          }
                          final p = goalProgress(
                            goal,
                            today,
                            meals: meals.value ?? [],
                            water: water.value ?? [],
                            activities: activity.value ?? [],
                            metrics: metrics.value ?? [],
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${goal.draft.type.label}: ${p.value == null ? '—' : NumberFormat('0.#', 'vi').format(p.value)} / ${NumberFormat('0.#', 'vi').format(goal.draft.targetValue)} ${goal.draft.type.unit}',
                              ),
                              if (p.fraction != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                LinearProgressIndicator(value: p.fraction),
                              ],
                              Text(
                                p.label,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  if (active.length > 3)
                    Text(
                      'Còn ${active.length - 3} mục tiêu. Mở trang mục tiêu để xem đầy đủ.',
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nhiệm vụ · ${DateFormat('dd/MM').format(today)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          quest.when(
            skipLoadingOnRefresh: false,
            skipError: false,
            loading: () => const Text('Đang tải nhiệm vụ…'),
            error: (_, _) => TextButton(
              onPressed: () => ref.invalidate(dailyQuestProvider(key)),
              child: const Text('Thử lại nhiệm vụ'),
            ),
            data: (value) => Text(
              value == null
                  ? 'Mở trang nhiệm vụ để xem gợi ý.'
                  : '${value.title} · ${value.status.label}',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            key: const ValueKey('dashboard-open-goals'),
            onPressed: () => context.go(AppRoutes.quest),
            icon: const Icon(AppIcons.goals),
            label: const Text('Mở mục tiêu và nhiệm vụ'),
          ),
        ],
      ),
    );
  }
}
