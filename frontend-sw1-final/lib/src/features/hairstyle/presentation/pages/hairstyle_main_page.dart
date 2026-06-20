import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/hairstyle_service.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../chat/presentation/pages/face_scan_page.dart';
import '../../../outfit/presentation/pages/outfit_history_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../providers/hairstyle_provider.dart';

class HairstyleMainPage extends StatefulWidget {
  const HairstyleMainPage({super.key});

  @override
  State<HairstyleMainPage> createState() => _HairstyleMainPageState();
}

class _HairstyleMainPageState extends State<HairstyleMainPage> {
  bool _aiLoading = false;
  HairstyleRecommendResult? _aiResult;
  String? _aiError;

  HairstyleItem? _selectedItem;
  bool _tryOnLoading = false;
  String? _tryOnResultUrl;
  String? _tryOnError;
  File? _lastPhotoFile;

  bool get _isPremium => context.read<SubscriptionProvider>().isPremium;

  static const _hairstyleLoadingMessages = [
    'Preparando tu foto...',
    'Aplicando el peinado...',
    'Ajustando el estilo...',
    '¡Casi listo!',
    'Un momento más...',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HairstyleProvider>().load();
    });
  }

  // ── Selección de foto ─────────────────────────────────────────────────────

  Future<File?> _pickPhoto() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _PhotoSourceSheet(),
    );
    if (choice == null || !mounted) return null;

    if (choice == 'gallery') {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      return f != null ? File(f.path) : null;
    } else {
      final path = await Navigator.push<String?>(
        context,
        MaterialPageRoute(builder: (_) => const FaceScanPage()),
      );
      return (path != null && mounted) ? File(path) : null;
    }
  }

  // ── IA Recomienda ─────────────────────────────────────────────────────────

  Future<void> _runRecommend() async {
    if (!_isPremium) { _premiumSnack(); return; }
    final file = await _pickPhoto();
    if (file == null || !mounted) return;
    _lastPhotoFile = file; // reutilizar en "Probar este estilo" sin pedir foto otra vez

    setState(() { _aiLoading = true; _aiError = null; _aiResult = null; });
    try {
      final result = await HairstyleService.recommend(file);
      if (mounted) setState(() => _aiResult = result);
    } catch (e) {
      if (mounted) setState(() => _aiError = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  // ── Probar peinado ────────────────────────────────────────────────────────

  Future<void> _startTryOn(HairstyleItem item) async {
    if (!_isPremium) { _premiumSnack(); return; }
    // Si ya hay una foto (de la recomendación o de un try-on previo), reutilizarla
    if (_lastPhotoFile != null) {
      await _runTryOn(item, _lastPhotoFile!);
      return;
    }
    final file = await _pickPhoto();
    if (file == null || !mounted) return;
    await _runTryOn(item, file);
  }

  Future<void> _runTryOn(HairstyleItem item, File file) async {
    _lastPhotoFile = file;
    setState(() {
      _selectedItem = item;
      _tryOnLoading = true;
      _tryOnError = null;
      _tryOnResultUrl = null;
    });
    try {
      final url = await HairstyleService.tryOn(item.id, file);
      if (mounted) setState(() => _tryOnResultUrl = url);
    } catch (e) {
      if (mounted) setState(() => _tryOnError = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _tryOnLoading = false);
    }
  }

  /// Reutiliza la última foto sin volver a pedirla, ideal para "Probar otro estilo".
  Future<void> _tryAnotherStyle(HairstyleItem item) async {
    if (!_isPremium) { _premiumSnack(); return; }
    if (_lastPhotoFile != null) {
      await _runTryOn(item, _lastPhotoFile!);
    } else {
      await _startTryOn(item);
    }
  }

  Future<void> _pickAndTryOn() async {
    if (!_isPremium) { _premiumSnack(); return; }
    final provider = context.read<HairstyleProvider>();
    final item = await showModalBottomSheet<HairstyleItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const _CatalogPickerSheet(),
      ),
    );
    if (item == null || !mounted) return;
    await _startTryOn(item);
  }

  void _premiumSnack() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Esta función requiere Premium'),
      backgroundColor: AppPalette.accent,
    ));
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HairstyleProvider>();
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.hairstyles),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Ver catálogo completo',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => ChangeNotifierProvider.value(
                value: provider,
                child: _CatalogPickerSheet(
                  onTryOn: _startTryOn,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () => provider.load(force: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(theme),
            const SizedBox(height: 28),
            _buildGenderFilter(provider),
            const SizedBox(height: 24),
            _buildActions(theme),
            const SizedBox(height: 32),

            if (_aiLoading) ...[
              TryOnLoadingWidget(
                messages: _hairstyleLoadingMessages,
                subtitle: 'La IA está analizando tu rostro con Gemini',
              ),
              const SizedBox(height: 24),
            ],
            if (_aiError != null) ...[
              _ErrorBanner(message: _aiError!, onRetry: _runRecommend),
              const SizedBox(height: 24),
            ],
            if (_aiResult != null) ...[
              _buildAIResult(theme, provider),
              const SizedBox(height: 32),
            ],

            if (_tryOnLoading) ...[
              TryOnLoadingWidget(
                messages: _hairstyleLoadingMessages,
                subtitle: 'Aplicando el peinado con IA en tu foto',
              ),
              const SizedBox(height: 24),
            ],
            if (_tryOnError != null) ...[
              _ErrorBanner(
                message: _tryOnError!,
                onRetry: _selectedItem != null ? () => _tryAnotherStyle(_selectedItem!) : null,
              ),
              const SizedBox(height: 24),
            ],
            if (_tryOnResultUrl != null)
              _buildTryOnResult(theme, provider),
          ],
        ),
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPalette.accent.withValues(alpha: 0.12),
            AppPalette.accent.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.content_cut_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Encuentra tu estilo',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'La IA analiza tu rostro y recomienda el peinado ideal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Gender filter ─────────────────────────────────────────────────────────

  Widget _buildGenderFilter(HairstyleProvider provider) {
    const filters = [('ALL', 'Todos'), ('FEMALE', 'Femenino'), ('MALE', 'Masculino')];
    return Row(
      children: filters.map((f) {
        final selected = provider.genderFilter == f.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(f.$2),
            selected: selected,
            onSelected: (_) => provider.setGenderFilter(f.$1),
            showCheckmark: false,
          ),
        );
      }).toList(),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¿Qué quieres hacer?',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            )),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.auto_awesome_rounded,
          title: 'Recomendarme un peinado',
          subtitle: 'La IA analiza tu rostro y elige el estilo ideal',
          gradient: true,
          onTap: _runRecommend,
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.face_retouching_natural_rounded,
          title: 'Probar un peinado',
          subtitle: 'Elige del catálogo y míralo en tu foto',
          onTap: _pickAndTryOn,
        ),
      ],
    );
  }

  // ── AI Result ─────────────────────────────────────────────────────────────

  Widget _buildAIResult(ThemeData theme, HairstyleProvider provider) {
    final result = _aiResult!;
    final item = result.recommended;
    final genderFilter = provider.genderFilter;
    final others = result.catalog.where((h) {
      if (h.id == item.id) return false;
      if (genderFilter == 'ALL') return true;
      return h.gender == genderFilter || h.gender == 'UNISEX' || h.gender == null;
    }).take(6).toList();

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppPalette.accent, size: 18),
              const SizedBox(width: 8),
              Text('Recomendado para ti',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() { _aiResult = null; _aiError = null; }),
                child: const Text('Cerrar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RecommendedCard(
            item: item,
            explanation: result.explanation,
            isFavorite: provider.isFavorite(item.id),
            onFavoriteToggle: () => provider.toggleFavorite(item.id),
            onTryOn: () => _startTryOn(item),
          ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Otros estilos compatibles',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: others.length,
                itemBuilder: (_, i) => _MiniHairstyleCard(
                  item: others[i],
                  onTap: () => _startTryOn(others[i]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Try-on Result ─────────────────────────────────────────────────────────

  Widget _buildTryOnResult(ThemeData theme, HairstyleProvider provider) {
    final genderFilter = provider.genderFilter;
    final others = provider.catalog.where((h) {
      if (h.id == _selectedItem?.id) return false;
      if (genderFilter == 'ALL') return true;
      return h.gender == genderFilter || h.gender == 'UNISEX' || h.gender == null;
    }).take(8).toList();

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Resultado',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  _tryOnResultUrl = null;
                  _tryOnError = null;
                  _selectedItem = null;
                }),
                child: const Text('Cerrar'),
              ),
            ],
          ),
          if (_selectedItem != null) ...[
            const SizedBox(height: 2),
            Text(
              _selectedItem!.shortDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppPalette.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              _tryOnResultUrl!,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: AppPalette.gray200,
                child: const Center(
                    child: Icon(Icons.broken_image, size: 48, color: Colors.white54)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => downloadTryOnImage(context, _tryOnResultUrl!),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Guardar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.accent,
                    side: BorderSide(color: AppPalette.accent.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => ShareTryOnSheet(imageUrl: _tryOnResultUrl!),
                  ),
                  icon: const Icon(Icons.people_alt_rounded, size: 18),
                  label: const Text('Comunidad'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Probar otro estilo',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: others.length,
                itemBuilder: (_, i) => _MiniHairstyleCard(
                  item: others[i],
                  onTap: () => _tryAnotherStyle(others[i]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Photo source sheet ────────────────────────────────────────────────────────

class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('¿Cómo quieres subir tu foto?',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppPalette.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.photo_library_outlined, color: AppPalette.accent),
            ),
            title: const Text('Desde galería'),
            subtitle: const Text('Selecciona una foto existente'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          const SizedBox(height: 4),
          ListTile(
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white),
            ),
            title: const Text('Tomar foto'),
            subtitle: const Text('Usa la cámara con detección facial'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
        ],
      ),
    );
  }
}

// ── Action card ───────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool gradient;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: gradient ? null : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: gradient
              ? null
              : Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: gradient
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppPalette.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 26,
                  color: gradient ? Colors.white : AppPalette.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15,
                          color: gradient ? Colors.white : theme.colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: gradient
                              ? Colors.white.withValues(alpha: 0.8)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14,
                color: gradient
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppPalette.accent),
          ],
        ),
      ),
    );
  }
}

// ── Recommended card ──────────────────────────────────────────────────────────

class _RecommendedCard extends StatefulWidget {
  final HairstyleItem item;
  final String explanation;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTryOn;

  const _RecommendedCard({
    required this.item,
    required this.explanation,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTryOn,
  });

  @override
  State<_RecommendedCard> createState() => _RecommendedCardState();
}

class _RecommendedCardState extends State<_RecommendedCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.accent.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.item.imageUrl != null)
            Image.network(
              widget.item.imageUrl!,
              width: double.infinity, height: 200, fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(
                      height: 200, color: AppPalette.gray200,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
              errorBuilder: (_, __, ___) => Container(
                height: 80, color: AppPalette.gray200,
                child: const Center(child: Icon(Icons.content_cut, size: 36)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(widget.item.shortDescription,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: widget.onFavoriteToggle,
                      icon: Icon(
                          widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: widget.isFavorite ? Colors.redAccent : null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (widget.explanation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.explanation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      height: 1.4,
                    ),
                    maxLines: _expanded ? null : 3,
                    overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _expanded ? 'Ver menos' : 'Ver más',
                        style: TextStyle(
                          color: AppPalette.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onTryOn,
                    icon: const Icon(Icons.face_retouching_natural_rounded, size: 18),
                    label: const Text('Probar este estilo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini hairstyle card (tira horizontal) ─────────────────────────────────────

class _MiniHairstyleCard extends StatelessWidget {
  final HairstyleItem item;
  final VoidCallback onTap;

  const _MiniHairstyleCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPalette.accent.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              Image.network(item.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
            else
              _placeholder(),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 6, left: 4, right: 4,
              child: Text(
                item.shortDescription,
                style: const TextStyle(
                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500),
                maxLines: 2, overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            Positioned(
              top: 4, right: 4,
              child: Container(
                width: 26, height: 26,
                decoration: const BoxDecoration(
                  color: AppPalette.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.content_cut_rounded,
                    color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppPalette.gray200,
        child: const Center(
            child: Icon(Icons.content_cut, size: 28, color: Colors.white54)),
      );
}

// ── Catalog picker sheet ──────────────────────────────────────────────────────

class _CatalogPickerSheet extends StatelessWidget {
  final void Function(HairstyleItem)? onTryOn;
  const _CatalogPickerSheet({this.onTryOn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<HairstyleProvider>();
    final items = provider.displayed;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Catálogo de peinados',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () => provider.load(force: true),
                ),
              ],
            ),
          ),
          _GenderFilterChips(provider: provider),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(
                        child: Text('Sin peinados disponibles',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5))),
                      )
                    : GridView.builder(
                        controller: ctrl,
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _CatalogCard(
                          item: items[i],
                          isFavorite: provider.isFavorite(items[i].id),
                          onFavoriteToggle: () =>
                              provider.toggleFavorite(items[i].id),
                          onTap: () {
                            if (onTryOn != null) {
                              Navigator.pop(context);
                              onTryOn!(items[i]);
                            } else {
                              Navigator.pop(context, items[i]);
                            }
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Gender filter chips ───────────────────────────────────────────────────────

class _GenderFilterChips extends StatelessWidget {
  final HairstyleProvider provider;
  const _GenderFilterChips({required this.provider});

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('ALL', 'Todos'),
      ('FEMALE', 'Femenino'),
      ('MALE', 'Masculino'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final selected = provider.genderFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.$2),
              selected: selected,
              onSelected: (_) => provider.setGenderFilter(f.$1),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Catalog card ──────────────────────────────────────────────────────────────

class _CatalogCard extends StatelessWidget {
  final HairstyleItem item;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  const _CatalogCard({
    required this.item,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              Image.network(item.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
            else
              _placeholder(),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.45, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6, right: 6,
              child: GestureDetector(
                onTap: onFavoriteToggle,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.redAccent : Colors.white,
                      size: 17),
                ),
              ),
            ),
            if (item.gender != null)
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _genderColor(item.gender).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item.genderLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            Positioned(
              bottom: 8, left: 8, right: 8,
              child: Text(item.shortDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Color _genderColor(String? g) {
    switch (g) {
      case 'MALE': return const Color(0xFF1565C0);
      case 'FEMALE': return const Color(0xFFAD1457);
      default: return const Color(0xFF37474F);
    }
  }

  Widget _placeholder() => Container(
        color: AppPalette.gray200,
        child: const Center(
            child: Icon(Icons.content_cut, size: 40, color: Colors.white54)),
      );
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorBanner({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppPalette.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppPalette.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(color: AppPalette.error, fontSize: 13)),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 4),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.error,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Reintentar', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}
