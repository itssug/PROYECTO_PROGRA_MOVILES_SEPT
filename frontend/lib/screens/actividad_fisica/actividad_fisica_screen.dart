// lib/screens/actividad_fisica/actividad_fisica_screen.dart
// Pantalla principal del módulo — tema oscuro naranja (estilo Figma Nutri-AI)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/actividad_fisica_service.dart';
import 'registrar_actividad_screen.dart';
import 'progreso_actividad_screen.dart';

const Color kBgPrimary    = Color(0xFF121212);
const Color kBgCard       = Color(0xFF1E1E1E);
const Color kBgInput      = Color(0xFF2A2A2A);
const Color kNaranja      = Color(0xFFFF6B00);
const Color kNaranjaLight = Color(0xFFFF8C38);
const Color kTextoBlanco  = Color(0xFFFFFFFF);
const Color kTextoGris    = Color(0xFF9E9E9E);
const Color kVerde        = Color(0xFF4CAF50);
const Color kRojo         = Color(0xFFF44336);
const Color kAzul         = Color(0xFF2196F3);

Map<String, IconData> iconosTipo = {
  'caminata': Icons.directions_walk,
  'trote': Icons.directions_run,
  'ciclismo': Icons.directions_bike,
  'natacion': Icons.pool,
  'pesas': Icons.fitness_center,
  'yoga': Icons.self_improvement,
  'baile': Icons.music_note,
  'futbol': Icons.sports_soccer,
  'otro_aerobico': Icons.favorite,
  'otro_anaerobico': Icons.bolt,
};

Map<String, Color> coloresTipo = {
  'caminata': const Color(0xFF4CAF50),
  'trote': const Color(0xFFFF6B00),
  'ciclismo': const Color(0xFF2196F3),
  'natacion': const Color(0xFF00BCD4),
  'pesas': const Color(0xFFE91E63),
  'yoga': const Color(0xFF9C27B0),
  'baile': const Color(0xFFFF9800),
  'futbol': const Color(0xFF4CAF50),
  'otro_aerobico': const Color(0xFFFF5722),
  'otro_anaerobico': const Color(0xFF607D8B),
};

class ActividadFisicaScreen extends StatefulWidget {
  const ActividadFisicaScreen({super.key});

  @override
  State<ActividadFisicaScreen> createState() => _ActividadFisicaScreenState();
}

class _ActividadFisicaScreenState extends State<ActividadFisicaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic>? _resumenHoy;
  List<dynamic> _actividades = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final hoy = await ActividadFisicaService.obtenerResumenHoy();
      final lista = await ActividadFisicaService.listarActividades();
      setState(() {
        _resumenHoy = hoy;
        _actividades = lista['actividades'] ?? [];
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar al servidor.\nVerifica que el backend esté corriendo.';
        _cargando = false;
      });
    }
  }

  Future<void> _eliminarActividad(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBgCard,
        title: const Text('¿Eliminar actividad?', style: TextStyle(color: kTextoBlanco)),
        content: const Text('Esta acción no se puede deshacer.', style: TextStyle(color: kTextoGris)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: kTextoGris)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRojo),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await ActividadFisicaService.eliminarActividad(id);
        _cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Actividad eliminada'), backgroundColor: kVerde),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: kRojo),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kNaranja.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fitness_center, color: kNaranja, size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Actividad Física',
                    style: TextStyle(color: kTextoBlanco, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Tu progreso deportivo', style: TextStyle(color: kTextoGris, fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: kNaranja),
            tooltip: 'Ver progreso',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProgresoActividadScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: kTextoGris),
            onPressed: _cargarDatos,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kNaranja,
          labelColor: kNaranja,
          unselectedLabelColor: kTextoGris,
          tabs: const [
            Tab(text: 'HOY', icon: Icon(Icons.today, size: 18)),
            Tab(text: 'HISTORIAL', icon: Icon(Icons.history, size: 18)),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: kNaranja))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabHoy(),
                    _buildTabHistorial(),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: kNaranja,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Registrar', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegistrarActividadScreen()),
          );
          if (resultado == true) _cargarDatos();
        },
      ),
    );
  }

  Widget _buildTabHoy() {
    final resumen = _resumenHoy?['resumen'] ?? {};
    final actividades = (_resumenHoy?['actividades'] as List?) ?? [];
    final int minutos = resumen['minutos'] ?? 0;
    final double calorias = (resumen['calorias'] ?? 0).toDouble();
    final int pasos = resumen['pasos'] ?? 0;
    final int totalActs = resumen['actividades'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitulo('Resumen de Hoy'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(Icons.timer_outlined, '${minutos}min', 'Duración', kNaranja),
              const SizedBox(width: 10),
              _buildStatCard(Icons.local_fire_department, '${calorias.toInt()}kcal', 'Calorías', kRojo),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatCard(Icons.directions_walk, '$pasos', 'Pasos', kVerde),
              const SizedBox(width: 10),
              _buildStatCard(Icons.sports, '$totalActs', 'Actividades', kAzul),
            ],
          ),
          const SizedBox(height: 20),
          _buildMetaSemanal(minutos, 150),
          const SizedBox(height: 20),
          _buildTitulo('Actividades del Día'),
          const SizedBox(height: 12),
          if (actividades.isEmpty)
            _buildVacio('Sin actividades hoy', '¡Registra tu primera actividad del día!')
          else
            ...actividades.map((a) => _buildTarjetaActividad(a)).toList(),
        ],
      ),
    );
  }

  Widget _buildTabHistorial() {
    return _actividades.isEmpty
        ? _buildVacio('Sin actividades registradas', 'Toca el botón + para registrar tu primera actividad')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _actividades.length,
            itemBuilder: (_, i) {
              final a = _actividades[i];
              return _buildTarjetaActividadCompleta(a);
            },
          );
  }

  Widget _buildTitulo(String texto) {
    return Text(texto,
        style: const TextStyle(
            color: kTextoBlanco, fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _buildStatCard(IconData icono, String valor, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color, size: 24),
            const SizedBox(height: 8),
            Text(valor,
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: kTextoGris, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaSemanal(int minutos, int meta) {
    final double pct = (minutos / meta).clamp(0.0, 1.0);
    final bool cumplida = minutos >= meta;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cumplida ? kVerde.withOpacity(0.5) : kNaranja.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Meta Semanal ADA',
                  style: TextStyle(color: kTextoBlanco, fontWeight: FontWeight.bold)),
              Text(
                cumplida ? '¡Completada! 🎉' : '$minutos / $meta min',
                style: TextStyle(
                  color: cumplida ? kVerde : kNaranja,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: kBgInput,
              valueColor: AlwaysStoppedAnimation<Color>(cumplida ? kVerde : kNaranja),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'La Asociación Americana de Diabetes recomienda 150 min/semana de actividad moderada.',
            style: TextStyle(color: kTextoGris, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaActividad(Map a) {
    final String tipo = a['tipo'] ?? 'caminata';
    final Color color = coloresTipo[tipo] ?? kNaranja;
    final IconData icono = iconosTipo[tipo] ?? Icons.fitness_center;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nombreTipo(tipo),
                    style: const TextStyle(
                        color: kTextoBlanco, fontWeight: FontWeight.bold)),
                Text(
                  '${a['duracion']} min · ${(a['calorias_quemadas'] ?? 0).toStringAsFixed(0)} kcal · ${a['intensidad'] ?? ''}',
                  style: const TextStyle(color: kTextoGris, fontSize: 12),
                ),
              ],
            ),
          ),
          if (a['hora_inicio'] != null)
            Text(a['hora_inicio'].toString().substring(0, 5),
                style: const TextStyle(color: kNaranja, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTarjetaActividadCompleta(Map a) {
    final String tipo = a['tipo'] ?? 'caminata';
    final Color color = coloresTipo[tipo] ?? kNaranja;
    final IconData icono = iconosTipo[tipo] ?? Icons.fitness_center;
    final int id = a['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: color, size: 22),
            ),
            title: Text(_nombreTipo(tipo),
                style: const TextStyle(
                    color: kTextoBlanco, fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${a['fecha']} · ${a['intensidad'] ?? ''}',
              style: const TextStyle(color: kTextoGris, fontSize: 12),
            ),
            trailing: PopupMenuButton<String>(
              color: kBgInput,
              icon: const Icon(Icons.more_vert, color: kTextoGris),
              onSelected: (v) {
                if (v == 'editar') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RegistrarActividadScreen(actividadEditar: a),
                    ),
                  ).then((ok) { if (ok == true) _cargarDatos(); });
                } else if (v == 'eliminar') {
                  _eliminarActividad(id);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'editar',
                  child: Row(children: [
                    Icon(Icons.edit, color: kNaranja, size: 18),
                    SizedBox(width: 8),
                    Text('Editar', style: TextStyle(color: kTextoBlanco)),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'eliminar',
                  child: Row(children: [
                    Icon(Icons.delete, color: kRojo, size: 18),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: kRojo)),
                  ]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStat(Icons.timer, '${a['duracion']} min', kNaranja),
                _buildMiniStat(Icons.local_fire_department,
                    '${(a['calorias_quemadas'] ?? 0).toStringAsFixed(0)} kcal', kRojo),
                _buildMiniStat(Icons.directions_walk, '${a['pasos'] ?? 0} pasos', kVerde),
                if (a['glucosa_pre'] != null)
                  _buildMiniStat(Icons.monitor_heart,
                      '${a['glucosa_pre']}→${a['glucosa_post']} mg/dL', kAzul),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icono, String texto, Color color) {
    return Row(
      children: [
        Icon(icono, color: color, size: 14),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildVacio(String titulo, String subtitulo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kNaranja.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fitness_center, color: kNaranja, size: 48),
            ),
            const SizedBox(height: 20),
            Text(titulo,
                style: const TextStyle(
                    color: kTextoBlanco, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitulo,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kTextoGris, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: kRojo, size: 64),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kTextoGris, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: kNaranja),
              icon: const Icon(Icons.refresh, color: Colors.black),
              label: const Text('Reintentar', style: TextStyle(color: Colors.black)),
              onPressed: _cargarDatos,
            ),
          ],
        ),
      ),
    );
  }

  String _nombreTipo(String tipo) {
    final nombres = {
      'caminata': 'Caminata',
      'trote': 'Trote / Jogging',
      'ciclismo': 'Ciclismo',
      'natacion': 'Natación',
      'pesas': 'Pesas / Gimnasio',
      'yoga': 'Yoga / Meditación',
      'baile': 'Baile',
      'futbol': 'Fútbol',
      'otro_aerobico': 'Ejercicio Aeróbico',
      'otro_anaerobico': 'Ejercicio Anaeróbico',
    };
    return nombres[tipo] ?? tipo;
  }
}
