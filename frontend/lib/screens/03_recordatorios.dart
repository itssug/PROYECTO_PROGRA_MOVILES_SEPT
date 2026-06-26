import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/medicamento_model.dart';
import '../models/registro_model.dart';
import '../services/medicamento_service.dart';
import '../services/registro_service.dart';
import '04_confirmar_toma.dart';

class RecordatoriosScreen extends StatefulWidget {
  const RecordatoriosScreen({super.key});

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen> {
  bool _cargando = true;
  String? _error;

  List<Medicamento> _medicamentos   = [];
  List<RegistroMedicamento> _registrosHoy = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });

    // Cargamos en paralelo — más rápido
    final results = await Future.wait([
      MedicamentoService.listarActivos(),
      RegistroService.hoy(),
    ]);

    if (!mounted) return;

    final resMeds     = results[0] as ServiceResult<List<Medicamento>>;
    final resRegistros = results[1] as ServiceResult<List<RegistroMedicamento>>;

    if (resMeds.success && resRegistros.success) {
      setState(() {
        _medicamentos    = resMeds.data!;
        _registrosHoy    = resRegistros.data!;
        _cargando        = false;
      });
    } else {
      setState(() {
        _error    = resMeds.error ?? resRegistros.error;
        _cargando = false;
      });
    }
  }

  // Calcula el estado de cada medicamento cruzando con registros de hoy
  _Estado _calcularEstado(Medicamento med) {
    final reg = _registrosHoy
        .where((r) => r.medicamentoId == med.id)
        .toList();

    if (reg.isEmpty) {
      // Sin registro → pendiente o próximo según la hora
      if (med.horaToma == null) return _Estado.pendiente;
      final parts  = med.horaToma!.split(':');
      final medMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final ahora  = TimeOfDay.now();
      final ahoraMin = ahora.hour * 60 + ahora.minute;
      return medMin > ahoraMin ? _Estado.proximo : _Estado.pendiente;
    }

    final ultimo = reg.last;
    if (ultimo.fueTomado == 1) return _Estado.tomado;
    return _Estado.omitido;
  }

  int get _pendientesCount => _medicamentos
      .where((m) => _calcularEstado(m) == _Estado.pendiente)
      .length;

  Future<void> _confirmarToma(Medicamento med, bool tomado) async {
    final result = await RegistroService.confirmarToma(
      medicamentoId: med.id!,
      fueTomado: tomado,
      dosisTomada: med.dosis != null ? double.tryParse(med.dosis!) : null,
    );
    if (!mounted) return;
    if (result.success) {
      _cargar(); // recarga para reflejar el nuevo estado
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Error al registrar'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        actions: [
          if (!_cargando && _error == null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentDim,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      size: 14, color: AppTheme.accent),
                  const SizedBox(width: 4),
                  Text('$_pendientesCount pendiente${_pendientesCount != 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? _ErrorView(mensaje: _error!, onRetry: _cargar)
              : _medicamentos.isEmpty
                  ? const _EmptyView()
                  : _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        _TimelineBanner(medicamentos: _medicamentos, calcularEstado: _calcularEstado),
        const SizedBox(height: 24),
        const SectionLabel('Hoy'),
        ..._medicamentos.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _RecordatorioTile(
            med: m,
            estado: _calcularEstado(m),
            onConfirmar: () => _confirmarToma(m, true),
            onOmitir:    () => _confirmarToma(m, false),
          ),
        )),
      ],
    );
  }
}

// ── Timeline ──────────────────────────────────────────────────────────────────

class _TimelineBanner extends StatelessWidget {
  final List<Medicamento> medicamentos;
  final _Estado Function(Medicamento) calcularEstado;
  const _TimelineBanner({required this.medicamentos, required this.calcularEstado});

  @override
  Widget build(BuildContext context) {
    // Agrupa por turno según hora_toma
    final manana = medicamentos.where((m) => _turno(m) == 'Mañana').toList();
    final tarde  = medicamentos.where((m) => _turno(m) == 'Tarde').toList();
    final noche  = medicamentos.where((m) => _turno(m) == 'Noche').toList();

    final turnos = [
      (
        'Mañana', manana,
        _todosTomados(manana) ? AppTheme.success : AppTheme.accent,
        _todosTomados(manana),
      ),
      (
        'Tarde', tarde,
        _todosTomados(tarde) ? AppTheme.success : AppTheme.accent,
        _todosTomados(tarde),
      ),
      (
        'Noche', noche,
        const Color(0xFF5E9BFF),
        _todosTomados(noche),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Horario del día',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 14),
          Row(
            children: List.generate(turnos.length * 2 - 1, (i) {
              if (i.isOdd) {
                return Expanded(child: Container(height: 2, color: AppTheme.border));
              }
              final t = turnos[i ~/ 2];
              return _TurnoNode(
                label: t.$1,
                count: t.$2.length,
                done: t.$4,
                color: t.$3,
              );
            }),
          ),
        ],
      ),
    );
  }

  String _turno(Medicamento m) {
    if (m.horaToma == null) return 'Mañana';
    final h = int.tryParse(m.horaToma!.split(':')[0]) ?? 0;
    if (h < 12) return 'Mañana';
    if (h < 19) return 'Tarde';
    return 'Noche';
  }

  bool _todosTomados(List<Medicamento> meds) {
    if (meds.isEmpty) return false;
    return meds.every((m) => calcularEstado(m) == _Estado.tomado);
  }
}

class _TurnoNode extends StatelessWidget {
  final String label;
  final int count;
  final bool done;
  final Color color;
  const _TurnoNode({required this.label, required this.count, required this.done, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? color : AppTheme.surfaceLight,
            border: Border.all(color: color, width: done ? 0 : 1.5),
          ),
          child: Icon(
            done ? Icons.check_rounded : Icons.access_time_rounded,
            size: 18,
            color: done ? Colors.white : color,
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
        Text(count == 0 ? '—' : '$count med.',
            style: TextStyle(color: done ? color : AppTheme.textMuted, fontSize: 10)),
      ],
    );
  }
}

// ── Tile de recordatorio ──────────────────────────────────────────────────────

class _RecordatorioTile extends StatelessWidget {
  final Medicamento med;
  final _Estado estado;
  final VoidCallback onConfirmar;
  final VoidCallback onOmitir;

  const _RecordatorioTile({
    required this.med,
    required this.estado,
    required this.onConfirmar,
    required this.onOmitir,
  });

  (Color, IconData, String) get _estadoInfo {
    switch (estado) {
      case _Estado.tomado:   return (AppTheme.success,              Icons.check_circle_rounded, 'Tomado');
      case _Estado.pendiente:return (AppTheme.accent,               Icons.access_time_rounded,  'Pendiente');
      case _Estado.proximo:  return (const Color(0xFF5E9BFF),       Icons.schedule_rounded,     'Próximo');
      case _Estado.omitido:  return (AppTheme.danger,               Icons.cancel_rounded,       'Omitido');
    }
  }

  IconData get _tipoIcon {
    switch (med.tipo) {
      case 'insulina':   return Icons.vaccines_rounded;
      case 'inyectable': return Icons.vaccines_outlined;
      case 'liquido':    return Icons.water_drop_outlined;
      default:           return Icons.medication_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = _estadoInfo;
    final dosisLabel = med.dosis != null && med.unidad != null
        ? '${med.dosis} ${med.unidad}'
        : med.dosis ?? '—';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: estado == _Estado.pendiente
              ? AppTheme.accent.withOpacity(0.4)
              : AppTheme.border,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(_tipoIcon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.nombre,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(
                        '$dosisLabel · ${med.horaFormateada}'
                        '${med.relacionComida != null ? ' · ${med.relacionComida}' : ''}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(label,
                          style: TextStyle(
                              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (estado == _Estado.pendiente) ...[
            const Divider(color: AppTheme.border, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOmitir,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Omitir'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.border),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final cambio = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConfirmarTomaScreen(medicamento: med),
                          ),
                        );
                        if (cambio == true) onConfirmar();
                      },
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Confirmar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
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

// ── Auxiliares ────────────────────────────────────────────────────────────────

enum _Estado { tomado, pendiente, proximo, omitido }

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.medication_outlined, size: 56, color: AppTheme.textMuted),
        SizedBox(height: 16),
        Text('Sin medicamentos activos',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorView({required this.mensaje, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}