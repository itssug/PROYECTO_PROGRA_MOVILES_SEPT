import 'dart:convert';
import 'package:http/http.dart' as http;

class AIPredictionResult {
  final double predictedGlucose;
  final String riskLevel;
  final String modelUsed;

  AIPredictionResult({
    required this.predictedGlucose,
    required this.riskLevel,
    required this.modelUsed,
  });

  factory AIPredictionResult.fromJson(Map<String, dynamic> json) {
    return AIPredictionResult(
      predictedGlucose: json['glucosa_predicha'] != null ? double.parse(json['glucosa_predicha'].toString()) : 0.0,
      riskLevel: json['riesgo'] ?? 'UNKNOWN',
      modelUsed: json['modelo_usado'] ?? 'unknown',
    );
  }
}

class AIService {
  static const String baseUrl = 'http://localhost:8000/api';

  Future<AIPredictionResult?> predictRisk(int userId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict/$userId/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return AIPredictionResult.fromJson(responseData);
      } else {
        print('Error predicting risk: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception predicting risk: $e');
      return null;
    }
  }
}
