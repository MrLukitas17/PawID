class Evento {
  final String id;
  final String usuarioId;
  final String mascotaId;
  final String mascotaNombre;
  final String tipo; // 'control', 'vacuna', 'medicamento'
  final String titulo;
  final String descripcion;
  final String fecha; // yyyy-MM-dd
  final String hora;
  bool completado;

  Evento({
    required this.id,
    required this.usuarioId,
    required this.mascotaId,
    required this.mascotaNombre,
    required this.tipo,
    required this.titulo,
    this.descripcion = '',
    required this.fecha,
    this.hora = '',
    this.completado = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'usuario_id': usuarioId,
    'mascota_id': mascotaId,
    'mascota_nombre': mascotaNombre,
    'tipo': tipo,
    'titulo': titulo,
    'descripcion': descripcion,
    'fecha': fecha,
    'hora': hora,
    'completado': completado,
  };

  factory Evento.fromJson(Map<String, dynamic> j) => Evento(
    id: j['id'],
    usuarioId: j['usuario_id'] ?? '',
    mascotaId: j['mascota_id'] ?? '',
    mascotaNombre: j['mascota_nombre'] ?? '',
    tipo: j['tipo'] ?? 'control',
    titulo: j['titulo'] ?? '',
    descripcion: j['descripcion'] ?? '',
    fecha: j['fecha'] ?? '',
    hora: j['hora'] ?? '',
    completado: j['completado'] ?? false,
  );

  DateTime get fechaDateTime => DateTime.tryParse(fecha) ?? DateTime.now();

  String get tipoLabel {
    switch (tipo) {
      case 'vacuna': return 'Vacuna';
      case 'medicamento': return 'Medicamento';
      default: return 'Control Veterinario';
    }
  }

  String get tipoIcon {
    switch (tipo) {
      case 'vacuna': return '💉';
      case 'medicamento': return '💊';
      default: return '🏥';
    }
  }
}