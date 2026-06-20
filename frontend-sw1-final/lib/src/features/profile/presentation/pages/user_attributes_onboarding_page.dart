import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/user_attribute_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/user_attribute_model.dart';
import 'package:animate_do/animate_do.dart';

// ─── Constantes de opciones ───────────────────────────────────────────────────

const _genders = [
  {'label': 'Masculino',   'value': 'MALE'},
  {'label': 'Femenino',    'value': 'FEMALE'},
  {'label': 'No binario',  'value': 'NON_BINARY'},
  {'label': 'Prefiero no decir', 'value': 'OTHER'},
];

const _bodyTypes = [
  {'label': 'Pera',              'value': 'PEAR',               'desc': 'Caderas más anchas que hombros'},
  {'label': 'Rectángulo',        'value': 'RECTANGLE',          'desc': 'Hombros, cintura y caderas similares'},
  {'label': 'Reloj de arena',    'value': 'HOURGLASS',          'desc': 'Hombros y caderas similares, cintura marcada'},
  {'label': 'Manzana',           'value': 'APPLE',              'desc': 'Mayor volumen en la zona media'},
  {'label': 'Triángulo invertido','value': 'INVERTED_TRIANGLE', 'desc': 'Hombros más anchos que caderas'},
];

final _skinTones = [
  {'label': 'Muy clara',  'value': 'LIGHT',       'color': const Color(0xFFFFE5D4)},
  {'label': 'Clara',      'value': 'MEDIUM_LIGHT', 'color': const Color(0xFFFFD5B8)},
  {'label': 'Media',      'value': 'MEDIUM',       'color': const Color(0xFFD4A574)},
  {'label': 'Morena',     'value': 'MEDIUM_DARK',  'color': const Color(0xFFB07D4B)},
  {'label': 'Oscura',     'value': 'DARK',         'color': const Color(0xFF6B3F1E)},
];

const _faceTypes = [
  {'label': 'Ovalada',    'value': 'OVAL'},
  {'label': 'Redonda',    'value': 'ROUND'},
  {'label': 'Cuadrada',   'value': 'SQUARE'},
  {'label': 'Corazón',    'value': 'HEART'},
  {'label': 'Alargada',   'value': 'OBLONG'},
];

const _styleOptions = [
  {'label': 'Casual',      'value': 'CASUAL',      'icon': '👕'},
  {'label': 'Formal',      'value': 'FORMAL',      'icon': '👔'},
  {'label': 'Streetwear',  'value': 'STREETWEAR',  'icon': '🧢'},
  {'label': 'Bohemio',     'value': 'BOHEMIAN',    'icon': '🌸'},
  {'label': 'Minimalista', 'value': 'MINIMALIST',  'icon': '⬜'},
  {'label': 'Deportivo',   'value': 'SPORTY',      'icon': '🏃'},
  {'label': 'Elegante',    'value': 'ELEGANT',     'icon': '✨'},
];

const _clothingSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

const _budgets = [
  {'label': 'Económico',   'value': 'LOW',    'desc': 'Marcas accesibles y outlet'},
  {'label': 'Moderado',    'value': 'MEDIUM', 'desc': 'Balance calidad-precio'},
  {'label': 'Premium',     'value': 'HIGH',   'desc': 'Marcas de diseñador'},
  {'label': 'Lujo',        'value': 'LUXURY', 'desc': 'Alta costura y exclusivo'},
];

const int _totalSteps = 8;

// ─── Page ─────────────────────────────────────────────────────────────────────

class UserAttributesOnboardingPage extends StatefulWidget {
  final String userId;
  const UserAttributesOnboardingPage({super.key, required this.userId});

  @override
  State<UserAttributesOnboardingPage> createState() =>
      _UserAttributesOnboardingPageState();
}

class _UserAttributesOnboardingPageState
    extends State<UserAttributesOnboardingPage> {
  int _currentStep = 0;
  bool _isLoading = false;
  late final PageController _pageController;

  // Datos del formulario
  String? _gender;
  int? _age;
  double? _stature;
  double? _weight;
  String? _bodyType;
  String? _skinTone;
  String? _faceType;
  final List<String> _preferredStyles = [];
  String? _clothingSize;
  String? _budget;
  String? _profession;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.cream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
                children: [
                  _buildGenderStep(),       // 0
                  _buildAgeStep(),          // 1
                  _buildPhysicalStep(),     // 2
                  _buildBodyTypeStep(),     // 3 ← nuevo
                  _buildSkinToneStep(),     // 4
                  _buildFaceTypeStep(),     // 5
                  _buildStylesStep(),       // 6 ← nuevo
                  _buildSizeAndBudget(),    // 7 ← nuevo
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  // ── Header con barra de progreso ───────────────────────────────────────────

  Widget _buildHeader() {
    final progress = (_currentStep + 1) / _totalSteps;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppPalette.softGray.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(AppPalette.softCoral),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_currentStep + 1}/$_totalSteps',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppPalette.charcoalGray),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _stepTitle(_currentStep),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppPalette.charcoalGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _stepSubtitle(_currentStep),
            style: TextStyle(fontSize: 13, color: AppPalette.charcoalGray.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Paso 0: Género ─────────────────────────────────────────────────────────

  Widget _buildGenderStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          ..._genders.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _SelectionCard(
              label: g['label']!,
              isSelected: _gender == g['value'],
              onTap: () => setState(() => _gender = g['value']),
            ),
          )),
        ],
      ),
    );
  }

  // ── Paso 1: Edad ───────────────────────────────────────────────────────────

  Widget _buildAgeStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cake_outlined, size: 72, color: AppPalette.softCoral),
            const SizedBox(height: 32),
            _SliderCard(
              label: _age != null ? '$_age años' : 'Seleccioná tu edad',
              value: _age?.toDouble() ?? 25,
              min: 13, max: 80, divisions: 67,
              onChanged: (v) => setState(() => _age = v.round()),
            ),
          ],
        ),
      ),
    );
  }

  // ── Paso 2: Físico (estatura + peso) ───────────────────────────────────────

  Widget _buildPhysicalStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.height_outlined, size: 72, color: AppPalette.softCoral),
          const SizedBox(height: 24),
          _SliderCard(
            label: _stature != null ? '${_stature!.round()} cm' : 'Estatura',
            value: _stature ?? 165,
            min: 140, max: 210, divisions: 70,
            onChanged: (v) => setState(() => _stature = v),
          ),
          const SizedBox(height: 20),
          _SliderCard(
            label: _weight != null ? '${_weight!.round()} kg' : 'Peso',
            value: _weight ?? 65,
            min: 35, max: 150, divisions: 115,
            onChanged: (v) => setState(() => _weight = v),
          ),
        ],
      ),
    );
  }

  // ── Paso 3: Tipo de cuerpo ─────────────────────────────────────────────────

  Widget _buildBodyTypeStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          ..._bodyTypes.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SelectionCard(
              label: b['label']!,
              subtitle: b['desc'],
              isSelected: _bodyType == b['value'],
              onTap: () => setState(() => _bodyType = b['value']),
            ),
          )),
        ],
      ),
    );
  }

  // ── Paso 4: Tono de piel ───────────────────────────────────────────────────

  Widget _buildSkinToneStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Preview del tono seleccionado
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _skinTone != null
                    ? (_skinTones.firstWhere((s) => s['value'] == _skinTone)['color'] as Color)
                    : AppPalette.softGray.withValues(alpha: 0.2),
                border: Border.all(color: AppPalette.softCoral, width: 3),
              ),
              child: _skinTone != null
                  ? const Icon(Icons.check, color: Colors.white, size: 36)
                  : Icon(Icons.touch_app_outlined, color: AppPalette.softGray, size: 36),
            ),
            const SizedBox(height: 8),
            Text(
              _skinTone != null
                  ? _skinTones.firstWhere((s) => s['value'] == _skinTone)['label'] as String
                  : 'Seleccioná un tono',
              style: TextStyle(fontSize: 15, color: AppPalette.charcoalGray, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16, runSpacing: 20,
              alignment: WrapAlignment.center,
              children: _skinTones.map((tone) {
                final isSelected = _skinTone == tone['value'];
                final color = tone['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _skinTone = tone['value'] as String),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 68 : 58,
                        height: isSelected ? 68 : 58,
                        decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppPalette.softCoral : Colors.white,
                            width: isSelected ? 4 : 3,
                          ),
                          boxShadow: [BoxShadow(
                            color: isSelected ? AppPalette.softCoral.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.12),
                            blurRadius: isSelected ? 14 : 6,
                            offset: const Offset(0, 4),
                          )],
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 26) : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tone['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppPalette.charcoalGray : AppPalette.softGray,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Paso 5: Forma del rostro ───────────────────────────────────────────────

  Widget _buildFaceTypeStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.face_outlined, size: 72, color: AppPalette.softCoral),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12, runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _faceTypes.map((f) {
                final isSelected = _faceType == f['value'];
                return GestureDetector(
                  onTap: () => setState(() => _faceType = f['value']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppPalette.softCoral : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected ? AppPalette.softCoral : AppPalette.softGray.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: isSelected ? [BoxShadow(
                        color: AppPalette.softCoral.withValues(alpha: 0.3),
                        blurRadius: 14, offset: const Offset(0, 5),
                      )] : null,
                    ),
                    child: Text(
                      f['label']!,
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppPalette.charcoalGray,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Paso 6: Estilos preferidos (multi-select) ──────────────────────────────

  Widget _buildStylesStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _styleOptions.map((s) {
              final value = s['value'] as String;
              final isSelected = _preferredStyles.contains(value);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    _preferredStyles.remove(value);
                  } else {
                    _preferredStyles.add(value);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppPalette.softCoral : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppPalette.softCoral : AppPalette.softGray.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: isSelected ? [BoxShadow(
                      color: AppPalette.softCoral.withValues(alpha: 0.25),
                      blurRadius: 10, offset: const Offset(0, 4),
                    )] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s['icon'] as String, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        s['label'] as String,
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppPalette.charcoalGray,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_preferredStyles.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Seleccioná al menos un estilo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppPalette.softGray),
            ),
          ],
        ],
      ),
    );
  }

  // ── Paso 7: Talla y presupuesto ────────────────────────────────────────────

  Widget _buildSizeAndBudget() {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Talla de ropa
          Text('Talla de ropa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppPalette.charcoalGray)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _clothingSizes.map((size) {
              final isSelected = _clothingSize == size;
              return GestureDetector(
                onTap: () => setState(() => _clothingSize = size),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: isSelected ? AppPalette.softCoral : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppPalette.softCoral : AppPalette.softGray.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      size,
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppPalette.charcoalGray,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // Presupuesto
          Text('Presupuesto habitual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppPalette.charcoalGray)),
          const SizedBox(height: 12),
          ..._budgets.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectionCard(
              label: b['label']!,
              subtitle: b['desc'],
              isSelected: _budget == b['value'],
              onTap: () => setState(() => _budget = b['value']),
            ),
          )),
        ],
      ),
    );
  }

  // ── Botones de navegación ──────────────────────────────────────────────────

  Widget _buildNavigationButtons() {
    final isLast = _currentStep == _totalSteps - 1;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            IconButton(
              onPressed: _goBack,
              icon: const Icon(Icons.arrow_back_ios_rounded),
              color: AppPalette.charcoalGray,
            ),
            const SizedBox(width: 8),
          ],
          if (!isLast)
            Expanded(
              child: TextButton(
                onPressed: _skipOnboarding,
                child: Text('Omitir', style: TextStyle(color: AppPalette.softGray, fontWeight: FontWeight.w600)),
              ),
            ),
          if (!isLast) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.softCoral,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text(isLast ? 'Finalizar' : 'Continuar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lógica de navegación ───────────────────────────────────────────────────

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  void _handleNext() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final attributes = UserAttribute(
        gender: _gender,
        age: _age,
        stature: _stature,
        weight: _weight,
        bodyType: _bodyType,
        skinTone: _skinTone,
        faceType: _faceType,
        preferredStyles: List.from(_preferredStyles),
        clothingSize: _clothingSize,
        budget: _budget,
        profession: _profession,
        userId: widget.userId,
      );
      await UserAttributeService.saveUserAttributes(attributes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('¡Perfil guardado!'), backgroundColor: AppPalette.success, behavior: SnackBarBehavior.floating),
        );
        context.go('/main');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red.shade400, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _skipOnboarding() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Omitir configuración', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Para mejores recomendaciones de moda, completá todos los campos. ¿Omitir de todas formas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Completar', style: TextStyle(color: AppPalette.charcoalGray))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Omitir', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirm == true && mounted) await _finishOnboarding();
  }

  // ── Textos por paso ────────────────────────────────────────────────────────

  String _stepTitle(int step) => const [
    '¿Cuál es tu género?',
    '¿Cuántos años tenés?',
    'Medidas físicas',
    'Tipo de cuerpo',
    'Tono de piel',
    'Forma del rostro',
    'Estilos que te gustan',
    'Talla y presupuesto',
  ][step];

  String _stepSubtitle(int step) => const [
    'Personalizamos tu experiencia según tu género',
    'Para recomendaciones adecuadas a tu etapa',
    'Para sugerencias de tallas precisas',
    'Nos ayuda a recomendar siluetas que te favorezcan',
    'Definimos los colores que mejor te quedan',
    'Influye en cortes y accesorios recomendados',
    'Seleccioná todos los que te identifiquen',
    'Filtramos recomendaciones por tu talla y presupuesto',
  ][step];
}

// ─── Widgets reutilizables ────────────────────────────────────────────────────

class _SelectionCard extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCard({required this.label, this.subtitle, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.softCoral : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppPalette.softCoral : AppPalette.softGray.withValues(alpha: 0.3),
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppPalette.softCoral.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppPalette.charcoalGray)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : AppPalette.softGray)),
                  ],
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderCard({required this.label, required this.value, required this.min, required this.max, required this.divisions, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppPalette.softCoral.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppPalette.softCoral)),
          const SizedBox(height: 16),
          Slider(
            value: value, min: min, max: max, divisions: divisions,
            activeColor: AppPalette.softCoral,
            inactiveColor: AppPalette.softGray.withValues(alpha: 0.3),
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${min.round()}', style: TextStyle(color: AppPalette.softGray, fontSize: 12)),
              Text('${max.round()}', style: TextStyle(color: AppPalette.softGray, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
