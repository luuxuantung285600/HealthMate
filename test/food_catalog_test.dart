import 'support/fake_food_search_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/nutrition/models/food_catalog_search.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';

FoodCatalogItem _food(
  String id,
  String name, {
  List<String> aliases = const [],
}) => FoodCatalogItem(
  id: id,
  name: name,
  alternateNames: aliases,
  category: 'Món ăn Việt',
  servingBasis: ServingBasis.per100g,
  unit: 'g',
  per100g: const NutritionTotals(kcal: 150, proteinG: 8, carbsG: 25, fatG: 2),
  sourceLabel: 'Công thức tham khảo',
  isEstimated: true,
);

Future<void> _pump(
  WidgetTester tester,
  List<FoodCatalogItem> catalog, {
  double scale = 1,
  ValueChanged<MealDraft?>? onSaved,
}) async {
  await tester.pumpWidget(
    testFoodScope(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('vi')],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final draft = await showDialog<MealDraft>(
                  context: context,
                  builder: (_) => MealFormDialog(catalog: catalog),
                );
                onSaved?.call(draft);
              },
              child: const Text('Mở bữa ăn'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Mở bữa ăn'));
  await tester.pumpAndSettle();
}

void main() {
  test('search handles Vietnamese marks, aliases, NFD and space/case', () {
    final pho = _food('pho', 'Phở bò', aliases: ['phở tái']);
    final com = _food('com', 'Cơm tấm sườn', aliases: ['cơm sườn']);
    final dau = _food('dau', 'Đậu phụ trắng', aliases: ['tàu hũ']);
    final catalog = [pho, com, dau];
    for (final query in [
      'PHO BO',
      'phở bò',
      '  pho   bo ',
      'pho\u031b\u0309 bo\u0300',
    ]) {
      expect(searchFoodCatalog(catalog, query), [pho]);
    }
    expect(searchFoodCatalog(catalog, 'com suon'), [com]);
    expect(searchFoodCatalog(catalog, 'dau phu'), [dau]);
    expect(searchFoodCatalog(catalog, 'tau hu'), [dau]);
    expect(searchFoodCatalog(catalog, 'pizza'), isEmpty);
    expect(searchFoodCatalog(catalog, '  '), same(catalog));
  });

  for (final scale in [1.0, 1.5]) {
    testWidgets(
      'large catalog can be browsed beyond first page at scale $scale',
      (tester) async {
        final catalog = List.generate(
          30,
          (i) => _food('food-$i', 'Món thử ${i.toString().padLeft(2, '0')}'),
        );
        await _pump(tester, catalog, scale: scale);
        final more = find.byKey(const ValueKey('more-catalog-foods'));
        await tester.scrollUntilVisible(
          more,
          500,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(more);
        await tester.pumpAndSettle();
        await tester.tap(more);
        await tester.pumpAndSettle();
        final later = find.byTooltip('Thêm Món thử 23');
        await tester.scrollUntilVisible(
          later,
          500,
          scrollable: find.byType(Scrollable).first,
        );
        expect(later, findsOneWidget);
        // A new query searches all 30 foods, not only already displayed entries.
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('food-search')),
          -600,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(
          find.byKey(const ValueKey('food-search')),
          'mon thu 29',
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byTooltip('Thêm Món thử 29'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byTooltip('Thêm Món thử 29'), findsOneWidget);
        expect(more, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'a Vietnamese search result saves an estimated portion snapshot',
    (tester) async {
      MealDraft? saved;
      await _pump(tester, [
        _food('pho', 'Phở bò'),
      ], onSaved: (draft) => saved = draft);
      final search = find.byKey(const ValueKey('food-search'));
      await tester.ensureVisible(search);
      await tester.enterText(search, 'pho bo');
      await tester.pumpAndSettle();
      final add = find.byTooltip('Thêm Phở bò');
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('meal-grams')), '200');
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-meal')));
      await tester.pumpAndSettle();
      expect(saved!.items.single.foodId, 'pho');
      expect(saved!.items.single.grams, 200);
      expect(saved!.items.single.nutrition.kcal, 300);
      expect(saved!.items.single.isEstimated, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
