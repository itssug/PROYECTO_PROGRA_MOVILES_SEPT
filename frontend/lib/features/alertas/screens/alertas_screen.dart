import 'package:flutter/material.dart';
import '../models/alerta_model.dart';
import '../services/alertas_service.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  static const _bg = Color(0xFF111111);
  static const _card = Color(0xFF1A1A1A);
  static const _orange = Color(0xFFFF6B35);
  static const _muted = Color(0xFF666666);

  List<Alerta> _alertas = [];
  Map<String, dynamic>? _resumen;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final alertas = await AlertasService.getAlertas();
      final resumen = await AlertasService.getResumenDiario();
      setState(() {
        _alertas = alertas;
        _resumen = resumen;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar al servidor.';
        _cargando = false;
      });
    }
  }

  Color _colorPrioridad(String? p) {
    switch (p) {
      case 'alta': return const Color(0xFFE24B4A);
      case 'media': return const Color(0xFFEF9F27);
      default: return const Color(0xFF5DCAA5);
    }
  }

  IconData _iconoTipo(String tipo) {
    switch (tipo) {
      case 'exceso_carbohidratos': return Icons.bakery_dining;
      case 'exceso_azucares': return Icons.icecream;
      case 'resumen_diario': return Icons.summarize;
      default: return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: const Text('Alertas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _muted),
            onPressed: _cargarTodo,
          ),
        ],
      ),
      body: _cargando
    ? const Center(child: CircularProgressIndicator(color: _orange))
    : _error != null
        ? _buildError()
        : RefreshIndicator(
            onRefresh: _cargarTodo,
            color: _orange,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // Botón para verificar consumo
                ElevatedButton.icon(
                  onPressed: () async {
                    final n = await AlertasService.verificarLimites();

                    if (n > 0) _cargarTodo();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            n > 0
                                ? '$n nueva(s) alerta(s) generada(s)'
                                : 'Sin nuevas alertas',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Verificar consumo de hoy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                if (_resumen != null) _buildResumenCard(),

                const SizedBox(height: 20),

                const Text(
                  'Historial de alertas',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 12),

                if (_alertas.isEmpty)
                  _buildVacio()
                else
                  ..._alertas.map((a) => _buildAlertaCard(a)),
              ],
            ),
          ),
    );
    
  }

  Widget _buildResumenCard() {
    final carbosPct = (_resumen!['carbohidratos_porcentaje'] as num).toDouble();
    final azucaresPct = (_resumen!['azucares_porcentaje'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Consumo de hoy',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 14),
        _buildBarraProgreso(
          'Carbohidratos',
          _resumen!['carbohidratos_consumidos'],
          _resumen!['carbohidratos_limite'],
          carbosPct,
        ),
        const SizedBox(height: 12),
        _buildBarraProgreso(
          'Azúcares',
          _resumen!['azucares_consumidos'],
          _resumen!['azucares_limite'],
          azucaresPct,
        ),
      ]),
    );
  }

  Widget _buildBarraProgreso(String label, dynamic consumido, dynamic limite, double pct) {
    final color = pct >= 100
        ? const Color(0xFFE24B4A)
        : pct >= 70
            ? const Color(0xFFEF9F27)
            : const Color(0xFF5DCAA5);
    final pctClamped = (pct / 100).clamp(0.0, 1.0);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        Text('${consumido}g / ${limite}g',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: pctClamped,
          backgroundColor: const Color(0xFF2A2A2A),
          color: color,
          minHeight: 8,
        ),
      ),
    ]);
  }

  Widget _buildAlertaCard(Alerta a) {
    final color = _colorPrioridad(a.prioridad);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: a.esLeida ? null : Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_iconoTipo(a.tipo), color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.titulo ?? '',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Text(a.mensaje ?? '',
                style: const TextStyle(color: _muted, fontSize: 12)),
            if (a.fecha != null) ...[
              const SizedBox(height: 6),
              Text(a.fecha!.substring(0, 16),
                  style: const TextStyle(color: Color(0xFF444444), fontSize: 10)),
            ],
          ]),
        ),
        if (!a.esLeida)
          GestureDetector(
            onTap: () async {
              await AlertasService.marcarLeida(a.id);
              _cargarTodo();
            },
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
      ]),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Icon(Icons.notifications_off_outlined, color: _muted, size: 48),
          const SizedBox(height: 16),
          const Text('Sin alertas',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('No has superado tus límites diarios',
              style: TextStyle(color: _muted, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off, color: Color(0xFFE24B4A), size: 56),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarTodo,
            style: ElevatedButton.styleFrom(backgroundColor: _orange),
            child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}