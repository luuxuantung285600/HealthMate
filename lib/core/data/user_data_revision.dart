import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_providers.dart';

/// Tests and secondary Firebase apps must bind every realtime listener to the
/// same instance as their repositories, rather than falling back to [DEFAULT].
final realtimeFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// Only revision timestamps, never health records. One listener per signed-in
/// user invalidates server-backed range reports after changes on another device.
final serverRevisionSyncProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment('HEALTHMATE_SERVER_REVISIONS'),
);

final userDataRevisionProvider = StreamProvider<Map<String, dynamic>>((ref) {
  if (!ref.watch(serverRevisionSyncProvider)) return const Stream.empty();
  final user = ref.watch(authSessionProvider).value;
  if (user?.emailVerified != true || Firebase.apps.isEmpty) {
    return Stream.value(const {});
  }
  return ref
      .watch(realtimeFirestoreProvider)
      .collection('user_sync')
      .doc(user!.uid)
      .snapshots(includeMetadataChanges: true)
      .where(
        (snapshot) =>
            !snapshot.metadata.isFromCache &&
            !snapshot.metadata.hasPendingWrites,
      )
      .map((snapshot) => snapshot.data() ?? const {});
}, retry: (_, _) => null);
