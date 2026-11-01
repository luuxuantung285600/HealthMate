import 'package:flutter/material.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../food_library/models/food_library_models.dart';

import '../models/nutrition_models.dart';
import '../models/nutrition_validation.dart';

class CustomFoodDialog extends StatefulWidget {
  const CustomFoodDialog({
    this.newLibraryId,
    this.onSaveToLibrary,
    this.libraryErrorMessage,
    super.key,
  });
  final String Function()? newLibraryId;
  final Future<bool> Function(PersonalFood)? onSaveToLibrary;
  final String? Function()? libraryErrorMessage;

  @override
  State<CustomFoodDialog> createState() => _CustomFoodDialogState();
}

class _CustomFoodDialogState extends State<CustomFoodDialog>
    with ConfirmedSave<MealItemSnapshot, CustomFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _grams = TextEditingController(text: '100');
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _fiber = TextEditingController();
  String? _error;
  bool _saveToLibrary = false;
  bool _libraryAttempted = false;
  late final String? _libraryId;
  @override
  void initState() {
    super.initState();
    _libraryId = widget.newLibraryId?.call();
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _grams,
      _kcal,
      _protein,
      _carbs,
      _fat,
      _fiber,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _nameValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2) return 'Tên món cần ít nhất 2 ký tự.';
    if (text.length > 100) return 'Tên món tối đa 100 ký tự.';
    return null;
  }

  String? _nutrientValidator(String? value, {required double max}) {
    final parsed = NutritionValidation.parseDecimal(value);
    if (parsed == null || parsed < 0 || parsed > max) {
      return 'Nhập số từ 0 đến ${max.toStringAsFixed(0)}.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final grams = NutritionValidation.parseDecimal(_grams.text)!;
    final per100g = NutritionTotals(
      kcal: NutritionValidation.parseDecimal(_kcal.text)!,
      proteinG: NutritionValidation.parseDecimal(_protein.text)!,
      carbsG: NutritionValidation.parseDecimal(_carbs.text)!,
      fatG: NutritionValidation.parseDecimal(_fat.text)!,
      fiberG: NutritionValidation.parseDecimal(_fiber.text) ?? 0,
      fiberKnown: _fiber.text.trim().isNotEmpty,
    );
    final nutrition = per100g.scale(grams / 100);
    if (nutrition.kcal > 10000 ||
        nutrition.proteinG > 1000 ||
        nutrition.carbsG > 1000 ||
        nutrition.fatG > 1000 ||
        nutrition.fiberG > 1000) {
      setState(() {
        _error = 'Giá trị theo khẩu phần vượt giới hạn có thể lưu.';
      });
      return;
    }
    final name = _name.text.trim();
    final snapshot = MealItemSnapshot(
      foodId: _saveToLibrary
          ? 'custom:$_libraryId'
          : 'custom-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      grams: grams,
      nutrition: nutrition,
      sourceLabel: 'Người dùng nhập · Ước tính',
      isEstimated: true,
    );
    if (_saveToLibrary) {
      _libraryAttempted = true;
      final food = PersonalFood(
        id: _libraryId!,
        name: name,
        per100g: per100g,
        defaultServingGrams: grams,
      );
      await saveDraft(snapshot, (_) => widget.onSaveToLibrary!(food));
    } else {
      Navigator.pop(context, snapshot);
    }
  }

  @override
  Widget build(BuildContext context) {
    return guardSave(
      AlertDialog(
        title: const Text('Món ngoài danh mục'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nhập giá trị trên 100 g từ nhãn thực phẩm hoặc nguồn bạn có. HealthMate sẽ lưu món này với nhãn “Ước tính”.',
                  ),
                  const SizedBox(height: 16),
                  if (widget.onSaveToLibrary != null && _libraryId != null)
                    CheckboxListTile(
                      key: const ValueKey('save-to-library'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Lưu vào Món của tôi để dùng lại'),
                      subtitle: const Text(
                        'Mặc định chỉ thêm món vào bản nháp bữa ăn.',
                      ),
                      value: _saveToLibrary,
                      onChanged: _libraryAttempted
                          ? null
                          : (value) =>
                                setState(() => _saveToLibrary = value ?? false),
                    ),
                  TextFormField(
                    key: const ValueKey('custom-food-name'),
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Tên món'),
                    validator: _nameValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('custom-food-grams'),
                    controller: _grams,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Khối lượng đã ăn',
                      suffixText: 'g',
                    ),
                    validator: NutritionValidation.grams,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('custom-food-kcal'),
                    controller: _kcal,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Năng lượng trên 100 g',
                      suffixText: 'kcal',
                    ),
                    validator: (value) => _nutrientValidator(value, max: 10000),
                  ),
                  const SizedBox(height: 12),
                  _macroField(_protein, 'Đạm', 'protein'),
                  const SizedBox(height: 12),
                  _macroField(_carbs, 'Carb', 'carbs'),
                  const SizedBox(height: 12),
                  _macroField(_fat, 'Chất béo', 'fat'),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('custom-food-fiber'),
                    controller: _fiber,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Chất xơ (tùy chọn)',
                      suffixText: 'g/100 g',
                      helperText: 'Để trống nếu nguồn chưa có.',
                      helperMaxLines: 2,
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? null
                        : _nutrientValidator(v, max: 100),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  saveFeedback(),
                  if (saveError != null &&
                      widget.libraryErrorMessage?.call() != null)
                    Text(widget.libraryErrorMessage!.call()!),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: const ValueKey('save-custom-food'),
            onPressed: saving ? null : _submit,
            child: const Text('Thêm món'),
          ),
        ],
      ),
    );
  }

  Widget _macroField(
    TextEditingController controller,
    String label,
    String keyName,
  ) {
    return TextFormField(
      key: ValueKey('custom-food-$keyName'),
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, suffixText: 'g/100 g'),
      validator: (value) => _nutrientValidator(value, max: 1000),
    );
  }
}
