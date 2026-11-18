import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/local_date_key.dart';
import '../../../shared/providers/local_clock_provider.dart';

final journalDateProvider = NotifierProvider<JournalDateController, DateTime>(
  JournalDateController.new,
);

class JournalDateController extends Notifier<DateTime> {
  @override
  DateTime build() => localDateOnly(ref.read(currentLocalTimeProvider)());

  void select(DateTime date) => state = localDateOnly(date);

  void previousDay() =>
      state = DateTime(state.year, state.month, state.day - 1);

  void nextDay() {
    final next = DateTime(state.year, state.month, state.day + 1);
    if (!next.isAfter(localDateOnly(ref.read(currentLocalTimeProvider)()))) {
      state = next;
    }
  }
}
