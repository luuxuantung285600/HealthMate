import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/subscription_stream.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/firebase_support_repository.dart';
import '../data/support_repository.dart';
import '../models/support_models.dart';

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => FirebaseSupportRepository(FirebaseFirestore.instance),
);
// AsyncValue may retain a previous user during loading/error. That retained
// value must not start support reads or permit sends for an uncertain session.
final supportSessionUidProvider = Provider<String?>((ref) {
  final session = ref.watch(authSessionProvider);
  return !session.isLoading &&
          !session.hasError &&
          session.value?.emailVerified == true
      ? session.value?.uid
      : null;
});
final supportTicketsProvider = StreamProvider.autoDispose<List<SupportTicket>>((
  ref,
) {
  final uid = ref.watch(supportSessionUidProvider);
  if (uid == null) return Stream.value([]);
  return subscriptionStream(
    ref.watch(supportRepositoryProvider).watchTickets(uid),
  );
});
final supportTicketPageProvider = StreamProvider.autoDispose
    .family<SupportTicketPage, SupportTicketCursor?>((ref, cursor) {
      final uid = ref.watch(supportSessionUidProvider);
      if (uid == null) {
        return Stream.value(const SupportTicketPage(tickets: []));
      }
      return subscriptionStream(
        ref
            .watch(supportRepositoryProvider)
            .watchTicketPage(uid, after: cursor),
      );
    });
final supportTicketProvider = StreamProvider.autoDispose
    .family<SupportTicket?, String>((ref, id) {
      final uid = ref.watch(supportSessionUidProvider);
      if (uid == null) return Stream.value(null);
      return subscriptionStream(
        ref.watch(supportRepositoryProvider).watchTicket(uid, id),
      );
    });
final supportMessagesProvider = StreamProvider.autoDispose
    .family<List<SupportMessage>, String>((ref, id) {
      final uid = ref.watch(supportSessionUidProvider);
      if (uid == null) return Stream.value([]);
      return subscriptionStream(
        ref.watch(supportRepositoryProvider).watchMessages(uid, id),
      );
    });
