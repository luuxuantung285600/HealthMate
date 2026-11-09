import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../core/widgets/help_details.dart';
import '../../food_library/presentation/food_nutrition_text.dart';
import '../../nutrition/models/food_avoidance.dart';
import '../../nutrition/models/food_diet.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../models/meal_plan_suggestion.dart';

class MealPlanSuggestionDialog extends StatefulWidget {
  const MealPlanSuggestionDialog({
    required this.suggestion,
    required this.diet,
    required this.avoidance,
    required this.isCurrent,
    required this.onAdd,
    super.key,
  });

  final MealPlanSuggestion suggestion;
  final FoodDietPreference diet;
  final FoodAvoidance avoidance;
  final bool Function() isCurrent;
  final Future<bool> Function(MealDraft) onAdd;

  @override
  State<MealPlanSuggestionDialog> createState() =>
      _MealPlanSuggestionDialogState();
}

class _MealPlanSuggestionDialogState extends State<MealPlanSuggestionDialog> {
  bool saving = false;
  int processed = 0, added = 0, kept = 0;
  String? error;
  bool get complete => processed == widget.suggestion.drafts.length;

  Future<void> saveRemaining() async {
    if (saving || complete || !widget.isCurrent()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      // Each meal is atomic and bounded by existing Rules. Advance only after
      // ACK, so retry starts at the first unresolved draft, using this preview.
      while (processed < widget.suggestion.drafts.length) {
        if (!mounted || !widget.isCurrent()) return;
        final created = await widget.onAdd(widget.suggestion.drafts[processed]);
        if (!mounted || !widget.isCurrent()) return;
        setState(() {
          processed++;
          if (created) {
            added++;
          } else {
            kept++;
          }
        });
      }
    } catch (failure) {
      if (mounted && widget.isCurrent()) {
        setState(() {
          error = failure is FormatException
              ? failure.message
              : 'Chưa xác nhận được bữa tiếp theo. Kiểm tra kết nối rồi lưu tiếp.';
        });
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      title: const Text('Xem trước gợi ý 7 ngày'),
      content: SizedBox(
        width: 440,
        height: 400,
        child: ListView(
          children: [
            if (widget.diet != FoodDietPreference.general)
              Text('Lựa chọn trong hồ sơ: ${widget.diet.label}.'),
            if (widget.avoidance.isActive)
              Text('Đang tránh: ${widget.avoidance.label}'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chỉ lưu kế hoạch. Xác nhận đã ăn để ghi nhật ký. Bữa đã có khi lưu sẽ được giữ nguyên.',
              ),
            ),
            for (final summary in widget.suggestion.summaries)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  key: ValueKey('suggested-day-${localDateKey(summary.date)}'),
                  initiallyExpanded:
                      summary == widget.suggestion.summaries.first,
                  title: Text(
                    DateFormat('EEEE dd/MM', 'vi').format(summary.date),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: [
                        Text(
                          '${foodNumber(summary.plannedKcal)} kcal dự kiến'
                          '${summary.targetKcal == null ? ' · Chưa có mục tiêu' : ' / ${foodNumber(summary.targetKcal!)} kcal mục tiêu'}',
                        ),
                        if (summary.outsideTarget)
                          const Text('Lệch trên 5% · Cần kiểm tra khẩu phần'),
                      ],
                    ),
                  ),
                  children: [
                    for (final draft in widget.suggestion.drafts.where(
                      (d) => d.dateKey == localDateKey(summary.date),
                    ))
                      Padding(
                        key: ValueKey(
                          'suggested-meal-${draft.dateKey}-${draft.type.name}',
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 6,
                          children: [
                            Text(
                              '${draft.type.label} · ${foodNumber(draft.totals.kcal)} kcal',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            for (final item in draft.items)
                              Text(
                                '${item.name} · ${foodNumber(item.grams)} g',
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const HelpDetails(
              title: 'Cách gợi ý và giới hạn',
              children: [
                Text(
                  'Điều chỉnh gram theo mục tiêu kcal, giữ các bữa đã có kế hoạch. Chưa cân bằng riêng từng chất hay thay thế tư vấn dinh dưỡng.',
                ),
                Text(
                  'Ẩn món cần tránh và món chưa rõ thành phần. Kiểm tra món thực tế; bộ lọc không xác minh nhiễm chéo.',
                ),
                Text(
                  'Số kcal ở đây là bản xem trước. Nếu dữ liệu đổi trên thiết bị khác, hãy kiểm tra lại thực đơn sau khi lưu.',
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .35,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (saving || processed > 0 || error != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'Đã xử lý $processed/${widget.suggestion.drafts.length} bữa · Thêm $added · Giữ nguyên $kept',
                      key: const ValueKey('suggestion-progress'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    saving
                        ? 'Đang chờ máy chủ xác nhận. Nếu mất mạng, hãy kết nối lại; không gửi lặp.'
                        : complete
                        ? 'Đã xử lý xong. Các bữa có sẵn được giữ nguyên.'
                        : 'Các bữa đã lưu được giữ lại kể cả khi đóng. Lưu tiếp để xử lý phần còn lại.',
                  ),
                ],
                if (saving) const LinearProgressIndicator(),
                if (error != null)
                  Text(
                    error!,
                    key: const ValueKey('suggestion-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: saving ? null : () => Navigator.pop(context),
                      child: Text(
                        complete
                            ? 'Xong'
                            : processed > 0
                            ? 'Đóng'
                            : 'Hủy',
                      ),
                    ),
                    if (!complete)
                      FilledButton(
                        key: const ValueKey('save-suggested-plans'),
                        onPressed: saving ? null : saveRemaining,
                        child: Text(
                          error != null ? 'Lưu tiếp' : 'Thêm bữa còn trống',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
