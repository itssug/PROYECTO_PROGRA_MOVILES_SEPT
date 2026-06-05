class RegistroSueno {
  final int? id;
  final int usuarioId;
  final String fecha;
  final String? horaAcostarse;
  final String? horaDespertar;
  final double? horasDormidas;
  final String calidad;
  final bool? huboDespertares;
  final String? notas;

  RegistroSueno({
    this.id, required this.usuarioId, required this.fecha,
    this.horaAcostarse, this.horaDespertar, this.horasDormidas,
    required this.calidad, this.huboDespertares, this.notas,
  });

  factory RegistroSueno.fromJson(Map<String, dynamic> json) => RegistroSueno(
    id: json['id'], usuarioId: json['usuario'],
    fecha: json['fecha'], horaAcostarse: json['hora_acostarse'],
    horaDespertar: json['hora_despertar'],
    horasDormidas: json['horas_dormidas'] != null
        ? double.parse(json['horas_dormidas'].toString()) : null,
    calidad: json['calidad'],
    huboDespertares: json['hubo_despertares'] == 1,
    notas: json['notas'],
  );

  Map<String, dynamic> toJson() => {
    'usuario': usuarioId, 'fecha': fecha,
    'hora_acostarse': horaAcostarse, 'hora_despertar': horaDespertar,
    'horas_dormidas': horasDormidas, 'calidad': calidad,
    'hubo_despertares': huboDespertares == true ? 1 : 0, 'notas': notas,
  };
}