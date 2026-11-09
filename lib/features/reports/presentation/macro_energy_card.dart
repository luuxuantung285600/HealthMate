import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/reference_palette.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/providers/auth_providers.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../models/macro_energy_report.dart';
import '../models/period_report.dart';

/// Uses the parent's already loaded report, without opening another query.
/// Details stay in this subtree, so source loading/errors and account changes
/// cannot leave a detached dialog showing an old report.
class MacroEnergyCard extends ConsumerStatefulWidget {
  const MacroEnergyCard({
    required this.meals,
    required this.ownerUid,
    required this.range,
    required this.today,
    super.key,
  });

  final List<MealLog> meals;
  final String ownerUid;
  final ReportRange range;
  final DateTime today;

  @override
  ConsumerState<MacroEnergyCard> createState() => _MacroEnergyCardState();
}

class _MacroEnergyCardState extends ConsumerState<MacroEnergyCard> {
  EnergyMacro? _selected;
  int _visibleItems = 20;
  String? _owner;
  final _detailHeading = GlobalKey();
  final _number = NumberFormat('0.#', 'vi');

  @override
  void didUpdateWidget(covariant MacroEnergyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range ||
        oldWidget.ownerUid != widget.ownerUid) {
      _selected = null;
      _visibleItems = 20;
    }
  }

  Color _color(EnergyMacro macro) => switch (macro) {
    EnergyMacro.carbs => ReferencePalette.carb,
    EnergyMacro.protein => ReferencePalette.protein,
    EnergyMacro.fat => ReferencePalette.fat,
  };

  void _select(EnergyMacro? macro) {
    setState(() {
      _selected = macro;
      _visibleItems = 20;
    });
    if (macro == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selected != macro) return;
      final heading = _detailHeading.currentContext;
      if (heading != null) {
        Scrollable.ensureVisible(
          heading,
          alignment: 0.15,
          duration: const Duration(milliseconds: 200),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final uid = session.value?.uid;
    if (_owner != uid || session.isLoading || session.hasError) {
      _owner = uid;
      _selected = null;
      _visibleItems = 20;
    }
    if (uid != widget.ownerUid ||
        session.value?.emailVerified != true ||
        session.isLoading ||
        session.hasError) {
      return const SizedBox.shrink();
    }
    final report = MacroEnergyReport(
      meals: widget.meals,
      range: widget.range,
      today: widget.today,
    );
    if (!report.canChart ||
        (_selected != null && report.energy(_selected!) == 0)) {
      _selected = null;
    }
    final selected = _selected;
    final date = DateFormat('dd/MM/yyyy');
    final parts = EnergyMacro.values
        .where((macro) => report.energy(macro) > 0)
        .toList();
    return PopScope(
      canPop: selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && selected != null) _select(null);
      },
      child: AppCard(
        key: const ValueKey('macro-energy-card'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tỷ lệ năng lượng từ dưỡng chất',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${date.format(widget.range.start)} – ${date.format(widget.range.lastDay)} · Theo ngày đã ghi',
            ),
            const SizedBox(height: 12),
            if (report.mealCount == 0)
              const Text(
                'Chưa có bữa ăn trong khoảng này. Ghi nhật ký để xem tỷ lệ dưỡng chất.',
                key: ValueKey('macro-energy-empty'),
              )
            else if (!report.complete)
              Text(
                'Chưa đủ dữ liệu Carb, Đạm và Chất béo để tính tỷ lệ. '
                '${report.incompleteItemCount} món thiếu dữ liệu; '
                '${report.missingMealCount} bữa chưa có chi tiết món. '
                'Dữ liệu thiếu không được coi là 0.',
                key: const ValueKey('macro-energy-incomplete'),
              )
            else if (!report.canChart)
              const Text(
                'Tổng năng lượng từ ba dưỡng chất bằng 0; chưa có tỷ lệ để vẽ biểu đồ.',
                key: ValueKey('macro-energy-zero'),
              ),
            if (report.canChart) ...[
              ExcludeSemantics(
                child: SizedBox(
                  height: 184,
                  child: PieChart(
                    key: const ValueKey('macro-energy-pie'),
                    PieChartData(
                      centerSpaceRadius: 32,
                      sectionsSpace: 3,
                      borderData: FlBorderData(show: false),
                      sections: [
                        for (final macro in parts)
                          PieChartSectionData(
                            value: report.energy(macro),
                            color: _color(macro),
                            radius: macro == selected ? 55 : 48,
                            showTitle: false,
                          ),
                      ],
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          final index =
                              response?.touchedSection?.touchedSectionIndex;
                          if (event is FlTapUpEvent &&
                              index != null &&
                              index >= 0 &&
                              index < parts.length) {
                            _select(parts[index]);
                          }
                        },
                      ),
                    ),
                    duration: const Duration(milliseconds: 180),
                  ),
                ),
              ),
              Text(
                '${_number.format(report.totalEnergy)} kcal từ ba dưỡng chất',
                key: const ValueKey('macro-energy-total'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final macro in EnergyMacro.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    key: ValueKey('macro-energy-${macro.name}'),
                    onPressed: report.energy(macro) > 0
                        ? () => _select(macro)
                        : null,
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      backgroundColor: selected == macro
                          ? Theme.of(context).colorScheme.surfaceContainerHigh
                          : null,
                      padding: const EdgeInsets.all(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: _color(macro), size: 12),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${macro.label} · ${_number.format(report.grams(macro))} g\n'
                            '${_number.format(report.energy(macro))} kcal · '
                            '${_number.format(report.percent(macro))}%',
                          ),
                        ),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                  ),
                ),
              const Text(
                'Chạm lát biểu đồ hoặc tên dưỡng chất để xem từng món.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Tính từ dưỡng chất của từng món đã lưu: Carb × 4 + Đạm × 4 + '
                'Chất béo × 9 (kcal). Tỷ lệ dùng tổng này làm mẫu số, có thể '
                'khác kcal trong nhật ký. Chỉ phản ánh những gì bạn đã ghi.',
              ),
              if (report.estimatedItemCount > 0)
                Text(
                  '${report.estimatedItemCount} món được gắn nhãn ước tính.',
                ),
            ],
            if (selected != null) ...[
              const Divider(height: 32),
              Row(
                key: _detailHeading,
                children: [
                  Expanded(
                    child: Text(
                      'Đóng góp năng lượng từ ${selected.label}',
                      key: const ValueKey('macro-energy-detail-title'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('close-macro-energy-detail'),
                    tooltip: 'Đóng chi tiết dưỡng chất',
                    onPressed: () => _select(null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                'Xếp theo năng lượng đóng góp. Phần trăm bên dưới tính trong '
                '${_number.format(report.energy(selected))} kcal từ ${selected.label}.',
              ),
              ..._details(report, selected),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _details(MacroEnergyReport report, EnergyMacro macro) {
    final rows = report.contributions(macro);
    return [
      for (final row in rows.take(_visibleItems))
        Padding(
          key: ValueKey('macro-food-${row.meal.id}-${row.itemIndex}'),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.item.name,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '${row.meal.type.label} · '
                '${row.dateKey.split('-').reversed.join('/')} · '
                '${_number.format(row.item.quantity)} ${row.item.quantityUnitLabel}',
              ),
              Text(
                '${_number.format(macro.grams(row.item.nutrition))} g ${macro.label} · '
                '${_number.format(row.energy(macro))} kcal · '
                '${_number.format(row.energy(macro) / report.energy(macro) * 100)}%',
              ),
              Text(
                '${row.item.sourceLabel}${row.item.isEstimated ? ' · Ước tính' : ''}',
              ),
            ],
          ),
        ),
      Text(
        '${rows.length} món đóng góp · Đang hiện ${rows.take(_visibleItems).length} món',
      ),
      if (_visibleItems < rows.length)
        TextButton(
          key: const ValueKey('more-macro-energy-items'),
          onPressed: () => setState(() => _visibleItems += 20),
          child: const Text('Xem thêm 20 món'),
        ),
    ];
  }
}
