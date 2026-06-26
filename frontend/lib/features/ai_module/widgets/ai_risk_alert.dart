import 'package:flutter/material.dart';

class AiRiskAlert extends StatelessWidget {
  final String riskLevel;
  final double predictedGlucose;

  const AiRiskAlert({
    Key? key,
    required this.riskLevel,
    required this.predictedGlucose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    Color textColor;
    IconData icon;
    String title;

    switch (riskLevel.toUpperCase()) {
      case 'HIGH':
      case 'ALTO':
        cardColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
        icon = Icons.warning_amber_rounded;
        title = "Riesgo Alto Detectado";
        break;
      case 'MEDIUM':
      case 'MEDIO':
        cardColor = Colors.orange.shade50;
        textColor = Colors.orange.shade900;
        icon = Icons.info_outline;
        title = "Riesgo Moderado";
        break;
      default:
        cardColor = Colors.green.shade50;
        textColor = Colors.green.shade900;
        icon = Icons.check_circle_outline;
        title = "Riesgo Bajo";
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: textColor.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 28),
              const SizedBox(width: 8.0),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            "Glucosa Predicha Post-Comida: ${predictedGlucose.toStringAsFixed(1)} mg/dL",
            style: TextStyle(
              color: textColor.withOpacity(0.8),
              fontSize: 15.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
