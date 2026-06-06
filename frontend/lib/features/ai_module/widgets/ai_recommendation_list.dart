import 'package:flutter/material.dart';

/// Lista de recomendaciones con aspecto de insights de IA.
/// Cada ítem tiene ícono específico por categoría, badge "IA" y
/// micro-animación de entrada escalonada.
class AiRecommendationList extends StatefulWidget {
  final List<String> recommendations;

  const AiRecommendationList({Key? key, required this.recommendations})
      : super(key: key);

  @override
  State<AiRecommendationList> createState() => _AiRecommendationListState();
}

class _AiRecommendationListState extends State<AiRecommendationList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _buildAnimations();
  }

  void _buildAnimations() {
    _controllers = List.generate(
      widget.recommendations.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      ),
    );

    _fadeAnims = _controllers
        .map((c) => Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: c, curve: Curves.easeOut),
            ))
        .toList();

    _slideAnims = _controllers
        .map((c) => Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();

    // Stagger
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: 100 + i * 80), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recommendations.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con badge IA
          Row(
            children: [
              const Icon(
                Icons.psychology_rounded,
                color: Color(0xFFFF7A00),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Sugerencias del sistema',
                style: TextStyle(
                  color: Color(0xFFF5F5F7),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF7A00).withOpacity(0.3),
                  ),
                ),
                child: const Text(
                  'IA',
                  style: TextStyle(
                    color: Color(0xFFFF7A00),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Items animados
          ...List.generate(widget.recommendations.length, (i) {
            if (i >= _fadeAnims.length) return const SizedBox.shrink();
            return FadeTransition(
              opacity: _fadeAnims[i],
              child: SlideTransition(
                position: _slideAnims[i],
                child: _RecommendationItem(
                  text: widget.recommendations[i],
                  index: i,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RecommendationItem extends StatelessWidget {
  final String text;
  final int index;

  const _RecommendationItem({required this.text, required this.index});

  /// Detecta el tipo de recomendación para asignar ícono y color.
  _ItemStyle get _style {
    final lower = text.toLowerCase();
    if (lower.contains('sueño') || lower.contains('descanso')) {
      return _ItemStyle(
        icon: Icons.bedtime_rounded,
        color: const Color(0xFF5E9BFF),
      );
    } else if (lower.contains('ejercicio') ||
        lower.contains('actividad') ||
        lower.contains('caminata')) {
      return _ItemStyle(
        icon: Icons.directions_run_rounded,
        color: const Color(0xFF34C759),
      );
    } else if (lower.contains('estrés') || lower.contains('relaj')) {
      return _ItemStyle(
        icon: Icons.self_improvement_rounded,
        color: const Color(0xFFBE8FFF),
      );
    } else if (lower.contains('glucosa') ||
        lower.contains('riesgo') ||
        lower.contains('monitorea')) {
      return _ItemStyle(
        icon: Icons.monitor_heart_rounded,
        color: const Color(0xFFFF3B30),
      );
    } else {
      return _ItemStyle(
        icon: Icons.restaurant_menu_rounded,
        color: const Color(0xFFFF7A00),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: style.color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: style.color, width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(style.icon, color: style.color, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemStyle {
  final IconData icon;
  final Color color;
  const _ItemStyle({required this.icon, required this.color});
}
