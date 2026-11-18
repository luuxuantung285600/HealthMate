import '../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../nutrition_targets/models/personal_nutrition_plan.dart';
import '../models/health_goal.dart';
import '../models/personalization_answers.dart';
import '../models/profile_validation.dart';

class OnboardingPrompt extends StatelessWidget {
  const OnboardingPrompt({
    super.key,
    required this.title,
    required this.message,
  });
  final String title, message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: const Icon(AppIcons.leaf),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Text(title, style: theme.textTheme.titleLarge),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(message, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class OnboardingChoice extends StatelessWidget {
  const OnboardingChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
    this.icon,
  });
  final String label;
  final String? description;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected
              ? colors.primaryContainer
              : colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: colors.primary),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 6),
                          Text(description!),
                        ],
                      ],
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 8),
                    Icon(AppIcons.circleCheck, color: colors.primary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingSurvey extends StatelessWidget {
  const OnboardingSurvey({
    super.key,
    required this.id,
    required this.answers,
    required this.onChanged,
    this.goal,
    this.enabled = true,
  });
  final String id;
  final PersonalizationAnswers answers;
  final ValueChanged<PersonalizationAnswers> onChanged;
  final bool enabled;
  final HealthGoal? goal;

  @override
  Widget build(BuildContext context) {
    final question = personalizationQuestions.firstWhere((q) => q.id == id);
    final options = id == 'sleepHours'
        ? [for (var h = 0; h <= 48; h++) SurveyOption(h / 2, '${h / 2} giờ')]
        : question.options;
    return Column(
      key: ValueKey('survey-$id'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (id == 'avoidFoods')
          TextFormField(
            key: const ValueKey('survey-avoidFoods-input'),
            initialValue: answers[id] as String? ?? '',
            enabled: enabled,
            maxLength: 200,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Thực phẩm cần tránh',
              hintText: 'Ví dụ: sữa; trứng; đậu phộng',
            ),
            onChanged: (value) => onChanged(
              answers.withAnswer(
                id,
                value.trim().isEmpty ? null : value.trim(),
              ),
            ),
          )
        else if (id == 'sleepHours')
          DropdownButtonFormField<Object>(
            key: const ValueKey('survey-sleepHours-input'),
            initialValue: answers[id] ?? 'unanswered',
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Thời lượng ngủ'),
            items: [
              const DropdownMenuItem(
                value: 'unanswered',
                child: Text('Để sau'),
              ),
              for (final option in options)
                DropdownMenuItem(
                  value: option.value,
                  child: Text(option.label),
                ),
            ],
            onChanged: enabled
                ? (value) => onChanged(
                    answers.withAnswer(
                      id,
                      value == 'unanswered' ? null : value,
                    ),
                  )
                : null,
          )
        else ...[
          for (final option in options)
            OnboardingChoice(
              key: ValueKey('survey-$id-${option.value}'),
              label: option.label,
              description: _description(option),
              selected: answers[id] == option.value,
              onTap: enabled
                  ? () {
                      var next = answers.withAnswer(id, option.value);
                      if (id == 'exerciseDays' && option.value == 0) {
                        next = next
                            .withAnswer('exerciseMinutes', null)
                            .withAnswer('exerciseType', null);
                      }
                      onChanged(next);
                    }
                  : null,
            ),
        ],
        if (answers[id] != null && id != 'avoidFoods' && id != 'sleepHours')
          TextButton(
            onPressed: enabled
                ? () => onChanged(answers.withAnswer(id, null))
                : null,
            child: const Text('Xóa câu trả lời, để sau'),
          ),
      ],
    );
  }

  String? _description(SurveyOption option) {
    if (id == 'activity') {
      return PlanActivity.values
          .firstWhere((value) => value.name == option.value)
          .description;
    }
    if (id == 'pace') {
      final pace = PlanPace.values.firstWhere(
        (value) => value.name == option.value,
      );
      final losing = goal == HealthGoal.loseWeight;
      final fraction = losing ? pace.lossFraction : pace.gainFraction;
      return '${losing ? 'Giảm' : 'Tăng'} ${(fraction * 100).round()}% so với mức duy trì ước tính.';
    }
    return null;
  }
}

class OnboardingMeasurement extends StatelessWidget {
  const OnboardingMeasurement({
    super.key,
    required this.controller,
    required this.fieldKey,
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.validator,
    this.enabled = true,
  });
  final TextEditingController controller;
  final String fieldKey, label, unit;
  final double min, max;
  final String? Function(String?) validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final value = ProfileValidation.parseDecimal(controller.text);
    return Column(
      children: [
        TextFormField(
          key: ValueKey(fieldKey),
          controller: controller,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall,
          decoration: InputDecoration(labelText: '$label ($unit)'),
          validator: validator,
        ),
        const SizedBox(height: 24),
        Slider(
          key: ValueKey('$fieldKey-slider'),
          min: min,
          max: max,
          divisions: ((max - min) * 10).round(),
          value: (value ?? (unit == 'cm' ? 170 : 60)).clamp(min, max),
          label: value == null
              ? 'Kéo để chọn'
              : '${value.toStringAsFixed(1)} $unit',
          semanticFormatterCallback: (v) => '${v.toStringAsFixed(1)} $unit',
          onChanged: enabled
              ? (v) => controller.text = v.toStringAsFixed(1)
              : null,
        ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 8,
          children: [
            Text('${min.toInt()} $unit'),
            Text('${max.toInt()} $unit'),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Kéo để chọn hoặc chạm vào số để nhập chính xác.'),
      ],
    );
  }
}

class OnboardingBmi extends StatelessWidget {
  const OnboardingBmi({
    super.key,
    required this.heightCm,
    required this.weightKg,
    this.isTarget = false,
  });
  final double? heightCm, weightKg;
  final bool isTarget;

  @override
  Widget build(BuildContext context) {
    final bmi = ProfileValidation.bmi(heightCm: heightCm, weightKg: weightKg);
    if (bmi == null) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(top: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${isTarget ? 'BMI tại cân nặng đích' : 'BMI hiện tại'}: ${bmi.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              bmi < 18.5
                  ? 'Dưới khoảng tham chiếu BMI người lớn.'
                  : bmi < 25
                  ? 'Trong khoảng tham chiếu BMI 18,5–24,9 của người lớn.'
                  : 'Trên khoảng tham chiếu BMI người lớn.',
            ),
            const SizedBox(height: 8),
            const Text(
              'BMI = kg / m². Chỉ số tham khảo; không phân biệt cơ, mỡ và không dùng để chẩn đoán.',
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPlanSummary extends StatelessWidget {
  const OnboardingPlanSummary({
    super.key,
    required this.plan,
    required this.name,
  });
  final PersonalNutritionPlan plan;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = NumberFormat('#,##0.#', 'vi');
    final difference = plan.maintenanceKcal * plan.input.adjustmentFraction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$name, kế hoạch của bạn đã sẵn sàng!',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Mục tiêu của bạn: ${plan.input.goal!.label}',
          style: theme.textTheme.titleMedium,
        ),
        if (plan.input.goal == HealthGoal.gainMuscle)
          const Text(
            'Bắt đầu ở mức duy trì và ưu tiên đạm. Đây chưa phải chương trình tập hoặc cam kết tăng cơ.',
          ),
        if (plan.input.goal == HealthGoal.healthierHabits)
          const Text(
            'Theo dõi thói quen là trọng tâm; bạn có thể dùng app mà chưa đặt mục tiêu calo.',
          ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text(
                '${plan.kcal.toStringAsFixed(0)} kcal',
                key: const ValueKey('onboarding-nutrition-summary'),
                style: theme.textTheme.displaySmall,
              ),
              const Text('Mục tiêu nạp mỗi ngày · ước tính'),
              const SizedBox(height: 12),
              Text(
                '${number.format(plan.kcal * 7)} kcal / 7 ngày nếu giữ cùng mục tiêu',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _PlanRow(
          'Năng lượng nghỉ ước tính',
          '${number.format(plan.restingKcal)} kcal',
        ),
        _PlanRow(
          'Năng lượng duy trì (TDEE) ước tính',
          '${number.format(plan.maintenanceKcal)} kcal',
        ),
        _PlanRow(
          'Điều chỉnh theo mục tiêu',
          '${difference >= 0 ? '+' : ''}${number.format(difference)} kcal',
        ),
        const SizedBox(height: 12),
        const Text('Kết quả cuối làm tròn đến 10 kcal.'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            Chip(label: Text('Đạm ${number.format(plan.proteinG)} g')),
            Chip(label: Text('Carb ${number.format(plan.carbsG)} g')),
            Chip(label: Text('Béo ${number.format(plan.fatG)} g')),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Đề xuất chỉ được lưu khi bạn chọn áp dụng và bấm hoàn tất. Theo dõi tiến độ thực tế để xem lại mức khởi đầu này.',
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Cách tính và nguồn tham khảo'),
          children: [
            Text(
              'Mifflin–St Jeor (1990), nhân hệ số vận động ${plan.input.activity!.factor}. Điều chỉnh ${number.format(plan.input.adjustmentFraction * 100)}%, làm tròn đến 10 kcal. Giấc ngủ và bài tập khai báo không cộng calo thêm lần nữa.',
            ),
            const SelectableText(
              'pubmed.ncbi.nlm.nih.gov/2305711/\nwww.niddk.nih.gov/bwp',
            ),
            const Text(
              'Nhịp điều chỉnh là chính sách của HealthMate. Phân bổ dưỡng chất trong khoảng AMDR người lớn; đây không phải chế độ ăn điều trị.',
            ),
          ],
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(label),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    ),
  );
}
