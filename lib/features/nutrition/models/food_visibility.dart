import 'nutrition_models.dart';
import '../data/bundled_food_photo_visibility.dart';

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
    final fdc = food.fdcId ?? _fdcFromId(food.id);
    final liveAllowed =
        !hiddenIds.contains(food.id) &&
        !hiddenFdcIds.contains(fdc) &&
        !hiddenIds.any(
          (id) => id.startsWith('usda') && _fdcFromId(id) == fdc && fdc != null,
        );
    if (!liveAllowed) return false;
    if (food.photoMode == 'custom' && food.photo != null) return true;
    return !excludedFoodPhotoIds.contains(food.id) &&
        !excludedFoodPhotoFdcIds.contains(fdc);
  }

  static int? _fdcFromId(String id) => int.tryParse(
    RegExp(
          r'^usda(?:[-_](?:sr|foundation|branded|survey))?[-_](\d+)$',
        ).firstMatch(id)?.group(1) ??
        '',
  );
}
