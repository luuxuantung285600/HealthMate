import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../profile/providers/profile_providers.dart';
import '../../nutrition_targets/providers/nutrition_target_providers.dart';
import '../../../core/utils/local_date_key.dart';
import '../models/activity_energy.dart';
import '../models/activity_log.dart';
import '../providers/activity_energy_providers.dart';

/// Shared by manual logging and the timer summary. No default MET or effort is
/// inferred from the timer pace, the GIF, or a target weight.
class ActivityEnergyEditor extends ConsumerStatefulWidget {
  const ActivityEnergyEditor({
    required this.type,
    required this.performedAt,
    required this.durationSeconds,
    this.initial,
    this.guided = false,
    this.enabled = true,
    this.onChanged,
    super.key,
  });
  final ActivityType type;
  final DateTime performedAt;
  final int durationSeconds;
  final ActivityEnergyEstimate? initial;
  final bool guided, enabled;
  final VoidCallback? onChanged;
  @override
  ConsumerState<ActivityEnergyEditor> createState() =>
      ActivityEnergyEditorState();
}

class ActivityEnergyEditorState extends ConsumerState<ActivityEnergyEditor> {
  late String? _code = widget.initial?.metCode;
  late bool _include = widget.initial?.includedInBudget ?? false;
  bool _edited = false;
  bool _recalculate = false;
  bool get changed => _edited;
  @override
  void didUpdateWidget(ActivityEnergyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type ||
        oldWidget.durationSeconds != widget.durationSeconds ||
        oldWidget.performedAt != widget.performedAt) {
      _edited = true;
      _recalculate = true;
      _include = false;
      if (oldWidget.type != widget.type) _code = null;
    }
  }

  ActivityEnergyEstimate? get estimate {
    if (!widget.enabled) return widget.initial;
    final target = ref
        .read(nutritionTargetProvider(localDateKey(widget.performedAt)))
        .value;
    if (!_recalculate && widget.initial != null) {
      return _edited
          ? widget.initial!.withBudget(
              _include ? target?.effectiveFromDateKey : null,
              _include ? target?.kcalTarget : null,
            )
          : widget.initial;
    }
    final entry = activityMetForCode(_code);
    final birthDate = ref.read(userProfileProvider).value?.birthDate;
    final weight = ref
        .read(activityWeightProvider(widget.performedAt))
        .value
        ?.firstOrNull;
    final age = birthDate == null
        ? null
        : ageAtActivity(birthDate, widget.performedAt);
    if (entry == null ||
        weight == null ||
        age == null ||
        age < 19 ||
        age > 59 ||
        widget.durationSeconds < 60 ||
        widget.durationSeconds > 86400) {
      return null;
    }
    final result = ActivityEnergyEstimate(
      metCode: entry.code,
      weightKg: weight.weightKg,
      weightMeasuredAt: weight.measuredAt,
      ageYears: age,
      durationSeconds: widget.durationSeconds,
      budgetTargetFromDateKey: _include ? target?.effectiveFromDateKey : null,
      budgetBaseKcal: _include ? target?.kcalTarget : null,
    );
    return result.validFor(
          type: widget.type.name,
          minutes: widget.durationSeconds ~/ 60,
          performedAt: widget.performedAt,
        )
        ? result
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final weight = ref.watch(activityWeightProvider(widget.performedAt));
    final target = ref.watch(
      nutritionTargetProvider(localDateKey(widget.performedAt)),
    );
    final entries = activityMetCatalog
        .where(
          (e) =>
              e.type == widget.type.name &&
              (!widget.guided ||
                  ['02024', '02056', '02022', '02020'].contains(e.code)),
        )
        .toList();
    final result = estimate;
    final number = NumberFormat('#,##0.#', 'vi');
    final birth = profile.value?.birthDate;
    final age = birth == null ? null : ageAtActivity(birth, widget.performedAt);
    final loading = profile.isLoading || weight.isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Calo vận động ước tính',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (entries.isNotEmpty)
          DropdownButtonFormField<String>(
            key: ValueKey('activity-met-${widget.type.name}'),
            initialValue: _code,
            itemHeight: null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Chọn cách tập thực tế',
            ),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Chỉ ghi phút, chưa tính calo'),
              ),
              for (final e in entries)
                DropdownMenuItem(
                  value: e.code,
                  child: Text(
                    '${e.label} · ${e.met} MET',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: widget.enabled
                ? (value) {
                    setState(() {
                      _code = value == '' ? null : value;
                      _edited = true;
                      _recalculate = true;
                      _include = false;
                    });
                    widget.onChanged?.call();
                  }
                : null,
          )
        else
          const Text(
            'Chưa có hệ số phù hợp cho hoạt động này; bạn vẫn có thể ghi thời lượng.',
          ),
        const SizedBox(height: 10),
        if (result != null) ...[
          Text(
            '≈ ${number.format(result.activeKcal)} kcal vận động thêm',
            key: const ValueKey('activity-active-kcal'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            'Tổng trong lúc tập ≈ ${number.format(result.grossKcal)} kcal, gồm cả năng lượng khi nghỉ.',
          ),
          Text(
            '${number.format(result.weightKg)} kg · cân ngày ${DateFormat('dd/MM/yyyy').format(result.weightMeasuredAt)} · ${result.durationSeconds} giây vận động',
          ),
          if (widget.performedAt.difference(result.weightMeasuredAt).inDays >
              90)
            const Text(
              'Cân nặng đã cũ; cập nhật cân nặng trước khi tính lại nếu thể trạng đã thay đổi.',
            ),
          if (!_recalculate && widget.initial != null)
            const Text(
              'Đang giữ ước tính đã lưu. Chọn lại cách tập để tính bằng hồ sơ hiện tại.',
            ),
          if (target.value != null)
            CheckboxListTile(
              key: const ValueKey('activity-include-budget'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _include,
              onChanged: widget.enabled
                  ? (v) {
                      setState(() {
                        _include = v ?? false;
                        _edited = true;
                      });
                      widget.onChanged?.call();
                    }
                  : null,
              title: const Text('Cộng phần vận động thêm vào calo còn lại'),
              subtitle: const Text(
                'Tôi xác nhận buổi này chưa nằm trong mức hoạt động thường ngày dùng để đặt mục tiêu ăn. Không cộng đồng thời điều chỉnh bước chân.',
              ),
            )
          else
            const Text(
              'Cần mục tiêu dinh dưỡng để cộng calo vận động vào calo còn lại.',
            ),
        ] else if (entries.isNotEmpty)
          Text(
            loading
                ? 'Đang tải hồ sơ và cân nặng…'
                : profile.hasError || weight.hasError
                ? 'Chưa tải được hồ sơ/cân nặng. Bạn vẫn có thể lưu phút vận động.'
                : age == null
                ? 'Cần ngày sinh trong hồ sơ để chọn bộ MET phù hợp.'
                : age < 19 || age > 59
                ? 'Bộ MET này dành cho tuổi 19–59; app chưa quy đổi calo cho độ tuổi của bạn.'
                : weight.value?.isEmpty != false
                ? 'Chưa có cân nặng được ghi trước thời điểm vận động. Hãy bổ sung trong hồ sơ.'
                : 'Chọn cách tập phù hợp để xem ước tính. Không chọn nếu không khớp hoạt động thực tế.',
          ),
        if (profile.hasError || weight.hasError)
          TextButton(
            onPressed: () {
              ref.invalidate(userProfileProvider);
              ref.invalidate(activityWeightProvider(widget.performedAt));
            },
            child: const Text('Tải lại dữ liệu tính calo'),
          ),
        TextButton(
          onPressed: () => showActivityEnergyMethod(context),
          child: const Text('Cách tính và nguồn dữ liệu'),
        ),
      ],
    );
  }
}

Future<void> showActivityEnergyMethod(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Cách tính calo vận động'),
    content: const SingleChildScrollView(
      child: Text(
        'Nguồn: 2024 Adult Compendium of Physical Activities (19–59 tuổi). '
        '1 MET được quy ước bằng 1 kcal/kg/giờ.\n\n'
        'Calo tổng = MET × cân nặng (kg) × giây vận động ÷ 3.600.\n'
        'Calo vận động thêm = (MET − 1) × kg × giây ÷ 3.600.\n\n'
        'Ví dụ 60 kg, 30 phút thể dục vừa (3,8 MET): tổng 114 kcal, phần vận động thêm 84 kcal. '
        'Đây là ví dụ tính toán, không phải số liệu cá nhân.\n\n'
        'App dùng thời gian thực sự vận động; buổi tập có hướng dẫn loại thời gian nghỉ, chuẩn bị và tạm dừng. '
        'Với nhập tay, chỉ nhập số phút thực sự vận động.\n\n'
        'Đây là ước tính theo nhóm hoạt động, không đo bằng cảm biến. Thể trạng, kỹ thuật, cường độ và chuyển hóa cá nhân có thể làm kết quả thực tế khác. '
        'ExerciseDB cung cấp hình minh họa; không cung cấp số calo này. Không dùng API hay AI để đoán calo.',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () async {
          final ok = await launchUrl(
            Uri.parse('https://pacompendium.com/home/'),
            mode: LaunchMode.externalApplication,
          );
          if (!ok && context.mounted) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(
                content: Text(
                  'Không mở được nguồn. Xem tại https://pacompendium.com/home/',
                ),
              ),
            );
          }
        },
        child: const Text('Xem nguồn MET'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
    ],
  ),
);
