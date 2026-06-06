import 'package:flutter/material.dart';
import '../core/theme.dart';
import '01_registrar_medicamento.dart';
import '02_plan_tratamiento.dart';
import '03_recordatorios.dart';
import '04_confirmar_toma.dart';
import '05_historial.dart';
import '06_analisis_glucosa.dart';

class MedicamentosMainScreen extends StatelessWidget {
  const MedicamentosMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      initialIndex: 1, // Start at Tratamiento as originally intended by Danil
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppTheme.surface,
          elevation: 0,
          title: const Text(
            'Glucosa y Medicamentos',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppTheme.accent,
            labelColor: AppTheme.accent,
            unselectedLabelColor: AppTheme.textMuted,
            tabs: [
              Tab(icon: Icon(Icons.add_circle_outline_rounded), text: 'Registrar'),
              Tab(icon: Icon(Icons.medication_liquid_rounded), text: 'Tratamiento'),
              Tab(icon: Icon(Icons.notifications_none_rounded), text: 'Recordatorios'),
              Tab(icon: Icon(Icons.check_circle_outline_rounded), text: 'Confirmar'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Historial'),
              Tab(icon: Icon(Icons.insights_rounded), text: 'Análisis'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RegistrarMedicamentoScreen(),
            PlanTratamientoScreen(),
            RecordatoriosScreen(),
            ConfirmarTomaScreen(),
            HistorialScreen(),
            AnalisisGlucosaScreen(),
          ],
        ),
      ),
    );
  }
}
