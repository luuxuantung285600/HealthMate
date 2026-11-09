enum SupportType {
  bug('Báo lỗi'),
  suggestion('Góp ý');

  const SupportType(this.label);
  final String label;
}

enum SupportTopic {
  account('account', 'Tài khoản & đăng nhập'),
  premium('premium', 'Premium & thanh toán'),
  nutrition('nutrition', 'Dinh dưỡng & món ăn'),
  activity('activity', 'Bài tập & vận động'),
  tracking('tracking', 'Hồ sơ & sức khỏe'),
  foodScanner('food_scanner', 'AI quét món ăn'),
  chatbot('chatbot', 'AI Chatbot'),
  other('other', 'Vấn đề khác');

  const SupportTopic(this.code, this.label);
  final String code, label;

  static SupportTopic? fromCode(Object? code) {
    for (final topic in values) {
      if (topic.code == code) return topic;
    }
    return null;
  }
}

/// New ticket allowance only. Existing-thread replies do not consume it.
abstract final class SupportPolicy {
  static const dailyTicketLimit = 3;
  static const createInterval = Duration(seconds: 60);
  static const pageSize = 25;
  static int usedToday({
    required DateTime instant,
    required DateTime previousDayStart,
    required int previousCount,
  }) =>
      previousDayStart.isAtSameMomentAs(dayStart(instant)) ? previousCount : 0;

  static DateTime dayStart(DateTime instant) {
    final vietnam = instant.toUtc().add(const Duration(hours: 7));
    return DateTime.utc(
      vietnam.year,
      vietnam.month,
      vietnam.day,
    ).subtract(const Duration(hours: 7));
  }
}

class SupportTicketCursor {
  const SupportTicketCursor({
    required this.seconds,
    required this.nanoseconds,
    required this.id,
  });
  final int seconds, nanoseconds;
  final String id;
}

class SupportTicketPage {
  const SupportTicketPage({required this.tickets, this.nextCursor});
  final List<SupportTicket> tickets;
  final SupportTicketCursor? nextCursor;
}

enum SupportStatus {
  open('Đã tiếp nhận'),
  inProgress('Đang xử lý'),
  resolved('Đã giải quyết');

  const SupportStatus(this.label);
  final String label;
  String get code => this == inProgress ? 'in_progress' : name;
}

class SupportFailure implements Exception {
  const SupportFailure(this.message);
  factory SupportFailure.firebase(String code, {required bool replying}) {
    final action = replying ? 'tin nhắn' : 'yêu cầu';
    return SupportFailure(switch (code) {
      'permission-denied' =>
        'Máy chủ chưa cho phép gửi $action. Tài khoản có thể đã bị khóa, đang xóa hoặc cấu hình hỗ trợ chưa sẵn sàng. Nội dung vẫn được giữ.',
      'unauthenticated' =>
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại trước khi gửi $action.',
      _ =>
        'Chưa xác nhận gửi $action. Kiểm tra kết nối rồi thử lại; nội dung vẫn được giữ.',
    });
  }
  final String message;
}

String supportText(String input, int maximum, String label) {
  final value = input.trim();
  if (value.isEmpty || value.runes.length > maximum) {
    throw SupportFailure('$label cần từ 1 đến $maximum ký tự.');
  }
  return value;
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.uid,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    this.topic,
  });
  final String id, uid, title, description;
  final SupportType type;
  // Historical tickets have no topic. Do not infer one from their content.
  final SupportTopic? topic;
  String get topicLabel => topic?.label ?? 'Chưa phân loại';
  final SupportStatus status;
  final DateTime createdAt, updatedAt;
  final int messageCount;
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.text,
    required this.isAdmin,
    required this.createdAt,
    required this.sequence,
  });
  final String id, text;
  final bool isAdmin;
  final DateTime createdAt;
  final int sequence;
}
