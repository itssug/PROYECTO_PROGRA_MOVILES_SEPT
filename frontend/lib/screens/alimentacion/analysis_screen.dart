
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/alimentacion_service.dart';

// ─── Colores ──────────────────────────────────────────────────────────────────
const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF1A1A1A);
const _orange = Color(0xFFFF5500);
const _purple = Color(0xFFD8B4FE);
const _green = Color(0xFF86EFAC);
const _yellow = Color(0xFFFDE68A);
const _redOrange = Color(0xFFFCA5A5);
const _textSub = Color(0xFF9CA3AF);

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int _selectedPeriod = 0; // 0=Diario, 1=Semanal
  final List<String> _periods = ['Diario', 'Semanal'];

  bool _isLoading = true;
  String? _error;
  double _metaCalorias = 1800;

  // ── Datos crudos del historial (se guardan para recalcular) ──
  List<Map<String, dynamic>> _historico = [];

  // ── Valores calculados para mostrar (cambian según el período) ──
  double _totalCalories = 0;
  double _totalCarbs = 0;
  double _totalProteins = 0;
  double _totalFats = 0;

  List<double> _actualCaloriesChart = [];
  List<double> _goalCaloriesChart = [];
  List<String> _chartLabels = [];

  List<RegistroComidaApi> _registrosHoy = [];

  // ── Estadísticas semanales ──
  int _diasConDatos = 0;
  double _totalCaloriasSemana = 0;

  // Porcentajes de Macronutrientes
  double get _totalMacroG => _totalCarbs + _totalProteins + _totalFats;
  double get _proteinPct => _totalMacroG > 0 ? (_totalProteins / _totalMacroG * 100) : 0;
  double get _carbsPct => _totalMacroG > 0 ? (_totalCarbs / _totalMacroG * 100) : 0;
  double get _fatsPct => _totalMacroG > 0 ? (_totalFats / _totalMacroG * 100) : 0;

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // 1. Cargar historial de 7 días
      final data = await AlimentacionService.getResumenHistorico(dias: 7);
      final List historico = data['historial'] ?? [];
      _metaCalorias = (data['meta_calorias_diarias'] as num?)?.toDouble() ?? 1800.0;

      // 2. Cargar los registros reales de hoy
      final hoyStr = DateTime.now().toString().split(' ')[0];
      final registros = await AlimentacionService.getRegistrosDia(fecha: hoyStr);

      // 3. Guardar datos crudos
      _historico = historico.map((e) => Map<String, dynamic>.from(e)).toList();
      _registrosHoy = registros;

      // 4. Preparar datos del gráfico (siempre muestran los 7 días)
      if (_historico.isNotEmpty) {
        _actualCaloriesChart = _historico.map((e) => (e['calorias'] as num).toDouble()).toList();
        _goalCaloriesChart = List.generate(_historico.length, (_) => _metaCalorias);
        _chartLabels = _historico.map((e) {
          final date = DateTime.parse(e['fecha']);
          const dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
          return dias[date.weekday - 1];
        }).toList();
      }

      // 5. Calcular estadísticas semanales (totales)
      _totalCaloriasSemana = 0;
      _diasConDatos = 0;
      for (final dia in _historico) {
        final cal = (dia['calorias'] as num).toDouble();
        _totalCaloriasSemana += cal;
        if (cal > 0) _diasConDatos++;
      }

      // 6. Calcular valores para la vista actual
      _recalcularVista();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los datos.\nVerifica que el servidor esté activo.';
        _isLoading = false;
      });
    }
  }

  /// Recalcula los valores mostrados según el período seleccionado
  void _recalcularVista() {
    if (_historico.isEmpty) return;

    if (_selectedPeriod == 0) {
      // ── DIARIO: usar datos del último día (hoy) ──
      final dataHoy = _historico.last;
      _totalCalories = (dataHoy['calorias'] as num).toDouble();
      _totalCarbs = (dataHoy['carbos'] as num).toDouble();
      _totalProteins = (dataHoy['proteinas'] as num).toDouble();
      _totalFats = (dataHoy['grasas'] as num).toDouble();
    } else {
      // ── SEMANAL: promedios diarios de la semana ──
      double sumCal = 0, sumCarbs = 0, sumProt = 0, sumFats = 0;
      for (final dia in _historico) {
        sumCal += (dia['calorias'] as num).toDouble();
        sumCarbs += (dia['carbos'] as num).toDouble();
        sumProt += (dia['proteinas'] as num).toDouble();
        sumFats += (dia['grasas'] as num).toDouble();
      }
      final divisor = _diasConDatos > 0 ? _diasConDatos : 1;
      _totalCalories = sumCal / divisor;
      _totalCarbs = sumCarbs / divisor;
      _totalProteins = sumProt / divisor;
      _totalFats = sumFats / divisor;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _orange)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 56),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center,
                    style: const TextStyle(color: _textSub, fontSize: 14)),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _loadRealData,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                        color: _orange, borderRadius: BorderRadius.circular(30)),
                    child: const Text('Reintentar',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildBannerCard(),
                    const SizedBox(height: 20),
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),
                    _buildCalorieTrendsCard(),
                    const SizedBox(height: 16),
                    _buildMacroDistributionCard(),
                    const SizedBox(height: 16),
                    // Mostrar sección diferente según el período
                    if (_selectedPeriod == 0)
                      _buildTodayLogSection()
                    else
                      _buildWeeklySummarySection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cabecera ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Análisis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Banner ──────────────────────────────────────────────────────────────────
  Widget _buildBannerCard() {
    final esSemanal = _selectedPeriod == 1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: esSemanal ? const Color(0xFF60A5FA) : const Color(0xFF4ADE80),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            esSemanal ? 'Tu Resumen Semanal' : 'Tu Análisis Nutricional',
            style: TextStyle(
              color: esSemanal ? const Color(0xFF1E3A5F) : const Color(0xFF14532D),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            esSemanal
                ? 'Promedios diarios de los últimos $_diasConDatos días con registros.'
                : 'Sigue tendencias. Detecta patrones. Alcanza tus metas.',
            style: TextStyle(
              color: esSemanal ? const Color(0xFF1E40AF) : const Color(0xFF166534),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Selector de Período ─────────────────────────────────────────────────────
  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(40)),
      child: Row(
        children: List.generate(_periods.length, (i) {
          final active = i == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedPeriod != i) {
                  _selectedPeriod = i;
                  _recalcularVista(); // ← AHORA SÍ recalcula los datos
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? _orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(36),
                ),
                child: Center(
                  child: Text(
                    _periods[i],
                    style: TextStyle(
                      color: active ? Colors.white : _textSub,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Gráfico de Tendencias de Calorías ───────────────────────────────────────
  Widget _buildCalorieTrendsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _purple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedPeriod == 0 ? 'Tendencias de Calorías' : 'Calorías de la Semana',
            style: const TextStyle(
              color: Color(0xFF3B0764),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: _CalorieLineChart(
              goalData: _goalCaloriesChart.isEmpty ? [_metaCalorias] : _goalCaloriesChart,
              actualData: _actualCaloriesChart.isEmpty ? [0] : _actualCaloriesChart,
              labels: _chartLabels.isEmpty ? ['Hoy'] : _chartLabels,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _chartLegend(_orange, 'Consumo Real'),
              const SizedBox(width: 16),
              _chartLegend(
                const Color(0xFF1A1A1A),
                'Meta (${_metaCalorias.toStringAsFixed(0)})',  // ← FIX: sin decimales
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF4B0082)),
        ),
      ],
    );
  }

  // ── Distribución de Macronutrientes ─────────────────────────────────────────
  Widget _buildMacroDistributionCard() {
    final esSemanal = _selectedPeriod == 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _yellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            esSemanal ? 'Macros — Promedio Diario' : 'Distribución de Macros',
            style: const TextStyle(
              color: Color(0xFF713F12),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _proteinPct < 25
                ? "Estás consistentemente bajo en proteínas."
                : _carbsPct > 55
                    ? "El consumo de carbohidratos supera tu meta diaria."
                    : esSemanal
                        ? "Promedio semanal de tus macronutrientes."
                        : "¡Tus macros lucen equilibrados hoy!",
            style: const TextStyle(color: Color(0xFF92400E), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _macroCard(
                  'Grasas',
                  '${_totalFats.toStringAsFixed(1)}g',
                  _fatsPct / 100,
                  _redOrange,
                  const Color(0xFF7F1D1D),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _macroCard(
                  'Carbos',
                  '${_totalCarbs.toStringAsFixed(1)}g',
                  _carbsPct / 100,
                  _green,
                  const Color(0xFF14532D),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _macroCard(
                  'Proteína',
                  '${_totalProteins.toStringAsFixed(1)}g',
                  _proteinPct / 100,
                  _purple,
                  const Color(0xFF3B0764),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Resumen de calorías
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      esSemanal ? 'Promedio Diario' : 'Total de Hoy',
                      style: const TextStyle(color: Color(0xFF92400E), fontSize: 12),
                    ),
                    Text(
                      '${_totalCalories.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        color: Color(0xFF713F12),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      esSemanal ? 'Total Semana' : 'Meta',
                      style: const TextStyle(color: Color(0xFF92400E), fontSize: 12),
                    ),
                    Text(
                      esSemanal
                          ? '${_totalCaloriasSemana.toStringAsFixed(0)} kcal'
                          : '${_metaCalorias.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        color: Color(0xFF713F12),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroCard(String label, String value, double progress, Color bgColor, Color textColor) {
    if (progress.isNaN || progress.isInfinite) progress = 0.0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: textColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(textColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: textColor, fontSize: 10)),
              Text('100%', style: TextStyle(color: textColor, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Registro de Comidas de Hoy (DIARIO) ─────────────────────────────────────
  Widget _buildTodayLogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Registro de Hoy",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('${_registrosHoy.length} elementos',
                style: const TextStyle(color: _textSub, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        if (_registrosHoy.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text("No has registrado alimentos hoy.",
                  style: TextStyle(color: _textSub)),
            ),
          )
        else
          ..._registrosHoy.map((e) => _buildRealFoodItem(e)),
      ],
    );
  }

  Widget _buildRealFoodItem(RegistroComidaApi entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.restaurant_menu_rounded, color: _orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.comidaNombre,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${entry.tipoComida} · ${entry.hora.length > 5 ? entry.hora.substring(0, 5) : entry.hora}',
                  style: const TextStyle(color: _textSub, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(entry.caloriasCalculadas ?? 0).toStringAsFixed(0)} kcal',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                'C: ${(entry.carbohidratosCalculados ?? 0).toStringAsFixed(1)}g',
                style: const TextStyle(color: _textSub, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Resumen Semanal (SEMANAL) — NUEVO ───────────────────────────────────────
  Widget _buildWeeklySummarySection() {
    // Encontrar mejor y peor día
    String mejorDia = '-';
    String peorDia = '-';
    double mejorCal = double.infinity;
    double peorCal = 0;

    for (final dia in _historico) {
      final cal = (dia['calorias'] as num).toDouble();
      if (cal > 0 && cal < mejorCal) {
        mejorCal = cal;
        mejorDia = _formatearFechaDia(dia['fecha']);
      }
      if (cal > peorCal) {
        peorCal = cal;
        peorDia = _formatearFechaDia(dia['fecha']);
      }
    }

    // Calcular adherencia a la meta
    int diasEnMeta = 0;
    for (final dia in _historico) {
      final cal = (dia['calorias'] as num).toDouble();
      if (cal > 0 && cal <= _metaCalorias * 1.1) {
        diasEnMeta++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Resumen de la Semana",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Estadísticas rápidas
        Row(
          children: [
            _buildWeeklyStatCard(
              Icons.local_fire_department_rounded,
              'Total Semana',
              '${_totalCaloriasSemana.toStringAsFixed(0)} kcal',
              _orange,
            ),
            const SizedBox(width: 10),
            _buildWeeklyStatCard(
              Icons.calendar_today_rounded,
              'Días Registrados',
              '$_diasConDatos de ${_historico.length}',
              const Color(0xFF60A5FA),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildWeeklyStatCard(
              Icons.check_circle_rounded,
              'Días en Meta',
              '$diasEnMeta de $_diasConDatos',
              _green,
            ),
            const SizedBox(width: 10),
            _buildWeeklyStatCard(
              Icons.trending_down_rounded,
              'Día Más Ligero',
              mejorDia,
              const Color(0xFF5EEAD4),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Desglose por día
        const Text(
          "Desglose Diario",
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        ..._historico.map((dia) => _buildDayRow(dia)),
      ],
    );
  }

  Widget _buildWeeklyStatCard(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: _textSub, fontSize: 11)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayRow(Map<String, dynamic> dia) {
    final cal = (dia['calorias'] as num).toDouble();
    final carbos = (dia['carbos'] as num).toDouble();
    final prot = (dia['proteinas'] as num).toDouble();
    final fat = (dia['grasas'] as num).toDouble();
    final enMeta = cal > 0 && cal <= _metaCalorias * 1.1;
    final sinDatos = cal == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: sinDatos
            ? null
            : Border.all(
                color: enMeta
                    ? _green.withOpacity(0.3)
                    : _orange.withOpacity(0.3),
              ),
      ),
      child: Row(
        children: [
          // Día de la semana
          SizedBox(
            width: 70,
            child: Text(
              _formatearFechaDia(dia['fecha']),
              style: TextStyle(
                color: sinDatos ? _textSub.withOpacity(0.5) : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          // Indicador
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: sinDatos
                  ? _textSub.withOpacity(0.3)
                  : enMeta
                      ? _green
                      : _orange,
            ),
          ),
          // Calorías
          Expanded(
            child: Text(
              sinDatos ? 'Sin registros' : '${cal.toStringAsFixed(0)} kcal',
              style: TextStyle(
                color: sinDatos ? _textSub.withOpacity(0.5) : Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          // Macros resumidos
          if (!sinDatos)
            Text(
              'P:${prot.toStringAsFixed(0)} C:${carbos.toStringAsFixed(0)} G:${fat.toStringAsFixed(0)}',
              style: const TextStyle(color: _textSub, fontSize: 10),
            ),
        ],
      ),
    );
  }

  String _formatearFechaDia(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return '${dias[date.weekday - 1]} ${date.day}';
    } catch (_) {
      return fecha;
    }
  }
}

// ─── Gráfico de Líneas Personalizado ──────────────────────────────────────────
class _CalorieLineChart extends StatelessWidget {
  final List<double> goalData;
  final List<double> actualData;
  final List<String> labels;

  const _CalorieLineChart({
    required this.goalData,
    required this.actualData,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    double highestValue = 2000.0;
    if (actualData.isNotEmpty) highestValue = math.max(highestValue, actualData.reduce(math.max));
    if (goalData.isNotEmpty) highestValue = math.max(highestValue, goalData.reduce(math.max));

    final maxY = ((highestValue / 500).ceil() * 500).toDouble();

    return CustomPaint(
      size: Size.infinite,
      painter: _LineChartPainter(
        goalData: goalData,
        actualData: actualData,
        labels: labels,
        maxY: maxY,
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> goalData;
  final List<double> actualData;
  final List<String> labels;
  final double maxY;

  _LineChartPainter({
    required this.goalData,
    required this.actualData,
    required this.labels,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 38.0;
    const bottomPad = 28.0;
    const topPad = 8.0;
    const rightPad = 8.0;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - bottomPad - topPad;
    const double minY = 0;

    final gridPaint = Paint()
      ..color = const Color(0xFF4B0082).withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = topPad + chartH * (1 - i / 4);
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + chartW, y), gridPaint);

      final valorEtiqueta = (maxY / 4) * i;
      final tp = TextPainter(
        text: TextSpan(
          text: '${valorEtiqueta.toInt()}',
          style: const TextStyle(color: Color(0xFF4B0082), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    if (labels.isNotEmpty) {
      for (int i = 0; i < labels.length; i++) {
        final x = leftPad + chartW * i / math.max(1, labels.length - 1);
        final tp = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: const TextStyle(color: Color(0xFF4B0082), fontSize: 9),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, size.height - bottomPad + 6));
      }
    }

    double mapY(double v) => topPad + chartH * (1 - (v - minY) / (maxY - minY));
    double mapX(int i) => leftPad + chartW * i / math.max(1, goalData.length - 1);

    void drawSmoothLine(List<double> data, Color color) {
      if (data.isEmpty) return;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      for (int i = 0; i < data.length; i++) {
        final x = mapX(i);
        final y = mapY(data[i]);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          final prevX = mapX(i - 1);
          final prevY = mapY(data[i - 1]);
          final cpX = (prevX + x) / 2;
          path.cubicTo(cpX, prevY, cpX, y, x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    drawSmoothLine(goalData, const Color(0xFF1A1A1A));
    drawSmoothLine(actualData, _orange);

    final dotPaint = Paint()..color = _orange;
    for (int i = 0; i < actualData.length; i++) {
      canvas.drawCircle(Offset(mapX(i), mapY(actualData[i])), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}