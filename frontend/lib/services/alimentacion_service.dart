import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// ─── Modelos de Respuesta de la API ──────────────────────────────────────────

class ComidaApi {
  final int id;
  final String nombre;
  final String categoria;
  final double? calorias;
  final double? carbohidratos;
  final double? azucares;
  final double? proteinas;
  final double? grasas;
  final int? indiceGlucemico;
  final double? cargaGlucemica;
  final String unidadMedida;
  final double porcionTipica;
  final bool esPersonalizado;

  ComidaApi({
    required this.id,
    required this.nombre,
    required this.categoria,
    this.calorias,
    this.carbohidratos,
    this.azucares,
    this.proteinas,
    this.grasas,
    this.indiceGlucemico,
    this.cargaGlucemica,
    required this.unidadMedida,
    required this.porcionTipica,
    required this.esPersonalizado,
  });

  factory ComidaApi.fromJson(Map<String, dynamic> json) {
    return ComidaApi(
      id: json['id'],
      nombre: json['nombre'],
      categoria: json['categoria'],
      calorias: json['calorias'] != null ? double.parse(json['calorias'].toString()) : null,
      carbohidratos: json['carbohidratos'] != null ? double.parse(json['carbohidratos'].toString()) : null,
      azucares: json['azucares'] != null ? double.parse(json['azucares'].toString()) : null,
      proteinas: json['proteinas'] != null ? double.parse(json['proteinas'].toString()) : null,
      grasas: json['grasas'] != null ? double.parse(json['grasas'].toString()) : null,
      indiceGlucemico: json['indiceGlucemico'],
      cargaGlucemica: json['cargaGlucemica'] != null ? double.parse(json['cargaGlucemica'].toString()) : null,
      unidadMedida: json['unidadMedida'] ?? 'gramos',
      porcionTipica: json['porcionTipica'] != null ? double.parse(json['porcionTipica'].toString()) : 100.0,
      esPersonalizado: json['esPersonalizado'] ?? false,
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
  final String tipoComidaDisplay;
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
    required this.tipoComidaDisplay,
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
      comidaId: json['comidaId'],
      comidaNombre: json['comidaNombre'] ?? '',
      comidaCategoria: json['comidaCategoria'] ?? '',
      cantidad: double.parse(json['cantidad'].toString()),
      unidad: json['unidad'] ?? 'gramos',
      tipoComida: json['tipoComida'] ?? '',
      tipoComidaDisplay: json['tipoComidaDisplay'] ?? '',
      fecha: json['fecha'],
      hora: json['hora'],
      caloriasCalculadas: json['caloriasCalculadas'] != null ? double.parse(json['caloriasCalculadas'].toString()) : null,
      carbohidratosCalculados: json['carbohidratosCalculados'] != null ? double.parse(json['carbohidratosCalculados'].toString()) : null,
      azucaresCalculados: json['azucaresCalculados'] != null ? double.parse(json['azucaresCalculados'].toString()) : null,
      cargaGlucemica: json['cargaGlucemica'] != null ? double.parse(json['cargaGlucemica'].toString()) : null,
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
    Map<String, double> tipoComidaMap = {};
    if (json['porTipoComida'] != null) {
      json['porTipoComida'].forEach((k, v) {
        tipoComidaMap[k] = double.parse(v.toString());
      });
    }

    return ResumenDiario(
      fecha: json['fecha'] ?? '',
      totalCalorias: json['totalCalorias'] != null ? double.parse(json['totalCalorias'].toString()) : 0.0,
      totalCarbohidratos: json['totalCarbohidratos'] != null ? double.parse(json['totalCarbohidratos'].toString()) : 0.0,
      totalAzucares: json['totalAzucares'] != null ? double.parse(json['totalAzucares'].toString()) : 0.0,
      totalCargaGlucemica: json['totalCargaGlucemica'] != null ? double.parse(json['totalCargaGlucemica'].toString()) : 0.0,
      cantidadRegistros: json['cantidadRegistros'] ?? 0,
      porTipoComida: tipoComidaMap,
    );
  }
}

// ─── Excepción Personalizada ─────────────────────────────────────────────────

class AlimentacionException implements Exception {
  final String message;
  const AlimentacionException(this.message);
  @override
  String toString() => message;
}

// ─── Servicio Principal (Conexión Real Backend) ──────────────────────────────

class AlimentacionService {
  final String _token;

  AlimentacionService({required String token}) : _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  // ── Operaciones de Comidas (Catálogo) ───────────────────────────────────────

  Future<List<ComidaApi>> getCatalogo({String? categoria}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/alimentacion/catalogo/').replace(
          queryParameters: categoria != null ? {'categoria': categoria} : null);
          
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((c) => ComidaApi.fromJson(c)).toList();
      } else {
        throw const AlimentacionException('Error al cargar el catálogo de comidas.');
      }
    } catch (e) {
      throw AlimentacionException('Fallo de conexión: $e');
    }
  }

  Future<List<ComidaApi>> buscarAlimentos(String query) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/alimentacion/buscar/').replace(
          queryParameters: {'q': query});
          
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((c) => ComidaApi.fromJson(c)).toList();
      } else {
        throw const AlimentacionException('Error al buscar alimentos.');
      }
    } catch (e) {
      throw AlimentacionException('Fallo de conexión: $e');
    }
  }

  Future<ComidaApi> crearAlimentoPersonalizado({
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/alimentacion/catalogo/'),
        headers: _headers,
        body: json.encode({
          'nombre': nombre,
          'categoria': categoria,
          'calorias': calorias,
          'carbohidratos': carbohidratos,
          'azucares': azucares,
          'proteinas': proteinas,
          'grasas': grasas,
          'indiceGlucemico': indiceGlucemico,
          'unidadMedida': unidadMedida,
          'porcionTipica': porcionTipica,
          'descripcion': descripcion,
        }),
      );

      if (response.statusCode == 201) {
        return ComidaApi.fromJson(json.decode(response.body));
      } else {
        throw const AlimentacionException('Error al crear el alimento personalizado.');
      }
    } catch (e) {
      throw AlimentacionException('Fallo de conexión: $e');
    }
  }

  // ── Registro de Comidas consumidas ──────────────────────────────────────────

  Future<List<RegistroComidaApi>> getRegistrosDia({String? fecha}) async {
    try {
      final targetDate = fecha ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/alimentacion/registros/').replace(
          queryParameters: {'fecha': targetDate});
          
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((r) => RegistroComidaApi.fromJson(r)).toList();
      } else {
        throw const AlimentacionException('Error al cargar registros del día.');
      }
    } catch (e) {
      throw AlimentacionException('Fallo de conexión: $e');
    }
  }

  Future<RegistroComidaApi> registrarComida({
    required int comidaId,
    required double cantidad,
    required String tipoComida,
    required String fecha,
    required String hora,
    String unidad = 'gramos',
    String? notas,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/alimentacion/registros/'),
        headers: _headers,
        body: json.encode({
          'comidaId': comidaId,
          'cantidad': cantidad,
          'tipoComida': tipoComida,
          'fecha': fecha,
          'hora': hora,
          'unidad': unidad,
          'notas': notas,
        }),
      );

      if (response.statusCode == 201) {
        return RegistroComidaApi.fromJson(json.decode(response.body));
      } else {
        throw const AlimentacionException('Error al registrar la comida.');
      }
    } catch (e) {
      throw AlimentacionException('Fallo de conexión: $e');
    }
  }

  Future<void> eliminarRegistro(int registroId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/alimentacion/registros/$registroId/'),
        headers: _headers,
      );

      if (response.statusCode != 204) {
        throw const AlimentacionException('Error al eliminar el registro.');
      }
    } catch (e) {
      throw AlimentacionException('Fallo de conexión: $e');
    }
  }

  // ── Resúmenes Diarios e Historial ───────────────────────────────────────────

  Future<ResumenDiario> getResumenDia({String? fecha}) async {
    try {
      final targetDate = fecha ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/alimentacion/resumen/').replace(
          queryParameters: {'fecha': targetDate});
          
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        return ResumenDiario.fromJson(json.decode(response.body));
      } else {
        throw const AlimentacionException('Error al cargar el resumen diario.');
      }
    } catch (e) {
      throw AlimentacionException('Fallo de conexión: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHistorial({int dias = 7}) async {
    return []; // Aún no implementado en backend.
  }
}