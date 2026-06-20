import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/selfie_analysis_service.dart';
import '../../data/models/user_attribute_model.dart';
import '../providers/profile_provider.dart';

class EditAttributesPage extends StatefulWidget {
  final UserAttribute attributes;
  const EditAttributesPage({super.key, required this.attributes});

  @override
  State<EditAttributesPage> createState() => _EditAttributesPageState();
}

class _EditAttributesPageState extends State<EditAttributesPage> {
  late String? _gender;
  late int? _age;
  late double? _stature;
  late double? _weight;
  late String? _bodyType;
  late String? _skinTone;
  late String? _faceType;
  late String? _clothingSize;
  late String? _budget;
  late String? _climate;
  late List<String> _preferredStyles;

  final _professionCtrl = TextEditingController();

  static const _genders = ['MALE', 'FEMALE', 'NON_BINARY', 'OTHER'];
  static const _genderLabels = {
    'MALE': 'Masculino',
    'FEMALE': 'Femenino',
    'NON_BINARY': 'No binario',
    'OTHER': 'Otro',
  };

  static const _bodyTypes = [
    'PEAR', 'RECTANGLE', 'HOURGLASS', 'APPLE', 'INVERTED_TRIANGLE'
  ];
  static const _bodyTypeLabels = {
    'PEAR': 'Pera',
    'RECTANGLE': 'Rectángulo',
    'HOURGLASS': 'Reloj de arena',
    'APPLE': 'Manzana',
    'INVERTED_TRIANGLE': 'Triángulo invertido',
  };

  static const _skinTones = [
    'LIGHT', 'MEDIUM_LIGHT', 'MEDIUM', 'MEDIUM_DARK', 'DARK'
  ];
  static const _skinToneLabels = {
    'LIGHT': 'Clara',
    'MEDIUM_LIGHT': 'Medio clara',
    'MEDIUM': 'Media',
    'MEDIUM_DARK': 'Medio oscura',
    'DARK': 'Oscura',
  };

  static const _faceTypes = ['OVAL', 'ROUND', 'SQUARE', 'HEART', 'OBLONG'];
  static const _faceTypeLabels = {
    'OVAL': 'Oval',
    'ROUND': 'Redonda',
    'SQUARE': 'Cuadrada',
    'HEART': 'Corazón',
    'OBLONG': 'Alargada',
  };

  static const _styles = [
    'CASUAL', 'FORMAL', 'SPORTY', 'BOHEMIAN', 'MINIMALIST',
    'ELEGANT', 'STREETWEAR', 'VINTAGE', 'ROMANTIC',
  ];
  static const _styleLabels = {
    'CASUAL': 'Casual',
    'FORMAL': 'Formal',
    'SPORTY': 'Deportivo',
    'BOHEMIAN': 'Bohemio',
    'MINIMALIST': 'Minimalista',
    'ELEGANT': 'Elegante',
    'STREETWEAR': 'Streetwear',
    'VINTAGE': 'Vintage',
    'ROMANTIC': 'Romántico',
  };

  static const _sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static const _budgets = ['LOW', 'MEDIUM', 'HIGH', 'LUXURY'];
  static const _budgetLabels = {
    'LOW': 'Económico',
    'MEDIUM': 'Medio',
    'HIGH': 'Alto',
    'LUXURY': 'Lujo',
  };
  static const _climates = [
    'TROPICAL', 'DRY', 'TEMPERATE', 'CONTINENTAL', 'POLAR'
  ];
  static const _climateLabels = {
    'TROPICAL': 'Tropical',
    'DRY': 'Árido',
    'TEMPERATE': 'Templado',
    'CONTINENTAL': 'Continental',
    'POLAR': 'Polar',
  };

  @override
  void initState() {
    super.initState();
    final a = widget.attributes;
    _gender = a.gender;
    _age = a.age;
    _stature = a.stature;
    _weight = a.weight;
    _bodyType = a.bodyType;
    _skinTone = a.skinTone;
    _faceType = a.faceType;
    _clothingSize = a.clothingSize;
    _budget = a.budget;
    _climate = a.climate;
    _preferredStyles = List<String>.from(a.preferredStyles);
    _professionCtrl.text = a.profession ?? '';
  }

  @override
  void dispose() {
    _professionCtrl.dispose();
    super.dispose();
  }

  void _openSelfieSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelfieAnalysisSheet(onApply: _applyAnalysis),
    );
  }

  void _applyAnalysis(SelfieAnalysisResult result) {
    Navigator.pop(context);
    setState(() {
      if (result.gender != null) _gender = result.gender;
      if (result.bodyType != null) _bodyType = result.bodyType;
      if (result.skinTone != null) _skinTone = result.skinTone;
      if (result.faceType != null) _faceType = result.faceType;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Características aplicadas al perfil'),
        backgroundColor: AppPalette.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save() async {
    final data = <String, dynamic>{
      if (_gender != null) 'gender': _gender,
      if (_age != null) 'age': _age,
      if (_stature != null) 'stature': _stature,
      if (_weight != null) 'weight': _weight,
      if (_bodyType != null) 'bodyType': _bodyType,
      if (_skinTone != null) 'skinTone': _skinTone,
      if (_faceType != null) 'faceType': _faceType,
      if (_clothingSize != null) 'clothingSize': _clothingSize,
      if (_budget != null) 'budget': _budget,
      if (_climate != null) 'climate': _climate,
      'profession': _professionCtrl.text.trim().isEmpty ? null : _professionCtrl.text.trim(),
      'preferredStyles': _preferredStyles,
    };

    final ok = await context.read<ProfileProvider>().updateAttributes(data);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Preferencias actualizadas'),
        backgroundColor: AppPalette.success,
      ));
      Navigator.pop(context);
    } else {
      final err = context.read<ProfileProvider>().saveError ?? 'Error al guardar';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: AppPalette.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaving = context.watch<ProfileProvider>().isSaving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar preferencias'),
        actions: [
          TextButton(
            onPressed: isSaving ? null : _save,
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Guardar',
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Banner IA ────────────────────────────────────────────────────
          _AiBanner(onTap: _openSelfieSheet),
          const SizedBox(height: 24),

          // ── Datos físicos ────────────────────────────────────────────────
          _sectionHeader(theme, Icons.person_outline, 'Datos físicos'),
          const SizedBox(height: 12),

          _chipSelector(
            theme: theme,
            label: 'Género',
            options: _genders,
            labels: _genderLabels,
            selected: _gender,
            onSelected: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 16),

          _numberField(
            theme: theme,
            label: 'Edad',
            value: _age?.toDouble(),
            min: 12,
            max: 99,
            divisions: 87,
            unit: 'años',
            onChanged: (v) => setState(() => _age = v.round()),
          ),
          const SizedBox(height: 16),

          _numberField(
            theme: theme,
            label: 'Estatura',
            value: _stature,
            min: 140,
            max: 220,
            divisions: 80,
            unit: 'cm',
            onChanged: (v) => setState(() => _stature = v.roundToDouble()),
          ),
          const SizedBox(height: 16),

          _numberField(
            theme: theme,
            label: 'Peso',
            value: _weight,
            min: 40,
            max: 150,
            divisions: 110,
            unit: 'kg',
            onChanged: (v) => setState(() => _weight = v.roundToDouble()),
          ),
          const SizedBox(height: 16),

          _chipSelector(
            theme: theme,
            label: 'Tipo de cuerpo',
            options: _bodyTypes,
            labels: _bodyTypeLabels,
            selected: _bodyType,
            onSelected: (v) => setState(() => _bodyType = v),
          ),

          const SizedBox(height: 28),

          // ── Apariencia ───────────────────────────────────────────────────
          _sectionHeader(theme, Icons.face_outlined, 'Apariencia'),
          const SizedBox(height: 12),

          _chipSelector(
            theme: theme,
            label: 'Tono de piel',
            options: _skinTones,
            labels: _skinToneLabels,
            selected: _skinTone,
            onSelected: (v) => setState(() => _skinTone = v),
          ),
          const SizedBox(height: 16),

          _chipSelector(
            theme: theme,
            label: 'Forma del rostro',
            options: _faceTypes,
            labels: _faceTypeLabels,
            selected: _faceType,
            onSelected: (v) => setState(() => _faceType = v),
          ),

          const SizedBox(height: 28),

          // ── Estilo ───────────────────────────────────────────────────────
          _sectionHeader(theme, Icons.style_outlined, 'Estilos preferidos'),
          const SizedBox(height: 8),
          Text(
            'Seleccioná todos los que te representen',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _styles.map((s) {
              final selected = _preferredStyles.contains(s);
              return FilterChip(
                label: Text(_styleLabels[s] ?? s),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) {
                    _preferredStyles.add(s);
                  } else {
                    _preferredStyles.remove(s);
                  }
                }),
                showCheckmark: true,
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // ── Contexto ─────────────────────────────────────────────────────
          _sectionHeader(theme, Icons.work_outline, 'Contexto personal'),
          const SizedBox(height: 12),

          TextField(
            controller: _professionCtrl,
            decoration: InputDecoration(
              labelText: 'Profesión',
              hintText: 'Ej: Diseñadora gráfica',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          _chipSelector(
            theme: theme,
            label: 'Clima habitual',
            options: _climates,
            labels: _climateLabels,
            selected: _climate,
            onSelected: (v) => setState(() => _climate = v),
          ),
          const SizedBox(height: 16),

          _chipSelector(
            theme: theme,
            label: 'Talla de ropa',
            options: _sizes,
            labels: {for (final s in _sizes) s: s},
            selected: _clothingSize,
            onSelected: (v) => setState(() => _clothingSize = v),
          ),
          const SizedBox(height: 16),

          _chipSelector(
            theme: theme,
            label: 'Presupuesto',
            options: _budgets,
            labels: _budgetLabels,
            selected: _budget,
            onSelected: (v) => setState(() => _budget = v),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
            child: Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3))),
      ],
    );
  }

  Widget _chipSelector({
    required ThemeData theme,
    required String label,
    required List<String> options,
    required Map<String, String> labels,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: options.map((opt) {
            final isSelected = selected == opt;
            return ChoiceChip(
              label: Text(labels[opt] ?? opt),
              selected: isSelected,
              onSelected: (_) => onSelected(isSelected ? null : opt),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _numberField({
    required ThemeData theme,
    required String label,
    required double? value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    final display = value != null ? '${value.round()} $unit' : 'Sin definir';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text(display,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value?.clamp(min, max) ?? min,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ============================================================================
// AI BANNER
// ============================================================================

class _AiBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _AiBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Completar con IA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Sacate una foto y detectamos tu tipo de rostro, tono de piel y más',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Analizar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SELFIE ANALYSIS SHEET
// ============================================================================

enum _AnalysisStep { intro, loading, result }

class _SelfieAnalysisSheet extends StatefulWidget {
  final void Function(SelfieAnalysisResult) onApply;
  const _SelfieAnalysisSheet({required this.onApply});

  @override
  State<_SelfieAnalysisSheet> createState() => _SelfieAnalysisSheetState();
}

class _SelfieAnalysisSheetState extends State<_SelfieAnalysisSheet> {
  _AnalysisStep _step = _AnalysisStep.intro;
  SelfieAnalysisResult? _result;
  String? _error;

  // ── Label maps ─────────────────────────────────────────────────────────────
  static const _faceLabels = {
    'OVAL': 'Oval', 'ROUND': 'Redonda', 'SQUARE': 'Cuadrada',
    'HEART': 'Corazón', 'OBLONG': 'Alargada',
  };
  static const _skinLabels = {
    'LIGHT': 'Clara', 'MEDIUM_LIGHT': 'Medio clara', 'MEDIUM': 'Media',
    'MEDIUM_DARK': 'Medio oscura', 'DARK': 'Oscura',
  };
  static const _hairColorLabels = {
    'BLACK': 'Negro', 'DARK_BROWN': 'Marrón oscuro', 'BROWN': 'Marrón',
    'LIGHT_BROWN': 'Marrón claro', 'BLONDE': 'Rubio', 'PLATINUM': 'Platinado',
    'RED': 'Rojo', 'GRAY': 'Gris', 'WHITE': 'Blanco',
  };
  static const _hairTypeLabels = {
    'STRAIGHT': 'Liso', 'WAVY': 'Ondulado', 'CURLY': 'Rizado', 'COILY': 'Muy rizado',
  };
  static const _eyeLabels = {
    'DARK_BROWN': 'Marrón oscuro', 'BROWN': 'Marrón', 'LIGHT_BROWN': 'Marrón claro',
    'HAZEL': 'Avellana', 'AMBER': 'Ámbar', 'BLUE': 'Azul', 'LIGHT_BLUE': 'Azul claro',
    'GREEN': 'Verde', 'LIGHT_GREEN': 'Verde claro', 'GRAY': 'Gris', 'BLACK': 'Negro',
  };
  static const _genderLabels = {
    'MALE': 'Masculino', 'FEMALE': 'Femenino', 'NON_BINARY': 'No binario',
  };
  static const _bodyLabels = {
    'PEAR': 'Pera', 'RECTANGLE': 'Rectángulo', 'HOURGLASS': 'Reloj de arena',
    'APPLE': 'Manzana', 'INVERTED_TRIANGLE': 'Triángulo invertido',
  };

  Future<void> _pickAndAnalyze(bool isFullBody) async {
    final picker = ImagePicker();
    final source = await _showSourcePicker();
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;

    setState(() { _step = _AnalysisStep.loading; _error = null; });

    try {
      final result = await SelfieAnalysisService.analyze(
        File(picked.path),
        isFullBody: isFullBody,
      );
      if (mounted) setState(() { _result = result; _step = _AnalysisStep.result; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _step = _AnalysisStep.intro;
        });
      }
    }
  }

  Future<ImageSource?> _showSourcePicker() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _confColor(int c) {
    if (c >= 75) return const Color(0xFF22C55E);
    if (c >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_step == _AnalysisStep.intro) _buildIntro(theme),
          if (_step == _AnalysisStep.loading) _buildLoading(theme),
          if (_step == _AnalysisStep.result) _buildResult(theme),
        ],
      ),
    );
  }

  // ── Step 1: Intro ──────────────────────────────────────────────────────────

  Widget _buildIntro(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Análisis con IA',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text('Detectamos tus características físicas al instante',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    )),
              ]),
            ),
          ]),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppPalette.error.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppPalette.error, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppPalette.error))),
              ]),
            ),
          ],

          const SizedBox(height: 24),
          Text('¿Qué foto vas a usar?',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          // ── Tarjetas de tipo ──────────────────────────────────────────────
          Row(children: [
            Expanded(child: _TypeCard(
              icon: Icons.face_retouching_natural,
              title: 'Solo rostro',
              subtitle: 'Rostro, piel, cabello y ojos',
              onTap: () => _pickAndAnalyze(false),
            )),
            const SizedBox(width: 12),
            Expanded(child: _TypeCard(
              icon: Icons.accessibility_new,
              title: 'Cuerpo completo',
              subtitle: 'Todo lo anterior + tipo de cuerpo',
              onTap: () => _pickAndAnalyze(true),
            )),
          ]),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline,
                    color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Consejos: buena iluminación, fondo simple y el rostro bien visible.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Step 2: Loading ────────────────────────────────────────────────────────

  Widget _buildLoading(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          SizedBox(
            width: 80, height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80, height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Analizando tu foto...',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('La IA está detectando tus características físicas',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Step 3: Results ────────────────────────────────────────────────────────

  Widget _buildResult(ThemeData theme) {
    final r = _result!;
    final rows = <_ResultRow>[
      if (r.gender != null)
        _ResultRow('Género', _genderLabels[r.gender] ?? r.gender!, Icons.wc, r.conf('gender')),
      if (r.faceType != null)
        _ResultRow('Forma del rostro', _faceLabels[r.faceType] ?? r.faceType!, Icons.face, r.conf('faceType')),
      if (r.skinTone != null)
        _ResultRow('Tono de piel', _skinLabels[r.skinTone] ?? r.skinTone!, Icons.palette_outlined, r.conf('skinTone')),
      if (r.hairColor != null)
        _ResultRow('Color de cabello', _hairColorLabels[r.hairColor] ?? r.hairColor!, Icons.cut, r.conf('hairColor')),
      if (r.hairType != null)
        _ResultRow('Tipo de cabello', _hairTypeLabels[r.hairType] ?? r.hairType!, Icons.waves, r.conf('hairType')),
      if (r.eyeColor != null)
        _ResultRow('Color de ojos', _eyeLabels[r.eyeColor] ?? r.eyeColor!, Icons.remove_red_eye_outlined, r.conf('eyeColor')),
      if (r.bodyType != null)
        _ResultRow('Tipo de cuerpo', _bodyLabels[r.bodyType] ?? r.bodyType!, Icons.accessibility_new, r.conf('bodyType')),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Análisis completado',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text('Revisá los resultados y aplicá los que desees',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  )),
            ])),
          ]),
          const SizedBox(height: 20),

          ...rows.map((row) => _buildResultRow(theme, row)),

          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => widget.onApply(r),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Aplicar al perfil'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() { _step = _AnalysisStep.intro; _result = null; }),
            child: Text('Volver a analizar',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildResultRow(ThemeData theme, _ResultRow row) {
    final color = _confColor(row.confidence);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(row.icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                )),
            Text(row.value,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        )),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${row.confidence}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color, fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                width: 48, height: 4,
                child: LinearProgressIndicator(
                  value: row.confidence / 100,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                    theme.colorScheme.primary.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 28),
            ),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                )),
          ],
        ),
      ),
    );
  }
}

class _ResultRow {
  final String label;
  final String value;
  final IconData icon;
  final int confidence;
  const _ResultRow(this.label, this.value, this.icon, this.confidence);
}
