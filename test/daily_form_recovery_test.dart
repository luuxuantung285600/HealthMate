import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/core/widgets/confirmed_save.dart';
import 'package:healthmate/features/activity/presentation/activity_log_dialog.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/profile/models/user_profile.dart';
import 'package:healthmate/features/profile/models/health_goal.dart';
import 'package:healthmate/features/profile/presentation/body_metric_form_dialog.dart';
import 'package:healthmate/features/profile/presentation/profile_form_dialog.dart';
import 'package:healthmate/features/water/presentation/water_log_dialog.dart';

import 'support/fake_auth_repository.dart';

void main() {
  final at = DateTime.now().subtract(const Duration(days: 1));
  final profile = UserProfile(
    uid: 'test-uid',
    email: 'member@example.test',
    displayName: 'An',
    heightCm: 170,
    birthDate: DateTime(2000, 1, 1),
    healthGoal: HealthGoal.maintainWeight,
    targetWeightKg: null,
    onboardingCompletedAt: at,
    createdAt: at,
    updatedAt: at,
    schemaVersion: 3,
  );
  final cases =
      <
        (
          String,
          String,
          String,
          String,
          Widget Function(Future<bool> Function()),
        )
      >[
        (
          'water',
          'water-amount',
          'save-water',
          '350',
          (save) => WaterLogDialog(selectedDate: at, onSave: (_) => save()),
        ),
        (
          'activity',
          'activity-duration',
          'save-activity',
          '45',
          (save) => ActivityLogDialog(selectedDate: at, onSave: (_) => save()),
        ),
        (
          'weight',
          'metric-weight',
          'save-metric',
          '65.5',
          (save) => BodyMetricFormDialog(onSave: (_) => save()),
        ),
        (
          'profile',
          'profile-name',
          'save-profile',
          'Bình',
          (save) => ProfileFormDialog(profile: profile, onSave: (_) => save()),
        ),
      ];

  Future<void> open(
    WidgetTester tester,
    Widget form, {
    bool small = false,
    FakeAuthRepository? auth,
  }) async {
    tester.view.physicalSize = small
        ? const Size(320, 640)
        : const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            auth ?? FakeAuthRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(small ? 1.6 : 1)),
            child: child!,
          ),
          home: Consumer(
            builder: (context, ref, _) {
              ref.watch(authSessionProvider);
              return Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => AccountBoundDialog(child: form),
                    ),
                    child: const Text('Mở form'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mở form'));
    await tester.pumpAndSettle();
  }

  for (final (name, field, saveKey, value, form) in cases) {
    testWidgets(
      '$name warns before Android Back or Cancel discards entered values',
      (tester) async {
        await open(tester, form(() async => false));
        final input = find.byKey(ValueKey(field));
        await tester.enterText(input, value);
        await tester.pump();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
        await tester.tap(find.text('Tiếp tục nhập'));
        await tester.pumpAndSettle();
        expect(tester.widget<TextFormField>(input).controller!.text, value);
        await tester.ensureVisible(find.text('Hủy'));
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();
        expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
        await tester.tap(find.text('Bỏ thay đổi'));
        await tester.pumpAndSettle();
        expect(input, findsNothing);
      },
    );

    testWidgets(
      '$name keeps values after failed save and sends one write while offline ACK is pending',
      (tester) async {
        var calls = 0;
        final gate = Completer<bool>();
        await open(
          tester,
          form(() {
            calls++;
            return calls == 1 ? Future.value(false) : gate.future;
          }),
        );
        final input = find.byKey(ValueKey(field));
        await tester.enterText(input, value);
        final save = find.byKey(ValueKey(saveKey));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(calls, 1);
        expect(find.textContaining('Thông tin vẫn được giữ'), findsOneWidget);
        expect(tester.widget<TextFormField>(input).controller!.text, value);
        await tester.tap(save);
        await tester.pump();
        expect(calls, 2);
        await tester.binding.handlePopRoute();
        await tester.pump(const Duration(seconds: 20));
        expect(calls, 2);
        expect(input, findsOneWidget);
        expect(find.textContaining('Đang chờ máy chủ'), findsOneWidget);
        gate.complete(true);
        await tester.pumpAndSettle();
        expect(input, findsNothing);
      },
    );

    testWidgets('$name stays usable at 320px with large text and keyboard', (
      tester,
    ) async {
      await open(tester, form(() async => false), small: true);
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      final input = find.byKey(ValueKey(field));
      await tester.ensureVisible(input);
      await tester.enterText(input, value);
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      final save = find.byKey(ValueKey(saveKey));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.textContaining('Thông tin vẫn được giữ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'account switch removes an old daily form even while awaiting save ACK',
    (tester) async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final gate = Completer<bool>();
      await open(
        tester,
        WaterLogDialog(selectedDate: at, onSave: (_) => gate.future),
        auth: auth,
      );
      await tester.enterText(find.byKey(const ValueKey('water-amount')), '500');
      await tester.tap(find.byKey(const ValueKey('save-water')));
      await tester.pump();
      auth.emitUser(null);
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(WaterLogDialog), findsNothing);
      gate.complete(true);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await auth.dispose();
    },
  );
}
