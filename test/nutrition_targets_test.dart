import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/journal/providers/journal_date_provider.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/nutrition_targets/providers/nutrition_target_providers.dart';
import 'package:healthmate/features/nutrition_targets/presentation/nutrition_target_form.dart';
import 'package:healthmate/features/nutrition_targets/presentation/nutrition_target_card.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_nutrition_target_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'package:healthmate/features/profile/models/user_profile.dart';
import 'support/test_app.dart';

final now = DateTime(2026, 10, 17, 12);

class DelayedTargetRepository extends FakeNutritionTargetRepository {
  final delayed = Completer<NutritionTarget?>();
  @override
  Future<NutritionTarget?> loadForDay(String uid, String key) =>
      key == '2026-10-16' ? delayed.future : super.loadForDay(uid, key);
}

UserProfile profileForUid(String uid) {
  final p = FakeHealthProfileRepository.testProfile;
  return UserProfile(
    uid: uid,
    displayName: p.displayName,
    email: p.email,
    heightCm: p.heightCm,
    birthDate: p.birthDate,
    healthGoal: p.healthGoal,
    targetWeightKg: p.targetWeightKg,
    onboardingCompletedAt: p.onboardingCompletedAt,
    createdAt: p.createdAt,
    updatedAt: p.updatedAt,
    schemaVersion: p.schemaVersion,
  );
}

NutritionTarget target(
  String key,
  double kcal, {
  double? p,
  double? c,
  double? f,
}) => NutritionTarget(
  effectiveFromDateKey: key,
  kcalTarget: kcal,
  proteinGTarget: p,
  carbsGTarget: c,
  fatGTarget: f,
);
FakeNutritionTargetRepository seeded([NutritionTarget? value]) {
  final repository = FakeNutritionTargetRepository();
  if (value != null) {
    repository.byUid['test-uid'] = {value.effectiveFromDateKey: value};
  }
  return repository;
}

Future<void> openForm(WidgetTester tester) async {
  await openDashboardDetails(tester);
  final entry = find.byKey(const ValueKey('edit-nutrition-target-2026-10-17'));
  await tester.ensureVisible(entry);
  await tester.pumpAndSettle();
  await tester.tap(entry);
  await tester.pumpAndSettle();
  expect(find.byType(NutritionTargetForm), findsOneWidget);
}

Future<void> input(WidgetTester tester, String key, String value) async {
  final field = find.byKey(ValueKey(key));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
  await tester.pump();
}

void main() {
  setUpAll(() async {
    final fonts = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/inter/Inter-$weight.ttf'));
    }
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets(
    'all recorded macros and kcal show their actual excess without negative remaining',
    (tester) async {
      final repository = seeded(
        target('2026-10-17', 1800, p: 100, c: 200, f: 60),
      );
      final nutrition = FakeNutritionRepository(
        meals: [
          MealLog(
            id: 'excess',
            type: MealType.lunch,
            consumedAt: now,
            items: const [],
            totals: const NutritionTotals(
              kcal: 2000,
              proteinG: 150,
              carbsG: 220,
              fatG: 80,
            ),
            source: MealSource.manual,
          ),
        ],
      );
      await pumpApp(
        tester,
        dashboardNow: now,
        targetRepository: repository,
        nutritionRepository: nutrition,
      );
      await openDashboardDetails(tester);
      expect(find.text('Vượt 200 kcal'), findsOneWidget);
      expect(find.text('Vượt 50 g'), findsOneWidget);
      expect(find.text('Vượt 20 g'), findsNWidgets(2));
      expect(find.textContaining('Còn -'), findsNothing);
    },
  );
  testWidgets(
    'changing to a future effective date loads and edits that version, not today',
    (tester) async {
      final repository = seeded(target('2026-10-17', 1800));
      repository.byUid['test-uid']!['2026-10-18'] = target('2026-10-18', 2000);
      await pumpApp(tester, dashboardNow: now, targetRepository: repository);
      await openForm(tester);
      await tester.tap(find.byKey(const ValueKey('target-date')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DatePickerDialog>(find.byType(DatePickerDialog))
            .firstDate,
        DateTime(2026, 10, 17),
      );
      await tester.tap(find.text('18').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('target-kcal')))
            .controller!
            .text,
        '2000.0',
      );
      await input(tester, 'target-kcal', '2100');
      await tester.tap(find.byKey(const ValueKey('save-target')));
      await tester.pumpAndSettle();
      expect(repository.byUid['test-uid']!['2026-10-17']!.kcalTarget, 1800);
      expect(repository.byUid['test-uid']!['2026-10-18']!.kcalTarget, 2100);
      expect(repository.byUid['test-uid']!.length, 2);
    },
  );
  testWidgets(
    'late target response from an earlier selected day cannot replace current day',
    (tester) async {
      final repository = DelayedTargetRepository();
      repository.byUid['test-uid'] = {'2026-10-17': target('2026-10-17', 1800)};
      final container = await pumpApp(
        tester,
        dashboardNow: now,
        targetRepository: repository,
      );
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      container
          .read(journalDateProvider.notifier)
          .select(DateTime(2026, 10, 16));
      await tester.pump();
      await tester.pump();
      expect(find.text('Đang tải mục tiêu…'), findsOneWidget);
      container
          .read(journalDateProvider.notifier)
          .select(DateTime(2026, 10, 17));
      await tester.pumpAndSettle();
      repository.delayed.complete(target('2026-10-16', 900));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('journal-nutrition-details')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Mục tiêu áp dụng từ 2026-10-17'),
        findsOneWidget,
      );
      expect(find.textContaining('/ 900 kcal'), findsNothing);
    },
  );
  testWidgets(
    'crossing midnight while editing requires a current or future effective date',
    (tester) async {
      var clock = now;
      final repository = seeded();
      await pumpApp(
        tester,
        dashboardNowSource: () => clock,
        targetRepository: repository,
      );
      await openForm(tester);
      await input(tester, 'target-kcal', '1800');
      clock = DateTime(2026, 10, 18);
      await tester.tap(find.byKey(const ValueKey('save-target')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chỉ áp dụng từ hôm nay'), findsOneWidget);
      expect(repository.saveCalls, 0);
    },
  );
  test(
    'effective targets never apply backwards across month/year or future dates',
    () {
      final old = target('2026-12-31', 1800), next = target('2027-01-02', 2000);
      expect(targetForDate([next, old], '2026-12-30'), isNull);
      expect(targetForDate([next, old], '2026-12-31'), same(old));
      expect(targetForDate([next, old], '2027-01-01'), same(old));
      expect(targetForDate([next, old], '2027-01-02'), same(next));
      expect(targetForDate([], '2027-01-02'), isNull);
    },
  );
  test(
    'finite bounds, complete macros, deliberate zero and local effective date validation',
    () {
      for (final value in [0.0, -1.0, 20001.0, double.nan, double.infinity]) {
        expect(target('2026-10-17', value).validate(), isNotNull);
      }
      expect(target('2026-02-30', 1800).validate(), isNotNull);
      expect(
        target('2026-10-16', 1800).validate(earliestDateKey: '2026-10-17'),
        isNotNull,
      );
      expect(
        target('2026-10-18', 1800).validate(earliestDateKey: '2026-10-17'),
        isNull,
      );
      expect(target('2026-10-17', 1800, p: 1).validate(), isNotNull);
      for (final value in [-1.0, 5001.0, double.nan, double.infinity]) {
        expect(
          target('2026-10-17', 1800, p: 0, c: 0, f: value).validate(),
          isNotNull,
        );
      }
      expect(
        target('2026-10-17', 20000, p: 5000, c: 5000, f: 5000).validate(),
        isNull,
      );
      expect(target('2026-10-17', 1800, p: 0, c: 0, f: 0).validate(), isNull);
      expect(target('2026-10-17', 1800).hasMacros, isFalse);
    },
  );
  test(
    'remaining/excess use true numbers and zero macro target has no divide by zero',
    () {
      const remaining = TargetComparison(recorded: 1200, target: 1800);
      expect(remaining.remaining, 600);
      expect(remaining.excess, 0);
      const excess = TargetComparison(recorded: 2000, target: 1800);
      expect(excess.excess, 200);
      expect(excess.remaining, 0);
      expect(excess.progress, 1);
      expect(const TargetComparison(recorded: 10, target: 0).progress, isNull);
      expect(
        target(
          '2026-10-17',
          2000,
          p: 100,
          c: 250,
          f: 60,
        ).needsMacroConfirmation,
        isFalse,
      );
      expect(
        target('2026-10-17', 1800, p: 0, c: 0, f: 0).needsMacroConfirmation,
        isTrue,
      );
    },
  );

  testWidgets(
    'new and existing users without nutrition targets can set kcal without repeating onboarding',
    (tester) async {
      final repository = seeded();
      final container = await pumpApp(
        tester,
        dashboardNow: now,
        targetRepository: repository,
      );
      expect(find.text('Chưa đặt mục tiêu'), findsOneWidget);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        AppRoutes.dashboard,
      );
      await openForm(tester);
      await input(tester, 'target-kcal', '1800,5');
      await tester.tap(find.byKey(const ValueKey('save-target')));
      await tester.pumpAndSettle();
      expect(find.byType(NutritionTargetForm), findsNothing);
      expect(repository.byUid['test-uid']!['2026-10-17']!.kcalTarget, 1800.5);
      expect(repository.byUid['test-uid']!.values.single.hasMacros, isFalse);
      expect(
        find.textContaining('Chưa đặt mục tiêu cho ba chất'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'validation preserves partial macros and mismatch confirmation never silently changes inputs',
    (tester) async {
      final repository = seeded();
      await pumpApp(tester, dashboardNow: now, targetRepository: repository);
      await openForm(tester);
      await input(tester, 'target-kcal', '1800');
      await input(tester, 'target-protein', '0');
      await tester.tap(find.byKey(const ValueKey('save-target')));
      await tester.pumpAndSettle();
      expect(
        find.text('Nhập đủ cả ba chất hoặc để trống cả ba.'),
        findsOneWidget,
      );
      expect(repository.saveCalls, 0);
      await input(tester, 'target-carbs', '0');
      await input(tester, 'target-fat', '0');
      await tester.tap(find.byKey(const ValueKey('save-target')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('confirm-target-mismatch')),
        findsOneWidget,
      );
      expect(repository.saveCalls, 0);
      await tester.tap(find.text('Quay lại sửa'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('target-protein')))
            .controller!
            .text,
        '0',
      );
      await tester.tap(find.byKey(const ValueKey('save-target')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-target-mismatch')));
      await tester.pumpAndSettle();
      expect(repository.byUid['test-uid']!.values.single.proteinGTarget, 0);
      expect(repository.byUid['test-uid']!.values.single.kcalTarget, 1800);
    },
  );
  testWidgets(
    'rejected save retains input and retry creates one target version',
    (tester) async {
      final repository = seeded()..failSave = true;
      await pumpApp(tester, dashboardNow: now, targetRepository: repository);
      await openForm(tester);
      await input(tester, 'target-kcal', '1800');
      await tester.tap(find.byKey(const ValueKey('save-target')));
      await tester.pumpAndSettle();
      expect(find.byType(NutritionTargetForm), findsOneWidget);
      expect(find.textContaining('Thông tin vẫn được giữ'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('target-kcal')))
            .controller!
            .text,
        '1800',
      );
      repository.failSave = false;
      await tester.tap(find.byKey(const ValueKey('save-target')));
      await tester.pumpAndSettle();
      expect(repository.saveCalls, 2);
      expect(repository.byUid['test-uid']!.length, 1);
    },
  );
  testWidgets(
    'pending save disables double tap and survives 20 seconds without resubmission',
    (tester) async {
      final repository = seeded()..pendingSave = Completer<void>();
      await pumpApp(tester, dashboardNow: now, targetRepository: repository);
      await openForm(tester);
      await input(tester, 'target-kcal', '1800');
      await tester.tap(find.byKey(const ValueKey('save-target')));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('save-target')))
            .onPressed,
        isNull,
      );
      await tester.pump(const Duration(seconds: 20));
      expect(find.byType(NutritionTargetForm), findsOneWidget);
      expect(repository.saveCalls, 1);
      repository.pendingSave!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(NutritionTargetForm), findsNothing);
      expect(repository.byUid['test-uid']!.length, 1);
    },
  );
  testWidgets(
    'account switch closes pending draft and ignores old completion',
    (tester) async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final profiles = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
      );
      final repository = seeded()..pendingSave = Completer<void>();
      final container = await pumpApp(
        tester,
        repository: auth,
        profileRepository: profiles,
        dashboardNow: now,
        targetRepository: repository,
      );
      final subscription = container.listen(
        nutritionTargetControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await openForm(tester);
      await input(tester, 'target-kcal', '1800');
      await tester.tap(find.byKey(const ValueKey('save-target')));
      await tester.pump();
      auth.emitUser(
        const AuthUser(
          emailVerified: true,
          uid: 'another-user',
          email: 'other@example.com',
        ),
      );
      profiles.emitProfile(profileForUid('another-user'));
      await tester.pumpAndSettle();
      expect(find.byType(NutritionTargetForm), findsNothing);
      repository.pendingSave!.complete();
      await tester.pumpAndSettle();
      expect(repository.savedUids, ['test-uid']);
      expect(repository.byUid['another-user'], isNull);
      expect(
        container.read(nutritionTargetControllerProvider).hasError,
        isFalse,
      );
      expect(find.textContaining('Đã lưu mục tiêu áp dụng'), findsNothing);
    },
  );
  testWidgets(
    'target read errors and loading never masquerade as no target; retry reloads',
    (tester) async {
      final repository = seeded()..pendingRead = Completer<void>();
      await pumpApp(
        tester,
        dashboardNow: now,
        targetRepository: repository,
        settle: false,
      );
      await tester.pump();
      await tester.pump();
      await openDashboardDetails(tester, settle: false);
      expect(
        find.descendant(
          of: find.byType(NutritionTargetCard),
          matching: find.text('Đang tải mục tiêu…'),
        ),
        findsOneWidget,
      );
      expect(find.text('Chưa đặt mục tiêu'), findsNothing);
      repository.failRead = true;
      repository.pendingRead!.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('Không coi lỗi tải'), findsOneWidget);
      expect(find.text('Chưa đặt mục tiêu'), findsNothing);
      repository.failRead = false;
      await Scrollable.ensureVisible(
        tester.element(find.text('Thử tải lại mục tiêu')),
        alignment: .4,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thử tải lại mục tiêu'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa đặt mục tiêu'), findsNWidgets(2));
    },
  );
  testWidgets(
    'dashboard and journal compare the applicable target and preserve earlier dates',
    (tester) async {
      final repository = seeded(target('2026-10-17', 1800));
      repository.byUid['test-uid']!['2026-10-18'] = target('2026-10-18', 2000);
      final nutrition = FakeNutritionRepository(
        meals: [
          MealLog(
            id: 'test',
            type: MealType.lunch,
            consumedAt: now,
            items: const [],
            totals: const NutritionTotals(kcal: 1200),
            source: MealSource.manual,
          ),
        ],
      );
      final container = await pumpApp(
        tester,
        dashboardNow: now,
        targetRepository: repository,
        nutritionRepository: nutrition,
      );
      await openDashboardDetails(tester);
      expect(find.text('Còn 600 kcal'), findsOneWidget);
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      container
          .read(journalDateProvider.notifier)
          .select(DateTime(2026, 10, 16));
      await tester.pumpAndSettle();
      expect(find.text('Chưa đặt mục tiêu'), findsOneWidget);
      expect(find.text('Còn 600 kcal'), findsNothing);
      container
          .read(journalDateProvider.notifier)
          .select(DateTime(2026, 10, 17));
      await tester.pumpAndSettle();
      await openJournalNutritionDetails(tester);
      expect(find.text('Còn 600 kcal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'journal loading/error does not compute remaining from a guessed zero',
    (tester) async {
      final repository = seeded(target('2026-10-17', 1800));
      final nutrition = FakeNutritionRepository()
        ..dayError = const FormatException('fixture');
      await pumpApp(
        tester,
        dashboardNow: now,
        targetRepository: repository,
        nutritionRepository: nutrition,
      );
      await openDashboardDetails(tester);
      expect(find.textContaining('chưa tính còn/vượt'), findsOneWidget);
      expect(find.text('Còn 1800 kcal'), findsNothing);
    },
  );
  for (final width in [360.0, 390.0, 412.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final theme in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets('target card/form/keyboard fit $width scale$scale $theme', (
          tester,
        ) async {
          final captureKey = GlobalKey();
          final container = await pumpApp(
            tester,
            size: Size(width, 800),
            textScale: scale,
            dashboardNow: now,
            targetRepository: seeded(
              target('2026-10-17', 1800, p: 100, c: 200, f: 60),
            ),
            captureKey: captureKey,
            initialThemeMode: theme,
          );
          container.read(appRouterProvider).go(AppRoutes.profile);
          await tester.pumpAndSettle();
          await openForm(tester);
          expect(
            tester
                .widget<TextField>(find.byKey(const ValueKey('target-kcal')))
                .controller!
                .text,
            '1800.0',
          );
          await input(tester, 'target-fat', '30,5');
          tester.view.viewInsets = const FakeViewPadding(bottom: 260);
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('save-target')), findsOneWidget);
          expect(
            tester.getBottomRight(find.byKey(const ValueKey('save-target'))).dy,
            lessThanOrEqualTo(540),
          );
          expect(tester.takeException(), isNull);
          if ((width == 360 && scale == 1 && theme == ThemeMode.light) ||
              (width == 390 && scale == 1.5 && theme == ThemeMode.dark) ||
              (width == 412 && scale == 2 && theme == ThemeMode.light)) {
            await tester.runAsync(() async {
              final boundary =
                  captureKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              final folder = Directory('build/c2-layout');
              await folder.create(recursive: true);
              await File(
                '${folder.path}/$width-$scale-${theme.name}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
            });
          }
          tester.view.resetViewInsets();
        });
      }
    }
  }
}
