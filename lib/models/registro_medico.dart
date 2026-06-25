class RegistroMedico {
  final String id;
  final String usuarioId;
  final String mascotaId;
  final String mascotaNombre;
  final String nombre;
  final String fecha;
  final String fotoUrl;
  final String notas;

  RegistroMedico({
    required this.id,
    required this.usuarioId,
    required this.mascotaId,
    required this.mascotaNombre,
    required this.nombre,
    this.fecha = '',
    this.fotoUrl = '',
    this.notas = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'usuario_id': usuarioId,
    'mascota_id': mascotaId,
    'mascota_nombre': mascotaNombre,
    'nombre': nombre,
    'fecha': fecha,
    'foto_url': fotoUrl,
    'notas': notas,
  };

  factory RegistroMedico.fromJson(Map<String, dynamic> j) => RegistroMedico(
    id: j['id'],
    usuarioId: j['usuario_id'] ?? '',
    mascotaId: j['mascota_id'] ?? '',
    mascotaNombre: j['mascota_nombre'] ?? '',
    nombre: j['nombre'] ?? '',
    fecha: j['fecha'] ?? '',
    fotoUrl: j['foto_url'] ?? '',
    notas: j['notas'] ?? '',
  );
}