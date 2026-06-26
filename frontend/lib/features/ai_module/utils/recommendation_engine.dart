class RecommendationEngine {
  static List<String> generateRecommendations(Map<String, dynamic> inputs, String riskLevel) {
    List<String> recommendations = [];

    // Parse values defensively
    final glucosaAntes = _parseDouble(inputs['glucosa_antes']);
    final estres = _parseInt(inputs['estres']);
    final horasSueno = _parseDouble(inputs['horas_sueno']);
    final ejercicio = _parseDouble(inputs['ejercicio']);

    if (glucosaAntes > 120) {
      recommendations.add("Considera ajustar tu dieta para controlar los niveles actuales de glucosa.");
    }

    if (estres >= 4) {
      recommendations.add("Nivel de estrés alto detectado. Esto puede causar picos de glucosa. Practica técnicas de relajación.");
    }

    if (horasSueno < 6 && horasSueno > 0) {
      recommendations.add("Sueño inadecuado detectado. Te recomendamos mejorar tu descanso para estabilizar el metabolismo.");
    }

    if (ejercicio == 0) {
      recommendations.add("No se registró actividad física. Te sugerimos realizar actividad ligera como una caminata de 15 minutos.");
    }

    if ((riskLevel == "HIGH" || riskLevel == "ALTO") && recommendations.isEmpty) {
      recommendations.add("Nivel de riesgo alto detectado. Por favor, monitorea tu glucosa de cerca.");
    }

    return recommendations;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
