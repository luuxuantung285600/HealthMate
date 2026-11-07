import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/data/bounded_range.dart';

import '../../../core/utils/local_date_key.dart';
import '../models/nutrition_failure.dart';
import '../models/nutrition_models.dart';
import '../models/catalog_food_reader.dart';
import '../models/food_catalog_search.dart';
import 'nutrition_repository.dart';
import '../models/food_visibility.dart';
import 'meal_document.dart';
import 'meal_query_mode.dart';
import 'bundled_vietnamese_foods.dart';

class FirebaseNutritionRepository implements NutritionRepository {
  FirebaseNutritionRepository(
    this._firestore, {
    Future<List<FoodCatalogItem>> Function()? catalogLoader,
    this.onQueryRead,
  }) : _catalogLoader = catalogLoader ?? loadBundledVietnameseFoods;

  final FirebaseFirestore _firestore;
  final Future<List<FoodCatalogItem>> Function() _catalogLoader;

  /// Optional aggregate-only instrumentation for emulator/diagnostics.
  final void Function(MealQueryRead read)? onQueryRead;

  Future<MealQueryMode> _queryMode(String uid) async {
    try {
      final marker = await _firestore
          .collection('users')
          .doc(uid)
          .collection('data_migrations')
          .doc('meal_date_key_v1')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 3));
      onQueryRead?.call(
        MealQueryRead(
          branch: 'migration-marker',
          documentCount: marker.exists ? 1 : 0,
          fromCache: false,
        ),
      );
      final data = marker.data();
      if (data?['schemaVersion'] != 1 || data?['verifiedAt'] is! Timestamp) {
        return MealQueryMode.compatibility;
      }
      return switch (data?['state']) {
        'partitioned' => MealQueryMode.partitioned,
        'complete' => MealQueryMode.complete,
        _ => MealQueryMode.compatibility,
      };
    } catch (_) {
      // An absent/unavailable marker is never proof legacy data was migrated.
      // Retain the old safe queries, including when viewing an offline diary.
      return MealQueryMode.compatibility;
    }
  }

  CollectionReference<Map<String, dynamic>> _meals(String uid) =>
      _firestore.collection('users').doc(uid).collection('meal_logs');

  @override
  Stream<FoodVisibility> watchFoodVisibility() => _firestore
      .collection('food_catalog')
      .where('isActive', isEqualTo: false)
      .snapshots()
      .map(
        (snapshot) => FoodVisibility(
          hiddenIds: snapshot.docs.map((doc) => doc.id).toSet(),
          hiddenFdcIds: snapshot.docs
              .map((doc) => doc.data()['fdcId'])
              .whereType<int>()
              .toSet(),
        ),
      );

  @override
  Stream<List<FoodCatalogItem>> watchFoodCatalog() async* {
    List<FoodCatalogItem> bundled = const [];
    try {
      // Local asset decoding runs in an isolate; a short network-style timeout
      // could discard the expanded catalog on a slower device.
      bundled = await _catalogLoader();
    } catch (_) {
      /* A missing bundle must not block the real server catalog. */
    }
    if (bundled.isNotEmpty) yield bundled;
    final bundledById = {for (final food in bundled) food.id: food};
    try {
      // Delegate cancellation to Firestore even while no new snapshot arrives.
      // An await-for generator can otherwise wait for the next event on exit.
      yield* _firestore
          .collection('food_catalog')
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
            final serverIds = snapshot.docs.map((d) => d.id).toSet();
            return [
              for (final doc in snapshot.docs)
                if (doc.data()['isActive'] != false)
                  readCatalogFood(
                    doc.id,
                    doc.data(),
                    updatedAt: _date(doc.data()['updatedAt']),
                    referenceFood: bundledById[doc.id],
                  ),
              for (final food in bundled)
                if (!serverIds.contains(food.id)) food,
            ]..sort(compareCatalogFoods);
          });
    } on FirebaseException catch (error) {
      if (bundled.isEmpty) throw NutritionFailure.fromCode(error.code);
    }
  }

  @override
  Stream<List<MealLog>> watchMealLogs(String uid, DateTime localDate) async* {
    final dateKey = localDateKey(localDate);
    final range = localDayRange(localDate);
    yield* _watchMealDay(uid, dateKey, range, await _queryMode(uid));
  }

  Stream<List<MealLog>> _watchMealDay(
    String uid,
    String dateKey,
    LocalDayRange legacyRange,
    MealQueryMode mode,
  ) {
    late StreamController<List<MealLog>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? currentSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? legacySub;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? currentDocs;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? legacyDocs =
        mode == MealQueryMode.complete ? const [] : null;

    void emitWhenReady() {
      if (currentDocs == null || legacyDocs == null || controller.isClosed) {
        return;
      }
      final byId = <String, MealLog>{
        for (final doc in currentDocs!) doc.id: _meal(doc.id, doc.data()),
      };
      for (final doc in legacyDocs!) {
        final data = doc.data();
        if (mode == MealQueryMode.compatibility && data['dateKey'] is String) {
          continue;
        }
        byId.putIfAbsent(doc.id, () => _meal(doc.id, data));
      }
      final meals = byId.values.toList(growable: false)
        ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));
      controller.add(meals);
    }

    void addError(Object error, StackTrace stack) {
      if (controller.isClosed) return;
      controller.addError(
        error is FirebaseException
            ? NutritionFailure.fromCode(error.code)
            : NutritionFailure.fromCode('unknown'),
        stack,
      );
    }

    controller = StreamController<List<MealLog>>(
      onListen: () {
        Query<Map<String, dynamic>> currentQuery = _meals(
          uid,
        ).where('dateKey', isEqualTo: dateKey);
        if (mode == MealQueryMode.partitioned) {
          currentQuery = currentQuery.where(
            'queryPartition',
            isEqualTo: 'current',
          );
        }
        currentSub = currentQuery.snapshots().listen((snapshot) {
          currentDocs = snapshot.docs;
          onQueryRead?.call(
            MealQueryRead(
              branch: 'current',
              documentCount: snapshot.docs.length,
              fromCache: snapshot.metadata.isFromCache,
            ),
          );
          emitWhenReady();
        }, onError: addError);
        if (mode == MealQueryMode.complete) return;
        Query<Map<String, dynamic>> legacyQuery = _meals(uid)
            .where(
              'consumedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(legacyRange.start),
            )
            .where(
              'consumedAt',
              isLessThan: Timestamp.fromDate(legacyRange.end),
            )
            .orderBy('consumedAt', descending: true);
        if (mode == MealQueryMode.partitioned) {
          legacyQuery = legacyQuery.where(
            'queryPartition',
            isEqualTo: 'legacy',
          );
        }
        legacySub = legacyQuery.snapshots().listen((snapshot) {
          legacyDocs = snapshot.docs;
          onQueryRead?.call(
            MealQueryRead(
              branch: 'legacy',
              documentCount: snapshot.docs.length,
              fromCache: snapshot.metadata.isFromCache,
            ),
          );
          emitWhenReady();
        }, onError: addError);
      },
      onCancel: () async {
        await currentSub?.cancel();
        await legacySub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Stream<RecentMealPage> watchRecentMeals(String uid, {int limit = 20}) async* {
    try {
      await for (final snapshot
          in _meals(uid)
              .orderBy('consumedAt', descending: true)
              .limit(limit)
              .snapshots(includeMetadataChanges: true)) {
        if (snapshot.metadata.hasPendingWrites) continue;
        yield RecentMealPage(
          meals: [for (final doc in snapshot.docs) _meal(doc.id, doc.data())],
          fromCache: snapshot.metadata.isFromCache,
        );
      }
    } on FirebaseException catch (error) {
      throw NutritionFailure.fromCode(error.code);
    }
  }

  @override
  Future<List<MealLog>> loadRange(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final mode = await _queryMode(uid);
      Query<Map<String, dynamic>> currentQuery = _meals(uid)
          .where('dateKey', isGreaterThanOrEqualTo: localDateKey(start))
          .where('dateKey', isLessThan: localDateKey(end));
      Query<Map<String, dynamic>> legacyQuery = _meals(uid)
          .where(
            'consumedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('consumedAt', isLessThan: Timestamp.fromDate(end));
      if (mode == MealQueryMode.partitioned) {
        currentQuery = currentQuery.where(
          'queryPartition',
          isEqualTo: 'current',
        );
        legacyQuery = legacyQuery.where('queryPartition', isEqualTo: 'legacy');
      }
      final currentFuture = readBoundedRange(currentQuery, start, end);
      final snapshots = await (
        currentFuture,
        mode == MealQueryMode.complete
            ? Future<QuerySnapshot<Map<String, dynamic>>?>.value(null)
            : readBoundedRange(legacyQuery, start, end),
      ).wait;
      onQueryRead?.call(
        MealQueryRead(
          branch: 'current',
          documentCount: snapshots.$1.docs.length,
          fromCache: false,
        ),
      );
      if (snapshots.$2 != null) {
        onQueryRead?.call(
          MealQueryRead(
            branch: 'legacy',
            documentCount: snapshots.$2!.docs.length,
            fromCache: false,
          ),
        );
      }
      final byId = <String, MealLog>{
        for (final doc in snapshots.$1.docs) doc.id: _meal(doc.id, doc.data()),
      };
      for (final doc
          in snapshots.$2?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
        if (mode == MealQueryMode.compatibility &&
            doc.data()['dateKey'] is String) {
          continue;
        }
        byId.putIfAbsent(doc.id, () => _meal(doc.id, doc.data()));
      }
      return byId.values.toList()
        ..sort((a, b) => a.consumedAt.compareTo(b.consumedAt));
    } on FirebaseException catch (error) {
      throw NutritionFailure.fromCode(error.code);
    }
  }

  @override
  String newMealId() => _firestore.collection('users').doc().id;

  @override
  Future<String> addMeal({
    required String uid,
    required MealDraft draft,
    String? operationId,
  }) => _guard(() async {
    final ref = _meals(uid).doc(operationId);
    final data = mealDocumentData(draft);
    if (operationId == null) {
      await ref.set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.runTransaction((transaction) async {
        final previous = await transaction.get(ref);
        if (previous.exists) {
          if (!sameMealPayload(data, previous.data())) {
            throw const NutritionFailure(
              'Thao tác trước đã lưu nội dung khác. Hãy đóng form, tải lại bữa và chọn Sửa.',
            );
          }
          return;
        }
        transaction.set(ref, {
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      final confirmed = await ref.get(const GetOptions(source: Source.server));
      if (!confirmed.exists ||
          confirmed.metadata.hasPendingWrites ||
          confirmed.metadata.isFromCache ||
          !sameMealPayload(data, confirmed.data())) {
        throw const NutritionFailure(
          'Chưa xác nhận được đúng bữa trên máy chủ; bản nháp vẫn được giữ.',
        );
      }
    }
    return ref.id;
  });

  @override
  Future<void> updateMeal({
    required String uid,
    required String mealId,
    required MealDraft draft,
  }) => _guard(
    () => _meals(uid).doc(mealId).update({
      ...mealDocumentData(draft),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> deleteMeal({
    required String uid,
    required String mealId,
  }) => _guard(() async {
    final meal = _meals(uid).doc(mealId);
    // Reserved deterministic IDs identify one plan directly; never scan plans.
    final planId =
        RegExp(
          r'^plan-\d{4}-\d{2}-\d{2}-(breakfast|lunch|dinner|snack)$',
        ).hasMatch(mealId)
        ? mealId.substring(5)
        : null;
    final plan = planId == null
        ? null
        : _firestore
              .collection('users')
              .doc(uid)
              .collection('meal_plans')
              .doc(planId);
    await _firestore.runTransaction((transaction) async {
      final previous = await transaction.get(meal);
      final planned = plan == null ? null : await transaction.get(plan);
      if (planned?.data()?['loggedMealId'] == mealId) {
        transaction.update(plan!, {
          'loggedMealId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (previous.exists) transaction.delete(meal);
    });
  });

  MealLog _meal(String id, Map<String, dynamic> data) {
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .map(
          (item) => data['schemaVersion'] == 5
              ? MealItemSnapshot.fromCompactData(item)
              : MealItemSnapshot.fromData(
                  item,
                  allowPartial: [3, 4, 5].contains(data['schemaVersion']),
                ),
        )
        .toList(growable: false);
    final snapshotTotals = sumNutritionTotals(items.map((i) => i.nutrition));
    return MealLog(
      id: id,
      type:
          MealType.values
              .where((value) => value.name == data['mealType'])
              .firstOrNull ??
          MealType.snack,
      consumedAt: _date(data['consumedAt']) ?? DateTime.now(),
      items: items,
      totals: [3, 4, 5].contains(data['schemaVersion'])
          ? snapshotTotals
          : NutritionTotals(
              kcal: _number(data['totalKcal']),
              proteinG: _number(data['totalProteinG']),
              carbsG: _number(data['totalCarbsG']),
              fatG: _number(data['totalFatG']),
              fiberG: snapshotTotals.fiberG,
              fiberKnown: snapshotTotals.fiberKnown,
              extraNutrients: snapshotTotals.extraNutrients,
            ),
      source: data['source'] == 'ai_assisted'
          ? MealSource.aiAssisted
          : MealSource.manual,
      dateKey: data['dateKey'] as String?,
      timezoneOffsetMinutes: (data['timezoneOffsetMinutes'] as num?)?.toInt(),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      schemaVersion: (data['schemaVersion'] as num?)?.toInt() ?? 2,
    );
  }

  double _number(Object? value) => value is num ? value.toDouble() : 0;

  DateTime? _date(Object? value) => switch (value) {
    Timestamp timestamp => timestamp.toDate(),
    DateTime date => date,
    _ => null,
  };

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on NutritionFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw NutritionFailure.fromCode(error.code);
    } catch (_) {
      throw NutritionFailure.fromCode('unknown');
    }
  }
}
