import '../models/registro_model.dart';
import 'api_client.dart';
import 'medicamento_service.dart'; // reutiliza ServiceResult

class RegistroService {
  static const String _base = '/med-trat/registros';

  // ── GET /registros/ — historial completo ──────────────────────────────────
  static Future<ServiceResult<List<RegistroMedicamento>>> historial() async {
    final res = await ApiClient.get('$_base/');
    if (!res.success) return ServiceResult.error(res.error!);

    try {
      final lista = (res.data as List)
          .map((e) => RegistroMedicamento.fromJson(e))
          .toList();
      return ServiceResult.success(lista);
    } catch (_) {
      return ServiceResult.error('Error al procesar el historial.');
    }
  }

  // ── GET /registros/hoy/ — tomas del día ───────────────────────────────────
  static Future<ServiceResult<List<RegistroMedicamento>>> hoy() async {
    final res = await ApiClient.get('$_base/hoy/');
    if (!res.success) return ServiceResult.error(res.error!);

    try {
      final lista = (res.data as List)
          .map((e) => RegistroMedicamento.fromJson(e))
          .toList();
      return ServiceResult.success(lista);
    } catch (_) {
      return ServiceResult.error('Error al procesar registros de hoy.');
    }
  }

  // ── GET /registros/{id}/ — detalle ────────────────────────────────────────
  static Future<ServiceResult<RegistroMedicamento>> obtener(int id) async {
    final res = await ApiClient.get('$_base/$id/');
    if (!res.success) return ServiceResult.error(res.error!);

    try {
      return ServiceResult.success(RegistroMedicamento.fromJson(res.data));
    } catch (_) {
      return ServiceResult.error('Error al procesar el registro.');
    }
  }

  // ── POST /registros/ — confirmar toma ─────────────────────────────────────
  static Future<ServiceResult<RegistroMedicamento>> confirmar(
    RegistroMedicamento registro,
  ) async {
    final res = await ApiClient.post('$_base/', registro.toJson());
    if (!res.success) return ServiceResult.error(res.error!);

    try {
      return ServiceResult.success(RegistroMedicamento.fromJson(res.data));
    } catch (_) {
      return ServiceResult.error('Error al procesar la confirmación.');
    }
  }

  // ── Shortcut: confirmar toma rápida desde la pantalla 04 ─────────────────
  static Future<ServiceResult<RegistroMedicamento>> confirmarToma({
    required int medicamentoId,
    required bool fueTomado,
    double? dosisTomada,
    String? notas,
  }) async {
    final ahora = DateTime.now();
    final fecha = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';
    final hora  = '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}:00';

    final registro = RegistroMedicamento(
      medicamentoId: medicamentoId,
      fecha:         fecha,
      hora:          hora,
      fueTomado:     fueTomado ? 1 : 0,
      dosisTomada:   dosisTomada,
      notas:         notas,
    );

    return confirmar(registro);
  }

  // ── PATCH /registros/{id}/ — corregir un registro ─────────────────────────
  static Future<ServiceResult<RegistroMedicamento>> corregir(
    int id,
    Map<String, dynamic> campos,
  ) async {
    final res = await ApiClient.patch('$_base/$id/', campos);
    if (!res.success) return ServiceResult.error(res.error!);

    try {
      return ServiceResult.success(RegistroMedicamento.fromJson(res.data));
    } catch (_) {
      return ServiceResult.error('Error al procesar la corrección.');
    }
  }

  // ── GET /registros/adherencia/ ────────────────────────────────────────────
  static Future<ServiceResult<Adherencia>> adherencia() async {
    final res = await ApiClient.get('$_base/adherencia/');
    if (!res.success) return ServiceResult.error(res.error!);

    try {
      return ServiceResult.success(Adherencia.fromJson(res.data));
    } catch (_) {
      return ServiceResult.error('Error al procesar la adherencia.');
    }
  }
}

// ── Modelo de adherencia ──────────────────────────────────────────────────────
class Adherencia {
  final int total;
  final int tomados;
  final int omitidos;
  final double porcentaje;

  const Adherencia({
    required this.total,
    required this.tomados,
    required this.omitidos,
    required this.porcentaje,
  });

  factory Adherencia.fromJson(Map<String, dynamic> json) => Adherencia(
    total:      json['total']      ?? 0,
    tomados:    json['tomados']    ?? 0,
    omitidos:   json['omitidos']   ?? 0,
    porcentaje: (json['porcentaje'] ?? 0).toDouble(),
  );
}