import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/social_branding_service.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../../../../features/wardrobe/presentation/providers/wardrobe_provider.dart';
import '../../../../features/profile/presentation/providers/profile_provider.dart';
import '../../../../features/community/presentation/providers/community_provider.dart';
import '../providers/social_branding_provider.dart';

// ── Network config ────────────────────────────────────────────────────────────

class _Net {
  final String id;
  final String label;
  final IconData icon;
  final Color primary;
  final Color accent;

  const _Net({
    required this.id,
    required this.label,
    required this.icon,
    required this.primary,
    required this.accent,
  });

  /// Builds a platform-correct search URL for the given term.
  String searchUrl(String term) {
    switch (id) {
      case 'instagram':
        // Instagram hashtag: remove all non-alphanumeric chars (including spaces)
        final tag = term.toLowerCase().replaceAll(RegExp(r'[^a-z0-9áéíóúüñ]'), '');
        return 'https://www.instagram.com/explore/tags/$tag/';
      case 'tiktok':
        return 'https://www.tiktok.com/search?q=${Uri.encodeQueryComponent(term)}';
      case 'linkedin':
        return 'https://www.linkedin.com/search/results/content/?keywords=${Uri.encodeQueryComponent(term)}';
      case 'facebook':
      default:
        return 'https://www.facebook.com/search/top/?q=${Uri.encodeQueryComponent(term)}';
    }
  }
}

const _nets = [
  _Net(
    id: 'instagram',
    label: 'Instagram',
    icon: Icons.camera_alt_outlined,
    primary: Color(0xFFE1306C),
    accent: Color(0xFF833AB4),
  ),
  _Net(
    id: 'tiktok',
    label: 'TikTok',
    icon: Icons.music_note_outlined,
    primary: Color(0xFF010101),
    accent: Color(0xFF69C9D0),
  ),
  _Net(
    id: 'linkedin',
    label: 'LinkedIn',
    icon: Icons.business_center_outlined,
    primary: Color(0xFF0A66C2),
    accent: Color(0xFF004182),
  ),
  _Net(
    id: 'facebook',
    label: 'Facebook',
    icon: Icons.groups_outlined,
    primary: Color(0xFF1877F2),
    accent: Color(0xFF0C4A9D),
  ),
];

_Net _netFor(String id) =>
    _nets.firstWhere((n) => n.id == id, orElse: () => _nets[0]);

// ── Page ──────────────────────────────────────────────────────────────────────

class SocialBrandingPage extends StatefulWidget {
  const SocialBrandingPage({super.key});

  @override
  State<SocialBrandingPage> createState() => _SocialBrandingPageState();
}

class _SocialBrandingPageState extends State<SocialBrandingPage> {
  String? _previewImageUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<SocialBrandingProvider>();
      if (p.result == null && !p.loading) p.load();
      context.read<ProfileProvider>().loadProfile();
      context.read<WardrobeProvider>().loadCloset();
    });
  }

  Future<void> _showImagePicker() async {
    final url = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImagePickerSheet(
        currentUserId:
            context.read<ProfileProvider>().user?.id ?? '',
      ),
    );
    if (url != null && mounted) {
      setState(() => _previewImageUrl = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SocialBrandingProvider, ProfileProvider>(
      builder: (context, provider, profileProvider, _) {
        final net = _netFor(provider.selectedNetwork);
        final user = profileProvider.user;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.personalBranding),
            actions: [
              if (!provider.loading)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Regenerar',
                  onPressed: () => provider.load(refresh: true),
                ),
            ],
          ),
          body: Column(
            children: [
              _NetworkSelector(
                selected: provider.selectedNetwork,
                onSelect: provider.selectNetwork,
              ),
              const Divider(height: 1),
              Expanded(
                child: _buildBody(context, provider, net, user),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    SocialBrandingProvider provider,
    _Net net,
    User? user,
  ) {
    if (provider.loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: net.primary),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.generatingGuideFor(net.label),
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              'La IA está analizando tu perfil de moda',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      );
    }

    if (provider.error != null) {
      return _ErrorState(
          message: provider.error!, onRetry: () => provider.load());
    }

    final result = provider.result;
    if (result == null) {
      return _EmptyState(net: net, onLoad: () => provider.load());
    }

    return _ResultView(
      result: result,
      net: net,
      user: user,
      previewImageUrl: _previewImageUrl,
      onPickImage: _showImagePicker,
    );
  }
}

// ── Network selector ──────────────────────────────────────────────────────────

class _NetworkSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _NetworkSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: _nets.map((net) {
          final isSelected = net.id == selected;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => onSelect(net.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? net.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? net.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(net.icon,
                          size: 22,
                          color: isSelected
                              ? net.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.45)),
                      const SizedBox(height: 4),
                      Text(
                        net.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? net.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Result view ───────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final SocialBrandingResult result;
  final _Net net;
  final User? user;
  final String? previewImageUrl;
  final VoidCallback onPickImage;

  const _ResultView({
    required this.result,
    required this.net,
    required this.user,
    required this.previewImageUrl,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!result.hasProfile) ...[
          _WarningBanner(
            message:
                'Completá tu perfil (estilos, colores, profesión) para recomendaciones más personalizadas.',
          ),
          const SizedBox(height: 12),
        ],

        _HeroCard(net: net, tono: result.tono),
        const SizedBox(height: 14),

        _SectionCard(
          title: 'Vista previa de publicación',
          icon: Icons.phone_android_outlined,
          color: net.primary,
          child: _PostPreviewCard(
            net: net,
            result: result,
            user: user,
            previewImageUrl: previewImageUrl,
            onPickImage: onPickImage,
          ),
        ),
        const SizedBox(height: 12),

        if (result.contentCalendar.isNotEmpty) ...[
          _SectionCard(
            title: 'Calendario semanal',
            icon: Icons.calendar_month_outlined,
            color: net.primary,
            child: _ContentCalendar(
                calendar: result.contentCalendar, netColor: net.primary),
          ),
          const SizedBox(height: 12),
        ],

        if (result.captionTemplates.isNotEmpty) ...[
          _SectionCard(
            title: 'Captions listos para copiar',
            icon: Icons.content_copy_outlined,
            color: net.primary,
            child: _CaptionTemplatesSection(
                templates: result.captionTemplates, netColor: net.primary),
          ),
          const SizedBox(height: 12),
        ],

        _SectionCard(
          title: 'Imagen Personal',
          icon: Icons.palette_outlined,
          color: net.primary,
          child: _ImagenSection(imagen: result.imagen, netColor: net.primary),
        ),
        const SizedBox(height: 12),

        _SectionCard(
          title: 'Estrategia de Contenido',
          icon: Icons.grid_view_outlined,
          color: net.primary,
          child: _ContenidoSection(
              contenido: result.contenido, netColor: net.primary),
        ),
        const SizedBox(height: 12),

        if (result.profileChecklist.isNotEmpty) ...[
          _SectionCard(
            title: 'Optimizá tu perfil',
            icon: Icons.checklist_outlined,
            color: net.primary,
            child: _ProfileChecklist(
                items: result.profileChecklist, netColor: net.primary),
          ),
          const SizedBox(height: 12),
        ],

        _SectionCard(
          title: 'Hashtags Recomendados',
          icon: Icons.tag,
          color: net.primary,
          child: _HashtagsSection(
              hashtags: result.hashtags, netColor: net.primary),
        ),
        const SizedBox(height: 12),

        _SectionCard(
          title: 'Mejores Horarios',
          icon: Icons.access_time_outlined,
          color: net.primary,
          child: _HorariosSection(horarios: result.horarios),
        ),
        const SizedBox(height: 12),

        if (result.trendingSearches.isNotEmpty) ...[
          _SectionCard(
            title: 'Buscá inspiración en ${net.label}',
            icon: Icons.explore_outlined,
            color: net.primary,
            child: _InspirationSection(
                searches: result.trendingSearches, net: net),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

// ── Mock post preview ─────────────────────────────────────────────────────────

class _PostPreviewCard extends StatelessWidget {
  final _Net net;
  final SocialBrandingResult result;
  final User? user;
  final String? previewImageUrl;
  final VoidCallback onPickImage;

  const _PostPreviewCard({
    required this.net,
    required this.result,
    required this.user,
    required this.previewImageUrl,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border =
        isDark ? const Color(0xFF333333) : const Color(0xFFDBDBDB);

    final caption = result.captionTemplates.isNotEmpty
        ? result.captionTemplates.first.corta
        : (result.contenido.ideas.isNotEmpty
            ? result.contenido.ideas.first
            : '');
    final hashtagLine =
        result.hashtags.take(3).map((h) => h.startsWith('#') ? h : '#$h').join(' ');

    return switch (net.id) {
      'instagram' => _InstagramPreview(
          net: net,
          caption: caption,
          hashtags: hashtagLine,
          bg: bg,
          border: border,
          paleta: result.imagen.paleta,
          user: user,
          previewImageUrl: previewImageUrl,
          onPickImage: onPickImage,
        ),
      'tiktok' => _TikTokPreview(
          net: net,
          caption: caption,
          hashtags: hashtagLine,
          user: user,
          previewImageUrl: previewImageUrl,
          onPickImage: onPickImage,
        ),
      'linkedin' => _LinkedInPreview(
          net: net,
          caption: caption,
          bg: bg,
          border: border,
          user: user,
          previewImageUrl: previewImageUrl,
          onPickImage: onPickImage,
        ),
      _ => _FacebookPreview(
          net: net,
          caption: caption,
          bg: bg,
          border: border,
          user: user,
          previewImageUrl: previewImageUrl,
          onPickImage: onPickImage,
        ),
    };
  }
}

// ── Shared preview helpers ────────────────────────────────────────────────────

Widget _buildPhotoArea({
  required String? imageUrl,
  required VoidCallback onPickImage,
  required Color netColor,
  required Color accentColor,
  required List<String> paleta,
  required double height,
  BorderRadius? borderRadius,
}) {
  Color mockColor = netColor;
  if (paleta.isNotEmpty) {
    try {
      final hex = paleta.first.replaceFirst('#', '');
      mockColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}
  }

  final inner = imageUrl != null
      ? Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: mockColor.withValues(alpha: 0.2),
                child: const Center(child: Icon(Icons.broken_image_outlined)),
              ),
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(
                      color: mockColor.withValues(alpha: 0.1),
                      child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: onPickImage,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz, color: Colors.white, size: 13),
                      SizedBox(width: 4),
                      Text('Cambiar',
                          style:
                              TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )
      : GestureDetector(
          onTap: onPickImage,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [mockColor, accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    color: Colors.white.withValues(alpha: 0.9), size: 38),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Tocar para elegir imagen',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );

  return ClipRRect(
    borderRadius: borderRadius ?? BorderRadius.zero,
    child: SizedBox(height: height, child: inner),
  );
}

Widget _buildUserAvatar(User? user, {double radius = 15, Color? ringColor}) {
  final avatarUrl = user?.avatarUrl;
  final initials = user?.initials ?? '?';

  final child = avatarUrl != null
      ? CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(avatarUrl),
        )
      : CircleAvatar(
          radius: radius,
          backgroundColor:
              (ringColor ?? Colors.grey).withValues(alpha: 0.2),
          child: Text(
            initials,
            style: TextStyle(
              fontSize: radius * 0.8,
              fontWeight: FontWeight.bold,
              color: ringColor ?? Colors.grey,
            ),
          ),
        );

  if (ringColor == null) return child;

  return Container(
    width: radius * 2 + 4,
    height: radius * 2 + 4,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [ringColor, ringColor.withValues(alpha: 0.4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    padding: const EdgeInsets.all(2),
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(1.5),
      child: ClipOval(child: child),
    ),
  );
}

// ── Instagram preview ─────────────────────────────────────────────────────────

class _InstagramPreview extends StatelessWidget {
  final _Net net;
  final String caption;
  final String hashtags;
  final Color bg;
  final Color border;
  final List<String> paleta;
  final User? user;
  final String? previewImageUrl;
  final VoidCallback onPickImage;

  const _InstagramPreview({
    required this.net,
    required this.caption,
    required this.hashtags,
    required this.bg,
    required this.border,
    required this.paleta,
    required this.user,
    required this.previewImageUrl,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final handle =
        user?.name?.toLowerCase().replaceAll(' ', '_') ?? 'tu_cuenta';

    return Center(
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Row(
                children: [
                  _buildUserAvatar(user, radius: 17, ringColor: net.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(handle,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12)),
                        Text('Publicación · Ahora',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Icon(Icons.more_horiz,
                      color: Colors.grey.shade400, size: 18),
                ],
              ),
            ),
            // Photo area
            _buildPhotoArea(
              imageUrl: previewImageUrl,
              onPickImage: onPickImage,
              netColor: net.primary,
              accentColor: net.accent,
              paleta: paleta,
              height: 180,
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Row(
                children: [
                  const Text('🤍', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Text('💬', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Text('✈️', style: TextStyle(fontSize: 20)),
                  const Spacer(),
                  const Text('🔖', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
              child: Text('1.243 Me gusta',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 11)),
            ),
            if (caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                    children: [
                      TextSpan(
                          text: '$handle ',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                      TextSpan(text: caption),
                    ],
                  ),
                ),
              ),
            if (hashtags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Text(hashtags,
                    style: TextStyle(
                        fontSize: 10,
                        color: net.primary,
                        fontWeight: FontWeight.w500)),
              ),
          ],
        ),
      ),
    );
  }
}

// ── TikTok preview ────────────────────────────────────────────────────────────

class _TikTokPreview extends StatelessWidget {
  final _Net net;
  final String caption;
  final String hashtags;
  final User? user;
  final String? previewImageUrl;
  final VoidCallback onPickImage;

  const _TikTokPreview({
    required this.net,
    required this.caption,
    required this.hashtags,
    required this.user,
    required this.previewImageUrl,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final handle =
        user?.name?.toLowerCase().replaceAll(' ', '_') ?? 'tu_cuenta';

    return Center(
      child: SizedBox(
        width: 180,
        height: 310,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background: real image or dark gradient
              previewImageUrl != null
                  ? Image.network(
                      previewImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF1A1A2E)),
                    )
                  : GestureDetector(
                      onTap: onPickImage,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color:
                                    Colors.white.withValues(alpha: 0.7),
                                size: 40),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Elegir imagen',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                    ),

              // Dark gradient overlay at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 150,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Right sidebar
              Positioned(
                right: 8,
                bottom: 60,
                child: Column(
                  children: [
                    _TikTokAction(icon: '❤️', count: '12.4K'),
                    const SizedBox(height: 16),
                    _TikTokAction(icon: '💬', count: '234'),
                    const SizedBox(height: 16),
                    _TikTokAction(icon: '🔁', count: '891'),
                    const SizedBox(height: 16),
                    const _TikTokAction(icon: '⭐', count: ''),
                  ],
                ),
              ),

              // Bottom left text
              Positioned(
                left: 10,
                right: 48,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@$handle',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                    if (caption.isNotEmpty)
                      Text(caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10, height: 1.3)),
                    if (hashtags.isNotEmpty)
                      Text(hashtags,
                          style: TextStyle(
                              color: net.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              // Change image button (when image selected)
              if (previewImageUrl != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onPickImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz,
                              color: Colors.white, size: 13),
                          SizedBox(width: 3),
                          Text('Cambiar',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),

              // Avatar + music disc
              Positioned(
                right: 8,
                bottom: 12,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.grey.shade800,
                  ),
                  child: ClipOval(
                    child: user?.avatarUrl != null
                        ? Image.network(user!.avatarUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 14))
                        : const Icon(Icons.music_note,
                            color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TikTokAction extends StatelessWidget {
  final String icon;
  final String count;
  const _TikTokAction({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        if (count.isNotEmpty)
          Text(count,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── LinkedIn preview ──────────────────────────────────────────────────────────

class _LinkedInPreview extends StatelessWidget {
  final _Net net;
  final String caption;
  final Color bg;
  final Color border;
  final User? user;
  final String? previewImageUrl;
  final VoidCallback onPickImage;

  const _LinkedInPreview({
    required this.net,
    required this.caption,
    required this.bg,
    required this.border,
    required this.user,
    required this.previewImageUrl,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = user?.displayName ?? 'Tu Nombre';
    final profession =
        context.read<ProfileProvider>().userAttributes?.profession ?? 'Creator';

    return Center(
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildUserAvatar(user, radius: 20, ringColor: net.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12)),
                        Text('$profession · 1h',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Icon(Icons.more_horiz,
                      color: Colors.grey.shade400, size: 18),
                ],
              ),
            ),
            if (caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Text(caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, height: 1.4)),
              ),
            _buildPhotoArea(
              imageUrl: previewImageUrl,
              onPickImage: onPickImage,
              netColor: net.primary,
              accentColor: net.accent,
              paleta: const [],
              height: 130,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Text('👍 12',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(width: 12),
                  Text('💬 3 comentarios',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                  const Spacer(),
                  Text('↗ 5',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Facebook preview ──────────────────────────────────────────────────────────

class _FacebookPreview extends StatelessWidget {
  final _Net net;
  final String caption;
  final Color bg;
  final Color border;
  final User? user;
  final String? previewImageUrl;
  final VoidCallback onPickImage;

  const _FacebookPreview({
    required this.net,
    required this.caption,
    required this.bg,
    required this.border,
    required this.user,
    required this.previewImageUrl,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = user?.displayName ?? 'Tu Nombre';

    return Center(
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildUserAvatar(user, radius: 18, ringColor: net.primary),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                      Row(
                        children: [
                          Text('2 h · ',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade500)),
                          Icon(Icons.public,
                              size: 10, color: Colors.grey.shade500),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.more_horiz,
                      color: Colors.grey.shade400, size: 18),
                ],
              ),
            ),
            if (caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, height: 1.4)),
              ),
            _buildPhotoArea(
              imageUrl: previewImageUrl,
              onPickImage: onPickImage,
              netColor: net.primary,
              accentColor: net.accent,
              paleta: const [],
              height: 130,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  Text('👍❤️🔥  34',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                  const Spacer(),
                  Text('7 comentarios',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('👍 Me gusta',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600)),
                  Text('💬 Comentar',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600)),
                  Text('↗ Compartir',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image picker bottom sheet ─────────────────────────────────────────────────

class _ImagePickerSheet extends StatefulWidget {
  final String currentUserId;

  const _ImagePickerSheet({required this.currentUserId});

  @override
  State<_ImagePickerSheet> createState() => _ImagePickerSheetState();
}

class _ImagePickerSheetState extends State<_ImagePickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wardrobe = context.watch<WardrobeProvider>();
    final community = context.watch<CommunityProvider>();

    // Posts with images (from this user or any photo post)
    final photoPosts = community.posts
        .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
        .toList();

    // Outfit posts with garment images
    final outfitPosts = community.posts
        .where((p) =>
            p.outfit != null && p.outfit!.garmentOutfits.isNotEmpty)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Elegí una imagen',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          'Se mostrará en la vista previa de la publicación',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Tabs
            TabBar(
              controller: _tab,
              tabs: const [
                Tab(text: 'Mis prendas'),
                Tab(text: 'Publicaciones'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  // ── Garments tab ────────────────────────────────────────
                  wardrobe.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : wardrobe.garments.isEmpty
                          ? _EmptyPickerHint(
                              icon: Icons.checkroom_outlined,
                              message:
                                  'No tenés prendas en tu armario todavía.',
                            )
                          : GridView.builder(
                              controller: scrollCtrl,
                              padding: const EdgeInsets.all(12),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: wardrobe.garments.length,
                              itemBuilder: (_, i) {
                                final g = wardrobe.garments[i];
                                return _PickerTile(
                                  imageUrl: g.path,
                                  label: g.name ?? g.category ?? '',
                                  onTap: () =>
                                      Navigator.pop(context, g.path),
                                );
                              },
                            ),

                  // ── Posts tab ───────────────────────────────────────────
                  (photoPosts.isEmpty && outfitPosts.isEmpty)
                      ? _EmptyPickerHint(
                          icon: Icons.photo_library_outlined,
                          message:
                              'No hay publicaciones con imágenes disponibles.',
                        )
                      : GridView.builder(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount:
                              photoPosts.length + outfitPosts.length,
                          itemBuilder: (_, i) {
                            if (i < photoPosts.length) {
                              final p = photoPosts[i];
                              return _PickerTile(
                                imageUrl: p.imageUrl!,
                                label: p.caption ?? 'Foto',
                                onTap: () =>
                                    Navigator.pop(context, p.imageUrl),
                              );
                            }
                            final p = outfitPosts[i - photoPosts.length];
                            final imgUrl = p.outfit!.garmentOutfits
                                .map((go) => go.garment?.path)
                                .firstWhere((url) => url != null,
                                    orElse: () => null);
                            if (imgUrl == null) return const SizedBox.shrink();
                            return _PickerTile(
                              imageUrl: imgUrl,
                              label: p.outfit!.name ?? 'Outfit',
                              onTap: () =>
                                  Navigator.pop(context, imgUrl),
                            );
                          },
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

class _PickerTile extends StatelessWidget {
  final String imageUrl;
  final String label;
  final VoidCallback onTap;

  const _PickerTile({
    required this.imageUrl,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image_outlined,
                    color: Colors.grey),
              ),
              loadingBuilder: (_, child, p) => p == null
                  ? child
                  : Container(
                      color: Colors.grey.shade100,
                      child: const Center(
                          child:
                              CircularProgressIndicator(strokeWidth: 2))),
            ),
          ),
          // Bottom label
          if (label.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10)),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyPickerHint extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyPickerHint({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Content calendar ──────────────────────────────────────────────────────────

class _ContentCalendar extends StatefulWidget {
  final List<CalendarDay> calendar;
  final Color netColor;

  const _ContentCalendar({required this.calendar, required this.netColor});

  @override
  State<_ContentCalendar> createState() => _ContentCalendarState();
}

class _ContentCalendarState extends State<_ContentCalendar> {
  int? _selectedDay;

  static const _typeConfig = {
    'OUTFIT': (emoji: '👗', color: Color(0xFFE1306C), label: 'Outfit'),
    'PHOTO':  (emoji: '📷', color: Color(0xFF0891B2), label: 'Foto'),
    'TIP':    (emoji: '💡', color: Color(0xFFD69E2E), label: 'Tip'),
    'REST':   (emoji: '—',  color: Color(0xFFAAAAAA), label: 'Descanso'),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = widget.calendar;
    final selected = _selectedDay != null && _selectedDay! < days.length
        ? days[_selectedDay!]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 76,
          child: Row(
            children: List.generate(days.length, (i) {
              final d = days[i];
              final cfg = _typeConfig[d.type] ?? _typeConfig['REST']!;
              final isSelected = _selectedDay == i;
              final isRest = d.isRest;

              return Expanded(
                child: GestureDetector(
                  onTap: isRest
                      ? null
                      : () => setState(() {
                            _selectedDay = _selectedDay == i ? null : i;
                          }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cfg.color.withValues(alpha: 0.15)
                          : isRest
                              ? Colors.transparent
                              : cfg.color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isSelected ? cfg.color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          d.day.substring(0, 3),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isRest
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3)
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(cfg.emoji,
                            style: TextStyle(
                                fontSize: isRest ? 14 : 18)),
                        if (!isRest && d.hour.isNotEmpty)
                          Text(d.hour,
                              style: TextStyle(
                                  fontSize: 8,
                                  color: cfg.color,
                                  fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        if (selected != null &&
            !selected.isRest &&
            selected.idea.isNotEmpty) ...[
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_typeConfig[selected.type]?.color ?? widget.netColor)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _typeConfig[selected.type]?.emoji ?? '📌',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selected.day} · ${selected.hour}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _typeConfig[selected.type]?.color ??
                                widget.netColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(selected.idea,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: _typeConfig.entries
              .where((e) => e.key != 'REST')
              .map((e) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: e.value.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(e.value.label,
                          style: const TextStyle(fontSize: 10)),
                    ],
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ── Caption templates ─────────────────────────────────────────────────────────

class _CaptionTemplatesSection extends StatefulWidget {
  final List<CaptionSet> templates;
  final Color netColor;

  const _CaptionTemplatesSection(
      {required this.templates, required this.netColor});

  @override
  State<_CaptionTemplatesSection> createState() =>
      _CaptionTemplatesSectionState();
}

class _CaptionTemplatesSectionState extends State<_CaptionTemplatesSection> {
  int _activeIdx = 0;

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.captionCopied),
        backgroundColor: AppPalette.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templates = widget.templates;
    if (templates.isEmpty) return const SizedBox.shrink();

    final active = templates[_activeIdx];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (templates.length > 1) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(templates.length, (i) {
                final isActive = i == _activeIdx;
                return GestureDetector(
                  onTap: () => setState(() => _activeIdx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? widget.netColor
                          : widget.netColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Idea ${i + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : widget.netColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            active.idea,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color:
                  theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
        ],

        _CaptionVariant(
          label: 'Corta',
          icon: '⚡',
          hint: '< 60 caracteres',
          text: active.corta,
          color: widget.netColor,
          onCopy: () => _copy(context, active.corta),
        ),
        const SizedBox(height: 8),
        _CaptionVariant(
          label: 'Media',
          icon: '✍️',
          hint: '~130 caracteres',
          text: active.media,
          color: widget.netColor,
          onCopy: () => _copy(context, active.media),
        ),
        const SizedBox(height: 8),
        _CaptionVariant(
          label: 'Larga',
          icon: '📖',
          hint: 'Storytelling completo',
          text: active.larga,
          color: widget.netColor,
          onCopy: () => _copy(context, active.larga),
        ),
      ],
    );
  }
}

class _CaptionVariant extends StatefulWidget {
  final String label;
  final String icon;
  final String hint;
  final String text;
  final Color color;
  final VoidCallback onCopy;

  const _CaptionVariant({
    required this.label,
    required this.icon,
    required this.hint,
    required this.text,
    required this.color,
    required this.onCopy,
  });

  @override
  State<_CaptionVariant> createState() => _CaptionVariantState();
}

class _CaptionVariantState extends State<_CaptionVariant> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    if (widget.text.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                children: [
                  Text(widget.icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.hint,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: widget.color,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(widget.text,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onCopy,
                  icon: const Icon(Icons.copy, size: 14),
                  label: Text(l.copyCaption,
                      style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.color,
                    side: BorderSide(
                        color: widget.color.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Profile checklist ─────────────────────────────────────────────────────────

class _ProfileChecklist extends StatefulWidget {
  final List<String> items;
  final Color netColor;

  const _ProfileChecklist({required this.items, required this.netColor});

  @override
  State<_ProfileChecklist> createState() => _ProfileChecklistState();
}

class _ProfileChecklistState extends State<_ProfileChecklist> {
  late final List<bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = List.filled(widget.items.length, false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = _checked.where((v) => v).length;
    final total = _checked.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? done / total : 0,
                  backgroundColor:
                      widget.netColor.withValues(alpha: 0.12),
                  color: widget.netColor,
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$done/$total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: widget.netColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...widget.items.asMap().entries.map((e) {
          final isChecked = _checked[e.key];
          return GestureDetector(
            onTap: () =>
                setState(() => _checked[e.key] = !_checked[e.key]),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isChecked
                          ? widget.netColor
                          : Colors.transparent,
                      border: Border.all(
                        color: isChecked
                            ? widget.netColor
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: isChecked
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 12)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        decoration: isChecked
                            ? TextDecoration.lineThrough
                            : null,
                        color: isChecked
                            ? theme.colorScheme.onSurface
                                .withValues(alpha: 0.4)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Inspiration section ───────────────────────────────────────────────────────

class _InspirationSection extends StatelessWidget {
  final List<String> searches;
  final _Net net;

  const _InspirationSection({required this.searches, required this.net});

  Future<void> _open(String term) async {
    final url = net.searchUrl(term);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tocá un término para abrir ${net.label} con esa búsqueda',
          style: theme.textTheme.bodySmall?.copyWith(
            color:
                theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: searches.map((term) {
            return GestureDetector(
              onTap: () => _open(term),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: net.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: net.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 14, color: net.primary),
                    const SizedBox(width: 6),
                    Text(
                      term,
                      style: TextStyle(
                        color: net.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.open_in_new,
                        size: 12,
                        color: net.primary.withValues(alpha: 0.6)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final _Net net;
  final SocialBrandingTono tono;

  const _HeroCard({required this.net, required this.tono});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [net.primary, net.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: net.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(net.icon, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              Text(net.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
          const SizedBox(height: 14),
          if (tono.titulo.isNotEmpty) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(tono.titulo,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
            const SizedBox(height: 10),
          ],
          if (tono.descripcion.isNotEmpty)
            Text(tono.descripcion,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, height: 1.5)),
          if (tono.tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...tono.tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(color: Colors.white70)),
                      Expanded(
                        child: Text(tip,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.4)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Imagen section ────────────────────────────────────────────────────────────

class _ImagenSection extends StatelessWidget {
  final SocialBrandingImagen imagen;
  final Color netColor;

  const _ImagenSection({required this.imagen, required this.netColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.55));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imagen.titulo.isNotEmpty) ...[
          Text(imagen.titulo,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
        ],
        if (imagen.paleta.isNotEmpty) ...[
          Text(l.colorPalette, style: labelStyle),
          const SizedBox(height: 10),
          Row(
            children: imagen.paleta.map((hex) {
              Color color;
              try {
                final clean = hex.replaceFirst('#', '');
                color = Color(int.parse(
                      clean.length == 6 ? 'FF$clean' : clean,
                      radix: 16,
                    ) |
                    0xFF000000);
              } catch (_) {
                color = netColor;
              }
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(hex.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
        ],
        if (imagen.keywords.isNotEmpty) ...[
          Text(l.keywords, style: labelStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: imagen.keywords
                .map((k) => Chip(
                      label: Text(k, style: const TextStyle(fontSize: 12)),
                      backgroundColor: netColor.withValues(alpha: 0.1),
                      side: BorderSide(
                          color: netColor.withValues(alpha: 0.3)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
        ],
        if (imagen.tips.isNotEmpty)
          ...imagen.tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 16, color: netColor),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(tip,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(height: 1.4))),
                  ],
                ),
              )),
      ],
    );
  }
}

// ── Contenido section ─────────────────────────────────────────────────────────

class _ContenidoSection extends StatelessWidget {
  final SocialBrandingContenido contenido;
  final Color netColor;

  const _ContenidoSection(
      {required this.contenido, required this.netColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.55));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (contenido.frecuencia.isNotEmpty) ...[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: netColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_outlined,
                    size: 16, color: netColor),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodySmall,
                      children: [
                        TextSpan(
                          text: 'Frecuencia: ',
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6)),
                        ),
                        TextSpan(
                          text: contenido.frecuencia,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (contenido.tipos.isNotEmpty) ...[
          Text(l.contentTypes, style: labelStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: contenido.tipos
                .map((t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 12)),
                      backgroundColor: netColor.withValues(alpha: 0.07),
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
        ],
        if (contenido.ideas.isNotEmpty) ...[
          Text(l.postIdeas, style: labelStyle),
          const SizedBox(height: 10),
          ...contenido.ideas.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                          color: netColor, shape: BoxShape.circle),
                      child: Center(
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(e.value,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(height: 1.4))),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}

// ── Hashtags section ──────────────────────────────────────────────────────────

class _HashtagsSection extends StatelessWidget {
  final List<String> hashtags;
  final Color netColor;

  const _HashtagsSection({required this.hashtags, required this.netColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    if (hashtags.isEmpty) {
      return Text(l.noHashtagsAvailable,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4)));
    }

    final allHashtags = hashtags
        .map((h) => h.startsWith('#') ? h : '#$h')
        .join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: hashtags.map((h) {
            final tag = h.startsWith('#') ? h : '#$h';
            return GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: tag));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.hashtagCopied(tag)),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: netColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: netColor.withValues(alpha: 0.3)),
                ),
                child: Text(tag,
                    style: TextStyle(
                        color: netColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: allHashtags));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l.allHashtagsCopied),
                backgroundColor: AppPalette.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.copy, size: 14),
          label:
              Text(l.copyAll, style: const TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: netColor,
            side: BorderSide(color: netColor.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      ],
    );
  }
}

// ── Horarios section ──────────────────────────────────────────────────────────

class _HorariosSection extends StatelessWidget {
  final SocialBrandingHorarios horarios;

  const _HorariosSection({required this.horarios});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (horarios.mejores.isNotEmpty) ...[
          Text(l.idealMoments,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: AppPalette.success)),
          const SizedBox(height: 8),
          ...horarios.mejores.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: AppPalette.success),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(h,
                            style: theme.textTheme.bodySmall)),
                  ],
                ),
              )),
        ],
        if (horarios.evitar.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l.avoidPosting,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: AppPalette.error)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cancel_outlined,
                  size: 16, color: AppPalette.error),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(horarios.evitar,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(height: 1.4))),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Empty / Error / Warning ───────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _Net net;
  final VoidCallback onLoad;

  const _EmptyState({required this.net, required this.onLoad});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(net.icon,
                size: 72,
                color: net.primary.withValues(alpha: 0.35)),
            const SizedBox(height: 20),
            Text(
              'Generá tu guía de branding\npara ${net.label}',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'La IA analizará tu perfil y creará\nuna estrategia con previews, captions\ny calendario de contenido',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onLoad,
              icon: const Icon(Icons.auto_awesome),
              label: Text(l.generateGuideFor(net.label)),
              style: FilledButton.styleFrom(
                backgroundColor: net.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppPalette.error),
            const SizedBox(height: 16),
            Text(message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String message;

  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppPalette.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: 18, color: AppPalette.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.gold,
                      height: 1.4,
                    )),
          ),
        ],
      ),
    );
  }
}
