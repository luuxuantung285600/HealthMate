import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/nutrition/data/unified_food_search_service.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_search_controller.dart';

import 'support/fake_food_search_service.dart';
import 'support/fake_nutrition_repository.dart';

class PendingSearch extends FakeFoodSearchService {
  final requests = <FoodSearchRequest>[];
  final searches = <Completer<FoodSearchOutcome>>[];
  final details = <Completer<FoodDetailOutcome>>[];
  final detailRequests = <FoodSearchRequest>[];
  final progress = <void Function(FoodSearchOutcome)?>[];
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
    progress.add(onProgress);
    final gate = Completer<FoodSearchOutcome>();
    searches.add(gate);
    return gate.future;
  }

  @override
  Future<FoodDetailOutcome> resolveResult(
    FoodSearchResult result, {
    FoodSearchRequest? request,
  }) {
    detailRequests.add(request!);
    final gate = Completer<FoodDetailOutcome>();
    details.add(gate);
    return gate.future;
  }
}

void main() {
  const rice = FakeNutritionRepository.rice;
  const egg = FakeNutritionRepository.egg;
  const riceResult = FoodSearchResult(
    food: rice,
    source: FoodResultSource.firestore,
  );
  const eggResult = FoodSearchResult(
    food: egg,
    source: FoodResultSource.usdaApi,
  );
  late PendingSearch service;
  late MealSearchController controller;
  late String query;
  late String? uid;
  late bool active;
  late bool eligible;
  late bool allowEgg;
  setUp(() {
    service = PendingSearch();
    query = 'com';
    uid = 'alice';
    active = true;
    eligible = true;
    allowEgg = true;
    controller = MealSearchController(
      service: () => service,
      catalog: () => [rice, egg],
      query: () => query,
      currentUid: () => uid,
      isActive: () => active,
      canSearch: () => eligible,
      allows: (food) => food.id != egg.id || allowEgg,
      onChanged: () {},
      debounce: Duration.zero,
    );
  });
  tearDown(() => controller.dispose());

  test(
    'direct retry and detail selection cannot start in an inactive source',
    () async {
      eligible = false;
      await controller.search();
      expect(await controller.resolve(eggResult), isNull);
      expect(service.searches, isEmpty);
      expect(service.details, isEmpty);
      eligible = true;
      active = false;
      await controller.search();
      expect(await controller.resolve(eggResult), isNull);
      expect(service.searches, isEmpty);
    },
  );

  test('debounce rechecks eligibility before starting remote work', () async {
    controller.changed();
    eligible = false;
    await Future<void>.delayed(Duration.zero);
    expect(service.searches, isEmpty);
    expect(controller.state.isSearching, false);
  });

  test(
    'query change cancels detail and late failure cannot overwrite new results',
    () async {
      const row = FoodSearchResult(
        food: egg,
        source: FoodResultSource.usdaApi,
        requiresDetail: true,
      );
      final detail = controller.resolve(row);
      query = 'com';
      controller.changed();
      expect(service.detailRequests.single.isActive, false);
      service.details.single.completeError(StateError('Late detail failure'));
      expect(await detail, isNull);
      expect(controller.state.error, isNull);
      controller.cancel();
    },
  );

  test(
    'detail failure clears single flight and permits explicit selection retry',
    () async {
      const row = FoodSearchResult(
        food: egg,
        source: FoodResultSource.usdaApi,
        requiresDetail: true,
      );
      final first = controller.resolve(row);
      service.details.first.completeError(StateError('Network unavailable'));
      expect(await first, isNull);
      expect(controller.state.pendingDetailId, isNull);
      expect(controller.state.error, isNotNull);
      final retry = controller.resolve(row);
      service.details.last.complete(const FoodDetailOutcome(egg));
      expect((await retry)?.id, egg.id);
      expect(controller.state.error, isNull);
    },
  );

  test(
    'dispose cancels requests and suppresses late search publication',
    () async {
      final pending = controller.search();
      controller.dispose();
      final state = controller.state;
      expect(service.requests.single.isActive, false);
      service.progress.single!(const FoodSearchOutcome([eggResult]));
      service.searches.single.complete(const FoodSearchOutcome([eggResult]));
      await pending;
      expect(identical(controller.state, state), true);
      await controller.search();
      expect(service.searches, hasLength(1));
    },
  );

  test(
    'local rows publish before remote; replacing query cancels and ignores stale result',
    () async {
      final first = controller.search();
      expect(
        controller.state.results.map((row) => row.food.id),
        contains(rice.id),
      );
      expect(controller.state.isSearching, true);
      query = 'trung';
      final second = controller.search();
      expect(service.requests.first.isActive, false);
      service.searches.first.complete(const FoodSearchOutcome([riceResult]));
      await first;
      expect(
        controller.state.results.map((row) => row.food.id),
        isNot(contains(rice.id)),
      );
      service.searches.last.complete(const FoodSearchOutcome([eggResult]));
      await second;
      expect(controller.state.results.single.food.id, egg.id);
      expect(controller.state.isSearching, false);
    },
  );

  test(
    'UID change ignores progress/final result; cancellation closes pending request',
    () async {
      final pending = controller.search();
      uid = 'bob';
      service.progress.single!(
        const FoodSearchOutcome([eggResult], stage: FoodSearchStage.online),
      );
      service.searches.single.complete(const FoodSearchOutcome([eggResult]));
      await pending;
      expect(
        controller.state.results.map((row) => row.food.id),
        isNot(contains(egg.id)),
      );
      controller.clear();
      expect(controller.state.results, isEmpty);
    },
  );

  test(
    'search failure retains usable local results and filters remote progress',
    () async {
      allowEgg = false;
      final pending = controller.search();
      service.progress.single!(
        const FoodSearchOutcome([
          riceResult,
          eggResult,
        ], stage: FoodSearchStage.online),
      );
      expect(controller.state.results.map((row) => row.food.id), [rice.id]);
      service.searches.single.completeError(StateError('Provider unavailable'));
      await pending;
      expect(controller.state.results.single.food.id, rice.id);
      expect(controller.state.error, isNotNull);
      expect(controller.state.isSearching, false);
    },
  );

  test(
    'debounce coalesces query changes; inactive source does not request online',
    () async {
      controller.changed();
      query = 'trung';
      controller.changed();
      await Future<void>.delayed(Duration.zero);
      expect(service.searches, hasLength(1));
      service.searches.single.complete(const FoodSearchOutcome([eggResult]));
      await Future<void>.delayed(Duration.zero);
      eligible = false;
      query = 'com';
      controller.changed();
      await Future<void>.delayed(Duration.zero);
      expect(service.searches, hasLength(1));
      expect(controller.state.isSearching, false);
    },
  );

  test(
    'selected detail is single flight; cache warning retained and late UID result discarded',
    () async {
      const pending = FoodSearchResult(
        food: egg,
        source: FoodResultSource.usdaApi,
        requiresDetail: true,
      );
      final first = controller.resolve(pending);
      expect(controller.state.pendingDetailId, egg.id);
      expect(await controller.resolve(pending), isNull);
      service.details.single.complete(
        const FoodDetailOutcome(egg, cacheWarning: true),
      );
      expect((await first)?.id, egg.id);
      expect(controller.state.pendingDetailId, isNull);
      expect(controller.state.error, contains('chưa lưu'));
      final second = controller.resolve(pending);
      uid = 'bob';
      controller.clear();
      expect(service.detailRequests.last.isActive, false);
      service.details.last.complete(const FoodDetailOutcome(egg));
      expect(await second, isNull);
      expect(controller.state.results, isEmpty);
    },
  );

  test(
    'filter changes reject selected detail and paging does not trigger requests',
    () async {
      const pending = FoodSearchResult(
        food: egg,
        source: FoodResultSource.usdaApi,
        requiresDetail: true,
      );
      final resolution = controller.resolve(pending);
      allowEgg = false;
      service.details.single.complete(const FoodDetailOutcome(egg));
      expect(await resolution, isNull);
      expect(controller.state.error, contains('bộ lọc'));
      controller.showMore();
      expect(controller.state.visibleCount, 24);
      expect(service.searches, isEmpty);
    },
  );
}
