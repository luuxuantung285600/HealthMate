import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/user_data_revision.dart';
import '../../../core/data/private_data_changes.dart';
import '../../auth/providers/auth_providers.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../water/providers/water_providers.dart';
import '../../activity/providers/activity_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../models/weekly_reflection.dart';

// One future per UID/week, shared by all consumers. No per-day listeners.
final weeklyLogsProvider = FutureProvider.autoDispose
    .family<WeekLogs, DateTime>((ref, start) async {
      final end = DateTime(start.year, start.month, start.day + 7);
      for (final source in [
        'meal_logs',
        'water_logs',
        'activity_logs',
        'body_metrics',
      ]) {
        watchPrivateRange(ref, source, start, end);
      }
      ref.watch(
        userDataRevisionProvider.select(
          (state) => (
            state.value?['meal_logs'],
            state.value?['water_logs'],
            state.value?['activity_logs'],
            state.value?['body_metrics'],
          ),
        ),
      );
      final uid = ref.watch(
        authSessionProvider.select((session) => session.value?.uid),
      );
      if (uid == null) throw StateError('Cần đăng nhập để xem báo cáo.');
      final nutrition = ref.watch(nutritionRepositoryProvider);
      final water = ref.watch(waterRepositoryProvider);
      final activity = ref.watch(activityRepositoryProvider);
      final profile = ref.watch(healthProfileRepositoryProvider);
      final data = await (
        nutrition.loadRange(uid, start, end),
        water.loadRange(uid, start, end),
        activity.loadRange(uid, start, end),
        profile.loadBodyMetricsRange(uid, start, end),
      ).wait.timeout(const Duration(seconds: 15));
      return WeekLogs(
        meals: data.$1,
        water: data.$2,
        activities: data.$3,
        loadedAt: DateTime.now(),
        metrics: data.$4,
      );
    }, retry: (_, _) => null);
