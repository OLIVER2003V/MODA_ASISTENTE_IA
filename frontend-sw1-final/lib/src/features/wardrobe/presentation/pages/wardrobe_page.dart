import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/virtual_try_on_service.dart';
import '../../../outfit/presentation/pages/outfit_history_page.dart';
import '../../data/models/garment_model.dart';
import '../providers/wardrobe_provider.dart';

// TryOnLoadingWidget, ShareTryOnSheet y downloadTryOnImage se importan desde outfit_history_page.dart

class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  @override
  void initState() {
    super.initState();
    // Cargar datos solo si no hay caché reciente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WardrobeProvider>().loadCloset();
    });
  }

  void _openCreateClosetSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateClosetSheet(
        onClosetCreated: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openEditClosetDialog() {
    final provider = context.read<WardrobeProvider>();
    final closet = provider.closetData!.closet;
    showDialog(
      context: context,
      builder: (context) => EditClosetDialog(
        closetId: closet.id,
        currentName: closet.name,
        currentDescription: closet.description,
        onUpdated: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _confirmDeleteCloset() {
    showDialog(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l.delete),
          content: const Text(
            '¿Estás seguro de que quieres eliminar tu armario? '
            'Esta acción eliminará todas tus prendas y no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _deleteCloset();
              },
              style: TextButton.styleFrom(foregroundColor: AppPalette.error),
              child: Text(l.delete),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCloset() async {
    final provider = context.read<WardrobeProvider>();
    final success = await provider.deleteCloset();
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.closetDeleted),
          backgroundColor: AppPalette.success,
        ),
      );
    } else if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al eliminar'),
          backgroundColor: AppPalette.error,
        ),
      );
    }
  }

  void _openAddGarmentSheet() {
    final provider = context.read<WardrobeProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddGarmentSheet(
        closetId: provider.closetData!.closet.id,
        onGarmentAdded: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _editGarment(Garment garment) {
    final nameCtrl = TextEditingController(text: garment.name ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(ctx)!.editGarment,
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Camisa azul casual',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx);
                  final provider = context.read<WardrobeProvider>();
                  final ok =
                      await provider.updateGarment(garment.id, name: name);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok
                          ? AppLocalizations.of(context)!.garmentAdded
                          : provider.errorMessage ?? 'Error'),
                      backgroundColor:
                          ok ? AppPalette.success : AppPalette.error,
                    ));
                  }
                },
                child: Text(AppLocalizations.of(ctx)!.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGarment(Garment garment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l.editGarment),
          content: Text(
            '¿Eliminar ${garment.name ?? "esta prenda"}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppPalette.error),
              child: Text(l.delete),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final provider = context.read<WardrobeProvider>();
      final success = await provider.deleteGarment(garment.id);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.garmentDeleted),
            backgroundColor: AppPalette.success,
          ),
        );
      } else if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error al eliminar'),
            backgroundColor: AppPalette.error,
          ),
        );
      }
    }
  }

  void _openTryOnSheet(Garment garment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VirtualTryOnSheet(garment: garment),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WardrobeProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.wardrobe),
            actions: [
              IconButton(
                icon: const Icon(Icons.style_outlined),
                tooltip: AppLocalizations.of(context)!.myOutfits,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OutfitHistoryPage()),
                ),
              ),
              if (provider.hasData) ...[
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => provider.loadCloset(force: true),
                  tooltip: 'Actualizar',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _openEditClosetDialog();
                        break;
                      case 'delete':
                        _confirmDeleteCloset();
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    final l = AppLocalizations.of(context)!;
                    return [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20),
                            const SizedBox(width: 12),
                            Text(l.editCloset),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 20, color: AppPalette.error),
                            const SizedBox(width: 12),
                            Text(l.deleteCloset,
                                style: const TextStyle(color: AppPalette.error)),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ],
          ),
          body: _buildBody(provider),
          floatingActionButton: provider.hasData
              ? FloatingActionButton.extended(
                  onPressed: _openAddGarmentSheet,
                  backgroundColor: AppPalette.softCoral,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: Text(
                    AppLocalizations.of(context)!.addGarment,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(WardrobeProvider provider) {
    if (provider.isLoading && !provider.hasData) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppPalette.softCoral,
        ),
      );
    }

    if (provider.errorMessage != null && !provider.hasData) {
      return _buildErrorState(provider);
    }

    if (!provider.hasData) {
      return _buildEmptyState();
    }

    return _buildClosetView(provider);
  }

  Widget _buildErrorState(WardrobeProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppPalette.softGray,
            ),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => provider.loadCloset(force: true),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                gradient: AppPalette.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.checkroom_outlined,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Tu armario está vacío',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Crea tu armario virtual agregando fotos de tus prendas favoritas',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _openCreateClosetSheet,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.createMyCloset),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosetView(WardrobeProvider provider) {
    final closet = provider.closetData!.closet;
    final garments = provider.garments;

    return RefreshIndicator(
      onRefresh: () => provider.loadCloset(force: true),
      color: AppPalette.softCoral,
      child: CustomScrollView(
        slivers: [
          // Header del closet
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppPalette.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.checkroom,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              closet.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (closet.description != null &&
                                closet.description!.isNotEmpty)
                              Text(
                                closet.description!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      final isDark = theme.brightness == Brightness.dark;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${garments.length} prendas',
                          style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Grid de prendas
          if (garments.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: AppPalette.softGray,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay prendas en tu armario',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _openAddGarmentSheet,
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context)!.addFirstGarment),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _GarmentCard(
                    garment: garments[index],
                    onDelete: () => _deleteGarment(garments[index]),
                    onEdit: () => _editGarment(garments[index]),
                    onTryOn: () => _openTryOnSheet(garments[index]),
                  ),
                  childCount: garments.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// GARMENT CARD
// ============================================================================

class _GarmentCard extends StatelessWidget {
  final Garment garment;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTryOn;

  const _GarmentCard({
    required this.garment,
    required this.onDelete,
    required this.onEdit,
    required this.onTryOn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Image.network(
                    garment.path,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: theme.colorScheme.primary,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark ? AppPalette.gray700 : AppPalette.lightGray,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: isDark ? AppPalette.gray500 : AppPalette.gray400,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (garment.name != null && garment.name!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      garment.name!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            // Botones superpuestos (editar + eliminar)
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_outlined,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onTryOn,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 18),
                    ),
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

// ============================================================================
// VIRTUAL TRY-ON SHEET
// ============================================================================

class _VirtualTryOnSheet extends StatefulWidget {
  final Garment garment;
  const _VirtualTryOnSheet({required this.garment});

  @override
  State<_VirtualTryOnSheet> createState() => _VirtualTryOnSheetState();
}

class _VirtualTryOnSheetState extends State<_VirtualTryOnSheet> {
  File? _personPhoto;
  bool _isLoading = false;
  String? _resultUrl;
  String? _error;

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1024);
    if (picked != null && mounted) {
      setState(() {
        _personPhoto = File(picked.path);
        _resultUrl = null;
        _error = null;
      });
    }
  }

  Future<void> _generate() async {
    if (_personPhoto == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final url = await VirtualTryOnService.tryOn(widget.garment.id, _personPhoto!);
      if (mounted) setState(() { _resultUrl = url; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prueba virtual',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        widget.garment.name ?? 'Prenda',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Fila: prenda + foto persona ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('Prenda', style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      )),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.garment.path,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 130,
                            color: isDark ? AppPalette.gray700 : AppPalette.lightGray,
                            child: const Icon(Icons.checkroom_outlined, size: 40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Text('Tu foto', style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      )),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showPickerOptions(),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _personPhoto != null
                              ? Image.file(
                                  _personPhoto!,
                                  height: 130,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 130,
                                  width: double.infinity,
                                  color: isDark
                                      ? AppPalette.gray700
                                      : AppPalette.lightGray,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined,
                                          size: 32,
                                          color: theme.colorScheme.primary),
                                      const SizedBox(height: 6),
                                      Text('Seleccionar',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                          )),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Resultado ────────────────────────────────────────────────────
            if (_resultUrl != null) ...[
              Text('Resultado',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  )),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _resultUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 300,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(color: theme.colorScheme.primary),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: const Text('No se pudo cargar la imagen'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => downloadTryOnImage(context, _resultUrl!),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(AppLocalizations.of(context)!.save),
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
                        builder: (_) => ShareTryOnSheet(imageUrl: _resultUrl!),
                      ),
                      icon: const Icon(Icons.people_alt_rounded, size: 18),
                      label: Text(AppLocalizations.of(context)!.shareInCommunity),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPalette.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ── Error ────────────────────────────────────────────────────────
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppPalette.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppPalette.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppPalette.error)),
                ),
              ),

            // ── Botón generar ─────────────────────────────────────────────────
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: TryOnLoadingWidget(),
              )
            else
              ElevatedButton.icon(
                onPressed: _personPhoto != null ? _generate : null,
                icon: const Icon(Icons.auto_awesome),
                label: Text(_resultUrl != null ? 'Generar de nuevo' : 'Generar look'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

            if (_personPhoto == null && _resultUrl == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Seleccioná una foto tuya para probarte la prenda',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPickerOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(AppLocalizations.of(context)!.takePhoto),
              onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppLocalizations.of(context)!.chooseFromGallery),
              onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.gallery); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EDIT CLOSET DIALOG
// ============================================================================

class EditClosetDialog extends StatefulWidget {
  final String closetId;
  final String currentName;
  final String? currentDescription;
  final VoidCallback onUpdated;

  const EditClosetDialog({
    super.key,
    required this.closetId,
    required this.currentName,
    this.currentDescription,
    required this.onUpdated,
  });

  @override
  State<EditClosetDialog> createState() => _EditClosetDialogState();
}

class _EditClosetDialogState extends State<EditClosetDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _descriptionController =
        TextEditingController(text: widget.currentDescription ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.closetNameRequired),
          backgroundColor: AppPalette.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<WardrobeProvider>();
    final success = await provider.updateCloset(
      closetId: widget.closetId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.closetUpdated),
            backgroundColor: AppPalette.success,
          ),
        );
        widget.onUpdated();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error al actualizar'),
            backgroundColor: AppPalette.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.editCloset),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej: Mi armario principal',
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
              hintText: 'Ej: Ropa casual',
            ),
            enabled: !_isLoading,
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l.save),
        ),
      ],
    );
  }
}

// ============================================================================
// ADD GARMENT SHEET
// ============================================================================

class AddGarmentSheet extends StatefulWidget {
  final String closetId;
  final VoidCallback onGarmentAdded;

  const AddGarmentSheet({
    super.key,
    required this.closetId,
    required this.onGarmentAdded,
  });

  @override
  State<AddGarmentSheet> createState() => _AddGarmentSheetState();
}

class _AddGarmentSheetState extends State<AddGarmentSheet> {
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppPalette.error,
          ),
        );
      }
    }
  }

  Future<void> _addGarment() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.chooseFromGallery),
          backgroundColor: AppPalette.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<WardrobeProvider>();
    final success = await provider.addGarment(
      imageFile: _selectedImage!,
      pathLocal: _selectedImage!.path,
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.garmentAdded),
            backgroundColor: AppPalette.success,
          ),
        );
        widget.onGarmentAdded();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error al agregar'),
            backgroundColor: AppPalette.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.addGarment,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Imagen
              if (_selectedImage == null)
                Row(
                  children: [
                    Expanded(
                      child: _SourceButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Galería',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SourceButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Cámara',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                  ],
                )
              else
                Stack(
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppPalette.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              // Nombre opcional
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre (opcional)',
                  hintText: 'Ej: Camisa azul',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              // Botón agregar
              ElevatedButton(
                onPressed: _isLoading ? null : _addGarment,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(l.addGarment),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CREATE CLOSET SHEET
// ============================================================================

class CreateClosetSheet extends StatefulWidget {
  final VoidCallback onClosetCreated;

  const CreateClosetSheet({super.key, required this.onClosetCreated});

  @override
  State<CreateClosetSheet> createState() => _CreateClosetSheetState();
}

class _CreateClosetSheetState extends State<CreateClosetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (images.isNotEmpty && mounted) {
        setState(() {
          _selectedImages.addAll(images.map((x) => File(x.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imágenes: $e'),
            backgroundColor: AppPalette.error,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar la foto: $e'),
            backgroundColor: AppPalette.error,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _createCloset() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.closetNameRequired),
          backgroundColor: AppPalette.error,
        ),
      );
      setState(() => _currentStep = 0);
      return;
    }
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.mustAddGarment),
          backgroundColor: AppPalette.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<WardrobeProvider>();
    final pathLocals = _selectedImages.map((f) => f.path).toList();

    final success = await provider.createCloset(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      imageFiles: _selectedImages,
      pathLocals: pathLocals,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.closetCreated),
            backgroundColor: AppPalette.success,
          ),
        );
        widget.onClosetCreated();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Error al crear'),
            backgroundColor: AppPalette.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    l.createMyCloset,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // Steps indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _StepIndicator(
                  step: 1,
                  title: 'Información',
                  isActive: _currentStep == 0,
                  isCompleted: _currentStep > 0,
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _currentStep > 0
                        ? AppPalette.softCoral
                        : AppPalette.softGray.withOpacity(0.3),
                  ),
                ),
                _StepIndicator(
                  step: 2,
                  title: 'Prendas',
                  isActive: _currentStep == 1,
                  isCompleted: _currentStep > 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child:
                  _currentStep == 0 ? _buildInfoStep() : _buildGarmentsStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppPalette.secondaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.checkroom,
                    size: 64,
                    color: AppPalette.charcoalGray,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dale un nombre a tu armario',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del armario',
                hintText: 'Ej: Mi armario principal',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!.closetNameRequired;
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Ej: Ropa casual y de trabajo',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() => _currentStep = 1);
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.next),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGarmentsStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _AddButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Galería',
                        onTap: _pickImages,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AddButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Cámara',
                        onTap: _takePhoto,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_selectedImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      '${_selectedImages.length} prendas seleccionadas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                if (_selectedImages.isEmpty)
                  Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      final isDark = theme.brightness == Brightness.dark;
                      return Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: isDark ? AppPalette.gray800 : AppPalette.lightGray,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 64,
                              color: isDark ? AppPalette.gray500 : AppPalette.gray400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Agrega fotos de tus prendas',
                              style:
                                  theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return _ImageTile(
                        file: _selectedImages[index],
                        onRemove: () => _removeImage(index),
                      );
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final l = AppLocalizations.of(context)!;
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isLoading ? null : () => setState(() => _currentStep = 0),
                        child: Text(l.back),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createCloset,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l.createCloset),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  final String title;
  final bool isActive;
  final bool isCompleted;

  const _StepIndicator({
    required this.step,
    required this.title,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive || isCompleted
        ? AppPalette.softCoral
        : AppPalette.softGray.withOpacity(0.5);

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive || isCompleted ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const _ImageTile({
    required this.file,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppPalette.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
