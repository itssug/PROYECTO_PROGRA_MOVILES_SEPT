// ============================================================
// ARCHIVO: lib/screens/usuarios/salud.dart
// ============================================================
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/perfil_service.dart';
import '../app_colors.dart';

class SaludScreen extends StatelessWidget {
  const SaludScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.usuario ?? {};
    final imc = PerfilService.calcularIMC(
      usuario['peso'],
      usuario['altura'],
    );

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

          // Tarjeta de IMC
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getColorIMC(imc).withOpacity(0.8),
                  _getColorIMC(imc).withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Tu Índice de Masa Corporal',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  imc?.toStringAsFixed(1) ?? '--',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  imc != null ? PerfilService.getCategoriaIMC(imc) : 'No disponible',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Control de Glucosa
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

          // Medicamentos
          _HealthCard(
            title: 'Medicamentos',
            icon: Icons.medication,
            children: [
              _HealthRow(
                label: 'Insulina',
                value: usuario['usa_insulina'] == 1 ? 'Sí' : 'No',
              ),
              _HealthRow(
                label: 'Fumador',
                value: usuario['es_fumador'] == 1 ? 'Sí' : 'No',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Condiciones Médicas
          _HealthCard(
            title: 'Condiciones Médicas',
            icon: Icons.health_and_safety,
            children: [
              _HealthRow(
                label: 'Hipertensión',
                value: usuario['tiene_hipertension'] == 1 ? 'Sí' : 'No',
              ),
              _HealthRow(
                label: 'Dislipidemia',
                value: usuario['tiene_dislipidemia'] == 1 ? 'Sí' : 'No',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Actividad Física
          _HealthCard(
            title: 'Actividad Física',
            icon: Icons.fitness_center,
            children: [
              _HealthRow(
                label: 'Nivel de actividad',
                value: _getActividadTexto(usuario['nivel_actividad_base']),
              ),
              _HealthRow(label: 'Meta diaria', value: '30 minutos'),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorIMC(double? imc) {
    if (imc == null) return AppColors.orange;
    if (imc < 18.5) return Colors.blue;
    if (imc < 25) return Colors.green;
    if (imc < 30) return Colors.orange;
    return Colors.red;
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
// WIDGETS SALUD
// ============================================================

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