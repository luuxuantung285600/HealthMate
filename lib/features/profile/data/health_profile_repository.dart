import '../models/body_metric.dart';
import '../models/onboarding_draft.dart';
import '../models/user_profile.dart';
import '../models/profile_appearance.dart';

abstract interface class HealthProfileRepository {
  Future<void> ensureProfile({required String uid, required String email});

  Stream<UserProfile?> watchProfile(String uid);

  /// Atomically changes identity without rewriting health measurements or goals.
  Future<void> updateIdentity({
    required String uid,
    required ProfileIdentityDraft draft,
  });

  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required double heightCm,
    required DateTime birthDate,
    required String healthGoal,
    required double? targetWeightKg,
  });

  Future<void> completeOnboarding({
    required String uid,
    required OnboardingDraft draft,
  });

  /// The first 25 newest measurements; never an unbounded history query.
  Stream<List<BodyMetric>> watchBodyMetrics(String uid);

  Stream<BodyMetricPage> watchBodyMetricPage(
    String uid, {
    BodyMetricCursor? after,
    int pageSize = 25,
  });

  /// One first-ever record for goal baseline, independently of history pages.
  Stream<List<BodyMetric>> watchFirstBodyMetric(String uid);

  Stream<List<BodyMetric>> watchLatestBodyMetric(
    String uid,
    DateTime day, {
    bool atOrBefore = false,
  });

  Future<List<BodyMetric>> loadBodyMetricsRange(
    String uid,
    DateTime start,
    DateTime end,
  );

  Future<String> addBodyMetric({
    required String uid,
    required BodyMetricDraft draft,
  });

  Future<void> updateBodyMetric({
    required String uid,
    required String metricId,
    required BodyMetricDraft draft,
  });

  Future<void> deleteBodyMetric({
    required String uid,
    required String metricId,
  });
}
