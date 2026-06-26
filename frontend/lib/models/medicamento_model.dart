class Medicamento {
  final int? id;
  final int? usuarioId;
  final String nombre;
  final String? tipo;
  final String? dosis;
  final String? unidad;
  final String? horaToma;       // "HH:MM:SS"
  final String? relacionComida;
  final String? frecuencia;
  final String? fechaInicio;    // "YYYY-MM-DD"
  final String? fechaFin;
  final int? activo;            // 0 o 1
  final String? notas;

  const Medicamento({
    this.id,
    this.usuarioId,
    required this.nombre,
    this.tipo,
    this.dosis,
    this.unidad,
    this.horaToma,
    this.relacionComida,
    this.frecuencia,
    this.fechaInicio,
    this.fechaFin,
    this.activo = 1,
    this.notas,
  });

  // ── Desde JSON (respuesta del backend) ───────────────────────────────────
  factory Medicamento.fromJson(Map<String, dynamic> json) => Medicamento(
    id:             json['id'],
    usuarioId:      json['usuario_id'],
    nombre:         json['nombre'] ?? '',
    tipo:           json['tipo'],
    dosis:          json['dosis'],
    unidad:         json['unidad'],
    horaToma:       json['hora_toma'],
    relacionComida: json['relacion_comida'],
    frecuencia:     json['frecuencia'],
    fechaInicio:    json['fecha_inicio'],
    fechaFin:       json['fecha_fin'],
    activo:         json['activo'],
    notas:          json['notas'],
  );

  // ── A JSON (para enviar al backend) ──────────────────────────────────────
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'nombre': nombre,
    };
    // Solo incluye los campos que no son null — DRF los acepta parcialmente
    if (tipo != null)           map['tipo']           = tipo;
    if (dosis != null)          map['dosis']          = dosis;
    if (unidad != null)         map['unidad']         = unidad;
    if (horaToma != null)       map['hora_toma']      = horaToma;
    if (relacionComida != null) map['relacion_comida']= relacionComida;
    if (frecuencia != null)     map['frecuencia']     = frecuencia;
    if (fechaInicio != null)    map['fecha_inicio']   = fechaInicio;
    if (fechaFin != null)       map['fecha_fin']      = fechaFin;
    if (activo != null)         map['activo']         = activo;
    if (notas != null)          map['notas']          = notas;
    return map;
  }

  // ── Helpers de UI ─────────────────────────────────────────────────────────
  bool get estaActivo => activo == 1;

  String get horaFormateada {
    if (horaToma == null) return '--:--';
    // Convierte "HH:MM:SS" a "HH:MM"
    return horaToma!.substring(0, 5);
  }

  // copyWith para edición parcial en formularios
  Medicamento copyWith({
    String? nombre,
    String? tipo,
    String? dosis,
    String? unidad,
    String? horaToma,
    String? relacionComida,
    String? frecuencia,
    String? fechaInicio,
    String? fechaFin,
    int? activo,
    String? notas,
  }) =>
      Medicamento(
        id:             id,
        usuarioId:      usuarioId,
        nombre:         nombre         ?? this.nombre,
        tipo:           tipo           ?? this.tipo,
        dosis:          dosis          ?? this.dosis,
        unidad:         unidad         ?? this.unidad,
        horaToma:       horaToma       ?? this.horaToma,
        relacionComida: relacionComida ?? this.relacionComida,
        frecuencia:     frecuencia     ?? this.frecuencia,
        fechaInicio:    fechaInicio    ?? this.fechaInicio,
        fechaFin:       fechaFin       ?? this.fechaFin,
        activo:         activo         ?? this.activo,
        notas:          notas          ?? this.notas,
      );
}