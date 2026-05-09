// ============================================================
// ARCHIVO: lib/screens/home_screen.dart
// CORREGIDO - PASANDO DATOS A TODAS LAS PANTALLAS
// ============================================================
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../../widgets/shared_widgets.dart';
import 'app_colors.dart';
import '../screens/inicio/Onboarding_screen_3.dart'; // ← Importar OnboardingScreen3 para logout

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

  Future<void> _cargarPerfil() async {
    setState(() => _cargando = true);
    try {
      // Obtener perfil actualizado desde el servidor
      final perfil = await AuthService.getPerfil();
      setState(() => _perfil = perfil);
    } catch (e) {
      print('Error cargando perfil: $e');
      // Si hay error, usar los datos en memoria
      setState(() => _perfil = AuthService.usuario);
    } finally {
      setState(() => _cargando = false);
    }
  }

  // Método para recargar el perfil después de editar
  Future<void> _recargarPerfil() async {
    try {
      final perfil = await AuthService.getPerfil();
      setState(() => _perfil = perfil);
    } catch (e) {
      setState(() => _perfil = AuthService.usuario);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'GlucoWatch',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recargarPerfil, // Botón para recargar datos
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const OnboardingScreen3()),
                );
              }
            },
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.orange,
              ),
            )
          : IndexedStack(
              index: _selectedIndex,
              children: [
                DashboardScreen(perfil: _perfil),
                HealthScreen(perfil: _perfil), // ← PASAR DATOS
                ProfileScreen(
                  perfil: _perfil,
                  onPerfilActualizado: _recargarPerfil, // ← CALLBACK PARA ACTUALIZAR
                ),
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
    final nombre = perfil?['nombre'] ?? 'Usuario';
    final email = perfil?['email'] ?? '';

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

          // Tarjeta de glucosa (principal)
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
                  value: _calcularIMC(perfil?['peso'], perfil?['altura']),
                  unit: '',
                  icon: Icons.calculate,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Sección de actividad reciente
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

          // Botón rápido para registro
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

  String _calcularIMC(double? peso, double? altura) {
    if (peso == null || altura == null || altura <= 0) return '--';
    final alturaMetros = altura / 100;
    final imc = peso / (alturaMetros * alturaMetros);
    return imc.toStringAsFixed(1);
  }
}

// ============================================================
// PANTALLA SALUD (RECIBE DATOS)
// ============================================================
class HealthScreen extends StatelessWidget {
  final Map<String, dynamic>? perfil;

  const HealthScreen({super.key, this.perfil});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mi Salud',
            style: TextStyle(
              color: AppColors.textPrim,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          _HealthCard(
            title: 'Control de Glucosa',
            icon: Icons.bloodtype,
            children: [
              _HealthRow(label: 'Meta diaria', value: '70-140 mg/dL'),
              _HealthRow(label: 'Última medición', value: '126 mg/dL'),
              _HealthRow(label: 'Frecuencia', value: '4 veces/día'),
            ],
          ),

          const SizedBox(height: 16),

          _HealthCard(
            title: 'Medicamentos',
            icon: Icons.medication,
            children: [
              _HealthRow(
                label: 'Insulina',
                value: perfil?['usa_insulina'] == 1 ? 'Sí' : 'No',
              ),
              _HealthRow(
                label: 'Fumador',
                value: perfil?['es_fumador'] == 1 ? 'Sí' : 'No',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _HealthCard(
            title: 'Condiciones Médicas',
            icon: Icons.health_and_safety,
            children: [
              _HealthRow(
                label: 'Hipertensión',
                value: perfil?['tiene_hipertension'] == 1 ? 'Sí' : 'No',
              ),
              _HealthRow(
                label: 'Dislipidemia',
                value: perfil?['tiene_dislipidemia'] == 1 ? 'Sí' : 'No',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _HealthCard(
            title: 'Actividad Física',
            icon: Icons.fitness_center,
            children: [
              _HealthRow(
                label: 'Nivel de actividad',
                value: _getActividadTexto(perfil?['nivel_actividad_base']),
              ),
              _HealthRow(label: 'Meta diaria', value: '30 minutos'),
            ],
          ),
        ],
      ),
    );
  }

  String _getActividadTexto(String? nivel) {
    switch (nivel) {
      case 'sedentario':
        return 'Sedentario';
      case 'moderado':
        return 'Moderado';
      case 'activo':
        return 'Activo';
      default:
        return 'No especificado';
    }
  }
}

// ============================================================
// PANTALLA PERFIL (RECIBE DATOS Y CALLBACK)
// ============================================================
class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? perfil;
  final VoidCallback? onPerfilActualizado;

  const ProfileScreen({
    super.key,
    this.perfil,
    this.onPerfilActualizado,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editando = false;
  late Map<String, dynamic> _datosEditables;

  @override
  void initState() {
    super.initState();
    // Usar los datos recibidos o los de AuthService
    _datosEditables = Map.from(widget.perfil ?? AuthService.usuario ?? {});
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar si el perfil cambió
    if (widget.perfil != oldWidget.perfil) {
      _datosEditables = Map.from(widget.perfil ?? AuthService.usuario ?? {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.perfil ?? AuthService.usuario ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con avatar
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.orange,
                  child: Text(
                    usuario['nombre']?.isNotEmpty == true
                        ? usuario['nombre'][0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  usuario['nombre'] ?? 'Usuario',
                  style: const TextStyle(
                    color: AppColors.textPrim,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  usuario['email'] ?? '',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                if (!_editando)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _editando = true);
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Editar perfil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Información del perfil
          const Text(
            'Información Personal',
            style: TextStyle(
              color: AppColors.textPrim,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _ProfileInfoRow(
            label: 'ID de usuario',
            value: '${usuario['id'] ?? 'N/A'}',
          ),
          _ProfileInfoRow(
            label: 'Sexo',
            value: _getSexoTexto(usuario['sexo']),
            editable: _editando,
            onEdit: (valor) {
              setState(() {
                _datosEditables['sexo'] = valor;
              });
            },
            options: const ['masculino', 'femenino', 'otro'],
            optionLabels: const ['Masculino', 'Femenino', 'Otro'],
          ),
          _ProfileInfoRow(
            label: 'Peso',
            value: usuario['peso'] != null ? '${usuario['peso']} kg' : 'No registrado',
            editable: _editando,
            onEditNumber: (valor) {
              setState(() {
                _datosEditables['peso'] = double.tryParse(valor);
              });
            },
          ),
          _ProfileInfoRow(
            label: 'Altura',
            value: usuario['altura'] != null ? '${usuario['altura']} cm' : 'No registrado',
            editable: _editando,
            onEditNumber: (valor) {
              setState(() {
                _datosEditables['altura'] = double.tryParse(valor);
              });
            },
          ),
          _ProfileInfoRow(
            label: 'HbA1c inicial',
            value: usuario['hba1c_inicial'] != null
                ? '${usuario['hba1c_inicial']}%'
                : 'No registrado',
            editable: _editando,
            onEditNumber: (valor) {
              setState(() {
                _datosEditables['hba1c_inicial'] = double.tryParse(valor);
              });
            },
          ),
          _ProfileInfoRow(
            label: 'Años con diagnóstico',
            value: usuario['anios_diagnostico'] != null
                ? '${usuario['anios_diagnostico']} años'
                : 'No registrado',
            editable: _editando,
            onEditNumber: (valor) {
              setState(() {
                _datosEditables['anios_diagnostico'] = int.tryParse(valor);
              });
            },
          ),
          _ProfileInfoRow(
            label: 'Nivel de actividad',
            value: _getActividadTexto(usuario['nivel_actividad_base']),
            editable: _editando,
            onEdit: (valor) {
              setState(() {
                _datosEditables['nivel_actividad_base'] = valor;
              });
            },
            options: const ['sedentario', 'moderado', 'activo'],
            optionLabels: const ['Sedentario', 'Moderado', 'Activo'],
          ),

          const SizedBox(height: 24),

          if (_editando) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _editando = false;
                        _datosEditables = Map.from(widget.perfil ?? AuthService.usuario ?? {});
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        // Actualizar solo campos modificados
                        final cambios = <String, dynamic>{};
                        for (var key in _datosEditables.keys) {
                          if (_datosEditables[key] != widget.perfil?[key]) {
                            cambios[key] = _datosEditables[key];
                          }
                        }
                        if (cambios.isNotEmpty) {
                          await AuthService.updatePerfil(cambios);
                          // Notificar a HomeScreen que recargue los datos
                          widget.onPerfilActualizado?.call();
                        }
                        setState(() {
                          _editando = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Perfil actualizado correctamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Guardar cambios'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getSexoTexto(String? sexo) {
    switch (sexo) {
      case 'masculino':
        return 'Masculino';
      case 'femenino':
        return 'Femenino';
      case 'otro':
        return 'Otro';
      default:
        return 'No especificado';
    }
  }

  String _getActividadTexto(String? nivel) {
    switch (nivel) {
      case 'sedentario':
        return 'Sedentario';
      case 'moderado':
        return 'Moderado';
      case 'activo':
        return 'Activo';
      default:
        return 'No especificado';
    }
  }
}

// ============================================================
// WIDGETS REUTILIZABLES (igual que antes)
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              Text('140', style: TextStyle(color: Colors.white70, fontSize: 12)),
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

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
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
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ],
          ),
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

class _HealthCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _HealthCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.orange, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrim,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final String value;

  const _HealthRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
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
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool editable;
  final Function(String)? onEdit;
  final Function(String)? onEditNumber;
  final List<String>? options;
  final List<String>? optionLabels;

  const _ProfileInfoRow({
    required this.label,
    required this.value,
    this.editable = false,
    this.onEdit,
    this.onEditNumber,
    this.options,
    this.optionLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: editable
                ? _buildEditWidget()
                : Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrim,
                      fontSize: 14,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditWidget() {
    if (options != null && onEdit != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _getCurrentValue(),
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.textPrim),
            items: options!.map((option) {
              final index = options!.indexOf(option);
              return DropdownMenuItem(
                value: option,
                child: Text(optionLabels?[index] ?? option),
              );
            }).toList(),
            onChanged: (valor) {
              if (valor != null) onEdit!(valor);
            },
          ),
        ),
      );
    }
    return TextFormField(
      initialValue: value.replaceAll(' kg', '').replaceAll(' cm', '').replaceAll('%', '').replaceAll(' años', ''),
      style: const TextStyle(color: AppColors.textPrim),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.orange),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      keyboardType: TextInputType.number,
      onChanged: onEditNumber != null ? onEditNumber : null,
    );
  }

  String _getCurrentValue() {
    if (onEdit != null && options != null) {
      if (label == 'Sexo') {
        if (value == 'Masculino') return 'masculino';
        if (value == 'Femenino') return 'femenino';
        if (value == 'Otro') return 'otro';
      }
      if (label == 'Nivel de actividad') {
        if (value == 'Sedentario') return 'sedentario';
        if (value == 'Moderado') return 'moderado';
        if (value == 'Activo') return 'activo';
      }
    }
    return options?.first ?? '';
  }
}