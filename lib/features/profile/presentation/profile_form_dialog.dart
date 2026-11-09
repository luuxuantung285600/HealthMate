import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/confirmed_save.dart';

import '../models/health_goal.dart';
import '../models/profile_validation.dart';
import '../models/user_profile.dart';
import 'profile_number_input.dart';

class ProfileFormDialog extends StatefulWidget {
  const ProfileFormDialog({required this.profile, this.onSave, super.key});
  final Future<bool> Function(UserProfileDraft)? onSave;

  final UserProfile profile;

  @override
  State<ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends State<ProfileFormDialog>
    with ConfirmedSave<UserProfileDraft, ProfileFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _heightController;
  late final TextEditingController _targetWeightController;
  late DateTime? _birthDate;
  late HealthGoal? _goal;
  String? _birthDateError;
  late final String _initialName, _initialHeight, _initialTarget;

  @override
  bool get hasUnsavedChanges =>
      _nameController.text != _initialName ||
      _heightController.text != _initialHeight ||
      _targetWeightController.text != _initialTarget ||
      _birthDate != widget.profile.birthDate ||
      _goal != widget.profile.healthGoal;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _heightController = TextEditingController(
      text: profileNumberInput(widget.profile.heightCm),
    );
    _targetWeightController = TextEditingController(
      text: profileNumberInput(widget.profile.targetWeightKg),
    );
    _birthDate = widget.profile.birthDate;
    _goal = widget.profile.healthGoal;
    _initialName = _nameController.text;
    _initialHeight = _heightController.text;
    _initialTarget = _targetWeightController.text;
    _nameController.addListener(_changed);
    _heightController.addListener(_changed);
    _targetWeightController.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _submit() {
    final birthDateError = ProfileValidation.birthDate(_birthDate);
    setState(() => _birthDateError = birthDateError);
    if (!_formKey.currentState!.validate() || birthDateError != null) return;
    FocusScope.of(context).unfocus();
    saveDraft(
      UserProfileDraft(
        displayName: _nameController.text.trim(),
        heightCm: ProfileValidation.parseDecimal(
          _heightController.text.trim(),
        )!,
        birthDate: _birthDate!,
        healthGoal: _goal!,
        targetWeightKg: _goal!.needsTargetWeight
            ? ProfileValidation.parseDecimal(
                _targetWeightController.text.trim(),
              )
            : null,
      ),
      widget.onSave,
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 120, now.month, now.day);
    final last = DateTime(now.year - 18, now.month, now.day);
    final initial = _birthDate ?? DateTime(now.year - 20);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(last)
          ? last
          : initial.isBefore(first)
          ? first
          : initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (selected != null && mounted) {
      setState(() {
        _birthDate = selected;
        _birthDateError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return guardSave(
      AlertDialog(
        title: const Text('Chỉnh sửa hồ sơ'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    saveFeedback(),
                    const Text(
                      'Cân nặng hiện tại được cập nhật riêng trong Lịch sử cân nặng. Thay đổi mục tiêu ở đây không sửa các lần cân đã lưu.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('profile-name'),
                      controller: _nameController,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      maxLength: 50,
                      decoration: const InputDecoration(
                        labelText: 'Tên hiển thị',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: ProfileValidation.displayName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('profile-height'),
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Chiều cao (cm)',
                        helperText: 'Từ 80 đến 250 cm; có thể nhập dấu phẩy.',
                        helperMaxLines: 3,
                        prefixIcon: Icon(Icons.height_rounded),
                      ),
                      validator: ProfileValidation.requiredHeight,
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Ngày sinh · HealthMate dành cho người từ 18 tuổi',
                      ),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('profile-birth-date'),
                      onPressed: _pickBirthDate,
                      icon: const Icon(Icons.cake_outlined),
                      label: Text(
                        _birthDate == null
                            ? 'Chọn ngày sinh'
                            : DateFormat('dd/MM/yyyy').format(_birthDate!),
                      ),
                    ),
                    if (_birthDateError != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _birthDateError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    DropdownButtonFormField<HealthGoal>(
                      key: const ValueKey('profile-health-goal'),
                      initialValue: _goal,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Mục tiêu sức khỏe',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: [
                        for (final goal in HealthGoal.values)
                          DropdownMenuItem(
                            value: goal,
                            child: Text(goal.label),
                          ),
                      ],
                      onChanged: (value) => setState(() => _goal = value),
                      validator: (value) =>
                          value == null ? 'Vui lòng chọn một mục tiêu.' : null,
                    ),
                    if (_goal?.needsTargetWeight == true) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('profile-target-weight'),
                        controller: _targetWeightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Cân nặng mục tiêu (kg)',
                          prefixIcon: Icon(Icons.monitor_weight_outlined),
                        ),
                        validator: (value) =>
                            ProfileValidation.targetWeight(value, _goal),
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: requestClose, child: const Text('Hủy')),
          FilledButton(
            key: const ValueKey('save-profile'),
            onPressed: _submit,
            child: const Text('Lưu hồ sơ'),
          ),
        ],
      ),
    );
  }
}
