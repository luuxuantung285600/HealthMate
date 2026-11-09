import 'package:flutter/material.dart';
import '../../../core/widgets/help_details.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/local_date_key.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/models/health_goal.dart';
import '../../profile/providers/profile_providers.dart';
import '../models/energy_estimate.dart';
import '../models/nutrition_target.dart';
import '../models/personal_nutrition_plan.dart';
import '../providers/nutrition_target_providers.dart';

Future<NutritionTarget?> openPersonalNutritionPlanner(
  BuildContext context, {
  PersonalNutritionSeed? seed,
  bool saveToAccount = true,
  bool lockProfileSeed = false,
}) => showDialog<NutritionTarget>(
  context: context,
  barrierDismissible: false,
  builder: (_) => AccountBoundDialog(
    child: Dialog.fullscreen(
      child: _PlannerEntry(
        seed: seed,
        saveToAccount: saveToAccount,
        lockProfileSeed: lockProfileSeed,
      ),
    ),
  ),
);

class _PlannerEntry extends ConsumerStatefulWidget {
  const _PlannerEntry({
    this.seed,
    required this.saveToAccount,
    required this.lockProfileSeed,
  });
  final PersonalNutritionSeed? seed;
  final bool saveToAccount;
  final bool lockProfileSeed;

  @override
  ConsumerState<_PlannerEntry> createState() => _PlannerEntryState();
}

class _PlannerEntryState extends ConsumerState<_PlannerEntry> {
  late final String? _ownerUid;
  PersonalNutritionSeed? _loadedSeed;
  String? _seedUid;

  @override
  void initState() {
    super.initState();
    _ownerUid = ref.read(authSessionProvider).value?.uid;
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authSessionProvider.select((s) => s.value?.uid));
    if (uid == null || uid != _ownerUid) return const SizedBox.shrink();
    final now = ref.read(currentLocalTimeProvider)();
    if (widget.seed case final initial?) {
      return _PlannerForm(
        seed: initial,
        saveToAccount: widget.saveToAccount,
        lockProfileSeed: widget.lockProfileSeed,
      );
    }
    // Once opened, a midnight tick or profile refresh must not discard edits.
    if (_seedUid == uid && _loadedSeed != null) {
      return _PlannerForm(
        key: ValueKey('nutrition-plan-$uid'),
        seed: _loadedSeed!,
        saveToAccount: widget.saveToAccount,
      );
    }
    final profile = ref.watch(userProfileProvider);
    final weightDay = localDateOnly(now);
    final weight = ref.watch(latestBodyMetricProvider(weightDay));
    if (!profile.isLoading &&
        !profile.hasError &&
        profile.value?.uid == uid &&
        !weight.isLoading &&
        !weight.hasError) {
      _seedUid = uid;
      _loadedSeed = PersonalNutritionSeed.fromProfile(
        profile.value!,
        weight.value?.firstOrNull,
        now,
      );
      return _PlannerForm(
        key: ValueKey('nutrition-plan-$uid'),
        seed: _loadedSeed!,
        saveToAccount: widget.saveToAccount,
      );
    }
    final failed = profile.hasError || weight.hasError;
    return Scaffold(
      appBar: AppBar(title: const Text('Kế hoạch dinh dưỡng')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              failed
                  ? 'Chưa tải được hồ sơ hoặc cân nặng. Hãy thử lại.'
                  : 'Đang lấy thông tin đã có trong hồ sơ…',
            ),
            if (!failed) const LinearProgressIndicator(),
            if (failed)
              TextButton(
                onPressed: () {
                  ref.invalidate(userProfileProvider);
                  ref.invalidate(latestBodyMetricProvider(weightDay));
                },
                child: const Text('Thử lại'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlannerForm extends ConsumerStatefulWidget {
  const _PlannerForm({
    required this.seed,
    required this.saveToAccount,
    this.lockProfileSeed = false,
    super.key,
  });
  final PersonalNutritionSeed seed;
  final bool saveToAccount;
  final bool lockProfileSeed;
  @override
  ConsumerState<_PlannerForm> createState() => _PlannerFormState();
}

class _PlannerFormState extends ConsumerState<_PlannerForm>
    with ConfirmedSave<NutritionTarget, _PlannerForm> {
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _targetWeight;
  FormulaSex? _sex;
  PlanActivity? _activity;
  HealthGoal? _goal;
  PlanPace _pace = PlanPace.gentle;
  PlanMacroSplit _macros = PlanMacroSplit.balanced;
  bool _eligible = false;
  bool _replace = false;
  NutritionTarget? _reviewedExisting;
  PersonalNutritionPlan? _plan;
  String? _calculatedDay;
  String? _error;
  final _number = NumberFormat('0.#', 'vi');
  final _scroll = ScrollController();
  late final String? _uid;
  late final List<Object?> _openedValues;
  List<Object?> get _values => [
    _age.text,
    _height.text,
    _weight.text,
    _targetWeight.text,
    _sex,
    _activity,
    _goal,
    _pace,
    _macros,
    _eligible,
  ];
  bool get _current =>
      mounted &&
      _uid != null &&
      ref.read(authSessionProvider).value?.uid == _uid &&
      ref.read(authRepositoryProvider).currentUid == _uid;
  @override
  bool get hasUnsavedChanges =>
      _plan != null || _values.indexed.any((e) => e.$2 != _openedValues[e.$1]);

  @override
  void initState() {
    super.initState();
    _uid = ref.read(authSessionProvider).value?.uid;
    _age = TextEditingController(text: widget.seed.age?.toString() ?? '');
    _height = TextEditingController(
      text: widget.seed.heightCm?.toString() ?? '',
    );
    _weight = TextEditingController(
      text: widget.seed.weightKg?.toString() ?? '',
    );
    _targetWeight = TextEditingController(
      text: widget.seed.targetWeightKg?.toString() ?? '',
    );
    _goal = widget.seed.goal;
    _openedValues = _values;
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final controller in [_age, _height, _weight, _targetWeight]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _decimal(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  void _calculate() {
    FocusScope.of(context).unfocus();
    try {
      final input = PersonalNutritionInput(
        age: int.tryParse(_age.text.trim()),
        heightCm: _decimal(_height),
        weightKg: _decimal(_weight),
        sex: _sex,
        activity: _activity,
        goal: _goal,
        targetWeightKg: _decimal(_targetWeight),
        pace: _pace,
        macros: _macros,
        eligible: _eligible,
      );
      final result = input.calculate();
      setState(() {
        _plan = result;
        _calculatedDay = localDateKey(ref.read(currentLocalTimeProvider)());
        _error = null;
        saveError = null;
        _replace = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _accept(NutritionTarget? existing) async {
    if (!_current || saving || _plan == null) return;
    final day = localDateKey(ref.read(currentLocalTimeProvider)());
    if (day != _calculatedDay) {
      setState(() {
        _plan = null;
        _error = 'Đã sang ngày mới. Hãy xem lại và tính đề xuất cho hôm nay.';
      });
      return;
    }
    final draft = _plan!.toTarget(day);
    if (!widget.saveToAccount) {
      Navigator.pop(context, draft);
      return;
    }
    if (existing != null &&
        (!_replace || !sameNutritionTarget(existing, _reviewedExisting))) {
      return;
    }
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) return;
    await saveDraft(draft, (target) async {
      // A plan reviewed in a stale tab must not silently replace a newer target.
      final latest = await ref
          .read(nutritionTargetRepositoryProvider)
          .loadForDay(uid, day)
          .timeout(const Duration(seconds: 15));
      if (!_current) {
        return false;
      }
      if (!sameNutritionTarget(existing, latest)) {
        ref.invalidate(nutritionTargetProvider(day));
        setState(() {
          _replace = false;
          _error =
              'Mục tiêu đã thay đổi. Hãy xem lại mục tiêu hiện tại rồi xác nhận lần nữa.';
        });
        return false;
      }
      return ref.read(nutritionTargetControllerProvider.notifier).save(target);
    });
  }

  Widget _numeric(
    String key,
    String label,
    TextEditingController c, {
    String? helper,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(key),
      controller: c,
      onChanged: (_) => setState(() {
        _error = null;
        saveError = null;
      }),
      readOnly: widget.lockProfileSeed,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 3,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final day = localDateKey(ref.watch(localClockProvider));
    final existingState = widget.saveToAccount
        ? ref.watch(nutritionTargetProvider(day))
        : const AsyncData<NutritionTarget?>(null);
    final existing = existingState.value;
    final ready = !existingState.isLoading && !existingState.hasError;
    final replacementApproved =
        existing == null ||
        (_replace && sameNutritionTarget(existing, _reviewedExisting));
    return guardSave(
      Scaffold(
        appBar: AppBar(
          toolbarHeight: MediaQuery.textScalerOf(
            context,
          ).scale(kToolbarHeight).clamp(kToolbarHeight, double.infinity),
          title: const Text('Kế hoạch dinh dưỡng', maxLines: 2),
          leading: IconButton(
            tooltip: 'Đóng',
            onPressed: saving ? null : requestClose,
            icon: const Icon(Icons.close),
          ),
        ),
        body: SingleChildScrollView(
          controller: _scroll,
          key: const ValueKey('nutrition-plan-scroll'),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_plan == null)
                ..._inputFields(context)
              else
                ..._review(context, _plan!),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    key: const ValueKey('nutrition-plan-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_plan != null && widget.saveToAccount) ...[
                if (existingState.isLoading) const LinearProgressIndicator(),
                if (existingState.hasError) ...[
                  const Text(
                    'Chưa tải được mục tiêu hiện tại; chưa thể lưu đề xuất.',
                  ),
                  TextButton(
                    key: const ValueKey('nutrition-plan-retry-target'),
                    onPressed: () =>
                        ref.invalidate(nutritionTargetProvider(day)),
                    child: const Text('Tải lại mục tiêu'),
                  ),
                ],
                if (ready && existing != null) ...[
                  Text(
                    'Mục tiêu hiện tại: ${_number.format(existing.kcalTarget)} kcal/ngày. Lịch sử trước hôm nay được giữ nguyên.',
                  ),
                  CheckboxListTile(
                    key: const ValueKey('nutrition-plan-replace'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tôi đồng ý thay mục tiêu từ hôm nay'),
                    value:
                        _replace &&
                        sameNutritionTarget(existing, _reviewedExisting),
                    onChanged: (value) => setState(() {
                      _replace = value == true;
                      _reviewedExisting = existing;
                    }),
                  ),
                ],
              ],
              saveFeedback(),
              if (_plan == null)
                FilledButton.icon(
                  key: const ValueKey('nutrition-plan-calculate'),
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Xem đề xuất của tôi'),
                )
              else ...[
                FilledButton(
                  key: const ValueKey('nutrition-plan-save'),
                  onPressed: saving || !ready || !replacementApproved
                      ? null
                      : () => _accept(existing),
                  child: Text(
                    widget.saveToAccount
                        ? 'Xác nhận và lưu từ hôm nay'
                        : 'Dùng đề xuất này',
                  ),
                ),
                TextButton(
                  key: const ValueKey('nutrition-plan-edit'),
                  onPressed: saving
                      ? null
                      : () {
                          setState(() {
                            _plan = null;
                            _error = null;
                            saveError = null;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _scroll.hasClients) {
                              _scroll.jumpTo(0);
                            }
                          });
                        },
                  child: const Text('Quay lại chỉnh thông tin'),
                ),
              ],
              if (!saving)
                TextButton(
                  onPressed: requestClose,
                  child: const Text('Để sau, giữ mục tiêu hiện tại'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _inputFields(BuildContext context) => [
    Text(
      'Cá nhân hóa kcal mỗi ngày',
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: 8),
    Text(
      widget.lockProfileSeed
          ? 'Thông tin từ hồ sơ. Quay lại bước trước nếu cần sửa.'
          : 'Kiểm tra số đo hiện tại trước khi tính.',
    ),
    const SizedBox(height: 20),
    _numeric('nutrition-plan-age', 'Tuổi', _age),
    _numeric('nutrition-plan-height', 'Chiều cao (cm)', _height),
    _numeric('nutrition-plan-weight', 'Cân nặng hiện tại (kg)', _weight),
    DropdownButtonFormField<FormulaSex>(
      key: const ValueKey('nutrition-plan-sex'),
      initialValue: _sex,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Hệ số sinh lý cho công thức',
      ),
      items: const [
        DropdownMenuItem(
          value: FormulaSex.male,
          child: Text(
            'Nam · hệ số nghiên cứu',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: FormulaSex.female,
          child: Text(
            'Nữ · hệ số nghiên cứu',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      onChanged: (v) => setState(() => _sex = v),
    ),
    const SizedBox(height: 16),
    DropdownButtonFormField<PlanActivity>(
      key: const ValueKey('nutrition-plan-activity'),
      initialValue: _activity,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Hoạt động thường ngày'),
      items: [
        for (final a in PlanActivity.values)
          DropdownMenuItem(
            value: a,
            child: Text(a.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => setState(() => _activity = v),
    ),
    if (_activity != null) Text(_activity!.description),
    const SizedBox(height: 8),
    const HelpDetails(
      title: 'Chọn mức hoạt động',
      children: [
        Text(
          'Tính cả sinh hoạt và tập luyện thường lệ. Không cộng lặp bước chân thường ngày vào kcal.',
        ),
      ],
    ),
    const SizedBox(height: 16),
    DropdownButtonFormField<HealthGoal>(
      key: const ValueKey('nutrition-plan-goal'),
      initialValue: _goal,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Mục tiêu cho kế hoạch này'),
      items: [
        for (final g in HealthGoal.values)
          DropdownMenuItem(
            value: g,
            child: Text(g.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: widget.lockProfileSeed
          ? null
          : (v) => setState(() => _goal = v),
    ),
    if (_goal?.needsTargetWeight == true) ...[
      const SizedBox(height: 16),
      _numeric(
        'nutrition-plan-target-weight',
        'Cân nặng mục tiêu (kg)',
        _targetWeight,
      ),
      DropdownButtonFormField<PlanPace>(
        key: const ValueKey('nutrition-plan-pace'),
        initialValue: _pace,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Nhịp điều chỉnh năng lượng',
        ),
        items: [
          for (final p in PlanPace.values)
            DropdownMenuItem(
              value: p,
              child: Text(
                '${p.label} · ${_goal == HealthGoal.loseWeight ? 'giảm ${p.lossFraction * 100 ~/ 1}%' : 'thêm ${p.gainFraction * 100 ~/ 1}%'} mức duy trì',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (v) => setState(() => _pace = v ?? _pace),
      ),
      const SizedBox(height: 8),
      const Text('Nhịp kcal khởi đầu, không dự báo ngày đạt cân nặng đích.'),
    ],
    const SizedBox(height: 16),
    DropdownButtonFormField<PlanMacroSplit>(
      key: const ValueKey('nutrition-plan-macros'),
      initialValue: _macros,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Phân bổ dưỡng chất'),
      items: [
        for (final m in PlanMacroSplit.values)
          DropdownMenuItem(
            value: m,
            child: Text(
              '${m.label} · ${m.protein * 100 ~/ 1}/${m.carbs * 100 ~/ 1}/${m.fat * 100 ~/ 1}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) => setState(() => _macros = v ?? _macros),
    ),
    const Text('Tỷ lệ % năng lượng: đạm / carbohydrate / chất béo.'),
    const SizedBox(height: 16),
    const Text(
      'Đề xuất dành cho người 18–65 tuổi, không mang thai/cho con bú, không có chế độ ăn điều trị, rối loạn ăn uống hoặc nhu cầu thể thao chuyên nghiệp. Ngoài phạm vi, bạn vẫn có thể nhập mục tiêu được tư vấn riêng.',
    ),
    CheckboxListTile(
      key: const ValueKey('nutrition-plan-eligible'),
      contentPadding: EdgeInsets.zero,
      title: const Text('Tôi đã đọc và thuộc phạm vi áp dụng'),
      value: _eligible,
      onChanged: (v) => setState(() => _eligible = v == true),
    ),
  ];

  List<Widget> _review(BuildContext context, PersonalNutritionPlan plan) => [
    Text('Kế hoạch đề xuất', style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 12),
    Text(
      '${_number.format(plan.kcal)} kcal/ngày',
      key: const ValueKey('nutrition-plan-result'),
      style: Theme.of(context).textTheme.headlineMedium,
    ),
    Text(
      'Đạm ${_number.format(plan.proteinG)} g · Carb ${_number.format(plan.carbsG)} g · Béo ${_number.format(plan.fatG)} g',
    ),
    const SizedBox(height: 16),
    Text(
      '${plan.input.age} tuổi · ${_number.format(plan.input.heightCm)} cm · ${_number.format(plan.input.weightKg)} kg',
    ),
    Text('${plan.input.goal!.label} · ${plan.input.activity!.label}'),
    if (plan.input.changesWeight)
      Text('Cân nặng đích ${_number.format(plan.input.targetWeightKg)} kg'),
    const SizedBox(height: 12),
    const Text('Mức khởi đầu ước tính. Theo dõi tiến độ để điều chỉnh.'),
    if (!widget.saveToAccount)
      const Text('Chưa lưu. Xác nhận ở bước tiếp theo để áp dụng.'),
    HelpDetails(
      title: 'Cách tính và lưu dữ liệu',
      children: [
        Text('Năng lượng nghỉ: ${_number.format(plan.restingKcal)} kcal/ngày'),
        Text(
          'Mức duy trì: ${_number.format(plan.maintenanceKcal)} kcal/ngày · Hệ số ${plan.input.activity!.factor}',
        ),
        Text(
          'Điều chỉnh ${_number.format(plan.input.adjustmentFraction * 100)}% · Làm tròn đến hàng chục kcal',
        ),
        const Text(
          'Đây là ước tính, không phải đơn ăn điều trị. Không tự cập nhật mục tiêu khi cân nặng thay đổi hoặc tự cộng kcal từ bước chân/giấc ngủ.',
        ),
        const Text(
          'Chỉ lưu kcal và mục tiêu ba chất sau xác nhận. Các đầu vào lần tính không được lưu thêm hoặc gửi cho AI.',
        ),
      ],
    ),
    ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Công thức và nguồn tham khảo'),
      children: const [
        SelectionArea(
          child: Text(
            'Mifflin–St Jeor (1990): 9,99 × kg + 6,25 × cm − 4,92 × tuổi + 5 (nam) hoặc −161 (nữ). Nhân hệ số hoạt động tự chọn.\n'
            'pubmed.ncbi.nlm.nih.gov/2305711/\n'
            'Hệ số là mức tham khảo trong khoảng PAL của NIDDK, không đo từ điện thoại: niddk.nih.gov/bwp\n'
            'Hai phân bổ đạm/carb/béo nằm trong khoảng AMDR cho người lớn.\n'
            'Nguồn: Health Canada, Dietary reference intakes tables — Reference values for macronutrients.\n'
            'Nhịp điều chỉnh và giới hạn đề xuất là chính sách thận trọng của HealthMate, không phải công thức dự báo cân nặng.',
          ),
        ),
      ],
    ),
  ];
}
