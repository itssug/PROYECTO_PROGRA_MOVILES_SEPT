import 'package:flutter/material.dart';
import '../models/registro_sueno_model.dart';
import '../services/estado_sueno_service.dart';

class AddRegistroSuenoScreen extends StatefulWidget {
  final int usuarioId;
  final VoidCallback onSaved;

  const AddRegistroSuenoScreen({
    super.key,
    required this.usuarioId,
    required this.onSaved,
  });

  @override
  State<AddRegistroSuenoScreen> createState() => _AddRegistroSuenoScreenState();
}

class _AddRegistroSuenoScreenState extends State<AddRegistroSuenoScreen> {
  static const _bg = Color(0xFF111111);
  static const _card = Color(0xFF1A1A1A);
  static const _orange = Color(0xFFFF6B35);
  static const _muted = Color(0xFF666666);

  TimeOfDay _horaAcostarse = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _horaDespertar = const TimeOfDay(hour: 6, minute: 30);
  String _calidad = 'bueno';
  bool _huboDespertares = false;
  bool _guardando = false;
  final _notasCtrl = TextEditingController();

  // Valores válidos para el campo calidad (max_length=9)
  final List<Map<String, dynamic>> _opcCalidad = [
  {'valor': 'excelente', 'color': const Color(0xFF5DCAA5), 'label': 'Excelente'},
  {'valor': 'bueno',     'color': const Color(0xFF1D9E75), 'label': 'Bueno'},      // ← era 'buena'
  {'valor': 'regular',   'color': const Color(0xFFEF9F27), 'label': 'Regular'},
  {'valor': 'malo',      'color': const Color(0xFFE24B4A), 'label': 'Malo'},       // ← era 'mala'
  {'valor': 'muy_malo',  'color': const Color(0xFF991F1F), 'label': 'Muy malo'},   // ← nuevo
];

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  String _horaStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  String _fechaHoy() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  double _calcHoras() {
    // Calcula horas dormidas cruzando medianoche si hace falta
    int minAc = _horaAcostarse.hour * 60 + _horaAcostarse.minute;
    int minDes = _horaDespertar.hour * 60 + _horaDespertar.minute;
    if (minDes <= minAc) minDes += 24 * 60; // cruzó medianoche
    return (minDes - minAc) / 60;
  }

  String _formatHoras(double h) {
    final horas = h.floor();
    final min = ((h - horas) * 60).round();
    return min > 0 ? '${horas}h ${min}m' : '${horas}h';
  }

  Future<void> _pickTime(bool esAcostarse) async {
    final initial = esAcostarse ? _horaAcostarse : _horaDespertar;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _orange),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (esAcostarse) _horaAcostarse = picked;
      else _horaDespertar = picked;
    });
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final horas = _calcHoras();
      final nuevo = RegistroSueno(
        usuarioId: widget.usuarioId,
        fecha: _fechaHoy(),
        horaAcostarse: _horaStr(_horaAcostarse),
        horaDespertar: _horaStr(_horaDespertar),
        horasDormidas: double.parse(horas.toStringAsFixed(2)),
        calidad: _calidad,
        huboDespertares: _huboDespertares,
        notas: _notasCtrl.text.isEmpty ? null : _notasCtrl.text,
      );
      await EstadoSuenoService.createSueno(nuevo);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: const Color(0xFFE24B4A)),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final horas = _calcHoras();
    final colorCalidad = _opcCalidad
        .firstWhere((e) => e['valor'] == _calidad)['color'] as Color;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _orange, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Registro de Sueño',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w600, fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: _orange, strokeWidth: 2))
                  : const Text('Guardar',
                      style: TextStyle(color: _orange,
                          fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Horario ──────────────────────────
          _SectionLabel('Horario de sueño'),
          Row(children: [
            // Me acosté
            Expanded(child: GestureDetector(
              onTap: () => _pickTime(true),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: _card, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  const Icon(Icons.bedtime, color: Color(0xFF7F77DD), size: 24),
                  const SizedBox(height: 6),
                  Text(
                    '${_horaAcostarse.hour.toString().padLeft(2,'0')}:'
                    '${_horaAcostarse.minute.toString().padLeft(2,'0')}',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  const Text('Me acosté',
                      style: TextStyle(color: _muted, fontSize: 10)),
                ]),
              ),
            )),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward, color: Color(0xFF333333), size: 20),
            ),
            // Desperté
            Expanded(child: GestureDetector(
              onTap: () => _pickTime(false),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: _card, borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  const Icon(Icons.wb_sunny_outlined,
                      color: Color(0xFFEF9F27), size: 24),
                  const SizedBox(height: 6),
                  Text(
                    '${_horaDespertar.hour.toString().padLeft(2,'0')}:'
                    '${_horaDespertar.minute.toString().padLeft(2,'0')}',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  const Text('Desperté',
                      style: TextStyle(color: _muted, fontSize: 10)),
                ]),
              ),
            )),
          ]),

          // ── Total calculado ──────────────────
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
                color: _orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _orange.withOpacity(0.3))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timelapse, color: _orange, size: 20),
                const SizedBox(width: 8),
                Text('Total: ', style: TextStyle(color: _muted, fontSize: 13)),
                Text(_formatHoras(horas),
                    style: const TextStyle(color: _orange,
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // ── Calidad ──────────────────────────
          _SectionLabel('Calidad del sueño'),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8, crossAxisSpacing: 8,
            childAspectRatio: 2.8,
            children: _opcCalidad.map((op) {
              final sel = op['valor'] == _calidad;
              final col = op['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _calidad = op['valor'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: sel ? col.withOpacity(0.15) : _card,
                    borderRadius: BorderRadius.circular(10),
                    border: sel
                        ? Border.all(color: col, width: 1.5)
                        : Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 8, height: 8,
                          decoration: BoxDecoration(
                              color: col, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(op['label'] as String,
                          style: TextStyle(
                              color: sel ? col : _muted,
                              fontSize: 12,
                              fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // ── Despertares ──────────────────────
          _SectionLabel('Interrupciones'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: _card, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.notifications_active_outlined,
                  color: _muted, size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Hubo despertares nocturnos?',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                  Text('Interrupciones durante el sueño',
                      style: TextStyle(color: _muted, fontSize: 11)),
                ],
              )),
              Switch(
                value: _huboDespertares,
                activeColor: _orange,
                onChanged: (v) => setState(() => _huboDespertares = v),
              ),
            ]),
          ),

          // ── Notas ────────────────────────────
          _SectionLabel('Notas (opcional)'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: _card, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _notasCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Pesadillas, ronquidos, ambiente...',
                hintStyle: TextStyle(color: Color(0xFF333333), fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _guardando
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                  : const Text('Guardar Registro',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// Reutiliza _SectionLabel del archivo anterior, o cópiala aquí:
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(text.toUpperCase(),
        style: const TextStyle(color: Color(0xFF666666),
            fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w500)),
  );
}