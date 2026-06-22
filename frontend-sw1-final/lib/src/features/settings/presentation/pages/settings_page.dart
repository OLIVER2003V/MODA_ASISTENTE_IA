import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../app/app.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/outfit_service.dart';
import '../../../../core/services/admin_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../features/auth/data/models/user_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isRetraining = false;
  bool _isBackingUp  = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    App.themeService.addListener(_onThemeChanged);
    StorageService.getUser().then((u) {
      if (mounted) setState(() => _currentUser = u);
    });
  }

  @override
  void dispose() {
    App.themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.logoutTitle),
        content: Text(_l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.error,
            ),
            child: Text(_l10n.logout),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await StorageService.clearAll();
      if (mounted) context.go('/login');
    }
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ThemeSelectorSheet(
        currentMode: App.themeService.themeMode,
        onChanged: (mode) {
          App.themeService.setThemeMode(mode);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _LanguageSelectorSheet(
        current: context.read<LocaleProvider>().locale,
        onChanged: (locale) {
          context.read<LocaleProvider>().setLocale(locale);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _triggerBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final ok = await AdminService.triggerBackup();
      if (!mounted) return;
      if (ok) {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => const _BackupSuccessSheet(),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('El servidor no tiene GITHUB_PERSONAL_TOKEN configurado'),
          backgroundColor: AppPalette.error,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppPalette.error,
      ));
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  void _showBackupHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _BackupHistorySheet(),
    );
  }

  Future<void> _retrainModel() async {
    setState(() => _isRetraining = true);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RetrainingDialog(
        retrainFuture: OutfitService.retrainModel(),
      ),
    );
    if (mounted) setState(() => _isRetraining = false);
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _NotificationsSheet(),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.terms),
        content: const SingleChildScrollView(
          child: Text(
            'Al usar ModalA aceptás que toda la información generada por IA es '
            'orientativa y no constituye asesoramiento profesional de moda.\n\n'
            'El contenido publicado en la comunidad es responsabilidad exclusiva '
            'del usuario. Nos reservamos el derecho de eliminar contenido que '
            'incumpla nuestras normas de convivencia.\n\n'
            'Las imágenes de prendas son procesadas por servicios de IA de terceros '
            '(Google Gemini) para generar descripciones automáticas.\n\n'
            'Última actualización: Junio 2026',
            style: TextStyle(fontSize: 14, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_l10n.close),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.privacy),
        content: const SingleChildScrollView(
          child: Text(
            'ModalA recopila fotos de prendas y datos de perfil para generar '
            'recomendaciones de outfits personalizadas.\n\n'
            'Las imágenes se almacenan de forma segura en Google Cloud Storage. '
            'No compartimos tu información personal con terceros sin tu '
            'consentimiento explícito.\n\n'
            'Podés solicitar la eliminación total de tus datos en cualquier '
            'momento contactándonos desde la sección de soporte.\n\n'
            'Usamos Firebase para notificaciones push. El token de dispositivo '
            'se almacena únicamente para enviar notificaciones relevantes.\n\n'
            'Última actualización: Junio 2026',
            style: TextStyle(fontSize: 14, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_l10n.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          // ── Apariencia ──────────────────────────────────────────────────
          _buildSectionHeader(context, _l10n.appearance),
          const SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingsTile(
                context,
                icon: App.themeService.themeModeIcon,
                title: _l10n.theme,
                subtitle: _themeLabel(App.themeService.themeMode),
                onTap: _showThemeSelector,
                trailing: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                context,
                icon: Icons.language,
                title: _l10n.language,
                subtitle: localeProvider.localeLabel(null),
                onTap: _showLanguageSelector,
                trailing: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Cuenta ──────────────────────────────────────────────────────
          _buildSectionHeader(context, _l10n.account),
          const SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.person_outline,
                title: _l10n.profileTile,
                subtitle: _l10n.profileTileSub,
                onTap: () => Navigator.pop(context),
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                context,
                icon: Icons.notifications_outlined,
                title: _l10n.notifications,
                subtitle: _l10n.notificationsSub,
                onTap: _showNotificationsSheet,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Modelo de IA ─────────────────────────────────────────────────
          _buildSectionHeader(context, 'Modelo de IA'),
          const SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.model_training,
                title: 'Reentrenar modelo de compatibilidad',
                subtitle: 'Regenera el clasificador de outfits con datos actualizados',
                onTap: _isRetraining ? null : _retrainModel,
                trailing: _isRetraining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.chevron_right,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Administración (solo visible para ADMIN) ─────────────────────
          if (_currentUser?.isAdmin == true) ...[
            // Respaldo de datos
            _buildSectionHeader(context, 'Respaldo de datos'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              context,
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.backup_outlined,
                  title: 'Crear respaldo ahora',
                  subtitle: 'Exporta la base de datos completa a GitHub',
                  onTap: _isBackingUp ? null : _triggerBackup,
                  trailing: _isBackingUp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.chevron_right,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.3)),
                ),
                const Divider(height: 1, indent: 56),
                _buildSettingsTile(
                  context,
                  icon: Icons.history_outlined,
                  title: 'Historial de respaldos',
                  subtitle: 'Ver los últimos respaldos realizados',
                  onTap: _showBackupHistory,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Administración'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              context,
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.admin_panel_settings,
                  title: 'Panel de administración',
                  subtitle: 'Usuarios, reportes, peinados y bitácora',
                  onTap: () => context.push(RoutePath.adminDashboard),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // ── Información ─────────────────────────────────────────────────
          _buildSectionHeader(context, _l10n.information),
          const SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.info_outline,
                title: _l10n.about,
                subtitle: _l10n.versionLabel(AppConstants.version),
                onTap: _showAboutDialog,
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                context,
                icon: Icons.description_outlined,
                title: _l10n.terms,
                onTap: _showTermsDialog,
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: _l10n.privacy,
                onTap: _showPrivacyDialog,
              ),
            ],
          ),

          const SizedBox(height: 32),

          OutlinedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            label: Text(_l10n.logout),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.error,
              side: const BorderSide(color: AppPalette.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              '${AppConstants.appName} v${AppConstants.version}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _themeLabel(ThemeModeOption mode) {
    switch (mode) {
      case ThemeModeOption.light:
        return _l10n.themeLight;
      case ThemeModeOption.dark:
        return _l10n.themeDark;
      default:
        return _l10n.themeSystem;
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? Colors.transparent,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showAboutDialog() {
    final l = _l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppPalette.accentGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.checkroom, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppConstants.appName),
                  Text(
                    l.versionLabel(AppConstants.version),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Text(l.aboutContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }
}

// ── Theme selector sheet ──────────────────────────────────────────────────────

class _ThemeSelectorSheet extends StatelessWidget {
  final ThemeModeOption currentMode;
  final ValueChanged<ThemeModeOption> onChanged;

  const _ThemeSelectorSheet({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  l.selectTheme,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          _buildOption(context, ThemeModeOption.system, Icons.brightness_auto,
              l.themeSystem, l.themeSystemSub),
          _buildOption(context, ThemeModeOption.light, Icons.light_mode,
              l.themeLight, l.themeLightSub),
          _buildOption(context, ThemeModeOption.dark, Icons.dark_mode,
              l.themeDark, l.themeDarkSub),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    ThemeModeOption mode,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final isSelected = currentMode == mode;
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
      onTap: () => onChanged(mode),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}

// ── Language selector sheet ───────────────────────────────────────────────────

class _LanguageSelectorSheet extends StatelessWidget {
  final Locale? current;
  final ValueChanged<Locale> onChanged;

  const _LanguageSelectorSheet({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    const options = [
      (Locale('es'), '🇪🇸', 'Español'),
      (Locale('en'), '🇺🇸', 'English'),
      (Locale('pt'), '🇧🇷', 'Português'),
      (Locale('fr'), '🇫🇷', 'Français'),
      (Locale('it'), '🇮🇹', 'Italiano'),
      (Locale('de'), '🇩🇪', 'Deutsch'),
      (Locale('zh'), '🇨🇳', '中文'),
      (Locale('ja'), '🇯🇵', '日本語'),
      (Locale('ko'), '🇰🇷', '한국어'),
      (Locale('ar'), '🇸🇦', 'العربية'),
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.language, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  l.selectLanguage,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          ...options.map((opt) {
            final (locale, flag, title) = opt;
            final isSelected = (current?.languageCode ?? 'es') ==
                locale.languageCode;
            return ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(flag, style: const TextStyle(fontSize: 22)),
                ),
              ),
              title: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : null,
              onTap: () => onChanged(locale),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            );
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    ),
  ),
);
  }
}

// ── Notifications Sheet ───────────────────────────────────────────────────────

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  bool _dmNotifs = true;
  bool _communityNotifs = true;
  bool _outfitNotifs = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.notifications,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Elegí qué notificaciones querés recibir',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            value: _dmNotifs,
            onChanged: (v) => setState(() => _dmNotifs = v),
            title: const Text('Mensajes directos'),
            subtitle: const Text('Notificaciones de DMs nuevos'),
            secondary: const Icon(Icons.chat_bubble_outline),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: _communityNotifs,
            onChanged: (v) => setState(() => _communityNotifs = v),
            title: const Text('Comunidad'),
            subtitle: const Text('Likes y comentarios en tus posts'),
            secondary: const Icon(Icons.favorite_border),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: _outfitNotifs,
            onChanged: (v) => setState(() => _outfitNotifs = v),
            title: const Text('Recomendaciones'),
            subtitle: const Text('Outfits y sugerencias de IA'),
            secondary: const Icon(Icons.auto_awesome_outlined),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Guardar preferencias'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Retraining dialog — loading → success / error ─────────────────────────────

class _RetrainingDialog extends StatefulWidget {
  final Future<RetrainingMetrics> retrainFuture;
  const _RetrainingDialog({required this.retrainFuture});

  @override
  State<_RetrainingDialog> createState() => _RetrainingDialogState();
}

class _RetrainingDialogState extends State<_RetrainingDialog> {
  RetrainingMetrics? _metrics;
  String? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final start = DateTime.now();
    widget.retrainFuture.then((m) async {
      // Minimum 1.8 s so the user can read the loading explanation
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      if (elapsed < 1800) {
        await Future.delayed(Duration(milliseconds: 1800 - elapsed));
      }
      if (mounted) setState(() { _metrics = m; _done = true; });
    }).catchError((Object e) {
      if (mounted) setState(() { _error = e.toString(); _done = true; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _done,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _done
                ? (_error != null ? _buildError() : _buildSuccess())
                : _buildLoading(),
          ),
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('loading'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppPalette.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppPalette.accent,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Entrenando modelo de IA...',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'El sistema genera miles de combinaciones de outfits y aprende qué prendas combinan bien.',
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _LoadingStep(icon: Icons.dataset_outlined,     label: 'Generando 2.400 outfits de entrenamiento'),
        const SizedBox(height: 10),
        _LoadingStep(icon: Icons.palette_outlined,     label: 'Analizando colores, estilos y formalidad'),
        const SizedBox(height: 10),
        _LoadingStep(icon: Icons.school_outlined,      label: 'Entrenando clasificador (150 árboles)'),
        const SizedBox(height: 10),
        _LoadingStep(icon: Icons.analytics_outlined,   label: 'Evaluando precisión en test set (20%)'),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Success ───────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    final m = _metrics!;
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppPalette.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          'Modelo actualizado',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Dataset: ${m.nTrain + m.nTest} outfits  •  '
          'CLIP: ${m.clipUsed ? "activo" : "sin GPU"}',
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _AnimatedMetricBar(
          label: 'Precisión',
          sublabel: 'aciertos sobre el total',
          value: m.accuracy,
          display: '${(m.accuracy * 100).toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 14),
        _AnimatedMetricBar(
          label: 'F1-Score',
          sublabel: 'balance precisión / cobertura',
          value: m.f1Score,
          display: m.f1Score.toStringAsFixed(3),
        ),
        const SizedBox(height: 14),
        _AnimatedMetricBar(
          label: 'AUC-ROC',
          sublabel: 'capacidad de distinguir outfits',
          value: m.aucRoc,
          display: m.aucRoc.toStringAsFixed(3),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Listo'),
          ),
        ),
      ],
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError() {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('error'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppPalette.error,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        Text('Error al entrenar',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          _error ?? 'Error desconocido',
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ),
      ],
    );
  }
}

// ── Paso de carga ─────────────────────────────────────────────────────────────

class _LoadingStep extends StatelessWidget {
  final IconData icon;
  final String label;
  const _LoadingStep({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ),
      ],
    );
  }
}

// ── Barra de métrica animada ──────────────────────────────────────────────────

class _AnimatedMetricBar extends StatelessWidget {
  final String label;
  final String sublabel;
  final double value;
  final String display;

  const _AnimatedMetricBar({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.display,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = value >= 0.90
        ? AppPalette.success
        : value >= 0.70
            ? AppPalette.accent
            : AppPalette.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(sublabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5))),
                ],
              ),
            ),
            Text(display,
                style: theme.textTheme.titleSmall?.copyWith(
                    color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 10,
              backgroundColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.08),
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Backup success sheet ──────────────────────────────────────────────────────

class _BackupSuccessSheet extends StatelessWidget {
  const _BackupSuccessSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4, height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(
                color: AppPalette.success, shape: BoxShape.circle),
            child: const Icon(Icons.cloud_done_outlined,
                color: Colors.white, size: 34),
          ),
          const SizedBox(height: 16),
          Text('Respaldo iniciado',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'El proceso corre en GitHub Actions y tarda ~1 minuto.\n'
            'Podés ver el progreso y descargar el archivo desde\n'
            'GitHub → Actions → Database Backup.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Los respaldos se guardan por 90 días.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Backup history sheet ──────────────────────────────────────────────────────

class _BackupHistorySheet extends StatefulWidget {
  const _BackupHistorySheet();

  @override
  State<_BackupHistorySheet> createState() => _BackupHistorySheetState();
}

class _BackupHistorySheetState extends State<_BackupHistorySheet> {
  List<BackupRun>? _runs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AdminService.listBackups().then((runs) {
      if (mounted) setState(() { _runs = runs; _loading = false; });
    }).catchError((_) {
      if (mounted) setState(() { _runs = []; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.history_outlined),
              const SizedBox(width: 10),
              Text('Historial de respaldos',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_runs == null || _runs!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No hay respaldos registrados aún',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5))),
              ),
            )
          else
            ...(_runs!.map((r) => _BackupRunTile(run: r))),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupRunTile extends StatelessWidget {
  final BackupRun run;
  const _BackupRunTile({required this.run});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = run.isSuccess
        ? AppPalette.success
        : run.isRunning
            ? AppPalette.accent
            : AppPalette.error;
    final icon = run.isSuccess
        ? Icons.check_circle_outline
        : run.isRunning
            ? Icons.sync
            : Icons.error_outline;
    final label = run.isSuccess
        ? 'Completado'
        : run.isRunning
            ? 'En proceso...'
            : 'Falló';

    final date = run.createdAt;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}  '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Respaldo #${run.runNumber}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(dateStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
