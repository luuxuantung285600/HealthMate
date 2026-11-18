import '../../../core/utils/subscription_stream.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../../journal/models/daily_log_failure.dart';
import '../data/activity_repository.dart';
import '../data/firebase_activity_repository.dart';
import '../models/activity_log.dart';

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => FirebaseActivityRepository(FirebaseFirestore.instance),
);

final activityLogsProvider = StreamProvider.autoDispose
    .family<List<ActivityLog>, String>((ref, dateKey) {
      final user = ref.watch(authSessionProvider).value;
      if (user == null) {
        return Stream.value(const []);
      }
      return subscriptionStream(
        ref.watch(activityRepositoryProvider).watchLogs(user.uid, dateKey),
      );
    }, retry: (_, _) => null);

final activityControllerProvider =
    NotifierProvider<ActivityController, AsyncValue<void>>(
      ActivityController.new,
    );

class ActivityController extends Notifier<AsyncValue<void>> {
  int _generation = 0;
  @override
  AsyncValue<void> build() {
    ref.watch(authSessionProvider.select((s) => s.value?.uid));
    _generation++;
    return const AsyncData(null);
  }

  void clearError() {
    if (!state.isLoading) state = const AsyncData(null);
  }

  Future<bool> add(ActivityLogDraft draft, {String? operationId}) =>
      _perform((user) async {
        await ref
            .read(activityRepositoryProvider)
            .add(uid: user.uid, draft: draft, operationId: operationId);
      });

  Future<bool> update(String id, ActivityLogDraft draft) => _perform((user) {
    return ref
        .read(activityRepositoryProvider)
        .update(uid: user.uid, logId: id, draft: draft);
  });

  Future<bool> delete(String id) => _perform((user) {
    return ref
        .read(activityRepositoryProvider)
        .delete(uid: user.uid, logId: id);
  });

  Future<bool> _perform(Future<void> Function(AuthUser user) operation) async {
    if (state.isLoading) return false;
    final user = ref.read(authSessionProvider).value;
    if (user == null) {
      state = AsyncError(
        const DailyLogFailure('Phiên đăng nhập đã hết hạn.'),
        StackTrace.current,
      );
      return false;
    }
    final generation = _generation;
    bool current() =>
        ref.mounted &&
        generation == _generation &&
        ref.read(authSessionProvider).value?.uid == user.uid;
    state = const AsyncLoading();
    try {
      await operation(user);
      if (!current()) return false;
      state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (current()) {
        state = AsyncError(
          error is DailyLogFailure
              ? error
              : DailyLogFailure.fromCode('unknown'),
          stack,
        );
      }
      return false;
    }
  }
}
