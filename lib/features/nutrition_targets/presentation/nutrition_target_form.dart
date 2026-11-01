import 'package:flutter/material.dart';
import '../../../core/widgets/help_details.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/nutrition_target.dart';
import '../providers/nutrition_target_providers.dart';
import 'energy_estimate_dialog.dart';
import 'personal_nutrition_planner.dart';

Future<void> openNutritionTargetForm(
  BuildContext context,
  WidgetRef ref,
  NutritionTarget? initial,
) async {
  final uid = ref.read(authSessionProvider).value?.uid;
  final result = await showDialog<NutritionTarget>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        AccountBoundDialog(child: NutritionTargetForm(initial: initial)),
  );
  if (result != null &&
      context.mounted &&
      ref.read(authSessionProvider).value?.uid == uid) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã lưu mục tiêu áp dụng từ ${result.effectiveFromDateKey}.',
        ),
      ),
    );
  }
}

class NutritionTargetForm extends ConsumerStatefulWidget {
  const NutritionTargetForm({this.initial, super.key});
  final NutritionTarget? initial;
  @override
  ConsumerState<NutritionTargetForm> createState() =>
      _NutritionTargetFormState();
}

class _NutritionTargetFormState extends ConsumerState<NutritionTargetForm>
    with ConfirmedSave<NutritionTarget, NutritionTargetForm> {
  final _fields = List.generate(4, (_) => TextEditingController());
  late DateTime _day;
  String? _uid;
  String? _error;
  String? _loadError;
  bool _loading = false;
  bool _confirming = false;
  int _loadGeneration = 0;
  DateTime get _today => localDateOnly(ref.read(currentLocalTimeProvider)());
  bool get _current =>
      mounted && ref.read(authSessionProvider).value?.uid == _uid;

  @override
  void initState() {
    super.initState();
    _uid = ref.read(authSessionProvider).value?.uid;
    _day = _today;
    _fill(widget.initial);
  }

  void _fill(NutritionTarget? value) {
    final numbers = [
      value?.kcalTarget,
      value?.proteinGTarget,
      value?.carbsGTarget,
      value?.fatGTarget,
    ];
    for (var i = 0; i < _fields.length; i++) {
      _fields[i].text = numbers[i]?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDay() async {
    final generation = ++_loadGeneration;
    final provider = nutritionTargetProvider(localDateKey(_day));
    final subscription = ref.listenManual(provider, (_, _) {});
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final target = await ref.read(provider.future);
      if (!_current || generation != _loadGeneration) return;
      _fill(target);
    } catch (_) {
      if (_current && generation == _loadGeneration) {
        _loadError =
            'Chưa tải được mục tiêu cho ngày áp dụng. Hãy thử lại trước khi lưu.';
      }
    } finally {
      subscription.close();
      if (_current && generation == _loadGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final today = _today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _day.isBefore(today) ? today : _day,
      firstDate: today,
      lastDate: DateTime(today.year + 20, 12, 31),
      helpText: 'Ngày bắt đầu áp dụng',
    );
    if (picked == null ||
        !_current ||
        localDateKey(picked) == localDateKey(_day)) {
      return;
    }
    setState(() {
      _day = picked;
      _error = null;
    });
    await _loadDay();
  }

  double? _number(int index) => _fields[index].text.trim().isEmpty
      ? null
      : double.tryParse(_fields[index].text.trim().replaceAll(',', '.')) ??
            double.nan;
  Future<void> _submit() async {
    if (saving || _confirming || _loading || _loadError != null) return;
    FocusScope.of(context).unfocus();
    final target = NutritionTarget(
      effectiveFromDateKey: localDateKey(_day),
      kcalTarget: _number(0) ?? double.nan,
      proteinGTarget: _number(1),
      carbsGTarget: _number(2),
      fatGTarget: _number(3),
    );
    final error = target.validate(earliestDateKey: localDateKey(_today));
    setState(() {
      _error = error;
      saveError = null;
    });
    if (error != null) return;
    if (target.needsMacroConfirmation) {
      setState(() => _confirming = true);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kiểm tra lại năng lượng và các chất'),
          content: Text(
            'Năng lượng quy đổi 4 × đạm + 4 × tinh bột + 9 × béo là ${NumberFormat('0.#', 'vi').format(target.macroKcal)} kcal, lệch hơn 5% so với kcal bạn nhập. Bạn muốn giữ nguyên các giá trị này?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Quay lại sửa'),
            ),
            FilledButton(
              key: const ValueKey('confirm-target-mismatch'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Giữ giá trị'),
            ),
          ],
        ),
      );
      if (!_current) return;
      setState(() => _confirming = false);
      if (confirmed != true) return;
    }
    if (!_current) return;
    await saveDraft(
      target,
      (value) =>
          ref.read(nutritionTargetControllerProvider.notifier).save(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = saving || _confirming || _loading;
    final failure = ref.watch(nutritionTargetControllerProvider).error;
    return guardSave(
      Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Mục tiêu dinh dưỡng'),
            leading: IconButton(
              tooltip: 'Đóng',
              onPressed: busy ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ),
          body: AbsorbPointer(
            absorbing: busy,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: const ValueKey('target-date'),
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      'Áp dụng từ ${DateFormat('dd/MM/yyyy').format(_day)}',
                    ),
                  ),
                  if (_loading) const LinearProgressIndicator(),
                  if (_loadError != null) ...[
                    Text(_loadError!),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(
                          nutritionTargetProvider(localDateKey(_day)),
                        );
                        _loadDay();
                      },
                      child: const Text('Tải lại mục tiêu'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  for (var i = 0; i < 4; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        key: ValueKey(
                          [
                            'target-kcal',
                            'target-protein',
                            'target-carbs',
                            'target-fat',
                          ][i],
                        ),
                        controller: _fields[i],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: [
                            'Năng lượng (kcal/ngày)',
                            'Đạm (g/ngày)',
                            'Carb (g/ngày)',
                            'Chất béo (g/ngày)',
                          ][i],
                        ),
                      ),
                    ),
                  const Text(
                    'Ba mục tiêu chất có thể cùng để trống hoặc cùng được nhập. Số 0 được nhập có chủ ý vẫn được giữ.',
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HelpDetails(
                    title: 'Cách đặt mục tiêu',
                    children: [
                      Text(
                        'Bạn có thể nhập chỉ kcal hoặc thêm mục tiêu ba chất. Chọn ngày áp dụng rồi lưu; các ngày trước được giữ nguyên. Giới hạn nhập là giới hạn kỹ thuật, không phải khuyến nghị ăn uống.',
                      ),
                    ],
                  ),
                  TextButton.icon(
                    key: const ValueKey('personalize-target-form'),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Cá nhân hóa kcal và ba chất'),
                    onPressed: () async {
                      final result = await openPersonalNutritionPlanner(
                        context,
                        saveToAccount: false,
                      );
                      if (!_current || result == null) return;
                      setState(() {
                        _fill(result);
                        _error = null;
                      });
                    },
                  ),
                  TextButton.icon(
                    key: const ValueKey('open-energy-estimate'),
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('Tham khảo mức duy trì (tùy chọn)'),
                    onPressed: () async {
                      final result = await showDialog<double>(
                        context: context,
                        builder: (_) => const AccountBoundDialog(
                          child: EnergyEstimateDialog(),
                        ),
                      );
                      if (!_current || result == null) return;
                      setState(() {
                        _fields[0].text = result.toStringAsFixed(0);
                        _error = null;
                      });
                    },
                  ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (saveError != null && failure is NutritionTargetFailure)
                    Text(failure.message),
                  saveFeedback(),
                  FilledButton(
                    key: const ValueKey('save-target'),
                    onPressed: busy || _loadError != null ? null : _submit,
                    child: Text(saving ? 'Đang chờ xác nhận' : 'Lưu mục tiêu'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
