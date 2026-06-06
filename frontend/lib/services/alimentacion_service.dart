import 'dart:async';
import 'package:intl/intl.dart';

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
}

// ─── Excepción Personalizada ─────────────────────────────────────────────────

class AlimentacionException implements Exception {
  final String message;
  const AlimentacionException(this.message);
  @override
  String toString() => message;
}

// ─── Servicio Principal (Datos Simulados / Mock) ─────────────────────────────

class AlimentacionService {
  final String _token;

  AlimentacionService({required String token}) : _token = token {
    _initMockData();
  }

  // ── Base de Datos Local Simulada en Memoria ───────────────────────────────
  static int _nextRegistroId = 1000;
  static bool _initialized = false;

  // Catálogo adaptado al contexto (Pacientes con Diabetes y dieta local)
  static final List<ComidaApi> _catalogo = [
    ComidaApi(id: 1, nombre: 'Avena cocida', categoria: 'Cereales', calorias: 71, carbohidratos: 12, azucares: 0.5, proteinas: 2.5, grasas: 1.4, indiceGlucemico: 55, cargaGlucemica: 6.6, unidadMedida: 'gramos', porcionTipica: 100, esPersonalizado: false),
    ComidaApi(id: 2, nombre: 'Pechuga de pollo a la plancha', categoria: 'Carnes', calorias: 165, carbohidratos: 0, azucares: 0, proteinas: 31, grasas: 3.6, indiceGlucemico: 0, cargaGlucemica: 0, unidadMedida: 'gramos', porcionTipica: 100, esPersonalizado: false),
    ComidaApi(id: 3, nombre: 'Quinua cocida', categoria: 'Cereales', calorias: 120, carbohidratos: 21.3, azucares: 0.9, proteinas: 4.4, grasas: 1.9, indiceGlucemico: 53, cargaGlucemica: 11, unidadMedida: 'gramos', porcionTipica: 100, esPersonalizado: false),
    ComidaApi(id: 4, nombre: 'Sopa de Maní', categoria: 'Sopas', calorias: 280, carbohidratos: 30, azucares: 2, proteinas: 10, grasas: 14, indiceGlucemico: 65, cargaGlucemica: 18, unidadMedida: 'plato', porcionTipica: 1, esPersonalizado: false),
    ComidaApi(id: 5, nombre: 'Salteña de pollo', categoria: 'Comida Rápida', calorias: 350, carbohidratos: 45, azucares: 15, proteinas: 12, grasas: 18, indiceGlucemico: 75, cargaGlucemica: 30, unidadMedida: 'unidad', porcionTipica: 1, esPersonalizado: false),
    ComidaApi(id: 6, nombre: 'Manzana verde', categoria: 'Frutas', calorias: 52, carbohidratos: 13.8, azucares: 10.4, proteinas: 0.3, grasas: 0.2, indiceGlucemico: 39, cargaGlucemica: 5, unidadMedida: 'gramos', porcionTipica: 100, esPersonalizado: false),
    ComidaApi(id: 7, nombre: 'Mate de Coca (sin azúcar)', categoria: 'Bebidas', calorias: 2, carbohidratos: 0.5, azucares: 0, proteinas: 0, grasas: 0, indiceGlucemico: 0, cargaGlucemica: 0, unidadMedida: 'taza', porcionTipica: 1, esPersonalizado: false),
    ComidaApi(id: 8, nombre: 'Huevo duro', categoria: 'Proteínas', calorias: 155, carbohidratos: 1.1, azucares: 1.1, proteinas: 13, grasas: 11, indiceGlucemico: 0, cargaGlucemica: 0, unidadMedida: 'unidad', porcionTipica: 1, esPersonalizado: false),
  ];

  static final List<RegistroComidaApi> _registros = [];

  void _initMockData() {
    if (_initialized) return;
    
    // Generar datos para "Hoy" automáticamente
    final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    _registros.addAll([
      RegistroComidaApi(
        id: _nextRegistroId++, comidaId: 1, comidaNombre: 'Avena cocida', comidaCategoria: 'Cereales', cantidad: 150, unidad: 'gramos', tipoComida: 'desayuno', tipoComidaDisplay: 'Desayuno', fecha: hoy, hora: '07:30:00', caloriasCalculadas: 106.5, carbohidratosCalculados: 18, azucaresCalculados: 0.75, cargaGlucemica: 9.9
      ),
      RegistroComidaApi(
        id: _nextRegistroId++, comidaId: 7, comidaNombre: 'Mate de Coca (sin azúcar)', comidaCategoria: 'Bebidas', cantidad: 1, unidad: 'taza', tipoComida: 'desayuno', tipoComidaDisplay: 'Desayuno', fecha: hoy, hora: '07:45:00', caloriasCalculadas: 2, carbohidratosCalculados: 0.5, azucaresCalculados: 0, cargaGlucemica: 0
      ),
      RegistroComidaApi(
        id: _nextRegistroId++, comidaId: 2, comidaNombre: 'Pechuga de pollo a la plancha', comidaCategoria: 'Carnes', cantidad: 200, unidad: 'gramos', tipoComida: 'almuerzo', tipoComidaDisplay: 'Almuerzo', fecha: hoy, hora: '13:00:00', caloriasCalculadas: 330, carbohidratosCalculados: 0, azucaresCalculados: 0, cargaGlucemica: 0
      ),
      RegistroComidaApi(
        id: _nextRegistroId++, comidaId: 3, comidaNombre: 'Quinua cocida', comidaCategoria: 'Cereales', cantidad: 100, unidad: 'gramos', tipoComida: 'almuerzo', tipoComidaDisplay: 'Almuerzo', fecha: hoy, hora: '13:05:00', caloriasCalculadas: 120, carbohidratosCalculados: 21.3, azucaresCalculados: 0.9, cargaGlucemica: 11
      ),
    ]);
    
    _initialized = true;
  }

  // ── Operaciones de Comidas (Catálogo) ───────────────────────────────────────

  Future<List<ComidaApi>> getCatalogo({String? categoria}) async {
    await Future.delayed(const Duration(milliseconds: 400)); // Simula latencia de red
    if (categoria != null) {
      return _catalogo.where((c) => c.categoria.toLowerCase() == categoria.toLowerCase()).toList();
    }
    return _catalogo;
  }

  Future<List<ComidaApi>> buscarAlimentos(String query) async {
    await Future.delayed(const Duration(milliseconds: 500)); 
    final q = query.toLowerCase();
    return _catalogo.where((c) => c.nombre.toLowerCase().contains(q)).toList();
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
    await Future.delayed(const Duration(milliseconds: 600));
    final nuevaComida = ComidaApi(
      id: _catalogo.length + 1,
      nombre: nombre,
      categoria: categoria,
      calorias: calorias,
      carbohidratos: carbohidratos,
      azucares: azucares,
      proteinas: proteinas,
      grasas: grasas,
      indiceGlucemico: indiceGlucemico,
      cargaGlucemica: 0, 
      unidadMedida: unidadMedida,
      porcionTipica: porcionTipica,
      esPersonalizado: true,
    );
    _catalogo.add(nuevaComida);
    return nuevaComida;
  }

  // ── Registro de Comidas consumidas ──────────────────────────────────────────

  Future<List<RegistroComidaApi>> getRegistrosDia({String? fecha}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final targetDate = fecha ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _registros.where((r) => r.fecha == targetDate).toList();
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
    await Future.delayed(const Duration(milliseconds: 600));
    
    final comida = _catalogo.firstWhere((c) => c.id == comidaId, 
      orElse: () => throw const AlimentacionException('Comida no encontrada en el catálogo local.'));

    // Calcular macronutrientes proporcionales a la cantidad ingresada
    double factor = cantidad / comida.porcionTipica;

    final nuevoRegistro = RegistroComidaApi(
      id: _nextRegistroId++,
      comidaId: comida.id,
      comidaNombre: comida.nombre,
      comidaCategoria: comida.categoria,
      cantidad: cantidad,
      unidad: unidad,
      tipoComida: tipoComida,
      tipoComidaDisplay: tipoComida.toUpperCase(),
      fecha: fecha,
      hora: hora,
      caloriasCalculadas: (comida.calorias ?? 0) * factor,
      carbohidratosCalculados: (comida.carbohidratos ?? 0) * factor,
      azucaresCalculados: (comida.azucares ?? 0) * factor,
      cargaGlucemica: (comida.cargaGlucemica ?? 0) * factor,
      notas: notas,
    );

    _registros.add(nuevoRegistro);
    return nuevoRegistro;
  }

  Future<void> eliminarRegistro(int registroId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _registros.removeWhere((r) => r.id == registroId);
  }

  // ── Resúmenes Diarios e Historial ───────────────────────────────────────────

  Future<ResumenDiario> getResumenDia({String? fecha}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final targetDate = fecha ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    final registrosDia = _registros.where((r) => r.fecha == targetDate).toList();
    
    double cal = 0, carb = 0, azu = 0, gl = 0;
    Map<String, double> porTipo = {};

    for (var r in registrosDia) {
      cal += r.caloriasCalculadas ?? 0;
      carb += r.carbohidratosCalculados ?? 0;
      azu += r.azucaresCalculados ?? 0;
      gl += r.cargaGlucemica ?? 0;
      
      porTipo[r.tipoComida] = (porTipo[r.tipoComida] ?? 0) + (r.caloriasCalculadas ?? 0);
    }

    return ResumenDiario(
      fecha: targetDate,
      totalCalorias: cal,
      totalCarbohidratos: carb,
      totalAzucares: azu,
      totalCargaGlucemica: gl,
      cantidadRegistros: registrosDia.length,
      porTipoComida: porTipo,
    );
  }

  Future<List<Map<String, dynamic>>> getHistorial({int dias = 7}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return []; // Se devuelve vacío ya que no se utiliza activamente en la UI proporcionada
  }
}