import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/local_date_key.dart';
import '../models/nutrition_target.dart';
import 'nutrition_target_repository.dart';

class FirebaseNutritionTargetRepository implements NutritionTargetRepository {
  FirebaseNutritionTargetRepository(this.firestore, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final FirebaseFirestore firestore;
  final DateTime Function() now;
  CollectionReference<Map<String, dynamic>> _targets(String uid) =>
      firestore.collection('users').doc(uid).collection('nutrition_targets');

  @override
  Future<NutritionTarget?> loadForDay(String uid, String dateKey) async {
    if (!isValidDateKey(dateKey)) {
      throw const NutritionTargetFailure('Ngày cần xem không hợp lệ.');
    }
    try {
      final data = await _targets(uid)
          .where('effectiveFromDateKey', isLessThanOrEqualTo: dateKey)
          .orderBy('effectiveFromDateKey', descending: true)
          .limit(1)
          .get(const GetOptions(source: Source.server));
      if (data.docs.isEmpty) return null;
      return _parse(data.docs.single);
    } on FirebaseException {
      throw const NutritionTargetFailure(
        'Chưa tải được mục tiêu từ máy chủ. Kiểm tra kết nối/quyền truy cập rồi thử lại.',
      );
    } catch (_) {
      throw const NutritionTargetFailure(
        'Dữ liệu mục tiêu không hợp lệ; không thể dùng làm mục tiêu của ngày.',
      );
    }
  }

  NutritionTarget _parse(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    const requiredKeys = [
      'effectiveFromDateKey',
      'kcalTarget',
      'proteinGTarget',
      'carbsGTarget',
      'fatGTarget',
      'source',
      'schemaVersion',
      'createdAt',
      'updatedAt',
    ];
    if (!requiredKeys.every(d.containsKey) ||
        d['effectiveFromDateKey'] != doc.id ||
        d['source'] != 'user_manual' ||
        d['schemaVersion'] != 1 ||
        d['createdAt'] is! Timestamp ||
        d['updatedAt'] is! Timestamp) {
      throw const FormatException();
    }
    final target = NutritionTarget(
      effectiveFromDateKey: d['effectiveFromDateKey'] as String,
      kcalTarget: (d['kcalTarget'] as num).toDouble(),
      proteinGTarget: (d['proteinGTarget'] as num?)?.toDouble(),
      carbsGTarget: (d['carbsGTarget'] as num?)?.toDouble(),
      fatGTarget: (d['fatGTarget'] as num?)?.toDouble(),
      saltGLimit: (d['saltGLimit'] as num?)?.toDouble(),
      sugarGLimit: (d['sugarGLimit'] as num?)?.toDouble(),
      fiberGTarget: (d['fiberGTarget'] as num?)?.toDouble(),
    );
    if (target.validate() != null) throw const FormatException();
    return target;
  }

  @override
  Future<List<NutritionTarget>> loadForRange(
    String uid,
    String startKey,
    String endKey,
  ) async {
    if (!isValidDateKey(startKey) || !isValidDateKey(endKey)) {
      throw const NutritionTargetFailure('Khoảng ngày không hợp lệ.');
    }
    // Calendar days, independent of DST or a device UTC offset.
    final start = DateTime.parse('${startKey}T00:00:00Z');
    final end = DateTime.parse('${endKey}T00:00:00Z');
    final days = end.difference(start).inDays;
    if (days < 1 || days > 90) {
      throw const NutritionTargetFailure('Chỉ tải tối đa 90 ngày mỗi lần.');
    }
    try {
      final results = await (
        _targets(uid)
            .where('effectiveFromDateKey', isLessThanOrEqualTo: startKey)
            .orderBy('effectiveFromDateKey', descending: true)
            .limit(1)
            .get(const GetOptions(source: Source.server)),
        _targets(uid)
            .where('effectiveFromDateKey', isGreaterThan: startKey)
            .where('effectiveFromDateKey', isLessThan: endKey)
            .orderBy('effectiveFromDateKey')
            .limit(90)
            .get(const GetOptions(source: Source.server)),
      ).wait;
      return [...results.$1.docs, ...results.$2.docs].map(_parse).toList();
    } on FirebaseException {
      throw const NutritionTargetFailure(
        'Chưa tải được mục tiêu cho khoảng ngày từ máy chủ. Hãy thử lại.',
      );
    } catch (_) {
      throw const NutritionTargetFailure(
        'Dữ liệu mục tiêu cho khoảng ngày không hợp lệ.',
      );
    }
  }

  @override
  Future<void> save(String uid, NutritionTarget target) async {
    final error = target.validate(earliestDateKey: localDateKey(now()));
    if (error != null) throw NutritionTargetFailure(error);
    try {
      final reference = _targets(uid).doc(target.effectiveFromDateKey);
      await firestore.runTransaction((transaction) async {
        final existing = await transaction.get(reference);
        final data = <String, dynamic>{
          'effectiveFromDateKey': target.effectiveFromDateKey,
          'kcalTarget': target.kcalTarget,
          'proteinGTarget': target.proteinGTarget,
          'carbsGTarget': target.carbsGTarget,
          'fatGTarget': target.fatGTarget,
          'saltGLimit': target.saltGLimit,
          'sugarGLimit': target.sugarGLimit,
          'fiberGTarget': target.fiberGTarget,
          'source': 'user_manual',
          'schemaVersion': 1,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (existing.exists) {
          transaction.update(reference, data);
        } else {
          transaction.set(reference, {
            ...data,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });
      // Confirm the actual server value. In the web SDK emulator test, a
      // transaction could complete while disableNetwork blocked normal reads.
      // A completed callback alone must never close the form as a saved target.
      final confirmed = await reference.get(
        const GetOptions(source: Source.server),
      );
      final data = confirmed.data();
      if (!confirmed.exists ||
          confirmed.metadata.isFromCache ||
          confirmed.metadata.hasPendingWrites ||
          data?['kcalTarget'] != target.kcalTarget ||
          data?['proteinGTarget'] != target.proteinGTarget ||
          data?['carbsGTarget'] != target.carbsGTarget ||
          data?['fatGTarget'] != target.fatGTarget ||
          data?['saltGLimit'] != target.saltGLimit ||
          data?['sugarGLimit'] != target.sugarGLimit ||
          data?['fiberGTarget'] != target.fiberGTarget) {
        throw const NutritionTargetFailure(
          'Chưa xác nhận được đúng nội dung mục tiêu trên máy chủ. Bản nháp được giữ để thử lại.',
        );
      }
    } on FirebaseException {
      throw const NutritionTargetFailure(
        'Máy chủ chưa xác nhận lưu mục tiêu. Hãy kiểm tra kết nối và thử lại.',
      );
    }
  }
}
