import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../nutrition/models/nutrition_models.dart';
import '../../../core/config/ai_access_policy.dart';
import '../../../core/config/app_feature_flags.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../food_library/models/food_library_models.dart';
import '../../food_library/presentation/library_forms.dart';
import '../../food_library/presentation/food_nutrition_text.dart';
import '../../food_library/providers/food_library_providers.dart';
import '../../nutrition/models/nutrition_validation.dart';
import '../data/food_scanner_service.dart';
import '../data/food_camera_service.dart';
import '../data/food_image_picker.dart';
import 'food_camera_view.dart';
import '../models/ai_food_suggestion.dart';
import '../models/food_scan_catalog_matcher.dart';
import '../providers/food_scanner_providers.dart';

class FoodScanChoice {
  const FoodScanChoice({required this.query, this.food, this.grams = 100});

  final String query;
  final FoodCatalogItem? food;
  final double grams;
}

class FoodScannerDialog extends ConsumerStatefulWidget {
  const FoodScannerDialog({
    required this.catalog,
    this.embedded = false,
    this.active = true,
    this.onSelected,
    this.onBarcode,
    this.onSearch,
    super.key,
  });

  final List<FoodCatalogItem> catalog;
  final bool embedded, active;
  final ValueChanged<FoodScanChoice>? onSelected;
  final Future<void> Function()? onBarcode;
  final VoidCallback? onSearch;

  @override
  ConsumerState<FoodScannerDialog> createState() => _FoodScannerDialogState();
}

class _FoodScannerDialogState extends ConsumerState<FoodScannerDialog> {
  final _nameController = TextEditingController();
  final _gramsController = TextEditingController(text: '100');
  Uint8List? _bytes;
  String? _mimeType;
  AiFoodSuggestion? _suggestion;
  FoodCatalogItem? _selected;
  FoodCatalogItem? _savedFood;
  String? _newFoodId;
  bool _reviewing = false;
  bool _loading = false;
  bool _picking = false;
  bool _acceptedProcessing = false;
  int _operation = 0;
  Completer<void>? _stopped;
  String? _error;

  void _acceptImage(FoodImage image) {
    setState(() {
      _bytes = image.bytes;
      _mimeType = image.mimeType;
      _suggestion = null;
      _selected = null;
      _savedFood = null;
      _newFoodId = null;
      _acceptedProcessing = false;
      _nameController.clear();
    });
  }

  Future<void> _barcode() async {
    if (_picking || _loading || _reviewing) return;
    setState(() => _picking = true);
    try {
      await ref.read(foodCameraServiceProvider).release();
      if (mounted) await widget.onBarcode?.call();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Chưa mở được máy quét mã vạch. Hãy thử lại hoặc nhập tay.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _confirm() {
    final choice = FoodScanChoice(
      query: _nameController.text.trim(),
      food: _selected,
      grams: NutritionValidation.parseDecimal(_gramsController.text) ?? 100,
    );
    if (widget.onSelected != null) {
      widget.onSelected!(choice);
    } else {
      Navigator.pop(context, choice);
    }
  }

  @override
  void dispose() {
    if (_stopped case final stopped? when !stopped.isCompleted) {
      stopped.complete();
    }
    _operation++;
    _nameController.dispose();
    _gramsController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (!ref.read(appFeatureFlagsProvider).foodScannerEnabled) return;
    if (ref.read(foodScannerServiceProvider).photoUnavailableReason != null) {
      return;
    }
    if (_picking || _loading) return;
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) {
      setState(() => _error = 'Hãy đăng nhập trước khi chọn ảnh.');
      return;
    }
    final operation = ++_operation;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      if (widget.embedded) await ref.read(foodCameraServiceProvider).release();
      final image = await ref.read(foodImagePickerProvider).pick(source);
      if (image == null || !_current(operation, uid)) return;
      _acceptImage(image);
    } catch (error) {
      if (_current(operation, uid)) {
        setState(
          () => _error = error is FoodScannerFailure
              ? error.message
              : 'Chưa thể chọn ảnh. Bạn vẫn có thể nhập món thủ công.',
        );
      }
    } finally {
      if (_current(operation, uid)) setState(() => _picking = false);
    }
  }

  bool _current(int operation, String? uid) =>
      mounted &&
      operation == _operation &&
      uid != null &&
      ref.read(authSessionProvider).value?.uid == uid;

  Future<void> _analyze() async {
    if (!ref.read(appFeatureFlagsProvider).foodScannerEnabled) return;
    final bytes = _bytes;
    final mime = _mimeType;
    if (bytes == null ||
        mime == null ||
        _loading ||
        _picking ||
        !_acceptedProcessing) {
      return;
    }
    final access = ref.read(aiAccessProvider);
    if (!access.allowed) {
      setState(() => _error = access.message);
      return;
    }
    final uid = ref.read(authSessionProvider).value?.uid;
    final operation = ++_operation;
    final stopped = _stopped = Completer<void>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.any<AiFoodSuggestion>([
        ref
            .read(foodScannerServiceProvider)
            .analyze(bytes: bytes, mimeType: mime),
        stopped.future.then<AiFoodSuggestion>(
          (_) => throw const FoodScannerFailure('Đã đóng lượt quét.'),
        ),
      ]).timeout(const Duration(seconds: 45));
      if (!_current(operation, uid)) return;
      _nameController.text = result.dishName;
      setState(() {
        _suggestion = result;
        _savedFood = null;
        _newFoodId = null;
        final matches = _matches(result);
        // Only a unique whole-dish match may replace the AI estimate.
        _selected = matches.length == 1 ? matches.single : null;
        _gramsController.text = (result.estimatedServingGrams ?? 100)
            .toString();
      });
    } on FoodScannerFailure catch (error) {
      if (_current(operation, uid)) setState(() => _error = error.message);
    } on TimeoutException {
      if (_current(operation, uid)) {
        setState(
          () => _error =
              'Phân tích quá thời gian chờ. Hãy thử lại hoặc nhập thủ công.',
        );
      }
    } catch (_) {
      if (_current(operation, uid)) {
        setState(
          () => _error =
              'Chưa thể phân tích ảnh. Hãy kiểm tra mạng hoặc nhập thủ công.',
        );
      }
    } finally {
      if (_current(operation, uid)) {
        _stopped = null;
        setState(() => _loading = false);
      }
    }
  }

  List<FoodCatalogItem> _matches(AiFoodSuggestion suggestion) {
    if (!suggestion.isFood) return const [];
    return FoodScanCatalogMatcher.matches(_nameController.text, [
      ...widget.catalog,
      ?_savedFood,
    ]);
  }

  FoodCatalogItem? get _nutritionFood =>
      _selected?.hasNutritionData == true ? _selected : null;

  Future<void> _saveRecognizedFood() async {
    final suggestion = _suggestion;
    final uid = ref.read(authSessionProvider).value?.uid;
    if (_reviewing || uid == null || suggestion == null || !suggestion.isFood) {
      return;
    }
    final estimate = suggestion.estimatedNutritionPer100g;
    // Known catalog values take priority. A missing field stays empty in review.
    final selected = _nutritionFood;
    final per100g = selected != null
        ? selected.nutritionPer100g
        : NutritionTotals(
            kcal: estimate?.kcal ?? 0,
            proteinG: estimate?.proteinG ?? 0,
            carbsG: estimate?.carbsG ?? 0,
            fatG: estimate?.fatG ?? 0,
            fiberG: estimate?.fiberG ?? 0,
            proteinKnown: estimate?.proteinG != null,
            carbsKnown: estimate?.carbsG != null,
            fatKnown: estimate?.fatG != null,
            fiberKnown: estimate?.fiberG != null,
          );
    final kcalKnown = selected != null || estimate?.kcal != null;
    _newFoodId ??= ref.read(foodLibraryRepositoryProvider).newId();
    final initial = PersonalFood(
      id: _newFoodId!,
      name: _nameController.text.trim(),
      per100g: per100g,
      defaultServingGrams:
          NutritionValidation.parseDecimal(_gramsController.text) ?? 100,
      sourceLabel:
          selected?.sourceLabel ??
          'AI Gemini · Ước tính từ ảnh, người dùng xác nhận',
    );
    setState(() => _reviewing = true);
    try {
      final saved = await showDialog<PersonalFood>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AccountBoundDialog(
          child: PersonalFoodForm(
            initialFood: initial,
            initialKcalKnown: kcalKnown,
          ),
        ),
      );
      if (!mounted ||
          ref.read(authSessionProvider).value?.uid != uid ||
          saved == null) {
        return;
      }
      setState(() {
        _savedFood = saved.asFood();
        _selected = _savedFood;
        _nameController.text = saved.name;
        _gramsController.text = saved.defaultServingGrams.toString();
      });
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  Widget _nutritionDetails(AiFoodSuggestion suggestion) {
    final food = _nutritionFood;
    final n = food?.nutritionPer100g;
    final estimate = suggestion.estimatedNutritionPer100g;
    final grams = NutritionValidation.grams(_gramsController.text) == null
        ? NutritionValidation.parseDecimal(_gramsController.text)
        : null;
    String amount(double? value, String unit) =>
        value == null ? 'Chưa có dữ liệu' : '${foodNumber(value)} $unit';
    final values = <(String, double?, String)>[
      ('Năng lượng', n?.kcal ?? estimate?.kcal, 'kcal'),
      (
        'Đạm (protein)',
        n != null ? (n.proteinKnown ? n.proteinG : null) : estimate?.proteinG,
        'g',
      ),
      (
        'Carbohydrate',
        n != null ? (n.carbsKnown ? n.carbsG : null) : estimate?.carbsG,
        'g',
      ),
      (
        'Chất béo',
        n != null ? (n.fatKnown ? n.fatG : null) : estimate?.fatG,
        'g',
      ),
      (
        'Chất xơ',
        n != null ? (n.fiberKnown ? n.fiberG : null) : estimate?.fiberG,
        'g',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Thông tin dinh dưỡng',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text('Nguồn: ${food?.sourceLabel ?? 'AI Gemini · Ước tính từ ảnh'}'),
        Text(
          food == null
              ? 'Dinh dưỡng cho toàn bộ món trong ảnh, gồm các thành phần nhận diện được.'
              : 'Dinh dưỡng của món danh mục: ${food.name}.',
        ),
        Text(
          n == null || food!.isEstimated
              ? 'Ước tính · Kiểm tra món, cách chế biến và khẩu phần trước khi lưu.'
              : 'Theo danh mục đã chọn; hãy kiểm tra món và khẩu phần.',
        ),
        if (food != null && _savedFood == null)
          TextButton(
            key: const ValueKey('scanner-use-ai'),
            onPressed: _loading || _picking || _reviewing
                ? null
                : () => setState(() => _selected = null),
            child: const Text('Dùng ước tính AI cho món trong ảnh'),
          ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('scanner-grams'),
          controller: _gramsController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Khối lượng phần ăn (g) — hãy kiểm tra',
            errorText: NutritionValidation.grams(_gramsController.text),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (suggestion.estimatedServingGrams != null)
          Text(
            'AI gợi ý khoảng ${foodNumber(suggestion.estimatedServingGrams!)} g; đây không phải khối lượng đã đo.',
          ),
        const SizedBox(height: 8),
        for (final value in values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${value.$1}: ${amount(value.$2, value.$3)} / 100 g'
              '${grams == null ? '' : ' · Phần ${foodNumber(grams)} g: ${amount(value.$2 == null ? null : value.$2! * grams / 100, value.$3)}'}',
            ),
          ),
        const Text(
          'Các vitamin, khoáng chất và thông tin dị ứng chưa được xác minh từ ảnh. Không có số liệu không có nghĩa là 0.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(appFeatureFlagsProvider).foodScannerEnabled) {
      return AlertDialog(
        title: const Text('Quét món đang tạm tắt'),
        content: const Text('Bạn vẫn có thể thêm bữa ăn thủ công từ Nhật ký.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      );
    }
    ref.listen(authSessionProvider.select((session) => session.value?.uid), (
      previous,
      next,
    ) {
      if (previous == next) return;
      _operation++;
      if (_stopped case final stopped? when !stopped.isCompleted) {
        stopped.complete();
      }
      final route = ModalRoute.of(context);
      final navigator = Navigator.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Auth redirects may already have removed this dialog by this frame.
        if (mounted && route?.isCurrent == true && navigator.canPop()) {
          navigator.pop();
        }
      });
    });
    final access = ref.watch(aiAccessProvider);
    final unavailable = ref
        .watch(foodScannerServiceProvider)
        .photoUnavailableReason;
    if (unavailable != null) {
      final content = SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.image_outlined, size: 40),
            const SizedBox(height: 16),
            Text(
              'Phân tích ảnh chưa sẵn sàng',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(unavailable),
            const SizedBox(height: 24),
            if (widget.onBarcode != null)
              FilledButton.icon(
                key: const ValueKey('photo-fallback-barcode'),
                onPressed: _picking ? null : _barcode,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Quét mã vạch'),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('photo-fallback-search'),
              onPressed: widget.onSearch ?? () => Navigator.pop(context),
              icon: const Icon(Icons.search),
              label: const Text('Tìm món hoặc nhập thủ công'),
            ),
            if (_error != null) Text(_error!),
          ],
        ),
      );
      return widget.embedded
          ? content
          : Dialog.fullscreen(child: SafeArea(child: content));
    }
    final busy = _loading || _picking || _reviewing;
    final suggestion = _suggestion;
    final matches = suggestion == null
        ? const <FoodCatalogItem>[]
        : _matches(suggestion);
    if (widget.embedded && _bytes == null) {
      return FoodCameraView(
        active: widget.active && !busy,
        onImage: _acceptImage,
        onGallery: () => _pick(ImageSource.gallery),
        onBarcode: _barcode,
        errorMessage: _error,
      );
    }
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: _buildContent(access, busy, suggestion, matches),
      ),
    );
    if (widget.embedded) return content;
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nhận diện món từ ảnh'),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Đóng',
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: content,
      ),
    );
  }

  Widget _buildContent(
    AiAccess access,
    bool busy,
    AiFoodSuggestion? suggestion,
    List<FoodCatalogItem> matches,
  ) => ListView(
    key: const ValueKey('scanner-content'),
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        'Nhận diện món và xem dinh dưỡng. Ưu tiên danh mục; số liệu AI chỉ là ước tính. Bạn kiểm tra món, khẩu phần và xác nhận trước khi lưu.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 16),
      if (_bytes case final bytes?)
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(bytes, height: 260, fit: BoxFit.cover),
        )
      else
        Container(
          height: 220,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_search_rounded, size: 56),
              SizedBox(height: 8),
              Text('Chỉ chọn ảnh món ăn'),
            ],
          ),
        ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : widget.embedded
                ? () => setState(() {
                    _bytes = null;
                    _suggestion = null;
                  })
                : () => _pick(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Chụp ảnh'),
          ),
          OutlinedButton.icon(
            onPressed: busy ? null : () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Chọn ảnh'),
          ),
          FilledButton.icon(
            key: const ValueKey('analyze-food-image'),
            onPressed:
                _bytes == null ||
                    busy ||
                    !_acceptedProcessing ||
                    !access.allowed
                ? null
                : _analyze,
            icon: _loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(_loading ? 'Đang phân tích…' : 'Phân tích'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      const Text(
        'Khi bạn bấm Phân tích, ảnh được gửi đến dịch vụ AI của Google. Dịch vụ miễn phí có thể dùng ảnh và kết quả để cải thiện sản phẩm, có thể có người đánh giá nội dung. Không chọn ảnh có mặt người, giấy tờ hoặc thông tin riêng tư. HealthMate không tải ảnh gốc lên kho lưu trữ; camera/thư viện có thể giữ tệp tạm trên thiết bị.',
      ),
      CheckboxListTile(
        key: const ValueKey('scanner-processing-consent'),
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Ảnh chỉ có món ăn, không có thông tin cá nhân; tôi đồng ý gửi ảnh để phân tích.',
        ),
        value: _acceptedProcessing,
        onChanged: busy || _bytes == null
            ? null
            : (value) => setState(() => _acceptedProcessing = value ?? false),
      ),
      if (!access.allowed) Text(access.message),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      if (suggestion != null) ...[
        const Divider(height: 40),
        TextField(
          key: const ValueKey('scanner-dish-name'),
          controller: _nameController,
          maxLength: 80,
          decoration: const InputDecoration(
            labelText: 'Tên món — hãy sửa nếu nhận diện chưa đúng',
            prefixIcon: Icon(Icons.edit_outlined),
          ),
          onChanged: (_) => setState(() {
            _selected = null;
            _savedFood = null;
            _newFoodId = null;
          }),
        ),
        const SizedBox(height: 8),
        Text(suggestion.description),
        if (suggestion.ingredients.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Có thể gồm: ${suggestion.ingredients.join(', ')}'),
        ],
        if (suggestion.isFood) ...[
          const SizedBox(height: 16),
          _nutritionDetails(suggestion),
        ] else
          const Text(
            'Không nhận diện được món ăn. Chụp/chọn ảnh khác hoặc tiếp tục nhập thủ công.',
          ),
        const SizedBox(height: 20),
        Text(
          'Món trùng tên trong danh mục',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (matches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Chưa có món trùng tên cho cả phần ăn. Giữ ước tính AI; bạn có thể kiểm tra và lưu vào Món của tôi hoặc nhập thủ công.',
            ),
          )
        else ...[
          const Text(
            'Chỉ chọn nếu đúng toàn bộ món và cách chế biến. Không dùng một nguyên liệu thay cho cả đĩa; gram bên trên áp dụng cho món được chọn.',
          ),
          RadioGroup<FoodCatalogItem>(
            groupValue: _selected,
            onChanged: (value) => setState(() => _selected = value),
            child: Column(
              children: [
                for (final food in matches)
                  RadioListTile<FoodCatalogItem>(
                    value: food,
                    title: Text(food.name),
                    subtitle: Text(
                      '${food.nutritionPer100g.kcal.toStringAsFixed(0)} kcal / 100 g',
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (suggestion.isFood && _savedFood == null) ...[
          OutlinedButton.icon(
            key: const ValueKey('scanner-save-food'),
            onPressed: busy ? null : _saveRecognizedFood,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Kiểm tra và lưu vào Món của tôi'),
          ),
          const Text(
            'Nếu danh mục chưa có đúng món, kiểm tra/sửa số liệu rồi Lưu. Món chỉ thuộc thư viện tài khoản của bạn.',
          ),
          const SizedBox(height: 12),
        ],
        if (_savedFood != null)
          const Text('Đã lưu vào Món của tôi. Bữa ăn chưa được ghi nhật ký.'),
        FilledButton.icon(
          onPressed:
              busy ||
                  (_selected != null &&
                      NutritionValidation.grams(_gramsController.text) != null)
              ? null
              : _confirm,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(
            _selected == null
                ? 'Tiếp tục nhập thủ công'
                : 'Xác nhận món đã chọn',
          ),
        ),
      ],
    ],
  );
}
