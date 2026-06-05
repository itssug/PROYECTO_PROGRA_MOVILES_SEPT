import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/actividad_fisica_service.dart';
import 'actividad_fisica_screen.dart'; // importa constantes de color

class RegistrarActividadScreen extends StatefulWidget {
  final Map? actividadEditar; // null = crear, != null = editar

  const RegistrarActividadScreen({super.key, this.actividadEditar});

  @override
  State<RegistrarActividadScreen> createState() =>
      _RegistrarActividadScreenState();
}

class _RegistrarActividadScreenState extends State<RegistrarActividadScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _guardando = false;
  bool get _esEdicion => widget.actividadEditar != null;

  String _tipo = 'caminata';
  String _intensidad = 'moderada';
  final _duracionCtrl = TextEditingController();
  final _caloriasCtrl = TextEditingController();
  final _pasosCtrl = TextEditingController();
  final _frecuenciaCtrl = TextEditingController();
  final _glucosaPreCtrl = TextEditingController();
  final _glucosaPostCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();
  TimeOfDay? _horaInicio;

  final List<Map<String, dynamic>> _tipos = [
    {'valor': 'caminata', 'label': 'Caminata', 'icono': Icons.directions_walk},
    {'valor': 'trote', 'label': 'Trote', 'icono': Icons.directions_run},
    {'valor': 'ciclismo', 'label': 'Ciclismo', 'icono': Icons.directions_bike},
    {'valor': 'natacion', 'label': 'Natación', 'icono': Icons.pool},
    {'valor': 'pesas', 'label': 'Pesas', 'icono': Icons.fitness_center},
    {'valor': 'yoga', 'label': 'Yoga', 'icono': Icons.self_improvement},
    {'valor': 'baile', 'label': 'Baile', 'icono': Icons.music_note},
    {'valor': 'futbol', 'label': 'Fútbol', 'icono': Icons.sports_soccer},
    {'valor': 'otro_aerobico', 'label': 'Aeróbico', 'icono': Icons.favorite},
    {'valor': 'otro_anaerobico', 'label': 'Anaeróbico', 'icono': Icons.bolt},
  ];

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final a = widget.actividadEditar!;
      _tipo = a['tipo'] ?? 'caminata';
      _intensidad = a['intensidad'] ?? 'moderada';
      _duracionCtrl.text = '${a['duracion'] ?? ''}';
      _caloriasCtrl.text = '${a['calorias_quemadas'] ?? ''}';
      _pasosCtrl.text = '${a['pasos'] ?? ''}';
      _frecuenciaCtrl.text = '${a['frecuencia_cardiaca_prom'] ?? ''}';
      _glucosaPreCtrl.text = '${a['glucosa_pre'] ?? ''}';
      _glucosaPostCtrl.text = '${a['glucosa_post'] ?? ''}';
      _notasCtrl.text = a['notas'] ?? '';
      if (a['fecha'] != null) {
        _fecha = DateTime.parse(a['fecha']);
      }
    }
  }

  @override
  void dispose() {
    _duracionCtrl.dispose(); _caloriasCtrl.dispose();
    _pasosCtrl.dispose(); _frecuenciaCtrl.dispose();
    _glucosaPreCtrl.dispose(); _glucosaPostCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final datos = {
      'tipo': _tipo,
      'intensidad': _intensidad,
      'duracion': int.tryParse(_duracionCtrl.text) ?? 30,
      'calorias_quemadas': double.tryParse(_caloriasCtrl.text),
      'pasos': int.tryParse(_pasosCtrl.text),
      'frecuencia_cardiaca_prom': int.tryParse(_frecuenciaCtrl.text),
      'fecha': _fecha.toIso8601String().split('T')[0],
      'hora_inicio': _horaInicio != null
          ? '${_horaInicio!.hour.toString().padLeft(2, '0')}:${_horaInicio!.minute.toString().padLeft(2, '0')}:00'
          : null,
      'glucosa_pre': double.tryParse(_glucosaPreCtrl.text),
      'glucosa_post': double.tryParse(_glucosaPostCtrl.text),
      'notas': _notasCtrl.text,
    };

    try {
      if (_esEdicion) {
        await ActividadFisicaService.editarActividad(
            widget.actividadEditar!['id'], datos);
        if (mounted) _mostrarExito('Actividad actualizada correctamente');
      } else {
        await ActividadFisicaService.crearActividad(datos);
        if (mounted) _mostrarExito('¡Actividad registrada!');
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: kRojo),
        );
      }
    }
    setState(() => _guardando = false);
  }

  void _mostrarExito(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Text(msg),
        ]),
        backgroundColor: kVerde,
      ),
    );
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
        title: Text(
          _esEdicion ? 'Editar Actividad' : 'Registrar Actividad',
          style: const TextStyle(color: kTextoBlanco, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSeccion('Tipo de Actividad'),
              const SizedBox(height: 12),
              _buildSelectorTipo(),
              const SizedBox(height: 20),

              _buildSeccion('Intensidad'),
              const SizedBox(height: 12),
              _buildSelectorIntensidad(),
              const SizedBox(height: 20),

              _buildSeccion('Duración y Fecha'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCampoNumerico(
                      controller: _duracionCtrl,
                      label: 'Duración *',
                      hint: 'minutos',
                      icono: Icons.timer,
                      obligatorio: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildFechaPicker()),
                ],
              ),
              const SizedBox(height: 12),
              _buildHoraPicker(),
              const SizedBox(height: 20),

              _buildSeccion('Métricas de Rendimiento'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCampoNumerico(
                      controller: _caloriasCtrl,
                      label: 'Calorías (kcal)',
                      hint: 'ej: 250',
                      icono: Icons.local_fire_department,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCampoNumerico(
                      controller: _pasosCtrl,
                      label: 'Pasos',
                      hint: 'ej: 3000',
                      icono: Icons.directions_walk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCampoNumerico(
                controller: _frecuenciaCtrl,
                label: 'Frec. cardíaca promedio (bpm)',
                hint: 'ej: 120',
                icono: Icons.favorite,
              ),
              const SizedBox(height: 20),

              _buildSeccion('Glucosa Relacionada (opcional)'),
              const SizedBox(height: 4),
              const Text(
                'Registra tus niveles antes y después para ver el impacto del ejercicio',
                style: TextStyle(color: kTextoGris, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCampoNumerico(
                      controller: _glucosaPreCtrl,
                      label: 'Glucosa PRE (mg/dL)',
                      hint: 'antes',
                      icono: Icons.monitor_heart,
                      decimal: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCampoNumerico(
                      controller: _glucosaPostCtrl,
                      label: 'Glucosa POST (mg/dL)',
                      hint: 'después',
                      icono: Icons.monitor_heart_outlined,
                      decimal: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSeccion('Notas'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notasCtrl,
                maxLines: 3,
                style: const TextStyle(color: kTextoBlanco),
                decoration: _inputDecoration('¿Cómo te sentiste?', Icons.notes),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNaranja,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          _esEdicion ? 'Actualizar Actividad' : 'Guardar Actividad',
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccion(String titulo) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: kNaranja),
        const SizedBox(width: 8),
        Text(titulo,
            style: const TextStyle(
                color: kTextoBlanco, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSelectorTipo() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tipos.length,
        itemBuilder: (_, i) {
          final t = _tipos[i];
          final bool seleccionado = _tipo == t['valor'];
          final Color color = coloresTipo[t['valor']] ?? kNaranja;
          return GestureDetector(
            onTap: () => setState(() => _tipo = t['valor']),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: seleccionado ? color.withOpacity(0.2) : kBgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: seleccionado ? color : kBgInput,
                  width: seleccionado ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(t['icono'] as IconData,
                      color: seleccionado ? color : kTextoGris, size: 26),
                  const SizedBox(height: 6),
                  Text(t['label'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: seleccionado ? color : kTextoGris,
                        fontSize: 11,
                        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectorIntensidad() {
    final opciones = [
      {'valor': 'leve', 'label': 'Leve', 'color': kVerde, 'icono': Icons.battery_1_bar},
      {'valor': 'moderada', 'label': 'Moderada', 'color': kNaranja, 'icono': Icons.battery_3_bar},
      {'valor': 'intensa', 'label': 'Intensa', 'color': kRojo, 'icono': Icons.battery_full},
    ];
    return Row(
      children: opciones.map((op) {
        final bool sel = _intensidad == op['valor'];
        final Color color = op['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _intensidad = op['valor'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: sel ? color.withOpacity(0.2) : kBgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? color : kBgInput, width: sel ? 2 : 1),
              ),
              child: Column(
                children: [
                  Icon(op['icono'] as IconData, color: sel ? color : kTextoGris),
                  const SizedBox(height: 4),
                  Text(op['label'] as String,
                      style: TextStyle(
                        color: sel ? color : kTextoGris,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFechaPicker() {
    return GestureDetector(
      onTap: () async {
        final fecha = await showDatePicker(
          context: context,
          initialDate: _fecha,
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: kNaranja,
                onPrimary: Colors.black,
                surface: kBgCard,
              ),
            ),
            child: child!,
          ),
        );
        if (fecha != null) setState(() => _fecha = fecha);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBgInput,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fecha', style: TextStyle(color: kTextoGris, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: kNaranja, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${_fecha.day.toString().padLeft(2, '0')}/${_fecha.month.toString().padLeft(2, '0')}/${_fecha.year}',
                  style: const TextStyle(color: kTextoBlanco, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoraPicker() {
    return GestureDetector(
      onTap: () async {
        final hora = await showTimePicker(
          context: context,
          initialTime: _horaInicio ?? TimeOfDay.now(),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: kNaranja,
                onPrimary: Colors.black,
              ),
            ),
            child: child!,
          ),
        );
        if (hora != null) setState(() => _horaInicio = hora);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBgInput,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: kNaranja, size: 18),
            const SizedBox(width: 8),
            Text(
              _horaInicio != null
                  ? 'Hora inicio: ${_horaInicio!.format(context)}'
                  : 'Seleccionar hora de inicio (opcional)',
              style: TextStyle(
                color: _horaInicio != null ? kTextoBlanco : kTextoGris,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoNumerico({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icono,
    bool obligatorio = false,
    bool decimal = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: decimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
          : [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: kTextoBlanco),
      decoration: _inputDecoration(label, icono, hint: hint),
      validator: obligatorio
          ? (v) {
              if (v == null || v.isEmpty) return 'Campo requerido';
              if (int.tryParse(v) == null) return 'Número válido';
              if (int.parse(v) <= 0) return 'Debe ser > 0';
              return null;
            }
          : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icono, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: kTextoGris),
      hintStyle: const TextStyle(color: kBgInput),
      prefixIcon: Icon(icono, color: kNaranja, size: 20),
      filled: true,
      fillColor: kBgInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kNaranja, width: 2),
      ),
    );
  }
}
