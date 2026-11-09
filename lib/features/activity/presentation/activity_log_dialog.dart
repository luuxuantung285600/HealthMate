import 'package:flutter/material.dart';
import '../../../core/widgets/confirmed_save.dart';

import '../models/activity_log.dart';

class ActivityLogDialog extends StatefulWidget {
  const ActivityLogDialog({
    required this.selectedDate,
    this.log,
    this.onSave,
    super.key,
  });

  final Future<bool> Function(ActivityLogDraft)? onSave;
  final DateTime selectedDate;
  final ActivityLog? log;

  @override
  State<ActivityLogDialog> createState() => _ActivityLogDialogState();
}

class _ActivityLogDialogState extends State<ActivityLogDialog>
    with ConfirmedSave<ActivityLogDraft, ActivityLogDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _duration;
  late final TextEditingController _note;
  late ActivityType _type;
  late DateTime _performedAt;
  String? _timeError;
  late final DateTime _initialAt;
  late final String _initialDuration, _initialNote;
  late final ActivityType _initialType;

  @override
  bool get hasUnsavedChanges =>
      _duration.text != _initialDuration ||
      _note.text != _initialNote ||
      _type != _initialType ||
      _performedAt != _initialAt;

  @override
  void initState() {
    super.initState();
    _duration = TextEditingController(
      text: widget.log?.durationMinutes.toString() ?? '30',
    );
    _note = TextEditingController(text: widget.log?.note ?? '');
    _type = widget.log?.type ?? ActivityType.walking;
    final now = DateTime.now();
    _performedAt =
        widget.log?.performedAt ??
        DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
          widget.selectedDate.day,
          now.hour,
          now.minute,
        );
    _initialAt = _performedAt;
    _initialType = _type;
    _initialDuration = _duration.text;
    _initialNote = _note.text;
    _duration.addListener(_changed);
    _note.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _duration.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_performedAt),
      helpText: 'Giờ vận động',
    );
    if (value == null || !mounted) return;
    setState(() {
      _performedAt = DateTime(
        _performedAt.year,
        _performedAt.month,
        _performedAt.day,
        value.hour,
        value.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (saving) return;
    if (!_formKey.currentState!.validate()) return;
    final timeError = ActivityValidation.performedAt(_performedAt);
    if (timeError != null) {
      setState(() => _timeError = timeError);
      return;
    }
    await saveDraft(
      ActivityLogDraft(
        type: _type,
        durationMinutes: int.parse(_duration.text.trim()),
        performedAt: _performedAt,
        note: _note.text.trim(),
      ),
      widget.onSave,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    return guardSave(
      AlertDialog(
        title: Text(widget.log == null ? 'Thêm vận động' : 'Sửa vận động'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                saveFeedback(),
                DropdownButtonFormField<ActivityType>(
                  key: const ValueKey('activity-type'),
                  isExpanded: true,
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Loại hoạt động',
                  ),
                  items: [
                    for (final type in ActivityType.values)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? _type),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('activity-duration'),
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Thời lượng',
                    suffixText: 'phút',
                  ),
                  validator: ActivityValidation.duration,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(
                    locale.formatTimeOfDay(
                      TimeOfDay.fromDateTime(_performedAt),
                    ),
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
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('activity-note'),
                  controller: _note,
                  maxLength: ActivityValidation.maxNoteLength,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú (không bắt buộc)',
                  ),
                  validator: ActivityValidation.note,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: requestClose, child: const Text('Hủy')),
          FilledButton(
            key: const ValueKey('save-activity'),
            onPressed: saving ? null : _submit,
            child: Text(saving ? 'Đang lưu…' : 'Lưu'),
          ),
        ],
      ),
    );
  }
}
