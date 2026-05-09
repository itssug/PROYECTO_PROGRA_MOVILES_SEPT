// ============================================================
// ARCHIVO: lib/services/perfil_service.dart (VERSIÓN CORREGIDA)
// ============================================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import '../screens/app_colors.dart';

class PerfilService {
  static const String _base = 'http://localhost:8000/api';
  static const Duration _timeout = Duration(seconds: 30);

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
      print('📤 GET Perfil - Headers: $headers');

      final response = await http
          .get(Uri.parse('$_base/auth/perfil/'), headers: headers)
          .timeout(_timeout);

      print('📥 GET Perfil - Status: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = _normalizarPerfil(jsonDecode(response.body)); // ← añadir
        await _actualizarCacheLocal(data);
        return data;
      } else if (response.statusCode == 401) {
        print('⚠️ Token inválido, cerrando sesión...');
        await AuthService.logout();
        throw Exception('Sesión expirada. Inicia sesión nuevamente.');
      } else {
        throw Exception('Error al cargar perfil: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getPerfil: $e');
      rethrow;
    }
  }

  // ============================================================
  // ACTUALIZAR PERFIL
  // ============================================================
  static Future<Map<String, dynamic>> updatePerfil(
    Map<String, dynamic> cambios,
  ) async {
    try {
      final headers = await _getAuthHeaders();

      final camposPermitidos = [
        'nombre',
        'email',
        'fecha_nacimiento',
        'sexo',
        'peso',
        'altura',
        'anios_diagnostico',
        'hba1c_inicial',
        'usa_insulina',
        'tiene_hipertension',
        'tiene_dislipidemia',
        'es_fumador',
        'nivel_actividad_base',
      ];

      final datosAActualizar = <String, dynamic>{};
      for (var key in cambios.keys) {
        if (camposPermitidos.contains(key)) {
          datosAActualizar[key] = cambios[key];
        }
      }

      if (datosAActualizar.isEmpty) {
        throw Exception('No hay campos válidos para actualizar');
      }

      print('📤 PUT Perfil - Enviando: ${jsonEncode(datosAActualizar)}');

      final response = await http
          .put(
            Uri.parse('$_base/auth/perfil/'),
            headers: headers,
            body: jsonEncode(datosAActualizar),
          )
          .timeout(_timeout);

      print('📥 PUT Perfil - Status: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = _normalizarPerfil(jsonDecode(response.body)); // ← añadir
        await _actualizarCacheLocal(data);
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(_extraerError(error));
      }
    } catch (e) {
      print('❌ Error en updatePerfil: $e');
      rethrow;
    }
  }

  // ============================================================
  // VERIFICAR TOKEN
  // ============================================================
  static Future<bool> verificarToken() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .get(Uri.parse('$_base/auth/perfil/'), headers: headers)
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // MÉTODOS ESPECÍFICOS
  // ============================================================
  static Map<String, dynamic> _normalizarPerfil(Map<String, dynamic> data) {
    // Django devuelve DecimalFields como strings ("55.00") → convertir a double
    const camposDouble = ['peso', 'altura', 'hba1c_inicial'];
    for (final campo in camposDouble) {
      if (data[campo] is String) {
        data[campo] = double.tryParse(data[campo]);
      }
    }
    return data;
  }

  static Future<Map<String, dynamic>> updateDatosBasicos({
    required String nombre,
    required String email,
  }) async {
    return await updatePerfil({'nombre': nombre, 'email': email});
  }

  static Future<Map<String, dynamic>> updateMedidas({
    required double peso,
    required double altura,
  }) async {
    return await updatePerfil({'peso': peso, 'altura': altura});
  }

  static Future<Map<String, dynamic>> updateDatosClinicos({
    int? aniosDiagnostico,
    double? hba1cInicial,
    String? nivelActividadBase,
  }) async {
    final cambios = <String, dynamic>{};
    if (aniosDiagnostico != null)
      cambios['anios_diagnostico'] = aniosDiagnostico;
    if (hba1cInicial != null) cambios['hba1c_inicial'] = hba1cInicial;
    if (nivelActividadBase != null)
      cambios['nivel_actividad_base'] = nivelActividadBase;
    return await updatePerfil(cambios);
  }

  static Future<Map<String, dynamic>> updateCondicionesMedicas({
    int? usaInsulina,
    int? tieneHipertension,
    int? tieneDislipidemia,
    int? esFumador,
  }) async {
    final cambios = <String, dynamic>{};
    if (usaInsulina != null) cambios['usa_insulina'] = usaInsulina;
    if (tieneHipertension != null)
      cambios['tiene_hipertension'] = tieneHipertension;
    if (tieneDislipidemia != null)
      cambios['tiene_dislipidemia'] = tieneDislipidemia;
    if (esFumador != null) cambios['es_fumador'] = esFumador;
    return await updatePerfil(cambios);
  }

  static Future<Map<String, dynamic>> updateInfoPersonal({
    String? sexo,
    String? fechaNacimiento,
  }) async {
    final cambios = <String, dynamic>{};
    if (sexo != null) cambios['sexo'] = sexo;
    if (fechaNacimiento != null) cambios['fecha_nacimiento'] = fechaNacimiento;
    return await updatePerfil(cambios);
  }

  // ============================================================
  // CÁLCULO DE IMC
  // ============================================================
  static double? calcularIMC(dynamic peso, dynamic altura) {
    try {
      final p = peso is double ? peso : double.tryParse(peso.toString());
      final a = altura is double ? altura : double.tryParse(altura.toString());
      if (p == null || a == null || a <= 0) return null;
      final alturaMetros = a / 100;
      return p / (alturaMetros * alturaMetros);
    } catch (_) {
      return null;
    }
  }

  static String getCategoriaIMC(double? imc) {
    if (imc == null) return 'No disponible';
    if (imc < 18.5) return 'Bajo peso ⚠️';
    if (imc < 25) return 'Normal ✅';
    if (imc < 30) return 'Sobrepeso ⚠️';
    return 'Obesidad 🔴';
  }

  static Color getColorIMC(double? imc) {
    if (imc == null) return AppColors.textMuted;
    if (imc < 18.5) return Colors.blue;
    if (imc < 25) return Colors.green;
    if (imc < 30) return Colors.orange;
    return Colors.red;
  }

  // ============================================================
  // FORMATEO DE FECHAS
  // ============================================================
  static String formatearFecha(DateTime fecha) {
    return fecha.toIso8601String().split('T')[0];
  }

  static DateTime? parsearFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return null;
    try {
      return DateTime.parse(fecha);
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // HELPERS PRIVADOS
  // ============================================================
  static Future<void> _actualizarCacheLocal(Map<String, dynamic> perfil) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_usuario', jsonEncode(perfil));
    await AuthService.actualizarPerfilLocal(perfil);
  }

  static String _extraerError(Map<String, dynamic> data) {
    if (data.containsKey('error')) return data['error'].toString();
    if (data.containsKey('detail')) return data['detail'].toString();
    if (data.containsKey('non_field_errors')) {
      final v = data['non_field_errors'];
      return v is List ? v.first.toString() : v.toString();
    }
    for (final val in data.values) {
      if (val is List && val.isNotEmpty) return val.first.toString();
      if (val is String) return val;
    }
    return 'Error al actualizar el perfil';
  }
}
