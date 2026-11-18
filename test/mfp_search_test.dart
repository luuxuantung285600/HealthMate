import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/food_library/presentation/meal_food_sources.dart';
import 'package:healthmate/features/nutrition/data/unified_food_search_service.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'support/test_app.dart';
import 'support/fake_food_search_service.dart';
import 'support/fake_nutrition_repository.dart';

class PendingSearch extends FakeFoodSearchService {
  final pending = <String, Completer<List<FoodSearchResult>>>{};
  @override
  Future<FoodSearchOutcome> search({
    required String query,
    required List<FoodCatalogItem> firestoreCatalog,
    int limit = 25,
    FoodSearchRequest? request,
    void Function(FoodSearchOutcome)? onProgress,
    bool Function(FoodCatalogItem)? matches,
  }) => pending
      .putIfAbsent(query, Completer<List<FoodSearchResult>>.new)
      .future
      .then(FoodSearchOutcome.new);
  void complete(String query, FoodCatalogItem food) => pending[query]!.complete(
    [FoodSearchResult(food: food, source: FoodResultSource.firestore)],
  );
}

void main() {
  for (final library in [false, true]) {
    testWidgets(
      'search keeps newest query and clearing restores catalog, library=$library',
      (tester) async {
        final search = PendingSearch();
        await pumpApp(tester, foodSearchService: search);
        unawaited(
          showDialog<void>(
            context: tester.element(
              find.byKey(const ValueKey('today-date-picker')),
            ),
            builder: (_) => library
                ? Dialog.fullscreen(
                    child: Scaffold(
                      body: SingleChildScrollView(
                        child: MealFoodSources(
                          onCatalog: (_) {},
                          onRecent: (_) {},
                          onCustom: () {},
                        ),
                      ),
                    ),
                  )
                : const MealFormDialog(
                    catalog: [
                      FakeNutritionRepository.rice,
                      FakeNutritionRepository.egg,
                    ],
                  ),
          ),
        );
        await tester.pumpAndSettle();
        final field = find.byKey(const ValueKey('food-search'));
        if (field.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            field,
            200,
            scrollable: find
                .descendant(
                  of: find.byType(MealFormDialog),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
        }
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.enterText(field, 'com');
        await tester.pump(const Duration(milliseconds: 350));
        expect(search.pending.containsKey('com'), isTrue);
        await tester.enterText(field, 'trung');
        await tester.pump(const Duration(milliseconds: 350));
        search.complete('trung', FakeNutritionRepository.egg);
        await tester.pumpAndSettle();
        expect(find.byTooltip('Thêm Trứng gà luộc'), findsOneWidget);
        search.complete('com', FakeNutritionRepository.rice);
        await tester.pumpAndSettle();
        expect(find.byTooltip('Thêm Trứng gà luộc'), findsOneWidget);
        expect(find.byTooltip('Thêm Cơm trắng chín'), findsNothing);
        await tester.ensureVisible(
          find.byKey(const ValueKey('clear-food-search')),
        );
        await tester.tap(find.byKey(const ValueKey('clear-food-search')));
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(field).controller!.text, isEmpty);
        expect(find.byKey(const ValueKey('clear-food-search')), findsNothing);
        expect(find.byTooltip('Thêm Cơm trắng chín'), findsOneWidget);
        expect(find.byTooltip('Thêm Trứng gà luộc'), findsOneWidget);
        expect(search.pending.keys, ['com', 'trung']);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
