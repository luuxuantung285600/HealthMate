import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../providers/profile_providers.dart';

/// Profile identity and the user's chosen goal. Daily journals belong in Diary.
class PersonalOverview extends ConsumerWidget {
  const PersonalOverview({required this.onEdit, super.key});
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userProfileProvider);
    final user = !state.isLoading && !state.hasError ? state.value : null;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProfileAvatar(size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName.isNotEmpty == true
                        ? user!.displayName
                        : 'Hồ sơ của bạn',
                    style: theme.textTheme.titleLarge,
                  ),
                  if (user?.email.isNotEmpty == true)
                    Text(user!.email, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const ValueKey('edit-profile'),
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Chỉnh sửa hồ sơ'),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Mục tiêu của bạn', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                state.isLoading
                    ? 'Đang tải mục tiêu…'
                    : state.hasError
                    ? 'Chưa tải được mục tiêu. Thử lại ở phần Hồ sơ.'
                    : user?.healthGoal?.label ?? 'Chưa chọn mục tiêu sức khỏe',
              ),
              if (user?.healthGoal?.needsTargetWeight == true &&
                  user?.targetWeightKg != null) ...[
                Text(
                  'Cân nặng mục tiêu: ${NumberFormat('0.###############', 'vi').format(user!.targetWeightKg)} kg',
                ),
                const SizedBox(height: 8),
                _WeightGoalProgress(target: user.targetWeightKg!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _WeightGoalProgress extends ConsumerWidget {
  const _WeightGoalProgress({required this.target});
  final double target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final first = ref.watch(firstBodyMetricProvider);
    final latest = ref.watch(
      latestBodyMetricProvider(localDateOnly(ref.watch(localClockProvider))),
    );
    if (first.isLoading || latest.isLoading) {
      return const Text('Đang tải tiến độ cân nặng…');
    }
    if (first.hasError || latest.hasError) {
      return TextButton.icon(
        onPressed: () {
          ref.invalidate(firstBodyMetricProvider);
          ref.invalidate(latestBodyMetricProvider);
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Thử lại tiến độ cân nặng'),
      );
    }
    final baseline = first.value?.firstOrNull;
    final current = latest.value?.firstOrNull;
    final distance = baseline == null ? null : baseline.weightKg - target;
    final progress =
        baseline == null ||
            current == null ||
            baseline.id == current.id ||
            distance == null ||
            distance == 0
        ? null
        : ((baseline.weightKg - current.weightKg) / distance).clamp(0.0, 1.0);
    if (progress == null) {
      return const Text('Chưa đủ lần cân để tính tiến độ mục tiêu.');
    }
    final label =
        'Tiến độ so với lần cân đầu tiên đã ghi: ${(progress * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress, semanticsLabel: label),
      ],
    );
  }
}
