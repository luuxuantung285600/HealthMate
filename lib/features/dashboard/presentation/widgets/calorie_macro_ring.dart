import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/reference_palette.dart';
import '../../models/calorie_ring_data.dart';

/// The gray track remains visible for the part of the goal not yet recorded.
class CalorieMacroRing extends StatelessWidget {
  const CalorieMacroRing({required this.data, required this.child, super.key});
  final CalorieRingData data;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: CalorieMacroRingPainter(
      progress: data.progress,
      shares: data.shares,
      track: Theme.of(context).colorScheme.surfaceContainerHighest,
      fallback: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    child: child,
  );
}

class CalorieMacroRingPainter extends CustomPainter {
  const CalorieMacroRingPainter({
    required this.progress,
    required this.shares,
    required this.track,
    required this.fallback,
  });
  final double progress;
  final List<double> shares;
  final Color track, fallback;
  static const colors = [
    ReferencePalette.protein,
    ReferencePalette.carb,
    ReferencePalette.fat,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide / 2 - 6).clamp(0, double.infinity),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    var start = -math.pi / 2;
    final sweep = math.pi * 2 * progress;
    if (!shares.any((share) => share > 0)) {
      canvas.drawArc(rect, start, sweep, false, paint..color = fallback);
      return;
    }
    for (var i = 0; i < shares.length; i++) {
      final part = sweep * shares[i];
      if (part > 0) {
        canvas.drawArc(rect, start, part, false, paint..color = colors[i]);
      }
      start += part;
    }
  }

  @override
  bool shouldRepaint(CalorieMacroRingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      !listEquals(shares, oldDelegate.shares) ||
      track != oldDelegate.track ||
      fallback != oldDelegate.fallback;
}
