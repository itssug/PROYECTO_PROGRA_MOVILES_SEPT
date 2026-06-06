import 'package:flutter/material.dart';

class AiBanner extends StatelessWidget {
  final String modelUsed;

  const AiBanner({Key? key, required this.modelUsed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isGlobal = modelUsed.toLowerCase().contains('global');
    final String message = isGlobal
        ? "Estás usando un modelo de IA global. Tus predicciones mejorarán con más datos."
        : "Modelo de IA personalizado activo. Mayor precisión habilitada.";

    final IconData icon = isGlobal ? Icons.public : Icons.person_pin;
    final Color bgColor = isGlobal ? Colors.blue.shade50 : Colors.green.shade50;
    final Color textColor = isGlobal ? Colors.blue.shade800 : Colors.green.shade800;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
