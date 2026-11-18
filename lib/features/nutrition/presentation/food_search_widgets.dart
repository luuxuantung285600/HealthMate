import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';

/// Both meal-entry sources retain ownership of their query and request lifecycle.
class FoodSearchField extends StatelessWidget {
  const FoodSearchField({
    required this.controller,
    this.onSearch,
    this.onChanged,
    this.labelText,
    this.hintText = 'Tìm món, trái cây, đồ uống…',
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback? onSearch;
  final ValueChanged<String>? onChanged;
  final String? labelText;
  final String hintText;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          key: const ValueKey('food-search'),
          controller: controller,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          onSubmitted: (_) {
            FocusScope.of(context).unfocus();
            onSearch?.call();
          },
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            prefixIcon: const Icon(AppIcons.search),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    key: const ValueKey('clear-food-search'),
                    tooltip: 'Xóa từ khóa tìm món',
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                    icon: const Icon(AppIcons.x),
                  ),
          ),
        ),
      );
}

/// Counts refer to the current loaded rows, not all records in an external API.
class FoodSearchResultsSummary extends StatelessWidget {
  const FoodSearchResultsSummary({
    required this.visibleCount,
    required this.totalCount,
    super.key,
  });

  final int visibleCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    if (totalCount <= 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'Hiển thị ${visibleCount.clamp(0, totalCount)}/$totalCount món đã tải',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
