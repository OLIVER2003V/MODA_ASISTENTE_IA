import 'dart:async';
import 'dart:typed_data';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saver_gallery/saver_gallery.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/outfit_service.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../wardrobe/presentation/providers/wardrobe_provider.dart';
import '../providers/outfit_history_provider.dart';

// ── Outfit detail + try-on bottom sheet ──────────────────────────────────────

void showOutfitDetail(BuildContext context, SavedOutfit outfit) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _OutfitDetailSheet(outfit: outfit),
  );
}

class _OutfitDetailSheet extends StatefulWidget {
  final SavedOutfit outfit;
  const _OutfitDetailSheet({required this.outfit});

  @override
  State<_OutfitDetailSheet> createState() => _OutfitDetailSheetState();
}

class _OutfitDetailSheetState extends State<_OutfitDetailSheet> {
  bool _generatingTryOn = false;
  String? _tryOnUrl;
  String? _tryOnError;

  @override
  void initState() {
    super.initState();
    // Si ya hay imagen cacheada, mostrarla directamente
    _tryOnUrl = widget.outfit.tryOnImageUrl;
  }

  Future<void> _startTryOn({bool regenerate = false}) async {
    setState(() { _generatingTryOn = true; _tryOnError = null; });
    try {
      final url = regenerate
          ? await OutfitService.regenerateTryOn(widget.outfit.id)
          : await OutfitService.generateTryOn(widget.outfit.id);
      if (mounted) setState(() { _tryOnUrl = url; _generatingTryOn = false; });
    } catch (e) {
      if (mounted) setState(() { _tryOnError = e.toString(); _generatingTryOn = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outfit = widget.outfit;
    final name = outfit.name?.isNotEmpty == true ? outfit.name! : 'Outfit sin nombre';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, sc) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(child: Text(name,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (outfit.score > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppPalette.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('★ ${outfit.score}', style: TextStyle(color: AppPalette.accent, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
          // Scrollable content
          Expanded(
            child: ListView(
              controller: sc,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                if (outfit.description?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(outfit.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                  ),

                // Prendas en grid
                Text('Prendas', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.75,
                  ),
                  itemCount: outfit.garmentOutfits.length,
                  itemBuilder: (_, i) {
                    final g = outfit.garmentOutfits[i].garment;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          g.path != null
                              ? Image.network(g.path!, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: AppPalette.gray200,
                                      child: const Icon(Icons.checkroom, size: 40, color: Colors.white54)))
                              : Container(color: AppPalette.gray200,
                                  child: const Icon(Icons.checkroom, size: 40, color: Colors.white54)),
                          if (g.name != null)
                            Positioned(bottom: 0, left: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                color: Colors.black54,
                                child: Text(g.name!, style: const TextStyle(color: Colors.white, fontSize: 12),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              )),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ── Try-On section ───────────────────────────────────────────
                Text('Cómo te queda', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                if (_generatingTryOn)
                  const TryOnLoadingWidget()
                else if (_tryOnError != null && _tryOnError!.contains('NO_BODY_PHOTO'))
                  const _TryOnNeedBodyPhotoWidget()
                else if (_tryOnError != null)
                  _TryOnErrorWidget(error: _tryOnError!, onRetry: () => _startTryOn(regenerate: true))
                else if (_tryOnUrl != null)
                  _TryOnResultWidget(
                    imageUrl: _tryOnUrl!,
                    onRegenerate: () => _startTryOn(regenerate: true),
                    outfitName: outfit.name,
                  )
                else
                  _TryOnPlaceholderWidget(onTap: () => _startTryOn()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Función pública de descarga (reutilizable desde wardrobe) ─────────────────

Future<void> downloadTryOnImage(BuildContext context, String imageUrl) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      final result = await SaverGallery.saveImage(
        Uint8List.fromList(response.bodyBytes),
        fileName: 'outfit_tryon_${DateTime.now().millisecondsSinceEpoch}.jpg',
        quality: 95,
        androidRelativePath: 'Pictures',
        skipIfExists: false,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.isSuccess ? 'Imagen guardada en la galería' : 'No se pudo guardar'),
          backgroundColor: result.isSuccess ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al descargar la imagen'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ── Loading animado con progreso simulado ─────────────────────────────────────

class TryOnLoadingWidget extends StatefulWidget {
  final List<String>? messages;
  final String? subtitle;
  const TryOnLoadingWidget({super.key, this.messages, this.subtitle});

  @override
  State<TryOnLoadingWidget> createState() => _TryOnLoadingWidgetState();
}

class _TryOnLoadingWidgetState extends State<TryOnLoadingWidget> {
  static const _defaultMessages = [
    'Preparando tu look...',
    'Aplicando las prendas...',
    'Ajustando los detalles...',
    '¡Casi listo!',
    'Un momento más...',
  ];

  List<String> get _messages => widget.messages ?? _defaultMessages;

  double _progress = 0.0;
  int _msgIndex = 0;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _seconds++;
        if (_seconds <= 8) {
          _progress = _seconds / 8 * 0.20;
        } else if (_seconds <= 18) {
          _progress = 0.20 + (_seconds - 8) / 10 * 0.30;
        } else if (_seconds <= 28) {
          _progress = 0.50 + (_seconds - 18) / 10 * 0.25;
        } else if (_seconds <= 38) {
          _progress = 0.75 + (_seconds - 28) / 10 * 0.15;
        } else {
          _progress = 0.90;
        }
        if (_seconds % 7 == 0) { _msgIndex = (_msgIndex + 1) % _messages.length; }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pulse(
            infinite: true,
            duration: const Duration(milliseconds: 1500),
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: AppPalette.accent.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(AppPalette.accent),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FadeInLeft(
                key: ValueKey(_msgIndex),
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _messages[_msgIndex],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${(_progress * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle ?? 'La IA está generando tu imagen con FLUX.2',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _TryOnPlaceholderWidget extends StatelessWidget {
  final VoidCallback onTap;
  const _TryOnPlaceholderWidget({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: isDark ? AppPalette.gray700 : AppPalette.gray100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 40, color: AppPalette.accent),
            const SizedBox(height: 12),
            Text('Probarme este outfit', style: theme.textTheme.titleSmall?.copyWith(color: AppPalette.accent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Genera una imagen realista de cómo te quedaría',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

class _TryOnResultWidget extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onRegenerate;
  final String? outfitName;

  const _TryOnResultWidget({
    required this.imageUrl,
    required this.onRegenerate,
    this.outfitName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              height: 200, color: AppPalette.gray200,
              child: const Icon(Icons.broken_image, size: 48, color: Colors.white54),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => downloadTryOnImage(context, imageUrl),
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
                  builder: (_) => ShareTryOnSheet(imageUrl: imageUrl),
                ),
                icon: const Icon(Icons.people_alt_rounded, size: 18),
                label: const Text('Comunidad'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: onRegenerate,
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: 'Regenerar',
              style: IconButton.styleFrom(
                side: BorderSide(color: AppPalette.accent.withValues(alpha: 0.3)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TryOnNeedBodyPhotoWidget extends StatelessWidget {
  const _TryOnNeedBodyPhotoWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.accessibility_new_rounded, color: AppPalette.accent, size: 36),
          const SizedBox(height: 10),
          Text('Necesitas una foto de cuerpo',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'Para ver cómo te queda el outfit, sube una foto de cuerpo completo en tu perfil. Así la imagen mostrará tu cara y tipo de cuerpo reales.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            icon: const Icon(Icons.person_outline, size: 16),
            label: const Text('Ir a mi perfil'),
            style: FilledButton.styleFrom(backgroundColor: AppPalette.accent),
          ),
        ],
      ),
    );
  }
}

class _TryOnErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _TryOnErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppPalette.error, size: 32),
          const SizedBox(height: 8),
          Text('No se pudo generar la imagen', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(error.replaceFirst('Exception: ', ''),
              style: theme.textTheme.bodySmall?.copyWith(color: AppPalette.error),
              textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh, size: 16), label: const Text('Reintentar')),
        ],
      ),
    );
  }
}

// ── Sheet de compartir en comunidad ──────────────────────────────────────────

class ShareTryOnSheet extends StatefulWidget {
  final String imageUrl;
  const ShareTryOnSheet({super.key, required this.imageUrl});

  @override
  State<ShareTryOnSheet> createState() => _ShareTryOnSheetState();
}

class _ShareTryOnSheetState extends State<ShareTryOnSheet> {
  final _captionController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    setState(() => _isPosting = true);
    try {
      await PostService.createPhotoPost(
        widget.imageUrl,
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('¡Publicado en la comunidad!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Compartir en Comunidad',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 100,
                color: AppPalette.accent.withValues(alpha: 0.1),
                child: const Icon(Icons.image_outlined),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _captionController,
            maxLines: 3,
            maxLength: 280,
            decoration: InputDecoration(
              hintText: 'Contá algo sobre tu outfit (opcional)...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isPosting ? null : _publish,
              icon: _isPosting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_isPosting ? 'Publicando...' : 'Publicar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class OutfitHistoryPage extends StatefulWidget {
  const OutfitHistoryPage({super.key});

  @override
  State<OutfitHistoryPage> createState() => _OutfitHistoryPageState();
}

class _OutfitHistoryPageState extends State<OutfitHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OutfitHistoryProvider>().load();
    });
  }

  void _showCreateSheet(BuildContext ctx) {
    final wardrobeProvider = ctx.read<WardrobeProvider>();
    wardrobeProvider.loadCloset();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateOutfitSheet(
        wardrobeProvider: wardrobeProvider,
        onSubmit: (name, ids) async {
          final ok = await ctx.read<OutfitHistoryProvider>().createManual(
                name: name,
                garmentIds: ids,
              );
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(ok ? 'Outfit creado' : 'Error al crear outfit'),
              backgroundColor: ok ? AppPalette.accent : AppPalette.error,
            ));
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, String outfitId, String name) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar outfit'),
        content: Text('¿Eliminar "$name"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppPalette.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && ctx.mounted) {
      final ok = await ctx.read<OutfitHistoryProvider>().remove(outfitId);
      if (!ok && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el outfit')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis outfits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => context.read<OutfitHistoryProvider>().load(force: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Crear outfit'),
      ),
      body: Consumer<OutfitHistoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return _ErrorState(
              message: provider.error!,
              onRetry: () => provider.load(force: true),
            );
          }

          if (provider.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.load(force: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.outfits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final outfit = provider.outfits[i];
                return _OutfitCard(
                  outfit: outfit,
                  onDelete: () => _confirmDelete(context, outfit.id, outfit.name ?? 'Outfit'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Outfit card ───────────────────────────────────────────────────────────────

class _OutfitCard extends StatelessWidget {
  final SavedOutfit outfit;
  final VoidCallback onDelete;

  const _OutfitCard({required this.outfit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = outfit.name?.isNotEmpty == true ? outfit.name! : 'Outfit sin nombre';
    final garments = outfit.garmentOutfits;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showOutfitDetail(context, outfit),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (outfit.score > 0) ...[
                  const SizedBox(width: 6),
                  _ScoreBadge(score: outfit.score),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppPalette.error,
                  tooltip: 'Eliminar',
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(outfit.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Garment images ────────────────────────────────────────────────
          if (garments.isNotEmpty)
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: garments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _GarmentThumb(garment: garments[i].garment),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Sin prendas',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),

          // ── Description ───────────────────────────────────────────────────
          if (outfit.description?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                outfit.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const SizedBox(height: 14),
        ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Garment thumbnail ─────────────────────────────────────────────────────────

class _GarmentThumb extends StatelessWidget {
  final Garment garment;
  const _GarmentThumb({required this.garment});

  @override
  Widget build(BuildContext context) {
    final url = garment.path;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              width: 90,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: 90,
        height: 110,
        color: AppPalette.gray200,
        child: const Icon(Icons.checkroom, color: Colors.white54, size: 32),
      );
}

// ── Score badge ───────────────────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppPalette.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '★ $score',
        style: TextStyle(
          color: AppPalette.accent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
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
            Icon(Icons.style_outlined, size: 72,
                color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            Text('Aún no tenés outfits guardados',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Generá un outfit con la IA o creá uno manualmente con el botón +.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create outfit sheet ───────────────────────────────────────────────────────

class _CreateOutfitSheet extends StatefulWidget {
  final WardrobeProvider wardrobeProvider;
  final Future<void> Function(String name, List<String> garmentIds) onSubmit;

  const _CreateOutfitSheet({
    required this.wardrobeProvider,
    required this.onSubmit,
  });

  @override
  State<_CreateOutfitSheet> createState() => _CreateOutfitSheetState();
}

class _CreateOutfitSheetState extends State<_CreateOutfitSheet> {
  final _nameCtrl = TextEditingController();
  final Set<String> _selected = {};
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresá un nombre para el outfit')));
      return;
    }
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccioná al menos una prenda')));
      return;
    }
    setState(() => _saving = true);
    await widget.onSubmit(name, _selected.toList());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final garments = widget.wardrobeProvider.garments;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, sc) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              Text('Nuevo outfit',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_saving)
                const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                FilledButton(onPressed: _submit, child: const Text('Crear')),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del outfit',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Seleccioná las prendas (${_selected.length} seleccionadas)',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ),
          Expanded(
            child: widget.wardrobeProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : garments.isEmpty
                    ? Center(
                        child: Text('No tenés prendas en tu armario',
                            style: theme.textTheme.bodyMedium))
                    : ListView.builder(
                        controller: sc,
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                        itemCount: garments.length,
                        itemBuilder: (_, i) {
                          final g = garments[i];
                          final selected = _selected.contains(g.id);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (_) => setState(() {
                              selected
                                  ? _selected.remove(g.id)
                                  : _selected.add(g.id);
                            }),
                            title: Text(
                              g.name?.isNotEmpty == true
                                  ? g.name!
                                  : 'Prenda sin nombre',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            secondary: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                g.path,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 48,
                                  height: 48,
                                  color: AppPalette.gray200,
                                  child: const Icon(Icons.checkroom,
                                      color: Colors.white54, size: 24),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
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
            Icon(Icons.error_outline, size: 56,
                color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(message,
                style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
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
