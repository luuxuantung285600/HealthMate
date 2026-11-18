import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/nutrition/data/bundled_food_photo_visibility.dart';
import 'package:healthmate/features/nutrition/data/food_search_cache.dart';
import 'package:healthmate/features/nutrition/data/unified_food_search_service.dart';
import 'package:healthmate/features/nutrition/data/usda_api_service.dart';
import 'package:healthmate/features/nutrition/models/food_visibility.dart';
import 'package:healthmate/features/nutrition/models/food_photo.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fake_nutrition_repository.dart';

FoodCatalogItem food(
  String id, {
  int? fdcId,
  bool private = false,
  FoodPhoto? photo,
}) => FoodCatalogItem(
  id: id,
  name: 'Photo release food',
  category: 'Test',
  servingBasis: ServingBasis.per100g,
  sourceLabel: 'Test',
  isEstimated: true,
  kcalPer100g: 123,
  fdcId: fdcId,
  dataSource: private ? FoodDataSource.user : FoodDataSource.local,
  photo: photo,
  photoMode: photo == null ? 'default' : 'custom',
);

class ReleaseRepository extends FakeNutritionRepository {
  ReleaseRepository(this.foods);
  final List<FoodCatalogItem> foods;
  @override
  Stream<List<FoodCatalogItem>> watchFoodCatalog() => Stream.value(foods);
}

class ReleaseCache implements FoodSearchCache {
  ReleaseCache(this.foods);
  final List<FoodCatalogItem> foods;
  @override
  Future<List<FoodCatalogItem>> searchFoods(
    String query, {
    int limit = 25,
    FoodDataSource? filterSource,
  }) async => foods;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'custom admin photo restores static exclusion but not live tombstone',
    () {
      final id = excludedFoodPhotoIds.first;
      final custom = food(
        id,
        photo: FoodPhoto(
          foodId: id,
          foodName: 'Photo release food',
          imageUrl: 'https://example.com/food.jpg',
          title: 'Reviewed food',
          author: 'Photographer',
          sourceUrl: 'https://example.com/source',
          license: 'CC0',
          licenseUrl: 'https://creativecommons.org/publicdomain/zero/1.0/',
        ),
      );
      expect(const FoodVisibility().allows(custom), isTrue);
      expect(FoodVisibility(hiddenIds: {id}).allows(custom), isFalse);
      expect(const FoodVisibility().allows(food(id)), isFalse);
    },
  );
  test('generated offline exclusions match the reviewed release', () {
    final release =
        jsonDecode(
              File('data/food_catalog/photo-release.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(excludedFoodPhotoIds, isNotEmpty);
    expect(
      excludedFoodPhotoIds,
      unorderedEquals((release['excluded'] as List).map((row) => row['id'])),
    );
    for (final id in release['visibleIds'] as List) {
      expect(const FoodVisibility().allows(food(id as String)), isTrue);
    }
  });

  test(
    'offline public exclusions preserve private foods and historical values',
    () {
      final hidden = food(excludedFoodPhotoIds.first);
      final snapshot = MealItemSnapshot.fromCatalog(hidden, 100);
      final before = snapshot.toData();
      expect(const FoodVisibility().allows(hidden), isFalse);
      expect(
        const FoodVisibility().allows(food(hidden.id, private: true)),
        isTrue,
      );
      expect(snapshot.toData(), before);
      expect(snapshot.nutrition.kcal, 123);
    },
  );

  test(
    'USDA exclusion follows cache/API aliases and explicit FDC identity',
    () {
      expect(excludedFoodPhotoFdcIds, isNotEmpty);
      final fdc = excludedFoodPhotoFdcIds.first;
      for (final id in ['usda_$fdc', 'usda-$fdc', 'usda-sr-$fdc']) {
        expect(const FoodVisibility().allows(food(id)), isFalse);
      }
      expect(
        const FoodVisibility().allows(food('arbitrary', fdcId: fdc)),
        isFalse,
      );
      expect(
        const FoodVisibility().allows(
          food('private', fdcId: fdc, private: true),
        ),
        isTrue,
      );
      expect(
        FoodVisibility(hiddenIds: {'usda-sr-12345'}).allows(food('usda_12345')),
        isFalse,
      );
    },
  );

  for (final error in [false, true]) {
    test(
      'catalog filters before visibility ${error ? 'error' : 'snapshot'}',
      () async {
        final hidden = food(excludedFoodPhotoIds.first);
        final private = food(hidden.id, private: true);
        final pending = StreamController<FoodVisibility>();
        final container = ProviderContainer(
          overrides: [
            nutritionRepositoryProvider.overrideWithValue(
              ReleaseRepository([hidden, private]),
            ),
            foodVisibilityProvider.overrideWith((ref) => pending.stream),
          ],
        );
        addTearDown(() async {
          container.dispose();
          await pending.close();
        });
        final sub = container.listen(foodCatalogProvider, (_, _) {});
        addTearDown(sub.close);
        if (error) pending.addError(StateError('Offline'));
        expect(await container.read(foodCatalogProvider.future), [private]);
      },
    );
  }

  test(
    'search default filters cache and USDA API without provider callback',
    () async {
      final hidden = food(excludedFoodPhotoIds.first);
      final fdc = excludedFoodPhotoFdcIds.first;
      final api = UsdaApiService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'foods': [
                {'fdcId': fdc, 'description': 'Photo release food'},
              ],
            }),
            200,
          ),
        ),
      );
      addTearDown(api.dispose);
      final service = UnifiedFoodSearchService(
        localDatabase: ReleaseCache([hidden, food(hidden.id, private: true)]),
        usdaService: api,
      );
      final result = await service.search(
        query: 'Photo release',
        firestoreCatalog: [hidden],
      );
      expect(result.results, hasLength(1));
      expect(result.results.single.food.dataSource, FoodDataSource.user);
    },
  );
}
