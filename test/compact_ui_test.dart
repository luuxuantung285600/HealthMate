import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/widgets/details_disclosure.dart';
import 'package:healthmate/features/goals/providers/goals_providers.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/nutrition_targets/presentation/nutrition_target_card.dart';
import 'package:healthmate/features/weekly_reflection/presentation/weekly_reflection_card.dart';

import 'support/fake_nutrition_repository.dart';
import 'support/test_app.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty &&
      find.byKey(const ValueKey('meal-manual-content')).evaluate().isNotEmpty) {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('meal-manual-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Today keeps secondary reports closed and loads them only on request',
    (tester) async {
      final nutrition = FakeNutritionRepository();
      final container = await pumpApp(tester, nutritionRepository: nutrition);
      expect(find.byType(NutritionTargetCard), findsNothing);
      expect(find.byType(WeeklyReflectionCard), findsNothing);
      expect(container.exists(goalsProvider), isFalse);
      expect(nutrition.rangeCalls, 0);
      expect(find.text('Xem tiến độ tuần'), findsNothing);
      expect(find.text('Chưa ghi bữa này'), findsNothing);
      expect(find.text('Chưa ghi món'), findsNWidgets(4));
      await openDashboardDetails(tester);
      expect(find.byType(NutritionTargetCard), findsOneWidget);
      expect(find.byType(WeeklyReflectionCard), findsOneWidget);
      expect(container.exists(goalsProvider), isTrue);
      await tapVisible(tester, find.text('Xem thêm'));
      expect(find.byType(NutritionTargetCard), findsNothing);
      expect(find.byType(WeeklyReflectionCard), findsNothing);
      expect(nutrition.rangeCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets(
      'short guidance opens on demand and closes at text scale $scale',
      (tester) async {
        final container = await pumpApp(
          tester,
          textScale: scale,
          size: const Size(320, 844),
          featureFlags: const AppFeatureFlags(foodScannerEnabled: true),
        );
        expect(find.textContaining('Thanh màu thể hiện'), findsNothing);
        // Home shows compact, labelled nutrients; contextual explanations are
        // opened from the journal control they describe.
        container.read(appRouterProvider).go(AppRoutes.journal);
        await tester.pumpAndSettle();
        expect(
          find.text('Tổng theo ngày đã chọn, dựa trên các lần bạn tự ghi.'),
          findsNothing,
        );
        await tapVisible(tester, find.byTooltip('Về Nước uống'));
        expect(
          find.text('Tổng theo ngày đã chọn, dựa trên các lần bạn tự ghi.'),
          findsOneWidget,
        );
        await tapVisible(tester, find.text('Đóng'));
        await tapVisible(
          tester,
          find.byKey(const ValueKey('journal-add-meal')),
        );
        expect(find.byType(MealFormDialog), findsOneWidget);
        expect(find.textContaining('Mỗi bản ghi tối đa 5 món.'), findsNothing);
        await tapVisible(tester, find.text('Lưu ý khi ghi bữa'));
        expect(
          find.textContaining('Mỗi bản ghi tối đa 5 món.'),
          findsOneWidget,
        );
        expect(find.byType(AlertDialog), findsNothing);
        await tapVisible(tester, find.text('Lưu ý khi ghi bữa'));
        expect(find.textContaining('Mỗi bản ghi tối đa 5 món.'), findsNothing);
        expect(find.byKey(const ValueKey('save-meal')), findsOneWidget);
        await openMealTools(tester);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('scan-barcode')),
          -180,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('meal-manual-content')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(find.byKey(const ValueKey('scan-barcode')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('collapsed disclosure never builds secondary content', (
    tester,
  ) async {
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DetailsDisclosure(
            title: 'Chi tiết',
            builder: (_) {
              builds++;
              return const Text('Thông tin đầy đủ');
            },
          ),
        ),
      ),
    );
    expect(builds, 0);
    await tester.tap(find.text('Chi tiết'));
    await tester.pumpAndSettle();
    expect(find.text('Thông tin đầy đủ'), findsOneWidget);
    expect(builds, 1);
    await tester.tap(find.text('Chi tiết'));
    await tester.pumpAndSettle();
    expect(find.text('Thông tin đầy đủ'), findsNothing);
    expect(builds, 1);
  });
}
