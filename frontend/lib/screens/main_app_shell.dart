import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/perfil_service.dart';
import 'app_colors.dart';

import 'dashboard_screen.dart';
import 'medicamentos_main_screen.dart';
import 'alimentacion/alimentacion_main_screen.dart';
import 'actividad_fisica/actividad_fisica_screen.dart';
import '../features/estado_sueno/screens/estado_sueno_screen.dart';
import '../features/ai_module/screens/ai_prediction_screen.dart';
import 'usuarios/salud.dart';
import 'usuarios/perfil.dart';
import 'chat_screen.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _perfil;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() => _cargando = true);
    try {
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

  void _recargarPerfil() {
    _cargarPerfil();
  }

  void _openAiScreen(BuildContext context) {
    final userId = AuthService.usuario?['id'] ?? 14;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiPredictionScreen(
          userId: userId,
          contextData: {
            // Datos conocidos del usuario
            // En producción vendrán del último registro
            'glucosa_antes': _perfil?['glucosa_actual'] ?? 126.0,
            'horas_sueno': 7.0,
            'estres': 2,
            'ejercicio': 30.0,
          },
        ),
      ),
    );
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
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : IndexedStack(
              index: _selectedIndex,
              children: [
                DashboardScreen(perfil: _perfil),
                const MedicamentosMainScreen(),
                const AlimentacionMainScreen(),
                const ActividadFisicaScreen(),
                const ChatScreen(),
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
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: 'Glucosa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_outlined),
            activeIcon: Icon(Icons.restaurant),
            label: 'Dieta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: 'Actividad',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final nombre = _perfil?['nombre'] ?? AuthService.usuario?['nombre'] ?? 'Usuario';
    final email = _perfil?['email'] ?? AuthService.usuario?['email'] ?? '';

    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.bg,
            ),
            accountName: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.orange,
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  text: 'Inicio / Dashboard',
                  onTap: () {
                    setState(() => _selectedIndex = 0);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.medical_services,
                  text: 'Glucosa y Medicamentos',
                  onTap: () {
                    setState(() => _selectedIndex = 1);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.restaurant,
                  text: 'Alimentación y Nutrición',
                  onTap: () {
                    setState(() => _selectedIndex = 2);
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.fitness_center,
                  text: 'Actividad Física',
                  onTap: () {
                    setState(() => _selectedIndex = 3);
                    Navigator.pop(context);
                  },
                ),
                const Divider(color: AppColors.border),
                // ── Motor de IA
                _buildDrawerItemHighlighted(
                  icon: Icons.hub_rounded,
                  text: 'Motor de Predicción IA',
                  onTap: () {
                    Navigator.pop(context);
                    _openAiScreen(context);
                  },
                ),
                const Divider(color: AppColors.border),
                _buildDrawerItem(
                  icon: Icons.mood,
                  text: 'Estado Emocional y Sueño',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EstadoSuenoScreen(usuarioId: 1), // Assuming user ID 1 for now or fetch dynamically if available
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.favorite,
                  text: 'Salud',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SaludScreen()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person,
                  text: 'Mi Perfil',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PerfilScreen(onPerfilActualizado: _recargarPerfil),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.orange,
                  ),
                  title: const Text(
                    'Asistente IA',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.auto_awesome,
                    color: Colors.orange,
                    size: 18,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatScreen(),
                      ),
                    );
                  },
                ),
                const Divider(color: AppColors.border),
                _buildDrawerItem(
                  icon: Icons.settings,
                  text: 'Configuración',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Pantalla de Configuración si existe
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                foregroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
              onPressed: () async {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/onboarding');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textMuted),
      title: Text(text, style: const TextStyle(color: AppColors.textPrim)),
      onTap: onTap,
    );
  }

  Widget _buildDrawerItemHighlighted({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B2500), Color(0xFFE55A00)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrim,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.orange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'IA',
          style: TextStyle(
            color: AppColors.orange,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}
