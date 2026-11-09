import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'package:healthmate/features/profile/models/health_goal.dart';
import 'package:healthmate/features/profile/models/profile_failure.dart';
import 'package:healthmate/features/profile/models/user_profile.dart';
import 'package:healthmate/features/profile/presentation/body_metric_form_dialog.dart';
import 'package:healthmate/features/profile/presentation/delete_body_metric_dialog.dart';
import 'package:healthmate/features/profile/presentation/profile_form_dialog.dart';
import 'package:healthmate/features/profile/presentation/profile_number_input.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';

import 'support/fake_health_profile_repository.dart';
import 'support/fake_auth_repository.dart';
import 'support/test_app.dart';

BodyMetric reading({
  String id = 'reading',
  DateTime? at,
  double weight = 70.25,
  String note = 'Buổi sáng',
}) => BodyMetric(
  id: id,
  weightKg: weight,
  measuredAt: at ?? DateTime(2026, 1, 15, 8, 35, 42, 123, 456),
  note: note,
  createdAt: null,
  updatedAt: null,
);

Future<void> openForm(WidgetTester tester, Widget form) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => form,
            ),
            child: const Text('Mở'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Mở'));
  await tester.pumpAndSettle();
}

void main() {
  test('editor number formatting preserves stored precision', () {
    expect(profileNumberInput(null), '');
    expect(profileNumberInput(170), '170');
    expect(profileNumberInput(170.125), '170.125');
    expect(profileNumberInput(70.25), '70.25');
  });

  testWidgets('editing name preserves exact height and target weight', (
    tester,
  ) async {
    UserProfileDraft? saved;
    final original = FakeHealthProfileRepository.testProfile;
    final profile = UserProfile(
      uid: original.uid,
      displayName: original.displayName,
      email: original.email,
      heightCm: 170.125,
      birthDate: original.birthDate,
      healthGoal: HealthGoal.loseWeight,
      targetWeightKg: 65.375,
      onboardingCompletedAt: original.onboardingCompletedAt,
      createdAt: original.createdAt,
      updatedAt: original.updatedAt,
      schemaVersion: original.schemaVersion,
    );
    await openForm(
      tester,
      ProfileFormDialog(
        profile: profile,
        onSave: (draft) async {
          saved = draft;
          return true;
        },
      ),
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('profile-height')))
          .controller!
          .text,
      '170.125',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('profile-target-weight')),
          )
          .controller!
          .text,
      '65.375',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-name')),
      'Nguyễn Bình',
    );
    await tester.tap(find.byKey(const ValueKey('save-profile')));
    await tester.pumpAndSettle();
    expect(saved?.displayName, 'Nguyễn Bình');
    expect(saved?.heightCm, 170.125);
    expect(saved?.targetWeightKg, 65.375);
  });

  testWidgets(
    'editing a note keeps fractional weight and the full original instant',
    (tester) async {
      final metric = reading(
        at: DateTime.utc(2026, 1, 15, 1, 35, 42, 123, 456),
      );
      BodyMetricDraft? saved;
      await openForm(
        tester,
        BodyMetricFormDialog(
          metric: metric,
          onSave: (draft) async {
            saved = draft;
            return true;
          },
        ),
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('metric-weight')))
            .controller!
            .text,
        '70.25',
      );
      await tester.enterText(
        find.byKey(const ValueKey('metric-note')),
        'Sau bữa sáng',
      );
      await tester.tap(find.byKey(const ValueKey('save-metric')));
      await tester.pumpAndSettle();
      expect(saved?.weightKg, 70.25);
      expect(saved!.measuredAt.isAtSameMomentAs(metric.measuredAt), isTrue);
    },
  );

  testWidgets(
    'future measurement is rejected and an old valid date opens without assertion',
    (tester) async {
      var calls = 0;
      await openForm(
        tester,
        BodyMetricFormDialog(
          metric: reading(at: DateTime.now().add(const Duration(days: 1))),
          onSave: (_) async {
            calls++;
            return true;
          },
        ),
      );
      await tester.tap(find.byKey(const ValueKey('save-metric')));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(
        find.textContaining('Thời điểm đo không được ở tương lai'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('metric-date')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await openForm(
        tester,
        BodyMetricFormDialog(metric: reading(at: DateTime(1999, 12, 31))),
      );
      await tester.tap(find.byKey(const ValueKey('metric-date')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'time picker preserves selected day and saves chosen local hour and minute',
    (tester) async {
      final metric = reading();
      BodyMetricDraft? saved;
      await openForm(
        tester,
        BodyMetricFormDialog(
          metric: metric,
          onSave: (draft) async {
            saved = draft;
            return true;
          },
        ),
      );
      await tester.tap(find.byKey(const ValueKey('metric-time')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TimePickerDialog>(find.byType(TimePickerDialog))
            .initialTime,
        const TimeOfDay(hour: 8, minute: 35),
      );
      await tester.tap(find.byTooltip('Switch to text input mode'));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(fields.at(0), '10');
      await tester.enterText(fields.at(1), '15');
      await tester.tap(find.text('Chọn'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-metric')));
      await tester.pumpAndSettle();
      expect(saved?.measuredAt, DateTime(2026, 1, 15, 10, 15));
      expect(saved?.weightKg, 70.25);
    },
  );

  testWidgets(
    'delete waits for acknowledgement, blocks repeat submits and keeps failure for retry',
    (tester) async {
      final held = Completer<bool>();
      var calls = 0;
      await openForm(
        tester,
        DeleteBodyMetricDialog(
          metric: reading(),
          onDelete: () {
            calls++;
            return calls == 1 ? held.future : Future.value(true);
          },
        ),
      );
      expect(find.textContaining('Buổi sáng'), findsOneWidget);
      final remove = find.byKey(const ValueKey('confirm-delete-metric'));
      await tester.tap(remove);
      await tester.tap(remove);
      await tester.pump();
      expect(calls, 1);
      expect(find.byType(DeleteBodyMetricDialog), findsOneWidget);
      expect(find.textContaining('Đang chờ máy chủ xác nhận'), findsOneWidget);
      held.complete(false);
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa xóa được lần đo'), findsOneWidget);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.byType(DeleteBodyMetricDialog), findsNothing);
    },
  );

  testWidgets(
    'profile shortcuts scroll to their target and remain valid after rebuilding',
    (tester) async {
      final repo = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
        metrics: [reading()],
      );
      final container = await pumpApp(tester, profileRepository: repo);
      container.read(appRouterProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('jump-weight')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('add-metric')).hitTestable(),
        findsOneWidget,
      );
      expect(find.textContaining('Lần cân mới nhất: 70.25 kg'), findsOneWidget);
      expect(find.text('70.25 kg'), findsOneWidget);
      expect(find.text('Ngày sinh: 15/01/2000'), findsOneWidget);
      expect(find.textContaining('15/01/2026 · 08:35'), findsNWidgets(2));
      repo.emitProfile(FakeHealthProfileRepository.testProfile);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('jump-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('jump-account')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('change-password')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed delete preserves the real reading and successful retry updates history and BMI',
    (tester) async {
      final repo = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
        metrics: [reading()],
      );
      final container = await pumpApp(tester, profileRepository: repo);
      container.read(appRouterProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      final remove = find.byKey(const ValueKey('delete-metric-reading'));
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pumpAndSettle();
      repo.failure = const ProfileFailure('Offline');
      await tester.tap(find.byKey(const ValueKey('confirm-delete-metric')));
      await tester.pumpAndSettle();
      expect(repo.metrics.length, 1);
      expect(find.byType(DeleteBodyMetricDialog), findsOneWidget);
      repo.failure = null;
      await tester.tap(find.byKey(const ValueKey('confirm-delete-metric')));
      await tester.pumpAndSettle();
      expect(repo.metrics, isEmpty);
      expect(find.byType(DeleteBodyMetricDialog), findsNothing);
      expect(find.textContaining('BMI tham khảo:'), findsNothing);
    },
  );

  testWidgets(
    'saving a new reading from an older history page returns to recent history',
    (tester) async {
      final repo = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
        metrics: [
          for (var i = 0; i < 26; i++)
            reading(
              id: 'm-$i',
              at: DateTime(2026, 1, 1).subtract(Duration(days: i)),
            ),
        ],
      );
      final container = await pumpApp(tester, profileRepository: repo);
      container.read(appRouterProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('weight-history-older')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('weight-history-older')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Trang 2 ·'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('add-metric')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-metric')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('metric-weight')),
        '69.75',
      );
      await tester.tap(find.byKey(const ValueKey('save-metric')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Trang 1 ·'), findsOneWidget);
      expect(
        container
            .read(bodyMetricPageProvider(null))
            .value
            ?.metrics
            .first
            .weightKg,
        69.75,
      );
    },
  );

  testWidgets(
    'pending deletion closes on logout and never reports success in the next session',
    (tester) async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final repo = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
        metrics: [reading()],
      );
      final container = await pumpApp(
        tester,
        profileRepository: repo,
        repository: auth,
      );
      container.read(appRouterProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      final remove = find.byKey(const ValueKey('delete-metric-reading'));
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pumpAndSettle();
      repo.pending = Completer<void>();
      await tester.tap(find.byKey(const ValueKey('confirm-delete-metric')));
      await tester.pump();
      expect(find.byType(DeleteBodyMetricDialog), findsOneWidget);
      auth.emitUser(null);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DeleteBodyMetricDialog), findsNothing);
      repo.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Đã xóa lần đo.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty older page explains how to return without claiming the full history is empty',
    (tester) async {
      final repo = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
        metrics: [
          for (var i = 0; i < 26; i++)
            reading(
              id: 'm-$i',
              at: DateTime(2026, 1, 1).subtract(Duration(days: i)),
            ),
        ],
      );
      final container = await pumpApp(tester, profileRepository: repo);
      container.read(appRouterProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('weight-history-older')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('weight-history-older')));
      await tester.pumpAndSettle();
      final remove = find.byKey(const ValueKey('delete-metric-m-25'));
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-delete-metric')));
      await tester.pumpAndSettle();
      expect(repo.metrics.length, 25);
      expect(
        find.textContaining('Trang này không còn lần đo nào'),
        findsOneWidget,
      );
      expect(find.textContaining('Chưa có lần đo nào.'), findsNothing);
      await tester.ensureVisible(
        find.byKey(const ValueKey('weight-history-newer')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('weight-history-newer')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('edit-metric-m-0')), findsOneWidget);
    },
  );

  testWidgets(
    'Google account displays its real sign-in method and explains password management',
    (tester) async {
      final auth = FakeAuthRepository(
        user: const AuthUser(
          uid: 'test-uid',
          email: 'member@example.com',
          emailVerified: true,
          providerIds: ['google.com'],
        ),
      );
      final container = await pumpApp(tester, repository: auth);
      container.read(appRouterProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('jump-account')));
      await tester.pumpAndSettle();
      expect(find.text('Cách đăng nhập: Google'), findsOneWidget);
      expect(find.text('Email đã xác minh'), findsOneWidget);
      expect(
        find.textContaining('Quản lý mật khẩu trong tài khoản Google'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('change-password')), findsNothing);
      expect(find.byKey(const ValueKey('sign-out')), findsOneWidget);
    },
  );
}
