import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/hairstyle_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../providers/hairstyle_provider.dart';

class HairstyleCatalogPage extends StatefulWidget {
  const HairstyleCatalogPage({super.key});

  @override
  State<HairstyleCatalogPage> createState() => _HairstyleCatalogPageState();
}

class _HairstyleCatalogPageState extends State<HairstyleCatalogPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        context.read<HairstyleProvider>().setTab(_tabCtrl.index == 1);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HairstyleProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  bool get _isPremium =>
      context.read<SubscriptionProvider>().isPremium;

  Future<void> _recommendWithAI() async {
    if (!_isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Esta función requiere Premium'),
        backgroundColor: AppPalette.accent,
      ));
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Expanded(child: Text('Analizando tu rostro...')),
        ]),
      ),
    );

    try {
      final result =
          await HairstyleService.recommend(File(file.path));
      if (!mounted) return;
      Navigator.pop(context);
      _showRecommendResult(result);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: AppPalette.error,
      ));
    }
  }

  void _showRecommendResult(HairstyleRecommendResult result) {
    final item = result.recommended;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, sc) => SingleChildScrollView(
            controller: sc,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(children: [
                  Icon(Icons.auto_awesome, color: AppPalette.accent),
                  const SizedBox(width: 8),
                  Text('Peinado recomendado',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 16),
                if (item.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(item.imageUrl!,
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover),
                  ),
                const SizedBox(height: 16),
                if (result.explanation.isNotEmpty) ...[
                  Text('Por qué te queda bien',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(result.explanation,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(height: 1.5)),
                  const SizedBox(height: 16),
                ],
                Text('Descripción',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(item.description,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(height: 1.5)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _tryOnHairstyle(item);
                    },
                    icon: const Icon(Icons.face_retouching_natural),
                    label: const Text('Probar virtualmente'),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _tryOnHairstyle(HairstyleItem item) async {
    if (!_isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Esta función requiere Premium'),
        backgroundColor: AppPalette.accent,
      ));
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Expanded(child: Text('Generando prueba virtual...')),
        ]),
      ),
    );

    try {
      final url =
          await HairstyleService.tryOn(item.id, File(file.path));
      if (!mounted) return;
      Navigator.pop(context);
      _showTryOnResult(url);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: AppPalette.error,
      ));
    }
  }

  void _showTryOnResult(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tu prueba virtual'),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<HairstyleProvider>();
    final favCount = provider.favoriteCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peinados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Recomendar peinado con IA',
            onPressed: _recommendWithAI,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => provider.load(force: true),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            const Tab(text: 'Todos'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Favoritos'),
                  if (favCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$favCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: () {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return _ErrorState(
            message: provider.error!,
            onRetry: () => provider.load(force: true),
          );
        }
        return Column(
          children: [
            _GenderFilterBar(provider: provider),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _HairstyleGrid(provider: provider, onTryOn: _tryOnHairstyle),
                  _HairstyleGrid(provider: provider, onTryOn: _tryOnHairstyle),
                ],
              ),
            ),
          ],
        );
      }(),
    );
  }
}

// ── Gender filter bar ─────────────────────────────────────────────────────────

class _GenderFilterBar extends StatelessWidget {
  final HairstyleProvider provider;
  const _GenderFilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final filters = [
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

// ── Grid ──────────────────────────────────────────────────────────────────────

class _HairstyleGrid extends StatelessWidget {
  final HairstyleProvider provider;
  final void Function(HairstyleItem) onTryOn;
  const _HairstyleGrid({required this.provider, required this.onTryOn});

  @override
  Widget build(BuildContext context) {
    final items = provider.displayed;

    if (items.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => provider.load(force: true),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _HairstyleCard(
          item: items[i],
          isFavorite: provider.isFavorite(items[i].id),
          onFavoriteToggle: () => provider.toggleFavorite(items[i].id),
          onTryOn: onTryOn,
        ),
      ),
    );
  }
}

// ── Hairstyle card ────────────────────────────────────────────────────────────

class _HairstyleCard extends StatelessWidget {
  final HairstyleItem item;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final void Function(HairstyleItem) onTryOn;

  const _HairstyleCard({
    required this.item,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTryOn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Imagen ────────────────────────────────────────────────
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
              )
            else
              _imagePlaceholder(),

            // ── Gradient bottom ───────────────────────────────────────
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

            // ── Favorite button (top-right) ───────────────────────────
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onFavoriteToggle,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ),

            // ── Gender chip (top-left) ────────────────────────────────
            if (item.gender != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _genderColor(item.gender).withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.genderLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),

            // ── Description (bottom) ──────────────────────────────────
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                item.shortDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _genderColor(String? g) {
    switch (g) {
      case 'MALE':
        return const Color(0xFF1565C0);
      case 'FEMALE':
        return const Color(0xFFAD1457);
      default:
        return const Color(0xFF37474F);
    }
  }

  Widget _imagePlaceholder() => Container(
        color: AppPalette.gray200,
        child: const Center(
          child: Icon(Icons.content_cut, size: 40, color: Colors.white54),
        ),
      );

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HairstyleDetailSheet(
        item: item,
        isFavorite: isFavorite,
        onFavoriteToggle: onFavoriteToggle,
        onTryOn: onTryOn,
      ),
    );
  }
}

// ── Detail bottom sheet ───────────────────────────────────────────────────────

class _HairstyleDetailSheet extends StatelessWidget {
  final HairstyleItem item;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final void Function(HairstyleItem) onTryOn;

  const _HairstyleDetailSheet({
    required this.item,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTryOn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen grande
                  if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Image.network(
                          item.imageUrl!,
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: AppPalette.gray200,
                            child: const Center(
                                child: Icon(Icons.content_cut, size: 48)),
                          ),
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            if (item.gender != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.genderLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            // Favorite button
                            IconButton.filled(
                              onPressed: onFavoriteToggle,
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: isFavorite
                                    ? Colors.redAccent
                                    : theme.colorScheme.surfaceContainerHighest,
                                foregroundColor: isFavorite
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                              tooltip: isFavorite
                                  ? 'Quitar de favoritos'
                                  : 'Agregar a favoritos',
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Descripción completa
                        Text(
                          'Descripción',
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              onTryOn(item);
                            },
                            icon: const Icon(Icons.face_retouching_natural),
                            label: const Text('Probar virtualmente'),
                            style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.content_cut,
                size: 72,
                color: theme.colorScheme.outline.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text('Sin peinados disponibles',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Cuando el catálogo tenga peinados aparecerán aquí.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.55)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

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
                size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(message,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
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
