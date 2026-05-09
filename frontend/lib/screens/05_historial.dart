import 'package:flutter/material.dart';
import '../core/theme.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  String _filtro = 'Todos';
  final List<String> _filtros = ['Todos', 'Tomado', 'Omitido'];

  final List<_RegistroMed> _registros = [
    _RegistroMed(medicamento: 'Metformina',    dosis: '850 mg', fecha: 'Hoy',   hora: '08:12', fueTomado: true,  notas: null),
    _RegistroMed(medicamento: 'Glibenclamida', dosis: '5 mg',   fecha: 'Hoy',   hora: '13:05', fueTomado: false, notas: 'Olvidé el medicamento en casa'),
    _RegistroMed(medicamento: 'Insulina',      dosis: '20 UI',  fecha: 'Ayer',  hora: '22:00', fueTomado: true,  notas: null),
    _RegistroMed(medicamento: 'Metformina',    dosis: '850 mg', fecha: 'Ayer',  hora: '08:03', fueTomado: true,  notas: null),
    _RegistroMed(medicamento: 'Glibenclamida', dosis: '5 mg',   fecha: 'Ayer',  hora: '13:00', fueTomado: true,  notas: null),
    _RegistroMed(medicamento: 'Insulina',      dosis: '18 UI',  fecha: '7 may', hora: '22:15', fueTomado: true,  notas: 'Dosis reducida por indicación médica'),
    _RegistroMed(medicamento: 'Metformina',    dosis: '850 mg', fecha: '7 may', hora: '08:00', fueTomado: false, notas: null),
    _RegistroMed(medicamento: 'Glibenclamida', dosis: '5 mg',   fecha: '6 may', hora: '13:00', fueTomado: true,  notas: null),
  ];

  List<_RegistroMed> get _filtrados {
    if (_filtro == 'Todos') return _registros;
    return _registros.where((r) => _filtro == 'Tomado' ? r.fueTomado : !r.fueTomado).toList();
  }

  Map<String, List<_RegistroMed>> get _agrupados {
    final result = <String, List<_RegistroMed>>{};
    for (final r in _filtrados) {
      result.putIfAbsent(r.fecha, () => []).add(r);
    }
    return result;
  }

  double get _adherencia {
    final total   = _registros.length;
    final tomados = _registros.where((r) => r.fueTomado).length;
    return total == 0 ? 0 : tomados / total;
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _agrupados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: AppTheme.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // ── Tarjeta de adherencia
          _AdherenciaCard(porcentaje: _adherencia),
          const SizedBox(height: 20),

          // ── Filtros
          _FiltroBar(
            filtros: _filtros,
            seleccionado: _filtro,
            onChanged: (f) => setState(() => _filtro = f),
          ),
          const SizedBox(height: 20),

          // ── Grupos por fecha
          for (final entry in grupos.entries) ...[
            _FechaHeader(fecha: entry.key),
            ...entry.value.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RegistroTile(reg: r),
            )),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _AdherenciaCard extends StatelessWidget {
  final double porcentaje;
  const _AdherenciaCard({required this.porcentaje});

  Color get _color {
    if (porcentaje >= 0.8) return AppTheme.success;
    if (porcentaje >= 0.6) return AppTheme.warning;
    return AppTheme.danger;
  }

  String get _label {
    if (porcentaje >= 0.8) return 'Muy buena';
    if (porcentaje >= 0.6) return 'Regular';
    return 'Baja';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.surface, AppTheme.surfaceLight.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Adherencia (últimos 7 días)',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Text('${(porcentaje * 100).round()}%',
                    style: TextStyle(
                        color: _color, fontSize: 36, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                AccentBadge(_label, color: _color),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: porcentaje,
                    minHeight: 6,
                    backgroundColor: AppTheme.border,
                    valueColor: AlwaysStoppedAnimation(_color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            children: [
              _StatItem(value: '${(_registros().where((r) => r.fueTomado).length)}', label: 'Tomados', color: AppTheme.success),
              const SizedBox(height: 12),
              _StatItem(value: '${(_registros().where((r) => !r.fueTomado).length)}', label: 'Omitidos', color: AppTheme.danger),
            ],
          ),
        ],
      ),
    );
  }

  List<_RegistroMed> _registros() => [
    _RegistroMed(medicamento: '', dosis: '', fecha: '', hora: '', fueTomado: true, notas: null),
    _RegistroMed(medicamento: '', dosis: '', fecha: '', hora: '', fueTomado: true, notas: null),
    _RegistroMed(medicamento: '', dosis: '', fecha: '', hora: '', fueTomado: true, notas: null),
    _RegistroMed(medicamento: '', dosis: '', fecha: '', hora: '', fueTomado: true, notas: null),
    _RegistroMed(medicamento: '', dosis: '', fecha: '', hora: '', fueTomado: true, notas: null),
    _RegistroMed(medicamento: '', dosis: '', fecha: '', hora: '', fueTomado: false, notas: null),
    _RegistroMed(medicamento: '', dosis: '', fecha: '', hora: '', fueTomado: false, notas: null),
  ];
}

class _StatItem extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _FiltroBar extends StatelessWidget {
  final List<String> filtros;
  final String seleccionado;
  final ValueChanged<String> onChanged;
  const _FiltroBar(
      {required this.filtros, required this.seleccionado, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: filtros.map((f) {
        final sel = f == seleccionado;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppTheme.accent : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? AppTheme.accent : AppTheme.border),
              ),
              child: Text(f,
                  style: TextStyle(
                      color: sel ? Colors.white : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FechaHeader extends StatelessWidget {
  final String fecha;
  const _FechaHeader({required this.fecha});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(fecha,
        style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3)),
  );
}

class _RegistroTile extends StatelessWidget {
  final _RegistroMed reg;
  const _RegistroTile({required this.reg});

  @override
  Widget build(BuildContext context) {
    final color  = reg.fueTomado ? AppTheme.success : AppTheme.danger;
    final icon   = reg.fueTomado ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final label  = reg.fueTomado ? 'Tomado' : 'Omitido';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reg.medicamento,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${reg.dosis} · ${reg.hora}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (reg.notas != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes_rounded,
                      size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(reg.notas!,
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RegistroMed {
  final String medicamento, dosis, fecha, hora;
  final bool fueTomado;
  final String? notas;

  const _RegistroMed({
    required this.medicamento,
    required this.dosis,
    required this.fecha,
    required this.hora,
    required this.fueTomado,
    required this.notas,
  });
}