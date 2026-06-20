import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/community_provider.dart';
import '../../../notifications/presentation/pages/notification_page.dart';
import '../../../people/presentation/pages/people_page.dart';
import '../../../people/presentation/pages/public_profile_page.dart';
import '../../../social_branding/presentation/pages/social_branding_page.dart';
import '../../../social_branding/presentation/providers/social_branding_provider.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

String _fmtDate(DateTime date) {
  final diff = DateTime.now().difference(date.toLocal());
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
  return '${date.day}/${date.month}/${date.year}';
}

// ── Avatar del autor ──────────────────────────────────────────────────────────

class _AuthorAvatar extends StatelessWidget {
  final PostUser? user;
  final double size;
  final VoidCallback? onTap;

  const _AuthorAvatar({this.user, this.size = 40, this.onTap});

  @override
  Widget build(BuildContext context) {
    final url = user?.avatarUrl;
    final Widget avatar = url != null
        ? CircleAvatar(
            radius: size / 2,
            backgroundImage: NetworkImage(url),
            backgroundColor: AppPalette.gray200,
            onBackgroundImageError: (_, __) {},
          )
        : CircleAvatar(
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

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}

// ── Caption con hashtags clicables + expandible ───────────────────────────────

class _CaptionText extends StatefulWidget {
  final String caption;
  final void Function(String tag) onHashtag;

  const _CaptionText({required this.caption, required this.onHashtag});

  @override
  State<_CaptionText> createState() => _CaptionTextState();
}

class _CaptionTextState extends State<_CaptionText> {
  bool _expanded = false;

  static const _maxLines = 4;
  static const _charsPerLine = 42;

  bool get _likelyOverflows =>
      widget.caption.split('\n').length > _maxLines ||
      widget.caption.length > _maxLines * _charsPerLine;

  List<InlineSpan> _buildSpans(BuildContext context) {
    final theme = Theme.of(context);
    // Tokenize preserving whitespace (including \n)
    final tokens = RegExp(r'[^\s]+|\s+')
        .allMatches(widget.caption)
        .map((m) => m.group(0)!)
        .toList();

    final spans = <InlineSpan>[];
    for (final token in tokens) {
      final trimmed = token.trim();
      if (trimmed.startsWith('#') && trimmed.length > 1) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => widget.onHashtag(trimmed),
            child: Text(
              token,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: token,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            fontSize: 14,
          ),
        ));
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final spans = _buildSpans(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(children: spans),
          maxLines: _expanded ? null : _maxLines,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (_likelyOverflows)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _expanded ? 'Ver menos' : 'Ver más',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Reaction Picker (overlay flotante) ───────────────────────────────────────

class _ReactionPicker extends StatelessWidget {
  final void Function(String type) onPick;

  const _ReactionPicker({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactionTypes.map((type) {
          final emoji = reactionEmojis[type]!;
          return GestureDetector(
            onTap: () => onPick(type),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Post Card ─────────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final Post post;
  final String? currentUserId;
  final void Function(String tag) onHashtag;
  final void Function() onDeleted;
  final void Function() onCommentTap;

  const _PostCard({
    required this.post,
    required this.currentUserId,
    required this.onHashtag,
    required this.onDeleted,
    required this.onCommentTap,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _showPicker = false;

  void _navigateToProfile() {
    final user = widget.post.user;
    if (user == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfilePage(
          userId: user.id,
          initialName: user.displayName,
        ),
      ),
    );
  }

  void _showOptionsSheet() {
    final isOwn = widget.post.userId != null &&
        widget.post.userId == widget.currentUserId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              if (isOwn) ...[
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppPalette.error),
                  title: const Text(
                    'Eliminar publicación',
                    style: TextStyle(color: AppPalette.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deletePost();
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Reportar publicación'),
                  onTap: () {
                    Navigator.pop(context);
                    _reportPost();
                  },
                ),
                if (widget.post.user != null)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text('Ver perfil de ${widget.post.user!.displayName}'),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToProfile();
                    },
                  ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text(
            '¿Eliminás esta publicación? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppPalette.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await PostService.deletePost(widget.post.id);
      widget.onDeleted();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppPalette.error),
      );
    }
  }

  void _reportPost() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reporte enviado. Gracias por mantener la comunidad.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showReactionsSheet() {
    if (widget.post.reactionCount == 0) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReactionsSheet(postId: widget.post.id),
    );
  }

  void _share() {
    // Copy caption or post info to clipboard
    final text = widget.post.caption?.isNotEmpty == true
        ? widget.post.caption!
        : 'Mirá este post en ModaIA';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copiado al portapapeles'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final post = widget.post;
    final provider = context.watch<CommunityProvider>();
    final myReaction = provider.myReactionFor(post.id);
    final isLoadingReaction = provider.isLoadingReaction(post.id);
    final canNavigateToProfile =
        post.user != null && post.user!.id != widget.currentUserId;

    return TapRegion(
      onTapOutside: (_) {
        if (_showPicker) setState(() => _showPicker = false);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
              child: Row(
                children: [
                  _AuthorAvatar(
                    user: post.user,
                    size: 42,
                    onTap: canNavigateToProfile ? _navigateToProfile : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: canNavigateToProfile ? _navigateToProfile : null,
                          child: Text(
                            post.user?.displayName ?? 'Usuario',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              decoration: canNavigateToProfile
                                  ? TextDecoration.none
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            Tooltip(
                              message:
                                  '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year} '
                                  '${post.createdAt.hour.toString().padLeft(2, '0')}:${post.createdAt.minute.toString().padLeft(2, '0')}',
                              child: Text(
                                _fmtDate(post.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _PostTypeBadge(postType: post.postType),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    onPressed: _showOptionsSheet,
                  ),
                ],
              ),
            ),

            // ── Contenido según tipo ───────────────────────────────────────────
            if (post.caption != null && post.caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: _CaptionText(
                    caption: post.caption!, onHashtag: widget.onHashtag),
              ),

            if (post.postType == 'OUTFIT' &&
                (post.outfit?.garmentOutfits.isNotEmpty ?? false))
              _GarmentsGrid(garments: post.outfit!.garmentOutfits),

            if (post.postType == 'PHOTO' && post.imageUrl != null)
              _PhotoContent(imageUrl: post.imageUrl!),

            if (post.postType == 'TIP')
              _TipContent(
                  caption: post.caption ?? '', onHashtag: widget.onHashtag),

            // ── Barra de acciones ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  // Reaction emoji (tap = react, long press = picker)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (_showPicker)
                        Positioned(
                          bottom: 44,
                          left: 0,
                          child: _ReactionPicker(
                            onPick: (type) {
                              setState(() => _showPicker = false);
                              context
                                  .read<CommunityProvider>()
                                  .react(post.id, type);
                            },
                          ),
                        ),
                      GestureDetector(
                        onTap: () {
                          if (_showPicker) {
                            setState(() => _showPicker = false);
                            return;
                          }
                          context.read<CommunityProvider>().react(
                                post.id,
                                myReaction ?? 'LIKE',
                              );
                        },
                        onLongPress: () =>
                            setState(() => _showPicker = !_showPicker),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: myReaction != null
                                ? theme.colorScheme.primary
                                    .withValues(alpha: 0.12)
                                : (isDark
                                    ? AppPalette.gray700
                                    : AppPalette.gray100),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: myReaction != null
                                  ? theme.colorScheme.primary
                                      .withValues(alpha: 0.35)
                                  : Colors.transparent,
                            ),
                          ),
                          child: isLoadingReaction
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : Text(
                                  myReaction != null
                                      ? reactionEmojis[myReaction]!
                                      : '🤍',
                                  style: const TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                    ],
                  ),

                  // Reaction count — tappable to see who reacted
                  GestureDetector(
                    onTap: _showReactionsSheet,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Text(
                        '${post.reactionCount}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: myReaction != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Comentarios
                  GestureDetector(
                    onTap: () {
                      if (_showPicker) setState(() => _showPicker = false);
                      widget.onCommentTap();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppPalette.gray700 : AppPalette.gray100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 18,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6)),
                          const SizedBox(width: 6),
                          Text(
                            '${post.commentCount}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Compartir
                  IconButton(
                    onPressed: _share,
                    icon: Icon(Icons.share_outlined,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.45)),
                    tooltip: 'Compartir',
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

// ── Post type badge ───────────────────────────────────────────────────────────

class _PostTypeBadge extends StatelessWidget {
  final String postType;
  const _PostTypeBadge({required this.postType});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (postType) {
      'PHOTO' => ('📷 Foto', const Color(0xFF0891B2)),
      'TIP' => ('💡 Tip', const Color(0xFFD69E2E)),
      _ => ('👗 Outfit', AppPalette.accent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Garments grid (posts OUTFIT) ──────────────────────────────────────────────

class _GarmentsGrid extends StatelessWidget {
  final List<PostGarmentOutfit> garments;
  const _GarmentsGrid({required this.garments});

  @override
  Widget build(BuildContext context) {
    final sorted = [...garments]..sort((a, b) => a.order.compareTo(b.order));
    final preview = sorted.take(4).toList();
    final extra = garments.length - 4;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppPalette.gray700 : AppPalette.gray100;

    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _garmentTile(preview[0].garment, bg),
            ),
            if (preview.length > 1) ...[
              const SizedBox(width: 3),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _garmentTile(preview[1].garment, bg)),
                    if (preview.length > 2) ...[
                      const SizedBox(height: 3),
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _garmentTile(
                                preview.length > 2 ? preview[2].garment : null,
                                bg),
                            if (extra > 0)
                              Container(
                                color: Colors.black.withValues(alpha: 0.45),
                                child: Center(
                                  child: Text('+$extra',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _garmentTile(PostGarment? g, Color bg) {
    if (g?.path == null) {
      return Container(
        color: bg,
        child: const Center(
            child: Icon(Icons.checkroom, color: AppPalette.gray400, size: 28)),
      );
    }
    return Image.network(
      g!.path!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
          color: bg,
          child: const Center(
              child:
                  Icon(Icons.checkroom, color: AppPalette.gray400, size: 28))),
      loadingBuilder: (_, child, p) => p == null
          ? child
          : Container(
              color: bg,
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }
}

// ── Foto content (posts PHOTO) ────────────────────────────────────────────────

class _PhotoContent extends StatelessWidget {
  final String imageUrl;
  const _PhotoContent({required this.imageUrl});

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Foto', style: TextStyle(color: Colors.white)),
          ),
          body: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, p) => p == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        constraints: const BoxConstraints(maxHeight: 320),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 200,
                color: AppPalette.gray100,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: AppPalette.gray100,
              child: const Center(
                  child: Icon(Icons.broken_image,
                      size: 40, color: AppPalette.gray400)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tip content (posts TIP) ───────────────────────────────────────────────────

class _TipContent extends StatelessWidget {
  final String caption;
  final void Function(String) onHashtag;
  const _TipContent({required this.caption, required this.onHashtag});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: _CaptionText(caption: caption, onHashtag: onHashtag),
          ),
        ],
      ),
    );
  }
}

// ── Comments sheet ────────────────────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  final Post post;
  final String? currentUserId;
  final VoidCallback onCommentAdded;
  final VoidCallback onCommentDeleted;

  const _CommentsSheet({
    required this.post,
    required this.currentUserId,
    required this.onCommentAdded,
    required this.onCommentDeleted,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  List<Comment> _comments = [];
  bool _loading = true;
  bool _sending = false;
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = await PostService.getComments(widget.post.id);
    if (!mounted) return;
    setState(() {
      _comments = c;
      _loading = false;
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final c = await PostService.createComment(widget.post.id, text);
      _ctrl.clear();
      setState(() => _comments = [..._comments, c]);
      widget.onCommentAdded();
      // Scroll to new comment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'), backgroundColor: AppPalette.error),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(Comment c) async {
    try {
      await PostService.deleteComment(c.id);
      setState(() => _comments.removeWhere((x) => x.id == c.id));
      widget.onCommentDeleted();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, __) => Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Título
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 20),
                    const SizedBox(width: 8),
                    Text('Comentarios',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${_comments.length}',
                          style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Lista
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('💬',
                                    style: TextStyle(fontSize: 36)),
                                const SizedBox(height: 10),
                                Text('Sin comentarios todavía',
                                    style: TextStyle(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5))),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _comments.length,
                            itemBuilder: (_, i) {
                              final c = _comments[i];
                              final isOwn = c.userId == widget.currentUserId;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _AuthorAvatar(user: c.user, size: 34),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                  c.user?.displayName ??
                                                      'Usuario',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 13)),
                                              const SizedBox(width: 6),
                                              Text(
                                                _fmtDate(c.createdAt),
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: theme
                                                        .colorScheme.onSurface
                                                        .withValues(
                                                            alpha: 0.4)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(c.content,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    if (isOwn)
                                      GestureDetector(
                                        onTap: () => _delete(c),
                                        child: Icon(Icons.delete_outline,
                                            size: 18,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.35)),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              // Input
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  border:
                      Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: 'Escribí un comentario…',
                          hintStyle: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                              fontSize: 14),
                          filled: true,
                          fillColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.05),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _send,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: _sending
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send,
                                color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Publish Modal ─────────────────────────────────────────────────────────────

class _PublishModal extends StatefulWidget {
  final String userId;
  final void Function(Post) onPublished;

  const _PublishModal({required this.userId, required this.onPublished});

  @override
  State<_PublishModal> createState() => _PublishModalState();
}

class _PublishModalState extends State<_PublishModal> {
  String? _selectedType;
  bool _publishing = false;

  // OUTFIT
  List<SimpleOutfit> _outfits = [];
  bool _loadingOutfits = false;
  SimpleOutfit? _selectedOutfit;

  // PHOTO
  File? _photo;
  bool _uploadingPhoto = false;

  // Caption (PHOTO + TIP)
  final _captionCtrl = TextEditingController();

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOutfits() async {
    setState(() => _loadingOutfits = true);
    try {
      final list = await PostService.getUserOutfits(widget.userId);
      if (mounted) {
        setState(() {
          _outfits = list;
          _loadingOutfits = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOutfits = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xfile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xfile == null || !mounted) return;
    setState(() => _photo = File(xfile.path));
  }

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      Post post;
      if (_selectedType == 'OUTFIT') {
        if (_selectedOutfit == null) throw Exception('Seleccioná un outfit');
        post = await PostService.createOutfitPost(
          _selectedOutfit!.id,
          caption: _captionCtrl.text.trim().isEmpty
              ? null
              : _captionCtrl.text.trim(),
        );
      } else if (_selectedType == 'PHOTO') {
        if (_photo == null) throw Exception('Seleccioná una foto');
        setState(() => _uploadingPhoto = true);
        final url = await PostService.uploadPostImage(_photo!);
        setState(() => _uploadingPhoto = false);
        post = await PostService.createPhotoPost(
          url,
          caption: _captionCtrl.text.trim().isEmpty
              ? null
              : _captionCtrl.text.trim(),
        );
      } else {
        final cap = _captionCtrl.text.trim();
        if (cap.isEmpty) throw Exception('Escribí algo para el tip');
        post = await PostService.createTipPost(cap);
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onPublished(post);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppPalette.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _publishing = false;
          _uploadingPhoto = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Text('Nueva publicación',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Paso 1: elegir tipo
            if (_selectedType == null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿Qué querés compartir?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _TypeTile(
                          emoji: '👗',
                          label: 'Outfit',
                          subtitle: 'Compartí un outfit de tu armario',
                          onTap: () {
                            setState(() => _selectedType = 'OUTFIT');
                            _loadOutfits();
                          },
                        ),
                        const SizedBox(width: 10),
                        _TypeTile(
                          emoji: '📷',
                          label: 'Foto',
                          subtitle: 'Subí una imagen de tu look',
                          onTap: () => setState(() => _selectedType = 'PHOTO'),
                        ),
                        const SizedBox(width: 10),
                        _TypeTile(
                          emoji: '💡',
                          label: 'Tip',
                          subtitle: 'Compartí un consejo de moda',
                          onTap: () => setState(() => _selectedType = 'TIP'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedType = null;
                          _selectedOutfit = null;
                          _photo = null;
                        }),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios,
                                size: 14, color: theme.colorScheme.primary),
                            Text('Cambiar tipo',
                                style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // OUTFIT
                      if (_selectedType == 'OUTFIT') ...[
                        Text('Elegí un outfit',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        if (_loadingOutfits)
                          const Center(child: CircularProgressIndicator())
                        else if (_outfits.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppPalette.gray100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                                'No tenés outfits. Generá uno desde el Chat IA.'),
                          )
                        else
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _outfits.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (_, i) {
                                final o = _outfits[i];
                                final selected = _selectedOutfit?.id == o.id;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedOutfit = o),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    width: 100,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? theme.colorScheme.primary
                                            : AppPalette.gray200,
                                        width: selected ? 2.5 : 1,
                                      ),
                                      color: selected
                                          ? theme.colorScheme.primary
                                              .withValues(alpha: 0.08)
                                          : theme.cardTheme.color,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (o.garmentOutfits.isNotEmpty &&
                                            o.garmentOutfits.first.garment
                                                    ?.path !=
                                                null)
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              o.garmentOutfits.first
                                                  .garment!.path!,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons.checkroom,
                                                      size: 40),
                                            ),
                                          )
                                        else
                                          const Icon(Icons.checkroom, size: 40),
                                        const SizedBox(height: 6),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          child: Text(
                                            o.name ?? 'Outfit',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600),
                                            maxLines: 2,
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 14),
                      ],

                      // PHOTO
                      if (_selectedType == 'PHOTO') ...[
                        GestureDetector(
                          onTap: _pickPhoto,
                          child: Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: AppPalette.gray100,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppPalette.gray300, width: 1.5),
                            ),
                            child: _photo != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: Image.file(_photo!,
                                        fit: BoxFit.cover,
                                        width: double.infinity),
                                  )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                            Icons
                                                .add_photo_alternate_outlined,
                                            size: 44,
                                            color: AppPalette.gray400),
                                        SizedBox(height: 8),
                                        Text('Tocar para elegir una foto',
                                            style: TextStyle(
                                                color: AppPalette.gray500,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (_selectedType == 'TIP') ...[
                        Text('Escribí tu tip de moda',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                      ] else ...[
                        Text('Descripción (opcional)',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                      ],
                      TextField(
                        controller: _captionCtrl,
                        maxLines: 3,
                        maxLength: 300,
                        decoration: InputDecoration(
                          hintText: _selectedType == 'TIP'
                              ? 'Ej: En verano, combiná telas livianas con #colores neutros…'
                              : 'Agregá una descripción o #hashtags…',
                          filled: true,
                          fillColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: AppPalette.gray200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: AppPalette.gray200),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _publishing ? null : _publish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _publishing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _uploadingPhoto
                                      ? 'Subiendo imagen…'
                                      : 'Publicar',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _TypeTile(
      {required this.emoji,
      required this.label,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppPalette.gray200),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5)),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reactions summary sheet ───────────────────────────────────────────────────

class _ReactionsSheet extends StatefulWidget {
  final String postId;
  const _ReactionsSheet({required this.postId});

  @override
  State<_ReactionsSheet> createState() => _ReactionsSheetState();
}

class _ReactionsSheetState extends State<_ReactionsSheet> {
  List<Interaction> _reactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    PostService.getPostReactions(widget.postId).then((r) {
      if (mounted) setState(() { _reactions = r; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  const Text('❤️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text('Reacciones',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _reactions.isEmpty
                      ? Center(
                          child: Text('Sin reacciones',
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5))))
                      : ListView.builder(
                          controller: ctrl,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: _reactions.length,
                          itemBuilder: (_, i) {
                            final r = _reactions[i];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading:
                                  _AuthorAvatar(user: r.user, size: 40),
                              title: Text(r.user?.displayName ?? 'Usuario',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              trailing: Text(
                                  reactionEmojis[r.reactionType] ?? '❤️',
                                  style: const TextStyle(fontSize: 22)),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final CommunityProvider provider;
  const _FilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final typeFilter = provider.typeFilter;
    final timeFilter = provider.timeFilter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          _Chip(
            label: '👗 Outfits',
            isActive: typeFilter == 'OUTFIT',
            isDark: isDark,
            onTap: () => provider.setTypeFilter('OUTFIT'),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: '📷 Fotos',
            isActive: typeFilter == 'PHOTO',
            isDark: isDark,
            onTap: () => provider.setTypeFilter('PHOTO'),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: '💡 Tips',
            isActive: typeFilter == 'TIP',
            isDark: isDark,
            onTap: () => provider.setTypeFilter('TIP'),
          ),
          const SizedBox(width: 12),
          Container(
              height: 20,
              width: 1,
              color: theme.dividerColor),
          const SizedBox(width: 12),
          _Chip(
            label: 'Hoy',
            isActive: timeFilter == 'TODAY',
            isDark: isDark,
            onTap: () => provider.setTimeFilter('TODAY'),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Esta semana',
            isActive: timeFilter == 'WEEK',
            isDark: isDark,
            onTap: () => provider.setTimeFilter('WEEK'),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Este mes',
            isActive: timeFilter == 'MONTH',
            isDark: isDark,
            onTap: () => provider.setTimeFilter('MONTH'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary
              : (isDark ? AppPalette.gray700 : AppPalette.gray100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary : AppPalette.gray200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ── Community Page ────────────────────────────────────────────────────────────

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(_onTabChange);
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadPosts();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (_tabCtrl.indexIsChanging) return;
    final provider = context.read<CommunityProvider>();
    if (_tabCtrl.index == 0) {
      provider.setFeedMode(FeedMode.global);
    } else {
      provider.setFeedMode(FeedMode.following);
    }
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<CommunityProvider>().loadMore();
    }
  }

  void _onHashtag(String tag) {
    context.read<CommunityProvider>().setFeedMode(FeedMode.tag, tag: tag);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mostrando posts con $tag'),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Limpiar',
          onPressed: () =>
              context.read<CommunityProvider>().setFeedMode(FeedMode.global),
        ),
      ),
    );
  }

  void _showComments(Post post) {
    final provider = context.read<CommunityProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        post: post,
        currentUserId: provider.currentUserId,
        onCommentAdded: () => provider.incrementCommentCount(post.id),
        onCommentDeleted: () => provider.decrementCommentCount(post.id),
      ),
    );
  }

  void _openPublish() async {
    final provider = context.read<CommunityProvider>();
    final userId = provider.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iniciá sesión para publicar')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PublishModal(
        userId: userId,
        onPublished: (post) {
          provider.addPostToFeed(post);
          provider.loadPosts(force: true);
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Publicado exitosamente'),
              backgroundColor: AppPalette.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Consumer<CommunityProvider>(
      builder: (_, provider, __) {
        return Scaffold(
          appBar: AppBar(
            title: provider.activeTag != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(provider.activeTag!,
                          style:
                              TextStyle(color: theme.colorScheme.primary)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          provider.setFeedMode(FeedMode.global);
                          _tabCtrl.index = 0;
                        },
                        child: Icon(Icons.close,
                            size: 18, color: theme.colorScheme.primary),
                      ),
                    ],
                  )
                : Text(l.communityTitle),
            centerTitle: true,
            bottom: provider.activeTag == null
                ? TabBar(
                    controller: _tabCtrl,
                    tabs: [
                      Tab(text: l.forYou),
                      Tab(text: l.following),
                    ],
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    indicatorWeight: 3,
                  )
                : null,
            actions: [
              const NotificationBell(),
              IconButton(
                icon: const Icon(Icons.people_alt_outlined),
                tooltip: 'Buscar personas',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PeoplePage()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.auto_awesome_outlined),
                tooltip: 'Branding personal',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => SocialBrandingProvider(),
                      child: const SocialBrandingPage(),
                    ),
                  ),
                ),
              ),
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => provider.loadPosts(force: true),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openPublish,
            icon: const Icon(Icons.add),
            label: Text(l.publish),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(CommunityProvider provider) {
    if (provider.isLoading && !provider.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && !provider.hasData) {
      return _ErrorView(
        message: provider.errorMessage!,
        onRetry: () => provider.loadPosts(force: true),
      );
    }
    if (!provider.hasData) {
      return _EmptyView(
        isFollowingMode: provider.feedMode == FeedMode.following,
        activeTag: provider.activeTag,
      );
    }

    final posts = provider.posts;

    return RefreshIndicator(
      onRefresh: () => provider.loadPosts(force: true),
      color: AppPalette.accent,
      child: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // Filter chips
          SliverToBoxAdapter(
            child: _FilterBar(provider: provider),
          ),

          // Empty state when filters active but no results
          if (posts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      'Sin resultados con estos filtros',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        provider.setTypeFilter(null);
                        provider.setTimeFilter('ALL');
                      },
                      child: const Text('Limpiar filtros'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i == posts.length) {
                      return provider.isLoadingMore
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                  child: CircularProgressIndicator()),
                            )
                          : const SizedBox(height: 4);
                    }
                    final post = posts[i];
                    return FadeInUp(
                      key: ValueKey(post.id),
                      duration: Duration(
                          milliseconds: 250 + (i.clamp(0, 5) * 60)),
                      child: _PostCard(
                        post: post,
                        currentUserId: provider.currentUserId,
                        onHashtag: _onHashtag,
                        onDeleted: () =>
                            provider.removePostFromFeed(post.id),
                        onCommentTap: () => _showComments(post),
                      ),
                    );
                  },
                  childCount: posts.length + 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty / Error views ───────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 56, color: AppPalette.error.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text('Error al cargar',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool isFollowingMode;
  final String? activeTag;
  const _EmptyView({required this.isFollowingMode, this.activeTag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (emoji, title, subtitle) = activeTag != null
        ? ('🔍', 'Sin resultados', 'No hay posts con $activeTag')
        : isFollowingMode
            ? ('👥', 'Sin publicaciones',
                'Seguí a otros usuarios para ver su contenido aquí')
            : ('🌟', 'Sin publicaciones',
                'Sé el primero en compartir tu outfit');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
