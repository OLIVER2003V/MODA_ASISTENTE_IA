import 'package:flutter/material.dart';

import '../../../../core/services/dm_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'dm_chat_page.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtDate(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
  return '${date.day}/${date.month}/${date.year}';
}

// ── Conversation tile ─────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final DmConversation conv;
  final String currentUserId;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conv,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final other = conv.otherUser;
    final last = conv.lastMessage;
    final hasUnread = conv.unreadCount > 0 && last?.senderId != currentUserId;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: hasUnread
              ? theme.colorScheme.primary.withValues(alpha: 0.06)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: hasUnread
              ? Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                _ConvAvatar(user: other),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: theme.scaffoldBackgroundColor, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          other?.displayName ?? 'Usuario',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: hasUnread
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (last != null)
                        Text(
                          _fmtDate(last.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUnread
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (last?.senderId == currentUserId)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            last!.read
                                ? Icons.done_all
                                : Icons.done,
                            size: 14,
                            color: last.read
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          last?.content ?? 'Iniciá la conversación',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.8)
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread && conv.unreadCount > 1)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conv.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConvAvatar extends StatelessWidget {
  final DmUser? user;

  const _ConvAvatar({this.user});

  @override
  Widget build(BuildContext context) {
    final url = user?.avatarUrl;
    if (url != null) {
      return CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(url),
        backgroundColor: AppPalette.gray200,
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 26,
      backgroundColor: AppPalette.accent,
      child: Text(
        user?.initials ?? '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ── DM Inbox Page ─────────────────────────────────────────────────────────────

class DmInboxPage extends StatefulWidget {
  const DmInboxPage({super.key});

  @override
  State<DmInboxPage> createState() => _DmInboxPageState();
}

class _DmInboxPageState extends State<DmInboxPage> {
  List<DmConversation> _conversations = [];
  bool _loading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = await StorageService.getUser();
    if (mounted) setState(() => _currentUserId = user?.id);
    await _load();
  }

  Future<void> _load() async {
    try {
      final convs = await DmService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = convs;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _openChat(DmConversation conv) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DmChatPage(
          conversationId: conv.id,
          otherUser: conv.otherUser,
          currentUserId: _currentUserId ?? '',
        ),
      ),
    ).then((_) => _load()); // Reload on return to refresh unread counts
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        centerTitle: true,
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _conversations.isEmpty
              ? _ErrorView(error: _error!, onRetry: _load)
              : _conversations.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppPalette.accent,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _conversations.length,
                        itemBuilder: (_, i) => _ConversationTile(
                          conv: _conversations[i],
                          currentUserId: _currentUserId ?? '',
                          onTap: () => _openChat(_conversations[i]),
                        ),
                      ),
                    ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 52, color: AppPalette.error),
            const SizedBox(height: 14),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💬', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Sin mensajes',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Mandá un mensaje a alguien desde\n"Personas" para iniciar una charla',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
