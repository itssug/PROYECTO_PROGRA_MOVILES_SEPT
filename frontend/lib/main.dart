// ============================================================
// ARCHIVO: lib/main.dart
// ============================================================
/*GISELLE MAIN.DART
import 'package:flutter/material.dart';
import 'services/api_service.dart';
// Ajusta esta ruta según tu estructura de carpetas:
import 'features/estado_sueno/screens/estado_sueno_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String mensaje = "Cargando...";

  @override
  void initState() {
    super.initState();
    obtenerDatos();
  }

  Future<void> obtenerDatos() async {
    try {
      final res = await ApiService.test();
      setState(() => mensaje = res);
    } catch (e) {
      setState(() => mensaje = "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text("Inicio",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Estado de conexión
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      mensaje.contains("Error") ? Icons.error : Icons.check_circle,
                      color: mensaje.contains("Error")
                          ? const Color(0xFFE24B4A)
                          : const Color(0xFF5DCAA5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(mensaje,
                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Botón para tu módulo
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.mood),
                  label: const Text('Estado Emocional y Sueño',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Cambia el usuarioId por uno que exista en tu BD
                      builder: (_) => const EstadoSuenoScreen(usuarioId: 1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}*/


// ============================================================
// ARCHIVO: lib/main.dart KATERIN
// ============================================================

// import 'package:flutter/material.dart';
// import 'screens/actividad_fisica/actividad_fisica_screen.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Glucosa App - Diabetes Tipo II',
//       theme: ThemeData(
//         brightness: Brightness.dark,
//         primaryColor: const Color(0xFFFF6B00),
//         scaffoldBackgroundColor: const Color(0xFF121212),
//       ),
//       home: const ActividadFisicaScreen(),
//     );
//   }
// }






// ============================================================
// ARCHIVO: lib/main.dart
// ============================================================
/*DANIL MAIN.DART
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
      home: hasSession ? const HomeScreen() : const PrincipalScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const PrincipalScreen());
          default:
            return null;
        }
      },
    );
  }
}*/ 

// ============================================================
// ARCHIVO: lib/main.dart PATI
// ============================================================
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/home.dart';
import 'screens/inicio/Principal_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final hasSession = await AuthService.init();
  
  runApp(MyApp(hasSession: hasSession));
}

class MyApp extends StatelessWidget {
  final bool hasSession;
  
  const MyApp({super.key, required this.hasSession});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GlucoWatch',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.bg,
      ),
      home: hasSession ? const HomeScreen() : const PrincipalScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const PrincipalScreen());
          default:
            return null;
        }
      },
    );
  }
}
