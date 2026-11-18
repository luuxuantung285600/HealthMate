import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../activity/providers/activity_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../nutrition_targets/providers/nutrition_target_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../models/energy_budget.dart';
import '../providers/energy_providers.dart';

String energyNumber(num value) => NumberFormat('0.#', 'vi').format(value);

class EnergyBudgetCard extends ConsumerWidget {
  const EnergyBudgetCard({required this.day, super.key});
  final DateTime day;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = localDateKey(day),
        budget = ref.watch(dailyEnergyBudgetProvider(localDateKey(day))),
        meals = ref.watch(mealLogsProvider(localDateOnly(day)));
    final recorded = !meals.isLoading && !meals.hasError ? meals.value : null;
    return Card(
      key: const ValueKey('energy-budget-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ngân sách năng lượng · ${DateFormat('dd/MM').format(day)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            budget.when(
              skipLoadingOnReload: false,
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Column(
                children: [
                  const Text(
                    'Chưa tải đủ ngân sách; không dùng số cũ để tính còn lại.',
                  ),
                  TextButton(
                    onPressed: () {
                      retryEnergyBudget(ref, key);
                    },
                    child: const Text('Thử lại ngân sách'),
                  ),
                ],
              ),
              data: (b) => b == null
                  ? const Text(
                      'Chưa đặt mục tiêu dinh dưỡng. Thiết lập tại Tổng quan hoặc Nhật ký.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mục tiêu gốc: ${energyNumber(b.baseTarget.kcalTarget)} kcal',
                        ),
                        Text(
                          'Vận động đã xác nhận: +${energyNumber(b.adjustmentKcal)} kcal (ước tính)',
                        ),
                        Text('Ngân sách: ${energyNumber(b.kcalTarget)} kcal'),
                        if (recorded != null) ...[
                          Text(
                            'Đã ghi: ${energyNumber(totalMealNutrition(recorded).kcal)} kcal',
                          ),
                          Text(
                            '${b.remaining(totalMealNutrition(recorded).kcal) >= 0 ? 'Còn theo nhật ký' : 'Vượt ngân sách'}: ${energyNumber(b.remaining(totalMealNutrition(recorded).kcal).abs())} kcal',
                          ),
                          if (recorded.isEmpty)
                            const Text(
                              'Chưa ghi bữa ăn; không có nghĩa là bạn chưa ăn.',
                            ),
                        ] else
                          const Text('Chưa tải đủ bữa ăn; chưa tính còn/vượt.'),
                        Text(b.explanation),
                        const Text(
                          'Không thay kcal của món đã ăn. Chỉ đối chiếu nhật ký, không phải mức thâm hụt đã đo.',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> openWellnessPreferences(
  BuildContext context,
  WidgetRef ref,
  WellnessPreferences initial,
) async {
  final uid = ref.read(authSessionProvider).value?.uid;
  if (uid == null) return;
  await showDialog<WellnessPreferences>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AccountBoundDialog(
      child: WellnessPreferencesDialog(
        initial: initial,
        onSave: (p) async {
          if (ref.read(authSessionProvider).value?.uid != uid) return false;
          await ref.read(energyRepositoryProvider).savePreferences(uid, p);
          return ref.read(authSessionProvider).value?.uid == uid;
        },
      ),
    ),
  );
}

class WellnessPreferencesDialog extends StatefulWidget {
  const WellnessPreferencesDialog({
    required this.initial,
    required this.onSave,
    super.key,
  });
  final WellnessPreferences initial;
  final Future<bool> Function(WellnessPreferences) onSave;
  @override
  State<WellnessPreferencesDialog> createState() =>
      _WellnessPreferencesDialogState();
}

class _WellnessPreferencesDialogState extends State<WellnessPreferencesDialog>
    with ConfirmedSave<WellnessPreferences, WellnessPreferencesDialog> {
  late final stride = TextEditingController(
    text: widget.initial.stepLengthCm?.toString() ?? '',
  );
  late final baseline = TextEditingController(
    text: widget.initial.baselineSteps?.toString() ?? '',
  );
  late final hours = TextEditingController(
    text: widget.initial.sleepGoalMinutes == null
        ? ''
        : (widget.initial.sleepGoalMinutes! / 60).toString(),
  );
  String? error;
  @override
  void dispose() {
    stride.dispose();
    baseline.dispose();
    hours.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => guardSave(
    AlertDialog(
      title: const Text('Thiết lập bước và giờ ngủ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Để trống thông tin chưa biết. Đo khoảng cách một đoạn rồi chia cho số bước để lấy độ dài một bước; không phải một sải hai bước.',
            ),
            TextField(
              key: const ValueKey('step-length'),
              controller: stride,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Độ dài một bước (cm)',
              ),
            ),
            TextField(
              key: const ValueKey('baseline-steps'),
              controller: baseline,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số bước đã tính sẵn trong mục tiêu gốc',
              ),
            ),
            const Text(
              'Nếu chưa biết phần vận động đã tính sẵn, hãy để trống và chỉ xem ước tính; không cộng thêm ngân sách.',
            ),
            TextField(
              key: const ValueKey('sleep-goal-hours'),
              controller: hours,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Mục tiêu giờ ngủ bạn tự đặt (giờ)',
              ),
            ),
            if (error != null) Text(error!),
            saveFeedback(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const ValueKey('save-wellness-preferences'),
          onPressed: () {
            double? decimal(String s) =>
                double.tryParse(s.trim().replaceAll(',', '.'));
            final s = stride.text.trim(),
                b = baseline.text.trim(),
                h = hours.text.trim();
            if ((s.isNotEmpty && decimal(s) == null) ||
                (b.isNotEmpty && int.tryParse(b) == null) ||
                (h.isNotEmpty &&
                    (decimal(h) == null || !decimal(h)!.isFinite))) {
              setState(() => error = 'Nhập số hợp lệ hoặc để trống.');
              return;
            }
            final p = WellnessPreferences(
              stepLengthCm: s.isEmpty ? null : decimal(s),
              baselineSteps: b.isEmpty ? null : int.parse(b),
              sleepGoalMinutes: h.isEmpty ? null : (decimal(h)! * 60).round(),
            );
            final validation = p.validate();
            if (validation != null) {
              setState(() => error = validation);
              return;
            }
            saveDraft(p, widget.onSave);
          },
          child: const Text('Lưu thiết lập'),
        ),
      ],
    ),
  );
}

class StepEnergyCard extends ConsumerWidget {
  const StepEnergyCard({required this.steps, super.key});
  final int? steps;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = localDateOnly(ref.watch(localClockProvider)),
        key = localDateKey(today);
    final prefs = ref.watch(wellnessPreferencesProvider),
        metrics = ref.watch(latestBodyMetricProvider(today)),
        activities = ref.watch(activityLogsProvider(key)),
        target = ref.watch(nutritionTargetProvider(key));
    final adjustment = ref.watch(energyAdjustmentProvider(key));
    final p = !prefs.isLoading && !prefs.hasError ? prefs.value : null;
    final metric =
        !metrics.isLoading && !metrics.hasError && metrics.value!.isNotEmpty
        ? metrics.value!.first
        : null;
    final now = ref.watch(currentLocalTimeProvider)();
    final fresh =
        metric != null &&
        metric.weightKg.isFinite &&
        metric.weightKg >= 20 &&
        metric.weightKg <= 300 &&
        !metric.measuredAt.isAfter(now) &&
        now.difference(metric.measuredAt) <= const Duration(days: 90);
    final estimate = steps != null && p?.stepLengthCm != null && fresh
        ? StepEnergyEstimate(
            steps!,
            p!.stepLengthCm!,
            metric.weightKg,
            p.baselineSteps ?? steps!,
          )
        : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bước chân và calo ước tính',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (prefs.isLoading || metrics.isLoading)
              const LinearProgressIndicator(),
            if (prefs.hasError || metrics.hasError)
              TextButton(
                onPressed: () {
                  ref.invalidate(wellnessPreferencesProvider);
                  ref.invalidate(latestBodyMetricProvider(today));
                },
                child: const Text('Chưa tải đủ thiết lập/cân nặng · Thử lại'),
              ),
            if (estimate == null)
              const Text(
                'Cần số bước đã ghi, cân nặng trong 90 ngày gần nhất và độ dài một bước đã đo. Chưa đủ dữ liệu thì không tự quy đổi.',
              ),
            if (estimate != null) ...[
              Text(
                '${estimate.steps} bước · khoảng ${energyNumber(estimate.distanceKm)} km',
              ),
              Text(
                'Vận động trên mức nghỉ: khoảng ${energyNumber(estimate.netKcal)} kcal',
              ),
              if (p!.baselineSteps != null)
                Text(
                  'Vượt ${estimate.baselineSteps} bước đã tính sẵn: khoảng ${energyNumber(estimate.extraKcal)} kcal',
                )
              else
                const Text(
                  'Chưa xác nhận mức bước đã tính sẵn; chỉ xem ước tính, không cộng ngân sách.',
                ),
              Text(
                'Cân nặng ${energyNumber(metric!.weightKg)} kg · ${DateFormat('dd/MM').format(metric.measuredAt)}',
              ),
            ],
            const Text(
              'Giả định đi bộ thông thường trên đường bằng. Không đo tốc độ/độ dốc/nhịp tim; không dùng như số calo đốt chính xác. Không tự áp dụng ngày sau.',
            ),
            if (p != null)
              TextButton(
                key: const ValueKey('configure-step-energy'),
                onPressed: () => openWellnessPreferences(context, ref, p),
                child: const Text('Thiết lập độ dài bước và mục tiêu ngủ'),
              ),
            if (activities.hasError || target.hasError || adjustment.hasError)
              const Text('Chưa tải đủ dữ liệu để xác nhận điều chỉnh.'),
            if (!activities.isLoading &&
                !activities.hasError &&
                activities.value!.isNotEmpty)
              const Text(
                'Hôm nay có vận động nhập tay. Giữ calo bước riêng để tránh tính trùng; không cộng thêm ngân sách.',
              ),
            if (estimate != null &&
                estimate.extraKcal >= 1 &&
                !target.isLoading &&
                !target.hasError &&
                target.value != null &&
                !activities.isLoading &&
                !activities.hasError &&
                activities.value!.isEmpty &&
                !adjustment.isLoading &&
                !adjustment.hasError)
              OutlinedButton(
                key: const ValueKey('confirm-step-budget'),
                onPressed: () async {
                  final uid = ref.read(authSessionProvider).value?.uid;
                  if (uid == null) return;
                  await showDialog<EnergyAdjustment>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AccountBoundDialog(
                      child: StepAdjustmentDialog(
                        maximum: estimate.extraKcal,
                        create: (amount) => EnergyAdjustment(
                          dateKey: key,
                          timezoneOffsetMinutes: now.timeZoneOffset.inMinutes,
                          steps: estimate.steps,
                          baselineSteps: estimate.baselineSteps,
                          stepLengthCm: estimate.stepLengthCm,
                          weightKg: estimate.weightKg,
                          weightMeasuredAt: metric!.measuredAt,
                          targetFromDateKey: target.value!.effectiveFromDateKey,
                          baseKcalTarget: target.value!.kcalTarget,
                          kcal: amount,
                        ),
                        onSave: (a) async {
                          if (ref.read(authSessionProvider).value?.uid != uid) {
                            return false;
                          }
                          await ref
                              .read(energyRepositoryProvider)
                              .saveAdjustment(uid, a);
                          return ref.read(authSessionProvider).value?.uid ==
                              uid;
                        },
                      ),
                    ),
                  );
                },
                child: Text(
                  adjustment.value == null
                      ? 'Xác nhận cộng vào ngân sách hôm nay'
                      : 'Xác nhận lại điều chỉnh hôm nay',
                ),
              ),
            if (!adjustment.isLoading &&
                !adjustment.hasError &&
                adjustment.value != null)
              TextButton(
                key: const ValueKey('clear-step-budget'),
                onPressed: () async {
                  final uid = ref.read(authSessionProvider).value?.uid;
                  if (uid == null) return;
                  try {
                    await ref
                        .read(energyRepositoryProvider)
                        .clearAdjustment(uid, key);
                  } catch (_) {
                    if (context.mounted &&
                        ref.read(authSessionProvider).value?.uid == uid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Chưa bỏ được điều chỉnh. Hãy thử lại.',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Bỏ điều chỉnh hôm nay'),
              ),
            EnergyBudgetCard(day: today),
          ],
        ),
      ),
    );
  }
}

class StepAdjustmentDialog extends StatefulWidget {
  const StepAdjustmentDialog({
    required this.maximum,
    required this.create,
    required this.onSave,
    super.key,
  });
  final double maximum;
  final EnergyAdjustment Function(double) create;
  final Future<bool> Function(EnergyAdjustment) onSave;
  @override
  State<StepAdjustmentDialog> createState() => _StepAdjustmentDialogState();
}

class _StepAdjustmentDialogState extends State<StepAdjustmentDialog>
    with ConfirmedSave<EnergyAdjustment, StepAdjustmentDialog> {
  late final amount = TextEditingController(
    text: widget.maximum.clamp(0, 5000).floor().toString(),
  );
  bool accepted = false;
  String? error;
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => guardSave(
    AlertDialog(
      title: const Text('Điều chỉnh cho hôm nay'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tối đa phần vượt mức bước đã tính sẵn: ${energyNumber(widget.maximum)} kcal ước tính. Bạn có thể chọn ít hơn; không sửa mục tiêu gốc hoặc macro.',
            ),
            TextField(
              key: const ValueKey('step-adjustment-kcal'),
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Kcal muốn cộng hôm nay',
              ),
            ),
            CheckboxListTile(
              key: const ValueKey('ack-step-budget'),
              value: accepted,
              onChanged: (v) => setState(() => accepted = v ?? false),
              title: const Text(
                'Tôi đã kiểm tra mức bước tính sẵn và muốn dùng ước tính này cho hôm nay.',
              ),
            ),
            if (error != null) Text(error!),
            saveFeedback(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const ValueKey('save-step-budget'),
          onPressed: !accepted
              ? null
              : () {
                  final value = double.tryParse(
                    amount.text.replaceAll(',', '.'),
                  );
                  if (value == null) {
                    setState(() => error = 'Nhập kcal hợp lệ.');
                    return;
                  }
                  final a = widget.create(value), validation = a.validate();
                  if (validation != null) {
                    setState(() => error = validation);
                    return;
                  }
                  saveDraft(a, widget.onSave);
                },
          child: const Text('Áp dụng hôm nay'),
        ),
      ],
    ),
  );
}
