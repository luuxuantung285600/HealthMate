import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../utils/local_date_key.dart';
import 'bounded_range.dart';
import 'user_data_revision.dart';

/// A shared listener only for a source/range currently visible in the UI.
/// The server revision worker can replace these listeners in a future build.
typedef PrivateDataScope = ({
  String collection,
  String field,
  Object? lower,
  Object? upper,
  bool lowerInclusive,
  bool upperInclusive,
  bool descending,
  int maxRecords,
  String? documentId,
});

PrivateDataScope _scope(
  String collection,
  String field, {
  Object? lower,
  Object? upper,
  bool lowerInclusive = true,
  bool upperInclusive = false,
  bool descending = false,
  int maxRecords = 2000,
  String? documentId,
}) => (
  collection: collection,
  field: field,
  lower: lower,
  upper: upper,
  lowerInclusive: lowerInclusive,
  upperInclusive: upperInclusive,
  descending: descending,
  maxRecords: maxRecords,
  documentId: documentId,
);

List<PrivateDataScope> privateRangeScopes(
  String collection,
  DateTime start,
  DateTime end,
) {
  calendarRangeDays(start, end);
  final first = localDateKey(start), last = localDateKey(end);
  return switch (collection) {
    'meal_logs' => [
      _scope(collection, 'dateKey', lower: first, upper: last),
      // Includes legacy logs without dateKey and catches timestamp moves.
      _scope(
        collection,
        'consumedAt',
        lower: Timestamp.fromDate(start),
        upper: Timestamp.fromDate(end),
      ),
    ],
    'water_logs' || 'activity_logs' || 'day_reviews' => [
      _scope(
        collection,
        'dateKey',
        lower: first,
        upper: last,
        maxRecords: collection == 'day_reviews' ? 90 : 2000,
      ),
    ],
    'body_metrics' || 'sleep_logs' => [
      _scope(
        collection,
        collection == 'body_metrics' ? 'measuredAt' : 'endedAt',
        lower: Timestamp.fromDate(start),
        upper: Timestamp.fromDate(end),
      ),
    ],
    'nutrition_targets' => [
      privateTargetScope(first),
      _scope(
        collection,
        'effectiveFromDateKey',
        lower: first,
        upper: last,
        lowerInclusive: false,
        maxRecords: 90,
      ),
    ],
    _ => throw ArgumentError.value(collection, 'collection'),
  };
}

PrivateDataScope privateTargetScope(String day) {
  if (!isValidDateKey(day)) throw const FormatException('Ngày chưa hợp lệ.');
  return _scope(
    'nutrition_targets',
    'effectiveFromDateKey',
    upper: day,
    upperInclusive: true,
    descending: true,
    maxRecords: 1,
  );
}

PrivateDataScope privateLibraryScope(String collection, String id) {
  if (!['custom_foods', 'recipes'].contains(collection) ||
      id.isEmpty ||
      id.contains('/')) {
    throw const FormatException('Nguồn món chưa hợp lệ.');
  }
  return _scope(collection, '', documentId: id, maxRecords: 1);
}

final privateDataChangesProvider = StreamProvider.autoDispose
    .family<int, PrivateDataScope>((ref, scope) {
      final user = ref.watch(authSessionProvider).value;
      if (user?.emailVerified != true || Firebase.apps.isEmpty) {
        return const Stream.empty();
      }
      final source = ref
          .watch(realtimeFirestoreProvider)
          .collection('users')
          .doc(user!.uid)
          .collection(scope.collection);
      var revision = 0, confirmed = false;
      if (scope.documentId != null) {
        return source
            .doc(scope.documentId)
            .snapshots(includeMetadataChanges: true)
            .where(
              (snapshot) =>
                  !snapshot.metadata.isFromCache &&
                  !snapshot.metadata.hasPendingWrites,
            )
            .map((snapshot) => ++revision);
      }
      Query<Map<String, dynamic>> query = source;
      if (scope.lower != null) {
        query = scope.lowerInclusive
            ? query.where(scope.field, isGreaterThanOrEqualTo: scope.lower)
            : query.where(scope.field, isGreaterThan: scope.lower);
      }
      if (scope.upper != null) {
        query = scope.upperInclusive
            ? query.where(scope.field, isLessThanOrEqualTo: scope.upper)
            : query.where(scope.field, isLessThan: scope.upper);
      }
      query = query
          .orderBy(scope.field, descending: scope.descending)
          .limit(
            scope.collection == 'nutrition_targets' && scope.descending
                ? 1
                : scope.maxRecords + 1,
          );
      return query
          .snapshots(includeMetadataChanges: true)
          .where((snapshot) {
            if (snapshot.metadata.isFromCache ||
                snapshot.metadata.hasPendingWrites) {
              confirmed = false;
              return false;
            }
            return true;
          })
          .where((snapshot) {
            final changed = !confirmed || snapshot.docChanges.isNotEmpty;
            confirmed = true;
            return changed;
          })
          .map((snapshot) {
            if (snapshot.size > scope.maxRecords) {
              throw const RangeReadFailure(
                'Quá nhiều bản ghi để đồng bộ khoảng đang xem. Hãy chọn khoảng ngắn hơn.',
              );
            }
            return ++revision;
          });
    }, retry: (_, _) => null);

void watchPrivateScope(Ref ref, PrivateDataScope scope) {
  if (ref.watch(serverRevisionSyncProvider)) return;
  final state = ref.watch(privateDataChangesProvider(scope));
  if (state.hasError) throw state.error!;
}

void watchPrivateRange(Ref ref, String source, DateTime start, DateTime end) {
  if (ref.watch(serverRevisionSyncProvider)) return;
  for (final scope in privateRangeScopes(source, start, end)) {
    watchPrivateScope(ref, scope);
  }
}
