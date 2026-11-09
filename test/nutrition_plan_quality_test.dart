import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/core/widgets/confirmed_save.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/nutrition_targets/models/personal_nutrition_plan.dart';
import 'package:healthmate/features/nutrition_targets/presentation/nutrition_target_form.dart';
import 'package:healthmate/features/nutrition_targets/presentation/personal_nutrition_planner.dart';
import 'package:healthmate/features/nutrition_targets/providers/nutrition_target_providers.dart';
import 'package:healthmate/features/profile/models/health_goal.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/wellness/models/wellness_models.dart';
import 'package:healthmate/features/wellness/presentation/wellness_screen.dart';
import 'package:healthmate/features/wellness/providers/wellness_providers.dart';
import 'package:healthmate/shared/providers/local_clock_provider.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_nutrition_target_repository.dart';
import 'support/test_app.dart';

const qualityTarget = NutritionTarget(
  effectiveFromDateKey: '2026-11-09',
  kcalTarget: 1800,
);
const futureTarget = NutritionTarget(
  effectiveFromDateKey: '2026-11-10',
  kcalTarget: 2000,
);

enum QualityKind { target, personal, meal, panel }

class NutritionPlanFixture {
  final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
  final targets = FakeNutritionTargetRepository();
  final attempts = <MealDraft>[];
  DateTime clock = DateTime(2026, 11, 9, 12);
  bool failPlan = false;
  Completer<void>? pendingPlan;
  late ProviderContainer container;
  Future<void> start(
    WidgetTester tester,
    QualityKind kind, {
    Size size = const Size(390, 844),
    double scale = 1,
    ThemeMode mode = ThemeMode.light,
    GlobalKey? captureKey,
  }) async {
    targets.byUid['test-uid'] = {
      '2026-11-09': qualityTarget,
      '2026-11-10': futureTarget,
    };
    container = await pumpApp(
      tester,
      repository: auth,
      targetRepository: targets,
      dashboardNowSource: () => clock,
      size: size,
      textScale: scale,
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: captureKey,
          child: QualityEntry(this, kind, mode: mode),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (kind != QualityKind.panel) {
      await qualityTap(
        tester,
        find.byKey(const ValueKey('open-quality-entry')),
      );
    }
  }
}

class QualityEntry extends ConsumerWidget {
  const QualityEntry(this.fixture, this.kind, {required this.mode, super.key});
  final NutritionPlanFixture fixture;
  final QualityKind kind;
  final ThemeMode mode;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authSessionProvider);
    ref.watch(userProfileProvider);
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: kind == QualityKind.panel
          ? ProviderScope(
              overrides: [
                plansProvider.overrideWith(
                  (ref, week) => Stream.value([
                    PlannedMeal(
                      id: '2026-11-10-breakfast',
                      date: DateTime(2026, 11, 10),
                      type: MealType.breakfast,
                      items: [
                        MealItemSnapshot.fromCatalog(
                          FakeNutritionRepository.rice,
                          100,
                        ),
                      ],
                    ),
                  ]),
                ),
              ],
              child: const Scaffold(body: MealPlannerPanel()),
            )
          : Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  key: const ValueKey('open-quality-entry'),
                  onPressed: () {
                    switch (kind) {
                      case QualityKind.target:
                        openNutritionTargetForm(context, ref, qualityTarget);
                      case QualityKind.personal:
                        openPersonalNutritionPlanner(
                          context,
                          seed: const PersonalNutritionSeed(
                            age: 30,
                            heightCm: 175,
                            weightKg: 70,
                            goal: HealthGoal.maintainWeight,
                          ),
                        );
                      case QualityKind.meal:
                        showDialog<MealDraft>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => AccountBoundDialog(
                            child: PlanMealDialog(
                              date: DateTime(2026, 11, 10),
                              type: MealType.breakfast,
                              catalog: const [FakeNutritionRepository.rice],
                              items: [
                                MealItemSnapshot.fromCatalog(
                                  FakeNutritionRepository.rice,
                                  100,
                                ),
                              ],
                              onSave: (draft) async {
                                fixture.attempts.add(draft);
                                await fixture.pendingPlan?.future;
                                return !fixture.failPlan;
                              },
                            ),
                          ),
                        );
                      case QualityKind.panel:
                        break;
                    }
                  },
                  child: const Text('Mở form kiểm thử'),
                ),
              ),
            ),
    );
  }
}

Future<void> qualityTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> qualityInput(WidgetTester tester, String key, String value) async {
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.enterText(f, value);
  await tester.pump();
}

String qualityText(WidgetTester tester, String key) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;
Future<void> pickTomorrow(WidgetTester tester) async {
  await qualityTap(tester, find.byKey(const ValueKey('target-date')));
  Navigator.of(
    tester.element(find.byType(DatePickerDialog)),
  ).pop(DateTime(2026, 11, 10));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'target close and Back preserve edits; reverting values closes without a warning',
    (tester) async {
      final f = NutritionPlanFixture();
      await f.start(tester, QualityKind.target);
      await qualityInput(tester, 'target-kcal', '1900');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
      await qualityTap(tester, find.text('Tiếp tục nhập'));
      expect(qualityText(tester, 'target-kcal'), '1900');
      await qualityInput(tester, 'target-kcal', '1800.0');
      await qualityTap(tester, find.byTooltip('Đóng'));
      expect(find.byType(NutritionTargetForm), findsNothing);
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsNothing);
      expect(f.targets.saveCalls, 0);
    },
  );
  testWidgets(
    'date change asks before replacing edits; cancel keeps date and values; accepting preserves older target',
    (tester) async {
      final f = NutritionPlanFixture();
      await f.start(tester, QualityKind.target);
      await qualityInput(tester, 'target-kcal', '1950');
      await pickTomorrow(tester);
      expect(find.text('Đổi ngày áp dụng?'), findsOneWidget);
      await qualityTap(tester, find.text('Tiếp tục sửa'));
      expect(qualityText(tester, 'target-kcal'), '1950');
      expect(find.text('Áp dụng từ 09/11/2026'), findsOneWidget);
      await pickTomorrow(tester);
      await qualityTap(
        tester,
        find.byKey(const ValueKey('confirm-change-target-date')),
      );
      expect(qualityText(tester, 'target-kcal'), '2000.0');
      await qualityTap(tester, find.byTooltip('Đóng'));
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
      await qualityTap(tester, find.text('Tiếp tục nhập'));
      await qualityTap(tester, find.byKey(const ValueKey('save-target')));
      expect(f.targets.byUid['test-uid']!['2026-11-09']!.kcalTarget, 1800);
      expect(f.targets.byUid['test-uid']!['2026-11-10']!.kcalTarget, 2000);
      expect(f.targets.saveCalls, 1);
    },
  );
  testWidgets(
    'date load failure blocks save, keeps input and retry loads the selected day',
    (tester) async {
      final f = NutritionPlanFixture();
      await f.start(tester, QualityKind.target);
      await qualityInput(tester, 'target-kcal', '1950');
      f.targets.failRead = true;
      await pickTomorrow(tester);
      await qualityTap(
        tester,
        find.byKey(const ValueKey('confirm-change-target-date')),
      );
      expect(qualityText(tester, 'target-kcal'), '1950');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('save-target')))
            .onPressed,
        isNull,
      );
      expect(f.targets.saveCalls, 0);
      f.targets.failRead = false;
      await qualityTap(tester, find.text('Tải lại mục tiêu'));
      expect(qualityText(tester, 'target-kcal'), '2000.0');
      await qualityTap(tester, find.byKey(const ValueKey('save-target')));
      expect(f.targets.saveCalls, 1);
    },
  );
  testWidgets(
    'target form blocks writes when Auth changes before its stream event',
    (tester) async {
      final f = NutritionPlanFixture();
      await f.start(tester, QualityKind.target);
      await qualityInput(tester, 'target-kcal', '1900');
      f.auth.emitUser(null);
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('save-target')))
          .onPressed!();
      await tester.pumpAndSettle();
      expect(f.targets.saveCalls, 0);
      expect(find.byType(NutritionTargetForm), findsNothing);
    },
  );
  testWidgets(
    'target controller independently blocks an Auth and stream UID mismatch',
    (tester) async {
      final f = NutritionPlanFixture();
      await f.start(tester, QualityKind.target);
      final controller = f.container.read(
        nutritionTargetControllerProvider.notifier,
      );
      f.auth.emitUser(null);
      expect(await controller.save(qualityTarget), isFalse);
      expect(f.targets.saveCalls, 0);
    },
  );
  testWidgets(
    'personal planner protects numeric edits on close and explicit defer',
    (tester) async {
      final f = NutritionPlanFixture();
      await f.start(tester, QualityKind.personal);
      await qualityInput(tester, 'nutrition-plan-weight', '72');
      await qualityTap(tester, find.byTooltip('Đóng'));
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
      await qualityTap(tester, find.text('Tiếp tục nhập'));
      expect(qualityText(tester, 'nutrition-plan-weight'), '72');
      await qualityTap(tester, find.text('Để sau, giữ mục tiêu hiện tại'));
      await qualityTap(tester, find.text('Bỏ thay đổi'));
      expect(find.byKey(const ValueKey('nutrition-plan-scroll')), findsNothing);
      expect(f.targets.saveCalls, 0);
    },
  );
  testWidgets('personal planner protects dropdown-only edits and Back', (
    tester,
  ) async {
    final f = NutritionPlanFixture();
    await f.start(tester, QualityKind.personal);
    await qualityTap(tester, find.byKey(const ValueKey('nutrition-plan-sex')));
    await qualityTap(tester, find.text('Nam · hệ số nghiên cứu').last);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
    await qualityTap(tester, find.text('Tiếp tục nhập'));
    expect(find.text('Nam · hệ số nghiên cứu'), findsOneWidget);
    expect(f.targets.saveCalls, 0);
  });
  testWidgets('plan search alone is not an unsaved meal change', (
    tester,
  ) async {
    final f = NutritionPlanFixture();
    await f.start(tester, QualityKind.meal);
    await qualityInput(tester, 'plan-food-search', 'cơm');
    await qualityTap(tester, find.byTooltip('Đóng'));
    expect(find.byType(PlanMealDialog), findsNothing);
    expect(find.text('Bỏ thay đổi chưa lưu?'), findsNothing);
    expect(f.attempts, isEmpty);
  });
  testWidgets(
    'removed planned food is retained after canceling Back and only discarded explicitly',
    (tester) async {
      final f = NutritionPlanFixture();
      await f.start(tester, QualityKind.meal);
      await qualityTap(tester, find.byTooltip('Bỏ món'));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
      await qualityTap(tester, find.text('Tiếp tục nhập'));
      expect(find.byTooltip('Bỏ món'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('save-meal-plan')))
            .onPressed,
        isNull,
      );
      await qualityTap(tester, find.byTooltip('Đóng'));
      await qualityTap(tester, find.text('Bỏ thay đổi'));
      expect(find.byType(PlanMealDialog), findsNothing);
      expect(f.attempts, isEmpty);
    },
  );
  testWidgets(
    'changed plan quantity prompts before leaving and is saved precisely after continuing',
    (tester) async {
      final f = NutritionPlanFixture();
      await f.start(tester, QualityKind.meal);
      await qualityTap(
        tester,
        find.ancestor(
          of: find.byTooltip('Bỏ món'),
          matching: find.byType(ListTile),
        ),
      );
      await qualityInput(tester, 'meal-grams', '225.5');
      await qualityTap(tester, find.text('Xác nhận'));
      await qualityTap(tester, find.byTooltip('Đóng'));
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
      await qualityTap(tester, find.text('Tiếp tục nhập'));
      await qualityTap(tester, find.byKey(const ValueKey('save-meal-plan')));
      expect(f.attempts.single.items.single.grams, 225.5);
      expect(
        f.attempts.single.items.single.nutrition.kcal,
        closeTo(293.15, .00001),
      );
      expect(find.byType(PlanMealDialog), findsNothing);
    },
  );
  testWidgets(
    'pending plan blocks duplicate submits and Back; failure retries the same snapshot',
    (tester) async {
      final f = NutritionPlanFixture();
      await f.start(tester, QualityKind.meal);
      f.pendingPlan = Completer<void>();
      f.failPlan = true;
      final save = find.byKey(const ValueKey('save-meal-plan'));
      await tester.tap(save);
      await tester.pump();
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(PlanMealDialog), findsOneWidget);
      expect(f.attempts, hasLength(1));
      f.pendingPlan!.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('Thông tin vẫn được giữ'), findsOneWidget);
      f.pendingPlan = null;
      f.failPlan = false;
      await qualityTap(tester, save);
      expect(f.attempts, hasLength(2));
      expect(
        f.attempts[0].items.single.toData(),
        f.attempts[1].items.single.toData(),
      );
      expect(find.byType(PlanMealDialog), findsNothing);
    },
  );
  testWidgets(
    'meal planner uses the shared clock and enables logging when the planned day arrives',
    (tester) async {
      final f = NutritionPlanFixture();
      await f.start(tester, QualityKind.panel);
      expect(find.text('Xác nhận đã ăn'), findsNothing);
      f.clock = DateTime(2026, 11, 10, 0, 1);
      f.container.invalidate(localClockProvider);
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận đã ăn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
