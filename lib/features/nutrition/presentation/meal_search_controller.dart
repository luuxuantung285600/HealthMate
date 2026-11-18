import 'dart:async';

import '../data/unified_food_search_service.dart';
import '../models/food_catalog_search.dart';
import '../models/nutrition_models.dart';

class MealSearchState {
  const MealSearchState({
    this.results = const [],
    this.isSearching = false,
    this.error,
    this.pendingDetailId,
    this.visibleCount = 12,
  });
  final List<FoodSearchResult> results;
  final bool isSearching;
  final String? error;
  final String? pendingDetailId;
  final int visibleCount;
}

/// Async search lifecycle independent of widgets, navigation and Riverpod.
/// Callbacks expose only the currently eligible catalog/session, not Firestore.
class MealSearchController {
  MealSearchController({
    required this.service,
    required this.catalog,
    required this.query,
    required this.currentUid,
    required this.isActive,
    required this.canSearch,
    required this.allows,
    required this.onChanged,
    List<FoodSearchResult> initialResults = const [],
    this.debounce = const Duration(milliseconds: 300),
  }) : state = MealSearchState(results: List.unmodifiable(initialResults));

  final UnifiedFoodSearchService Function() service;
  final List<FoodCatalogItem> Function() catalog;
  final String Function() query;
  final String? Function() currentUid;
  final bool Function() isActive;
  final bool Function() canSearch;
  final bool Function(FoodCatalogItem) allows;
  final void Function() onChanged;
  final Duration debounce;
  static const pageSize = 12;
  MealSearchState state;
  Timer? _debounce;
  int _generation = 0;
  FoodSearchRequest? _request;
  FoodSearchRequest? _detailRequest;
  bool _disposed = false;

  bool _current(int generation, String? uid) =>
      !_disposed &&
      isActive() &&
      generation == _generation &&
      currentUid() == uid;

  void _publish(MealSearchState next) {
    if (_disposed) return;
    state = next;
    onChanged();
  }

  void cancel() {
    _debounce?.cancel();
    _generation++;
    _request?.cancel();
    _detailRequest?.cancel();
    _request = null;
    _detailRequest = null;
    state = MealSearchState(
      results: state.results,
      error: state.error,
      visibleCount: state.visibleCount,
    );
  }

  void clear() {
    cancel();
    _publish(const MealSearchState());
  }

  List<FoodSearchResult> _local(String text) =>
      searchFoodCatalog(catalog(), text)
          .where(allows)
          .map(
            (food) => FoodSearchResult(
              food: food,
              source: FoodResultSource.firestore,
            ),
          )
          .toList();

  void changed() {
    if (_disposed) return;
    cancel();
    final text = query().trim();
    final eligible = isActive() && canSearch();
    _publish(
      MealSearchState(
        results: _local(text),
        isSearching: text.isNotEmpty && eligible,
      ),
    );
    if (text.isEmpty || !eligible) return;
    _debounce = Timer(debounce, () {
      if (_disposed) return;
      if (isActive() && canSearch()) {
        search();
      } else {
        cancel();
        _publish(state);
      }
    });
  }

  Future<void> search() async {
    if (_disposed) return;
    cancel();
    final text = query().trim();
    final generation = _generation;
    final uid = currentUid();
    if (!_current(generation, uid) || !canSearch()) return;
    if (text.isEmpty) {
      _publish(
        MealSearchState(
          results: catalog()
              .where(allows)
              .map(
                (food) => FoodSearchResult(
                  food: food,
                  source: FoodResultSource.firestore,
                ),
              )
              .toList(),
        ),
      );
      return;
    }
    _publish(MealSearchState(results: _local(text), isSearching: true));
    final request = FoodSearchRequest();
    _request = request;
    void accept(FoodSearchOutcome outcome) {
      if (!_current(generation, uid) || query().trim() != text) return;
      _publish(
        MealSearchState(
          results: outcome.results
              .where((result) => allows(result.food))
              .toList(),
          isSearching: outcome.isLoading,
          error: outcome.message,
        ),
      );
    }

    try {
      accept(
        await service().search(
          query: text,
          firestoreCatalog: catalog(),
          limit: 50,
          request: request,
          onProgress: accept,
          matches: allows,
        ),
      );
    } catch (_) {
      if (_current(generation, uid) && query().trim() == text) {
        _publish(
          MealSearchState(
            results: state.results,
            error:
                'Chưa tìm thêm được món. Bạn có thể dùng kết quả trong danh mục hoặc thử lại.',
            visibleCount: state.visibleCount,
          ),
        );
      }
    } finally {
      request.finish();
      if (identical(_request, request)) _request = null;
    }
  }

  Future<FoodCatalogItem?> resolve(FoodSearchResult result) async {
    if (state.pendingDetailId != null ||
        _disposed ||
        !isActive() ||
        !canSearch()) {
      return null;
    }
    if (!result.requiresDetail) {
      return allows(result.food) ? result.food : null;
    }
    final generation = _generation;
    final uid = currentUid();
    final request = FoodSearchRequest();
    _detailRequest = request;
    _publish(
      MealSearchState(
        results: state.results,
        isSearching: state.isSearching,
        pendingDetailId: result.food.id,
        visibleCount: state.visibleCount,
      ),
    );
    try {
      final detail = await service().resolveResult(result, request: request);
      if (!_current(generation, uid)) return null;
      if (!allows(detail.food)) {
        _detailError('Món không phù hợp bộ lọc hiện tại.');
        return null;
      }
      _publish(
        MealSearchState(
          results: state.results
              .map(
                (row) => row.food.id == result.food.id
                    ? FoodSearchResult(food: detail.food, source: row.source)
                    : row,
              )
              .toList(),
          isSearching: state.isSearching,
          pendingDetailId: state.pendingDetailId,
          visibleCount: state.visibleCount,
          error: detail.cacheWarning
              ? 'Đã tải món; chưa lưu được vào bộ nhớ máy.'
              : null,
        ),
      );
      return detail.food;
    } on FoodSearchFailure catch (failure) {
      if (_current(generation, uid) &&
          failure.kind != FoodSearchFailureKind.cancelled) {
        _detailError(failure.message);
      }
    } catch (_) {
      if (_current(generation, uid)) {
        _detailError('Chưa tải được dinh dưỡng. Hãy thử chọn lại món.');
      }
    } finally {
      request.finish();
      if (!_disposed && identical(_detailRequest, request)) {
        _detailRequest = null;
        _publish(
          MealSearchState(
            results: state.results,
            isSearching: state.isSearching,
            error: state.error,
            visibleCount: state.visibleCount,
          ),
        );
      }
    }
    return null;
  }

  void _detailError(String message) => _publish(
    MealSearchState(
      results: state.results,
      isSearching: state.isSearching,
      error: message,
      pendingDetailId: state.pendingDetailId,
      visibleCount: state.visibleCount,
    ),
  );

  void showMore() => _publish(
    MealSearchState(
      results: state.results,
      isSearching: state.isSearching,
      error: state.error,
      pendingDetailId: state.pendingDetailId,
      visibleCount: state.visibleCount + pageSize,
    ),
  );

  void dispose() {
    cancel();
    _disposed = true;
  }
}
