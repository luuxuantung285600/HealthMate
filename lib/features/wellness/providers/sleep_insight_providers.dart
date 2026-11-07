import '../../../core/data/user_data_revision.dart';
import '../../../core/data/private_data_changes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../reports/models/period_report.dart';
import '../models/wellness_models.dart';
import 'wellness_providers.dart';

final sleepRangeProvider = FutureProvider.autoDispose
    .family<List<SleepLog>, ReportRange>((ref, range) {
      watchPrivateRange(ref, 'sleep_logs', range.start, range.end);
      ref.watch(
        userDataRevisionProvider.select((state) => state.value?['sleep_logs']),
      );
      final user = ref.watch(authSessionProvider).value;
      if (user?.emailVerified != true) return Future.value([]);
      return ref
          .watch(wellnessRepositoryProvider)
          .loadSleepRange(user!.uid, range.start, range.end)
          .timeout(const Duration(seconds: 20));
    }, retry: (_, _) => null);
