import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/home_palette.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/information_button.dart';
import '../../../nutrition/models/nutrition_models.dart';
import '../../../nutrition_targets/models/nutrition_target.dart';
import 'home_macro_panel.dart';

/// Both pages reuse the day's recorded totals; switching opens no queries.
class HomeNutrientPanels extends StatefulWidget {
  const HomeNutrientPanels({
    required this.totals,
    this.target,
    this.onEditTarget,
    this.targetStatus,
    super.key,
  });
  final NutritionTotals? totals;
  final NutritionTarget? target;
  final VoidCallback? onEditTarget;
  final String? targetStatus;
  @override
  State<HomeNutrientPanels> createState() => _HomeNutrientPanelsState();
}

class _HomeNutrientPanelsState extends State<HomeNutrientPanels> {
  int _page = 0;
  double _drag = 0;
  void _select(int value) => setState(() => _page = value.clamp(0, 1));
  @override
  Widget build(BuildContext context) => AppCard(
    key: const ValueKey('home-nutrient-panels'),
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        GestureDetector(
          onHorizontalDragStart: (_) => _drag = 0,
          onHorizontalDragUpdate: (details) => _drag += details.delta.dx,
          onHorizontalDragEnd: (details) {
            final movement = _drag.abs() >= 30
                ? _drag
                : (details.primaryVelocity ?? 0) / 10;
            if (movement.abs() >= 30) _select(_page + (movement < 0 ? 1 : -1));
          },
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _page == 0
                ? HomeMacroPanel(totals: widget.totals, target: widget.target)
                : HomeSecondaryNutrientsPanel(
                    totals: widget.totals,
                    target: widget.target,
                    onEditTarget: widget.onEditTarget,
                    targetStatus: widget.targetStatus,
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var page = 0; page < 2; page++)
                TextButton(
                  key: ValueKey('home-nutrient-page-$page'),
                  onPressed: () => _select(page),
                  style: TextButton.styleFrom(
                    foregroundColor: _page == page
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    backgroundColor: _page == page
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: .12)
                        : Colors.transparent,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                  ),
                  child: Semantics(
                    selected: _page == page,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _page == page
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            page == 0 ? 'Đạm · Bột · Béo' : 'Muối · Đường · Xơ',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class HomeSecondaryNutrientsPanel extends StatelessWidget {
  const HomeSecondaryNutrientsPanel({
    required this.totals,
    this.target,
    this.onEditTarget,
    this.targetStatus,
    super.key,
  });
  final NutritionTotals? totals;
  final NutritionTarget? target;
  final VoidCallback? onEditTarget;
  final String? targetStatus;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = NumberFormat('0.##', 'vi');
    final rows = [
      (
        'Muối',
        totals?.saltEquivalentG,
        target?.saltGLimit,
        AppIcons.droplet,
        HomePalette.fat,
        true,
      ),
      (
        'Đường',
        totals?.totalSugarG,
        target?.sugarGLimit,
        AppIcons.cookie,
        HomePalette.carbs,
        true,
      ),
      (
        'Chất xơ',
        totals?.fiberKnown == true ? totals?.fiberG : null,
        target?.fiberGTarget,
        AppIcons.leaf,
        const Color(0xFFD09FC2),
        false,
      ),
    ];
    return Padding(
      key: const ValueKey('home-secondary-nutrients'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked =
                  constraints.maxWidth < 260 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.4;
              return Wrap(
                spacing: 16,
                runSpacing: 20,
                children: [
                  for (final (index, row) in rows.indexed)
                    SizedBox(
                      width: stacked
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 32) / 3,
                      child: Semantics(
                        excludeSemantics: true,
                        label:
                            '${row.$1}${index == 0
                                ? ' quy đổi từ natri'
                                : index == 1
                                ? ' tổng'
                                : ''}: ${row.$2 == null ? 'Chưa đủ dữ liệu' : '${number.format(row.$2)} g'}${row.$3 == null ? ', ${targetStatus ?? 'chưa đặt mốc'}' : ', mốc tự đặt ${number.format(row.$3)} g'}',
                        child: Column(
                          children: [
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Icon(row.$4, size: 18, color: row.$5),
                                Text(
                                  row.$1,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                key: ValueKey('home-secondary-progress-$index'),
                                value: row.$2 != null && row.$3 != null
                                    ? row.$3! > 0
                                          ? (row.$2! / row.$3!).clamp(0, 1)
                                          : row.$2! > 0
                                          ? 1
                                          : 0
                                    : 0,
                                minHeight: 8,
                                color: row.$5,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text.rich(
                              TextSpan(
                                text: row.$2 == null
                                    ? '—'
                                    : number.format(row.$2),
                                style: theme.textTheme.titleLarge,
                                children: [
                                  TextSpan(
                                    text: row.$3 == null
                                        ? (row.$2 == null ? '' : ' g')
                                        : '/${number.format(row.$3)}g',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              key: ValueKey('home-secondary-value-$index'),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              row.$2 == null
                                  ? 'Chưa đủ dữ liệu'
                                  : row.$3 == null
                                  ? targetStatus ?? 'Chưa đặt mốc'
                                  : row.$6 && row.$2! > row.$3!
                                  ? 'Vượt mốc ${number.format(row.$2! - row.$3!)} g'
                                  : row.$6
                                  ? 'Mốc tối đa tự đặt'
                                  : 'Mục tiêu tự đặt',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const InformationButton(
                title: 'Cách đọc muối, đường và chất xơ',
                message:
                    'Muối được quy đổi từ natri: natri (mg) × 2,5 / 1.000 = muối (g). '
                    'Đây không chỉ là muối thêm khi nấu. Đường là đường tổng, gồm cả đường tự nhiên; '
                    'khác đường tự do/đường thêm và khác đường bột (carb). '
                    'Các mốc do bạn tự đặt; ứng dụng không tự áp một giới hạn y tế. '
                    'Thiếu dữ liệu ở bất kỳ món đã ghi nào sẽ hiện chưa đủ dữ liệu, không coi là 0.',
              ),
              if (onEditTarget != null)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const ValueKey('home-edit-secondary-targets'),
                      onPressed: onEditTarget,
                      child: const Text('Đặt mốc theo ngày'),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
