import 'package:flutter/material.dart';
import '../core/theme.dart';

class PlanTratamientoScreen extends StatefulWidget {
  const PlanTratamientoScreen({super.key});

  @override
  State<PlanTratamientoScreen> createState() => _PlanTratamientoScreenState();
}

class _PlanTratamientoScreenState extends State<PlanTratamientoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<_Medicamento> _activos = [
    _Medicamento(
      nombre: 'Metformina',
      tipo: 'pastilla',
      dosis: '850 mg',
      frecuencia: 'Diario',
      hora: '08:00',
      relacionComida: 'después',
      activo: true,
      icono: Icons.circle,
      color: AppTheme.success,
    ),
    _Medicamento(
      nombre: 'Glibenclamida',
      tipo: 'pastilla',
      dosis: '5 mg',
      frecuencia: 'Diario',
      hora: '13:00',
      relacionComida: 'antes',
      activo: true,
      icono: Icons.circle,
      color: AppTheme.accent,
    ),
    _Medicamento(
      nombre: 'Insulina Glargina',
      tipo: 'insulina',
      dosis: '20 UI',
      frecuencia: 'Diario',
      hora: '22:00',
      relacionComida: 'independiente',
      activo: true,
      icono: Icons.circle,
      color: const Color(0xFF5E9BFF),
    ),
  ];

  final List<_Medicamento> _inactivos = [
    _Medicamento(
      nombre: 'Sitagliptina',
      tipo: 'pastilla',
      dosis: '100 mg',
      frecuencia: 'Diario',
      hora: '08:00',
      relacionComida: 'independiente',
      activo: false,
      icono: Icons.circle,
      color: AppTheme.textMuted,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan de Tratamiento'),
        actions: [
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _MedicamentosTab(medicamentos: _activos),
          _MedicamentosTab(medicamentos: _inactivos),
        ],
      ),
    );
  }
}

class _MedicamentosTab extends StatelessWidget {
  final List<_Medicamento> medicamentos;
  const _MedicamentosTab({required this.medicamentos});

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
        // ── Resumen del día
        _ResumenDia(),
        const SizedBox(height: 20),
        // ── Lista por horario
        ...medicamentos.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _MedicamentoCard(med: m),
        )),
      ],
    );
  }
}

class _ResumenDia extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentDim, AppTheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentDim),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hoy, viernes',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                SizedBox(height: 4),
                Text('3 medicamentos',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Próxima toma: 13:00 — Glibenclamida',
                    style: TextStyle(
                        color: AppTheme.accent, fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _CircularProgress(tomados: 1, total: 3),
        ],
      ),
    );
  }
}

class _CircularProgress extends StatelessWidget {
  final int tomados;
  final int total;
  const _CircularProgress({required this.tomados, required this.total});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: tomados / total,
            strokeWidth: 5,
            backgroundColor: AppTheme.border,
            valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
          ),
          Text(
            '$tomados/$total',
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MedicamentoCard extends StatelessWidget {
  final _Medicamento med;
  const _MedicamentoCard({required this.med});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {},
      child: Row(
        children: [
          // Indicador de color / tipo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: med.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_tipoIcon(med.tipo), color: med.color, size: 22),
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
                    AccentBadge(med.dosis, color: med.color),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(med.hora,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(width: 10),
                    const Icon(Icons.restaurant_rounded,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(med.relacionComida,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(width: 10),
                    Text('• ${med.frecuencia}',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12)),
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

  IconData _tipoIcon(String tipo) {
    switch (tipo) {
      case 'insulina': return Icons.vaccines_rounded;
      case 'inyectable': return Icons.vaccines_outlined;
      case 'liquido': return Icons.water_drop_outlined;
      default: return Icons.medication_rounded;
    }
  }
}

class _Medicamento {
  final String nombre, tipo, dosis, frecuencia, hora, relacionComida;
  final bool activo;
  final IconData icono;
  final Color color;

  const _Medicamento({
    required this.nombre,
    required this.tipo,
    required this.dosis,
    required this.frecuencia,
    required this.hora,
    required this.relacionComida,
    required this.activo,
    required this.icono,
    required this.color,
  });
}