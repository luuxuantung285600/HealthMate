import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/reports/models/macro_energy_report.dart';
import 'package:healthmate/features/reports/models/period_report.dart';
import 'package:healthmate/features/reports/presentation/macro_energy_card.dart';
import 'package:healthmate/features/reports/providers/report_providers.dart';
import 'package:healthmate/features/weekly_reflection/models/weekly_reflection.dart';
import 'package:healthmate/features/weekly_reflection/providers/weekly_reflection_providers.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/test_app.dart';

final _today = DateTime(2026, 11, 7);
final _range = ReportRange(DateTime(2026, 11, 9), 7);

MealItemSnapshot _food({
  String name = 'Món kiểm thử',
  NutritionTotals nutrition = const NutritionTotals(
    kcal: 1234,
    carbsG: 100,
    proteinG: 60,
    fatG: 40,
  ),
  bool available = true,
}) => MealItemSnapshot(
  foodId: 'fixture',
  name: name,
  grams: 250,
  nutrition: nutrition,
  hasNutritionData: available,
  sourceLabel: 'Fixture chỉ dùng trong kiểm thử',
  isEstimated: true,
);

MealLog _meal(
  String id, {
  List<MealItemSnapshot>? items,
  DateTime? at,
  String? dateKey,
}) {
  final saved = items ?? [_food()];
  return MealLog(
    id: id,
    type: MealType.lunch,
    consumedAt: at ?? DateTime(2026, 11, 3, 12),
    dateKey: dateKey,
    items: saved,
    totals: sumNutritionTotals(saved.map((item) => item.nutrition)),
    source: MealSource.manual,
  );
}

MacroEnergyReport _report(List<MealLog> meals) =>
    MacroEnergyReport(meals: meals, range: _range, today: _today);

typedef _Input = ({List<MealLog> meals, ReportRange range, String owner});

Future<({ValueNotifier<_Input> input, FakeAuthRepository auth})> _open(
  WidgetTester tester, {
  List<MealLog>? meals,
  double width = 390,
  double scale = 1,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final input = ValueNotifier<_Input>((
    meals: meals ?? [_meal('one')],
    range: _range,
    owner: 'test-uid',
  ));
  final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(auth)],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    input.dispose();
    await auth.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: ValueListenableBuilder<_Input>(
            valueListenable: input,
            builder: (_, data, child) => ListView(
              children: [
                MacroEnergyCard(
                  ownerUid: data.owner,
                  meals: data.meals,
                  range: data.range,
                  today: _today,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (input: input, auth: auth);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  test('4/4/9 denominator uses saved item macros, not total kcal or mass', () {
    final report = _report([_meal('one')]);
    expect(report.totalEnergy, 1000);
    expect(report.energy(EnergyMacro.carbs), 400);
    expect(report.percent(EnergyMacro.carbs), 40);
    expect(report.percent(EnergyMacro.protein), 24);
    expect(report.percent(EnergyMacro.fat), 36);
    expect(report.grams(EnergyMacro.fat), 40);
    expect(report.contributions(EnergyMacro.carbs).single.item.grams, 250);
    expect(report.estimatedItemCount, 1);
  });

  test('snapshot quantity in ml is never converted to grams or rescaled', () {
    const item = MealItemSnapshot(
      foodId: 'drink',
      name: 'Fixture ml',
      grams: 0,
      quantityUnit: 'ml',
      quantityValue: 300,
      nutrition: NutritionTotals(carbsG: 20),
      sourceLabel: 'test',
      isEstimated: false,
    );
    final report = _report([
      _meal('drink', items: [item]),
    ]);
    expect(report.totalEnergy, 80);
    expect(report.percent(EnergyMacro.carbs), 100);
    expect(report.contributions(EnergyMacro.carbs).single.item.quantity, 300);
  });

  test('unknown zero and malformed data do not become a complete chart', () {
    for (final item in [
      _food(nutrition: const NutritionTotals(carbsKnown: false)),
      _food(nutrition: const NutritionTotals(proteinKnown: false)),
      _food(nutrition: const NutritionTotals(fatKnown: false)),
      _food(available: false),
      _food(nutrition: const NutritionTotals(carbsG: double.nan)),
      _food(nutrition: const NutritionTotals(proteinG: -1)),
      _food(nutrition: const NutritionTotals(fatG: double.infinity)),
    ]) {
      final report = _report([
        _meal('partial', items: [item, _food()]),
      ]);
      expect(report.complete, false);
      expect(report.incompleteItemCount, 1);
      expect(report.percent(EnergyMacro.carbs), isNull);
      expect(report.contributions(EnergyMacro.carbs), isEmpty);
    }
  });

  test(
    'empty meals and complete zero stay distinct without division by zero',
    () {
      expect(_report([]).mealCount, 0);
      final legacy = _report([_meal('missing', items: [])]);
      expect(legacy.complete, false);
      expect(legacy.missingMealCount, 1);
      final zero = _report([
        _meal('zero', items: [_food(nutrition: NutritionTotals.zero)]),
      ]);
      expect(zero.complete, true);
      expect(zero.totalEnergy, 0);
      expect(zero.percent(EnergyMacro.carbs), isNull);
    },
  );

  test(
    'dateKey, inclusive range, future cutoff and meal dedup are consistent',
    () {
      final one = _meal('one');
      final logs = [
        one,
        one,
        _meal('start', dateKey: '2026-11-02'),
        _meal('today', dateKey: '2026-11-07'),
        _meal('before', dateKey: '2026-11-01'),
        _meal('future', dateKey: '2026-11-08'),
        _meal('after', dateKey: '2026-11-09'),
        _meal('tz', at: DateTime.utc(2026, 10, 31), dateKey: '2026-11-04'),
      ];
      final report = _report(logs);
      expect(report.mealCount, 4);
      expect(report.totalEnergy, 4000);
      expect(
        report.items.map((row) => row.meal.id),
        unorderedEquals(['one', 'start', 'today', 'tz']),
      );
    },
  );

  test(
    'drill down retains repeated foods and ranks by energy contribution',
    () {
      final report = _report([
        _meal('a', items: [_food(), _food()]),
        _meal('b', items: [_food()]),
        _meal(
          'small',
          items: [_food(nutrition: const NutritionTotals(carbsG: 1))],
        ),
      ]);
      final rows = report.contributions(EnergyMacro.carbs);
      expect(rows, hasLength(4));
      expect(rows.first.meal.id, 'a');
      expect(rows[1].itemIndex, 1);
      expect(rows.last.meal.id, 'small');
      expect(
        rows.fold(0.0, (sum, row) => sum + row.energy(EnergyMacro.carbs)),
        report.energy(EnergyMacro.carbs),
      );
    },
  );

  testWidgets('pie tap and accessible legend open details; Back keeps chart', (
    tester,
  ) async {
    await _open(tester);
    final pie = find.byKey(const ValueKey('macro-energy-pie'));
    expect(pie, findsOneWidget);
    expect(find.text('1000 kcal từ ba dưỡng chất'), findsOneWidget);
    final center = tester.getCenter(pie);
    await tester.tapAt(center + const Offset(52, 25));
    await tester.pumpAndSettle();
    expect(find.text('Đóng góp năng lượng từ Carb'), findsOneWidget);
    expect(find.text('Món kiểm thử'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('macro-energy-detail-title')),
      findsNothing,
    );
    expect(pie, findsOneWidget);
    await _tap(tester, 'macro-energy-protein');
    expect(find.text('Đóng góp năng lượng từ Đạm'), findsOneWidget);
    await _tap(tester, 'close-macro-energy-detail');
    expect(
      find.byKey(const ValueKey('macro-energy-detail-title')),
      findsNothing,
    );
  });

  testWidgets('empty, incomplete and zero display explanations with no pie', (
    tester,
  ) async {
    final fixture = await _open(tester, meals: []);
    expect(find.byKey(const ValueKey('macro-energy-empty')), findsOneWidget);
    for (final entry in [
      (
        _food(nutrition: const NutritionTotals(carbsKnown: false)),
        'macro-energy-incomplete',
      ),
      (_food(nutrition: NutritionTotals.zero), 'macro-energy-zero'),
    ]) {
      fixture.input.value = (
        meals: [
          _meal('one', items: [entry.$1]),
        ],
        range: _range,
        owner: 'test-uid',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(entry.$2)), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
    }
  });

  testWidgets(
    'same-range update recalculates open details, range change closes',
    (tester) async {
      final fixture = await _open(tester);
      await _tap(tester, 'macro-energy-carbs');
      fixture.input.value = (
        meals: [
          _meal('new', items: [_food(name: 'Món mới')]),
        ],
        range: _range,
        owner: 'test-uid',
      );
      await tester.pumpAndSettle();
      expect(find.text('Món kiểm thử'), findsNothing);
      expect(find.text('Món mới'), findsOneWidget);
      fixture.input.value = (
        meals: [],
        range: ReportRange(DateTime(2026, 11, 2), 7),
        owner: 'test-uid',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('macro-energy-detail-title')),
        findsNothing,
      );
      expect(find.text('Món mới'), findsNothing);
      expect(find.byKey(const ValueKey('macro-energy-empty')), findsOneWidget);
    },
  );

  testWidgets(
    'old-owner report vanishes on account change even before new data',
    (tester) async {
      final fixture = await _open(tester);
      await _tap(tester, 'macro-energy-carbs');
      fixture.auth.emitUser(
        const AuthUser(
          uid: 'bob',
          email: 'bob@example.test',
          emailVerified: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PieChart), findsNothing);
      expect(find.text('Món kiểm thử'), findsNothing);
      fixture.input.value = (
        meals: [
          _meal('bob', items: [_food(name: 'Món của B')]),
        ],
        range: _range,
        owner: 'bob',
      );
      await tester.pumpAndSettle();
      expect(find.byType(PieChart), findsOneWidget);
      expect(
        find.byKey(const ValueKey('macro-energy-detail-title')),
        findsNothing,
      );
    },
  );

  testWidgets('large reports render details in bounded groups of twenty', (
    tester,
  ) async {
    await _open(tester, meals: [for (var i = 0; i < 45; i++) _meal('row-$i')]);
    await _tap(tester, 'macro-energy-carbs');
    Finder rows() => find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('macro-food-'),
      skipOffstage: false,
    );
    expect(rows(), findsNWidgets(20));
    await _tap(tester, 'more-macro-energy-items');
    expect(rows(), findsNWidgets(40));
    await _tap(tester, 'more-macro-energy-items');
    expect(rows(), findsNWidgets(45));
    expect(find.byKey(const ValueKey('more-macro-energy-items')), findsNothing);
  });

  for (final width in [320.0, 390.0, 720.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final brightness in Brightness.values) {
        testWidgets('macro chart fits $width / $scale / $brightness', (
          tester,
        ) async {
          await _open(
            tester,
            width: width,
            scale: scale,
            brightness: brightness,
          );
          await _tap(tester, 'macro-energy-fat');
          expect(find.text('Đóng góp năng lượng từ Chất béo'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets(
    'weekly and period use existing reads; Back retains week/filter',
    (tester) async {
      final repo = FakeNutritionRepository(meals: [_meal('one')]);
      final container = await pumpApp(
        tester,
        nutritionRepository: repo,
        dashboardNow: _today,
      );
      try {
        container.read(appRouterProvider).go(AppRoutes.progress);
        await tester.pumpAndSettle();
        final baselineReads = repo.rangeCalls;
        await _tap(tester, 'progress-tab-3');
        expect(find.byType(PieChart), findsOneWidget);
        await _tap(tester, 'macro-energy-carbs');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(PieChart), findsOneWidget);
        expect(repo.rangeCalls, baselineReads);
        final before = repo.rangeCalls;
        await _tap(tester, 'previous-week');
        expect(
          find.byKey(const ValueKey('macro-energy-empty')),
          findsOneWidget,
        );
        await _tap(tester, 'next-week');
        expect(find.byType(PieChart), findsOneWidget);
        expect(repo.rangeCalls, greaterThanOrEqualTo(before));
        await _tap(tester, 'report-window-30');
        expect(find.byType(PieChart), findsOneWidget);
        final periodReads = repo.rangeCalls;
        await _tap(tester, 'macro-energy-carbs');
        expect(repo.rangeCalls, periodReads);
        final period = periodMealsProvider(
          ReportRange(DateTime(2026, 11, 8), 30),
        );
        repo.rangePending = Completer<void>();
        container.invalidate(period);
        await tester.pump();
        await tester.pump();
        expect(find.byType(PieChart), findsNothing);
        expect(
          find.byKey(const ValueKey('macro-energy-detail-title')),
          findsNothing,
        );
        await repo.updateMeal(
          uid: 'test-uid',
          mealId: 'one',
          draft: MealDraft(
            type: MealType.lunch,
            consumedAt: DateTime(2026, 11, 3, 12),
            items: [_food(nutrition: const NutritionTotals(carbsG: 50))],
            source: MealSource.manual,
          ),
        );
        repo.rangePending!.complete();
        repo.rangePending = null;
        await tester.pumpAndSettle();
        expect(find.byType(PieChart), findsOneWidget);
        expect(find.text('200 kcal từ ba dưỡng chất'), findsOneWidget);
        repo.rangeError = StateError('fixture report unavailable');
        container.invalidate(period);
        await tester.pumpAndSettle();
        expect(find.byType(PieChart), findsNothing);
        expect(find.text('200 kcal từ ba dưỡng chất'), findsNothing);
        repo.rangeError = null;
        container.invalidate(period);
        await tester.pumpAndSettle();
        expect(find.text('200 kcal từ ba dưỡng chất'), findsOneWidget);
        container.invalidate(weeklyLogsProvider(weekStart(_today)));
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        await tester.pump();
      }
    },
  );
}
