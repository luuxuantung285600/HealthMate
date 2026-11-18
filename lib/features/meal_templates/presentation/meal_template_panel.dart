import '../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../food_library/presentation/food_portion_dialog.dart';
import '../../food_library/presentation/library_forms.dart';
import '../../food_library/presentation/food_nutrition_text.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/meal_template.dart';
import '../providers/meal_template_providers.dart';

Future<void> editMealTemplate(
  BuildContext context, {
  MealTemplate? template,
  List<MealItemSnapshot> initialItems = const [],
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => AccountBoundDialog(
    child: MealTemplateEditor(template: template, initialItems: initialItems),
  ),
);

class MealTemplateEditor extends ConsumerStatefulWidget {
  const MealTemplateEditor({
    this.template,
    this.initialItems = const [],
    super.key,
  });
  final MealTemplate? template;
  final List<MealItemSnapshot> initialItems;
  @override
  ConsumerState<MealTemplateEditor> createState() => _MealTemplateEditorState();
}

class _MealTemplateEditorState extends ConsumerState<MealTemplateEditor> {
  late final TextEditingController _name;
  late final String _id;
  late List<MealItemSnapshot> _items;
  String? _error;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.template?.name);
    _id =
        widget.template?.id ?? ref.read(mealTemplateRepositoryProvider).newId();
    _items = [...widget.template?.items ?? widget.initialItems];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final uid = ref.read(authSessionProvider).value?.uid;
    final value = MealTemplate(id: _id, name: _name.text.trim(), items: _items);
    try {
      value.validate();
    } on FormatException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await ref
        .read(mealTemplateControllerProvider.notifier)
        .save(value, create: widget.template == null);
    if (!mounted || ref.read(authSessionProvider).value?.uid != uid) return;
    if (saved) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _saving = false;
      _error =
          'Chưa lưu được. Bản nháp được giữ; hãy kết nối lại và thử lưu cùng thao tác.';
    });
  }

  Future<void> _add() async {
    final item = await showDialog<MealItemSnapshot>(
      context: context,
      builder: (_) => const AccountBoundDialog(child: IngredientPicker()),
    );
    if (mounted && item != null) setState(() => _items.add(item));
  }

  Future<void> _edit(int index) async {
    final grams = await askSnapshotQuantity(context, _items[index]);
    if (grams != null && mounted) {
      setState(() => _items[index] = _items[index].withQuantity(grams));
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AbsorbPointer(
      absorbing: _saving,
      child: Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Thiết lập bữa mẫu'),
            leading: IconButton(
              tooltip: 'Hủy',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(AppIcons.x),
            ),
            actions: [
              TextButton(
                key: const ValueKey('save-meal-template'),
                onPressed: _save,
                child: const Text('Lưu bữa mẫu'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                key: const ValueKey('meal-template-name'),
                controller: _name,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Tên bữa mẫu'),
              ),
              const Text(
                'Chưa ghi nhật ký. Kiểm tra món và lượng trước khi dùng.',
              ),
              for (final e in _items.indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.$2.name),
                  subtitle: Text(
                    '${snapshotQuantityLabel(e.$2)} · ${nutritionLabel(e.$2.nutrition)}',
                  ),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Sửa lượng món ${e.$1 + 1}',
                        onPressed: () => _edit(e.$1),
                        icon: const Icon(AppIcons.squarePen),
                      ),
                      IconButton(
                        tooltip: 'Bỏ món ${e.$1 + 1}',
                        onPressed: () => setState(() => _items.removeAt(e.$1)),
                        icon: const Icon(AppIcons.x),
                      ),
                    ],
                  ),
                ),
              if (_items.length < 5)
                OutlinedButton.icon(
                  key: const ValueKey('add-template-item'),
                  onPressed: _add,
                  icon: const Icon(AppIcons.plus),
                  label: const Text('Thêm món vào bữa mẫu'),
                ),
              Text('${_items.length}/5 món; có thể tạo bữa mẫu khác nếu cần.'),
              if (_saving) ...[
                const LinearProgressIndicator(),
                const Text('Đang chờ máy chủ xác nhận; không gửi lặp.'),
              ],
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class MealTemplatePanel extends ConsumerStatefulWidget {
  const MealTemplatePanel({
    required this.items,
    required this.onUse,
    super.key,
  });
  final List<MealItemSnapshot> items;
  final ValueChanged<List<MealItemSnapshot>> onUse;
  @override
  ConsumerState<MealTemplatePanel> createState() => _MealTemplatePanelState();
}

class _MealTemplatePanelState extends ConsumerState<MealTemplatePanel> {
  bool _open = false;
  int _limit = 40;
  Future<void> _delete(MealTemplate t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xóa bữa mẫu ${t.name}?'),
        content: const Text('Bữa ăn đã ghi không bị thay đổi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa bữa mẫu'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(mealTemplateControllerProvider.notifier).delete(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _open ? ref.watch(mealTemplatesProvider(_limit)) : null;
    final action = ref.watch(mealTemplateControllerProvider);
    return ExpansionTile(
      key: const ValueKey('meal-templates'),
      title: const Text('Bữa mẫu'),
      onExpansionChanged: (v) => setState(() => _open = v),
      children: [
        const Text(
          'Dùng bản sao các món/lượng vào ngày và bữa đang chọn; kiểm tra từng món rồi Lưu. Không tự ghi nhật ký.',
        ),
        OutlinedButton(
          key: const ValueKey('create-meal-template'),
          onPressed: action.isLoading
              ? null
              : () => editMealTemplate(context, initialItems: widget.items),
          child: Text(
            widget.items.isEmpty
                ? 'Tạo bữa mẫu'
                : 'Lưu món đang chọn thành bữa mẫu',
          ),
        ),
        if (action.isLoading) const LinearProgressIndicator(),
        if (action.error case final MealTemplateFailure e) Text(e.message),
        if (state != null)
          state.when(
            loading: () => const Column(
              children: [
                LinearProgressIndicator(),
                Text(
                  'Đang chờ bữa mẫu từ máy chủ. Nếu mất mạng, hãy kết nối lại hoặc tiếp tục nhập tay.',
                ),
              ],
            ),
            error: (_, _) => Column(
              children: [
                const Text(
                  'Chưa tải được bữa mẫu. Bạn vẫn ghi bữa thủ công được.',
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(mealTemplatesProvider(_limit)),
                  child: const Text('Thử tải bữa mẫu'),
                ),
              ],
            ),
            data: (templates) => Column(
              children: [
                if (templates.isEmpty)
                  const Text(
                    'Chưa có bữa mẫu. Chọn vài món rồi lưu để dùng lại.',
                  ),
                for (final t in templates)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        t.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        t.items
                            .map((i) => '${i.name} ${snapshotQuantityLabel(i)}')
                            .join(' · '),
                      ),
                      Wrap(
                        children: [
                          TextButton(
                            key: ValueKey('use-template-${t.id}'),
                            onPressed: action.isLoading
                                ? null
                                : () => widget.onUse(t.items),
                            child: const Text('Dùng bữa mẫu'),
                          ),
                          TextButton(
                            key: ValueKey('edit-template-${t.id}'),
                            onPressed: action.isLoading
                                ? null
                                : () => editMealTemplate(context, template: t),
                            child: const Text('Sửa bữa mẫu'),
                          ),
                          TextButton(
                            key: ValueKey('delete-template-${t.id}'),
                            onPressed: action.isLoading
                                ? null
                                : () => _delete(t),
                            child: const Text('Xóa bữa mẫu'),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (templates.length >= _limit && _limit < 200)
                  TextButton(
                    onPressed: () => setState(() => _limit += 40),
                    child: const Text('Xem thêm bữa mẫu'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
