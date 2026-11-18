import '../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import '../../nutrition/models/food_browse_group.dart';
import '../../nutrition/presentation/food_selection_theme.dart';
import '../../../core/widgets/help_details.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../nutrition/providers/food_photo_provider.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/models/nutrition_validation.dart';
import '../../nutrition/presentation/food_nutrition_panel.dart';
import '../../nutrition/presentation/food_photo_thumbnail.dart';
import 'food_nutrition_text.dart';

Future<double?> askFoodGrams(
  BuildContext context, {
  double initial = 100,
  FoodCatalogItem? food,
}) => showDialog<double>(
  context: context,
  builder: (_) => FoodPortionDialog(initial: initial, food: food),
);

Future<double?> askSnapshotQuantity(
  BuildContext context,
  MealItemSnapshot snapshot,
) => showDialog<double>(
  context: context,
  builder: (_) =>
      FoodPortionDialog(initial: snapshot.quantity, snapshot: snapshot),
);

/// Food detail and portion confirmation share a single scrollable page.
/// Historical entries retain their snapshot when the live catalog changes.
class FoodPortionDialog extends ConsumerStatefulWidget {
  const FoodPortionDialog({
    required this.initial,
    this.food,
    this.snapshot,
    super.key,
  });
  final double initial;
  final FoodCatalogItem? food;
  final MealItemSnapshot? snapshot;
  @override
  ConsumerState<FoodPortionDialog> createState() => _FoodPortionDialogState();
}

class _FoodPortionDialogState extends ConsumerState<FoodPortionDialog> {
  late final TextEditingController _amount;
  bool _portions = false;
  final _form = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: widget.initial.toString());
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double? get _grams {
    final amount = NutritionValidation.parseDecimal(_amount.text);
    return amount == null
        ? null
        : amount * (_portions ? widget.food!.servingGrams! : 1);
  }

  void _submit() {
    if (_form.currentState!.validate()) Navigator.pop(context, _grams);
  }

  void _switchUnit(bool portions) {
    if (_portions == portions) return;
    final grams = _grams;
    setState(() {
      _portions = portions;
      _amount.text = grams == null
          ? ''
          : (grams / (portions ? widget.food!.servingGrams! : 1)).toString();
    });
  }

  String? _validate() {
    final error = NutritionValidation.grams(_grams?.toString());
    if (error != null || widget.food == null) return error;
    final nutrition = widget.food!.forGrams(_grams!);
    if ([
          nutrition.kcal,
          nutrition.proteinG,
          nutrition.carbsG,
          nutrition.fatG,
          nutrition.fiberG,
        ].any((value) => !value.isFinite || value < 0) ||
        nutrition.kcal > 10000 ||
        nutrition.proteinG > 1000 ||
        nutrition.carbsG > 1000 ||
        nutrition.fatG > 1000 ||
        nutrition.fiberG > 1000) {
      return 'Khẩu phần vượt giới hạn lưu của một món. Hãy giảm lượng trong bản ghi này.';
    }
    return null;
  }

  NutritionTotals? _nutrition(double? amount) {
    if (amount == null || !amount.isFinite || amount <= 0 || amount > 2000) {
      return null;
    }
    try {
      if (widget.snapshot case final snapshot?) {
        return snapshot.withQuantity(amount).nutrition;
      }
      if (widget.food?.hasNutritionData == true) {
        return widget.food!.forGrams(amount);
      }
    } on FormatException {
      // Damaged snapshots cannot silently turn into live catalog values.
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: foodSelectionTheme(context),
    child: Builder(builder: _buildPage),
  );

  Widget _buildPage(BuildContext context) {
    final food = widget.food;
    final isDrink = food != null && FoodBrowseGroup.drinks.allows(food);
    final snapshot = widget.snapshot;
    final theme = Theme.of(context);
    final grams = _grams;
    final nutrition = _nutrition(grams);
    final hasPortion = food?.hasValidServing == true;
    final photoId = food?.id ?? snapshot?.foodId;
    final name = food?.name ?? snapshot?.name;
    final unit = snapshot?.quantityUnitLabel ?? 'g';
    final quantity =
        '${grams == null || !grams.isFinite ? '—' : foodNumber(grams)} $unit';
    final estimated = food?.isEstimated ?? snapshot?.isEstimated ?? true;
    final recipe = food?.recipeIngredients ?? const <FoodRecipeIngredient>[];
    return Dialog.fullscreen(
      backgroundColor: theme.colorScheme.surface,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          toolbarHeight: MediaQuery.textScalerOf(context).scale(56),
          leading: IconButton(
            tooltip: 'Quay lại',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(AppIcons.arrowLeft),
          ),
          title: const Text('Chi tiết món'),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(AppIcons.check),
                    label: const Text('Xác nhận'),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              key: const ValueKey('food-detail-content'),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (photoId != null &&
                        name != null &&
                        ref.watch(foodPhotoProvider((photoId, name))) !=
                            null) ...[
                      Center(
                        child: FoodPhotoThumbnail(
                          key: const ValueKey('portion-food-photo'),
                          foodId: photoId,
                          foodName: name,
                          size: 152,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (name != null)
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '$quantity${estimated ? ' · Ước tính' : ''}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    if (nutrition != null) ...[
                      FoodNutritionPanel(value: nutrition),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        key: const ValueKey('show-food-nutrition'),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerLow,
                        ),
                        onPressed: () => showFoodNutritionSheet(
                          context,
                          value: nutrition,
                          quantityLabel: quantity,
                          isEstimated: estimated,
                        ),
                        icon: const Icon(AppIcons.chevronDown),
                        label: const Text('Giá trị dinh dưỡng'),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      snapshot != null && snapshot.quantityUnit != 'g'
                          ? 'Lượng đã ghi'
                          : 'Khẩu phần',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (food?.packageLabel != null) ...[
                      Text(food!.packageLabel!),
                      if (food.packageLabel!.contains('chưa pha nước'))
                        const Text(
                          'Nhập khối lượng gói khô hoặc chọn Khẩu phần để ghi theo gói. '
                          'Không cộng trọng lượng nước pha; trứng, thịt và rau thêm ghi riêng.',
                        ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      key: const ValueKey('meal-grams'),
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        fillColor: theme.colorScheme.surfaceContainerLow,
                        labelText: _portions
                            ? 'Số phần'
                            : isDrink
                            ? 'Lượng đã uống'
                            : 'Lượng đã ăn',
                        suffixText: _portions ? 'phần' : unit,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (_) => _validate(),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (hasPortion) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Gram'),
                            selected: !_portions,
                            onSelected: (_) => _switchUnit(false),
                          ),
                          ChoiceChip(
                            key: const ValueKey('portion-unit'),
                            label: const Text('Khẩu phần'),
                            selected: _portions,
                            onSelected: (_) => _switchUnit(true),
                          ),
                        ],
                      ),
                      if (_portions) ...[
                        Text(
                          '1 ${food!.servingLabel} = ${foodNumber(food.servingGrams!)} g',
                          style: theme.textTheme.bodySmall,
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final count in [0.5, 1.0, 1.5, 2.0])
                              ActionChip(
                                label: Text('${foodNumber(count)} phần'),
                                onPressed: () => setState(() {
                                  _amount.text = count.toString();
                                }),
                              ),
                          ],
                        ),
                        if (grams != null && grams.isFinite)
                          Text('Tương đương ${foodNumber(grams)} g'),
                      ],
                    ],
                    if (isDrink) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Dinh dưỡng tính theo khối lượng g. Có thể dùng khẩu phần cốc nếu nguồn đã cung cấp; không mặc định 1 ml = 1 g. Nước uống hằng ngày ghi riêng ở mục Nước.',
                      ),
                    ],
                    if (food?.servingMetadataInvalid == true)
                      const Text('Khẩu phần chưa rõ. Hãy nhập số gram đã cân.'),
                    const SizedBox(height: 20),
                    if (recipe.isNotEmpty) ...[
                      Text(
                        'Nguyên liệu tham khảo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Theo công thức dùng để tính dinh dưỡng. Lượng nguyên liệu trước chế biến '
                        'được quy đổi theo gram món thành phẩm bạn chọn; cách nấu thực tế có thể khác.',
                      ),
                      const SizedBox(height: 8),
                      for (final ingredient in recipe) ...[
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          leading:
                              ref.watch(
                                    foodPhotoProvider((
                                      ingredient.foodId,
                                      ingredient.name,
                                    )),
                                  ) ==
                                  null
                              ? null
                              : FoodPhotoThumbnail(
                                  foodId: ingredient.foodId,
                                  foodName: ingredient.name,
                                  size: 56,
                                ),
                          title: Text(ingredient.name),
                          subtitle: Text(
                            nutrition == null
                                ? 'Chọn khẩu phần hợp lệ'
                                : '${foodNumber(ingredient.gramsPer100gYield * grams! / 100)} g',
                          ),
                        ),
                        const Divider(),
                      ],
                    ] else if (food?.ingredientNames.isNotEmpty == true) ...[
                      Text(
                        'Thành phần theo nguồn',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(food!.ingredientNames.join(', ')),
                      const Text(
                        'Nguồn chưa có định lượng cho từng nguyên liệu.',
                      ),
                    ],
                    const SizedBox(height: 12),
                    HelpDetails(
                      title: food?.originalName != null
                          ? 'Tên gốc và nguồn USDA'
                          : 'Nguồn dinh dưỡng',
                      children: [
                        if (food?.originalName != null)
                          SelectableText(food!.originalName!),
                        Text(
                          food?.sourceLabel ??
                              snapshot?.sourceLabel ??
                              'Chưa có nguồn',
                        ),
                        if (hasPortion)
                          Text(
                            '1 ${food!.servingLabel} = ${foodNumber(food.servingGrams!)} g',
                          ),
                        const Text(
                          'Ảnh minh họa không xác định khẩu phần hay lượng calo. Kiểm tra đúng món và cân phần ăn được khi có thể.',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
