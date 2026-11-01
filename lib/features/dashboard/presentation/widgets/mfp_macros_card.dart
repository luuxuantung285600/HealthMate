import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/information_button.dart';
import '../../../../core/theme/reference_palette.dart';
import '../../../nutrition_targets/models/nutrition_target.dart';
import 'dart:math' as math;
import '../../../nutrition/models/nutrition_models.dart';

class MfpMacrosCard extends StatefulWidget {
  const MfpMacrosCard({
    required this.totals,
    this.target,
    this.embedded = false,
    this.showRings = true,
    super.key,
  });
  final NutritionTotals? totals;
  final NutritionTarget? target;
  final bool embedded;
  final bool showRings;
  @override
  State<MfpMacrosCard> createState() => _MfpMacrosCardState();
}

class _MfpMacrosCardState extends State<MfpMacrosCard> {
  bool _percent = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = widget.totals;
    final energy = totals == null
        ? 0.0
        : totals.carbsG * 4 + totals.fatG * 9 + totals.proteinG * 4;
    final complete = totals?.hasCompleteMacros ?? false;
    final rows = [
      (
        'Carb',
        totals?.carbsG,
        totals?.carbsKnown ?? false,
        4,
        ReferencePalette.carb,
      ),
      (
        'Đạm',
        totals?.proteinG,
        totals?.proteinKnown ?? false,
        4,
        ReferencePalette.protein,
      ),
      (
        'Chất béo',
        totals?.fatG,
        totals?.fatKnown ?? false,
        9,
        ReferencePalette.fat,
      ),
    ];
    Widget column(int i) {
      final r = rows[i];
      final known = totals != null && r.$3;
      final canPercent = complete && energy > 0;
      final value = !known || (_percent && !canPercent)
          ? '—'
          : _percent
          ? '${NumberFormat('0', 'vi').format(r.$2! * r.$4 / energy * 100)}%'
          : '${NumberFormat('0.#', 'vi').format(r.$2)} g';
      final target = switch (i) {
        0 => widget.target?.carbsGTarget,
        1 => widget.target?.proteinGTarget,
        _ => widget.target?.fatGTarget,
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.showRings)
            Semantics(
              label:
                  '${r.$1}: $value${target == null ? '' : ', mục tiêu $target g'}',
              child: ExcludeSemantics(
                child: SizedBox.square(
                  dimension: 48,
                  child: CustomPaint(
                    painter: MacroRingPainter(
                      color: r.$5,
                      track: theme.colorScheme.surfaceContainerHighest,
                      progress: known && target != null && target > 0
                          ? (r.$2! / target).clamp(0.0, 1.0)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          if (widget.showRings) const SizedBox(height: 6),
          Text(
            !widget.embedded && !_percent && known && target != null
                ? '${NumberFormat('0.#', 'vi').format(r.$2)}/${NumberFormat('0.#', 'vi').format(target)} g'
                : value,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: r.$5, shape: BoxShape.circle),
              ),
              Text(
                r.$1,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      );
    }

    if (widget.embedded) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Semantics(
            button: true,
            label: _percent ? 'Hiển thị gram' : 'Hiển thị tỷ lệ năng lượng',
            child: InkWell(
              key: const ValueKey('toggle-macro-unit'),
              onTap: () => setState(() => _percent = !_percent),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final stacked =
                        MediaQuery.textScalerOf(context).scale(1) > 1.4;
                    return Wrap(
                      spacing: 6,
                      runSpacing: 12,
                      children: [
                        for (var i = 0; i < 3; i++)
                          SizedBox(
                            width: stacked ? c.maxWidth : (c.maxWidth - 12) / 3,
                            child: column(i),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Dinh dưỡng', style: theme.textTheme.titleSmall),
            ),
            const InformationButton(
              title: 'Cách đọc dinh dưỡng',
              message:
                  'Số gram lấy từ các món đã ghi. Thanh màu thể hiện tỷ lệ năng lượng từ tinh bột, béo và đạm. Bấm nút đổi đơn vị để xem gram hoặc phần trăm. Dấu — là chưa đủ dữ liệu, không phải 0.',
            ),
            IconButton(
              key: const ValueKey('toggle-macro-unit'),
              tooltip: _percent ? 'Hiển thị gram' : 'Hiển thị tỷ lệ năng lượng',
              onPressed: () => setState(() => _percent = !_percent),
              icon: const Icon(Icons.swap_horiz),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, c) {
            final stacked =
                c.maxWidth < 250 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.4;
            return Wrap(
              spacing: 12,
              runSpacing: 16,
              children: [
                for (var i = 0; i < 3; i++)
                  SizedBox(
                    width: stacked ? c.maxWidth : (c.maxWidth - 24) / 3,
                    child: column(i),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 10,
            child: Row(
              children: complete && energy > 0
                  ? [
                      for (final r in rows)
                        if (r.$2! > 0)
                          Expanded(
                            flex: (r.$2! * r.$4 / energy * 10000).round().clamp(
                              1,
                              10000,
                            ),
                            child: ColoredBox(
                              color: r.$5,
                              child: const SizedBox.expand(),
                            ),
                          ),
                    ]
                  : [
                      Expanded(
                        child: ColoredBox(
                          color: theme.scaffoldBackgroundColor,
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ],
            ),
          ),
        ),
        if (!complete || (_percent && energy == 0)) ...[
          const SizedBox(height: 10),
          Text(
            !complete ? 'Chưa đủ số liệu' : 'Chưa tính được tỷ lệ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
    return widget.embedded ? content : AppCard(child: content);
  }
}

class MacroRingPainter extends CustomPainter {
  const MacroRingPainter({
    required this.color,
    required this.track,
    required this.progress,
  });
  final Color color, track;
  final double? progress;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 1;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    // Figma uses 64 radial strokes, each spanning the outer seven units.
    for (var i = 0; i < 64; i++) {
      final angle = -math.pi / 2 + i * math.pi * 2 / 64;
      paint.color = progress != null && i / 64 < progress! ? color : track;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius - 7),
        center + direction * radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(MacroRingPainter oldDelegate) =>
      color != oldDelegate.color ||
      track != oldDelegate.track ||
      progress != oldDelegate.progress;
}
