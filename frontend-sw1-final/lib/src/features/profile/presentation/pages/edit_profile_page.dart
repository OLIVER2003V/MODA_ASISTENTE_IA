import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

// ── Avatar styles disponibles ─────────────────────────────────────────────────

class _AvatarStyle {
  final String id;
  final String label;
  const _AvatarStyle(this.id, this.label);
}

const _kAvatarStyles = [
  _AvatarStyle('adventurer', 'Aventurero'),
  _AvatarStyle('avataaars', 'Avataaars'),
  _AvatarStyle('big-ears', 'Orejas'),
  _AvatarStyle('lorelei', 'Lorelei'),
  _AvatarStyle('micah', 'Micah'),
  _AvatarStyle('notionists', 'Notionists'),
  _AvatarStyle('open-peeps', 'Peeps'),
  _AvatarStyle('personas', 'Persona'),
];

// ── Page ──────────────────────────────────────────────────────────────────────

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameCtrl;
  final _formKey = GlobalKey<FormState>();

  File? _pendingPhoto;
  bool _photoPickerLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Foto ──────────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _photoPickerLoading = true);
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (xfile != null) {
        setState(() => _pendingPhoto = File(xfile.path));
      }
    } finally {
      setState(() => _photoPickerLoading = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPhoto() async {
    if (_pendingPhoto == null) return;
    final ok = await context.read<ProfileProvider>().uploadPhoto(_pendingPhoto!);
    if (ok && mounted) {
      setState(() => _pendingPhoto = null);
      _showSnack('Foto actualizada');
    } else if (mounted) {
      _showSnack(context.read<ProfileProvider>().saveError ?? 'Error al subir foto',
          isError: true);
    }
  }

  Future<void> _deletePhoto() async {
    final ok = await context.read<ProfileProvider>().deletePhoto();
    if (ok && mounted) {
      _showSnack('Foto eliminada');
    } else if (mounted) {
      _showSnack(context.read<ProfileProvider>().saveError ?? 'Error al eliminar foto',
          isError: true);
    }
  }

  // ── Nombre ────────────────────────────────────────────────────────────────

  Future<void> _saveName() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<ProfileProvider>().updateName(_nameCtrl.text.trim());
    if (ok && mounted) {
      _showSnack('Nombre actualizado');
    } else if (mounted) {
      _showSnack(context.read<ProfileProvider>().saveError ?? 'Error al actualizar nombre',
          isError: true);
    }
  }

  // ── Avatar ────────────────────────────────────────────────────────────────

  Future<void> _selectAvatar(String style) async {
    final ok = await context.read<ProfileProvider>().setAvatar(style);
    if (ok && mounted) {
      setState(() => _pendingPhoto = null);
      _showSnack('Avatar actualizado');
    } else if (mounted) {
      _showSnack(context.read<ProfileProvider>().saveError ?? 'Error al cambiar avatar',
          isError: true);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppPalette.error : AppPalette.success,
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        final user = provider.user;
        final saving = provider.isSaving;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Editar perfil'),
          ),
          body: saving
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── Avatar preview ────────────────────────────────
                      _buildAvatarPreview(user?.avatarUrl, user?.initials ?? '?', theme),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: _photoPickerLoading ? null : _showImageSourceSheet,
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: const Text('Cambiar foto'),
                          ),
                          if (user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: saving ? null : _deletePhoto,
                              icon: Icon(Icons.delete_outline, size: 18, color: AppPalette.error),
                              label: Text('Quitar foto', style: TextStyle(color: AppPalette.error)),
                            ),
                          ],
                        ],
                      ),
                      if (_pendingPhoto != null) ...[
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: saving ? null : _uploadPhoto,
                          icon: const Icon(Icons.upload_rounded, size: 18),
                          label: const Text('Subir foto seleccionada'),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // ── Nombre ────────────────────────────────────────
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Nombre visible',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      Form(
                        key: _formKey,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameCtrl,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  hintText: 'Tu nombre',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().length < 2) {
                                    return 'Mínimo 2 caracteres';
                                  }
                                  if (v.trim().length > 60) {
                                    return 'Máximo 60 caracteres';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: saving ? null : _saveName,
                              child: const Text('Guardar'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Avatar styles ─────────────────────────────────
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Elige un avatar',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Se eliminará la foto de perfil al elegir un avatar',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurface.withValues(alpha: 0.55))),
                      ),
                      const SizedBox(height: 16),
                      _buildAvatarGrid(user?.avatarStyle, user?.id ?? '', saving, theme),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildAvatarPreview(String? url, String initials, ThemeData theme) {
    Widget child;

    if (_pendingPhoto != null) {
      child = ClipOval(
        child: Image.file(_pendingPhoto!, width: 100, height: 100, fit: BoxFit.cover),
      );
    } else if (url != null) {
      child = CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(url),
        backgroundColor: AppPalette.gray200,
      );
    } else {
      child = CircleAvatar(
        radius: 50,
        backgroundColor: AppPalette.accent,
        child: Text(
          initials,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        child,
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.surface, width: 2),
          ),
          child: Icon(Icons.edit, size: 14, color: theme.colorScheme.onPrimary),
        ),
      ],
    );
  }

  Widget _buildAvatarGrid(
      String? selectedStyle, String userId, bool saving, ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _kAvatarStyles.length,
      itemBuilder: (_, i) {
        final style = _kAvatarStyles[i];
        final selected = selectedStyle == style.id;
        final url = 'https://api.dicebear.com/9.x/${style.id}/png?seed=$userId';

        return GestureDetector(
          onTap: saving ? null : () => _selectAvatar(style.id),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: selected ? 3 : 1.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                          )
                        ]
                      : null,
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(url),
                  backgroundColor: AppPalette.gray200,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                style.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
