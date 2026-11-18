import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/local_date_key.dart';
import '../../../../core/widgets/app_inset_panel.dart';

class HomeDaySelector extends StatelessWidget {
  const HomeDaySelector({
    required this.day,
    required this.today,
    required this.onSelected,
    super.key,
  });
  final DateTime day, today;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final monday = DateTime(day.year, day.month, day.day - day.weekday + 1);
    final current = DateUtils.isSameDay(day, today);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: AppInsetPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${current ? 'HÔM NAY, ' : ''}${day.day} THG ${day.month}',
                    key: const ValueKey('home-selected-date'),
                    semanticsLabel: DateFormat(
                      'EEEE, d MMMM yyyy',
                      'vi',
                    ).format(day),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: .2,
                    ),
                  ),
                ),
                if (!current)
                  TextButton(
                    key: const ValueKey('home-return-today'),
                    onPressed: () => onSelected(today),
                    child: const Text('Về hôm nay'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final diameter = math.max(
                  50.0,
                  30 * MediaQuery.textScalerOf(context).scale(1),
                );
                final width = math.max(constraints.maxWidth / 7, diameter + 2);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        _dayButton(
                          context,
                          DateTime(monday.year, monday.month, monday.day + i),
                          i,
                          width,
                          diameter,
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayButton(
    BuildContext context,
    DateTime date,
    int index,
    double width,
    double diameter,
  ) {
    final selected = DateUtils.isSameDay(day, date);
    final enabled = !date.isAfter(today) && date.year >= 2020;
    final dateLabel = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(date);
    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      label: dateLabel,
      child: Tooltip(
        message: dateLabel,
        child: SizedBox(
          width: width,
          height: diameter + 6,
          child: InkWell(
            key: ValueKey('home-week-${localDateKey(date)}'),
            onTap: enabled ? () => onSelected(date) : null,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Container(
                width: diameter,
                height: diameter,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: selected
                      ? Border.all(color: Theme.of(context).colorScheme.primary)
                      : null,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: ExcludeSemantics(
                      child: Text(
                        const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][index],
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : enabled
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
