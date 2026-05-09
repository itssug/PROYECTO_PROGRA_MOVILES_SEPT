import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme.dart';
import 'screens/01_registrar_medicamento.dart';
import 'screens/02_plan_tratamiento.dart';
import 'screens/03_recordatorios.dart';
import 'screens/04_confirmar_toma.dart';
import 'screens/05_historial.dart';
import 'screens/06_analisis_glucosa.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const MedicamentosApp());
}

class MedicamentosApp extends StatelessWidget {
  const MedicamentosApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'GlucoTrack',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: const MainShell(),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 1; // Inicia en Plan de Tratamiento

  // ─── MIGRACIÓN FUTURA A HAMBURGUESA ────────────────────────────────────────
  // Para migrar a Drawer/menú hamburguesa:
  // 1. Reemplaza BottomNavigationBar con Scaffold(drawer: AppDrawer(...))
  // 2. Mueve _navItems al AppDrawer como ListTiles
  // 3. Elimina el parámetro bottomNavigationBar del Scaffold principal
  // ───────────────────────────────────────────────────────────────────────────

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.add_circle_outline_rounded,  label: 'Registrar'),
    _NavItem(icon: Icons.medication_liquid_rounded,   label: 'Tratamiento'),
    _NavItem(icon: Icons.notifications_none_rounded,  label: 'Recordatorios'),
    _NavItem(icon: Icons.check_circle_outline_rounded,label: 'Confirmar'),
    _NavItem(icon: Icons.history_rounded,             label: 'Historial'),
    _NavItem(icon: Icons.insights_rounded,            label: 'Análisis'),
  ];

  final List<Widget> _screens = [
    const RegistrarMedicamentoScreen(),
    const PlanTratamientoScreen(),
    const RecordatoriosScreen(),
    const ConfirmarTomaScreen(),
    const HistorialScreen(),
    const AnalisisGlucosaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: _AppBottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _AppBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.accentDim : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            items[i].icon,
                            size: 22,
                            color: selected ? AppTheme.accent : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            fontSize: 9,
                            color: selected ? AppTheme.accent : AppTheme.textMuted,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}