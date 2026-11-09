import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/play_billing_models.dart';

abstract interface class PlayBillingRepository {
  Future<PlayBillingConfig> prepare();
  Future<BillingVerification> verify(String token);
  Stream<VerifiedMembership?> watchMembership(String uid);
}

class FirebasePlayBillingRepository implements PlayBillingRepository {
  FirebasePlayBillingRepository(this.functions, this.db);
  final FirebaseFunctions functions;
  final FirebaseFirestore db;
  @override
  Future<PlayBillingConfig> prepare() async {
    final result = await functions
        .httpsCallable(
          'preparePlayBilling',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
        )
        .call();
    return PlayBillingConfig.fromData(
      Map<String, dynamic>.from(result.data as Map),
    );
  }

  @override
  Future<BillingVerification> verify(String token) async {
    final result = await functions
        .httpsCallable(
          'verifyPlayPurchase',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 125)),
        )
        .call({'purchaseToken': token});
    final data = Map<String, dynamic>.from(result.data as Map);
    return BillingVerification.fromData(data);
  }

  @override
  Stream<VerifiedMembership?> watchMembership(String uid) => db
      .collection('premium_memberships')
      .doc(uid)
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) {
        // Cached membership is never presented as a freshly confirmed entitlement.
        if (snapshot.metadata.isFromCache ||
            snapshot.metadata.hasPendingWrites) {
          throw StateError('Cần kết nối mạng để xác nhận gói Premium.');
        }
        final data = snapshot.data();
        if (data == null) return null;
        if (data['provider'] != 'google_play' ||
            data['verified'] != true ||
            !['production', 'test'].contains(data['environment']) ||
            data['startedAt'] is! Timestamp ||
            data['expiresAt'] is! Timestamp ||
            data['active'] is! bool ||
            data['autoRenewing'] is! bool ||
            data['status'] is! String) {
          throw const FormatException('Gói Premium chưa được xác nhận.');
        }
        return VerifiedMembership(
          active: data['active'],
          startedAt: (data['startedAt'] as Timestamp).toDate(),
          expiresAt: (data['expiresAt'] as Timestamp).toDate(),
          environment: data['environment'],
          autoRenewing: data['autoRenewing'],
          status: data['status'],
        );
      });
}
