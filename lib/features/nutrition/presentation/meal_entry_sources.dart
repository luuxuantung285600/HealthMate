import 'package:flutter/material.dart';

import '../../food_library/presentation/meal_food_sources.dart';
import '../data/unified_food_search_service.dart';
import '../models/food_avoidance.dart';
import '../models/food_diet.dart';
import '../models/nutrition_models.dart';
import 'meal_search_controller.dart';

/// Catalog UI renders search state; the controller owns requests and deadlines.
class MealCatalogSource {
  const MealCatalogSource({
    required this.state,
    required this.searchController,
    required this.onRetry,
    required this.onCustom,
    required this.onSelect,
    required this.onMore,
  });
  final MealSearchState state;
  final TextEditingController searchController;
  final VoidCallback onRetry;
  final VoidCallback onCustom;
  final ValueChanged<FoodSearchResult> onSelect;
  final VoidCallback onMore;

  // Keep rows as direct ListView children so paging retains lazy layout/reveal.
  List<Widget> buildChildren(BuildContext context) {
    final theme = Theme.of(context);
    return [
      TextField(
        key: const ValueKey('food-search'),
        controller: searchController,
        decoration: const InputDecoration(
          hintText: 'Ví dụ: phở bò, com tam, trứng…',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
      const SizedBox(height: 8),
      TextButton.icon(
        key: const ValueKey('add-custom-food'),
        onPressed: onCustom,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Tự nhập món'),
      ),
      const SizedBox(height: 8),
      if (state.isSearching && state.results.isNotEmpty) ...[
        const LinearProgressIndicator(),
        const Text('Đang bổ sung món…'),
      ],
      if (state.isSearching && state.results.isEmpty) ...[
        const LinearProgressIndicator(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Đang tìm kiếm từ nhiều nguồn...'),
        ),
      ] else if (state.error != null && state.results.isEmpty) ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                state.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ] else if (state.results.isEmpty) ...[
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Không tìm thấy món phù hợp trong tất cả nguồn dữ liệu.'),
        ),
      ] else ...[
        if (state.error != null) ...[
          Text(state.error!),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
        for (final result in state.results.take(state.visibleCount))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(result.food.name),
            subtitle: Text(
              result.food.hasNutritionData
                  ? '${result.food.nutritionPer100g.kcal.toStringAsFixed(0)} kcal / 100 g${result.food.isEstimated ? ' · Ước tính' : ''}'
                  : result.requiresDetail
                  ? 'USDA · Chọn để tải dinh dưỡng'
                  : 'Món thiếu dữ liệu dinh dưỡng; chưa thể thêm vào bữa.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton.filledTonal(
              onPressed:
                  state.pendingDetailId == null &&
                      (result.food.hasNutritionData || result.requiresDetail)
                  ? () => onSelect(result)
                  : null,
              tooltip: 'Thêm ${result.food.name}',
              icon: state.pendingDetailId == result.food.id
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
            ),
          ),
        if (state.results.length > state.visibleCount)
          TextButton.icon(
            key: const ValueKey('more-catalog-foods'),
            onPressed: onMore,
            icon: const Icon(Icons.expand_more_rounded),
            label: const Text('Xem thêm món'),
          ),
      ],
    ];
  }
}

/// Favorites retain their own source/repository widget and selection callbacks.
class MealFavoritesSource extends StatelessWidget {
  const MealFavoritesSource({
    required this.filter,
    required this.diet,
    required this.avoidance,
    required this.onCatalog,
    required this.onRecent,
    required this.onCustom,
    super.key,
  });
  final Widget filter;
  final FoodDietPreference diet;
  final FoodAvoidance avoidance;
  final ValueChanged<FoodCatalogItem> onCatalog;
  final ValueChanged<MealItemSnapshot> onRecent;
  final VoidCallback onCustom;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Món yêu thích', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          filter,
          const SizedBox(height: 12),
          MealFoodSources(
            favoritesOnly: true,
            diet: diet,
            avoidance: avoidance,
            onCatalog: onCatalog,
            onRecent: onRecent,
            onCustom: onCustom,
          ),
        ],
      ),
    ),
  );
}
