import 'dart:convert';

import '../../../core/utils/local_date_key.dart';
import '../../activity/models/activity_log.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../profile/models/body_metric.dart';
import '../../water/models/water_log.dart';
import '../../reports/models/period_report.dart';

/// RFC 4180 cell encoding. Only generated finite numbers bypass text escaping.
/// The apostrophe neutralizes spreadsheet formulas without removing user text.
String csvCell(Object? value) {
  String text;
  if (value == null) {
    text = '';
  } else if (value is num) {
    if (!value.isFinite) throw const FormatException('Số liệu không hữu hạn.');
    text = value.toString();
  } else if (value is String || value is bool) {
    text = value.toString();
    if (RegExp(
      r'^[\s\u0000-\u0020\u007f-\u009f\uFEFF\u200B-\u200F\u202A-\u202E\u2060-\u206F]*[=+\-@]',
    ).hasMatch(text)) {
      text = "'$text";
    }
  } else {
    throw const FormatException('Kiểu ô CSV không được hỗ trợ.');
  }
  return '"${text.replaceAll('"', '""')}"';
}

const journalCsvColumns = [
  'export_schema',
  'range_start',
  'range_end_exclusive',
  'record_kind',
  'record_id',
  'record_schema',
  'date_key',
  'recorded_at_utc',
  'timezone_offset_minutes',
  'timezone_basis',
  'meal_type',
  'item_index',
  'name',
  'quantity',
  'quantity_unit',
  'kcal',
  'protein_g',
  'protein_status',
  'carbs_g',
  'carbs_status',
  'fat_g',
  'fat_status',
  'fiber_g',
  'fiber_status',
  'water_ml',
  'activity_minutes',
  'weight_kg',
  'note',
  'source_label',
  'is_estimated',
];

/// Pure encoder for ALREADY owner-scoped repository results. This is not an
/// authorization boundary or a file writer. An eventual export controller must
/// capture/recheck the UID before loading and before writing a user-chosen file.
/// One row per meal item avoids counting both items and meal totals twice.
String buildJournalCsv({
  required DateTime start,
  required DateTime endExclusive,
  List<MealLog> meals = const [],
  List<WaterLog> water = const [],
  List<ActivityLog> activities = const [],
  List<BodyMetric> weights = const [],
}) => _encodeCsv(
  journalCsvColumns,
  _journalRows(
    start: start,
    endExclusive: endExclusive,
    meals: meals,
    water: water,
    activities: activities,
    weights: weights,
  ),
);

List<Map<String, Object?>> _journalRows({
  required DateTime start,
  required DateTime endExclusive,
  List<MealLog> meals = const [],
  List<WaterLog> water = const [],
  List<ActivityLog> activities = const [],
  List<BodyMetric> weights = const [],
}) {
  if (start != DateTime(start.year, start.month, start.day) ||
      endExclusive !=
          DateTime(endExclusive.year, endExclusive.month, endExclusive.day)) {
    throw const FormatException(
      'Khoảng xuất phải bắt đầu và kết thúc ở đầu ngày theo múi giờ thiết bị.',
    );
  }
  final first = localDateKey(start), last = localDateKey(endExclusive);
  final days = DateTime.utc(
    endExclusive.year,
    endExclusive.month,
    endExclusive.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
  if (days < 1 || days > maxReportDays || !start.isBefore(endExclusive)) {
    throw const FormatException('Chọn khoảng xuất từ 1 đến 366 ngày.');
  }
  final rows = <Map<String, Object?>>[];
  final ids = <String>{};
  bool selected(String key) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
      throw const FormatException('Ngày của bản ghi không hợp lệ.');
    }
    final date = DateTime.tryParse(key);
    if (date == null || localDateKey(date) != key) {
      throw const FormatException('Ngày của bản ghi không tồn tại.');
    }
    return key.compareTo(first) >= 0 && key.compareTo(last) < 0;
  }

  void identity(String kind, String id) {
    if (id.isEmpty || !ids.add('$kind/$id')) {
      throw const FormatException(
        'Bản ghi thiếu mã hoặc bị trùng trong nguồn xuất.',
      );
    }
  }

  Map<String, Object?> base(
    String kind,
    String id,
    Object schema,
    String key,
    DateTime at,
    int offset,
    String basis,
  ) {
    if (offset < -720 || offset > 840) {
      throw const FormatException('Múi giờ của bản ghi không hợp lệ.');
    }
    return {
      'export_schema': 'healthmate_journal_csv_v1',
      'range_start': first,
      'range_end_exclusive': last,
      'record_kind': kind,
      'record_id': id,
      'record_schema': schema,
      'date_key': key,
      'recorded_at_utc': at.toUtc().toIso8601String(),
      'timezone_offset_minutes': offset,
      'timezone_basis': basis,
    };
  }

  void nutrient(
    Map<String, Object?> row,
    String name,
    double value,
    bool known,
  ) {
    if (!value.isFinite || value < 0) {
      throw const FormatException('Giá trị chất dinh dưỡng không hợp lệ.');
    }
    row['${name}_g'] = known || value > 0 ? value : null;
    row['${name}_status'] = known
        ? 'known'
        : value > 0
        ? 'partial'
        : 'unknown';
  }

  for (final meal in meals) {
    final offset =
        meal.timezoneOffsetMinutes ??
        meal.consumedAt.toLocal().timeZoneOffset.inMinutes;
    final key =
        meal.dateKey ?? dateKeyFromTimestampAndOffset(meal.consumedAt, offset);
    if (!selected(key)) continue;
    identity('meal_item', meal.id);
    if (meal.items.isEmpty) {
      throw const FormatException('Bữa ăn thiếu snapshot.');
    }
    for (final (index, item) in meal.items.indexed) {
      item.withQuantity(item.quantity); // Reject damaged historical snapshots.
      final n = item.nutrition;
      final row = base(
        'meal_item',
        meal.id,
        meal.schemaVersion,
        key,
        meal.consumedAt,
        offset,
        meal.timezoneOffsetMinutes == null
            ? 'device_at_export_legacy'
            : 'stored',
      );
      row.addAll({
        'meal_type': meal.type.name,
        'item_index': index + 1,
        'name': item.name,
        'quantity': item.quantity,
        'quantity_unit': item.quantityUnit,
        'kcal': n.kcal,
        'source_label': item.sourceLabel,
        'is_estimated': item.isEstimated,
      });
      nutrient(row, 'protein', n.proteinG, n.proteinKnown);
      nutrient(row, 'carbs', n.carbsG, n.carbsKnown);
      nutrient(row, 'fat', n.fatG, n.fatKnown);
      nutrient(row, 'fiber', n.fiberG, n.fiberKnown);
      rows.add(row);
    }
  }
  for (final log in water) {
    if (!selected(log.dateKey)) continue;
    if (log.amountMl < WaterValidation.minAmountMl ||
        log.amountMl > WaterValidation.maxAmountMl) {
      throw const FormatException('Lượng nước của bản ghi không hợp lệ.');
    }
    identity('water', log.id);
    rows.add(
      base(
        'water',
        log.id,
        'water_logs_contract_v1',
        log.dateKey,
        log.consumedAt,
        log.timezoneOffsetMinutes,
        'stored',
      )..['water_ml'] = log.amountMl,
    );
  }
  for (final log in activities) {
    if (!selected(log.dateKey)) continue;
    if (log.durationMinutes < 1 || log.durationMinutes > 1440) {
      throw const FormatException('Thời lượng của bản ghi không hợp lệ.');
    }
    identity('activity', log.id);
    rows.add(
      base(
        'activity',
        log.id,
        'activity_logs_contract_v1',
        log.dateKey,
        log.performedAt,
        log.timezoneOffsetMinutes,
        'stored',
      )..addAll({
        'name': log.type.label,
        'activity_minutes': log.durationMinutes,
        'note': log.note,
      }),
    );
  }
  for (final log in weights) {
    final at = log.measuredAt.toLocal(),
        key = localDateKey(log.measuredAt.toLocal());
    if (!selected(key)) continue;
    if (!log.weightKg.isFinite || log.weightKg < 20 || log.weightKg > 500) {
      throw const FormatException('Cân nặng của bản ghi không hợp lệ.');
    }
    identity('weight', log.id);
    rows.add(
      base(
        'weight',
        log.id,
        'body_metrics_contract_v1',
        key,
        at,
        at.timeZoneOffset.inMinutes,
        'device_at_export',
      )..addAll({'weight_kg': log.weightKg, 'note': log.note}),
    );
  }
  rows.sort((a, b) {
    final time = DateTime.parse(
      a['recorded_at_utc'] as String,
    ).compareTo(DateTime.parse(b['recorded_at_utc'] as String));
    if (time != 0) return time;
    for (final key in ['record_kind', 'record_id']) {
      final comparison = (a[key] as String).compareTo(b[key] as String);
      if (comparison != 0) return comparison;
    }
    return ((a['item_index'] as int?) ?? 0).compareTo(
      (b['item_index'] as int?) ?? 0,
    );
  });
  return rows;
}

String _encodeCsv(List<String> columns, List<Map<String, Object?>> rows) {
  final output =
      '\uFEFF${[columns.map(csvCell).join(','), for (final row in rows) columns.map((key) => csvCell(row[key])).join(',')].join('\r\n')}\r\n';
  if (utf8.encode(output).length > 5 * 1024 * 1024) {
    throw const FormatException('File vượt 5 MB; hãy chọn khoảng ngắn hơn.');
  }
  return output;
}

/// Totals describe recorded items only. An unrecorded day never means zero intake.
/// Share validation and snapshot rows with the detailed export, not meal totals
/// or today's catalog, so edits to the catalog cannot rewrite historical reports.
String buildDailySummaryCsv({
  required DateTime start,
  required DateTime endExclusive,
  List<MealLog> meals = const [],
  List<WaterLog> water = const [],
  List<ActivityLog> activities = const [],
  List<BodyMetric> weights = const [],
}) {
  final detail = _journalRows(
    start: start,
    endExclusive: endExclusive,
    meals: meals,
    water: water,
    activities: activities,
    weights: weights,
  );
  final byDay = <String, List<Map<String, Object?>>>{};
  for (final row in detail) {
    byDay.putIfAbsent(row['date_key'] as String, () => []).add(row);
  }
  const columns = [
    'Ngày',
    'Số bữa đã ghi',
    'Số món đã ghi',
    'kcal đã ghi',
    'Đạm đã ghi (g)',
    'Trạng thái đạm',
    'Carb đã ghi (g)',
    'Trạng thái carb',
    'Béo đã ghi (g)',
    'Trạng thái béo',
    'Xơ đã ghi (g)',
    'Trạng thái xơ',
    'Nước đã ghi (ml)',
    'Vận động đã ghi (phút)',
    'Cân nặng gần nhất trong ngày (kg)',
    'Thời điểm cân (UTC)',
    'Số món ước tính',
    'Tình trạng ghi nhận',
    'Từ ngày',
    'Đến hết ngày',
    'Cách xác định ngày',
    'Lưu ý',
  ];
  final result = <Map<String, Object?>>[];
  var day = start;
  while (day.isBefore(endExclusive)) {
    final key = localDateKey(day), rows = byDay[key] ?? const [];
    final items = rows.where((r) => r['record_kind'] == 'meal_item').toList();
    final waters = rows.where((r) => r['record_kind'] == 'water').toList();
    final activity = rows.where((r) => r['record_kind'] == 'activity').toList();
    final weight = rows.where((r) => r['record_kind'] == 'weight').lastOrNull;
    num? sum(List<Map<String, Object?>> entries, String field) =>
        entries.isEmpty
        ? null
        : entries.fold<num>(0, (n, r) => n + (r[field] as num? ?? 0));
    final row = <String, Object?>{
      'Ngày': key,
      'Số bữa đã ghi': items.map((r) => r['record_id']).toSet().length,
      'Số món đã ghi': items.length,
      'kcal đã ghi': sum(items, 'kcal'),
      'Nước đã ghi (ml)': sum(waters, 'water_ml'),
      'Vận động đã ghi (phút)': sum(activity, 'activity_minutes'),
      'Cân nặng gần nhất trong ngày (kg)': weight?['weight_kg'],
      'Thời điểm cân (UTC)': weight?['recorded_at_utc'],
      'Số món ước tính': items.where((r) => r['is_estimated'] == true).length,
      'Tình trạng ghi nhận': rows.isEmpty ? 'Chưa có nhật ký' : 'Có nhật ký',
      'Từ ngày': localDateKey(start),
      'Đến hết ngày': localDateKey(
        DateTime(endExclusive.year, endExclusive.month, endExclusive.day - 1),
      ),
      'Cách xác định ngày':
          'Bữa ăn/nước/vận động: ngày đã lưu; bản ghi cũ và cân nặng: múi giờ thiết bị lúc xuất',
      'Lưu ý':
          'Chỉ tổng hợp dữ liệu đã ghi, không xác nhận đầy đủ cả ngày. Ô trống là chưa có dữ liệu; không thay thế tư vấn y tế.',
    };
    for (final (field, label) in [
      ('protein', 'đạm'),
      ('carbs', 'carb'),
      ('fat', 'béo'),
      ('fiber', 'xơ'),
    ]) {
      final known = items.where((r) => r['${field}_status'] == 'known').length;
      final total = sum(items, '${field}_g');
      final hasData =
          known > 0 || items.any((r) => r['${field}_status'] == 'partial');
      final title = '${label[0].toUpperCase()}${label.substring(1)}';
      row['$title đã ghi (g)'] = hasData ? total : null;
      row['Trạng thái $label'] = items.isEmpty || !hasData
          ? 'Chưa có dữ liệu'
          : known == items.length
          ? 'Đủ dữ liệu trong các món đã ghi'
          : 'Thiếu dữ liệu một phần';
    }
    result.add(row);
    day = DateTime(day.year, day.month, day.day + 1);
  }
  return _encodeCsv(columns, result);
}
