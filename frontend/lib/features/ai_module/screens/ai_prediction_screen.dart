import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/alimentacion_service.dart';
import '../../../services/auth_service.dart';
import '../services/ai_service.dart';
import '../utils/recommendation_engine.dart';
import '../widgets/ai_model_badge.dart';
import '../widgets/ai_gauge_card.dart';
import '../widgets/ai_recommendation_list.dart';
import '../../../services/actividad_fisica_service.dart';
import '../../estado_sueno/services/estado_sueno_service.dart';

/// Pantalla del Motor de Predicción IA — flujo pre-comida.
///
/// 1. El usuario busca y agrega alimentos de la BD (máx 5).
/// 2. El sistema calcula automáticamente carbos + carga glucémica totales.
/// 3. Al tocar "Predecir" se envía al modelo con los datos de contexto.
class AiPredictionScreen extends StatefulWidget {
  final int userId;
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
  late final AlimentacionService _alimentacionService;

  // ── Búsqueda de alimentos
  final _searchController = TextEditingController();
  List<ComidaApi> _searchResults = [];
  bool _isSearching = false;

  // ── Plato seleccionado (alimentos + porciones)
  final List<_SelectedFood> _selectedFoods = [];
  static const int _maxFoods = 5;

  // ── Predicción
  AIPredictionResult? _result;
  List<String> _recommendations = [];
  bool _isPredicting = false;
  String? _error;
  bool _hasPredicted = false;

  // ── Contexto del usuario
  late double _glucosaAntes;
  late double _horasSueno;
  late int _estres;
  late double _ejercicio;

  late AnimationController _resultController;
  late Animation<double> _resultFade;

  @override
  void initState() {
    super.initState();
    final token = AuthService.token ?? '';
    _alimentacionService = AlimentacionService(token: token);

    _glucosaAntes = _toDouble(widget.contextData['glucosa_antes']) ?? 120.0;
    _horasSueno   = 0.0;
    _estres       = 3;
    _ejercicio    = 0.0;

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultFade = CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOut,
    );

    _loadRealContextData();
  }

  Future<void> _loadRealContextData() async {
    // 1. Cargar Actividad Física
    try {
      final act = await ActividadFisicaService.obtenerResumenHoy();
      if (mounted) {
        setState(() {
          _ejercicio = (act['total_minutos'] ?? 30.0).toDouble(); // Ejercicio por defecto si es nulo
        });
      }
    } catch (e) {
      if (mounted) setState(() => _ejercicio = 30.0);
    }

    // 2. Cargar Sueño
    try {
      final suenos = await EstadoSuenoService.getSuenos(widget.userId);
      if (mounted && suenos.isNotEmpty) {
        setState(() {
          _horasSueno = suenos.first.horasDormidas ?? 7.0;
        });
      }
    } catch (e) {
      // Ignorar fallo de sueño
    }

    // 3. Cargar Estado Emocional (Estrés)
    try {
      final estados = await EstadoSuenoService.getEstados(widget.userId);
      if (mounted && estados.isNotEmpty) {
        setState(() {
          // Normalizar el nivel de estrés a una escala de 1 a 5 si el modelo lo requiere,
          // o si el nivel ya es 1-5, tomarlo directo.
          int estresDB = estados.first.nivelEstres;
          // Si en la DB está guardado de 1 a 10, lo escalamos a 1-5 (opcional). 
          // Supondremos que la DB usa la misma escala requerida por ML.
          if (estresDB > 5) estresDB = (estresDB / 2).ceil(); 
          if (estresDB < 1) estresDB = 1;
          _estres = estresDB;
        });
      }
    } catch (e) {
      // Ignorar fallo de estado emocional
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  // ── Cálculos totales del plato
  double get _totalCarbs {
    double total = 0;
    for (final f in _selectedFoods) {
      final factor = f.cantidad / f.comida.porcionTipica;
      total += (f.comida.carbohidratos ?? 0) * factor;
    }
    return total;
  }

  double get _totalCargaGlucemica {
    double total = 0;
    for (final f in _selectedFoods) {
      final factor = f.cantidad / f.comida.porcionTipica;
      total += (f.comida.cargaGlucemica ?? 0) * factor;
    }
    return total;
  }

  double get _totalCalorias {
    double total = 0;
    for (final f in _selectedFoods) {
      final factor = f.cantidad / f.comida.porcionTipica;
      total += (f.comida.calorias ?? 0) * factor;
    }
    return total;
  }

  bool get _canPredict => _selectedFoods.isNotEmpty;

  // ── Búsqueda
  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await _alimentacionService.buscarAlimentos(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _addFood(ComidaApi comida) {
    if (_selectedFoods.length >= _maxFoods) return;
    // No duplicar
    if (_selectedFoods.any((f) => f.comida.id == comida.id)) return;

    setState(() {
      _selectedFoods.add(_SelectedFood(
        comida: comida,
        cantidad: comida.porcionTipica,
      ));
      _searchController.clear();
      _searchResults = [];
      _hasPredicted = false;
      _result = null;
    });
  }

  void _removeFood(int index) {
    setState(() {
      _selectedFoods.removeAt(index);
      _hasPredicted = false;
      _result = null;
    });
  }

  void _updatePortion(int index, double nuevaCantidad) {
    setState(() {
      _selectedFoods[index] = _SelectedFood(
        comida: _selectedFoods[index].comida,
        cantidad: nuevaCantidad,
      );
      _hasPredicted = false;
      _result = null;
    });
  }

  // ── Predicción
  Future<void> _predict() async {
    if (!_canPredict) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isPredicting = true;
      _error = null;
      _hasPredicted = false;
    });

    final data = {
      'glucosa_antes':   _glucosaAntes,
      'carbohidratos':   _totalCarbs,
      'carga_glucemica': _totalCargaGlucemica,
      'horas_sueno':     _horasSueno,
      'estres':          _estres,
      'ejercicio':       _ejercicio,
    };

    final result = await _aiService.predictRisk(widget.userId, data);

    if (mounted) {
      setState(() {
        _isPredicting = false;
        if (result != null) {
          _result = result;
          _hasPredicted = true;
          _recommendations =
              RecommendationEngine.generateRecommendations(data, result.riskLevel);
        } else {
          _error = 'No se pudo conectar con el motor de IA.';
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
            _buildFlowExplainer(),
            const SizedBox(height: 20),

            // ── Datos de contexto
            _SectionTitle(title: 'TUS DATOS ACTUALES', icon: Icons.person_outline_rounded),
            const SizedBox(height: 10),
            _buildContextGrid(),
            const SizedBox(height: 20),

            // ── Selección de alimentos
            _SectionTitle(title: '¿QUÉ VAS A COMER?', icon: Icons.restaurant_rounded),
            const SizedBox(height: 10),
            _buildFoodSelector(),
            const SizedBox(height: 10),

            // ── Alimentos seleccionados
            if (_selectedFoods.isNotEmpty) ...[
              ..._selectedFoods.asMap().entries.map((e) =>
                _FoodPortionCard(
                  food: e.value,
                  index: e.key,
                  onRemove: () => _removeFood(e.key),
                  onPortionChanged: (val) => _updatePortion(e.key, val),
                ),
              ),
              const SizedBox(height: 10),
              // ── Resumen nutricional del plato
              _buildNutritionSummary(),
            ],

            const SizedBox(height: 20),

            // ── Botón predecir
            _buildPredictButton(),

            // ── Resultado
            if (_isPredicting) ...[
              const SizedBox(height: 20),
              _buildLoadingCard(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 20),
              _buildErrorCard(),
            ],
            if (_hasPredicted && _result != null) ...[
              const SizedBox(height: 24),
              _SectionTitle(title: 'RESULTADO DE PREDICCIÓN', icon: Icons.hub_rounded),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _resultFade,
                child: Column(
                  children: [
                    AiModelBadge(modelUsed: _result!.modelUsed),
                    // ── Avisos clínicos del backend
                    if (_result!.avisos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _ClinicalWarningsCard(avisos: _result!.avisos),
                    ],
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

            const SizedBox(height: 20),
            _buildHowItWorks(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  // Sub-widgets
  // ─────────────────────────────────────

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
                  '¿Qué vas a comer?',
                  style: TextStyle(
                    color: Color(0xFFF5F5F7),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Elige tus alimentos, ajusta las porciones y la IA predecirá tu glucosa ~2h después.',
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
            'Tomados de tu último registro',
            style: TextStyle(color: Color(0xFF4A4A58), fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ContextChip(
                icon: Icons.bloodtype_rounded,
                label: 'Glucosa basal',
                value: '${_glucosaAntes.toStringAsFixed(0)} mg/dL',
                color: const Color(0xFFFF3B30),
              )),
              const SizedBox(width: 8),
              Expanded(child: _ContextChip(
                icon: Icons.bedtime_rounded,
                label: 'Sueño',
                value: '${_horasSueno.toStringAsFixed(1)} h',
                color: const Color(0xFF5E9BFF),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _ContextChip(
                icon: Icons.self_improvement_rounded,
                label: 'Estrés',
                value: '$_estres / 10',
                color: const Color(0xFFBE8FFF),
              )),
              const SizedBox(width: 8),
              Expanded(child: _ContextChip(
                icon: Icons.directions_run_rounded,
                label: 'Ejercicio',
                value: '${_ejercicio.toStringAsFixed(0)} min',
                color: const Color(0xFF34C759),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodSelector() {
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
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            onChanged: _search,
            style: const TextStyle(color: Color(0xFFF5F5F7), fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Buscar alimento... (ej: avena, pollo)',
              hintStyle: const TextStyle(color: Color(0xFF4A4A58), fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF4A4A58), size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF4A4A58), size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    )
                  : null,
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
                borderSide: const BorderSide(color: Color(0xFFFF7A00), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          // Resultados de búsqueda
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF7A00)),
                ),
              ),
            ),

          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 10),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2C2C38)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFF2C2C38)),
                itemBuilder: (_, i) {
                  final comida = _searchResults[i];
                  final alreadyAdded = _selectedFoods.any((f) => f.comida.id == comida.id);
                  return ListTile(
                    dense: true,
                    leading: _FoodIcon(categoria: comida.categoria),
                    title: Text(
                      comida.nombre,
                      style: TextStyle(
                        color: alreadyAdded
                            ? const Color(0xFF4A4A58)
                            : const Color(0xFFF5F5F7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${comida.carbohidratos?.toStringAsFixed(0) ?? '?'}g carbos · '
                      'GL ${comida.cargaGlucemica?.toStringAsFixed(0) ?? '?'} · '
                      '${comida.calorias?.toStringAsFixed(0) ?? '?'} kcal',
                      style: const TextStyle(
                        color: Color(0xFF4A4A58),
                        fontSize: 11,
                      ),
                    ),
                    trailing: alreadyAdded
                        ? const Icon(Icons.check_rounded, color: Color(0xFF34C759), size: 18)
                        : const Icon(Icons.add_circle_outline_rounded,
                            color: Color(0xFFFF7A00), size: 20),
                    onTap: alreadyAdded ? null : () => _addFood(comida),
                  );
                },
              ),
            ),

          if (_searchResults.isEmpty &&
              _searchController.text.isNotEmpty &&
              !_isSearching)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'No se encontraron alimentos con "${_searchController.text}"',
                style: const TextStyle(color: Color(0xFF4A4A58), fontSize: 12),
              ),
            ),

          // Indicador de capacidad
          if (_selectedFoods.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '${_selectedFoods.length}/$_maxFoods alimentos seleccionados',
                style: TextStyle(
                  color: _selectedFoods.length >= _maxFoods
                      ? const Color(0xFFFFCC00)
                      : const Color(0xFF4A4A58),
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1A0A), Color(0xFF1A1A1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A3F1F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate_rounded, color: Color(0xFF34C759), size: 16),
              SizedBox(width: 6),
              Text(
                'CÁLCULO AUTOMÁTICO DE TU PLATO',
                style: TextStyle(
                  color: Color(0xFF34C759),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _SummaryPill(
                label: 'Carbohidratos',
                value: '${_totalCarbs.toStringAsFixed(1)} g',
                color: const Color(0xFFFF7A00),
                icon: Icons.grain_rounded,
              )),
              const SizedBox(width: 8),
              Expanded(child: _SummaryPill(
                label: 'Carga Glucémica',
                value: _totalCargaGlucemica.toStringAsFixed(1),
                color: const Color(0xFFFFCC00),
                icon: Icons.show_chart_rounded,
              )),
              const SizedBox(width: 8),
              Expanded(child: _SummaryPill(
                label: 'Calorías',
                value: '${_totalCalorias.toStringAsFixed(0)} kcal',
                color: const Color(0xFF5E9BFF),
                icon: Icons.local_fire_department_rounded,
              )),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _totalCargaGlucemica < 10
                ? '✅ Carga glucémica baja — buen impacto en glucosa'
                : _totalCargaGlucemica < 20
                    ? '⚠️ Carga glucémica media — impacto moderado'
                    : '🔴 Carga glucémica alta — posible pico de glucosa',
            style: const TextStyle(
              color: Color(0xFF8E8E9A),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictButton() {
    return AnimatedOpacity(
      opacity: _canPredict ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: _canPredict && !_isPredicting ? _predict : null,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: _canPredict
                ? const LinearGradient(
                    colors: [Color(0xFF8B2500), Color(0xFFFF7A00)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: _canPredict ? null : const Color(0xFF1A1A1F),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _canPredict
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
                _isPredicting ? Icons.hourglass_top_rounded : Icons.hub_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                _isPredicting
                    ? 'Calculando...'
                    : _canPredict
                        ? 'Predecir glucosa post-comida'
                        : 'Agrega alimentos para predecir',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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
            width: 36, height: 36,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFFF7A00)),
          ),
          const SizedBox(height: 14),
          Text(
            'El modelo Random Forest está procesando tu comida...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
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
            Expanded(child: Text(_error!,
                style: const TextStyle(color: Color(0xFF8E8E9A), fontSize: 13))),
            const Icon(Icons.refresh_rounded, color: Color(0xFFFF7A00)),
          ],
        ),
      ),
    );
  }

  Widget _buildModelExplanation() {
    final isPersonalized = !_result!.modelUsed.toLowerCase().contains('global');
    return Column(
      children: [
        _ModelTypeCard(
          icon: Icons.hub_rounded,
          title: 'Modelo Global',
          subtitle: 'Entrenado con datos de múltiples usuarios',
          isActive: !isPersonalized,
          gradientColors: const [Color(0xFF1A237E), Color(0xFF283593)],
          accentColor: const Color(0xFF7986CB),
        ),
        const SizedBox(height: 10),
        _ModelTypeCard(
          icon: Icons.person_rounded,
          title: 'Modelo Personalizado',
          subtitle: 'Entrenado exclusivamente con tus datos',
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code_rounded, color: Color(0xFF8E8E9A), size: 16),
              SizedBox(width: 8),
              Text('CÓMO FUNCIONA', style: TextStyle(
                color: Color(0xFF8E8E9A), fontSize: 11,
                fontWeight: FontWeight.w600, letterSpacing: 1.0,
              )),
            ],
          ),
          SizedBox(height: 14),
          _HowStep(number: '1', title: 'Eliges tus alimentos',
            description: 'Seleccionas de la base de datos lo que vas a comer y ajustas las porciones.',
            color: Color(0xFF5E9BFF)),
          SizedBox(height: 10),
          _HowStep(number: '2', title: 'Se calculan carbos y carga glucémica',
            description: 'El sistema suma automáticamente los macros de tu plato completo.',
            color: Color(0xFFFF7A00)),
          SizedBox(height: 10),
          _HowStep(number: '3', title: 'Random Forest predice',
            description: 'Con 6 variables (glucosa + comida + contexto) estima tu glucosa ~2h post-comida.',
            color: Color(0xFF34C759)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────
// Modelos y sub-widgets
// ─────────────────────────────────

class _SelectedFood {
  final ComidaApi comida;
  final double cantidad;
  const _SelectedFood({required this.comida, required this.cantidad});
}

class _FoodPortionCard extends StatelessWidget {
  final _SelectedFood food;
  final int index;
  final VoidCallback onRemove;
  final ValueChanged<double> onPortionChanged;
  const _FoodPortionCard({
    required this.food,
    required this.index,
    required this.onRemove,
    required this.onPortionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final factor = food.cantidad / food.comida.porcionTipica;
    final carbsCalc = (food.comida.carbohidratos ?? 0) * factor;
    final glCalc = (food.comida.cargaGlucemica ?? 0) * factor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C2C38)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _FoodIcon(categoria: food.comida.categoria),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.comida.nombre,
                      style: const TextStyle(
                        color: Color(0xFFF5F5F7), fontSize: 14,
                        fontWeight: FontWeight.w600,
                      )),
                    const SizedBox(height: 2),
                    Text(
                      '${carbsCalc.toStringAsFixed(1)}g carbos · GL ${glCalc.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Color(0xFF8E8E9A), fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF4A4A58), size: 18),
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Slider de porción
          Row(
            children: [
              Text(
                'Porción:',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
              ),
              Expanded(
                child: Slider(
                  value: food.cantidad,
                  min: food.comida.unidadMedida == 'gramos' || food.comida.unidadMedida == 'ml'
                      ? 10
                      : 0.5,
                  max: food.comida.unidadMedida == 'gramos' || food.comida.unidadMedida == 'ml'
                      ? 500
                      : 5,
                  divisions: food.comida.unidadMedida == 'gramos' || food.comida.unidadMedida == 'ml'
                      ? 49
                      : 9,
                  activeColor: const Color(0xFFFF7A00),
                  inactiveColor: const Color(0xFF2C2C38),
                  onChanged: onPortionChanged,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatPortion(food.cantidad, food.comida.unidadMedida),
                  style: const TextStyle(
                    color: Color(0xFFFF7A00), fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPortion(double cantidad, String unidad) {
    if (unidad == 'gramos' || unidad == 'ml') {
      return '${cantidad.toStringAsFixed(0)} $unidad';
    }
    return '${cantidad.toStringAsFixed(1)} $unidad';
  }
}

class _FoodIcon extends StatelessWidget {
  final String categoria;
  const _FoodIcon({required this.categoria});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (categoria.toLowerCase()) {
      case 'cereales':
        icon = Icons.grain_rounded;
        color = const Color(0xFFFFCC00);
        break;
      case 'carnes':
      case 'proteínas':
        icon = Icons.kebab_dining_rounded;
        color = const Color(0xFFFF3B30);
        break;
      case 'frutas':
        icon = Icons.apple;
        color = const Color(0xFF34C759);
        break;
      case 'verduras':
        icon = Icons.eco_rounded;
        color = const Color(0xFF34C759);
        break;
      case 'bebidas':
        icon = Icons.local_cafe_rounded;
        color = const Color(0xFF5E9BFF);
        break;
      case 'sopas':
        icon = Icons.soup_kitchen_rounded;
        color = const Color(0xFFFF7A00);
        break;
      default:
        icon = Icons.restaurant_rounded;
        color = const Color(0xFF8E8E9A);
    }
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryPill(
      {required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF4A4A58), fontSize: 9)),
        ],
      ),
    );
  }
}

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
        Text(title, style: const TextStyle(
          color: Color(0xFF4A4A58), fontSize: 11,
          fontWeight: FontWeight.w600, letterSpacing: 1.1,
        )),
      ],
    );
  }
}

class _ContextChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ContextChip({required this.icon, required this.label, required this.value, required this.color});

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
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
              Text(label, style: const TextStyle(color: Color(0xFF4A4A58), fontSize: 10)),
            ],
          )),
        ],
      ),
    );
  }
}

class _ModelTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final List<Color> gradientColors;
  final Color accentColor;
  const _ModelTypeCard({
    required this.icon, required this.title, required this.subtitle,
    required this.isActive, required this.gradientColors, required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: isActive ? null : const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? accentColor.withOpacity(0.5) : const Color(0xFF2C2C38),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withOpacity(0.15) : accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isActive ? Colors.white : accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(title, style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFFF5F5F7),
                  fontSize: 13, fontWeight: FontWeight.w700,
                )),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('ACTIVO', style: TextStyle(
                        color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
              Text(subtitle, style: TextStyle(
                color: isActive ? Colors.white.withOpacity(0.6) : const Color(0xFF8E8E9A),
                fontSize: 11,
              )),
            ],
          )),
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
      child: const Row(
        children: [
          Icon(Icons.trending_up_rounded, color: Color(0xFFFFCC00), size: 18),
          SizedBox(width: 10),
          Expanded(child: Text(
            'Acumula más registros para desbloquear el modelo personalizado con mayor precisión.',
            style: TextStyle(color: Color(0xFF8E8E9A), fontSize: 11, height: 1.4),
          )),
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
  const _HowStep({required this.number, required this.title, required this.description, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Center(child: Text(number,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(description, style: const TextStyle(color: Color(0xFF8E8E9A), fontSize: 12, height: 1.4)),
          ],
        )),
      ],
    );
  }
}

class _ClinicalWarningsCard extends StatelessWidget {
  final List<String> avisos;
  const _ClinicalWarningsCard({required this.avisos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1300),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF5A3E00), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFFCC00), size: 18),
              SizedBox(width: 8),
              Text(
                'AVISO CLÍNICO',
                style: TextStyle(
                  color: Color(0xFFFFCC00),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...avisos.map((aviso) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.circle, color: Color(0xFFFFCC00), size: 5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    aviso,
                    style: const TextStyle(
                      color: Color(0xFFCCAA44),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const Divider(color: Color(0xFF5A3E00), height: 16),
          const Text(
            'Los valores ingresados exceden el rango de datos con los que el modelo fue entrenado. '
            'La predicción se complementa con reglas clínicas.',
            style: TextStyle(
              color: Color(0xFF8E7A3A),
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
