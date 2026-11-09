import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/subscription_stream.dart';
import '../../../core/utils/local_date_key.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/data/meal_document.dart';
import '../models/wellness_models.dart';

enum _PlanRecordStatus { saved, deleted, changed, conflict }

class WellnessRepository {
  WellnessRepository(this.db);
  final FirebaseFirestore db;
  void _requireOwner(String uid) {
    final user = FirebaseAuth.instanceFor(app: db.app).currentUser;
    if (user?.uid != uid || user?.emailVerified != true) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message:
            'Không thể truy cập dữ liệu của tài khoản khác hoặc chưa xác minh.',
      );
    }
  }

  Stream<T> _owned<T>(String uid, Stream<T> Function() create) async* {
    _requireOwner(uid);
    yield* subscriptionStream(
      create().map((value) {
        _requireOwner(uid);
        return value;
      }),
    );
  }

  CollectionReference<Map<String, dynamic>> _collection(
    String uid,
    String name,
  ) {
    _requireOwner(uid);
    return db.collection('users').doc(uid).collection(name);
  }

  Stream<DateTime?> watchSleepStart(String uid) => _owned(
    uid,
    () => _collection(uid, 'wellness_state')
        .doc('sleep')
        .snapshots()
        .map((d) => (d.data()?['startedAt'] as Timestamp?)?.toDate()),
  );

  Stream<List<SleepLog>> watchSleepLogs(String uid) => _owned(
    uid,
    () => _collection(uid, 'sleep_logs')
        .orderBy('startedAt', descending: true)
        .limit(60)
        .snapshots()
        .map(
          (s) => [
            for (final d in s.docs)
              SleepLog(
                id: d.id,
                start: (d['startedAt'] as Timestamp).toDate(),
                end: (d['endedAt'] as Timestamp).toDate(),
                source: d['source'] as String,
              ),
          ],
        ),
  );

  Future<void> startSleep(String uid) async {
    final target = _collection(uid, 'wellness_state').doc('sleep');
    final started = await db.runTransaction<bool>((t) async {
      if ((await t.get(target)).exists) {
        return false;
      }
      t.set(target, {
        'startedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 1,
      });
      return true;
    });
    if (!started) {
      throw const FormatException(
        'Đã có lần ngủ đang chạy. Hãy kết thúc trước.',
      );
    }
  }

  Future<void> cancelSleep(String uid) =>
      _collection(uid, 'wellness_state').doc('sleep').delete();

  Future<void> saveSleep(
    String uid,
    DateTime start,
    DateTime end, {
    String? id,
    bool finishTimer = false,
    DateTime? expectedTimerStart,
  }) async {
    final error = SleepLog.validate(start, end, DateTime.now());
    if (error != null) throw FormatException(error);
    final active = _collection(uid, 'wellness_state').doc('sleep');
    // The active timestamp makes finishing the same timer idempotent.
    final target = _collection(uid, 'sleep_logs').doc(
      id ??
          (finishTimer
              ? 'timer-${(expectedTimerStart ?? start).millisecondsSinceEpoch}'
              : 'manual-${start.millisecondsSinceEpoch}-${end.millisecondsSinceEpoch}'),
    );
    final saved = await db.runTransaction<bool>((t) async {
      final previous = await t.get(target);
      final state = finishTimer ? await t.get(active) : null;
      if (finishTimer && !state!.exists) {
        return previous.exists;
      }
      if (finishTimer &&
          (state!.data()?['startedAt'] as Timestamp?)?.toDate() !=
              (expectedTimerStart ?? start)) {
        return false;
      }
      t.set(target, {
        'startedAt': Timestamp.fromDate(start),
        'endedAt': Timestamp.fromDate(end),
        'source': finishTimer ? 'manual_timer' : 'manual_entry',
        'createdAt': previous.exists
            ? previous['createdAt']
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 1,
      });
      if (finishTimer) t.delete(active);
      return true;
    });
    if (!saved) {
      throw const FormatException('Lần ngủ đã đổi hoặc đã hủy. Hãy tải lại.');
    }
  }

  Future<void> deleteSleep(String uid, String id) =>
      _collection(uid, 'sleep_logs').doc(id).delete();

  Future<List<SleepLog>> loadSleepRange(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    if (!end.isAfter(start) || end.difference(start).inDays > 31) {
      throw const FormatException('Chỉ tải tối đa 31 ngày giờ ngủ.');
    }
    final result = await _collection(uid, 'sleep_logs')
        .where('endedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('endedAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('endedAt')
        .limit(2001)
        .get(const GetOptions(source: Source.server));
    _requireOwner(uid);
    if (result.docs.length > 2000) {
      throw const FormatException(
        'Quá nhiều lần ghi; hãy chọn khoảng ngắn hơn.',
      );
    }
    return result.docs
        .map(
          (d) => SleepLog(
            id: d.id,
            start: (d['startedAt'] as Timestamp).toDate(),
            end: (d['endedAt'] as Timestamp).toDate(),
            source: d['source'] as String,
          ),
        )
        .toList();
  }

  Stream<List<PlannedMeal>> watchPlans(String uid, DateTime start) {
    final end = DateTime(start.year, start.month, start.day + 7);
    return _owned(
      uid,
      () => _collection(uid, 'meal_plans')
          .where('dateKey', isGreaterThanOrEqualTo: localDateKey(start))
          .where('dateKey', isLessThan: localDateKey(end))
          .orderBy('dateKey')
          .snapshots()
          .map((s) => [for (final d in s.docs) _plan(d.id, d.data())]),
    );
  }

  PlannedMeal _plan(String id, Map<String, dynamic> data) => PlannedMeal(
    id: id,
    date: DateTime.parse(data['dateKey'] as String),
    type: MealType.values.byName(data['mealType'] as String),
    items: (data['items'] as List)
        .map(
          (v) => MealItemSnapshot.fromCompactData(
            Map<String, dynamic>.from(v as Map),
          ),
        )
        .toList(),
    loggedMealId: data['loggedMealId'] as String?,
    createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
  );

  Future<PlannedMeal?> loadPlan(String uid, String id) async {
    final result = await _collection(
      uid,
      'meal_plans',
    ).doc(id).get(const GetOptions(source: Source.server));
    _requireOwner(uid);
    return result.exists ? _plan(result.id, result.data()!) : null;
  }

  Future<void> savePlan(String uid, MealDraft draft) async {
    if (draft.items.isEmpty || draft.items.length > 5) {
      throw const FormatException('Chọn từ 1 đến 5 món cho một bữa dự kiến.');
    }
    final id = '${draft.dateKey}-${draft.type.name}';
    final target = _collection(uid, 'meal_plans').doc(id);
    final meal = _collection(uid, 'meal_logs').doc('plan-$id');
    final saved = await db.runTransaction<bool>((t) async {
      final previous = await t.get(target);
      final recorded = await t.get(meal);
      _requireOwner(uid);
      if (recorded.exists) {
        if (previous.exists && previous.data()?['loggedMealId'] != meal.id) {
          t.update(target, {
            'loggedMealId': meal.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        return false;
      }
      t.set(target, {
        'dateKey': draft.dateKey,
        'mealType': draft.type.name,
        'items': draft.items.map((i) => i.toCompactData()).toList(),
        'createdAt': previous.exists
            ? previous['createdAt']
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 2,
      });
      return true;
    });
    if (!saved) {
      throw const FormatException(
        'Bữa này đã ghi nhật ký; hãy sửa tại Nhật ký.',
      );
    }
  }

  /// Suggestions fill gaps only. Replaying an unacknowledged create never
  /// replaces a meal that another device has since edited or recorded.
  Future<bool> addSuggestedPlan(String uid, MealDraft draft) async {
    if (draft.items.isEmpty || draft.items.length > 5) {
      throw const FormatException('Chọn từ 1 đến 5 món cho một bữa dự kiến.');
    }
    final id = '${draft.dateKey}-${draft.type.name}';
    final target = _collection(uid, 'meal_plans').doc(id);
    final meal = _collection(uid, 'meal_logs').doc('plan-$id');
    late final bool created;
    try {
      created = await db.runTransaction<bool>((transaction) async {
        final planned = await transaction.get(target);
        final recorded = await transaction.get(meal);
        _requireOwner(uid);
        if (planned.exists || recorded.exists) return false;
        transaction.set(target, {
          'dateKey': draft.dateKey,
          'mealType': draft.type.name,
          'items': draft.items.map((i) => i.toCompactData()).toList(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'schemaVersion': 2,
        });
        return true;
      });
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      // A concurrent create may be evaluated by Rules before transaction retry.
      // Confirm the winner using owner-authorized server reads, never the cache.
      _requireOwner(uid);
      const server = GetOptions(source: Source.server);
      final planned = await target.get(server);
      final recorded = await meal.get(server);
      _requireOwner(uid);
      if (!planned.exists && !recorded.exists) rethrow;
      return false;
    }
    _requireOwner(uid);
    return created;
  }

  Future<void> deletePlan(
    String uid,
    String id, {
    PlannedMeal? expected,
  }) async {
    if (expected != null &&
        (expected.id != id ||
            expected.createdAt == null ||
            expected.updatedAt == null)) {
      throw const FormatException('Kế hoạch chưa được xác nhận. Hãy tải lại.');
    }
    final target = _collection(uid, 'meal_plans').doc(id);
    final deleted = await db.runTransaction<bool>((transaction) async {
      final current = await transaction.get(target);
      _requireOwner(uid);
      if (!current.exists) {
        return true; // Safe retry after losing the delete ACK.
      }
      final data = current.data()!;
      if (expected != null &&
          ((data['createdAt'] as Timestamp?)?.toDate() != expected.createdAt ||
              (data['updatedAt'] as Timestamp?)?.toDate() !=
                  expected.updatedAt ||
              data['dateKey'] != localDateKey(expected.date) ||
              data['mealType'] != expected.type.name ||
              data['loggedMealId'] != expected.loggedMealId ||
              !sameDocumentValue(
                data['items'],
                expected.items.map((i) => i.toCompactData()).toList(),
              ))) {
        return false;
      }
      transaction.delete(target);
      return true;
    });
    _requireOwner(uid);
    if (!deleted) {
      throw const FormatException(
        'Kế hoạch đã thay đổi. Hãy đóng hộp thoại và kiểm tra lại trước khi xóa.',
      );
    }
  }

  /// Reconcile only this deterministic pair, including legacy split writes.
  /// A missing meal clears a dangling marker; an existing meal is never changed.
  Future<bool> existingPlanMeal(String uid, String id) async {
    final plan = _collection(uid, 'meal_plans').doc(id);
    final meal = _collection(uid, 'meal_logs').doc('plan-$id');
    return db.runTransaction<bool>((t) async {
      final planned = await t.get(plan);
      final recorded = await t.get(meal);
      _requireOwner(uid);
      if (planned.exists) {
        final link = planned.data()?['loggedMealId'];
        if (recorded.exists && link != meal.id) {
          t.update(plan, {
            'loggedMealId': meal.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else if (!recorded.exists && link != null) {
          t.update(plan, {
            'loggedMealId': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return recorded.exists;
    });
  }

  Future<void> markPlanLogged(String uid, String id) async {
    if (!await existingPlanMeal(uid, id)) {
      throw const FormatException('Chưa có bữa nhật ký để liên kết.');
    }
  }

  /// One transaction records the confirmed snapshot and links its plan.
  /// Replaying the same payload is safe; a different payload never overwrites it.
  Future<String> recordPlanMeal(
    String uid,
    PlannedMeal plan,
    MealDraft draft,
  ) async {
    if (plan.id != '${localDateKey(plan.date)}-${plan.type.name}' ||
        plan.createdAt == null ||
        plan.updatedAt == null) {
      throw const FormatException('Kế hoạch chưa được xác nhận. Hãy tải lại.');
    }
    final target = _collection(uid, 'meal_plans').doc(plan.id);
    final meal = _collection(uid, 'meal_logs').doc('plan-${plan.id}');
    final data = mealDocumentData(draft);
    Future<_PlanRecordStatus> record() => db.runTransaction<_PlanRecordStatus>((
      t,
    ) async {
      final planned = await t.get(target);
      final recorded = await t.get(meal);
      _requireOwner(uid);
      if (!planned.exists) {
        return _PlanRecordStatus.deleted;
      }
      final current = planned.data()!;
      if (recorded.exists) {
        if (!sameMealPayload(data, recorded.data())) {
          return _PlanRecordStatus.conflict;
        }
      } else {
        if ((current['createdAt'] as Timestamp?)?.toDate() != plan.createdAt ||
            (current['updatedAt'] as Timestamp?)?.toDate() != plan.updatedAt ||
            !sameDocumentValue(
              current['items'],
              plan.items.map((i) => i.toCompactData()).toList(),
            )) {
          return _PlanRecordStatus.changed;
        }
        t.set(meal, {
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (current['loggedMealId'] != meal.id) {
        t.update(target, {
          'loggedMealId': meal.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return _PlanRecordStatus.saved;
    });
    late final _PlanRecordStatus status;
    try {
      status = await record();
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      _requireOwner(uid);
      // A competing create can win before the emulator evaluates the losing
      // transaction's Rules, producing permission-denied before ABORTED. Only
      // retry when the server confirms the deterministic pair already exists.
      // The fresh transaction still checks ownership and the complete payload;
      // it never treats an authorization error itself as a successful save.
      const server = GetOptions(source: Source.server);
      final winner = await meal.get(server);
      final linked = await target.get(server);
      _requireOwner(uid);
      if (!winner.exists ||
          !linked.exists ||
          linked.data()?['loggedMealId'] != meal.id) {
        rethrow;
      }
      status = await record();
    }
    _requireOwner(uid);
    switch (status) {
      case _PlanRecordStatus.deleted:
        throw const FormatException('Kế hoạch đã bị xóa. Hãy tải lại.');
      case _PlanRecordStatus.changed:
        throw const FormatException(
          'Kế hoạch đã thay đổi. Hãy đóng form và tải lại.',
        );
      case _PlanRecordStatus.conflict:
        throw const FormatException(
          'Bữa đã có nội dung khác. Hãy xem hoặc sửa tại Nhật ký.',
        );
      case _PlanRecordStatus.saved:
        break;
    }
    return meal.id;
  }

  Stream<List<StepDay>> watchStepDays(String uid) => _owned(
    uid,
    () => _collection(uid, 'step_logs')
        .orderBy('dateKey', descending: true)
        .limit(30)
        .snapshots()
        .map(
          (s) => [
            for (final d in s.docs)
              StepDay(
                d['dateKey'] as String,
                d['steps'] as int,
                (d['trackingStartedAt'] as Timestamp).toDate(),
                (d['measuredAt'] as Timestamp).toDate(),
              ),
          ],
        ),
  );

  Future<void> syncSteps(String uid, Map<String, dynamic> data) async {
    final day = data['day'] as String;
    final steps = data['steps'] as int;
    if (!isValidDateKey(day) || steps < 0 || steps > 150000) {
      throw const FormatException('Dữ liệu bước chân chưa hợp lệ.');
    }
    final start = DateTime.fromMillisecondsSinceEpoch(data['startedAt'] as int);
    final measured = DateTime.fromMillisecondsSinceEpoch(
      data['measuredAt'] as int,
    );
    final target = _collection(uid, 'step_logs').doc(day);
    await db.runTransaction((transaction) async {
      final previous = await transaction.get(target);
      // Keep the highest device recording for the day; never add overlapping
      // phone measurements or let a stale/offline snapshot reduce the history.
      if (previous.exists && (previous['steps'] as int) >= steps) return;
      transaction.set(target, {
        'dateKey': day,
        'steps': steps,
        'timezoneOffsetMinutes': data['timezoneOffsetMinutes'],
        'trackingStartedAt': Timestamp.fromDate(start),
        'measuredAt': Timestamp.fromDate(measured),
        'updatedAt': FieldValue.serverTimestamp(),
        'source': 'device_step_counter',
        'schemaVersion': 1,
      });
    });
  }
}
