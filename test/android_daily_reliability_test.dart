import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/activity/providers/activity_providers.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/nutrition_targets/providers/nutrition_target_providers.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/wellness/data/wellness_device.dart';
import 'package:healthmate/features/wellness/data/wellness_repository.dart';
import 'package:healthmate/features/wellness/models/energy_budget.dart';
import 'package:healthmate/features/wellness/models/wellness_models.dart';
import 'package:healthmate/features/wellness/presentation/wellness_screen.dart';
import 'package:healthmate/features/wellness/providers/energy_providers.dart';
import 'package:healthmate/features/wellness/providers/wellness_providers.dart';
import 'package:healthmate/shared/providers/local_clock_provider.dart';

import 'support/fake_account_data_repository.dart';
import 'support/fake_auth_repository.dart';

class _Device extends WellnessDevice {
  _Device(this.now);
  final DateTime Function() now;
  bool permission = false;
  int reads = 0, schedules = 0, count = 100;
  String? active;
  Completer<void>? saveGate;
  Completer<void>? sleepReadGate;
  final settings = <String, List<MealReminder>>{};
  @override
  bool get supported => true;
  @override
  Future<void> setAccount(String? uid) async {
    active = uid;
    schedules++;
  }

  @override
  Future<List<MealReminder>> readSettings(String uid) async =>
      settings[uid] ?? defaultMealReminders;
  @override
  Future<SleepReminder> readSleepReminder(String uid) async {
    if (sleepReadGate != null) await sleepReadGate!.future;
    return const SleepReminder();
  }

  @override
  Future<bool> notificationsAllowed() async => permission;
  @override
  Future<bool> requestNotifications() async => permission;
  @override
  Future<bool> takeReminderTap(String uid) async => false;
  @override
  Future<bool> takeSleepReminderTap(String uid) async => false;
  @override
  Future<void> recordMeals(String uid, String day, List<String> meals) async {}
  @override
  Future<void> saveSettings(String uid, List<MealReminder> values) async {
    if (saveGate != null) await saveGate!.future;
    settings[uid] = values;
  }

  @override
  Future<Map<String, dynamic>> steps(String uid) async {
    expect(active, uid);
    reads++;
    final at = now();
    return {
      'supported': true,
      'running': true,
      'days': {
        localDateKey(at): {
          'steps': count,
          'startedAt': at
              .subtract(const Duration(minutes: 5))
              .millisecondsSinceEpoch,
          'measuredAt': at.millisecondsSinceEpoch,
          'timezoneOffsetMinutes': at.timeZoneOffset.inMinutes,
        },
      },
    };
  }
}

class _Repository implements WellnessRepository {
  final attempts = <(String, Map<String, dynamic>)>[];
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<void> syncSteps(String uid, Map<String, dynamic> data) async {
    attempts.add((uid, Map.of(data)));
    if (gate != null) await gate!.future;
    if (fail) throw StateError('Offline fixture');
  }

  @override
  Stream<List<StepDay>> watchStepDays(String uid) => Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Harness extends ConsumerWidget {
  const _Harness(this.visible, {this.steps = false});
  final ValueNotifier<bool> visible;
  final bool steps;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(wellnessBootstrapProvider);
    return MaterialApp(
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (_, enabled, child) =>
              TickerMode(enabled: enabled, child: child!),
          child: steps ? const StepPanel() : const ReminderPanel(),
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime now;
  late _Device device;
  late _Repository repository;
  late FakeAuthRepository auth;
  late ProviderContainer container;
  late ValueNotifier<bool> visible;

  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump();
    }
  }

  Future<void> start(WidgetTester tester, {bool steps = false}) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    now = DateTime.now();
    device = _Device(() => now);
    repository = _Repository();
    auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
    visible = ValueNotifier(true);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        accountDataRepositoryProvider.overrideWithValue(
          FakeAccountDataRepository(),
        ),
        wellnessDeviceProvider.overrideWithValue(device),
        wellnessRepositoryProvider.overrideWithValue(repository),
        currentLocalTimeProvider.overrideWithValue(() => now),
        wellnessPreferencesProvider.overrideWith(
          (ref) => Stream.value(const WellnessPreferences()),
        ),
        latestBodyMetricProvider.overrideWith((ref, day) => Stream.value([])),
        activityLogsProvider.overrideWith((ref, day) => Stream.value([])),
        nutritionTargetProvider.overrideWith((ref, day) async => null),
        energyAdjustmentProvider.overrideWith((ref, day) => Stream.value(null)),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      visible.dispose();
      await auth.dispose();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _Harness(visible, steps: steps),
      ),
    );
    await flush(tester);
    if (steps) {
      await tester.pump(const Duration(seconds: 3));
      await flush(tester);
    }
  }

  void testCase(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        await tester.pump();
      }
    });
  }

  testCase('resume snapshot cannot replace a newer saved reminder', (
    tester,
  ) async {
    await start(tester);
    device.sleepReadGate = Completer<void>();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await flush(tester);
    final values = [
      for (final r in defaultMealReminders) MealReminder(r.meal, r.minute + 5),
    ];
    await container.read(localWellnessProvider.notifier).saveReminders(values);
    device.sleepReadGate!.complete();
    await flush(tester);
    expect(container.read(localWellnessProvider).value!.reminders, values);
  });

  testCase('stale resume failure cannot replace a newer saved reminder', (
    tester,
  ) async {
    await start(tester);
    final pendingRead = Completer<void>();
    device.sleepReadGate = pendingRead;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await flush(tester);
    final values = [
      for (final r in defaultMealReminders) MealReminder(r.meal, r.minute + 5),
    ];
    await container.read(localWellnessProvider.notifier).saveReminders(values);
    device.sleepReadGate = null;
    pendingRead.completeError(StateError('Stale native settings read failed'));
    await flush(tester);
    expect(container.read(localWellnessProvider).hasError, false);
    expect(container.read(localWellnessProvider).value!.reminders, values);
  });

  testCase(
    'return from Android settings refreshes notification permission and schedules',
    (tester) async {
      await start(tester);
      expect(container.read(localWellnessProvider).value!.permission, false);
      final previousSchedules = device.schedules;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      device.permission = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await flush(tester);
      expect(container.read(localWellnessProvider).value!.permission, true);
      expect(device.schedules, greaterThan(previousSchedules));
      expect(find.textContaining('Thông báo đang tắt'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      device.permission = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await flush(tester);
      expect(container.read(localWellnessProvider).value!.permission, false);
      expect(find.textContaining('Thông báo đang tắt'), findsOneWidget);
    },
  );

  testCase(
    'step polling stops in background and hidden tab, refreshes on return',
    (tester) async {
      await start(tester, steps: true);
      expect(device.reads, greaterThan(0));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final beforeBackground = device.reads;
      await tester.pump(const Duration(seconds: 15));
      expect(device.reads, beforeBackground);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await flush(tester);
      expect(device.reads, greaterThan(beforeBackground));
      visible.value = false;
      await flush(tester);
      final beforeHidden = device.reads;
      await tester.pump(const Duration(seconds: 15));
      expect(device.reads, beforeHidden);
      visible.value = true;
      await flush(tester);
      expect(device.reads, greaterThan(beforeHidden));
    },
  );

  testCase('same count on next local day still creates its own step history', (
    tester,
  ) async {
    await start(tester, steps: true);
    expect(repository.attempts, hasLength(1));
    final firstDay = localDateKey(now);
    now = now.add(const Duration(days: 1));
    await tester.pump(const Duration(seconds: 3));
    await flush(tester);
    expect(repository.attempts, hasLength(2));
    expect(repository.attempts.first.$2['day'], firstDay);
    expect(repository.attempts.last.$2['day'], localDateKey(now));
    expect(repository.attempts.last.$2['steps'], device.count);
  });

  testCase(
    'failed sync retries on resume without waiting a minute and clears stale error',
    (tester) async {
      await start(tester, steps: true);
      repository.fail = true;
      device.count++;
      now = now.add(const Duration(minutes: 2));
      await tester.pump(const Duration(seconds: 3));
      await flush(tester);
      expect(repository.attempts, hasLength(2));
      expect(
        find.textContaining('Bước chân đang giữ trên máy'),
        findsOneWidget,
      );
      repository.fail = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await flush(tester);
      expect(repository.attempts, hasLength(3));
      expect(find.textContaining('Bước chân đang giữ trên máy'), findsNothing);
    },
  );

  testCase('one pending server ACK never spawns duplicate step writes', (
    tester,
  ) async {
    await start(tester, steps: true);
    repository.gate = Completer<void>();
    device.count++;
    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(seconds: 3));
    await flush(tester);
    expect(repository.attempts, hasLength(2));
    await tester.pump(const Duration(seconds: 15));
    expect(repository.attempts, hasLength(2));
    repository.gate!.complete();
    await flush(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(repository.attempts, hasLength(2));
  });

  testCase('old account permission-save ACK is ignored after A to B to A', (
    tester,
  ) async {
    await start(tester);
    device.permission = true;
    device.saveGate = Completer<void>();
    final pending = container
        .read(localWellnessProvider.notifier)
        .saveReminders([
          for (final r in defaultMealReminders)
            MealReminder(r.meal, r.minute + 1),
        ]);
    await flush(tester);
    auth.emitUser(
      const AuthUser(
        uid: 'other',
        email: 'other@example.test',
        emailVerified: true,
      ),
    );
    await flush(tester);
    auth.emitUser(FakeAuthRepository.testUser);
    await flush(tester);
    final current = container.read(localWellnessProvider).value!.reminders;
    device.saveGate!.complete();
    await pending;
    await flush(tester);
    expect(container.read(localWellnessProvider).value!.reminders, current);
  });
}
