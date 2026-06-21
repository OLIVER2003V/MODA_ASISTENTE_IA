import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/dm_service.dart';
import '../../../../core/theme/app_theme.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String _fmtDateLabel(DateTime d) {
  final now = DateTime.now();
  final diff = now.difference(d);
  if (diff.inDays == 0) return 'Hoy';
  if (diff.inDays == 1) return 'Ayer';
  return '${d.day}/${d.month}/${d.year}';
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _ChatAvatar extends StatelessWidget {
  final DmUser? user;
  final double size;

  const _ChatAvatar({this.user, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final url = user?.avatarUrl;
    if (url != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(url),
        backgroundColor: AppPalette.gray200,
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppPalette.accent,
      child: Text(
        user?.initials ?? '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

// ── Date separator ────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _fmtDateLabel(date),
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final DmMessage message;
  final bool isMe;
  final bool isFirst;
  final bool isOptimistic;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isFirst,
    this.isOptimistic = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final myBubbleColor = theme.colorScheme.primary;
    final otherBubbleColor =
        isDark ? AppPalette.gray700 : const Color(0xFFF0F0F0);

    final myTextColor = Colors.white;
    final otherTextColor = theme.colorScheme.onSurface;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : (isFirst ? 4 : 18)),
      bottomRight: Radius.circular(isMe ? (isFirst ? 4 : 18) : 18),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: isFirst ? 6 : 2,
          bottom: 2,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? myBubbleColor : otherBubbleColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? myTextColor : otherTextColor,
                fontSize: 14.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _fmtTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: (isMe ? myTextColor : otherTextColor)
                        .withValues(alpha: 0.55),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  if (isOptimistic)
                    Icon(Icons.access_time,
                        size: 11,
                        color: myTextColor.withValues(alpha: 0.55))
                  else
                    Icon(
                      message.read ? Icons.done_all : Icons.done,
                      size: 12,
                      color: message.read
                          ? Colors.lightBlueAccent.withValues(alpha: 0.9)
                          : myTextColor.withValues(alpha: 0.55),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 10
            : MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: controller,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Escribí un mensaje…',
                  hintStyle: TextStyle(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSending
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final String name;
  const _EmptyChat({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👋', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            Text(
              '¡Iniciá la conversación!',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Mandá un mensaje a $name',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── DM Chat Page ──────────────────────────────────────────────────────────────

class DmChatPage extends StatefulWidget {
  final String conversationId;
  final DmUser? otherUser;
  final String currentUserId;

  const DmChatPage({
    super.key,
    required this.conversationId,
    required this.otherUser,
    required this.currentUserId,
  });

  @override
  State<DmChatPage> createState() => _DmChatPageState();
}

class _DmChatPageState extends State<DmChatPage> with WidgetsBindingObserver {
  List<DmMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _isTyping = false;
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _pollTimer;
  Timer? _typingTimer;
  String? _lastKnownId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl.addListener(_onTextChanged);
    _loadMessages();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _poll(),
    );
  }

  void _onTextChanged() {
    if (!_isTyping) setState(() => _isTyping = true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isTyping = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _typingTimer?.cancel();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _poll();
    }
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await DmService.getMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loading = false;
        if (msgs.isNotEmpty) _lastKnownId = msgs.last.id;
      });
      _scrollToBottom(instant: true);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _poll() async {
    if (!mounted || _sending) return;
    try {
      final msgs = await DmService.getMessages(widget.conversationId);
      if (!mounted) return;
      if (msgs.isEmpty) return;
      final newLastId = msgs.last.id;
      if (newLastId != _lastKnownId) {
        setState(() {
          _messages = msgs;
          _lastKnownId = newLastId;
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;

    _ctrl.clear();
    final optimisticId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = DmMessage(
      id: optimisticId,
      content: text,
      conversationId: widget.conversationId,
      senderId: widget.currentUserId,
      read: false,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages = [..._messages, optimistic];
      _sending = true;
    });
    _scrollToBottom();

    try {
      final sent = await DmService.sendMessage(widget.conversationId, text);
      if (!mounted) return;
      setState(() {
        _messages = [
          ..._messages.where((m) => m.id != optimisticId),
          sent,
        ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _lastKnownId = sent.id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.id == optimisticId);
        _ctrl.text = text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppPalette.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom({bool instant = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      if (instant) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      } else {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final other = widget.otherUser;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            _ChatAvatar(user: other, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    other?.displayName ?? 'Chat',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_isTyping)
                    Text(
                      'Escribiendo...',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppPalette.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _EmptyChat(name: other?.displayName ?? 'esta persona')
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding:
                            const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isMe =
                              msg.senderId == widget.currentUserId;
                          final isFirst = i == 0 ||
                              _messages[i - 1].senderId != msg.senderId;
                          final showDate = i == 0 ||
                              msg.createdAt
                                      .difference(
                                          _messages[i - 1].createdAt)
                                      .inMinutes
                                      .abs() >
                                  10;
                          final isOptimistic =
                              msg.id.startsWith('temp_');

                          return Column(
                            children: [
                              if (showDate)
                                _DateSeparator(date: msg.createdAt),
                              _MessageBubble(
                                message: msg,
                                isMe: isMe,
                                isFirst: isFirst,
                                isOptimistic: isOptimistic,
                              ),
                            ],
                          );
                        },
                      ),
          ),
          _InputBar(
            controller: _ctrl,
            isSending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}
