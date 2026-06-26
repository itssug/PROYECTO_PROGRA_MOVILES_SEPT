
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

// ─── Modelos ─────────────────────────────────────────────────

class ComidaApi {
  final int id;
  final String nombre;
  final String? descripcion;
  final String categoria;
  final double? calorias;
  final double? carbohidratos;
  final double? azucares;
  final double? fibra;
  final double? proteinas;
  final double? grasas;
  final double? sodio;
  final int? indiceGlucemico;
  final double? cargaGlucemica;
  final String unidadMedida;
  final double porcionTipica;
  final bool esPersonalizado;

  ComidaApi({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.categoria,
    this.calorias,
    this.carbohidratos,
    this.azucares,
    this.fibra,
    this.proteinas,
    this.grasas,
    this.sodio,
    this.indiceGlucemico,
    this.cargaGlucemica,
    required this.unidadMedida,
    required this.porcionTipica,
    required this.esPersonalizado,
  });

  factory ComidaApi.fromJson(Map<String, dynamic> json) {
    return ComidaApi(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      categoria: json['categoria'] ?? '',
      calorias: _toDouble(json['calorias']),
      carbohidratos: _toDouble(json['carbohidratos']),
      azucares: _toDouble(json['azucares']),
      fibra: _toDouble(json['fibra']),
      proteinas: _toDouble(json['proteinas']),
      grasas: _toDouble(json['grasas']),
      sodio: _toDouble(json['sodio']),
      indiceGlucemico: json['indice_glucemico'],
      cargaGlucemica: _toDouble(json['carga_glucemica']),
      unidadMedida: json['unidad_medida'] ?? 'gramos',
      porcionTipica: _toDouble(json['porcion_tipica']) ?? 100,
      esPersonalizado: json['es_personalizado'] == 1 || json['es_personalizado'] == true,
    );
  }
}

class RegistroComidaApi {
  final int id;
  final int comidaId;
  final String comidaNombre;
  final String comidaCategoria;
  final double cantidad;
  final String unidad;
  final String tipoComida;
  final String fecha;
  final String hora;
  final double? caloriasCalculadas;
  final double? carbohidratosCalculados;
  final double? azucaresCalculados;
  final double? cargaGlucemica;
  final String? notas;

  RegistroComidaApi({
    required this.id,
    required this.comidaId,
    required this.comidaNombre,
    required this.comidaCategoria,
    required this.cantidad,
    required this.unidad,
    required this.tipoComida,
    required this.fecha,
    required this.hora,
    this.caloriasCalculadas,
    this.carbohidratosCalculados,
    this.azucaresCalculados,
    this.cargaGlucemica,
    this.notas,
  });

  factory RegistroComidaApi.fromJson(Map<String, dynamic> json) {
    return RegistroComidaApi(
      id: json['id'],
      comidaId: json['comida_id'] ?? json['comida'] ?? 0,
      comidaNombre: json['comida_nombre'] ?? '',
      comidaCategoria: json['comida_categoria'] ?? '',
      cantidad: _toDouble(json['cantidad']) ?? 0,
      unidad: json['unidad'] ?? 'gramos',
      tipoComida: json['tipo_comida'] ?? '',
      fecha: json['fecha'] ?? '',
      hora: json['hora'] ?? '',
      caloriasCalculadas: _toDouble(json['calorias_calculadas']),
      carbohidratosCalculados: _toDouble(json['carbohidratos_calculados']),
      azucaresCalculados: _toDouble(json['azucares_calculados']),
      cargaGlucemica: _toDouble(json['carga_glucemica_calc']),
      notas: json['notas'],
    );
  }
}

class ResumenDiario {
  final String fecha;
  final double totalCalorias;
  final double totalCarbohidratos;
  final double totalAzucares;
  final double totalCargaGlucemica;
  final int cantidadRegistros;
  final Map<String, double> porTipoComida;

  ResumenDiario({
    required this.fecha,
    required this.totalCalorias,
    required this.totalCarbohidratos,
    required this.totalAzucares,
    required this.totalCargaGlucemica,
    required this.cantidadRegistros,
    required this.porTipoComida,
  });

  factory ResumenDiario.fromJson(Map<String, dynamic> json) {
    final porTipo = <String, double>{};
    if (json['por_tipo_comida'] != null) {
      (json['por_tipo_comida'] as Map<String, dynamic>).forEach((k, v) {
        porTipo[k] = (v is num) ? v.toDouble() : 0;
      });
    }
    return ResumenDiario(
      fecha: json['fecha'] ?? '',
      totalCalorias: _toDouble(json['total_calorias']) ?? 0,
      totalCarbohidratos: _toDouble(json['total_carbohidratos']) ?? 0,
      totalAzucares: _toDouble(json['total_azucares']) ?? 0,
      totalCargaGlucemica: _toDouble(json['total_carga_glucemica']) ?? 0,
      cantidadRegistros: json['cantidad_registros'] ?? 0,
      porTipoComida: porTipo,
    );
  }
}

// ─── Excepción personalizada ─────────────────────────────────

class AlimentacionException implements Exception {
  final String message;
  const AlimentacionException(this.message);
  @override
  String toString() => message;
}

// ─── Helper para parsear decimals de Django ──────────────────

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

// ─── Servicio principal ──────────────────────────────────────

class AlimentacionService {
  static const String _base = '${ApiConfig.baseUrl}/api/alimentacion';
  static const Duration _timeout = Duration(seconds: 15);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Token ${AuthService.token}',
      };

  // ── BUSCAR ALIMENTOS ────────────────────────────────────────

  static Future<List<ComidaApi>> buscarAlimentos(String query) async {
    try {
      final url = '$_base/comidas/?buscar=${Uri.encodeComponent(query)}';
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => ComidaApi.fromJson(e)).toList();
      }
      throw AlimentacionException('Error al buscar alimentos: ${res.statusCode}');
    } catch (e) {
      if (e is AlimentacionException) rethrow;
      throw AlimentacionException('No se pudo conectar al servidor.');
    }
  }

  static Future<List<ComidaApi>> getCatalogo({String? categoria}) async {
    try {
      String url = '$_base/comidas/';
      if (categoria != null) url += '?categoria=${Uri.encodeComponent(categoria)}';

      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => ComidaApi.fromJson(e)).toList();
      }
      throw AlimentacionException('Error al cargar catálogo: ${res.statusCode}');
    } catch (e) {
      if (e is AlimentacionException) rethrow;
      throw AlimentacionException('No se pudo conectar al servidor.');
    }
  }

  // ── REGISTROS DE COMIDAS ────────────────────────────────────

  static Future<List<RegistroComidaApi>> getRegistrosDia({String? fecha}) async {
    try {
      String url = '$_base/registro/';
      if (fecha != null) url += '?fecha=$fecha';

      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => RegistroComidaApi.fromJson(e)).toList();
      }
      if (res.statusCode == 401) {
        throw AlimentacionException('Sesión expirada. Vuelve a iniciar sesión.');
      }
      throw AlimentacionException('Error al cargar registros: ${res.statusCode}');
    } catch (e) {
      if (e is AlimentacionException) rethrow;
      throw AlimentacionException('No se pudo conectar al servidor.');
    }
  }

  static Future<RegistroComidaApi> registrarComida({
    required int comidaId,
    required double cantidad,
    required String tipoComida,
    required String fecha,
    required String hora,
    String unidad = 'gramos',
    String? notas,
  }) async {
    try {
      final body = {
        'comida_id': comidaId,
        'cantidad': cantidad,
        'tipo_comida': tipoComida,
        'fecha': fecha,
        'hora': hora,
        'unidad': unidad,
        if (notas != null && notas.isNotEmpty) 'notas': notas,
      };

      final res = await http
          .post(
            Uri.parse('$_base/registro/'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (res.statusCode == 201) {
        return RegistroComidaApi.fromJson(jsonDecode(res.body));
      }
      if (res.statusCode == 401) {
        throw AlimentacionException('Sesión expirada.');
      }

      try {
        final error = jsonDecode(res.body);
        final msg = error.values.first;
        throw AlimentacionException(
            msg is List ? msg.first.toString() : msg.toString());
      } catch (_) {
        throw AlimentacionException('Error al registrar comida: ${res.statusCode}');
      }
    } catch (e) {
      if (e is AlimentacionException) rethrow;
      throw AlimentacionException('No se pudo conectar al servidor.');
    }
  }

  // ── NUEVO: EDITAR REGISTRO DE COMIDA ────────────────────────
  static Future<RegistroComidaApi> editarRegistro({
    required int registroId,
    double? cantidad,
    String? tipoComida,
    String? hora,
    String? unidad,
    String? notas,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (cantidad != null) body['cantidad'] = cantidad;
      if (tipoComida != null) body['tipo_comida'] = tipoComida;
      if (hora != null) body['hora'] = hora;
      if (unidad != null) body['unidad'] = unidad;
      if (notas != null) body['notas'] = notas;

      final res = await http
          .put(
            Uri.parse('$_base/registro/$registroId/'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        return RegistroComidaApi.fromJson(jsonDecode(res.body));
      }
      if (res.statusCode == 401) {
        throw AlimentacionException('Sesión expirada.');
      }
      if (res.statusCode == 404) {
        throw AlimentacionException('Registro no encontrado.');
      }

      try {
        final error = jsonDecode(res.body);
        final msg = error.values.first;
        throw AlimentacionException(
            msg is List ? msg.first.toString() : msg.toString());
      } catch (_) {
        throw AlimentacionException('Error al editar registro: ${res.statusCode}');
      }
    } catch (e) {
      if (e is AlimentacionException) rethrow;
      throw AlimentacionException('No se pudo conectar al servidor.');
    }
  }

  static Future<Map<String, dynamic>> getResumenHistorico({int dias = 7}) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/historico/?dias=$dias'), headers: _headers)
          .timeout(_timeout);

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      throw AlimentacionException('Error al cargar historial.');
    } catch (e) {
      if (e is AlimentacionException) rethrow;
      throw AlimentacionException('No se pudo conectar al servidor.');
    }
  }

  static Future<List<dynamic>> getDietasCatalogo() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/dietas/'), headers: _headers)
          .timeout(_timeout);

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> eliminarRegistro(int registroId) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$_base/registro/$registroId/'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        throw AlimentacionException('Error al eliminar registro: ${res.statusCode}');
      }
    } catch (e) {
      if (e is AlimentacionException) rethrow;
      throw AlimentacionException('No se pudo conectar al servidor.');
    }
  }

  // ── RESUMEN DIARIO ──────────────────────────────────────────

  static Future<ResumenDiario> getResumenDia({String? fecha}) async {
    try {
      String url = '$_base/resumen/';
      if (fecha != null) url += '?fecha=$fecha';

      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(_timeout);

      if (res.statusCode == 200) {
        return ResumenDiario.fromJson(jsonDecode(res.body));
      }
      if (res.statusCode == 401) {
        throw AlimentacionException('Sesión expirada.');
      }
      throw AlimentacionException('Error al cargar resumen: ${res.statusCode}');
    } catch (e) {
      if (e is AlimentacionException) rethrow;
      throw AlimentacionException('No se pudo conectar al servidor.');
    }
  }

  // ── ALIMENTOS PERSONALIZADOS ────────────────────────────────

  static Future<ComidaApi> crearAlimentoPersonalizado({
    required String nombre,
    required String categoria,
    double? calorias,
    double? carbohidratos,
    double? azucares,
    double? proteinas,
    double? grasas,
    int? indiceGlucemico,
    String unidadMedida = 'gramos',
    double porcionTipica = 100,
    String? descripcion,
  }) async {
    try {
      final body = {
        'nombre': nombre,
        'categoria': categoria,
        'unidad_medida': unidadMedida,
        'porcion_tipica': porcionTipica,
        if (descripcion != null) 'descripcion': descripcion,
        if (calorias != null) 'calorias': calorias,
        if (carbohidratos != null) 'carbohidratos': carbohidratos,
        if (azucares != null) 'azucares': azucares,
        if (proteinas != null) 'proteinas': proteinas,
        if (grasas != null) 'grasas': grasas,
        if (indiceGlucemico != null) 'indice_glucemico': indiceGlucemico,
      };

      final res = await http
          .post(
            Uri.parse('$_base/comidas/crear/'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (res.statusCode == 201) {
        return ComidaApi.fromJson(jsonDecode(res.body));
      }
      throw AlimentacionException('Error al crear alimento: ${res.statusCode}');
    } catch (e) {
      if (e is AlimentacionException) rethrow;
      throw AlimentacionException('No se pudo conectar al servidor.');
    }
  }
}