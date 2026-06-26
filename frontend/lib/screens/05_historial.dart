import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/registro_model.dart';
import '../services/registro_service.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  String _filtro = 'Todos';
  final List<String> _filtros = ['Todos', 'Tomado', 'Omitido'];

  List<RegistroMedicamento> _registros = [];
  Adherencia? _adherencia;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() { _cargando = true; _error = null; });

    final resHistorial  = await RegistroService.historial();
    final resAdherencia = await RegistroService.adherencia();

    if (!mounted) return;

    if (resHistorial.success) {
      setState(() {
        _registros  = resHistorial.data ?? [];
        _adherencia = resAdherencia.data; // puede ser null si falla, no es crítico
        _cargando   = false;
      });
    } else {
      setState(() {
        _error    = resHistorial.error;
        _cargando = false;
      });
    }
  }

  List<RegistroMedicamento> get _filtrados {
    if (_filtro == 'Todos') return _registros;
    return _registros.where((r) =>
        _filtro == 'Tomado' ? r.fueTomado == 1 : r.fueTomado == 0
    ).toList();
  }

  /// Agrupa por fecha "YYYY-MM-DD" y devuelve label legible
  Map<String, List<RegistroMedicamento>> get _agrupados {
    final hoy  = _fechaStr(DateTime.now());
    final ayer = _fechaStr(DateTime.now().subtract(const Duration(days: 1)));

    final result = <String, List<RegistroMedicamento>>{};
    for (final r in _filtrados) {
      final label = r.fecha == hoy
          ? 'Hoy'
          : r.fecha == ayer
              ? 'Ayer'
              : _formatearFecha(r.fecha);
      result.putIfAbsent(label, () => []).add(r);
    }
    return result;
  }

  String _fechaStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatearFecha(String fecha) {
    // "YYYY-MM-DD" → "DD/MM"
    try {
      final parts = fecha.split('-');
      return '${parts[2]}/${parts[1]}';
    } catch (_) {
      return fecha;
    }
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

    final grupos = _agrupados;

    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: _cargarDatos,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // ── Tarjeta de adherencia
          _AdherenciaCard(adherencia: _adherencia),
          const SizedBox(height: 20),

          // ── Filtros
          _FiltroBar(
            filtros:      _filtros,
            seleccionado: _filtro,
            onChanged:    (f) => setState(() => _filtro = f),
          ),
          const SizedBox(height: 20),

          if (_filtrados.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text('Sin registros',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
              ),
            )
          else
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

// ── Widgets ───────────────────────────────────────────────────────────────────

class _AdherenciaCard extends StatelessWidget {
  final Adherencia? adherencia;
  const _AdherenciaCard({required this.adherencia});

  double get _porcentaje =>
      adherencia != null ? adherencia!.porcentaje / 100 : 0;

  Color get _color {
    if (_porcentaje >= 0.8) return AppTheme.success;
    if (_porcentaje >= 0.6) return AppTheme.warning;
    return AppTheme.danger;
  }

  String get _label {
    if (_porcentaje >= 0.8) return 'Muy buena';
    if (_porcentaje >= 0.6) return 'Regular';
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
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Text('${((_porcentaje) * 100).round()}%',
                    style: TextStyle(
                        color:      _color,
                        fontSize:   36,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                AccentBadge(_label, color: _color),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value:           _porcentaje,
                    minHeight:       6,
                    backgroundColor: AppTheme.border,
                    valueColor:      AlwaysStoppedAnimation(_color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            children: [
              _StatItem(
                value: '${adherencia?.tomados ?? 0}',
                label: 'Tomados',
                color: AppTheme.success,
              ),
              const SizedBox(height: 12),
              _StatItem(
                value: '${adherencia?.omitidos ?? 0}',
                label: 'Omitidos',
                color: AppTheme.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatItem(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(
                color:      AppTheme.textMuted,
                fontSize:   11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _FiltroBar extends StatelessWidget {
  final List<String> filtros;
  final String seleccionado;
  final ValueChanged<String> onChanged;
  const _FiltroBar(
      {required this.filtros,
      required this.seleccionado,
      required this.onChanged});

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:        sel ? AppTheme.accent : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? AppTheme.accent : AppTheme.border),
              ),
              child: Text(f,
                  style: TextStyle(
                      color:      sel ? Colors.white : AppTheme.textSecondary,
                      fontSize:   13,
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
                color:         AppTheme.textSecondary,
                fontSize:      13,
                fontWeight:    FontWeight.w600,
                letterSpacing: 0.3)),
      );
}

class _RegistroTile extends StatelessWidget {
  final RegistroMedicamento reg;
  const _RegistroTile({required this.reg});

  @override
  Widget build(BuildContext context) {
    final tomado = reg.fueTomado == 1;
    final color  = tomado ? AppTheme.success : AppTheme.danger;
    final icon   = tomado ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final label  = tomado ? 'Tomado' : 'Omitido';

    // hora "HH:MM:SS" → "HH:MM"
    final hora = reg.hora.length >= 5 ? reg.hora.substring(0, 5) : reg.hora;

    // dosis tomada
    final dosis = reg.dosisTomada != null ? '${reg.dosisTomada}' : '--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: AppTheme.border),
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
                    Text('Medicamento #${reg.medicamentoId}',
                        style: const TextStyle(
                            color:      AppTheme.textPrimary,
                            fontSize:   14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('$dosis · $hora',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label,
                    style: TextStyle(
                        color:      color,
                        fontSize:   11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (reg.notas != null && reg.notas!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding:    const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        AppTheme.surfaceLight,
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
                            color:      AppTheme.textSecondary,
                            fontSize:   12,
                            fontStyle:  FontStyle.italic)),
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