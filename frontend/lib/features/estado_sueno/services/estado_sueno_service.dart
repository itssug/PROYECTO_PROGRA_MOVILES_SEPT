import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/estado_emocional_model.dart';
import '../models/registro_sueno_model.dart';

class EstadoSuenoService {
  static const String baseUrl = 'http://localhost:8000/api/estado-sueno';
  // En dispositivo real: usa la IP de tu PC en la red local

  // ── Estado Emocional ──────────────────────────
  static Future<List<EstadoEmocional>> getEstados(int usuarioId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/estado-emocional/?usuario_id=$usuarioId'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => EstadoEmocional.fromJson(e)).toList();
    }
    throw Exception('Error al cargar estados emocionales');
  }

  static Future<EstadoEmocional> createEstado(EstadoEmocional e) async {
    final res = await http.post(
      Uri.parse('$baseUrl/estado-emocional/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(e.toJson()),
    );
    if (res.statusCode == 201) return EstadoEmocional.fromJson(jsonDecode(res.body));
    throw Exception('Error al crear estado emocional');
  }

  // ── Registro Sueño ────────────────────────────
  static Future<List<RegistroSueno>> getSuenos(int usuarioId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/registro-sueno/?usuario_id=$usuarioId'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => RegistroSueno.fromJson(e)).toList();
    }
    throw Exception('Error al cargar registros de sueño');
  }

  static Future<RegistroSueno> createSueno(RegistroSueno s) async {
    final res = await http.post(
      Uri.parse('$baseUrl/registro-sueno/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(s.toJson()),
    );
    if (res.statusCode == 201) return RegistroSueno.fromJson(jsonDecode(res.body));
    throw Exception('Error al crear registro de sueño');
  }
}