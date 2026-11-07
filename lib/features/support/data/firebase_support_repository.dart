import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/support_models.dart';
import 'support_repository.dart';

class FirebaseSupportRepository implements SupportRepository {
  FirebaseSupportRepository(this.db, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final FirebaseFirestore db;
  final DateTime Function() now;
  CollectionReference<Map<String, dynamic>> get _tickets =>
      db.collection('support_tickets');
  @override
  String newId() => _tickets.doc().id;

  SupportTicket _ticket(String id, Map<String, dynamic> d) => SupportTicket(
    id: id,
    uid: d['uid'] as String,
    type: SupportType.values.byName(d['type'] as String),
    title: d['title'] as String,
    description: d['description'] as String,
    status: SupportStatus.values.firstWhere((s) => s.code == d['status']),
    createdAt: (d['createdAt'] as Timestamp).toDate(),
    updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    messageCount: d['messageCount'] as int,
  );

  @override
  Stream<List<SupportTicket>> watchTickets(String uid) =>
      watchTicketPage(uid).map((page) => page.tickets);

  @override
  Stream<SupportTicketPage> watchTicketPage(
    String uid, {
    SupportTicketCursor? after,
  }) {
    Query<Map<String, dynamic>> query = _tickets
        .where('uid', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    if (after != null) {
      query = query.startAfter([
        Timestamp(after.seconds, after.nanoseconds),
        after.id,
      ]);
    }
    return query
        .limit(SupportPolicy.pageSize + 1)
        .snapshots(includeMetadataChanges: true)
        .where((s) => !s.metadata.isFromCache && !s.metadata.hasPendingWrites)
        .map((s) {
          // Keep the cursor in the raw query scope even if a deletion is in
          // progress; otherwise a hidden row can trap the page boundary.
          final visible = s.docs.take(SupportPolicy.pageSize).toList();
          final last = visible.lastOrNull;
          final time = last?.data()['updatedAt'] as Timestamp?;
          return SupportTicketPage(
            tickets: visible
                .where((d) => d.data()['deleting'] != true)
                .map((d) => _ticket(d.id, d.data()))
                .toList(),
            nextCursor:
                s.docs.length > SupportPolicy.pageSize &&
                    last != null &&
                    time != null
                ? SupportTicketCursor(
                    seconds: time.seconds,
                    nanoseconds: time.nanoseconds,
                    id: last.id,
                  )
                : null,
          );
        });
  }

  @override
  Stream<SupportTicket?> watchTicket(String uid, String ticketId) => _tickets
      .doc(ticketId)
      .snapshots(includeMetadataChanges: true)
      .where((s) => !s.metadata.isFromCache && !s.metadata.hasPendingWrites)
      .map((s) {
        if (!s.exists || s.data()?['deleting'] == true) return null;
        final value = _ticket(s.id, s.data()!);
        if (value.uid != uid) {
          throw const SupportFailure('Yêu cầu không thuộc tài khoản này.');
        }
        return value;
      });

  @override
  Stream<List<SupportMessage>> watchMessages(String uid, String ticketId) =>
      _tickets
          .doc(ticketId)
          .collection('messages')
          .orderBy('sequence')
          .limit(100)
          .snapshots(includeMetadataChanges: true)
          .where((s) => !s.metadata.isFromCache && !s.metadata.hasPendingWrites)
          .map(
            (s) => s.docs.map((doc) {
              final d = doc.data();
              return SupportMessage(
                id: doc.id,
                text: d['text'] as String,
                isAdmin: d['role'] == 'admin',
                createdAt: (d['createdAt'] as Timestamp).toDate(),
                sequence: d['sequence'] as int,
              );
            }).toList(),
          );

  @override
  Future<void> create(
    String uid,
    String id,
    SupportType type,
    String title,
    String description,
  ) async {
    final cleanTitle = supportText(title, 120, 'Tiêu đề');
    final cleanBody = supportText(description, 2000, 'Nội dung');
    final ticket = _tickets.doc(id);
    try {
      // Return business failures across the web SDK boundary. Throwing a Dart
      // exception inside a JS transaction callback wraps it in NativeError and
      // loses the SupportFailure type needed by callers (including retries).
      final failure = await db.runTransaction<String?>((t) async {
        final old = await t.get(ticket);
        if (old.exists) {
          if (old.data()?['uid'] != uid ||
              old.data()?['title'] != cleanTitle ||
              old.data()?['description'] != cleanBody ||
              old.data()?['type'] != type.name) {
            return 'Mã yêu cầu đã được dùng. Đóng form rồi gửi yêu cầu mới.';
          }
          return null;
        }
        final usage = db.collection('support_usage').doc(uid);
        final allowance = (await t.get(usage)).data();
        final at = now();
        final dayStart = SupportPolicy.dayStart(at);
        var count = 0;
        if (allowance != null) {
          final previousDay = allowance['dayStart'];
          final previousCount = allowance['count'];
          final lastCreated = allowance['lastCreatedAt'];
          if (allowance['schemaVersion'] != 1 ||
              previousDay is! Timestamp ||
              previousCount is! int ||
              previousCount < 1 ||
              previousCount > SupportPolicy.dailyTicketLimit ||
              lastCreated is! Timestamp) {
            return 'Chưa xác nhận được hạn mức hỗ trợ. Hãy tải lại.';
          }
          count = SupportPolicy.usedToday(
            instant: at,
            previousDayStart: previousDay.toDate(),
            previousCount: previousCount,
          );
          if (count >= SupportPolicy.dailyTicketLimit) {
            return 'Bạn đã gửi đủ ${SupportPolicy.dailyTicketLimit} yêu cầu mới hôm nay. Bạn vẫn có thể trả lời yêu cầu đã có.';
          }
          if (at.toUtc().difference(lastCreated.toDate()) <
              SupportPolicy.createInterval) {
            return 'Hãy chờ ${SupportPolicy.createInterval.inSeconds} giây giữa hai yêu cầu mới. Bạn vẫn có thể bổ sung vào yêu cầu đã có.';
          }
        }
        t.set(usage, {
          'schemaVersion': 1,
          'dayStart': Timestamp.fromDate(dayStart),
          'count': count + 1,
          'lastCreatedAt': FieldValue.serverTimestamp(),
          'lastTicketId': id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        t.set(ticket, {
          'uid': uid,
          'type': type.name,
          'title': cleanTitle,
          'description': cleanBody,
          'status': 'open',
          'messageCount': 0,
          'lastMessageId': '',
          'updatedBy': uid,
          'deleting': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return null;
      });
      if (failure != null) throw SupportFailure(failure);
      final confirmed = await ticket.get(
        const GetOptions(source: Source.server),
      );
      final data = confirmed.data();
      if (!confirmed.exists ||
          data?['deleting'] == true ||
          data?['uid'] != uid ||
          data?['title'] != cleanTitle ||
          data?['description'] != cleanBody ||
          data?['type'] != type.name) {
        throw const SupportFailure('Yêu cầu không còn khả dụng. Hãy tải lại.');
      }
    } on FirebaseException catch (error) {
      throw SupportFailure.firebase(error.code, replying: false);
    }
  }

  @override
  Future<void> reply(
    String uid,
    String ticketId,
    String messageId,
    String text,
  ) async {
    final clean = supportText(text, 2000, 'Tin nhắn');
    final ticket = _tickets.doc(ticketId),
        message = _tickets.doc(ticketId).collection('messages').doc(messageId);
    try {
      final failure = await db.runTransaction<String?>((t) async {
        final old = await t.get(message);
        final parent = await t.get(ticket);
        if (!parent.exists ||
            parent.data()?['uid'] != uid ||
            parent.data()?['deleting'] == true) {
          return 'Yêu cầu không còn khả dụng.';
        }
        if (old.exists) {
          if (old.data()?['authorUid'] != uid || old.data()?['text'] != clean) {
            return 'Tin nhắn đã gửi. Tải lại cuộc trao đổi.';
          }
          return null;
        }
        final count = parent.data()!['messageCount'] as int;
        if (count >= 100) {
          return 'Cuộc trao đổi đã đủ 100 tin nhắn. Hãy tạo yêu cầu mới.';
        }
        t.set(message, {
          'authorUid': uid,
          'role': 'customer',
          'text': clean,
          'sequence': count + 1,
          'createdAt': FieldValue.serverTimestamp(),
        });
        t.update(ticket, {
          'messageCount': count + 1,
          'lastMessageId': messageId,
          'updatedBy': uid,
          'status': 'open',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return null;
      });
      if (failure != null) throw SupportFailure(failure);
      final confirmed = await message.get(
        const GetOptions(source: Source.server),
      );
      final data = confirmed.data();
      if (!confirmed.exists ||
          data?['authorUid'] != uid ||
          data?['role'] != 'customer' ||
          data?['text'] != clean) {
        throw const SupportFailure('Chưa xác nhận được tin nhắn. Hãy tải lại.');
      }
    } on FirebaseException catch (error) {
      throw SupportFailure.firebase(error.code, replying: true);
    }
  }
}
