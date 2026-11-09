import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../journal/providers/journal_date_provider.dart';
import '../data/wellness_device.dart';
import '../data/wellness_repository.dart';
import '../models/wellness_models.dart';

final wellnessDeviceProvider = Provider<WellnessDevice>(
  (ref) => WellnessDevice(),
);
final wellnessRepositoryProvider = Provider<WellnessRepository>(
  (ref) => WellnessRepository(FirebaseFirestore.instance),
);

class LocalWellnessState {
  const LocalWellnessState({
    this.uid,
    this.available = false,
    this.reminders = defaultMealReminders,
    this.permission = false,
    this.sleepReminder = const SleepReminder(),
  });
  final String? uid;
  final bool available, permission;
  final List<MealReminder> reminders;
  final SleepReminder sleepReminder;
}

final localWellnessProvider =
    AsyncNotifierProvider<LocalWellnessController, LocalWellnessState>(
      LocalWellnessController.new,
    );

class LocalWellnessController extends AsyncNotifier<LocalWellnessState> {
  int _generation = 0;
  int _settingsWrites = 0;
  int _settingsRevision = 0;
  bool _refreshing = false;
  bool _resumePending = false;

  bool _current(String uid, int generation) =>
      ref.mounted &&
      generation == _generation &&
      ref.read(authSessionProvider).value?.uid == uid;

  @override
  Future<LocalWellnessState> build() async {
    final generation = ++_generation;
    final session = ref.watch(authSessionProvider);
    final user = session.value;
    final device = ref.watch(wellnessDeviceProvider);
    if (!device.supported || session.isLoading) {
      return const LocalWellnessState();
    }
    final observer = _WellnessResumeObserver(refreshDeviceState);
    WidgetsBinding.instance.addObserver(observer);
    ref.onDispose(() {
      _generation++;
      WidgetsBinding.instance.removeObserver(observer);
    });
    try {
      final uid = user?.emailVerified == true ? user!.uid : null;
      if (uid != null) {
        // Never reactivate native writers before a server-confirmed deletion
        // check, including after a process restart or on a second device.
        final deletion = await ref.watch(accountDeletionJobProvider.future);
        if (!_current(uid, generation)) {
          return const LocalWellnessState();
        }
        if (deletion != null) {
          await device.clearAccount(uid);
          return const LocalWellnessState();
        }
      }
      await device.setAccount(uid);
      if (uid == null) return const LocalWellnessState();
      return LocalWellnessState(
        uid: uid,
        available: true,
        reminders: await device.readSettings(uid),
        sleepReminder: await device.readSleepReminder(uid),
        permission: await device.notificationsAllowed(),
      );
    } on MissingPluginException {
      return const LocalWellnessState();
    }
  }

  /// Re-read Android permissions and restore alarms after returning from Settings
  /// or a force stop. A resume never replaces an in-flight settings write.
  Future<void> refreshDeviceState() async {
    if (!ref.mounted) return;
    if (_settingsWrites > 0) {
      _resumePending = true;
      return;
    }
    if (_refreshing) {
      _resumePending = true;
      return;
    }
    final previous = state.value;
    final uid = previous?.uid;
    final generation = _generation;
    final settingsRevision = _settingsRevision;
    final deletion = ref.read(accountDeletionJobProvider);
    if (uid == null ||
        previous?.available != true ||
        !_current(uid, generation) ||
        deletion.isLoading ||
        deletion.hasError ||
        deletion.value != null) {
      return;
    }
    _refreshing = true;
    _resumePending = false;
    try {
      final device = ref.read(wellnessDeviceProvider);
      await device.setAccount(uid);
      final reminders = await device.readSettings(uid);
      final sleepReminder = await device.readSleepReminder(uid);
      final permission = await device.notificationsAllowed();
      if (!_current(uid, generation)) return;
      if (_settingsWrites > 0 || settingsRevision != _settingsRevision) {
        _resumePending = true;
        return;
      }
      state = AsyncData(
        LocalWellnessState(
          uid: uid,
          available: true,
          reminders: reminders,
          sleepReminder: sleepReminder,
          permission: permission,
        ),
      );
    } catch (error, stack) {
      if (!_current(uid, generation)) return;
      if (_settingsWrites > 0 || settingsRevision != _settingsRevision) {
        _resumePending = true;
        return;
      }
      state = AsyncError(error, stack);
    } finally {
      _refreshing = false;
      if (_settingsWrites == 0 && _resumePending) {
        _resumePending = false;
        await refreshDeviceState();
      }
    }
  }

  Future<void> saveReminders(List<MealReminder> values) async {
    final uid = ref.read(authSessionProvider).value?.uid;
    final previous = state.value;
    if (uid == null || previous?.uid != uid || previous?.available != true) {
      throw const FormatException('Thiết bị chưa sẵn sàng.');
    }
    final generation = _generation;
    final device = ref.read(wellnessDeviceProvider);
    _settingsRevision++;
    _settingsWrites++;
    try {
      if (values.any((r) => r.enabled) &&
          !await device.requestNotifications()) {
        throw const FormatException(
          'Chưa được cấp quyền thông báo. Bạn có thể bật lại trong cài đặt Android.',
        );
      }
      if (!_current(uid, generation)) return;
      await device.saveSettings(uid, values);
      final permission = await device.notificationsAllowed();
      if (!_current(uid, generation)) return;
      state = AsyncData(
        LocalWellnessState(
          uid: uid,
          available: true,
          reminders: values,
          permission: permission,
          sleepReminder: state.value?.sleepReminder ?? previous!.sleepReminder,
        ),
      );
    } finally {
      _settingsWrites--;
      if (_settingsWrites == 0 && _resumePending) {
        _resumePending = false;
        await refreshDeviceState();
      }
    }
  }

  Future<void> saveSleepReminder(SleepReminder value) async {
    final uid = ref.read(authSessionProvider).value?.uid,
        previous = state.value;
    if (uid == null || previous?.uid != uid || previous?.available != true) {
      throw const FormatException('Thiết bị chưa sẵn sàng.');
    }
    final generation = _generation;
    final device = ref.read(wellnessDeviceProvider);
    _settingsRevision++;
    _settingsWrites++;
    try {
      if (value.enabled && !await device.requestNotifications()) {
        throw const FormatException('Chưa được cấp quyền thông báo.');
      }
      if (!_current(uid, generation)) return;
      await device.saveSleepReminder(uid, value);
      final permission = await device.notificationsAllowed();
      if (!_current(uid, generation)) return;
      state = AsyncData(
        LocalWellnessState(
          uid: uid,
          available: true,
          reminders: state.value?.reminders ?? previous!.reminders,
          sleepReminder: value,
          permission: permission,
        ),
      );
    } finally {
      _settingsWrites--;
      if (_settingsWrites == 0 && _resumePending) {
        _resumePending = false;
        await refreshDeviceState();
      }
    }
  }
}

class _WellnessResumeObserver extends WidgetsBindingObserver {
  _WellnessResumeObserver(this.refresh);
  final Future<void> Function() refresh;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }
}

// One shared current-day query only when reminders are enabled.
final wellnessBootstrapProvider = Provider<void>((ref) {
  final local = ref.watch(localWellnessProvider).value;
  final user = ref.watch(authSessionProvider).value;
  final device = ref.watch(wellnessDeviceProvider);
  final deletion = ref.watch(accountDeletionJobProvider);
  if (deletion.isLoading ||
      deletion.hasError ||
      deletion.value != null ||
      user == null ||
      local?.uid != user.uid ||
      local?.available != true) {
    return;
  }
  Future<void> openJournal() async {
    try {
      if (!await device.takeReminderTap(user.uid) ||
          !ref.mounted ||
          ref.read(authSessionProvider).value?.uid != user.uid) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.mounted &&
            ref.read(authSessionProvider).value?.uid == user.uid) {
          ref
              .read(journalDateProvider.notifier)
              .select(ref.read(currentLocalTimeProvider)());
          ref.read(appRouterProvider).go(AppRoutes.journal);
        }
      });
      WidgetsBinding.instance.scheduleFrame();
    } catch (_) {
      /* No navigation or data on a stale/unsupported tap. */
    }
  }

  Future<void> openSleep() async {
    try {
      if (!await device.takeSleepReminderTap(user.uid) ||
          !ref.mounted ||
          ref.read(authSessionProvider).value?.uid != user.uid) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.mounted &&
            ref.read(authSessionProvider).value?.uid == user.uid) {
          ref.read(appRouterProvider).push('${AppRoutes.wellness}?tab=3');
        }
      });
      WidgetsBinding.instance.scheduleFrame();
    } catch (_) {}
  }

  WellnessDevice.channel.setMethodCallHandler((call) async {
    if (call.method == 'notificationTap') await openJournal();
    if (call.method == 'sleepNotificationTap') await openSleep();
  });
  ref.onDispose(() => WellnessDevice.channel.setMethodCallHandler(null));
  openJournal();
  openSleep();
  if (!local!.reminders.any((r) => r.enabled)) return;
  final day = localDateOnly(ref.watch(localClockProvider));
  final meals = ref.watch(mealLogsProvider(day));
  if (meals.isLoading || meals.hasError || meals.value == null) return;
  device
      .recordMeals(
        user.uid,
        localDateKey(day),
        meals.value!.map((m) => m.type.name).toSet().toList(),
      )
      .catchError((Object _) {});
});

final sleepStartProvider = StreamProvider.autoDispose<DateTime?>((ref) {
  final uid = ref.watch(authSessionProvider).value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(wellnessRepositoryProvider).watchSleepStart(uid);
}, retry: (_, _) => null);
final sleepHistoryProvider = StreamProvider.autoDispose<List<SleepLog>>((ref) {
  final uid = ref.watch(authSessionProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(wellnessRepositoryProvider).watchSleepLogs(uid);
}, retry: (_, _) => null);
final plansProvider = StreamProvider.autoDispose
    .family<List<PlannedMeal>, DateTime>((ref, start) {
      final uid = ref.watch(authSessionProvider).value?.uid;
      if (uid == null) return Stream.value([]);
      return ref.watch(wellnessRepositoryProvider).watchPlans(uid, start);
    }, retry: (_, _) => null);
final stepHistoryProvider = StreamProvider.autoDispose<List<StepDay>>((ref) {
  final uid = ref.watch(authSessionProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(wellnessRepositoryProvider).watchStepDays(uid);
}, retry: (_, _) => null);
