import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/utils/subscription_stream.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/play_billing_repository.dart';
import '../data/play_store.dart';
import '../models/play_billing_models.dart';
import 'play_billing_controller.dart';

final playBillingEnabledProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment(
    'HEALTHMATE_ENABLE_PLAY_BILLING',
    defaultValue: false,
  ),
);

final playBillingSupportedProvider = Provider<bool>(
  (ref) => !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
);
final playBillingRepositoryProvider = Provider<PlayBillingRepository>(
  (ref) => FirebasePlayBillingRepository(
    FirebaseFunctions.instanceFor(region: 'asia-southeast1'),
    FirebaseFirestore.instance,
  ),
);
final playStoreProvider = Provider<PlayStore>(
  (ref) => GooglePlayStore(InAppPurchase.instance),
);
final playBillingControllerProvider = Provider<PlayBillingController?>((ref) {
  final user = ref.watch(authSessionProvider).value;
  if (!ref.watch(playBillingEnabledProvider) ||
      !ref.watch(playBillingSupportedProvider) ||
      user?.emailVerified != true) {
    return null;
  }
  final uid = user!.uid;
  var disposed = false;
  final controller = PlayBillingController(
    ref.watch(playBillingRepositoryProvider),
    ref.watch(playStoreProvider),
    isCurrent: () =>
        !disposed && ref.read(authSessionProvider).value?.uid == uid,
  );
  ref.onDispose(() {
    disposed = true;
    controller.dispose();
  });
  // Lifetime belongs to the signed-in app session, including checkout returns
  // and restored purchases received after leaving the Premium screen.
  unawaited(controller.start());
  return controller;
});
final verifiedMembershipProvider =
    StreamProvider.autoDispose<VerifiedMembership?>((ref) {
      final user = ref.watch(authSessionProvider).value;
      if (!ref.watch(playBillingEnabledProvider) ||
          !ref.watch(playBillingSupportedProvider) ||
          user?.emailVerified != true) {
        return Stream.value(null);
      }
      return subscriptionStream(
        ref.watch(playBillingRepositoryProvider).watchMembership(user!.uid),
      );
    }, retry: (_, _) => null);
