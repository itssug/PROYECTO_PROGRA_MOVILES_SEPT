class RegistroMedicamento {
  final int? id;
  final int? usuarioId;
  final int medicamentoId;
  final String? medicamentoNombre; // solo lectura, viene del backend
  final String? medicamentoTipo;   // solo lectura, viene del backend
  final String fecha;              // "YYYY-MM-DD"
  final String hora;               // "HH:MM:SS"
  final double? dosisTomada;
  final int fueTomado;             // 0 o 1
  final String? notas;

  const RegistroMedicamento({
    this.id,
    this.usuarioId,
    required this.medicamentoId,
    this.medicamentoNombre,
    this.medicamentoTipo,
    required this.fecha,
    required this.hora,
    this.dosisTomada,
    required this.fueTomado,
    this.notas,
  });

  // ── Desde JSON ────────────────────────────────────────────────────────────
  factory RegistroMedicamento.fromJson(Map<String, dynamic> json) =>
      RegistroMedicamento(
        id:                json['id'],
        usuarioId:         json['usuario_id'],
        medicamentoId:     json['medicamento'],
        medicamentoNombre: json['medicamento_nombre'],
        medicamentoTipo:   json['medicamento_tipo'],
        fecha:             json['fecha'] ?? '',
        hora:              json['hora'] ?? '',
        dosisTomada:       json['dosis_tomada'] != null
            ? double.tryParse(json['dosis_tomada'].toString())
            : null,
        fueTomado:         json['fue_tomado'] ?? 0,
        notas:             json['notas'],
      );

  // ── A JSON ────────────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'medicamento': medicamentoId,
      'fecha':       fecha,
      'hora':        hora,
      'fue_tomado':  fueTomado,
    };
    if (dosisTomada != null) map['dosis_tomada'] = dosisTomada;
    if (notas != null)       map['notas']        = notas;
    return map;
  }

  // ── Helpers de UI ─────────────────────────────────────────────────────────
  bool get tomado => fueTomado == 1;

  String get horaFormateada => hora.length >= 5 ? hora.substring(0, 5) : hora;

  String get fechaFormateada {
    // "2025-05-09" → "09/05/2025"
    final parts = fecha.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return fecha;
  }
}