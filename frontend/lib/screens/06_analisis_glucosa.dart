import 'package:flutter/material.dart';
import '../core/theme.dart';

class AnalisisGlucosaScreen extends StatefulWidget {
  const AnalisisGlucosaScreen({super.key});

  @override
  State<AnalisisGlucosaScreen> createState() => _AnalisisGlucosaScreenState();
}

class _AnalisisGlucosaScreenState extends State<AnalisisGlucosaScreen> {
  String _periodo = '7 días';
  final List<String> _periodos = ['7 días', '14 días', '30 días'];
  String? _medSeleccionado;

  final List<_MedAnalisis> _medicamentos = [
    _MedAnalisis(
      nombre: 'Metformina',
      dosis: '850 mg',
      reduccionPromedio: -18.4,
      adherencia: 0.86,
      color: AppTheme.success,
      puntos: [145, 132, 128, 119, 122, 115, 118],
    ),
    _MedAnalisis(
      nombre: 'Glibenclamida',
      dosis: '5 mg',
      reduccionPromedio: -24.1,
      adherencia: 0.71,
      color: AppTheme.accent,
      puntos: [160, 145, 138, 130, 142, 128, 125],
    ),
    _MedAnalisis(
      nombre: 'Insulina Glargina',
      dosis: '20 UI',
      reduccionPromedio: -31.7,
      adherencia: 0.95,
      color: const Color(0xFF5E9BFF),
      puntos: [170, 155, 148, 140, 135, 130, 128],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Glucosa'),
        actions: [
          // Selector de período
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _periodo,
                isDense: true,
                dropdownColor: AppTheme.surfaceLight,
                icon: const Icon(Icons.expand_more_rounded,
                    color: AppTheme.textMuted, size: 16),
                style: const TextStyle(
                    color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600),
                items: _periodos
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _periodo = v!),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // ── Insight principal
          _InsightBanner(),
          const SizedBox(height: 20),

          // ── Gráfica de glucosa simulada
          const SectionLabel('Glucosa en los últimos 7 días'),
          _GlucosaChart(medicamentos: _medicamentos),
          const SizedBox(height: 20),

          // ── Por medicamento
          const SectionLabel('Efecto por medicamento'),
          ..._medicamentos.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MedImpactCard(
              med: m,
              isSelected: _medSeleccionado == m.nombre,
              onTap: () => setState(() =>
                  _medSeleccionado = _medSeleccionado == m.nombre ? null : m.nombre),
            ),
          )),
          const SizedBox(height: 8),

          // ── Correlaciones
          const SectionLabel('Correlaciones detectadas'),
          _CorrelacionCard(
            icon: Icons.medication_rounded,
            color: AppTheme.success,
            titulo: 'Metformina + Ejercicio',
            descripcion:
                'La glucosa post-ejercicio baja 34% más cuando Metformina fue tomada en las últimas 4h.',
          ),
          const SizedBox(height: 10),
          _CorrelacionCard(
            icon: Icons.bedtime_rounded,
            color: const Color(0xFF5E9BFF),
            titulo: 'Insulina + Sueño',
            descripcion:
                'Noches con >7h de sueño presentan niveles matutinos 12% más bajos tras la dosis nocturna.',
          ),
          const SizedBox(height: 10),
          _CorrelacionCard(
            icon: Icons.warning_rounded,
            color: AppTheme.warning,
            titulo: 'Omisión de Glibenclamida',
            descripcion:
                'Los días en que no se tomó Glibenclamida, la glucosa post-almuerzo supera los 160 mg/dL en promedio.',
          ),
        ],
      ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2A1A), AppTheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.trending_down_rounded,
                color: AppTheme.success, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Control mejorando',
                    style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(
                  'Tu glucosa promedio bajó 11.2 mg/dL esta semana respecto a la anterior. Sigue así.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlucosaChart extends StatelessWidget {
  final List<_MedAnalisis> medicamentos;
  const _GlucosaChart({required this.medicamentos});

  @override
  Widget build(BuildContext context) {
    final dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final glucosa = [165, 148, 142, 135, 138, 128, 125];

    final maxVal = 200.0;
    final minVal = 70.0;

    return AppCard(
      child: Column(
        children: [
          // Leyenda de zona objetivo
          Row(
            children: [
              Container(width: 14, height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  )),
              const SizedBox(width: 6),
              const Text('Rango objetivo (70-130)',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              const Spacer(),
              Container(width: 14, height: 3, color: AppTheme.accent),
              const SizedBox(width: 6),
              const Text('Glucosa',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _ChartPainter(
                valores: glucosa.map((v) => v.toDouble()).toList(),
                max: maxVal,
                min: minVal,
                lineColor: AppTheme.accent,
                rangoMin: 70,
                rangoMax: 130,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          // Etiquetas de días
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dias.map((d) => Text(d,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11))).toList(),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> valores;
  final double max, min;
  final Color lineColor;
  final double rangoMin, rangoMax;

  const _ChartPainter({
    required this.valores,
    required this.max,
    required this.min,
    required this.lineColor,
    required this.rangoMin,
    required this.rangoMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;

    double toY(double v) => h - ((v - min) / (max - min)) * h;

    // ── Zona objetivo (fondo verde translúcido)
    final rangoPaint = Paint()
      ..color = AppTheme.success.withOpacity(0.08);
    canvas.drawRect(
      Rect.fromLTRB(0, toY(rangoMax), w, toY(rangoMin)),
      rangoPaint,
    );

    // ── Líneas horizontales de referencia
    final refPaint = Paint()
      ..color = AppTheme.border
      ..strokeWidth = 1;
    for (final ref in [100.0, 130.0, 160.0]) {
      canvas.drawLine(Offset(0, toY(ref)), Offset(w, toY(ref)), refPaint);
    }

    if (valores.isEmpty) return;
    final step = w / (valores.length - 1);

    // ── Área bajo la curva
    final areaPath = Path();
    areaPath.moveTo(0, h);
    for (var i = 0; i < valores.length; i++) {
      areaPath.lineTo(i * step, toY(valores[i]));
    }
    areaPath.lineTo((valores.length - 1) * step, h);
    areaPath.close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withOpacity(0.25), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // ── Línea principal
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < valores.length; i++) {
      if (i == 0) {
        path.moveTo(0, toY(valores[0]));
      } else {
        final prev = Offset((i - 1) * step, toY(valores[i - 1]));
        final curr = Offset(i * step, toY(valores[i]));
        final cp1 = Offset(prev.dx + step / 2, prev.dy);
        final cp2 = Offset(curr.dx - step / 2, curr.dy);
        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // ── Puntos
    final dotPaint = Paint()..color = lineColor;
    final dotBg    = Paint()..color = AppTheme.surface;
    for (var i = 0; i < valores.length; i++) {
      final center = Offset(i * step, toY(valores[i]));
      canvas.drawCircle(center, 5, dotBg);
      canvas.drawCircle(center, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _MedImpactCard extends StatelessWidget {
  final _MedAnalisis med;
  final bool isSelected;
  final VoidCallback onTap;
  const _MedImpactCard(
      {required this.med, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? med.color : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: med.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.medication_rounded,
                      color: med.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.nombre,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Text(med.dosis,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${med.reduccionPromedio.toStringAsFixed(1)} mg/dL',
                      style: TextStyle(
                          color: med.color,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                    const Text('reducción prom.',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 10)),
                  ],
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 14),
              const Divider(color: AppTheme.border, height: 1),
              const SizedBox(height: 14),
              // Mini gráfica de barras
              _MiniBars(puntos: med.puntos, color: med.color),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoChip(
                    icon: Icons.trending_down_rounded,
                    label: 'Tendencia bajando',
                    color: AppTheme.success,
                  ),
                  _InfoChip(
                    icon: Icons.check_circle_rounded,
                    label: '${(med.adherencia * 100).round()}% adherencia',
                    color: med.color,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniBars extends StatelessWidget {
  final List<int> puntos;
  final Color color;
  const _MiniBars({required this.puntos, required this.color});

  @override
  Widget build(BuildContext context) {
    final max = puntos.reduce((a, b) => a > b ? a : b).toDouble();
    final dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(puntos.length, (i) {
          final ratio = puntos[i] / max;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(puntos[i].toString(),
                      style: TextStyle(
                          color: color, fontSize: 8, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 40 * ratio,
                      color: color.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(dias[i],
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 9)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CorrelacionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String titulo, descripcion;
  const _CorrelacionCard(
      {required this.icon,
      required this.color,
      required this.titulo,
      required this.descripcion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(descripcion,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedAnalisis {
  final String nombre, dosis;
  final double reduccionPromedio, adherencia;
  final Color color;
  final List<int> puntos;

  const _MedAnalisis({
    required this.nombre,
    required this.dosis,
    required this.reduccionPromedio,
    required this.adherencia,
    required this.color,
    required this.puntos,
  });
}