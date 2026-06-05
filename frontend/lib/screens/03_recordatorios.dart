import 'package:flutter/material.dart';
import '../core/theme.dart';

class RecordatoriosScreen extends StatefulWidget {
  const RecordatoriosScreen({super.key});

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen> {
  final List<_Recordatorio> _recordatorios = [
    _Recordatorio(
      medicamento: 'Metformina',
      dosis: '850 mg',
      hora: '08:00',
      estado: _Estado.tomado,
      relacionComida: 'después del desayuno',
      esHoy: true,
      tipo: 'pastilla',
    ),
    _Recordatorio(
      medicamento: 'Glibenclamida',
      dosis: '5 mg',
      hora: '13:00',
      estado: _Estado.pendiente,
      relacionComida: 'antes del almuerzo',
      esHoy: true,
      tipo: 'pastilla',
    ),
    _Recordatorio(
      medicamento: 'Insulina Glargina',
      dosis: '20 UI',
      hora: '22:00',
      estado: _Estado.proximo,
      relacionComida: 'independiente',
      esHoy: true,
      tipo: 'insulina',
    ),
    _Recordatorio(
      medicamento: 'Metformina',
      dosis: '850 mg',
      hora: '08:00',
      estado: _Estado.omitido,
      relacionComida: 'después del desayuno',
      esHoy: false,
      tipo: 'pastilla',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final hoy    = _recordatorios.where((r) => r.esHoy).toList();
    final pasado = _recordatorios.where((r) => !r.esHoy).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentDim,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_active_rounded,
                    size: 14, color: AppTheme.accent),
                SizedBox(width: 4),
                Text('2 pendientes',
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // ── Timeline banner
          _TimelineBanner(),
          const SizedBox(height: 24),

          // ── Hoy
          const SectionLabel('Hoy'),
          ...hoy.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RecordatorioTile(
              rec: r,
              onConfirmar: () => setState(() => r.estado == _Estado.pendiente
                  ? null
                  : null),
            ),
          )),
          const SizedBox(height: 20),

          // ── Anteriores
          const SectionLabel('Ayer'),
          ...pasado.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RecordatorioTile(rec: r),
          )),
        ],
      ),
    );
  }
}

class _TimelineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final turnos = [
      ('Mañana',  '08:00', true,  AppTheme.success),
      ('Tarde',   '13:00', false, AppTheme.accent),
      ('Noche',   '22:00', false, const Color(0xFF5E9BFF)),
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
                return Expanded(
                  child: Container(
                    height: 2,
                    color: AppTheme.border,
                  ),
                );
              }
              final t = turnos[i ~/ 2];
              return _TurnoNode(
                label: t.$1,
                hora: t.$2,
                done: t.$3,
                color: t.$4,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TurnoNode extends StatelessWidget {
  final String label, hora;
  final bool done;
  final Color color;
  const _TurnoNode(
      {required this.label,
      required this.hora,
      required this.done,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
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
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 10,
                fontWeight: FontWeight.w500)),
        Text(hora,
            style: TextStyle(
                color: done ? color : AppTheme.textMuted, fontSize: 10)),
      ],
    );
  }
}

class _RecordatorioTile extends StatelessWidget {
  final _Recordatorio rec;
  final VoidCallback? onConfirmar;
  const _RecordatorioTile({required this.rec, this.onConfirmar});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = _estadoInfo(rec.estado);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rec.estado == _Estado.pendiente
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(_tipoIcon(rec.tipo), color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec.medicamento,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text('${rec.dosis} · ${rec.hora} · ${rec.relacionComida}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
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
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (rec.estado == _Estado.pendiente) ...[
            Divider(color: AppTheme.border, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
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
                      onPressed: () {},
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

  (Color, IconData, String) _estadoInfo(_Estado e) {
    switch (e) {
      case _Estado.tomado:  return (AppTheme.success, Icons.check_circle_rounded, 'Tomado');
      case _Estado.pendiente: return (AppTheme.accent, Icons.access_time_rounded, 'Pendiente');
      case _Estado.proximo: return (const Color(0xFF5E9BFF), Icons.schedule_rounded, 'Próximo');
      case _Estado.omitido: return (AppTheme.danger, Icons.cancel_rounded, 'Omitido');
    }
  }

  IconData _tipoIcon(String tipo) {
    switch (tipo) {
      case 'insulina': return Icons.vaccines_rounded;
      default: return Icons.medication_rounded;
    }
  }
}

enum _Estado { tomado, pendiente, proximo, omitido }

class _Recordatorio {
  final String medicamento, dosis, hora, relacionComida, tipo;
  _Estado estado;
  final bool esHoy;

  _Recordatorio({
    required this.medicamento,
    required this.dosis,
    required this.hora,
    required this.estado,
    required this.relacionComida,
    required this.esHoy,
    required this.tipo,
  });
}