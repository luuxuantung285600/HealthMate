import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../models/nutrition_failure.dart';
import '../models/nutrition_models.dart';
import '../../food_library/presentation/food_nutrition_text.dart';

class MealLogSection extends StatelessWidget {
  const MealLogSection({
    required this.catalogState,
    required this.mealsState,
    required this.catalog,
    required this.meals,
    required this.action,
    required this.onAdd,
    this.onAddForType,
    this.onOpenDrafts,
    required this.onScan,
    this.showScanner = false,
    this.compact = false,
    required this.onEdit,
    this.onDuplicate,
    required this.onDelete,
    required this.onRetry,
    required this.onDismissError,
    super.key,
  });

  final AsyncValue<List<FoodCatalogItem>> catalogState;
  final AsyncValue<List<MealLog>> mealsState;
  final List<FoodCatalogItem> catalog;
  final List<MealLog> meals;
  final AsyncValue<void> action;
  final VoidCallback? onAdd;
  final ValueChanged<MealType>? onAddForType;
  final VoidCallback? onOpenDrafts;
  final VoidCallback? onScan;
  final bool showScanner;
  final bool compact;
  final ValueChanged<MealLog> onEdit;
  final ValueChanged<MealLog>? onDuplicate;
  final ValueChanged<MealLog> onDelete;
  final VoidCallback onRetry;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadError = mealsState.error;
    final integer = NumberFormat.decimalPattern('vi_VN');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!compact)
              Row(
                children: [
                  Expanded(
                    child: Text('Bữa ăn', style: theme.textTheme.titleLarge),
                  ),
                  if (onOpenDrafts != null)
                    IconButton(
                      key: const ValueKey('open-meal-drafts'),
                      onPressed: action.isLoading ? null : onOpenDrafts,
                      tooltip: 'Bản nháp trên thiết bị',
                      icon: const Icon(Icons.drafts_outlined),
                    ),
                ],
              ),
            if (!compact) const SizedBox(height: AppSpacing.md),
            if (!compact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    key: const ValueKey('add-meal'),
                    onPressed: onAdd,
                    child: const Row(
                      children: [
                        Icon(Icons.add_rounded),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text('Thêm thủ công')),
                      ],
                    ),
                  ),
                  if (showScanner) ...[
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.tonal(
                      key: const ValueKey('scan-food'),
                      onPressed: onScan,
                      child: const Row(
                        children: [
                          Icon(Icons.camera_alt_outlined),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text('Quét món')),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            if (action.isLoading) ...[
              const SizedBox(height: AppSpacing.md),
              const LinearProgressIndicator(),
            ],
            if (action.error case final NutritionFailure error) ...[
              const SizedBox(height: AppSpacing.md),
              Material(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(error.message)),
                      IconButton(
                        onPressed: onDismissError,
                        tooltip: 'Đóng',
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (!compact) const Divider(height: AppSpacing.xl),
            if (mealsState.isLoading)
              const Row(
                children: [
                  SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('Đang tải danh mục và nhật ký…')),
                ],
              )
            else if (loadError != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loadError is NutritionFailure
                        ? loadError.message
                        : 'Chưa thể tải dữ liệu.',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              )
            else ...[
              if (!compact && meals.isEmpty)
                Text(
                  catalog.isEmpty &&
                          !catalogState.hasError &&
                          !catalogState.isLoading
                      ? 'Chưa có bữa ăn. Bạn có thể nhập món ngoài danh mục.'
                      : 'Chưa có bữa ăn. Chọn Thêm để bắt đầu.',
                ),
              if (catalogState.hasError)
                const Text(
                  'Danh mục chưa tải được; các bữa đã ghi vẫn hiển thị bên dưới.',
                ),
              for (final type in MealType.values) ...[
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.label,
                            style: theme.textTheme.titleMedium,
                            key: ValueKey('meal-group-${type.name}'),
                          ),
                          Text(
                            '${integer.format(totalMealNutrition(meals.where((meal) => meal.type == type)).kcal.round())} kcal',
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: ValueKey('add-meal-${type.name}'),
                      tooltip: 'Thêm ${type.label.toLowerCase()}',
                      onPressed:
                          action.isLoading ||
                              (onAddForType == null && onAdd == null)
                          ? null
                          : () => onAddForType != null
                                ? onAddForType!(type)
                                : onAdd?.call(),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (!meals.any((meal) => meal.type == type))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Chưa ghi món',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ...meals
                    .where((meal) => meal.type == type)
                    .map(
                      (meal) => _MealTile(
                        meal: meal,
                        onEdit: () => onEdit(meal),
                        onDuplicate: onDuplicate == null
                            ? null
                            : () => onDuplicate!(meal),
                        onDelete: () => onDelete(meal),
                      ),
                    ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({
    required this.meal,
    required this.onEdit,
    this.onDuplicate,
    required this.onDelete,
  });

  final MealLog meal;
  final VoidCallback onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final integer = NumberFormat.decimalPattern('vi_VN');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        meal.items
            .map((item) => '${item.name} · ${snapshotQuantityLabel(item)}')
            .join('\n'),
      ),
      onTap: onEdit,
      subtitle: Text(
        '${DateFormat('HH:mm').format(meal.consumedAt)} · ${integer.format(meal.totals.kcal.round())} kcal${meal.items.any((i) => i.isEstimated) ? ' · Ước tính' : ''}',
      ),
      titleAlignment: ListTileTitleAlignment.top,
      trailing: PopupMenuButton<String>(
        onSelected: (value) => switch (value) {
          'edit' => onEdit(),
          'duplicate' => onDuplicate!(),
          _ => onDelete(),
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Sửa')),
          if (onDuplicate != null)
            const PopupMenuItem(
              value: 'duplicate',
              child: Text('Nhân bản bữa'),
            ),
          const PopupMenuItem(value: 'delete', child: Text('Xóa')),
        ],
      ),
    );
  }
}
