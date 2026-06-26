import '../models/medicamento_model.dart';
import 'api_client.dart';

class MedicamentoService {
  static const String _base = '/med-trat/medicamentos';

  // ── GET /medicamentos/ — lista completa ───────────────────────────────────
  static Future<ServiceResult<List<Medicamento>>> listar() async {
    final res = await ApiClient.get('$_base/');
    if (!res.success) return ServiceResult.error(res.error!);

    try {
      final lista = (res.data as List)
          .map((e) => Medicamento.fromJson(e))
          .toList();
      return ServiceResult.success(lista);
    } catch (_) {
      return ServiceResult.error('Error al procesar la lista de medicamentos.');
    }
  }

  // ── GET /medicamentos/activos/ — solo activos ─────────────────────────────
  static Future<ServiceResult<List<Medicamento>>> listarActivos() async {
    final res = await ApiClient.get('$_base/activos/');
    if (!res.success) return ServiceResult.error(res.error!);

    try {
      final lista = (res.data as List)
          .map((e) => Medicamento.fromJson(e))
          .toList();
      return ServiceResult.success(lista);
    } catch (_) {
      return ServiceResult.error('Error al procesar medicamentos activos.');
    }
  }

  // ── GET /medicamentos/{id}/ — detalle ─────────────────────────────────────
  static Future<ServiceResult<Medicamento>> obtener(int id) async {
    final res = await ApiClient.get('$_base/$id/');
    if (!res.success) return ServiceResult.error(res.error!);

    try {
      return ServiceResult.success(Medicamento.fromJson(res.data));
    } catch (_) {
      return ServiceResult.error('Error al procesar el medicamento.');
    }
  }

  // ── POST /medicamentos/ — crear ───────────────────────────────────────────
  static Future<ServiceResult<Medicamento>> crear(Medicamento med) async {
    final res = await ApiClient.post('$_base/', med.toJson());
    if (!res.success) return ServiceResult.error(res.error!);

    try {
      return ServiceResult.success(Medicamento.fromJson(res.data));
    } catch (_) {
      return ServiceResult.error('Error al procesar la respuesta.');
    }
  }

  // ── PUT /medicamentos/{id}/ — editar completo ─────────────────────────────
  static Future<ServiceResult<Medicamento>> editar(int id, Medicamento med) async {
    final res = await ApiClient.put('$_base/$id/', med.toJson());
    if (!res.success) return ServiceResult.error(res.error!);

    try {
      return ServiceResult.success(Medicamento.fromJson(res.data));
    } catch (_) {
      return ServiceResult.error('Error al procesar la respuesta.');
    }
  }

  // ── PATCH /medicamentos/{id}/ — editar parcial ────────────────────────────
  static Future<ServiceResult<Medicamento>> editarParcial(
    int id,
    Map<String, dynamic> campos,
  ) async {
    final res = await ApiClient.patch('$_base/$id/', campos);
    if (!res.success) return ServiceResult.error(res.error!);

    try {
      return ServiceResult.success(Medicamento.fromJson(res.data));
    } catch (_) {
      return ServiceResult.error('Error al procesar la respuesta.');
    }
  }

  // ── DELETE /medicamentos/{id}/ ────────────────────────────────────────────
  static Future<ServiceResult<void>> eliminar(int id) async {
    final res = await ApiClient.delete('$_base/$id/');
    if (!res.success) return ServiceResult.error(res.error!);
    return ServiceResult.success(null);
  }

  // ── PATCH activo=0 — desactivar sin eliminar ──────────────────────────────
  static Future<ServiceResult<Medicamento>> desactivar(int id) async {
    return editarParcial(id, {'activo': 0});
  }
}

// ── Resultado tipado genérico (reutilizable en todos los services) ────────────
class ServiceResult<T> {
  final T? data;
  final String? error;
  final bool success;

  const ServiceResult._({this.data, this.error, required this.success});

  factory ServiceResult.success(T? data) =>
      ServiceResult._(data: data, success: true);

  factory ServiceResult.error(String error) =>
      ServiceResult._(error: error, success: false);
}