import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:healthmate/features/food_scanner/data/food_camera_service.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'support/fake_food_camera.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/test_app.dart';

final at = DateTime(2026, 10, 28, 12);
final rice = MealItemSnapshot.fromCatalog(FakeNutritionRepository.rice, 150);

Future<void> openForm(
  WidgetTester tester,
  MealFormDialog form, {
  void Function(MealDraft?)? onResult,
}) async {
  showDialog<MealDraft>(
    context: tester.element(find.byKey(const ValueKey('nav-dashboard')).first),
    barrierDismissible: false,
    builder: (_) => form,
  ).then((result) => onResult?.call(result));
  await tester.pumpAndSettle();
}

MealFormDialog form({
  List<MealItemSnapshot>? items,
  Future<void> Function(MealDraft)? keep,
  Future<bool> Function(MealDraft)? save,
}) => MealFormDialog(
  catalog: const [FakeNutritionRepository.rice, FakeNutritionRepository.egg],
  initialConsumedAt: at,
  initialType: MealType.lunch,
  initialItems: items ?? [rice],
  onDraftChanged: keep,
  onSave: save,
);

void main() {
  testWidgets(
    'known photo outage opens neither camera nor consent and retains meal',
    (tester) async {
      final camera = FakeFoodCamera();
      await pumpApp(
        tester,
        featureFlags: const AppFeatureFlags(foodScannerEnabled: true),
        foodCameraService: FoodCameraService(createSession: () => camera),
      );
      await openForm(
        tester,
        MealFormDialog(
          catalog: const [FakeNutritionRepository.rice],
          initialConsumedAt: at,
          initialItems: [rice],
          initialEntryMode: MealEntryMode.photo,
        ),
      );
      expect(find.text('Phân tích ảnh chưa sẵn sàng'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('photo-fallback-barcode')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('analyze-food-image')), findsNothing);
      expect(find.byKey(const ValueKey('camera-gallery')), findsNothing);
      expect(camera.starts, 0);
      await tester.tap(find.byKey(const ValueKey('photo-fallback-search')));
      await tester.pumpAndSettle();
      await openSelectedMealItems(tester);
      expect(
        find.byKey(const ValueKey('selected-meal-item-0')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('save-meal')), findsOneWidget);
    },
  );

  testWidgets('clean unsupported form closes without discard prompt', (
    tester,
  ) async {
    await pumpApp(tester);
    await openForm(tester, form());
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(find.byType(MealFormDialog), findsNothing);
    expect(find.text('Bỏ thay đổi chưa lưu?'), findsNothing);
  });

  testWidgets(
    'dirty close and system Back share recovery without losing input',
    (tester) async {
      await pumpApp(tester);
      await openForm(tester, form());
      await tester.tap(find.byTooltip('Bỏ món'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục nhập'));
      await tester.pumpAndSettle();
      expect(find.byType(MealFormDialog), findsOneWidget);
      expect(find.byKey(const ValueKey('selected-meal-item-0')), findsNothing);
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ nháp'));
      await tester.pumpAndSettle();
      expect(find.byType(MealFormDialog), findsNothing);
    },
  );

  testWidgets(
    'failed private draft write blocks close until explicit retry succeeds',
    (tester) async {
      var fail = true;
      final kept = <MealDraft>[];
      await pumpApp(
        tester,
        featureFlags: const AppFeatureFlags(foodScannerEnabled: true),
      );
      await openForm(
        tester,
        form(
          keep: (draft) async {
            if (fail) throw StateError('private disk unavailable');
            kept.add(draft);
          },
        ),
      );
      await tester.tap(find.byKey(const ValueKey('meal-entry-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Đóng và giữ nháp'));
      await tester.pumpAndSettle();
      expect(find.byType(MealFormDialog), findsOneWidget);
      expect(find.textContaining('Chưa giữ được nháp'), findsOneWidget);
      fail = false;
      await tester.tap(find.byTooltip('Đóng và giữ nháp'));
      await tester.pumpAndSettle();
      expect(find.byType(MealFormDialog), findsNothing);
      expect(kept.single.items.single.grams, 150);
    },
  );

  testWidgets('callback-free save returns the confirmed draft', (tester) async {
    MealDraft? result;
    await pumpApp(tester);
    await openForm(tester, form(), onResult: (value) => result = value);
    await tester.tap(find.byKey(const ValueKey('save-meal')));
    await tester.pumpAndSettle();
    expect(result!.items.single.grams, 150);
    expect(find.byType(MealFormDialog), findsNothing);
  });

  for (final width in [320.0, 390.0, 412.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets(
          'meal form keyboard and sources $width $scale ${mode.name}',
          (tester) async {
            await pumpApp(
              tester,
              size: Size(width, 844),
              textScale: scale,
              initialThemeMode: mode,
              featureFlags: const AppFeatureFlags(foodScannerEnabled: true),
            );
            await openForm(tester, form(items: []));
            final search = find.byKey(const ValueKey('food-search'));
            await tester.scrollUntilVisible(
              search,
              180,
              scrollable: find
                  .descendant(
                    of: find.byKey(const ValueKey('meal-manual-content')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.pumpAndSettle();
            await tester.enterText(search, 'cơm');
            tester.view.viewInsets = const FakeViewPadding(bottom: 250);
            addTearDown(tester.view.resetViewInsets);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            tester.view.resetViewInsets();
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('meal-entry-photo')));
            await tester.pumpAndSettle();
            final fallback = find.byKey(
              const ValueKey('photo-fallback-search'),
            );
            await tester.ensureVisible(fallback);
            await tester.pumpAndSettle();
            await tester.tap(fallback);
            await tester.pumpAndSettle();
            expect(tester.widget<TextField>(search).controller!.text, 'cơm');
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
