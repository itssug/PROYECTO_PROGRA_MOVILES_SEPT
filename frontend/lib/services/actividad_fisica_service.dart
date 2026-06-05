import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';

class ActividadFisicaService {
static const String baseUrl = '${ApiConfig.baseUrl}/api';

  static const int usuarioId = 1;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Usuario-Id': '$usuarioId',
      };

  static Future<Map<String, dynamic>> listarActividades({
    String? fechaDesde,
    String? fechaHasta,
    String? tipo,
  }) async {
    String url = '$baseUrl/actividades/';
    List<String> params = [];
    if (fechaDesde != null) params.add('fecha_desde=$fechaDesde');
    if (fechaHasta != null) params.add('fecha_hasta=$fechaHasta');
    if (tipo != null) params.add('tipo=$tipo');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final response = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al cargar actividades: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> crearActividad(
      Map<String, dynamic> datos) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/actividades/'),
          headers: _headers,
          body: json.encode(datos),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }

    try {
      final errorBody = json.decode(response.body);
      final detalles = errorBody['detalles'] ?? errorBody['error'] ?? '';
      throw Exception('$detalles');
    } catch (_) {
      throw Exception('Error al crear actividad: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> editarActividad(
      int id, Map<String, dynamic> datos) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/actividades/$id/'),
          headers: _headers,
          body: json.encode(datos),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }

    try {
      final errorBody = json.decode(response.body);
      final detalles = errorBody['detalles'] ?? errorBody['error'] ?? '';
      throw Exception('$detalles');
    } catch (_) {
      throw Exception('Error al editar actividad: ${response.statusCode}');
    }
  }

  static Future<void> eliminarActividad(int id) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/actividades/$id/'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar actividad');
    }
  }

  static Future<Map<String, dynamic>> obtenerEstadisticas(
      {int periodo = 7}) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/actividades/estadisticas/?periodo=$periodo'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al cargar estadísticas');
  }

  static Future<Map<String, dynamic>> obtenerResumenHoy() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/actividades/hoy/'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al cargar resumen de hoy');
  }
}