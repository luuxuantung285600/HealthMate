import '../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/local_date_key.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/config/app_feature_flags.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/chat_models.dart';
import '../domain/chat_request.dart';
import '../providers/chat_providers.dart';
import '../providers/assistant_providers.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(appFeatureFlagsProvider).chatbotEnabled) {
      return const SizedBox.shrink();
    }
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final uid = ref.watch(
      authSessionProvider.select((session) => session.value?.uid),
    );
    if (uid == null) return const SizedBox.shrink();
    return _ChatBody(key: ValueKey(uid));
  }
}

class _ChatBody extends ConsumerStatefulWidget {
  const _ChatBody({super.key});

  @override
  ConsumerState<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends ConsumerState<_ChatBody> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late DateTime _date;
  bool _aiDisclosureAccepted = false;
  bool _assistantConsent = false;
  bool _localOnly = false;
  bool _scrollScheduled = false;

  void _showLatest() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _date = localDateOnly(ref.read(currentLocalTimeProvider)());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send({
    String? text,
    KnowledgeTopic? topic,
    bool quickLookup = false,
  }) async {
    final original = _input.text;
    final question = topic?.label ?? text ?? original;
    final flexible =
        ref.read(flexibleChatAvailableProvider) && !_localOnly && !quickLookup;
    if (question.trim().isEmpty) return;
    if (flexible && !_assistantConsent) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chat AI'),
          content: const SingleChildScrollView(
            child: Text(
              'Câu hỏi, tối đa 3 lượt chat gần nhất và số liệu liên quan (bữa ăn, mục tiêu, nước, '
              'vận động, cân nặng) được gửi đến Cloudflare Workers AI để trả lời.\n\n'
              'App không lấy toàn bộ hồ sơ. Đừng nhập thông tin nhận dạng hoặc hồ sơ bệnh án. '
              'Cloudflare công bố không dùng nội dung để huấn luyện; có ngoại lệ lưu giữ theo pháp luật/an toàn. '
              'Hội thoại lưu riêng trong HealthMate.\n\n'
              'AI có thể sai, không thay tư vấn y tế. Chọn Tra cứu nhật ký để không gửi AI.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Để sau'),
            ),
            FilledButton(
              key: const ValueKey('chat-accept-assistant'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đồng ý'),
            ),
          ],
        ),
      );
      if (!mounted || accepted != true) return;
      _assistantConsent = true;
    }
    final resolvedTopic =
        topic ??
        planChatRequest(
          question,
          _date,
          ref.read(currentLocalTimeProvider)(),
        ).topic;
    if (!flexible &&
        !_localOnly &&
        resolvedTopic != null &&
        !_aiDisclosureAccepted) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kiến thức chung từ AI'),
          content: SingleChildScrollView(
            child: Text(
              'Chủ đề gửi: ${resolvedTopic.label}\n\n'
              'Chỉ câu hỏi chung chuẩn hóa theo chủ đề được gửi đến dịch vụ AI của Google. '
              'Không gửi nội dung tự nhập, hồ sơ, nhật ký hay lịch sử hội thoại. '
              'Dịch vụ miễn phí có thể dùng câu hỏi và câu trả lời để cải thiện '
              'sản phẩm, có thể có người đánh giá nội dung.\n\n'
              'Câu trả lời AI có thể sai, chỉ cung cấp kiến thức chung và không '
              'thay thế tư vấn y tế. Hội thoại được lưu trong tài khoản HealthMate.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Để sau'),
            ),
            FilledButton(
              key: const ValueKey('chat-accept-ai'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      );
      if (!mounted || accepted != true) return;
      _aiDisclosureAccepted = true;
    }
    final saved = await ref
        .read(chatControllerProvider.notifier)
        .send(
          question,
          _date,
          topic: topic,
          allowKnowledge: _aiDisclosureAccepted,
          allowAssistant: _assistantConsent,
          localOnly: _localOnly || quickLookup,
        );
    if (!mounted) return;
    if (saved && topic == null && text == null && _input.text == original) {
      _input.clear();
    }
    _showLatest();
  }

  Future<void> _chooseDate() async {
    final now = ref.read(currentLocalTimeProvider)();
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: localDateOnly(now),
    );
    if (date != null && mounted) {
      ref.read(chatControllerProvider.notifier).resetQuestionContext();
      setState(() => _date = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(chatControllerProvider, (previous, next) {
      final nearBottom =
          !_scroll.hasClients || _scroll.position.extentAfter < 100;
      if (previous?.pendingQuestion != next.pendingQuestion ||
          previous?.messages.length != next.messages.length ||
          (nearBottom && previous?.preview != next.preview)) {
        _showLatest();
      }
    });
    final chat = ref.watch(chatControllerProvider);
    final controller = ref.read(chatControllerProvider.notifier);
    final enabled = !chat.busy && !chat.full && !chat.pendingSave;
    final flexible = ref.watch(flexibleChatAvailableProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const ProfileAvatar(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Trò chuyện',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: const ValueKey('chat-new'),
                tooltip: 'Cuộc trò chuyện mới',
                onPressed: chat.busy ? null : controller.newSession,
                icon: const Icon(AppIcons.messageCirclePlus),
              ),
              PopupMenuButton<String>(
                key: const ValueKey('chat-history'),
                tooltip: '20 cuộc trò chuyện gần nhất',
                enabled: !chat.busy,
                onSelected: (id) {
                  if (id == 'refresh') {
                    controller.loadSessions();
                  } else {
                    controller.openSession(id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Text('Tải lại lịch sử'),
                  ),
                  for (final session in chat.sessions)
                    PopupMenuItem(
                      value: session.id,
                      child: Text(
                        '${DateFormat('dd/MM HH:mm').format(session.updatedAt.toLocal())} · ${session.messageCount ~/ 2} lượt',
                      ),
                    ),
                ],
                icon: const Icon(AppIcons.history),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              key: const ValueKey('chat-messages'),
              controller: _scroll,
              children: [
                if (chat.messages.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            AppIcons.chatbot,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Hiểu nhật ký của bạn',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hỏi về bữa ăn, mục tiêu và tiến độ. Tôi dùng số liệu đã lưu và nói rõ khi thiếu dữ liệu.',
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (flexible)
                  FilterChip(
                    key: const ValueKey('chat-local-only'),
                    selected: _localOnly,
                    label: const Text('Tra cứu nhật ký · không gửi AI'),
                    onSelected: enabled
                        ? (value) => setState(() => _localOnly = value)
                        : null,
                  ),
                if (!flexible)
                  const Text(
                    'Chat AI tự do chưa được kết nối. Bạn vẫn có thể tra cứu nhật ký và đọc kiến thức chung.',
                  ),
                if (chat.messages.isEmpty)
                  const Text('Tra cứu nhanh · không dùng hạn mức AI'),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('chat-date'),
                      onPressed: chat.busy ? null : _chooseDate,
                      icon: const Icon(AppIcons.calendarDays),
                      label: Text(DateFormat('dd/MM/yyyy').format(_date)),
                    ),
                    for (final question in const [
                      'Tóm tắt ngày đã chọn',
                      'Kcal đã ghi',
                      'Nước đã ghi',
                      'Vận động đã ghi',
                      'Hôm nay còn bao nhiêu kcal?',
                      'Tóm tắt tuần này',
                      'Cân nặng gần nhất',
                    ])
                      if (chat.messages.isEmpty)
                        ActionChip(
                          label: Text(question),
                          onPressed: enabled
                              ? () => _send(text: question, quickLookup: true)
                              : null,
                        ),
                  ],
                ),
                if (chat.phase == ChatPhase.loading)
                  const LinearProgressIndicator(),
                if (chat.messages.isEmpty &&
                    !chat.busy &&
                    chat.pendingQuestion.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Bạn có thể nhập “Hôm qua tôi ăn bao nhiêu?”, “7 ngày qua uống bao nhiêu nước?” '
                      'hoặc “Protein là gì?”. Hỏi tiếp “còn đạm thì sao?” để xem cùng khoảng ngày. '
                      'Thông tin hỗ trợ theo dõi thói quen, không thay thế tư vấn y tế.',
                    ),
                  ),
                const Divider(height: 24),
                if (!flexible)
                  ExpansionTile(
                    key: ValueKey('chat-knowledge-${chat.messages.isEmpty}'),
                    initiallyExpanded: chat.messages.isEmpty,
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Kiến thức chung từ AI',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    children: [
                      const Text(
                        'Gemini giải thích chủ đề chung. Nhật ký và nội dung tự nhập được xử lý trong HealthMate.',
                      ),
                      for (final topic in KnowledgeTopic.values.take(3))
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: ValueKey('chat-topic-${topic.name}'),
                            onPressed: enabled
                                ? () => _send(topic: topic)
                                : null,
                            icon: const Icon(AppIcons.sparkles),
                            label: Text(topic.label),
                          ),
                        ),
                      ExpansionTile(
                        key: const ValueKey('chat-more-topics'),
                        tilePadding: EdgeInsets.zero,
                        title: const Text(
                          'Đạm, chất xơ, khẩu phần và các chủ đề khác',
                        ),
                        children: [
                          for (final topic in KnowledgeTopic.values.skip(3))
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                key: ValueKey('chat-topic-${topic.name}'),
                                onPressed: enabled
                                    ? () => _send(topic: topic)
                                    : null,
                                icon: const Icon(AppIcons.sparkles),
                                label: Text(topic.label),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                for (final message in chat.messages)
                  _Bubble(
                    text: message.text,
                    isUser: message.isUser,
                    source: message.source,
                  ),
                if (chat.pendingQuestion.isNotEmpty) ...[
                  _Bubble(
                    text: chat.pendingQuestion,
                    isUser: true,
                    source: ChatSource.help,
                  ),
                  if (chat.preview.isNotEmpty)
                    _Bubble(
                      text: chat.preview,
                      isUser: false,
                      source: ChatSource.help,
                      pending: true,
                    ),
                ],
                if (chat.phase == ChatPhase.answering)
                  const Text('Đang chuẩn bị câu trả lời…'),
                if (chat.phase == ChatPhase.saving)
                  const Text('Đang lưu hội thoại…'),
                if (chat.error != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          if (chat.canRetry)
                            TextButton(
                              key: const ValueKey('chat-retry'),
                              onPressed: chat.busy ? null : controller.retry,
                              child: const Text('Thử lại'),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (chat.full)
                  const Text(
                    'Đã đủ ${ChatLimits.turnsPerSession} lượt. Nhấn nút cuộc trò chuyện mới để tiếp tục.',
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          if (chat.phase == ChatPhase.answering)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('chat-cancel'),
                onPressed: controller.cancel,
                icon: const Icon(AppIcons.circleStop),
                label: const Text('Dừng nhận'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('chat-input'),
                    controller: _input,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 3,
                    maxLength: ChatLimits.inputCharacters,
                    textInputAction: TextInputAction.send,
                    onSubmitted: enabled ? (_) => _send() : null,
                    decoration: const InputDecoration(
                      labelText: 'Nhắn HealthMate',
                      hintText: 'Hỏi về nhật ký hoặc dinh dưỡng…',
                      counterText: '',
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('chat-send'),
                  tooltip: 'Gửi tin nhắn',
                  onPressed: enabled ? () => _send() : null,
                  icon: const Icon(AppIcons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.isUser,
    required this.source,
    this.pending = false,
  });
  final String text;
  final bool isUser;
  final ChatSource source;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? colors.primaryContainer : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser
                  ? 'Bạn'
                  : pending
                  ? 'Bản tạm · chưa lưu'
                  : switch (source) {
                      ChatSource.journal => 'Từ nhật ký · tính tại ứng dụng',
                      ChatSource.ai => 'AI · thông tin tham khảo',
                      ChatSource.help => 'HealthMate',
                    },
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            SelectableText(
              text,
              style: TextStyle(
                color: isUser ? colors.onPrimaryContainer : colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
