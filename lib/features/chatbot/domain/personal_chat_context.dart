import 'package:intl/intl.dart';

import '../../../core/utils/local_date_key.dart';
import '../../activity/data/activity_repository.dart';
import '../../activity/models/activity_log.dart';
import '../../nutrition/data/nutrition_repository.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition_targets/data/nutrition_target_repository.dart';
import '../../nutrition_targets/models/nutrition_target.dart';
import '../../wellness/data/energy_repository.dart';
import '../../wellness/models/energy_budget.dart';
import '../../profile/data/health_profile_repository.dart';
import '../../water/data/water_repository.dart';
import '../../water/models/water_log.dart';
import '../models/chat_models.dart';
import 'chat_request.dart';

/// Personal answers are calculated locally, never sent to the unpaid AI API.
class PersonalChatContext {
  const PersonalChatContext({
    required this.nutrition,
    required this.water,
    required this.activity,
    required this.targets,
    required this.profile,
    this.energy,
    this.energyLoader,
  });
  final NutritionRepository nutrition;
  final WaterRepository water;
  final ActivityRepository activity;
  final NutritionTargetRepository targets;
  final HealthProfileRepository profile;
  final EnergyRepository? energy;
  final Future<List<EnergyAdjustment>> Function(
    String uid,
    DateTime start,
    DateTime end,
  )?
  energyLoader;
  String _n(num value) => NumberFormat('#,##0.##', 'vi').format(value);
  String _date(DateTime value) => DateFormat('dd/MM/yyyy').format(value);

  Future<String> answer(String uid, ChatRequest request) async {
    if (uid.isEmpty ||
        !request.isPersonal ||
        request.days < 1 ||
        request.days > 7) {
      throw const ChatFailure(
        'Khoảng tra cứu chưa hợp lệ. Hãy chọn từ 1 đến 7 ngày.',
      );
    }
    final last = DateTime(
      request.end.year,
      request.end.month,
      request.end.day - 1,
    );
    final offset = request.start.timeZoneOffset.inMinutes;
    final zone =
        'UTC${offset < 0 ? '-' : '+'}${(offset.abs() ~/ 60).toString().padLeft(2, '0')}:${(offset.abs() % 60).toString().padLeft(2, '0')}';
    final lines = <String>[
      request.days == 1
          ? 'Nhật ký ${_date(request.start)} ($zone, múi giờ thiết bị).'
          : 'Từ ${_date(request.start)} đến ${_date(last)} · ${request.days} ngày ($zone).',
    ];
    try {
      switch (request.intent) {
        case ChatIntent.nutrition:
          _meals(
            lines,
            await nutrition.loadRange(uid, request.start, request.end),
            request,
          );
        case ChatIntent.water:
          _water(
            lines,
            await water.loadRange(uid, request.start, request.end),
            request,
          );
        case ChatIntent.activity:
          _activity(
            lines,
            await activity.loadRange(uid, request.start, request.end),
            request,
          );
        case ChatIntent.summary:
          final data = await (
            nutrition.loadRange(uid, request.start, request.end),
            water.loadRange(uid, request.start, request.end),
            activity.loadRange(uid, request.start, request.end),
          ).wait;
          _meals(lines, data.$1, request);
          _water(lines, data.$2, request);
          _activity(lines, data.$3, request);
        case ChatIntent.remaining:
          await _remaining(uid, request, lines);
        case ChatIntent.weight:
          final start = request.days == 1
              ? DateTime(
                  request.end.year,
                  request.end.month,
                  request.end.day - 90,
                )
              : request.start;
          final values = await profile.loadBodyMetricsRange(
            uid,
            start,
            request.end,
          );
          values.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
          if (values.isEmpty) {
            lines.add(
              request.days == 1
                  ? 'Chưa có cân nặng được ghi trong 90 ngày kết thúc vào ngày đã chọn.'
                  : 'Chưa có cân nặng được ghi trong khoảng ngày này.',
            );
          } else {
            final latest = values.last;
            lines.add(
              'Cân nặng gần nhất trong khoảng tra cứu: ${_n(latest.weightKg)} kg, ghi ngày ${_date(latest.measuredAt.toLocal())}.',
            );
            if (request.days > 1 && values.length > 1) {
              final delta = latest.weightKg - values.first.weightKg;
              lines.add(
                'So với lần đầu ngày ${_date(values.first.measuredAt.toLocal())}: ${delta > 0 ? '+' : ''}${_n(delta)} kg (${values.length} lần ghi). Đây là thay đổi giữa hai bản ghi, không phải kết luận về sức khỏe.',
              );
            }
          }
        case ChatIntent.knowledge:
        case ChatIntent.help:
          throw const ChatFailure('Hãy chọn một câu hỏi nhật ký.');
      }
    } on ChatFailure {
      rethrow;
    } catch (_) {
      final source = switch (request.intent) {
        ChatIntent.nutrition => 'bữa ăn',
        ChatIntent.water => 'nước uống',
        ChatIntent.activity => 'vận động',
        ChatIntent.remaining => 'bữa ăn và mục tiêu',
        ChatIntent.weight => 'cân nặng',
        _ => 'đủ dữ liệu',
      };
      throw ChatFailure(
        'Chưa tải được $source. Tôi chưa thể xác định tổng; hãy kiểm tra mạng rồi thử lại.',
      );
    }
    lines.add('Chỉ phản ánh dữ liệu đã ghi; có thể chưa đủ cả ngày.');
    return lines.join('\n\n');
  }

  void _meals(List<String> lines, List<MealLog> meals, ChatRequest r) {
    if (meals.isEmpty) {
      lines.add('Bữa ăn: chưa có bản ghi; chưa thể xác định lượng đã ăn.');
      return;
    }
    final total = totalMealNutrition(meals);
    lines.add('${meals.length} bữa đã ghi: ${_n(total.kcal)} kcal.');
    final fields = [
      ('Đạm', total.proteinG, total.proteinKnown),
      ('Carbohydrate', total.carbsG, total.carbsKnown),
      ('Chất béo', total.fatG, total.fatKnown),
      ('Chất xơ', total.fiberG, total.fiberKnown),
    ];
    lines.add(
      fields
          .map((f) => '${f.$1}: ${f.$3 ? '${_n(f.$2)} g' : 'chưa đủ dữ liệu'}')
          .join(' · '),
    );
    if (r.days > 1) {
      final covered = meals
          .map((m) => m.dateKey ?? localDateKey(m.consumedAt))
          .toSet()
          .length;
      lines.add(
        'Có bữa ghi trong $covered/${r.days} ngày. Trung bình ${_n(total.kcal / covered)} kcal/ngày có bản ghi; không thay ngày thiếu bằng 0.',
      );
    }
    if (r.days == 1) {
      final names = meals
          .expand((m) => m.items)
          .map((i) => i.name)
          .toSet()
          .take(6)
          .toList();
      if (names.isNotEmpty) lines.add('Món đã ghi: ${names.join(', ')}.');
    }
    if (meals.any((m) => m.items.any((i) => i.isEstimated))) {
      lines.add('Có món mang số liệu ước tính trong nhật ký.');
    }
  }

  void _water(List<String> lines, List<WaterLog> logs, ChatRequest r) {
    lines.add(
      logs.isEmpty
          ? 'Nước: chưa có bản ghi.'
          : 'Nước đã ghi: ${_n(totalWaterMl(logs))} ml (${logs.length} lần).',
    );
    if (r.days > 1 && logs.isNotEmpty) {
      lines.add(
        'Có ghi nước trong ${logs.map((l) => l.dateKey).toSet().length}/${r.days} ngày.',
      );
    }
  }

  void _activity(List<String> lines, List<ActivityLog> logs, ChatRequest r) {
    lines.add(
      logs.isEmpty
          ? 'Vận động: chưa có bản ghi.'
          : 'Vận động đã ghi: ${_n(totalActivityMinutes(logs))} phút (${logs.length} lần).',
    );
    if (r.days > 1 && logs.isNotEmpty) {
      lines.add(
        'Có ghi vận động trong ${logs.map((l) => l.dateKey).toSet().length}/${r.days} ngày.',
      );
    }
  }

  Future<void> _remaining(String uid, ChatRequest r, List<String> lines) async {
    final (meals, versions) = await (
      nutrition.loadRange(uid, r.start, r.end),
      targets.loadForRange(uid, localDateKey(r.start), localDateKey(r.end)),
    ).wait;
    final configured = <NutritionTarget>[];
    for (var i = 0; i < r.days; i++) {
      final d = DateTime(r.start.year, r.start.month, r.start.day + i);
      final target = targetForDate(versions, localDateKey(d));
      if (target != null) configured.add(target);
    }
    if (configured.length != r.days) {
      lines.add(
        'Chưa có mục tiêu dinh dưỡng cho ${r.days - configured.length}/${r.days} ngày trong khoảng này. Hãy đặt mục tiêu trong Mục tiêu dinh dưỡng; tôi không tự tính một mức ăn cá nhân.',
      );
      return;
    }
    final adjustments = energy != null
        ? await energy!.loadAdjustments(uid, r.start, r.end)
        : await energyLoader?.call(uid, r.start, r.end) ?? <EnergyAdjustment>[];
    final activities = await activity.loadRange(uid, r.start, r.end);
    var appliedKcal = 0.0;
    var appliedActivityKcal = 0.0;
    for (var i = 0; i < r.days; i++) {
      final day = localDateKey(
        DateTime(r.start.year, r.start.month, r.start.day + i),
      );
      final matches = adjustments.where((a) => a.dateKey == day);
      final budget = resolveEnergyBudget(
        configured[i],
        matches.isEmpty ? null : matches.first,
        hasManualActivity: activities.any((a) => a.dateKey == day),
        activities: activities.where((a) => a.dateKey == day),
      );
      appliedKcal += budget.adjustmentKcal;
      appliedActivityKcal += budget.activityAdjustmentKcal;
    }
    if (appliedKcal > 0) {
      lines.add(
        appliedActivityKcal == 0
            ? 'Ngân sách gồm ${_n(appliedKcal)} kcal bước chân đã được bạn xác nhận, chỉ là ước tính; mục tiêu macro giữ nguyên.'
            : 'Ngân sách gồm ${_n(appliedKcal)} kcal vận động đã được bạn xác nhận ngoài mức thường ngày, chỉ là ước tính; mục tiêu macro giữ nguyên.',
      );
    }
    if (meals.isEmpty) {
      lines.add(
        'Mục tiêu: ${_n(configured.fold(0.0, (s, t) => s + t.kcalTarget) + appliedKcal)} kcal cho khoảng ngày đã chọn. Chưa có bữa ăn được ghi, nên chưa thể kết luận lượng thực tế còn lại.',
      );
      return;
    }
    final total = totalMealNutrition(meals);
    final kcalTarget =
        configured.fold(0.0, (s, t) => s + t.kcalTarget) + appliedKcal;
    String difference(double target, double used, String unit) {
      final left = target - used;
      return left >= 0 ? 'còn ${_n(left)} $unit' : 'vượt ${_n(-left)} $unit';
    }

    lines.add(
      'Đã ghi ${_n(total.kcal)} / ${_n(kcalTarget)} kcal mục tiêu: ${difference(kcalTarget, total.kcal, 'kcal')}.',
    );
    if (configured.every((t) => t.hasMacros)) {
      for (final field in [
        (
          'Đạm',
          total.proteinG,
          total.proteinKnown,
          configured.fold(0.0, (s, t) => s + t.proteinGTarget!),
        ),
        (
          'Carbohydrate',
          total.carbsG,
          total.carbsKnown,
          configured.fold(0.0, (s, t) => s + t.carbsGTarget!),
        ),
        (
          'Chất béo',
          total.fatG,
          total.fatKnown,
          configured.fold(0.0, (s, t) => s + t.fatGTarget!),
        ),
      ]) {
        lines.add(
          field.$3
              ? '${field.$1}: đã ghi ${_n(field.$2)} / ${_n(field.$4)} g, ${difference(field.$4, field.$2, 'g')}.'
              : '${field.$1}: nhật ký chưa đủ dữ liệu để tính phần còn lại.',
        );
      }
    } else {
      lines.add('Chưa đặt đầy đủ mục tiêu ba chất cho khoảng ngày này.');
    }
    if (r.days > 1) {
      var proteinDays = 0, proteinKnownDays = 0;
      for (var i = 0; i < r.days; i++) {
        final key = localDateKey(
          DateTime(r.start.year, r.start.month, r.start.day + i),
        );
        final dayMeals = meals
            .where((m) => (m.dateKey ?? localDateKey(m.consumedAt)) == key)
            .toList();
        final target = configured[i];
        if (dayMeals.isNotEmpty && target.hasMacros) {
          final totals = totalMealNutrition(dayMeals);
          if (totals.proteinKnown) {
            proteinKnownDays++;
            if (totals.proteinG >= target.proteinGTarget!) proteinDays++;
          }
        }
      }
      if (proteinKnownDays > 0) {
        lines.add(
          'Đạm đã ghi đạt ít nhất mục tiêu ở $proteinDays/$proteinKnownDays ngày có đủ mục tiêu và dữ liệu đạm. Không đánh giá ngày thiếu dữ liệu.',
        );
      }
      final covered = meals
          .map((m) => m.dateKey ?? localDateKey(m.consumedAt))
          .toSet()
          .length;
      lines.add(
        'Có bữa ghi trong $covered/${r.days} ngày. Khoảng chênh trên chỉ so mục tiêu với nhật ký, không phải khuyến nghị ăn bù.',
      );
    } else {
      lines.add(
        'Phần còn lại dựa trên mục tiêu bạn đã đặt và bữa đã ghi, không phải chỉ định phải ăn thêm.',
      );
    }
  }
}
