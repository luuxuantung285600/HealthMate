import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/profile/models/profile_validation.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/test_app.dart';

void main() {
  group('profile validation and BMI', () {
    test('validates editable profile and metric values', () {
      expect(ProfileValidation.displayName('A'), isNotNull);
      expect(ProfileValidation.displayName(' An Nguyen '), isNull);
      expect(ProfileValidation.height(''), isNull);
      expect(ProfileValidation.height('79'), isNotNull);
      expect(ProfileValidation.height('170,5'), isNull);
      expect(ProfileValidation.weight('abc'), isNotNull);
      expect(ProfileValidation.weight('70.2'), isNull);
      expect(ProfileValidation.note('x' * 201), isNotNull);
    });

    test('calculates BMI only from valid height and weight', () {
      expect(
        ProfileValidation.bmi(heightCm: 170, weightKg: 70),
        closeTo(24.22, 0.01),
      );
      expect(ProfileValidation.bmi(heightCm: null, weightKg: 70), isNull);
      expect(ProfileValidation.bmi(heightCm: 170, weightKg: 10), isNull);
    });
  });

  testWidgets('updates profile and completes body metric CRUD', (tester) async {
    final repository = FakeHealthProfileRepository(
      profile: FakeHealthProfileRepository.testProfile,
    );
    final container = await pumpApp(tester, profileRepository: repository);
    container.read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Chưa có lần đo nào. Thêm cân nặng để bắt đầu theo dõi lịch sử.',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const ValueKey('edit-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-profile')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-name')),
      'Nguyễn An',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-height')),
      '175,5',
    );
    await tester.tap(find.byKey(const ValueKey('profile-health-goal')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giảm cân').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-target-weight')),
      '65',
    );
    await tester.tap(find.byKey(const ValueKey('save-profile')));
    await tester.pumpAndSettle();
    expect(repository.updateProfileCalls, 1);
    expect(container.read(userProfileProvider).value?.displayName, 'Nguyễn An');
    expect(find.text('Nguyễn An'), findsNWidgets(2));
    expect(find.text('Chiều cao: 175.5 cm'), findsOneWidget);
    expect(find.text('Mục tiêu: Giảm cân'), findsOneWidget);
    expect(find.text('Cân nặng mục tiêu: 65.0 kg'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('add-metric')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-metric')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('metric-weight')), '70,2');
    await tester.enterText(
      find.byKey(const ValueKey('metric-note')),
      'Buổi sáng',
    );
    await tester.tap(find.byKey(const ValueKey('save-metric')));
    await tester.pumpAndSettle();
    expect(repository.addMetricCalls, 1);
    expect(find.text('70.2 kg'), findsOneWidget);
    expect(find.textContaining('BMI tham khảo:'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    final editButton = find.byKey(const ValueKey('edit-metric-metric-1'));
    await Scrollable.ensureVisible(tester.element(editButton), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(editButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('metric-weight')), '71.5');
    await tester.tap(find.byKey(const ValueKey('save-metric')));
    await tester.pumpAndSettle();
    expect(repository.updateMetricCalls, 1);
    expect(find.text('71.5 kg'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    final deleteButton = find.byKey(const ValueKey('delete-metric-metric-1'));
    await Scrollable.ensureVisible(tester.element(deleteButton), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-delete-metric')));
    await tester.pumpAndSettle();
    expect(repository.deleteMetricCalls, 1);
    expect(find.text('71.5 kg'), findsNothing);
    expect(find.textContaining('Chưa có lần đo nào'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile bootstrap creates an empty profile once per session', (
    tester,
  ) async {
    final repository = FakeHealthProfileRepository();
    final container = await pumpApp(tester, profileRepository: repository);
    container.read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();
    expect(find.text('Thiết lập sức khỏe ban đầu'), findsOneWidget);
    expect(repository.ensureCalls, 1);
  });

  testWidgets(
    'sign-in transition bootstraps the profile without a screen visit',
    (tester) async {
      final auth = FakeAuthRepository();
      final repository = FakeHealthProfileRepository();
      await pumpApp(tester, repository: auth, profileRepository: repository);
      expect(repository.ensureCalls, 0);

      auth.emitUser(FakeAuthRepository.testUser);
      await tester.pumpAndSettle();
      expect(repository.ensureCalls, 1);
    },
  );

  testWidgets('profile bootstrap timeout replaces the endless loading state', (
    tester,
  ) async {
    final repository = FakeHealthProfileRepository()
      ..pending = Completer<void>();
    final container = await pumpApp(
      tester,
      profileRepository: repository,
      settle: false,
    );
    await tester.pump();
    expect(find.text('Đang tải hồ sơ của bạn.'), findsOneWidget);

    await tester.pump(profileBootstrapTimeout + const Duration(seconds: 1));
    await tester.pump();

    expect(container.read(profileBootstrapProvider), isA<AsyncError<void>>());
    expect(find.text('Chưa thể mở dữ liệu tài khoản'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
