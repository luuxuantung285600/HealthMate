import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/food_library/presentation/meal_food_sources.dart';
import 'package:healthmate/features/nutrition/data/unified_food_search_service.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_food_search_service.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/test_app.dart';

const metadata = FoodCatalogItem(
  id: 'usda_321',
  name: 'USDA pending food',
  category: 'USDA',
  servingBasis: ServingBasis.per100g,
  sourceLabel: 'USDA',
  isEstimated: false,
  hasNutritionData: false,
  dataSource: FoodDataSource.usda,
  fdcId: 321,
);
const resolvedFood = FoodCatalogItem(
  id: 'usda_321',
  name: 'USDA pending food',
  category: 'USDA',
  servingBasis: ServingBasis.per100g,
  sourceLabel: 'USDA',
  isEstimated: false,
  kcalPer100g: 123,
  dataSource: FoodDataSource.usda,
  fdcId: 321,
);

class ControlledSearch extends FakeFoodSearchService {
  final requests = <FoodSearchRequest>[];
  final pending = <Completer<FoodSearchOutcome>>[];
  final detail = Completer<FoodDetailOutcome>();
  bool showMetadata = false;
  int detailCalls = 0;
  @override
  Future<FoodSearchOutcome> search({
    required String query,
    required List<FoodCatalogItem> firestoreCatalog,
    int limit = 25,
    FoodSearchRequest? request,
    void Function(FoodSearchOutcome)? onProgress,
    bool Function(FoodCatalogItem)? matches,
  }) {
    requests.add(request!);
    final rows = showMetadata
        ? [
            const FoodSearchResult(
              food: metadata,
              source: FoodResultSource.usdaApi,
              requiresDetail: true,
            ),
          ]
        : [
            const FoodSearchResult(
              food: FakeNutritionRepository.rice,
              source: FoodResultSource.firestore,
            ),
          ];
    onProgress?.call(FoodSearchOutcome(rows, stage: FoodSearchStage.online));
    final gate = Completer<FoodSearchOutcome>();
    pending.add(gate);
    return gate.future;
  }

  @override
  Future<FoodDetailOutcome> resolveResult(
    FoodSearchResult result, {
    FoodSearchRequest? request,
  }) {
    detailCalls++;
    return detail.future;
  }
}

Future<Finder> openSearch(
  WidgetTester tester,
  ControlledSearch search,
  bool library, {
  FakeAuthRepository? auth,
  ValueChanged<FoodCatalogItem>? onCatalog,
}) async {
  await pumpApp(tester, foodSearchService: search, repository: auth);
  unawaited(
    showDialog<void>(
      context: tester.element(find.byKey(const ValueKey('today-date-picker'))),
      builder: (_) => library
          ? Dialog.fullscreen(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: MealFoodSources(
                    onCatalog: onCatalog ?? (_) {},
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
  await tester.pump();
  return field;
}

void main() {
  for (final library in [false, true]) {
    testWidgets(
      'clear button cancels a pending search and ignores its late rows, library=$library',
      (tester) async {
        final search = ControlledSearch();
        final field = await openSearch(tester, search, library);
        final request = search.requests.single;
        await tester.tap(find.byKey(const ValueKey('clear-food-search')));
        await tester.pump();
        expect(request.isActive, isFalse);
        expect(tester.widget<TextField>(field).controller!.text, isEmpty);
        expect(find.byTooltip('Thêm Cơm trắng chín'), findsOneWidget);
        expect(find.byTooltip('Thêm Trứng gà luộc'), findsOneWidget);
        search.pending.single.complete(
          const FoodSearchOutcome([
            FoodSearchResult(
              food: metadata,
              source: FoodResultSource.usdaApi,
              requiresDetail: true,
            ),
          ]),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(search.requests, hasLength(1));
        expect(find.text(metadata.name), findsNothing);
        expect(
          find.descendant(
            of: library
                ? find.byType(MealFoodSources)
                : find.byType(MealFormDialog),
            matching: find.byType(LinearProgressIndicator),
          ),
          findsNothing,
        );
        expect(find.text('Hiển thị 2/2 món đã tải'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
    testWidgets(
      'keyboard search runs immediately once and dismisses the keyboard, library=$library',
      (tester) async {
        final search = ControlledSearch();
        final field = await openSearch(tester, search, library);
        await tester.enterText(field, 'trung');
        await tester.pump();
        expect(search.requests, hasLength(1));
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();
        expect(search.requests, hasLength(2));
        expect(search.requests.first.isActive, isFalse);
        final editable = tester.widget<EditableText>(
          find.descendant(of: field, matching: find.byType(EditableText)),
        );
        expect(editable.focusNode.hasFocus, isFalse);
        search.pending.last.complete(
          const FoodSearchOutcome([
            FoodSearchResult(
              food: FakeNutritionRepository.egg,
              source: FoodResultSource.firestore,
            ),
          ]),
        );
        search.pending.first.complete(
          const FoodSearchOutcome([
            FoodSearchResult(
              food: metadata,
              source: FoodResultSource.usdaApi,
              requiresDetail: true,
            ),
          ]),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(search.requests, hasLength(2));
        expect(find.byTooltip('Thêm Trứng gà luộc'), findsOneWidget);
        expect(find.text(metadata.name), findsNothing);
        expect(find.text('Hiển thị 1/1 món đã tải'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
    testWidgets(
      'local food stays selectable during online search and failure, library=$library',
      (tester) async {
        final search = ControlledSearch();
        await openSearch(tester, search, library);
        final add = find.byWidgetPredicate(
          (widget) =>
              widget is IconButton && widget.tooltip == 'Thêm Cơm trắng chín',
        );
        expect(add, findsOneWidget);
        expect(tester.widget<IconButton>(add).onPressed, isNotNull);
        expect(find.byType(LinearProgressIndicator), findsWidgets);
        search.pending.last.complete(
          const FoodSearchOutcome([
            FoodSearchResult(
              food: FakeNutritionRepository.rice,
              source: FoodResultSource.firestore,
            ),
          ], failure: FoodSearchFailure(FoodSearchFailureKind.quota)),
        );
        await tester.pump();
        expect(
          find.text(
            const FoodSearchFailure(FoodSearchFailureKind.quota).message,
          ),
          findsOneWidget,
        );
        expect(tester.widget<IconButton>(add).onPressed, isNotNull);
        expect(find.text('Thử lại'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
    testWidgets(
      'USDA metadata has no fake kcal and duplicate taps resolve once, library=$library',
      (tester) async {
        final search = ControlledSearch()..showMetadata = true;
        var selected = 0;
        await openSearch(
          tester,
          search,
          library,
          onCatalog: (_) {
            selected++;
          },
        );
        search.pending.last.complete(
          const FoodSearchOutcome([
            FoodSearchResult(
              food: metadata,
              source: FoodResultSource.usdaApi,
              requiresDetail: true,
            ),
          ]),
        );
        await tester.pump();
        expect(find.text('USDA · Chọn để tải dinh dưỡng'), findsOneWidget);
        final tile = find
            .ancestor(
              of: find.text(metadata.name),
              matching: find.byType(ListTile),
            )
            .first;
        expect(
          find.descendant(of: tile, matching: find.textContaining('0 kcal')),
          findsNothing,
        );
        if (library) {
          expect(
            tester
                .widget<IconButton>(
                  find.byKey(const ValueKey('save-favorite-usda_321')),
                )
                .onPressed,
            isNull,
          );
        }
        final add = find.byTooltip('Thêm ${metadata.name}');
        await tester.ensureVisible(add);
        await tester.tap(add);
        await tester.pump();
        await tester.tap(add);
        await tester.pump();
        expect(search.detailCalls, 1);
        search.detail.complete(const FoodDetailOutcome(resolvedFood));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        if (library) {
          expect(selected, 1);
        } else {
          expect(find.byKey(const ValueKey('meal-grams')), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
    testWidgets(
      'changing query and disposing cancels outstanding search, library=$library',
      (tester) async {
        final search = ControlledSearch();
        final field = await openSearch(tester, search, library);
        final old = search.requests.last;
        await tester.enterText(field, 'trung');
        expect(old.isActive, false);
        await tester.pump(const Duration(milliseconds: 350));
        final current = search.requests.last;
        expect(identical(old, current), false);
        await tester.pumpWidget(const SizedBox());
        expect(current.isActive, false);
        for (final pending in search.pending) {
          if (!pending.isCompleted) {
            pending.complete(const FoodSearchOutcome([]));
          }
        }
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('UID change cancels outstanding search, library=$library', (
      tester,
    ) async {
      final search = ControlledSearch();
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      await openSearch(tester, search, library, auth: auth);
      final request = search.requests.last;
      auth.emitUser(
        const AuthUser(
          uid: 'second-uid',
          email: 'other@example.com',
          emailVerified: true,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(request.isActive, false);
      search.pending.last.complete(const FoodSearchOutcome([]));
      await tester.pump();
      expect(find.text(metadata.name), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('changing library source cancels outstanding search', (
    tester,
  ) async {
    final search = ControlledSearch();
    await openSearch(tester, search, true);
    final request = search.requests.last;
    final source = find.widgetWithText(ChoiceChip, 'Gần đây');
    await tester.ensureVisible(source);
    await tester.tap(source);
    await tester.pump();
    expect(request.isActive, false);
    search.pending.last.complete(const FoodSearchOutcome([]));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
