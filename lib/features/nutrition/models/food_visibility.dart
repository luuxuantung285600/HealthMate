import 'nutrition_models.dart';

/// Admin tombstones apply to the public catalog, local cache and USDA identity.
/// Historical meal snapshots and the user's own recipes remain intact.
class FoodVisibility {
  const FoodVisibility({
    this.hiddenIds = const {},
    this.hiddenFdcIds = const {},
  });
  final Set<String> hiddenIds;
  final Set<int> hiddenFdcIds;

  bool sameAs(FoodVisibility? other) =>
      other != null &&
      hiddenIds.length == other.hiddenIds.length &&
      hiddenIds.containsAll(other.hiddenIds) &&
      hiddenFdcIds.length == other.hiddenFdcIds.length &&
      hiddenFdcIds.containsAll(other.hiddenFdcIds);

  bool allows(FoodCatalogItem food) {
    if (food.dataSource == FoodDataSource.user) return true;
    final fdc =
        food.fdcId ??
        int.tryParse(food.id.replaceFirst(RegExp(r'^usda[_-]'), ''));
    return !hiddenIds.contains(food.id) &&
        !hiddenFdcIds.contains(fdc) &&
        !hiddenIds.any(
          (id) =>
              id.startsWith('usda') &&
              int.tryParse(id.replaceFirst(RegExp(r'^usda[_-]'), '')) == fdc &&
              fdc != null,
        );
  }
}
