import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Card con gauge semicircular custom paint para la glucosa predicha.
/// Muestra el valor en el centro del gauge con colores según el nivel de riesgo.
class AiGaugeCard extends StatefulWidget {
  final double predictedGlucose;
  final String riskLevel;

  const AiGaugeCard({
    Key? key,
    required this.predictedGlucose,
    required this.riskLevel,
  }) : super(key: key);

  @override
  State<AiGaugeCard> createState() => _AiGaugeCardState();
}

class _AiGaugeCardState extends State<AiGaugeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _RiskConfig get _config {
    switch (widget.riskLevel.toUpperCase()) {
      case 'HIGH':
      case 'ALTO':
        return _RiskConfig(
          label: 'RIESGO ALTO',
          sublabel: 'Monitorea tu glucosa de cerca',
          color: const Color(0xFFFF3B30),
          bgColor: const Color(0xFF2A0A0A),
          borderColor: const Color(0xFF5A1A1A),
          icon: Icons.warning_amber_rounded,
        );
      case 'MEDIUM':
      case 'MEDIO':
        return _RiskConfig(
          label: 'RIESGO MODERADO',
          sublabel: 'Mantén control de tu dieta',
          color: const Color(0xFFFFCC00),
          bgColor: const Color(0xFF1F1A00),
          borderColor: const Color(0xFF4A3E00),
          icon: Icons.info_outline_rounded,
        );
      default:
        return _RiskConfig(
          label: 'RIESGO BAJO',
          sublabel: 'Niveles dentro del rango esperado',
          color: const Color(0xFF34C759),
          bgColor: const Color(0xFF0A1F0E),
          borderColor: const Color(0xFF1A4A22),
          icon: Icons.check_circle_outline_rounded,
        );
    }
  }

  /// Normaliza la glucosa para el gauge [70, 250] → [0.0, 1.0]
  double get _gaugeRatio {
    const minG = 70.0;
    const maxG = 250.0;
    return ((widget.predictedGlucose - minG) / (maxG - minG)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cfg.bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cfg.borderColor, width: 1.5),
          ),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cfg.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cfg.icon, color: cfg.color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cfg.label,
                        style: TextStyle(
                          color: cfg.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        cfg.sublabel,
                        style: TextStyle(
                          color: cfg.color.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Gauge
              SizedBox(
                width: 200,
                height: 110,
                child: CustomPaint(
                  painter: _GaugePainter(
                    progress: _gaugeRatio * _animation.value,
                    color: cfg.color,
                    glucose: widget.predictedGlucose,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Etiquetas de escala
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('70', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                    Text('130', style: TextStyle(color: const Color(0xFF34C759).withOpacity(0.7), fontSize: 10)),
                    Text('180', style: TextStyle(color: const Color(0xFFFFCC00).withOpacity(0.7), fontSize: 10)),
                    Text('250+', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Separador
              Divider(color: cfg.borderColor),
              const SizedBox(height: 8),

              // Footer: etiqueta "Predicción IA"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.psychology_rounded,
                      size: 14, color: cfg.color.withOpacity(0.7)),
                  const SizedBox(width: 6),
                  Text(
                    'Predicción post-comida generada por IA',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glucose;

  const _GaugePainter({
    required this.progress,
    required this.color,
    required this.glucose,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.92;
    final radius = size.width / 2 - 10;

    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // Track de fondo
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Zonas de color (verde → amarillo → rojo)
    _drawZone(canvas, cx, cy, radius, startAngle, sweepAngle * 0.47,
        const Color(0xFF34C759).withOpacity(0.25));
    _drawZone(canvas, cx, cy, radius, startAngle + sweepAngle * 0.47,
        sweepAngle * 0.27, const Color(0xFFFFCC00).withOpacity(0.25));
    _drawZone(canvas, cx, cy, radius, startAngle + sweepAngle * 0.74,
        sweepAngle * 0.26, const Color(0xFFFF3B30).withOpacity(0.25));

    // Arco de progreso con gradiente
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle * progress,
          colors: [
            const Color(0xFF34C759),
            const Color(0xFFFFCC00),
            const Color(0xFFFF3B30),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle,
        sweepAngle * progress,
        false,
        progressPaint,
      );

      // Punta luminosa (glow dot)
      final tipAngle = startAngle + sweepAngle * progress;
      final tipX = cx + radius * math.cos(tipAngle);
      final tipY = cy + radius * math.sin(tipAngle);

      canvas.drawCircle(
        Offset(tipX, tipY),
        8,
        Paint()..color = color.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(tipX, tipY),
        5,
        Paint()..color = Colors.white,
      );
    }

    // Valor central
    final glucoseText = '${glucose.toStringAsFixed(0)}';
    final unitText = 'mg/dL';

    final glucosePainter = TextPainter(
      text: TextSpan(
        text: glucoseText,
        style: TextStyle(
          color: color,
          fontSize: 36,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final unitPainter = TextPainter(
      text: TextSpan(
        text: unitText,
        style: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    glucosePainter.paint(
      canvas,
      Offset(cx - glucosePainter.width / 2, cy - glucosePainter.height - 2),
    );
    unitPainter.paint(
      canvas,
      Offset(cx - unitPainter.width / 2, cy + 2),
    );
  }

  void _drawZone(Canvas canvas, double cx, double cy, double radius,
      double startAngle, double sweepAngle, Color color) {
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.progress != progress || old.color != color;
}

class _RiskConfig {
  final String label;
  final String sublabel;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;

  const _RiskConfig({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
  });
}
