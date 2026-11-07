import '../../../core/data/user_data_revision.dart';
import '../../../core/data/private_data_changes.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../../core/utils/local_date_key.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/firebase_nutrition_target_repository.dart';
import '../data/nutrition_target_repository.dart';
import '../models/nutrition_target.dart';

final nutritionTargetRepositoryProvider = Provider<NutritionTargetRepository>(
  (ref) => FirebaseNutritionTargetRepository(
    FirebaseFirestore.instance,
    now: ref.watch(currentLocalTimeProvider),
  ),
);

final nutritionTargetProvider = FutureProvider.autoDispose
    .family<NutritionTarget?, String>((ref, key) async {
      watchPrivateScope(ref, privateTargetScope(key));
      ref.watch(
        userDataRevisionProvider.select(
          (state) => state.value?['nutrition_targets'],
        ),
      );
      final uid = ref.watch(authSessionProvider.select((s) => s.value?.uid));
      if (uid == null) {
        throw const NutritionTargetFailure('Hãy đăng nhập để tải mục tiêu.');
      }
      return ref
          .watch(nutritionTargetRepositoryProvider)
          .loadForDay(uid, key)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw const NutritionTargetFailure(
              'Tải mục tiêu quá thời gian chờ. Hãy thử lại.',
            ),
          );
    }, retry: (_, _) => null);

// Separate from logs: unavailable targets must not hide verified diary totals.
final weeklyNutritionTargetsProvider = FutureProvider.autoDispose
    .family<List<NutritionTarget>, DateTime>((ref, start) async {
      watchPrivateRange(
        ref,
        'nutrition_targets',
        start,
        DateTime(start.year, start.month, start.day + 7),
      );
      ref.watch(
        userDataRevisionProvider.select(
          (state) => state.value?['nutrition_targets'],
        ),
      );
      final uid = ref.watch(authSessionProvider.select((s) => s.value?.uid));
      if (uid == null) throw const NutritionTargetFailure('Hãy đăng nhập.');
      return ref
          .watch(nutritionTargetRepositoryProvider)
          .loadForRange(
            uid,
            localDateKey(start),
            localDateKey(DateTime(start.year, start.month, start.day + 7)),
          )
          .timeout(const Duration(seconds: 15));
    }, retry: (_, _) => null);

final nutritionTargetControllerProvider =
    NotifierProvider<NutritionTargetController, AsyncValue<void>>(
      NutritionTargetController.new,
    );

class NutritionTargetController extends Notifier<AsyncValue<void>> {
  int _generation = 0;
  @override
  AsyncValue<void> build() {
    ref.watch(authSessionProvider.select((s) => s.value?.uid));
    _generation++;
    return const AsyncData(null);
  }

  Future<bool> save(NutritionTarget target) async {
    if (state.isLoading) return false;
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) return false;
    final generation = _generation;
    bool current() =>
        ref.mounted &&
        _generation == generation &&
        ref.read(authSessionProvider).value?.uid == uid;
    final error = target.validate(earliestDateKey: _today());
    if (error != null) {
      state = AsyncError(NutritionTargetFailure(error), StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    try {
      await ref.read(nutritionTargetRepositoryProvider).save(uid, target);
      if (!current()) return false;
      ref.invalidate(nutritionTargetProvider);
      ref.invalidate(weeklyNutritionTargetsProvider);
      state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (current()) {
        state = AsyncError(
          error is NutritionTargetFailure
              ? error
              : const NutritionTargetFailure(),
          stack,
        );
      }
      return false;
    }
  }

  String _today() {
    return localDateKey(ref.read(currentLocalTimeProvider)());
  }
}
