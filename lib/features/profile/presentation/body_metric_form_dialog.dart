import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/confirmed_save.dart';

import '../models/body_metric.dart';
import '../models/profile_validation.dart';
import 'profile_number_input.dart';

class BodyMetricFormDialog extends StatefulWidget {
  const BodyMetricFormDialog({this.metric, this.onSave, super.key});
  final Future<bool> Function(BodyMetricDraft)? onSave;

  final BodyMetric? metric;

  @override
  State<BodyMetricFormDialog> createState() => _BodyMetricFormDialogState();
}

class _BodyMetricFormDialogState extends State<BodyMetricFormDialog>
    with ConfirmedSave<BodyMetricDraft, BodyMetricFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightController;
  late final TextEditingController _noteController;
  late DateTime _measuredAt;
  late final DateTime _initialAt;
  late final String _initialWeight, _initialNote;
  String? _timeError;

  @override
  bool get hasUnsavedChanges =>
      _weightController.text != _initialWeight ||
      _noteController.text != _initialNote ||
      _measuredAt != _initialAt;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: profileNumberInput(widget.metric?.weightKg),
    );
    _noteController = TextEditingController(text: widget.metric?.note ?? '');
    final initial = widget.metric?.measuredAt.toLocal() ?? DateTime.now();
    // Preserve an edited reading's timestamp; a new reading keeps the current
    // time so it can become the latest reading even after onboarding today.
    _measuredAt = initial;
    _initialAt = initial;
    _initialWeight = _weightController.text;
    _initialNote = _noteController.text;
    _weightController.addListener(_changed);
    _noteController.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final existingDay = DateUtils.dateOnly(_measuredAt);
    final earliest = existingDay.isBefore(DateTime(2000))
        ? existingDay
        : DateTime(2000);
    final selected = await showDatePicker(
      context: context,
      initialDate: existingDay.isAfter(today) ? today : existingDay,
      firstDate: earliest,
      lastDate: today,
      helpText: 'Ngày đo',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (selected != null && mounted) {
      final candidate = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _measuredAt.hour,
        _measuredAt.minute,
        _measuredAt.second,
        _measuredAt.millisecond,
        _measuredAt.microsecond,
      );
      setState(() {
        _measuredAt = candidate;
        _timeError = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_measuredAt),
      helpText: 'Giờ đo',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (selected == null || !mounted) return;
    if (selected.hour == _measuredAt.hour &&
        selected.minute == _measuredAt.minute) {
      return;
    }
    setState(() {
      _measuredAt = DateTime(
        _measuredAt.year,
        _measuredAt.month,
        _measuredAt.day,
        selected.hour,
        selected.minute,
      );
      _timeError = null;
    });
  }

  void _submit() {
    final error = _measuredAt.isAfter(DateTime.now())
        ? 'Thời điểm đo không được ở tương lai. Hãy chọn lại ngày hoặc giờ.'
        : null;
    setState(() => _timeError = error);
    if (!_formKey.currentState!.validate() || error != null) return;
    saveDraft(
      BodyMetricDraft(
        weightKg: ProfileValidation.parseDecimal(
          _weightController.text.trim(),
        )!,
        measuredAt: _measuredAt,
        note: _noteController.text.trim(),
      ),
      widget.onSave,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    return guardSave(
      AlertDialog(
        title: Text(widget.metric == null ? 'Thêm cân nặng' : 'Sửa cân nặng'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  saveFeedback(),
                  TextFormField(
                    key: const ValueKey('metric-weight'),
                    controller: _weightController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Cân nặng (kg)',
                      helperText: 'Từ 20 đến 500 kg; có thể nhập dấu phẩy.',
                      helperMaxLines: 3,
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                    ),
                    validator: ProfileValidation.weight,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: const ValueKey('metric-date'),
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(DateFormat('dd/MM/yyyy').format(_measuredAt)),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('metric-time'),
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(
                      locale.formatTimeOfDay(
                        TimeOfDay.fromDateTime(_measuredAt),
                        alwaysUse24HourFormat: true,
                      ),
                    ),
                  ),
                  const Text('Ngày và giờ theo múi giờ của thiết bị.'),
                  if (_timeError != null)
                    Text(
                      _timeError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('metric-note'),
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú (không bắt buộc)',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                    validator: ProfileValidation.note,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: requestClose, child: const Text('Hủy')),
          FilledButton(
            key: const ValueKey('save-metric'),
            onPressed: _submit,
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
