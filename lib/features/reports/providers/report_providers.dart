import '../../../core/data/user_data_revision.dart';
import '../../../core/data/private_data_changes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../nutrition_targets/models/nutrition_target.dart';
import '../../nutrition_targets/providers/nutrition_target_providers.dart';
import '../../water/models/water_log.dart';
import '../../water/providers/water_providers.dart';
import '../../activity/models/activity_log.dart';
import '../../activity/providers/activity_providers.dart';
import '../../profile/models/body_metric.dart';
import '../../profile/providers/profile_providers.dart';
import '../../../core/utils/local_date_key.dart';
import '../models/period_report.dart';
import '../data/day_review_repository.dart';
import '../data/report_range_loader.dart';

final dayReviewRepositoryProvider = Provider<DayReviewRepository>(
  (ref) => FirebaseDayReviewRepository(FirebaseFirestore.instance),
);
String _uid(Ref ref) {
  final uid = ref.watch(authSessionProvider.select((s) => s.value?.uid));
  if (uid == null) throw StateError('Hãy đăng nhập để xem báo cáo.');
  return uid;
}

final periodMealsProvider = FutureProvider.autoDispose
    .family<List<MealLog>, ReportRange>((ref, r) {
      for (final chunk in r.chunks) {
        watchPrivateRange(ref, 'meal_logs', chunk.start, chunk.end);
      }
      ref.watch(
        userDataRevisionProvider.select((state) => state.value?['meal_logs']),
      );
      final uid = _uid(ref);
      final repo = ref.watch(nutritionRepositoryProvider);
      return loadReportRange(
        r,
        (c) => repo.loadRange(uid, c.start, c.end),
        keyOf: (m) => m.id,
        isCurrent: () => ref.mounted,
      );
    }, retry: (_, _) => null);

final periodWaterProvider = FutureProvider.autoDispose
    .family<List<WaterLog>, ReportRange>((ref, r) {
      for (final chunk in r.chunks) {
        watchPrivateRange(ref, 'water_logs', chunk.start, chunk.end);
      }
      ref.watch(
        userDataRevisionProvider.select((state) => state.value?['water_logs']),
      );
      final uid = _uid(ref);
      final repo = ref.watch(waterRepositoryProvider);
      return loadReportRange(
        r,
        (c) => repo.loadRange(uid, c.start, c.end),
        keyOf: (w) => w.id,
        isCurrent: () => ref.mounted,
      );
    }, retry: (_, _) => null);

final periodActivityProvider = FutureProvider.autoDispose
    .family<List<ActivityLog>, ReportRange>((ref, r) {
      for (final chunk in r.chunks) {
        watchPrivateRange(ref, 'activity_logs', chunk.start, chunk.end);
      }
      ref.watch(
        userDataRevisionProvider.select(
          (state) => state.value?['activity_logs'],
        ),
      );
      final uid = _uid(ref);
      final repo = ref.watch(activityRepositoryProvider);
      return loadReportRange(
        r,
        (c) => repo.loadRange(uid, c.start, c.end),
        keyOf: (a) => a.id,
        isCurrent: () => ref.mounted,
      );
    }, retry: (_, _) => null);

final periodMetricsProvider = FutureProvider.autoDispose
    .family<List<BodyMetric>, ReportRange>((ref, r) {
      for (final chunk in r.chunks) {
        watchPrivateRange(ref, 'body_metrics', chunk.start, chunk.end);
      }
      ref.watch(
        userDataRevisionProvider.select(
          (state) => state.value?['body_metrics'],
        ),
      );
      final uid = _uid(ref);
      final repo = ref.watch(healthProfileRepositoryProvider);
      return loadReportRange(
        r,
        (c) => repo.loadBodyMetricsRange(uid, c.start, c.end),
        keyOf: (m) => m.id,
        isCurrent: () => ref.mounted,
      );
    }, retry: (_, _) => null);

final periodTargetsProvider = FutureProvider.autoDispose
    .family<List<NutritionTarget>, ReportRange>((ref, r) {
      for (final chunk in r.chunks) {
        watchPrivateRange(ref, 'nutrition_targets', chunk.start, chunk.end);
      }
      ref.watch(
        userDataRevisionProvider.select(
          (state) => state.value?['nutrition_targets'],
        ),
      );
      final uid = _uid(ref);
      final repo = ref.watch(nutritionTargetRepositoryProvider);
      return loadReportRange(
        r,
        (c) =>
            repo.loadForRange(uid, localDateKey(c.start), localDateKey(c.end)),
        keyOf: (t) => t.effectiveFromDateKey,
        isCurrent: () => ref.mounted,
      );
    }, retry: (_, _) => null);

final dayReviewsProvider = FutureProvider.autoDispose
    .family<List<DayReview>, ReportRange>((ref, r) {
      for (final chunk in r.chunks) {
        watchPrivateRange(ref, 'day_reviews', chunk.start, chunk.end);
      }
      ref.watch(
        userDataRevisionProvider.select((state) => state.value?['day_reviews']),
      );
      final uid = _uid(ref);
      final repo = ref.watch(dayReviewRepositoryProvider);
      return loadReportRange(
        r,
        (c) => repo.load(uid, c),
        keyOf: (d) => d.dateKey,
        isCurrent: () => ref.mounted,
      );
    }, retry: (_, _) => null);
