import '../../../core/theme/app_icons.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/home_palette.dart';
import '../../food_library/presentation/food_nutrition_text.dart';
import '../models/extra_nutrients.dart';
import '../models/nutrition_models.dart';

/// Percentages describe macro energy (4/4/9), not the mass of the food.
class FoodNutritionPanel extends StatelessWidget {
  const FoodNutritionPanel({required this.value, super.key});
  final NutritionTotals value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final energy = value.proteinG * 4 + value.carbsG * 4 + value.fatG * 9;
    final known = value.hasCompleteMacros && energy.isFinite && energy > 0;
    final macros = [
      ('Chất đạm', value.proteinG, value.proteinKnown, 4, HomePalette.protein),
      ('Đường bột', value.carbsG, value.carbsKnown, 4, HomePalette.carbs),
      ('Chất béo', value.fatG, value.fatKnown, 9, HomePalette.fat),
    ];
    final shares = [for (final m in macros) known ? m.$2 * m.$4 / energy : 0.0];
    final ring = Semantics(
      label: 'Năng lượng ${foodNumber(value.kcal)} kcal',
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension:
              104 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
          child: CustomPaint(
            painter: _MacroRing(
              shares,
              theme.colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.kcal.round().toString(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text('kcal', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final amounts = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in macros.indexed)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: entry.$2.$5.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      known ? '${(shares[entry.$1] * 100).round()}%' : '—',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.brightness == Brightness.dark
                            ? entry.$2.$5
                            : Color.lerp(entry.$2.$5, Colors.black, .4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    macroAmount(entry.$2.$2, entry.$2.$3),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    entry.$2.$1,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3) {
          return Column(children: [ring, const SizedBox(height: 20), amounts]);
        }
        return Row(
          children: [
            ring,
            const SizedBox(width: 14),
            Expanded(child: amounts),
          ],
        );
      },
    );
  }
}

class _MacroRing extends CustomPainter {
  _MacroRing(this.shares, this.track);
  final List<double> shares;
  final Color track;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(5, 5, size.width - 10, size.height - 10);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    var start = -math.pi / 2;
    const colors = [HomePalette.protein, HomePalette.carbs, HomePalette.fat];
    for (var i = 0; i < shares.length; i++) {
      final sweep = shares[i] * math.pi * 2;
      if (sweep > 0) {
        canvas.drawArc(rect, start, sweep, false, paint..color = colors[i]);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroRing oldDelegate) =>
      oldDelegate.track != track ||
      List.generate(3, (i) => oldDelegate.shares[i] != shares[i]).any((v) => v);
}

Future<void> showFoodNutritionSheet(
  BuildContext context, {
  required NutritionTotals value,
  required String quantityLabel,
  required bool isEstimated,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
  builder: (context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .85,
      child: SingleChildScrollView(
        key: const ValueKey('food-nutrition-sheet'),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Đóng bảng dinh dưỡng',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(AppIcons.x),
              ),
            ),
            FoodNutritionPanel(value: value),
            const SizedBox(height: 24),
            Text(
              'Giá trị dinh dưỡng',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Cho $quantityLabel${isEstimated ? ' · Ước tính' : ''}'),
            const SizedBox(height: 12),
            _NutrientRow('Năng lượng', '${foodNumber(value.kcal)} kcal'),
            _NutrientRow(
              'Đường bột (carb)',
              macroAmount(value.carbsG, value.carbsKnown),
            ),
            _NutrientRow(
              'Chất xơ',
              macroAmount(value.fiberG, value.fiberKnown),
            ),
            _NutrientRow(
              'Chất béo (fat)',
              macroAmount(value.fatG, value.fatKnown),
            ),
            _NutrientRow(
              'Chất đạm (protein)',
              macroAmount(value.proteinG, value.proteinKnown),
            ),
            _NutrientRow(
              'Muối quy đổi',
              value.saltEquivalentG == null
                  ? 'Chưa có dữ liệu'
                  : '${foodNumber(value.saltEquivalentG!)} g',
            ),
            const Text(
              'Muối (g) = natri (mg) × 2,5 / 1.000; đây không chỉ là muối thêm khi nấu.',
            ),
            for (final nutrient in ExtraNutrient.values)
              _NutrientRow(
                nutrient.label,
                value.extraNutrients[nutrient.name] != null
                    ? '${foodNumber(value.extraNutrients[nutrient.name]!)} ${nutrient.unit}'
                    : 'Chưa có dữ liệu',
              ),
            const SizedBox(height: 16),
            Text(
              'Tỷ lệ trên biểu đồ tính theo năng lượng từ đạm, đường bột và chất béo (4/4/9 kcal mỗi gram). '
              'Các tỷ lệ có thể chênh nhẹ do làm tròn. Dữ liệu còn thiếu không được xem là 0.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  ),
);

class _NutrientRow extends StatelessWidget {
  const _NutrientRow(this.label, this.amount);
  final String label, amount;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                amount,
                textAlign: TextAlign.end,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      const Divider(),
    ],
  );
}
