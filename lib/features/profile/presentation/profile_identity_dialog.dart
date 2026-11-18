import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/profile_image_picker.dart';
import '../models/profile_appearance.dart';
import '../models/profile_failure.dart';
import '../models/profile_validation.dart';
import '../models/user_profile.dart';

class ProfileIdentityDialog extends ConsumerStatefulWidget {
  const ProfileIdentityDialog({
    required this.profile,
    required this.onSave,
    super.key,
  });
  final UserProfile profile;
  final Future<bool> Function(ProfileIdentityDraft) onSave;

  @override
  ConsumerState<ProfileIdentityDialog> createState() =>
      _ProfileIdentityDialogState();
}

class _ProfileIdentityDialogState extends ConsumerState<ProfileIdentityDialog>
    with ConfirmedSave<ProfileIdentityDraft, ProfileIdentityDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late ProfileAppearance _appearance;
  ProfileImageSlot? _picking;
  String? _imageError;

  @override
  bool get hasUnsavedChanges =>
      _name.text != widget.profile.displayName ||
      !_appearance.sameAs(widget.profile.appearance);

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.displayName)
      ..addListener(_changed);
    _appearance = widget.profile.appearance;
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick(ProfileImageSlot slot) async {
    if (_picking != null || saving) return;
    setState(() {
      _picking = slot;
      _imageError = null;
    });
    try {
      final image = await ref.read(profileImagePickerProvider).pick(slot);
      if (!mounted ||
          ref.read(authSessionProvider).value?.uid != widget.profile.uid) {
        return;
      }
      if (image != null) {
        setState(() => _appearance = _appearance.replace(slot, image));
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _imageError = error is ProfileFailure
              ? error.message
              : 'Chưa chọn được ảnh. Hãy thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = null);
    }
  }

  void _save() {
    if (_picking != null || !_form.currentState!.validate()) return;
    saveDraft(
      ProfileIdentityDraft(
        displayName: _name.text.trim(),
        appearance: _appearance,
      ),
      widget.onSave,
    );
  }

  @override
  Widget build(BuildContext context) => guardSave(
    AlertDialog(
      title: const Text('Tên & ảnh hồ sơ'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const ValueKey('identity-name'),
                  controller: _name,
                  maxLength: 50,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                  validator: ProfileValidation.displayName,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chọn ảnh từ thư viện. Ảnh được cắt giữa khung; xem trước bên dưới rồi lưu.',
                ),
                for (final slot in ProfileImageSlot.values) ...[
                  const SizedBox(height: 18),
                  Text(
                    slot.label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        slot == ProfileImageSlot.avatar ? 48 : 12,
                      ),
                      child: SizedBox(
                        width: slot == ProfileImageSlot.avatar
                            ? 80
                            : double.infinity,
                        height: slot == ProfileImageSlot.avatar ? 80 : 110,
                        child: _appearance.image(slot) == null
                            ? ColoredBox(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                                child: Icon(
                                  slot == ProfileImageSlot.avatar
                                      ? AppIcons.profile
                                      : AppIcons.image,
                                ),
                              )
                            : Image.memory(
                                _appearance.image(slot)!.bytes,
                                key: ValueKey('identity-preview-${slot.name}'),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Text('Không đọc được ảnh'),
                                ),
                              ),
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        key: ValueKey('identity-pick-${slot.name}'),
                        onPressed: _picking != null ? null : () => _pick(slot),
                        icon: const Icon(AppIcons.image),
                        label: Text(
                          _picking == slot ? 'Đang xử lý…' : 'Chọn ảnh',
                        ),
                      ),
                      if (_appearance.image(slot) != null)
                        TextButton.icon(
                          key: ValueKey('identity-remove-${slot.name}'),
                          onPressed: _picking != null
                              ? null
                              : () => setState(
                                  () => _appearance = _appearance.replace(
                                    slot,
                                    null,
                                  ),
                                ),
                          icon: const Icon(AppIcons.trash2),
                          label: const Text('Gỡ ảnh'),
                        ),
                    ],
                  ),
                ],
                if (_picking != null) const LinearProgressIndicator(),
                if (_imageError != null)
                  Text(
                    _imageError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Chỉ ảnh thu nhỏ được lưu riêng theo tài khoản. Ảnh gốc và vị trí chụp không được lưu.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                saveFeedback(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : requestClose,
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const ValueKey('save-profile-identity'),
          onPressed: saving || _picking != null || !hasUnsavedChanges
              ? null
              : _save,
          child: const Text('Lưu thay đổi'),
        ),
      ],
    ),
  );
}
