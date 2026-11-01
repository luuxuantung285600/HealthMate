import '../models/nutrition_models.dart';
import '../models/nutrition_validation.dart';

/// Form-owned draft state. This never writes Firestore or changes an operation ID;
/// repository callbacks retain ownership of persistence and idempotency.
class MealFormController {
  MealFormController({
    required this.type,
    required this.consumedAt,
    required Iterable<MealItemSnapshot> items,
    required this.source,
    this.minimumSchemaVersion = 2,
    this.timezoneOffsetOverride,
    this.onDraftChanged,
    this.onChanged,
    bool Function()? isCurrent,
  }) : items = [...items],
       isCurrent = isCurrent ?? (() => true);

  MealType type;
  DateTime consumedAt;
  final List<MealItemSnapshot> items;
  MealSource source;
  int minimumSchemaVersion;
  int? timezoneOffsetOverride;
  bool scannerAiUsed = false;
  Future<void> Function(MealDraft)? onDraftChanged;
  final void Function()? onChanged;
  final bool Function() isCurrent;
  String? localStatus;
  int _revision = 0;
  bool _disposed = false;
  bool _submitting = false;

  MealDraft get draft => MealDraft(
    minimumSchemaVersion: minimumSchemaVersion,
    type: type,
    consumedAt: consumedAt,
    items: List.unmodifiable(items),
    timezoneOffsetOverride: timezoneOffsetOverride,
    source: scannerAiUsed ? MealSource.aiAssisted : source,
  );

  bool get _current => !_disposed && isCurrent();
  void _publish() {
    if (_current) onChanged?.call();
  }

  Future<bool> persistLocal() async {
    if (onDraftChanged == null || !_current) return false;
    final revision = ++_revision;
    final snapshot = draft;
    localStatus = 'Đang giữ nháp…';
    _publish();
    try {
      await onDraftChanged!(snapshot);
      if (_current && revision == _revision) {
        localStatus = 'Đã giữ nháp trên thiết bị';
        _publish();
      }
      return _current && revision == _revision;
    } catch (_) {
      if (_current && revision == _revision) {
        localStatus = 'Chưa giữ được nháp. Hãy thử lại trước khi đóng.';
        _publish();
      }
      return false;
    }
  }

  /// Cheap checks precede the UI's explicit food-avoidance confirmation.
  String? entryError(DateTime now) {
    if (consumedAt.isAfter(now)) {
      return 'Thời điểm dùng bữa không thể ở tương lai.';
    }
    if (items.length > NutritionValidation.maxItemsPerMeal) {
      return 'Mỗi bản ghi tối đa 5 món. Bạn có thể thêm bản ghi khác cùng bữa.';
    }
    if (items.isEmpty) return 'Hãy chọn ít nhất một món ăn.';
    return null;
  }

  /// Snapshot validation runs after confirmation; it never repairs history.
  String? snapshotError() {
    try {
      for (final item in items) {
        item.withQuantity(item.quantity);
      }
    } on FormatException {
      return 'Snapshot món bị thiếu hoặc hỏng. Hãy bỏ món và thêm lại sau khi xác nhận nguồn.';
    }
    if (draft.totals.kcal > NutritionValidation.maxMealKcal) {
      return 'Tổng năng lượng vượt giới hạn hợp lệ.';
    }
    return null;
  }

  /// One outstanding ACK, without a client timeout or a second write on retry.
  Future<bool> submit(
    MealDraft snapshot,
    Future<bool> Function(MealDraft) persist,
  ) async {
    if (_submitting || !_current) return false;
    _submitting = true;
    try {
      final saved = await persist(snapshot);
      return _current && saved;
    } finally {
      _submitting = false;
    }
  }

  void dispose() {
    _disposed = true;
    _revision++;
  }
}
