import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/confirmed_save.dart';
import '../../auth/models/auth_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/support_models.dart';
import '../providers/support_providers.dart';
import 'support_draft_guard.dart';

String _time(DateTime date) =>
    '${DateFormat('dd/MM/yyyy HH:mm').format(date.toUtc().add(const Duration(hours: 7)))} · VN';
String _failure(Object error) => error is SupportFailure
    ? error.message
    : 'Chưa tải được yêu cầu. Kiểm tra mạng rồi tải lại.';
String _sendFailure(Object error) => error is SupportFailure
    ? error.message
    : 'Chưa xác nhận gửi. Nội dung vẫn được giữ; kiểm tra kết nối rồi thử lại.';
String _sessionMessage(AsyncValue<AuthUser?> session) => session.isLoading
    ? 'Đang kiểm tra phiên đăng nhập…'
    : session.hasError
    ? 'Chưa xác nhận được phiên đăng nhập. Vui lòng đăng nhập lại để xem hỗ trợ.'
    : 'Hãy đăng nhập và xác minh email để dùng hỗ trợ.';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});
  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _cursors = <SupportTicketCursor?>[null];
  String? _uid;
  @override
  Widget build(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final uid = ref.watch(supportSessionUidProvider);
    if (_uid != uid) {
      _uid = uid;
      _cursors
        ..clear()
        ..add(null);
    }
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Báo lỗi & Góp ý')),
        body: Center(
          child: Text(_sessionMessage(ref.watch(authSessionProvider))),
        ),
      );
    }
    final tickets = ref.watch(supportTicketPageProvider(_cursors.last));
    return Scaffold(
      appBar: AppBar(title: const Text('Báo lỗi & Góp ý')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Gửi yêu cầu và trao đổi trực tiếp với đội ngũ HealthMate.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('new-support-ticket'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AccountBoundDialog(child: _NewTicket(uid: uid)),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Gửi yêu cầu mới'),
            ),
            const SizedBox(height: 24),
            Text(
              'Yêu cầu của bạn',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...tickets.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              skipError: false,
              loading: () => [
                const LinearProgressIndicator(),
                const Text('Đang kết nối máy chủ…'),
              ],
              error: (error, _) => [
                Text(_failure(error)),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(supportTicketPageProvider(_cursors.last)),
                  child: const Text('Tải lại'),
                ),
              ],
              data: (page) => [
                if (page.tickets.isEmpty)
                  const Text(
                    'Chưa có yêu cầu. Bạn có thể gửi báo lỗi hoặc đề xuất cải thiện tại đây.',
                  ),
                for (final ticket in page.tickets)
                  Card(
                    child: ListTile(
                      key: ValueKey('support-${ticket.id}'),
                      leading: Icon(
                        ticket.type == SupportType.bug
                            ? Icons.bug_report_outlined
                            : Icons.lightbulb_outline,
                      ),
                      title: Text(
                        ticket.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${ticket.topicLabel}\n${ticket.status.label}\n${_time(ticket.updatedAt)}',
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AccountBoundDialog(
                            child: SupportThreadScreen(ticketId: ticket.id),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      key: const ValueKey('support-newer'),
                      onPressed: _cursors.length == 1
                          ? null
                          : () => setState(() => _cursors.removeLast()),
                      child: const Text('Mới hơn'),
                    ),
                    Text('Trang ${_cursors.length}'),
                    TextButton(
                      key: const ValueKey('support-older'),
                      onPressed: page.nextCursor == null
                          ? null
                          : () => setState(() => _cursors.add(page.nextCursor)),
                      child: const Text('Cũ hơn'),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _cursors
                          ..clear()
                          ..add(null);
                        ref.invalidate(supportTicketPageProvider(null));
                      }),
                      child: const Text('Về mới nhất'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NewTicket extends ConsumerStatefulWidget {
  const _NewTicket({required this.uid});
  final String uid;
  @override
  ConsumerState<_NewTicket> createState() => _NewTicketState();
}

class _NewTicketState extends ConsumerState<_NewTicket> {
  final _title = TextEditingController(), _body = TextEditingController();
  SupportType _type = SupportType.bug;
  SupportTopic? _topic;
  bool _busy = false;
  bool _ownerEnded = false;
  String? _id, _error;
  @override
  void initState() {
    super.initState();
    _title.addListener(_changed);
    _body.addListener(_changed);
  }

  void _changed() => setState(() {});
  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy ||
        _ownerEnded ||
        ref.read(supportSessionUidProvider) != widget.uid) {
      return;
    }
    try {
      if (_topic == null) {
        throw const SupportFailure('Hãy chọn chủ đề cần hỗ trợ trước khi gửi.');
      }
      supportText(_title.text, 120, 'Tiêu đề');
      supportText(_body.text, 2000, 'Nội dung');
    } on SupportFailure catch (error) {
      setState(() => _error = error.message);
      return;
    }
    final repository = ref.read(supportRepositoryProvider);
    _id ??= repository.newId();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.create(
        widget.uid,
        _id!,
        _type,
        _title.text,
        _body.text,
        topic: _topic!,
      );
      if (!mounted ||
          _ownerEnded ||
          ref.read(supportSessionUidProvider) != widget.uid) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Đã gửi yêu cầu. Bạn có thể xem phản hồi tại Báo lỗi & Góp ý.',
          ),
        ),
      );
    } catch (error) {
      if (mounted &&
          !_ownerEnded &&
          ref.read(supportSessionUidProvider) == widget.uid) {
        setState(() => _error = _sendFailure(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider.select((s) => s.value?.uid), (
      before,
      after,
    ) {
      if (before != after && after != widget.uid) _ownerEnded = true;
    });
    return SupportDraftGuard(
      hasDraft:
          _title.text.isNotEmpty ||
          _body.text.isNotEmpty ||
          _type != SupportType.bug ||
          _topic != null,
      busy: _busy,
      child: _ownerEnded || ref.watch(supportSessionUidProvider) != widget.uid
          ? Scaffold(
              appBar: AppBar(title: const Text('Yêu cầu mới')),
              body: Center(
                child: Text(
                  _ownerEnded
                      ? 'Phiên đăng nhập đã thay đổi. Hãy mở lại yêu cầu.'
                      : _sessionMessage(ref.watch(authSessionProvider)),
                ),
              ),
            )
          : Scaffold(
              appBar: AppBar(title: const Text('Yêu cầu mới')),
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    DropdownButtonFormField<SupportTopic>(
                      key: const ValueKey('support-topic'),
                      initialValue: _topic,
                      isExpanded: true,
                      isDense: false,
                      itemHeight: null,
                      decoration: const InputDecoration(
                        labelText: 'Chủ đề cần hỗ trợ',
                      ),
                      hint: const Text('Chọn chủ đề'),
                      items: [
                        for (final topic in SupportTopic.values)
                          DropdownMenuItem(
                            value: topic,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(topic.label),
                            ),
                          ),
                      ],
                      onChanged: _id != null
                          ? null
                          : (value) => setState(() => _topic = value),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<SupportType>(
                      initialValue: _type,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Loại yêu cầu',
                      ),
                      items: [
                        for (final type in SupportType.values)
                          DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                      ],
                      onChanged: _id != null
                          ? null
                          : (value) => setState(() => _type = value!),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const ValueKey('support-title'),
                      controller: _title,
                      maxLength: 120,
                      readOnly: _id != null,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề',
                        hintText: 'Ví dụ: Không lưu được bữa sáng',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('support-description'),
                      controller: _body,
                      minLines: 5,
                      maxLines: 10,
                      maxLength: 2000,
                      readOnly: _id != null,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung',
                        hintText: 'Mô tả vấn đề hoặc điều bạn muốn cải thiện',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nội dung bạn gửi sẽ được admin xem để hỗ trợ. Không gửi mật khẩu, thông tin ngân hàng hoặc hồ sơ sức khỏe nhạy cảm.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tối đa ${SupportPolicy.dailyTicketLimit} yêu cầu mới/ngày, cách nhau ${SupportPolicy.createInterval.inSeconds} giây. Bạn vẫn có thể trả lời yêu cầu đã có.',
                    ),
                    const SizedBox(height: 16),
                    if (_busy) const _PendingSend(),
                    if (_id != null && !_busy)
                      const Text(
                        'Nội dung được giữ nguyên để thử gửi lại an toàn.',
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    FilledButton(
                      key: const ValueKey('send-support-ticket'),
                      onPressed: _busy ? null : _send,
                      child: Text(
                        _busy
                            ? 'Đang gửi…'
                            : _id != null
                            ? 'Thử gửi lại'
                            : 'Gửi yêu cầu',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class SupportThreadScreen extends ConsumerWidget {
  const SupportThreadScreen({required this.ticketId, super.key});
  final String ticketId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    // Retained identity only keeps the hidden in-memory composer mounted during
    // a temporary auth error. All reads/sends still require the ready session.
    final uid = ref.watch(authSessionProvider).value?.uid;
    return uid == null
        ? Scaffold(
            appBar: AppBar(title: const Text('Trao đổi hỗ trợ')),
            body: Center(
              child: Text(_sessionMessage(ref.watch(authSessionProvider))),
            ),
          )
        : _SupportThread(
            key: ValueKey('$uid/$ticketId'),
            uid: uid,
            ticketId: ticketId,
          );
  }
}

class _SupportThread extends ConsumerStatefulWidget {
  const _SupportThread({required this.uid, required this.ticketId, super.key});
  final String uid, ticketId;
  @override
  ConsumerState<_SupportThread> createState() => _SupportThreadState();
}

class _SupportThreadState extends ConsumerState<_SupportThread> {
  final _reply = TextEditingController();
  bool _busy = false;
  bool _ownerEnded = false;
  String? _messageId, _error;
  @override
  void initState() {
    super.initState();
    _reply.addListener(_changed);
  }

  void _changed() => setState(() {});
  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy ||
        _ownerEnded ||
        ref.read(supportSessionUidProvider) != widget.uid) {
      return;
    }
    try {
      supportText(_reply.text, 2000, 'Tin nhắn');
    } on SupportFailure catch (error) {
      setState(() => _error = error.message);
      return;
    }
    final repository = ref.read(supportRepositoryProvider);
    _messageId ??= repository.newId();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.reply(
        widget.uid,
        widget.ticketId,
        _messageId!,
        _reply.text,
      );
      if (!mounted ||
          _ownerEnded ||
          ref.read(supportSessionUidProvider) != widget.uid) {
        return;
      }
      _reply.clear();
      _messageId = null;
    } catch (error) {
      if (mounted &&
          !_ownerEnded &&
          ref.read(supportSessionUidProvider) == widget.uid) {
        setState(() => _error = _sendFailure(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider.select((s) => s.value?.uid), (
      before,
      after,
    ) {
      if (before != after && after != widget.uid) _ownerEnded = true;
    });
    if (_ownerEnded || ref.watch(supportSessionUidProvider) != widget.uid) {
      return SupportDraftGuard(
        hasDraft: _reply.text.isNotEmpty,
        busy: _busy,
        child: Scaffold(
          appBar: AppBar(title: const Text('Trao đổi hỗ trợ')),
          body: Center(
            child: Text(
              _ownerEnded
                  ? 'Phiên đăng nhập đã thay đổi. Hãy mở lại yêu cầu.'
                  : _sessionMessage(ref.watch(authSessionProvider)),
            ),
          ),
        ),
      );
    }
    final ticket = ref.watch(supportTicketProvider(widget.ticketId));
    final messages = ref.watch(supportMessagesProvider(widget.ticketId));
    final value = !ticket.isLoading && !ticket.hasError ? ticket.value : null;
    return SupportDraftGuard(
      hasDraft: _reply.text.isNotEmpty,
      busy: _busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Trao đổi hỗ trợ')),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                Expanded(
                  child: ticket.when(
                    skipLoadingOnRefresh: false,
                    skipLoadingOnReload: false,
                    skipError: false,
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_failure(error)),
                          TextButton(
                            onPressed: () => ref.invalidate(
                              supportTicketProvider(widget.ticketId),
                            ),
                            child: const Text('Tải lại'),
                          ),
                        ],
                      ),
                    ),
                    data: (value) => value == null || value.uid != widget.uid
                        ? const Center(
                            child: Text('Yêu cầu không còn khả dụng.'),
                          )
                        : ListView(
                            key: const ValueKey('support-message-history'),
                            padding: const EdgeInsets.all(20),
                            children: [
                              Text(
                                value.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${value.type.label} · ${value.status.label}',
                              ),
                              const SizedBox(height: 8),
                              Text('Chủ đề: ${value.topicLabel}'),
                              const SizedBox(height: 16),
                              _MessageCard(
                                label: 'Bạn · ${_time(value.createdAt)}',
                                text: value.description,
                              ),
                              ...messages.when(
                                skipLoadingOnRefresh: false,
                                skipLoadingOnReload: false,
                                skipError: false,
                                loading: () => [
                                  const LinearProgressIndicator(),
                                ],
                                error: (error, _) => [
                                  Text(_failure(error)),
                                  TextButton(
                                    onPressed: () => ref.invalidate(
                                      supportMessagesProvider(widget.ticketId),
                                    ),
                                    child: const Text('Tải lại tin nhắn'),
                                  ),
                                ],
                                data: (items) => [
                                  for (final item in items)
                                    _MessageCard(
                                      label:
                                          '${item.isAdmin ? 'HealthMate hỗ trợ' : 'Bạn'} · ${_time(item.createdAt)}',
                                      text: item.text,
                                      admin: item.isAdmin,
                                    ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
                if (value != null && value.uid == widget.uid)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.55,
                    ),
                    child: SingleChildScrollView(
                      key: const ValueKey('support-composer-scroll'),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: _composer(value, messages),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _composer(
    SupportTicket value,
    AsyncValue<List<SupportMessage>> messages,
  ) {
    final full = value.messageCount >= 100;
    final hasDraft = _reply.text.isNotEmpty || _messageId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (full)
          const Text(
            'Cuộc trao đổi đã đủ 100 tin nhắn. Hãy tạo yêu cầu mới nếu cần.',
          ),
        if (!full || hasDraft) ...[
          TextField(
            key: const ValueKey('support-reply'),
            controller: _reply,
            minLines: 1,
            maxLines: 4,
            maxLength: 2000,
            readOnly: _busy || _messageId != null || full,
            decoration: const InputDecoration(labelText: 'Bổ sung thông tin'),
          ),
          if (full && _messageId == null)
            const Text('Nội dung đang soạn vẫn được giữ để bạn sao chép.'),
          if (!full && value.status == SupportStatus.resolved)
            const Text('Gửi tin nhắn mới sẽ mở lại yêu cầu.'),
          if (_busy) const _PendingSend(),
          if (_messageId != null && !_busy)
            const Text('Nội dung được giữ nguyên để thử gửi lại an toàn.'),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          FilledButton(
            key: const ValueKey('send-support-reply'),
            onPressed:
                _busy ||
                    messages.hasError ||
                    messages.isLoading ||
                    (full && _messageId == null)
                ? null
                : _send,
            child: Text(
              _busy
                  ? 'Đang gửi…'
                  : _messageId != null
                  ? 'Thử gửi lại'
                  : 'Gửi tin nhắn',
            ),
          ),
        ],
      ],
    );
  }
}

class _PendingSend extends StatelessWidget {
  const _PendingSend();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(),
        SizedBox(height: 8),
        Text('Đang gửi. Vui lòng chờ xác nhận trước khi rời màn hình.'),
      ],
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.label,
    required this.text,
    this.admin = false,
  });
  final String label, text;
  final bool admin;
  @override
  Widget build(BuildContext context) => Card(
    color: admin ? Theme.of(context).colorScheme.secondaryContainer : null,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          SelectableText(text),
        ],
      ),
    ),
  );
}
