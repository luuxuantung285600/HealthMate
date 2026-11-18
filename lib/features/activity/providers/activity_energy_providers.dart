import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/models/body_metric.dart';
import '../../profile/providers/profile_providers.dart';

/// A bounded one-document query, excluding measurements after the activity.
final activityWeightProvider = StreamProvider.autoDispose
    .family<List<BodyMetric>, DateTime>((ref, at) {
      final user = ref.watch(authSessionProvider).value;
      if (user?.emailVerified != true) return Stream.value(const []);
      return ref
          .watch(healthProfileRepositoryProvider)
          .watchLatestBodyMetric(user!.uid, at, atOrBefore: true);
    }, retry: (_, _) => null);
