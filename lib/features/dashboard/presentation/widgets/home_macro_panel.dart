import '../../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/home_palette.dart';
import '../../../nutrition/models/nutrition_models.dart';
import '../../../nutrition_targets/models/nutrition_target.dart';

class HomeMacroPanel extends StatefulWidget {
  const HomeMacroPanel({required this.totals, this.target, super.key});
  final NutritionTotals? totals;
  final NutritionTarget? target;

  @override
  State<HomeMacroPanel> createState() => _HomeMacroPanelState();
}

class _HomeMacroPanelState extends State<HomeMacroPanel> {
  bool _percent = false;

  @override
  Widget build(BuildContext context) {
    final totals = widget.totals;
    final number = NumberFormat('0.#', 'vi');
    final energy = totals == null
        ? 0.0
        : totals.proteinG * 4 + totals.carbsG * 4 + totals.fatG * 9;
    final canPercent = totals?.hasCompleteMacros == true && energy > 0;
    final rows = [
      (
        'Chất đạm',
        totals?.proteinG,
        totals?.proteinKnown ?? false,
        widget.target?.proteinGTarget,
        4,
        AppIcons.protein,
        HomePalette.protein,
      ),
      (
        'Đường bột',
        totals?.carbsG,
        totals?.carbsKnown ?? false,
        widget.target?.carbsGTarget,
        4,
        AppIcons.carbs,
        HomePalette.carbs,
      ),
      (
        'Chất béo',
        totals?.fatG,
        totals?.fatKnown ?? false,
        widget.target?.fatGTarget,
        9,
        AppIcons.fat,
        HomePalette.fat,
      ),
    ];
    return Padding(
      key: const ValueKey('home-macro-panel'),
      padding: const EdgeInsets.all(16),
      child: Semantics(
        button: true,
        label: _percent ? 'Hiển thị gram' : 'Hiển thị tỷ lệ năng lượng',
        child: InkWell(
          key: const ValueKey('toggle-macro-unit'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _percent = !_percent),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked =
                  constraints.maxWidth < 260 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.4;
              return Wrap(
                spacing: 16,
                runSpacing: 20,
                children: [
                  for (var i = 0; i < rows.length; i++)
                    SizedBox(
                      width: stacked
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 32) / 3,
                      child: Builder(
                        builder: (context) {
                          final r = rows[i];
                          final known = totals != null && r.$3;
                          final value = !known || (_percent && !canPercent)
                              ? '—'
                              : _percent
                              ? '${number.format(r.$2! * r.$5 / energy * 100)}%'
                              : number.format(r.$2);
                          final target = r.$4;
                          return Semantics(
                            label:
                                '${r.$1}: $value${_percent || !known ? '' : ' g'}${target == null ? ', chưa có mục tiêu' : ', mục tiêu ${number.format(target)} g'}',
                            child: Column(
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  children: [
                                    Icon(r.$6, size: 18, color: r.$7),
                                    Text(
                                      r.$1,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: LinearProgressIndicator(
                                    key: ValueKey('home-macro-progress-$i'),
                                    value: known && target != null && target > 0
                                        ? (r.$2! / target).clamp(0, 1)
                                        : 0,
                                    minHeight: 8,
                                    color: r.$7,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    semanticsLabel: 'Tiến độ ${r.$1}',
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text.rich(
                                  TextSpan(
                                    text: value,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                    children: [
                                      if (!_percent)
                                        TextSpan(
                                          text: target == null
                                              ? (known ? ' g' : '')
                                              : '/${number.format(target)}g',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                    ],
                                  ),
                                  key: ValueKey('home-macro-value-$i'),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
