// ============================================================
// ARCHIVO: lib/services/auth_service.dart
// CON TODOS LOS CAMPOS DEL SERIALIZER DE DJANGO
// ============================================================
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/api_config.dart';

class AuthService {
  static const String _base = '${ApiConfig.baseUrl}/api';
  static const Duration _timeout = Duration(seconds: 30);

  static String? _token;
  static Map<String, dynamic>? _usuario;

  static String? get token => _token;
  static Map<String, dynamic>? get usuario => _usuario;
  static bool get isLoggedIn => _token != null;

  static Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
  };

  static Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Token $_token',
  };

  static Future<void> actualizarPerfilLocal(
    Map<String, dynamic> nuevoPerfil,
  ) async {
    _usuario = nuevoPerfil;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_usuario', jsonEncode(nuevoPerfil));
  }

  // ============================================================
// ARCHIVO: lib/services/auth_service.dart
// AGREGAR MÉTODO PARA OBTENER TOKEN DE FORMA SEGURA
// ============================================================

// Agrega este método al final de la clase AuthService:
static Future<String?> getTokenSeguro() async {
  // Si ya tenemos token en memoria, usarlo
  if (_token != null) return _token;
  
  // Si no, intentar cargar desde SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString('auth_token');
  if (savedToken != null) {
    _token = savedToken;
    return _token;
  }
  return null;
}



// También modifica authHeaders para que sea async o usa un getter seguro:
static Future<Map<String, String>> getAuthHeaders() async {
  final token = await getTokenSeguro();
  return {
    'Content-Type': 'application/json',
    'Authorization': 'Token $token',
  };
}

  static Future<bool> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      final savedUsuario = prefs.getString('auth_usuario');

      if (savedToken != null && savedUsuario != null) {
        _token = savedToken;
        _usuario = jsonDecode(savedUsuario);
        print('✅ Sesión restaurada: ${_usuario?['nombre']}');
        return true;
      }
    } catch (e) {
      print('Error inicializando AuthService: $e');
    }
    return false;
  }

  // ============================================================
  // REGISTRO - COMPLETO CON TODOS LOS CAMPOS DE DJANGO
  // ============================================================
  static Future<void> registro({
    // Campos obligatorios
    required String nombre,
    required String email,
    required String password,
    required String confirmarPassword,

    // Campos opcionales del serializer
    String? fechaNacimiento, // Nuevo: fecha de nacimiento
    String? sexo, // masculino, femenino, otro
    double? peso, // en kg
    double? altura, // en cm
    int? aniosDiagnostico, // años desde diagnóstico
    double? hba1cInicial, // Nuevo: nivel de HbA1c inicial
    int? usaInsulina, // 0 o 1
    int? tieneHipertension, // 0 o 1
    int? tieneDislipidemia, // 0 o 1
    int? esFumador, // Nuevo: 0 o 1
    String? nivelActividadBase, // sedentario, moderado, activo
  }) async {
    try {
      final body = <String, dynamic>{
        // Campos requeridos
        'nombre': nombre,
        'email': email,
        'password': password,
        'confirmar_password': confirmarPassword,

        // Campos con valores por defecto
        'usa_insulina': usaInsulina ?? 0,
        'tiene_hipertension': tieneHipertension ?? 0,
        'tiene_dislipidemia': tieneDislipidemia ?? 0,
        'es_fumador': esFumador ?? 0,
        'nivel_actividad_base': nivelActividadBase ?? 'sedentario',
      };

      // Agregar solo los campos que tienen valor (no null)
      if (fechaNacimiento != null && fechaNacimiento.isNotEmpty) {
        body['fecha_nacimiento'] = fechaNacimiento;
      }
      if (sexo != null && sexo.isNotEmpty) {
        body['sexo'] = sexo;
      }
      if (peso != null) {
        body['peso'] = peso;
      }
      if (altura != null) {
        body['altura'] = altura;
      }
      if (aniosDiagnostico != null && aniosDiagnostico > 0) {
        body['anios_diagnostico'] = aniosDiagnostico;
      }
      if (hba1cInicial != null && hba1cInicial > 0) {
        body['hba1c_inicial'] = hba1cInicial;
      }

      print('📤 Enviando registro a Django...');
      print('URL: $_base/auth/registro/');
      print('Body: ${jsonEncode(body)}');

      final res = await http
          .post(
            Uri.parse('$_base/auth/registro/'),
            headers: _jsonHeaders,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      print('📥 Respuesta recibida. Status: ${res.statusCode}');
      print('📥 Body: ${res.body}');

      final data = jsonDecode(res.body);

      if (res.statusCode == 201) {
        final token = data['token'];
        final usuario = data['usuario'];

        print('✅ Registro exitoso!');
        print('Token: $token');
        print('Usuario ID: ${usuario['id']}');
        print('Nombre: ${usuario['nombre']}');

        await _guardarSesion(token, usuario);
      } else {
        throw Exception(_extraerError(data));
      }
    } on TimeoutException {
      throw Exception('⏰ Tiempo de espera agotado. Verifica tu conexión.');
    } on http.ClientException {
      throw Exception(
        '🔌 No se puede conectar al servidor. Verifica que el backend esté corriendo.',
      );
    } catch (e) {
      print('❌ Error en registro: $e');
      rethrow;
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================
  static Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      print('📤 Intentando login: $email');

      final res = await http
          .post(
            Uri.parse('$_base/auth/login/'),
            headers: _jsonHeaders,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);

      print('📥 Respuesta login. Status: ${res.statusCode}');
      print('📥 Body: ${res.body}');

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final token = data['token'];
        final usuario = data['usuario'];

        print('✅ Login exitoso!');
        print('Usuario: ${usuario['nombre']}');

        await _guardarSesion(token, usuario);
      } else {
        throw Exception(_extraerError(data));
      }
    } on TimeoutException {
      throw Exception('⏰ Tiempo de espera agotado.');
    } on http.ClientException {
      throw Exception('🔌 No se puede conectar al servidor.');
    } catch (e) {
      print('❌ Error en login: $e');
      rethrow;
    }
  }

  static Future<void> logout() async {
    try {
      await http
          .post(Uri.parse('$_base/auth/logout/'), headers: authHeaders)
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
    await _borrarSesion();
    print('👋 Sesión cerrada');
  }

  static Future<Map<String, dynamic>> getPerfil() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/auth/perfil/'), headers: authHeaders)
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _usuario = data;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_usuario', jsonEncode(data));
        return data;
      } else if (res.statusCode == 401) {
        await _borrarSesion();
        throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
      } else {
        throw Exception('No se pudo cargar el perfil.');
      }
    } catch (e) {
      print('❌ Error al obtener perfil: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updatePerfil(
    Map<String, dynamic> campos,
  ) async {
    try {
      final res = await http
          .put(
            Uri.parse('$_base/auth/perfil/'),
            headers: authHeaders,
            body: jsonEncode(campos),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _usuario = data;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_usuario', jsonEncode(data));
        return data;
      } else {
        throw Exception(_extraerError(jsonDecode(res.body)));
      }
    } catch (e) {
      print('❌ Error al actualizar perfil: $e');
      rethrow;
    }
  }

  static Future<void> _guardarSesion(
    String token,
    Map<String, dynamic> usuario,
  ) async {
    _token = token;
    _usuario = usuario;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_usuario', jsonEncode(usuario));

    print('💾 Sesión guardada para: ${usuario['nombre']}');
  }

  static Future<void> _borrarSesion() async {
    _token = null;
    _usuario = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_usuario');
  }

  static String _extraerError(Map<String, dynamic> data) {
    if (data.containsKey('detail')) return data['detail'].toString();
    if (data.containsKey('non_field_errors')) {
      final v = data['non_field_errors'];
      return v is List ? v.first.toString() : v.toString();
    }
    if (data.containsKey('email')) {
      final v = data['email'];
      return v is List ? v.first.toString() : v.toString();
    }
    if (data.containsKey('password')) {
      final v = data['password'];
      return v is List ? v.first.toString() : v.toString();
    }
    for (final val in data.values) {
      if (val is List && val.isNotEmpty) return val.first.toString();
      if (val is String) return val;
    }
    return 'Error desconocido. Intenta de nuevo.';
  }
}
