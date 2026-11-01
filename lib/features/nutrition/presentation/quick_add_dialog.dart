import 'package:flutter/material.dart';
import '../models/nutrition_models.dart';
import '../models/nutrition_validation.dart';
import '../../food_library/presentation/food_nutrition_text.dart';

enum LabelBasis {
  per100g('Trên 100 g', 'g'),
  per100ml('Trên 100 ml', 'ml'),
  serving('Trên 1 khẩu phần', 'serving'),
  total('Tổng phần đã ăn / chỉ kcal', 'entry');

  const LabelBasis(this.label, this.unit);
  final String label, unit;
}

class QuickAddDialog extends StatefulWidget {
  const QuickAddDialog({super.key});
  @override
  State<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<QuickAddDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _amount = TextEditingController(),
      _kcal = TextEditingController();
  final _protein = TextEditingController(),
      _carbs = TextEditingController(),
      _fat = TextEditingController(),
      _fiber = TextEditingController();
  LabelBasis _basis = LabelBasis.total;
  final _id = 'quick-${DateTime.now().microsecondsSinceEpoch}';
  @override
  void dispose() {
    for (final c in [_name, _amount, _kcal, _protein, _carbs, _fat, _fiber]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _number(TextEditingController c) =>
      NutritionValidation.parseDecimal(c.text);
  String? _validate(
    TextEditingController c, {
    bool optional = false,
    double max = 10000,
  }) {
    if (optional && c.text.trim().isEmpty) return null;
    final value = _number(c);
    return value == null || value < 0 || value > max
        ? 'Nhập số từ 0 đến ${foodNumber(max)}.'
        : null;
  }

  MealItemSnapshot? _preview() {
    final kcal = _number(_kcal);
    final q = _basis == LabelBasis.total ? 1.0 : _number(_amount);
    if (kcal == null || kcal < 0 || q == null || q <= 0 || q > 2000) {
      return null;
    }
    final p = _number(_protein), c = _number(_carbs), f = _number(_fat);
    final factor =
        (_basis == LabelBasis.per100g || _basis == LabelBasis.per100ml)
        ? q / 100
        : q;
    return MealItemSnapshot(
      foodId: _id,
      name: _name.text.trim().isEmpty ? 'Ghi nhanh kcal' : _name.text.trim(),
      grams: _basis.unit == 'g' ? q : 0,
      quantityUnit: _basis.unit,
      quantityValue: _basis.unit == 'g' ? null : q,
      nutrition: NutritionTotals(
        kcal: kcal * factor,
        proteinG: (p ?? 0) * factor,
        carbsG: (c ?? 0) * factor,
        fatG: (f ?? 0) * factor,
        fiberG: (_number(_fiber) ?? 0) * factor,
        fiberKnown: _number(_fiber) != null,
        proteinKnown: p != null,
        carbsKnown: c != null,
        fatKnown: f != null,
      ),
      sourceLabel: 'Người dùng nhập · ${_basis.label} · Ước tính',
      isEstimated: true,
    );
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final item = _preview();
    if (item == null) return;
    if (item.nutrition.kcal > 10000 ||
        [
          item.nutrition.proteinG,
          item.nutrition.carbsG,
          item.nutrition.fatG,
          item.nutrition.fiberG,
        ].any((v) => v > 1000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lượng đã ăn vượt giới hạn một món; hãy giảm lượng trong bản ghi này.',
          ),
        ),
      );
      return;
    }
    Navigator.pop(context, item);
  }

  Widget _field(
    String key,
    String label,
    TextEditingController c, {
    bool optional = false,
    double max = 10000,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(key),
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        helperText: optional
            ? 'Để trống nếu chưa biết; nhập 0 chỉ khi nhãn ghi 0.'
            : null,
        helperMaxLines: 3,
      ),
      validator: (_) => _validate(c, optional: optional, max: max),
      onChanged: (_) => setState(() {}),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final preview = _preview();
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nhập nhãn'),
          leading: IconButton(
            tooltip: 'Hủy',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: FilledButton(
            key: const ValueKey('confirm-quick-add'),
            onPressed: _submit,
            child: const Text('Thêm vào bản nháp'),
          ),
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Chưa ghi nhật ký. Chọn đúng cơ sở trên nhãn; ml không được coi là gram.',
              ),
              DropdownButtonFormField<LabelBasis>(
                key: const ValueKey('quick-basis'),
                initialValue: _basis,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Số liệu dinh dưỡng đang nhập',
                ),
                items: [
                  for (final b in LabelBasis.values)
                    DropdownMenuItem(value: b, child: Text(b.label)),
                ],
                onChanged: (v) => setState(() {
                  _basis = v!;
                  _amount.clear();
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('quick-name'),
                controller: _name,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Tên món / ghi chú ngắn (tùy chọn)',
                ),
              ),
              const SizedBox(height: 16),
              if (_basis != LabelBasis.total)
                TextFormField(
                  key: const ValueKey('quick-amount'),
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText:
                        'Lượng đã ăn (${_basis == LabelBasis.serving ? 'số khẩu phần' : _basis.unit})',
                    helperText:
                        'Nhập lượng đúng đơn vị này. Không tự quy đổi gram và ml.',
                    helperMaxLines: 3,
                  ),
                  validator: (_) {
                    final q = _number(_amount);
                    return q == null || q <= 0 || q > 2000
                        ? 'Nhập lượng trên 0 và tối đa 2.000.'
                        : null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              const SizedBox(height: 16),
              _field('quick-kcal', 'kcal · ${_basis.label}', _kcal),
              _field(
                'quick-protein',
                'Đạm (g) · ${_basis.label}',
                _protein,
                optional: true,
                max: 1000,
              ),
              _field(
                'quick-carbs',
                'Carb (g) · ${_basis.label}',
                _carbs,
                optional: true,
                max: 1000,
              ),
              _field(
                'quick-fat',
                'Chất béo (g) · ${_basis.label}',
                _fat,
                optional: true,
                max: 1000,
              ),
              _field(
                'quick-fiber',
                'Chất xơ (g) · ${_basis.label}',
                _fiber,
                optional: true,
                max: 1000,
              ),
              const SizedBox(height: 16),
              if (preview != null)
                Text(
                  'Phần đã ăn: ${snapshotQuantityLabel(preview)}\n${nutritionLabel(preview.nutrition)}',
                  key: const ValueKey('quick-preview'),
                ),
              const Text(
                'Giá trị do bạn nhập, không phải phép đo của ứng dụng. Chất chưa biết không được suy ra từ kcal. Có thể dùng lại trong Gần đây hoặc bữa mẫu.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
