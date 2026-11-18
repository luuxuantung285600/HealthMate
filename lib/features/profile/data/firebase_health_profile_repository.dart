import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/data/bounded_range.dart';
import '../../../core/utils/local_date_key.dart';

import '../models/body_metric.dart';
import '../models/health_goal.dart';
import '../models/onboarding_draft.dart';
import '../models/profile_failure.dart';
import '../models/user_profile.dart';
import '../models/personalization_answers.dart';
import '../models/profile_appearance.dart';
import '../models/profile_validation.dart';
import 'health_profile_repository.dart';

class FirebaseHealthProfileRepository implements HealthProfileRepository {
  FirebaseHealthProfileRepository(this._firestore, {this.onMetricQueryRead});

  final FirebaseFirestore _firestore;
  final void Function(BodyMetricQueryRead read)? onMetricQueryRead;

  DocumentReference<Map<String, dynamic>> _profile(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _metrics(String uid) =>
      _profile(uid).collection('body_metrics');

  @override
  Future<void> ensureProfile({required String uid, required String email}) =>
      _guard(() async {
        final reference = _profile(uid);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(reference);
          if (!snapshot.exists) {
            transaction.set(reference, {
              'displayName': '',
              'email': email,
              'heightCm': null,
              'birthDate': null,
              'healthGoal': null,
              'targetWeightKg': null,
              'onboardingCompletedAt': null,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'schemaVersion': 2,
            });
            return;
          }
          final data = snapshot.data();
          final updates = <String, Object?>{};
          if (data?['email'] != email) updates['email'] = email;
          if (data?['schemaVersion'] != 2) updates['schemaVersion'] = 2;
          for (final field in const [
            'birthDate',
            'healthGoal',
            'targetWeightKg',
            'onboardingCompletedAt',
          ]) {
            if (data?.containsKey(field) != true) updates[field] = null;
          }
          if (updates.isNotEmpty) {
            updates['updatedAt'] = FieldValue.serverTimestamp();
            transaction.update(reference, updates);
          }
        });
      });

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    try {
      await for (final snapshot in _profile(uid).snapshots()) {
        final data = snapshot.data();
        yield data == null ? null : _profileFromData(uid, data);
      }
    } on FirebaseException catch (error) {
      throw ProfileFailure.fromCode(error.code);
    } catch (_) {
      throw ProfileFailure.fromCode('unknown');
    }
  }

  @override
  Future<void> updateIdentity({
    required String uid,
    required ProfileIdentityDraft draft,
  }) => _guard(() {
    final error = ProfileValidation.displayName(draft.displayName);
    if (error != null) throw ProfileFailure(error);
    return _profile(uid).update({
      'displayName': draft.displayName.trim(),
      'profileAppearance': draft.appearance.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });

  @override
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required double heightCm,
    required DateTime birthDate,
    required String healthGoal,
    required double? targetWeightKg,
  }) => _guard(
    () => _profile(uid).update({
      'displayName': displayName.trim(),
      'heightCm': heightCm,
      'birthDate': Timestamp.fromDate(birthDate),
      'healthGoal': healthGoal,
      'targetWeightKg': targetWeightKg,
      'updatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': 2,
    }),
  );

  @override
  Future<void> completeOnboarding({
    required String uid,
    required OnboardingDraft draft,
  }) => _guard(() async {
    final profileReference = _profile(uid);
    final metricReference = _metrics(
      uid,
    ).doc(draft.isProfileEdit ? null : 'onboarding-current');
    await _firestore.runTransaction((transaction) async {
      final profileSnapshot = await transaction.get(profileReference);
      if (!profileSnapshot.exists) {
        throw const ProfileFailure('Không tìm thấy hồ sơ để thiết lập.');
      }
      final metricSnapshot = draft.recordCurrentWeight
          ? await transaction.get(metricReference)
          : null;
      transaction.update(profileReference, {
        'displayName': draft.displayName.trim(),
        'heightCm': draft.heightCm,
        'birthDate': Timestamp.fromDate(draft.birthDate),
        'healthGoal': draft.healthGoal.value,
        'targetWeightKg': draft.healthGoal.needsTargetWeight
            ? draft.targetWeightKg
            : null,
        'onboardingCompletedAt':
            profileSnapshot.data()?['onboardingCompletedAt'] ??
            FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 2,
        if (draft.personalization != null)
          'personalization': draft.personalization!
              .normalized(draft.healthGoal)
              .toMap(),
      });
      final metricData = <String, Object?>{
        'weightKg': draft.currentWeightKg,
        'measuredAt': FieldValue.serverTimestamp(),
        'note': draft.isProfileEdit
            ? 'Cân nặng khi cập nhật cá nhân hóa'
            : 'Cân nặng khi hoàn tất thiết lập ban đầu',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!draft.recordCurrentWeight) return;
      if (metricSnapshot!.exists) {
        transaction.update(metricReference, metricData);
      } else {
        transaction.set(metricReference, {
          ...metricData,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  });

  @override
  Stream<List<BodyMetric>> watchBodyMetrics(String uid) =>
      watchBodyMetricPage(uid).map((page) => page.metrics);

  @override
  Stream<BodyMetricPage> watchBodyMetricPage(
    String uid, {
    BodyMetricCursor? after,
    int pageSize = 25,
  }) async* {
    if (pageSize < 1 || pageSize > 100) {
      throw const ProfileFailure('Mỗi trang chỉ tải từ 1 đến 100 lần cân.');
    }
    try {
      Query<Map<String, dynamic>> query = _metrics(uid)
          .orderBy('measuredAt', descending: true)
          .orderBy(FieldPath.documentId, descending: true);
      if (after != null) {
        query = query.startAfter([
          Timestamp.fromDate(after.measuredAt),
          after.id,
        ]);
      }
      await for (final snapshot
          in query
              .limit(pageSize + 1)
              .snapshots(includeMetadataChanges: true)) {
        onMetricQueryRead?.call(
          BodyMetricQueryRead(
            branch: 'history-page',
            documentCount: snapshot.docs.length,
            fromCache: snapshot.metadata.isFromCache,
          ),
        );
        yield BodyMetricPage(
          metrics: [
            for (final document in snapshot.docs.take(pageSize))
              _metricFromData(document.id, document.data()),
          ],
          hasMore: snapshot.docs.length > pageSize,
        );
      }
    } on FirebaseException catch (error) {
      throw ProfileFailure.fromCode(error.code);
    } catch (_) {
      throw ProfileFailure.fromCode('unknown');
    }
  }

  @override
  Stream<List<BodyMetric>> watchFirstBodyMetric(String uid) async* {
    try {
      await for (final snapshot
          in _metrics(uid)
              .orderBy('measuredAt')
              .orderBy(FieldPath.documentId)
              .limit(1)
              .snapshots(includeMetadataChanges: true)) {
        onMetricQueryRead?.call(
          BodyMetricQueryRead(
            branch: 'first',
            documentCount: snapshot.docs.length,
            fromCache: snapshot.metadata.isFromCache,
          ),
        );
        yield [
          for (final doc in snapshot.docs) _metricFromData(doc.id, doc.data()),
        ];
      }
    } on FirebaseException catch (error) {
      throw ProfileFailure.fromCode(error.code);
    }
  }

  @override
  Stream<List<BodyMetric>> watchLatestBodyMetric(
    String uid,
    DateTime day, {
    bool atOrBefore = false,
  }) async* {
    try {
      await for (final snapshot
          in _metrics(uid)
              .where(
                'measuredAt',
                isLessThan: atOrBefore
                    ? null
                    : Timestamp.fromDate(localDayRange(day).end),
                isLessThanOrEqualTo: atOrBefore
                    ? Timestamp.fromDate(day)
                    : null,
              )
              .orderBy('measuredAt', descending: true)
              .limit(1)
              .snapshots(includeMetadataChanges: true)) {
        onMetricQueryRead?.call(
          BodyMetricQueryRead(
            branch: 'latest',
            documentCount: snapshot.docs.length,
            fromCache: snapshot.metadata.isFromCache,
          ),
        );
        yield [
          for (final doc in snapshot.docs) _metricFromData(doc.id, doc.data()),
        ];
      }
    } on FirebaseException catch (error) {
      throw ProfileFailure.fromCode(error.code);
    }
  }

  @override
  Future<List<BodyMetric>> loadBodyMetricsRange(
    String uid,
    DateTime start,
    DateTime end,
  ) => _guard(() async {
    final snapshot = await readBoundedRange(
      _metrics(uid)
          .where(
            'measuredAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('measuredAt', isLessThan: Timestamp.fromDate(end)),
      start,
      end,
    );
    onMetricQueryRead?.call(
      BodyMetricQueryRead(
        branch: 'range',
        documentCount: snapshot.docs.length,
        fromCache: false,
      ),
    );
    return [
      for (final doc in snapshot.docs) _metricFromData(doc.id, doc.data()),
    ];
  });

  @override
  Future<String> addBodyMetric({
    required String uid,
    required BodyMetricDraft draft,
  }) => _guard(() async {
    final reference = _metrics(uid).doc();
    await reference.set({
      'weightKg': draft.weightKg,
      'measuredAt': Timestamp.fromDate(draft.measuredAt),
      'note': draft.note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  });

  @override
  Future<void> updateBodyMetric({
    required String uid,
    required String metricId,
    required BodyMetricDraft draft,
  }) => _guard(
    () => _metrics(uid).doc(metricId).update({
      'weightKg': draft.weightKg,
      'measuredAt': Timestamp.fromDate(draft.measuredAt),
      'note': draft.note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> deleteBodyMetric({
    required String uid,
    required String metricId,
  }) => _guard(() => _metrics(uid).doc(metricId).delete());

  UserProfile _profileFromData(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      heightCm: _double(data['heightCm']),
      birthDate: _date(data['birthDate']),
      healthGoal: HealthGoal.fromValue(data['healthGoal']),
      targetWeightKg: _double(data['targetWeightKg']),
      onboardingCompletedAt: _date(data['onboardingCompletedAt']),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      schemaVersion: data['schemaVersion'] as int? ?? 1,
      appearance: ProfileAppearance.fromMap(data['profileAppearance']),
      personalization: data['personalization'] is Map
          ? PersonalizationAnswers.fromMap(
              Map<String, dynamic>.from(data['personalization'] as Map),
            )
          : null,
    );
  }

  BodyMetric _metricFromData(String id, Map<String, dynamic> data) {
    final measuredAt = _date(data['measuredAt']);
    final weight = _double(data['weightKg']);
    if (measuredAt == null || weight == null) {
      throw StateError('Invalid body metric schema.');
    }
    return BodyMetric(
      id: id,
      weightKg: weight,
      measuredAt: measuredAt,
      note: data['note'] as String? ?? '',
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  double? _double(Object? value) => value is num ? value.toDouble() : null;

  DateTime? _date(Object? value) => switch (value) {
    Timestamp timestamp => timestamp.toDate(),
    DateTime date => date,
    _ => null,
  };

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ProfileFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw ProfileFailure.fromCode(error.code);
    } catch (_) {
      throw ProfileFailure.fromCode('unknown');
    }
  }
}
