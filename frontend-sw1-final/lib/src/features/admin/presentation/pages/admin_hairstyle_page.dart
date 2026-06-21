import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/hairstyle_service.dart';
import '../../../../core/theme/app_theme.dart';

class AdminHairstylePage extends StatefulWidget {
  const AdminHairstylePage({super.key});

  @override
  State<AdminHairstylePage> createState() => _AdminHairstylePageState();
}

class _AdminHairstylePageState extends State<AdminHairstylePage> {
  String _gender = 'UNISEX';
  final List<File> _selected = [];
  bool _uploading = false;
  String? _result;
  String? _error;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    setState(() {
      _selected.addAll(picked.map((x) => File(x.path)));
      _result = null;
      _error = null;
    });
  }

  void _removeImage(int index) {
    setState(() => _selected.removeAt(index));
  }

  Future<void> _upload() async {
    if (_selected.isEmpty) {
      setState(() => _error = 'Seleccioná al menos una imagen.');
      return;
    }
    setState(() {
      _uploading = true;
      _result = null;
      _error = null;
    });
    try {
      final items = await HairstyleService.uploadHairstyles(_selected, _gender);
      setState(() {
        _result = '${items.length} peinado(s) subido(s) correctamente.';
        _selected.clear();
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Peinados'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info card ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.primary.withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPalette.primary.withValues(alpha:0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.info_outline, color: AppPalette.primary, size: 18),
                    const SizedBox(width: 8),
                    Text('¿Cómo funciona?',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppPalette.primary)),
                  ]),
                  const SizedBox(height: 8),
                  const Text(
                    'Cada imagen que subas será analizada automáticamente por Gemini AI, '
                    'que generará una descripción del estilo. Luego CLIP calculará un '
                    'embedding visual para mejorar las recomendaciones.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Gender selector ────────────────────────────────────────────────
            const Text('Género del peinado',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'FEMALE', label: Text('Femenino'), icon: Icon(Icons.face)),
                ButtonSegment(value: 'MALE',   label: Text('Masculino'), icon: Icon(Icons.face_3)),
                ButtonSegment(value: 'UNISEX', label: Text('Unisex'), icon: Icon(Icons.people)),
              ],
              selected: {_gender},
              onSelectionChanged: (v) => setState(() => _gender = v.first),
            ),
            const SizedBox(height: 24),

            // ── Image picker ───────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Imágenes (${_selected.length})',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                TextButton.icon(
                  onPressed: _uploading ? null : _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_selected.isEmpty)
              GestureDetector(
                onTap: _uploading ? null : _pickImages,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.grey.withValues(alpha:0.4), width: 1.5,
                        style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            size: 36, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('Tocá para seleccionar imágenes',
                            style: TextStyle(color: Colors.grey[500])),
                        Text('JPG, PNG, WebP — hasta 20 a la vez',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selected.length,
                itemBuilder: (ctx, i) => Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_selected[i], fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(i),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ── Result / error ─────────────────────────────────────────────────
            if (_result != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withValues(alpha:0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_result!,
                          style: const TextStyle(color: Colors.green))),
                ]),
              ),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha:0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha:0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red))),
                ]),
              ),

            const SizedBox(height: 20),

            // ── Upload button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _uploading || _selected.isEmpty ? null : _upload,
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.upload),
                label: Text(
                  _uploading
                      ? 'Subiendo ${_selected.length} imagen(es)...'
                      : 'Subir al catálogo',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Cada imagen es procesada individualmente — puede tomar unos segundos por foto.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
