class EstadoEmocional {
  final int? id;
  final int usuarioId;
  final String fecha;
  final String? hora;
  final int nivelEstres;
  final String estado;
  final String? evento;
  final String? notas;

  EstadoEmocional({
    this.id, required this.usuarioId, required this.fecha,
    this.hora, required this.nivelEstres, required this.estado,
    this.evento, this.notas,
  });

  factory EstadoEmocional.fromJson(Map<String, dynamic> json) => EstadoEmocional(
    id: json['id'], usuarioId: json['usuario'],
    fecha: json['fecha'], hora: json['hora'],
    nivelEstres: json['nivel_estres'], estado: json['estado'],
    evento: json['evento'], notas: json['notas'],
  );

  Map<String, dynamic> toJson() => {
    'usuario': usuarioId, 'fecha': fecha, 'hora': hora,
    'nivel_estres': nivelEstres, 'estado': estado,
    'evento': evento, 'notas': notas,
  };
}