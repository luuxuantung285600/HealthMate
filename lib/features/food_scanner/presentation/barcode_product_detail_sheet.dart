import '../../../core/theme/app_icons.dart';
import '../../../core/theme/reference_palette.dart';
import 'package:flutter/material.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/models/nutrition_validation.dart';
import '../../food_library/presentation/food_nutrition_text.dart';
import '../models/barcode_product_models.dart';

/// Bottom sheet hiển thị thông tin sản phẩm từ barcode
class BarcodeProductDetailSheet extends StatefulWidget {
  final BarcodeProduct product;

  const BarcodeProductDetailSheet({required this.product, super.key});

  @override
  State<BarcodeProductDetailSheet> createState() =>
      _BarcodeProductDetailSheetState();
}

class _BarcodeProductDetailSheetState extends State<BarcodeProductDetailSheet> {
  late final TextEditingController _quantityController;
  double? _quantity = 100;
  String? _quantityError;
  late BarcodeNutritionBasis _basis;
  String get _unit => _basis == BarcodeNutritionBasis.per100ml ? 'ml' : 'g';
  double? get _serving => _basis == BarcodeNutritionBasis.per100ml
      ? widget.product.servingSizeMl
      : widget.product.servingSizeG;

  @override
  void initState() {
    super.initState();
    _basis = widget.product.basis;
    // Default serving size hoặc 100g
    final serving = _basis == BarcodeNutritionBasis.unconfirmed
        ? null
        : _serving;
    _quantity =
        serving != null && NutritionValidation.grams(serving.toString()) == null
        ? serving
        : 100;
    _quantityController = TextEditingController(text: _quantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  NutritionTotals? get _scaledNutrition {
    if (_quantity == null ||
        widget.product.nutrition == null ||
        _basis == BarcodeNutritionBasis.unconfirmed) {
      return null;
    }
    try {
      return _selection.toSnapshot().nutrition;
    } on FormatException {
      return null;
    }
  }

  BarcodeMealSelection get _selection => BarcodeMealSelection(
    product: widget.product,
    quantity: _quantity!,
    confirmedBasis: _basis,
  );

  void _changeBasis(BarcodeNutritionBasis? value) {
    if (value == null) return;
    setState(() {
      _basis = value;
      final serving = _serving;
      _quantity =
          serving != null && serving.isFinite && serving > 0 && serving <= 2000
          ? serving
          : 100;
      _quantityController.text = foodNumber(_quantity!);
      _quantityError = null;
    });
  }

  void _updateQuantity(String value) {
    setState(() {
      final amount = NutritionValidation.parseDecimal(value);
      _quantityError = amount == null || amount <= 0 || amount > 2000
          ? 'Nhập lượng từ trên 0 đến 2.000 $_unit.'
          : null;
      _quantity = _quantityError == null
          ? NutritionValidation.parseDecimal(value)
          : null;
    });
  }

  void _confirm() {
    try {
      final selection = _selection;
      selection.toSnapshot();
      Navigator.pop(context, selection);
    } on FormatException catch (error) {
      setState(() => _quantityError = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nutrition = _scaledNutrition;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 +
                MediaQuery.viewInsetsOf(context).bottom +
                MediaQuery.viewPaddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Product image
              if (widget.product.imageUrl != null)
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(widget.product.imageUrl!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

              // Product name
              Text(
                widget.product.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Brand
              if (widget.product.brand != null)
                Text(
                  widget.product.brand!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 8),

              // Barcode & Source
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProductMetadata(
                    icon: AppIcons.qrCode,
                    text: widget.product.barcode,
                  ),
                  const SizedBox(height: 8),
                  _ProductMetadata(
                    icon: AppIcons.fileText,
                    text: widget.product.source,
                  ),
                ],
              ),
              const Divider(height: 32),

              // Serving size input
              Text('Điều chỉnh khẩu phần', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (widget.product.basis ==
                  BarcodeNutritionBasis.unconfirmed) ...[
                const Text('Nhãn dùng gram hay mililít?'),
                const SizedBox(height: 8),
                DropdownButtonFormField<BarcodeNutritionBasis>(
                  key: const ValueKey('barcode-basis'),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Đơn vị trên nhãn',
                  ),
                  hint: const Text('Chọn đơn vị'),
                  items: const [
                    DropdownMenuItem(
                      value: BarcodeNutritionBasis.per100g,
                      child: Text('100 g'),
                    ),
                    DropdownMenuItem(
                      value: BarcodeNutritionBasis.per100ml,
                      child: Text('100 ml'),
                    ),
                  ],
                  onChanged: _changeBasis,
                ),
                const SizedBox(height: 16),
              ],
              if (_basis != BarcodeNutritionBasis.unconfirmed)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const ValueKey('barcode-grams'),
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: _unit == 'g'
                            ? 'Khối lượng (g)'
                            : 'Thể tích (ml)',
                        suffixText: _unit,
                        errorText: _quantityError,
                        errorMaxLines: 3,
                      ),
                      onChanged: _updateQuantity,
                    ),
                    if (_serving != null)
                      TextButton(
                        onPressed: () {
                          final serving = _serving!;
                          _quantityController.text = serving.toString();
                          _updateQuantity(serving.toString());
                        },
                        child: const Text('Khẩu phần gốc'),
                      ),
                  ],
                ),
              const SizedBox(height: 24),

              // Nutrition info
              if (nutrition != null) ...[
                Text(
                  'Thông tin dinh dưỡng',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _NutritionRow(
                  label: 'Năng lượng',
                  value: '${nutrition.kcal.toStringAsFixed(0)} kcal',
                  color: theme.colorScheme.primary,
                ),
                _NutritionRow(
                  label: 'Protein',
                  value: macroAmount(
                    nutrition.proteinG,
                    nutrition.proteinKnown,
                  ),
                  color: ReferencePalette.protein,
                ),
                _NutritionRow(
                  label: 'Carbs',
                  value: macroAmount(nutrition.carbsG, nutrition.carbsKnown),
                  color: ReferencePalette.carb,
                ),
                _NutritionRow(
                  label: 'Chất béo',
                  value: macroAmount(nutrition.fatG, nutrition.fatKnown),
                  color: ReferencePalette.fat,
                ),
                _NutritionRow(
                  label: 'Chất xơ',
                  value: macroAmount(nutrition.fiberG, nutrition.fiberKnown),
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tính cho ${foodNumber(_quantity!)} $_unit · Dữ liệu tham khảo, hãy kiểm tra nhãn sản phẩm.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else if (widget.product.nutrition == null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.triangleAlert,
                        color: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Sản phẩm này thiếu thông tin dinh dưỡng.\n'
                          'Bạn có thể nhập thủ công sau.',
                        ),
                      ),
                    ],
                  ),
                ),
              if (nutrition == null &&
                  widget.product.nutrition != null &&
                  _quantity != null &&
                  _basis != BarcodeNutritionBasis.unconfirmed)
                Text(
                  'Dữ liệu theo đơn vị hoặc khẩu phần này không hợp lệ. Hãy kiểm tra và nhập theo nhãn sản phẩm.',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              const SizedBox(height: 32),

              // Action buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Quét lại'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('barcode-confirm'),
                    onPressed: nutrition != null ? _confirm : null,
                    child: const Text('Thêm vào bữa ăn'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutritionRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductMetadata extends StatelessWidget {
  const _ProductMetadata({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text(text)),
    ],
  );
}
