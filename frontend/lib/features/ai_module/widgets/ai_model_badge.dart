import 'package:flutter/material.dart';

/// Badge premium que indica el tipo de modelo ML activo.
/// - Modelo global: gradiente azul-índigo con ícono de red global
/// - Modelo personalizado: gradiente naranja brand con animación de pulso
class AiModelBadge extends StatefulWidget {
  final String modelUsed;

  const AiModelBadge({Key? key, required this.modelUsed}) : super(key: key);

  @override
  State<AiModelBadge> createState() => _AiModelBadgeState();
}

class _AiModelBadgeState extends State<AiModelBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_isPersonalizado) {
      _pulseController.repeat(reverse: true);
    }
  }

  bool get _isPersonalizado =>
      !widget.modelUsed.toLowerCase().contains('global');

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isPersonalizado
        ? ScaleTransition(scale: _pulseAnimation, child: _buildBadge())
        : _buildBadge();
  }

  Widget _buildBadge() {
    final isGlobal = !_isPersonalizado;

    final List<Color> gradientColors = isGlobal
        ? [const Color(0xFF1A237E), const Color(0xFF283593)]
        : [const Color(0xFF8B2500), const Color(0xFFE55A00)];

    final Color accentColor =
        isGlobal ? const Color(0xFF7986CB) : const Color(0xFFFF8A50);

    final IconData icon = isGlobal ? Icons.hub_rounded : Icons.person_rounded;

    final String label =
        isGlobal ? 'MODELO GLOBAL' : 'MODELO PERSONALIZADO';

    final String subtitle = isGlobal
        ? 'Compartido · mejora con tus datos'
        : 'Entrenado con tu historial';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícono con fondo circular
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Dot vivo
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Chip "IA ACTIVA"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
            ),
            child: const Text(
              'IA ACTIVA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
