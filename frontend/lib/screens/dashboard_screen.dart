import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/perfil_service.dart';
import '../services/in_app_alert_service.dart';
import '../features/ai_module/widgets/ai_dashboard_plugin.dart';
import 'app_colors.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic>? perfil;

  const DashboardScreen({super.key, this.perfil});

  @override
  Widget build(BuildContext context) {
    final nombre = perfil?['nombre'] ?? AuthService.usuario?['nombre'] ?? 'Usuario';
    final email = perfil?['email'] ?? AuthService.usuario?['email'] ?? '';
    double? _toDouble(dynamic v) => v == null ? null : (v is double ? v : double.tryParse(v.toString()));

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

          // --- AI Module Plugin ---
          AiDashboardPlugin(
            userId: AuthService.usuario?['id'] ?? 14,
            contextData: {
              // Datos conocidos del usuario (glucosa basal, sueño, estrés, ejercicio)
              // En producción vendrán del último registro del perfil
              "glucosa_antes": perfil?['glucosa_actual'] ?? 126.0,
              "horas_sueno": 7.0,
              "estres": 2,
              "ejercicio": 30.0,
            },
          ),
          // ------------------------

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
                  subtitle: imc != null ? PerfilService.getCategoriaIMC(imc) : null,
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

          const _ActividadItem(
            icon: Icons.bloodtype,
            title: 'Última glucosa',
            value: '126 mg/dL',
            time: 'Hace 2 horas',
            color: AppColors.orange,
          ),
          const SizedBox(height: 8),
          const _ActividadItem(
            icon: Icons.restaurant,
            title: 'Última comida',
            value: 'Desayuno',
            time: 'Hace 3 horas',
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          const _ActividadItem(
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
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom,
                      left: 24,
                      right: 24,
                      top: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Registrar Glucosa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Nivel de glucosa (mg/dL)',
                            labelStyle: const TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.bg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            InAppAlertService.show(
                              title: '¡Glucosa Registrada!',
                              message: 'Tu nivel de glucosa ha sido guardado exitosamente.',
                              type: AlertType.success,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Guardar Registro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
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
