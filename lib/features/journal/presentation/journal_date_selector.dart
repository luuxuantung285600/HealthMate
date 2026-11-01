import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

class JournalDateSelector extends StatelessWidget {
  const JournalDateSelector({
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
    super.key,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final previous = DateTime(date.year, date.month, date.day - 1);
    final next = DateTime(date.year, date.month, date.day + 1);
    final today = DateUtils.isSameDay(date, DateTime.now());
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              key: const ValueKey('journal-previous-day'),
              onPressed: onPrevious,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                DateFormat('dd/MM').format(previous),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton(
                key: const ValueKey('journal-pick-date'),
                onPressed: onPick,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '${today ? 'Hôm nay · ' : ''}${DateFormat('dd/MM/yyyy').format(date)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton(
              key: const ValueKey('journal-next-day'),
              onPressed: onNext,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                DateFormat('dd/MM').format(next),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onNext == null ? theme.disabledColor : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
