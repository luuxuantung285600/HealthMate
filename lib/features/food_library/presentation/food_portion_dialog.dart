import 'package:flutter/material.dart';
import '../../../core/widgets/help_details.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/models/nutrition_validation.dart';
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

class FoodPortionDialog extends StatefulWidget {
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
  State<FoodPortionDialog> createState() => _FoodPortionDialogState();
}

class _FoodPortionDialogState extends State<FoodPortionDialog> {
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

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final hasPortion = food?.hasValidServing == true;
    final grams = _grams;
    return AlertDialog(
      title: Text(
        widget.snapshot?.quantityUnit != null &&
                widget.snapshot!.quantityUnit != 'g'
            ? 'Lượng đã ghi'
            : 'Khẩu phần',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              if (food != null)
                Text(food.name, style: Theme.of(context).textTheme.titleSmall),
              TextFormField(
                key: const ValueKey('meal-grams'),
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _portions ? 'Số phần' : 'Lượng đã ăn',
                  suffixText: _portions
                      ? 'phần'
                      : widget.snapshot?.quantityUnitLabel ?? 'g',
                ),
                onChanged: (_) => setState(() {}),
                validator: (_) => _validate(),
                onFieldSubmitted: (_) => _submit(),
              ),
              if (hasPortion) ...[
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
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final count in [0.5, 1.0, 1.5, 2.0])
                        ActionChip(
                          label: Text('${foodNumber(count)} phần'),
                          onPressed: () => setState(() {
                            _portions = true;
                            _amount.text = count.toString();
                          }),
                        ),
                    ],
                  ),
                ],
              ],
              if (grams != null &&
                  grams.isFinite &&
                  grams > 0 &&
                  grams <= 2000) ...[
                if (_portions) Text('Tương đương ${foodNumber(grams)} g'),
                if (widget.snapshot != null)
                  FoodNutritionSummary(
                    value: widget.snapshot!.withQuantity(grams).nutrition,
                  )
                else if (food?.hasNutritionData == true)
                  FoodNutritionSummary(value: food!.forGrams(grams)),
              ],
              if (food?.servingMetadataInvalid == true)
                const Text('Khẩu phần chưa rõ. Hãy nhập số gram đã cân.'),
              if (food != null)
                HelpDetails(
                  title: food.originalName != null
                      ? 'Tên gốc và nguồn USDA'
                      : 'Nguồn và khẩu phần',
                  children: [
                    if (food.originalName != null)
                      SelectableText(food.originalName!),
                    Text(food.sourceLabel),
                    if (hasPortion)
                      Text(
                        '1 ${food.servingLabel} = ${foodNumber(food.servingGrams!)} g',
                      ),
                    const Text(
                      'Khẩu phần tham khảo. Kiểm tra đúng món và cân phần ăn được khi có thể.',
                    ),
                  ],
                ),
              if (widget.snapshot case final snapshot?)
                HelpDetails(
                  title: 'Nguồn dinh dưỡng',
                  children: [
                    Text(snapshot.sourceLabel),
                    if (snapshot.isEstimated) const Text('Dữ liệu ước tính.'),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Xác nhận')),
      ],
    );
  }
}
