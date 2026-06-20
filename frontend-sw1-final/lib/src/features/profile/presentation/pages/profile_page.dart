import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/user_attribute_service.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../dm/presentation/pages/dm_inbox_page.dart';
import '../../../notifications/presentation/pages/notification_page.dart';
import '../../../wardrobe/presentation/providers/wardrobe_provider.dart';
import '../../data/models/user_attribute_model.dart';
import '../providers/profile_provider.dart';
import '../../../subscription/presentation/pages/subscription_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import 'edit_attributes_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesion'),
        content: const Text('Estas seguro de que deseas cerrar sesion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.error,
            ),
            child: const Text('Cerrar sesion'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Limpiar todos los providers antes de cerrar sesión
      context.read<ProfileProvider>().clear();
      context.read<WardrobeProvider>().clear();

      // Cerrar sesión (elimina tokens y datos locales)
      await context.read<ProfileProvider>().logout();

      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l.myProfile),
            actions: [
              const NotificationBell(),
              IconButton(
                icon: const Icon(Icons.mail_outline_rounded),
                tooltip: 'Mensajes',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DmInboxPage()),
                ),
              ),
              if (provider.hasData)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => provider.loadProfile(force: true),
                  tooltip: 'Actualizar',
                ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
                tooltip: 'Configuracion',
              ),
            ],
          ),
          body: _buildBody(provider, theme),
        );
      },
    );
  }

  Widget _buildBody(ProfileProvider provider, ThemeData theme) {
    if (provider.isLoading && !provider.hasData) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (!provider.hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? 'No se pudo cargar la informacion',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => provider.loadProfile(force: true),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadProfile(force: true),
      color: theme.colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(provider.user!, theme),
            const SizedBox(height: 16),
            Text(
              provider.user!.name ?? 'Sin nombre',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              provider.user!.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBadge(
                  theme,
                  icon: Icons.check_circle_outline,
                  label: provider.user!.isActive ? 'Activo' : 'Inactivo',
                  color: provider.user!.isActive ? AppPalette.success : theme.colorScheme.outline,
                ),
                const SizedBox(width: 10),
                _buildBadge(
                  theme,
                  icon: Icons.calendar_today_outlined,
                  label: 'Desde ${_formatDate(provider.user!.createdAt)}',
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              ).then((_) => provider.loadProfile(force: true)),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(AppLocalizations.of(context)!.editProfile),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            const SizedBox(height: 24),
            _buildPremiumCard(context, theme),
            if (provider.userAttributes != null) ...[
              const SizedBox(height: 16),
              _buildAttributesCard(provider.userAttributes!, theme),
            ],
            const SizedBox(height: 16),
            _BodyPhotoCard(theme: theme, userId: provider.user!.id),
            const SizedBox(height: 32),
            _buildLogoutButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(User user, ThemeData theme) {
    final url = user.avatarUrl;
    if (url != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 60,
          backgroundImage: NetworkImage(url),
          backgroundColor: AppPalette.gray200,
        ),
      );
    }
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: AppPalette.accentGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          user.initials,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(ThemeData theme, {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAttributesCard(UserAttribute attributes, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.fashionProfile,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Editar preferencias',
                  onPressed: () {
                    final provider = context.read<ProfileProvider>();
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                          builder: (_) =>
                              EditAttributesPage(attributes: attributes),
                        ))
                        .then((_) => provider.loadProfile(force: true));
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (attributes.gender != null)
              _buildInfoRow(
                theme: theme,
                icon: Icons.person,
                label: AppLocalizations.of(context)!.gender,
                value: attributes.gender!,
              ),
            if (attributes.age != null) ...[
              if (attributes.gender != null) const Divider(height: 24),
              _buildInfoRow(
                theme: theme,
                icon: Icons.cake,
                label: AppLocalizations.of(context)!.age,
                value: '${attributes.age}',
              ),
            ],
            if (attributes.stature != null || attributes.weight != null) ...[
              if (attributes.age != null || attributes.gender != null)
                const Divider(height: 24),
              if (attributes.stature != null)
                _buildInfoRow(
                  theme: theme,
                  icon: Icons.height,
                  label: AppLocalizations.of(context)!.height,
                  value:
                      '${attributes.stature!.toStringAsFixed(attributes.stature == attributes.stature!.roundToDouble() ? 0 : 1)} cm',
                ),
              if (attributes.stature != null && attributes.weight != null)
                const SizedBox(height: 16),
              if (attributes.weight != null)
                _buildInfoRow(
                  theme: theme,
                  icon: Icons.monitor_weight_outlined,
                  label: AppLocalizations.of(context)!.weight,
                  value:
                      '${attributes.weight!.toStringAsFixed(attributes.weight == attributes.weight!.roundToDouble() ? 0 : 1)} kg',
                ),
            ],
            if (attributes.profession != null) ...[
              if (attributes.stature != null ||
                  attributes.weight != null ||
                  attributes.age != null ||
                  attributes.gender != null)
                const Divider(height: 24),
              _buildInfoRow(
                theme: theme,
                icon: Icons.work_outline,
                label: 'Profesión',
                value: attributes.profession!,
              ),
            ],
            if (attributes.skinTone != null) ...[
              if (attributes.profession != null ||
                  attributes.stature != null ||
                  attributes.weight != null ||
                  attributes.age != null ||
                  attributes.gender != null)
                const Divider(height: 24),
              _buildSkinToneRow(
                theme: theme,
                label: 'Tono de Piel',
                value: attributes.skinTone!,
              ),
            ],
            if (attributes.faceType != null) ...[
              if (attributes.skinTone != null ||
                  attributes.profession != null ||
                  attributes.stature != null ||
                  attributes.weight != null ||
                  attributes.age != null ||
                  attributes.gender != null)
                const Divider(height: 24),
              _buildInfoRow(
                theme: theme,
                icon: Icons.face_outlined,
                label: 'Forma del Rostro',
                value: attributes.faceType!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext ctx, ThemeData theme) {
    final subProvider = ctx.watch<SubscriptionProvider>();
    final isPremium = subProvider.isPremium;

    return GestureDetector(
      onTap: () {
        ctx.read<SubscriptionProvider>().loadStatus();
        Navigator.of(ctx).push(
          MaterialPageRoute(builder: (_) => const SubscriptionPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: isPremium
              ? const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : LinearGradient(
                  colors: [
                    theme.colorScheme.surfaceContainerHigh,
                    theme.colorScheme.surfaceContainerHighest,
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: isPremium
              ? null
              : Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              isPremium ? Icons.workspace_premium : Icons.workspace_premium_outlined,
              color: isPremium ? Colors.white : theme.colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium ? 'StyleAI Premium' : 'Actualizar a Premium',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPremium ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPremium
                        ? 'Plan activo · Tocá para ver detalles'
                        : 'IA ilimitada, peinados y más',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isPremium
                          ? Colors.white.withValues(alpha: 0.8)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isPremium ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout),
        label: const Text(
          'Cerrar sesion',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.error,
          side: BorderSide(
            color: AppPalette.error,
            width: 2,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static const Map<String, Color> _skinToneColors = {
    'Muy clara': Color(0xFFFFE5D4),
    'Clara': Color(0xFFFFD5B8),
    'Media': Color(0xFFD4A574),
    'Morena': Color(0xFFB07D4B),
    'Oscura': Color(0xFF8B5A2B),
    'Muy oscura': Color(0xFF5D3A1A),
  };

  Widget _buildSkinToneRow({
    required ThemeData theme,
    required String label,
    required String value,
  }) {
    final color = _skinToneColors[value] ?? theme.colorScheme.outline;
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha:0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ── Body Photo Card ───────────────────────────────────────────────────────────

class _BodyPhotoCard extends StatefulWidget {
  final ThemeData theme;
  final String userId;
  const _BodyPhotoCard({required this.theme, required this.userId});

  @override
  State<_BodyPhotoCard> createState() => _BodyPhotoCardState();
}

class _BodyPhotoCardState extends State<_BodyPhotoCard> {
  bool _loading = false;
  bool _uploading = false;
  String? _photoUrl;

  String get _cacheKey => 'body_photo_url_${widget.userId}';

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    // Show cached URL immediately (no spinner for repeat visits)
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null && mounted) setState(() => _photoUrl = cached);

    // Then refresh from server in background
    setState(() => _loading = cached == null);
    try {
      final url = await UserAttributeService.getBodyPhotoUrl();
      if (mounted) setState(() => _photoUrl = url);
      if (url != null) {
        await prefs.setString(_cacheKey, url);
      } else {
        await prefs.remove(_cacheKey);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final url = await UserAttributeService.uploadBodyPhoto(File(picked.path));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, url);
      if (mounted) {
        setState(() => _photoUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de cuerpo actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir foto: $e'), backgroundColor: AppPalette.error),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.accessibility_new_rounded, color: AppPalette.accent, size: 20),
                const SizedBox(width: 8),
                Text('Foto de cuerpo', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_uploading)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  TextButton.icon(
                    onPressed: _pickAndUpload,
                    icon: const Icon(Icons.upload_rounded, size: 16),
                    label: Text(_photoUrl == null ? 'Subir foto' : 'Cambiar'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Usamos esta foto para mostrarte cómo quedan los outfits en tu cuerpo. Solo la ves tú.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _photoUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(isDark),
                ),
              )
            else
              _placeholder(isDark),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(bool isDark) {
    return GestureDetector(
      onTap: _pickAndUpload,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppPalette.gray700 : AppPalette.gray100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppPalette.gray600 : AppPalette.gray300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppPalette.accent.withValues(alpha: 0.7)),
            const SizedBox(height: 8),
            Text('Toca para subir tu foto de cuerpo completo',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? AppPalette.gray400 : AppPalette.gray600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
