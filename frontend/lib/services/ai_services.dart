import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../../../config/api_config.dart';

class AIService {
  static const String _base = '${ApiConfig.baseUrl}/api';
  // ── Configuración base ────────────────────────────────────────────────────
  // Cambia según entorno:
  //   Android emulator → 10.0.2.2
  //   iOS simulator    → 127.0.0.1
  //   Dispositivo real → IP local de tu máquina (ej: 192.168.x.x)
  static const Duration _timeout = Duration(seconds: 30);

  // TODO: cuando implementes auth, guardar el token aquí
  // static String? _authToken;

  // ── Cabeceras base ────────────────────────────────────────────────────────
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // TODO: descomentar cuando tengas auth
    // if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };
    // ============================================================
  // OBTENER HEADERS CON TOKEN DE FORMA SEGURA
  // ============================================================
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await AuthService.getTokenSeguro();
    print('🔑 Token usado para headers: $token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    };
  }

  static Future<void> debugToken() async {
    try {
      final token = await AuthService.getTokenSeguro();
      print('🐛 DEBUG - Token: $token');

      final response = await http.get(
        Uri.parse('$_base/auth/debug-token/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      print('🐛 DEBUG - Status: ${response.statusCode}');
      print('🐛 DEBUG - Response: ${response.body}');
    } catch (e) {
      print('🐛 DEBUG - Error: $e');
    }
  }

  // ============================================================
  // OBTENER PERFIL COMPLETO
  // ============================================================
  static Future<Map<String, dynamic>> getPerfil() async {
    try {
      final headers = await _getAuthHeaders();

      final response = await http
          .get(
            Uri.parse('$_base/auth/perfil/'),
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception(
        'Error al obtener perfil (${response.statusCode})',
      );

    } catch (e) {
      print('❌ Error en getPerfil: $e');
      rethrow;
    }
  }
 

  // ── Chat principal ────────────────────────────────────────────────────────
  static Future<AIResponse> enviarMensaje(String mensaje) async {
    final perfil = await getPerfil();

    final userId = perfil['id'];
    final url = Uri.parse('http://127.0.0.1:8000/api/ai/chat/');
    /* Ayudame a printear el id */
    print("id del usu");

    try {
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({
              'message': mensaje,
              // temporal: el backend necesita user_id mientras no hay auth
              if (userId != null) 'user_id': userId,
            }),
          )
          .timeout(_timeout);

      return _parseResponse(response);
    } on SocketException {
      return AIResponse.error(
        'Sin conexión. Verifica que el servidor esté corriendo.',
      );
    } on HttpException {
      return AIResponse.error('Error de red. Intenta de nuevo.');
    } on FormatException {
      return AIResponse.error('Respuesta inválida del servidor.');
    } catch (e) {
      return AIResponse.error('Error inesperado: ${e.runtimeType}');
    }
  }

  // ── Parser de respuesta ───────────────────────────────────────────────────
  static AIResponse _parseResponse(http.Response response) {
    // El backend puede no devolver JSON en errores 500
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return AIResponse.error('El servidor devolvió una respuesta inesperada.');
    }

    switch (response.statusCode) {
      case 200:
        final answer = data['answer'] as String?;
        if (answer == null || answer.isEmpty) {
          return AIResponse.error('La IA no devolvió respuesta.');
        }
        return AIResponse.success(answer);

      case 400:
        final msg = data['error'] ?? 'Petición inválida.';
        return AIResponse.error(msg.toString());

      case 401:
      case 403:
        return AIResponse.error('Sin autorización. Inicia sesión nuevamente.');

      case 404:
        return AIResponse.error('Endpoint no encontrado. Revisa la URL.');

      case 500:
      default:
        return AIResponse.error('Error del servidor (${response.statusCode}).');
    }
  }
}

// ── Modelo de respuesta tipada ────────────────────────────────────────────────
class AIResponse {
  final String? answer;
  final String? error;
  final bool success;

  const AIResponse._({this.answer, this.error, required this.success});

  factory AIResponse.success(String answer) =>
      AIResponse._(answer: answer, success: true);

  factory AIResponse.error(String error) =>
      AIResponse._(error: error, success: false);

  /// Texto a mostrar en la UI siempre
  String get displayText => success ? answer! : '⚠️ $error';
}