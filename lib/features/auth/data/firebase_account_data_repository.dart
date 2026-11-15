import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_data_repository.dart';
import '../models/account_deletion_job.dart';

/// Resumable client fallback. A durable privileged worker is still required for
/// unattended completion, legacy orphan discovery and verified Auth finalization.
class FirebaseAccountDataRepository implements AccountDataRepository {
  FirebaseAccountDataRepository(this._firestore);

  static const _batchSize = 100;
  static const privateCollections = [
    'body_metrics',
    'meal_plans', // Remove links before journal batches.
    'meal_logs',
    'water_logs',
    'activity_logs',
    'workout_sessions',
    'goals',
    'daily_quests',
    'nutrition_targets',
    'favorite_foods',
    'custom_foods',
    'recipes',
    'meal_templates',
    'day_reviews',
    'sleep_logs',
    'wellness_state',
    'step_logs',
    'wellness_preferences',
    'energy_adjustments',
    'data_migrations',
  ];

  static const serverScopes = {
    'ai_gateway_usage': 'days',
    'ai_gateway_reservations': 'requests',
  };

  final FirebaseFirestore _firestore;
  DocumentReference<Map<String, dynamic>> _job(String uid) =>
      _firestore.collection('account_deletions').doc(uid);

  AccountDeletionJob _decode(String uid, Map<String, dynamic> data) {
    final checkpoint = data['checkpoint'];
    final requested = data['requestedAt'], updated = data['updatedAt'];
    if (data['uid'] != uid ||
        data['schemaVersion'] != 1 ||
        data['executor'] != 'client' ||
        checkpoint is! int ||
        checkpoint < 0 ||
        checkpoint > 5 ||
        requested is! Timestamp ||
        updated is! Timestamp ||
        data['state'] is! String) {
      throw const AccountDataFailure();
    }
    return AccountDeletionJob(
      uid: uid,
      state: AccountDeletionJob.parseState(data['state'] as String),
      checkpoint: checkpoint,
      requestedAt: requested.toDate(),
      updatedAt: updated.toDate(),
    );
  }

  @override
  Stream<AccountDeletionJob?> watchDeletion(String uid) => _job(uid)
      .snapshots(includeMetadataChanges: true)
      // Cached absence must not open product access while offline.
      .where((s) => !s.metadata.isFromCache && !s.metadata.hasPendingWrites)
      .map((s) => s.exists ? _decode(uid, s.data()!) : null);

  @override
  Future<AccountDeletionJob> requestDeletion(String uid) async {
    try {
      final job = _job(uid);
      await _firestore.runTransaction((t) async {
        final old = await t.get(job);
        if (old.exists) {
          _decode(uid, old.data()!);
          return;
        }
        t.set(job, {
          'uid': uid,
          'schemaVersion': 1,
          'executor': 'client',
          'state': 'requested',
          'checkpoint': 0,
          'requestedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return _decode(
        uid,
        (await job.get(const GetOptions(source: Source.server))).data()!,
      );
    } catch (_) {
      throw const AccountDataFailure();
    }
  }

  Future<void> _advance(
    String uid,
    int checkpoint, {
    bool authPending = false,
  }) => _firestore.runTransaction((t) async {
    final ref = _job(uid);
    final data = (await t.get(ref)).data();
    if (data == null) throw const AccountDataFailure();
    final old = _decode(uid, data);
    // Another retry/device may be ahead; never reset its progress.
    if (old.state == AccountDeletionState.authPending ||
        old.checkpoint > checkpoint) {
      return;
    }
    if (old.checkpoint == checkpoint &&
        old.state == AccountDeletionState.cleaning &&
        !authPending) {
      return;
    }
    t.update(ref, {
      'state': authPending ? 'auth_pending' : 'cleaning',
      'checkpoint': checkpoint,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });

  @override
  Future<void> deleteAllUserData(String uid) async {
    try {
      await requestDeletion(uid);
      await _advance(uid, 0);
      final user = _firestore.collection('users').doc(uid);
      // Checkpoints record progress only. Re-enumerate every stage on every
      // resume so a forged/stale checkpoint cannot hide remaining documents.
      for (final name in privateCollections) {
        await _deleteQuery(user.collection(name));
      }
      await _deleteChatSessions(user.collection('chat_sessions'));
      await _advance(uid, 1);
      await _deleteSupportTickets(uid);
      await _advance(uid, 2);
      await _deleteQuery(
        _firestore
            .collection('demo_premium_transactions')
            .where('uid', isEqualTo: uid),
      );
      final usage = _firestore.collection('demo_ai_usage').doc(uid);
      await _deleteQuery(usage.collection('days'));
      await usage.delete();
      for (final scope in serverScopes.entries) {
        final parent = _firestore.collection(scope.key).doc(uid);
        await _deleteQuery(parent.collection(scope.value));
        await _requireEmpty(parent.collection(scope.value));
        await parent.delete();
      }
      for (final name in [
        'demo_premium_accounts',
        'support_usage',
        'user_directory',
        'account_controls',
      ]) {
        await _firestore.collection(name).doc(uid).delete();
      }
      await _advance(uid, 3);
      await user.delete();
      await _verifyEmpty(uid);
      await _advance(uid, 4);
    } catch (_) {
      throw const AccountDataFailure();
    }
  }

  @override
  Future<void> markLocalDataDeleted(String uid) async {
    try {
      // Server queries, not cached snapshots or checkpoint booleans.
      await _verifyEmpty(uid);
      final job = (await _job(
        uid,
      ).get(const GetOptions(source: Source.server))).data();
      if (job == null || _decode(uid, job).checkpoint < 4) {
        throw const AccountDataFailure();
      }
      await _advance(uid, 5, authPending: true);
    } catch (_) {
      throw const AccountDataFailure();
    }
  }

  Future<void> _verifyEmpty(String uid) async {
    final user = _firestore.collection('users').doc(uid);
    for (final name in [...privateCollections, 'chat_sessions']) {
      await _requireEmpty(user.collection(name));
    }
    await _requireEmpty(
      _firestore.collection('support_tickets').where('uid', isEqualTo: uid),
    );
    await _requireEmpty(
      _firestore
          .collection('demo_premium_transactions')
          .where('uid', isEqualTo: uid),
    );
    await _requireEmpty(
      _firestore.collection('demo_ai_usage').doc(uid).collection('days'),
    );
    for (final scope in serverScopes.entries) {
      await _requireEmpty(
        _firestore.collection(scope.key).doc(uid).collection(scope.value),
      );
    }
    for (final ref in [
      user,
      for (final name in [
        'demo_premium_accounts',
        'demo_ai_usage',
        'support_usage',
        'user_directory',
        'account_controls',
        ...serverScopes.keys,
      ])
        _firestore.collection(name).doc(uid),
    ]) {
      if ((await ref.get(const GetOptions(source: Source.server))).exists) {
        throw const AccountDataFailure();
      }
    }
  }

  Future<void> _requireEmpty(Query<Map<String, dynamic>> query) async {
    if ((await query.limit(1).get(const GetOptions(source: Source.server)))
        .docs
        .isNotEmpty) {
      throw const AccountDataFailure();
    }
  }

  Future<void> _deleteChatSessions(
    CollectionReference<Map<String, dynamic>> sessions,
  ) async {
    while (true) {
      final snapshot = await sessions
          .limit(_batchSize)
          .get(const GetOptions(source: Source.server));
      if (snapshot.docs.isEmpty) return;
      for (final session in snapshot.docs) {
        await _deleteQuery(session.reference.collection('messages'));
        // Never remove a parent before its known children have been confirmed empty.
        await _requireEmpty(session.reference.collection('messages'));
        await session.reference.delete();
      }
    }
  }

  Future<void> _deleteSupportTickets(String uid) async {
    final query = _firestore
        .collection('support_tickets')
        .where('uid', isEqualTo: uid);
    while (true) {
      final snapshot = await query
          .limit(50)
          .get(const GetOptions(source: Source.server));
      if (snapshot.docs.isEmpty) return;
      for (final ticket in snapshot.docs) {
        await _firestore.runTransaction((t) async {
          final current = await t.get(ticket.reference);
          if (current.exists && current.data()?['deleting'] != true) {
            t.update(ticket.reference, {
              'deleting': true,
              'updatedBy': uid,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        });
        await _deleteQuery(ticket.reference.collection('messages'));
        await _requireEmpty(ticket.reference.collection('messages'));
        await ticket.reference.delete();
      }
    }
  }

  Future<void> _deleteQuery(Query<Map<String, dynamic>> query) async {
    while (true) {
      final snapshot = await query
          .limit(_batchSize)
          .get(const GetOptions(source: Source.server));
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
