import '../models/support_models.dart';

abstract interface class SupportRepository {
  String newId();
  Stream<List<SupportTicket>> watchTickets(String uid);
  Stream<SupportTicketPage> watchTicketPage(
    String uid, {
    SupportTicketCursor? after,
  });
  Stream<SupportTicket?> watchTicket(String uid, String ticketId);
  Stream<List<SupportMessage>> watchMessages(String uid, String ticketId);
  Future<void> create(
    String uid,
    String id,
    SupportType type,
    String title,
    String description, {
    required SupportTopic topic,
  });
  Future<void> reply(
    String uid,
    String ticketId,
    String messageId,
    String text,
  );
}
