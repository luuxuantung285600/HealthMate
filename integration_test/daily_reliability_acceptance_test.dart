// Android native + real SDK acceptance. Only the guarded AVD/demo runner may run it.
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:healthmate/core/data/private_local_data.dart';
import 'package:healthmate/core/data/user_data_revision.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/core/widgets/confirmed_save.dart';
import 'package:healthmate/features/activity/data/firebase_activity_repository.dart';
import 'package:healthmate/features/activity/presentation/activity_log_dialog.dart';
import 'package:healthmate/features/activity/providers/activity_providers.dart';
import 'package:healthmate/features/auth/data/firebase_account_data_repository.dart';
import 'package:healthmate/features/auth/data/firebase_auth_repository.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/meal_drafts/data/meal_draft_store.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/water/data/firebase_water_repository.dart';
import 'package:healthmate/features/water/presentation/water_log_dialog.dart';
import 'package:healthmate/features/water/providers/water_providers.dart';
import 'package:healthmate/features/wellness/data/wellness_device.dart';
import 'package:healthmate/features/wellness/models/wellness_models.dart';
import 'package:healthmate/features/wellness/providers/wellness_providers.dart';

import 'support/emulator_email_actions.dart';

class _DailyApp extends ConsumerWidget {
  const _DailyApp();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authSessionProvider);
    ref.watch(wellnessBootstrapProvider);
    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              FilledButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AccountBoundDialog(
                    child: WaterLogDialog(
                      selectedDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      onSave: ref.read(waterControllerProvider.notifier).add,
                    ),
                  ),
                ),
                child: const Text('Mở nước'),
              ),
              FilledButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AccountBoundDialog(
                    child: ActivityLogDialog(
                      selectedDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      onSave: ref.read(activityControllerProvider.notifier).add,
                    ),
                  ),
                ),
                child: const Text('Mở vận động'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isAndroid ||
      !const bool.fromEnvironment('HEALTHMATE_CORE_EMULATOR_TESTS') ||
      const bool.fromEnvironment(
        'HEALTHMATE_ENABLE_CHATBOT',
        defaultValue: true,
      ) ||
      const bool.fromEnvironment(
        'HEALTHMATE_ENABLE_FOOD_SCANNER',
        defaultValue: true,
      )) {
    throw StateError(
      'Run only with the guarded Android QA runner and demo backend.',
    );
  }

  testWidgets(
    'Android daily: native resume, durable draft, offline SDK ACK and account isolation',
    (tester) async {
      const project = 'demo-healthmate-rules';
      final app = await Firebase.initializeApp(
        name: 'healthmate-daily-qa',
        options: const FirebaseOptions(
          apiKey: 'emulator-only-fake-api-key',
          appId: '1:1234567890:android:0123456789abcdef',
          messagingSenderId: '1234567890',
          projectId: project,
        ),
      );
      final auth = FirebaseAuth.instanceFor(app: app);
      await auth.useAuthEmulator('10.0.2.2', 9099, automaticHostMapping: false);
      final db = FirebaseFirestore.instanceFor(app: app);
      db.settings = const Settings(persistenceEnabled: false);
      db.useFirestoreEmulator('10.0.2.2', 8080, automaticHostMapping: false);
      final suffix = DateTime.now().microsecondsSinceEpoch;
      await auth.createUserWithEmailAndPassword(
        email: 'daily-a-$suffix@example.test',
        password: 'Synthetic-daily-123!',
      );
      await verifyEmulatorEmail(auth, projectId: project);
      final alice = auth.currentUser!.uid;
      final device = WellnessDevice();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FirebaseAuthRepository(auth),
          ),
          accountDataRepositoryProvider.overrideWithValue(
            FirebaseAccountDataRepository(db),
          ),
          realtimeFirestoreProvider.overrideWithValue(db),
          waterRepositoryProvider.overrideWithValue(
            FirebaseWaterRepository(db),
          ),
          activityRepositoryProvider.overrideWithValue(
            FirebaseActivityRepository(db),
          ),
          wellnessDeviceProvider.overrideWithValue(device),
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        await device.setAccount(null);
        await db.enableNetwork();
        await db.terminate();
        await auth.signOut();
        await app.delete();
      });
      Future<void> until(bool Function() condition) async {
        final deadline = DateTime.now().add(const Duration(seconds: 35));
        while (!condition()) {
          if (DateTime.now().isAfter(deadline)) {
            fail('Daily native state did not settle.');
          }
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pump(const Duration(milliseconds: 300));
      }

      Future<void> tap(Finder finder) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pump(const Duration(milliseconds: 300));
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const _DailyApp(),
        ),
      );
      await until(
        () => container.read(localWellnessProvider).value?.uid == alice,
      );
      expect(await device.requestNotifications(), true);
      const externalSleep = SleepReminder(minute: 21 * 60);
      await device.saveSleepReminder(alice, externalSleep);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await until(
        () =>
            container.read(localWellnessProvider).value?.sleepReminder.minute ==
            externalSleep.minute,
      );
      expect(container.read(localWellnessProvider).value!.permission, true);
      await device.testReminder(alice);
      expect(await device.activeNotificationIds(alice), contains(5100));
      debugPrint(
        'DAILY_PASS native resume rereads encrypted settings and posts notification',
      );

      final local = PrivateLocalData();
      final draft = SavedMealDraft(
        operationId: 'native-daily-draft',
        updatedAt: DateTime.now(),
        draft: MealDraft(
          type: MealType.lunch,
          consumedAt: DateTime.now(),
          source: MealSource.manual,
          items: const [
            MealItemSnapshot(
              foodId: 'synthetic-native',
              name: 'Synthetic test only',
              grams: 100,
              nutrition: NutritionTotals(
                kcal: 100,
                proteinG: 5,
                carbsG: 15,
                fatG: 2,
              ),
              sourceLabel: 'Synthetic emulator fixture',
              isEstimated: true,
            ),
          ],
        ),
      );
      await MealDraftStore(local).put(alice, draft);
      final reopened = MealDraftStore(PrivateLocalData());
      expect(
        (await reopened.list(alice)).single.operationId,
        draft.operationId,
      );
      expect((await reopened.list(alice)).single.draft.totals.kcal, 100);
      debugPrint('DAILY_PASS native encrypted draft survives store recreation');

      await tap(find.text('Mở nước'));
      await tester.enterText(find.byKey(const ValueKey('water-amount')), '350');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.binding.handlePopRoute();
      await until(
        () => find.text('Bỏ thay đổi chưa lưu?').evaluate().isNotEmpty,
      );
      await tap(find.text('Tiếp tục nhập'));
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('water-amount')))
            .controller!
            .text,
        '350',
      );
      await db.disableNetwork();
      await tap(find.byKey(const ValueKey('save-water')));
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(WaterLogDialog), findsOneWidget);
      expect(find.textContaining('Đang chờ máy chủ xác nhận'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(WaterLogDialog), findsOneWidget);
      await db.enableNetwork();
      await until(() => find.byType(WaterLogDialog).evaluate().isEmpty);
      final waters = await db
          .collection('users/$alice/water_logs')
          .get(const GetOptions(source: Source.server));
      expect(waters.docs, hasLength(1));
      expect(waters.docs.single['amountMl'], 350);
      debugPrint(
        'DAILY_PASS real Android Firestore offline write ACK saves exactly one water log',
      );

      await tap(find.text('Mở vận động'));
      await tester.enterText(
        find.byKey(const ValueKey('activity-duration')),
        '45',
      );
      await db.disableNetwork();
      await tap(find.byKey(const ValueKey('save-activity')));
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(ActivityLogDialog), findsOneWidget);
      await db.enableNetwork();
      await until(() => find.byType(ActivityLogDialog).evaluate().isEmpty);
      final activities = await db
          .collection('users/$alice/activity_logs')
          .get(const GetOptions(source: Source.server));
      expect(activities.docs, hasLength(1));
      expect(activities.docs.single['durationMinutes'], 45);
      debugPrint(
        'DAILY_PASS real Android Firestore offline activity reconnect saves exactly once',
      );

      await tap(find.text('Mở nước'));
      await tester.enterText(find.byKey(const ValueKey('water-amount')), '500');
      await auth.createUserWithEmailAndPassword(
        email: 'daily-b-$suffix@example.test',
        password: 'Synthetic-daily-123!',
      );
      await verifyEmulatorEmail(auth, projectId: project);
      final bob = auth.currentUser!.uid;
      await until(
        () => container.read(localWellnessProvider).value?.uid == bob,
      );
      expect(find.byType(WaterLogDialog), findsNothing);
      expect(await reopened.list(bob), isEmpty);
      await expectLater(
        device.readSettings(alice),
        throwsA(isA<PlatformException>()),
      );
      await expectLater(
        db
            .collection('users/$alice/water_logs')
            .get(const GetOptions(source: Source.server)),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      debugPrint(
        'DAILY_PASS changed account closes dirty form and denies another UID on native and Firestore',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
