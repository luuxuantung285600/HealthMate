import 'package:flutter/material.dart';

class MetricValue extends StatelessWidget {
  const MetricValue({
    required this.value,
    required this.unit,
    super.key,
    this.color,
    this.valueStyle,
  });

  final String value;
  final String unit;
  final Color? color;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style:
                valueStyle ??
                theme.textTheme.headlineLarge?.copyWith(
                  color: color,
                  fontSize: 33,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
          ),
          if (unit.isNotEmpty)
            TextSpan(
              text: ' $unit',
              style: theme.textTheme.labelLarge?.copyWith(
                color: color ?? theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.fade,
    );
  }
}
