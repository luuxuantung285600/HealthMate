import '../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../auth/providers/auth_providers.dart';
import '../../goals/models/goal_failure.dart';
import '../../activity/providers/activity_providers.dart';
import '../../goals/models/tracking_goal.dart';
import '../../goals/presentation/goal_form_dialog.dart';
import '../../goals/providers/goals_providers.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../../water/providers/water_providers.dart';
import '../models/daily_quest.dart';

class QuestScreen extends ConsumerWidget {
  const QuestScreen({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    DateTime today, {
    TrackingGoal? goal,
  }) async {
    final metrics = ref.read(latestBodyMetricProvider(today)).value;
    final uid = ref.read(authSessionProvider).value?.uid;
    final id = goal?.id ?? ref.read(goalsRepositoryProvider).newGoalId();
    await showDialog<GoalDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AccountBoundDialog(
        child: GoalFormDialog(
          today: today,
          goal: goal,
          errorMessage: () => context.mounted
              ? ref.read(goalActionsProvider).error?.toString()
              : null,
          currentWeightKg: metrics == null || metrics.isEmpty
              ? null
              : metrics.first.weightKg,
          onSave: (draft) =>
              !context.mounted ||
                  ref.read(authSessionProvider).value?.uid != uid
              ? Future.value(false)
              : ref
                    .read(goalActionsProvider.notifier)
                    .save(draft, id: id, create: goal == null),
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TrackingGoal goal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa mục tiêu?'),
        content: const Text('Nhật ký đã ghi và nhiệm vụ hôm nay vẫn được giữ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(goalActionsProvider.notifier).delete(goal.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final today = ref.watch(goalsTodayProvider);
    final key = localDateKey(today);
    final goals = ref.watch(goalsProvider);
    final quest = ref.watch(dailyQuestProvider(key));
    final setup = ref.watch(questSetupProvider(today));
    final action = ref.watch(goalActionsProvider);
    final meals = ref.watch(mealLogsProvider(today));
    final water = ref.watch(waterLogsProvider(key));
    final activity = ref.watch(activityLogsProvider(key));
    final metrics = ref.watch(latestBodyMetricProvider(today));
    final sources = [meals, water, activity, metrics];
    final theme = Theme.of(context);
    AsyncValue<Object?> sourceFor(GoalType type) => switch (type) {
      GoalType.meals => meals,
      GoalType.water => water,
      GoalType.activity => activity,
      GoalType.weight => metrics,
    };
    void retrySources() {
      if (goals.hasError || goals.isLoading) ref.invalidate(goalsProvider);
      if (meals.hasError || meals.isLoading) {
        ref.invalidate(mealLogsProvider(today));
      }
      if (water.hasError || water.isLoading) {
        ref.invalidate(waterLogsProvider(key));
      }
      if (activity.hasError || activity.isLoading) {
        ref.invalidate(activityLogsProvider(key));
      }
      if (metrics.hasError) ref.invalidate(latestBodyMetricProvider(today));
    }

    return FeaturePage(
      showProfileAvatar: true,
      title: 'Nhịp khỏe mỗi ngày',
      subtitle:
          '${DateFormat('dd/MM/yyyy').format(today)} · Ngày theo múi giờ thiết bị (${DateTime.now().timeZoneName}).',
      children: [
        Text(
          'Mục tiêu do bạn tự chọn; ghi nhận thiếu không có nghĩa là bạn chưa ăn, chưa uống hoặc chưa vận động.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        if (action.hasError) ...[
          Text(
            'Chưa thể hoàn tất thao tác. Kiểm tra mạng và thử lại.',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          TextButton(
            onPressed: ref.read(goalActionsProvider.notifier).clearError,
            child: const Text('Đóng thông báo'),
          ),
        ],
        if (quest.hasError || setup.hasError)
          _RetryCard(
            message:
                'Chưa thể tải hoặc tạo nhiệm vụ. Không tạo gợi ý từ dữ liệu chưa tải được.'
                '${setup.error is GoalFailure ? '\n${(setup.error as GoalFailure).message}' : ''}',
            onRetry: () {
              retrySources();
              ref.invalidate(dailyQuestProvider(key));
              ref.invalidate(questSetupProvider(today));
            },
          )
        else if (quest.value != null)
          _QuestCard(
            quest: quest.value!,
            busy: action.isLoading,
            onFinish: (status) =>
                ref.read(goalActionsProvider.notifier).finish(key, status),
            onJournal: () => context.go(AppRoutes.journal),
          )
        else if (setup.isLoading || quest.isLoading)
          const AppCard(child: Center(child: CircularProgressIndicator()))
        else
          _RetryCard(
            message: 'Chưa có nhiệm vụ hôm nay.',
            onRetry: () => ref.invalidate(questSetupProvider(today)),
          ),
        const SizedBox(height: AppSpacing.lg),
        if (sources.any((source) => source.hasError))
          TextButton(
            onPressed: retrySources,
            child: const Text('Tải lại nhật ký để tính tiến độ'),
          ),
        Text('Mục tiêu của bạn', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          key: const ValueKey('add-goal'),
          onPressed: action.isLoading ? null : () => _edit(context, ref, today),
          icon: const Icon(AppIcons.plus),
          label: const Text('Thêm mục tiêu'),
        ),
        const SizedBox(height: AppSpacing.md),
        goals.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _RetryCard(
            message: 'Chưa thể tải mục tiêu.',
            onRetry: () => ref.invalidate(goalsProvider),
          ),
          data: (items) => items.isEmpty
              ? const EmptyState(
                  icon: AppIcons.goals,
                  title: 'Chưa có mục tiêu định lượng',
                  description:
                      'Bấm Thêm mục tiêu để chọn nội dung, giá trị và thời hạn bạn muốn theo dõi. Định hướng trong hồ sơ vẫn được giữ riêng.',
                )
              : Column(
                  children: [
                    for (final goal in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _GoalCard(
                          goal: goal,
                          busy: action.isLoading,
                          loading: sourceFor(goal.draft.type).isLoading,
                          hasError: sourceFor(goal.draft.type).hasError,
                          progress:
                              sourceFor(goal.draft.type).isLoading ||
                                  sourceFor(goal.draft.type).hasError
                              ? null
                              : goalProgress(
                                  goal,
                                  today,
                                  meals: meals.value ?? [],
                                  water: water.value ?? [],
                                  activities: activity.value ?? [],
                                  metrics: metrics.value ?? [],
                                ),
                          onEdit: () => _edit(context, ref, today, goal: goal),
                          onDelete: () => _delete(context, ref, goal),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.quest,
    required this.busy,
    required this.onFinish,
    required this.onJournal,
  });
  final DailyQuest quest;
  final bool busy;
  final ValueChanged<QuestStatus> onFinish;
  final VoidCallback onJournal;
  @override
  Widget build(BuildContext context) => AppCard(
    key: const ValueKey('daily-quest'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Nhiệm vụ hôm nay', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(quest.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${NumberFormat('0.#', 'vi').format(quest.targetValue)} ${quest.unit} · ${quest.status.label}',
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(quest.description),
        const SizedBox(height: AppSpacing.md),
        Text('Vì sao gợi ý này? ${quest.reason}'),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Gợi ý được giữ nguyên trong ngày. Hoàn thành là xác nhận của bạn, không tự tạo nhật ký. Bỏ qua không bị trừ điểm.',
        ),
        if (quest.status == QuestStatus.available) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onJournal, child: const Text('Mở nhật ký')),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton(
                key: const ValueKey('complete-quest'),
                onPressed: busy ? null : () => onFinish(QuestStatus.completed),
                child: const Text('Tôi đã hoàn thành'),
              ),
              TextButton(
                key: const ValueKey('skip-quest'),
                onPressed: busy ? null : () => onFinish(QuestStatus.skipped),
                child: const Text('Bỏ qua hôm nay'),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.busy,
    required this.loading,
    required this.hasError,
    required this.progress,
    required this.onEdit,
    required this.onDelete,
  });
  final TrackingGoal goal;
  final bool busy, loading, hasError;
  final GoalProgress? progress;
  final VoidCallback onEdit, onDelete;
  @override
  Widget build(BuildContext context) {
    final d = goal.draft;
    final number = NumberFormat('0.#', 'vi');
    final date = DateFormat('dd/MM/yyyy');
    final current = progress?.value;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(d.type.label, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${number.format(d.targetValue)} ${d.type.unit}${d.type == GoalType.weight ? '' : ' / ngày'} · ${d.status.label}',
          ),
          Text('${date.format(d.startDate)} – ${date.format(d.endDate)}'),
          if (d.baselineWeightKg != null)
            Text('Ban đầu: ${number.format(d.baselineWeightKg)} kg'),
          const SizedBox(height: AppSpacing.md),
          if (d.status == GoalStatus.active) ...[
            if (loading)
              const LinearProgressIndicator()
            else if (hasError)
              const Text('Chưa tải đủ dữ liệu để tính tiến độ.')
            else ...[
              Text(
                current == null
                    ? progress!.label
                    : '${number.format(current)} ${d.type.unit} · ${progress!.label}',
              ),
              if (progress?.fraction != null) ...[
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(value: progress!.fraction),
              ],
            ],
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              TextButton(
                onPressed: busy ? null : onEdit,
                child: const Text('Chỉnh sửa'),
              ),
              TextButton(
                onPressed: busy ? null : onDelete,
                child: const Text('Xóa mục tiêu'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RetryCard extends StatelessWidget {
  const _RetryCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        Text(message),
        const SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}
