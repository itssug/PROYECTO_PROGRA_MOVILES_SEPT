import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';
import '../utils/recommendation_engine.dart';
import '../widgets/ai_model_badge.dart';
import '../widgets/ai_gauge_card.dart';
import '../widgets/ai_recommendation_list.dart';

/// Pantalla del Motor de Predicción IA.
///
/// Flujo correcto:
///   1. El usuario ve sus datos actuales (glucosa basal, sueño, estrés, ejercicio)
///      — vienen del perfil / últimos registros.
///   2. El usuario ingresa LO QUE VA A COMER (carbohidratos + carga glucémica).
///   3. Toca "Predecir" → llamada al API → resultado post-comida.
class AiPredictionScreen extends StatefulWidget {
  final int userId;

  /// Datos contextuales que ya se conocen (glucosa basal, sueño, estrés, ejercicio).
  /// Pueden venir del perfil o del último registro del usuario.
  final Map<String, dynamic> contextData;

  const AiPredictionScreen({
    Key? key,
    required this.userId,
    this.contextData = const {},
  }) : super(key: key);

  @override
  State<AiPredictionScreen> createState() => _AiPredictionScreenState();
}

class _AiPredictionScreenState extends State<AiPredictionScreen>
    with TickerProviderStateMixin {
  final AIService _aiService = AIService();

  // ── Controladores del formulario de comida
  final _carbsController = TextEditingController(text: '');
  final _glyCargaController = TextEditingController(text: '');

  // ── Estado de la predicción
  AIPredictionResult? _result;
  List<String> _recommendations = [];
  bool _isLoading = false;
  String? _error;
  bool _hasPredicted = false;

  // ── Datos contextuales (ya conocidos)
  late double _glucosaAntes;
  late double _horasSueno;
  late int _estres;
  late double _ejercicio;

  late AnimationController _resultController;
  late Animation<double> _resultFade;

  @override
  void initState() {
    super.initState();
    // Tomar valores del contexto o usar defaults razonables
    _glucosaAntes = _toDouble(widget.contextData['glucosa_antes']) ?? 120.0;
    _horasSueno   = _toDouble(widget.contextData['horas_sueno'])   ?? 7.0;
    _estres       = _toInt(widget.contextData['estres'])           ?? 3;
    _ejercicio    = _toDouble(widget.contextData['ejercicio'])      ?? 0.0;

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultFade = CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _carbsController.dispose();
    _glyCargaController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  bool get _formValid {
    final carbs = double.tryParse(_carbsController.text);
    final carga = double.tryParse(_glyCargaController.text);
    return carbs != null && carbs > 0 && carga != null && carga >= 0;
  }

  Future<void> _predict() async {
    if (!_formValid) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
      _hasPredicted = false;
    });

    final data = {
      'glucosa_antes':   _glucosaAntes,
      'carbohidratos':   double.parse(_carbsController.text),
      'carga_glucemica': double.parse(_glyCargaController.text),
      'horas_sueno':     _horasSueno,
      'estres':          _estres,
      'ejercicio':       _ejercicio,
    };

    final result = await _aiService.predictRisk(widget.userId, data);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result != null) {
          _result = result;
          _hasPredicted = true;
          _recommendations =
              RecommendationEngine.generateRecommendations(data, result.riskLevel);
        } else {
          _error = 'No se pudo conectar con el motor de IA. Intenta de nuevo.';
        }
      });
      if (_hasPredicted) {
        _resultController.forward(from: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Predicción Pre-Comida',
          style: TextStyle(
            color: Color(0xFFF5F5F7),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Explicación del flujo
            _buildFlowExplainer(),
            const SizedBox(height: 20),

            // ── Datos del contexto (ya conocidos)
            _SectionTitle(title: 'TUS DATOS ACTUALES', icon: Icons.person_outline_rounded),
            const SizedBox(height: 10),
            _buildContextGrid(),
            const SizedBox(height: 20),

            // ── Formulario: ¿qué vas a comer?
            _SectionTitle(title: '¿QUÉ VAS A COMER?', icon: Icons.restaurant_rounded),
            const SizedBox(height: 10),
            _buildMealForm(),
            const SizedBox(height: 20),

            // ── Botón de predicción
            _buildPredictButton(),

            // ── Resultado (solo si ya se predijo)
            if (_isLoading) ...[
              const SizedBox(height: 20),
              _buildLoadingCard(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 20),
              _buildErrorCard(),
            ],
            if (_hasPredicted && _result != null) ...[
              const SizedBox(height: 24),
              _SectionTitle(
                  title: 'RESULTADO DE PREDICCIÓN', icon: Icons.hub_rounded),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _resultFade,
                child: Column(
                  children: [
                    AiModelBadge(modelUsed: _result!.modelUsed),
                    const SizedBox(height: 8),
                    AiGaugeCard(
                      predictedGlucose: _result!.predictedGlucose,
                      riskLevel: _result!.riskLevel,
                    ),
                    if (_recommendations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      AiRecommendationList(recommendations: _recommendations),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildModelExplanation(),
            ],

            // ── Cómo funciona (siempre visible)
            const SizedBox(height: 20),
            _buildHowItWorks(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────
  // Widgets de la pantalla
  // ─────────────────────────────────

  Widget _buildFlowExplainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0D00), Color(0xFF1A1A1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D2200)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A00).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Color(0xFFFF7A00), size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Predicción post-comida',
                  style: TextStyle(
                    color: Color(0xFFF5F5F7),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ingresa lo que vas a comer y el modelo estimará tu glucosa ~2h después.',
                  style: TextStyle(
                    color: Color(0xFF8E8E9A),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estos valores se toman de tu último registro',
            style: TextStyle(color: Color(0xFF4A4A58), fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ContextChip(
                  icon: Icons.bloodtype_rounded,
                  label: 'Glucosa basal',
                  value: '${_glucosaAntes.toStringAsFixed(0)} mg/dL',
                  color: const Color(0xFFFF3B30),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ContextChip(
                  icon: Icons.bedtime_rounded,
                  label: 'Sueño',
                  value: '${_horasSueno.toStringAsFixed(1)} h',
                  color: const Color(0xFF5E9BFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ContextChip(
                  icon: Icons.self_improvement_rounded,
                  label: 'Estrés',
                  value: '$_estres / 10',
                  color: const Color(0xFFBE8FFF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ContextChip(
                  icon: Icons.directions_run_rounded,
                  label: 'Ejercicio',
                  value: '${_ejercicio.toStringAsFixed(0)} min',
                  color: const Color(0xFF34C759),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carbohidratos
          const _FormLabel(
            label: 'Carbohidratos',
            sublabel: 'gramos totales de la comida',
            icon: Icons.grain_rounded,
            color: Color(0xFFFF7A00),
          ),
          const SizedBox(height: 8),
          _NumberField(
            controller: _carbsController,
            hint: 'Ej: 45',
            suffix: 'g',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Carga glucémica
          const _FormLabel(
            label: 'Carga glucémica',
            sublabel: 'impacto glucémico total (carbos × índice / 100)',
            icon: Icons.show_chart_rounded,
            color: Color(0xFFFFCC00),
          ),
          const SizedBox(height: 8),
          _NumberField(
            controller: _glyCargaController,
            hint: 'Ej: 30',
            suffix: 'GL',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Guía rápida de carga glucémica
          _buildGlycemicGuide(),
        ],
      ),
    );
  }

  Widget _buildGlycemicGuide() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Referencia rápida de carga glucémica',
            style: TextStyle(
              color: Color(0xFF4A4A58),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _GlRef(
                      color: const Color(0xFF34C759),
                      label: '< 10',
                      desc: 'Baja\nEnsalada, verduras')),
              const SizedBox(width: 6),
              Expanded(
                  child: _GlRef(
                      color: const Color(0xFFFFCC00),
                      label: '10–20',
                      desc: 'Media\nArroz, pan')),
              const SizedBox(width: 6),
              Expanded(
                  child: _GlRef(
                      color: const Color(0xFFFF3B30),
                      label: '> 20',
                      desc: 'Alta\nPasta, dulces')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictButton() {
    return AnimatedOpacity(
      opacity: _formValid ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: _formValid && !_isLoading ? _predict : null,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: _formValid
                ? const LinearGradient(
                    colors: [Color(0xFF8B2500), Color(0xFFFF7A00)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: _formValid ? null : const Color(0xFF1A1A1F),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _formValid
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF7A00).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isLoading ? Icons.hourglass_top_rounded : Icons.hub_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                _isLoading ? 'Calculando...' : 'Predecir glucosa post-comida',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C38)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFFFF7A00),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'El modelo Random Forest está procesando tu comida...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return GestureDetector(
      onTap: _predict,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2C2C38)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Color(0xFF4A4A58)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_error!,
                  style:
                      const TextStyle(color: Color(0xFF8E8E9A), fontSize: 13)),
            ),
            const Icon(Icons.refresh_rounded, color: Color(0xFFFF7A00)),
          ],
        ),
      ),
    );
  }

  Widget _buildModelExplanation() {
    final isPersonalized =
        !_result!.modelUsed.toLowerCase().contains('global');

    return Column(
      children: [
        _ModelTypeCard(
          icon: Icons.hub_rounded,
          title: 'Modelo Global',
          subtitle: 'Entrenado con datos de múltiples usuarios',
          description:
              'Se usa cuando aún no tienes suficientes registros propios.',
          isActive: !isPersonalized,
          gradientColors: const [Color(0xFF1A237E), Color(0xFF283593)],
          accentColor: const Color(0xFF7986CB),
        ),
        const SizedBox(height: 10),
        _ModelTypeCard(
          icon: Icons.person_rounded,
          title: 'Modelo Personalizado',
          subtitle: 'Entrenado exclusivamente con tus datos',
          description:
              'Mayor precisión. Aprende tus patrones únicos de glucosa.',
          isActive: isPersonalized,
          gradientColors: const [Color(0xFF8B2500), Color(0xFFE55A00)],
          accentColor: const Color(0xFFFF8A50),
        ),
        if (!isPersonalized) ...[
          const SizedBox(height: 10),
          _UpgradeHint(),
        ],
      ],
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.code_rounded, color: Color(0xFF8E8E9A), size: 16),
              SizedBox(width: 8),
              Text(
                'CÓMO FUNCIONA',
                style: TextStyle(
                  color: Color(0xFF8E8E9A),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _HowStep(
            number: '1',
            title: 'Describes tu comida',
            description:
                'Ingresas los carbohidratos y la carga glucémica de lo que vas a comer.',
            color: Color(0xFF5E9BFF),
          ),
          const SizedBox(height: 10),
          const _HowStep(
            number: '2',
            title: 'Se combina con tu contexto',
            description:
                'El modelo suma tu glucosa basal, horas de sueño, estrés y ejercicio.',
            color: Color(0xFFFF7A00),
          ),
          const SizedBox(height: 10),
          const _HowStep(
            number: '3',
            title: 'Random Forest predice',
            description:
                'Estima tu glucosa ~2h post-comida. < 140 Bajo · 140–180 Medio · > 180 Alto.',
            color: Color(0xFF34C759),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4A4A58), size: 14),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF4A4A58),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _ContextChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ContextChip(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF4A4A58), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  const _FormLabel(
      {required this.label,
      required this.sublabel,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 14, fontWeight: FontWeight.w600)),
            Text(sublabel,
                style: const TextStyle(
                    color: Color(0xFF4A4A58), fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;
  final ValueChanged<String> onChanged;
  const _NumberField(
      {required this.controller,
      required this.hint,
      required this.suffix,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
      ],
      style: const TextStyle(
        color: Color(0xFFF5F5F7),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF2C2C38), fontSize: 18),
        suffixText: suffix,
        suffixStyle: const TextStyle(
            color: Color(0xFF4A4A58), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF0D0D0F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C2C38)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C2C38)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFFF7A00), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _GlRef extends StatelessWidget {
  final Color color;
  final String label;
  final String desc;
  const _GlRef(
      {required this.color, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF4A4A58), fontSize: 9, height: 1.3)),
        ],
      ),
    );
  }
}

class _ModelTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final bool isActive;
  final List<Color> gradientColors;
  final Color accentColor;
  const _ModelTypeCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.description,
      required this.isActive,
      required this.gradientColors,
      required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? accentColor.withOpacity(0.5)
              : const Color(0xFF2C2C38),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.15)
                  : accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: isActive ? Colors.white : accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title,
                        style: TextStyle(
                          color:
                              isActive ? Colors.white : const Color(0xFFF5F5F7),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        )),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('ACTIVO',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
                Text(subtitle,
                    style: TextStyle(
                        color: isActive
                            ? Colors.white.withOpacity(0.6)
                            : const Color(0xFF8E8E9A),
                        fontSize: 11)),
                const SizedBox(height: 4),
                Text(description,
                    style: TextStyle(
                        color: isActive
                            ? Colors.white.withOpacity(0.75)
                            : const Color(0xFF8E8E9A),
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1A00),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A3E00)),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded,
              color: Color(0xFFFFCC00), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Acumula más registros para desbloquear el modelo personalizado con mayor precisión.',
              style: TextStyle(
                  color: Color(0xFF8E8E9A), fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final Color color;
  const _HowStep(
      {required this.number,
      required this.title,
      required this.description,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Center(
            child: Text(number,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(description,
                  style: const TextStyle(
                      color: Color(0xFF8E8E9A), fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
