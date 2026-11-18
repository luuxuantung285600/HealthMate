import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/bundled_food_photos.dart';
import '../models/food_catalog_search.dart';
import '../models/food_photo.dart';
import 'nutrition_providers.dart';

/// Reuses the shared catalog subscription; individual images create no queries.
final foodPhotoProvider = Provider.autoDispose
    .family<FoodPhoto?, (String, String)>((ref, identity) {
      final foods = ref.watch(foodCatalogProvider).value;
      final food = foods?.where((food) => food.id == identity.$1).firstOrNull;
      if (food != null) {
        if (food.photoMode == 'hidden' ||
            normalizeFoodSearch(food.name) !=
                normalizeFoodSearch(identity.$2)) {
          return null;
        }
        if (food.photoMode == 'custom') return food.photo;
      }
      return findFoodPhoto(identity.$1, identity.$2);
    });
