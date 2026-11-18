import '../../../core/utils/subscription_stream.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../../journal/models/daily_log_failure.dart';
import '../data/firebase_water_repository.dart';
import '../data/water_repository.dart';
import '../models/water_log.dart';

final waterRepositoryProvider = Provider<WaterRepository>(
  (ref) => FirebaseWaterRepository(FirebaseFirestore.instance),
);

final waterLogsProvider = StreamProvider.autoDispose
    .family<List<WaterLog>, String>((ref, dateKey) async* {
      final user = ref.watch(authSessionProvider).value;
      if (user == null) {
        yield const [];
        return;
      }
      yield* subscriptionStream(
        ref.watch(waterRepositoryProvider).watchLogs(user.uid, dateKey),
      );
    }, retry: (_, _) => null);

final waterControllerProvider =
    NotifierProvider<WaterController, AsyncValue<void>>(WaterController.new);

class WaterEntryReceipt {
  const WaterEntryReceipt._(this.uid, this.logId, this.draft, this._generation);
  final String uid, logId;
  final WaterLogDraft draft;
  final int _generation;
}

class WaterController extends Notifier<AsyncValue<void>> {
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

  Future<bool> add(WaterLogDraft draft) => _perform((user) async {
    await ref.read(waterRepositoryProvider).add(uid: user.uid, draft: draft);
  });

  Future<WaterEntryReceipt?> addWithReceipt(WaterLogDraft draft) async {
    WaterEntryReceipt? receipt;
    final generation = _generation;
    final saved = await _perform((user) async {
      final id = await ref
          .read(waterRepositoryProvider)
          .add(uid: user.uid, draft: draft);
      receipt = WaterEntryReceipt._(user.uid, id, draft, generation);
    });
    return saved ? receipt : null;
  }

  Future<bool> undoAdd(WaterEntryReceipt receipt) {
    if (receipt._generation != _generation ||
        ref.read(authSessionProvider).value?.uid != receipt.uid) {
      return Future.value(false);
    }
    return _perform(
      (user) => ref
          .read(waterRepositoryProvider)
          .undoAdd(uid: user.uid, logId: receipt.logId, draft: receipt.draft),
    );
  }

  Future<bool> update(String id, WaterLogDraft draft) => _perform((user) {
    return ref
        .read(waterRepositoryProvider)
        .update(uid: user.uid, logId: id, draft: draft);
  });

  Future<bool> delete(String id) => _perform((user) {
    return ref.read(waterRepositoryProvider).delete(uid: user.uid, logId: id);
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
