import 'dart:convert';
import 'api_client.dart';
import 'auth_service.dart';

class GlucosaService {
  static Future<bool> registrarGlucosa(double nivelGlucosa) async {
    try {
      final user = AuthService.usuario;
      if (user == null) return false;
      final userId = user['id'];

      final response = await ApiClient.post('/api/glucosa/', {
        'usuario': userId,
        'nivel_glucosa': nivelGlucosa,
        'tipo_medicion': 'aleatoria',
      });

      if (response.success) {
        return true;
      } else {
        print('Error al registrar glucosa: ${response.error}');
        return false;
      }
    } catch (e) {
      print('Excepción al registrar glucosa: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUltimaGlucosa() async {
    try {
      final user = AuthService.usuario;
      if (user == null) return null;
      final userId = user['id'];

      final response = await ApiClient.get('/api/glucosa/?usuario=$userId&limit=1');
      if (response.success && response.data is List && response.data.isNotEmpty) {
        return response.data[0];
      }
      return null;
    } catch (e) {
      print('Excepción al obtener última glucosa: $e');
      return null;
    }
  }
}
