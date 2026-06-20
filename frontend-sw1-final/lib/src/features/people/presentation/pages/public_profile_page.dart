import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/dm_service.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dm/presentation/pages/dm_chat_page.dart';
import '../providers/people_provider.dart';

// ── Avatar ────────────────────────────────────────────────────────────────────

class _ProfileAvatar extends StatelessWidget {
  final PublicProfile profile;
  final double size;

  const _ProfileAvatar({required this.profile, this.size = 80});

  @override
  Widget build(BuildContext context) {
    final url = profile.avatarUrl;
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
        profile.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

// ── Stat column ───────────────────────────────────────────────────────────────

class _StatCol extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatCol({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Post mini card ────────────────────────────────────────────────────────────

class _PostMini extends StatelessWidget {
  final Post post;

  const _PostMini({required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppPalette.gray700 : AppPalette.gray100;

    // Determinar imagen a mostrar
    String? imageUrl;
    if (post.postType == 'PHOTO' && post.imageUrl != null) {
      imageUrl = post.imageUrl;
    } else if (post.postType == 'OUTFIT' &&
        (post.outfit?.garmentOutfits.isNotEmpty ?? false)) {
      imageUrl = post.outfit!.garmentOutfits.first.garment?.path;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(bg, post.postType),
            )
          else
            _placeholder(bg, post.postType),
          // Badge de tipo
          Positioned(
            top: 6,
            left: 6,
            child: _TypeBadge(postType: post.postType),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(Color bg, String type) {
    final (icon, _) = switch (type) {
      'PHOTO' => (Icons.photo_camera, AppPalette.gray400),
      'TIP' => (Icons.lightbulb_outline, AppPalette.gray400),
      _ => (Icons.checkroom, AppPalette.gray400),
    };
    return Container(
      color: bg,
      child: Center(child: Icon(icon, color: AppPalette.gray400, size: 28)),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String postType;
  const _TypeBadge({required this.postType});

  @override
  Widget build(BuildContext context) {
    final (emoji, _) = switch (postType) {
      'PHOTO' => ('📷', const Color(0xFF0891B2)),
      'TIP' => ('💡', const Color(0xFFD69E2E)),
      _ => ('👗', AppPalette.accent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 10)),
    );
  }
}

// ── Follow list sheet ─────────────────────────────────────────────────────────

class _FollowListSheet extends StatefulWidget {
  final String userId;
  final bool showFollowers;

  const _FollowListSheet({required this.userId, required this.showFollowers});

  @override
  State<_FollowListSheet> createState() => _FollowListSheetState();
}

class _FollowListSheetState extends State<_FollowListSheet> {
  List<FollowUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = widget.showFollowers
          ? await UserService.getFollowers(widget.userId)
          : await UserService.getFollowing(widget.userId);
      if (mounted) setState(() { _users = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.showFollowers ? 'Seguidores' : 'Siguiendo';

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _users.isEmpty
                      ? Center(
                          child: Text(
                            'Sin ${title.toLowerCase()}',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.45)),
                          ),
                        )
                      : ListView.builder(
                          controller: ctrl,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: _users.length,
                          itemBuilder: (_, i) {
                            final u = _users[i];
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: AppPalette.accent,
                                backgroundImage: u.avatarUrl != null
                                    ? NetworkImage(u.avatarUrl!)
                                    : null,
                                child: u.avatarUrl == null
                                    ? Text(u.initials,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold))
                                    : null,
                              ),
                              title: Text(u.displayName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
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

// ── Public Profile Page ───────────────────────────────────────────────────────

class PublicProfilePage extends StatefulWidget {
  final String userId;
  final String? initialName;

  const PublicProfilePage({
    super.key,
    required this.userId,
    this.initialName,
  });

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  PublicProfile? _profile;
  List<Post> _posts = [];
  bool _loadingProfile = true;
  bool _loadingPosts = true;
  bool _followLoading = false;
  bool _dmLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_loadProfile(), _loadPosts()]);
  }

  Future<void> _loadProfile() async {
    try {
      final p = await UserService.getPublicProfile(widget.userId);
      if (mounted) setState(() { _profile = p; _loadingProfile = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadPosts() async {
    try {
      final p = await PostService.getPostsByUser(widget.userId);
      if (mounted) setState(() { _posts = p; _loadingPosts = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  Future<void> _toggleFollow() async {
    final p = _profile;
    if (p == null || _followLoading) return;

    setState(() => _followLoading = true);
    final wasFollowing = p.isFollowing;

    // Optimistic update
    setState(() {
      p.isFollowing = !wasFollowing;
      p.followerCount += wasFollowing ? -1 : 1;
      if (p.followerCount < 0) p.followerCount = 0;
    });

    try {
      if (wasFollowing) {
        await UserService.unfollow(p.id);
      } else {
        await UserService.follow(p.id);
      }
      if (mounted) {
        try {
          context.read<PeopleProvider>().syncFollowState(p.id, p.isFollowing);
        } catch (_) {}
      }
    } catch (e) {
      // Rollback
      if (mounted) {
        setState(() {
          p.isFollowing = wasFollowing;
          p.followerCount += wasFollowing ? 1 : -1;
          if (p.followerCount < 0) p.followerCount = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  void _showFollowerList(bool showFollowers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FollowListSheet(
        userId: widget.userId,
        showFollowers: showFollowers,
      ),
    );
  }

  Future<void> _openDm() async {
    if (_dmLoading) return;
    setState(() => _dmLoading = true);
    try {
      final conv = await DmService.getOrCreateConversation(widget.userId);
      final me = await StorageService.getUser();
      if (!mounted) return;
      final p = _profile;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DmChatPage(
          conversationId: conv.id,
          otherUser: p != null
              ? DmUser(
                  id: p.id,
                  name: p.name,
                  profilePhoto: p.profilePhoto,
                  avatarStyle: p.avatarStyle,
                )
              : null,
          currentUserId: me?.id ?? '',
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: AppPalette.error,
      ));
    } finally {
      if (mounted) setState(() => _dmLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _profile?.displayName ?? widget.initialName ?? 'Perfil',
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _profile == null
              ? _ErrorBody(error: _error!, onRetry: _load)
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeader(theme, isDark),
                    ),
                    if (_loadingPosts)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_posts.isEmpty)
                      SliverFillRemaining(
                        child: _EmptyPosts(
                          name: _profile?.displayName ?? 'Este usuario',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _PostMini(post: _posts[i]),
                            childCount: _posts.length,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final p = _profile!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar + stats
          Row(
            children: [
              _ProfileAvatar(profile: p, size: 80),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatCol(value: '${p.postCount}', label: 'Posts'),
                    _StatCol(
                      value: '${p.followerCount}',
                      label: 'Seguidores',
                      onTap: () => _showFollowerList(true),
                    ),
                    _StatCol(
                      value: '${p.followingCount}',
                      label: 'Siguiendo',
                      onTap: () => _showFollowerList(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Nombre
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              p.displayName,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          // Botones: Seguir + Mensaje
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _followLoading ? null : _toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.isFollowing
                        ? Colors.transparent
                        : theme.colorScheme.primary,
                    foregroundColor: p.isFollowing
                        ? theme.colorScheme.primary
                        : Colors.white,
                    side: p.isFollowing
                        ? BorderSide(
                            color: theme.colorScheme.primary, width: 1.5)
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: p.isFollowing ? 0 : null,
                  ),
                  child: _followLoading
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: p.isFollowing
                                ? theme.colorScheme.primary
                                : Colors.white,
                          ),
                        )
                      : Text(
                          p.isFollowing ? 'Siguiendo' : 'Seguir',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _dmLoading ? null : _openDm,
                icon: _dmLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('Mensaje',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(
                      color: theme.colorScheme.primary, width: 1.5),
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Separador posts
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, size: 16),
              const SizedBox(width: 6),
              Text('Publicaciones',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorBody({required this.error, required this.onRetry});

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

class _EmptyPosts extends StatelessWidget {
  final String name;
  const _EmptyPosts({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            Text('$name aún no publicó nada',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}
