import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/medicamento_model.dart';
import '../models/registro_model.dart';
import '../services/medicamento_service.dart';
import '../services/registro_service.dart';

class AnalisisGlucosaScreen extends StatefulWidget {
  const AnalisisGlucosaScreen({super.key});

  @override
  State<AnalisisGlucosaScreen> createState() => _AnalisisGlucosaScreenState();
}

class _AnalisisGlucosaScreenState extends State<AnalisisGlucosaScreen> {
  String _periodo = '7 días';
  final List<String> _periodos = ['7 días', '14 días', '30 días'];
  String? _medSeleccionado;

  // ── Estado real ───────────────────────────────────────────────────────────
  bool _cargando = true;
  String? _error;

  Adherencia? _adherencia;
  List<Medicamento> _medicamentosActivos = [];
  List<RegistroMedicamento> _historial   = [];

  // Datos calculados en cliente por medicamento
  List<_MedAnalisis> _medAnalisis = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() { _cargando = true; _error = null; });

    // Llamadas en paralelo
    final results = await Future.wait([
      RegistroService.adherencia(),
      MedicamentoService.listarActivos(),
      RegistroService.historial(),
    ]);

    if (!mounted) return;

    final resAdherencia = results[0] as ServiceResult<Adherencia>;
    final resMeds       = results[1] as ServiceResult<List<Medicamento>>;
    final resHistorial  = results[2] as ServiceResult<List<RegistroMedicamento>>;

    if (!resMeds.success) {
      setState(() { _error = resMeds.error; _cargando = false; });
      return;
    }

    final meds      = resMeds.data ?? [];
    final historial = resHistorial.data ?? [];

    setState(() {
      _adherencia          = resAdherencia.data;
      _medicamentosActivos = meds;
      _historial           = historial;
      _medAnalisis         = _calcularAnalisisPorMed(meds, historial);
      _cargando            = false;
    });
  }

  /// Calcula adherencia y reducción simulada por medicamento a partir
  /// de los registros reales. La reducción de glucosa es simulada
  /// hasta que el backend exponga un endpoint de glucosa.
  List<_MedAnalisis> _calcularAnalisisPorMed(
    List<Medicamento> meds,
    List<RegistroMedicamento> historial,
  ) {
    const colors = [AppTheme.success, AppTheme.accent, Color(0xFF5E9BFF)];

    return List.generate(meds.length, (i) {
      final med = meds[i];
      final registrosMed = historial
          .where((r) => r.medicamentoId == med.id)
          .toList();

      final total   = registrosMed.length;
      final tomados = registrosMed.where((r) => r.fueTomado == 1).length;
      final adherencia = total == 0 ? 0.0 : tomados / total;

      // Últimos 7 puntos de dosis tomada (o 0 si no fue tomado)
      final ultimos7 = registrosMed.take(7).toList();
      final puntos = List.generate(7, (j) {
        if (j < ultimos7.length) {
          return ((ultimos7[j].dosisTomada ?? 0) * 1).toInt();
        }
        return 0;
      }).reversed.toList();

      return _MedAnalisis(
        id:                 med.id ?? 0,
        nombre:             med.nombre,
        dosis:              '${med.dosis ?? '--'} ${med.unidad ?? ''}',
        adherencia:         adherencia,
        // TODO: calcular reducción real cuando exista endpoint de glucosa
        reduccionPromedio: (-(adherencia * 30).clamp(0, 40)).toDouble(),
        color:              colors[i % colors.length],
        puntos:             puntos,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppTheme.danger, size: 48),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Glucosa'),
        actions: [
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
                    color: AppTheme.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
                items: _periodos
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _periodo = v!),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.accent,
        onRefresh: _cargarDatos,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // ── Insight de adherencia general (dato real)
            _InsightBanner(adherencia: _adherencia),
            const SizedBox(height: 20),

            // ── Gráfica de glucosa — simulada hasta tener endpoint
            const SectionLabel('Glucosa en los últimos 7 días'),
            const _GlucosaChartSimulada(),
            const SizedBox(height: 20),

            // ── Por medicamento (adherencia real, reducción estimada)
            const SectionLabel('Efecto por medicamento'),
            if (_medAnalisis.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('Sin medicamentos activos',
                      style: TextStyle(color: AppTheme.textMuted)),
                ),
              )
            else
              ..._medAnalisis.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MedImpactCard(
                      med:        m,
                      isSelected: _medSeleccionado == m.nombre,
                      onTap: () => setState(() => _medSeleccionado =
                          _medSeleccionado == m.nombre ? null : m.nombre),
                    ),
                  )),
            const SizedBox(height: 8),

            // ── Correlaciones — simuladas hasta tener endpoint de IA
            const SectionLabel('Correlaciones detectadas'),
            // TODO: conectar a endpoint de correlaciones cuando esté disponible
            const _CorrelacionCard(
              icon:        Icons.medication_rounded,
              color:       AppTheme.success,
              titulo:      'Medicamento + Ejercicio',
              descripcion: 'Análisis de correlaciones disponible próximamente.',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _InsightBanner extends StatelessWidget {
  final Adherencia? adherencia;
  const _InsightBanner({required this.adherencia});

  @override
  Widget build(BuildContext context) {
    final pct     = adherencia?.porcentaje ?? 0;
    final buena   = pct >= 80;
    final color   = buena ? AppTheme.success : AppTheme.warning;
    final icono   = buena ? Icons.trending_up_rounded : Icons.warning_amber_rounded;
    final titulo  = buena ? 'Adherencia excelente' : 'Adherencia mejorable';
    final mensaje = adherencia != null
        ? 'Tomaste ${adherencia!.tomados} de ${adherencia!.total} dosis '
          'en los últimos 7 días (${pct.toStringAsFixed(1)}%).'
        : 'No hay datos de adherencia disponibles.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), AppTheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(
                        color: color, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(mensaje,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Gráfica simulada — TODO: reemplazar con datos reales de /glucosa/
class _GlucosaChartSimulada extends StatelessWidget {
  const _GlucosaChartSimulada();

  @override
  Widget build(BuildContext context) {
    final dias    = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final glucosa = [165, 148, 142, 135, 138, 128, 125];
    const maxVal  = 200.0;
    const minVal  = 70.0;

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 14, height: 3,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text('Rango objetivo (70-130)',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              const Spacer(),
              Container(width: 14, height: 3, color: AppTheme.accent),
              const SizedBox(width: 6),
              const Text('Simulado',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _ChartPainter(
                valores:   glucosa.map((v) => v.toDouble()).toList(),
                max:       maxVal,
                min:       minVal,
                lineColor: AppTheme.accent,
                rangoMin:  70,
                rangoMax:  130,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dias
                .map((d) => Text(d,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)))
                .toList(),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 12, color: AppTheme.textMuted),
                SizedBox(width: 6),
                Text('Datos simulados — endpoint de glucosa pendiente',
                    style:
                        TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              ],
            ),
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

    final rangoPaint = Paint()..color = AppTheme.success.withOpacity(0.08);
    canvas.drawRect(
        Rect.fromLTRB(0, toY(rangoMax), w, toY(rangoMin)), rangoPaint);

    final refPaint = Paint()..color = AppTheme.border..strokeWidth = 1;
    for (final ref in [100.0, 130.0, 160.0]) {
      canvas.drawLine(Offset(0, toY(ref)), Offset(w, toY(ref)), refPaint);
    }

    if (valores.isEmpty) return;
    final step = w / (valores.length - 1);

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
        final cp1  = Offset(prev.dx + step / 2, prev.dy);
        final cp2  = Offset(curr.dx - step / 2, curr.dy);
        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
      }
    }
    canvas.drawPath(path, linePaint);

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
                              color:      AppTheme.textPrimary,
                              fontSize:   14,
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
                          color:      med.color,
                          fontSize:   15,
                          fontWeight: FontWeight.w700),
                    ),
                    const Text('reducción est.',
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
              _MiniBars(puntos: med.puntos, color: med.color),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoChip(
                    icon:  Icons.check_circle_rounded,
                    label: '${(med.adherencia * 100).round()}% adherencia',
                    color: med.color,
                  ),
                  _InfoChip(
                    icon:  Icons.info_outline_rounded,
                    label: 'Reducción estimada',
                    color: AppTheme.textMuted,
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
    final max  = puntos.isEmpty ? 1 : puntos.reduce((a, b) => a > b ? a : b);
    final dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(puntos.length, (i) {
          final ratio = max == 0 ? 0.0 : puntos[i] / max;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(puntos[i].toString(),
                      style: TextStyle(
                          color:      color,
                          fontSize:   8,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 40 * ratio,
                      color:  color.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(i < dias.length ? dias[i] : '',
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
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

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
  const _CorrelacionCard({
    required this.icon,
    required this.color,
    required this.titulo,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppTheme.border),
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
                        color:      AppTheme.textPrimary,
                        fontSize:   13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(descripcion,
                    style: const TextStyle(
                        color:    AppTheme.textSecondary,
                        fontSize: 12,
                        height:   1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modelos locales ───────────────────────────────────────────────────────────

class _MedAnalisis {
  final int id;
  final String nombre, dosis;
  final double reduccionPromedio, adherencia;
  final Color color;
  final List<int> puntos;

  const _MedAnalisis({
    required this.id,
    required this.nombre,
    required this.dosis,
    required this.reduccionPromedio,
    required this.adherencia,
    required this.color,
    required this.puntos,
  });
}