import 'package:flutter/material.dart';
import '../core/theme.dart';

class RegistrarMedicamentoScreen extends StatefulWidget {
  const RegistrarMedicamentoScreen({super.key});

  @override
  State<RegistrarMedicamentoScreen> createState() =>
      _RegistrarMedicamentoScreenState();
}

class _RegistrarMedicamentoScreenState
    extends State<RegistrarMedicamentoScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _tipoSeleccionado;
  String? _frecuenciaSeleccionada;
  String? _relacionComidaSeleccionada;
  String? _unidadSeleccionada;
  TimeOfDay? _horaToma;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _activo = true;

  final _nombreCtrl   = TextEditingController();
  final _dosisCtrl    = TextEditingController();
  final _notasCtrl    = TextEditingController();

  static const _tipos = ['insulina', 'pastilla', 'inyectable', 'liquido', 'otro'];
  static const _frecuencias = ['diario', 'semanal', 'mensual', 'condicional'];
  static const _relacionComida = ['antes', 'durante', 'después', 'independiente'];
  static const _unidades = ['mg', 'ml', 'UI'];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _dosisCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _horaToma ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accent,
            surface: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _horaToma = t);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accent,
            surface: AppTheme.surface,
            onSurface: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) {
      setState(() {
        if (isStart) _fechaInicio = d;
        else _fechaFin = d;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Medicamento'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Guardar',
              style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // ── Hero info card
            _HeroInputCard(
              nombreCtrl: _nombreCtrl,
              tipoSeleccionado: _tipoSeleccionado,
              tipos: _tipos,
              onTipoChanged: (v) => setState(() => _tipoSeleccionado = v),
            ),
            const SizedBox(height: 20),

            // ── Dosificación
            const SectionLabel('Dosificación'),
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _FieldItem(
                          label: 'Dosis',
                          child: TextFormField(
                            controller: _dosisCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(hintText: '500'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FieldItem(
                          label: 'Unidad',
                          child: _DropdownField(
                            hint: 'mg',
                            value: _unidadSeleccionada,
                            items: _unidades,
                            onChanged: (v) => setState(() => _unidadSeleccionada = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Divider(),
                  const SizedBox(height: 16),
                  _FieldItem(
                    label: 'Frecuencia',
                    child: _DropdownField(
                      hint: 'Seleccionar frecuencia',
                      value: _frecuenciaSeleccionada,
                      items: _frecuencias,
                      onChanged: (v) => setState(() => _frecuenciaSeleccionada = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Horario
            const SectionLabel('Horario'),
            AppCard(
              child: Column(
                children: [
                  _TapField(
                    label: 'Hora de toma',
                    value: _horaToma != null
                        ? _horaToma!.format(context)
                        : 'Seleccionar hora',
                    icon: Icons.access_time_rounded,
                    onTap: _pickTime,
                    hasValue: _horaToma != null,
                  ),
                  _Divider(),
                  _FieldItem(
                    label: 'Relación con comida',
                    child: _DropdownField(
                      hint: 'Cuándo tomarlo',
                      value: _relacionComidaSeleccionada,
                      items: _relacionComida,
                      onChanged: (v) => setState(() => _relacionComidaSeleccionada = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Vigencia
            const SectionLabel('Vigencia del tratamiento'),
            AppCard(
              child: Column(
                children: [
                  _TapField(
                    label: 'Fecha inicio',
                    value: _fechaInicio != null
                        ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'
                        : 'Seleccionar fecha',
                    icon: Icons.calendar_today_rounded,
                    onTap: () => _pickDate(isStart: true),
                    hasValue: _fechaInicio != null,
                  ),
                  _Divider(),
                  _TapField(
                    label: 'Fecha fin (opcional)',
                    value: _fechaFin != null
                        ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'
                        : 'Sin fecha de fin',
                    icon: Icons.event_rounded,
                    onTap: () => _pickDate(isStart: false),
                    hasValue: _fechaFin != null,
                  ),
                  _Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tratamiento activo',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                      ),
                      Switch(
                        value: _activo,
                        onChanged: (v) => setState(() => _activo = v),
                        activeColor: AppTheme.accent,
                        inactiveThumbColor: AppTheme.textMuted,
                        inactiveTrackColor: AppTheme.surfaceLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Notas
            const SectionLabel('Notas'),
            AppCard(
              child: TextFormField(
                controller: _notasCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Instrucciones adicionales del médico...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Agregar al Plan de Tratamiento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets internos de la pantalla ──────────────────────────────────────────

class _HeroInputCard extends StatelessWidget {
  final TextEditingController nombreCtrl;
  final String? tipoSeleccionado;
  final List<String> tipos;
  final ValueChanged<String?> onTipoChanged;

  const _HeroInputCard({
    required this.nombreCtrl,
    required this.tipoSeleccionado,
    required this.tipos,
    required this.onTipoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.surface, Color(0xFF1F1A14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accentDim,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medication_rounded,
                    color: AppTheme.accent, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Medicamento',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11,
                            fontWeight: FontWeight.w500, letterSpacing: 0.8)),
                    SizedBox(height: 2),
                    Text('Información básica',
                        style: TextStyle(
                            color: AppTheme.textPrimary, fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: nombreCtrl,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              hintText: 'Nombre del medicamento',
              prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          // Chips de tipo
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tipos.map((t) {
              final selected = t == tipoSeleccionado;
              return GestureDetector(
                onTap: () => onTipoChanged(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.accent : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppTheme.accent : AppTheme.border,
                    ),
                  ),
                  child: Text(
                    t[0].toUpperCase() + t.substring(1),
                    style: TextStyle(
                      color: selected ? Colors.white : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FieldItem extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldItem({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class _DropdownField extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _DropdownField(
      {required this.hint, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
      dropdownColor: AppTheme.surfaceLight,
      icon: const Icon(Icons.expand_more_rounded, color: AppTheme.textMuted),
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: const InputDecoration(),
      items: items
          .map((i) => DropdownMenuItem(
                value: i,
                child: Text(i[0].toUpperCase() + i.substring(1)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _TapField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasValue;
  const _TapField(
      {required this.label,
      required this.value,
      required this.icon,
      required this.onTap,
      required this.hasValue});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: hasValue ? AppTheme.accent : AppTheme.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                        color: hasValue ? AppTheme.textPrimary : AppTheme.textMuted,
                        fontSize: 14,
                        fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                      )),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(color: AppTheme.border, height: 1);
}