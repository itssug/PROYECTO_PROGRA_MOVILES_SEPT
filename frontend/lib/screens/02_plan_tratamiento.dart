import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/medicamento_model.dart';
import '../services/medicamento_service.dart';

class PlanTratamientoScreen extends StatefulWidget {
  const PlanTratamientoScreen({super.key});

  @override
  State<PlanTratamientoScreen> createState() => _PlanTratamientoScreenState();
}

class _PlanTratamientoScreenState extends State<PlanTratamientoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Estado real ───────────────────────────────────────────────────────────
  bool _cargando = true;
  String? _error;
  List<Medicamento> _activos   = [];
  List<Medicamento> _inactivos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });

    final result = await MedicamentoService.listar();

    if (!mounted) return;

    if (result.success) {
      final todos = result.data!;
      setState(() {
        _activos   = todos.where((m) => m.estaActivo).toList();
        _inactivos = todos.where((m) => !m.estaActivo).toList();
        _cargando  = false;
      });
    } else {
      setState(() { _error = result.error; _cargando = false; });
    }
  }

  Future<void> _eliminarMedicamento(Medicamento med) async {
    if (med.id == null) return;
    final result = await MedicamentoService.eliminar(med.id!);
    if (result.success) {
      _cargar();
    } else {
      setState(() => _error = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan de Tratamiento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: _cargar,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.accent),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              tabs: const [Tab(text: 'Activos'), Tab(text: 'Inactivos')],
            ),
          ),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _error != null
              ? _ErrorView(mensaje: _error!, onRetry: _cargar)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _MedicamentosTab(medicamentos: _activos, onEliminar: _eliminarMedicamento),
                    _MedicamentosTab(medicamentos: _inactivos, onEliminar: _eliminarMedicamento),
                  ],
                ),
    );
  }
}

// ── Tab ───────────────────────────────────────────────────────────────────────

class _MedicamentosTab extends StatelessWidget {
  final List<Medicamento> medicamentos;
  final Function(Medicamento) onEliminar;
  const _MedicamentosTab({required this.medicamentos, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    if (medicamentos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 56, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text('Sin medicamentos',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        _ResumenDia(medicamentos: medicamentos),
        const SizedBox(height: 20),
        ...medicamentos.map((m) => Dismissible(
          key: Key(m.id.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          ),
          onDismissed: (_) => onEliminar(m),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MedicamentoCard(med: m),
          ),
        )),
      ],
    );
  }
}

// ── Resumen del día ───────────────────────────────────────────────────────────

class _ResumenDia extends StatelessWidget {
  final List<Medicamento> medicamentos;
  const _ResumenDia({required this.medicamentos});

  // Próxima toma: el medicamento con hora_toma más cercana a ahora
  Medicamento? _proximaToma() {
    final ahora = TimeOfDay.now();
    final ahoraMin = ahora.hour * 60 + ahora.minute;

    Medicamento? proximo;
    int? menorDif;

    for (final m in medicamentos) {
      if (m.horaToma == null) continue;
      final parts = m.horaToma!.split(':');
      if (parts.length < 2) continue;
      final medMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final dif = medMin - ahoraMin;
      if (dif > 0 && (menorDif == null || dif < menorDif)) {
        menorDif = dif;
        proximo  = m;
      }
    }
    return proximo;
  }

  @override
  Widget build(BuildContext context) {
    final proximo   = _proximaToma();
    final diasSemana = ['lunes','martes','miércoles','jueves','viernes','sábado','domingo'];
    final hoy = diasSemana[DateTime.now().weekday - 1];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accentDim, AppTheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentDim),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hoy, $hoy',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${medicamentos.length} medicamento${medicamentos.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  proximo != null
                      ? 'Próxima toma: ${proximo.horaFormateada} — ${proximo.nombre}'
                      : 'Sin tomas pendientes hoy',
                  style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          _CircularProgress(total: medicamentos.length),
        ],
      ),
    );
  }
}

class _CircularProgress extends StatelessWidget {
  final int total;
  const _CircularProgress({required this.total});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: total == 0 ? 0 : 1,
            strokeWidth: 5,
            backgroundColor: AppTheme.border,
            valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
          ),
          Text(
            '$total',
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── Card de medicamento ───────────────────────────────────────────────────────

class _MedicamentoCard extends StatelessWidget {
  final Medicamento med;
  const _MedicamentoCard({required this.med});

  Color get _color {
    switch (med.tipo) {
      case 'insulina':    return const Color(0xFF5E9BFF);
      case 'inyectable':  return const Color(0xFFB06BFF);
      case 'liquido':     return AppTheme.success;
      default:            return AppTheme.accent;
    }
  }

  IconData get _icon {
    switch (med.tipo) {
      case 'insulina':   return Icons.vaccines_rounded;
      case 'inyectable': return Icons.vaccines_outlined;
      case 'liquido':    return Icons.water_drop_outlined;
      default:           return Icons.medication_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dosisLabel = med.dosis != null && med.unidad != null
        ? '${med.dosis} ${med.unidad}'
        : med.dosis ?? '—';

    return AppCard(
      onTap: () {},
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(med.nombre,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                    AccentBadge(dosisLabel, color: _color),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(med.horaFormateada,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    if (med.relacionComida != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.restaurant_rounded,
                          size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(med.relacionComida!,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                    if (med.frecuencia != null) ...[
                      const SizedBox(width: 10),
                      Text('• ${med.frecuencia}',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: AppTheme.textMuted, size: 18),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorView({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
}