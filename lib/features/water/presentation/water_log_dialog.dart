import 'package:flutter/material.dart';
import '../../../core/widgets/confirmed_save.dart';

import '../models/water_log.dart';

class WaterLogDialog extends StatefulWidget {
  const WaterLogDialog({
    required this.selectedDate,
    this.log,
    this.onSave,
    super.key,
  });

  final Future<bool> Function(WaterLogDraft)? onSave;
  final DateTime selectedDate;
  final WaterLog? log;

  @override
  State<WaterLogDialog> createState() => _WaterLogDialogState();
}

class _WaterLogDialogState extends State<WaterLogDialog>
    with ConfirmedSave<WaterLogDraft, WaterLogDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late DateTime _consumedAt;
  String? _timeError;
  late final DateTime _initialAt;
  late final String _initialAmount;

  @override
  bool get hasUnsavedChanges =>
      _amount.text != _initialAmount || _consumedAt != _initialAt;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.log?.amountMl.toString() ?? '250',
    );
    final now = DateTime.now();
    _consumedAt =
        widget.log?.consumedAt ??
        DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
          now.hour,
          now.minute,
        );
    _initialAt = _consumedAt;
    _initialAmount = _amount.text;
    _amount.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_consumedAt),
      helpText: 'Giờ uống nước',
    );
    if (value == null || !mounted) return;
    setState(() {
      _consumedAt = DateTime(
        _consumedAt.year,
        _consumedAt.month,
        _consumedAt.day,
        value.hour,
        value.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (saving) return;
    if (!_formKey.currentState!.validate()) return;
    final timeError = WaterValidation.consumedAt(_consumedAt);
    if (timeError != null) {
      setState(() => _timeError = timeError);
      return;
    }
    await saveDraft(
      WaterLogDraft(
        amountMl: int.parse(_amount.text.trim()),
        consumedAt: _consumedAt,
      ),
      widget.onSave,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    return guardSave(
      AlertDialog(
        title: Text(widget.log == null ? 'Thêm nước uống' : 'Sửa nước uống'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                saveFeedback(),
                TextFormField(
                  key: const ValueKey('water-amount'),
                  controller: _amount,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Lượng nước',
                    suffixText: 'ml',
                  ),
                  validator: WaterValidation.amount,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(
                    locale.formatTimeOfDay(TimeOfDay.fromDateTime(_consumedAt)),
                  ),
                ),
                if (_timeError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _timeError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: requestClose, child: const Text('Hủy')),
          FilledButton(
            key: const ValueKey('save-water'),
            onPressed: saving ? null : _submit,
            child: Text(saving ? 'Đang lưu…' : 'Lưu'),
          ),
        ],
      ),
    );
  }
}
