import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/dm_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dm/presentation/pages/dm_chat_page.dart';
import '../providers/people_provider.dart';
import 'public_profile_page.dart';

// ── User avatar ───────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final UserSuggestion user;
  final double size;

  const _UserAvatar({required this.user, this.size = 46});

  @override
  Widget build(BuildContext context) {
    final url = user.avatarUrl;
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
        user.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

// ── User card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatefulWidget {
  final UserSuggestion user;
  final VoidCallback onFollow;
  final bool isFollowLoading;

  const _UserCard({
    super.key,
    required this.user,
    required this.onFollow,
    required this.isFollowLoading,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _dmLoading = false;

  void _openProfile() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PublicProfilePage(
        userId: widget.user.id,
        initialName: widget.user.displayName,
      ),
    ));
  }

  Future<void> _openDm() async {
    if (_dmLoading) return;
    setState(() => _dmLoading = true);
    try {
      final conv =
          await DmService.getOrCreateConversation(widget.user.id);
      final me = await StorageService.getUser();
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DmChatPage(
          conversationId: conv.id,
          otherUser: DmUser(
            id: widget.user.id,
            name: widget.user.name,
            profilePhoto: widget.user.profilePhoto,
            avatarStyle: widget.user.avatarStyle,
          ),
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

    return GestureDetector(
      onTap: _openProfile,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _UserAvatar(user: widget.user, size: 50),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.displayName,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.people_outline,
                        label: '${widget.user.followerCount}',
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        icon: Icons.grid_view_rounded,
                        label: '${widget.user.postCount}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Botón mensaje
            _dmLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: _openDm,
                    tooltip: 'Enviar mensaje',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 36, minHeight: 36),
                  ),
            const SizedBox(width: 4),
            _FollowButton(
              isFollowing: widget.user.isFollowing,
              isLoading: widget.isFollowLoading,
              onTap: widget.onFollow,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 12, color: c)),
      ],
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback onTap;

  const _FollowButton({
    required this.isFollowing,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isFollowing
              ? Colors.transparent
              : theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          border: isFollowing
              ? Border.all(color: theme.colorScheme.primary, width: 1.5)
              : null,
        ),
        child: isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isFollowing
                      ? theme.colorScheme.primary
                      : Colors.white,
                ),
              )
            : Text(
                isFollowing ? 'Siguiendo' : 'Seguir',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isFollowing ? theme.colorScheme.primary : Colors.white,
                ),
              ),
      ),
    );
  }
}

// ── People Page ───────────────────────────────────────────────────────────────

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PeopleProvider>().loadSuggestions();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<PeopleProvider>(
      builder: (_, provider, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Personas'),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  onChanged: provider.onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar personas…',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: provider.hasQuery
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              provider.clearSearch();
                              _searchFocus.unfocus();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
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
          ),
          body: provider.hasQuery
              ? _SearchResultsBody(provider: provider)
              : _SuggestionsBody(provider: provider),
        );
      },
    );
  }
}

// ── Suggestions body ──────────────────────────────────────────────────────────

class _SuggestionsBody extends StatelessWidget {
  final PeopleProvider provider;
  const _SuggestionsBody({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingSuggestions && provider.suggestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppPalette.error),
            const SizedBox(height: 12),
            Text(provider.error!,
                style: const TextStyle(color: AppPalette.gray500)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.loadSuggestions(force: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (provider.suggestions.isEmpty) {
      return const _EmptyState(
        emoji: '👥',
        title: 'Sin sugerencias',
        subtitle: 'No hay usuarios sugeridos por el momento',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadSuggestions(force: true),
      color: AppPalette.accent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SectionHeader(
            title: 'Personas sugeridas',
            subtitle: '${provider.suggestions.length} usuarios',
          ),
          const SizedBox(height: 12),
          ...provider.suggestions.map(
            (user) => _UserCard(
              key: ValueKey(user.id),
              user: user,
              isFollowLoading: provider.isFollowLoading(user.id),
              onFollow: () => provider.toggleFollow(user),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search results body ───────────────────────────────────────────────────────

class _SearchResultsBody extends StatelessWidget {
  final PeopleProvider provider;
  const _SearchResultsBody({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.searchResults.isEmpty) {
      return _EmptyState(
        emoji: '🔍',
        title: 'Sin resultados',
        subtitle: 'No hay usuarios con "${provider.query}"',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SectionHeader(
          title: 'Resultados',
          subtitle: '${provider.searchResults.length} encontrados',
        ),
        const SizedBox(height: 12),
        ...provider.searchResults.map(
          (user) => _UserCard(
            key: ValueKey(user.id),
            user: user,
            isFollowLoading: provider.isFollowLoading(user.id),
            onFollow: () => provider.toggleFollow(user),
          ),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.45))),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.emoji, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
