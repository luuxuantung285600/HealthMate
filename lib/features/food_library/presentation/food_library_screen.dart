import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../auth/providers/auth_providers.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/models/food_catalog_search.dart';
import '../models/food_library_models.dart';
import '../providers/food_library_providers.dart';
import '../providers/favorite_food_providers.dart';
import 'library_forms.dart';
import 'food_nutrition_text.dart';
import 'delete_library_entry_dialog.dart';

Future<void> openLibraryForm(
  BuildContext context, {
  required FoodSourceKind kind,
  LibraryEntry? entry,
}) async {
  final saved = await showDialog<LibraryEntry>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AccountBoundDialog(
      child: kind == FoodSourceKind.custom
          ? PersonalFoodForm(food: entry as PersonalFood?)
          : RecipeForm(recipe: entry as FoodRecipe?),
    ),
  );
  if (saved != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu vào thư viện. Các bữa ăn đã ghi giữ nguyên.'),
      ),
    );
  }
}

class FoodLibraryScreen extends StatefulWidget {
  const FoodLibraryScreen({super.key});
  @override
  State<FoodLibraryScreen> createState() => _FoodLibraryScreenState();
}

class _FoodLibraryScreenState extends State<FoodLibraryScreen> {
  FoodSourceKind _kind = FoodSourceKind.custom;
  @override
  Widget build(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Thư viện món')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Món và công thức chỉ thuộc tài khoản của bạn. Sửa hoặc xóa nguồn không thay đổi bữa ăn đã ghi.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in [
                  FoodSourceKind.custom,
                  FoodSourceKind.recipe,
                ])
                  ChoiceChip(
                    label: Text(
                      kind == FoodSourceKind.custom
                          ? 'Món của tôi'
                          : 'Công thức',
                    ),
                    selected: _kind == kind,
                    onSelected: (_) => setState(() => _kind = kind),
                  ),
              ],
            ),
            LibraryFoodList(key: ValueKey(_kind), kind: _kind),
          ],
        ),
      ),
    );
  }
}

class LibraryFoodList extends ConsumerStatefulWidget {
  const LibraryFoodList({
    required this.kind,
    this.query = '',
    this.onChoose,
    super.key,
  });
  final FoodSourceKind kind;
  final String query;
  final ValueChanged<FoodCatalogItem>? onChoose;
  @override
  ConsumerState<LibraryFoodList> createState() => _LibraryFoodListState();
}

class _LibraryFoodListState extends ConsumerState<LibraryFoodList> {
  int _limit = 40;
  bool _deleteOpen = false;
  Future<void> _delete(LibraryEntry entry) async {
    if (_deleteOpen) return;
    _deleteOpen = true;
    try {
      final uid = ref.read(authSessionProvider).value?.uid;
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AccountBoundDialog(
          child: DeleteLibraryEntryDialog(
            entry: entry,
            onDelete: () {
              if (!mounted ||
                  uid == null ||
                  ref.read(authSessionProvider).value?.uid != uid) {
                return Future.value(false);
              }
              return ref
                  .read(foodLibraryControllerProvider.notifier)
                  .delete(entry);
            },
          ),
        ),
      );
      if (saved != true ||
          !mounted ||
          ref.read(authSessionProvider).value?.uid != uid) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa nguồn khỏi thư viện.')),
      );
    } finally {
      _deleteOpen = false;
    }
  }

  Future<void> _favorite(LibraryEntry entry) async {
    final saved = await ref
        .read(favoriteFoodControllerProvider.notifier)
        .setFavorite(entry.id, true, sourceKind: entry.kind);
    if (!mounted || !saved) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã lưu món vào yêu thích.')));
  }

  @override
  Widget build(BuildContext context) {
    final key = (kind: widget.kind, limit: _limit);
    final state = ref.watch(foodLibraryProvider(key));
    final action = ref.watch(foodLibraryControllerProvider);
    final favorite = ref.watch(favoriteFoodControllerProvider);
    final busy = action.isLoading || favorite.isLoading;
    final page = state.value;
    final items =
        page?.items.where((item) {
          final food = item.asFood();
          return searchFoodCatalog([food], widget.query).isNotEmpty;
        }).toList() ??
        [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          key: ValueKey('create-${widget.kind.name}'),
          onPressed: busy
              ? null
              : () => openLibraryForm(context, kind: widget.kind),
          icon: const Icon(Icons.add),
          label: Text(
            widget.kind == FoodSourceKind.custom
                ? 'Tạo món cá nhân'
                : 'Tạo công thức',
          ),
        ),
        if (busy) ...[
          const LinearProgressIndicator(),
          const Text(
            'Đang chờ máy chủ xác nhận. Không gửi lại khi thao tác còn chạy.',
          ),
        ],
        if (action.error case final FoodLibraryFailure e) Text(e.message),
        if (favorite.hasError)
          const Text(
            'Chưa lưu được yêu thích. Hãy kiểm tra kết nối và thử lại.',
          ),
        if (state.isLoading)
          const LinearProgressIndicator()
        else if (state.hasError) ...[
          const Text('Chưa tải được thư viện. Không coi lỗi là chưa có món.'),
          TextButton(
            onPressed: () => ref.invalidate(foodLibraryProvider(key)),
            child: const Text('Thử tải lại thư viện'),
          ),
        ] else ...[
          if (page!.fromCache)
            const Text('Dữ liệu trên thiết bị; đang chờ xác nhận với máy chủ.'),
          if (items.isEmpty)
            Text(
              page.fromCache
                  ? 'Chưa xác nhận được món phù hợp từ máy chủ.'
                  : 'Chưa có món phù hợp. Hãy tạo hoặc chọn nguồn món khác.',
            ),
          for (final item in items)
            Card(
              key: ValueKey('library-entry-${item.kind.name}-${item.id}'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${nutritionLabel(item.asFood().nutritionPer100g)} /100 g · Ước tính',
                    ),
                    if (item.asFood().servingGrams != null)
                      Text(
                        '1 ${item.asFood().servingLabel} = ${foodNumber(item.asFood().servingGrams!)} g',
                      ),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (widget.onChoose != null)
                          TextButton.icon(
                            key: ValueKey(
                              'choose-${item.kind.name}-${item.id}',
                            ),
                            onPressed: busy
                                ? null
                                : () => widget.onChoose!(item.asFood()),
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm vào bữa'),
                          ),
                        TextButton(
                          key: ValueKey('edit-${item.kind.name}-${item.id}'),
                          onPressed: busy
                              ? null
                              : () => openLibraryForm(
                                  context,
                                  kind: widget.kind,
                                  entry: item,
                                ),
                          child: const Text('Sửa'),
                        ),
                        TextButton(
                          key: ValueKey(
                            'favorite-${item.kind.name}-${item.id}',
                          ),
                          onPressed: busy ? null : () => _favorite(item),
                          child: const Text('Lưu yêu thích'),
                        ),
                        TextButton(
                          key: ValueKey('delete-${item.kind.name}-${item.id}'),
                          onPressed: busy ? null : () => _delete(item),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (page.items.length == _limit)
            TextButton(
              key: const ValueKey('more-library'),
              onPressed: () => setState(() => _limit += 40),
              child: const Text('Xem thêm thư viện'),
            ),
        ],
      ],
    );
  }
}
