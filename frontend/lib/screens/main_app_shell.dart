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
import '../features/alertas/screens/alertas_screen.dart';
import '../features/alertas/services/alertas_service.dart'; 
import 'chat_screen.dart';

import '../services/in_app_alert_service.dart';
import '../services/medicamento_service.dart';
import '../services/registro_service.dart';
import '../models/medicamento_model.dart';
import '../models/registro_model.dart';

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

      // ── Verifica alertas nutricionales al abrir la app ──
      try {
        await AlertasService.verificarLimites();
      } catch (e) {
        print('No se pudo verificar alertas: $e');
      }

    } catch (e) {
      print('Error cargando perfil: $e');

      if (e.toString().contains('Sesión expirada') ||
          e.toString().contains('Token inválido')) {
        await AuthService.logout();

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
      // Tras cargar perfil, verificar medicamentos pendientes
      Future.delayed(const Duration(seconds: 3), _verificarMedicamentosPendientes);
    }
  }

  Future<void> _verificarMedicamentosPendientes() async {
    try {
      final results = await Future.wait([
        MedicamentoService.listarActivos(),
        RegistroService.hoy(),
      ]);
      final resMeds = results[0] as ServiceResult<List<Medicamento>>;
      final resRegs = results[1] as ServiceResult<List<RegistroMedicamento>>;

      if (resMeds.success && resRegs.success) {
        final meds = resMeds.data!;
        final regs = resRegs.data!;
        final ahora = TimeOfDay.now();
        final ahoraMin = ahora.hour * 60 + ahora.minute;

        for (final m in meds) {
          if (m.horaToma == null) continue;
          final parts = m.horaToma!.split(':');
          final medMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
          if (medMin <= ahoraMin) {
            final tomado = regs.any((r) => r.medicamentoId == m.id && r.fueTomado == 1);
            if (!tomado) {
              InAppAlertService.show(
                title: 'Recordatorio de Medicamento',
                message: 'Es hora de tomar tu medicamento: ${m.nombre}. ¡No lo olvides!',
                type: AlertType.warning,
                duration: const Duration(seconds: 10),
                actionLabel: 'Confirmar',
                onTap: () {
                  setState(() => _selectedIndex = 1);
                },
              );
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error verificando meds: $e');
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
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const AlertasScreen(),
              ));
            },
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
                _buildDrawerItem(
                  icon: Icons.notifications_active,
                  text: 'Alertas',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const AlertasScreen(),
                    ));
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
                    // Obtiene el id real del usuario desde AuthService
                    final usuarioId = AuthService.usuario?['id'];
                    if (usuarioId == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EstadoSuenoScreen(
                          
                        ),
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
                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
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
