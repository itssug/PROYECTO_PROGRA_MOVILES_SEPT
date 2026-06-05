import 'package:flutter/material.dart';
import '../models/estado_emocional_model.dart';
import '../services/estado_sueno_service.dart';

class AddEstadoEmocionalScreen extends StatefulWidget {
  final int usuarioId;
  final VoidCallback onSaved;

  const AddEstadoEmocionalScreen({
    super.key,
    required this.usuarioId,
    required this.onSaved,
  });

  @override
  State<AddEstadoEmocionalScreen> createState() =>
      _AddEstadoEmocionalScreenState();
}

class _AddEstadoEmocionalScreenState extends State<AddEstadoEmocionalScreen> {
  // ── Constantes de diseño ─────────────────────
  static const _bg = Color(0xFF111111);
  static const _card = Color(0xFF1A1A1A);
  static const _orange = Color(0xFFFF6B35);
  static const _muted = Color(0xFF666666);

  // ── Estado del formulario ────────────────────
  double _nivelEstres = 5;
  String _estadoSeleccionado = 'tranquilo';
  TimeOfDay _hora = TimeOfDay.now();
  final _eventoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  bool _guardando = false;

  // Valores válidos según el modelo (max_length=9)
  final List<Map<String, dynamic>> _estados = [
    {'valor': 'tranquilo',  'icono': Icons.sentiment_neutral,          'label': 'Tranquilo'},
    {'valor': 'ansioso',    'icono': Icons.sentiment_very_dissatisfied,'label': 'Ansioso'},
    {'valor': 'estresado',  'icono': Icons.mood_bad,                   'label': 'Estresado'},
    {'valor': 'triste',     'icono': Icons.sentiment_dissatisfied,     'label': 'Triste'},
    {'valor': 'irritable',  'icono': Icons.sentiment_very_dissatisfied,'label': 'Irritable'},
    {'valor': 'alegre',     'icono': Icons.sentiment_very_satisfied,   'label': 'Alegre'},
  ];

  @override
  void dispose() {
    _eventoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────
  Color get _colorEstres {
    if (_nivelEstres <= 3) return const Color(0xFF5DCAA5);
    if (_nivelEstres <= 6) return const Color(0xFFEF9F27);
    return const Color(0xFFE24B4A);
  }

  String _horaFormateada(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fechaHoy() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _seleccionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _orange),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _hora = picked);
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final nuevo = EstadoEmocional(
        usuarioId: widget.usuarioId,
        fecha: _fechaHoy(),
        hora: _horaFormateada(_hora),
        nivelEstres: _nivelEstres.round(),
        estado: _estadoSeleccionado,
        evento: _eventoCtrl.text.isEmpty ? null : _eventoCtrl.text,
        notas: _notasCtrl.text.isEmpty ? null : _notasCtrl.text,
      );
      await EstadoSuenoService.createEstado(nuevo);
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

  // ── UI ───────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _orange, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Registro Emocional',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600,
                fontSize: 16)),
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
                      style: TextStyle(color: _orange, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Nivel de estrés ──────────────────
          _SectionLabel('Nivel de estrés'),
          _Card(child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Sin estrés',
                  style: TextStyle(color: _muted, fontSize: 11)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: _colorEstres.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('${_nivelEstres.round()}/10',
                    style: TextStyle(color: _colorEstres,
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const Text('Muy alto',
                  style: TextStyle(color: _muted, fontSize: 11)),
            ]),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _colorEstres,
                inactiveTrackColor: const Color(0xFF2A2A2A),
                thumbColor: _colorEstres,
                overlayColor: _colorEstres.withOpacity(0.15),
                trackHeight: 4,
              ),
              child: Slider(
                value: _nivelEstres,
                min: 0, max: 10, divisions: 10,
                onChanged: (v) => setState(() => _nivelEstres = v),
              ),
            ),
          ])),

          // ── Estado de ánimo ──────────────────
          _SectionLabel('Estado de ánimo'),
          _Card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('¿Cómo te sientes ahora?',
                  style: TextStyle(color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              // Reemplaza el Row de mood_grid por un Wrap:
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _estados.map((e) {
                  final sel = e['valor'] == _estadoSeleccionado;
                  return GestureDetector(
                    onTap: () => setState(() => _estadoSeleccionado = e['valor']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: (MediaQuery.of(context).size.width - 80) / 3,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFFFF6B35).withOpacity(0.15)
                            : const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(10),
                        border: sel
                            ? Border.all(color: const Color(0xFFFF6B35), width: 1.5)
                            : Border.all(color: Colors.transparent),
                      ),
                      child: Column(children: [
                        Icon(e['icono'] as IconData,
                            color: sel ? const Color(0xFFFF6B35) : const Color(0xFF666666),
                            size: 22),
                        const SizedBox(height: 4),
                        Text(e['label'] as String,
                            style: TextStyle(
                                color: sel ? const Color(0xFFFF6B35) : const Color(0xFF666666),
                                fontSize: 10,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ],
          )),

          // ── Hora ────────────────────────────
          _SectionLabel('Hora del registro'),
          GestureDetector(
            onTap: _seleccionarHora,
            child: _Card(child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Hora', style: TextStyle(color: _muted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(_horaFormateada(_hora),
                      style: const TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: _orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.access_time, color: _orange, size: 20),
                ),
              ],
            )),
          ),

          // ── Evento ──────────────────────────
          _SectionLabel('Evento o causa (opcional)'),
          _Card(child: TextField(
            controller: _eventoCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Trabajo, familia, consulta médica...',
              hintStyle: TextStyle(color: Color(0xFF333333), fontSize: 13),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          )),

          // ── Notas ───────────────────────────
          _SectionLabel('Notas adicionales (opcional)'),
          _Card(child: TextField(
            controller: _notasCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Observaciones sobre tu estado...',
              hintStyle: TextStyle(color: Color(0xFF333333), fontSize: 13),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          )),

          const SizedBox(height: 16),

          // ── Botón guardar ───────────────────
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
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
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

// ── Widgets auxiliares reutilizables ─────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(text.toUpperCase(),
        style: const TextStyle(color: Color(0xFF666666),
            fontSize: 10, letterSpacing: 0.8,
            fontWeight: FontWeight.w500)),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12)),
    child: child,
  );
}