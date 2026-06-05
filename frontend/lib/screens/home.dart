// ============================================================
// ARCHIVO: lib/screens/home.dart
// ============================================================
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/perfil_service.dart';
import '../widgets/shared_widgets.dart';
import 'app_colors.dart';
import 'usuarios/salud.dart';
import 'usuarios/perfil.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _perfil;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  // En _cargarPerfil(), modifica:
  Future<void> _cargarPerfil() async {
    setState(() => _cargando = true);
    try {
      // ✅ getPerfil() ya maneja el 401 internamente
      final perfil = await PerfilService.getPerfil();
      setState(() => _perfil = perfil);
    } catch (e) {
      print('Error cargando perfil: $e');
      if (e.toString().contains('Sesión expirada') ||
          e.toString().contains('Token inválido')) {
        await AuthService.logout();
        if (mounted) Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Método para recargar perfil después de editar
  void _recargarPerfil() {
    _cargarPerfil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'GlucoWatch',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Notificaciones
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/onboarding');
              }
            },
          ),
        ],
      ),
      body:
          _cargando
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              )
              : IndexedStack(
                index: _selectedIndex,
                children: [
                  DashboardScreen(perfil: _perfil),
                  const SaludScreen(),
                  PerfilScreen(onPerfilActualizado: _recargarPerfil),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outlined),
            activeIcon: Icon(Icons.favorite),
            label: 'Salud',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PANTALLA DASHBOARD (Principal)
// ============================================================
class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic>? perfil;

  const DashboardScreen({super.key, this.perfil});

  @override
  Widget build(BuildContext context) {
    final nombre =
        perfil?['nombre'] ?? AuthService.usuario?['nombre'] ?? 'Usuario';
    final email = perfil?['email'] ?? AuthService.usuario?['email'] ?? '';
    double? _toDouble(dynamic v) =>
        v == null ? null : (v is double ? v : double.tryParse(v.toString()));

    final imc = PerfilService.calcularIMC(
      _toDouble(perfil?['peso'] ?? AuthService.usuario?['peso']),
      _toDouble(perfil?['altura'] ?? AuthService.usuario?['altura']),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saludo
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.orange,
                child: Text(
                  nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, $nombre!',
                      style: const TextStyle(
                        color: AppColors.textPrim,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Tarjeta de glucosa
          const _GlucosaCard(),

          const SizedBox(height: 20),

          // Métricas rápidas
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'HbA1c',
                  value: perfil?['hba1c_inicial']?.toString() ?? '--',
                  unit: '%',
                  icon: Icons.science,
                  color: _getHbA1cColor(perfil?['hba1c_inicial']),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Peso',
                  value: perfil?['peso']?.toString() ?? '--',
                  unit: 'kg',
                  icon: Icons.monitor_weight,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'IMC',
                  value: imc?.toStringAsFixed(1) ?? '--',
                  unit: '',
                  icon: Icons.calculate,
                  color: AppColors.orange,
                  subtitle:
                      imc != null ? PerfilService.getCategoriaIMC(imc) : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Actividad reciente
          const Text(
            'Actividad Reciente',
            style: TextStyle(
              color: AppColors.textPrim,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _ActividadItem(
            icon: Icons.bloodtype,
            title: 'Última glucosa',
            value: '126 mg/dL',
            time: 'Hace 2 horas',
            color: AppColors.orange,
          ),
          const SizedBox(height: 8),
          _ActividadItem(
            icon: Icons.restaurant,
            title: 'Última comida',
            value: 'Desayuno',
            time: 'Hace 3 horas',
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          _ActividadItem(
            icon: Icons.fitness_center,
            title: 'Ejercicio',
            value: 'Caminata',
            time: 'Ayer',
            color: Colors.blue,
          ),

          const SizedBox(height: 24),

          // Botón rápido
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Navegar a registro de glucosa
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Registrar glucosa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getHbA1cColor(double? value) {
    if (value == null) return AppColors.textMuted;
    if (value < 5.7) return Colors.green;
    if (value < 6.5) return Colors.orange;
    return Colors.red;
  }
}

// ============================================================
// WIDGETS DASHBOARD
// ============================================================

class _GlucosaCard extends StatelessWidget {
  const _GlucosaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.orange.withOpacity(0.8),
            AppColors.orange.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Glucosa actual',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Hace 2h',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '126',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'mg/dL',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Normal',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 126 / 200,
            backgroundColor: Colors.white.withOpacity(0.3),
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('70', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                '140',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrim,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(color: AppColors.textHint, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActividadItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String time;
  final Color color;

  const _ActividadItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrim,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(color: AppColors.textHint, fontSize: 11),
          ),
        ],
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../core/theme.dart';
// import '../screens/01_registrar_medicamento.dart';
// import '../screens/02_plan_tratamiento.dart';
// import '../screens/03_recordatorios.dart';
// import '../screens/04_confirmar_toma.dart';
// import '../screens/05_historial.dart';
// import '../screens/06_analisis_glucosa.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
//     statusBarColor: Colors.transparent,
//     statusBarIconBrightness: Brightness.light,
//   ));
//   runApp(const MedicamentosApp());
// }

// class MedicamentosApp extends StatelessWidget {
//   const MedicamentosApp({super.key});

//   @override
//   Widget build(BuildContext context) => MaterialApp(
//     title: 'GlucoTrack',
//     debugShowCheckedModeBanner: false,
//     theme: AppTheme.dark,
//     home: const MainShell(),
//   );
// }

// class MainShell extends StatefulWidget {
//   const MainShell({super.key});

//   @override
//   State<MainShell> createState() => _MainShellState();
// }

// class _MainShellState extends State<MainShell> {
//   int _currentIndex = 1; // Inicia en Plan de Tratamiento

//   // ─── MIGRACIÓN FUTURA A HAMBURGUESA ────────────────────────────────────────
//   // Para migrar a Drawer/menú hamburguesa:
//   // 1. Reemplaza BottomNavigationBar con Scaffold(drawer: AppDrawer(...))
//   // 2. Mueve _navItems al AppDrawer como ListTiles
//   // 3. Elimina el parámetro bottomNavigationBar del Scaffold principal
//   // ───────────────────────────────────────────────────────────────────────────

//   final List<_NavItem> _navItems = [
//     _NavItem(icon: Icons.add_circle_outline_rounded,  label: 'Registrar'),
//     _NavItem(icon: Icons.medication_liquid_rounded,   label: 'Tratamiento'),
//     _NavItem(icon: Icons.notifications_none_rounded,  label: 'Recordatorios'),
//     _NavItem(icon: Icons.check_circle_outline_rounded,label: 'Confirmar'),
//     _NavItem(icon: Icons.history_rounded,             label: 'Historial'),
//     _NavItem(icon: Icons.insights_rounded,            label: 'Análisis'),
//   ];

//   final List<Widget> _screens = [
//     const RegistrarMedicamentoScreen(),
//     const PlanTratamientoScreen(),
//     const RecordatoriosScreen(),
//     const ConfirmarTomaScreen(),
//     const HistorialScreen(),
//     const AnalisisGlucosaScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 220),
//         switchInCurve: Curves.easeOut,
//         child: KeyedSubtree(
//           key: ValueKey(_currentIndex),
//           child: _screens[_currentIndex],
//         ),
//       ),
//       bottomNavigationBar: _AppBottomNav(
//         currentIndex: _currentIndex,
//         items: _navItems,
//         onTap: (i) => setState(() => _currentIndex = i),
//       ),
//     );
//   }
// }

// class _NavItem {
//   final IconData icon;
//   final String label;
//   const _NavItem({required this.icon, required this.label});
// }

// class _AppBottomNav extends StatelessWidget {
//   final int currentIndex;
//   final List<_NavItem> items;
//   final ValueChanged<int> onTap;

//   const _AppBottomNav({
//     required this.currentIndex,
//     required this.items,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         color: AppTheme.surface,
//         border: Border(top: BorderSide(color: AppTheme.border)),
//       ),
//       child: SafeArea(
//         child: SizedBox(
//           height: 60,
//           child: Row(
//             children: List.generate(items.length, (i) {
//               final selected = i == currentIndex;
//               return Expanded(
//                 child: GestureDetector(
//                   onTap: () => onTap(i),
//                   behavior: HitTestBehavior.opaque,
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 200),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         AnimatedContainer(
//                           duration: const Duration(milliseconds: 200),
//                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: selected ? AppTheme.accentDim : Colors.transparent,
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Icon(
//                             items[i].icon,
//                             size: 22,
//                             color: selected ? AppTheme.accent : AppTheme.textMuted,
//                           ),
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           items[i].label,
//                           style: TextStyle(
//                             fontSize: 9,
//                             color: selected ? AppTheme.accent : AppTheme.textMuted,
//                             fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             }),
//           ),
//         ),
//       ),
//     );
//   }
// }