import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/models/nutrition_validation.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../nutrition/models/food_catalog_search.dart';
import '../models/food_library_models.dart';
import '../providers/food_library_providers.dart';
import 'food_portion_dialog.dart';
import 'food_nutrition_text.dart';
import '../../nutrition/models/extra_nutrients.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/ingredient_selection.dart';

Widget libraryField(
  TextEditingController controller,
  String key,
  String label, {
  bool number = false,
  bool optional = false,
  VoidCallback? changed,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: TextFormField(
    key: ValueKey(key),
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: number
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    onChanged: (_) => changed?.call(),
    validator: (value) {
      if (value?.trim().isEmpty ?? true) {
        return optional ? null : 'Vui lòng nhập thông tin.';
      }
      if (!number) return null;
      final n = NutritionValidation.parseDecimal(value);
      if (n == null) return 'Nhập số hữu hạn, dùng dấu phẩy hoặc dấu chấm.';
      final max = key.startsWith('library-extra-')
          ? ExtraNutrient.values.byName(key.substring(14)).maximum
          : switch (key) {
              'library-kcal' => 10000.0,
              'library-protein' ||
              'library-carbs' ||
              'library-fat' ||
              'recipe-servings' => 1000.0,
              'library-fiber' => 100.0,
              'recipe-yield' => 20000.0,
              _ => 2000.0,
            };
      final positive = [
        'library-default-grams',
        'library-serving-grams',
        'recipe-yield',
        'recipe-servings',
      ].contains(key);
      return n > max || (positive ? n <= 0 : n < 0)
          ? 'Nhập ${positive ? "trên 0" : "từ 0"} đến ${max.toStringAsFixed(0)}.'
          : null;
    },
  ),
);

Widget libraryFrame({
  required BuildContext context,
  required String title,
  required Widget body,
  required VoidCallback? save,
  required VoidCallback cancel,
  required Widget feedback,
}) => Dialog.fullscreen(
  child: Scaffold(
    appBar: AppBar(
      title: Text(title),
      leading: IconButton(
        onPressed: cancel,
        tooltip: 'Hủy',
        icon: const Icon(Icons.close),
      ),
      actions: [
        TextButton(
          key: const ValueKey('library-save'),
          onPressed: save,
          child: const Text('Lưu'),
        ),
      ],
    ),
    body: body,
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: feedback,
      ),
    ),
  ),
);

class PersonalFoodForm extends ConsumerStatefulWidget {
  const PersonalFoodForm({
    this.food,
    this.initialFood,
    this.initialKcalKnown = true,
    super.key,
  }) : assert(food == null || initialFood == null);
  final PersonalFood? food;

  /// A reviewed scanner draft creates a new private food, never updates catalog.
  final PersonalFood? initialFood;
  final bool initialKcalKnown;
  @override
  ConsumerState<PersonalFoodForm> createState() => _PersonalFoodFormState();
}

class _PersonalFoodFormState extends ConsumerState<PersonalFoodForm>
    with ConfirmedSave<PersonalFood, PersonalFoodForm> {
  final _form = GlobalKey<FormState>();
  final _extraControllers = <ExtraNutrient, TextEditingController>{};
  late final String _id;
  late final TextEditingController _name,
      _aliases,
      _kcal,
      _protein,
      _carbs,
      _fat,
      _fiber,
      _defaultGrams,
      _servingLabel,
      _servingGrams,
      _source;
  String? _error;
  late final List<String> _openingValues;
  List<TextEditingController> get _controllers => [
    _name,
    _aliases,
    _kcal,
    _protein,
    _carbs,
    _fat,
    _fiber,
    _defaultGrams,
    _servingLabel,
    _servingGrams,
    _source,
    ..._extraControllers.values,
  ];
  @override
  bool get hasUnsavedChanges =>
      widget.initialFood != null ||
      _controllers.indexed.any(
        (entry) => entry.$2.text != _openingValues[entry.$1],
      );

  void _changed() => setState(() {});
  @override
  void initState() {
    super.initState();
    final food = widget.food ?? widget.initialFood;
    for (final n in ExtraNutrient.values) {
      _extraControllers[n] = TextEditingController(
        text: food?.per100g.extraNutrients[n.name]?.toString(),
      );
    }
    _id = food?.id ?? ref.read(foodLibraryRepositoryProvider).newId();
    _name = TextEditingController(text: food?.name);
    _aliases = TextEditingController(text: food?.alternateNames.join(', '));
    _kcal = TextEditingController(
      text: widget.initialKcalKnown ? food?.per100g.kcal.toString() : null,
    );
    _protein = TextEditingController(
      text: food?.per100g.proteinKnown == true
          ? food!.per100g.proteinG.toString()
          : null,
    );
    _carbs = TextEditingController(
      text: food?.per100g.carbsKnown == true
          ? food!.per100g.carbsG.toString()
          : null,
    );
    _fat = TextEditingController(
      text: food?.per100g.fatKnown == true
          ? food!.per100g.fatG.toString()
          : null,
    );
    _fiber = TextEditingController(
      text: food?.per100g.fiberKnown == true
          ? food!.per100g.fiberG.toString()
          : null,
    );
    _defaultGrams = TextEditingController(
      text: (food?.defaultServingGrams ?? 100).toString(),
    );
    _servingLabel = TextEditingController(text: food?.servingLabel);
    _servingGrams = TextEditingController(text: food?.servingGrams?.toString());
    _source = TextEditingController(
      text: food?.sourceLabel ?? 'Người dùng nhập · Ước tính',
    );
    _openingValues = _controllers.map((c) => c.text).toList();
    for (final controller in _controllers) {
      controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    for (final c in _extraControllers.values) {
      c.dispose();
    }
    for (final c in [
      _name,
      _aliases,
      _kcal,
      _protein,
      _carbs,
      _fat,
      _fiber,
      _defaultGrams,
      _servingLabel,
      _servingGrams,
      _source,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (saving) return;
    if (!_form.currentState!.validate()) return;
    double read(TextEditingController c) =>
        NutritionValidation.parseDecimal(c.text) ?? double.nan;
    try {
      final food = PersonalFood(
        id: _id,
        minimumSchemaVersion:
            (widget.food ?? widget.initialFood)?.minimumSchemaVersion ?? 1,
        name: _name.text.trim(),
        alternateNames: _aliases.text.trim().isEmpty
            ? const []
            : _aliases.text.split(',').map((s) => s.trim()).toList(),
        per100g: NutritionTotals(
          extraNutrients: {
            for (final e in _extraControllers.entries)
              if (e.value.text.trim().isNotEmpty) e.key.name: read(e.value),
          },
          kcal: read(_kcal),
          proteinG: read(_protein),
          carbsG: read(_carbs),
          fatG: read(_fat),
          fiberG: _fiber.text.trim().isEmpty ? 0 : read(_fiber),
          fiberKnown: _fiber.text.trim().isNotEmpty,
        ),
        defaultServingGrams: read(_defaultGrams),
        servingLabel: _servingLabel.text.trim().isEmpty
            ? null
            : _servingLabel.text.trim(),
        servingGrams: _servingGrams.text.trim().isEmpty
            ? null
            : read(_servingGrams),
        sourceLabel: _source.text.trim(),
      );
      food.validate();
      setState(() => _error = null);
      FocusScope.of(context).unfocus();
      await saveDraft(
        food,
        (value) => ref
            .read(foodLibraryControllerProvider.notifier)
            .save(value, create: widget.food == null),
      );
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(foodLibraryControllerProvider);
    return guardSave(
      libraryFrame(
        context: context,
        title: 'Món của tôi',
        save: saving ? null : _submit,
        cancel: requestClose,
        feedback: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) Text(_error!),
            if (saveError != null && action.error is FoodLibraryFailure)
              Text((action.error as FoodLibraryFailure).message),
            saveFeedback(),
          ],
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (widget.initialFood != null) ...[
                const Text(
                  'Món nhận diện từ ảnh · Ước tính. Kiểm tra/sửa tên, dinh dưỡng trên 100 g và khẩu phần trước khi bấm Lưu. Chỉ lưu vào thư viện riêng; chưa ghi nhật ký.',
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'Nhập đầy đủ dinh dưỡng trên 100 g từ nhãn hoặc nguồn bạn có. Số 0 cần được nhập chủ động; món được gắn nhãn ước tính.',
              ),
              const SizedBox(height: 16),
              libraryField(_name, 'library-name', 'Tên món'),
              libraryField(
                _aliases,
                'library-aliases',
                'Tên khác, ngăn cách bằng dấu phẩy (tối đa 5)',
                optional: true,
              ),
              libraryField(
                _kcal,
                'library-kcal',
                'Năng lượng (kcal/100 g)',
                number: true,
              ),
              libraryField(
                _protein,
                'library-protein',
                'Đạm (g/100 g)',
                number: true,
              ),
              libraryField(
                _carbs,
                'library-carbs',
                'Tinh bột (g/100 g)',
                number: true,
              ),
              libraryField(
                _fat,
                'library-fat',
                'Chất béo (g/100 g)',
                number: true,
              ),
              libraryField(
                _fiber,
                'library-fiber',
                'Chất xơ (g/100 g, tùy chọn)',
                number: true,
                optional: true,
              ),
              const Text(
                'Để trống chất xơ nếu nguồn chưa có; số 0 phải được công bố/nhập có chủ ý.',
              ),
              libraryField(
                _defaultGrams,
                'library-default-grams',
                'Khối lượng mặc định (g)',
                number: true,
              ),
              ExpansionTile(
                title: const Text('Dưỡng chất mở rộng · tùy chọn'),
                children: [
                  const Text(
                    'Nhập theo nguồn/nhãn trên 100 g. Để trống nếu chưa biết; không tự điền 0.',
                  ),
                  for (final e in _extraControllers.entries)
                    libraryField(
                      e.value,
                      'library-extra-${e.key.name}',
                      '${e.key.label} (${e.key.unit}/100 g)',
                      number: true,
                      optional: true,
                    ),
                ],
              ),
              const Text(
                'Khẩu phần tùy chọn: nhập cả tên và gram. Ví dụ: tên “bát”, khối lượng 150 g. Không tự suy ra từ tên món.',
              ),
              libraryField(
                _servingLabel,
                'library-serving-label',
                'Tên một khẩu phần (tùy chọn)',
                optional: true,
              ),
              libraryField(
                _servingGrams,
                'library-serving-grams',
                'Gram của một khẩu phần (tùy chọn)',
                number: true,
                optional: true,
              ),
              libraryField(_source, 'library-source', 'Nguồn thông tin'),
            ],
          ),
        ),
      ),
    );
  }
}

class RecipeForm extends ConsumerStatefulWidget {
  const RecipeForm({this.recipe, super.key});
  final FoodRecipe? recipe;
  @override
  ConsumerState<RecipeForm> createState() => _RecipeFormState();
}

class _RecipeFormState extends ConsumerState<RecipeForm>
    with ConfirmedSave<FoodRecipe, RecipeForm> {
  final _form = GlobalKey<FormState>();
  late final String _id;
  late final TextEditingController _name, _yield, _servings;
  late final List<MealItemSnapshot> _ingredients;
  String? _error;
  late final List<String> _openingValues;
  late final String _openingIngredients;
  String get _ingredientValues =>
      jsonEncode(_ingredients.map((i) => i.toData()).toList());
  @override
  bool get hasUnsavedChanges =>
      [
        _name,
        _yield,
        _servings,
      ].indexed.any((entry) => entry.$2.text != _openingValues[entry.$1]) ||
      _ingredientValues != _openingIngredients;
  void _changed() => setState(() {});
  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    _id = recipe?.id ?? ref.read(foodLibraryRepositoryProvider).newId();
    _name = TextEditingController(text: recipe?.name);
    _yield = TextEditingController(text: recipe?.yieldGrams.toString());
    _servings = TextEditingController(text: recipe?.servingsCount?.toString());
    _ingredients = [...?recipe?.ingredients];
    _openingValues = [_name.text, _yield.text, _servings.text];
    _openingIngredients = _ingredientValues;
    for (final controller in [_name, _yield, _servings]) {
      controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _yield.dispose();
    _servings.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_ingredients.length >= LibraryValidation.maxIngredients) {
      setState(() => _error = 'Tối đa 6 nguyên liệu trong một công thức.');
      return;
    }
    final ingredient = await showDialog<MealItemSnapshot>(
      context: context,
      builder: (_) => const AccountBoundDialog(child: IngredientPicker()),
    );
    if (ingredient == null || !mounted) return;
    setState(() {
      _ingredients.add(ingredient);
      _error = null;
    });
  }

  Future<void> _edit(int index) async {
    final old = _ingredients[index];
    final grams = await askFoodGrams(context, initial: old.grams);
    if (grams == null || !mounted) return;
    try {
      setState(() => _ingredients[index] = old.withGrams(grams));
    } on FormatException {
      setState(
        () =>
            _error = 'Nguyên liệu thiếu dữ liệu. Hãy bỏ dòng này và chọn lại.',
      );
    }
  }

  Future<void> _submit() async {
    if (saving) return;
    if (!_form.currentState!.validate()) return;
    try {
      final recipe = FoodRecipe(
        id: _id,
        minimumSchemaVersion: widget.recipe?.minimumSchemaVersion ?? 1,
        name: _name.text.trim(),
        ingredients: _ingredients,
        sourceLabel:
            widget.recipe?.sourceLabel ?? 'Công thức người dùng · Ước tính',
        yieldGrams: NutritionValidation.parseDecimal(_yield.text) ?? double.nan,
        servingsCount: _servings.text.trim().isEmpty
            ? null
            : NutritionValidation.parseDecimal(_servings.text) ?? double.nan,
      );
      recipe.validate();
      setState(() => _error = null);
      FocusScope.of(context).unfocus();
      await saveDraft(
        recipe,
        (value) => ref
            .read(foodLibraryControllerProvider.notifier)
            .save(value, create: widget.recipe == null),
      );
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = sumNutritionTotals(_ingredients.map((i) => i.nutrition));
    final yieldGrams = NutritionValidation.parseDecimal(_yield.text);
    final count = NutritionValidation.parseDecimal(_servings.text);
    final action = ref.watch(foodLibraryControllerProvider);
    return guardSave(
      libraryFrame(
        context: context,
        title: 'Công thức',
        save: saving ? null : _submit,
        cancel: requestClose,
        feedback: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) Text(_error!),
            if (saveError != null && action.error is FoodLibraryFailure)
              Text((action.error as FoodLibraryFailure).message),
            saveFeedback(),
          ],
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              libraryField(_name, 'recipe-name', 'Tên công thức'),
              const Text(
                'Dinh dưỡng được tính từ snapshot nguyên liệu. Khối lượng thành phẩm có thể khác tổng nguyên liệu do chế biến; đây là số ước tính.',
              ),
              const SizedBox(height: 16),
              libraryField(
                _yield,
                'recipe-yield',
                'Khối lượng thành phẩm (g)',
                number: true,
                changed: () => setState(() {}),
              ),
              libraryField(
                _servings,
                'recipe-servings',
                'Số phần của toàn công thức (tùy chọn)',
                number: true,
                optional: true,
                changed: () => setState(() {}),
              ),
              Text('Tổng công thức: ${nutritionLabel(totals)}'),
              if (yieldGrams != null && yieldGrams > 0)
                Text(
                  'Trên 100 g: ${nutritionLabel(totals.scale(100 / yieldGrams))}',
                ),
              if (yieldGrams != null &&
                  yieldGrams > 0 &&
                  count != null &&
                  count > 0)
                Text('1 phần = ${foodNumber(yieldGrams / count)} g'),
              const SizedBox(height: 16),
              Text(
                '${_ingredients.length}/6 nguyên liệu · Chỉ catalog hoặc Món của tôi',
              ),
              OutlinedButton.icon(
                key: const ValueKey('add-ingredient'),
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: const Text('Thêm nguyên liệu'),
              ),
              for (final entry in _ingredients.indexed)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(entry.$2.name),
                        Text(
                          '${foodNumber(entry.$2.grams)} g · ${nutritionLabel(entry.$2.nutrition)}',
                        ),
                        Text(entry.$2.sourceLabel),
                        Wrap(
                          children: [
                            TextButton(
                              key: ValueKey('edit-ingredient-${entry.$1}'),
                              onPressed: () => _edit(entry.$1),
                              child: const Text('Sửa gram'),
                            ),
                            TextButton(
                              key: ValueKey('remove-ingredient-${entry.$1}'),
                              onPressed: () => setState(
                                () => _ingredients.removeAt(entry.$1),
                              ),
                              child: const Text('Bỏ'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class IngredientPicker extends ConsumerStatefulWidget {
  const IngredientPicker({super.key});
  @override
  ConsumerState<IngredientPicker> createState() => _IngredientPickerState();
}

class _IngredientPickerState extends ConsumerState<IngredientPicker> {
  bool _custom = false;
  int _limit = 40, _visible = 12;
  String _query = '';
  bool _choosing = false;
  String? _selectionError;
  int _session = 0;
  Future<void> _choose(FoodCatalogItem food) async {
    if (_choosing || !canUseRecipeIngredient(food)) return;
    final uid = ref.read(authSessionProvider).value?.uid, session = _session;
    if (uid == null) return;
    final custom = _custom, limit = _limit;
    setState(() {
      _choosing = true;
      _selectionError = null;
    });
    try {
      final grams = await askFoodGrams(
        context,
        initial: food.defaultServingGrams,
        food: food,
      );
      if (grams == null ||
          !mounted ||
          session != _session ||
          ref.read(authSessionProvider).value?.uid != uid) {
        return;
      }
      final List<FoodCatalogItem> available;
      if (custom) {
        final state = ref.read(
          foodLibraryProvider((kind: FoodSourceKind.custom, limit: limit)),
        );
        if (state.isLoading || state.hasError || !state.hasValue) {
          throw const FormatException(
            'Chưa xác nhận được nguồn nguyên liệu. Hãy tải lại và chọn lại.',
          );
        }
        available = state.requireValue.items
            .map((entry) => entry.asFood())
            .toList();
      } else {
        final state = ref.read(foodCatalogProvider),
            visibility = ref.read(foodVisibilityProvider);
        if (state.isLoading ||
            state.hasError ||
            !state.hasValue ||
            visibility.isLoading ||
            visibility.hasError ||
            !visibility.hasValue) {
          throw const FormatException(
            'Chưa xác nhận được danh mục. Hãy tải lại và chọn lại.',
          );
        }
        available = state.requireValue
            .where(visibility.requireValue.allows)
            .toList();
      }
      final latest = available.where((item) => item.id == food.id).firstOrNull;
      if (latest == null || !canUseRecipeIngredient(latest)) {
        throw const FormatException(
          'Nguyên liệu đã bị xóa, ẩn hoặc không còn đủ dữ liệu. Hãy chọn nguyên liệu khác.',
        );
      }
      if (ingredientSelectionRevision(latest) !=
          ingredientSelectionRevision(food)) {
        throw const FormatException(
          'Thông tin nguyên liệu vừa thay đổi. Hãy chọn lại để xem dữ liệu và khẩu phần mới.',
        );
      }
      Navigator.pop(context, MealItemSnapshot.fromCatalog(latest, grams));
    } on FormatException catch (error) {
      if (mounted) setState(() => _selectionError = error.message);
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider.select((s) => s.value?.uid), (
      before,
      after,
    ) {
      if (before != after) _session++;
    });
    final visibility = _custom ? null : ref.watch(foodVisibilityProvider);
    final state = _custom
        ? ref
              .watch(
                foodLibraryProvider((
                  kind: FoodSourceKind.custom,
                  limit: _limit,
                )),
              )
              .whenData(
                (page) => page.items.map((item) => item.asFood()).toList(),
              )
        : ref.watch(foodCatalogProvider);
    final visibilityPending =
        visibility != null &&
        (visibility.isLoading || visibility.hasError || !visibility.hasValue);
    final foods = searchFoodCatalog(
      (state.value ?? [])
          .where((food) => _custom || visibility?.value?.allows(food) == true)
          .toList(),
      _query,
    );
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chọn nguyên liệu'),
          leading: IconButton(
            tooltip: 'Hủy',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Catalog'),
                    selected: !_custom,
                    onSelected: (_) => setState(() => _custom = false),
                  ),
                  ChoiceChip(
                    label: const Text('Món của tôi'),
                    selected: _custom,
                    onSelected: (_) => setState(() => _custom = true),
                  ),
                ],
              ),
              TextField(
                key: const ValueKey('ingredient-search'),
                decoration: const InputDecoration(labelText: 'Tìm nguyên liệu'),
                onChanged: (value) => setState(() => _query = value),
              ),
              if (_selectionError != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _selectionError!,
                    key: const ValueKey('ingredient-selection-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (visibilityPending) ...[
                Text(
                  visibility.hasError
                      ? 'Chưa xác nhận được trạng thái hiển thị của nguyên liệu.'
                      : 'Đang đồng bộ trạng thái nguyên liệu…',
                ),
                TextButton(
                  onPressed: () => ref.invalidate(foodVisibilityProvider),
                  child: const Text('Thử tải trạng thái nguyên liệu'),
                ),
              ],
              if (state.isLoading)
                const LinearProgressIndicator()
              else if (state.hasError) ...[
                const Text(
                  'Chưa tải được nguyên liệu. Không coi lỗi là nguồn trống.',
                ),
                TextButton(
                  onPressed: () => _custom
                      ? ref.invalidate(
                          foodLibraryProvider((
                            kind: FoodSourceKind.custom,
                            limit: _limit,
                          )),
                        )
                      : ref.invalidate(foodCatalogProvider),
                  child: const Text('Thử lại'),
                ),
              ] else ...[
                if (_custom &&
                    ref
                            .watch(
                              foodLibraryProvider((
                                kind: FoodSourceKind.custom,
                                limit: _limit,
                              )),
                            )
                            .value
                            ?.fromCache ==
                        true)
                  const Text(
                    'Dữ liệu trên thiết bị; đang chờ xác nhận từ máy chủ.',
                  ),
                if (foods.isEmpty)
                  const Text('Chưa có nguyên liệu phù hợp trong nguồn đã tải.'),
                for (final food
                    in (visibilityPending ? <FoodCatalogItem>[] : foods).take(
                      _visible,
                    ))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(food.name),
                    subtitle: Text(
                      canUseRecipeIngredient(food)
                          ? '${nutritionLabel(food.nutritionPer100g)} /100 g'
                          : 'Thiếu dữ liệu dinh dưỡng',
                    ),
                    onTap: !_choosing && canUseRecipeIngredient(food)
                        ? () => _choose(food)
                        : null,
                  ),
                if (foods.length > _visible)
                  TextButton(
                    onPressed: () => setState(() => _visible += 12),
                    child: const Text('Xem thêm nguyên liệu'),
                  ),
                if (_custom && (state.value?.length ?? 0) == _limit)
                  TextButton(
                    onPressed: () => setState(() => _limit += 40),
                    child: const Text('Tải thêm Món của tôi'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
