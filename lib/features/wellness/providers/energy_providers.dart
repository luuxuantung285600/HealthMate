import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../activity/providers/activity_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../nutrition_targets/providers/nutrition_target_providers.dart';
import '../data/energy_repository.dart';
import '../models/energy_budget.dart';

final energyRepositoryProvider = Provider<EnergyRepository>(
  (ref) => FirebaseEnergyRepository(
    FirebaseFirestore.instance,
    now: ref.watch(currentLocalTimeProvider),
  ),
);
final wellnessPreferencesProvider =
    StreamProvider.autoDispose<WellnessPreferences>((ref) {
      final user = ref.watch(authSessionProvider).value;
      if (user?.emailVerified != true) {
        return Stream.value(const WellnessPreferences());
      }
      return ref.watch(energyRepositoryProvider).watchPreferences(user!.uid);
    }, retry: (_, _) => null);
final energyAdjustmentProvider = StreamProvider.autoDispose
    .family<EnergyAdjustment?, String>((ref, day) {
      final user = ref.watch(authSessionProvider).value;
      if (user?.emailVerified != true) return Stream.value(null);
      return ref
          .watch(energyRepositoryProvider)
          .watchAdjustment(user!.uid, day);
    }, retry: (_, _) => null);

final dailyEnergyBudgetProvider = Provider.autoDispose
    .family<AsyncValue<DailyEnergyBudget?>, String>((ref, day) {
      final target = ref.watch(nutritionTargetProvider(day));
      if (target.isLoading) return const AsyncLoading();
      if (target.hasError) {
        return AsyncError(
          target.error!,
          target.stackTrace ?? StackTrace.current,
        );
      }
      if (target.value == null) return const AsyncData(null);
      final adjustment = ref.watch(energyAdjustmentProvider(day));
      if (adjustment.isLoading) return const AsyncLoading();
      if (adjustment.hasError) {
        return AsyncError(
          adjustment.error!,
          adjustment.stackTrace ?? StackTrace.current,
        );
      }
      final activities = ref.watch(activityLogsProvider(day));
      if (activities.isLoading) return const AsyncLoading();
      if (activities.hasError) {
        return AsyncError(
          activities.error!,
          activities.stackTrace ?? StackTrace.current,
        );
      }
      return AsyncData(
        resolveEnergyBudget(
          target.value!,
          adjustment.value,
          hasManualActivity: activities.value!.isNotEmpty,
          activities: activities.value!,
        ),
      );
    });

void retryEnergyBudget(WidgetRef ref, String day) {
  ref.invalidate(energyAdjustmentProvider(day));
  ref.invalidate(activityLogsProvider(day));
  ref.invalidate(nutritionTargetProvider(day));
}
