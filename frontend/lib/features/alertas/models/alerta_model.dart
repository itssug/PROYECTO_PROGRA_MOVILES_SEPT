class Alerta {
  final int id;
  final int usuarioId;
  final String tipo;
  final String? prioridad;
  final String? titulo;
  final String? mensaje;
  final int? leido;
  final String? fecha;

  Alerta({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    this.prioridad,
    this.titulo,
    this.mensaje,
    this.leido,
    this.fecha,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) => Alerta(
        id: json['id'],
        usuarioId: json['usuario'],
        tipo: json['tipo'],
        prioridad: json['prioridad'],
        titulo: json['titulo'],
        mensaje: json['mensaje'],
        leido: json['leido'],
        fecha: json['fecha'],
      );

  bool get esLeida => leido == 1;
}