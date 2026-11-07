import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:healthmate/features/nutrition/data/food_search_cache.dart';
import 'package:healthmate/features/nutrition/data/unified_food_search_service.dart';
import 'package:healthmate/features/nutrition/data/usda_api_service.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/models/food_visibility.dart';

class MemoryCache implements FoodSearchCache {
  final foods = <String, FoodCatalogItem>{};
  Future<List<FoodCatalogItem>> Function()? searchHook;
  Future<FoodCatalogItem?> Function()? detailReadHook;
  Future<void> Function()? writeHook;
  bool failRead = false, failWrite = false;
  int writes = 0;
  @override
  Future<List<FoodCatalogItem>> searchFoods(
    String query, {
    int limit = 25,
    FoodDataSource? filterSource,
  }) async {
    if (failRead) throw StateError('cache unavailable');
    return searchHook == null ? [] : searchHook!();
  }

  @override
  Future<FoodCatalogItem?> getFoodById(String id) async {
    if (failRead) throw StateError('cache unavailable');
    return detailReadHook == null ? foods[id] : detailReadHook!();
  }

  @override
  Future<void> cacheFood(FoodCatalogItem food) async {
    writes++;
    if (failWrite) throw StateError('cache unavailable');
    if (writeHook != null) await writeHook!();
    foods[food.id] = food;
  }

  @override
  Future<void> markFoodUsed(String id) async {}
  @override
  Future<List<FoodCatalogItem>> getRecentFoods({int limit = 20}) async => [];
  @override
  Future<void> cleanOldCache() async {}
  @override
  Future<Map<String, int>> getCacheStats() async => {};
}

// Deliberately keeps the response pending after abort to prove the service also
// rejects late results when a transport does not actively stop delivery.
class ObservedAbortClient extends http.BaseClient {
  final response = Completer<http.StreamedResponse>();
  int calls = 0;
  bool aborted = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    calls++;
    if (request is http.AbortableRequest) {
      request.abortTrigger?.then((_) {
        aborted = true;
      });
    }
    return response.future;
  }

  void complete(http.Response value) => response.complete(
    http.StreamedResponse(Stream.value(value.bodyBytes), value.statusCode),
  );
}

const selectedMetadata = FoodSearchResult(
  source: FoodResultSource.usdaApi,
  requiresDetail: true,
  food: FoodCatalogItem(
    id: 'usda_1',
    name: 'Fixture',
    category: 'USDA',
    servingBasis: ServingBasis.per100g,
    sourceLabel: 'USDA',
    isEstimated: false,
    hasNutritionData: false,
    fdcId: 1,
  ),
);

const localFood = FoodCatalogItem(
  id: 'local',
  name: 'Fixture rice',
  category: 'grains',
  servingBasis: ServingBasis.per100g,
  sourceLabel: 'Fixture',
  isEstimated: false,
  kcalPer100g: 100,
);
http.Response searchRows([int count = 50]) => http.Response(
  jsonEncode({
    'foods': List.generate(
      count,
      (i) => {'fdcId': i + 1, 'description': 'Fixture food $i'},
    ),
  }),
  200,
);
http.Response detailRow(int id) => http.Response(
  jsonEncode({
    'fdcId': id,
    'description': 'Fixture food $id',
    'foodNutrients': [
      {'nutrientId': 1008, 'value': 100, 'unitName': 'kcal'},
    ],
  }),
  200,
);
UnifiedFoodSearchService serviceFor(
  MemoryCache cache,
  Future<http.Response> Function(http.Request) handler,
) => UnifiedFoodSearchService(
  localDatabase: cache,
  usdaService: UsdaApiService(client: MockClient(handler)),
);
Matcher failure(FoodSearchFailureKind kind) =>
    isA<FoodSearchFailure>().having((e) => e.kind, 'kind', kind);

void main() {
  test(
    'admin archive is applied to cache and USDA search, and restoration uses the same live policy',
    () async {
      final cache = MemoryCache()..searchHook = (() async => [localFood]);
      var visibility = const FoodVisibility(
        hiddenIds: {'local'},
        hiddenFdcIds: {1},
      );
      final api = UsdaApiService(
        client: MockClient((request) async => searchRows(2)),
      );
      addTearDown(api.dispose);
      final service = UnifiedFoodSearchService(
        localDatabase: cache,
        usdaService: api,
        isAllowed: (food) => visibility.allows(food),
      );
      final hidden = await service.search(
        query: 'fixture',
        firestoreCatalog: [],
      );
      expect(hidden.results.map((row) => row.food.id), ['usda_2']);
      visibility = const FoodVisibility();
      final restored = await service.search(
        query: 'fixture',
        firestoreCatalog: [],
      );
      expect(
        restored.results.map((row) => row.food.id),
        containsAll(['local', 'usda_1', 'usda_2']),
      );
    },
  );

  test(
    'archive received while USDA detail is pending prevents selecting and caching the late result',
    () async {
      final cache = MemoryCache(), pending = Completer<http.Response>();
      var allowed = true;
      final api = UsdaApiService(
        client: MockClient((request) => pending.future),
      );
      addTearDown(api.dispose);
      final service = UnifiedFoodSearchService(
        localDatabase: cache,
        usdaService: api,
        isAllowed: (_) => allowed,
      );
      final result = service.resolveResult(selectedMetadata);
      final assertion = expectLater(
        result,
        throwsA(failure(FoodSearchFailureKind.invalidData)),
      );
      await Future<void>.delayed(Duration.zero);
      allowed = false;
      pending.complete(detailRow(1));
      await assertion;
      expect(cache.writes, 0);
    },
  );

  test(
    '50 USDA rows issue one search and zero unselected details; selecting one fetches only it',
    () async {
      final calls = <String>[];
      final cache = MemoryCache();
      final service = serviceFor(cache, (r) async {
        calls.add(r.url.path);
        return r.url.path.endsWith('/search') ? searchRows() : detailRow(8);
      });
      final outcome = await service.search(
        query: 'fixture',
        firestoreCatalog: [],
        limit: 50,
      );
      expect(calls, ['/fdc/v1/foods/search']);
      expect(outcome.results, hasLength(50));
      expect(
        outcome.results.every(
          (r) => r.requiresDetail && !r.food.hasNutritionData,
        ),
        true,
      );
      expect(cache.writes, 0);
      final selected = await service.resolveResult(outcome.results[7]);
      expect(selected.food.fdcId, 8);
      expect(selected.food.hasNutritionData, true);
      expect(calls, ['/fdc/v1/foods/search', '/fdc/v1/food/8']);
      await service.resolveResult(outcome.results[7]);
      expect(calls, hasLength(2));
      expect(cache.writes, 1);
    },
  );

  test(
    'local results publish before cache/network and survive provider failure',
    () async {
      final gate = Completer<List<FoodCatalogItem>>();
      final cache = MemoryCache()..searchHook = () => gate.future;
      final progress = <FoodSearchOutcome>[];
      final service = serviceFor(cache, (_) async => http.Response('', 503));
      final pending = service.search(
        query: 'fixture',
        firestoreCatalog: [localFood],
        onProgress: progress.add,
      );
      expect(progress.single.results.single.food.id, localFood.id);
      expect(progress.single.isLoading, true);
      gate.complete([]);
      final outcome = await pending;
      expect(outcome.results.single.food.id, localFood.id);
      expect(outcome.failure?.kind, FoodSearchFailureKind.provider);
      expect(outcome.isPartial, true);
    },
  );

  for (final entry in <String, (int, String, FoodSearchFailureKind)>{
    'quota': (429, '', FoodSearchFailureKind.quota),
    'provider': (503, '', FoodSearchFailureKind.provider),
    'invalid JSON': (200, '{broken', FoodSearchFailureKind.invalidData),
    'invalid shape': (200, '{"foods":null}', FoodSearchFailureKind.invalidData),
  }.entries) {
    test(
      '${entry.key} is an explicit failure, not successful empty search',
      () async {
        final outcome = await serviceFor(
          MemoryCache(),
          (_) async => http.Response(entry.value.$2, entry.value.$1),
        ).search(query: 'fixture', firestoreCatalog: []);
        expect(outcome.results, isEmpty);
        expect(outcome.failure?.kind, entry.value.$3);
        expect(outcome.message, isNotNull);
      },
    );
  }
  test(
    'valid empty response is distinct from network error and cache warning',
    () async {
      final empty = await serviceFor(
        MemoryCache(),
        (_) async => searchRows(0),
      ).search(query: 'fixture', firestoreCatalog: []);
      expect(empty.results, isEmpty);
      expect(empty.failure, isNull);
      expect(empty.cacheWarning, false);
      final network = await serviceFor(
        MemoryCache(),
        (_) async => throw http.ClientException('fixture'),
      ).search(query: 'fixture', firestoreCatalog: []);
      expect(network.failure?.kind, FoodSearchFailureKind.network);
      final cache = await serviceFor(
        MemoryCache()..failRead = true,
        (_) async => searchRows(1),
      ).search(query: 'fixture', firestoreCatalog: []);
      expect(cache.results, hasLength(1));
      expect(cache.cacheWarning, true);
      expect(cache.isPartial, true);
    },
  );
  test(
    'cache read/write failure does not discard usable selected detail',
    () async {
      final cache = MemoryCache()
        ..failRead = true
        ..failWrite = true;
      final service = serviceFor(
        cache,
        (r) async =>
            r.url.path.endsWith('/search') ? searchRows(1) : detailRow(1),
      );
      final rows = await service.search(query: 'fixture', firestoreCatalog: []);
      final resolved = await service.resolveResult(rows.results.single);
      expect(resolved.food.hasNutritionData, true);
      expect(resolved.cacheWarning, true);
    },
  );
  test(
    'cancel during cache prevents subsequent HTTP and progress callbacks',
    () async {
      final gate = Completer<List<FoodCatalogItem>>();
      final cache = MemoryCache()..searchHook = () => gate.future;
      var calls = 0;
      final progress = <FoodSearchOutcome>[];
      final service = serviceFor(cache, (_) async {
        calls++;
        return searchRows();
      });
      final request = FoodSearchRequest();
      final pending = service.search(
        query: 'fixture',
        firestoreCatalog: [],
        request: request,
        onProgress: progress.add,
      );
      final check = expectLater(
        pending,
        throwsA(failure(FoodSearchFailureKind.cancelled)),
      );
      request.cancel();
      await check;
      gate.complete([]);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 0);
      expect(progress, hasLength(1));
      expect(request.isActive, false);
    },
  );
  test(
    'cancellation completes transport abort trigger and rejects new work',
    () async {
      final request = FoodSearchRequest();
      var aborted = false;
      final observed = request.abortTrigger.then((_) {
        aborted = true;
      });
      request.cancel();
      await observed;
      var started = false;
      await expectLater(
        request.run(() async {
          started = true;
          return 1;
        }),
        throwsA(failure(FoodSearchFailureKind.cancelled)),
      );
      expect(aborted, true);
      expect(started, false);
    },
  );
  testWidgets(
    'one eight-second deadline covers cache plus HTTP, using fake clock',
    (tester) async {
      final cacheGate = Completer<List<FoodCatalogItem>>();
      final httpGate = Completer<http.Response>();
      final cache = MemoryCache()..searchHook = () => cacheGate.future;
      var calls = 0;
      final service = serviceFor(cache, (_) {
        calls++;
        return httpGate.future;
      });
      FoodSearchOutcome? outcome;
      final pending = service
          .search(query: 'fixture', firestoreCatalog: [localFood])
          .then((value) {
            outcome = value;
          });
      await tester.pump(const Duration(seconds: 5));
      cacheGate.complete([]);
      await tester.pump();
      expect(calls, 1);
      await tester.pump(const Duration(seconds: 3));
      await pending;
      expect(outcome!.failure?.kind, FoodSearchFailureKind.timeout);
      expect(outcome!.results.single.food.id, localFood.id);
      httpGate.complete(searchRows());
      await tester.pump();
      expect(cache.writes, 0);
    },
  );
  testWidgets('cache deadline prevents starting a later HTTP request', (
    tester,
  ) async {
    final gate = Completer<List<FoodCatalogItem>>();
    var calls = 0;
    final service = serviceFor(MemoryCache()..searchHook = () => gate.future, (
      _,
    ) async {
      calls++;
      return searchRows();
    });
    FoodSearchOutcome? outcome;
    final pending = service.search(query: 'fixture', firestoreCatalog: []).then(
      (value) {
        outcome = value;
      },
    );
    await tester.pump(FoodSearchRequest.defaultTimeout);
    await pending;
    expect(outcome!.failure?.kind, FoodSearchFailureKind.timeout);
    gate.complete([]);
    await tester.pump();
    expect(calls, 0);
  });
  test(
    'search row missing description is invalidData, not an Unknown food',
    () async {
      final outcome = await serviceFor(
        MemoryCache(),
        (_) async => http.Response(
          jsonEncode({
            'foods': [
              {'fdcId': 1},
            ],
          }),
          200,
        ),
      ).search(query: 'fixture', firestoreCatalog: []);
      expect(outcome.results, isEmpty);
      expect(outcome.failure?.kind, FoodSearchFailureKind.invalidData);
    },
  );
  testWidgets(
    'selected detail deadline spans cache and HTTP and signals transport abort',
    (tester) async {
      final read = Completer<FoodCatalogItem?>();
      final cache = MemoryCache()..detailReadHook = () => read.future;
      final client = ObservedAbortClient();
      final service = UnifiedFoodSearchService(
        localDatabase: cache,
        usdaService: UsdaApiService(client: client),
      );
      final checked = expectLater(
        service.resolveResult(selectedMetadata),
        throwsA(failure(FoodSearchFailureKind.timeout)),
      );
      await tester.pump(const Duration(seconds: 5));
      read.complete(null);
      await tester.pump();
      expect(client.calls, 1);
      await tester.pump(const Duration(seconds: 3));
      await checked;
      expect(client.aborted, true);
      client.complete(detailRow(1));
      await tester.pump();
      expect(cache.writes, 0);
    },
  );
  testWidgets(
    'cancel pending search HTTP signals abort and suppresses late progress',
    (tester) async {
      final cache = MemoryCache();
      final client = ObservedAbortClient();
      final service = UnifiedFoodSearchService(
        localDatabase: cache,
        usdaService: UsdaApiService(client: client),
      );
      final request = FoodSearchRequest();
      final progress = <FoodSearchOutcome>[];
      final checked = expectLater(
        service.search(
          query: 'fixture',
          firestoreCatalog: [],
          request: request,
          onProgress: progress.add,
        ),
        throwsA(failure(FoodSearchFailureKind.cancelled)),
      );
      await tester.pump();
      expect(client.calls, 1);
      final published = progress.length;
      request.cancel();
      await tester.pump();
      await checked;
      expect(client.aborted, true);
      client.complete(searchRows());
      await tester.pump();
      expect(progress, hasLength(published));
      expect(client.calls, 1);
      expect(cache.writes, 0);
    },
  );
  testWidgets(
    'cancel pending selected detail HTTP never starts a later cache write',
    (tester) async {
      final cache = MemoryCache();
      final client = ObservedAbortClient();
      final service = UnifiedFoodSearchService(
        localDatabase: cache,
        usdaService: UsdaApiService(client: client),
      );
      final request = FoodSearchRequest();
      final checked = expectLater(
        service.resolveResult(selectedMetadata, request: request),
        throwsA(failure(FoodSearchFailureKind.cancelled)),
      );
      await tester.pump();
      expect(client.calls, 1);
      request.cancel();
      await tester.pump();
      await checked;
      expect(client.aborted, true);
      client.complete(detailRow(1));
      await tester.pump();
      expect(cache.writes, 0);
    },
  );
  testWidgets(
    'cache write deadline retains downloaded usable detail with warning',
    (tester) async {
      final write = Completer<void>();
      final cache = MemoryCache()..writeHook = () => write.future;
      final service = serviceFor(cache, (_) async => detailRow(1));
      FoodDetailOutcome? result;
      final pending = service.resolveResult(selectedMetadata).then((value) {
        result = value;
      });
      await tester.pump();
      expect(cache.writes, 1);
      await tester.pump(FoodSearchRequest.defaultTimeout);
      await pending;
      expect(result!.food.hasNutritionData, true);
      expect(result!.food.nutritionPer100g.kcal, 100);
      expect(result!.cacheWarning, true);
      // An already-started SQLite write is not cancellable and may finish later.
      write.complete();
      await tester.pump();
    },
  );
  testWidgets(
    'cancel during already-started cache write rejects selected result',
    (tester) async {
      final write = Completer<void>();
      final cache = MemoryCache()..writeHook = () => write.future;
      final service = serviceFor(cache, (_) async => detailRow(1));
      final request = FoodSearchRequest();
      final checked = expectLater(
        service.resolveResult(selectedMetadata, request: request),
        throwsA(failure(FoodSearchFailureKind.cancelled)),
      );
      await tester.pump();
      expect(cache.writes, 1);
      request.cancel();
      await tester.pump();
      await checked;
      // Cancellation stops continuation; it cannot roll back this cache operation.
      write.complete();
      await tester.pump();
      expect(cache.writes, 1);
    },
  );
}
