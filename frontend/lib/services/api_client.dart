import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiClient {
  // ── Configuración ─────────────────────────────────────────────────────────
  static const String _baseUrl = 'http://127.0.0.1:8000';
  static const Duration _timeout = Duration(seconds: 30);

  // ── Headers ───────────────────────────────────────────────────────────────
  static Map<String, String> get headers {
    final userId = AuthService.usuario?['id'];
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (userId != null) 'X-User-Id': '$userId',
      // TODO: con JWT reemplazar X-User-Id por:
      // if (AuthService.token != null) 'Authorization': 'Token ${AuthService.token}',
    };
  }

  // ── Métodos HTTP ──────────────────────────────────────────────────────────

  static Future<ApiResponse> get(String path, {Map<String, String>? params}) async {
    var uri = Uri.parse('$_baseUrl$path');
    if (params != null) uri = uri.replace(queryParameters: params);

    try {
      final response = await http.get(uri, headers: headers).timeout(_timeout);
      return _parse(response);
    } on SocketException {
      return ApiResponse.error('Sin conexión con el servidor.');
    } on TimeoutException {
      return ApiResponse.error('El servidor tardó demasiado en responder.');
    } catch (e) {
      return ApiResponse.error('Error inesperado: ${e.runtimeType}');
    }
  }

  static Future<ApiResponse> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl$path'), headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _parse(response);
    } on SocketException {
      return ApiResponse.error('Sin conexión con el servidor.');
    } on TimeoutException {
      return ApiResponse.error('El servidor tardó demasiado en responder.');
    } catch (e) {
      return ApiResponse.error('Error inesperado: ${e.runtimeType}');
    }
  }

  static Future<ApiResponse> patch(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .patch(Uri.parse('$_baseUrl$path'), headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _parse(response);
    } on SocketException {
      return ApiResponse.error('Sin conexión con el servidor.');
    } on TimeoutException {
      return ApiResponse.error('El servidor tardó demasiado en responder.');
    } catch (e) {
      return ApiResponse.error('Error inesperado: ${e.runtimeType}');
    }
  }

  static Future<ApiResponse> put(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(Uri.parse('$_baseUrl$path'), headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _parse(response);
    } on SocketException {
      return ApiResponse.error('Sin conexión con el servidor.');
    } on TimeoutException {
      return ApiResponse.error('El servidor tardó demasiado en responder.');
    } catch (e) {
      return ApiResponse.error('Error inesperado: ${e.runtimeType}');
    }
  }

  static Future<ApiResponse> delete(String path) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl$path'), headers: headers)
          .timeout(_timeout);
      return _parse(response);
    } on SocketException {
      return ApiResponse.error('Sin conexión con el servidor.');
    } on TimeoutException {
      return ApiResponse.error('El servidor tardó demasiado en responder.');
    } catch (e) {
      return ApiResponse.error('Error inesperado: ${e.runtimeType}');
    }
  }

  // ── Parser central ────────────────────────────────────────────────────────
  static ApiResponse _parse(http.Response response) {
    if (response.statusCode == 204) {
      return ApiResponse.success(null, statusCode: 204);
    }

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      return ApiResponse.error('Respuesta inválida del servidor.');
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        return ApiResponse.success(data, statusCode: response.statusCode);
      case 400:
        final msg = _extractError(data, fallback: 'Datos inválidos.');
        return ApiResponse.error(msg, statusCode: 400);
      case 401:
      case 403:
        return ApiResponse.error('Sin autorización.', statusCode: response.statusCode);
      case 404:
        return ApiResponse.error('Recurso no encontrado.', statusCode: 404);
      case 500:
      default:
        return ApiResponse.error(
          'Error del servidor (${response.statusCode}).',
          statusCode: response.statusCode,
        );
    }
  }

  static String _extractError(dynamic data, {required String fallback}) {
    if (data is Map) {
      if (data.containsKey('error')) return data['error'].toString();
      final first = data.values.first;
      if (first is List) return first.first.toString();
      return first.toString();
    }
    return fallback;
  }
}

// ── Modelo de respuesta tipada ────────────────────────────────────────────────
class ApiResponse {
  final dynamic data;
  final String? error;
  final bool success;
  final int? statusCode;

  const ApiResponse._({
    this.data,
    this.error,
    required this.success,
    this.statusCode,
  });

  factory ApiResponse.success(dynamic data, {int? statusCode}) =>
      ApiResponse._(data: data, success: true, statusCode: statusCode);

  factory ApiResponse.error(String error, {int? statusCode}) =>
      ApiResponse._(error: error, success: false, statusCode: statusCode);
}