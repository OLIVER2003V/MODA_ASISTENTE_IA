import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../app/app.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/outfit_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/locale_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isRetraining = false;

  @override
  void initState() {
    super.initState();
    App.themeService.addListener(_onThemeChanged);
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

  Future<void> _retrainModel() async {
    setState(() => _isRetraining = true);
    try {
      final metrics = await OutfitService.retrainModel();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.model_training, color: AppPalette.accent),
              SizedBox(width: 10),
              Text('Reentrenamiento completado'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MetricRow(
                  label: 'Accuracy',
                  value: metrics.accuracy,
                  display: '${(metrics.accuracy * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              _MetricRow(
                  label: 'F1-Score',
                  value: metrics.f1Score,
                  display: metrics.f1Score.toStringAsFixed(4)),
              const SizedBox(height: 8),
              _MetricRow(
                  label: 'AUC-ROC',
                  value: metrics.aucRoc,
                  display: metrics.aucRoc.toStringAsFixed(4)),
              const SizedBox(height: 16),
              Text(
                'Dataset: ${metrics.nTrain + metrics.nTest} outfits  •  '
                'CLIP: ${metrics.clipUsed ? "activo" : "no disponible"}',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reentrenar: $e'),
          backgroundColor: AppPalette.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRetraining = false);
    }
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

// ── Metric row for the retraining dialog ─────────────────────────────────────

class _MetricRow extends StatelessWidget {
  final String label;
  final double value;
  final String display;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.display,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: value >= 0.90
                  ? AppPalette.success
                  : value >= 0.70
                      ? AppPalette.accent
                      : AppPalette.error,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: Text(display,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
