// // ============================================================
// // ARCHIVO: lib/services/auth_service.dart (VERSIÓN CORREGIDA)
// // ============================================================
// import 'dart:async'; // ← IMPORTANTE: Para TimeoutException
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class AuthService {
//   // ─── URL base ───────────────────────────────────────────────
//   // CAMBIA ESTO según tu configuración:
//   // Emulador Android  → 10.0.2.2
//   // Dispositivo físico → IP local de tu PC, ej: 192.168.1.5
//   // iOS simulator     → 127.0.0.1
//   // WEB (Chrome)      → localhost o IP real
//   static const String _base = 'http://localhost:8000/api';
  
//   // Timeout más razonable (30 segundos)
//   static const Duration _timeout = Duration(seconds: 30);

//   // ─── Estado en memoria ──────────────────────────────────────
//   static String? _token;
//   static Map<String, dynamic>? _usuario;

//   static String? get token   => _token;
//   static Map<String, dynamic>? get usuario => _usuario;
//   static bool get isLoggedIn => _token != null;

//   // ─── Headers ────────────────────────────────────────────────
//   static Map<String, String> get _jsonHeaders => {
//     'Content-Type': 'application/json',
//   };

//   static Map<String, String> get authHeaders => {
//     'Content-Type': 'application/json',
//     'Authorization': 'Token $_token',
//   };

//   // ============================================================
//   // INICIALIZACIÓN
//   // ============================================================
//   static Future<bool> init() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final savedToken   = prefs.getString('auth_token');
//       final savedUsuario = prefs.getString('auth_usuario');

//       if (savedToken != null && savedUsuario != null) {
//         _token   = savedToken;
//         _usuario = jsonDecode(savedUsuario);
//         return true;
//       }
//     } catch (e) {
//       print('Error inicializando AuthService: $e');
//     }
//     return false;
//   }

//   // ============================================================
//   // LOGIN (CON MEJOR MANEJO DE ERRORES)
//   // ============================================================
//   static Future<void> login({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       print('Intentando login con: $email');
//       print('URL: ${_base}auth/login/');
      
//       final res = await http
//           .post(
//             Uri.parse('$_base/auth/login/'),
//             headers: _jsonHeaders,
//             body: jsonEncode({'email': email, 'password': password}),
//           )
//           .timeout(_timeout);

//       print('Respuesta recibida. Status code: ${res.statusCode}');
//       print('Respuesta body: ${res.body}');

//       final data = jsonDecode(res.body);

//       if (res.statusCode == 200) {
//         await _guardarSesion(data['token'], data['usuario']);
//       } else {
//         throw Exception(_extraerError(data));
//       }
//     } on TimeoutException catch (e) {
//       // PRIMERO: TimeoutException (más específico)
//       print('Timeout: $e');
//       throw Exception('Tiempo de espera agotado. El servidor no responde. Verifica que el backend esté corriendo.');
//     } on http.ClientException catch (e) {
//       // SEGUNDO: ClientException (más general)
//       print('Error de conexión: $e');
//       throw Exception('No se puede conectar al servidor. Verifica que el backend esté corriendo en $_base');
//     } catch (e) {
//       // TERCERO: Cualquier otro error
//       print('Error inesperado: $e');
//       rethrow;
//     }
//   }

//   // ============================================================
//   // REGISTRO
//   // ============================================================
//   static Future<void> registro({
//     required String nombre,
//     required String email,
//     required String password,
//     required String confirmarPassword,
//     int?    aniosDiagnostico,
//     double? peso,
//     double? altura,
//     String? sexo,
//     int     usaInsulina       = 0,
//     int     tieneHipertension = 0,
//     int     tieneDislipidemia = 0,
//     String  nivelActividadBase = 'sedentario',
//   }) async {
//     try {
//       final body = <String, dynamic>{
//         'nombre'            : nombre,
//         'email'             : email,
//         'password'          : password,
//         'confirmar_password': confirmarPassword,
//         'usa_insulina'      : usaInsulina,
//         'tiene_hipertension': tieneHipertension,
//         'tiene_dislipidemia': tieneDislipidemia,
//         'nivel_actividad_base': nivelActividadBase,
//       };

//       if (aniosDiagnostico != null) body['anios_diagnostico'] = aniosDiagnostico;
//       if (peso    != null) body['peso']   = peso;
//       if (altura  != null) body['altura'] = altura;
//       if (sexo    != null) body['sexo']   = sexo;

//       final res = await http
//           .post(
//             Uri.parse('$_base/auth/registro/'),
//             headers: _jsonHeaders,
//             body: jsonEncode(body),
//           )
//           .timeout(_timeout);

//       final data = jsonDecode(res.body);

//       if (res.statusCode == 201) {
//         await _guardarSesion(data['token'], data['usuario']);
//       } else {
//         throw Exception(_extraerError(data));
//       }
//     } on TimeoutException catch (e) {
//       print('Timeout en registro: $e');
//       throw Exception('Tiempo de espera agotado. Verifica tu conexión y que el backend esté corriendo.');
//     } on http.ClientException catch (e) {
//       print('Error de conexión en registro: $e');
//       throw Exception('No se puede conectar al servidor. Asegúrate que el backend esté ejecutándose en $_base');
//     } catch (e) {
//       print('Error inesperado en registro: $e');
//       rethrow;
//     }
//   }

//   // ============================================================
//   // LOGOUT
//   // ============================================================
//   static Future<void> logout() async {
//     try {
//       await http
//           .post(
//             Uri.parse('$_base/auth/logout/'),
//             headers: authHeaders,
//           )
//           .timeout(const Duration(seconds: 10));
//     } catch (_) {
//       // Si falla la red igual borramos la sesión local
//     }
//     await _borrarSesion();
//   }

//   // ============================================================
//   // PERFIL
//   // ============================================================
//   static Future<Map<String, dynamic>> getPerfil() async {
//     try {
//       final res = await http
//           .get(
//             Uri.parse('$_base/auth/perfil/'),
//             headers: authHeaders,
//           )
//           .timeout(_timeout);

//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         _usuario = data;
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('auth_usuario', jsonEncode(data));
//         return data;
//       } else if (res.statusCode == 401) {
//         await _borrarSesion();
//         throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
//       } else {
//         throw Exception('No se pudo cargar el perfil.');
//       }
//     } on TimeoutException catch (e) {
//       print('Timeout en getPerfil: $e');
//       throw Exception('Tiempo de espera agotado al cargar el perfil.');
//     } on http.ClientException catch (e) {
//       print('Error de conexión en getPerfil: $e');
//       throw Exception('Error de conexión al cargar el perfil.');
//     } catch (e) {
//       print('Error inesperado en getPerfil: $e');
//       rethrow;
//     }
//   }

//   static Future<Map<String, dynamic>> updatePerfil(
//       Map<String, dynamic> campos) async {
//     try {
//       final res = await http
//           .put(
//             Uri.parse('$_base/auth/perfil/'),
//             headers: authHeaders,
//             body: jsonEncode(campos),
//           )
//           .timeout(_timeout);

//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         _usuario = data;
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('auth_usuario', jsonEncode(data));
//         return data;
//       } else {
//         throw Exception(_extraerError(jsonDecode(res.body)));
//       }
//     } on TimeoutException catch (e) {
//       print('Timeout en updatePerfil: $e');
//       throw Exception('Tiempo de espera agotado al actualizar el perfil.');
//     } on http.ClientException catch (e) {
//       print('Error de conexión en updatePerfil: $e');
//       throw Exception('Error de conexión al actualizar el perfil.');
//     } catch (e) {
//       print('Error inesperado en updatePerfil: $e');
//       rethrow;
//     }
//   }

//   // ============================================================
//   // HELPERS PRIVADOS
//   // ============================================================
//   static Future<void> _guardarSesion(
//       String token, Map<String, dynamic> usuario) async {
//     _token   = token;
//     _usuario = usuario;

//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('auth_token',   token);
//     await prefs.setString('auth_usuario', jsonEncode(usuario));
//   }

//   static Future<void> _borrarSesion() async {
//     _token   = null;
//     _usuario = null;

//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('auth_token');
//     await prefs.remove('auth_usuario');
//   }

//   static String _extraerError(Map<String, dynamic> data) {
//     if (data.containsKey('detail')) return data['detail'].toString();
//     if (data.containsKey('non_field_errors')) {
//       final v = data['non_field_errors'];
//       return v is List ? v.first.toString() : v.toString();
//     }
//     for (final val in data.values) {
//       if (val is List && val.isNotEmpty) return val.first.toString();
//       if (val is String) return val;
//     }
//     return 'Error desconocido. Intenta de nuevo.';
//   }
// }




// ============================================================
// ARCHIVO: lib/services/auth_service.dart
// VERSIÓN CORREGIDA PARA TU API
// ============================================================
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ─── URL base ───────────────────────────────────────────────
  static const String _base = 'http://localhost:8000/api';
  static const Duration _timeout = Duration(seconds: 30);

  // ─── Estado en memoria ──────────────────────────────────────
  static String? _token;
  static Map<String, dynamic>? _usuario;

  static String? get token => _token;
  static Map<String, dynamic>? get usuario => _usuario;
  static bool get isLoggedIn => _token != null;

  // ─── Headers ────────────────────────────────────────────────
  static Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
  };

  static Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Token $_token',
  };

  // ============================================================
  // INICIALIZACIÓN
  // ============================================================
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
  // REGISTRO (CORREGIDO)
  // ============================================================
  static Future<void> registro({
    required String nombre,
    required String email,
    required String password,
    required String confirmarPassword,
    int? aniosDiagnostico,
    double? peso,
    double? altura,
    String? sexo,
    int usaInsulina = 0,
    int tieneHipertension = 0,
    int tieneDislipidemia = 0,
    String nivelActividadBase = 'sedentario',
  }) async {
    try {
      final body = <String, dynamic>{
        'nombre': nombre,
        'email': email,
        'password': password,
        'confirmar_password': confirmarPassword,
        'usa_insulina': usaInsulina,
        'tiene_hipertension': tieneHipertension,
        'tiene_dislipidemia': tieneDislipidemia,
        'nivel_actividad_base': nivelActividadBase,
      };

      if (aniosDiagnostico != null) body['anios_diagnostico'] = aniosDiagnostico;
      if (peso != null) body['peso'] = peso;
      if (altura != null) body['altura'] = altura;
      if (sexo != null) body['sexo'] = sexo;

      print('📤 Enviando registro...');
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
        // Tu API devuelve: { "token": "...", "usuario": {...} }
        final token = data['token'];
        final usuario = data['usuario'];
        
        print('✅ Registro exitoso!');
        print('Token: $token');
        print('Usuario: ${usuario['nombre']}');
        
        await _guardarSesion(token, usuario);
      } else {
        throw Exception(_extraerError(data));
      }
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Verifica tu conexión.');
    } on http.ClientException {
      throw Exception('No se puede conectar al servidor.');
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
      throw Exception('Tiempo de espera agotado.');
    } on http.ClientException {
      throw Exception('No se puede conectar al servidor.');
    } catch (e) {
      print('❌ Error en login: $e');
      rethrow;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  static Future<void> logout() async {
    try {
      await http
          .post(
            Uri.parse('$_base/auth/logout/'),
            headers: authHeaders,
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
    await _borrarSesion();
    print('👋 Sesión cerrada');
  }

  // ============================================================
  // PERFIL - Obtener
  // ============================================================
  static Future<Map<String, dynamic>> getPerfil() async {
    try {
      final res = await http
          .get(
            Uri.parse('$_base/auth/perfil/'),
            headers: authHeaders,
          )
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

  // ============================================================
  // PERFIL - Actualizar
  // ============================================================
  static Future<Map<String, dynamic>> updatePerfil(
      Map<String, dynamic> campos) async {
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

  // ============================================================
  // HELPERS PRIVADOS
  // ============================================================
  static Future<void> _guardarSesion(
      String token, Map<String, dynamic> usuario) async {
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
    for (final val in data.values) {
      if (val is List && val.isNotEmpty) return val.first.toString();
      if (val is String) return val;
    }
    return 'Error desconocido. Intenta de nuevo.';
  }
}