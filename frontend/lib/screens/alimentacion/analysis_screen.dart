import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:frontend/models/diet_model.dart';

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
  int _selectedPeriod = 0; // 0=Diario, 1=Semanal, 2=Mensual
  final List<String> _periods = ['Diario', 'Semanal', 'Mensual'];

  // Totales calculados a partir de registros simulados (mock entries)
  double get _totalCalories =>
      mockTodayEntries.fold(0, (s, e) => s + e.calories);
  double get _totalCarbs => mockTodayEntries.fold(0, (s, e) => s + e.carbs);
  double get _totalProteins =>
      mockTodayEntries.fold(0, (s, e) => s + e.proteins);
  double get _totalFats => mockTodayEntries.fold(0, (s, e) => s + e.fats);

  // Porcentajes de Macronutrientes
  double get _totalMacroG => _totalCarbs + _totalProteins + _totalFats;
  double get _proteinPct =>
      _totalMacroG > 0 ? (_totalProteins / _totalMacroG * 100) : 0;
  double get _carbsPct =>
      _totalMacroG > 0 ? (_totalCarbs / _totalMacroG * 100) : 0;
  double get _fatsPct =>
      _totalMacroG > 0 ? (_totalFats / _totalMacroG * 100) : 0;

  @override
  Widget build(BuildContext context) {
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
                    _buildTodayLogSection(),
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

  // ── Cabecera (Header) ───────────────────────────────────────────────────────
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
            child: const Icon(Icons.notifications_none_rounded,
                color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Tarjeta de Anuncio (Banner) ─────────────────────────────────────────────
  Widget _buildBannerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4ADE80),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu Análisis Nutricional',
            style: TextStyle(
              color: Color(0xFF14532D),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Sigue tendencias. Detecta patrones. Alcanza tus metas.',
            style: TextStyle(
              color: Color(0xFF166534),
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
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: List.generate(_periods.length, (i) {
          final active = i == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = i),
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
                      fontWeight:
                          active ? FontWeight.bold : FontWeight.normal,
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
          const Text(
            'Tendencias de Calorías',
            style: TextStyle(
              color: Color(0xFF3B0764),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: _CalorieLineChart(
              goalData: goalCalories,
              actualData: actualCalories,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _chartLegend(_orange, '5 días bajo la meta'),
              const SizedBox(width: 16),
              _chartLegend(Colors.black87, '2 días excedidos por más de 200 kcal'),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _yellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribución de Macros',
            style: TextStyle(
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
                    const Text(
                      'Total de Hoy',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12,
                      ),
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Meta',
                      style: TextStyle(color: Color(0xFF92400E), fontSize: 12),
                    ),
                    Text(
                      '1,800 kcal',
                      style: TextStyle(
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

  Widget _macroCard(
    String label,
    String value,
    double progress,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: textColor, fontSize: 10),
              ),
              Text(
                '100%',
                style: TextStyle(color: textColor, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Registro de Comidas de Hoy ──────────────────────────────────────────────
  Widget _buildTodayLogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Registro de Hoy",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('${mockTodayEntries.length} elementos',
                style: const TextStyle(color: _textSub, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        ...mockTodayEntries.map((e) => _buildFoodLogItem(e)),
      ],
    );
  }

  Widget _buildFoodLogItem(FoodEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant_menu_rounded,
                color: _orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.foodName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${entry.mealType} · ${entry.time}',
                  style:
                      const TextStyle(color: _textSub, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.calories.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                'C: ${entry.carbs.toStringAsFixed(1)}g',
                style: const TextStyle(color: _textSub, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Gráfico de Líneas Personalizado ──────────────────────────────────────────
class _CalorieLineChart extends StatelessWidget {
  final List<double> goalData;
  final List<double> actualData;

  const _CalorieLineChart({
    required this.goalData,
    required this.actualData,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _LineChartPainter(
        goalData: goalData,
        actualData: actualData,
        labels: const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'],
        yLabels: const ['100', '200', '300', '400'],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> goalData;
  final List<double> actualData;
  final List<String> labels;
  final List<String> yLabels;

  _LineChartPainter({
    required this.goalData,
    required this.actualData,
    required this.labels,
    required this.yLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 38.0;
    const bottomPad = 28.0;
    const topPad = 8.0;
    const rightPad = 8.0;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - bottomPad - topPad;
    final double minY = 0;
    final double maxY = 450;

    // Líneas del eje Y
    final gridPaint = Paint()
      ..color = const Color(0xFF4B0082).withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = topPad + chartH * (1 - i / 4);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + chartW, y),
        gridPaint,
      );
      // Etiquetas del eje Y
      final tp = TextPainter(
        text: TextSpan(
          text: '${(i * 100).toInt()}',
          style: const TextStyle(color: Color(0xFF4B0082), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Etiquetas del eje X
    for (int i = 0; i < labels.length; i++) {
      final x = leftPad + chartW * i / (labels.length - 1);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: Color(0xFF4B0082), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas, Offset(x - tp.width / 2, size.height - bottomPad + 6));
    }

    double mapY(double v) =>
        topPad + chartH * (1 - (v - minY) / (maxY - minY));
    double mapX(int i) => leftPad + chartW * i / (goalData.length - 1);

    void drawSmoothLine(List<double> data, Color color) {
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

    // Puntos sobre los datos reales
    final dotPaint = Paint()..color = _orange;
    for (int i = 0; i < actualData.length; i++) {
      canvas.drawCircle(Offset(mapX(i), mapY(actualData[i])), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}