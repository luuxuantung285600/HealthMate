import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/food_library/models/food_library_models.dart';
import 'package:healthmate/features/food_library/models/ingredient_selection.dart';
import 'package:healthmate/features/food_library/presentation/delete_library_entry_dialog.dart';
import 'package:healthmate/features/food_library/presentation/library_forms.dart';
import 'package:healthmate/features/food_library/presentation/food_portion_dialog.dart';
import 'package:healthmate/features/nutrition/models/food_visibility.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_food_library_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/test_app.dart';

PersonalFood ownFood({double kcal = 130}) => PersonalFood(
  id: 'personal',
  name: 'Cơm nhà nấu',
  per100g: NutritionTotals(
    kcal: kcal,
    proteinG: 2.69123,
    carbsG: 28.17123,
    fatG: .28123,
  ),
  defaultServingGrams: 123.45678,
);

FoodRecipe ownRecipe() => FoodRecipe(
  id: 'recipe',
  name: 'Công thức ban đầu',
  ingredients: [
    MealItemSnapshot.fromCatalog(FakeNutritionRepository.rice, 150.12345),
  ],
  yieldGrams: 200.45678,
  servingsCount: 2.45678,
);

FakeFoodLibraryRepository libraryFixture() => FakeFoodLibraryRepository()
  ..seed('test-uid', ownFood())
  ..seed('test-uid', ownRecipe());

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find.byType(Scrollable).last,
    );
  } else {
    await tester.ensureVisible(finder);
  }
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> editText(WidgetTester tester, String key, String value) async {
  final field = find.byKey(ValueKey(key));
  if (field.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      field,
      180,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

class LiveIngredientRepository extends FakeNutritionRepository {
  List<FoodCatalogItem> foods = [
    FakeNutritionRepository.rice,
    FakeNutritionRepository.egg,
  ];
  FoodVisibility visibility = const FoodVisibility();
  final changes = StreamController<void>.broadcast();
  Stream<T> watch<T>(T Function() read) => Stream.multi((c) {
    c.add(read());
    final sub = changes.stream.listen((_) => c.add(read()));
    c.onCancel = sub.cancel;
  });
  @override
  Stream<List<FoodCatalogItem>> watchFoodCatalog() => watch(() => foods);
  @override
  Stream<FoodVisibility> watchFoodVisibility() => watch(() => visibility);
  void update() => changes.add(null);
  @override
  Future<void> dispose() async {
    await changes.close();
    await super.dispose();
  }
}

void main() {
  for (final recipe in [false, true]) {
    testWidgets(
      '${recipe ? 'recipe' : 'personal'} Back/Cancel protects unsaved text and unchanged form closes',
      (tester) async {
        final library = libraryFixture();
        final container = await pumpApp(
          tester,
          libraryRepository: library,
          size: const Size(320, 740),
          textScale: 1.6,
        );
        container.read(appRouterProvider).go(AppRoutes.foodLibrary);
        await tester.pumpAndSettle();
        if (recipe) {
          await tapVisible(
            tester,
            find.widgetWithText(ChoiceChip, 'Công thức'),
          );
        }
        final edit = find.byKey(
          ValueKey(recipe ? 'edit-recipe-recipe' : 'edit-custom-personal'),
        );
        await tapVisible(tester, edit);
        await tapVisible(tester, find.byTooltip('Hủy'));
        expect(find.text('Bỏ thay đổi chưa lưu?'), findsNothing);
        await tapVisible(tester, edit);
        final name = recipe ? 'recipe-name' : 'library-name';
        await editText(tester, name, 'Tên đang nhập');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
        await tapVisible(tester, find.text('Tiếp tục nhập'));
        expect(
          tester
              .widget<TextFormField>(find.byKey(ValueKey(name)))
              .controller!
              .text,
          'Tên đang nhập',
        );
        expect(library.saveCalls, 0);
        await tapVisible(tester, find.byTooltip('Hủy'));
        await tapVisible(tester, find.text('Bỏ thay đổi'));
        expect(
          find.byType(recipe ? RecipeForm : PersonalFoodForm),
          findsNothing,
        );
        expect(library.saveCalls, 0);
      },
    );
  }

  testWidgets(
    'ingredient-only edits are protected without changing existing snapshots',
    (tester) async {
      final library = libraryFixture();
      final original = ownRecipe().ingredients.single;
      final container = await pumpApp(tester, libraryRepository: library);
      container.read(appRouterProvider).go(AppRoutes.foodLibrary);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Công thức'));
      await tapVisible(
        tester,
        find.byKey(const ValueKey('edit-recipe-recipe')),
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('remove-ingredient-0')),
      );
      await tapVisible(tester, find.byTooltip('Hủy'));
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
      await tapVisible(tester, find.text('Tiếp tục nhập'));
      expect(
        find.text('0/6 nguyên liệu · Chỉ catalog hoặc Món của tôi'),
        findsOneWidget,
      );
      final stored = library.byUid['test-uid']!['recipe:recipe'] as FoodRecipe;
      expect(stored.ingredients.single.toData(), original.toData());
      expect(library.saveCalls, 0);
    },
  );

  testWidgets('saving a name preserves nutrition and portion precision', (
    tester,
  ) async {
    final library = libraryFixture();
    final original = ownFood();
    final container = await pumpApp(tester, libraryRepository: library);
    container.read(appRouterProvider).go(AppRoutes.foodLibrary);
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(const ValueKey('edit-custom-personal')),
    );
    await editText(tester, 'library-name', 'Tên món đã sửa');
    await tapVisible(tester, find.byKey(const ValueKey('library-save')));
    final saved = library.byUid['test-uid']!['custom:personal'] as PersonalFood;
    expect(saved.per100g.proteinG, original.per100g.proteinG);
    expect(saved.defaultServingGrams, original.defaultServingGrams);
    expect(saved.name, 'Tên món đã sửa');
    expect(find.byType(PersonalFoodForm), findsNothing);
  });

  testWidgets(
    'delete waits for ACK, blocks duplicate calls and retries the same entry',
    (tester) async {
      final library = libraryFixture()..pending = Completer<void>();
      final container = await pumpApp(tester, libraryRepository: library);
      container.read(appRouterProvider).go(AppRoutes.foodLibrary);
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byKey(const ValueKey('delete-custom-personal')),
      );
      final button = find.byKey(const ValueKey('confirm-delete-library'));
      await tester.tap(button);
      await tester.pump();
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();
      expect(library.deleteCalls, 1);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(find.byType(DeleteLibraryEntryDialog), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(DeleteLibraryEntryDialog), findsOneWidget);
      library.failWrite = true;
      library.pending!.complete();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Chưa xác nhận xóa thành công'),
        findsOneWidget,
      );
      expect(library.byUid['test-uid']!.containsKey('custom:personal'), isTrue);
      library.pending = null;
      library.failWrite = false;
      await tapVisible(tester, button);
      expect(library.deleteCalls, 2);
      expect(library.writtenUids, ['test-uid', 'test-uid']);
      expect(find.byType(DeleteLibraryEntryDialog), findsNothing);
      expect(
        library.byUid['test-uid']!.containsKey('custom:personal'),
        isFalse,
      );
    },
  );

  testWidgets(
    'logout during deletion discards the dialog and late success message',
    (tester) async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final library = libraryFixture()..pending = Completer<void>();
      final container = await pumpApp(
        tester,
        repository: auth,
        libraryRepository: library,
      );
      container.read(appRouterProvider).go(AppRoutes.foodLibrary);
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byKey(const ValueKey('delete-custom-personal')),
      );
      await tester.tap(find.byKey(const ValueKey('confirm-delete-library')));
      await tester.pump();
      auth.emitUser(null);
      await tester.pumpAndSettle();
      expect(find.byType(DeleteLibraryEntryDialog), findsNothing);
      library.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Đã xóa nguồn khỏi thư viện.'), findsNothing);
      expect(library.writtenUids, ['test-uid']);
    },
  );

  for (final change in [
    'catalog-hidden',
    'catalog-updated',
    'personal-removed',
    'personal-updated',
  ]) {
    testWidgets('ingredient selection rejects $change while portion is open', (
      tester,
    ) async {
      final library = libraryFixture(), nutrition = LiveIngredientRepository();
      final container = await pumpApp(
        tester,
        libraryRepository: library,
        nutritionRepository: nutrition,
      );
      container.read(appRouterProvider).go(AppRoutes.foodLibrary);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Công thức'));
      await tapVisible(
        tester,
        find.byKey(const ValueKey('edit-recipe-recipe')),
      );
      await tapVisible(tester, find.byKey(const ValueKey('add-ingredient')));
      final personal = change.startsWith('personal');
      if (personal) {
        await tapVisible(
          tester,
          find.descendant(
            of: find.byType(IngredientPicker),
            matching: find.widgetWithText(ChoiceChip, 'Món của tôi'),
          ),
        );
      }
      final selectedName = personal
          ? 'Cơm nhà nấu'
          : FakeNutritionRepository.rice.name;
      await tapVisible(tester, find.widgetWithText(ListTile, selectedName));
      expect(find.byType(FoodPortionDialog), findsOneWidget);
      switch (change) {
        case 'catalog-hidden':
          nutrition.visibility = const FoodVisibility(
            hiddenIds: {'rice-cooked'},
          );
          nutrition.update();
        case 'catalog-updated':
          final old = FakeNutritionRepository.rice;
          nutrition.foods = [
            FoodCatalogItem(
              id: old.id,
              name: old.name,
              category: old.category,
              servingBasis: old.servingBasis,
              per100g: const NutritionTotals(kcal: 200),
              sourceLabel: old.sourceLabel,
              isEstimated: true,
            ),
            FakeNutritionRepository.egg,
          ];
          nutrition.update();
        case 'personal-removed':
          library.byUid['test-uid']!.remove('custom:personal');
          library.refresh();
        case 'personal-updated':
          library.seed('test-uid', ownFood(kcal: 200));
          library.refresh();
      }
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Xác nhận'));
      expect(find.byType(IngredientPicker), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ingredient-selection-error')),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          change.endsWith('updated') ? 'vừa thay đổi' : 'đã bị xóa',
        ),
        findsOneWidget,
      );
      expect(library.saveCalls, 0);
      await tapVisible(tester, find.byTooltip('Hủy').last);
      expect(
        find.text('1/6 nguyên liệu · Chỉ catalog hoặc Món của tôi'),
        findsOneWidget,
      );
      final stored = library.byUid['test-uid']!['recipe:recipe'] as FoodRecipe;
      expect(
        stored.ingredients.single.nutrition.kcal,
        ownRecipe().ingredients.single.nutrition.kcal,
      );
    });
  }

  testWidgets(
    'changed ingredient can be reviewed again and adds the current snapshot',
    (tester) async {
      final library = libraryFixture(), nutrition = LiveIngredientRepository();
      final container = await pumpApp(
        tester,
        libraryRepository: library,
        nutritionRepository: nutrition,
      );
      container.read(appRouterProvider).go(AppRoutes.foodLibrary);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Công thức'));
      await tapVisible(
        tester,
        find.byKey(const ValueKey('edit-recipe-recipe')),
      );
      await tapVisible(tester, find.byKey(const ValueKey('add-ingredient')));
      final tile = find.widgetWithText(
        ListTile,
        FakeNutritionRepository.rice.name,
      );
      await tapVisible(tester, tile);
      final old = FakeNutritionRepository.rice;
      nutrition.foods = [
        FoodCatalogItem(
          id: old.id,
          name: old.name,
          category: old.category,
          servingBasis: old.servingBasis,
          per100g: const NutritionTotals(kcal: 200),
          sourceLabel: old.sourceLabel,
          isEstimated: true,
        ),
      ];
      nutrition.update();
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Xác nhận'));
      expect(find.textContaining('vừa thay đổi'), findsOneWidget);
      await tapVisible(tester, tile);
      expect(
        find.byKey(const ValueKey('ingredient-selection-error')),
        findsNothing,
      );
      await tester.enterText(find.byKey(const ValueKey('meal-grams')), '50');
      await tapVisible(tester, find.text('Xác nhận'));
      expect(find.byType(IngredientPicker), findsNothing);
      expect(
        find.text('2/6 nguyên liệu · Chỉ catalog hoặc Món của tôi'),
        findsOneWidget,
      );
      await tapVisible(tester, find.byKey(const ValueKey('library-save')));
      final saved = library.byUid['test-uid']!['recipe:recipe'] as FoodRecipe;
      expect(saved.ingredients.last.grams, 50);
      expect(saved.ingredients.last.nutrition.kcal, 100);
      expect(
        saved.ingredients.first.toData(),
        ownRecipe().ingredients.first.toData(),
      );
    },
  );

  testWidgets(
    'partial macros remain visible with an explanation and cannot be selected',
    (tester) async {
      final nutrition = LiveIngredientRepository()
        ..foods = [
          FoodCatalogItem(
            id: 'partial',
            name: 'Món thiếu protein',
            category: '',
            servingBasis: ServingBasis.per100g,
            per100g: const NutritionTotals(kcal: 100, proteinKnown: false),
            sourceLabel: 'Fixture',
            isEstimated: true,
          ),
        ];
      final container = await pumpApp(
        tester,
        libraryRepository: libraryFixture(),
        nutritionRepository: nutrition,
      );
      container.read(appRouterProvider).go(AppRoutes.foodLibrary);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Công thức'));
      await tapVisible(
        tester,
        find.byKey(const ValueKey('edit-recipe-recipe')),
      );
      await tapVisible(tester, find.byKey(const ValueKey('add-ingredient')));
      final tile = find.widgetWithText(ListTile, 'Món thiếu protein');
      expect(tester.widget<ListTile>(tile).onTap, isNull);
      expect(find.text('Thiếu dữ liệu dinh dưỡng'), findsOneWidget);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.byType(FoodPortionDialog), findsNothing);
    },
  );

  testWidgets(
    'logout with ingredient portion open removes the entire private dialog stack',
    (tester) async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser),
          library = libraryFixture();
      final container = await pumpApp(
        tester,
        repository: auth,
        libraryRepository: library,
      );
      container.read(appRouterProvider).go(AppRoutes.foodLibrary);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Công thức'));
      await tapVisible(
        tester,
        find.byKey(const ValueKey('edit-recipe-recipe')),
      );
      await editText(tester, 'recipe-name', 'Bản nháp riêng tư');
      await tapVisible(tester, find.byKey(const ValueKey('add-ingredient')));
      await tapVisible(
        tester,
        find.widgetWithText(ListTile, FakeNutritionRepository.rice.name),
      );
      expect(find.byType(FoodPortionDialog), findsOneWidget);
      auth.emitUser(null);
      await tester.pumpAndSettle();
      expect(find.byType(RecipeForm), findsNothing);
      expect(find.byType(IngredientPicker), findsNothing);
      expect(find.byType(FoodPortionDialog), findsNothing);
      expect(find.text('Bản nháp riêng tư'), findsNothing);
      expect(library.saveCalls, 0);
    },
  );

  test(
    'recipe ingredient validation rejects partial macros; revision ignores extra-nutrient map order',
    () {
      final partial = FoodCatalogItem(
        id: 'p',
        name: 'Chưa đủ',
        category: '',
        servingBasis: ServingBasis.per100g,
        per100g: const NutritionTotals(kcal: 100, proteinKnown: false),
        sourceLabel: 'Fixture',
        isEstimated: true,
      );
      expect(canUseRecipeIngredient(partial), isFalse);
      expect(canUseRecipeIngredient(FakeNutritionRepository.rice), isTrue);
      FoodCatalogItem food(Map<String, double> extra) => FoodCatalogItem(
        id: 'a',
        name: 'Đủ',
        category: '',
        servingBasis: ServingBasis.per100g,
        per100g: NutritionTotals(kcal: 100, extraNutrients: extra),
        sourceLabel: 'Fixture',
        isEstimated: true,
      );
      expect(
        ingredientSelectionRevision(food({'sodium': 1, 'calcium': 2})),
        ingredientSelectionRevision(food({'calcium': 2, 'sodium': 1})),
      );
    },
  );
}
