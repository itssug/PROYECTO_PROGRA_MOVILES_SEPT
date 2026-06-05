import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/actividad_fisica_service.dart';
import 'actividad_fisica_screen.dart'; // colores compartidos

class ProgresoActividadScreen extends StatefulWidget {
  const ProgresoActividadScreen({super.key});

  @override
  State<ProgresoActividadScreen> createState() => _ProgresoActividadScreenState();
}

class _ProgresoActividadScreenState extends State<ProgresoActividadScreen> {
  int _periodoSeleccionado = 7;
  Map<String, dynamic>? _stats;
  bool _cargando = true;
  String? _error;

  final List<Map<String, dynamic>> _periodos = [
    {'dias': 7, 'label': '7 días'},
    {'dias': 30, 'label': '30 días'},
    {'dias': 90, 'label': '90 días'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final data = await ActividadFisicaService.obtenerEstadisticas(
          periodo: _periodoSeleccionado);
      setState(() { _stats = data; _cargando = false; });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar las estadísticas.';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kNaranja),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Mi Progreso',
            style: TextStyle(color: kTextoBlanco, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: kTextoGris),
            onPressed: _cargarEstadisticas,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: _periodos.map((p) {
                final bool sel = _periodoSeleccionado == p['dias'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _periodoSeleccionado = p['dias']);
                      _cargarEstadisticas();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? kNaranja : kBgCard,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        p['label'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: sel ? Colors.black : kTextoGris,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: kNaranja))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: kTextoGris)))
                    : _buildContenido(),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    final totales = _stats!['totales'] ?? {};
    final porTipo = (_stats!['por_tipo'] as List?) ?? [];
    final porDia = (_stats!['por_dia'] as List?) ?? [];
    final meta = _stats!['meta_semanal'] ?? {};
    final impactoGlucosa = (_stats!['impacto_glucosa'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitulo('Resumen del Periodo'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildKPI('${totales['actividades'] ?? 0}', 'Actividades', Icons.sports, kNaranja),
              const SizedBox(width: 10),
              _buildKPI('${totales['minutos'] ?? 0}', 'Minutos', Icons.timer, kAzul),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildKPI('${(totales['calorias'] ?? 0).toInt()}', 'Calorías', Icons.local_fire_department, kRojo),
              const SizedBox(width: 10),
              _buildKPI('${totales['pasos'] ?? 0}', 'Pasos', Icons.directions_walk, kVerde),
            ],
          ),
          const SizedBox(height: 24),

          _buildTitulo('Meta Semanal (ADA)'),
          const SizedBox(height: 12),
          _buildMetaSemanal(meta),
          const SizedBox(height: 24),

          if (porDia.isNotEmpty) ...[
            _buildTitulo('Minutos por Día'),
            const SizedBox(height: 12),
            _buildGraficoBarras(porDia),
            const SizedBox(height: 24),
          ],

          if (porTipo.isNotEmpty) ...[
            _buildTitulo('Actividades por Tipo'),
            const SizedBox(height: 12),
            _buildGraficoPastel(porTipo),
            const SizedBox(height: 24),
          ],

          if (impactoGlucosa.isNotEmpty) ...[
            _buildTitulo('Impacto en Glucosa'),
            const SizedBox(height: 8),
            const Text(
              'Diferencia de glucosa (mg/dL) antes vs después del ejercicio',
              style: TextStyle(color: kTextoGris, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ...impactoGlucosa.take(5).map((item) => _buildFilaImpacto(item)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildTitulo(String texto) {
    return Text(texto,
        style: const TextStyle(
            color: kTextoBlanco, fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _buildKPI(String valor, String label, IconData icono, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor,
                    style: TextStyle(
                        color: color, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: kTextoGris, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaSemanal(Map meta) {
    final int completado = meta['completado_minutos'] ?? 0;
    final int objetivo = meta['objetivo_minutos'] ?? 150;
    final double pct = ((meta['porcentaje'] ?? 0) / 100.0).clamp(0.0, 1.0);
    final bool cumplida = completado >= objetivo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cumplida ? kVerde.withOpacity(0.5) : kNaranja.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cumplida ? '¡Meta completada! 🎉' : 'En progreso...',
                    style: TextStyle(
                      color: cumplida ? kVerde : kNaranja,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('$completado / $objetivo minutos esta semana',
                      style: const TextStyle(color: kTextoGris, fontSize: 12)),
                ],
              ),
              Text(
                '${(pct * 100).toInt()}%',
                style: TextStyle(
                  color: cumplida ? kVerde : kNaranja,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: kBgInput,
              valueColor:
                  AlwaysStoppedAnimation<Color>(cumplida ? kVerde : kNaranja),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoBarras(List porDia) {
    final datos = porDia.length > 7
        ? porDia.sublist(porDia.length - 7)
        : porDia;

    final maxY = datos
            .map((d) => (d['minutos'] as num).toDouble())
            .fold(0.0, (a, b) => a > b ? a : b) +
        10;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY > 0 ? maxY : 60,
          backgroundColor: kBgCard,
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: kBgInput, strokeWidth: 1),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= datos.length) return const SizedBox();
                  final fecha = datos[idx]['fecha'].toString();
                  final partes = fecha.split('-');
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${partes[2]}/${partes[1]}',
                      style: const TextStyle(color: kTextoGris, fontSize: 9),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: datos.asMap().entries.map((e) {
            final minutos = (e.value['minutos'] as num).toDouble();
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: minutos,
                  color: minutos >= 30 ? kNaranja : kNaranjaLight.withOpacity(0.5),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGraficoPastel(List porTipo) {
    final total =
        porTipo.fold<int>(0, (sum, t) => sum + (t['cantidad'] as int));

    final sections = porTipo.asMap().entries.map((e) {
      final t = e.value;
      final String tipo = t['tipo'];
      final int cantidad = t['cantidad'];
      final Color color = coloresTipo[tipo] ?? kNaranja;
      final double pct = total > 0 ? (cantidad / total) * 100 : 0;

      return PieChartSectionData(
        value: cantidad.toDouble(),
        color: color,
        title: '${pct.toInt()}%',
        radius: 70,
        titleStyle: const TextStyle(
          color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 160,
            width: 160,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 30,
                sectionsSpace: 3,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: porTipo.take(5).map((t) {
                final String tipo = t['tipo'];
                final Color color = coloresTipo[tipo] ?? kNaranja;
                final IconData icono = iconosTipo[tipo] ?? Icons.fitness_center;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(icono, color: color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _nombreTipo(tipo),
                          style: const TextStyle(color: kTextoBlanco, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${t['cantidad']}x',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilaImpacto(Map item) {
    final double diff = (item['diferencia'] as num).toDouble();
    final bool bajo = diff < 0;
    final Color color = bajo ? kVerde : kRojo;
    final IconData icono = bajo ? Icons.trending_down : Icons.trending_up;
    final String tipo = item['tipo'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(iconosTipo[tipo] ?? Icons.fitness_center,
              color: coloresTipo[tipo] ?? kNaranja, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nombreTipo(tipo),
                    style: const TextStyle(color: kTextoBlanco, fontSize: 13)),
                Text(
                  '${item['glucosa_pre']} → ${item['glucosa_post']} mg/dL',
                  style: const TextStyle(color: kTextoGris, fontSize: 11),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(icono, color: color, size: 18),
              const SizedBox(width: 4),
              Text(
                '${bajo ? '' : '+'}${diff.toStringAsFixed(1)}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _nombreTipo(String tipo) {
    final nombres = {
      'caminata': 'Caminata',
      'trote': 'Trote',
      'ciclismo': 'Ciclismo',
      'natacion': 'Natación',
      'pesas': 'Pesas',
      'yoga': 'Yoga',
      'baile': 'Baile',
      'futbol': 'Fútbol',
      'otro_aerobico': 'Aeróbico',
      'otro_anaerobico': 'Anaeróbico',
    };
    return nombres[tipo] ?? tipo;
  }
}
