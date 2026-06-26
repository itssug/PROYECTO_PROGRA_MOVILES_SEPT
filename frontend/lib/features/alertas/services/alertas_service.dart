import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/api_config.dart';
import '../models/alerta_model.dart';

class AlertasService {
  static String get baseUrl => '${ApiConfig.baseUrl}/api/alertas';

  static Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    };
  }

  static Future<int?> _getUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioStr = prefs.getString('auth_usuario');
    if (usuarioStr == null) return null;
    final usuario = jsonDecode(usuarioStr);
    final id = usuario['id'];
    return id is int ? id : int.tryParse(id.toString());
  }

  /// Lista todas las alertas del usuario, más recientes primero.
  static Future<List<Alerta>> getAlertas() async {
    final usuarioId = await _getUsuarioId();
    if (usuarioId == null) throw Exception('No hay sesión activa');
    final res = await http.get(
      Uri.parse('$baseUrl/alertas/?usuario_id=$usuarioId'),
      headers: await _headers,
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Alerta.fromJson(e)).toList();
    }
    throw Exception('Error al cargar alertas: ${res.statusCode}');
  }

  /// Marca una alerta como leída.
  static Future<void> marcarLeida(int id) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/alertas/$id/'),
      headers: await _headers,
      body: jsonEncode({'leido': 1}),
    );
    if (res.statusCode != 200) throw Exception('Error al marcar como leída');
  }

  static Future<void> eliminarAlerta(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/alertas/$id/'),
      headers: await _headers,
    );
    if (res.statusCode != 204) throw Exception('Error al eliminar');
  }

  /// Llama esto justo después de registrar una comida (desde cualquier
  /// pantalla, sin importar quién la programó) para que el sistema
  /// revise si se superó el límite diario y genere alertas.
  static Future<int> verificarLimites() async {
    final usuarioId = await _getUsuarioId();
    if (usuarioId == null) return 0;
    final res = await http.post(
      Uri.parse('$baseUrl/verificar/'),
      headers: await _headers,
      body: jsonEncode({'usuario_id': usuarioId}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['alertas_generadas'] ?? 0;
    }
    return 0;
  }

  /// Obtiene el resumen de consumo de hoy vs. límite recomendado.
  static Future<Map<String, dynamic>> getResumenDiario() async {
    final usuarioId = await _getUsuarioId();
    if (usuarioId == null) throw Exception('No hay sesión activa');
    final res = await http.get(
      Uri.parse('$baseUrl/resumen-diario/?usuario_id=$usuarioId'),
      headers: await _headers,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Error al cargar resumen');
  }
}