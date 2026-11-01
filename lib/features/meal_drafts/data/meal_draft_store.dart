import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/private_local_data.dart';
import '../../nutrition/models/nutrition_models.dart';

final privateLocalDataProvider = Provider<PrivateLocalData>(
  (ref) => PrivateLocalData(),
);
final mealDraftStoreProvider = Provider<MealDraftStore>(
  (ref) => MealDraftStore(ref.watch(privateLocalDataProvider)),
);

class SavedMealDraft {
  const SavedMealDraft({
    required this.operationId,
    required this.draft,
    required this.updatedAt,
    this.mealId,
  });
  final String operationId;
  final String? mealId;
  final MealDraft draft;
  final DateTime updatedAt;
  Map<String, Object?> toJson() => {
    'id': operationId,
    'mealId': mealId,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'type': draft.type.name,
    'at': draft.consumedAt.toUtc().toIso8601String(),
    'offset': draft.timezoneOffsetMinutes,
    'day': draft.dateKey,
    'source': draft.source.name,
    'minimumSchema': draft.minimumSchemaVersion,
    'items': [for (final i in draft.items) i.toData()],
  };
  factory SavedMealDraft.fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String;
    final mealId = j['mealId'] as String?;
    final offset = j['offset'] as int;
    final minimum = j['minimumSchema'] as int;
    final items = (j['items'] as List)
        .map(
          (i) => MealItemSnapshot.fromData(
            Map<String, dynamic>.from(i as Map),
            allowPartial: true,
          ),
        )
        .toList();
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(id) ||
        (mealId != null &&
            !RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(mealId)) ||
        offset < -720 ||
        offset > 840 ||
        minimum < 2 ||
        minimum > 5 ||
        items.length > 5) {
      throw const FormatException('Bản nháp không hợp lệ.');
    }
    for (final i in items) {
      i.withQuantity(i.quantity);
    }
    final draft = MealDraft(
      type: MealType.values.byName(j['type'] as String),
      consumedAt: DateTime.parse(j['at'] as String).toLocal(),
      items: items,
      source: MealSource.values.byName(j['source'] as String),
      minimumSchemaVersion: minimum,
      timezoneOffsetOverride: offset,
    );
    if (draft.dateKey != j['day']) {
      throw const FormatException('Ngày nháp không khớp.');
    }
    return SavedMealDraft(
      operationId: id,
      mealId: mealId,
      draft: draft,
      updatedAt: DateTime.parse(j['updatedAt'] as String).toUtc(),
    );
  }
}

/// A single serialized queue prevents read/modify/write races, including cleanup.
/// Native writes use AtomicFile + AES-GCM. No silent eviction of live drafts.
class MealDraftStore {
  MealDraftStore(this.local, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final PrivateLocalData local;
  final DateTime Function() now;
  Future<void> _tail = Future.value();
  final _blocked = <String>{};
  Future<T> _serial<T>(Future<T> Function() action) {
    final next = _tail.then((_) => action());
    _tail = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return next;
  }

  Future<List<SavedMealDraft>> _read(String uid) async {
    final raw = await local.read(uid);
    if (raw == null) return [];
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['schema'] != 1 || json['uid'] != uid) {
      throw const FormatException('Không đọc được nháp của tài khoản này.');
    }
    final all = (json['drafts'] as List)
        .map(
          (j) => SavedMealDraft.fromJson(Map<String, dynamic>.from(j as Map)),
        )
        .toList();
    if (all.length > 20 ||
        all.map((d) => d.operationId).toSet().length != all.length) {
      throw const FormatException('Danh sách nháp không hợp lệ.');
    }
    final cutoff = now().toUtc().subtract(const Duration(days: 7));
    final live = all.where((d) => !d.updatedAt.isBefore(cutoff)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (live.length != all.length) await _write(uid, live);
    return live;
  }

  Future<void> _write(String uid, List<SavedMealDraft> drafts) async {
    if (_blocked.contains(uid)) throw StateError('Tài khoản đang được xóa.');
    final previous = await _envelope(uid);
    final raw = jsonEncode({
      'schema': 1,
      'uid': uid,
      'drafts': [for (final d in drafts) d.toJson()],
      if (previous['onboarding'] != null) 'onboarding': previous['onboarding'],
    });
    if (utf8.encode(raw).length > 512 * 1024) {
      throw StateError('Nháp quá lớn; hãy bỏ các nháp không cần thiết.');
    }
    await local.write(uid, raw);
  }

  Future<Map<String, dynamic>> _envelope(String uid) async {
    final raw = await local.read(uid);
    if (raw == null) return {'schema': 1, 'uid': uid, 'drafts': []};
    final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    if (data['schema'] != 1 || data['uid'] != uid) {
      throw const FormatException('Không đọc được nháp của tài khoản này.');
    }
    return data;
  }

  Future<Map<String, dynamic>?> readOnboarding(String uid) => _serial(() async {
    final value = (await _envelope(uid))['onboarding'];
    return value == null ? null : Map<String, dynamic>.from(value as Map);
  });

  /// Shares the encrypted UID envelope and queue with meal drafts, so neither
  /// form can overwrite the other's data. Account deletion clears both.
  Future<void> writeOnboarding(String uid, Map<String, Object?>? value) =>
      _serial(() async {
        if (_blocked.contains(uid)) {
          throw StateError('Tài khoản đang được xóa.');
        }
        final envelope = await _envelope(uid);
        if (value == null) {
          envelope.remove('onboarding');
        } else {
          envelope['onboarding'] = value;
        }
        final raw = jsonEncode(envelope);
        if (utf8.encode(raw).length > 512 * 1024) {
          throw StateError('Nháp quá lớn; hãy bỏ các nháp không cần thiết.');
        }
        await local.write(uid, raw);
      });

  Future<List<SavedMealDraft>> list(String uid) => _serial(() => _read(uid));
  Future<void> put(String uid, SavedMealDraft draft) => _serial(() async {
    // Round trip validates the same contract used after a process restart.
    SavedMealDraft.fromJson(draft.toJson());
    final all = await _read(uid);
    all.removeWhere((d) => d.operationId == draft.operationId);
    if (all.length >= 20) {
      throw StateError('Đã có 20 nháp; hãy bỏ nháp cũ trước.');
    }
    all.add(draft);
    await _write(uid, all);
  });
  Future<void> remove(String uid, String id) => _serial(() async {
    final all = (await _read(uid))..removeWhere((d) => d.operationId == id);
    await _write(uid, all);
  });
  Future<void> clearForAccountDeletion(String uid) {
    _blocked.add(
      uid,
    ); // Prevent queued/late form writes from recreating deleted data.
    return _serial(() async {
      await local.clearForDeletion(uid);
      // Keep this UID blocked for the lifetime of this store, including late
      // callbacks from a disposed form. A failed Auth deletion can retry clear.
    });
  }
}
